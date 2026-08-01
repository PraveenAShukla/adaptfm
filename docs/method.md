# Method

## What we served

- Qwen3.5-4B AWQ target, `QuantTrio/Qwen3.5-4B-AWQ` @ `32c292e3a73afe1138518180b1b6d2868c980ee2`, through AWQ-Marlin
- drafter `z-lab/Qwen3.5-4B-DFlash` @ `96899cc270945f554998309580b08a04a05a3187`
- DFlash speculative decoding at a fixed `K=15`
- vLLM `v0.20.1` (`132765e3560659ff63ebd236203672e991b70e08`) with the dtype patch below
- one serving process, both sets of weights baked in for offline evaluation

```json
{"method": "dflash", "model": "/opt/ml/dflash-model", "num_speculative_tokens": 15}
```

We trained nothing. The work was choosing a combination and getting the quantized target,
the DFlash draft, vLLM, CUDA and the API behaviour to hold together. Full environment in
[`submission/config.sh`](../submission/config.sh).

## Why K=15

Suffix decoding drafts by copying spans already in the context — cheap, and good on
repetitive input. Our configuration proposed 64 tokens a step over a tree 128 deep. (The
official results page calls this "suffix K=128", which is the tree depth, not the number
of proposed tokens.)

A large maximum window is not a large accepted window. Later tokens in a long draft are
likelier to be rejected, and drafting and verifying them still costs time. DFlash predicts
a block of future tokens from the target's own hidden states, so it keeps proposing
usefully once generation moves past text copied from the prompt. A moderate `K` cuts
target decode steps without much wasted work when a proposal diverges. The organizers
report `K` values across the field clustered between 12 and 23.

## The dtype patch

Before the DFlash fully connected projection, cast the target hidden state to the
projection weight's dtype:

```python
fc_weight = getattr(self.model.fc, "weight", None)
fc_dtype = getattr(fc_weight, "dtype", None)
if fc_dtype is not None and hidden_states.dtype != fc_dtype:
    hidden_states = hidden_states.to(fc_dtype)
result = self.model.fc(hidden_states)
```

This avoids a mixed-dtype matmul where the AWQ target and the draft model meet. It does
not change the verification rule, so under correct greedy verification it should not
change output; we did not test that token for token. Full patch in
[`patches/patch_qwen3_dflash_dtype.py`](../patches/patch_qwen3_dflash_dtype.py).

## Rebuilding

Weights are not in git; the build expects both Hugging Face snapshots locally.

```bash
docker build --build-arg VLLM_GIT_REF=v0.20.1 --build-arg TORCH_CUDA_ARCH_LIST=8.6 \
  -f submission/Dockerfile.vllm -t adaptfm-vllm:dflash-v0201 .
```

`TORCH_CUDA_ARCH_LIST=8.6` matters. The A10G is sm_86; a build carrying only sm_80 and
sm_89 loads, then fails at the first kernel launch with "no kernel image is available for
execution on the device". This cost us more time than any algorithmic decision.

Then, with `submission_context/qwen-weights/` and `submission_context/dflash-draft/` in
place:

```bash
docker build --build-arg BASE_IMAGE=adaptfm-vllm:dflash-v0201 \
  -f submission/Dockerfile -t adaptfm-rank6:dflash-k15 .
```

Before uploading, run the exact command the harness runs against the exact artifact you
are about to upload:

```bash
docker run --rm --gpus all -p 8080:8080 adaptfm-rank6:dflash-k15 serve
curl -f localhost:8080/ping
```

Five of our submissions never scored because we skipped this. See
[submission-history.md](submission-history.md).
