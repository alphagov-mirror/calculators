# encoding: utf-8

require 'active_model'

class ChildBenefitTaxCalculator
  include ActiveModel::Validations

  attr_reader :adjusted_net_income_calculator, :adjusted_net_income, :children_count,
    :starting_children, :tax_year, :is_part_year_claim, :part_year_children_count

  NET_INCOME_THRESHOLD = 50000
  TAX_COMMENCEMENT_DATE = Date.parse('7 Jan 2013')

  TAX_YEARS = (2012..2019).each_with_object({}) { |year, hash|
    hash[year.to_s] = [Date.new(year, 4, 6), Date.new(year + 1, 4, 5)]
  }.freeze

  validate :valid_child_dates
  validates_presence_of :is_part_year_claim, message: "select part year tax claim"
  validates_inclusion_of :tax_year, in: TAX_YEARS.keys.map(&:to_i), message: "select a tax year"
  validate :valid_number_of_children
  validate :tax_year_contains_at_least_one_child

  def initialize(params = {})
    @adjusted_net_income_calculator = AdjustedNetIncomeCalculator.new(params)
    @adjusted_net_income = calculate_adjusted_net_income(params[:adjusted_net_income])
    @children_count = params[:children_count] ? params[:children_count].to_i : 1
    @part_year_children_count = params[:part_year_children_count] ? params[:part_year_children_count].to_i : 0
    @is_part_year_claim = params[:is_part_year_claim]
    @tax_year = params[:year].to_i
    @starting_children = process_starting_children(params[:starting_children])
  end

  def self.valid_date_params?(params)
    params && params[:year].present? && params[:month].present? && params[:day].present?
  end

  def valid_date_params?(params)
    self.class.valid_date_params?(params)
  end

  # Return the date of the Monday in the future that is closest to the date supplied.
  # If the date supplied is a Monday, do not adjust it.
  def monday_on_or_after(date)
    date.monday? ? date : date.next_week(:monday)
  end

  def nothing_owed?
    @adjusted_net_income < NET_INCOME_THRESHOLD || tax_estimate.abs.zero?
  end

  def has_errors?
    errors.any? || starting_children_errors?
  end

  def starting_children_errors?
    is_part_year_claim == 'yes' && starting_children.select { |c| c.errors.any? }.any?
  end

  def percent_tax_charge
    if @adjusted_net_income >= 60000
      100
    elsif (59900..59999).cover?(@adjusted_net_income)
      99
    else
      ((@adjusted_net_income - 50000) / 100.0).floor
    end
  end

  def child_benefit_start_date
    @tax_year == 2012 ? TAX_COMMENCEMENT_DATE : selected_tax_year.first
  end

  def child_benefit_end_date
    selected_tax_year.last
  end

  def can_calculate?
    valid? && !has_errors?
  end

  def selected_tax_year
    TAX_YEARS[@tax_year.to_s]
  end

  def benefits_claimed_amount
    all_weeks_children = {}
    full_year_children = @children_count - @part_year_children_count
    (child_benefit_start_date...child_benefit_end_date).each_slice(7) do |week|
      monday = monday_on_or_after(week.first)
      all_weeks_children[monday] = 0
      @starting_children.each do |child|
        all_weeks_children[monday] += 1 if eligible?(child, tax_year, monday)
      end
      full_year_children.times do
        all_weeks_children[monday] += 1
      end
    end
    # calculate total for all weeks
    total = all_weeks_children.values.inject(0) do |sum, n|
      sum + BigDecimal(weekly_sum_for_children(n).to_s)
    end
    total.to_f
  end

  def tax_estimate
    (benefits_claimed_amount * (percent_tax_charge / 100.0)).floor
  end

private

  def process_starting_children(children)
    number_of_children = if selected_tax_year.present?
                           @part_year_children_count
                         else
                           @children_count
                         end

    [].tap do |ary|
      number_of_children.times do |n|
        ary << if children && children[n.to_s] && valid_date_params?(children[n.to_s][:start])
                 StartingChild.new(children[n.to_s])
               else
                 StartingChild.new
               end
      end
    end
  end

  def eligible?(child, tax_year, week_start_date)
    adjusted_start_date = monday_on_or_after(child.start_date)

    eligible_for_tax_year?(child, tax_year) &&
      days_include_week?(adjusted_start_date, child.benefits_end, week_start_date)
  end

  def eligible_for_tax_year?(child, tax_year)
    if tax_year == 2012
      !(Date.parse('1 April 2013')..Date.parse('5 April 2013')).cover?(child.start_date)
    else
      !(Date.parse("31 March #{tax_year + 1}")..Date.parse("5 April #{tax_year + 1}")).cover?(child.start_date)
    end
  end

  def days_include_week?(start_date, end_date, week_start_date)
    if start_date.nil?
      end_date >= week_start_date
    elsif end_date.nil?
      start_date <= week_start_date
    else
      (start_date..end_date).cover?(week_start_date)
    end
  end

  def weekly_sum_for_children(num_children)
    rate = ChildBenefitRates.new(tax_year)
    if num_children.positive?
      rate.first_child_rate + (num_children - 1) * rate.additional_child_rate
    else
      0
    end
  end

  def calculate_adjusted_net_income(adjusted_net_income)
    if @adjusted_net_income_calculator.can_calculate?
      @adjusted_net_income_calculator.calculate_adjusted_net_income
    elsif adjusted_net_income.present?
      adjusted_net_income.gsub(/[£, -]/, '').to_i
    end
  end

  def valid_child_dates
    is_part_year_claim == 'yes' && @starting_children.each(&:valid?)
  end

  def valid_number_of_children
    if @is_part_year_claim == 'yes' && (@children_count < @part_year_children_count)
      errors.add(:part_year_children_count, "the number of children you're claiming a part year for can't be more than the total number of children you're claiming for")
    end
  end

  def tax_year_contains_at_least_one_child
    return unless selected_tax_year.present? && @starting_children.select(&:valid?).any?

    in_tax_year = @starting_children.reject { |c| c.start_date.nil? || c.start_date > selected_tax_year.last || (c.end_date.present? && c.end_date < selected_tax_year.first) }
    if in_tax_year.empty?
      @starting_children.first.errors.add(:end_date, "You haven't received any Child Benefit for the tax year selected. Check your Child Benefit dates or choose a different tax year.")
    end
  end
end
