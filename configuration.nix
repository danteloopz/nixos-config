# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Set a limit on the number of generations to include in boot
  boot.loader.systemd-boot.configurationLimit = 20;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "kvm.enable_virt_at_load=0" ];

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.networkmanager.enable = true;
  networking.hostName = "nixos"; # Define your hostname.

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
  programs.hyprlock.enable = true;
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
     wlogout # Logout Manager
     hyprpolkitagent # Authentication agent for hyprland
     stow # Manage dotfiles
     vesktop # Better discord
     signal-desktop # Encrypted messenger
     spotify # Music
     pavucontrol # Audio manager
     hyprshot # Screenshots on Hyprland
     nwg-look # Cursors and looks
     swww # Wallpapers
     gnat15 # cpp utils
     gdb # cpp debugger
     obsidian #  Notes
     libreoffice-qt-fresh # Office suite
     gimp2-with-plugins # Image editing program
     bibata-cursors # Cursors
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
  #services.openssh.enable = true;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true; 
    user = "dante";
    configDir = "/home/dante/.config/syncthing";
  };

  # Printing
  services.printing.enable = true;

  # Nix settings
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.settings.auto-optimise-store = true;

  # Enable auto-upgrades.
  system.autoUpgrade = {
    enable = true;
    # Run daily
    dates = "daily";
    # Build the new config and make it the default, but don't switch yet.  This will be picked up on reboot.  This helps
    # prevent issues with OpenSnitch configs not well matching the state of the system.
    operation = "boot";
  };

  system.stateVersion = "25.11";

}
