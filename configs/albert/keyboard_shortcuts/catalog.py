import json
import os
import re
import subprocess
from pathlib import Path


def output(args, timeout=1):
    try:
        return subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              text=True, errors="replace", timeout=timeout, check=True).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def i3_bindings():
    raw = output(["i3-msg", "-r", "-t", "get_config"])
    if not raw:
        return
    try:
        config = json.loads(raw)
    except ValueError:
        return
    sources = [item["variable_replaced_contents"] for item in config.get("included_configs", [])
               if "variable_replaced_contents" in item] or [config["config"]]
    descriptions = {"~/.local/bin/i3-help": "Search keyboard shortcuts",
                    "$HOME/.local/bin/open-terminal": "Open terminal",
                    "split h": "Split horizontally", "split v": "Split vertically",
                    "kill": "Close focused window", "restart": "Restart i3",
                    "reload": "Reload i3 configuration"}
    for source in sources:
        mode = ""
        for line in source.splitlines():
            line = line.strip()
            if line.startswith("mode ") and line.endswith("{"):
                mode = line[5:-1].strip().strip('"')
            if line == "}":
                mode = ""
            match = re.match(r"bind(sym|code)\s+(?:--\S+\s+)*(\S+)\s+(.+)", line)
            if not match:
                continue
            kind, keys, command = match.groups()
            command = re.sub(r"^exec\s+(?:--no-startup-id\s+)?", "", command).strip('"')
            label = descriptions.get(command, command)
            if command.startswith("rofi -show drun"):
                label = "Open application launcher (Rofi)"
            if command.startswith("i3-nagbar") and "exit" in command:
                label = "Log out of i3"
            keys = keys.replace("Mod4+", "Win+").replace("Mod1+", "Alt+").replace("Return", "Enter")
            yield "i3" + (f" ({mode} mode)" if mode else ""), label, keys + (" (keycode)" if kind == "code" else "")


def ghostty_bindings():
    docs = {}
    for block in re.finditer(r"^(\w+):\n[ \t]+([^\n]+)", output(["ghostty", "+list-actions", "--docs"]), re.M):
        docs[block[1]] = block[2].strip().rstrip(".")
    for line in output(["ghostty", "+list-keybinds"]).splitlines():
        binding = re.fullmatch(r"keybind = (.+?)=(\w+)(?::(.*))?", line)
        if not binding:
            continue
        keys, action, argument = binding.groups()
        label = action.replace("_", " ")
        if argument and action not in {"text", "esc", "csi"}:
            label += " " + argument.replace("_", " ")
        yield "Ghostty", label, keys, f"{action} {docs.get(action, '')}"


READLINE_TERMS = {
    "reverse-search-history": "search previous commands backward through command history",
    "forward-search-history": "search commands forward through history",
    "unix-word-rubout": "delete previous word",
    "backward-kill-word": "delete previous word",
    "kill-line": "delete to end of line", "unix-line-discard": "delete to beginning of line",
    "yank": "paste last cut text", "yank-pop": "cycle previously cut text",
    "complete": "tab autocomplete file or command", "clear-screen": "clear terminal screen",
}


def readline_bindings():
    # Read the user's inputrc without executing shell startup commands.
    for line in output(["bash", "--noprofile", "--norc", "-c", "bind -p"]).splitlines():
        binding = re.fullmatch(r'"(.+)": ([\w-]+)', line)
        if not binding:
            continue
        keys, action = binding.groups()
        # Preserve encoded terminal escape sequences rather than guessing the keyboard.
        if keys.startswith((r"\e[", r"\eO")):
            keys = f'"{keys}"'
        else:
            tokens = re.findall(r"\\C-.|\\e|\\.|.", keys)
            chord = []
            for token in tokens:
                if token.startswith(r"\C-"):
                    chord.append("Backspace" if token == r"\C-?" else "Ctrl+" + token[-1].upper())
                else:
                    chord.append("Esc" if token == r"\e" else token.lstrip("\\"))
            keys = " then ".join(chord)
            if keys.startswith("Esc then "):
                keys = "Alt+" + keys[len("Esc then "):]
        yield "Bash / Readline", action.replace("-", " "), keys, f"{action} {READLINE_TERMS.get(action, '')}"


