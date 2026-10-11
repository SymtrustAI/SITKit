<div align="center">

# SITKit

**Surrogate Interaction Theory Toolkit**

One model or two · One sentence · One reproducible interaction report<br>
单模型或双模型 · 一句话 · 一份可复现的交互报告

<p>
  <img alt="Python 3.10+" src="https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white">
  <img alt="Models" src="https://img.shields.io/badge/Models-Qwen3--8B%20%7C%20Llama3--8B-2563EB">
  <img alt="Local runtime" src="https://img.shields.io/badge/Runtime-Local-16A34A">
</p>

[快速开始](#快速开始) · [Python API](#python-api) · [Jupyter Notebook](examples/notebooks/sitkit_quickstart.ipynb) · [English](#english)

</div>

---

## 简介

SITKit 是面向学术研究的模型交互分析工具。输入一个本地语言模型和一句文本，
即可提取 AND/OR Harsanyi 交互；也可以添加一个可选的对标模型进行联合分析。

- 支持单模型分析与可选的双模型对比
- 支持 **Qwen3-8B** 与 **Llama3-8B** 的指定基础模型快照
- 默认分析 10 个交互元，最多支持 12 个
- 模型、输入与结果始终保留在本地
- 自动匹配并校验随包提供的 baseline
- 按样本输出推理摘要、显著交互 CSV 与可视化报告

> SITKit 仅接受受支持的原始基础模型。微调模型、LoRA/PEFT 模型、修改后的权重及
> 其他模型规模不会通过模型校验。

## 快速开始

### 1. 安装

下载与你的操作系统和 Python 版本匹配的 wheel，然后安装：

```bash
python -m pip install ./sitkit-*.whl
sitkit --version
```

### 2. 准备模型

模型路径应指向完整的本地 Hugging Face 快照：

```text
/models/Qwen3-8B/
├── config.json
├── tokenizer.json
├── tokenizer_config.json
├── model-00001-of-00005.safetensors
└── model.safetensors.index.json
```

不同机器上的模型路径可以不同。SITKit 不校验机器名称或绝对路径，只校验模型的
配置、分词器和权重文件内容。请从官方仓库下载当前 SITKit 发行页列出的固定
**commit revision**，不要直接使用可能继续变化的 `main` 分支。

| 支持模型 | Hugging Face 官方仓库 |
|---|---|
| Qwen3-8B | [`Qwen/Qwen3-8B`](https://huggingface.co/Qwen/Qwen3-8B) |
| Llama3-8B | [`meta-llama/Meta-Llama-3-8B`](https://huggingface.co/meta-llama/Meta-Llama-3-8B) |

```python
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="Qwen/Qwen3-8B",
    revision="<当前 SITKit 发行页标注的 commit hash>",
    local_dir="/models/Qwen3-8B",
)
```

Llama3-8B 采用同样的下载方式，但需要先在 Hugging Face 接受 Meta 的访问条款。
只要仓库、revision 和下载后的文件完全一致，即使换一台机器或更换本地目录，
模型指纹也保持一致并可使用相应 baseline。重新保存、转换格式或重新切分权重会
改变文件指纹，无法匹配官方 baseline。

### 3. 运行分析

分析前可以只校验 JSON，不加载模型：

```bash
sitkit --input-json examples/datasets/economics.json --check-only
```

校验通过后运行单模型分析：

```bash
sitkit \
  --model /models/Qwen3-8B \
  --input-json examples/datasets/economics.json \
  --output-dir runs/quickstart
```

SITKit 会自动检查模型并选择对应 baseline，无需额外配置 baseline 路径。

如需与另一个模型对比，增加可选参数：

```bash
sitkit \
  --model /models/Qwen3-8B \
  --reference-model /models/Meta-Llama-3-8B \
  --input-json examples/datasets/economics.json \
  --output-dir runs/comparison
```

## 输出

```text
runs/quickstart/
└── economics-0001/
    └── report/
        └── target_model/
            ├── inference.txt
            ├── optimization_loss.png
            ├── signed_strength_by_order.png
            ├── and_or_tree.png
            ├── salient_interaction.csv
            └── sparsity.png
```

这些报告文件在每次成功运行后都会生成。使用 `--reference-model` 时，结果中会
额外生成 `reference_model/` 及同样的一组报告。
每个模型目录中的 `inference.txt` 汇总模型输入、该模型的下一 Token argmax、
本次解释目标及其 logit。`interaction_sum` 等于遮挡全部交互元时的模型输出
`v(∅)` 加上所有显著 AND/OR 交互的有符号加和。
批量运行结束后，还会生成数据集级平均分布：

```text
<output-dir>/aggregate/target_model/signed_strength_by_order.png
```

双模型模式会同时生成 `aggregate/reference_model/` 下的平均分布。每个阶数的柱高
是所有已完成样本对应 `signed_strength_by_order.png` 柱高的算术平均值。

当批量输入包含 **5 个以上样本**时，SITKit 会先为每个模型计算数据集尺度
`mean(|v(N)-v(∅)|)`，并将所有样本的 `threshold` 和 `q_bound` 统一设为
`0.04 × mean(|v(N)-v(∅)|)`。5 个及以下样本使用
`0.05 × |I_max|`。实际规则、数据集均值和每个模型的最终数值均写入结果，便于复核。

## Python API

```python
import json
from sitkit import SurrogateInteractionExplainer

samples = json.load(open("examples/datasets/economics.json"))
sample = samples[0]

explainer = SurrogateInteractionExplainer(
    "/models/Qwen3-8B",
    max_players=10,
    batch_size=16,
    device="auto",
)

result = explainer.explain(
    sample["text"],
    players=sample["players"],
    sample_id="economics-0001",
    target_text=sample.get("target_text"),
    top_k=5,
    output_dir="runs/python-api",
)

print(result.to_dict()["models"]["target_model"]["positive_top"])
```

将对标模型作为第二个参数传入即可进行双模型对比：

```python
explainer = SurrogateInteractionExplainer(
    "/models/Qwen3-8B",
    reference_model="/models/Meta-Llama-3-8B",
)
```

## 常用选项

| 参数 | 默认值 | 说明 |
|---|---:|---|
| `--input-json` | — | 单样本 JSON，或由样本对象组成的 JSON 数组 |
| `--input-dir` | — | 批量输入目录；支持单样本与数据集 JSON |
| `--check-only` | 关闭 | 仅检查 JSON、交互元顺序和重叠，不加载模型 |
| `--reference-model` | — | 可选对标模型；未设置时执行单模型分析 |
| `--max-players` | `10` | 交互元数量，范围为 1–12 |
| `--batch-size` | `16` | 模型前向计算批大小 |
| `--top-k` | `5` | 输出的正向与负向交互数量 |
| `--reward-type` | `gt` | 可选 `gt` 或 `gt-log-odds` |
| `--device` | `auto` | 自动使用可用 GPU，也可指定 `cpu` 或 `cuda:N` |

交互元数量为 `N` 时，需要计算 `2^N` 个遮挡状态。建议先使用默认的 10 个交互元。

单样本只需要句子和按原文顺序排列的交互元；数据集直接将多个样本放进一个
JSON 数组：

```json
[
  {
    "text": "Revenue growth slowed.",
    "players": [
      {"text": "Revenue"},
      {"text": "growth"},
      {"text": "slowed"}
    ]
  }
]
```

SITKit 根据文件名和数组顺序自动生成样本 ID，并默认解释评测模型的下一 Token
argmax 输出。用户只需要填写各交互元的 `text`；SITKit 会从左到右匹配并自动
生成字符位置。`--check-only` 会显示解析结果，找不到、乱序或重叠时不会开始实验。

运行整个目录：

```bash
sitkit \
  --model /models/Qwen3-8B \
  --input-dir samples \
  --output-dir runs/batch
```

仓库提供 6 个单文件示范数据集：经济学、医学、法律、计算机科学、环境科学和
医学证据推理。每个 JSON 包含 20 个样本，每个样本只保留 `text` 与 10 个
`players`。详见
[`examples/datasets/`](examples/datasets/README.md)。

## Notebook

安装 Notebook 环境并打开完整示例：

```bash
python -m pip install jupyterlab ipykernel
jupyter lab examples/notebooks/sitkit_quickstart.ipynb
```

---

<a id="english"></a>

<details>
<summary><strong>English</strong></summary>

## Overview

SITKit is a model interaction analysis toolkit for academic research. Given one
local language model and one sentence, it extracts AND/OR Harsanyi interactions.
An optional reference model enables aligned two-model comparison.

- Supports single-model analysis and optional two-model comparison
- Supports approved base-model snapshots of **Qwen3-8B** and **Llama3-8B**
- Uses 10 interaction players by default, with a maximum of 12
- Keeps models, inputs, and outputs in the local environment
- Selects and verifies the bundled baseline automatically
- Writes per-sample inference summaries, salient-interaction CSVs, and figures

> Fine-tuned checkpoints, LoRA/PEFT models, modified weights, and unsupported
> model sizes do not pass model admission.

## Quick start

### 1. Install

Download the wheel matching your operating system and Python version:

```bash
python -m pip install ./sitkit-*.whl
sitkit --version
```

### 2. Download the model

The local path may differ across machines. SITKit does not include the machine
name or absolute path in model admission; it verifies the contents of the model
configuration, tokenizer, and weight files. Download the exact **commit
revision** listed on the current SITKit release page instead of a moving `main`
branch.

| Supported model | Official Hugging Face repository |
|---|---|
| Qwen3-8B | [`Qwen/Qwen3-8B`](https://huggingface.co/Qwen/Qwen3-8B) |
| Llama3-8B | [`meta-llama/Meta-Llama-3-8B`](https://huggingface.co/meta-llama/Meta-Llama-3-8B) |

```python
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="Qwen/Qwen3-8B",
    revision="<commit hash listed on the current SITKit release page>",
    local_dir="/models/Qwen3-8B",
)
```

Meta's access terms must be accepted on Hugging Face before downloading
Llama3-8B. An identical repository revision and identical files produce the
same model fingerprint on another machine. Re-saving, converting, or
re-sharding the weights changes that fingerprint and will not match the bundled
baseline.

### 3. Run

```bash
sitkit --input-json examples/datasets/economics.json --check-only

sitkit \
  --model /models/Qwen3-8B \
  --input-json examples/datasets/economics.json \
  --output-dir runs/quickstart
```

No baseline path is required. To compare against a second model, add:

```bash
--reference-model /models/Meta-Llama-3-8B
```

## Python API

```python
import json
from sitkit import SurrogateInteractionExplainer

samples = json.load(open("examples/datasets/economics.json"))
sample = samples[0]

explainer = SurrogateInteractionExplainer(
    "/models/Qwen3-8B",
    max_players=10,
    batch_size=16,
    device="auto",
)

result = explainer.explain(
    sample["text"],
    players=sample["players"],
    sample_id="economics-0001",
    target_text=sample.get("target_text"),
    top_k=5,
    output_dir="runs/python-api",
)

print(result.to_dict()["models"]["target_model"]["positive_top"])
```

Pass `reference_model="/models/Meta-Llama-3-8B"` to enable two-model
comparison.

Every successful run writes the following files under
`<output-dir>/<sample-id>/report/target_model/`: `inference.txt`,
`optimization_loss.png`,
`signed_strength_by_order.png`, `and_or_tree.png`,
`salient_interaction.csv`, and `sparsity.png`. Comparison runs write the same
set under `report/reference_model/`.
Each model's `inference.txt` records the input, next-token argmax output,
and explanation target and logit. Its `interaction_sum` is the all-players-
masked model output `v(empty)` plus the signed sum of all salient AND/OR
interactions.
After a batch run completes, SITKit averages the sample-level bars at each
interaction order and writes
`<output-dir>/aggregate/target_model/signed_strength_by_order.png`. Comparison
runs also write the reference-model average under `aggregate/reference_model/`.

For a batch containing **more than 5 samples**, SITKit first computes the
model-specific dataset scale `mean(|v(N)-v(empty)|)`. Both `threshold` and
`q_bound` are then fixed to `0.04 * mean(|v(N)-v(empty)|)` for every sample.
Batches of 5 samples or fewer use `0.05 * |I_max|`. The selected rule, dataset
means, and final per-model values are recorded in the output for verification.

## Common options

| Option | Default | Description |
|---|---:|---|
| `--input-json` | — | One sample JSON or a JSON array of sample objects |
| `--input-dir` | — | Batch directory containing sample or dataset JSON files |
| `--check-only` | off | Validate JSON, player order, and overlap without loading a model |
| `--reference-model` | — | Optional reference model; omit for single-model analysis |
| `--max-players` | `10` | Number of interaction players, from 1 to 12 |
| `--batch-size` | `16` | Forward-pass batch size |
| `--top-k` | `5` | Positive and negative interactions to return |
| `--reward-type` | `gt` | `gt` or `gt-log-odds` |
| `--device` | `auto` | Automatic GPU selection, `cpu`, or `cuda:N` |

For `N` players, SITKit evaluates `2^N` masked states. Start with the default
10 players before increasing the analysis scale.

A sample only needs its text and ordered players. A dataset places multiple
sample objects directly in one JSON array:

```json
[
  {
    "text": "Revenue growth slowed.",
    "players": [
      {"text": "Revenue"},
      {"text": "growth"},
      {"text": "slowed"}
    ]
  }
]
```

SITKit derives sample IDs from the filename and array order and explains the
target model's next-token argmax output by default. Users only provide each
player's `text` in source order. SITKit resolves character ranges from left to
right, and `--check-only` rejects missing, out-of-order, or overlapping players.
Run the complete directory with:

```bash
sitkit \
  --model /models/Qwen3-8B \
  --input-dir samples \
  --output-dir runs/batch
```

Six ready-to-run single-file demonstration datasets are included: Economics,
Medicine, Law, Computer Science, Environmental Science, and medical evidence
inference. Each JSON contains 20 samples, and every sample contains only `text`
and exactly 10 `players`. See
[`examples/datasets/`](examples/datasets/README.md).

## Notebook

```bash
python -m pip install jupyterlab ipykernel
jupyter lab examples/notebooks/sitkit_quickstart.ipynb
```

</details>
