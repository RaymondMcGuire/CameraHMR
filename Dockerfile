# syntax=docker/dockerfile:1.7

ARG CUDA_IMAGE=nvidia/cuda:12.8.0-devel-ubuntu22.04
ARG UV_IMAGE=ghcr.io/astral-sh/uv:0.11.23

FROM ${UV_IMAGE} AS uv
FROM ${CUDA_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG TORCH_CUDA_ARCH_LIST="12.0"

ENV FORCE_CUDA=1 \
    PYOPENGL_PLATFORM=egl \
    PYTHONUNBUFFERED=1 \
    TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST} \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/camerahmr/.venv \
    PATH="/opt/camerahmr/.venv/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    ffmpeg \
    git \
    libegl1 \
    libgl1 \
    libgles2 \
    libglib2.0-0 \
    libglvnd0 \
    libjpeg-dev \
    libosmesa6 \
    libsm6 \
    libxext6 \
    libxrender1 \
    ninja-build \
    pkg-config \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/

WORKDIR /workspace/CameraHMR

COPY pyproject.toml ReadMe.md ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --python /usr/bin/python3.10 --extra cu128 --extra demo --no-install-project

COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --python /usr/bin/python3.10 --extra cu128 --extra demo

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --python /opt/camerahmr/.venv/bin/python --no-build-isolation \
    "detectron2 @ git+https://github.com/facebookresearch/detectron2.git"

CMD ["uv", "run", "--no-sync", "python", "demo.py", "--image_folder", "demo_images", "--output_folder", "output_images"]
