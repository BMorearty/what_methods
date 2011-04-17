# Some credits:
# Code this verions is based on: Andrew Birkett
#   http://www.nobugs.org/developer/ruby/method_finder.html
# Improvements from Why's blog entry
# * what? == - Why
# * @@blacklist - llasram
# * clone alias - Daniel Schierbeck
# * $stdout redirect - Why
#   http://redhanded.hobix.com/inspect/stickItInYourIrbrcMethodfinder.html
# Improvements from Nikolas Coukouma
# * Varargs and block support
# * Improved catching
# * Redirecting $stdout and $stderr (independently of Why)
#   http://atrustheotaku.livejournal.com/339449.html
#
# A version posted in 2002 by Steven Grady:
#   http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/32844
# David Tran's versions:
# * Simple
#   http://www.doublegifts.com/pub/ruby/methodfinder.rb.html
# * Checks permutations of arguments
#   http://www.doublegifts.com/pub/ruby/methodfinder2.rb.html
#
# Last updated: 2006/05/20

class Object
  def what?(*a)
    WhatMethods::MethodFinder.show(self, *a)
  end
  alias_method :__clone__, :clone
  def clone
    __clone__
  rescue TypeError
    self
  end
end

class DummyOut
  def write(*args)
  end
end

module WhatMethods
  class MethodFinder
    @@blacklist = %w(daemonize display exec exit! fork sleep system syscall what? ed emacs mate nano vi vim)
    
    def initialize( obj, *args )
      @obj = obj
      @args = args
    end
    def ==( val )
      MethodFinder.show( @obj, val, *@args )
    end
    
    # Find all methods on [anObject] which, when called with [args] return [expectedResult]
    def self.find( anObject, expectedResult, *args, &block )
      stdout, stderr = $stdout, $stderr
      $stdout = $stderr = DummyOut.new
      # change this back to == if you become worried about speed and warnings.
      res = anObject.methods.
            select { |name| anObject.method(name).arity <= args.size }.
            select { |name| not @@blacklist.include? name }.
            select { |name| begin 
                     anObject.clone.method( name ).call( *args, &block ) == expectedResult; 
                     rescue Object; end }
      $stdout, $stderr = stdout, stderr
      res
    end
    
    # Pretty-prints the results of the previous method
    def self.show( anObject, expectedResult, *args, &block)
      find( anObject, expectedResult, *args, &block).each { |name|
        print "#{anObject.inspect}.#{name}" 
        print "(" + args.map { |o| o.inspect }.join(", ") + ")" unless args.empty?
        puts " == #{expectedResult.inspect}" 
      }
    end
  end
end
