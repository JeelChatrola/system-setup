# Flatpak plan (system-setup owns GUI apps)

## Ground reality (2026-09-12)

- Host has Flatpak 1.14.6 with the `flathub` remote (`system` scope).
- `flatpak list --app` shows 4 system installs (all `--system`, none `--user`):
  - `app.zen_browser.zen` (Zen 1.22b)
  - `com.brave.Browser` (Brave 1.95.101)
  - `com.google.Chrome` (153.0.8010.36-1)
  - `org.videolan.VLC` (3.0.23)
- `main` README told users to install Chrome/Zen/Cursor manually or via Flatpak,
  but `install.sh` had no Flatpak path. This stub closes that gap.
- No Flatpak component exists yet on `main` or on `impl/modular-machines` (PR #5);
  that PR rewrites the installer around profiles/components with `--plan`.

## Ownership

| Repository | Responsibilities |
|---|---|
| `system-setup` | Host bootstrap: apt services, Flatpak runtime + Flathub + system-wide GUI apps, desktop integration |
| `nix-config` | Home Manager CLI tools, shell/editor, dotfiles. Currently still ships Firefox/Obsidian; desktop ownership stays a separate decision (see nix-config `docs/SETUP_PLAN.md`). |
| `ai-stack` | All AI clients (Codex, OpenCode, Agent Browser via npm; Hermes/DeepTutor via uv), generated config, optional Docker services |

Flatpak never installs AI clients, Nix packages, or Home Manager state.

## What this stub does

- `debian/install-flatpak.sh [--plan] [--apps FILE] [--system|--user]`:
  - `--plan`: no writes/sudo/network; prints scope + apps that would be ensured.
  - Apply: installs `flatpak` via apt when absent, ensures the Flathub remote
    (`--system` default, matching current workstation), then installs each ID in
    `configs/flatpak-apps.txt` idempotently (`flatpak list` check first).
  - Fails non-zero when the apps file is missing or any install fails.
- `configs/flatpak-apps.txt`: the 4 observed system apps, one ID per line.
- `install.sh`: new `flatpak` CLI target + menu entry + inclusion in Install Everything.
  `main` has no global `--plan`; the script's own `--plan` covers dry-run.
  PR #5 integration (profile component + global `--plan`) is future work.

## What stays manual

- Cursor / VSCode: not on Flathub; keep the existing manual install.
- Tailscale, Docker, Nix: apt flows owned by their existing components.
- Fonts: Nix/Home Manager owns user fonts (`appearance` does not install fonts).

## Migration to PR #5 (`impl/modular-machines`)

That branch replaces the menu installer with `--profile/--component --plan/--yes`.
To carry Flatpak forward there:

1. Add a `flatpak` component row (Flathub + `configs/flatpak-apps.txt`, system scope).
2. Decide profile membership (candidate: `personal` + `workstation`, not `server`/`base`).
3. Reuse this script's `--plan` output shape for the global `--plan` contract.
4. Add `tests/` coverage: plan lists expected apps, apply is convergent, no `--user` drift.

Expect a merge conflict on `install.sh` + `README.md` if both PRs are open; rebase
this stub onto that branch and keep `configs/flatpak-apps.txt` as the single list.

## Validation

```bash
bash -n debian/install-flatpak.sh
./debian/install-flatpak.sh --plan
./debian/install-flatpak.sh --plan --user
./install.sh flatpak   # apply path (installs via sudo + network)
flatpak list --app --columns=application,installation
git diff --check
```
