require 'spec_helper'

RSpec.describe DotfileManager::Configurator do
  let(:raw_configs) do
    YAML.load(<<~CONF)
          [
            {
              roles: { role_a: { var_a: 1, var_d: 'override d' } },
              exclude_roles: ['role_x2']
            },
            {
              roles: { role_a: { var_a: 2, var_b: 'b' } },
              exclude_roles: ['role_x1']
            },
            {
              roles: { role_b: { var_a: 2, var_b: 1 }, role_x1: nil, role_x2: nil },
              variables: { var_c: 'c', var_d: 'd' }
            }
          ]
    CONF
  end

  describe DotfileManager::Config do
    let(:config) { DotfileManager::Config.new(*raw_configs) }

    specify { expect(config.variable('var_a')).to be_nil }
    specify { expect(config.variable('var_a', 'role_a')).to eq(1) }
    specify { expect(config.variable('var_a', 'role_b')).to eq(2) }
    specify { expect(config.variable('var_b', 'role_a')).to eq('b') }
    specify { expect(config.variable('var_c')).to eq('c') }
    specify { expect(config.variable('var_c', 'role_a')).to eq('c') }
    specify { expect(config.variable('var_d')).to eq('d') }
    specify { expect(config.variable('var_d', 'role_a')).to eq('override d') }

    specify { expect(config.roles.to_a).to match_array(%w[role_a role_b]) }

    specify do
      expect(DotfileManager::Config.new(*raw_configs.drop(1)).roles.to_a).to(
        match_array(%w[role_a role_b role_x2])
      )
    end

    specify do
      expect(DotfileManager::Config.new(*raw_configs.drop(2)).roles.to_a).to(
        match_array(%w[role_b role_x1 role_x2])
      )
    end
  end

  pending do
    tmp = Dir.mktmpdir
    conf = DotfileManager::Configurator.new('manjaro', ['tmux'], tmp)
    expect(conf.templates.map(&:to_s)).to eq('')
  end
end
