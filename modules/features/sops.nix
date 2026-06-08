{ self, inputs, ... }: {
  flake.nixosModules.sops = { config, lib, pkgs, ... }: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops = {
      age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];
      
      defaultSopsFormat = "yaml";
      
      defaultSopsFile = ../../secrets.yaml; 
    };
  };
}
