# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # AMD GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  networking.hostName = "nixos"; # Define your hostname.
  
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "pl";
      #variant = "pl";
    };
  };

  # Configure console keymap
  console.keyMap = "pl2";

  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dante = {
    isNormalUser = true;
    description = "dante";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };



  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts 
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome 
    joypixels
    lato
    liberation_ttf
    open-sans
    roboto
    ubuntu-classic
    jetbrains-mono 
    monaspace 
    anonymousPro 
    fira-code 
    fira-code-symbols 
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem(lib.getName pkg) [
    "joypixels"
  ];
  nixpkgs.config.joypixels.acceptLicense = true;
  
  # Hyprland installation
  programs.hyprland = {
    enable = true;
    withUWSM = true; # recommended for most users
    xwayland.enable = true; # Xwayland can be disabled.
  };

  # Screensharing
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  programs.firefox.enable = true;
  programs.waybar.enable = true;
  programs.htop.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim # Text editor
     keepassxc # Password manager
     git # GITTTT
     foot # Terminal
     rofi # App launcher
     yazi # File manager
     mako # Notificaitons
     hyprpolkitagent # Authentication agent for hyprland
     stow # Manage dotfiles
     vesktop # Better discord
     signal-desktop # Encrypted messenger
     spotify # Music
     pavucontrol # Audio manager

     # Hyprland utilities
     hyprshot # Screenshots on Hyprland
     swww # Wallpapers
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Virtualization
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.dragAndDrop = true;
  users.extraGroups.vboxusers.members = [ "dante" ];
  virtualisation.virtualbox.host.enableHardening = false;
  #virtualisation.virtualbox.host.enableExtensionPack = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
