# System Setup

Ansible provisioning for personal Linux machines. Native packages and services belong here; Nix and Home Manager own user packages, fonts, and personal dotfiles.

The `experiment/ansible` branch adds an Ansible implementation of all twelve existing components. The original Bash entry point remains available during migration; its instructions are in [docs/legacy-bootstrap.md](docs/legacy-bootstrap.md).

## Platforms

| Platform | Package backend | Scope |
| --- | --- | --- |
| Ubuntu 24.04 | APT and signed vendor repositories | System capabilities and optional i3 desktop |
| Debian 12 / 13 | APT and signed vendor repositories | System capabilities; Ghostty needs a repository that packages it |
| Arch Linux | pacman, official repositories | System capabilities and optional i3 desktop |
| Omarchy | Arch backend | Personal system capabilities; Omarchy keeps ownership of its desktop |

The Docker tests run on x86_64. Debian-family tasks also accept aarch64, with architecture-specific repository settings and Nix installer checksums, but ARM64 has not been integration-tested. Chrome requires x86_64; the Debian-family nvtop component uses an x86_64 AppImage. Arch/Omarchy ARM64 is outside this experiment's supported matrix.

On Arch, fully update the machine before provisioning. Use Omarchy's own updater on Omarchy. Ansible installs missing packages against the existing package database and does not refresh that database independently or perform an OS upgrade. No AUR helper is used.

## Install the tooling

