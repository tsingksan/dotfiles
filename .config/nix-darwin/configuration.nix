{ config, pkgs, ... }:

{
  nix = {
    channel.enable = false;
    settings = {
      use-xdg-base-directories = true;
      experimental-features = "nix-command flakes";
      substituters = [
        "https://cache.nixos.org/"
        # "https://mirrors.ustc.edu.cn/nix-channels/store"
        # "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "mirrors.ustc.edu.cn:UmPCkKFZlHGKKMEMW4Cambh2I6WDhQQCCwMD1YzuFRw="
      ];
    };
    optimise = {
      automatic = true;
      interval = [
        {
          Weekday = 7;
        }
      ];
    };
  };
  

  users.users.todd = {
    home = "/Users/todd";
  };

  environment.systemPackages = with pkgs; [
    git vim tmux stow neovim
    gnupg pinentry_mac
    fastfetch htop
    kitty
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    brews = [];
    casks = [
      "1password"
      "appcleaner"
      "brave-browser"
      "chatgpt"
      "cursor"
      "firefox"
      "fork" 
      "maccy"
      "rectangle"
      "snipaste"
      "spotify"
      "telegram"
      "visual-studio-code"
      "wechat"
      "thunderbird@esr"
      "localsend"
      "keepassxc"
      "ddpm"
      "typora"
      "wechatwork"
    ];
  };

  # environment.variables = {
    # TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
  # };
  programs.nix-index.enable = true;

  environment.darwinConfig = "$HOME/.config/nix-darwin";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment.launchAgents.mihomo = {
    enable = true;
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>mihomo</string>
        <key>ProgramArguments</key>
        <array>
          <string>${pkgs.mihomo}/bin/mihomo</string>
          <string>-d</string>
          <string>${config.users.users.todd.home}/.config/mihomo</string>
        </array>
        <key>KeepAlive</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>${config.users.users.todd.home}</string>
        <key>StandardOutPath</key>
        <string>${config.users.users.todd.home}/Library/Logs/mihomo.log</string>
        <key>StandardErrorPath</key>
        <string>${config.users.users.todd.home}/Library/Logs/mihomo.err</string>
      </dict>
      </plist>
    '';
    target = "mihomo.plist"; # 文件名
  };
}
