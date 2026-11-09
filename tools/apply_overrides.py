#!/usr/bin/env python3
"""Apply run-form overrides (voice, speed, music) to a project's script.json."""
import json
import sys


def main() -> None:
    proj = sys.argv[1]
    voice = sys.argv[2]
    speed = float(sys.argv[3])
    music = sys.argv[4]
    path = f"{proj}/script.json"
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    if voice:
        d["voice"] = voice
    if speed:
        d["speed"] = speed
    if music:
        d["music"] = music
    with open(path, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
    print(f"overrides applied: voice={d.get('voice')} speed={d.get('speed')} music={d.get('music')}")


if __name__ == "__main__":
    main()
