# NixOS configuration for host "nixos" (user: dante)
# Help: configuration.nix(5), `nixos-help`
#
# Layout of this file:
#   1. Local variables
#   2. Imports
#   3. Nix & nixpkgs
#   4. Boot
#   5. Hardware
#   6. Networking
#   7. Localization
#   8. Users
#   9. Disks
#  10. Desktop (Hyprland, login, portals, default apps, fonts)
#  11. Audio
#  12. Services (sync, printing, discovery)
#  13. Virtualization
#  14. Local LLM (llama.cpp)
#  15. Programs
#  16. System packages
#  17. Updates & state version

{ config, pkgs, lib, ... }:

let
  # --- 1. LOCAL VARIABLES ---

  # Desktop entry that opens directories in yazi inside foot.
  # The stock yazi.desktop has Terminal=true, which GIO/portals can't launch
  # with foot, so "Open in folder" from Firefox silently did nothing.
  yaziFoot = pkgs.makeDesktopItem {
    name = "yazi-foot";
    desktopName = "Yazi (foot)";
    exec = "${pkgs.foot}/bin/foot -e ${pkgs.yazi}/bin/yazi %f";
    terminal = false;
    mimeTypes = [ "inode/directory" ];
    categories = [ "System" "FileManager" "FileTools" ];
  };

  # Where the LLM weights live. Must be readable by the (dynamic) llama-cpp user,
  # which is why it is NOT under /home.
  llamaModelDir = "/var/lib/llama-models";
  llamaModel = "${llamaModelDir}/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";


  # tuigreet command line, split out of the greetd block for readability.
  sessionDirs = config.services.displayManager.sessionData.desktops;
  tuigreetCmd = lib.concatStringsSep " " [
    "${pkgs.tuigreet}/bin/tuigreet"
    "--sessions ${sessionDirs}/share/wayland-sessions"
    "--xsessions ${sessionDirs}/share/xsessions"
    "--remember"
    "--remember-user-session"
    "--user-menu"
    "--user-menu-min-uid 1000"
    "--asterisks"
    "--power-shutdown 'shutdown -P now'"
    "--power-reboot 'shutdown -r now'"
  ];
