# System Setup Bootstrapper

An explicit, rerunnable bootstrapper for supported Ubuntu and Debian hosts. It installs system services and native desktop packages; Nix and Home Manager remain responsible for user packages, fonts, and dotfiles.

## Supported Matrix

| Distribution | Release | Architectures | Notes |
| --- | --- | --- | --- |
| Ubuntu | 24.04 (noble) | `x86_64`, `aarch64` | All components except `nvtop` on `aarch64` |
| Debian | 12 (bookworm) | `x86_64`, `aarch64` | All components except `nvtop` on `aarch64`; Ghostty must exist in configured Debian repositories |

Other distributions, codenames, and releases fail before apply. `nvtop` uses an upstream x86_64 AppImage and is therefore x86_64-only. `flatpak` converges a Chrome-only managed list and is likewise x86_64-only. Desktop package availability is checked by each component after it refreshes APT metadata; an active GUI session is not required.

## Commands

Exactly one profile or one component is required:

```bash
./install.sh --profile PROFILE [--add COMPONENT]... [--remove COMPONENT]... [--plan] [--yes] [--add-docker-group]
./install.sh --component COMPONENT [--plan] [--yes] [--add-docker-group]
```

Examples:

```bash
./install.sh --profile workstation --plan
./install.sh --profile workstation --add nvidia --add tailscale --yes
./install.sh --profile personal --remove appearance --add default-shell
./install.sh --component tailscale --yes
./install.sh --component docker --add-docker-group --yes
```

`--plan` parses `/etc/os-release` as data, validates the platform, and resolves the final component list without writes, `sudo`, Docker daemon queries, package commands, downloads, or network access. Checks that require Docker, Rofi, a terminal, or package metadata are explicitly deferred to apply. `--yes` answers supported component confirmations; it does not imply Docker group membership. Additions and removals are valid only with profiles.

Run apply as the intended non-root user. Direct root execution is refused because user-owned files, login-shell changes, and optional group membership must target that user consistently; the component scripts invoke `sudo` for system changes. Help and planning remain available as root. `SYSTEM_SETUP_OS_RELEASE`, `SYSTEM_SETUP_ARCH`, and systemd overrides are ignored unless the internal `SYSTEM_SETUP_TEST_MODE=1` test contract is explicitly enabled.

## Profiles

Components always run in canonical order, regardless of option order. Duplicate additions are ignored and removals win.

| Profile | Exact expansion |
| --- | --- |
| `base` | `nix` |
| `personal` | `nix ghostty launcher appearance flatpak` |
| `workstation` | `nix docker ghostty launcher i3 keybindings appearance flatpak` |
| `server` | `nix docker` |

## Components

| Component | Main side effects and ownership |
| --- | --- |
| `nix` | Installs pinned Determinate Nix when absent and ensures `nix-command`/flakes are enabled. Does not add channels or install Home Manager. |
| `docker` | Neutralizes stale installer-owned `docker.list`/`docker.sources` files before the first APT update, then converges Docker's canonical official repository, Engine packages, Compose plugin, and systemd service. It verifies the daemon through `sudo docker info` and does not change group membership by default. |
| `nvidia` | Installs NVIDIA Container Toolkit when needed, always converges the Docker runtime, and verifies Docker through sudo. Requires selected `docker` or a working existing privileged Docker installation. |
| `tailscale` | Installs and enables `tailscaled`; enables IPv4/IPv6 forwarding for exit-node use. Authentication and route advertisement remain manual. |
| `ghostty` | Installs Ghostty from APT. Ubuntu may use the validated noble PPA fallback; Debian never receives an Ubuntu PPA. |
| `launcher` | Owns the Rofi package and the fallback `~/.config/rofi/config.rasi`. When that path is managed elsewhere (symlink), the installer leaves it untouched; a differing real file is backed up before replacement. |
| `i3` | Installs i3, Polybar, wallpaper tools, and managed i3/Polybar files. It does not own Rofi and standalone apply requires Rofi to exist before any mutation. |
| `keybindings` | Installs the terminal helper and configures GNOME `Ctrl+Alt+T` when applicable. |
| `appearance` | Installs Papirus icons and builds `Gruvbox-Dark`, `-hdpi`, and `-xhdpi` inside one marked, versioned bundle. Only `~/.themes/Gruvbox-Dark` is published; arbitrary or broken links and unmanaged files/directories at that path are left byte-identical and require manual removal. It does not install fonts. |
| `flatpak` | Installs the Flatpak runtime, ensures the Flathub remote (system scope), and converges `configs/flatpak-apps.txt` (Chrome only; x86_64-only). Cursor/VSCode stay manual (not on Flathub). |
| `default-shell` | Requires zsh from the separately deployed nix-config at `~/.nix-profile/bin/zsh`, registers it in `/etc/shells`, and changes the login shell after confirmation or `--yes`. It never mutates the Nix profile. |
| `nvtop` | Installs and verifies the pinned upstream x86_64 AppImage in `~/.local/bin`. |

