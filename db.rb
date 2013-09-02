require "bundler/capistrano"

namespace :db do
  require 'yaml'

  desc "Copy the remote production database to the local development database NOTE: postgreSQL specific"
  task :pg_backup_production, :roles => :db, :only => { :primary => true } do
    # First lets get the remote database config file so that we can read in the database settings
    tmp_db_yml = "tmp/database.yml"
    get("#{shared_path}/config/database.yml", tmp_db_yml)

    # load the production settings within the database file
    db = YAML::load_file("tmp/database.yml")["production"]
    run_locally("rm #{tmp_db_yml}")
   
    filename = "#{application}_production.dump.#{Time.now.to_i}.sql.bz2"
    file = "/tmp/#{filename}"
    on_rollback {
      run "rm #{file}"
      run_locally("rm #{tmp_db_yml}")
    }
    run "pg_dump --clean --no-owner --no-privileges -U#{db['username']} -h localhost #{db['database']} | bzip2 > #{file}" do |ch, stream, out|
      ch.send_data "#{db['password']}\n" if out =~ /^Password:/
      puts out
    end
    run_locally "mkdir -p -v '#{File.dirname(__FILE__)}/../../db/backups/'"
    get file, "#{File.dirname(__FILE__)}/../../db/backups/#{filename}"
    run "rm #{file}"
  end

  desc "Copy the remote production database to the drob_box NOTE: postgreSQL specific"
  task :pg_backup_production_to_dropbox, :roles => :db, :only => { :primary => true } do
    # First lets get the remote database config file so that we can read in the database settings
    tmp_db_yml = "tmp/database.yml"
    get("#{shared_path}/config/database.yml", tmp_db_yml)

    # load the production settings within the database file
    db = YAML::load_file("tmp/database.yml")["production"]
    run_locally("rm #{tmp_db_yml}")
   
    filename = "#{application}_production.dump.#{Time.now.to_i}.sql.bz2"
    file = "/tmp/#{filename}"
    on_rollback {
      run "rm #{file}"
      run_locally("rm #{tmp_db_yml}")
    }
    run "pg_dump --clean --no-owner --no-privileges -U#{db['username']} -h localhost #{db['database']} | bzip2 > #{file}" do |ch, stream, out|
      ch.send_data "#{db['password']}\n" if out =~ /^Password:/
      puts out
    end
    #make Date
    dropbox_folder = "#{File.dirname(__FILE__)}/../../../../dropbox/backup_db/#{Date.today.strftime('%Y_%m_%d')}"
    run_locally "mkdir -p -v '#{dropbox_folder}'"
    get file, "#{dropbox_folder}/#{filename}"
    run "rm #{file}"
  end

  desc "Copy the latest backup to the local development database NOTE: postgreSQL specific"
  task :pg_import_backup do
    filename = `ls -tr db/backups | tail -n 1`.chomp
    if filename.empty?
      logger.important "No backups found"
    else
      ddb = YAML::load_file("config/database.yml")["development"]
      logger.debug "Loading db/backups/#{filename} into local development database"
      run_str = "bzcat db/backups/#{filename} | psql -U #{ddb['username']} #{ddb['database']}"
      %x!#{run_str}!
      logger.debug "command finished"
    end
  end

  desc "Backup the remote production database and import it to the local development database NOTE: postgreSQL specific"
  task :pg_backup_and_import_from_production do
    pg_backup_production
    pg_import_backup
  end

  desc "Backup the local development database to the backup folder NOTE: postgreSQL specific"
  task :pg_backup_local do
    ddb = YAML::load_file("config/database.yml")["development"]
    filename = "db/backups/#{application}_local.dump.#{Time.now.to_i}.sql.bz2"
    logger.debug "Backing up #{filename} on local development"
    run_locally "pg_dump --clean --no-owner --no-privileges -U #{ddb['username']} #{ddb['database']} | bzip2 > #{filename}" do |ch, stream, out|
      puts out
    end
    logger.debug "command finished"
  end

  desc "Copy the lastest backup database and push to the remote production database"
  task :pg_export_backup, :roles => :db, :only => { :primary => true } do
    filename = `ls -tr db/backups | tail -n 1`.chomp
    file = "db/backups/#{filename}"
    # First lets get the remote database config file so that we can read in the database settings
    tmp_db_yml = "tmp/database.yml"
    get("#{shared_path}/config/database.yml", tmp_db_yml)

    # load the production settings within the database file
    db = YAML::load_file("tmp/database.yml")["production"]
    run_locally("rm #{tmp_db_yml}")

    on_rollback {   
      run_locally("rm #{tmp_db_yml}")
      run("rm /tmp/#{filename}")
    }
    upload file, "/tmp/#{filename}"
    run "bzcat /tmp/#{filename} | psql -U #{db['username']} -d #{db['database']} -h #{db['host']}" do |ch, stream, out|
      ch.send_data "#{db['password']}\n" if out =~ /^Password.*:/
      puts out
    end

    run("rm /tmp/#{filename}")
  end

  desc "Backup the local development database and export it to the production database NOTE: postgreSQL specific"
  task :pg_backup_and_export_to_production do
    pg_backup_local
    pg_export_backup
  end
end