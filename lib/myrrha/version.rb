module Myrrha
  module Version

    MAJOR = 3
    MINOR = 0
    TINY  = 1

    def self.to_s
      [ MAJOR, MINOR, TINY ].join('.')
    end

  end
  VERSION = Version.to_s
end
