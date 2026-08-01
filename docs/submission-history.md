# Submission history

Our ranked entry was not our fastest one. Suffix speculation gave us around 21× and we
never found a legal way to make it pass the quality gate.

| Entry | Method | Speedup | Outcome |
| --- | --- | ---: | --- |
| `e5f87a3a` | suffix, single backend | **20.982×** | failed quality on answer extraction |
| `00636e1e` | dual backend | ~20× | passed every gate, led the board, removed |
| ranked entry | DFlash `K=15` | **5.366×** | sixth place |

The entry that won recorded 7.745×.

## Two failures, in order

The first was ours and it was avoidable. We had switched the multiple-choice formatting
path off, worried it looked like benchmark-specific behaviour, and were returning a raw
stream that exposed the model's thinking text to the grader. GPQA-Diamond came back at
0.040 on a four-option benchmark where guessing scores 0.250. A score that far below
chance is an extraction problem, not a reasoning one. We fixed it.

The second is the one that decided the competition.

The quality evaluation sends **eight** GPQA-Diamond questions at once, thinking enabled,
up to 12,288 output tokens each, and every one has to return inside 60 seconds. Anything
slower renders as `-` on the leaderboard. With speculation on, our server only ever had
about **two** of the eight in flight. The rest queued, ran in waves, and the tail landed
around 112 seconds. With speculation off all eight fit and the timing passed, at 1.718×.

The setting that made single-stream decoding fast was the setting that stopped us
answering eight long questions at once. Everything after that was an attempt to have both.

## What we tried

We patched vLLM so requests with no proposed draft tokens would not reserve speculative
KV slots, on the theory that admission was reserving for a draft window chat requests
never used. It helped — worst case came down from 331 seconds to 175 — and it was not
enough. Runaways survived. We ran out of time before separating the remaining causes, so
we do not claim to know exactly why the limit sat where it did.

Then we sidestepped it. Submission `00636e1e` served the two evaluations from different
backends: suffix speculation on `/v1/completions`, and a second backend with speculation
off for `/v1/chat/completions`. It passed every gate, GPQA-Diamond at 0.646, and for a
short while it sat at the top of the leaderboard.

The organizers removed it. Choosing a backend per request is benchmark routing, the rules
ban it, and they were right to pull it.

What we submitted in the end runs every request through one backend and one speculative
setting, at roughly a quarter of the speed, and it finished the evaluation.

## What never reached the leaderboard

Several later submissions failed at container startup and were never scored. They did not
answer the `/ping` health check in time.

The cause was packaging. We had been flattening images with
`docker export | docker import --change ENTRYPOINT` to fit the 20 GB limit, and a
flattened image does not handle `docker run <image> serve` the way the original entrypoint
does.

This decided our result more than any algorithm did. Our fastest configurations are not on
the leaderboard at all. The entry that ranked is the one that booted.

## Order of events

1. `3010fb88` — n-gram drafting, roughly 3-5×, quality verified. Our fallback.
2. `e5f87a3a` — suffix, single backend. 20.982×, failed on extraction.
3. `00636e1e` — dual backend. Passed every gate, then removed as benchmark routing.
4. `8285f137` — suffix again, formatting restored. Still could not clear the timing.
5. The ranked DFlash `K=15` entry. 5.366×, sixth place.
6. Several attempts that failed to start.