Run from the repository root as your normal account. The controller requires Python 3.12 or newer; target machines need Python 3.9 or newer and sudo. With [uv](https://docs.astral.sh/uv/) installed:

```bash
uv venv --python 3.12 .venv
uv pip install --python .venv/bin/python -r ansible/requirements.txt
source .venv/bin/activate
ansible-galaxy collection install -r ansible/requirements.yml
```

The requirements pin Ansible Core 2.20.2 and the collections used by the playbook and Docker test connection. The supplied inventory provisions localhost using its system Python.

## Run

Resolve the selection and validate the host first:

```bash
ansible-playbook -i ansible/inventory.ini ansible/site.yml \
  -K -e setup_user="$USER" -e @ansible/hosts/omarchy.yml --tags plan
```

Apply by removing `--tags plan`:

```bash
ansible-playbook -i ansible/inventory.ini ansible/site.yml \
  -K -e setup_user="$USER" -e @ansible/hosts/omarchy.yml
```

`-K` asks for the sudo password. Omit it when passwordless sudo is already configured. Supply `setup_user` explicitly, especially when provisioning another machine. The home directory is looked up from that machine's account database.

For the existing Ubuntu workstation, use `ansible/hosts/workstation.yml`; it includes NVIDIA Container Toolkit and Tailscale. To install only selected components:

```bash
ansible-playbook -i ansible/inventory.ini ansible/site.yml \
  -K -e setup_user="$USER" \
  -e '{"setup_components":["docker","nvidia","tailscale"]}'
```

To customize a profile:

```bash
ansible-playbook -i ansible/inventory.ini ansible/site.yml \
  -K -e setup_user="$USER" -e setup_profile=workstation \
  -e '{"setup_add":["tailscale"],"setup_remove":["appearance","flatpak"]}'
```

Components run in dependency order. Removals win. An explicit `setup_components` list cannot be combined with a profile or additions/removals.

`--tags plan` gathers facts and validates the selection without running component tasks. It does not check remote package availability. Ansible may need sudo and writes its normal temporary module files; this differs from the legacy offline `--plan` contract. `--check --diff` is useful after the first apply. On a fresh host, it cannot simulate packages or commands supplied by repositories that have not yet been added, and may fail on those missing prerequisites.

## Profiles

| Profile | Components |
| --- | --- |
| `base` | nix |
| `personal` | nix, ghostty, launcher, appearance, flatpak |
| `workstation` | nix, docker, ghostty, launcher, i3, keybindings, appearance, flatpak |
| `server` | nix, docker |
| `omarchy` | nix |

The example Omarchy host file adds Tailscale. Add Docker or NVIDIA explicitly if you want this repository to manage them. Selecting `omarchy`, or detecting `~/.local/share/omarchy` for the target user, blocks the desktop and login-shell components before package changes. Hyprland, themes, launcher settings, and Omarchy updates remain under Omarchy's control.

## Component behavior

| Component | Ansible behavior |
| --- | --- |
| `nix` | Installs checksum-pinned Determinate Nix when absent; adds CLI/flake features to a real user config file; verifies Nix as the target user. A new installation requires systemd. |
| `docker` | Installs Engine, Compose, and Buildx; starts/enables the service and verifies the daemon. Group membership requires `setup_docker_group: true`. |
| `nvidia` | Installs Container Toolkit and merges the NVIDIA runtime into `daemon.json`, preserving unrelated settings. Restarts Docker only when configuration changes. Requires selected or existing Docker. GPU drivers are separate. |
| `tailscale` | Installs/enables the daemon and configures forwarding by default. Set `setup_tailscale_forwarding: false` to leave forwarding unmanaged. Authentication and route advertisement are manual. |
| `ghostty` | Uses configured native repositories. Ubuntu 24.04 can use the existing PPA fallback; Debian never receives that PPA. |
| `launcher` | Installs Rofi and its fallback configuration. |
| `i3` | Installs i3/Polybar and existing configuration assets. Uses Feh for wallpaper loading on both backends. Requires a terminal and Rofi. |
| `keybindings` | Installs/verifies the terminal helper. GNOME dconf changes require `setup_gnome_keybindings: true`; existing shortcut entries are retained. |
| `appearance` | Installs Papirus and builds checksum-pinned Gruvbox assets as the user. Validates generated files before publishing a versioned theme link. |
| `flatpak` | Installs the runtime, system Flathub remote, and `setup_flatpak_apps` (Chrome by default). |
| `default-shell` | Registers and selects the existing `~/.nix-profile/bin/zsh`; deploy Home Manager first. Selecting this component authorizes the shell change. |
| `nvtop` | Uses Arch's native package or the existing pinned Debian-family AppImage. |

Ansible backs up differing real desktop configuration files. Symlinked destination files and immediate parent directories are left to their existing manager. The appearance migration refuses an existing theme link pointing outside its versioned bundle: move the old `~/.themes/Gruvbox-Dark` path aside before selecting that component.

APT signing keys retain the legacy pinned fingerprints. The matching legacy `.list` files are backed up and replaced by deb822 `.sources` files. Package installs use `state: present`; package upgrades belong to the host's normal update process.

## Tests

```bash
yamllint ansible tests/ansible .github/workflows/ansible.yml
ansible-lint --offline ansible/site.yml tests/ansible/*.yml
ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check
bash tests/ansible/run.sh
TEST_DESKTOP=1 bash tests/ansible/run.sh ubuntu:24.04 archlinux:base
```

The Docker runner builds disposable Ubuntu, Debian, and Arch containers, installs real packages, checks configuration preservation, reapplies and requires `changed=0`, then exercises check mode. The Arch test also simulates Omarchy's ownership marker and checks that desktop components are rejected. `TEST_DESKTOP=1` adds headless i3 configuration checks and a real Gruvbox build with a second-run idempotency check. CI runs this expanded suite on all four images.

Containers use `setup_manage_services: false`. They test package/configuration behavior, not systemd startup, Docker daemon operation, Nix installation, GPU access, a live desktop session, or a complete Omarchy installation. Those need a booted VM or real machine. Flatpak application downloads, the Ghostty PPA fallback, Nix, and login-shell changes require additional integration coverage before replacing the legacy installer on the current workstation.

## Layout

```text
ansible/site.yml                  Playbook entry point
ansible/hosts/                    Example host selections
ansible/roles/setup/defaults/     Profiles and configurable settings
ansible/roles/setup/vars/         Distro package mappings
ansible/roles/setup/tasks/        Native Ansible component tasks
tests/ansible/                   Docker fixtures, assertions, and runner
```

The Ansible path does not invoke the legacy provisioning scripts. The remaining command tasks handle external installers, build steps, read-only checks, and live sysctl settings.
