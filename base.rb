def template(from, to)
	erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
	put ERB.new(erb).result(binding), to
end

def set_default(name, *args, &block)
	set(name, *args, &block) unless exists?(name)
end

def go_on?(task)
	response = Capistrano::CLI.ui.ask "#{task} ! go on? type 'y':"
		if response == "y"
			true
		else
			exit
		end
end

namespace :deploy do
	desc "Install everything onto the server"
	task :install do
		run "#{sudo} apt-get -y update"
		run "#{sudo} apt-get -y install python-software-properties"
	end

	desc "creating the app_config"
	task :create_app_config, roles: :app do
		template "app_config.yml.erb", "#{shared_path}/config/app_config.yml"
	end
	after "postgresql:setup", "deploy:create_app_config"

	desc "symlinking the app_config.yml file into the latest release"
	task :symlink_app_config, roles: :app do
		run "ln -nfs #{shared_path}/config/app_config.yml #{release_path}/config/app_config.yml"
	end
	after "deploy:finalize_update", "deploy:symlink_app_config"

  desc "Uploads a robots.txt that mandates the site as off-limits to crawlers"
  task :block_robots, :roles => :app do
  		template "robots.txt.erb", "#{shared_path}/robots.txt"
		run "ln -nfs #{shared_path}/robots.txt #{release_path}/public/robots.txt"
  	end
  	after "deploy:symlink_app_config", "deploy:block_robots"
end

