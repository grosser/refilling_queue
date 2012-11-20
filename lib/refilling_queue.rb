require 'refilling_queue/version'

class RefillingQueue
  class Locked < RuntimeError
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
    item = _pop
    return item unless item.nil?
    refill
    _pop
  end

  private

  def _pop
    @client.lpop @name
  end

  def refill
    lock do
      results = @block.call
      return if results.empty?

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

  def lock
    lock = "#{@name}_lock"

    # transaction: prevent infinite lock when process dies immediately after setting lock
    acquired, _ = @client.multi do
      @client.setnx lock, "1"
      @client.expire lock, @options[:lock_timeout]
    end
    raise RefillingQueue::Locked unless [true, 1].include?(acquired)

    begin
      yield
    ensure
      @client.del lock, "1"
    end
  end
end
