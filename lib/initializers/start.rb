# Starting program

require 'yaml'
require 'sequel'
require 'sqlite3'
require 'require_all'
require 'logger'
require 'readline'
require 'bigdecimal'
require 'bigdecimal/util'
require 'pp'

begin
  CONFIG = YAML.load_file('config.yml')
rescue Exception => e
  STDERR.puts "Config file missing (config.yml)!\n#{e.full_message}"
  exit false
end

begin
  DB = Sequel.sqlite(CONFIG[:database][:path])
rescue Exception => e
  STDERR.puts "Couldn't connect to database!\n#{e.full_message}"
  exit false
end
# DB.loggers << Logger.new($stdout)

CURRENCIES = DB[:currencies].all.map{|c| c[:name]}.freeze
DEFAULT_PROMPT = 'pay_log> '.freeze
