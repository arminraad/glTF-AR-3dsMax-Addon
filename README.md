# AR glTF Material Forge

A compact material-preparation toolkit for **Autodesk 3ds Max** that cleans and simplifies V-Ray material graphs for architectural **glTF / AR** delivery.

The add-on installs as a persistent 3ds Max toolbar button and opens a fixed-size PySide6 panel containing focused material conversion, cleanup, and viewport tools.

> Current version: **v1.2.0**  
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

The conversion tools are designed around the architectural Multi/Sub workflow used by this project.

Where applicable, they preserve:

- object material assignments;
- Multi/Sub-Object slot positions;
- Material IDs;
- UVs;
- existing glTF material nodes.

Some operations are intentionally destructive to intermediate material-map graphs. **Always save a copy of the .max scene before batch cleanup.**

## Installation

### Recommended: install the MZP package

Download:

`dist/AR_glTF_Material_Forge_1_2_0.mzp`

Then use either method:

1. In 3ds Max, open **Scripting -> Run Script** and select the MZP file.
2. Or drag the MZP file directly into the 3ds Max viewport.

The installer:

- copies the add-on to the current user's 3ds Max scripts directory;
- registers the MacroScript;
- installs the startup loader;
- creates a persistent toolbar with the AR glTF Material Forge icon;
- opens the panel immediately.

After restarting 3ds Max, the toolbar is loaded again automatically.

For detailed installation and troubleshooting, see [docs/INSTALLATION.md](docs/INSTALLATION.md).

## Usage

1. Open the scene you want to prepare.
2. Save a backup copy.
3. Click the **AR glTF Material Forge** toolbar button.
4. Run the required tools individually.
5. Review the result in Slate Material Editor and the viewport.
6. Export your final glTF / GLB using your preferred 3ds Max export workflow.

A recommended operation order and detailed behavior for every tool are documented in [docs/USAGE.md](docs/USAGE.md).

## Suggested workflow

For scenes already converted from V-Ray materials toward glTF materials, a typical cleanup sequence is:

1. Remove V-Ray 2Sided wrappers.
2. Remove eligible V-Ray Blend wrappers.
3. Keep Base Color branches only.
4. Flatten Base Color to Bitmap.
5. Clean orphan Slate nodes.
6. Purge unused materials.
7. Disable extra glTF extensions.
8. Show textures in viewport and inspect the result.

Not every scene requires every step.

## Repository structure

```text
.
├─ README.md
├─ CHANGELOG.md
├─ docs/
│  ├─ INSTALLATION.md
│  └─ USAGE.md
├─ dist/
│  └─ AR_glTF_Material_Forge_1_2_0.mzp
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

The panel is implemented with PySide6 and is intentionally:

- fixed-size;
- high-contrast;
- icon-driven;
- persistent through a 3ds Max toolbar button;
- optimized for repeated architectural material cleanup.

## Updating

Install a newer MZP over the existing version. The installer replaces the add-on files in the user scripts directory and reloads the panel.

## Uninstalling

See [docs/INSTALLATION.md](docs/INSTALLATION.md#uninstall).

## Versioning

Current package: **1.2.0**

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Notes

- V-Ray wrapper removal is intentionally conservative.
- A complex V-Ray Blend material does not have a lossless one-to-one representation as a single glTF material.
- The Base Color flattening tool follows the primary content/color path and treats control inputs such as masks as secondary.
- Review converted materials before final export.
