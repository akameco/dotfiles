import { expect, test } from "bun:test";
import { isEnglish, lastAssistantText } from "./lang-guard.ts";

test("英語の経過報告を拾う", () => {
  expect(isEnglish("Now the list page header CSS (page head shared look: mono kicker + large Mincho title + rule).")).toBe(true);
  expect(isEnglish("Meanwhile, I'll take the final screenshots and build the Before/After side-by-side images.")).toBe(true);
});

test("日本語・短文・コードだけは拾わない", () => {
  expect(isEnglish("Now の list page を直します。`app/routes/index.css` の header を変えます。")).toBe(false);
  expect(isEnglish("Done.")).toBe(false);
  expect(isEnglish("```ts\nconst a = 1; export function foo() { return a + 1 }\n```")).toBe(false);
});

const j = (o: object) => JSON.stringify(o);
test("最後の assistant の文章を取る。後にユーザー発言があれば空", () => {
  const a = j({ type: "assistant", message: { content: [{ type: "text", text: "Next I'll run the tests and build." }, { type: "tool_use" }] } });
  const tr = j({ type: "user", message: { content: [{ type: "tool_result" }] } });
  const u = j({ type: "user", message: { content: "日本語で" } });
  expect(lastAssistantText([a, tr])).toBe("Next I'll run the tests and build.");
  expect(lastAssistantText([a, tr, u])).toBe("");
});
