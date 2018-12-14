module DotfileManager
  module Rendering
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
        Rendering::Differ.new(self).diff
      end

      def renderable_template
        return raw_template unless (fm = raw_template[YAML_FRONT_MATTER_REGEXP])
        raw_template.lines.drop(fm.lines.count).join
      end

      def to_s
        @to_s ||= render
      end

      def target_path
        # FIXME: handle unconfigured front matter path
        File.expand_path("~/#{front_matter['path']}")
      end

      def render
        Context.new(
          self,
          helpers: Rendering::Helpers[mod]
        ).result
      end

      def install_packages
        binding.pry
        return unless false
      end

      def run_after_commit_hooks
        clone_repos
        run_config_after_commit
        AfterCommitHooks[mod].reverse_each do |hook|
          hook.to_proc.call(self)
        end
      end

      private

      def clone_repos
        (config.variable('repos', @mod) || []).each do |repo_config|
          CloneRepo.new(repo_config, @mod, @target).checkout!
        end
      end

      def run_config_after_commit
        (config.variable('after_commit', @mod) || []).each do |cmd|
          if cmd.is_a?(Hash)
            run_hash_command(cmd)
          elsif cmd.is_a?(String)
            `#{cmd}`
          end
        end
      end

      def run_hash_command(cmd)
        return if cmd['require'] && File.exists?(File.expand_path(cmd['require']))
        `#{cmd['script']}`
      end
    end
  end
end
