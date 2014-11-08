A queue that refreshes itself when it gets empty or stale, so you can keep popping

Install
=======

```Bash
gem install refilling_queue
```

Usage
=====

```Ruby
queue = RefillingQueue.new redis_client, "my_queue", refresh_every: 30.seconds do
  expensive_operation.map(&:id)
end

begin
  queue.pop
rescue RefillingQueue::Locked
  # queue was empty, refilling failed because other process is already trying it
end

queue.pop -> return id
... # queue empty ?
queue.pop -> run block -> store new ids -> return id
... # 30 seconds elapsed (global expires_at stored in reque_client) ?
queue.pop -> run block -> store new ids -> return id
...
queue.pop -> run block -> empty result -> return nil
```

### Pagination
```
queue = RefillingQueue.new redis_client, "my_queue", refresh_every: 30.seconds, paginate: true do |page|
  expensive_operation(:page => page).map(&:id)
end

```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/refilling_queue.png)](https://travis-ci.org/grosser/refilling_queue)
