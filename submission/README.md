# The ranked entry

This is the configuration behind our 5.366× result.

| File | What it does |
| --- | --- |
| `config.sh` | sourced by the entrypoint at start; this is what actually takes effect |
| `combined.jinja` | chat template; lets one image serve thinking and no-thinking |
| `entrypoint.sh` | sources `config.sh`, then launches the server |
| `Dockerfile` | layers them onto the base image, pinned by digest |
| `Dockerfile.vllm` | builds vLLM 0.20.1 with the dtype patch, for sm_86 |

```bash
export SPECULATIVE_CONFIG='{"method":"dflash","model":"/opt/ml/dflash-model","num_speculative_tokens":15}'
export MAX_MODEL_LEN=13312   MAX_NUM_SEQS=8   GPU_MEMORY_UTILIZATION=0.90
export MAX_CHAT_TOKENS=2048  CHAT_TEMPLATE=/opt/program/combined.jinja
export MCQ_FORMAT_GUARD=1    MCQ_POSTPROCESS=1
```

## Why the chat template matters

Qwen3.5-4B formats a multiple-choice answer differently with thinking on and off. With it
off the model tended to write `Answer: X`, which the MMLU-Pro harness does not match.

`combined.jinja` makes the think block conditional on `enable_thinking`, so one image
serves the no-thinking benchmarks and still reasons normally on GPQA-Diamond, with no
second template and no second backend. In our local runs it moved MMLU-Pro from about
0.43 to about 0.68.

## Building it

The base image is public and carries both sets of weights:

```bash
docker build -t adaptfm-rank6 .
docker run --rm --gpus all -p 8080:8080 adaptfm-rank6 serve
curl -f localhost:8080/ping
```

## Why DFlash and not something faster

Suffix decoding was four times quicker and could not finish the quality evaluation, which
sends eight GPQA-Diamond questions at once with a 60-second limit on each. Only two ran
concurrently; the rest timed out. Full account in
[../docs/submission-history.md](../docs/submission-history.md).
