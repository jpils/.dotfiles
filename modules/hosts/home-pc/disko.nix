{ self, inputs, ... }: {
	flake.nixosModules.homePcDisko = { config, pkgs, ...}: 
	{
	  imports = [
	    inputs.disko.nixosModules.disko
	  ];

	  fileSystems."/nix".neededForBoot = true;
	  fileSystems."/persistent".neededForBoot = true;

	  disko.devices.nodev = {
	    "/" = {
	      fsType = "tmpfs";
	      mountOptions = [
		"size=25%"
		"mode=755"
	      ];
	    };
	  };

	  disko.devices.disk.main = {
	    device = "/dev/disk/by-id/ata-Samsung_SSD_850_PRO_512GB_S2BENWAJ604299M";
	    type = "disk";

	    content.type = "gpt";

	    content.partitions.boot = {
	      name = "boot";
	      size = "1M";
	      type = "EF02";
	    };

	    content.partitions.esp = {
	      name = "ESP";
	      size = "1G";
	      type = "EF00";

	      content = {
		type = "filesystem";
		format = "vfat";
		mountpoint = "/boot";
	      };
	    };

	    content.partitions.swap = {
	      size = "16G";

	      content = {
		type = "swap";
		resumeDevice = true;
	      };
	    };

	    content.partitions.root = {
	      name = "root";
	      size = "100%";

	      content = {
		type = "btrfs";
		extraArgs = ["-f"];

		subvolumes = {
		  "/persistent" = {
		    mountOptions = ["subvol=persistent" "noatime"];
		    mountpoint = "/persistent";
		  };

		  "/nix" = {
		    mountOptions = ["subvol=nix" "noatime"];
		    mountpoint = "/nix";
		  };
		};
	      };
	    };
	  };
	};
}
