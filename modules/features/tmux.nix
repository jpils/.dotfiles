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
		cleanupTmuxResurrect = pkgs.writeShellScriptBin "cleanup-tmux-resurrect" ''
			set -euo pipefail

			dir="''${1:-$HOME/.local/state/tmux/resurrect}"
			keep="''${2:-10}"

			[ -d "$dir" ] || exit 0

			last_target=""
			if [ -L "$dir/last" ]; then
				last_target="$(readlink -f "$dir/last")"
			fi

			keep_others="$keep"
			if [ -n "$last_target" ] && [ -e "$last_target" ]; then
				keep_others=$((keep - 1))
			fi

			find "$dir" -maxdepth 1 -type f -name 'tmux_resurrect_*.txt' -printf '%T@ %p\n' \
				| sort -rn \
				| awk -v keep_others="$keep_others" -v last_target="$last_target" '
					$2 == last_target { next }
					++count > keep_others { print $2 }
				' \
				| xargs -r rm -f --
		'';

		rewriteTmuxResurrectCommands = pkgs.writeShellScriptBin "rewrite-tmux-resurrect-commands" ''
			set -euo pipefail

			file="''${1:-}"
			if [ -z "$file" ]; then
				file="$HOME/.local/state/tmux/resurrect/last"
			fi
			[ -n "$file" ] && [ -f "$file" ] || exit 0
			file="$(readlink -f "$file")"

			${pkgs.perl}/bin/perl - "$file" <<'PERL'
use strict;
use warnings;
use File::Temp qw(tempfile);
use File::Basename qw(dirname);

my $path = shift @ARGV;
my %editor_windows;
my %shell_windows;
my %shell_dirs;
my @lines;

sub clean_dir {
	my ($dir) = @_;
	return undef unless defined $dir;
	return undef unless $dir =~ /^:(?:\/|~)/;
	$dir =~ s/^://;
	$dir =~ s/^~/$ENV{HOME}/;
	$dir =~ s/\\ / /g;
	return $dir;
}

sub pane_dir {
	my (@fields) = @_;
	for my $idx (7, 6) {
		my $dir = clean_dir($fields[$idx]);
		return $dir if defined $dir;
	}
	return undef;
}

sub shell_quote {
	my ($s) = @_;
	$s =~ s/'/'"'"'/g;
	return "'$s'";
}

open(my $in, '<', $path) or exit 0;
while (my $line = <$in>) {
	chomp $line;
	push @lines, $line;

	my @fields = split /\t/, $line, -1;
	if (@fields >= 4 && $fields[0] eq 'window') {
		my $key = "$fields[1]:$fields[2]";
		$editor_windows{$key} = 1 if $fields[3] eq ':editor';
		$shell_windows{$key} = $fields[1] if $fields[3] eq ':shell';
	}
}
close $in;

for my $line (@lines) {
	my @fields = split /\t/, $line, -1;
	next unless @fields >= 11 && $fields[0] eq 'pane';
	next unless $shell_windows{"$fields[1]:$fields[2]"};
	my $dir = pane_dir(@fields) or next;
	my $session = $fields[1];
	$shell_dirs{$session} = $dir if !exists $shell_dirs{$session} || $fields[8] eq '1';
}

my @out;
for my $line (@lines) {
	my @fields = split /\t/, $line, -1;
	if (@fields >= 11 && $fields[0] eq 'pane' && $editor_windows{"$fields[1]:$fields[2]"}) {
		my $dir = $shell_dirs{$fields[1]} // pane_dir(@fields) // '.';
		my $quoted_dir = shell_quote($dir);
		if (defined $fields[7] && $fields[7] =~ /^:(?:\/|~)/) {
			$fields[7] = ":$dir";
			splice @fields, 8, 0, '1' if !defined $fields[8] || $fields[8] !~ /^[01]$/;
		} else {
			splice @fields, 7, 0, ":$dir";
		}
		$fields[10] = ":cd $quoted_dir && direnv exec . yazi";
		$#fields = 10;
		$line = join "\t", @fields;
	}
	push @out, $line;
}

my ($fh, $tmp) = tempfile('tmux-resurrect-XXXXXX', DIR => dirname($path));
print $fh join("\n", @out), "\n";
close $fh;
rename $tmp, $path or die "rename $tmp -> $path: $!";
PERL
		'';

		mkTmux = { shellPath }: inputs.wrapper-modules.wrappers.tmux.wrap {
			inherit pkgs;
			plugins = with pkgs.tmuxPlugins; [ nord sensible yank resurrect continuum ];

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

# Status Line
				set-option -g status-interval 5
				set -g status-left '#[bold]#{=/#{e|/|:#{client_width},4}/...:#S} '
				set -g status-left-length 120
				set -g status-right '%a %d-%m-%Y   %H:%M#[default]'
				set -g status-right-length 40
				set -g status-position top
				set -g window-status-current-format '  #I: #W'
				set -g window-status-format '  #I: #W'
				set -g window-status-last-style 'fg=white, bg=black'

# Session Persistence
				set -g @resurrect-dir '$HOME/.local/state/tmux/resurrect'
				set -g @continuum-restore 'off'
				set -g @continuum-save-interval '5'
				set -g @resurrect-processes '"~pi -c->pi -c" "~bacon->direnv exec . bacon" "~yazi->direnv exec . yazi"'
				set -g @resurrect-hook-post-save-layout '${rewriteTmuxResurrectCommands}/bin/rewrite-tmux-resurrect-commands'
				set -g @resurrect-hook-pre-restore-all '${rewriteTmuxResurrectCommands}/bin/rewrite-tmux-resurrect-commands'
				set -g @resurrect-hook-post-save-all '${cleanupTmuxResurrect}/bin/cleanup-tmux-resurrect'

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
				set-option -g automatic-rename on
				set-option -g automatic-rename-format '#{b:pane_current_path}'
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
