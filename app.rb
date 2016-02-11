require 'sinatra/base'

class Builder < Sinatra::Application
  get '/' do
    'sup'
  end
end
