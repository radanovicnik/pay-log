# Finishing program

# Closing database
if $db_modified
  DB.run('VACUUM')

  FileUtils.cp(
    File.join(CONFIG[:database][:dir], CONFIG[:database][:file]),
    File.join(
      'db', 'backups',
      File.basename(CONFIG[:database][:file], '.*') +
          '_' + START_TIME.strftime('%Y%m%d_%H%M%S') + '.db'
    )
  )
end
DB.disconnect

# Checking the number of backups
backups = Dir.glob('db/backups/*.db').sort
count_for_removal = backups.size - CONFIG[:max_db_backups]

if count_for_removal > 0
  backups.first(count_for_removal).each { |bkp| FileUtils.rm(bkp) }
end

# Sending FINISHED broadcast (on Android)
if CONFIG[:on_android]
  `am broadcast --user 0 -a com.termux.PAY-LOG_FINISHED --ez modified #{$db_modified}`
end
