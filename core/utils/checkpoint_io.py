import contextlib
import functools
import inspect

import torch


def _torch_load_accepts_weights_only():
    return "weights_only" in inspect.signature(torch.load).parameters


def torch_load_trusted(*args, **kwargs):
    """Load official project checkpoints across PyTorch 2.0 and 2.6+."""
    if _torch_load_accepts_weights_only():
        kwargs.setdefault("weights_only", False)
    return torch.load(*args, **kwargs)


@contextlib.contextmanager
def trusted_torch_load():
    """Temporarily let Lightning load trusted legacy checkpoints on PyTorch 2.6+."""
    if not _torch_load_accepts_weights_only():
        yield
        return

    original_load = torch.load

    @functools.wraps(original_load)
    def load_with_legacy_checkpoint_support(*args, **kwargs):
        kwargs.setdefault("weights_only", False)
        return original_load(*args, **kwargs)

    torch.load = load_with_legacy_checkpoint_support
    try:
        yield
    finally:
        torch.load = original_load
