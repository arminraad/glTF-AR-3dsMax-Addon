import importlib
import sys
from pathlib import Path

root = Path(__file__).resolve().parent
if str(root) not in sys.path:
    sys.path.insert(0, str(root))

import ar_gltf_material_forge
importlib.reload(ar_gltf_material_forge)
ar_gltf_material_forge.launch()
