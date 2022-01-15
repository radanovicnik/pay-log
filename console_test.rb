require_relative 'lib/initializers/start'
require_all 'lib/helpers'

require 'irb'
ARGV.clear

################
# Ruby console #
################
binding.irb

require_relative 'lib/initializers/end'
