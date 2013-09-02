set_default(:port_and_default, "80 default deferred")
set_default(:only_playground, false)

namespace :nginx do
  desc "Install latest stable release of nginx"
  task :install, roles: :web do
    run "#{sudo} add-apt-repository ppa:nginx/stable"
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install nginx"
  end
  after "deploy:install", "nginx:install"

  desc "Setup nginx configuration for this application"
  task :setup, roles: :web do
    template "nginx_unicorn.erb", "/tmp/nginx_conf"
    run "#{sudo} mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
    run "#{sudo} rm -f /etc/nginx/sites-enabled/default"
    restart
  end
  after "deploy:setup", "nginx:setup"

  desc "Destroy nginx configuration for this application"
  task :destroy_setup_for_one_app do
    if go_on? "remove /etc/nginx/sites-enabled/#{application}"
      run "#{sudo} rm -rf /etc/nginx/sites-enabled/#{application}"
      puts "remove /etc/nginx/sites-enabled/#{application} -- Successfully"
    end
  end
  
  %w[start stop restart].each do |command|
    desc "#{command} nginx"
    task command, roles: :web do
      run "#{sudo} service nginx #{command}"
    end
  end
end