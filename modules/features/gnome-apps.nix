{ self, inputs, ... }: {
	flake.nixosModules.gnome-integration = { pkgs, lib, ... }: let
		gtkCalendarCss = pkgs.writeText "gtk-calendar.css" ''
			/* GNOME Calendar: all-day/multiday event text is too dark on Nordic. */
			event,
			event * {
				color: #ECEFF4; /* Nord 6 */
			}

			/* Timed entries were already OK; keep them theme-derived. */
			event.timed,
			event.timed * {
				color: var(--view-fg-color);
			}
		'';
	in {
	environment.systemPackages = with pkgs; [
		wl-clipboard
		nordic             
		papirus-nord      
		gnome-online-accounts-gtk
	];

		services.gvfs.enable = true;
		
		services.gnome.tinysparql.enable = true;
		services.gnome.localsearch.enable = true;

		services.gnome.evolution-data-server.enable = true;
		services.gnome.gnome-online-accounts.enable = true;

		services.gnome.gnome-keyring.enable = true;
		security.pam.services.sddm.enableGnomeKeyring = true;

		xdg.portal = {
			enable = true;
			extraPortals = [ pkgs.xdg-desktop-portal-gnome ]; 
			config.common.default = "*";
		};

		environment.sessionVariables = {
			GTK_THEME = "Nordic";
		};

		system.activationScripts.gtkCalendarCss.text = ''
			install -d -m 700 -o jay -g users /home/jay/.config/gtk-4.0
			install -m 600 -o jay -g users ${gtkCalendarCss} /home/jay/.config/gtk-4.0/gtk.css
		'';

		programs.dconf.profiles.user.databases = [{
			settings = {
				"org/gnome/desktop/interface" = {
					color-scheme = "prefer-dark";
					gtk-theme = "Nordic";
					icon-theme = "Papirus-Dark";
				};
			};
		}];

		fonts.packages = with pkgs; [
			noto-fonts
			noto-fonts-cjk-sans
			noto-fonts-color-emoji
			liberation_ttf
			ubuntu-classic
		];
	};
}
