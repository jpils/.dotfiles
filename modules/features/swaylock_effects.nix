{ self, ... }: {
    flake.nixosModules.swaylock-effects = { config, lib, pkgs, ... }: let
        cfg = config.jay.swaylock-effects;

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

        sleepCommand =
            if cfg.hibernate then
                "${pkgs.systemd}/bin/systemctl suspend-then-hibernate"
            else
                "${pkgs.systemd}/bin/systemctl suspend";

        sleepTimeoutLine = lib.optionalString cfg.suspend ''
                    timeout ${toString cfg.sleepTimeout} '${sleepCommand}' \
        '';
    in {
        options.jay.swaylock-effects = {
            suspend = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether swayidle should suspend after the idle timeout.";
            };

            hibernate = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Use suspend-then-hibernate instead of plain suspend.";
            };

            lockTimeout = lib.mkOption {
                type = lib.types.int;
                default = 300;
                description = "Seconds before locking.";
            };

            sleepTimeout = lib.mkOption {
                type = lib.types.int;
                default = 360;
                description = "Seconds before suspend or suspend-then-hibernate.";
            };
        };

        config = {
            security.pam.services.swaylock = {};

            environment.systemPackages = [ swaylock-wrapped ];

            systemd.user.services.swayidle = {
                description = "Idle management daemon";
                wantedBy = [ "graphical-session.target" ];
                after = [ "graphical-session.target" ];

                serviceConfig = {
                    ExecStart = ''
                        ${pkgs.swayidle}/bin/swayidle -w \
                        timeout ${toString cfg.lockTimeout} '${swaylock-wrapped}/bin/swaylock -f' \
${sleepTimeoutLine}                        before-sleep '${swaylock-wrapped}/bin/swaylock -f'
                    '';
                    Restart = "always";
                    RestartSec = 1;
                };
            };
        };
    };
}
