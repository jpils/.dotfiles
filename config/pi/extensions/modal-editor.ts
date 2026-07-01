/**
 * Vim-like modal editor for pi.
 *
 * Insert by default. Escape -> normal. Normal Escape -> app abort.
 * Common motions/operators: hjkl wb e 0 ^ $ gg G fFtT ; ,
 * d/y/c + motions, dd/yy/cc, x X D C Y, p/P, u,
 * text objects: iw/aw, i"/a", i'/a', i`/a`, i(/a(/ib/ab, i{/a{/iB/aB, i[/a[.
 */

import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

type Mode = "normal" | "insert";
type Operator = "d" | "y" | "c";
type PendingFind = { key: "f" | "F" | "t" | "T"; op?: Operator };
type LastFind = { key: "f" | "F" | "t" | "T"; char: string };
type Pos = { line: number; col: number };
type Range = { start: number; end: number; linewise?: boolean };

const isWord = (ch: string) => /[A-Za-z0-9_]/.test(ch);
const isSpace = (ch: string) => /\s/.test(ch);
const OPEN_TO_CLOSE: Record<string, string> = { "(": ")", "[": "]", "{": "}" };
const CLOSE_TO_OPEN: Record<string, string> = { ")": "(", "]": "[", "}": "{" };

class ModalEditor extends CustomEditor {
	private mode: Mode = "insert";
	private pendingOp: Operator | null = null;
	private pendingPrefix = "";
	private pendingFind: PendingFind | null = null;
	private lastFind: LastFind | null = null;
	private register = "";
	private registerLinewise = false;

	handleInput(data: string): void {
		if (matchesKey(data, "escape")) {
			this.pendingOp = null;
			this.pendingPrefix = "";
			this.pendingFind = null;
			if (this.mode === "insert") this.mode = "normal";
			else super.handleInput(data);
			return;
		}

		if (this.mode === "insert") {
			super.handleInput(data);
			return;
		}

		if (this.pendingFind) {
			if (data.length === 1) this.finishFind(data);
			return;
		}

		if (data.length !== 1) {
			super.handleInput(data);
			return;
		}

		this.handleNormalKey(data);
	}

	private handleNormalKey(key: string): void {
		if (key === "u") return this.feed("\x1f"); // ctrl+- undo in pi-tui
		if (key === ".") return; // repeat not implemented

		if (this.pendingPrefix) {
			const combo = this.pendingPrefix + key;
			this.pendingPrefix = "";
			if (this.handleCombo(combo)) return;
		}

		if (this.pendingOp) {
			if (key === this.pendingOp) return this.operateLine(this.pendingOp);
			if (key === "i" || key === "a") {
				this.pendingPrefix = key;
				return;
			}
			if (["f", "F", "t", "T"].includes(key)) {
				this.pendingFind = { key: key as PendingFind["key"], op: this.pendingOp };
				return;
			}
			return this.operateMotion(this.pendingOp, key);
		}

		if (["d", "y", "c"].includes(key)) {
			this.pendingOp = key as Operator;
			return;
		}
		if (["f", "F", "t", "T"].includes(key)) {
			this.pendingFind = { key: key as PendingFind["key"] };
			return;
		}

		switch (key) {
			case "i": this.mode = "insert"; return;
			case "a": this.moveBy(1); this.mode = "insert"; return;
			case "I": this.setCursorOffset(this.lineStart(this.cursorOffset())); this.mode = "insert"; return;
			case "A": this.setCursorOffset(this.lineEnd(this.cursorOffset())); this.mode = "insert"; return;
			case "o": return this.openLineBelow();
			case "O": return this.openLineAbove();
			case "p": return this.paste(false);
			case "P": return this.paste(true);
			case "x": return this.deleteRange({ start: this.cursorOffset(), end: this.cursorOffset() + 1 });
			case "X": return this.deleteRange({ start: this.cursorOffset() - 1, end: this.cursorOffset() });
			case "D": return this.deleteRange({ start: this.cursorOffset(), end: this.lineEnd(this.cursorOffset()) });
			case "C": this.deleteRange({ start: this.cursorOffset(), end: this.lineEnd(this.cursorOffset()) }); this.mode = "insert"; return;
			case "Y": return this.yankRange({ start: this.lineStart(this.cursorOffset()), end: this.lineEnd(this.cursorOffset()), linewise: true });
			case ";": return this.repeatFind(false);
			case ",": return this.repeatFind(true);
			default:
				if (this.motionOffset(key) !== null) this.setCursorOffset(this.motionOffset(key)!);
		}
	}

