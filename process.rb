
require 'rubygems'
require 'redis'
require 'json'


#
# utility program for loading st9 jetty request logs into redis
#
# USAGE: ruby process.rb jetty-ABC.log jetty-DEF.log ...
#

redis = Redis.new(:db => 10)  # use db 10 to avoid conflicts...
redis.flushdb                 # clear the db before starting...

ARGV.each do |f|
  open(f).each do |m|
    o = JSON(m)
    next unless o['o'] # ignore rows without an 'original' request uuid

    u = o['r']         # the st9 request uuid
    x = o['o']         # the original request id
    t = o['t'].to_i    # server request time in nanos
    z = o['z'].to_i    # response size in bytes

    redis.pipelined do
      redis[u] = m           # store this row's data in redis
      redis[x] = u           # store an originating uuid -> request id map (used to get original url)

      # originating request stats
      redis.incrby("count:" + x, 1)
      redis.incrby("time:" + x, t)
      redis.incrby("size:" + x, z)
      redis.rpush("req:" + x, u)

      # SCOREBOARD
      redis.zincrby("all_count", 1, x)
      redis.zincrby("all_time", t, x)
      redis.zincrby("all_size", z, x)
    end
  end
end