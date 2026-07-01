{ self, inputs, ... }: {
	flake.nixosModules.nvidia-30 = { config, lib, pkgs, ... }: {
		hardware.graphics = {
			enable = true;
			enable32Bit = true;
		};

		services.xserver.videoDrivers = [ "nvidia" ];

		hardware.nvidia = {
			modesetting.enable = true;

			powerManagement.enable = true;
			powerManagement.finegrained = false;

			open = false;

			nvidiaSettings = true;

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

			powerManagement.enable = true;
			powerManagement.finegrained = false;

			open = false;

			nvidiaSettings = true;

			moduleParams.nvidia.NVreg_TemporaryFilePath = "/persistent/var/tmp/nvidia";

			package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
		};

		systemd.tmpfiles.rules = [
			"d /persistent/var/tmp/nvidia 1777 root root -"
		];

		environment.sessionVariables = {
			WLR_NO_HARDWARE_CURSORS = "1";
			NVD_BACKEND = "direct";
			LIBVA_DRIVER_NAME = "nvidia";
		};
	};
}
