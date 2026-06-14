{ self, ... }: {
    flake.nixosModules.swaylock-effects = { pkgs, ... }: let
        swaylockConfig = pkgs.writeText "swaylock-config" ''
            image=${self.wallpaper}
            scaling=fill
            effect-blur=7x5
            clock
            indicator
            font=Iosevka
            timestr=%H:%M
            disable-caps-lock-text
            hide-keyboard-layout
            indicator-radius=100
            indicator-thickness=7
            text-color=d8dee9
            inside-color=2e344000
            inside-clear-color=2e344000
            inside-ver-color=2e344000
            inside-wrong-color=bf616a00
            ring-color=4c566a
            ring-clear-color=ebcb8b
            ring-ver-color=a3be8c
            ring-wrong-color=bf616a
            key-hl-color=88c0d0
            bs-hl-color=b48ead
            line-uses-ring
        '';

        swaylock-wrapped = pkgs.writeShellScriptBin "swaylock" ''
            exec ${pkgs.swaylock-effects}/bin/swaylock --config ${swaylockConfig} "$@"
        '';
    in {
        security.pam.services.swaylock = {};

        environment.systemPackages = [ swaylock-wrapped ];

        systemd.user.services.swayidle = {
            description = "Idle management daemon";
            wantedBy = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];

            serviceConfig = {
                ExecStart = ''
                    ${pkgs.swayidle}/bin/swayidle -w \
                    timeout 300 '${swaylock-wrapped}/bin/swaylock -f' \
                    timeout 360 '${pkgs.systemd}/bin/systemctl suspend-then-hibernate' \
                    before-sleep '${swaylock-wrapped}/bin/swaylock -f'
                '';
                Restart = "always";
                RestartSec = 1;
            };
        };
    };
}
