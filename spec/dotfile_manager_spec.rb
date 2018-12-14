require 'spec_helper'

RSpec.describe DotfileManager do
  it "has a version number" do
    expect(DotfileManager::VERSION).not_to be nil
  end
end
