require 'spec_helper'
require 'fakeredis'

describe RefillingQueue do
  def kill_all_threads
    Thread.list.each {|thread| thread.exit unless thread == Thread.current }
  end

  let(:client){ FakeRedis::Redis.new }

  before do
    kill_all_threads
  end

  it "has a VERSION" do
    RefillingQueue::VERSION.should =~ /^[\.\da-z]+$/
  end

  context "#initialize" do
    it "does not fill itself when started full" do
      x = 0
      RefillingQueue.new(client, "x"){ x = 1 }
      x.should == 0
    end
  end

  context "#pop" do
    it "removes an element" do
      queue = RefillingQueue.new(client, "x"){ [1,2,3,4] }
      queue.pop.should == 1
      queue.pop.should == 2
      queue.pop.should == 3
    end

    it "only tries to refill once" do
      calls = []
      RefillingQueue.new(client, "x"){ calls << 1; [] }.pop.should == nil
      calls.should == [1]
    end

    it "refills itself if queue gets empty" do
      content = [1]
      queue = RefillingQueue.new(client, "x"){ content }
      queue.pop.should == 1
      content.replace [4,5]
      queue.pop.should == 4
      queue.pop.should == 5
      queue.pop.should == 4
    end

    it "refills itself when it expires" do
      content = [1,2,3]
      queue = RefillingQueue.new(client, "x", :refresh_every => 0.1){ content }

      queue.pop.should == 1
      content.replace [4,5]
      queue.pop.should == 2
      sleep 0.5

      queue.pop.should == 4
    end
  end

  context "with multiple actors" do
    it "only refills once" do
      called = []

      # lock-blocker
      Thread.new do
        RefillingQueue.new(client, "x"){ sleep 0.2; called << 1; [] }.pop
      end
      sleep 0.1

      # blocked
      locked = false
      Thread.new do
        queue = RefillingQueue.new(client, "x"){ sleep 0.2; called << 1; [] }
        begin
          queue.pop
        rescue RefillingQueue::Locked
          locked = true
        end
      end
      sleep 0.3

      called.should == [1]
      locked.should == true
    end

    it "can refill after refill is complete" do
      called = []
      RefillingQueue.new(client, "x"){ called << 1; [1] }.pop
      RefillingQueue.new(client, "x"){ called << 2; [1] }.pop
      called.should == [1,2]
    end

    it "can refill if lock expired" do
      called = []
      RefillingQueue.new(client, "x", :lock_timeout => 1){ called << 1; [1] }.pop
      Thread.new do
        # lock-blocker
        RefillingQueue.new(client, "x", :lock_timeout => 1){ sleep 2; called << 2; [1] }.pop
      end
      sleep 1.5
      RefillingQueue.new(client, "x", :lock_timeout => 1){ called << 3; [1] }.pop
      called.should == [1,3]
    end
  end
end
