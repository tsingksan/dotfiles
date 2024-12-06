
# Dotfiles Management with Nix and Stow

This repository contains all my dotfiles, which have now been fully migrated to Nix. No further updates will be made directly here. If you want to use Stow to link these dotfiles, you can use the following Git commit hash:

**Git Commit Hash:** `656687c`

---

## Using Stow to Manage Dotfiles

GNU Stow is a symlink farm manager that allows you to easily manage dotfiles by creating symbolic links in your home directory.

### Linking Dotfiles with Stow

You can use Stow to link and unlink your dotfiles with the following commands:

- **Link dotfiles**:
  ```sh
  stow [dotfiles_directory] -t ~
  ```
  Replace `[dotfiles_directory]` with the name of the specific dotfiles package you want to link.

- **Unlink dotfiles**:
  ```sh
  stow -D [dotfiles_directory] -t ~
  ```

For example, to link all your shell-related configurations:

```sh
stow . -t ~
```

To unlink them:

```sh
stow -D . -t ~
```

---

## Oh-My-Zsh (OMZ) Optimization

Oh-My-Zsh optimizations can significantly improve shell performance. Refer to the following guide for detailed steps:

[Make Oh-My-Zsh Fly!](https://blog.skk.moe/post/make-oh-my-zsh-fly/)

### Plugin Management

This project has switched to using **zinit** for managing Zsh plugins. Zinit provides faster and more flexible plugin management for Zsh.

---

## References

Here are some useful resources that inspired and guided this setup:

- [Joseph Arhar's Dotfiles](https://github.com/josepharhar/dotfiles)
