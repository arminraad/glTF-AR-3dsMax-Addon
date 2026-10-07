# AR glTF Material Forge

A compact material-preparation toolkit for **Autodesk 3ds Max** that cleans and simplifies V-Ray material graphs for architectural **glTF / AR** delivery.

The add-on installs as a persistent 3ds Max toolbar button and opens a fixed-size PySide6 panel containing focused material conversion, cleanup, and viewport tools.

> Current version: **v1.3.0**  
> Current target: **3ds Max 2027**  
> Primary workflow: **V-Ray scene materials -> simplified glTF-ready material graphs**

## What it does

AR glTF Material Forge groups the material cleanup steps used when preparing architectural models for real-time glTF / AR presentation.

### V-Ray wrapper conversion

- **Remove V-Ray 2Sided Wrapper**  
  Replaces a `VRay2SidedMtl` wrapper with its Front glTF material while preserving the parent Multi/Sub slot.

- **Remove V-Ray Blend Wrapper**  
  Replaces a `VRayBlendMtl` with its Base glTF material when the Base material is already a glTF material.

### Base Color simplification

- **Keep Base Color Branch Only**  
  Keeps the Base Color texture branch of every glTF material and disconnects the other texture-map branches.

- **Flatten Base Color to Bitmap**  
  Bypasses intermediate maps such as Mix and Color Correction and connects the selected source Bitmap directly to Base Color.

### Scene cleanup

- **Clean Orphan Slate Nodes**  
  Removes Slate nodes that do not belong to dependency graphs rooted in a glTF material or Multi/Sub-Object material.

- **Purge Unused Materials**  
  Removes material nodes that have no real scene usage while preserving materials assigned to scene objects and their sub-material trees.

### Finalization

- **Disable Extra glTF Extensions**  
  Turns off Sheen, Specular, Transmission, Volume, and IOR on all glTF materials.

- **Show Textures in Viewport**  
  Enables connected material textures for viewport display across scene materials and nested Multi/Sub materials.

## Safety model

Where applicable, the tools preserve:

- object material assignments;
- Multi/Sub-Object slot positions;
- Material IDs;
- UVs;
- existing glTF material nodes.

Some operations are intentionally destructive to intermediate material-map graphs. **Always save a copy of the .max scene before batch cleanup.**

## Download

The current installable package is committed directly in the repository:

```text
dist/AR_glTF_Material_Forge_1_3_0.mzp
```

You can also obtain a freshly built copy from the latest successful **Build MZP** workflow in GitHub Actions.

## Installation and updates

1. Download `dist/AR_glTF_Material_Forge_1_3_0.mzp`.
2. In 3ds Max, use **Scripting -> Run Script**, or drag the MZP directly into the viewport.
3. The package opens a dedicated installer/updater window before changing any files.
4. If the add-on is not installed, the primary action is **Install**.
5. If an existing installation is detected, the primary action is **Update** and the installed version is shown.
6. After Install/Update completes, the panel opens and the persistent toolbar button is rebound to the current code.

The update process replaces the installed payload as a complete unit, refreshes the MacroScript/startup integration, reloads the Python module, and reconnects the existing toolbar action so an old toolbar button cannot keep launching an older in-memory panel.

After restarting 3ds Max, the toolbar is restored automatically.

For detailed installation, update, uninstall, and troubleshooting instructions, see [docs/INSTALLATION.md](docs/INSTALLATION.md).

## Usage

1. Open the scene you want to prepare.
2. Save a backup copy.
3. Click the **AR glTF Material Forge** toolbar button.
4. Run the required tools individually.
5. Review the result in Slate Material Editor and the viewport.
6. Export the prepared scene to glTF / GLB using your preferred 3ds Max exporter.

Detailed behavior for every operation is documented in [docs/USAGE.md](docs/USAGE.md).

## Suggested workflow

For scenes already converted from V-Ray materials toward glTF materials:

1. Remove V-Ray 2Sided wrappers.
2. Remove eligible V-Ray Blend wrappers.
3. Keep Base Color branches only.
4. Flatten Base Color to Bitmap.
5. Clean orphan Slate nodes.
6. Purge unused materials.
7. Disable extra glTF extensions.
8. Show textures in viewport and inspect the result.

Not every scene requires every step.

## Build from source

To rebuild the MZP locally:

```bash
python tools/build_mzp.py
```

Output:

```text
dist/AR_glTF_Material_Forge_1_3_0.mzp
```

The repository also contains a GitHub Actions workflow that performs the same build automatically.

## Repository structure

```text
.
├─ README.md
├─ CHANGELOG.md
├─ dist/
│  └─ AR_glTF_Material_Forge_1_3_0.mzp
├─ docs/
│  ├─ INSTALLATION.md
│  └─ USAGE.md
├─ tools/
│  └─ build_mzp.py
├─ .github/
│  └─ workflows/
│     └─ build.yml
└─ src/
   ├─ install.ms
   ├─ mzp.run
   └─ payload/
      ├─ ar_gltf_material_forge.py
      ├─ open_panel.py
      ├─ startup.py
      ├─ AR_glTF_Material_Forge.mcr
      ├─ AR_glTF_Material_Forge_startup.ms
      ├─ icons/
      └─ scripts/
```

## UI

The panel is implemented with PySide6 and is:

- fixed-size;
- high-contrast;
- icon-driven;
- persistent through a 3ds Max toolbar button;
- optimized for repeated architectural material cleanup.

## Updating

Install a newer MZP over the existing version. The installer replaces its own installed files and recreates the panel from the updated code.

## Uninstalling

See [docs/INSTALLATION.md](docs/INSTALLATION.md#uninstall).

## Versioning

Current package: **1.3.0**

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Notes

- V-Ray wrapper removal is intentionally conservative.
- A complex V-Ray Blend material does not have a lossless one-to-one representation as a single glTF material.
- The Base Color flattening tool follows the primary content/color path and treats control inputs such as masks as secondary.
- Review converted materials before final export.
