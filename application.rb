
require 'rubygems'
require 'sinatra'
require 'redis'
require 'json'

R = Redis.new(:db => 10)

#
# get rollup data for a given stats key ("all_count", "all_size", etc)
#
#   stats keys are stored in a sorted collection where score is the stat
#   like request count, request time etc
#
#   stat values are originating request identifiers
#
def get_rollup_data(key, start = "0", num = "100")

  ids = R.zrevrange(key, start.to_i, start.to_i + num.to_i)
  
  data = []
  shown = {}

  ids.each do |id|
    q = R.get(id)
    o = R.get(q)
    oo = JSON(o)
    f = oo['f']

    c = R.get("count:" + id)
    t = R.get("time:" + id)
    z = R.get("size:" + id)
    
    data << {
      :id => id,
      :url   => f,
      :count => c.to_i,
      :time_ms  => t.to_f / 1000000.0,
      :size_bytes  => z.to_i,
      :show_more => "http://localhost:4567/o/#{id}"
    }
  end
  
  data.to_json
end

#
# get detail data for a given originating request uuid
#
#   detail requests are stored in a redis list
#
def get_detail_data(key, start = "0", num = "1000")
  ids = R.lrange("req:" + key, start.to_i, start.to_i + num.to_i)
  
  data = []
  ids.each do |id|
    o = R.get(id)
    oo = JSON(o)
    t = oo['t']
    z = oo['z']

    data << {
      :id => id,
      :url   => oo['u'],
      :time_ms  => t.to_f / 1000000.0,
      :size_bytes  => z.to_i,
      :show_more => "http://localhost:4567/u/#{id}"
    }
  end
  
  # data.sort{|x,y| y[:time] <=> x[:time] }.to_json
  data.to_json
end

#
# get detail data for a given request uuid
#
#    (this is the data corresponding to an actual log entry)
#
def get_request_data(key)
  o = R.get(key)
  oo = JSON(o)
  t = oo['t']
  z = oo['z']
    
  {
    :id => key,
    :url   => oo['u'],
    :time_ms  => t.to_f / 1000000.0,
    :size_bytes  => z.to_i,
    :return => "http://localhost:4567/o/#{oo['o']}"
  }.to_json
end

#
# A bare-bones webapp for displaying json request data
#
class Webapp < Sinatra::Base
  get '/' do
    redirect to('/by_count')
  end

  get '/by_count' do
    get_rollup_data("all_count", params["s"] || "0", params["n"] || "100")
  end

  get '/by_time' do
    get_rollup_data("all_time", params["s"] || "0", params["n"] || "100")
  end

  get '/by_size' do
    get_rollup_data("all_size", params["s"] || "0", params["n"] || "100")
  end

  get '/o/:id' do
    get_detail_data(params['id'])
  end

  get '/u/:id' do
    get_request_data(params['id'])
  end

  run! if app_file == $0
end
