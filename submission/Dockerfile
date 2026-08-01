# The ranked entry: our suffix base image with the speculative config flipped to DFlash.
# The base already carries /opt/ml/model (AWQ target), /opt/ml/dflash-model (DFlash
# drafter) and the serving wrapper on port 8080.
#
# config.sh is sourced by the entrypoint and overrides the ENV values below. Where the
# two disagree, config.sh is what takes effect.
FROM 11noel11/adaptfm-submission@sha256:5fbbebdbc1c85de15d3e902c50e1121cc9e68053e1e399f32f228349fac14e4f

ENV MAX_NUM_SEQS=8
ENV MAX_MODEL_LEN=13312
ENV GPU_MEMORY_UTILIZATION=0.90
ENV MCQ_FORMAT_GUARD=1
ENV MCQ_POSTPROCESS=1
ENV PYTORCH_ALLOC_CONF=expandable_segments:True
ENV MAX_CHAT_TOKENS=2048
ENV CHAT_TEMPLATE=/opt/program/combined.jinja
ENV THINKING_REPETITION_PENALTY=1.15
ENV SPECULATIVE_CONFIG={\"method\":\"dflash\",\"model\":\"/opt/ml/dflash-model\",\"num_speculative_tokens\":15}

COPY config.sh /opt/program/config.sh
COPY combined.jinja /opt/program/combined.jinja
COPY entrypoint.sh /opt/program/entrypoint.sh
