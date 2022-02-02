require_relative 'lib/scripts/start'
require_all 'lib/classes'

require 'irb'
ARGV.clear

################
# Ruby console #
################
binding.irb

require_relative 'lib/scripts/end'
