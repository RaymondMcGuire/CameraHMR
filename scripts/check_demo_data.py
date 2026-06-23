import argparse
import pickle
from pathlib import Path


REQUIRED_FILES = [
    ("models/SMPL/SMPL_NEUTRAL.pkl", 1_000_000),
    ("pretrained-models/cam_model_cleaned.ckpt", 1_000_000),
    ("pretrained-models/camerahmr_checkpoint_cleaned.ckpt", 10_000_000),
    ("pretrained-models/model_final_f05665.pkl", 10_000_000),
    ("smpl_mean_params.npz", 1_000),
]


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate CameraHMR demo data files.")
    parser.add_argument("--data-dir", default="data", help="CameraHMR data directory")
    parser.add_argument(
        "--skip-pickle-load",
        action="store_true",
        help="Only check file presence and size; do not unpickle detector checkpoint.",
    )
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    ok = True

    for rel_path, min_bytes in REQUIRED_FILES:
        path = data_dir / rel_path
        if not path.exists():
            print(f"[missing] {path}")
            ok = False
            continue
        size = path.stat().st_size
        print(f"[file] {path} ({size:,} bytes)")
        if size < min_bytes:
            print(f"[error] {path} is smaller than expected minimum {min_bytes:,} bytes")
            ok = False

    detector_path = data_dir / "pretrained-models" / "model_final_f05665.pkl"
    if ok and not args.skip_pickle_load:
        print(f"[check] Loading pickle header/data: {detector_path}")
        try:
            with detector_path.open("rb") as handle:
                pickle.load(handle, encoding="latin1")
        except Exception as exc:
            print(f"[error] Failed to unpickle {detector_path}: {exc}")
            ok = False
        else:
            print("[ok] Detectron2 checkpoint pickle loaded successfully.")

    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
