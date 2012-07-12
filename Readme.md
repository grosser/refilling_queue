A queue that refreshes itself when it gets empty or stale, so you can keep popping

Install
=======

    gem install refilling_queue

Usage
=====

    queue = RefillingQueue.new resque_client, "my_queue", :refresh_every => 30.seconds do
      expensive_operation.map(&:id)
    end

    begin
      queue.pop
    rescue
      RefillingQueue::EmptyRefill # queue was empty, refilled but is still empty
    end

    queue.pop -> return id
    ... # queue empty ?
    queue.pop -> run block -> store new ids -> return id
    ... # 30 seconds elapsed (global expires_at stored in reque_client) ?
    queue.pop -> run block -> store new ids -> return id

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/refilling_queue.png)](http://travis-ci.org/grosser/refilling_queue)
