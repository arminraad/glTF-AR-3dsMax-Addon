# Installation

This guide covers download, installation, update, startup behavior, removal, and troubleshooting for **AR glTF Material Forge**.

## Requirements

- Autodesk 3ds Max 2027
- Python / PySide6 environment supplied with 3ds Max
- V-Ray only for operations that inspect V-Ray material classes
- Permission to write to the normal 3ds Max user script folders

## Download the MZP

The current installer is stored directly in the repository:

```text
dist/AR_glTF_Material_Forge_1_3_0.mzp
```

A freshly built copy is also produced by the **Build MZP** workflow in GitHub Actions.

## Install or update from MZP

### Method A — Run Script

1. Open 3ds Max.
2. Go to **Scripting -> Run Script**.
3. Select `AR_glTF_Material_Forge_1_3_0.mzp`.
4. The installer/updater window opens before any files are changed.

### Method B — Drag and drop

Drag the MZP file from Windows Explorer into the 3ds Max viewport.

The same installer/updater window opens.

### Installer state

The package detects the current user installation automatically.

- If no installation is found, the primary button is **Install**.
- If an existing installation is found, the primary button is **Update**.
- When possible, the installer also shows the currently installed version.
- Version 1.3.0 writes an explicit `version.txt` marker for reliable future detection.

No installed files are modified until you press **Install** or **Update**.

## What the installer adds

The package installs its working files below the current 3ds Max user scripts directory:

```text
<User Scripts>\AR_glTF_Material_Forge\
```

It also installs:

- a MacroScript in the user macros directory;
- a startup MAXScript in the user startup scripts directory;
- the application icon in the user icons directory;
- a persistent Qt toolbar in 3ds Max.

The exact directories are resolved at runtime using 3ds Max system-directory APIs, so the installer does not rely on a hard-coded Windows username.

## Files installed

Main application:

```text
AR_glTF_Material_Forge/
├─ ar_gltf_material_forge.py
├─ open_panel.py
├─ startup.py
├─ icons/
└─ scripts/
```

Integration files:

```text
<User Macros>\AR_glTF_Material_Forge.mcr
<User Startup Scripts>\AR_glTF_Material_Forge_startup.ms
<User Icons>\AR_glTF_Material_Forge.svg
```

## Opening the panel

After installation, use the **AR glTF Material Forge** toolbar button.

The panel can be closed normally and reopened from that button.

## Startup behavior

At 3ds Max startup:

1. the startup MAXScript loads `startup.py`;
2. the Python module registers or restores the toolbar;
3. the panel itself remains closed until you click the toolbar button.

## Updating

To update:

1. download the newer MZP;
2. run it in 3ds Max or drag it into the viewport;
3. confirm that the installer detects the existing version;
4. press **Update**.

During update, the add-on payload is replaced as a complete unit. The application module is then reloaded and the existing toolbar QAction is explicitly disconnected from the old in-memory callback and rebound to the newly loaded version.

This fixes the case where installing a new MZP opened the new panel once, but the persistent toolbar button continued to launch the old panel.

A 3ds Max restart is normally not required.

## Build locally

To rebuild the package from repository source:

```bash
python tools/build_mzp.py
```

Output:

```text
dist/AR_glTF_Material_Forge_1_3_0.mzp
```

## Uninstall

Close 3ds Max, then remove these installed items:

```text
<User Scripts>\AR_glTF_Material_Forge\
<User Macros>\AR_glTF_Material_Forge.mcr
<User Startup Scripts>\AR_glTF_Material_Forge_startup.ms
<User Icons>\AR_glTF_Material_Forge.svg
```

After restarting 3ds Max, the add-on will no longer load.

If the custom toolbar remains in the UI configuration, remove that toolbar from the 3ds Max interface customization.

## Troubleshooting

### The panel does not open

Re-run the MZP installer and confirm that the installation-complete dialog appears.

Then verify that this folder exists:

```text
<User Scripts>\AR_glTF_Material_Forge\
```

### The toolbar is missing after restart

Check that this startup file exists:

```text
<User Startup Scripts>\AR_glTF_Material_Forge_startup.ms
```

Re-running the MZP restores it.

### A V-Ray conversion tool reports no matching materials

The tool only acts on the material classes it is designed for:

- the 2Sided tool searches for `VRay2SidedMtl`;
- the Blend tool searches for `VRayBlendMtl`.

If V-Ray is not loaded, V-Ray-specific classes may not be available.

### A cleanup operation changes more than expected

Use Undo immediately and inspect the material graph.

These tools are intended for deliberate material preparation. Always work on a saved copy of the scene.
