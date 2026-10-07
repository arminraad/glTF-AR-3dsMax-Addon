# Installation

This guide covers package creation, installation, update, startup behavior, and removal of **AR glTF Material Forge**.

## Requirements

- Autodesk 3ds Max 2027
- Python / PySide6 environment supplied with 3ds Max
- V-Ray is required only for operations that inspect V-Ray material classes
- Windows user account with permission to write to the normal 3ds Max user script folders

## Get the MZP package

The repository tracks the complete MZP source.

### Download from GitHub Actions

1. Open the repository **Actions** tab.
2. Open the latest successful **Build MZP** workflow run.
3. Download the artifact named `AR-glTF-Material-Forge-v1.2.0`.
4. Extract the artifact ZIP.
5. Use `AR_glTF_Material_Forge_1_2_0.mzp`.

### Build locally

Clone the repository and run:

```bash
python tools/build_mzp.py
```

The builder packages the contents of `src/` with the correct MZP root layout and creates:

```text
dist/AR_glTF_Material_Forge_1_2_0.mzp
```

No third-party Python packages are required to build the archive.

## Install from MZP

Choose one of these methods.

### Method A — Run Script

1. Open 3ds Max.
2. Go to **Scripting -> Run Script**.
3. Select `AR_glTF_Material_Forge_1_2_0.mzp`.
4. Wait for the installation confirmation.
5. The panel opens immediately.

### Method B — Drag and drop

Drag the MZP file from Windows Explorer into the 3ds Max viewport.

The same installer is executed.

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

1. close the current panel;
2. obtain the newer MZP from GitHub Actions or build it locally;
3. run it in 3ds Max;
4. allow it to replace the existing add-on files.

The installer uses replace semantics for its own files.

A scene restart is normally not required. If an older in-memory panel is open, the application recreates the panel from the newly installed code.

## Uninstall

Close 3ds Max, then remove these installed items:

```text
<User Scripts>\AR_glTF_Material_Forge\
<User Macros>\AR_glTF_Material_Forge.mcr
<User Startup Scripts>\AR_glTF_Material_Forge_startup.ms
<User Icons>\AR_glTF_Material_Forge.svg
```

After restarting 3ds Max, the add-on will no longer load.

If the custom toolbar remains in the UI configuration, remove the toolbar from the 3ds Max interface customization or reset that toolbar layout.

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

The tool only acts on the material classes it is designed for. For example:

- the 2Sided tool searches for `VRay2SidedMtl`;
- the Blend tool searches for `VRayBlendMtl`.

If V-Ray is not loaded, V-Ray-specific classes may not be available.

### A cleanup operation changes more than expected

Use Undo immediately and inspect the material graph.

These tools are intended for deliberate material preparation. Always work on a saved copy of the scene.
