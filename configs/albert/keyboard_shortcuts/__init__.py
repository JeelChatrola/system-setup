"""Search keyboard shortcuts with the keys trigger in Albert."""
from pathlib import Path
import subprocess
import threading
import time

from albert import Action, GeneratorQueryHandler, Icon, PluginInstance, StandardItem, setClipboardText

md_iid = "5.0"
md_version = "1.0"
md_name = "Keyboard Shortcuts"
md_description = "Find keyboard bindings by action, application or key"
md_authors = ["Local setup"]


class Plugin(PluginInstance, GeneratorQueryHandler):
    def __init__(self):
        PluginInstance.__init__(self)
        GeneratorQueryHandler.__init__(self)
        self.lock = threading.Lock()
        self.rows = []
        self.expires = 0

    def defaultTrigger(self):
        return "keys "

    def synopsis(self, query):
        return "" if query.strip() else "action or app, e.g. reopen tab"

    def catalog(self):
        with self.lock:
            if time.monotonic() >= self.expires:
                catalog = Path(__file__).with_name("catalog.py")
                data = subprocess.check_output(["/usr/bin/python3", str(catalog)], text=True, timeout=12)
                self.rows = [line.split("\t") for line in data.splitlines()]
                self.expires = time.monotonic() + 10
            return self.rows

    def items(self, ctx):
        words = ctx.query.casefold().split()
        matches = []
        for source, action, keys, *aliases in self.catalog():
            if not ctx.isValid:
                return
            label = action.casefold()
            full = " ".join([source, action, keys, *aliases]).casefold()
            if all(word in full for word in words):
                matches.append((sum(word not in label for word in words), source, action, keys))
        if not matches:
            yield [StandardItem(id="no-match", text="No matching keyboard shortcuts",
                                subtext="Try an action such as reopen tab or split right",
                                icon_factory=lambda: Icon.grapheme("⌨"))]
            return
        matches.sort(key=lambda row: row[0])
        if not words:
            matches = matches[:40]
        yield [
            StandardItem(
                id=f"{source}/{action}/{keys}", text=action, subtext=f"{keys}   ·   {source}",
                icon_factory=lambda: Icon.grapheme("⌨"),
                actions=[Action("copy", "Copy shortcut", lambda value=keys: setClipboardText(value))],
            ) for _, source, action, keys in matches
        ]
