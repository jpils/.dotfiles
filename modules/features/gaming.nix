{ self, inputs, ... }: {
	flake.nixosModules.gaming = { config, lib, pkgs, ... }: {
		# --- Steam ----------------------------------------------------------
		programs.steam = {
			enable = true;
			remotePlay.openFirewall = true;
			dedicatedServer.openFirewall = true;
			localNetworkGameTransfers.openFirewall = true;
			gamescopeSession.enable = true;
			extraCompatPackages = with pkgs; [
				proton-ge-bin
			];
		};

		# --- Gamescope (standalone) -----------------------------------------
		programs.gamescope = {
			enable = true;
			capSysNice = true;
		};

		# --- GameMode -------------------------------------------------------
		programs.gamemode = {
			enable = true;
			enableRenice = true;
			settings = {
				general.renice = 10;
				gpu = {
					apply_gpu_optimisations = "accept-responsibility";
					gpu_device = 0;
				};
			};
		};

		# --- Graphics / Vulkan / 32-bit libs --------------------------------
		hardware.graphics = {
			enable = true;
			enable32Bit = true;
			extraPackages = with pkgs; [
				vulkan-loader
				vulkan-validation-layers
				vulkan-extension-layer
				mesa
				libva
				libvdpau-va-gl
			];
			extraPackages32 = with pkgs.pkgsi686Linux; [
				vulkan-loader
				mesa
				libva
			];
		};

		environment.sessionVariables = {
			MANGOHUD = "1";
		};

		# --- Controllers ----------------------------------------------------
		hardware.xpadneo.enable = true;
		hardware.xone.enable = true;
		services.udev.packages = with pkgs; [
			game-devices-udev-rules
		];
		hardware.steam-hardware.enable = true;

		# --- Networking: lower latency tweaks for online play ---------------
		boot.kernel.sysctl = {
			"net.core.rmem_max" = 2500000;
			"net.core.wmem_max" = 2500000;
		};

		# Increase file descriptor limits (esync/fsync, Star Citizen, etc.)
		systemd.settings.Manager = {
			DefaultLimitNOFILE = "1048576";
		};
		security.pam.loginLimits = [
			{ domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
			{ domain = "*"; type = "soft"; item = "nofile"; value = "1048576"; }
		];

		# --- Gaming applications & tools ------------------------------------
		users.users.jay.packages = with pkgs; [
			# Launchers / stores
			lutris
			heroic
			bottles
			prismlauncher

			# Wine / Proton helpers
			wineWow64Packages.staging
			winetricks
			protontricks
			protonup-qt

			# Performance / overlays / tweaking
			mangohud
			#goverlay
			gamescope
			gamemode
		];

		nixpkgs.config.allowUnfree = true;
	};
}
