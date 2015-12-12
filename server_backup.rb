require 'rubygems'
require 'net/ssh'

HOST = 'xxx.xxx.xxx.xxx'
USER = 'user'
PORT = 22
DATABASES_PATH = 'remote path to save databases'
HOME_PATH = 'remote path to save home folder'
MYSQL_ROOT_PASSWORD = 'pass'

today_folder = Time.now.strftime('%Y-%m-%d')

# First create folder to save databases
`mkdir -p /root/databases`

# Export all databases to folder
`mysql -uroot -p#{MYSQL_ROOT_PASSWORD} -e 'show databases' -N | grep -Ev 'information_schema|mysql' | while read dbname; do mysqldump -uroot -p#{MYSQL_ROOT_PASSWORD} "$dbname" > /root/databases/"$dbname".sql; done`

Net::SSH.start( HOST, USER, :port => PORT )  do |ssh|

  # Delete the oldest backup if are more than 3
  response = ssh.exec!("ls #{DATABASES_PATH}")

  unless response == nil
    current_files = response.split(' ')
    if current_files.size > 2
      ssh.exec!("rm -rf #{DATABASES_PATH}/#{current_files.first}")
    end
  end

  # Create today's databases backup folder
  ssh.exec!("mkdir #{DATABASES_PATH}/#{today_folder}")

end

# Copy all databases to remote host
`rsync -az -e "ssh -p #{PORT}" /root/databases/ #{USER}@#{HOST}:#{DATABASES_PATH}/#{today_folder}`


# Delete folder
`rm -rf /root/databases`

# Sync the /home folder
`rsync -az -e "ssh -p #{PORT}" /home #{USER}@#{HOST}:#{HOME_PATH}`
