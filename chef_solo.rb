#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#

set_default :chef_solo_path,       File.expand_path("../chef-solo/", File.dirname(__FILE__))
set_default :chef_solo_json,       "empty.json"
set_default :chef_solo_remote,     "~#{user}/chef"
set_default :chef_solo_command,    %Q{cd #{chef_solo_remote} && #{try_sudo} chef-solo --config #{chef_solo_remote}/solo.rb --json-attributes }
set_default :chef_solo_bootstrap_skip, false

namespace :chefsolo do

  desc <<-EOF
   Run chef-solo deploy on the remote server.

   Task needs chef-solo repository git@github.com:dmytro/chef-solo.git
   installed as git submodule or directory.

   Configuration and defaults
   --------------------------

    * set :chef_solo_path, <PATH>

      Local PATH to the directory where, chef-solo is installed. By
      default searched in ../chef-solo/

    * set :chef_solo_json, "empty.json"

      JSON configuration for Chef solo to deploy. Defaults to
      empty.json

    * set :custom_chef_solo, File.expand_path (...)

      Full path to the directory with custom chef-solo configuration.
      If set recipe will copy custom configuration to the remote host
      into the same directory where chef-solo is installed, therefore
      adding or overwriting files in chef-solo repository.

      Default: not set

    * set_default :chef_solo_remote,     "~/chef"

      Remote location where chef-solo is installed. By default in
      ~/chef directory of remote user.

    * set_default :chef_solo_command, \\
      %Q{cd #{chef_solo_remote} && #{try_sudo} chef-solo --config #{chef_solo_remote}/solo.rb --json-attributes }

      Remote command to execute chef-solo.  Use it as: `run
      chef_solo_command + 'empty.json'` in your recipes.

  Configuration
  -------------

  set `-S chef_solo_bootstrap_skip=true` to skip execution of this task.

  RVM
  -----

  In case chef-solo is not found or can't initiaize environment
  properly when used with sudo, use rvmsudo instead. You also
  prbably'd need to set rvmsudo_secure_path and PATH, some commands
  are failing when started from /usr/bin/env

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  set :sudo, 'rvmsudo'

  set :default_environment, {
      'rvmsudo_secure_path' => 1,
      'PATH' => '/usr/local/rvm/gems/ruby-2.0.0-p247/bin: \\
       /usr/local/rvm/gems/ruby-2.0.0-p247@global/bin:\\
       /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Source File #{path_to __FILE__}

EOF
  task :deploy do

    # Limit execution to only hosts in the list if list provided
    options = { shell: :bash, pty: true }
    options.merge! hosts: only_hosts if exists? :only_hosts


    unless exists?(:chef_solo_bootstrap_ran)
      upload_dir chef_solo_path, chef_solo_remote, exclude: %w{./.git ./tmp}, options: options

      if exists?(:custom_chef_solo) && Dir.exists?(custom_chef_solo)
        upload_dir custom_chef_solo, chef_solo_remote, exclude: %w{./.git ./tmp}, options: options
      end

      l_sudo = sudo               # Hack to use actual sudo locally. In other places - use rvmsudo.
      set :sudo, "sudo"

      sudo "bash #{chef_solo_remote}/install.sh #{chef_solo_json}", options

      set :sudo, l_sudo
      set :chef_solo_bootstrap_ran, true # Make sure that deploy of chef-solo never runs twice
    end


  end

  desc "Run chef-solo command remotely. Specify JSON file as: -s json=<file>"
  task :run_remote do

    # Limit execution to only hosts in the list if list provided
    options = { shell: :bash, pty: true }
    options.merge! hosts: only_hosts if exists? :only_hosts

    run chef_solo_command + (json ? json : "empty.json")
  end

end

before "deploy", "chefsolo:deploy" unless fetch(:chef_solo_bootstrap_skip, true)
