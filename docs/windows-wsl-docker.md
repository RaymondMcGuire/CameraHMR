# Windows download, WSL Docker run

This path is for demo/inference only. It does not download training datasets.

## 1. Download demo data on Windows

Open `cmd.exe` or PowerShell in the repository directory and run:

```bat
scripts\fetch_demo_data_windows.bat D:\camerahmr-data
```

If you double-click `scripts\fetch_demo_data_windows.bat` without arguments, it
downloads to the repository-level `data` directory, not `scripts\data`.
The window pauses before closing so you can read any curl or authentication
errors.

To save a log file, run it from `cmd.exe`:

```bat
scripts\fetch_demo_data_windows.bat D:\camerahmr-data > fetch_demo_data.log 2>&1
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

## 3. Build the Docker image in WSL

The data is not copied into the image. The build only creates the environment.

```bash
docker build -t camerahmr:demo-cu118 .
```

If Detectron2 fails because your GPU architecture is not in the default list,
build with a narrower architecture list, for example:

```bash
docker build --build-arg TORCH_CUDA_ARCH_LIST="8.6" -t camerahmr:demo-cu118 .
```

## 4. Run the SMPL demo

Create an output directory on the Windows side through WSL:

```bash
mkdir -p /mnt/d/SMPL-project/CameraHMR/output_images
```

Run the container and mount your Windows data directory into the path expected
by the code:

```bash
docker run --rm -it --gpus all \
  -v /mnt/d/camerahmr-data:/workspace/CameraHMR/data:ro \
  -v /mnt/d/SMPL-project/CameraHMR/output_images:/workspace/CameraHMR/output_images \
  camerahmr:demo-cu118
```

The default container command is equivalent to:

```bash
uv run --no-sync python demo.py --image_folder demo_images --output_folder output_images
```

## 5. Run with your own images

If your images are in `D:\my-images`, mount that folder too:

```bash
docker run --rm -it --gpus all \
  -v /mnt/d/camerahmr-data:/workspace/CameraHMR/data:ro \
  -v /mnt/d/my-images:/input_images:ro \
  -v /mnt/d/SMPL-project/CameraHMR/output_images:/workspace/CameraHMR/output_images \
  camerahmr:demo-cu118 \
  uv run --no-sync python demo.py --image_folder /input_images --output_folder output_images
```

For SMPL-X, use:

```bash
docker run --rm -it --gpus all \
  -v /mnt/d/camerahmr-data:/workspace/CameraHMR/data:ro \
  -v /mnt/d/SMPL-project/CameraHMR/output_images_smplx:/workspace/CameraHMR/output_images_smplx \
  camerahmr:demo-cu118 \
  uv run --no-sync python demo.py --image_folder demo_images --output_folder output_images_smplx --model_type smplx
```

## GPU check

Before building or running the demo, this should work inside WSL:

```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

If it does not, enable Docker Desktop WSL integration and install/update the
NVIDIA Windows driver with WSL GPU support.
