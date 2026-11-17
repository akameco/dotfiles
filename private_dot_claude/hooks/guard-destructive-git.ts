#!/usr/bin/env bun
// Bash の git reset --hard と force push（--force-with-lease 以外）を、フラグの順番によらず確認待ちにする。
// permissions.deny は前方一致なので `git reset -q --hard` や `git -C x reset --hard` をすり抜ける。
// あわせて、zsh で必ず失敗する `B="agent-browser --session x"; $B open …` と `echo ====` の形、
// python3 のヒアドキュメントでのファイルの書き換え（Edit ツールか bun を使う方針）を実行前に止める。
// worktree の中（cwd に /.claude/worktrees/）では sed -i・heredoc での書き込みを、サブエージェント（入力に agent_id）
// では cat・sed -n だけでファイルを見るコマンドを止め、Write/Edit・Read へ誘導する（2026-11-16 の retro）。

const RULES: [RegExp, string][] = [
  [/\bgit\b[^;&|\n]*\breset\b[^;&|\n]*\s--hard\b/, "git reset --hard"],
  [/\bgit\b[^;&|\n]*\bpush\b[^;&|\n]*\s(--force(?=\s|$)|-f(?=\s|$)|\+\S)/, "force push（--force-with-lease を使う）"],
];

const HEREDOC = /<<-?\s*(['"]?)(\w+)\1[^\n]*\n.*?\n\s*\2(?=\s|$)/gs;
const QUOTED = /'[^']*'|"(?:\\.|[^"\\])*"/g;
const BASH_C = /\bbash\s+-c\s+('[^']*'|"(?:\\.|[^"\\])*")/g;
const ASSIGN = /(?:^|[;&|\n]|\s)(?:export\s+|local\s+)?([A-Za-z_]\w*)=(["'])([^"'\n]*\s[^"'\n]*)\2/g;

type Decision = ["ask" | "deny", string];

export function stripLiterals(command: string): string {
  // heredoc の本文や引用符の中（commit メッセージ・正規表現の文字列など）は実行されないので判定から外す
  return command.replace(HEREDOC, "").replace(QUOTED, "''");
}

export function wordSplitUse(command: string): [string, string] | null {
  // Bash ツールのシェルは zsh なので変数は単語分割されず、"cmd --opt" 全体が 1 つのコマンド名になる。
  // heredoc の本文（#!/bin/bash のスクリプト）と bash -c の中は bash で動くので見ない。
  // 代入の値は引用符の中にあるので stripLiterals は使わない
  const code = command.replace(HEREDOC, "").replace(BASH_C, "''");
  for (const [, name, , value] of code.matchAll(ASSIGN)) {
    if (!/^[\w./~-]+\s+\S/.test(value.trim())) continue; // 「コマンド 引数…」の形（"node /x/a.mjs" も。使う側がコマンドの位置かは下で見る）
    if (new RegExp(String.raw`(?:^|[;&|\n(]|\bthen\b|\bdo\b)\s*\$\{?${name}\}?(?=\s|$)`).test(code)) return [name, value];
  }
  return null;
}

export function equalsWord(command: string): string | null {
  // zsh は `=` で始まる語を `=cmd` → cmd のパスに展開するので、`echo ====` や `[ a == b ]` は「= not found」で失敗する。
  // [[ ]] と (( )) の中は展開されないので外す
  const code = stripLiterals(command).replace(/\[\[.*?\]\]/gs, "").replace(/\(\(.*?\)\)/gs, "");
  return code.match(/(?:^|[\s;&|(])(={2,})(?=[\s;&|)]|$)/)?.[1] ?? null; // 1 文字の = は展開されない（[ a = b ] は通る）
}

export function pythonRewrite(command: string): boolean {
  // `python3 - <<'EOF'` の本文で open(...).read() → replace → write する形（ファイルの書き換え）
  return /\bpython3?(?:\s+-\w+)*\s+-\s*<</.test(command) && /\bopen\(/.test(command) && /\.write\(|\.write_text\(/.test(command);
}

export function shellRewrite(command: string): string | null {
  // `sed -i`・`cat > f <<EOF`・`tee f <<EOF` でのファイルの作成・書き換え。heredoc の本文は見ない
  const code = command.replace(HEREDOC, "<<");
  if (/(?:^|[;&|\n(]|\s)sed\s+(?:-\w*\s+)*-i\b|(?:^|[;&|\n(]|\s)sed\s+-\w*i\b/.test(code)) return "sed -i";
  const catRedirect = /\bcat\b[^;&|\n]*>>?\s*\S+[^;&|\n]*<</.test(code) || /\bcat\b[^;&|\n]*<<[^;&|\n]*>>?\s*\S+/.test(code);
  const teeFile = /\btee\s+(-a\s+)?[^\s<-][^;&|\n]*<</.test(code);
  if (catRedirect || teeFile) {
    return "heredoc での書き込み";
  }
  return null;
}

export type Ctx = { cwd?: string; agentId?: string };

export function catForRead(command: string): boolean {
  // サブエージェントが 1〜3 ファイルを cat・sed -n で見るだけのコマンド。Read を通さないと、あとの Edit・Write が
  // 「File has not been read yet」で失敗する（2026-11-16 の retro: 119 回のうち 106 回がこの形と巻き添え）
  const c = command.trim();
  if (/[|;&<>`$]|\n/.test(c)) return false; // パイプ・つなぎ・リダイレクト・展開があるものは対象外
  const file = String.raw`[^\s*?\[\-][^\s*?\[]*`; // オプションとグロブは対象外
  if (new RegExp(String.raw`^cat(?:\s+${file}){1,3}$`).test(c)) return true;
  return new RegExp(String.raw`^sed\s+-n\s+'?\d+(,\d+)?p'?\s+${file}$`).test(c);
}

export function decide(command: string, ctx: Ctx = {}): Decision | null {
  if (pythonRewrite(command)) {
    return ["deny", "ファイルの書き換えは Edit ツールで行う（複数箇所は replace_all）。使い捨ての処理は bun -e で書く（python3 は使わない方針）"];
  }
  if (ctx.cwd?.includes("/.claude/worktrees/")) {
    const rw = shellRewrite(command);
    if (rw) return ["deny", `worktree の中では ${rw} が拒否される。ファイルの作成は Write、書き換えは Read してから Edit ツールで行う`];
  }
  if (ctx.agentId && catForRead(command)) {
    return ["deny", "ファイルは Read ツールで読む（範囲は offset・limit）。cat・sed -n で見ただけでは既読にならず、あとの Edit・Write が失敗する"];
  }
  const eq = equalsWord(command);
  if (eq) {
    return ["deny", `zsh は「${eq}」のような = で始まる語をコマンドのパスに展開して失敗する。'${eq}' と引用符で囲むか、比較は [[ ]] を使う`];
  }
  const split = wordSplitUse(command);
  if (split) {
    const [name, value] = split;
    return [
      "deny",
      `zsh は $${name} を単語分割しないので「${value}」が 1 つのコマンド名として扱われ失敗する。` +
        '関数（例: ab() { agent-browser --session x "$@"; }）か配列で書き直す。' +
        "agent-browser なら export AGENT_BROWSER_SESSION=<名前> で渡す",
    ];
  }
  const stripped = stripLiterals(command);
  const hit = RULES.find(([pattern]) => pattern.test(stripped));
  if (!hit) return null;
  const alt = hit[1] === "git reset --hard" ? "。最新の main に合わせるだけなら `git fetch origin main` のあと `git switch -C <ブランチ> origin/main`" : "";
  return ["ask", `${hit[1]} は他のセッションのコミットを消す恐れがあるため確認します${alt}`];
}

if (import.meta.main) {
  const input = JSON.parse(await Bun.stdin.text());
  const result = decide(input?.tool_input?.command ?? "", { cwd: input?.cwd, agentId: input?.agent_id });
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
