# Open questions

Not results. Nothing below has been measured well enough to claim; we are writing them
down because the competition pointed at them.

Qwen3.5-4B is a hybrid: most layers are Gated DeltaNet, a linear-attention recurrence with
a fixed-size running state, the rest full attention. That architecture is becoming common
and most tooling around it still assumes a transformer.

**Recurrent state under low precision.** Fitting the model into 24 GB, the recurrent state
seemed far less bothered by lost precision than the KV cache. A KV cache stores every past
token and reads it all back, so quantization error accumulates and nothing removes it. A
gated recurrence multiplies its state by a forget gate below one each step, shrinking
whatever is already there, including earlier error. If that holds, the state should
tolerate coarser quantization than the cache, and the gap should widen with context. The
obvious failure mode is a forget gate near one, where there is little shrinking to do.

**What sets usable context.** A transformer can attend to any earlier token directly; a
recurrent layer cannot. What it can still use from far back should depend on how fast its
state decays and how much that state holds, rather than the length it was trained at —
which suggests usable context might be predictable from published config values across
model families.

**Exploring several continuations at once.** The chunked scans behind linear attention are
associative, unlike attention over a growing KV cache. That might let several independent
continuations advance in one memory-bound kernel, which would matter for tree speculation
and constrained decoding. Cheap to test: measure whether a chunked scan at batch B×K costs
meaningfully less than K scans at batch B. If it scales linearly there is nothing here.

**Getting the artifact to start.** Serving benchmarks measure latency on the assumption
that the server comes up. Here that assumption decided the ranking. A useful pre-ship
check would exercise cold start, memory pressure and mismatched kernel builds against the
artifact you are about to upload, not the image you built it from.

If you are working on any of these, or think one is already answered, please open an
issue.
