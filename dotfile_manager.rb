require 'erb'
require 'yaml'
require 'bundler/inline'

gemfile do
  gem 'pry-byebug'
end

require 'pry-byebug'

CONFIG = YAML.load <<~YAMLCONFIG
---
defaults: &defaults
  git:
    username: zvkemp
    email: zvkemp@gmail.com

  # - nvim
  # - tmux
  # - zsh
  # - prezto
  # - alacritty
variables: &variables
  git_username: zvkemp
  git_email: zvkemp@gmail.com
targets:
  mac:
    exclude: {}
    variables:
      <<: *variables
    git:
      username: zvkemp2
  manjaro:
    exclude: {}
    variables:
      <<: *variables
YAMLCONFIG

# scripts:
  # install nvim plugins
  # nvim -c PlugIns -c exit -c exit
class Configurator
  def initialize(target, mod)
    @target = target
    @mod = mod
    @config = CONFIG['defaults'][mod].merge(
      CONFIG['targets'][target][mod] || {}
    )
  end

  attr_reader :target, :mod

  def templates
    f = File.expand_path("./templates/#{mod}/*.erb")
    Dir[f].map do |template|
      Template.new(template, @config)
    end
  end

  def to_s
  end

  def write!
  end
end

class Template
  # from Jekyll::Document
  YAML_FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m.freeze

  attr_reader :path
  def initialize(path, config)
    @path = path
    @config = config
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

  def renderable_template
    return raw_template unless (fm = raw_template[YAML_FRONT_MATTER_REGEXP])
    raw_template.lines.drop(fm.lines.count).join
  end

  def render
    RenderContext.new(renderable_template, @config).result
  end
end

class RenderContext
  def initialize(template, config)
    @template = template
    @config = config
    p @config
  end

  def result
    ERB.new(@template).result(binding)
  end

  def method_missing(name, *args, &block)
    @config[name.to_s] or super
  end
end


c = Configurator.new('mac', 'git')


c.templates.each do |t|
  puts t.render
end

exit(0)
