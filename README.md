St9 Log Analysis Tool, version 0.1

PREREQUISITES

* gem install (json, sinatra, redis)
* Chrome with a good json view plugin (such as JSONview)

USAGE

* Make sure your local redis instance is running, and that it's ok to blow away db 10
* Find some st9 logs somewhere (they generally have a name like jetty-hostname-2012_02_14.request.log)
* ruby process.rb jetty-hostname-2012_02_14.request.log jetty-hostname-2012_02_15.request.log ...
* ruby application.rb
* open a chrome browser window to http://localhost:4567/by_count
* click on show_more links to see more details

EXTRAS

* http://localhost:4567/by_time is a view of requests by aggregate time (note, doesn't include client-perceived latency)
* http://localhost:4567/by_size is a view of requests by aggregate size
* add &s=start_offset url parameter to page through the urls
* add &n=page_size url parameter to see more results
