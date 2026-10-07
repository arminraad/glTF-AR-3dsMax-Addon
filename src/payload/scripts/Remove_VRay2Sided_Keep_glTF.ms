/*
    Remove_VRay2Sided_Keep_glTF.ms
    Purpose:
      - Find every VRay2SidedMtl in the current scene.
      - If its Front material is a glTF material, replace the VRay2SidedMtl
        instance with that Front material everywhere it is referenced.
      - Multi/Sub-Object slot numbers / Material IDs remain unchanged.

    Recommended:
      Save a copy of the .max scene before running.
*/

fn isGLTFMaterial m =
(
    if m == undefined then
    (
        false
    )
    else
    (
        local clsName = (classof m) as string
        matchPattern clsName pattern:"*gltf*" ignoreCase:true
    )
)

fn removeVRay2SidedWrappers =
(
    local wrappers = #()
    local replacedCount = 0
    local skippedNoFront = 0
    local skippedNonGLTF = 0

    try
    (
        wrappers = getClassInstances VRay2SidedMtl
    )
    catch
    (
        messageBox \
            "VRay2SidedMtl class was not found.\nMake sure V-Ray is loaded in this 3ds Max session." \
            title:"VRay2Sided -> glTF"
        return false
    )

    if wrappers.count == 0 then
    (
        messageBox \
            "No VRay2SidedMtl materials were found in the scene." \
            title:"VRay2Sided -> glTF"
        return true
    )

    undo "Remove VRay2Sided wrappers" on
    (
        for wrapper in wrappers do
        (
            local frontMat = undefined

            if isProperty wrapper #frontMtl then
                frontMat = wrapper.frontMtl

            if frontMat == undefined then
            (
                skippedNoFront += 1
                format "[SKIP - NO FRONT] %\n" wrapper.name
            )
            else if isGLTFMaterial frontMat then
            (
                local oldName = wrapper.name
                local newName = frontMat.name

                /*
                    This replaces the wrapper reference itself.
                    Example:
                      Multi/Sub ID 8 -> VRay2SidedMtl -> glTF
                    becomes:
                      Multi/Sub ID 8 -> glTF

                    ID 8 itself is not changed.
                */
                replaceInstances wrapper frontMat

                replacedCount += 1
                format "[REPLACED] %  -->  %\n" oldName newName
            )
            else
            (
                skippedNonGLTF += 1
                format "[SKIP - FRONT IS NOT glTF] % | Front: % | Class: %\n" \
                    wrapper.name frontMat.name ((classof frontMat) as string)
            )
        )
    )

    redrawViews()

    local report = \
        ("Finished.\n\n" +
         "VRay2SidedMtl found: " + wrappers.count as string + "\n" +
         "Replaced with Front glTF material: " + replacedCount as string + "\n" +
         "Skipped - no Front material: " + skippedNoFront as string + "\n" +
         "Skipped - Front is not glTF: " + skippedNonGLTF as string + "\n\n" +
         "Multi/Sub Material IDs were not renumbered.")

    messageBox report title:"VRay2Sided -> glTF"
    true
)

removeVRay2SidedWrappers()
