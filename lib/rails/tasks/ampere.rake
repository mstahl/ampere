namespace :ampere do
  desc "Flush ALL data out of Redis (only call this if you know what you're doing!)"
  task :flush do
    Redis.new.flushall
  end
  
end