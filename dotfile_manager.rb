require 'erb'
require 'yaml'
require 'bundler/inline'
require 'open3'

gemfile do
  gem 'pry-byebug'
end

require 'pry-byebug'

CONFIG = YAML.load <<~YAMLCONFIG
---
roles: &roles
  git:
    username: zvkemp
    email: zvkemp@gmail.com
  tmux: {}
  alacritty: {}
  # - nvim
  # - zsh
  # - prezto
variables: &variables
  git_username: zvkemp
  git_email: zvkemp@gmail.com
targets:
  mac:
    exclude_roles: []
    roles:
      <<: *roles
    variables:
      clipboard: pbcopy
    # add overrides like this:
    git:
      username: zvkemp
  manjaro:
    aliases:
      - linux
    exclude_roles: []
    roles:
      <<: *roles
      i3: {}
    variables:
      clipboard: xclip
  solus:
    variables:
      clipboard: xsel
    roles:
      <<: *roles
YAMLCONFIG

# scripts:
  # install nvim plugins
  # nvim -c PlugIns -c exit -c exit
class Configurator
  def initialize(target, mods_to_load = [])
    @target = target
    @config = CONFIG['targets'][target]
    @mods_to_load = mods_to_load

    process_config
  end

  attr_reader :target, :mod, :config

  def templates
    config['roles'].flat_map do |mod, _|
      next [] unless should_load?(mod)
      f = File.expand_path("./templates/#{mod}/*.erb")
      Dir[f].map do |template|
        Template.new(template, config: config, mod: mod, target: target)
      end
    end
  end

  def should_load?(mod)
    @mods_to_load.empty? || @mods_to_load.include?(mod)
  end

  def to_s
  end

  def write!
  end

  private

  def process_config
    old_roles = config['roles'] || {}
    exclude = config['exclude_roles'] || []
    config['roles'] = old_roles.reject { |k, _| exclude.include?(k) }
  end
end

class Template
  # from Jekyll::Document
  YAML_FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m.freeze

  attr_reader :path, :config, :mod, :target

  def initialize(path, mod:, target:, config:)
    @path = path
    @config = config
    @mod = mod
    @target = target
  end

  def raw_template
    @raw_template ||= File.read(path)
  end

  def front_matter
    @front_matter ||=
      if (fm = raw_template[YAML_FRONT_MATTER_REGEXP])
        YAML.load(fm)
      else
        {}
      end
  end

  def diff
    Differ.new(self).diff
  end

  def renderable_template
    return raw_template unless (fm = raw_template[YAML_FRONT_MATTER_REGEXP])
    raw_template.lines.drop(fm.lines.count).join
  end

  def to_s
    @to_s ||= render
  end

  def render
    RenderContext.new(renderable_template, @target, @config, variables: render_variables, helpers: TemplateHelpers::HELPERS[mod]).result
  end

  def render_variables
    # maybe shouldn't smoosh them all together?
    config['variables'].merge(config['roles'][@mod])
  end
end

module HasConfigVariable
  def method_missing(name, *args, &block)
    variables[name.to_s] or super
  end
end

module HasTarget
  def method_missing(name, *args, &block)
    query = name.to_s.end_with?('?')

    target = name.to_s.sub(/\?\Z/, '')

    if ::CONFIG['targets'][target]
      return false unless target == @target
      return true if query
      yield
    else
      return false if query
      super
    end
  end
end

module TemplateHelpers
  module Tmux
    def copy_command
      case clipboard
      when 'xclip'
        'xclip -i -selection clipboard'
      when 'xsel'
        'xsel -i --clipboard'
      when 'pbcopy'
        'pbcopy'
      end
    end
  end

  HELPERS = Hash.new { |h, k| h[k] = [] }
  HELPERS['tmux'] << Tmux
end

class RenderContext
  attr_reader :config, :variables, :template

  include HasConfigVariable
  include HasTarget

  def initialize(template, target, config, variables:, helpers:)
    @template = template
    @config = config
    @variables = variables
    @target = target

    helpers.each { |helper| extend(helper) }
  end

  def result
    ERB.new(@template).result(binding)
  end
end

class Differ
  def initialize(template)
    @template = template
  end

  def diff
    out, _ = Open3.capture2("diff #{comparison_path} -", stdin_data: @template.to_s)
    out
  end

  def diff
    Open3.pipeline_rw(
      "diff -U3 --minimal #{comparison_path} -",
      "sed 's/^-/\x1b[1;31m-/;s/^+/\x1b[1;32m+/;s/^@/\x1b[1;34m@/;s/$/\x1b[0m/'"
    ) do |stdin, stdout, _thr|
      stdin.puts(@template.to_s)
      stdin.close

      stdout.read
    end
  end

  def comparison_path
    File.expand_path("~/#{@template.front_matter['path']}")
  end
end


require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-t", "--target TARGET") do |t|
    options[:target] = t
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-d", "--diff", "print diff only") do |v|
    options[:diff] = v
  end
end.parse!

p options
p ARGV
mods = ARGV
target = options[:target]
raise ArgumentError.new("target `#{target.inspect}` not available") unless target && CONFIG['targets'][target]

c = Configurator.new(target, mods)

c.templates.each do |t|
  # puts t.render
  puts t.diff

  # binding.pry
end

exit(0)

# TODO: actually write files to target
# TODO: run scripts (nvim plugins, etc)
# TODO: support cloning/updating git repos
# TODO: support target classes/aliases e.g., manjaro (linux), mac (darwin),
# TODO: cli wizard
# TODO: add annotations versioning (i.e., current sha and previous sha)
#   - add some boilerplate warnings 'this file is managed by a script', etc.
#   - headers can drive rollbacks file-by-file
# TODO: plugins (rbenv, vim, nvim, etc)
