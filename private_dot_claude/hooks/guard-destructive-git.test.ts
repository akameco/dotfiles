// guard-destructive-git.ts を実際と同じ stdin 経由で呼んで判定を確かめる。
//   bun test ~/.claude/hooks/guard-destructive-git.test.ts
import { expect, test } from "bun:test";

const HOOK = `${import.meta.dir}/guard-destructive-git.ts`;

const CASES: [string, "ask" | "deny" | null][] = [
  // git reset --hard / force push は ask
  ["git reset --hard HEAD~1", "ask"],
  ["git reset -q --hard 9e8e9f0", "ask"],
  ["git -C ~/dev/x reset --hard origin/main", "ask"],
  ["git push --force origin main", "ask"],
  ["git push -f origin main", "ask"],
  ["git push origin +main", "ask"],
  ["cd x && git fetch && git reset --hard origin/main", "ask"],
  // 通すもの
  ["git push --force-with-lease origin feat/x", null],
  ["git reset --soft HEAD~1", null],
  ['git commit -m "docs: git reset --hard を使わない"', null],
  ["git commit -F - <<'EOF'\nfix: avoid git push --force\nEOF", null],
  ["grep -n 'git reset --hard' notes.md", null],
  ["gh pr view 12 --json body", null],
  // zsh の単語分割は deny
  ['B="agent-browser --session v1"; $B open http://x', "deny"],
  ['B="agent-browser --session v1"\n$B screenshot a.png', "deny"],
  ['export AB="agent-browser --session v2" && ${AB} open x', "deny"],
  ['for n in 1 2; do X="gh pr view --json"; $X $n; done', "deny"],
  // 単語分割でも通すもの
  ['B="agent-browser --session v1"; echo "$B"', null],
  ['msg="hello world"; echo $msg', null],
  ["D=~/x; ls $D", null],
  ["export AGENT_BROWSER_SESSION=v1; agent-browser open x", null],
  ["cat > s.sh <<'EOF'\n#!/bin/bash\nB=\"agent-browser --session v1\"\n$B open x\nEOF\nbash s.sh", null],
  ["bash -c 'B=\"agent-browser --session v1\"; $B open x'", null],
  // オプションの無い「コマンド 引数」も単語分割で deny
  ['T="node /x/tw-css.mjs"; $T a.css', "deny"],
  // zsh の = 展開は deny
  ["echo ====; git status", "deny"],
  ["echo ===== && ls", "deny"],
  ['[ "$a" == b ] && echo y', "deny"],
  // = 展開でも通すもの
  ["echo '===='; git status", null],
  ['[[ "$a" == b ]] && echo y', null],
  ["(( n = 1 )); echo $n", null],
  ["git log --format=%H -1", null],
  ["x=1; y=$x", null],
  ["awk -F= '{print $2}' a.env", null],
  ['[ "$b" = dev ] && echo y', null],
  // python3 のヒアドキュメントでの書き換えは deny
  ["python3 - <<'EOF'\np='a.ts'\ns=open(p).read()\nopen(p,'w').write(s.replace('a','b'))\nEOF", "deny"],
  ["cd x && python3 -I - <<'EOF'\nfrom pathlib import Path\np=Path('a.ts'); s=open(p).read(); p.write_text(s)\nEOF", "deny"],
  // python3 でも通すもの
  ["python3 - <<'EOF'\nimport json\nprint(json.load(open('a.json'))['x'])\nEOF", null],
  ["python3 scrape_dcatalog.py --out a.json", null],
];

// worktree の中（cwd に /.claude/worktrees/）の sed -i・heredoc での書き込みは deny
const WT = "/Users/x/dev/repo/.claude/worktrees/feat-a";
// サブエージェント（agent_id あり）の cat・sed -n だけのコマンドは deny
const SUB = "agent-123";
const CTX_CASES: [string, { cwd?: string; agent_id?: string }, "ask" | "deny" | null][] = [
  ["sed -i '' 's/a/b/' src/a.ts", { cwd: WT }, "deny"],
  ["sed -i.bak -e 's/a/b/' a.ts", { cwd: WT }, "deny"],
  ["cat > src/a.ts <<'EOF'\nexport const a = 1\nEOF", { cwd: WT }, "deny"],
  ["cat >> notes.md <<EOF\nx\nEOF", { cwd: WT }, "deny"],
  ["tee src/a.ts <<'EOF'\nx\nEOF", { cwd: WT }, "deny"],
  // worktree の中でも通すもの・worktree の外は通す
  ["sed -n '1,20p' a.ts", { cwd: WT }, null],
  ["git commit -F - <<'EOF'\nfix: x\nEOF", { cwd: WT }, null],
  ["cat a.ts | grep foo", { cwd: WT }, null],
  ["sed -i '' 's/a/b/' a.ts", { cwd: "/Users/x/dev/repo" }, null],
  ["cat > a.ts <<'EOF'\nx\nEOF", {}, null],
  // サブエージェント
  ["cat src/a.ts", { agent_id: SUB }, "deny"],
  ["cat src/a.ts src/b.css tokens.css", { agent_id: SUB }, "deny"],
  ["sed -n '10,80p' src/a.ts", { agent_id: SUB }, "deny"],
  ["sed -n 10,80p src/a.ts", { agent_id: SUB }, "deny"],
  // サブエージェントでも通すもの・main は通す
  ["cat a.ts | head -20", { agent_id: SUB }, null],
  ["cat a b c d", { agent_id: SUB }, null],
  ["cat docs/*.md", { agent_id: SUB }, null],
  ["cat -n a.ts", { agent_id: SUB }, null],
  ["grep -n foo a.ts", { agent_id: SUB }, null],
  ["cat src/a.ts", {}, null],
];

function run(command: string, extra: { cwd?: string; agent_id?: string } = {}): string | null {
  const out = Bun.spawnSync(["bun", HOOK], { stdin: Buffer.from(JSON.stringify({ tool_input: { command }, ...extra })) });
  const text = out.stdout.toString().trim();
  return text ? JSON.parse(text).hookSpecificOutput.permissionDecision : null;
}

for (const [command, want] of CASES) {
  test(`${want ?? "allow"}: ${command.replaceAll("\n", "⏎")}`, () => {
    expect(run(command)).toBe(want);
  });
}

for (const [command, extra, want] of CTX_CASES) {
  test(`${want ?? "allow"} (${extra.agent_id ? "sub" : extra.cwd?.includes("worktrees") ? "wt" : "main"}): ${command.replaceAll("\n", "⏎")}`, () => {
    expect(run(command, extra)).toBe(want);
  });
}

test("reset --hard の ask に代わりの手順が付く", () => {
  const out = Bun.spawnSync(["bun", HOOK], { stdin: Buffer.from(JSON.stringify({ tool_input: { command: "git reset --hard origin/main" } })) });
  expect(JSON.parse(out.stdout.toString()).hookSpecificOutput.permissionDecisionReason).toContain("git switch -C");
});
