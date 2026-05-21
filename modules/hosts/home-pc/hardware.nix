{self, inputs, ...}: {

	flake.nixosModules.homePcHardware = { config, lib, pkgs, modulesPath, ... }:
	{
		imports = [ 
			(modulesPath + "/installer/scan/not-detected.nix")
		];

		boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
		boot.initrd.kernelModules = [ ];
		boot.kernelModules = [ "kvm-intel" ];
		boot.extraModulePackages = [ ];

		fileSystems."/" = { 
			device = "/dev/disk/by-uuid/54489d31-c344-44b0-8fbf-7c2bb592dc9d";
			fsType = "ext4";
		};

		fileSystems."/boot" = { 
			device = "/dev/disk/by-uuid/1BA2-F80B";
			fsType = "vfat";
		};

		fileSystems."/home" = { 
			device = "/dev/disk/by-uuid/53f00220-65a5-4721-88ad-53b2c59093c9";
			fsType = "ext4";
		};

		swapDevices = [ 
			{ device = "/dev/disk/by-uuid/0752a460-46ab-4889-a9be-a8a7d4621676"; }
		];

		fileSystems."/Data" = {
			device = "/dev/disk/by-uuid/32dd7340-dea7-47be-840f-737f02887e8c";
			fsType = "ext4";
			options = [ "defaults" "noatime" ];
		};

		networking.useDHCP = lib.mkDefault true;

		nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
		hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
	};
}
