require 'yaml'
require 'set'

module DotfileManager
  ConfigUnit = Struct.new(:data) do
    def mod_variable(mod, key)
      return unless has_role?(mod)
      role_configs[mod][key]
    end

    def variable(key)
      variables[key]
    end

    def role_configs
      data['roles'] || {}
    end

    def has_role?(mod)
      role_configs.key?(mod)
    end

    def variables
      data['variables'] || {}
    end

    def roles
      role_configs.keys
    end

    def exclude_roles
      data['exclude_roles'] || []
    end

    def packages
      data['packages']
    end
  end

  class Config
    include Enumerable

    def initialize(*configs_in_order_of_priority)
      @configs = configs_in_order_of_priority.map { |c| ConfigUnit.new(c) }
    end

    attr_reader :configs

    def has_role?(role)
      roles.include?(role)
    end

    def variable(key, mod = nil)
      if mod
        result = detect_map { |c| c.mod_variable(mod, key) }
        return result if result
      end

      detect_map { |c| c.variable(key) }
    end

    def roles
      @roles ||= Set.new(flat_map { |c| c.roles } - flat_map { |c| c.exclude_roles })
    end

    def packages
      Set.new(flat_map(&:packages))
    end

    private

    def each(&block)
      configs.each(&block)
    end

    def detect_map
      each do |config|
        result = yield config
        return result if result
      end
      nil
    end
  end

  class Configurator
    def initialize(target, mods_to_load = [], base_dir = nil)
      @target = target
      base_config = YAML.load_file('targets/base/config.yml')
      target_config = YAML.load_file("targets/#{target}/config.yml")

      @config = Config.new(target_config, base_config)
      @mods_to_load = mods_to_load
      @base_dir = base_dir || File.expand_path('~')
    end

    attr_reader :target, :mod, :config

    def templates
      config.roles.flat_map do |mod, _|
        next [] unless should_load?(mod)
        f = File.expand_path("./templates/#{mod}/*.erb")
        Dir[f].map do |template|
          Rendering::Template.new(template, config: config, mod: mod, target: target)
        end
      end
    end

    def should_load?(mod)
      @mods_to_load.empty? || @mods_to_load.include?(mod)
    end
  end
end
