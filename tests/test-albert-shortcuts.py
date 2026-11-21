import runpy
import unittest
from pathlib import Path
from unittest.mock import patch


helper = runpy.run_path(str(Path(__file__).resolve().parents[1] /
                            "configs/albert/keyboard_shortcuts/catalog.py"))


class ShortcutSearchTests(unittest.TestCase):
    def read(self, source, outputs):
        function = helper[source]
        with patch.dict(function.__globals__, output=lambda args: outputs[args[-1]]):
            return list(function())

    def test_ghostty_keeps_equals_key_and_searchable_action_name(self):
        rows = self.read("ghostty_bindings", {
            "--docs": "increase_font_size:\n  Increase the size of the text.\n",
            "+list-keybinds": "keybind = ctrl+==increase_font_size:1\n",
        })
        self.assertEqual(rows, [("Ghostty", "increase font size 1", "ctrl+=",
                                 "increase_font_size Increase the size of the text")])

    def test_readline_distinguishes_chords_from_sequences(self):
        rows = self.read("readline_bindings", {"bind -p": r'''"\C-r": reverse-search-history
"\C-x\C-e": shell-expand-line
"\eb": backward-word'''})
        self.assertEqual([row[2] for row in rows], ["Ctrl+R", "Ctrl+X then Ctrl+E", "Alt+b"])
        self.assertIn("command history", rows[0][3])

    def test_i3_mode_scopes_and_actual_modifier(self):
        rows = self.read("i3_bindings", {"get_config":
            '{"included_configs":[{"variable_replaced_contents":"mode \\"resize\\" {\\n'
            'bindsym j resize grow height 10 px\\n}\\nbindsym Mod1+Return exec $HOME/.local/bin/open-terminal"}]}'})
        self.assertEqual(rows, [("i3 (resize mode)", "resize grow height 10 px", "j"),
                                ("i3", "Open terminal", "Alt+Enter")])


if __name__ == "__main__":
    unittest.main()
