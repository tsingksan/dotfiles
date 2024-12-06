{ config, pkgs, ... }:

{
  # Home Manager 配置
  home = {
    username = "todd";
    homeDirectory = "/Users/todd";
    stateVersion = "24.11";

    packages = with pkgs; [
      postgresql rustup zls
      mihomo 
      mise
    ];
  };

  # 程序配置
  # programs = {
    # # Git 配置
    # git = {
    #   enable = true;
    #   userName = "Your Name";
    #   userEmail = "your.email@example.com";
    #   extraConfig = {
    #     core.editor = "nvim";
    #   };
    # };

    # # Shell 配置 (以 zsh 为例)
    # zsh = {
    #   enable = true;
    #   enableCompletion = true;
    #   autosuggestion.enable = true;
    #   syntaxHighlighting.enable = true;
    # };

    # # Neovim 配置
    # neovim = {
    #   enable = true;
    #   viAlias = true;
    #   vimAlias = true;
    # };
  # };

  # 文件链接和配置
  home.file = {
    # ".config/some-config".source = ./dotfiles/some-config;
  };
}