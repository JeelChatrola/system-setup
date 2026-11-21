"""Install the per-user files for Albert without changing its existing hotkey."""
import configparser
import io
import os
import sys
import tempfile
from pathlib import Path


def install(path, data):
    if path.is_file() and path.read_bytes() == data:
        return
    if path.is_symlink():
        raise SystemExit(f"{path} is managed by another tool")
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as staged:
        staged.write(data)
    os.replace(staged.name, path)
    print(f"Updated {path}")


def desktop_exec(path):
    # Desktop Entry Exec escaping, including its second pass for field codes.
    exe = str(path).replace("%", "%%")
    for char in ("\\", '"', "$", "`"):
        exe = exe.replace(char, "\\" + char)
    return '"' + exe.replace("\\", "\\\\") + '"'


def configure(binary, screenshot=None):
    home = Path.home()
    data = Path(os.environ.get("XDG_DATA_HOME") or home / ".local/share")
    config = Path(os.environ.get("XDG_CONFIG_HOME") or home / ".config")
    source = Path(__file__).parent / "keyboard_shortcuts"
    for name in ["__init__.py", "catalog.py"]:
        install(data / "albert/python/plugins/keyboard_shortcuts" / name, (source / name).read_bytes())

    exe = desktop_exec(binary)
    desktop = "[Desktop Entry]\nType=Application\n"
    if binary.parent.parent.name == "albert-package":
        install(data / "applications/albert.desktop",
                (desktop + f"Name=Albert\nExec={exe}\nIcon=system-search\nCategories=Utility;\n").encode())
    if screenshot:
        install(data / "applications/xfce4-screenshooter.desktop",
                (desktop + f"Name=Screenshot\nExec={desktop_exec(screenshot)}\n"
                 + "Icon=camera-photo\nCategories=Utility;\n").encode())
    install(config / "autostart/albert.desktop",
            (desktop + f"Name=Albert\nExec={exe}\n").encode())
    install(data / "applications/local-albert-shortcuts.desktop",
            (desktop + "Name=Keyboard Shortcuts\nIcon=input-keyboard\n"
             + f'Exec={exe} show "keys "\nCategories=Utility;\n').encode())

    path = config / "albert/config"
    settings = configparser.RawConfigParser(delimiters=("=",), strict=False)
    settings.optionxform = str
    settings.read(path)
    dirty = False
    for section, options in {
        "General": {"hotkey": "Shift+F2", "telemetry": "false"},
        **{plugin: {"enabled": "true"} for plugin in
           ["applications", "calculator_qalculate", "websearch", "python", "python.keyboard_shortcuts"]},
    }.items():
        if not settings.has_section(section):
            settings.add_section(section)
        for key, value in options.items():
            if section == "General" and settings.has_option(section, key):
                continue
            if settings.get(section, key, fallback=None) != value:
                settings.set(section, key, value)
                dirty = True
    if dirty:
        rendered = io.StringIO()
        settings.write(rendered, space_around_delimiters=False)
        install(path, rendered.getvalue().encode())


if __name__ == "__main__":
    configure(*map(Path, sys.argv[1:]))
