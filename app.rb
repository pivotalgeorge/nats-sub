require 'sinatra'
require 'nats/client'

NATS_USER = ENV['NATS_USER']
NATS_PASS = ENV['NATS_PASS']
ROLE = ENV['ROLE']

CLIENT_CERT_PATH = "#{Dir.pwd}/certs/client.crt"
CLIENT_KEY_PATH = "#{Dir.pwd}/certs/client.key"
CA_PATH = "#{Dir.pwd}/certs/ca.crt"

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

def build_nats_options(host, port, subject)
  options = {
    :servers => [ "nats://#{NATS_USER}:#{NATS_PASS}@#{host}:#{port}" ],
  }
  if port == "4224"
    options[:tls] = {
      :private_key_file => CLIENT_KEY_PATH,
      :cert_chain_file  => CLIENT_CERT_PATH,
      :verify_peer => true,
      :ca_file => CA_PATH,
    }
  end
  options
end

get '/hello' do
  puts 'hi'
  STDERR.puts 'hello'
  return 'hi'
end

case ROLE
when 'pub', 'publish', 'PUB', 'PUBLISH'
  get '/publish/:host/:port/:subject' do |host, port, subject|
    options = build_nats_options(host, port, subject)
    NATS.start(options) do |nats|
      STDERR.puts "Publish: Connected to NATS at #{nats.connected_server}"
      nats.flush do
        nats.publish(subject, 'meow')
        STDERR.puts 'publishing!'
      end
    end
  end

when 'sub', 'subscribe', 'SUB', 'SUBSCRIBE'
  get '/subscribe/:host/:port/:subject' do |host, port, subject|
    options = build_nats_options(host, port, subject)
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
    STDERR.puts "unsubscribed"

    subscription_ids = []
  end

else
  STDERR.puts 'ROLE environment variable must be set. Going down'
  exit 2
end


get '/disconnect' do
  NATS.stop
  STDERR.puts "disconnected"
end