def tmux_bindings():
    prefix = output(["tmux", "show-options", "-gv", "prefix"]).strip()
    if prefix:
        for line in output(["tmux", "list-keys", "-T", "prefix"]).splitlines():
            match = re.match(r"bind-key\s+(?:-r\s+)?-T\s+prefix\s+(\S+)\s+(.+)", line)
            if match:
                yield "tmux", match[2], f"{prefix} then {match[1]}"


# Documented application defaults supplement shortcuts exported at runtime.
DEFAULTS = {
    "Chrome / Firefox": [
        ("Reopen last closed tab / restore tab", "Ctrl+Shift+T"),
        ("Open new tab", "Ctrl+T"), ("Close current tab", "Ctrl+W"),
        ("Next tab", "Ctrl+Tab"), ("Previous tab", "Ctrl+Shift+Tab"),
        ("Open new window", "Ctrl+N"),
        ("Focus address bar / search the web", "Ctrl+L"), ("Find text on page", "Ctrl+F"),
        ("Open browsing history", "Ctrl+H"),
        ("Go back", "Alt+Left"), ("Go forward", "Alt+Right"), ("Reload page", "Ctrl+R"),
        ("Bookmark page", "Ctrl+D"), ("Open developer tools", "Ctrl+Shift+I"),
    ],
    "Firefox": [("Open private window", "Ctrl+Shift+P"), ("Open downloads", "Ctrl+Shift+Y")],
    "Chrome": [
        ("Open incognito window", "Ctrl+Shift+N"), ("Open downloads", "Ctrl+J"),
        ("Open Chrome help", "F1"),
    ],
    "VS Code": [
        ("Search all keyboard shortcuts by action or key; includes extensions and overrides", "Ctrl+K Ctrl+S"),
        ("Search commands / command palette", "Ctrl+Shift+P"), ("Quick open file", "Ctrl+P"),
        ("Find in files", "Ctrl+Shift+F"), ("Toggle integrated terminal", "Ctrl+`"),
    ],
    "Terminal": [
        ("Interrupt or stop running command", "Ctrl+C"), ("Suspend foreground job", "Ctrl+Z"),
        ("Send end of input / exit empty shell prompt", "Ctrl+D"),
    ],
    "Vim": [
        ("Search command help by topic", ":help {topic}"), ("Show custom normal mode mappings", ":nmap"),
        ("Find text forward", "/pattern"), ("Undo change", "u"), ("Redo change", "Ctrl+R"),
        ("Save file", ":w"), ("Quit editor", ":q"),
    ],
    "Zsh (Emacs mode)": [
        ("Search history backward", "Ctrl+R"), ("Go to beginning of line", "Ctrl+A"),
        ("Go to end of line", "Ctrl+E"), ("Delete previous word", "Ctrl+W"),
        ("List current shell key bindings", "bindkey"),
    ],
    "tmux": [("List configured shortcuts", "Prefix then ?"), ("Search commands by name", "Ctrl+B then : (default prefix)")],
    "GNOME apps": [("Show app keyboard shortcuts when supported", "Ctrl+?")],
}


def shortcut_rows():
    rows = []
    rows.extend(i3_bindings())
    rows.extend(ghostty_bindings())
    rows.extend(readline_bindings())
    rows.extend(tmux_bindings())
    for group, entries in DEFAULTS.items():
        rows.extend((group + " defaults", name, key) for name, key in entries)

    custom = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "i3/shortcuts.tsv"
    try:
        custom_lines = custom.read_text(errors="replace").splitlines()
    except OSError:
        custom_lines = []
    for line in custom_lines:
        fields = line.split("\t")
        if not line.startswith("#") and len(fields) == 3 and all(fields):
            rows.append(tuple(fields))

    return list(dict.fromkeys(rows))


if __name__ == "__main__":
    for row in shortcut_rows():
        print("\t".join(" ".join(field.split()) for field in row))
