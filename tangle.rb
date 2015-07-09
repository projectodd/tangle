require "sinatra/base"
require "sinatra/reloader"
require "net/http"

require 'json/pure'
require 'yaml'

require 'pp'


class Tangle < Sinatra::Base

  register Sinatra::Reloader
  get '/' do
    "TorqueBox says 'hi'."
  end

  post '/' do
    if ( params[:token] != ENV['TANGLE_TOKEN'] )
      $stderr.puts "Invalid token: #{params[:token]}"
      return 404
    end

    payload = JSON params[:payload]
    #pp payload
    repo = payload['repository']['name']
    ref  = payload['ref']
    branch_name = nil
    if ( ref =~ %r(^refs/heads/(.*)$)  )
      branch_name = $1
    end

    config = YAML.load( File.read( File.dirname( __FILE__ ) + '/wiring.yml' ) )

    repo_config = config['repositories'][repo]
    if ( repo_config )
      branch_config = repo_config[branch_name]
      if ( branch_config )
        [ branch_config ].flatten.each do |trigger_url|
          dispatch_trigger( trigger_url )
        end
      end
    end
  end

  def dispatch_trigger(trigger_url)

    token = ENV['CLOUDBEES_TOKEN']

    token_part = ""

    if ( trigger_url =~ /\?/ )
      token_part = "&token=#{token}"
    else
      token_part = "?token=#{token}"
    end

    full_url = "#{trigger_url}#{token_part}"
    $stderr.puts "Dispatch #{full_url}"
    `curl -X POST '#{full_url}' --insecure --silent`
    $stderr.puts "Dispatch complete #{$?}"
  end

end
