#!/Users/akameco/.local/share/mise/shims/bun

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Open GitHub Issue/PR
// @raycast.mode silent
// @raycast.packageName GitHub
// @raycast.argument1 { "type": "text", "placeholder": "#5892 / owner/repo#12" }

// Optional parameters:
// @raycast.icon 🐙
// @raycast.description #番号で GitHub の Issue / PR を開く（フォールバックコマンド用）

// 既定のリポジトリ（owner/repo）は chezmoi で暗号化したファイルに置く
const DEFAULT_REPO = (
  await Bun.file(`${process.env.HOME}/.config/raycast/github-default-repo`).text()
).trim();

const input = (process.argv[2] ?? "").trim();
const match = input.match(/^(?:([\w.-]+\/[\w.-]+))?#?(\d+)$/);

if (!match) {
  console.log(`番号として読めません: ${input}`);
  process.exit(1);
}

const [, repo = DEFAULT_REPO, number] = match;
// /issues/N は PR 番号でも /pull/N にリダイレクトされる
const url = `https://github.com/${repo}/issues/${number}`;

Bun.spawnSync(["open", url]);
console.log(`${repo}#${number}`);
