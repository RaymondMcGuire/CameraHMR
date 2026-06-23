# Windows download, WSL Docker run

This path is for demo/inference only. It does not download training datasets.
Demo/inference is enough to run CameraHMR on your own images. You only need the
pretrained checkpoints, the detector checkpoint, and SMPL/SMPL-X model files.

## 1. Download demo data on Windows

Open `cmd.exe` or PowerShell in the repository directory and run:

```bat
scripts\fetch_demo_data_windows.bat D:\camerahmr-data
```

If you double-click `scripts\fetch_demo_data_windows.bat` without arguments, it
opens an interactive prompt for the data directory, `smpl`/`smplx` mode, and
whether to force re-download existing files. Press Enter at the data directory
prompt to use the repository-level `data` directory, not `scripts\data`.
The window pauses before closing so you can read any download or authentication
errors. The `.bat` file only changes to the repository root, calls
`scripts\fetch_demo_data_windows.ps1`, and pauses; the PowerShell script handles
the actual POST downloads, skip checks, file-size validation, and SMPL-X zip
extraction.

To save a log file, run it from `cmd.exe`:

```bat
scripts\fetch_demo_data_windows.bat D:\camerahmr-data > fetch_demo_data.log 2>&1
```

To replace previously downloaded files, add `-Force` after the mode:

```bat
scripts\fetch_demo_data_windows.bat D:\camerahmr-data smpl -Force
```

That downloads the SMPL demo files into:

```text
D:\camerahmr-data
├── models\SMPL\SMPL_NEUTRAL.pkl
├── pretrained-models\cam_model_cleaned.ckpt
├── pretrained-models\camerahmr_checkpoint_cleaned.ckpt
├── pretrained-models\model_final_f05665.pkl
└── smpl_mean_params.npz
```

The script prints each downloaded file size. If a checkpoint/model file is only
a few KB, it is almost certainly an authentication, license, or server error
page rather than the real file.

For the SMPL-X / BEDLAM2 demo, add `smplx`:

```bat
scripts\fetch_demo_data_windows.bat D:\camerahmr-data smplx
```

This will also ask for BEDLAM2 and SMPL-X credentials.

## 2. Use the Windows data directory from WSL

WSL normally exposes Windows drives under `/mnt`. For example:

```text
D:\camerahmr-data -> /mnt/d/camerahmr-data
D:\SMPL-project\CameraHMR -> /mnt/d/SMPL-project/CameraHMR
```

Open WSL and move to the repository:

```bash
cd /mnt/d/SMPL-project/CameraHMR
```

## 3. Configure Docker Compose in WSL

The data is not copied into the image. It is mounted at run time.

Create a local `.env` from the example:

```bash
cp .env.example .env
```

If you downloaded data to `D:\camerahmr-data`, edit `.env` to:

```env
CAMERAHMR_DATA_DIR=/mnt/d/camerahmr-data
CAMERAHMR_INPUT_DIR=./demo_images
CAMERAHMR_OUTPUT_DIR=./output_images
CAMERAHMR_MODEL_TYPE=smpl
```

If you downloaded data into this repository's `data` folder, the default
`CAMERAHMR_DATA_DIR=./data` is enough.

## 4. Build the Docker image in WSL

The default Compose image targets CUDA 12.8 / PyTorch cu128 for RTX 5090 and
other RTX 50-series GPUs.

Use Compose:

```bash
docker compose build
```

If Detectron2 fails because your GPU architecture is not in the default list,
set a narrower architecture list in `.env`, for example:

```env
TORCH_CUDA_ARCH_LIST=12.0
```

For many RTX 30-series cards, use `TORCH_CUDA_ARCH_LIST=8.6` instead.

Then rebuild:

```bash
docker compose build
```

After the image has been built once, normal Python/source-code edits do not need
another build. Compose live-mounts the repository into the container, while the
uv environment stays inside the image at `/opt/camerahmr/.venv`. Rebuild only
after changing dependency or image files such as `Dockerfile`, `compose.yaml`
build args, `pyproject.toml`, CUDA/PyTorch versions, apt packages, or
Detectron2 build settings.

## 5. Run the SMPL demo

Create an output directory on the host side through WSL. Compose usually creates
missing bind-mount directories, but creating it explicitly makes the path and
permissions obvious:

```bash
mkdir -p /mnt/d/SMPL-project/CameraHMR/output_images
```

Run the container:

```bash
docker compose run --rm camerahmr
```

To validate the mounted demo data before running the full demo:

```bash
docker compose run --rm camerahmr uv run --no-sync python scripts/check_demo_data.py --data-dir data
```

The Compose command is equivalent to:

```bash
uv run --no-sync python demo.py --image_folder /input_images --output_folder output_images
```

## 6. Run with your own images

If your images are in `D:\my-images`, edit `.env`:

```env
CAMERAHMR_INPUT_DIR=/mnt/d/my-images
CAMERAHMR_OUTPUT_DIR=./output_images
CAMERAHMR_MODEL_TYPE=smpl
```

Then run:

```bash
docker compose run --rm camerahmr
```

For SMPL-X, edit `.env`:

```env
CAMERAHMR_OUTPUT_DIR=./output_images_smplx
CAMERAHMR_MODEL_TYPE=smplx
```

Then run:

```bash
mkdir -p output_images_smplx
docker compose run --rm camerahmr
```

## GPU check

Before building or running the demo, this optional check should work inside WSL:

```bash
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

This does not build the CameraHMR image. Docker pulls NVIDIA's official CUDA
12.8 test image and runs `nvidia-smi` inside it. It only checks that Docker
Desktop, WSL, and the NVIDIA driver can pass the GPU into containers.

If it does not, enable Docker Desktop WSL integration and install/update the
NVIDIA Windows driver with WSL GPU support.
