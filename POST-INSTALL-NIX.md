# 🎯 Post-Install: Setting Up Nix

After running the system-level installations, follow this guide to set up Nix for your dotfiles and user packages.

## 📋 Philosophy

- **System Package Manager (apt)** = System-level stuff that needs deep integration
  - ✅ Docker, NVIDIA toolkit (kernel modules)
  - ✅ Desktop environment tools (launchers, keybindings)
  - ✅ Alacritty (for proper desktop integration)
  
- **Nix** = User-level packages and reproducible environments
  - ✅ Development tools (node, python, rust, etc.)
  - ✅ CLI utilities (ripgrep, fd, bat, etc.)
  - ✅ Your dotfiles via home-manager
  - ✅ Per-project development shells

## 🚀 Step 1: Install Nix

```bash
./install.sh nix
```

When prompted:
- Choose **multi-user installation** (recommended)
- Enable **experimental features** (flakes, nix-command) - YES
- Install **home-manager** - YES

## 🏠 Step 2: Set Up home-manager

Home-manager lets you manage your dotfiles declaratively.

### Initialize home-manager config:

```bash
# Create config directory
mkdir -p ~/.config/home-manager

# Create your home.nix
cat > ~/.config/home-manager/home.nix << 'EOF'
{ config, pkgs, ... }:

{
  # Basic info
  home.username = "YOUR_USERNAME";
  home.homeDirectory = "/home/YOUR_USERNAME";
  home.stateVersion = "23.11";

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Packages to install
  home.packages = with pkgs; [
    # CLI Tools
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
    starship
    
    # Development
    neovim
    git
    gh
    lazygit
    
    # System utilities
    htop
    btop
    tree
    tldr
    
    # Add more packages as needed
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your@email.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Zsh configuration (if using zsh)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "docker" "kubectl" ];
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  # Alacritty configuration
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "JetBrainsMono Nerd Font";
        size = 11.0;
      };
      colors = {
        primary = {
          background = "0x1e1e1e";
          foreground = "0xd4d4d4";
        };
      };
    };
  };
}
EOF
```

### Apply your configuration:

```bash
# Edit the file with your details
nano ~/.config/home-manager/home.nix

# Apply configuration
home-manager switch
```

## 📦 Step 3: Common Packages to Consider

Add these to your `home.packages` in `home.nix`:

### Development Tools
```nix
# Languages & Runtimes
nodejs
python3
rustup
go

# Version managers (if not using nix for this)
# Note: Consider using nix shells instead

# Build tools
cmake
gnumake
pkg-config
```

### CLI Productivity
```nix
# Better replacements
eza        # Better ls
bat        # Better cat
ripgrep    # Better grep
fd         # Better find
zoxide     # Better cd (with learning)
fzf        # Fuzzy finder

# Terminal multiplexers
tmux
zellij

# File managers
ranger
lf
yazi
```

### Development Utilities
```nix
jq         # JSON processor
yq         # YAML processor
httpie     # HTTP client
docker-compose  # If you want nix version
kubectl    # Kubernetes CLI
terraform  # Infrastructure as code
```

## 🔄 Step 4: Daily Workflow

### Update packages:
```bash
# Update channels
nix-channel --update

# Update home-manager
home-manager switch
```

### Search for packages:
```bash
nix search nixpkgs package-name
```

### Try a package without installing:
```bash
nix-shell -p package-name
```

### Create project-specific environments:
```bash
# Create a shell.nix in your project
cat > shell.nix << 'EOF'
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs
    python3
    postgresql
  ];
  
  shellHook = ''
    echo "Development environment loaded!"
  '';
}
EOF

# Enter the environment
nix-shell
```

## 🎨 Step 5: Dotfile Management

You can manage all your dotfiles through home-manager:

```nix
# In home.nix

# Example: Manage your shell config
home.file.".bashrc".text = ''
  # Your bashrc content
  export PATH="$HOME/.local/bin:$PATH"
'';

# Or source from a file
home.file.".config/nvim/init.vim".source = ./nvim/init.vim;

# Manage entire directories
home.file.".config/awesome".source = ./awesome;
```

## 🌟 Step 6: Advanced - Nix Flakes (Optional)

For even more reproducibility, consider using flakes:

```bash
# Create a flake.nix in your dotfiles repo
nix flake init

# Example flake.nix for home-manager
cat > flake.nix << 'EOF'
{
  description = "My Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations.YOUR_USERNAME = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
    };
  };
}
EOF

# Apply with flakes
home-manager switch --flake .#YOUR_USERNAME
```

## 📝 Tips & Best Practices

1. **Keep system and Nix separate**: Let apt handle system stuff, Nix handles user stuff
2. **Use home-manager for dotfiles**: Version control your entire config
3. **Use nix-shell for projects**: Each project gets its exact dependencies
4. **Don't use nix for kernel modules**: Docker, NVIDIA drivers → apt only
5. **Commit your home.nix**: Keep it in a git repo for easy migration

## 🔗 Useful Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/)
- [Home Manager Options](https://mipmip.github.io/home-manager-option-search/)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix in depth

## 🚀 Example: New Machine Setup

```bash
# 1. Clone your system-setup repo
git clone <your-repo> ~/system-setup
cd ~/system-setup

# 2. Run system installations
./install.sh all

# 3. Install Nix (already included in 'all')
# When prompted, enable flakes and home-manager

# 4. Clone your dotfiles (managed by Nix/home-manager)
git clone <your-dotfiles-repo> ~/.config/home-manager

# 5. Apply your configuration
home-manager switch

# 6. Log out and log back in
# Done! 🎉
```

