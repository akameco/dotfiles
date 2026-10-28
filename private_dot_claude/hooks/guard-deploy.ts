#!/usr/bin/env bun
// Cloudflare への本番デプロイ・ログインを Bash から実行させない（本番に出すのは人がターミナルで打つ）。
// 2026-10-21 に `pnpm deploy:worker -- --dry-run` が `wrangler deploy -- --dry-run` に展開され、本番 deploy が動いた事故から。
// あわせて、cloudflare.config.ts のないディレクトリでの `cf dev|build|deploy` を止める（cf の自動構成が設定ファイルを書き出すため）。
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import { stripLiterals } from "./guard-destructive-git.ts";

const HEREDOC_BODY = /<<-?\s*(['"]?)(\w+)\1[^\n]*\n.*?\n\s*\2(?=\s|$)/gs;

// アップロードを伴うサブコマンド。--dry-run が `--` より前にあるときだけ通す
const UPLOADS = /\b(?:cf\s+(?:previews\s+)?deploy|wrangler\s+(?:deploy|versions\s+(?:upload|deploy)|pages\s+deploy))\b/;
const LOGINS = /\b(?:cf\s+auth\s+login|wrangler\s+login)\b|\b(?:cf|wrangler)\b.*\s--temporary\b/;
const CF_PROJECT = /\bcf\s+(dev|build|deploy)\b/;

type Decision = ["deny", string];

function segments(command: string): string[] {
  // && ; || | 改行で区切った各コマンド。cd はあとの区切りに効くので順に見る
  return command.split(/&&|\|\||[;|\n]/).map((s) => s.trim()).filter(Boolean);
}

function dryRunBeforeDoubleDash(segment: string): boolean {
  const head = segment.split(/\s--(?=\s|$)/)[0];
  return /\s--dry-run\b/.test(head);
}

function expand(path: string, cwd: string): string {
  return resolve(cwd, path.replace(/^~(?=\/|$)/, homedir()));
}

// 同じコマンドの中の `NAME=value` を覚えて $NAME / ${NAME} を展開する。展開できない $ が残れば null（判定しない）
function substitute(word: string, vars: Map<string, string>): string | null {
  if (word.includes("''")) return null; // 引用符の中身は stripLiterals で消えているので判定しない
  const out = word.replace(/\$\{?([A-Za-z_]\w*)\}?/g, (m, name) => vars.get(name) ?? m);
  return out.includes("$") ? null : out;
}

export function decide(command: string, cwd: string): Decision | null {
  // dir が null のときは、cd の先が分からないので cloudflare.config.ts の判定をしない（デプロイ・ログインの判定は続ける）
  let dir: string | null = cwd;
  const vars = new Map<string, string>();
  for (const segment of segments(command.replace(HEREDOC_BODY, ""))) {
    const assign = /^(?:export\s+)?([A-Za-z_]\w*)=(\S*)$/.exec(segment);
    if (assign) {
      const value = substitute(assign[2].replace(/^(['"])(.*)\1$/, "$2"), vars);
      if (value !== null) vars.set(assign[1], value);
      continue;
    }
  }
  for (const segment of segments(stripLiterals(command))) {
    const cd = /^cd\s+(\S+)/.exec(segment);
    if (cd) {
      const target = substitute(cd[1], vars);
      dir = target === null || dir === null ? null : expand(target, dir);
      continue;
    }
    if (LOGINS.test(segment)) {
      return ["deny", "Cloudflare へのログイン（cf auth login・wrangler login・--temporary）は人がターミナルで行う"];
    }
    if (UPLOADS.test(segment) && !dryRunBeforeDoubleDash(segment)) {
      return [
        "deny",
        "本番へのデプロイ・アップロードは人がターミナルで行う。確かめるだけなら `pnpm exec cf deploy --dry-run`" +
          "（pnpm のスクリプト経由で `-- --dry-run` を付けると --dry-run が効かない）",
      ];
    }
    const cf = CF_PROJECT.exec(segment);
    if (cf) {
      const flagDir = /\s(?:--dir|-C)\s+(\S+)/.exec(segment);
      const flagTarget = flagDir ? substitute(flagDir[1], vars) : null;
      const target = flagDir ? (flagTarget === null || dir === null ? null : expand(flagTarget, dir)) : dir;
      if (target !== null && !existsSync(`${target}/cloudflare.config.ts`)) {
        return [
          "deny",
          `${target} に cloudflare.config.ts がない。cf ${cf[1]} は自動構成で設定ファイルを書き出すので、` +
            "移行済みのワークツリーで実行する",
        ];
      }
    }
  }
  return null;
}

if (import.meta.main) {
  const input = JSON.parse(await Bun.stdin.text());
  const result = decide(input?.tool_input?.command ?? "", input?.cwd ?? process.cwd());
  if (result) {
    console.log(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: result[0],
        permissionDecisionReason: result[1],
      },
    }));
  }
}
