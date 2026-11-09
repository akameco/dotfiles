#!/usr/bin/env bun
// 応答が英語に流れたら日本語に戻させる hook（2026-11-09 の週次 retro で導入。settings.json に登録済み）。
//   PostToolUse: 直前の assistant の文章が英語なら additionalContext で「日本語で書く」と返す（止めない）
//   Stop:        最後の応答が英語なら decision=block で日本語に書き直させる（stop_hook_active のときは止めない）
//   SessionStart（matcher: compact）: compact の直後に「日本語で書く」を入れる
// 登録例（settings.json）: PostToolUse・Stop は matcher なし、SessionStart は "matcher": "compact"。
//   command: ~/.local/share/mise/installs/bun/latest/bin/bun ~/.claude/hooks/lang-guard.ts、timeout: 5
// 英語の判定は extract.ts lang と同じ（かな・漢字が 3% 未満）。経過報告は短いので 40 字以上を対象にする。
import { closeSync, openSync, readSync, statSync } from "node:fs";

const MIN = 40;
const cpLen = (s: string) => Array.from(s).length;

export function isEnglish(text: string): boolean {
  const t = text.replace(/```[\s\S]*?```|`[^`]*`|https?:\/\/\S+/g, "").trim();
  if (cpLen(t) < MIN) return false;
  return (t.match(/[぀-ヿ一-鿿]/g)?.length ?? 0) / cpLen(t) < 0.03;
}

// transcript の末尾だけ読み、最後の assistant の文章を返す（ツール結果より後のユーザー発言があれば空）
export function lastAssistantText(lines: string[]): string {
  for (let i = lines.length - 1; i >= 0; i--) {
    let o: any;
    try { o = JSON.parse(lines[i]); } catch { continue; }
    const c = o.message?.content;
    if (o.type === "user" && !o.isMeta && (typeof c === "string" || (Array.isArray(c) && c.some((x: any) => x.type === "text")))) return "";
    if (o.type === "assistant" && Array.isArray(c)) {
      const t = c.filter((x: any) => x.type === "text").map((x: any) => x.text).join("\n").trim();
      if (t) return t;
    }
  }
  return "";
}

function tailLines(path: string, bytes = 256 * 1024): string[] {
  const size = statSync(path).size, fd = openSync(path, "r");
  const buf = Buffer.alloc(Math.min(bytes, size));
  readSync(fd, buf, 0, buf.length, size - buf.length);
  closeSync(fd);
  const lines = buf.toString("utf8").split("\n");
  return buf.length < size ? lines.slice(1) : lines; // 途中から読んだときだけ、切れた先頭行を捨てる
}

if (import.meta.main) {
  const input = JSON.parse(await Bun.stdin.text());
  // compact の要約が英語だと、そのあとの応答の約 9 割が英語になる（2026-11-09 の retro）。要約の言語にかかわらず戻す
  if (input.hook_event_name === "SessionStart") {
    if (input.source === "compact") console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: "会話は compact されました。要約が英語でも、以降の応答・経過報告は日本語で書く。" } }));
    process.exit(0);
  }
  const text = input.transcript_path ? lastAssistantText(tailLines(input.transcript_path)) : "";
  if (!isEnglish(text)) process.exit(0);
  if (input.hook_event_name === "Stop") {
    if (!input.stop_hook_active) console.log(JSON.stringify({ decision: "block", reason: "最後の応答が英語でした。同じ内容を日本語で書き直してください（コード・識別子はそのまま）。" }));
  } else {
    console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: "直前の経過報告が英語でした。以降の文章（経過報告を含む）は日本語で書く。" } }));
  }
}
