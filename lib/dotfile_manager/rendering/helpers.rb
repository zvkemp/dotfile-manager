module DotfileManager
  module Rendering
    module Helpers
      module CopyCommand
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

      def self.[](mod)
        MOD_HELPERS[mod] || []
      end

      MOD_HELPERS = {
        'tmux' => [CopyCommand],
        'nvim' => [CopyCommand]
      }

    end
  end
end
