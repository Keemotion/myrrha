require File.expand_path('../spec_helper', __FILE__)
describe Myrrha do

  it "should have a version number" do
    expect(Myrrha.const_defined?(:VERSION)).to be true
  end

  it "should provide the abitity to define a coercion rules" do
    rules = Myrrha.coercions do |g|
      g.coercion String, Integer, lambda{|s,t| Integer(s)}
      g.coercion String, Float,   lambda{|s,t| Float(s)  }
    end
    expect(rules.coerce(12,     Integer)).to eq(12)
    expect(rules.coerce("12",   Integer)).to eq(12)
    expect(rules.coerce(12.2,   Float)).to   eq(12.2)
    expect(rules.coerce("12.2", Float)).to   eq(12.2)
    expect(rules.coerce("12",   Numeric)).to eq(12)
    expect(rules.coerce("12.2", Numeric)).to eq(12.2)
    expect {
      rules.coerce(true, Integer)
    }.to raise_error(Myrrha::Error, "Unable to coerce `true` to Integer")
  end

  it "should support upon rules" do
    rules = Myrrha.coercions do |g|
      g.coercion(Integer, Symbol){|s,t| :coercion}
      g.upon(lambda{|s| s<0}){|s,t| :upon}
    end
    expect(rules.coerce(12, Symbol)).to eq(:coercion)
    expect(rules.coerce(-12, Symbol)).to eq(:upon)
  end

  it "should support fallback rules" do
    rules = Myrrha.coercions do |g|
      g.fallback String, lambda{|s,t| :world}
    end
    expect(rules.coerce("hello", Symbol)).to eq(:world)
  end

  it "should support using matchers" do
    ArrayOfSymbols = proc{|val| val.is_a?(Array) && val.all?{|x| Symbol===x}}
    rules = Myrrha.coercions do |g|
      g.coercion ArrayOfSymbols, String, lambda{|x,t| x.join(', ')}
    end
    expect(rules.coerce([:a, :b], ArrayOfSymbols)).to eq([:a, :b])
    expect(rules.coerce([:a, :b], String)).to eq("a, b")
  end

  it "should support using any object that respond to call as converter" do
    converter = Object.new
    def converter.call(arg, t); [arg, t]; end
    rules = Myrrha.coercions do |g|
      g.coercion String, Symbol, converter
    end
    expect(rules.coerce("hello", Symbol)).to eq(["hello", Symbol])
  end

  it "should support adding rules later" do
    rules = Myrrha.coercions do |c|
      c.coercion String, Symbol, lambda{|s,t| s.to_sym}
      c.fallback Object,         lambda{|s,t| :fallback}
    end
    expect(rules.coerce("hello", Symbol)).to eq(:hello)
    expect(rules.coerce(12, Symbol)).to eq(:fallback)

    rules.append do |c|
      c.coercion Integer, Symbol, lambda{|s,t| s.to_s.to_sym}
    end
    expect(rules.coerce(12, Symbol)).to eq(:"12")
    expect(rules.coerce(true, Symbol)).to eq(:fallback)
  end

  it "should support adding rules before" do
    rules = Myrrha.coercions do |c|
      c.coercion String, Symbol, lambda{|s,t| s.to_sym}
    end
    expect(rules.coerce("hello", Symbol)).to eq(:hello)
    rules.prepend do |c|
      c.coercion String, Symbol, lambda{|s,t| s.to_s.upcase.to_sym}
    end
    expect(rules.coerce("hello", Symbol)).to eq(:HELLO)
  end

  it "should used superdomain rules in an optimistic strategy" do
    rules = Myrrha.coercions do |c|
      c.coercion String, Numeric, lambda{|s,t| Integer(s)}
    end
    expect(rules.coerce("12", Integer)).to eql(12)
    expect { rules.coerce("12", Float) }.to raise_error(Myrrha::Error)
  end

  describe "path convertions" do
    let(:rules){
      Myrrha.coercions do |c|
        c.coercion Integer, String, lambda{|s,t| s.to_s}
        c.coercion String,  Float,  lambda{|s,t| Float(s)}
        c.coercion Integer, Float,  [String]
        c.coercion Float,   String, lambda{|s,t| s.to_s}
        c.coercion String,  Symbol, lambda{|s,t| s.to_sym}
        c.coercion Integer, Symbol, [Float, String]
      end
    }
    it "should work with a simple and single" do
      expect(rules.coerce(12, Float)).to eql(12.0)
    end
    it "should work with a complex and multiple path" do
      expect(rules.coerce(12, Symbol)).to eql(:"12.0")
    end
  end

  specify "path convertions (from CHANGELOG)" do
    rules = Myrrha.coercions do |r|
      r.coercion String,  Symbol, lambda{|s,t| s.to_sym }
      r.coercion Float,   String, lambda{|s,t| s.to_s   }
      r.coercion Integer, Float,  lambda{|s,t| Float(s) }
      r.coercion Integer, Symbol, [Float, String]
    end
    expect(rules.coerce(12, Symbol)).to eql(:"12.0")
  end

end
