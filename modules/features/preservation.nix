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
					"/var/lib/cups"
					"/var/cache/cups"
					"/var/log"
					{
						directory = "/var/lib/nixos";
						inInitrd = true;
					}
					"/etc/NetworkManager/system-connections"
					"/var/lib/AccountsService"
				];

				files = [
					"/etc/printcap"
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
						{
							directory = ".config/gnupg";
							mode = "0700";
						}
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
						".local/share/noctalia"
						".local/share/nvim/harpoon"
						".local/share/uv"
						".local/share/zoxide"
						".local/state/noctalia"
						".local/state/tmux"
						".local/state/wireplumber"
						{
							directory = ".gnupg";
							mode = "0700";
						}
						".mozilla"
						".password-store"
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

		system.activationScripts.gnupgPermissions.text = ''
			chmod 700 /home/jay/.gnupg 2>/dev/null || true
			chmod 700 /home/jay/.config/gnupg 2>/dev/null || true
			find /home/jay/.gnupg -type f -exec chmod 600 {} + 2>/dev/null || true
			find /home/jay/.gnupg -type d -exec chmod 700 {} + 2>/dev/null || true
			chown -R jay:users /home/jay/.gnupg /home/jay/.config/gnupg 2>/dev/null || true
		'';

		systemd.suppressedSystemUnits =  [ "systemd-machine-id-commit.service" ];
	};
}
