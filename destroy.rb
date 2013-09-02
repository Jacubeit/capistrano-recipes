namespace :destroy do
	desc "Destroying a full APP !!!"
	task :one_app do
		response = Capistrano::CLI.ui.ask "Are you shure you want to destroy '#{application}'? type the name of the application :"
		if response == "#{application}"
			remove_path = "remove /home/#{user}/apps/#{response}"
			go_on? remove_path
			run "#{sudo} rm -rf /home/#{user}/apps/#{response}"
			puts "#{remove_path} SUCCESSFULL"
		else
			puts "exit"
			exit
		end
	end
	after "destroy:one_app", "nginx:destroy_setup_for_one_app"
	after "destroy:one_app", "unicorn:destroy_setup_for_one_app"
	after "destroy:one_app", "postgresql:drop_db_for_this_app"
end