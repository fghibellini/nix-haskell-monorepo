{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "appuipieds";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 8080 5000 ];

  time.timeZone = "Europe/Paris";

  environment.systemPackages = with pkgs; [
    wget vim git
  ];

  services.hydra.enable = true;
  services.hydra.hydraURL = "http://appuipieds.yourcompany.com";
  services.hydra.notificationSender = "appuipieds@yourcompany.com";
  services.hydra.port = 8080;
  services.hydra.logo = ./your-logo.png;
  #services.hydra.buildMachinesFiles = [];
  nix.buildMachines = [
    { hostName = "localhost";
      system = "x86_64-linux";
      supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
      maxJobs = 8;
    }
  ];

  services.nix-serve.enable = true;

  services.openssh.enable = true;

  nix.extraOptions = ''
    allowed-uris = https://github.com/NixOS/nixpkgs.git git@git.yourcompany.com:john/projec-morpheus.git
  '';

  programs.ssh.extraConfig = ''
    StrictHostKeyChecking no
  '';

  users = {
    mutableUsers = false;
    users = {

      root = {
        # to gen password hash:
        # nix-shell -p mkpasswd --command 'mkpasswd -m sha-512'
        hashedPassword = "$6$BAsvcjK2489Nv0Gq$2tODxWxkH9GV6lnnaOQ8QKJKwvpBAtsf8uHRyogZEAapHE6t8yz7ZxqDlWtKYPjRB69006.z4hWS9wDbPS0LM0";
      };

      fghibellini = {
        isNormalUser = true;
        home = "/home/fghibellini";
        createHome = true;
        description = "Filippo Ghibellini";
        uid = 1001;
        extraGroups = [ "wheel" "networkmanager" ];
        openssh.authorizedKeys.keyFiles = [ ./user-keys/fghibellini.pubkey ];
      };

    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}
