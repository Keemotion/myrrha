require 'spec_helper'
module Myrrha
  describe "Coercions#subdomain?" do
    let(:r){ Coercions.new }

    before(:all) do
      class Coercions
        public :subdomain?
      end
    end

    it 'works as expected with modules and classes' do
      expect(r.subdomain?(Symbol, Object)).to be true
      expect(r.subdomain?(Class, Module)).to be true
    end

    it 'works as expected with Symbol target domains' do
      expect(r.subdomain?(:to_ruby_literal, :to_ruby_literal)).to be true
      expect(r.subdomain?(:to_ruby_literal, :none)).to be false
    end

  end
end
