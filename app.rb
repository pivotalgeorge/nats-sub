require 'sinatra'
require 'nats/client'

nats_user = ENV['NATS_USER']
nats_pass = ENV['NATS_PASS']

client_cert_path = "#{Dir.pwd}/certs/client.crt"
client_key_path = "#{Dir.pwd}/certs/client.key"
ca_path = "#{Dir.pwd}/certs/ca.crt"

subscription_ids = []

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

get '/publish/:host/:port/:subject' do |host, port, subject|
  options = {
    :servers => [ "nats://#{nats_user}:#{nats_pass}@#{host}:#{port}" ],
  }

  if port == "4224"
    options[:tls] = {
      :private_key_file => client_key_path,
      :cert_chain_file  => client_cert_path,
      :verify_peer => true,
      :ca_file => ca_path,
    }
  end

  NATS.start(options) do |nats|
    STDERR.puts "Publish: Connected to NATS at #{nats.connected_server}"
     nats.flush do
       nats.publish(subject, "meow")
       STDERR.puts "publishing!"
     end

  end
end


get '/subscribe/:host/:port/:subject' do |host, port, subject|
  options = {
    :servers => [ "nats://#{nats_user}:#{nats_pass}@#{host}:#{port}" ],
  }

  if port == "4224"
    options[:tls] = {
      :private_key_file => client_key_path,
      :cert_chain_file  => client_cert_path,
      :verify_peer => true,
      :ca_file => ca_path,
    }
  end

  NATS.start(options) do |nats|
    STDERR.puts "Subscribe: Connected to NATS at #{nats.connected_server}"

    sid = nats.subscribe(subject) do |msg|
      STDERR.puts "Received from #{host}:#{port}: #{msg}"
    end

    subscription_ids.push(sid)

  end

end

get '/unsubscribe' do
  subscription_ids.each do |sid|
    NATS.unsubscribe(sid)
  end

  subscription_ids = []
end
