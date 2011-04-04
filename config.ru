
require 'tangle'
require 'rack/reloader'


use Rack::Reloader
run Tangle
