<p align="center">
  <a href="README.md">English</a> · <strong>简体中文</strong>
</p>

<div align="center">

# SITKit

**Surrogate Interaction Theory Toolkit**

使用一个本地语言模型和一份 JSON 数据，生成模型交互分析报告。

</div>

## 开始之前

当前版本适用于：

- Linux x86_64
- Conda
- Python 3.11
- Qwen3-8B 或 Llama3-8B 基础模型
- 推荐使用 NVIDIA GPU；仅使用 CPU 会非常慢

下面以 **Qwen3-8B 单模型分析**为例。命令按顺序执行即可。

## 第一步：创建 Conda 环境

```bash
conda create -n sitkit python=3.11 -y
conda activate sitkit
python --version
```

最后一条命令应显示 `Python 3.11.x`。

## 第二步：进入下载好的目录

将本仓库和 `sitkit-0.1.0-*.whl` 下载到同一个目录，然后进入该目录：

```bash
cd SITKit
ls
```

应当能看到：

```text
README.md
README.zh-CN.md
examples/
requirements.txt
sitkit-0.1.0-cp311-cp311-linux_x86_64.whl
```

## 第三步：安装 SITKit

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m pip install --no-deps ./sitkit-0.1.0-*.whl
sitkit --version
```

成功后应显示：

```text
SITKit 0.1.0
```

## 第四步：下载 Qwen3-8B

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

请不要修改、转换或重新保存下载后的模型文件。SITKit 会校验模型内容，并自动匹配
随 wheel 提供的 baseline。

<details>
<summary><strong>如何构造自己的样本</strong></summary>

### 输入文本（`text`）

- 建议包含 **10–20 个英文单词**。
- 不要出现重复或冗余的词组。
- 文本应当自然、语义明确且有实际含义。

### 交互元（`players`）

- 方法上建议标注 **8–15 个交互元**。当前公开版为控制计算量，最多支持 12 个，
  因此实际请使用 **8–12 个**。
- 每个交互元可以是一个词或连续短语，不需要覆盖文本中的所有词。
- 必须按照它们在原文中出现的顺序填写。
- 不要把纯标点作为交互元。
- 尽量不要选择 `and`、`to`、`the` 等语义较弱的词。
- 交互元之间不能重叠，并且都必须能在输入文本中找到。

### 解释目标（`target_text`，可选）

- 如果提供，建议选择有明确语义的实词，例如名词、动词或形容词。
- 如果模型对该词的预测置信度很低，交互结果的稳定性和可解释性也会受到影响。
- 如果省略，SITKit 会自动解释目标模型预测概率最高的下一个 Token。

一个最小数据集是由样本对象组成的 JSON 数组：

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

保存后先运行：

```bash
sitkit --input-json your-dataset.json --check-only
```

确认交互元的顺序、位置和重叠检查均通过，再开始正式分析。

</details>

## 第五步：检查示例数据

第一次运行建议先检查 JSON，不加载模型：

```bash
sitkit \
  --input-json examples/datasets/economics.json \
  --check-only
```

看到下面的信息说明数据有效：

```text
"status": "valid"
"sample_count": 20
```

如果希望一次完成数据检查和分析，也可以直接运行简化版 CLI 示例：

```bash
bash examples/cli/quickstart.sh
```

脚本顶部只有模型、数据和输出三个路径可配置。

## 第六步：运行分析

```bash
sitkit \
  --model ./models/Qwen3-8B \
  --input-json examples/datasets/economics.json \
  --output-dir runs/economics
```

程序会依次处理 20 个样本。首次加载 8B 模型需要一些时间，请等待终端显示进度。

## 第七步：查看结果

第一个样本的报告位于：

```text
runs/economics/economics-0001/report/target_model/
├── inference.txt
├── optimization_loss.png
├── signed_strength_by_order.png
├── and_or_tree.png
├── salient_interaction.csv
└── sparsity.png
```

建议先打开：

- `inference.txt`：模型输入、输出和解释目标
- `salient_interaction.csv`：显著交互及其强度
- `signed_strength_by_order.png`：不同阶数的正负交互分布
- `and_or_tree.png`：AND/OR 交互结构图

整个数据集的平均交互分布位于：

```text
runs/economics/aggregate/target_model/signed_strength_by_order.png
```

## 可选：比较两个模型

Llama3-8B 需要先在 Hugging Face 接受 Meta 的模型访问条款。接受后下载：

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

然后增加 `--reference-model`：

```bash
sitkit \
  --model ./models/Qwen3-8B \
  --reference-model ./models/Meta-Llama-3-8B \
  --input-json examples/datasets/economics.json \
  --output-dir runs/comparison
```

双模型模式会额外生成 `reference_model/` 报告。

## 可选：使用 Jupyter Notebook

```bash
python -m pip install jupyterlab ipykernel
jupyter lab examples/notebooks/sitkit_quickstart.ipynb
```

## 常见问题

### `sitkit: command not found`

确认已进入正确的 Conda 环境：

```bash
conda activate sitkit
sitkit --version
```

### 模型校验失败

请确认使用的是上面指定 revision 的原始 Qwen3-8B 基础模型，而不是 Instruct、
LoRA、微调模型或转换后的权重。

### GPU 显存不足

关闭占用 GPU 的其他程序，或在显存更大的机器上运行。可以使用：

```bash
nvidia-smi
```

查看当前显存占用。
