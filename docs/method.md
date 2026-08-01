# Method

## What we served

- Qwen3.5-4B AWQ target from `QuantTrio/Qwen3.5-4B-AWQ`, through the AWQ-Marlin kernel
- the public `z-lab/Qwen3.5-4B-DFlash` drafter
- DFlash speculative decoding at a fixed `K=15`
- vLLM `v0.20.1` (`132765e3560659ff63ebd236203672e991b70e08`), built in the competition CUDA image
- one dtype compatibility patch, described below
- a single serving process, with both sets of weights baked into the image for offline
  evaluation

We did not train a target model or a drafter. Most of the work was choosing a
combination and getting the quantized target, the DFlash draft, vLLM, CUDA, and the
API behaviour to hold together.

| Component | Repository | Revision |
| --- | --- | --- |
| Target | `QuantTrio/Qwen3.5-4B-AWQ` | `32c292e3a73afe1138518180b1b6d2868c980ee2` |
| Drafter | `z-lab/Qwen3.5-4B-DFlash` | `96899cc270945f554998309580b08a04a05a3187` |

```json
{"method": "dflash", "model": "/opt/ml/dflash-model", "num_speculative_tokens": 15}
```

The full environment is in [`submission/config.sh`](../submission/config.sh).

## Why K=15 beat our suffix configuration

Suffix decoding drafts by copying spans that already appear in the context. It is cheap
and works well on repetitive input. Our earlier configuration proposed 64 tokens a step
over a suffix tree 128 deep. The official results page describes this as "suffix K=128",
which refers to the tree depth rather than the number of proposed tokens.

A large maximum window is not the same as a large accepted window. Later tokens in a
long draft are likelier to be rejected, and both the drafting and the verification of
those rejected tokens still cost time. DFlash predicts a block of future tokens from
the target's own hidden states, so it keeps proposing usefully once generation moves
past text copied from the prompt.

A moderate `K` gave a better trade: enough proposed tokens to cut target decode steps
without much wasted work when a proposal diverged, and a smaller verification block. The
organizers report that `K` values across the field clustered between 12 and 23.

## The dtype patch

Our vLLM build carries one narrow fix. Before the DFlash fully connected projection, we
cast the target hidden state to the projection weight's dtype:

```python
fc_weight = getattr(self.model.fc, "weight", None)
fc_dtype = getattr(fc_weight, "dtype", None)
if fc_dtype is not None and hidden_states.dtype != fc_dtype:
    hidden_states = hidden_states.to(fc_dtype)
result = self.model.fc(hidden_states)
```

This avoids a mixed-dtype matrix multiplication where the AWQ target and the draft model
meet. It does not change the target's verification rule, so under correct greedy
verification it should not change output. We did not test that token for token. The
full patch is in
[`patches/patch_qwen3_dflash_dtype.py`](../patches/patch_qwen3_dflash_dtype.py).

## Rebuilding

The build expects both Hugging Face snapshots locally. Weights are not stored in git.

First build the DFlash-capable vLLM image:

```bash
docker build \
  --build-arg VLLM_GIT_REF=v0.20.1 \
  --build-arg TORCH_CUDA_ARCH_LIST=8.6 \
  -f submission/Dockerfile.vllm \
  -t adaptfm-vllm:dflash-v0201 .
```

`TORCH_CUDA_ARCH_LIST=8.6` matters. The A10G is sm_86, and a build that only carries
sm_80 and sm_89 will load and then fail at the first kernel launch with "no kernel
image is available for execution on the device". This cost us more time than any
algorithmic decision.

Then prepare a build context holding the two snapshots:

```text
submission_context/
├── qwen-weights/
└── dflash-draft/
```

and build the submission image:

```bash
docker build \
  --build-arg BASE_IMAGE=adaptfm-vllm:dflash-v0201 \
  -f submission/Dockerfile \
  -t adaptfm-rank6:dflash-k15 .
```

Before uploading anything, run the exact command the evaluation harness runs, against
the exact artifact you are about to upload:

```bash
docker run --rm --gpus all -p 8080:8080 adaptfm-rank6:dflash-k15 serve
curl -f localhost:8080/ping
```

Four of our submissions never scored because we skipped this step. See
[submission-history.md](submission-history.md).
