#!/usr/bin/env bash
set -e

# 在 SITKit 目录下运行：
# bash examples/cli/quickstart.sh

# 只需按实际情况修改下面三个路径。
MODEL_PATH="./models/Qwen3-8B"
INPUT_FILE="examples/datasets/economics.json"
OUTPUT_DIR="runs/economics"

# 第一步：检查输入数据，不加载模型。
echo "Checking input data..."
sitkit \
  --input-json "$INPUT_FILE" \
  --check-only

# 第二步：运行单模型交互分析。
echo "Running SITKit..."
sitkit \
  --model "$MODEL_PATH" \
  --input-json "$INPUT_FILE" \
  --output-dir "$OUTPUT_DIR"

echo "Done. Results are saved in: $OUTPUT_DIR"
