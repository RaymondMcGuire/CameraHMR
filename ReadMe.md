
<div align="center">

# **CameraHMR: Aligning People with Perspective (3DV 2025)**  

[**Priyanka Patel**](https://pixelite1201.github.io/) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; [**Michael J. Black**](https://ps.is.mpg.de/person/black)

---

🌐 [**Project Page**](https://camerahmr.is.tue.mpg.de) | 📄 [**ArXiv Paper**](https://arxiv.org/abs/2411.08128) | 🎥 [**Video Results**](https://youtu.be/aDmfAxYLV2w)

--- 

###  **Looking for SMPL-X / BEDLAM2 instructions?** See our [BEDLAM2 documentation](docs/bedlam2.md). 

---
![](teaser/teaser.png)  
*Figure: CameraHMR Results*

</div>

---


## 🚀 **Release**
- **CameraHMR Demo Code**
- **CameraHMR Training and Evaluation Code**
- **DenseKP Code**
- **CamSMPLify Code**  
- **BEDLAM2 Training and Demo Code**


## **Installation**
The project is now described by `pyproject.toml` and can be recreated with
[uv](https://docs.astral.sh/uv/). The default research environment follows the
original release: Python 3.10, PyTorch 2.0.0, torchvision 0.15.1, torchaudio
2.0.1, and CUDA 11.8.

```
uv sync --extra cu118 --extra demo
```

The image demos also need Detectron2. Install it after `uv sync` so it can
build against the already-installed PyTorch:

```bash
uv pip install --python .venv/bin/python --no-build-isolation "detectron2 @ git+https://github.com/facebookresearch/detectron2.git"
```

After this manual Detectron2 step, run commands with `uv run --no-sync ...`.
Windows users should use the interpreter path shown in
[docs/environment.md](docs/environment.md).

For Docker:

```bash
docker build -t camerahmr:demo-cu118 .
```

See [docs/environment.md](docs/environment.md) for CPU setup, data mounts, and
container run examples. Windows + WSL users can follow
[docs/windows-wsl-docker.md](docs/windows-wsl-docker.md). `requirements.txt` is
kept as a legacy reference, but uv is the preferred path.

## 🎬 **Demo**

###  **Download Required Files**

Download necessary demo files using:

```bash
bash fetch_demo_data.sh
```

Alternatively, download files manually from the [CameraHMR website](https://camerahmr.is.tue.mpg.de). Ensure to update paths in [`constants.py`](core/constants.py) if doing so manually.


Run the demo with following command. It will run demo on all images in the specified --image_folder, and save renderings of the reconstructions and the output mesh in --out_folder. 

```
python demo.py --image_folder demo_images --output_folder output_images
```

##  **4DHumans Labels with full perspective camera**

You can download the training data; fitted SMPL parameters for **INSTA/AIC/COCO/MPII images** from the [CameraHMR website](https://camerahmr.is.tue.mpg.de/index.html) (registration required).

Alternatively, use the following script:

```bash
bash scripts/fetch_4dhumans_training_labels.sh
```

> **Note:** We cannot provide the original AIC/INSTA images. These images must be obtained from their original sources. For convenience, you can use the [4D-Humans repository](https://github.com/shubham-goel/4D-Humans?tab=readme-ov-file), which offers these images in WebDataset format. To extract images from the WebDataset, refer to [this script](core/utils/extract_images_from4dhumans.py).


To overlay the fitted SMPL mesh on your images, use the following command:

```bash
python dataset_vis.py --image_folder path_to_img_folder --output_folder path_for_output_file --npz_path path_to_npz_file
```
path_to_img_folder corresponds to path of download INSTA/AIC images. path_to_npz_file corresponds to downloaded SMPL params.


## Training and Evaluation 
Please check out the [document](docs/training.md) for Training and Evaluation detail instructions. 

## 🙌 **Acknowledgements**

This project leverages outstanding resources from:

- [ 4D-Humans](https://github.com/shubham-goel/4D-Humans?tab=readme-ov-file)  
- [ BEDLAM](https://bedlam.is.tue.mpg.de/)  
- [ SMPLify](https://smplify.is.tue.mpg.de/)  
- [ ViTPose](https://github.com/ViTAE-Transformer/ViTPose)  
- [ Detectron2](https://github.com/facebookresearch/detectron2)


## 📚 **Citation**

If you find **CameraHMR** useful in your work, please cite:

```bibtex
@inproceedings{patel2024camerahmr,
title={{CameraHMR}: Aligning People with Perspective},
author={Patel, Priyanka and Black, Michael J.},
booktitle={International Conference on 3D Vision (3DV)},
year={2025} }
```


<div align="center">

✨ **Thank you for your interest in CameraHMR!** ✨

</div>

