# Submission history

Our ranked entry was not our fastest one. Suffix speculation gave us around 20× and we
never found a legal way to make it pass the quality gate.

| Entry | Method | Speedup | Outcome |
| --- | --- | ---: | --- |
| `00636e1e` | dual backend | ~20.2× | passed quality, #2 overall, removed |
| `e5f87a3a` | suffix, single backend | 20.982× | failed quality |
| ranked entry | DFlash `K=15` | **5.366×** | sixth place |

The entry that won recorded 7.745×.

## What actually blocked us

Speculative decoding on this model corrupts the Gated DeltaNet recurrent state when
drafts are rejected. There is no correct rollback for linear-attention state, so
generation runs away: fluent, long, and wrong. Under load a suffix run would go to about
165 seconds where a no-speculation run took 34.

That mattered because of how quality is evaluated. Eight GPQA-Diamond questions are sent
at once, thinking enabled, up to 12,288 output tokens each, and every one has to return
inside 60 seconds. Anything slower renders as `-` on the leaderboard. At 12,288 tokens the
engine reserves around 803 KV blocks per sequence and admits about three of the eight. At
4,096 all eight are admitted and the timing passes, but 4,096 tokens is not enough room
for the model to reason its way to a correct answer, so quality falls over instead.

Fast, correct, and eight at once: we could get any two.

## What we tried

The corruption traces to an open vLLM bug ([#39273](https://github.com/vllm-project/vllm/issues/39273),
[#35288](https://github.com/vllm-project/vllm/issues/35288)). We patched the empty-draft
path in the Gated DeltaNet attention layer, which brought a runaway case from 331 seconds
down to 175. Our own note at the time: *"the GDN fix helped but didn't finish the job."*
Then acceptance gates, token-probability sweeps, and the two upstream patches, each
measured and each insufficient. The conclusion we wrote that day was *"everything that
could fix it, we tried — and it's an unsolved upstream bug."*

Then we sidestepped it. Submission `00636e1e` served the two evaluations from different
backends: suffix speculation on `/v1/completions`, and a second backend with speculation
off for `/v1/chat/completions`. It passed quality at GPQA-Diamond 0.646 and reached **#2
overall, first among entries that passed quality**, at about 20.2×.

The organizers removed it and announced a ban on routing different models to the quality
and latency evaluations. That is what we had built, and the rule is right.

## What never reached the leaderboard

Five later submissions failed at container startup and were never scored: `868b176d`,
`34e2dab6`, `3ec261d7`, `51d9a533`, `c1749458`. They did not answer the `/ping` health
check in time.

The cause was packaging. We had been flattening images with
`docker export | docker import --change ENTRYPOINT` to fit the 20 GB limit, and a
flattened image does not handle `docker run <image> serve` the way the original entrypoint
does.

Our fastest configurations are not on the leaderboard at all. Once the entries with
routing or startup failures came off, what remained for us was the one that booted and
passed: DFlash `K=15`, 5.366×, sixth.
