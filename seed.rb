namespace :deploy do
	desc "reload the database with seed data"
	task :seed do
		run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=#{rails_env}"
	end

	desc "reset the db"
	task :reset_database do
		run "cd #{current_path}; bundle exec rake db:reset RAILS_ENV=#{rails_env}"
	end
end