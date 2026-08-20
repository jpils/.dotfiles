{ self, inputs, ... }: {
  flake.nixosModules.userSsh = { config, lib, pkgs, ... }: let
    sshCfg = config.jay.userSecurity.ssh;

    keyType = lib.types.submodule ({ name, ... }: {
      options = {
        fileName = lib.mkOption {
          type = lib.types.str;
          default = "id_ed25519_sk_${name}";
          description = "File name under /home/jay/.ssh for this SSH private key or FIDO credential handle.";
        };

        secretName = lib.mkOption {
          type = lib.types.str;
          default = "ssh_${name}";
          description = "sops.secrets attribute containing this SSH private key or FIDO credential handle.";
        };

        publicKeySource = lib.mkOption {
          type = lib.types.path;
          description = "Public key file copied to /home/jay/.ssh/<fileName>.pub.";
        };
      };
    });

    hostType = lib.types.submodule {
      options = {
        hostName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Real SSH HostName. Null means omit HostName.";
        };

        user = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "SSH User. Null means omit User.";
        };

        identities = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Ordered key names from jay.userSecurity.ssh.keys to use as IdentityFile entries.";
        };

        identitiesOnly = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Set IdentitiesOnly yes for this host.";
        };

        addKeysToAgent = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "no";
          description = "Value for AddKeysToAgent. Null means omit.";
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Extra raw ssh_config lines for this host.";
        };
      };
    };

    usedKeyNames = lib.unique (lib.concatMap (host: host.identities) (builtins.attrValues sshCfg.hosts));
    usedKeys = lib.genAttrs usedKeyNames (keyName: sshCfg.keys.${keyName});

    sopsSshSecrets = lib.mapAttrs' (_: key: lib.nameValuePair key.secretName {
      owner = "jay";
      group = "users";
      mode = "0600";
      path = "/home/jay/.ssh/${key.fileName}";
    }) usedKeys;

    publicKeyInstallCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList (_: key: ''
      install -m 644 -o jay -g users ${key.publicKeySource} /home/jay/.ssh/${key.fileName}.pub
    '') usedKeys);

    hostConfigText = hostPattern: host: ''
      Host ${hostPattern}
      ${lib.optionalString (host.hostName != null) "  HostName ${host.hostName}"}
      ${lib.optionalString (host.user != null) "  User ${host.user}"}
      ${lib.concatMapStringsSep "\n" (keyName: "  IdentityFile ~/.ssh/${sshCfg.keys.${keyName}.fileName}") host.identities}
      ${lib.optionalString host.identitiesOnly "  IdentitiesOnly yes"}
      ${lib.optionalString (host.addKeysToAgent != null) "  AddKeysToAgent ${host.addKeysToAgent}"}
      ${host.extraConfig}
    '';

    generatedSshConfig = pkgs.writeText "jay-ssh-yubikeys-config" (
      lib.concatStringsSep "\n" (lib.mapAttrsToList hostConfigText sshCfg.hosts)
    );
  in {
    options.jay.userSecurity.ssh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Restore jay's SSH YubiKey credential handles and declarative identity order. Leaves ~/.ssh/config and known_hosts mutable/persisted.";
      };

      keys = lib.mkOption {
        type = lib.types.attrsOf keyType;
        default = {
          github_yk1 = {
            fileName = "id_ed25519_sk_github_yk1";
            secretName = "ssh_id_ed25519_sk_github_yk1";
            publicKeySource = ../../config/ssh/id_ed25519_sk_github_yk1.pub;
          };

          github_yk_nfc = {
            fileName = "id_ed25519_sk_github_yk_nfc";
            secretName = "ssh_id_ed25519_sk_github_yk_nfc";
            publicKeySource = ../../config/ssh/id_ed25519_sk_github_yk_nfc.pub;
          };

          github_yk2 = {
            fileName = "id_ed25519_sk_github_yk2";
            secretName = "ssh_id_ed25519_sk_github_yk2";
            publicKeySource = ../../config/ssh/id_ed25519_sk_github_yk2.pub;
          };
        };
        description = "SSH private keys/FIDO handles to restore from SOPS.";
      };

      hosts = lib.mkOption {
        type = lib.types.attrsOf hostType;
        default = {
          "github.com" = {
            hostName = "github.com";
            user = "git";
            identities = [ "github_yk1" "github_yk2" "github_yk_nfc" ];
            identitiesOnly = true;
            addKeysToAgent = "no";
          };
        };
        description = "Declarative ssh_config Host blocks for YubiKey identity order.";
      };
    };

    config = lib.mkIf sshCfg.enable {
      assertions = [
        {
          assertion = sshCfg.hosts != { };
          message = "jay.userSecurity.ssh.hosts must not be empty.";
        }
        {
          assertion = lib.all (keyName: builtins.hasAttr keyName sshCfg.keys) usedKeyNames;
          message = "Every jay.userSecurity.ssh.hosts.<host>.identities entry must exist in jay.userSecurity.ssh.keys.";
        }
      ];

      sops.secrets = sopsSshSecrets;

      system.activationScripts.sshYubikeyState.text = ''
        install -d -m 700 -o jay -g users /home/jay/.ssh
        install -d -m 700 -o jay -g users /home/jay/.ssh/config.d
        install -m 600 -o jay -g users ${generatedSshConfig} /home/jay/.ssh/config.d/nix-yubikeys.conf

        if [ ! -e /home/jay/.ssh/config ]; then
          install -m 600 -o jay -g users /dev/null /home/jay/.ssh/config
        fi

        if ! grep -Fxq 'Include ~/.ssh/config.d/nix-yubikeys.conf' /home/jay/.ssh/config; then
          printf '\nInclude ~/.ssh/config.d/nix-yubikeys.conf\n' >> /home/jay/.ssh/config
        fi

        chown jay:users /home/jay/.ssh/config
        chmod 600 /home/jay/.ssh/config
        ${publicKeyInstallCommands}
      '';
    };
  };
}
