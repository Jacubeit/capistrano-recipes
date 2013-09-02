set_default(:unicorn_user) { user }
set_default(:unicorn_pid) { "#{current_path}/tmp/pids/unicorn.pid" }
set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
set_default(:unicorn_log) { "#{shared_path}/log/unicorn.log" }
set_default(:unicorn_workers, 2)

namespace :unicorn do
  desc "Setup Unicorn initializer and app configuration"
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "unicorn.rb.erb", unicorn_config
    template "unicorn_init.erb", "/tmp/unicorn_init"
    run "chmod +x /tmp/unicorn_init"
    run "#{sudo} mv /tmp/unicorn_init /etc/init.d/unicorn_#{application}"
    run "#{sudo} update-rc.d -f unicorn_#{application} defaults"
  end
  after "deploy:setup", "unicorn:setup"

  desc "Destroy Unicorn configuration for this application"
  task :destroy_setup_for_one_app do
    removing_unicorn_setup = "remove /etc/init.d/unicorn_#{application}"
    if go_on? removing_unicorn_setup
      run "#{sudo} rm -rf /etc/init.d/unicorn_#{application}"
      puts "#{removing_unicorn_setup} -- Succesfully"
      run "#{sudo} update-rc.d -f unicorn_#{application} remove"
      puts "remove unicorn_#{application} from rc.d -- Succesfully"
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} unicorn"
    task command, roles: :app do
      run "service unicorn_#{application} #{command}"
    end
    after "deploy:#{command}", "unicorn:#{command}"
  end
end
