if Rails.env.development?
  require 'localtunnel'
  namespace :lt do
    pid_file_path = 'tmp/pids/localtunnel.pid'
    lt_subdomain = Rails.application.credentials.config[:localtunnel][:subdomain]
    lt_port = Rails.application.credentials.config[:localtunnel][:port]
  
    desc "Start the localtunnel."
    task :start => :environment do
      if File.exist?(pid_file_path)
        puts "LocalTunnel is already running. Please stop the current process before starting a new one."
      else
        puts "Starting LocalTunnel..."
        Process.spawn("lt --port #{lt_port} --subdomain #{lt_subdomain}")
        sleep(2) # Give some time for the process to start
        File.write(pid_file_path, `pgrep -f 'lt --port #{lt_port} --subdomain #{lt_subdomain}'`.chomp)
        pid = File.read(pid_file_path).chomp
        puts "LocalTunnel has started. pid:#{pid}"
      end
    end
  
    desc "Stop the localtunnel."
    task :stop => :environment do
      if File.exist?(pid_file_path)
        pid = File.read(pid_file_path).chomp
        Process.kill('TERM', pid.to_i)
        File.delete(pid_file_path)
        puts "LocalTunnel has stopped."
      else
        puts "LocalTunnel is not running."
      end
    end
  
    desc "Clean the localtunnel pid file."
    task :clean => :environment do
      if File.exist?(pid_file_path)
        File.delete(pid_file_path)
        puts "The localtunnel pid file has been deleted."
      else
        puts "No localtunnel pid file found."
      end
    end
  
    desc "Check the status of localtunnel."
    task :status => :environment do
      if File.exist?(pid_file_path)
        pid = File.read(pid_file_path).chomp
        if system("ps -p #{pid} > /dev/null")
          puts "LocalTunnel is running with pid: #{pid}"
        else
          puts "LocalTunnel is not running, but pid file exists. You may need to run 'rails lt:clean'."
        end
      else
        puts "LocalTunnel is not running."
      end
    end
  end
end
