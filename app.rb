require 'sinatra'
require 'nats/client'

# Set default callbacks
NATS.on_error do |e|
  puts "Error: #{e}"
end

NATS.on_disconnect do |reason|
  puts "Disconnected: #{reason}"
end

NATS.on_reconnect do |nats|
  puts "Reconnected to NATS server at #{nats.connected_server}"
end

NATS.on_close do
  puts "Connection to NATS closed"
  EM.stop
end

get '/hello' do
  puts 'hi'
  STDERR.puts 'hello'
  return 'hi'
end

get '/connect/:host/:port/:subject' do |host, port, subject|

  options = {
    :servers => [
     "nats://nats:<PASSWORD>@#{host}:#{port}"
    ]
    # :tls => {
    #   :private_key_file => '/var/vcap/jobs/route_emitter/config/certs/nats/client.key',
    #   :cert_chain_file  => '/var/vcap/jobs/route_emitter/config/certs/nats/client.crt',
    #   :verify_peer => true,
    #   :ca_file => '/var/vcap/jobs/route_emitter/config/certs/nats/ca.crt'
    # }
  }

  NATS.start(options) do |nats|
    STDERR.puts "Connected to NATS at #{nats.connected_server}"

    nats.subscribe("*.*") do |msg|
      STDERR.puts "Received: #{msg}"
    end

  #  nats.flush do
  #    nats.publish("hello", "world")
  #  end
  end

end

