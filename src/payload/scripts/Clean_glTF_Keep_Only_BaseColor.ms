/*
    Clean_glTF_Keep_Only_BaseColor.ms
    3ds Max / MAXScript

    WHAT IT DOES
    ------------
    For every glTF Material used by the scene:
      1. Keeps the entire texture/map dependency tree connected to Base Color Map.
      2. Disconnects ALL other direct map slots from that glTF Material.
      3. Removes now-unused disconnected map nodes from all Slate Material Editor views.
      4. Does NOT change:
           - Object material assignments
           - Multi/Sub-Object material structure
           - Multi/Sub material IDs / slot numbers
           - Sub-material connections
           - The Base Color Map chain

    IMPORTANT
    ---------
    Save a copy of the .max file before running.
*/

global GLTF_BASECOLOR_CLEANER_VERSION = "1.0"

fn _appendUniqueRef arr obj =
(
    if obj != undefined and (findItem arr obj) == 0 do append arr obj
)

fn _collectMapTree tex arr =
(
    if tex == undefined then return false
    if (findItem arr tex) != 0 then return true

    append arr tex

    local n = 0
    try (n = getNumSubTexmaps tex) catch (n = 0)

    for i = 1 to n do
    (
        local child = undefined
        try (child = getSubTexmap tex i) catch (child = undefined)
        if child != undefined do _collectMapTree child arr
    )
    true
)

fn _collectMaterialTree mtl arr =
(
    if mtl == undefined then return false
    if (findItem arr mtl) != 0 then return true

    append arr mtl

    local n = 0
    try (n = getNumSubMtls mtl) catch (n = 0)

    for i = 1 to n do
    (
        local sm = undefined
        try (sm = getSubMtl mtl i) catch (sm = undefined)
        if sm != undefined do _collectMaterialTree sm arr
    )
    true
)

fn _isGLTFMaterial mtl =
(
    if mtl == undefined then return false

    local cls = ""
    try (cls = toLower ((classof mtl) as string)) catch (cls = "")

    (findString cls "gltfmaterial") != undefined
)

fn _normalizedSlotName s =
(
    if s == undefined then return ""
    local t = toLower (s as string)
    t = substituteString t " " ""
    t = substituteString t "_" ""
    t = substituteString t "-" ""
    t
)

fn _findBaseColorSlot mtl =
(
    local n = 0
    try (n = getNumSubTexmaps mtl) catch (n = 0)

    for i = 1 to n do
    (
        local slotName = ""
        try (slotName = getSubTexmapSlotName mtl i) catch (slotName = "")

        local normalized = _normalizedSlotName slotName

        if ((findString normalized "basecolor") != undefined) then
            return i
    )

    0
)

fn CleanGLTFKeepOnlyBaseColor =
(
    local allMaterials = #()
    local gltfMaterials = #()
    local keepMaps = #()
    local removalCandidates = #()

    local processedMaterials = 0
    local disconnectedSlots = 0
    local skippedNoBaseSlot = 0
    local slateNodesDeleted = 0

    for topMtl in sceneMaterials do
        _collectMaterialTree topMtl allMaterials

    for m in allMaterials where (_isGLTFMaterial m) do
        append gltfMaterials m

    if gltfMaterials.count == 0 then
    (
        messageBox \
            "No glTF Material instances were found in the scene material hierarchy." \
            title:"glTF Base Color Cleaner"
        return false
    )

    for m in gltfMaterials do
    (
        local baseMap = undefined

        if isProperty m #baseColorMap then
        (
            try (baseMap = getProperty m #baseColorMap) catch (baseMap = undefined)
        )
        else
        (
            local baseSlot = _findBaseColorSlot m
            if baseSlot > 0 do
                try (baseMap = getSubTexmap m baseSlot) catch (baseMap = undefined)
        )

        if baseMap != undefined do _collectMapTree baseMap keepMaps
    )

    undo "glTF - Keep Only Base Color Maps" on
    (
        for m in gltfMaterials do
        (
            local baseSlot = _findBaseColorSlot m

            if baseSlot == 0 then
            (
                skippedNoBaseSlot += 1
                format "[SKIP] Could not identify Base Color Map slot: %\n" m.name
            )
            else
            (
                local n = 0
                try (n = getNumSubTexmaps m) catch (n = 0)

                for i = 1 to n where i != baseSlot do
                (
                    local oldMap = undefined
                    try (oldMap = getSubTexmap m i) catch (oldMap = undefined)

                    if oldMap != undefined then
                    (
                        _collectMapTree oldMap removalCandidates

                        try
                        (
                            setSubTexmap m i undefined
                            disconnectedSlots += 1

                            local slotName = ""
                            try (slotName = getSubTexmapSlotName m i) catch (slotName = ("Slot " + i as string))

                            format "[DISCONNECTED] % | %\n" m.name slotName
                        )
                        catch
                        (
                            format "[ERROR] Could not clear map slot % on material %\n" i m.name
                        )
                    )
                )

                processedMaterials += 1
            )
        )
    )

    local slateDeleteRefs = #()

    for tex in removalCandidates do
    (
        if (findItem keepMaps tex) == 0 then
        (
            local stillUsed = true
            try
            (
                stillUsed = isMtlUsedInSceneMtl tex \
                    skipCustAttributes:true \
                    includeXrefScenes:false \
                    topLevelMtlOnly:false
            )
            catch
            (
                stillUsed = true
            )

            if not stillUsed do _appendUniqueRef slateDeleteRefs tex
        )
    )

    try
    (
        local numViews = sme.GetNumViews()

        for vIndex = 1 to numViews do
        (
            local v = sme.GetView vIndex
            local refsInThisView = #()

            for tex in slateDeleteRefs do
            (
                local node = undefined
                try (node = v.GetNodeByRef tex) catch (node = undefined)

                if node != undefined do append refsInThisView tex
            )

            if refsInThisView.count > 0 then
            (
                v.SelectNone()
                v.SetSelectedNodes refsInThisView
                slateNodesDeleted += refsInThisView.count
                v.DeleteSelection()
            )
        )
    )
    catch
    (
        format "[WARNING] Material cleanup completed, but Slate node cleanup could not be completed.\n"
    )

    redrawViews()

    local report = \
        ("Finished.\n\n" +
         "glTF materials found: " + gltfMaterials.count as string + "\n" +
         "glTF materials processed: " + processedMaterials as string + "\n" +
         "Non-Base-Color map slots disconnected: " + disconnectedSlots as string + "\n" +
         "Protected Base Color map nodes: " + keepMaps.count as string + "\n" +
         "Unused Slate nodes removed: " + slateNodesDeleted as string + "\n" +
         "Skipped materials with unknown Base Color slot: " + skippedNoBaseSlot as string + "\n\n" +
         "Multi/Sub materials and Material IDs were not modified.")

    messageBox report title:"glTF Base Color Cleaner"
    format "\n=== glTF Base Color Cleaner ===\n%\n" report

    true
)

CleanGLTFKeepOnlyBaseColor()
