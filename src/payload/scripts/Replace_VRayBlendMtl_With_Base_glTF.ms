/*
    Replace_VRayBlendMtl_With_Base_glTF.ms
    --------------------------------------
    Finds every VRayBlendMtl in the scene.

    SAFE RULE:
      If the VRayBlendMtl Base Material is already a glTFMaterial:
          VRayBlendMtl -> Base glTFMaterial

      The VRayBlendMtl wrapper is removed from all references using
      replaceInstances, so Multi/Sub slot numbers / Material IDs remain
      exactly where they were.

      If the Base Material is NOT glTFMaterial, that VRayBlendMtl is skipped.

    IMPORTANT:
      VRayBlendMtl coat layers and masks do not have a lossless 1:1 mapping
      to a single glTFMaterial. This script intentionally does NOT guess.

    Save a copy of the .max file before running.
*/


fn VBM_IsGLTFMaterial m =
(
    if m == undefined then
    (
        false
    )
    else
    (
        local result = false

        try
        (
            result = ((classof m) == glTFMaterial)
        )
        catch
        (
            result = false
        )

        result
    )
)


fn VBM_GetBaseMaterial blendMtl =
(
    if blendMtl == undefined then return undefined

    local baseMtl = undefined

    /*
        V-Ray versions can expose the base material with slightly
        different property names. Try the common ones safely.
    */

    if isProperty blendMtl #baseMtl then
    (
        try (baseMtl = getProperty blendMtl #baseMtl) catch (baseMtl = undefined)
    )

    if baseMtl == undefined and isProperty blendMtl #base_material then
    (
        try (baseMtl = getProperty blendMtl #base_material) catch (baseMtl = undefined)
    )

    if baseMtl == undefined and isProperty blendMtl #baseMaterial then
    (
        try (baseMtl = getProperty blendMtl #baseMaterial) catch (baseMtl = undefined)
    )

    /*
        Fallback: first sub-material of VRayBlendMtl is normally Base Material.
    */
    if baseMtl == undefined then
    (
        local subCount = 0
        try (subCount = getNumSubMtls blendMtl) catch (subCount = 0)

        if subCount > 0 then
        (
            try (baseMtl = getSubMtl blendMtl 1) catch (baseMtl = undefined)
        )
    )

    baseMtl
)


fn ReplaceVRayBlendWithBaseGLTF =
(
    local blends = #()

    local replacedCount = 0
    local skippedNoBase = 0
    local skippedBaseNotGLTF = 0
    local failedCount = 0

    try
    (
        blends = getClassInstances VRayBlendMtl
    )
    catch
    (
        blends = #()
    )

    if blends.count == 0 then
    (
        messageBox "No VRayBlendMtl materials were found in the scene." title:"VRayBlendMtl -> glTF"
        return false
    )


    undo "Replace VRayBlendMtl With Base glTF" on
    (
        for blend in blends do
        (
            local baseMtl = VBM_GetBaseMaterial blend

            if baseMtl == undefined then
            (
                skippedNoBase += 1
                format "[SKIP - NO BASE MATERIAL] %\n" blend.name
            )
            else if not (VBM_IsGLTFMaterial baseMtl) then
            (
                skippedBaseNotGLTF += 1

                local cls = ""
                try (cls = (classof baseMtl) as string) catch (cls = "Unknown")

                format "[SKIP - BASE IS NOT glTF] % | Base: % | Class: %\n" \
                    blend.name baseMtl.name cls
            )
            else
            (
                local oldName = blend.name
                local newName = baseMtl.name

                try
                (
                    /*
                        Replaces every reference to the VRayBlendMtl itself.

                        Example:
                          Multi/Sub ID 8 -> VRayBlendMtl -> Base glTF

                        becomes:
                          Multi/Sub ID 8 -> Base glTF

                        Material ID 8 itself is unchanged.
                    */
                    replaceInstances blend baseMtl

                    replacedCount += 1
                    format "[REPLACED] %  -->  %\n" oldName newName
                )
                catch
                (
                    failedCount += 1
                    format "[FAILED] %\n" oldName
                )
            )
        )
    )


    redrawViews()

    local report = \
        ("Finished.\n\n" + \
         "VRayBlendMtl found: " + blends.count as string + "\n" + \
         "Replaced with Base glTF: " + replacedCount as string + "\n" + \
         "Skipped - no Base Material: " + skippedNoBase as string + "\n" + \
         "Skipped - Base Material is not glTF: " + skippedBaseNotGLTF as string + "\n" + \
         "Failed: " + failedCount as string + "\n\n" + \
         "Multi/Sub Material IDs were not renumbered.\n" + \
         "Object material assignments remain intact.")

    messageBox report title:"VRayBlendMtl -> glTF"
    format "\n=== VRayBlendMtl -> glTF ===\n%\n" report

    true
)


ReplaceVRayBlendWithBaseGLTF()
