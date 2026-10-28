import { expect, test } from "bun:test";
import { isMerge } from "./log-gh-merge.ts";

test("gh pr merge を拾う", () => {
  expect(isMerge("gh pr merge 5812 --merge")).toBe(true);
  expect(isMerge("cd x && gh pr merge $v --squash -R owner/repo")).toBe(true);
});

test("merge 以外と引用符の中は拾わない", () => {
  expect(isMerge("gh pr view 5812 --json mergedBy")).toBe(false);
  expect(isMerge('git commit -m "gh pr merge を記録"')).toBe(false);
  expect(isMerge("gh pr list --state merged")).toBe(false);
});
