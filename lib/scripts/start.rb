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
require 'json'
require 'fileutils'
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
    config_tmp.deep_merge!(YAML.load_file('config/custom.yml'))
  rescue StandardError => e
    STDERR.puts 'Unable to read custom config file (config/custom.yml).'
  end
end
CONFIG = config_tmp

%w(logs db/data).each do |dir|
  FileUtils.mkdir_p(dir) unless File.exist?(dir)
end

db_stats_file = File.join(CONFIG[:database][:dir], 'db_stats.json')
$db_stats = {modified: false}
if File.exist? db_stats_file
  $db_stats = JSON.parse(File.read(db_stats_file), symbolize_names: true)
else
  File.write(db_stats_file, JSON.pretty_generate($db_stats))
end

$db_stats[:modified] = false

begin
  DB = Sequel.sqlite(
    File.join(CONFIG[:database][:dir], CONFIG[:database][:file]),
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
