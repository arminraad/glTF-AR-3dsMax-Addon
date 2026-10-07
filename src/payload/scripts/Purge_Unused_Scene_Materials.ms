/*
    Purge_Unused_Scene_Materials.ms
    ------------------------------------------------------------
    Removes MATERIAL nodes from Slate Material Editor when the material
    is not used anywhere by the actual scene.

    A material is KEPT if:
      - it is assigned to any scene object, OR
      - it is a sub-material of a material assigned to a scene object, OR
      - 3ds Max reports that it is used somewhere in the scene material tree.

    A material is REMOVED if:
      - it exists in Slate, but
      - it has no real scene usage.

    SAFETY
    ------
    - Used materials are never rewired.
    - Multi/Sub Material IDs are never changed.
    - Object material assignments are never changed.
    - Texture/map nodes are not deleted by this script.
    - Unused glTF / Multi/Sub materials are also removed if they truly
      have no scene usage.

    Save a copy of the .max file before running.
*/


global PUM_USED_MATERIALS = #()


fn PUM_AddUnique arr obj =
(
    if obj != undefined do
    (
        if (findItem arr obj) == 0 do append arr obj
    )
)


fn PUM_CollectMaterialTree mtl =
(
    if mtl == undefined then return false

    if (findItem PUM_USED_MATERIALS mtl) != 0 then return true

    append PUM_USED_MATERIALS mtl

    local subCount = 0

    try
    (
        subCount = getNumSubMtls mtl
    )
    catch
    (
        subCount = 0
    )

    if subCount > 0 do
    (
        for i = 1 to subCount do
        (
            local subMtl = undefined

            try
            (
                subMtl = getSubMtl mtl i
            )
            catch
            (
                subMtl = undefined
            )

            if subMtl != undefined do
            (
                PUM_CollectMaterialTree subMtl
            )
        )
    )

    true
)


fn PUM_IsReallyUsed mtl =
(
    if mtl == undefined then return false

    if (findItem PUM_USED_MATERIALS mtl) != 0 then
    (
        return true
    )

    local usedByMax = false

    try
    (
        usedByMax = isMtlUsedInSceneMtl mtl \
            skipCustAttributes:false \
            includeXrefScenes:false \
            topLevelMtlOnly:false
    )
    catch
    (
        usedByMax = false
    )

    usedByMax
)


fn PUM_Main =
(
    PUM_USED_MATERIALS = #()

    local allSlateMaterials = #()
    local unusedMaterials = #()

    local viewCount = 0
    local inspectedMaterialNodes = 0
    local deletedNodes = 0

    for obj in objects do
    (
        local mtl = undefined

        try
        (
            mtl = obj.material
        )
        catch
        (
            mtl = undefined
        )

        if mtl != undefined do
        (
            PUM_CollectMaterialTree mtl
        )
    )

    try
    (
        viewCount = sme.GetNumViews()
    )
    catch
    (
        viewCount = 0
    )

    if viewCount < 1 then
    (
        messageBox "No Slate Material Editor views were found." title:"Purge Unused Materials"
        return false
    )

    for vIndex = 1 to viewCount do
    (
        local v = sme.GetView vIndex
        local nodeCount = 0

        try
        (
            nodeCount = v.GetNumNodes()
        )
        catch
        (
            nodeCount = 0
        )

        for nIndex = 1 to nodeCount do
        (
            local node = undefined
            local refObj = undefined

            try
            (
                node = v.GetNode nIndex
            )
            catch
            (
                node = undefined
            )

            if node != undefined do
            (
                try
                (
                    refObj = node.reference
                )
                catch
                (
                    refObj = undefined
                )

                if refObj != undefined do
                (
                    local isMat = false

                    try
                    (
                        isMat = isKindOf refObj Material
                    )
                    catch
                    (
                        isMat = false
                    )

                    if isMat do
                    (
                        inspectedMaterialNodes += 1
                        PUM_AddUnique allSlateMaterials refObj
                    )
                )
            )
        )
    )

    for mtl in allSlateMaterials do
    (
        if not (PUM_IsReallyUsed mtl) do
        (
            PUM_AddUnique unusedMaterials mtl
        )
    )

    undo "Purge Unused Slate Materials" on
    (
        for vIndex = 1 to viewCount do
        (
            local v = sme.GetView vIndex
            local refsInThisView = #()

            for mtl in unusedMaterials do
            (
                local node = undefined

                try
                (
                    node = v.GetNodeByRef mtl
                )
                catch
                (
                    node = undefined
                )

                if node != undefined do
                (
                    PUM_AddUnique refsInThisView mtl
                )
            )

            if refsInThisView.count > 0 do
            (
                try
                (
                    v.SelectNone()
                    v.SetSelectedNodes refsInThisView
                    v.DeleteSelection()

                    deletedNodes += refsInThisView.count
                )
                catch
                (
                    format "[WARNING] Could not delete some unused material nodes in Slate view %.\n" vIndex
                )
            )
        )
    )

    redrawViews()

    try
    (
        gc light:true
    )
    catch()

    local report = \
        ("Finished.\n\n" + \
         "Used materials in scene tree: " + PUM_USED_MATERIALS.count as string + "\n" + \
         "Unique Slate materials checked: " + allSlateMaterials.count as string + "\n" + \
         "Unused materials found: " + unusedMaterials.count as string + "\n" + \
         "Unused Slate material nodes deleted: " + deletedNodes as string + "\n\n" + \
         "Used material assignments, Multi/Sub IDs, and material connections were not changed.")

    messageBox report title:"Purge Unused Materials"
    format "\n=== Purge Unused Materials ===\n%\n" report

    true
)


PUM_Main()
