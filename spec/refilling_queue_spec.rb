require 'spec_helper'

describe RefillingQueue do
  it "has a VERSION" do
    RefillingQueue::VERSION.should =~ /^[\.\da-z]+$/
  end
end
