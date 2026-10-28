#!/usr/bin/env python3
"""Rich macOS notifications for Claude Code agents running in herdr panes.

Usage:
  herdr-notify.py hook    # from a Claude Code Stop / Notification hook (JSON on stdin)
  herdr-notify.py test    # show a sample notification for the current pane

Title: agent or tab name and the event. Subtitle: repository and branch.
Body: the last assistant message (Stop) or Claude's notification text.
Clicking focuses the pane in herdr and brings the terminal to the front.
Nothing is shown while the pane is focused and the terminal is frontmost.
"""
import json
import os
import re
import shlex
import shutil
import subprocess
import sys

BODY_MAX = 180
TERMINAL_BUNDLE = os.environ.get("__CFBundleIdentifier", "com.mitchellh.ghostty")
EVENTS = {
    "Stop": "完了",
    "permission_prompt": "許可待ち",
    "idle_prompt": "入力待ち",
    "elicitation_dialog": "入力待ち",
}


def run(*args):
    out = subprocess.run(args, capture_output=True, text=True, timeout=5)
    return out.stdout.strip() if out.returncode == 0 else ""


def herdr(*args):
    try:
        return json.loads(run(os.environ.get("HERDR_BIN_PATH", "herdr"), *args))["result"]
    except (ValueError, KeyError, subprocess.SubprocessError):
        return {}


def one_line(text):
    text = " ".join(text.split())
    return text if len(text) <= BODY_MAX else text[: BODY_MAX - 1].rstrip() + "…"


def last_assistant_text(transcript_path):
    try:
        with open(transcript_path, encoding="utf-8") as f:
            lines = f.readlines()[-400:]
    except OSError:
        return ""
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        message = entry.get("message") or {}
        if entry.get("type") != "assistant" or not isinstance(message.get("content"), list):
            continue
        texts = [c.get("text", "") for c in message["content"] if c.get("type") == "text"]
        if any(t.strip() for t in texts):
            return "\n".join(texts)
    return ""


def event_of(payload):
    if payload.get("hook_event_name") == "Stop":
        return "Stop"
    return payload.get("notification_type") or "idle_prompt"


def body_of(payload, event):
    if event == "Stop":
        text = payload.get("last_assistant_message") or last_assistant_text(
            payload.get("transcript_path", "")
        )
        return one_line(text) or "応答が終わりました"
    return one_line(payload.get("message", "")) or "入力を待っています"


def name_of(agent, tab):
    return (
        agent.get("name")
        or agent.get("terminal_title_stripped")
        or tab.get("label")
        or "Claude Code"
    )


def subtitle_of(cwd):
    repo = run("git", "-C", cwd, "rev-parse", "--show-toplevel") or cwd
    branch = run("git", "-C", cwd, "branch", "--show-current")
    name = os.path.basename(re.split(r"/(?:\.local/__worktree|\.claude/worktrees)/", repo)[0])
    return f"{name} · {branch}" if branch else name


def is_watching(agent):
    front = run("lsappinfo", "info", "-only", "bundleid", run("lsappinfo", "front"))
    return bool(agent.get("focused")) and TERMINAL_BUNDLE in front


def click_command(pane_id):
    env = " ".join(
        f"{key}={shlex.quote(os.environ[key])}"
        for key in ("HERDR_SOCKET_PATH",)
        if key in os.environ
    )
    herdr_bin = shlex.quote(os.environ.get("HERDR_BIN_PATH", "herdr"))
    focus = f"{env} {herdr_bin} agent focus {shlex.quote(pane_id)}".strip()
    return f"{focus} >/dev/null 2>&1; open -b {shlex.quote(TERMINAL_BUNDLE)}"


def notify(pane_id, payload, check_focus=True):
    notifier = shutil.which("terminal-notifier") or "/opt/homebrew/bin/terminal-notifier"
    if not os.path.exists(notifier):
        return
    agent = herdr("agent", "get", pane_id).get("agent", {})
    if check_focus and is_watching(agent):
        return
    tab = herdr("tab", "get", os.environ.get("HERDR_TAB_ID", "")).get("tab", {})
    event = event_of(payload)
    cwd = payload.get("cwd") or agent.get("cwd") or os.getcwd()
    subprocess.Popen(
        [
            notifier,
            "-title", f"{name_of(agent, tab)} — {EVENTS.get(event, '通知')}",
            "-subtitle", subtitle_of(cwd),
            "-message", body_of(payload, event),
            "-group", f"herdr-notify:{pane_id}",
            "-execute", click_command(pane_id),
            "-sound", "Glass" if event == "Stop" else "Ping",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def main():
    pane_id = os.environ.get("HERDR_PANE_ID")
    if not pane_id:
        return
    mode = sys.argv[1] if len(sys.argv) > 1 else "hook"
    if mode == "test":
        notify(pane_id, {"hook_event_name": "Stop", "last_assistant_message": "テスト通知です。クリックするとこのペインへ移ります。"}, check_focus=False)
        return
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return
    notify(pane_id, payload)


if __name__ == "__main__":
    main()
