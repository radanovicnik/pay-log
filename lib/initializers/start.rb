# Starting program

require 'yaml'
require 'sequel'
require 'sqlite3'
require 'require_all'
require 'deep_merge'
require 'logger'
require 'readline'
require 'bigdecimal'
require 'bigdecimal/util'
require 'pp'


config_tmp = {}
begin
  config_tmp = YAML.load_file 'config/default.yml'
rescue StandardError => e
  STDERR.puts "Default configuration file missing (config/default.yml)!\n#{e.full_message}"
  exit false
end

if File.exist? 'config/custom.yml'
  begin
    config_tmp = config_tmp.deep_merge(YAML.load_file('config/custom.yml'))
  rescue StandardError => e
    STDERR.puts 'Unable to read custom config file (config/custom.yml).'
  end
end
CONFIG = config_tmp

Dir.mkdir('logs') unless File.exist?('logs')

begin
  DB = Sequel.sqlite(
    CONFIG[:database][:path],
    readonly: CONFIG[:database][:readonly],
    foreign_keys: CONFIG[:database][:foreign_keys],
    case_sensitive_like: CONFIG[:database][:case_sensitive_like]
  )
rescue StandardError => e
  STDERR.puts "Couldn't connect to database!\n#{e.full_message}"
  exit false
end
DB.loggers << Logger.new('logs/db.log', 5, 5120)
# DB.loggers << Logger.new(STDOUT)

CURRENCIES = DB[:currencies].all.map{|c| c[:name]}.freeze
DEFAULT_PROMPT = 'pay_log> '.freeze
DEFAULT_UNKNOWN_ACCOUNT = 'other'.freeze
DEFAULT_PAGE_SIZE = 5