Nix owns user fonts. Home Manager configuration and dotfiles are handled separately.

## Docker Group Warning

Rootful Docker group membership is effectively root access. The installer never adds a user automatically. Pass `--add-docker-group` only when that access is intended; log out and back in afterward. This flag has no effect unless the `docker` component is selected.

## Terminal Shortcuts

The installed `open-terminal` helper chooses `$TERMINAL`, `ghostty`, `x-terminal-emulator`, `i3-sensible-terminal`, then `gnome-terminal`. It rejects itself as `$TERMINAL` to prevent recursion. Standalone `i3` requires both existing Rofi and a usable terminal before writes; standalone `keybindings` requires a terminal. The workstation profile installs launcher and Ghostty first.

Key i3 shortcuts:

| Action | Shortcut |
| --- | --- |
| Open terminal | `Win + Enter` |
| Open launcher | `Win + d` |
| Close window | `Win + Shift + q` |
| Help | `Win + Shift + ?` |
| Restart i3 | `Win + Shift + r` |

## Reruns

Component scripts verify existing installations and continue to repair required configuration instead of treating an existing executable as completion. Managed files are replaced atomically where practical. Package managers and service enablement are convergent, though APT metadata refreshes and remote repository checks still occur on apply. Existing i3 configuration is backed up before replacement when that component runs.

No universal rollback is attempted. Review `--plan` and the component side effects before apply.

## Current Workstation Migration

Migration of the current workstation is a mandatory clean break from the previous installer. Use the system profile with both host capabilities added explicitly:

```bash
./install.sh --profile workstation --add nvidia --add tailscale --plan
./install.sh --profile workstation --add nvidia --add tailscale --yes
```

Do not apply the bare workstation profile on that host: omitting `--add nvidia --add tailscale` would stop converging its current GPU-container and Tailscale capabilities. The workstation preset intentionally remains `nix docker ghostty launcher i3 keybindings appearance`; hardware- and host-specific services stay explicit additions rather than silently becoming defaults for every workstation.

## Fresh Machine Sequence

1. Install Ubuntu 24.04 or Debian 12 and ensure the user has `sudo` access and network connectivity.
2. Clone this repository using the machine's chosen authentication setup.
3. Run `./install.sh --profile workstation --plan` or the appropriate server/personal profile. For the current workstation, use the mandatory migration command above instead.
4. Apply with `./install.sh --profile workstation --yes`. For the current workstation, retain both explicit additions shown above.
5. Reboot or log out, then select i3 if installed.
6. Deploy Home Manager and dotfiles separately.
7. Add explicit host extras as needed. NVIDIA and Tailscale are mandatory explicit additions on the current workstation.

For a Tailscale exit node, authenticate and advertise it after installation:

```bash
sudo tailscale up
sudo tailscale set --advertise-exit-node
```

Approve the machine in the Tailscale admin console. The installer does not authenticate Tailscale, advertise routes, or broaden firewall forwarding policy.

## Validation

Run local validation before review:

```bash
bash tests/run.sh
git ls-files -z '*.sh' | while IFS= read -r -d '' script; do bash -n "$script"; done
git ls-files -z '*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
git diff --check
if git grep -nEi 'alacri[t]ty|ki[t]ty' --; then exit 1; fi
```
