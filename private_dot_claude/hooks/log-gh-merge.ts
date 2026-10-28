#!/usr/bin/env bun
// Bash の `gh pr merge` を、どのタブ・セッションが実行したかと一緒に ~/.local/state/merge-log へ 1 行ずつ残す（止めない）。
// GitHub の mergedBy はどのタブでも akameco なので、「勝手にマージしてない？」に答えるにはこの記録が要る。
// 1 行 = "<ISO 時刻>\t<herdr のタブ名>\t<session_id>\t<cwd>\t<command>"
import { appendFileSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { stripLiterals } from "./guard-destructive-git.ts";

const LOG = process.env.MERGE_LOG ?? join(homedir(), ".local/state/merge-log");

export function isMerge(command: string): boolean {
  return /\bgh\s+pr\s+merge\b/.test(stripLiterals(command));
}

function tabName(): string {
  const pane = process.env.HERDR_PANE_ID;
  if (!pane) return "-";
  const result = Bun.spawnSync(["herdr", "agent", "list"], { timeout: 3000 });
  try {
    const agents: { name?: string; pane_id?: string }[] = JSON.parse(result.stdout.toString()).result.agents;
    return agents.find((a) => a.pane_id === pane)?.name ?? pane;
  } catch {
    return pane;
  }
}

if (import.meta.main) {
  const input = JSON.parse(await Bun.stdin.text());
  const command: string = input?.tool_input?.command ?? "";
  if (isMerge(command)) {
    const line = [new Date().toISOString(), tabName(), input.session_id ?? "-", input.cwd ?? "-", command.replace(/\s+/g, " ")];
    mkdirSync(join(LOG, ".."), { recursive: true });
    appendFileSync(LOG, `${line.join("\t")}\n`);
  }
}
