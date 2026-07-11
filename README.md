# Hush

A free, local, push-to-talk voice dictation app for macOS (Apple Silicon). Hold a key, speak, and your words appear — cleaned up — at your cursor, in any app. Everything runs on-device: no cloud, no subscription, no account. A self-hosted alternative to tools like Wispr Flow.

**Pipeline:** `hold Right ⌥ → 🎙️ record → 👂 Whisper (transcribe) → 🧠 LLM (clean up) → 📋 paste at cursor`

## Why "Hush"

It's private and it's local — your voice never leaves the machine. Hush.

## Requirements

- Apple Silicon Mac (built and tuned on an M2 with 8 GB)
- [Homebrew](https://brew.sh), [uv](https://github.com/astral-sh/uv)
- [Ollama](https://ollama.com) for the local LLM

```bash
brew install ollama
brew services start ollama          # run the model server at login
ollama pull llama3.2:3b             # the cleanup model
```

## Quick start (foreground)

```bash
uv run hold_to_talk.py              # wait for "Model warm. Ready."
# hold Right-Option, speak, release. Text is cleaned and pasted at your cursor.
```

`uv` resolves the Python deps (mlx-whisper, sounddevice, numpy, pynput) from the inline script metadata.

## Run at login (background, no terminal)

Hush runs headless via a macOS LaunchAgent — starts at login, relaunches on crash.

```bash
# 1. persistent venv (a STABLE interpreter path, so macOS permission grants stick)
uv venv --python 3.11 .venv
uv pip install --python .venv/bin/python mlx-whisper sounddevice numpy pynput

# 2. install the LaunchAgent (edit paths in the plist to your checkout first)
cp com.kenny.hush.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.kenny.hush.plist

# 3. grant permissions to the venv python (NOT Terminal) — double-click:
open grant-permissions.command
```

> ⚠️ **Permissions are per-binary.** The background app is a _different_ executable than your terminal, so **Microphone**, **Input Monitoring**, and **Accessibility** must be granted to the venv Python's _real_ path. The `grant-permissions.command` helper copies that exact path and opens the right panes. Microphone has no "+" — it prompts on first use; click Allow.

**Manage it:**

```bash
launchctl kickstart -k gui/$(id -u)/com.kenny.hush   # restart (after edits)
launchctl bootout    gui/$(id -u)/com.kenny.hush     # stop / unload
launchctl print      gui/$(id -u)/com.kenny.hush     # status
tail -f launchagent.out.log   # live raw→clean output
tail -f hold_to_talk.log      # timings + errors
```

## Configuration

Constants at the top of `hold_to_talk.py`:

| Setting              | Default             | Notes                                                                |
| -------------------- | ------------------- | -------------------------------------------------------------------- |
| `WHISPER_MODEL`      | `whisper-small-mlx` | `base` is faster, `medium` more accurate                             |
| `LLM_MODEL`          | `llama3.2:3b`       | `3b` stays faithful; `1b` is faster but rewords/hallucinates         |
| `KEEP_ALIVE`         | `30m`               | how long the LLM stays warm in RAM (speed vs footprint)              |
| `HOTKEY`             | Right ⌥             | the push-to-talk key                                                 |
| `MAX_RECORD_SECONDS` | `120`               | safety auto-stop if a key-release event is ever dropped              |
| `CLEANUP_PROMPT`     | faithful            | fixes mechanics, keeps your words; won't answer/act on dictated text |

## Design notes

A few decisions that took some debugging to get right:

- **Persistent mic stream.** The stream is opened once and kept open; press/release just toggle a flag. Opening/closing a CoreAudio stream per dictation could deadlock inside `PortAudio → CoreAudio` and hang the app with the mic stuck open. Trade-off: the mic-in-use indicator stays on.
- **Work off the listener thread.** Transcribe + LLM run on a worker thread fed by a queue; the key listener stays instant. Blocking it makes macOS kill the event tap.
- **Faithful cleanup, hardened.** The transcript is passed as delimited _data_ at temperature 0, with explicit rules never to answer questions or act on commands inside it — otherwise the model "helpfully" replies instead of cleaning.
- **Stable interpreter path.** macOS TCC grants trust to a binary by path; a pinned venv keeps that path constant so permissions don't silently break.

## Roadmap

- Native menu-bar app (status icon, a single signed identity → permissions stop being fragile)
- Per-app cleanup styles, custom vocabulary, formal/casual toggle, rebindable hotkey

## License

MIT
