# Handoff for Noel

Please replace the reconstructed files with the exact rank-6 submission files
from your MacBook.

## Highest priority

- [ ] Add the final `Dockerfile`.
- [ ] Add the final `serve_vllm_contest.py` or equivalent server.
- [ ] Add the final entrypoint.
- [ ] Confirm that the submitted speculative setting was DFlash `K=15`.
- [ ] Confirm the target and draft model revisions in the README.
- [ ] Record the exact vLLM commit.
- [ ] Record every runtime environment variable.

## Artifact identity

- [ ] Add the competition submission ID.
- [ ] Add the submitted image ID.
- [ ] Add the submitted `image.tar.gz` SHA-256.
- [ ] Add the competition base-image digest.
- [ ] Add the final Git commit used to build the image.

Do not commit the 20 GB-class image archive to GitHub. A checksum and an
external download location are enough.

## Results

- [ ] Add the raw A10G latency JSON or log.
- [ ] Add the MMLU-Pro result.
- [ ] Add the IFEval result.
- [ ] Add the GPQA-Diamond result.
- [ ] Add the exact commands used for the final validation.

## Documentation

- [ ] Add team member names and affiliations.
- [ ] Correct any part of the optimization story that differs from the final
      MacBook workspace.
- [ ] Remove the “reconstructed” warning once the exact files are present.

## Safety check

Please review the final server before pushing it. Do not include:

- API keys or upload URLs;
- Hugging Face tokens;
- benchmark-specific answer logic;
- private cluster paths;
- model weights that cannot be redistributed;
- raw Docker credentials or shell history.

