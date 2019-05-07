
# Setting Up a Hydra Instance

While you can run Hydra on your own laptop, in a team it definitely makes sense to
setup a dedicated machine for it.
This machine will then act as the CI and as a Nix cache for all your devs.

First you need to go through the [NixOS installation process](https://nixos.org/nixos/manual/index.html#sec-installation).
The last steps of the process are

```
nixos-generate-config --root /mnt     # STEP 1
vim /mnt/etc/nixos/configuration.nix  # STEP 2
nixos-install                         # STEP 3
reboot                                # STEP 4
```

Once you generate the NixOS config file (step 1), you will want to edit the files included in [./hydra](./hydra) and copy them to `/etc/nixos`.
Then run `nixos-install` and you're ready to reboot.

> NOTE
>
> When running any command that will use the above config file you will get a warning:
>
> ```
> warning: unknown setting 'allowed-uris'
> ```
>
> This is a [bug](https://github.com/NixOS/nix/issues/2480), but the config works just fine - you can safely ignore it.

To sum up the config:

```nix
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
```

1. we enable the `networkmanager` service whithout which DHCP doesn't work
2. we open the two ports 8080 (for the Hydra web UI) and 5000 (for the Nix cache)
3. we include `wget` and `git` whithout which we might fail to fetch some repos, and add `vim` cause how else would we further modify this config file in the future ;)
4. enable the hydra service
5. `nix.buildMachines` is by default empty and builds will work. That it until you want to run tests, those require the features listed in `supportedFeatures` which are not listed on the default build machine, and so those jobs will simply get stuck in the queue without any debug information.
6. the `nix-serve` service enables the Nix cache (on port 5000 by default).
7. openssh for remote access
8. in `nix.extraOptions` we set the `allowed-uris` Nix option. The Hydra evaluations are performed in pure mode. And will not have access to any urls other than the ones specified as inputs in the UI. This option circumvents this and gives it access to the repositories.
9. `programs.ssh.extraConfig.StrictHostKeyChecking` is also necessary to access the repos
10. we will declaratively manager our users so we set a hashedPassword for root and add public keys for users. This means you can accept new users as pull requests!


## Adding the Hydra instance as a cache

Now on your client machines you have to modify your `/etc/nix/nix.conf` file to:

```
binary-caches = http://10.0.0.25:5000/ http://cache.nixos.org/
require-sigs = false
```

Where `10.0.0.25` is the IP address of your Hydra instance.

# TODO Darwin caching

TODO darwin builder
TODO cover `nix copy --to ssh://appuipieds $(nix-instantiate shell.nix)`
