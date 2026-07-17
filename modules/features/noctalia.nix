{ self, inputs, ... }:
let
	defaultSettings = {
		audio.enable_overdrive = true;

		backdrop = {
			blur_intensity = 0.0;
			tint_intensity = 0.0;
		};

		bar = {
			order = [ "Default" "SystemMonitor" ];

			Default = {
				background_opacity = 0.5;
				capsule = true;
				capsule_border = "outline";
				capsule_fill = "on_hover";
				capsule_opacity = 0.4999999888241291;
				capsule_padding = 7.0;
				capsule_thickness = 0.84999998472630978;
				center = [];
				end = [ "media" "notifications" "clipboard" "network" "bluetooth" "volume" "brightness" "group:g1" ];
				font_family = "Iosevka";
				font_weight = 400;
				margin_edge = 3;
				margin_ends = 3;
				position = "left";
				start = [ "workspaces" ];

				capsule_group = [
					{
						border = "outline";
						enabled = true;
						fill = "on_hover";
						id = "g1";
						members = [ "clock" "date" ];
						opacity = 0.5;
						padding = 7.0;
					}
				];
			};

			SystemMonitor = {
				auto_hide = true;
				background_opacity = 0.79999998211860657;
				capsule = true;
				capsule_border = "outline";
				capsule_fill = "on_hover";
				capsule_opacity = 0.4999999888241291;
				capsule_padding = 24.0;
				capsule_thickness = 0.84999998472630978;
				center = [ "cpu" "temp" "ram" "network_rx" "network_tx" "battery" "power_profile" ];
				enabled = true;
				end = [];
				font_family = "Iosevka";
				font_weight = 400;
				layer = "overlay";
				margin_edge = 3;
				margin_ends = 900;
				reserve_space = false;
				start = [];
			};
		};

		calendar = {
			enabled = true;
			refresh_minutes = 5;
			account = {
				personal_google = {
					name = "Personal Calendar";
					type = "google";
				};
				shared_google = {
					name = "Shared Calendar";
					type = "google";
				};
			};
		};

		keybinds = {
			down = [ "Ctrl+n" ];
			up = [ "Ctrl+p" ];
		};

		location.auto_locate = true;

		lockscreen_widgets = {
			enabled = false;
			schema_version = 2;
			widget_order = [ "lockscreen-login-box@DP-2" ];
			grid = {
				cell_size = 16;
				major_interval = 4;
				visible = true;
			};
			widget."lockscreen-login-box@DP-2" = {
				box_height = 70.0;
				box_width = 400.0;
				cx = 1280.0;
				cy = 1321.0;
				output = "DP-2";
				rotation = 0.0;
				type = "login_box";
				settings = {
					background_color = "surface_variant";
					background_opacity = 0.88;
					background_radius = 12.0;
					input_opacity = 1.0;
					input_radius = 6.0;
					show_caps_lock = true;
					show_keyboard_layout = true;
					show_login_button = true;
					show_password_hint = true;
				};
			};
		};

		nightlight = {
			temperature_day = 6700;
			temperature_night = 4500;
		};

		shell = {
			panel.open_near_click_control_center = true;
			screenshot.directory = "~/Pictures/Screenshots";
		};

		theme = {
			builtin = "Nord";
			community_palette = "Catppuccin Macchiato Lavender";
		};

		wallpaper = {
			directory = builtins.dirOf (toString self.wallpaper);
			default.path = toString self.wallpaper;
			last.path = toString self.wallpaper;
		};

		widget = {
			brightness.scroll_step = 2;
			date.format = "{:%d %b}";
			media.hide_when_no_media = true;
			workspaces.hide_when_empty = true;
		};
	};

	mkNoctaliaPackage = { pkgs, package, configFile }:
		let
			noctaliaConfigHome = pkgs.runCommand "noctalia-config-home" { } ''
				mkdir -p $out/noctalia
				cp ${configFile} $out/noctalia/config.toml
			'';
		in pkgs.symlinkJoin {
			name = "noctalia";
			paths = [ package ];
			nativeBuildInputs = [ pkgs.makeWrapper ];
			postBuild = ''
				wrapProgram $out/bin/noctalia \
					--set NOCTALIA_CONFIG_HOME ${noctaliaConfigHome}
			'';
			meta = package.meta // { mainProgram = "noctalia"; };
		};
