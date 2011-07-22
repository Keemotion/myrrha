require File.expand_path('../spec_helper', __FILE__)
describe Myrrha do
  
  it "should have a version number" do
    Myrrha.const_defined?(:VERSION).should be_true
  end
  
  it "should provide the abitity to define a coercion rules" do
    rules = Myrrha.coercions do |g|
      g.coercion String, Integer, lambda{|s,t| Integer(s)}
      g.coercion String, Float,   lambda{|s,t| Float(s)  }
    end
    rules.coerce(12,     Integer).should eq(12)
    rules.coerce("12",   Integer).should eq(12)
    rules.coerce(12.2,   Float).should   eq(12.2)
    rules.coerce("12.2", Float).should   eq(12.2) 
    rules.coerce("12",   Numeric).should eq(12)
    rules.coerce("12.2", Numeric).should eq(12.2)
    lambda{ 
      rules.coerce(true, Integer) 
    }.should raise_error(Myrrha::Error, "Unable to coerce `true` to Integer")
    lambda{ 
      rules.coerce("12.2", Integer)
    }.should raise_error(Myrrha::Error, /^Unable to coerce `12.2` to Integer \(invalid value /)
  end
  
  it "should support upon rules" do
    rules = Myrrha.coercions do |g|
      g.coercion(Integer, Symbol){|s,t| :coercion} 
      g.upon(lambda{|s| s<0}){|s,t| :upon}
    end
    rules.coerce(12, Symbol).should eq(:coercion)
    rules.coerce(-12, Symbol).should eq(:upon)
  end
  
  it "should support fallback rules" do
    rules = Myrrha.coercions do |g|
      g.fallback String, lambda{|s,t| :world}
    end
    rules.coerce("hello", Symbol).should eq(:world)
  end
  
  it "should support using matchers" do
    ArrayOfSymbols = proc{|val| val.is_a?(Array) && val.all?{|x| Symbol===x}}
    rules = Myrrha.coercions do |g|
      g.coercion ArrayOfSymbols, String, lambda{|x,t| x.join(', ')}
    end
    rules.coerce([:a, :b], ArrayOfSymbols).should eq([:a, :b])
    rules.coerce([:a, :b], String).should eq("a, b")
  end
  
  it "should support using any object that respond to call as converter" do
    converter = Object.new
    def converter.call(arg, t); [arg, t]; end
    rules = Myrrha.coercions do |g|
      g.coercion String, Symbol, converter
    end
    rules.coerce("hello", Symbol).should eq(["hello", Symbol])
  end
  
  it "should support adding rules later" do
    rules = Myrrha.coercions do |c|
      c.coercion String, Symbol, lambda{|s,t| s.to_sym}
      c.fallback Object,         lambda{|s,t| :fallback}
    end
    rules.coerce("hello", Symbol).should eq(:hello)
    rules.coerce(12, Symbol).should eq(:fallback)
    
    rules.append do |c|
      c.coercion Integer, Symbol, lambda{|s,t| s.to_s.to_sym} 
    end
    rules.coerce(12, Symbol).should eq(:"12")
    rules.coerce(true, Symbol).should eq(:fallback)
  end
  
  it "should support adding rules before" do
    rules = Myrrha.coercions do |c|
      c.coercion String, Symbol, lambda{|s,t| s.to_sym}
    end
    rules.coerce("hello", Symbol).should eq(:hello)
    rules.prepend do |c|
      c.coercion String, Symbol, lambda{|s,t| s.to_s.upcase.to_sym}
    end
    rules.coerce("hello", Symbol).should eq(:HELLO)
  end
  
end
