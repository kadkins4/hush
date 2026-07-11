#!/bin/bash
# run-dictation.sh — launched by the LaunchAgent at login.
# Waits for Ollama to be reachable, then runs the push-to-talk app on the
# STABLE venv interpreter (so macOS permission grants keep working).

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
cd "$HOME/Developer/hush" || exit 1

# Ollama is started separately (brew services). Give it up to ~60s to answer
# before we launch, so warmup/first-dictation don't fail on a cold server.
for i in $(seq 1 60); do
  if curl -s -o /dev/null http://localhost:11434/api/tags; then
    break
  fi
  # Fallback: if it never comes up, try to start it ourselves once.
  if [ "$i" = "10" ]; then
    (ollama serve >/dev/null 2>&1 &)
  fi
  sleep 1
done

# macOS ties permissions to the RESOLVED binary path. The venv python is a
# symlink, which makes TCC matching ambiguous. So resolve it and exec the real
# interpreter directly, handing it the venv's packages via PYTHONPATH. Now the
# path launchd runs == the path you grant permissions to. No symlink in between.
VENV_PY="$HOME/Developer/hush/.venv/bin/python"
REAL_PY="$("$VENV_PY" -c 'import os,sys;print(os.path.realpath(sys.executable))')"
export PYTHONPATH="$("$VENV_PY" -c 'import site;print(site.getsitepackages()[0])')"

exec "$REAL_PY" "$HOME/Developer/hush/hold_to_talk.py"
