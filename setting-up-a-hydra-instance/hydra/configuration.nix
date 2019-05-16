{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "appuipieds";
  networking.networkmanager.enable = true; # !! IMPORTANT !! without this DHCP doesn't work on the interfaces
  networking.firewall.allowedTCPPorts = [
    8080 # Hydra web UI
    5000 # nix-serve daemon (Nix cache)
  ];

  time.timeZone = "Europe/Paris";

  environment.systemPackages = with pkgs; [
    wget vim git
  ];

  # Hydra CI service
  services.hydra.enable = true;
  services.hydra.hydraURL = "http://appuipieds.company.com";
  services.hydra.notificationSender = "fghibellini@company.com";
  services.hydra.port = 8080;
  services.hydra.logo = ./custom-logo.png;
  # services.hydra.buildMachinesFiles = [];
  nix.buildMachines = [
    # localhost is included as a build machine even by default
    # but it has no supportedFeatures listed
    # this effectively means that your builds will at first work
    # but the first time you push a test, it will get stuck in the
    # queue without any debugging information (there are simply no builders that can process the job)
    { hostName = "localhost";
      system = "x86_64-linux";
      supportedFeatures = ["kvm" "nixos-test" "big-parallel" "benchmark"];
      maxJobs = 8;
    }
  ];

  # nix-serve - Nix cache daemon
  services.nix-serve.enable = true;
  # I didn't manage to get signing to work
  # services.nix-serve.secretKeyFile = "${./secret-signing-key}"; # generated with `nix-store --generate-binary-cache-key`

  # for remote access to the machine
  services.openssh.enable = true;

  nix.extraOptions = ''

    # these are the only urls that will be available at evaluation time
    allowed-uris = https://github.com/NixOS/nixpkgs.git git@git.company.com:user/peqnp.git

    # fghibellini was added because otherwise you will not be able to copy non-signed derivations to the machine with `nix copy`
    # hydra-queue-runner is trusted by default but the moment you specify the field it no longer is and it breaks the builds
    trusted-users = fghibellini hydra-queue-runner

  '';

  # without this any ssh connections will not succeed as they will require interractive approval of signatures
  programs.ssh.extraConfig = ''
    StrictHostKeyChecking no
  '';

  users = {
    mutableUsers = false; # new users are accepted as pull requests !
    users = {

      root = {
        # this hashed password can be generated with:
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
