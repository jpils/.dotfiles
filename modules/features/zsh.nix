{ self, inputs, ... }: {
	flake.nixosModules.zsh = { pkgs, ... }: {
		environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.zsh ];
		environment.shells = [ self.packages.${pkgs.stdenv.hostPlatform.system}.zsh ];
	};

	perSystem = { pkgs, lib, ... }: {
		packages.zsh = inputs.wrapper-modules.wrappers.zsh.wrap {
			inherit pkgs;
			
			runtimePkgs = with pkgs; [
				fzf
				fd
				starship
				zoxide
				direnv
				zsh-syntax-highlighting
				sesh
			];

			zshAliases = {
				v = "nvim";
				l = "ls --color=auto -lh";
				la = "ls --color=auto -lah";
				ts = "tmux new -s";
				cd = "z";
				tn = "tmux-new";
				leonardo = "source ~/nixconf/leonardo.sh";
				univie = "nmcli connection up id 'univie' --ask";
				fzf-custom = "fzf --multi --height=50% --margin=5%,2%,2%,5% --layout=reverse-list --border=rounded --info=inline --prompt='> ' --pointer='→' --marker='▶' --color='dark,fg:blue'";
			};

			env = {
				KEYTIMEOUT = "20";
				FZF_DEFAULT_OPTS = " --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8";
			};

			zshrc.content = ''
				# Lines configured by zsh-newuser-install
				HISTFILE=~/.histfile
				HISTSIZE=1000
				SAVEHIST=1000

				autoload -U compinit
				zstyle ':completion:*' menu select
				zmodload zsh/complist
				compinit
				_comp_options+=(globdots) #include dotfiles

				# vim mode
				bindkey -v
				bindkey -M menuselect 'h' vi-backward-char
				bindkey -M menuselect 'k' vi-up-line-or-history
				bindkey -M menuselect 'l' vi-forward-char
				bindkey -M menuselect 'j' vi-down-line-or-history

				if [ "$IS_PC" = "true" ]; then
					export LD_LIBRARY_PATH="/run/opengl-driver/lib:$LD_LIBRARY_PATH"
					export LIBGL_DRIVERS_PATH="/run/opengl-driver/lib/dri"
				fi

				# Load zsh syntax highlighting from the Nix store!
				source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

				# Load fzf completions and keybindings from the Nix store!
				source ${pkgs.fzf}/share/fzf/completion.zsh 2>/dev/null
				source ${pkgs.fzf}/share/fzf/key-bindings.zsh 2>/dev/null

				find-directories-widget() {
					local dir
					dir=$(fd --type d | fzf-custom ) || {
						zle reset-prompt
						return
					}
					LBUFFER+="$dir"
					zle reset-prompt
				}

				find-hidden-directories-widget() {
					local dir
					dir=$(fd --type d --hidden | fzf-custom) || {
						zle reset-prompt
						return
					}
					LBUFFER+="$dir"
					zle reset-prompt
				}

				find-command-hist-widget() {
					local cmd
					cmd=$(fc -rl 1 | fzf-custom | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//') || return
					LBUFFER+="$cmd"
					zle reset-prompt
				}

				find-file-widget() {
					local file
					file=$(fd --type f | fzf-custom) || {
						zle reset-prompt
						return
					}
					LBUFFER+="$file"
					zle reset-prompt
				}

				function zle-keymap-select {
					case $KEYMAP in
						vicmd)      print -n -- $'\e[2 q' ;;  # block cursor
						viins|main) print -n -- $'\e[6 q' ;;  # bar cursor
					esac
				}
				zle -N zle-keymap-select
				function zle-line-init { zle-keymap-select }
				zle -N zle-line-init

				zle -N find-directories-widget
				zle -N find-hidden-directories-widget
				zle -N find-command-hist-widget
				zle -N find-file-widget

				bindkey '^t' find-directories-widget
				bindkey '^h' find-hidden-directories-widget
				bindkey '^r' find-command-hist-widget
				bindkey '^f' find-file-widget

				tmux-new() {
					session=$(sesh list | fzf-custom)
						sesh connect "$session"
				}

				stty -ixon

				
				# Initialize our baked-in tools!
				eval "$(zoxide init zsh)"
				eval "$(direnv hook zsh)"
				eval "$(starship init zsh)"
			'';
		};
	};
}
