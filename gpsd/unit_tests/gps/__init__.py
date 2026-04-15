from pathlib import Path

__path__ = [str(Path("/workspace/run/unit_tests/gps")), str(Path("/src/gpsd/gps"))]

from .misc import *  # noqa: F401,F403
