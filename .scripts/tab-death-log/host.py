#!/usr/bin/python3 -I
"""Native-messaging host for the tab death log extension: appends each message it gets, with the time, to a JSONL log."""
import datetime
import json
import os
import struct
import sys

LOG = os.environ.get("TAB_DEATH_LOG") or os.path.expanduser("~/.local/share/browser-tab-watchdog/tab-deaths.jsonl")


def main():
    header = sys.stdin.buffer.read(4)
    if len(header) < 4:
        return
    (length,) = struct.unpack("=I", header)
    message = json.loads(sys.stdin.buffer.read(length))
    record = {"timestamp": datetime.datetime.now().astimezone().isoformat(timespec="seconds"), "browser": "Brave", **message}
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    with open(LOG, "a") as log:
        log.write(json.dumps(record, separators=(",", ":")) + "\n")
    reply = b'{"ok":true}'
    sys.stdout.buffer.write(struct.pack("=I", len(reply)) + reply)
    sys.stdout.buffer.flush()


main()
