/*
    glTF_Flatten_BaseColor_To_Bitmap_v2.ms

    For every glTFMaterial:
      - trace Base Color Map upstream
      - bypass Color Correction / Mix / Composite / other map nodes
      - prefer normal color/content inputs over control inputs (mask/amount/etc.)
      - connect the first valid Bitmap directly to Base Color Map
      - remove Slate nodes no longer belonging to any glTFMaterial or MultiMaterial graph

    Multi/Sub IDs and object material assignments are not changed.
*/

global GFB_KEEP = #()

fn GFB_AddUnique arr obj =
(
    if obj != undefined do
    (
        if (findItem arr obj) == 0 do append arr obj
    )
)

fn GFB_Norm s =
(
    if s == undefined then return ""
    local t = toLower (s as string)
    t = substituteString t " " ""
    t = substituteString t "_" ""
    t = substituteString t "-" ""
    t
)

fn GFB_IsBitmap tex =
(
    if tex == undefined then return false
    local c = ""
    try (c = toLower ((classof tex) as string)) catch (c = "")
    ((findString c "bitmap") != undefined)
)

fn GFB_IsControlSlot slotName =
(
    local s = GFB_Norm slotName
    if (findString s "mask") != undefined then return true
    if (findString s "amount") != undefined then return true
    if (findString s "opacity") != undefined then return true
    if (findString s "alpha") != undefined then return true
    if (findString s "bump") != undefined then return true
    if (findString s "normal") != undefined then return true
    if (findString s "rough") != undefined then return true
    if (findString s "metal") != undefined then return true
    if (findString s "displace") != undefined then return true
    if (findString s "occlusion") != undefined then return true
    if (findString s "weight") != undefined then return true
    false
)

fn GFB_FindPrimaryBitmap tex visited =
(
    if tex == undefined then return undefined
    if (findItem visited tex) != 0 then return undefined
    append visited tex

    if GFB_IsBitmap tex then return tex

    local n = 0
    try (n = getNumSubTexmaps tex) catch (n = 0)
    if n < 1 then return undefined

    -- First pass: main/color/content inputs
    for i = 1 to n do
    (
        local child = undefined
        local slotName = ""
        try (child = getSubTexmap tex i) catch (child = undefined)
        try (slotName = getSubTexmapSlotName tex i) catch (slotName = "")

        if child != undefined do
        (
            if not (GFB_IsControlSlot slotName) do
            (
                local found = GFB_FindPrimaryBitmap child visited
                if found != undefined then return found
            )
        )
    )

    -- Second pass: control inputs only as fallback
    for i = 1 to n do
    (
        local child = undefined
        local slotName = ""
        try (child = getSubTexmap tex i) catch (child = undefined)
        try (slotName = getSubTexmapSlotName tex i) catch (slotName = "")

        if child != undefined do
        (
            if GFB_IsControlSlot slotName do
            (
                local found = GFB_FindPrimaryBitmap child visited
                if found != undefined then return found
            )
        )
    )

    undefined
)

fn GFB_FindBaseSlot mtl =
(
    local n = 0
    try (n = getNumSubTexmaps mtl) catch (n = 0)

    for i = 1 to n do
    (
        local sn = ""
        try (sn = getSubTexmapSlotName mtl i) catch (sn = "")
        if (findString (GFB_Norm sn) "basecolor") != undefined then return i
    )
    0
)

