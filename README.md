# DFlash K=15 for Qwen3.5-4B

This is the open-source writeup for team **AFM-qd39x2e6**, which finished
**sixth** in the AdaptFM Efficient Qwen Challenge at ICML 2026.

Our submitted system served Qwen3.5-4B on one NVIDIA A10G. It reached a
**5.366× mean speedup** and passed all three quality checks.

The main change was simple: we moved from suffix decoding with `K=128` to a
trained DFlash drafter with `K=15`.

## Result

The numbers below come from the
[official final results](https://adaptfm.gitlab.io/competition-results/).

| Prompt | Baseline | Our latency | Approx. speedup |
| --- | ---: | ---: | ---: |
| 64 tokens | 2,582 ms | **345 ms** | 7.48× |
| 2,048 tokens | 5,441 ms | **881 ms** | 6.18× |
| 8,192 tokens | 6,576 ms | **2,684 ms** | 2.45× |
| Mean | — | — | **5.366× official** |

The published latencies are rounded. That is why calculating the mean from
the table gives roughly 5.37× instead of exactly 5.366×.

| Quality check | Required | Our score |
| --- | ---: | ---: |
| MMLU-Pro | 0.621 | **0.661** |
| IFEval | 0.814 | **0.845** |
| GPQA-Diamond | 0.630 | **0.667** |

## What we submitted

The recovered configuration points to this stack:

- Qwen3.5-4B AWQ target from `QuantTrio/Qwen3.5-4B-AWQ`
- AWQ-Marlin for the target model
- public `z-lab/Qwen3.5-4B-DFlash` draft model
- DFlash speculative decoding with a fixed `K=15`
- vLLM 0.20.1 built inside the competition CUDA environment
- a small dtype compatibility patch for the DFlash projection
- a single model-serving process on one A10G
- target and draft weights included in the Docker image for offline evaluation

We did not train a new target model or drafter. Most of our work went into
choosing a fast combination and getting the quantized target, DFlash draft,
vLLM, CUDA, and API behavior to work together reliably.

## Why K=15 worked better than suffix K=128

Suffix decoding can copy long spans that already appear in the prompt. It is
cheap and can work very well on repetitive input. Our earlier configuration
allowed it to propose as many as 128 tokens.

But a large maximum window is not the same as a large accepted window. The
later tokens are more likely to be rejected, and the extra draft and
verification work still has a cost.

DFlash uses target-model features to predict a block of future tokens. It can
keep making useful proposals after generation moves beyond text copied from
the prompt. A moderate `K=15` gave us a better trade-off:

- enough proposed tokens to reduce target decode steps;
- less wasted work when a proposal diverged;
- better behavior on newly generated text;
- a smaller and more predictable verification block.

This was also visible across the final leaderboard. Most of the leading
DFlash entries used K values between 12 and 18.

## Runtime patch

Our vLLM source build included one narrow compatibility fix. Before the
DFlash fully connected projection, we convert the target hidden state to the
projection weight's dtype:

```python
fc_weight = getattr(self.model.fc, "weight", None)
fc_dtype = getattr(fc_weight, "dtype", None)
if fc_dtype is not None and hidden_states.dtype != fc_dtype:
    hidden_states = hidden_states.to(fc_dtype)
result = self.model.fc(hidden_states)
```

This avoids a mixed-dtype matrix multiplication when the AWQ target and the
draft model meet. It does not change the target model's verification rule.
The complete patch is in
[`patches/patch_qwen3_dflash_dtype.py`](patches/patch_qwen3_dflash_dtype.py).

## Recovered configuration

The archived K=15 scripts contain these model revisions:

| Component | Repository | Revision |
| --- | --- | --- |
| Target | `QuantTrio/Qwen3.5-4B-AWQ` | `32c292e3a73afe1138518180b1b6d2868c980ee2` |
| Drafter | `z-lab/Qwen3.5-4B-DFlash` | `96899cc270945f554998309580b08a04a05a3187` |

They also use:

```json
{
  "method": "dflash",
  "model": "/opt/ml/dflash-draft",
  "num_speculative_tokens": 15
}
```

The recovered environment is saved in
[`configs/recovered-dflash-k15.env`](configs/recovered-dflash-k15.env).

## What is still missing

This repository was prepared from the HPC archive. Noel has the original
submission workspace on his MacBook and will add the exact final files.

Until that happens, we are deliberately not claiming that the reference
Dockerfile is byte-for-byte identical to the submitted image.

We still need to add:

- the final Dockerfile and serving script;
- the exact vLLM commit;
- the final environment-variable dump;
- the submission ID tied to the rank-6 result;
- the Docker image ID and archive SHA-256;
- raw A10G latency output;
- raw quality summaries;
- team member names and affiliations.

The full handoff list is in
[`NOEL_HANDOFF.md`](NOEL_HANDOFF.md).

## Repository contents

```text
.
├── README.md
├── NOEL_HANDOFF.md
├── LICENSE
├── DEPENDENCIES.md
├── configs/
│   └── recovered-dflash-k15.env
├── patches/
│   └── patch_qwen3_dflash_dtype.py
├── reference/
│   ├── Dockerfile.vllm-dflash
│   └── Dockerfile.submission
└── results/
    └── official-results.json
```

The two Dockerfiles under `reference/` are reconstructed from the HPC archive.
They are useful for understanding and rebuilding the stack, but they should
be replaced if Noel's final files differ.

## Rebuilding the reference image

The reference build expects both Hugging Face snapshots to be available
locally. Model weights are not stored in Git.

First build the DFlash-capable vLLM image:

```bash
docker build \
  --build-arg VLLM_GIT_REF=v0.20.1 \
  --build-arg TORCH_CUDA_ARCH_LIST=8.6 \
  -f reference/Dockerfile.vllm-dflash \
  -t adaptfm-vllm:dflash-v0201 .
```

Then prepare a build context containing:

```text
submission_context/
├── qwen-weights/
└── dflash-draft/
```

and build the submission image:

```bash
docker build \
  --build-arg BASE_IMAGE=adaptfm-vllm:dflash-v0201 \
  -f reference/Dockerfile.submission \
  -t adaptfm-rank6:dflash-k15 .
```

The reference Dockerfile expects `serve_vllm_contest.py` and `entrypoint.sh`
from the final submission workspace. They are not included yet because the
HPC copy contains later experimental changes that we do not want to
misrepresent as the submitted code.

## Lessons from the competition

The biggest lesson was that pushing K higher was not automatically faster.
The accepted prefix matters more than the advertised draft length.

We also learned to keep the final serving path small. Several more complicated
ideas were interesting in local tests, but every extra runtime component added
startup risk, memory pressure, or another compatibility problem.

Finally, image tags are not evidence. Some of our old tags were reused for
different configurations. The final release will identify everything by
commit, model revision, image digest, and checksum.

## Acknowledgements

Thanks to the AdaptFM organizers and the Amazon Edge AI team for running the
challenge. We also thank the teams behind
[Qwen3.5](https://huggingface.co/Qwen/Qwen3.5-4B),
[DFlash](https://github.com/z-lab/dflash),
[vLLM](https://github.com/vllm-project/vllm),
[AWQ](https://github.com/mit-han-lab/llm-awq), and
[Marlin](https://github.com/IST-DASLab/marlin).
