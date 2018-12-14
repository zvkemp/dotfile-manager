require "dotfile_manager/version"
require "pry-byebug"

module DotfileManager
  class Error < StandardError; end

  require 'dotfile_manager/configurator'
  require 'dotfile_manager/rendering'
  require 'dotfile_manager/has_config_variable'
  require 'dotfile_manager/after_commit_hooks'
end
