#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="/opt/ros/noetic/lib/python3/dist-packages:/usr/lib/python3/dist-packages${PYTHONPATH:+:${PYTHONPATH}}"

source /opt/ros/noetic/setup.bash
if [[ -f /ws/SimEnv/devel/setup.bash ]]; then
  source /ws/SimEnv/devel/setup.bash
fi

exec "$@"
