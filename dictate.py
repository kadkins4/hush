# /// script
# requires-python = ">=3.11"
# dependencies = ["mlx-whisper"]
# ///
"""
dictate.py — the local dictation loop in one command.

    uv run dictate.py "path/to/audio.m4a"

Pipeline (your Wispr Flow clone, stations 2 + 3):
    audio file -> Whisper (transcribe) -> LLM (clean up) -> print + copy to clipboard
Everything runs locally on your Mac. No cloud, no cost.
"""

import json
import subprocess
import sys
import urllib.error
import urllib.request

# --- Config: the two models. Swap these to trade speed vs quality. ---
WHISPER_MODEL = "mlx-community/whisper-small-mlx"  # the "ears" (Station 2)
LLM_MODEL = "llama3.2:3b"                          # the "brain" (Station 3)
OLLAMA_URL = "http://localhost:11434/api/generate"

CLEANUP_PROMPT = (
    "Clean up this dictation. Fix punctuation and capitalization, remove filler "
    "words (um, uh, like), and tidy the grammar — but keep my exact meaning. "
    "Return ONLY the cleaned text, with no preamble or quotes.\n\nTranscript:\n"
)


def transcribe(audio_path: str) -> str:
    """Station 2 — the ears. Whisper is a Python library we call directly."""
    import mlx_whisper  # imported here so --help is instant

    result = mlx_whisper.transcribe(audio_path, path_or_hf_repo=WHISPER_MODEL)
    return result["text"].strip()


def clean_up(text: str) -> str:
    """Station 3 — the brain. We talk to Ollama over its local HTTP API,
    the same way you'd call any LLM server (local or cloud)."""
    payload = json.dumps(
        {"model": LLM_MODEL, "prompt": CLEANUP_PROMPT + text, "stream": False}
    ).encode()
    req = urllib.request.Request(
        OLLAMA_URL, data=payload, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())["response"].strip()
    except urllib.error.URLError:
        sys.exit(
            "❌ Can't reach Ollama at localhost:11434.\n"
            "   Start it first:  ollama serve   (or launch the Ollama app)"
        )


def copy_to_clipboard(text: str) -> None:
    """A first taste of Station 4 (inject): put the result on the clipboard."""
    subprocess.run("pbcopy", input=text.encode(), check=True)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit('usage: uv run dictate.py "path/to/audio.m4a"')
    audio_path = sys.argv[1]

    print("👂 Transcribing…", file=sys.stderr)
    raw = transcribe(audio_path)
    print(f"   raw: {raw}\n", file=sys.stderr)

    print("🧠 Cleaning up…", file=sys.stderr)
    clean = clean_up(raw)

    print(clean)  # the payoff goes to stdout so you can pipe it
    copy_to_clipboard(clean)
    print("\n✅ Cleaned text copied to clipboard.", file=sys.stderr)


if __name__ == "__main__":
    main()
