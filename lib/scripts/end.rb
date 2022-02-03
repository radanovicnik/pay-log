# Finishing program

DB.run('VACUUM') if $db_modified
DB.disconnect

if CONFIG[:on_android]
  `am broadcast --user 0 -a com.termux.PAY-LOG_FINISHED --ez modified #{$db_modified}`
end
