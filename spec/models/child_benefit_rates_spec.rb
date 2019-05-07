# encoding: utf-8

require 'spec_helper'

describe ChildBenefitRates, type: :model do
  describe "test initialization of instance variable" do
    it "should intialize instance correctly" do
      expect(ChildBenefitRates.new(2014).year).to eq(2014)
    end
  end

  describe "return correct rates for 2012 year passed in" do
    before(:each) do
      @calc = ChildBenefitRates.new(2012)
    end

    it "should return correct rates" do
      expect(@calc.first_child_rate).to eq(20.3)
      expect(@calc.additional_child_rate).to eq(13.4)
    end
  end

  describe "return correct rates for 2013 year passed in" do
    before(:each) do
      @calc = ChildBenefitRates.new(2013)
    end

    it "should return correct rates" do
      expect(@calc.first_child_rate).to eq(20.3)
      expect(@calc.additional_child_rate).to eq(13.4)
    end
  end

  describe "return correct rates for 2014 year passed in" do
    before(:each) do
      @calc = ChildBenefitRates.new(2014)
    end

    it "should return correct rates" do
      expect(@calc.first_child_rate).to eq(20.5)
      expect(@calc.additional_child_rate).to eq(13.55)
    end
  end

  describe "return correct rates for 2015 year passed in" do
    before(:each) do
      @calc = ChildBenefitRates.new(2015)
    end

    it "should return correct rates" do
      expect(@calc.first_child_rate).to eq(20.7)
      expect(@calc.additional_child_rate).to eq(13.7)
    end
  end

  describe "return correct rates for 2016 year passed in" do
    before(:each) do
      @calc = ChildBenefitRates.new(2016)
    end

    it "should return correct rates" do
      expect(@calc.first_child_rate).to eq(20.7)
      expect(@calc.additional_child_rate).to eq(13.7)
    end
  end

  describe "return correct rates for 2017/18" do
    before(:each) do
      @calc = ChildBenefitRates.new(2017)
    end

    it "should return correct rates" do
      expect(@calc.first_child_rate).to eq(20.7)
      expect(@calc.additional_child_rate).to eq(13.7)
    end
  end

  describe "return correct rates for 2018/19" do
    before(:each) do
      @calc = ChildBenefitRates.new(2018)
    end

    it "should return correct rates" do
      expect(@calc.first_child_rate).to eq(20.7)
      expect(@calc.additional_child_rate).to eq(13.7)
    end
  end

  describe "return correct rates for 2019/20" do
    before(:each) do
      @calc = ChildBenefitRates.new(2019)
    end

    it "should return correct rates" do
      expect(@calc.first_child_rate).to eq(20.7)
      expect(@calc.additional_child_rate).to eq(13.7)
    end
  end
end
