require 'refilling_queue/version'

class RefillingQueue
  class Locked < RuntimeError
  end

  DEFAULT_OPTIONS = {
    :lock_timeout => 60,
    :refresh_every => nil,
    :paginate => false
  }

  def initialize(client, name, options={}, &block)
    @client, @name, @block = client, name, block
    @page_name = name + "/page"
    @options = DEFAULT_OPTIONS.merge(options)
    raise "Invalid keys" if (options.keys - DEFAULT_OPTIONS.keys).any?
  end

  def pop
    item = _pop
    return item unless item.nil?
    refill
    _pop
  end

  def clear
    lock do
      mark_as_empty
      @client.del @name
    end
  end

  private

  def paginate?
    @options[:paginate]
  end

  def _pop
    @client.lpop @name
  end

  def refill
    lock do
      _refill
    end
  end

  def _refill
    results = if paginate?
      page = (@client.get(@page_name) || 0).to_i
      @block.call(page + 1)
    else
      @block.call
    end
    if results.empty?
      mark_as_empty
      return
    end

    @client.pipelined do
      @client.del @name
      @client.rpush @name, results
      @client.expire @name, @options[:refresh_every] if @options[:refresh_every]
      if paginate?
        @client.incr @page_name
        @client.expire @page_name, @options[:refresh_every] if @options[:refresh_every]
      end
    end
  end

  def empty?
    @client.llen(@name) == 0
  end

  def mark_as_empty
    @client.del @page_name if paginate?
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
