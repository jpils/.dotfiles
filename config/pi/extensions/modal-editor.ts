/**
 * Vim-like modal editor for pi.
 *
 * - Insert mode by default.
 * - Escape: insert -> normal; normal -> app escape/abort.
 * - Normal: h/j/k/l, w/b, 0/$, x, i/a/I/A.
 */

import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const NORMAL_KEYS: Record<string, string | null> = {
	h: "\x1b[D", // left
	j: "\x1b[B", // down
	k: "\x1b[A", // up
	l: "\x1b[C", // right
	b: "\x1bb", // word left
	w: "\x1bf", // word right
	"0": "\x01", // line start
	$: "\x05", // line end
	x: "\x1b[3~", // delete char
	i: null, // insert
	a: null, // append
	I: null, // line start + insert
	A: null, // line end + insert
};

class ModalEditor extends CustomEditor {
	private mode: "normal" | "insert" = "insert";

	handleInput(data: string): void {
		if (matchesKey(data, "escape")) {
			if (this.mode === "insert") {
				this.mode = "normal";
			} else {
				super.handleInput(data);
			}
			return;
		}

		if (this.mode === "insert") {
			super.handleInput(data);
			return;
		}

		if (data in NORMAL_KEYS) {
			const seq = NORMAL_KEYS[data];
			if (data === "i") {
				this.mode = "insert";
			} else if (data === "a") {
				this.mode = "insert";
				super.handleInput("\x1b[C");
			} else if (data === "I") {
				this.mode = "insert";
				super.handleInput("\x01");
			} else if (data === "A") {
				this.mode = "insert";
				super.handleInput("\x05");
			} else if (seq) {
				super.handleInput(seq);
			}
			return;
		}

		// Ignore printable chars in normal mode; keep ctrl/app shortcuts working.
		if (data.length === 1 && data.charCodeAt(0) >= 32) return;
		super.handleInput(data);
	}

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;

		const label = this.mode === "normal" ? " NORMAL " : " INSERT ";
		const last = lines.length - 1;
		if (visibleWidth(lines[last]!) >= label.length) {
			lines[last] = truncateToWidth(lines[last]!, width - label.length, "") + label;
		}
		return lines;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setEditorComponent((tui, theme, keybindings) =>
			new ModalEditor(tui, theme, keybindings),
		);
	});
}
