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

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Hardware
  #hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
 
  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  
  # Configure keymap in X11
  services.xserver.xkb = {
      layout = "pl";
      variant = "";
  };

  # Configure console keymap
  console.keyMap = "pl2";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dante = {
    isNormalUser = true;
    description = "dante";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Joypixels licence
  nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem(lib.getName pkg) [
    "joypixels"
  ];
  nixpkgs.config.joypixels.acceptLicense = true;
  
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
  programs.zsh.enable = true;

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
     gnat15 # cpp utils
     gdb # cpp debugger
     obsidian #  Notes
  ];

  # List services that you want to enable:

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Virtualization
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.dragAndDrop = true;
  users.extraGroups.vboxusers.members = [ "dante" ];
  virtualisation.virtualbox.host.enableHardening = false;
  #virtualisation.virtualbox.host.enableExtensionPack = true;

  # Login Manager
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/hyprland";
        user = "dante";
      };
      default_session = initial_session;
    };
  };


  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
  };


  # Nix settings
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "25.11";

}
