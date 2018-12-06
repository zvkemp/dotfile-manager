require 'erb'
require 'yaml'
require 'bundler/inline'

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
  def initialize(target)
    @target = target
    @config = CONFIG['targets'][target]

    process_config
  end

  attr_reader :target, :mod, :config

  def templates
    config['roles'].flat_map do |mod, _|
      f = File.expand_path("./templates/#{mod}/*.erb")
      Dir[f].map do |template|
        Template.new(template, config: config, mod: mod, target: target)
      end
    end
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
        {} end end

  def renderable_template
    return raw_template unless (fm = raw_template[YAML_FRONT_MATTER_REGEXP])
    raw_template.lines.drop(fm.lines.count).join
  end

  def render
    RenderContext.new(renderable_template, @config, variables: render_variables).result
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
      return true if query
      yield
    else
      return false if query
      super
    end
  end
end

class RenderContext
  attr_reader :config, :variables

  def initialize(template, config, variables:)
    @template = template
    @config = config
    @variables = variables
  end

  include HasConfigVariable
  include HasTarget

  def result
    ERB.new(@template).result(binding)
  end
end


target = ARGV[0]
raise ArgumentError.new("target `#{target.inspect}` not available") unless target && CONFIG['targets'][target]

c = Configurator.new(target)

c.templates.each do |t|
  puts t.render
end

exit(0)

# TODO: actually write files to target
# TODO: run scripts (nvim plugins, etc)
# TODO: support cloning/updating git repos
# TODO: support target classes/aliases e.g., manjaro (linux), mac (darwin),
# TODO: cli wizard
