#!/usr/bin/env bash
set -euo pipefail

: "${MODEL:?Set MODEL to a local Qwen3-8B or Llama3-8B directory}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RUN_DIR:-${SCRIPT_DIR}/../../runs/cli-quickstart}"
INPUT_JSON="${INPUT_JSON:-${SCRIPT_DIR}/../datasets/economics.json}"

mkdir -p "${RUN_DIR}"

ARGS=(
  --model "${MODEL}"
  --input-json "${INPUT_JSON}"
  --reward-type gt
  --max-players 10
  --top-k 5
  --output-dir "${RUN_DIR}/interaction"
)

if [[ -n "${REFERENCE_MODEL:-}" ]]; then
  ARGS+=(--reference-model "${REFERENCE_MODEL}")
fi

sitkit "${ARGS[@]}"

printf 'SITKit quickstart outputs: %s\n' "${RUN_DIR}"
