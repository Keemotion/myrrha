#
# Myrrha -- the missing coercion framework for Ruby
#
module Myrrha
  
  #
  # Raised when a coercion fails
  #
  class Error < StandardError; end
  
  #
  # Creates a domain instance by specialization by constraint
  #
  # @param [Class] superdom the superdomain of the created domain
  # @param [Proc] pred the domain predicate
  # @return [Class] the created domain
  #
  def self.domain(superdom = Object, subdoms=nil, &pred) 
    dom = Class.new(superdom).extend(Domain)
    dom.instance_eval {
      @sub_domains = subdoms 
      @super_domain = superdom
      @predicate = pred
    }
    dom
  end
  
  #
  # Builds a set of coercions rules. 
  #
  # Example:
  #
  #   rules = Myrrha.coercions do |c|
  #     c.coercion String, Integer, lambda{|s,t| Integer(s)}
  #     #
  #     # [...]
  #     #
  #     c.fallback String, lambda{|s,t| ... }
  #   end
  #
  def self.coercions(&block)
    Coercions.new(&block)
  end
    
  # 
  # Encapsulates class methods of created domains
  #
  module Domain
    
    #
    # Creates a new instance of this domain
    #
    def new(*args)
      if (args.size == 1) && (superclass === args.first)
        if self === args.first
          args.first
        else
          raise ArgumentError, "Invalid value #{args.join(' ')} for #{self}"
        end
      elsif superclass.respond_to?(:new)
        new(super(*args))
      else
        raise ArgumentError, "Invalid value #{args.join(' ')} for #{self}"
      end
    end
    
    # (see Class.superclass)
    def superclass
      @super_domain
    end
    
    #
    # Checks if `value` belongs to this domain
    # 
    def ===(value)
      (superclass === value) && @predicate.call(value)
    end
    
    #
    # Returns true if clazz if an explicit sub domain of self or if it's the
    # case in Ruby.
    #
    def superdomain_of?(child)
      Array(@sub_domains).include?(child)
    end
    
    #
    # Returns the specialization by constraint predicate
    #
    # @return [Proc] the domain predicate
    #  
    def predicate
      @predicate
    end
    
  end # module Domain
    
  # Defines a set of coercion rules
  #
  class Coercions
    
    # @return [Domain] The main target domain, if any
    attr_accessor :main_target_domain
    
    #
    # Creates an empty list of coercion rules
    #
    def initialize(upons = [], rules = [], fallbacks = [], main_target_domain = nil)
      @upons = upons
      @rules = rules
      @fallbacks = fallbacks
      @appender = :<<
      @main_target_domain = main_target_domain
      yield(self) if block_given?
    end
    
    #
    # Appends the list of rules with new ones.
    #
    # New upon, coercion and fallback rules will be put after the already 
    # existing ones, in each case.  
    #
    # Example:
    #
    #   rules = Myrrha.coercions do ... end
    #   rules.append do |r|
    #
    #     # [previous coercion rules would come here]
    #
    #     # install new rules
    #     r.coercion String, Float, lambda{|v,t| Float(t)}
    #   end
    #
    def append(&proc)
      extend_rules(:<<, proc)
    end
    
    #
    # Prepends the list of rules with new ones.
    #
    # New upon, coercion and fallback rules will be put before the already 
    # existing ones, in each case.  
    #
    # Example:
    #
    #   rules = Myrrha.coercions do ... end
    #   rules.prepend do |r|
    #
    #     # install new rules
    #     r.coercion String, Float, lambda{|v,t| Float(t)}
    #
    #     # [previous coercion rules would come here]
    #
    #   end
    #
    def prepend(&proc)
      extend_rules(:unshift, proc)
    end
    
    #
    # Adds an upon rule for a source domain.
    #
    # Example:
    #
    #   Myrrha.coercions do |r|
    #
    #     # Don't even try something else on nil
    #     r.upon(NilClass){|s,t| nil}
    #     [...]
    #
    #   end
    #
    # @param source [Domain] a source domain (mimic Domain) 
    # @param converter [Converter] an optional converter (mimic Converter)
    # @param convproc [Proc] used when converter is not specified
    # @return self
    #
    def upon(source, converter = nil, &convproc)
      @upons.send(@appender, [source, nil, converter || convproc])
      self
    end
    
    #
    # Adds a coercion rule from a source to a target domain.
    #
    # The conversion can be provided through `converter` or via a block
    # directly. See main documentation about recognized converters.
    #
    # Example:
    #
    #   Myrrha.coercions do |r|
    #     
    #     # With an explicit proc
    #     r.coercion String, Integer, lambda{|v,t| 
    #       Integer(v)
    #     } 
    #
    #     # With an implicit proc
    #     r.coercion(String, Float) do |v,t| 
    #       Float(v)
    #     end
    #
    #   end
    #
    # @param source [Domain] a source domain (mimicing Domain) 
    # @param target [Domain] a target domain (mimicing Domain)
    # @param converter [Converter] an optional converter (mimic Converter)
    # @param convproc [Proc] used when converter is not specified
    # @return self
    #
    def coercion(source, target = main_target_domain, converter = nil, &convproc)
      @rules.send(@appender, [source, target, converter || convproc])
      self
    end
    
    #
    # Adds a fallback rule for a source domain.
    #
    # Example:
    #
    #   Myrrha.coercions do |r|
    #     
    #     # Add a 'last chance' rule for Strings
    #     r.fallback(String) do |v,t| 
    #       # the user wants _v_ to be converted to a value of domain _t_
    #     end
    #
    #   end
    #
    # @param source [Domain] a source domain (mimic Domain) 
    # @param converter [Converter] an optional converter (mimic Converter)
    # @param convproc [Proc] used when converter is not specified
    # @return self
    #
    def fallback(source, converter = nil, &convproc)
      @fallbacks.send(@appender, [source, nil, converter || convproc])
      self
    end
    
    #
    # Coerces `value` to an element of `target_domain`
    #
    # This method tries each coercion rule, then each fallback in turn. Rules 
    # for which source and target domain match are executed until one succeeds.
    # A Myrrha::Error is raised if no rule matches or executes successfuly.
    #
    # @param [Object] value any ruby value
    # @param [Domain] target_domain a target domain to convert to (mimic Domain)
    # @return self
    #
    def coerce(value, target_domain = main_target_domain)
      return value if belongs_to?(value, target_domain)
      error = nil
      each_rule do |from,to,converter|
        next unless from.nil? or belongs_to?(value, from, target_domain)
        begin
          catch(:nextrule) do
            if to.nil? or subdomain?(to, target_domain)
              got = convert(value, target_domain, converter)
              return got
            elsif subdomain?(target_domain, to)
              got = convert(value, to, converter)
              return got if belongs_to?(got, target_domain)
            end
          end
        rescue => ex
          error = ex.message unless error
        end
      end
      msg = "Unable to coerce `#{value}` to #{target_domain}"
      msg += " (#{error})" if error
      raise Error, msg
    end
    alias :apply :coerce
    
    #
    # Returns true if `value` can be considered as a valid element of the 
    # domain `domain`, false otherwise.
    #
    # @param [Object] value any ruby value
    # @param [Domain] domain a domain (mimic Domain)
    # @return [Boolean] true if `value` belongs to `domain`, false otherwise
    #
    def belongs_to?(value, domain, target_domain = domain)
      case domain
      when Proc
        if domain.arity == 2
          domain.call(value, target_domain)
        elsif RUBY_VERSION < "1.9"
          domain.call(value)
        elsif domain
          domain === value
        end
      else 
        domain.respond_to?(:===) ? 
          domain === value :
          false
      end
    end
    
    #
    # Returns `true` if `child` can be considered a valid sub domain of 
    # `parent`, false otherwise.
    #
    # @param [Domain] child a domain (mimic Domain)
    # @param [Domain] parent another domain (mimic Domain)
    # @return [Boolean] true if `child` is a subdomain of `parent`, false 
    #         otherwise.
    #
    def subdomain?(child, parent)
      if child == parent
        true
      elsif parent.respond_to?(:superdomain_of?)
        parent.superdomain_of?(child)
      elsif child.respond_to?(:superclass) && child.superclass 
        subdomain?(child.superclass, parent)
      else 
        false
      end
    end
    
    #
    # Duplicates this set of rules in such a way that the original will not
    # be affected by any change made to the copy.
    #
    # @return [Coercions] a copy of this set of rules
    # 
    def dup
      Coercions.new(@upons.dup, @rules.dup, @fallbacks.dup, main_target_domain)
    end
    
    private
    
    # Extends existing rules
    def extend_rules(appender, block)
      @appender = appender
      block.call(self)
      self
    end
    
    #
    # Yields each rule in turn (upons, coercions then fallbacks)
    #
    def each_rule(&proc)
      @upons.each(&proc)
      @rules.each(&proc)
      @fallbacks.each(&proc)
    end
    
    #
    # Calls converter on a (value,target_domain) pair.
    # 
    def convert(value, target_domain, converter)
      if converter.respond_to?(:call)
        converter.call(value, target_domain)
      elsif converter.is_a?(Array)
        path = converter + [target_domain]
        path.inject(value){|cur,ndom| coerce(cur, ndom)}
      else
        raise ArgumentError, "Unable to use #{converter} for coercing"
      end
    end
    
  end # class Coercions
    
  # Myrrha main options
  OPTIONS = {
    :core_ext => false
  }
  
  # Install core extensions?
  def self.core_ext?
    OPTIONS[:core_ext]
  end
  
end # module Myrrha
require "myrrha/version"
require "myrrha/loader"