{self, inputs, ...}: {

	flake.nixosModules.workstationHardware = { config, lib, pkgs, modulesPath, ... }:
	{
		imports =
			[ (modulesPath + "/installer/scan/not-detected.nix")
			];

		boot.initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
		boot.initrd.kernelModules = [ ];
		boot.kernelModules = [ "kvm-amd" ];
		boot.extraModulePackages = [ ];

		fileSystems."/" =
		{ device = "/dev/disk/by-uuid/c1765ed6-3b5c-4244-a8a6-04776024986e";
			fsType = "ext4";
		};

		fileSystems."/boot" =
		{ device = "/dev/disk/by-uuid/F4FA-C3B8";
			fsType = "vfat";
		};

		fileSystems."/home" =
		{ device = "/dev/disk/by-uuid/9fc48da3-7684-44d9-ab66-b5ba541f161f";
			fsType = "ext4";
		};

		swapDevices =
			[ { device = "/dev/disk/by-uuid/1285b119-44c7-4ee7-95e8-083a84de08cc"; }
		];

		fileSystems."/Data" = {
			device = "/dev/disk/by-uuid/806c5d44-1a06-44fb-b590-4528116d2e1b";
			fsType = "ext4";
			options = [ "defaults" "noatime" ];
		};

		networking.useDHCP = lib.mkDefault true;

		nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
		hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
	};
}
