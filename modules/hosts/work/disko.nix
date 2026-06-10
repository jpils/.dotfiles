{ self, inputs, ... }: {
	flake.nixosModules.workstationDisko = { config, pkgs, ...}: 
	{
	  imports = [
	    inputs.disko.nixosModules.disko
	  ];

	  fileSystems."/nix".neededForBoot = true;
	  fileSystems."/persistent".neededForBoot = true; # sometimes needed too

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
		device = "/dev/disk/by-id/nvme-KINGSTON_SNVS1000G_50026B778460B74A";
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
		  size = "32G";

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
