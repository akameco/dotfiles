#!/usr/bin/env python3
"""Give herdr tabs short automatic labels.

Usage:
  herdr-tab-autoname.py hook [--agy]   # from a Claude Code / agy Stop hook
  herdr-tab-autoname.py all [--dry-run]

Label priority: ticket / PR number > worktree branch > title cut to MAX_WIDTH.
Only tabs whose label is still a herdr default number, or the label this
script set last time, are renamed, so hand-written names are kept.
"""
import glob
import json
import os
import re
import sqlite3
import subprocess
import sys
import tempfile
import unicodedata

MAX_WIDTH = 10
STATE_PATH = os.path.expanduser("~/.cache/herdr-tab-autoname/state.json")
AGY_DB = os.path.expanduser("~/.gemini/antigravity-cli/conversation_summaries.db")
TICKET_RE = re.compile(r"(?<![A-Za-z0-9])([A-Z][A-Z0-9]{1,9}-\d+)(?!\d)")
PR_RE = re.compile(r"(?<![A-Za-z0-9])PR\s*#?(\d+)(?!\d)", re.IGNORECASE)
NOT_TICKETS = {"UTF", "ISO", "SHA"}
DEFAULT_TITLES = {"", "Claude Code"}
COMMAND_RE = re.compile(r"<command-name>/?([\w:-]+)</command-name>(?:(?:\\n|\s)*<command-args>/?([\w:-]+))?")


def herdr(*args):
    out = subprocess.run(["herdr", *args], capture_output=True, text=True, timeout=5)
    return json.loads(out.stdout)["result"]


def width(text):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in text)


def cut(text):
    text = " ".join(text.split())
    if width(text) <= MAX_WIDTH:
        return text
    kept = ""
    for c in text:
        if width(kept + c) > MAX_WIDTH - 1:
            break
        kept += c
    return kept.rstrip(" ・-_:") + "…"


def find_ticket(text):
    pr = PR_RE.search(text)
    if pr:
        return "PR" + pr.group(1)
    tickets = [t for t in TICKET_RE.findall(text) if t.split("-")[0] not in NOT_TICKETS]
    return tickets[0] if tickets else None


def branch_of(cwd):
    m = re.search(r"/(?:\.local/__worktree|\.claude/worktrees)/([^/]+)", cwd)
    return m.group(1) if m else None


def agy_title(conversation_id):
    # mode=ro fails on a WAL database once agy has removed the -shm file;
    # immutable=1 reads the main file directly, which is complete then.
    for query in ("mode=ro", "immutable=1"):
        try:
            with sqlite3.connect(f"file:{AGY_DB}?{query}", uri=True, timeout=1) as db:
                row = db.execute(
                    "select title from conversation_summaries where conversation_id = ?",
                    (conversation_id,),
                ).fetchone()
            return row[0] if row else ""
        except sqlite3.Error:
            continue
    return ""


def first_command(session_id):
    # スラッシュコマンドで始めたセッションは Claude Code がタイトルを付けないので、コマンド名を使う
    # （/loop /linear-auto-impl なら linear-auto-impl）
    paths = glob.glob(os.path.expanduser(f"~/.claude/projects/*/{session_id}.jsonl"))
    if not paths:
        return ""
    with open(paths[0]) as f:
        for line in f:
            if '"type":"user"' not in line:
                continue
            m = COMMAND_RE.search(line)
            if m:
                return m.group(2) if m.group(1) == "loop" and m.group(2) else m.group(1)
            return ""
    return ""


def title_of(pane):
    session = pane.get("agent_session") or {}
    if pane.get("agent") == "agy":
        return agy_title(session["value"]) if session.get("value") else ""
    # スラッシュコマンドで始めたセッションは、途中の発言で付いたタイトルよりコマンド名を優先する
    command = first_command(session["value"]) if pane.get("agent") == "claude" and session.get("value") else ""
    if command:
        return command
    title = pane.get("terminal_title_stripped") or ""
    return title if title not in DEFAULT_TITLES else ""


def label_for(pane):
    title = title_of(pane)
    branch = branch_of(pane.get("foreground_cwd") or pane.get("cwd") or "")
    ticket = find_ticket(title) or (find_ticket(branch) if branch else None)
    if ticket:
        return ticket
    if branch:
        return cut(branch)
    return cut(title) if title else None


def load_state():
    try:
        with open(STATE_PATH) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_state(state):
    os.makedirs(os.path.dirname(STATE_PATH), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(STATE_PATH))
    with os.fdopen(fd, "w") as f:
        json.dump(state, f, ensure_ascii=False)
    os.replace(tmp, STATE_PATH)


def plan(panes, tabs, state):
    """Return {tab_id: new_label} for tabs that should be renamed."""
    first_pane = {}
    for p in panes:
        first_pane.setdefault(p["tab_id"], p)
    renames = {}
    for tab_id, pane in first_pane.items():
        current = tabs.get(tab_id)
        if current is None:
            continue
        if not (current.isdigit() or current == state.get(tab_id)):
            continue
        label = label_for(pane)
        if label and label != current:
            renames[tab_id] = label
    return renames


def run(panes, dry_run=False):
    tab_ids = {p["tab_id"] for p in panes}
    tabs = {
        t["tab_id"]: t["label"]
        for t in herdr("tab", "list")["tabs"]
        if t["tab_id"] in tab_ids
    }
    state = load_state()
    renames = plan(panes, tabs, state)
    for tab_id, label in renames.items():
        print(f"{tab_id}: {tabs[tab_id]} -> {label}", file=sys.stderr)
        if not dry_run:
            herdr("tab", "rename", tab_id, label)
    if renames and not dry_run:
        save_state({**state, **renames})


def hook():
    pane = herdr("pane", "get", os.environ["HERDR_PANE_ID"])["pane"]
    siblings = [
        p for p in herdr("pane", "list", "--workspace", pane["workspace_id"])["panes"]
        if p["tab_id"] == pane["tab_id"]
    ]
    run(siblings)


def main(argv):
    mode = argv[1] if len(argv) > 1 else "hook"
    if mode == "all":
        run(herdr("pane", "list")["panes"], dry_run="--dry-run" in argv)
        return
    is_agy = "--agy" in argv
    try:
        sys.stdin.read()
        if os.environ.get("HERDR_ENV") == "1" and os.environ.get("HERDR_PANE_ID"):
            hook()
    except Exception:
        pass
    if is_agy:
        print("{}")


if __name__ == "__main__":
    main(sys.argv)
