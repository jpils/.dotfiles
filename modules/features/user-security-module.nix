{ self, inputs, ... }: {
  flake.nixosModules.userSecurity = { config, lib, pkgs, ... }: {
    options.jay.userSecurity = {
      sudo.u2f = {
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

      ssh.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Restore jay's SSH config, known_hosts, public keys, and SOPS-encrypted FIDO SSH handles.";
      };
    };

    config = lib.mkMerge [
      (lib.mkIf config.jay.userSecurity.sudo.u2f.enable {
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
          Defaults lecture=never
        '';
      })

      (lib.mkIf config.jay.userSecurity.ssh.enable {
        sops.secrets.ssh_id_ed25519_sk_github_yk1 = {
          owner = "jay";
          group = "users";
          mode = "0600";
          path = "/home/jay/.ssh/id_ed25519_sk_github_yk1";
        };

        sops.secrets.ssh_id_ed25519_sk_github_yk_nfc = {
          owner = "jay";
          group = "users";
          mode = "0600";
          path = "/home/jay/.ssh/id_ed25519_sk_github_yk_nfc";
        };

        system.activationScripts.sshDeclarativeState.text = ''
          install -d -m 700 -o jay -g users /home/jay/.ssh
          install -m 600 -o jay -g users ${../../config/ssh/config} /home/jay/.ssh/config
          install -m 644 -o jay -g users ${../../config/ssh/known_hosts} /home/jay/.ssh/known_hosts
          install -m 644 -o jay -g users ${../../config/ssh/id_ed25519_sk_github_yk1.pub} /home/jay/.ssh/id_ed25519_sk_github_yk1.pub
          install -m 644 -o jay -g users ${../../config/ssh/id_ed25519_sk_github_yk_nfc.pub} /home/jay/.ssh/id_ed25519_sk_github_yk_nfc.pub
        '';
      })
    ];
  };
}
