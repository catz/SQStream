# em-hiredis causes some problems

# require 'em-synchrony/em-hiredis'

# config['redis'] = EventMachine::Synchrony::ConnectionPool.new(:size => 20) do
#   conn = EM::Hiredis::Client.connect('127.0.0.1', 6379) 
# end

require 'em-synchrony/em-redis'

config['redis'] = EventMachine::Synchrony::ConnectionPool.new(:size => 20) do
  conn = EM::Protocols::Redis.connect('127.0.0.1', 6379) 
end

environment(:development) do
  config['redis'].flushdb
end