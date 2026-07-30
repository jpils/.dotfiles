{ self, inputs, ... }: {
	flake.nixosModules.scanner = { pkgs, ... }: {
		hardware.sane = {
			enable = true;
			openFirewall = true;

			# Driverless network scanning via eSCL/AirScan.
			extraBackends = with pkgs; [ sane-airscan ];

			# Brother backend. If AirScan does not discover it, add the printer IP here:
			# brscan5.netDevices.Brother_DCP_T780DW = {
			# 	model = "DCP-T780DW";
			# 	ip = "192.168.1.123";
			# };
			brscan5.enable = true;
		};

		users.users.jay = {
			extraGroups = [ "scanner" "lp" ];
			packages = with pkgs; [
				sane-backends
				simple-scan
			];
		};
	};
}
