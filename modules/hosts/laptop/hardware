{self, inputs, ...}: {

	flake.nixosModules.laptopHardware = { config, lib, pkgs, modulesPath, ... }:
	{
		imports = [ 
			(modulesPath + "/installer/scan/not-detected.nix")
		];

		boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
		boot.initrd.kernelModules = [ ];
		boot.kernelModules = [ "kvm-intel" ];
		boot.extraModulePackages = [ ];

		fileSystems."/" =
		{
			device = "/dev/disk/by-uuid/efa25ff2-09e6-4edb-a17b-79438b2f076c";
			fsType = "ext4";
		};

		fileSystems."/boot" =
		{ 
			device = "/dev/disk/by-uuid/A046-3FB8";
			fsType = "vfat";
		};

		fileSystems."/home" =
		{
			device = "/dev/disk/by-uuid/3af29c83-7334-4433-80f4-e7804fa90836";
			fsType = "ext4";
		};

		swapDevices = [ 
			{ device = "/dev/disk/by-uuid/4e6dd9dc-4dd0-4b12-b0bf-813a5c4dad2e"; }
		];

# Enables DHCP on each ethernet and wireless interface. In case of scripted networking
# (the default) this is the recommended approach. When using systemd-networkd it's
# still possible to use this option, but it's recommended to use it in conjunction
# with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
		networking.useDHCP = lib.mkDefault true;
# networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;
# networking.interfaces.wwan0.useDHCP = lib.mkDefault true;

		nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
		hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
	};
}
