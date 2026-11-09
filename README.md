# faceless-cloud

Render narrated, captioned vertical shorts (9:16) entirely on GitHub's servers.
Your computer only submits the job and downloads the finished MP4 — rendering never touches your CPU.

## How it works

```
 your PC                        GitHub Actions (ubuntu)
┌─────────────┐   job form    ┌──────────────────────────────┐
│ script.json │ ────────────▶ │ AI voice (Kokoro)            │
│  or project │               │ word timing (Whisper)        │
└─────────────┘               │ frame render (Chrome)        │
                              │ music + sfx + ffmpeg         │
        ▲                     └──────────────┬───────────────┘
        └──── MP4 + QA sheet (Artifacts) ─────┘
```

## Two ways to start a render

### A. From the web UI
1. Open **Actions → render → Run workflow**
2. Either paste full `script.json` content into **script_json** (and pick a style), or name an existing folder under `projects/`
3. Choose voice, speed, music, FPS → **Run workflow**
4. When the run turns green, download **video-\<project\>** from the run's Artifacts

### B. One command from your PC
```powershell
tools\render-cloud.ps1 -Script my-script.json -Title "My Video"
```
It submits the job, waits, and drops the finished MP4 into `renders\`.

## Inputs

| input | default | meaning |
|---|---|---|
| `project` | — | render a committed project from `projects/` |
| `script_json` | — | full script.json content (used when `project` is empty; never committed) |
| `style` | inside-out | template: inside-out · deep-dive · night-file · stick-story · paper-atlas · tall-tale |
| `voice` | am_michael | any Kokoro voice id (am_puck, af_heart, …) |
| `speed` | 1.0 | speech speed multiplier |
| `music` | bed | `bed` (built-in) or `none` |
| `fps` | 30 | lower = faster render |
| `temp_host` | false | also get a public watch link that self-deletes after 24 h |

## What every run produces
- **video-\<project\>** artifact — the finished MP4
- **qa-\<project\>** artifact — a time-stamped contact sheet (every 0.5 s) + word-timing JSON, so any frame can be checked before posting
- A run **summary** page with settings and duration

## Privacy
- Nothing about you is stored in this repo
- Rendered projects created from `script_json` exist only inside the run, and are deleted when it finishes
- `temp_host` is opt-in: the video is uploaded to a public temporary host (24 h) only if you ask for it

## Notes & limits
- Free plan: 2 000 Actions minutes/month on private repos, unlimited on public repos. A typical 25 s video costs 10-20 minutes
- Brand-new GitHub accounts can see private-repo Actions fail instantly with "no jobs" — this lifts after account verification / a short wait, or use a public repo
- Voice models (~850 MB) are cached after the first run, so later renders are much faster
