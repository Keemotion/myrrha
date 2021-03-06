require 'date'
require 'myrrha/with_core_ext'
require 'myrrha/to_ruby_literal'

require 'date'
require 'myrrha/with_core_ext'
require 'myrrha/to_ruby_literal'

1.to_ruby_literal                       # => "1"      
Date.today.to_ruby_literal              # => "Marshal.load('...')"
["hello", Date.today].to_ruby_literal   # => "['hello', Marshal.load('...')]"

(1..10).to_ruby_literal                 # => "1..10"

today = Date.today
(today..today+1).to_ruby_literal        # => "Marshal.load('...')"
