{ self, ... }: {
  flake.nixosModules.swaylock-effects = { pkgs, ... }: let
    # 1. Declaratively bake your configuration directly into the Nix store
    swaylockConfig = pkgs.writeText "swaylock-config" ''
      # Fixed Background Image from your Flake
      image=${self.wallpaper}
      scaling=fill

      # --- Blur Effects Configuration ---
      effect-blur=7x5
      # ----------------------------------

      # Render Elements
      clock
      indicator

      # Font & Formats (Hiding date entirely)
      font=Iosevka
      timestr=%H:%M
      
      # Strip out UI noise
      disable-caps-lock-text
      hide-keyboard-layout
      indicator-radius=100
      indicator-thickness=7

      # Nord Color Palette Implementation
      text-color=d8dee9

      # Completely transparent inside circle backgrounds
      inside-color=2e344000
      inside-clear-color=2e344000
      inside-ver-color=2e344000
      inside-wrong-color=bf616a00

      # Ring boundaries (Nord polar night/aurora tones)
      ring-color=4c566a
      ring-clear-color=ebcb8b
      ring-ver-color=a3be8c
      ring-wrong-color=bf616a

      # Interactive keystroke/backspace indicators
      key-hl-color=88c0d0
      bs-hl-color=b48ead
      line-uses-ring
    '';

    # Create a clean wrapped executable pointing to our config path
    swaylock-wrapped = pkgs.writeShellScriptBin "swaylock" ''
      exec ${pkgs.swaylock-effects}/bin/swaylock --config ${swaylockConfig} "$@"
    '';
  in {
    # 2. Tell NixOS to initialize the PAM context for swaylock (so it can read passwords)
    security.pam.services.swaylock = {};

    # 3. Add the wrapped locker package globally to your user path
    environment.systemPackages = [ swaylock-wrapped ];

    # 4. Swayidle background daemon configuration
    systemd.user.services.swayidle = {
      description = "Idle management daemon for Wayland sessions";
      wantedBy = [ "default.target" ];
      after = [ "graphical-session.target" ];
      
      serviceConfig = {
        # -w waits for the lock command to finish before letting the system sleep
        # timeout 300 = 5 minutes of inactivity before firing the lockscreen
        ExecStart = ''
          ${pkgs.swayidle}/bin/swayidle -w \
            timeout 30 '${swaylock-wrapped}/bin/swaylock -f' \
			timeout 40 '${pkgs.systemd}/bin/systemctl suspend' \
            before-sleep '${swaylock-wrapped}/bin/swaylock -f'
        '';
        Restart = "always";
        RestartSec = 1;
      };
    };
  };
}
