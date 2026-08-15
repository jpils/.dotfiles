{ self, inputs, ... }: {
  flake.nixosModules.userSecurity = { config, lib, pkgs, ... }: {
    options.jay.userSecurity.sudo.u2f = {
      enable = lib.mkEnableOption "FIDO2/pam_u2f sudo authentication";

      unixFallback = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Keep Unix password sudo fallback during YubiKey enrollment/testing.";
      };

      origin = lib.mkOption {
        type = lib.types.str;
        default = "pam://nixconf";
        description = "Stable pam_u2f origin used when enrolling credentials.";
      };
    };

    config = lib.mkIf config.jay.userSecurity.sudo.u2f.enable {
      environment.systemPackages = with pkgs; [ pam_u2f yubikey-manager ];

      sops.secrets.u2f_keys = {
        mode = "0400";
      };

      security.pam.u2f.settings = {
        authfile = config.sops.secrets.u2f_keys.path;
        cue = true;
        pinverification = 1;
        userpresence = 1;
        origin = config.jay.userSecurity.sudo.u2f.origin;
      };

      security.pam.services.sudo = {
        unixAuth = config.jay.userSecurity.sudo.u2f.unixFallback;
        u2f = {
          enable = true;
          control = "sufficient";
        };
      };

      security.sudo.extraConfig = ''
        Defaults timestamp_timeout=0
      '';
    };
  };
}
