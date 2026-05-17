#!/usr/bin/env bash
set -euo pipefail

swift test
./script/build_and_run.sh --ui-smoke

