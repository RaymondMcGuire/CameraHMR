# CameraHMR uv and Docker environment

This repository now uses `pyproject.toml` as the primary environment definition.
The Docker/Compose path defaults to Python 3.10, PyTorch 2.7.1, torchvision
0.22.1, torchaudio 2.7.1, and CUDA 12.8 so RTX 50-series GPUs can run the
demo. The original release stack, PyTorch 2.0.0 with CUDA 11.8, is still
available as the `cu118` extra for older GPUs.

## Local uv setup

Install the CUDA 12.8 demo environment used by the Docker image:

```bash
uv sync --extra cu128 --extra demo
```

For the original CUDA 11.8 stack, use `uv sync --extra cu118 --extra demo`.

The image demos use Detectron2 for person detection. Install it after `uv sync`
so the source build sees the PyTorch version in the project environment:

```bash
# Linux/macOS
uv pip install --python .venv/bin/python --no-build-isolation "detectron2 @ git+https://github.com/facebookresearch/detectron2.git"

# Windows PowerShell
uv pip install --python .venv\Scripts\python.exe --no-build-isolation "detectron2 @ git+https://github.com/facebookresearch/detectron2.git"
```

For a CPU-only environment:

```bash
uv sync --extra cpu --extra demo
```

For training/data-conversion/CamSMPLify extras, add `--extra train`,
`--extra data`, and `--extra optimize` as needed.

Detectron2 needs a working compiler toolchain. On Linux with CUDA, install the
CUDA toolkit and set `FORCE_CUDA=1` if Detectron2 should build CUDA ops without
a visible GPU during the build.

Run commands through uv:

```bash
uv run --no-sync python demo.py --image_folder demo_images --output_folder output_images
uv run --no-sync python train.py data=train experiment=camerahmr exp_name=train_run1
uv run --no-sync python eval.py data=eval experiment=camerahmr
```

## Data location

By default the code reads from `./data`, matching the upstream scripts. To keep
large or private assets outside the repository, set:

```bash
export CAMERAHMR_DATA_DIR=/path/to/camerahmr-data
```

The same directory structure is expected under that data root, for example
`pretrained-models/`, `models/SMPL/`, `training-images/`, and `test-labels/`.

## Docker

Build the CUDA 12.8 image:

```bash
docker compose build
```

The Dockerfile runs `uv sync` first and then installs Detectron2 with
`uv pip install --no-build-isolation`, which avoids making every uv lock/sync
depend on Detectron2's Git repository.

Run the demo with GPU access and mounted data:

```bash
docker compose run --rm camerahmr
```

Compose mounts the repository into `/workspace/CameraHMR` at run time. After the
image has been built once, Python/source changes are picked up by the next
`docker compose run` without rebuilding. Rebuild only after changing
`Dockerfile`, `compose.yaml` build args, `pyproject.toml`, uv dependency
extras, CUDA/PyTorch versions, apt packages, or Detectron2 build settings.

If your GPU needs a different Detectron2 CUDA architecture list, override it at
build time. The default is `12.0` for RTX 5090 / `sm_120`.

```bash
TORCH_CUDA_ARCH_LIST=8.6 docker compose build
```

The Compose build installs the environment only. Running the demo, training, or
evaluation still requires the registered/downloaded CameraHMR, SMPL/SMPL-X, and
dataset files described in the main README.