in
{
  # --- 2. IMPORTS ---
  imports = [ ./hardware-configuration.nix ];

  # --- 3. NIX & NIXPKGS ---
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.joypixels.acceptLicense = true;

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # --- 4. BOOT ---
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20; # Keep at most 20 generations in the boot menu
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages; # Default kernel (use pkgs.linuxPackages_latest for bleeding edge)
  # If VirtualBox and KVM ever fight over virtualization extensions, try:
  # boot.kernelParams = [ "kvm.enable_virt_at_load=0" ];

  # --- 5. HARDWARE ---
  hardware.enableRedistributableFirmware = true; # AMD GPU firmware + microcode source
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # --- 6. NETWORKING ---
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Uncomment to block distracting sites:
  networking.extraHosts = ''
    0.0.0.0 youtube.com
    0.0.0.0 www.youtube.com
    0.0.0.0 m.youtube.com
    0.0.0.0 youtu.be
    0.0.0.0 twitch.tv
    0.0.0.0 www.twitch.tv
    0.0.0.0 claude.ai
  '';

  # --- 7. LOCALIZATION ---
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "pl2";
  services.xserver.xkb = {
    layout = "pl";
    variant = "";
    options = "caps:escape";
  };

  # --- 8. USERS ---
  users.users.dante = {
    isNormalUser = true;
    description = "dante";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "vboxusers" # VirtualBox
      "kvm"
      "docker"    # NOTE: docker group is root-equivalent
    ];
  };

  # --- 9. DISKS ---
  # External exFAT USB drive, mounted on first access.
  fileSystems."/mnt/usb" = {
    device = "/dev/disk/by-uuid/6A72-9D94";
    fsType = "exfat";
    options = [
      "defaults"
      "noatime"
      "nofail"                          # never block boot if the drive is absent
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=5"
      "uid=1000"                        # exFAT has no permissions: make it owned by dante
      "gid=100"
      "umask=022"
    ];
  };
  services.udisks2.enable = true; # Needed to connect USB devices in calibre

  # --- 10. DESKTOP ---

  # Window manager
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
    # Explicit so the portal that gets installed is the one matching Hyprland
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # Login manager
  services.greetd = {
    enable = true;
    useTextGreeter = true; # stops boot messages from drawing over the TUI
    settings.default_session.command = tuigreetCmd;
  };

  # Portals (screensharing, file chooser, etc.)
  # programs.hyprland already installs xdg-desktop-portal-hyprland; we only add gtk.
  # Config is keyed on "hyprland" because XDG_CURRENT_DESKTOP=Hyprland takes
  # precedence over "common". Screencast/screenshot go to hyprland, the rest to gtk.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common.default = [ "hyprland" "gtk" ];
      hyprland.default = [ "hyprland" "gtk" ];
    };
  };

  # Default applications
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/sgnl" = [ "signal.desktop" ];
      "x-scheme-handler/signalcaptcha" = [ "signal.desktop" ];
      "x-scheme-handler/discord" = [ "discord-ptb.desktop" ];
      "x-scheme-handler/terminal" = [ "foot.desktop" ];

      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];

      "application/pdf" = [ "firefox.desktop" ];
      "image/png" = [ "firefox.desktop" ];
      "image/jpeg" = [ "firefox.desktop" ];
      "image/gif" = [ "firefox.desktop" ];
      "image/webp" = [ "firefox.desktop" ];
      "image/bmp" = [ "firefox.desktop" ];

      "application/lrf" = [ "calibre-lrfviewer.desktop" ];
      "inode/directory" = [ "yazi-foot.desktop" ];
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    # UI / text
    noto-fonts
    noto-fonts-cjk-sans
    lato
    liberation_ttf
    open-sans
    roboto
    ubuntu-classic
    corefonts
    # Emoji / icons
    noto-fonts-color-emoji
    joypixels
    font-awesome
    # Monospace / coding
    nerd-fonts.jetbrains-mono # the default monospace below needs the Nerd variant
    jetbrains-mono
    monaspace
    anonymousPro
    fira-code
    fira-code-symbols
  ];
  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [ "JetBrainsMono Nerd Font Mono" ];
  };

  # --- 11. AUDIO ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- 12. SERVICES ---

  # File sync
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "dante";
    group = "users";
    dataDir = "/home/dante"; # default (/var/lib/syncthing) is wrong when running as dante
    configDir = "/home/dante/.config/syncthing";
  };

  # Network service discovery (printers, etc.)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Printing: Brother HL-L2442DW
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      brlaser              # open-source driver for Brother laser printers
      brgenml1cupswrapper  # Brother's generic laser driver (fallback)
    ];
  };

  # Optional: declare the printer so it doesn't have to be added through the web UI.
  # Find the address in the printer's own menu (or your router), ideally reserve it in DHCP.
  hardware.printers = {
    ensurePrinters = [{
      name = "Brother_HL-L2442DW";
      deviceUri = "ipp://192.168.0.122/ipp/print";
      model = "everywhere"; # driverless IPP; swap for a brlaser/Brother PPD if output is wrong
    }];
    ensureDefaultPrinter = "Brother_HL-L2442DW";
  };

  # --- 13. VIRTUALIZATION ---
  virtualisation.virtualbox.host = {
    enable = true;
    # enableExtensionPack = true;
    # enableKvm = true;
    # addNetworkInterface = false;
  };

  virtualisation.docker.enable = true; # the package alone gave a CLI with no daemon

  # --- 14. LOCAL LLM (llama.cpp, ROCm) ---
  #   hf download unsloth/Qwen3.6-35B-A3B-GGUF Qwen3.6-35B-A3B-Q4_K_M.gguf --local-dir /var/lib/llama-models
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-rocm;

    model = llamaModel;
    extraFlags = [
      "--n-gpu-layers" "all"
      "--n-cpu-moe" "99"
      "--ctx-size" "32768"
      "--flash-attn" "on"
      "-ctk" "q4_0"
      "-ctv" "q4_0"
      "-t" "8"
      "--mmap"
      "--mmproj" "${llamaModelDir}/mmproj-BF16.gguf"
      "--cache-type-k" "q4_0"
      "--cache-type-v" "q4_0"
      "-b" "1024"
      "-ub" "512"
    ];
  };

  systemd.services.llama-cpp = {
    # Don't crash-loop before the model has been downloaded.
    unitConfig.ConditionPathExists = llamaModel;
    # The service runs as a dynamic user; ROCm needs /dev/kfd and /dev/dri.
    serviceConfig.SupplementaryGroups = [ "render" "video" ];
  };

  # Model directory: writable by dante (for downloads), readable by the service.
  systemd.tmpfiles.rules = [
    "d ${llamaModelDir} 0775 dante users - -"
  ];

  # --- 15. PROGRAMS ---
  programs.zsh.enable = true;
  programs.ssh.startAgent = true;
  programs.htop.enable = true;
  programs.firefox.enable = true;
  programs.waybar.enable = true;
  programs.hyprlock.enable = true;
  programs.obs-studio.enable = true;
  programs.nix-ld = {
    enable = true; # run prebuilt binaries (uv/pip wheels, etc.)
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
    ];
  };

  # --- 16. SYSTEM PACKAGES ---
  environment = {
    localBinInPath = true;
    systemPackages = with pkgs; [
      # Hyprland ecosystem
      foot # Terminal
      rofi # App launcher
      mako # Notifications
      wlogout # Logout menu
      hyprpolkitagent # Authentication agent
      hyprshot # Screenshots
      hyprsunset # Blue light filter
      awww # Wallpapers
      nwg-look # Cursors and looks
      bibata-cursors # Cursor theme
      wl-clipboard
      cliphist # Clipboard history
      qt5.qtwayland
      qt6.qtwayland

      # CLI & system tools
      neovim # Text editor
      git
      stow # Dotfile manager
      yazi # File manager
      yaziFoot # Desktop entry: yazi inside foot (used for inode/directory)
      p7zip # 7z
      ffmpeg # Converter
      exiftool
      pavucontrol # Audio manager

      # Development
      vscodium
      gcc # C/C++ compiler
      gdb # Debugger
      nodejs
      uv # Python package/project manager

      # AI / LLM
      llama-cpp-rocm # CLI tools; the server itself runs as a service (section 14)
      python3Packages.huggingface-hub # `hf` CLI for downloading models

      # Apps
      keepassxc # Password manager
      signal-desktop # Encrypted messenger
      discord-ptb
      webex
      obsidian # Notes
      libreoffice-qt-fresh # Office suite
      gimp2-with-plugins # Image editing
      calibre # Ebooks
      vlc # Video and audio player
      qbittorrent
    ];
  };

  # --- 17. UPDATES & STATE VERSION ---
  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    # Build the new config and make it the boot default, but don't switch live;
    # it takes effect on the next reboot, so a running session is never disturbed.
    operation = "boot";
  };

  system.stateVersion = "25.11"; # Don't change after install
}