fn GFB_GetBaseMap mtl =
(
    local t = undefined
    if isProperty mtl #baseColorMap do
    (
        try (t = getProperty mtl #baseColorMap) catch (t = undefined)
    )
    if t == undefined do
    (
        local i = GFB_FindBaseSlot mtl
        if i > 0 do try (t = getSubTexmap mtl i) catch (t = undefined)
    )
    t
)

fn GFB_SetBaseMap mtl tex =
(
    local ok = false
    if isProperty mtl #baseColorMap do
    (
        try
        (
            setProperty mtl #baseColorMap tex
            ok = true
        )
        catch (ok = false)
    )
    if not ok do
    (
        local i = GFB_FindBaseSlot mtl
        if i > 0 do
        (
            try
            (
                setSubTexmap mtl i tex
                ok = true
            )
            catch (ok = false)
        )
    )
    ok
)

fn GFB_IsRoot obj =
(
    if obj == undefined then return false
    local c = classof obj
    if c == glTFMaterial then return true
    if c == MultiMaterial then return true
    false
)

fn GFB_Collect obj =
(
    if obj == undefined then return false
    if (findItem GFB_KEEP obj) != 0 then return true
    append GFB_KEEP obj

    local nt = 0
    try (nt = getNumSubTexmaps obj) catch (nt = 0)
    for i = 1 to nt do
    (
        local t = undefined
        try (t = getSubTexmap obj i) catch (t = undefined)
        if t != undefined do GFB_Collect t
    )

    local nm = 0
    try (nm = getNumSubMtls obj) catch (nm = 0)
    for i = 1 to nm do
    (
        local m = undefined
        try (m = getSubMtl obj i) catch (m = undefined)
        if m != undefined do GFB_Collect m
    )
    true
)

fn GFB_CleanSlateOrphans =
(
    GFB_KEEP = #()
    local roots = #()
    local visible = #()
    local doomed = #()
    local deleted = 0
    local vc = 0
    try (vc = sme.GetNumViews()) catch (vc = 0)

    local gs = #()
    local ms = #()
    try (gs = getClassInstances glTFMaterial) catch (gs = #())
    try (ms = getClassInstances MultiMaterial) catch (ms = #())
    for r in gs do GFB_AddUnique roots r
    for r in ms do GFB_AddUnique roots r

    for vi = 1 to vc do
    (
        local v = sme.GetView vi
        local nn = 0
        try (nn = v.GetNumNodes()) catch (nn = 0)
        for ni = 1 to nn do
        (
            local node = undefined
            local refObj = undefined
            try (node = v.GetNode ni) catch (node = undefined)
            if node != undefined do
            (
                try (refObj = node.reference) catch (refObj = undefined)
                if refObj != undefined do
                (
                    GFB_AddUnique visible refObj
                    if GFB_IsRoot refObj do GFB_AddUnique roots refObj
                )
            )
        )
    )

    for r in roots do GFB_Collect r

    for refObj in visible do
    (
        if not (GFB_IsRoot refObj) do
        (
            if (findItem GFB_KEEP refObj) == 0 do GFB_AddUnique doomed refObj
        )
    )

    for vi = 1 to vc do
    (
        local v = sme.GetView vi
        local inView = #()
        for refObj in doomed do
        (
            local n = undefined
            try (n = v.GetNodeByRef refObj) catch (n = undefined)
            if n != undefined do GFB_AddUnique inView refObj
        )
        if inView.count > 0 do
        (
            try
            (
                v.SelectNone()
                v.SetSelectedNodes inView
                v.DeleteSelection()
                deleted += inView.count
            )
            catch()
        )
    )
    deleted
)

fn GFB_Main =
(
    local mats = #()
    local rewired = 0
    local direct = 0
    local skipped = 0
    local failed = 0

    try (mats = getClassInstances glTFMaterial) catch (mats = #())

    if mats.count == 0 then
    (
        messageBox "No glTFMaterial instances were found." title:"Flatten glTF Base Color"
        return false
    )

    undo "Flatten glTF Base Color" on
    (
        for mtl in mats do
        (
            local baseMap = GFB_GetBaseMap mtl

            if baseMap == undefined then
            (
                skipped += 1
                format "[SKIP] % - no Base Color Map\n" mtl.name
            )
            else if GFB_IsBitmap baseMap then
            (
                direct += 1
                format "[DIRECT] % -> %\n" mtl.name baseMap.name
            )
            else
            (
                local visited = #()
                local bmp = GFB_FindPrimaryBitmap baseMap visited

                if bmp == undefined then
                (
                    skipped += 1
                    format "[SKIP] % - no Bitmap found upstream\n" mtl.name
                )
                else
                (
                    if GFB_SetBaseMap mtl bmp then
                    (
                        rewired += 1
                        format "[REWIRED] % -> %\n" mtl.name bmp.name
                    )
                    else
                    (
                        failed += 1
                        format "[FAILED] %\n" mtl.name
                    )
                )
            )
        )
    )

    local deleted = GFB_CleanSlateOrphans()
    redrawViews()

    local msg = "Finished.\n\n" + \
        "glTF materials: " + mats.count as string + "\n" + \
        "Rewired to direct Bitmap: " + rewired as string + "\n" + \
        "Already direct: " + direct as string + "\n" + \
        "Skipped: " + skipped as string + "\n" + \
        "Failed: " + failed as string + "\n" + \
        "Orphan Slate nodes removed: " + deleted as string

    messageBox msg title:"Flatten glTF Base Color"
    true
)

GFB_Main()
