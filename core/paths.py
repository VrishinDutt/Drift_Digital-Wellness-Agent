from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"


def project_path(*parts):
    return PROJECT_ROOT.joinpath(*parts)


def data_path(filename):
    return DATA_DIR / filename
