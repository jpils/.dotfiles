{ self, inputs, ... }: {
	flake.nixosModules.nvidia-30 = { config, lib, pkgs, ... }: {
		hardware.graphics = {
			enable = true;
			enable32Bit = true;
		};

		services.xserver.videoDrivers = [ "nvidia" ];

		hardware.nvidia = {
			modesetting.enable = true;

			# Required for reliable suspend/resume with proprietary NVIDIA.
			# Enables nvidia-suspend/resume units and preserves VRAM allocations.
			powerManagement.enable = true;
			powerManagement.finegrained = false;

			open = false;

			nvidiaSettings = true;

			# Store the VRAM image on persistent disk; root may be tmpfs.
			moduleParams.nvidia.NVreg_TemporaryFilePath = "/persistent/var/tmp/nvidia";

			package = config.boot.kernelPackages.nvidiaPackages.stable;
		};

		systemd.tmpfiles.rules = [
			"d /persistent/var/tmp/nvidia 1777 root root -"
		];

		environment.sessionVariables = {
			WLR_NO_HARDWARE_CURSORS = "1";
		};
	};

	flake.nixosModules.nvidia-10 = { config, lib, pkgs, ... }: {
		hardware.graphics = {
			enable = true;
			enable32Bit = true;
			extraPackages = with pkgs; [
				nvidia-vaapi-driver
			];
		};

		services.xserver.videoDrivers = [ "nvidia" ];

		hardware.nvidia = {
			modesetting.enable = true;

			# Pascal benefits from PM being on (suspend/resume fixes).
			powerManagement.enable = true;
			powerManagement.finegrained = false;

			# Pascal is NOT supported by the open kernel modules.
			open = false;

			nvidiaSettings = true;

			# Store full VRAM image on persistent disk for suspend/hibernate.
			# Root is tmpfs; GTX 1080 Ti has 11G VRAM, so default temp path can corrupt resume.
			moduleParams.nvidia.NVreg_TemporaryFilePath = "/persistent/var/tmp/nvidia";

			# Pascal is on the legacy/production branch upstream.
			# `production` is more conservative than `stable` and is the
			# recommended pin for 10-series cards going forward.
			package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
		};

		systemd.tmpfiles.rules = [
			"d /persistent/var/tmp/nvidia 1777 root root -"
		];

		environment.sessionVariables = {
			WLR_NO_HARDWARE_CURSORS = "1";
			# Enable VA-API through NVDEC for Firefox/Chromium/mpv.
			NVD_BACKEND = "direct";
			LIBVA_DRIVER_NAME = "nvidia";
		};
	};
}
