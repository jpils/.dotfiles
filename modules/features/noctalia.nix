{ inputs, ... }: {
	flake.nixosModules.noctalia = { ... }: {
		system.activationScripts.noctalia-config.text = ''
			install -d -m 700 -o jay -g users /home/jay/.config/noctalia
			install -d -m 700 -o jay -g users /home/jay/.local/state/noctalia

			ln -sfn ${../../config/noctalia/config.toml} /home/jay/.config/noctalia/config.toml
			chown -h jay:users /home/jay/.config/noctalia/config.toml

			# GUI overrides live here and win over config.toml. Remove them so
			# ~/.config/noctalia/config.toml is the only declarative source.
			rm -f /home/jay/.local/state/noctalia/settings.toml
		'';
	};

	perSystem = { pkgs, ... }: {
		# Noctalia v5: native Wayland shell, not v4 Quickshell wrapper.
		packages.noctalia = inputs.noctalia-v5.packages.${pkgs.system}.default;
	};
}
