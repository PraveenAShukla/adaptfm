# The ranked entry

The configuration behind our 5.366× result.

| File | What it does |
| --- | --- |
| `config.sh` | sourced by the entrypoint at start; this is what takes effect |
| `combined.jinja` | chat template; lets one image serve thinking and no-thinking |
| `entrypoint.sh` | sources `config.sh`, then launches the server |
| `Dockerfile` | layers them onto the base image, pinned by digest |
| `Dockerfile.vllm` | builds vLLM 0.20.1 with the dtype patch, for sm_86 |

```bash
export SPECULATIVE_CONFIG='{"method":"dflash","model":"/opt/ml/dflash-model","num_speculative_tokens":15}'
export MAX_MODEL_LEN=13312   MAX_NUM_SEQS=8   GPU_MEMORY_UTILIZATION=0.90
export MAX_CHAT_TOKENS=2048  CHAT_TEMPLATE=/opt/program/combined.jinja
```

## The chat template

Qwen3.5-4B formats a multiple-choice answer differently with thinking on and off; with it
off the model tended to write `Answer: X`, which the MMLU-Pro harness does not match.
`combined.jinja` makes the think block conditional on `enable_thinking`, so one image
serves the no-thinking benchmarks and still reasons on GPQA-Diamond, with no second
template and no second backend. In our local runs it moved MMLU-Pro from about 0.43 to
about 0.68.

## Building

```bash
docker build -t adaptfm-rank6 .
docker run --rm --gpus all -p 8080:8080 adaptfm-rank6 serve
curl -f localhost:8080/ping
```

`entrypoint.sh` and the serving wrapper come from the base image. We did not keep the
built artifact, so these files are the recipe rather than a copy of it.
