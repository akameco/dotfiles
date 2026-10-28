// guard-deploy.ts を実際と同じ stdin 経由で呼んで判定を確かめる。
//   bun test ~/.claude/hooks/guard-deploy.test.ts
import { expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";

const HOOK = `${import.meta.dir}/guard-deploy.ts`;

// 移行済み（cloudflare.config.ts あり）と未移行のディレクトリ
const ROOT = mkdtempSync(`${tmpdir()}/guard-deploy-`);
const CF = `${ROOT}/cf`;
const PLAIN = `${ROOT}/plain`;
mkdirSync(CF);
mkdirSync(PLAIN);
writeFileSync(`${CF}/cloudflare.config.ts`, "export default {};\n");

const CASES: [string, string, "deny" | null][] = [
  // 本番デプロイ・アップロードは deny
  ["pnpm exec cf deploy", CF, "deny"],
  ["pnpm exec cf deploy --prebuilt", CF, "deny"],
  ["pnpm exec cf previews deploy", CF, "deny"],
  ["pnpm exec wrangler deploy", CF, "deny"],
  ["npx wrangler versions upload", CF, "deny"],
  ["wrangler pages deploy dist", CF, "deny"],
  // 2026-10-21 の事故: pnpm 12 は -- をそのまま渡すので --dry-run が wrangler に効かない
  ["pnpm deploy:worker -- --dry-run", CF, null], // スクリプト名だけでは中身が分からないので通る（スクリプトは撤去済み）
  ["vite build && wrangler deploy -- --dry-run", CF, "deny"],
  ["pnpm exec cf deploy -- --dry-run", CF, "deny"],
  // ログインは deny
  ["pnpm exec cf auth login", CF, "deny"],
  ["pnpm exec wrangler login", CF, "deny"],
  ["pnpm exec wrangler deploy --dry-run --temporary", CF, "deny"],
  // 未移行のディレクトリでの cf dev|build|deploy は deny
  ["pnpm exec cf build", PLAIN, "deny"],
  ["pnpm exec cf dev", PLAIN, "deny"],
  ["pnpm exec cf deploy --dry-run", PLAIN, "deny"],
  [`cd ${PLAIN} && pnpm exec cf build`, CF, "deny"],
  [`pnpm --dir ${PLAIN} exec cf build`, CF, "deny"],
  // 変数の展開（2026-10-21、`W=...; cd $W` を誤って止めた）
  [`W=${CF}; cd $W && pnpm exec cf build`, PLAIN, null],
  [`W=${PLAIN}; cd $W && pnpm exec cf build`, CF, "deny"],
  [`W=${CF}\ncd \${W} && pnpm exec cf build`, PLAIN, null],
  ["cd $UNKNOWN && pnpm exec cf build", PLAIN, null], // 展開できない先は判定しない
  ["cd $UNKNOWN && pnpm exec cf deploy", PLAIN, "deny"], // デプロイの判定は続ける
  [`D=${PLAIN}; pnpm --dir $D exec cf build`, CF, "deny"],
  [`cd "$(git rev-parse --show-toplevel)" && pnpm exec cf build`, PLAIN, null], // 引用符の中は判定しない
  [`W=${PLAIN}; cd "$W" && pnpm exec cf build`, CF, null],
  [`cd "${PLAIN}" && pnpm exec cf deploy`, CF, "deny"], // デプロイの判定は続ける
  // 通すもの
  ["pnpm exec cf deploy --dry-run", CF, null],
  ["pnpm exec cf build && pnpm exec cf deploy --dry-run", CF, null],
  ["pnpm exec wrangler deploy --dry-run", CF, null],
  [`cd ${CF} && pnpm exec cf build`, PLAIN, null],
  [`pnpm --dir ${CF} exec cf build`, PLAIN, null],
  ["portless share-impl pnpm exec cf dev", CF, null],
  ["pnpm exec cf --help", PLAIN, null],
  ['git commit -m "chore: cf deploy の手順を README に書く"', PLAIN, null],
  ["grep -n 'wrangler login' README.md", PLAIN, null],
  ["cat > notes.md <<'EOF'\npnpm exec cf deploy\nEOF", PLAIN, null],
];

function run(command: string, cwd: string): string | null {
  const out = Bun.spawnSync(["bun", HOOK], { stdin: Buffer.from(JSON.stringify({ cwd, tool_input: { command } })) });
  const text = out.stdout.toString().trim();
  return text ? JSON.parse(text).hookSpecificOutput.permissionDecision : null;
}

for (const [command, cwd, want] of CASES) {
  test(`${want ?? "allow"}: ${command.replaceAll("\n", "⏎")} (${cwd === CF ? "cf" : "plain"})`, () => {
    expect(run(command, cwd)).toBe(want);
  });
}
