{ self, inputs, ... }: {
	flake.nixosModules.preservation = { config, pkgs, ... }:
	{
		imports = [
			inputs.preservation.nixosModules.default
		];

		preservation = {
			enable = true;

			preserveAt."/persistent" = {
				directories = [
					"/etc/nixos"
					"/etc/ssh"
					"/var/db/sudo"
					"/var/lib/systemd"
					"/var/lib/bluetooth"
					"/var/log"
					{
						directory = "/var/lib/nixos";
						inInitrd = true;
					}
					"/etc/NetworkManager/system-connections"
					"/var/lib/AccountsService"
				];

				files = [
					{
						file = "/etc/machine-id";
						inInitrd = true;
					}
				];

				users.jay = {
					directories = [
						".cache/direnv"
						".cache/evolution"
						".cache/geary"
						".cache/noctalia"
						".cache/noctalia-qs"
						".cache/rattler"
						".cache/spotify"
						".cache/uv"
						".cache/zen"
						".config/dconf"
						".config/elephant"
						".config/evolution"
						".config/geary"
						".config/goa-1.0"
						".config/jj"
						".config/noctalia"
						".config/sops"
						".config/spotify"
						".config/vesktop"
						".config/zen"
						".local/share/Steam"
						".local/share/TelegramDesktop"
						".local/share/direnv"
						".local/share/evolution"
						".local/share/geary"
						".local/share/goa-1.0"
						".local/share/keyrings"
						".local/share/nvim/harpoon"
						".local/share/uv"
						".local/share/zoxide"
						".local/state/wireplumber"
						".mozilla"
						".pi"
						".ssh"
						".steam"
						".step"
						".zen"
						"Documents"
						"Pictures"
						"Projects"
						"nixconf"
					];

					files = [
						".config/nushell/history.txt"
					];
				};
			};
		};
		systemd.suppressedSystemUnits =  [ "systemd-machine-id-commit.service" ];
	};
}
