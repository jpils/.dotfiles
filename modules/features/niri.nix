{ self, inputs, ... }: {
	flake.wrappersModules.niri = { config, lib, pkgs, ... }: {
		options = {
			keyboardLayout = lib.mkOption {
				type = lib.types.str;
				default = "us";
				description = "Keyboard layout for Niri";
			};
			keyboardVariant = lib.mkOption {
				type = lib.types.str;
				default = "";
				description = "Keyboard variant for Niri";
			};
			outputMonitorName = lib.mkOption {
				type = lib.types.str;
				default = "*";
				description = "Monitor name for Niri";
			};
			outputMode = lib.mkOption {
				type = lib.types.str;
				default = "preferred";
				description = "Monitor resolution and refresh rate";
			};
			outputScaling = lib.mkOption {
				type = lib.types.float;
				default = 1.0;
				description = "Fractional scaling value";
			};
			noctaliaExe = lib.mkOption {
				type = lib.types.str;
				default = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia;
				description = "Noctalia executable to spawn from Niri.";
			};
		};

		config = {
			settings = let 
				selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
				noctaliaExe = config.noctaliaExe;
				zenExe = lib.getExe inputs.zen-browser.packages.${pkgs.system}.default;
				ghosttyExe = lib.getExe selfPkgs.ghostty;
				niriExe = lib.getExe pkgs.niri;
				outputKey = config.outputMonitorName;
				noctaliaBarEmptyWorkspace = pkgs.writeShellScriptBin "noctalia-bar-empty-workspace" ''
					set -eu

					update() {
						focused_id="$(${niriExe} msg -j workspaces 2>/dev/null \
							| ${lib.getExe pkgs.jq} -r '.[] | select(.is_focused == true) | .id' 2>/dev/null \
							| head -n1 || true)"

						if [ -z "$focused_id" ] || [ "$focused_id" = null ]; then
							return 0
						fi

						window_count="$(${niriExe} msg -j windows 2>/dev/null \
							| ${lib.getExe pkgs.jq} --argjson ws "$focused_id" '[.[] | select(.workspace_id == $ws)] | length' 2>/dev/null \
							|| printf 1)"

						if [ "$window_count" = 0 ]; then
							${noctaliaExe} msg bar-auto-hide-set off Default >/dev/null 2>&1 || true
						else
							${noctaliaExe} msg bar-auto-hide-set on Default >/dev/null 2>&1 || true
						fi
					}

					sleep 2
					update

					${niriExe} msg -j event-stream 2>/dev/null | while IFS= read -r _; do
						update
					done
				'';
			in {
				prefer-no-csd = _: {};
				hotkey-overlay.skip-at-startup = true;

				spawn-at-startup = [
					noctaliaExe
					(lib.getExe noctaliaBarEmptyWorkspace)
					(lib.getExe (
					    pkgs.writeShellScriptBin "wallpaper"
					    "${lib.getExe pkgs.swaybg} -i ${self.wallpaper} -m fill"
					))
				];

				xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
				
				screenshot-path = "~/Pictures/Screenshots/Screenshot_from_%Y-%m-%d_%H-%M-%S.png";

				
				cursor = {
					xcursor-theme = "Bibata-Modern-Ice";
					xcursor-size = 20;
				};

				input = {
					keyboard = {
						xkb.layout = config.keyboardLayout;
						xkb.variant = config.keyboardVariant;
					};
					touchpad = {
						tap = _: {};              
						natural-scroll = _: {};  
					};
				};

				outputs.${outputKey} = {
					scale = config.outputScaling; 
				} // lib.optionalAttrs (config.outputMode != "preferred") {
					mode = config.outputMode;
				};

				layout = {
					gaps = 5;
					default-column-width = { proportion = 0.5; }; 
					center-focused-column = "on-overflow";
					always-center-single-column = true;

					focus-ring = {
						width = 2;
					};
				};

				workspaces = let
					settings = {layout.gaps = 5;};
				in {
				  "1" = settings;
				  "2" = settings;
				  "3" = settings;
				  "4" = settings;
				};

				binds = {
					"Mod+Return".spawn-sh = ghosttyExe;
					"Mod+C".close-window = _: {};
					
					# focus windows
					"Mod+H".focus-column-left = _: {};
					"Mod+L".focus-column-right = _: {};
					"Mod+K".focus-window-up = _: {};
					"Mod+J".focus-window-down = _: {};
					
					# move windows
					"Mod+Ctrl+H".move-column-left = _: {};
					"Mod+Ctrl+L".move-column-right = _: {};
					"Mod+Ctrl+K".move-window-up = _: {};
					"Mod+Ctrl+J".move-window-down = _: {};
					
					# consume / expel
					"Mod+Shift+L".consume-or-expel-window-left = _: {};
					"Mod+Shift+H".consume-or-expel-window-right = _: {};
					
					# workspaces
					"Mod+1".focus-workspace = 1;
					"Mod+2".focus-workspace = 2;
					"Mod+3".focus-workspace = 3;
					"Mod+4".focus-workspace = 4;
					
					# move window to workspace
					"Mod+Shift+1".move-column-to-workspace = 1;
					"Mod+Shift+2".move-column-to-workspace = 2;
					"Mod+Shift+3".move-column-to-workspace = 3;
					"Mod+Shift+4".move-column-to-workspace = 4;
					
					# view modes
					"Mod+F".toggle-window-floating = _: {};
					"Mod+Shift+F".fullscreen-window = _: {};
					"Mod+Shift+C".center-column = _: {};
					
					# window size presets
					"Mod+7".set-column-width = "33.3%";
					"Mod+8".set-column-width = "50%";
					"Mod+9".set-column-width = "66.6%";
					"Mod+0".set-column-width = "100%"; 

					# screenshot settings
					"Print".screenshot = _: {};
					"Ctrl+Print".screenshot-screen = _: {};
					"Alt+Print".screenshot-window = _: {};

					# audio controls
					"XF86AudioRaiseVolume" = _: {
						props.allow-when-locked = true;
						content.spawn = [ "${pkgs.wireplumber}/bin/wpctl" "set-volume" "-l" "1.5" "@DEFAULT_AUDIO_SINK@" "5%+" ];
					};
					"XF86AudioLowerVolume" = _: {
						props.allow-when-locked = true;
						content.spawn = [ "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
					};
					"XF86AudioMute" = _: {
						props.allow-when-locked = true;
						content.spawn = [ "${pkgs.wireplumber}/bin/wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
					};
					"XF86AudioMicMute" = _: {
						props.allow-when-locked = true;
						content.spawn = [ "${pkgs.wireplumber}/bin/wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
					};

					# brightness controls
					"XF86MonBrightnessUp" = _: {
						props.allow-when-locked = true;
						content.spawn = [ (lib.getExe pkgs.brightnessctl) "set" "5%+" ];
					};
					"XF86MonBrightnessDown" = _: {
						props.allow-when-locked = true;
						content.spawn = [ (lib.getExe pkgs.brightnessctl) "set" "5%-" ];
					};

					# application shortcuts
					"Mod+W".spawn-sh = zenExe;
					"Mod+D".spawn-sh = "vesktop";
					"Mod+T".spawn-sh = lib.getExe pkgs.telegram-desktop;
					
					"Mod+E".spawn-sh = "nautilus";
					"Mod+S".spawn-sh = "${noctaliaExe} msg panel-toggle launcher";

					# lock screen
					"Mod+Ctrl+C".spawn = "swaylock";
				};

				window-rules = [
					{
						geometry-corner-radius = 8;
						clip-to-geometry = true;
					}
					{
						matches = [{ app-id = "^zen$"; }];
						default-column-width = { proportion = 0.7; };
					}
					{
						matches = [{ app-id = "^vesktop$"; }];
						default-column-width = { proportion = 0.5; };
						open-on-workspace = "3";
					}
					{
						matches = [{ title = "^Ovito"; }];
						default-column-width = { proportion = 0.7; };
					}
					{
						matches = [{ app-id = "^geary$"; }];
						default-column-width = { proportion = 0.7; };
						open-on-workspace = "3";
					}
					{
						matches = [{ app-id = "^org.telegram.desktop$"; }];
						default-column-width = { proportion = 0.5; };
						open-on-workspace = "3";
					}
					{
						matches = [{ app-id = "(?i)spotify"; }]; 
						open-on-workspace = "3";
					}
					{
						matches = [{ app-id = "^steam$"; }];
						open-on-workspace = "4";
					}
					{
						matches = [{ app-id = "^steam_app_.*"; }];
						open-on-workspace = "4";
						open-fullscreen = true;
					}
					{
						matches = [{ app-id = "^org.gnome.Nautilus"; }];
						open-floating = true;
					}
					{
						matches = [{ app-id = "^org.gnome.Calendar"; }];
						open-floating = true;
					}
					{
						matches = [{ app-id = "^nm-openconnect-auth-dialog"; }];
						open-floating = true;
					}
					{
						matches = [{ title = "^Gnuplot"; }];
						open-floating = true;
					}
				];
			};
		};
	};

	flake.nixosModules.niri = { config, pkgs, lib, ... }: let
		cfg = config.programs.niri.custom;
	in {
		options.programs.niri.custom = {
			keyboardLayout = lib.mkOption {
				type = lib.types.str;
				default = "us";
				description = "Keyboard layout for Niri";
			};
			keyboardVariant = lib.mkOption {
				type = lib.types.str;
				default = "";
				description = "Keyboard variant for Niri";
			};
			outputMonitorName = lib.mkOption {
				type = lib.types.str;
				default = "*";
				description = "Monitor name for Niri";
			};
			outputMode = lib.mkOption {
				type = lib.types.str;
				default = "preferred";
				description = "Monitor resolution and refresh rate";
			};
			outputScaling = lib.mkOption {
				type = lib.types.float;
				default = 1.0;
				description = "Fractional scaling value";
			};
		};

		config = {
			programs.niri = { 
				enable = true;
				package = inputs.wrapper-modules.wrappers.niri.wrap {
					inherit pkgs;
					imports = [ self.wrappersModules.niri ];
					keyboardLayout = cfg.keyboardLayout;
					keyboardVariant = cfg.keyboardVariant;
					outputMonitorName = cfg.outputMonitorName;
					outputMode = cfg.outputMode;
					outputScaling = cfg.outputScaling;
					noctaliaExe = lib.getExe config.programs.noctalia.package;
				};
			};
		};
	};

	perSystem = { pkgs, ... }: {
		packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
			inherit pkgs;
			imports = [ self.wrappersModules.niri ];
		};
	};
}