	private handleCombo(combo: string): boolean {
		if (this.pendingOp && ["iw", "aw", "iW", "aW"].includes(combo)) {
			return this.operateTextObject(this.pendingOp, combo);
		}
		if (this.pendingOp && /^.["'`(){}\[\]]$/.test(combo)) {
			return this.operateTextObject(this.pendingOp, combo);
		}
		if (combo === "gg") { this.setCursorOffset(0); return true; }
		return false;
	}

	private finishFind(char: string): void {
		const pending = this.pendingFind!;
		this.pendingFind = null;
		this.lastFind = { key: pending.key, char };
		const target = this.findChar(pending.key, char);
		if (target === null) { this.pendingOp = null; return; }
		if (pending.op) {
			const opTarget = (pending.key === "f" || pending.key === "t") ? target + 1 : target;
			this.applyOperatorToRange(pending.op, this.rangeTo(opTarget));
		} else this.setCursorOffset(target);
	}

	private repeatFind(reverse: boolean): void {
		if (!this.lastFind) return;
		const keyMap: Record<string, PendingFind["key"]> = { f: "f", F: "F", t: "t", T: "T" };
		let key = keyMap[this.lastFind.key];
		if (reverse) key = ({ f: "F", F: "f", t: "T", T: "t" } as Record<string, PendingFind["key"]>)[key];
		const target = this.findChar(key, this.lastFind.char);
		if (target !== null) this.setCursorOffset(target);
	}

	private operateMotion(op: Operator, motion: string): void {
		const target = this.motionOffset(motion);
		this.pendingOp = null;
		if (target === null) return;
		this.applyOperatorToRange(op, this.rangeTo(target));
	}

	private operateLine(op: Operator): void {
		const off = this.cursorOffset();
		const start = this.lineStart(off);
		let end = this.nextLineStart(off);
		if (end <= start) end = this.text().length;
		this.pendingOp = null;
		this.applyOperatorToRange(op, { start, end, linewise: true });
	}

	private operateTextObject(op: Operator, object: string): boolean {
		this.pendingOp = null;
		const range = this.textObjectRange(object);
		if (!range) return true;
		this.applyOperatorToRange(op, range);
		return true;
	}

	private applyOperatorToRange(op: Operator, range: Range): void {
		if (op === "y") return this.yankRange(range);
		this.deleteRange(range);
		if (op === "c") this.mode = "insert";
	}

	private motionOffset(key: string): number | null {
		const off = this.cursorOffset();
		switch (key) {
			case "h": return Math.max(0, off - 1);
			case "l": return Math.min(this.text().length, off + 1);
			case "j": return this.vertical(1);
			case "k": return this.vertical(-1);
			case "w": return this.wordForward(off);
			case "b": return this.wordBackward(off);
			case "e": return this.wordEnd(off);
			case "0": return this.lineStart(off);
			case "^": return this.firstNonBlank(off);
			case "$": return this.lineEnd(off);
			case "G": return this.text().length;
			default: return null;
		}
	}

	private rangeTo(target: number): Range {
		const off = this.cursorOffset();
		if (target >= off) return { start: off, end: target };
		return { start: target, end: off };
	}

	private textObjectRange(object: string): Range | null {
		const text = this.text();
		const off = this.cursorOffset();
		const mode = object[0];
		let kind = object[1];
		if (kind === "b") kind = "(";
		if (kind === "B") kind = "{";
		if (kind === "w" || kind === "W") return this.wordObject(mode === "a");
		if (["'", '"', "`"].includes(kind)) return this.quoteObject(kind, mode === "a");
		if (kind in OPEN_TO_CLOSE || kind in CLOSE_TO_OPEN) {
			const open = kind in OPEN_TO_CLOSE ? kind : CLOSE_TO_OPEN[kind];
			const close = OPEN_TO_CLOSE[open];
			let left = text.lastIndexOf(open, off);
			let right = text.indexOf(close, off);
			if (left < 0 || right < 0 || left >= right) return null;
			return mode === "a" ? { start: left, end: right + 1 } : { start: left + 1, end: right };
		}
		return null;
	}

	private wordObject(around: boolean): Range | null {
		const text = this.text();
		let off = Math.min(this.cursorOffset(), Math.max(0, text.length - 1));
		while (off < text.length && isSpace(text[off])) off++;
		if (off >= text.length) return null;
		const wordClass = isWord(text[off]) ? isWord : (ch: string) => !isSpace(ch) && !isWord(ch);
		let start = off, end = off + 1;
		while (start > 0 && wordClass(text[start - 1])) start--;
		while (end < text.length && wordClass(text[end])) end++;
		if (around) while (end < text.length && isSpace(text[end])) end++;
		return { start, end };
	}

	private quoteObject(q: string, around: boolean): Range | null {
		const text = this.text();
		const off = this.cursorOffset();
		const lineStart = this.lineStart(off);
		const lineEnd = this.lineEnd(off);

		// Prefer enclosing quotes on the current line, including cursor on quote chars.
		let left = text.lastIndexOf(q, off === lineEnd ? off - 1 : off);
		while (left >= lineStart) {
			const right = text.indexOf(q, left + 1);
			if (right >= off && right <= lineEnd) {
				return around ? { start: left, end: right + 1 } : { start: left + 1, end: right };
			}
			left = text.lastIndexOf(q, left - 1);
		}

		// If not inside quotes, operate on the next quoted string on this line.
		left = text.indexOf(q, off);
		if (left < 0 || left > lineEnd) return null;
		const right = text.indexOf(q, left + 1);
		if (right < 0 || right > lineEnd) return null;
		return around ? { start: left, end: right + 1 } : { start: left + 1, end: right };
	}

	private findChar(key: PendingFind["key"], char: string): number | null {
		const text = this.text();
		const off = this.cursorOffset();
		if (key === "f" || key === "t") {
			const idx = text.indexOf(char, off + 1);
			if (idx < 0) return null;
			return key === "t" ? Math.max(off, idx - 1) : idx;
		}
		const idx = text.lastIndexOf(char, off - 1);
		if (idx < 0) return null;
		return key === "T" ? Math.min(off, idx + 1) : idx;
	}

	private deleteRange(range: Range): void {
		let { start, end } = this.clampRange(range);
		if (start === end) return;
		const text = this.text();
		this.register = text.slice(start, end);
		this.registerLinewise = !!range.linewise;
		this.setTextAndCursor(text.slice(0, start) + text.slice(end), start);
	}

	private yankRange(range: Range): void {
		let { start, end } = this.clampRange(range);
		this.register = this.text().slice(start, end);
		this.registerLinewise = !!range.linewise;
		this.setCursorOffset(start);
	}

	private paste(before: boolean): void {
		if (!this.register) return;
		const off = this.cursorOffset();
		let insertAt = before ? off : Math.min(this.text().length, off + (this.registerLinewise ? 0 : 1));
		if (this.registerLinewise) insertAt = before ? this.lineStart(off) : this.nextLineStart(off);
		this.setTextAndCursor(this.text().slice(0, insertAt) + this.register + this.text().slice(insertAt), insertAt + this.register.length);
	}

	private openLineBelow(): void {
		const at = this.lineEnd(this.cursorOffset());
		this.setTextAndCursor(this.text().slice(0, at) + "\n" + this.text().slice(at), at + 1);
		this.mode = "insert";
	}
	private openLineAbove(): void {
		const at = this.lineStart(this.cursorOffset());
		this.setTextAndCursor(this.text().slice(0, at) + "\n" + this.text().slice(at), at);
		this.mode = "insert";
	}

	private text(): string { return this.getText(); }
	private stateAny(): { lines: string[]; cursorLine: number; cursorCol: number } { return (this as any).state; }
	private cursorOffset(): number { return this.posToOffset(this.getCursor()); }
	private posToOffset(pos: Pos): number {
		const lines = this.getLines();
		let off = 0;
		for (let i = 0; i < pos.line; i++) off += (lines[i]?.length ?? 0) + 1;
		return off + pos.col;
	}
	private offsetToPos(offset: number): Pos {
		const lines = this.getLines();
		let rest = Math.max(0, Math.min(offset, this.text().length));
		for (let line = 0; line < lines.length; line++) {
			const len = lines[line]?.length ?? 0;
			if (rest <= len) return { line, col: rest };
			rest -= len + 1;
		}
		const last = Math.max(0, lines.length - 1);
		return { line: last, col: lines[last]?.length ?? 0 };
	}
	private setCursorOffset(offset: number): void {
		const pos = this.offsetToPos(offset);
		const st = this.stateAny();
		st.cursorLine = pos.line;
		st.cursorCol = pos.col;
	}
	private setTextAndCursor(text: string, cursor: number): void {
		this.setText(text);
		this.setCursorOffset(cursor);
	}
	private clampRange(range: Range): Range {
		const len = this.text().length;
		return { ...range, start: Math.max(0, Math.min(range.start, len)), end: Math.max(0, Math.min(range.end, len)) };
	}
	private lineStart(off: number): number { const i = this.text().lastIndexOf("\n", Math.max(0, off - 1)); return i < 0 ? 0 : i + 1; }
	private lineEnd(off: number): number { const i = this.text().indexOf("\n", off); return i < 0 ? this.text().length : i; }
	private nextLineStart(off: number): number { const i = this.text().indexOf("\n", off); return i < 0 ? this.text().length : i + 1; }
	private firstNonBlank(off: number): number { const s = this.lineStart(off), e = this.lineEnd(off); const m = this.text().slice(s, e).match(/\S/); return m ? s + (m.index ?? 0) : s; }
	private vertical(delta: number): number {
		const cur = this.getCursor();
		const lines = this.getLines();
		const line = Math.max(0, Math.min(lines.length - 1, cur.line + delta));
		return this.posToOffset({ line, col: Math.min(cur.col, lines[line]?.length ?? 0) });
	}
	private moveBy(delta: number): void { this.setCursorOffset(this.cursorOffset() + delta); }
	private wordForward(off: number): number { const t = this.text(); let i = off + 1; while (i < t.length && !isWord(t[i])) i++; while (i < t.length && isWord(t[i - 1]) && isWord(t[i])) i++; return Math.min(i, t.length); }
	private wordBackward(off: number): number { const t = this.text(); let i = Math.max(0, off - 1); while (i > 0 && !isWord(t[i])) i--; while (i > 0 && isWord(t[i - 1])) i--; return i; }
	private wordEnd(off: number): number { const t = this.text(); let i = off + 1; while (i < t.length && !isWord(t[i])) i++; while (i + 1 < t.length && isWord(t[i + 1])) i++; return Math.min(i, t.length); }
	private feed(seq: string): void { super.handleInput(seq); }

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;
		const pending = this.pendingFind ? this.pendingFind.key : this.pendingOp ? this.pendingOp + this.pendingPrefix : "";
		const label = this.mode === "normal" ? ` NORMAL${pending ? ` ${pending}` : ""} ` : " INSERT ";
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
