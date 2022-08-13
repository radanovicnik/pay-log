# Starting program

require 'yaml'
require 'sequel'
require 'sqlite3'
require 'require_all'
require 'deep_merge'
require 'colorize'
require 'logger'
require 'readline'
require 'bigdecimal'
require 'bigdecimal/util'
require 'fileutils'
require 'pp'


config_tmp = {}
begin
  config_tmp = YAML.load_file 'config/default.yml'
rescue StandardError => e
  STDERR.puts(
    "Default configuration file missing (config/default.yml)!\n" +
    "[#{e.class}] #{e.message} - #{e.backtrace[0]}"
  )
  exit false
end

if File.exist? 'config/custom.yml'
  begin
    config_tmp.deep_merge!(YAML.load_file('config/custom.yml'))
  rescue StandardError => e
    puts 'Custom configuration file (config/custom.yml) is missing. Using default options.'
  end
end
CONFIG = config_tmp

%w(logs db/data db/backups).each do |dir|
  FileUtils.mkdir_p(dir) unless File.exist?(dir)
end

$db_modified = false

begin
  DB = Sequel.sqlite(
    File.join(CONFIG[:database][:dir], CONFIG[:database][:file]),
    readonly: CONFIG[:database][:readonly],
    foreign_keys: CONFIG[:database][:foreign_keys],
    case_sensitive_like: CONFIG[:database][:case_sensitive_like]
  )
rescue StandardError => e
  STDERR.puts(
    "Couldn't connect to database!\n" + 
    "[#{e.class}] #{e.message} - #{e.backtrace[0]}"
  )
  exit false
end
DB.loggers << Logger.new(
  CONFIG[:db_log][:path],
  CONFIG[:db_log][:files_count],
  CONFIG[:db_log][:file_size]
)
DB.loggers << Logger.new(STDOUT) if CONFIG[:db_log][:log_to_stdout]

START_TIME = Time.now.freeze
CURRENCIES = DB[:currencies].all.map{|c| c[:name]}.freeze
DEFAULT_PROMPT = 'pay_log> '.freeze
DEFAULT_UNKNOWN_ACCOUNT = 'other'.freeze
DEFAULT_PAGE_SIZE = CONFIG[:list_page_size]
MAX_CHOICES = CONFIG[:max_choices]
