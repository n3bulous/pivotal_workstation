#http://solutions.treypiepmeier.com/2010/02/28/installing-mysql-on-snow-leopard-using-homebrew/

DEFAULT_PIVOTAL_MYSQL_PASSWORD = "password"

include_recipe "pivotal_workstation::homebrew"

run_unless_marker_file_exists("mysql_" + marker_version_string_for("homebrew")) do
  brew_install("mysql", true)

  directory "/Users/#{WS_USER}/Library/LaunchAgents" do
    owner WS_USER
    action :create
  end

  execute "copy mysql plist to ~/Library/LaunchAgents" do
    command "cp `brew --prefix mysql`/com.mysql.mysqld.plist #{WS_HOME}/Library/LaunchAgents/"
    user WS_USER
  end

  execute "mysql_install_db" do
    command "mysql_install_db --verbose --user=#{WS_USER} --basedir=\"$(brew --prefix mysql)\" --datadir=/usr/local/var/mysql --tmpdir=/tmp"
    user WS_USER
  end

  execute "load the mysql plist into the mac daemon startup thing" do
    command "launchctl load -w #{WS_HOME}/Library/LaunchAgents/com.mysql.mysqld.plist"
    user WS_USER
  end

  ruby_block "wait for mysql to come up" do
    block do
      Timeout::timeout(60) do
        until system("ls /tmp/mysql.sock")
          sleep 1
        end
      end
    end
  end

  execute "set the root password to the default" do
    command "mysqladmin -uroot password #{DEFAULT_PIVOTAL_MYSQL_PASSWORD}"
    not_if "mysql -uroot -p#{DEFAULT_PIVOTAL_MYSQL_PASSWORD} -e 'show databases'"
  end
end
