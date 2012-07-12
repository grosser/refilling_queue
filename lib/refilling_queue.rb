require 'refilling_queue/version'

class RefillingQueue
  class EmptyRefill < RuntimeError
  end

  DEFAULT_OPTIONS = {
    :lock_timeout => 60,
    :refresh_every => nil
  }

  def initialize(client, name, options={}, &block)
    @client, @name, @block = client, name, block
    @options = DEFAULT_OPTIONS.merge(options)
    raise "Invalid keys" if (options.keys - DEFAULT_OPTIONS.keys).any?
  end

  def pop
    item = @client.lpop @name
    return item unless item.nil?

    refill

    item = @client.lpop @name
    return item unless item.nil?

    raise RefillingQueue::EmptyRefill
  end

  def refill
    lock do
      results = @block.call
      @client.pipelined do
        @client.del @name
        results.each{ |r| @client.rpush @name, r } # TODO https://github.com/redis/redis-rb/issues/253
        @client.expire @name, @options[:refresh_every] if @options[:refresh_every]
      end
    end
  end

  def empty?
    @client.llen(@name) == 0
  end

  private

  def lock
    lock = "#{@name}_lock"
    return unless @client.setnx lock, "1"
    @client.expire lock, @options[:lock_timeout]
    begin
      yield
    ensure
      @client.del lock, "1"
    end
  end
end
