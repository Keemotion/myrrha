require 'spec_helper'
module Myrrha
  describe "Coercions#belongs_to?" do
    let(:rules){ Coercions.new }

    before(:all) do
      class Coercions
        public :belongs_to?
      end
    end

    specify "with a class" do
      expect(rules.belongs_to?(12, Integer)).to be(true)
    end

    specify "with a superclass" do
      expect(rules.belongs_to?(12, Numeric)).to be true
    end

    specify "with a proc or arity 1" do
      expect(rules.belongs_to?(12, lambda{|x| x>10})).to be true
      expect(rules.belongs_to?(12, lambda{|x| x<10})).to be false
    end

    specify "with a proc or arity 2" do
      got = nil
      l = lambda{|x,t| got = t; t == l }
      expect(rules.belongs_to?(12, l)).to be true
      got.should eq(l)
      expect(rules.belongs_to?(12, l, :nosuch)).to be false
      got.should eq(:nosuch)
    end

  end
end
