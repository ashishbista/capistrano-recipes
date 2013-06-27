# Runs +command+ as root invoking the command with su -c
# and handling the root password prompt.
#
#   surun "/etc/init.d/apache reload"
#   # Executes
#   # su - -c '/etc/init.d/apache reload'
#
# Methods sets :root_password attribute, so that this method is
# executed only once during the run.
#
def surun(command)
  password = Capistrano::CLI.password_prompt("root password: ")
  
  run("su - -c '#{command}'", :shell => :bash) do |channel, stream, output|
    channel.send_data("#{password}n") if output
  end
end
