{ self, inputs, ... }: {
	flake.nixosModules.tmux = { pkgs, ... }: {
		programs.tmux = {
			enable = true;
			package = self.packages.${pkgs.stdenv.hostPlatform.system}.tmux;
		};
	};

	flake.nixosModules.tmux-nu = { pkgs, ... }: {
		programs.tmux = {
			enable = true;
			package = self.packages.${pkgs.stdenv.hostPlatform.system}.tmux-nu;
		};
	};

	perSystem = { pkgs, self', ... }: let
		mkTmux = { shellPath }: inputs.wrapper-modules.wrappers.tmux.wrap {
			inherit pkgs;
			plugins = with pkgs.tmuxPlugins; [ nord sensible yank ];

			configBefore = ''
# Set prefix to Space (C-Space)
				unbind C-b
				set -g prefix C-Space
				setw -g mode-keys vi
				bind C-Space send-prefix

# Core Settings
				set -g default-shell ${shellPath}
				set -g mouse on
				set -g base-index 1
				set -g pane-base-index 1
				set-window-option -g pane-base-index 1
				set-option -g renumber-windows on

# Enable True Color, Italics, and Undercurls
				set -g default-terminal "tmux-256color"
				set -ag terminal-overrides ",xterm-256color:RGB,xterm-ghostty:RGB"
				set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
				set -g allow-passthrough on

# Plugin Configs
				set -g @catppuccin_flavor 'mocha'
				set -g @catppuccin_window_tabs_enabled on
				set -g @catppuccin_date_time "%H:%M"
			'';

			configAfter = ''
				bind-key x kill-pane
				set -g detach-on-destroy off
				set -g history-limit 100000
				set -sg escape-time 10
				set -g focus-events on
				bind -n M-H previous-window
				bind -n M-L next-window
				bind -r ^ last-window
				bind -r k select-pane -U
				bind -r j select-pane -D
				bind -r h select-pane -L
				bind -r l select-pane -R
				bind | split-window -h -c "#{pane_current_path}"
				bind - split-window -v -c "#{pane_current_path}"
				bind c new-window -c "#{pane_current_path}"
				bind -r H resize-pane -L 5
				bind -r J resize-pane -D 5
				bind -r K resize-pane -U 5
				bind -r L resize-pane -R 5
				bind s choose-tree -Zs
				bind g display-popup -E -w 90% -h 80% -d "#{pane_current_path}" "${shellPath}"
				bind G display-popup -E -w 90% -h 80% -d "#{pane_current_path}" "jj st; exec ${shellPath}"
				set-option -g status-interval 5
				set-option -g automatic-rename on
				set-option -g automatic-rename-format '#{b:pane_current_path}'
				set -g status-right '%a %d-%m-%Y   %H:%M#[default]'
				set -g status-position top
				set -g window-status-current-format '  #I: #W'
				set -g window-status-format '  #I: #W'
				set -g window-status-last-style 'fg=white, bg=black'
			'';
		};
	in {
		packages = {
			tmux = mkTmux {
				shellPath = "${pkgs.zsh}/bin/zsh";
			};

			tmux-nu = mkTmux {
				shellPath = "${self'.packages.nushell}/bin/nu";
			};
		};
	};
}
