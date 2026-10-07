/*
    Show_All_Scene_Textures_In_Viewport.ms
    ------------------------------------------------------------
    Enables viewport texture display for every material and sub-material
    used in the current scene.

    SAFE:
    - Does NOT change material connections
    - Does NOT change Multi/Sub IDs
    - Does NOT change UVs
    - Does NOT replace maps/materials
    - Only enables viewport display flags

    Recommended viewport mode:
      Shaded or Realistic
*/


global SVT_VISITED_MTLS = #()
global SVT_MATERIAL_COUNT = 0
global SVT_MAP_COUNT = 0


fn SVT_AddUnique arr obj =
(
    if obj != undefined do
    (
        if (findItem arr obj) == 0 do append arr obj
    )
)


fn SVT_EnableMaterial mtl =
(
    if mtl == undefined then return false

    if (findItem SVT_VISITED_MTLS mtl) != 0 then return true
    append SVT_VISITED_MTLS mtl

    SVT_MATERIAL_COUNT += 1

    try
    (
        mtl.showInViewport = true
    )
    catch()

    try
    (
        showTextureMap mtl true
    )
    catch()

    try
    (
        enableHardwareMaterial mtl true
    )
    catch()

    try
    (
        showHWTextureMap mtl true
    )
    catch()

    local texCount = 0
    try
    (
        texCount = getNumSubTexmaps mtl
    )
    catch
    (
        texCount = 0
    )

    for i = 1 to texCount do
    (
        local tex = undefined

        try
        (
            tex = getSubTexmap mtl i
        )
        catch
        (
            tex = undefined
        )

        if tex != undefined do
        (
            SVT_MAP_COUNT += 1

            try
            (
                showTextureMap mtl tex true
            )
            catch()

            try
            (
                enableHardwareMaterial mtl tex true
            )
            catch()

            try
            (
                showHWTextureMap mtl tex true
            )
            catch()
        )
    )

    local subCount = 0
    try
    (
        subCount = getNumSubMtls mtl
    )
    catch
    (
        subCount = 0
    )

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
            SVT_EnableMaterial subMtl
        )
    )

    true
)


fn SVT_Main =
(
    SVT_VISITED_MTLS = #()
    SVT_MATERIAL_COUNT = 0
    SVT_MAP_COUNT = 0

    for mtl in sceneMaterials do
    (
        SVT_EnableMaterial mtl
    )

    for obj in objects do
    (
        local objMtl = undefined

        try
        (
            objMtl = obj.material
        )
        catch
        (
            objMtl = undefined
        )

        if objMtl != undefined do
        (
            SVT_EnableMaterial objMtl
        )
    )

    redrawViews()

    try
    (
        completeRedraw()
    )
    catch()

    local msg = \
        ("Finished.\n\n" + \
         "Materials enabled in viewport: " + SVT_MATERIAL_COUNT as string + "\n" + \
         "Connected texture slots enabled: " + SVT_MAP_COUNT as string + "\n\n" + \
         "No materials, connections, Multi/Sub IDs, or UVs were changed.\n\n" + \
         "Use a Shaded or Realistic viewport to see the textures.")

    messageBox msg title:"Show Scene Textures In Viewport"

    true
)


SVT_Main()
