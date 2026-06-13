# groundwork

Ansible playbooks to provision a macOS developer workstation: Homebrew packages/casks, applications, and macOS system preferences.

> **Configuration files (dotfiles) live elsewhere.** Files under `$HOME` — `~/.zshrc`, `~/.gitconfig`, starship, ghostty, iTerm2, goose, the global `~/.claude/CLAUDE.md`, etc. — are managed by a separate dotfiles repo with [chezmoi](https://www.chezmoi.io/). This repo installs software and sets OS-level state only. The one config-ish exception kept here is `osx_defaults` (not file-based).

## Prerequisites

- macOS
- Python 3.12
- [Pipenv](https://pipenv.pypa.io/)

## Setup

### 1. Install Python dependencies

```bash
pipenv install
```

### 2. Install Ansible collections

```bash
bin/ansible.sh setup
```

### 3. Configuration files

**`group_vars/all.yml`** — the committed Homebrew manifest. This is the single source of truth for trivial single-formula installs (CLIs, shell plugins, terminals); only tools needing extra configuration get their own playbook. Edit it to match the toolset you want:

```yaml
homebrew_packages:
  - jq
  - kubectl
  - starship
  - tmux
  - neovim

homebrew_casks:
  - ghostty
  - vscodium
```

**`host_vars/localhost.yml`** — host-specific, non-secret variables (`git_repos`, per-cask install toggles, extra Dock apps). This file is gitignored; copy the template and edit it for the current machine:

```bash
cp host_vars/localhost.yml.example host_vars/localhost.yml
```

## Playbook reference

Every install — CLI formulae, GUI app casks, Rectangle, Claude Code (the `claude-code` cask), dockutil — lives in the `group_vars/all.yml` manifest and is applied by `homebrew.yml`. A playbook exists only when a tool needs configuration beyond install; the matching config (where any) lives in the `dotfiles` repo.

| Playbook | What it does |
|----------|-------------|
| `playbooks/site.yml` | Full provisioning — runs all playbooks in dependency order |
| `playbooks/homebrew.yml` | Bootstraps Homebrew and installs the whole manifest (`homebrew_packages` / `homebrew_casks`) — every formula and cask, in one pass |
| `playbooks/osx.yml` | macOS system preferences (Dock, Finder, input, display, Rectangle) via `osx_defaults`, plus Dock app pinning via dockutil (requires the manifest installed first) |
| `playbooks/git-repos.yml` | Creates `~/Projects` and `~/Temporary`, clones git repos with submodules, installs pre-commit hooks (requires `git_repos` in `host_vars/localhost.yml`) |

## Running playbooks

Always use `bin/ansible.sh play` instead of `ansible-playbook` directly. It handles the Pipenv environment and inventory.

```bash
bin/ansible.sh play playbooks/site.yml      # everything, in dependency order
bin/ansible.sh play playbooks/homebrew.yml  # just the Homebrew manifest
bin/ansible.sh play playbooks/osx.yml
bin/ansible.sh play playbooks/site.yml --tags osx   # a single concern by tag
```

Pass any `ansible-playbook` flags through as normal:

```bash
# Dry run
bin/ansible.sh play --check --diff playbooks/osx.yml

# Update Homebrew index and upgrade all packages (both skipped by default)
bin/ansible.sh play -e homebrew_update=true -e homebrew_upgrade_all=true playbooks/homebrew.yml
```

## Repository structure

```
.
├── bin/
│   └── ansible.sh              # Pipenv-wrapped Ansible: `setup` (galaxy) and `play` (run a playbook)
├── group_vars/
│   └── all.yml                 # Shared Homebrew manifest: homebrew_packages, homebrew_casks (committed)
├── host_vars/
│   └── localhost.yml.example   # Template for host-specific vars (git_repos, toggles); real file is gitignored
├── playbooks/                  # One self-contained playbook per concern (trivial installs live in the manifest)
├── galaxy_collections/         # Installed Ansible collections (gitignored)
└── requirements.yml            # Ansible collections: community.general
```

## Variable precedence

| File | Scope | Secret | Gitignored |
|------|-------|--------|------------|
| `group_vars/all.yml` | All hosts | No | No |
| `host_vars/localhost.yml` | This machine | No | Yes |

## Multi-machine support

The inventory is defined in `inventory.ini`. By default it targets only `localhost`:

```ini
[all]
localhost ansible_connection=local
```

To provision additional machines, add them to the inventory and create a matching `host_vars/<hostname>.yml` with machine-specific variables (`git_repos`, etc.):

```ini
[all]
localhost    ansible_connection=local
my-laptop    ansible_user=youruser
```

```yaml
# host_vars/my-laptop.yml
git_repos:
  - repo: https://github.com/user/repo.git
    dest: ~/Projects/repo
```

Each machine needs its own `host_vars/<hostname>.yml` (gitignored). Per-machine identity (git user, signing key) is handled by chezmoi in the dotfiles repo, not here.

## macOS compatibility

| macOS version | Status |
|---|---|
| Tahoe (26) | Tested |
| Older versions | Not supported |

**Known limitations:**

- Homebrew formulae compile from source (non-standard install path `~/.homebrew`) — build times vary significantly by machine.

## Development

```bash
# Run all linters
pre-commit run --all-files

# Individual linters
pipenv run yamllint .
pipenv run ansible-lint playbooks/
```
