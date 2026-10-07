# Usage

AR glTF Material Forge is a set of independent material-processing operations. Run only the operations required by the current scene.

## Before you start

1. Save the scene.
2. Save a second backup copy.
3. Open Slate Material Editor if you want to inspect graph changes.
4. Confirm that the expected V-Ray-to-glTF conversion stage has already been completed where required.

## Recommended sequence

For the architectural workflow this add-on was built around:

1. **Remove V-Ray 2Sided Wrapper**
2. **Remove V-Ray Blend Wrapper**
3. **Keep Base Color Branch Only**
4. **Flatten Base Color to Bitmap**
5. **Clean Orphan Slate Nodes**
6. **Purge Unused Materials**
7. **Disable Extra glTF Extensions**
8. **Show Textures in Viewport**

This is a recommended order, not a mandatory batch process.

---

## Remove V-Ray 2Sided Wrapper

### Purpose

Simplify:

```text
Multi/Sub slot
  -> VRay2SidedMtl
     -> Front glTF Material
```

into:

```text
Multi/Sub slot
  -> glTF Material
```

### Behavior

- searches the scene for `VRay2SidedMtl`;
- checks the Front material;
- replaces the wrapper only when the Front material is a glTF material;
- preserves the existing parent reference.

### Preserved

- Multi/Sub slot number;
- Material ID;
- object material assignment.

---

## Remove V-Ray Blend Wrapper

### Purpose

Simplify eligible V-Ray Blend wrappers when the Base material has already been converted to glTF.

### Behavior

If:

```text
VRayBlendMtl
  -> Base Material = glTF Material
```

the wrapper is replaced with that Base glTF material.

### Important limitation

Complex Coat layers and masks are not reconstructed into a new glTF material.

If the Base material is not already glTF, the tool skips that wrapper rather than guessing.

---

## Keep Base Color Branch Only

### Purpose

Strip a glTF material down to the texture-map branch required for Base Color preparation.

### Behavior

- identifies the Base Color Map slot;
- preserves the complete dependency tree connected to Base Color;
- disconnects other direct texture-map branches;
- removes now-unused Slate map nodes when safe.

### Typical removed branches

Depending on the material, this may disconnect:

- Normal;
- Specular;
- Ambient Occlusion;
- Alpha;
- Emission;
- Clearcoat;
- Sheen;
- Transmission-related maps.

Material assignments and Multi/Sub structure are not changed.

---

## Flatten Base Color to Bitmap

### Purpose

Replace intermediate map processing with a direct Bitmap connection.

Example:

```text
Bitmap
  -> Color Correction
     -> Mix
        -> glTF Base Color Map
```

becomes:

```text
Bitmap
  -> glTF Base Color Map
```

### Selection logic

The tool traces backward from Base Color.

For multi-input maps such as Mix, content/color inputs are preferred over control inputs such as:

- mask;
- amount;
- opacity;
- alpha;
- bump;
- normal;
- roughness;
- metalness;
- displacement;
- AO;
- weight.

After rewiring, orphaned Slate nodes outside protected glTF/Multi-Sub graphs are cleaned.

### Review requirement

Because flattening removes color-correction and mix logic, visually inspect the resulting Base Color after running this operation.

---

## Clean Orphan Slate Nodes

### Definition of orphan used by this tool

A node is retained only when it belongs to a dependency graph rooted at:

- `glTFMaterial`; or
- `MultiMaterial` / Multi/Sub-Object.

A free-standing graph such as:

```text
Bitmap -> Composite -> VRayNormalMap
```

is removed if that graph does not ultimately belong to one of those protected roots.

### Preserved

- all glTF material roots;
- all Multi/Sub-Object roots;
- their complete dependency graphs.

---

## Purge Unused Materials

### Purpose

Remove material nodes with no real scene usage.

### A material is considered used when

- it is assigned to a scene object; or
- it is a sub-material of an assigned material; or
- 3ds Max reports it as used inside the scene material tree.

Unused material nodes remaining only in Slate are removed.

### Preserved

- used Multi/Sub structures;
- used sub-materials;
- Material IDs;
- object assignments.

---

## Disable Extra glTF Extensions

Turns off these glTF material options across the scene:

```text
Sheen
Specular
Transmission
Volume
IOR
```

The operation changes the corresponding enable states. It does not intentionally renumber materials or alter Multi/Sub assignments.

---

## Show Textures in Viewport

Enables viewport texture display for materials used by the scene, including nested sub-materials.

The operation does not modify:

- UVs;
- map file paths;
- Material IDs;
- object material assignments.

For visible texture display, use an appropriate **Shaded** or **Realistic** viewport mode.

---

## Undo

Most material-changing operations are wrapped in a 3ds Max Undo block.

If a result is not appropriate for the current material, use Undo immediately and inspect that material separately.

## Final verification

Before glTF / GLB export:

- inspect all visible materials in the viewport;
- inspect critical materials in Slate Material Editor;
- confirm Multi/Sub Material IDs still match the intended geometry;
- verify transparency / alpha materials separately;
- verify any material that originally used V-Ray procedural blending;
- save a new prepared scene version before export.
