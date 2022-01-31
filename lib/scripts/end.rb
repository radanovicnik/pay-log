# Finishing program

File.write(
  File.join(CONFIG[:database][:dir], 'db_stats.json'),
  JSON.pretty_generate($db_stats)
)

DB.run('VACUUM') if $db_stats[:modified]
DB.disconnect
