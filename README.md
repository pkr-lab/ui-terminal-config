# Dev Tools Bootstrap

One script, three things, for Ubuntu Desktop: installs **Starship**, the **JetBrainsMono Nerd Font**, and whichever **AI CLI tools** you opt into. Nothing else — no editor config, no plugins, no dotfile symlinks.

## Usage

```sh
git clone <repo-url> ~/dev-tools-bootstrap
cd ~/dev-tools-bootstrap
./install.sh
```

Safe to re-run any time — every step skips what's already installed.

### What it installs

1. **Starship** — via its official install script, to `~/.local/bin`
2. **AI CLI tools**, opt-in per tool (default: none installed):
   ```sh
   INSTALL_CLAUDE=true ./install.sh   # just Claude Code
   INSTALL_CODEX=true ./install.sh    # just Codex CLI
   INSTALL_GEMINI=true ./install.sh   # just Gemini CLI
   INSTALL_AGY=true ./install.sh      # just the Antigravity CLI
   # or combine any of the four
   ```
   `claude`/`codex`/`gemini` are installed via `npm install -g` (needs Node/npm on PATH already); `agy` via its own `curl | bash` installer.
3. **JetBrainsMono Nerd Font** — downloaded from the [nerd-fonts releases](https://github.com/ryanoasis/nerd-fonts/releases) (not in Ubuntu's apt repos) into `~/.local/share/fonts`

## Prerequisites

`install.sh` needs `curl` to even run — install it first if it's missing:

```sh
sudo apt install curl
```

Optionally, `npm`/`nodejs` if you want the `claude`/`codex`/`gemini` CLI tools:

```sh
sudo apt install nodejs npm
```

`unzip` is installed automatically (via `sudo apt-get install unzip`) if missing, only when the font needs unpacking.

## After install

- Add `~/.local/bin` to your `PATH` if it isn't already, so `starship` is found
- Set your shell prompt to use Starship (e.g. in `~/.bashrc`: `eval "$(starship init bash)"`)
- Set your terminal emulator's font to `JetBrainsMono Nerd Font Mono`
