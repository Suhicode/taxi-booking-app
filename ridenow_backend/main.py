# Minimal deployment wrapper to expose the root-level FastAPI `app` when
# Render sets the working directory to `ridenow_backend`.
# This keeps application code unchanged and only adds a small wrapper.
import sys
from pathlib import Path

# Add repository root to path so we can import the main app defined at repo root
sys.path.append(str(Path(__file__).resolve().parents[1]))

from main import app  # NOQA: re-export the FastAPI app for uvicorn

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
