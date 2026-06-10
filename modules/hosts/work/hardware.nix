{self, inputs, ...}: {

	flake.nixosModules.workstationHardware = { config, lib, pkgs, modulesPath, ... }:

	{
	  imports =
		[ (modulesPath + "/installer/scan/not-detected.nix")
		];

	  boot.initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
	  boot.initrd.kernelModules = [ ];
	  boot.kernelModules = [ ];
	  boot.extraModulePackages = [ ];

	  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
	};
}