in {
	flake.nixosModules.noctalia = { config, lib, pkgs, ... }: let
		cfg = config.programs.noctalia;
		tomlFormat = pkgs.formats.toml { };
		parseOutputWidth = mode: let
			match = builtins.match "([0-9]+)x.*" mode;
		in if match == null then null else builtins.fromJSON (builtins.elemAt match 0);
		autoOutputWidth = if cfg.systemMonitorBar.outputWidth != null then
			cfg.systemMonitorBar.outputWidth
		else
			parseOutputWidth config.programs.niri.custom.outputMode;
		computedMarginEnds = if cfg.systemMonitorBar.marginEnds != null then
			cfg.systemMonitorBar.marginEnds
		else if autoOutputWidth != null then let
			percentWidth = builtins.div (autoOutputWidth * cfg.systemMonitorBar.widthPercent) 100;
			requestedWidth = if percentWidth < cfg.systemMonitorBar.minWidth then cfg.systemMonitorBar.minWidth else percentWidth;
			visibleWidth = if requestedWidth > autoOutputWidth then autoOutputWidth else requestedWidth;
		in builtins.div (autoOutputWidth - visibleWidth) 2
		else null;
		baseComputedSettings = lib.recursiveUpdate cfg.settings {
			shell.session.actions = [
				{ action = "lock"; command = cfg.lockCommand; }
				{ action = "logout"; }
				{ action = "lock_and_suspend"; command = cfg.lockAndSuspendCommand; }
				{ action = "reboot"; }
				{ action = "shutdown"; variant = "destructive"; }
			];
		};
		computedSettings = if computedMarginEnds != null then
			lib.recursiveUpdate baseComputedSettings {
				bar.SystemMonitor.margin_ends = computedMarginEnds;
			}
		else baseComputedSettings;
		configFile = if cfg.settingsFile != null then cfg.settingsFile else tomlFormat.generate "noctalia-config.toml" computedSettings;
		wrappedPackage = mkNoctaliaPackage {
			inherit pkgs configFile;
			package = cfg.basePackage;
		};
	in {
		options.programs.noctalia = {
			enable = lib.mkOption {
				type = lib.types.bool;
				default = true;
				description = "Install wrapped Noctalia v5 with packaged declarative config.";
			};

			basePackage = lib.mkOption {
				type = lib.types.package;
				default = inputs.noctalia-v5.packages.${pkgs.stdenv.hostPlatform.system}.default;
				description = "Unwrapped upstream Noctalia package.";
			};

			settings = lib.mkOption {
				type = tomlFormat.type;
				default = defaultSettings;
				description = "Noctalia config as a Nix attrset, rendered to config.toml and packaged into the wrapper.";
			};

			settingsFile = lib.mkOption {
				type = lib.types.nullOr lib.types.path;
				default = null;
				description = "Optional raw config.toml path. If set, overrides programs.noctalia.settings.";
			};

			clearGuiOverrides = lib.mkOption {
				type = lib.types.bool;
				default = true;
				description = "Delete GUI-generated settings.toml on activation so packaged config is authoritative.";
			};

			lockCommand = lib.mkOption {
				type = lib.types.str;
				default = "swaylock -f";
				description = "Command used by Noctalia's session panel lock action.";
			};

			lockAndSuspendCommand = lib.mkOption {
				type = lib.types.str;
				default = "swaylock -f && systemctl suspend";
				description = "Command used by Noctalia's session panel lock-and-suspend action.";
			};

			systemMonitorBar = {
				widthPercent = lib.mkOption {
					type = lib.types.ints.between 1 100;
					default = 30;
					description = "Target visible width of the SystemMonitor top bar as a percentage of output width.";
				};
				minWidth = lib.mkOption {
					type = lib.types.ints.positive;
					default = 900;
					description = "Minimum visible SystemMonitor bar width in logical pixels, used so small laptop outputs do not truncate widgets.";
				};
				outputWidth = lib.mkOption {
					type = lib.types.nullOr lib.types.int;
					default = null;
					description = "Manual logical output width in pixels. If unset, parsed from programs.niri.custom.outputMode when possible.";
				};
				marginEnds = lib.mkOption {
					type = lib.types.nullOr lib.types.int;
					default = null;
					description = "Manual bar.SystemMonitor.margin_ends override. If set, disables auto percent/minWidth calculation.";
				};
			};

			package = lib.mkOption {
				type = lib.types.package;
				readOnly = true;
				description = "Final wrapped Noctalia package.";
			};
		};

		config = lib.mkIf cfg.enable {
			programs.noctalia.package = wrappedPackage;
			environment.systemPackages = [ cfg.package ];

			system.activationScripts.noctalia-config.text = lib.mkIf cfg.clearGuiOverrides ''
				# GUI overrides live here and win over packaged config.toml.
				# Remove them so the wrapped Noctalia package is authoritative.
				rm -f /home/jay/.local/state/noctalia/settings.toml
			'';
		};
	};

	perSystem = { pkgs, ... }: let
		tomlFormat = pkgs.formats.toml { };
		configFile = tomlFormat.generate "noctalia-config.toml" defaultSettings;
	in {
		# Noctalia v5: native Wayland shell, not v4 Quickshell wrapper.
		# Package carries declarative config via NOCTALIA_CONFIG_HOME.
		packages.noctalia = mkNoctaliaPackage {
			inherit pkgs configFile;
			package = inputs.noctalia-v5.packages.${pkgs.system}.default;
		};
	};
}
