# DFlash K=15 for Qwen3.5-4B on a single A10G

Team `AFM-qd39x2e6`, sixth place in the
[Efficient LLM Challenge](https://adaptfm.gitlab.io/competition-results/), AdaptFM
workshop at ICML 2026. Around 176 teams entered and 41 landed a valid submission.

**5.366× mean speedup, all three quality gates passed.**

| Prompt | Baseline | Ours | | Gate | Required | Ours |
| --- | ---: | ---: | --- | --- | ---: | ---: |
| 64 tokens | 2,582 ms | 345 ms | | MMLU-Pro | 0.621 | 0.661 |
| 2,048 tokens | 5,441 ms | 881 ms | | IFEval | 0.814 | 0.845 |
| 8,192 tokens | 6,576 ms | 2,684 ms | | GPQA-Diamond | 0.630 | 0.667 |

A 4-bit AWQ Qwen3.5-4B target, the public `z-lab/Qwen3.5-4B-DFlash` drafter at a fixed
`K=15`, and vLLM 0.20.1 with one dtype patch. No new training.

**The configuration that ranked is in [`submission/`](submission).**

## Start here

| | |
| --- | --- |
| [submission/](submission) | the three files behind the 5.366× result |
| [docs/method.md](docs/method.md) | why `K=15`, the dtype patch, how to rebuild |
| [docs/submission-history.md](docs/submission-history.md) | our fastest entry hit 20.982× and scored nothing |
| [docs/what-we-tried.md](docs/what-we-tried.md) | every configuration we built, and what wasted our time |
| [docs/future-work.md](docs/future-work.md) | what we are working on next |

## The short version

Speculative decoding on this model corrupts the recurrent state when drafts are rejected,
so generation runs away and blows the 60-second per-sample limit on the quality
evaluation. Our fastest entries were fast and wrong. One that passed, by serving the two
evaluations from separate backends, reached #2 overall and was removed as benchmark
routing. Five later submissions never started at all.

The entry that ranked is the slow one that booted. That is most of what we learned.

Judging by the organizers' writeup, the winning entry used the same recipe we ended on, a
4-bit target with DFlash at `K=15`. The gap between sixth and first looks like
quantization detail and per-step serving overhead rather than the choice of algorithm.

## Reproducing

Most of the images we built are public on
[Docker Hub](https://hub.docker.com/r/11noel11/adaptfm-submission/tags), and
[what-we-tried.md](docs/what-we-tried.md) shows how to read any one's configuration
without downloading it.

```bash
docker pull 11noel11/adaptfm-submission:dflash-k15
```

That build is DFlash `K=15` from before the chat-template change. The configuration that
ranked is in [`submission/`](submission).

Latency and quality figures here are the official results.

## Dependencies

No model weights are stored here. Qwen3.5-4B, the AWQ quantization and the DFlash drafter
each carry their own terms — see [DEPENDENCIES.md](DEPENDENCIES.md). Licensed under
[MIT](LICENSE). Contributions welcome, see [CONTRIBUTING.md](CONTRIBUTING.md).

Thanks to the AdaptFM organizers and the Amazon Edge AI team, and to the teams behind
[Qwen3.5](https://huggingface.co/Qwen/Qwen3.5-4B),
[DFlash](https://github.com/z-lab/dflash), [vLLM](https://github.com/vllm-project/vllm),
[AWQ](https://github.com/mit-han-lab/llm-awq) and
[Marlin](https://github.com/IST-DASLab/marlin).

## Citation

Praveen A. Shukla and Noel Thomas, Mohamed bin Zayed University of Artificial
Intelligence.

```bibtex
@misc{shukla2026adaptfm,
  author = {Shukla, Praveen A. and Thomas, Noel},
  title  = {{DFlash K=15 for Qwen3.5-4B on a single A10G}},
  year   = {2026},
  note   = {Sixth place, Efficient LLM Challenge, AdaptFM Workshop, ICML 2026},
  url    = {https://github.com/PraveenAShukla/adaptfm}
}
```
