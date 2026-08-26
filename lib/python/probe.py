"""Reports whether the Python bridge is usable, without touching the network.

Run it from Rails to tell a broken interpreter apart from a missing library:
  PythonRunner.call("probe.py")
"""

import json
import platform
import sys

payload = {"python": platform.python_version(), "yfinance": None}

try:
    import yfinance

    payload["yfinance"] = yfinance.__version__
except ImportError:
    pass

sys.stdout.write(json.dumps(payload))
