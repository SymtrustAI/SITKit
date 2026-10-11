<div align="center">

<p>
  <a href="https://www.symtrustai.com/"><img src="assets/branding/symtrust-logo.png" alt="SymTrust" height="82"></a>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://www.sjtu.edu.cn/"><img src="assets/branding/sjtu-logo.png" alt="Shanghai Jiao Tong University" height="82"></a>
</p>

<h1>SITKit</h1>

<p><strong>Surrogate Interaction Theory Toolkit</strong></p>

<p>Generate model interaction reports from a local language model and a JSON dataset.</p>

<p><code>v0.1.0</code> · <code>Python 3.11</code> · <code>Linux x86_64</code></p>

<p><a href="LICENSE.md">PolyForm Strict 1.0.0</a></p>

<p><strong>English</strong> · <a href="README.zh-CN.md">简体中文</a></p>

</div>

---

## Before you start

This release supports:

- Linux x86_64
- Conda
- Python 3.11
- Qwen3-8B and Llama3-8B base models
- An NVIDIA GPU is recommended; CPU-only execution is very slow

The steps below use **single-model analysis with Qwen3-8B**.

## Step 1: Create a Conda environment

```bash
conda create -n sitkit python=3.11 -y
conda activate sitkit
python --version
```

The last command should print `Python 3.11.x`.

## Step 2: Enter the downloaded directory

Place this repository and `sitkit-0.1.0-*.whl` in the same directory, then enter it:

```bash
cd SITKit
ls
```

You should see:

```text
README.md
README.zh-CN.md
examples/
requirements.txt
sitkit-0.1.0-cp311-cp311-linux_x86_64.whl
```

## Step 3: Install SITKit

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m pip install --no-deps ./sitkit-0.1.0-*.whl
sitkit --version
```

Successful installation prints:

```text
SITKit 0.1.0
```

## Step 4: Download Qwen3-8B

```bash
mkdir -p models

python - <<'PY'
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="Qwen/Qwen3-8B",
    revision="b968826d9c46dd6066d109eabc6255188de91218",
    local_dir="models/Qwen3-8B",
)
PY
```

Do not modify, convert, or resave the downloaded model files. SITKit verifies the
model contents and selects the matching baseline bundled in the wheel.

<details>
<summary><strong>How to prepare your own samples</strong></summary>

### Input text (`text`)

- Use **10–20 English words**.
- Avoid repeated or redundant phrases.
- Keep the text natural and semantically meaningful.

### Players (`players`)

- The method recommends **8–15 players**. To control computation, this public
  release supports at most 12, so use **8–12 players** in practice.
- A player may be one word or a contiguous phrase. Players do not need to cover
  every word in the input.
- Preserve their original order in the text.
- Avoid punctuation-only tokens.
- Avoid weak semantic words such as `and`, `to`, and `the`.
- Players must not overlap, and every player must occur in the input text.

### Explanation target (`target_text`, optional)

- Prefer a semantically meaningful content word, such as a noun, verb, or adjective.
- Low model confidence in the selected word can reduce the stability and
  interpretability of the result.
- If omitted, SITKit explains the target model's highest-probability next token.

A minimal dataset is a JSON array of sample objects:

```json
[
  {
    "text": "Rising energy costs reduced factory output and weakened regional manufacturing",
    "players": [
      {"text": "Rising"},
      {"text": "energy"},
      {"text": "costs"},
      {"text": "reduced"},
      {"text": "factory output"},
      {"text": "weakened"},
      {"text": "regional"},
      {"text": "manufacturing"}
    ],
    "target_text": "growth"
  }
]
```

Validate the file before starting an analysis:

```bash
sitkit --input-json your-dataset.json --check-only
```

Continue only after the order, location, and overlap checks pass.

</details>

## Step 5: Validate the example dataset

Check the JSON without loading a model:

```bash
sitkit \
  --input-json examples/datasets/economics.json \
  --check-only
```

Valid data produces output containing:

```text
"status": "valid"
"sample_count": 20
```

You can also validate the data and run the analysis with the simplified CLI example:

```bash
bash examples/cli/quickstart.sh
```

Only the model, dataset, and output paths are configurable at the top of the script.

## Step 6: Run the analysis

```bash
sitkit \
  --model ./models/Qwen3-8B \
  --input-json examples/datasets/economics.json \
  --output-dir runs/economics
```

SITKit processes all 20 samples in order. Loading an 8B model can take some time
on the first run.

## Step 7: View the results

The report for the first sample is located at:

```text
runs/economics/economics-0001/report/target_model/
├── inference.txt
├── optimization_loss.png
├── signed_strength_by_order.png
├── and_or_tree.png
├── salient_interaction.csv
└── sparsity.png
```

Start with:

- `inference.txt`: model input, output, and explanation target
- `salient_interaction.csv`: salient interactions and their strengths
- `signed_strength_by_order.png`: positive and negative strength by interaction order
- `and_or_tree.png`: all salient AND/OR interactions, capped at the 20 strongest

The dataset-level average interaction distribution is written to:

```text
runs/economics/aggregate/target_model/signed_strength_by_order.png
```

## Optional: Compare two models

Llama3-8B requires accepting Meta's model access terms on Hugging Face. After
access is granted, download it with:

```bash
python - <<'PY'
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="meta-llama/Meta-Llama-3-8B",
    revision="8cde5ca8380496c9a6cc7ef3a8b46a0372a1d920",
    local_dir="models/Meta-Llama-3-8B",
)
PY
```

Then add `--reference-model`:

```bash
sitkit \
  --model ./models/Qwen3-8B \
  --reference-model ./models/Meta-Llama-3-8B \
  --input-json examples/datasets/economics.json \
  --output-dir runs/comparison
```

Two-model mode also writes a `reference_model/` report.

## Optional: Use the Jupyter Notebook

```bash
python -m pip install jupyterlab ipykernel
jupyter lab examples/notebooks/sitkit_quickstart.ipynb
```

## Troubleshooting

### `sitkit: command not found`

Activate the correct Conda environment:

```bash
conda activate sitkit
sitkit --version
```

### Model validation failed

Use the exact Qwen3-8B base-model revision listed above. Instruct, LoRA,
fine-tuned, converted, or resaved weights are not supported.

### Not enough GPU memory

Stop other GPU workloads or use a machine with more GPU memory. Check current
usage with:

```bash
nvidia-smi
```

## License

SITKit is available under the
[PolyForm Strict License 1.0.0](LICENSE.md). Noncommercial academic,
educational, and personal research use is permitted. Modification,
redistribution, and commercial use require separate written permission from the
copyright holder.

This is a source-available, noncommercial release. It is not OSI-approved open
source software.
