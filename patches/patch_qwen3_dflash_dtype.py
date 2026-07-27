#!/usr/bin/env python3
"""Match DFlash hidden-state dtype to its fully connected projection."""

from pathlib import Path

import vllm


root = Path(vllm.__file__).resolve().parent
target = root / "model_executor" / "models" / "qwen3_dflash.py"
text = target.read_text(encoding="utf-8")

needle = "        result = self.model.fc(hidden_states)\n"
replacement = """        fc_weight = getattr(self.model.fc, "weight", None)
        fc_dtype = getattr(fc_weight, "dtype", None)
        if fc_dtype is None:
            try:
                fc_dtype = next(self.model.fc.parameters()).dtype
            except StopIteration:
                fc_dtype = None
        if fc_dtype is not None and hidden_states.dtype != fc_dtype:
            hidden_states = hidden_states.to(fc_dtype)
        result = self.model.fc(hidden_states)
"""

if replacement in text:
    print(f"patch already present: {target}")
elif needle in text:
    target.write_text(text.replace(needle, replacement, 1), encoding="utf-8")
    print(f"patched: {target}")
else:
    raise SystemExit(f"patch target not found: {target}")

