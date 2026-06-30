import { homedir } from "node:os";
import { isAbsolute, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = homedir();
const ALLOWED_MUTATION_ROOTS = [`${HOME}/.pi`, `${HOME}/nixconf/config/pi`];

function summarizeInput(toolName: string, input: Record<string, unknown>): string {
	if (toolName === "bash") return String(input.command ?? "");
	if (toolName === "write" || toolName === "edit") return String(input.path ?? "");
	return JSON.stringify(input, null, 2);
}

function toAbsolutePath(path: string, cwd: string): string {
	const expanded = path === "~" ? HOME : path.startsWith("~/") ? `${HOME}/${path.slice(2)}` : path;
	return isAbsolute(expanded) ? resolve(expanded) : resolve(cwd, expanded);
}

function isAllowedMutationPath(path: string, cwd: string): boolean {
	const absolute = toAbsolutePath(path, cwd);
	return ALLOWED_MUTATION_ROOTS.some((root) => absolute === root || absolute.startsWith(`${root}/`));
}

function bashMayMutate(command: string): boolean {
	const stripped = command
		.replace(/#[^\n]*/g, "")
		.replace(/(['"]).*?\1/g, "");

	// Redirection writes: >, >>, &>, 2>, etc. Excludes read-only < and here-strings <<<.
	if (/(^|[^<])(?:\d*|&)>>?[^>(]/.test(stripped)) return true;

	// Common filesystem / system mutation commands.
	return /(^|[\s;|&()])(?:rm|rmdir|mv|cp|install|mkdir|touch|ln|chmod|chown|chgrp|truncate|dd|tee|sed\s+-i|perl\s+-pi|python\s+-m\s+pip\s+install|pip(?:x|3)?\s+install|npm\s+(?:install|i|update|add|remove|rm|uninstall|run)|pnpm\s+(?:install|add|remove|update|run)|yarn\s+(?:install|add|remove|upgrade|run)|git\s+(?:add|commit|checkout|switch|restore|reset|clean|merge|rebase|pull|push|apply|am|stash|mv|rm)|jj\s+(?:new|commit|describe|abandon|restore|squash|split|rebase|bookmark|git)|nix\s+(?:profile|store|collect-garbage|build|flake\s+update)|nixos-rebuild|home-manager|systemctl|service|docker\s+(?:run|build|compose|rm|rmi|volume|network|cp|exec)|podman\s+(?:run|build|rm|rmi|volume|network|cp|exec))\b/.test(stripped);
}

function bashMutationAllowed(command: string, cwd: string): boolean {
	const commandWithoutComments = command.replace(/#[^\n]*/g, "");
	const tokens = commandWithoutComments.match(/"[^"]*"|'[^']*'|[^\s]+/g) ?? [];
	const cleanedTokens = tokens.map((token) => token.replace(/^['"]|['"]$/g, ""));

	// If mutating command has no path args, it mutates cwd. Allow only inside allowlisted roots.
	let sawPath = false;
	let sawAllowedPath = isAllowedMutationPath(cwd, cwd);

	for (const token of cleanedTokens) {
		if (!token || token.startsWith("-")) continue;
		if (["&&", "||", "|", ";", "(", ")"].includes(token)) continue;

		const redirectionMatch = token.match(/^(?:\d*|&)>>?(.+)$/);
		const candidate = redirectionMatch?.[1] || token;
		const pathLike =
			candidate === "~" ||
			candidate.startsWith("~/") ||
			candidate.startsWith("/") ||
			candidate.startsWith("./") ||
			candidate.startsWith("../") ||
			candidate.startsWith("config/pi") ||
			candidate.includes("/.pi") ||
			candidate.includes("/config/pi");

		if (!pathLike) continue;
		sawPath = true;
		if (!isAllowedMutationPath(candidate, cwd)) return false;
		sawAllowedPath = true;
	}

	return sawAllowedPath || (!sawPath && isAllowedMutationPath(cwd, cwd));
}

export default function confirmFileMutations(pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		// Never prompt for shell commands. Pi has no built-in permission popups;
		// this extension only gates file writes/edits outside trusted config paths.
		if (!["write", "edit"].includes(event.toolName)) return undefined;

		const target = summarizeInput(event.toolName, event.input as Record<string, unknown>);
		if (isAllowedMutationPath(target, ctx.cwd)) return undefined;

		const title = `Allow ${event.toolName} to modify file?`;
		const message = target;

		if (!ctx.hasUI) {
			return { block: true, reason: `${event.toolName} blocked: no UI for confirmation` };
		}

		const ok = await ctx.ui.confirm(title, message);
		if (!ok) return { block: true, reason: `${event.toolName} blocked by user` };

		return undefined;
	});
}
