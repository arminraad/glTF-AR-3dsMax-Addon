/*
    Clean_Slate_Orphans_Protected_Roots_v2_1.ms

    Rule:
    Keep every Slate node that belongs to a dependency tree rooted at:
      1) glTFMaterial
      2) MultiMaterial (Multi/Sub-Object)

    Delete every other visible Slate node.

    Safety:
    - glTFMaterial is NEVER deleted.
    - Multi/Sub-Object is NEVER deleted.
    - Multi/Sub IDs are not changed.
    - Object material assignments are not changed.
    - Material/map wiring is not changed.
    - Only Slate Material Editor view nodes are removed.
*/

global SLC_KEEP_REFS = #()
global SLC_ROOT_REFS = #()


fn SLC_AddUnique arr obj =
(
    if obj != undefined do
    (
        if (findItem arr obj) == 0 do append arr obj
    )
)


fn SLC_IsProtectedRoot obj =
(
    if obj == undefined then
    (
        false
    )
    else
    (
        local c = classof obj

        if c == glTFMaterial then
        (
            true
        )
        else if c == MultiMaterial then
        (
            true
        )
        else
        (
            false
        )
    )
)


fn SLC_CollectDependencies obj =
(
    if obj == undefined then return false
    if (findItem SLC_KEEP_REFS obj) != 0 then return true

    append SLC_KEEP_REFS obj

    local texCount = 0
    try
    (
        texCount = getNumSubTexmaps obj
    )
    catch
    (
        texCount = 0
    )

    if texCount > 0 do
    (
        for i = 1 to texCount do
        (
            local childMap = undefined

            try
            (
                childMap = getSubTexmap obj i
            )
            catch
            (
                childMap = undefined
            )

            if childMap != undefined do
            (
                SLC_CollectDependencies childMap
            )
        )
    )

    local mtlCount = 0
    try
    (
        mtlCount = getNumSubMtls obj
    )
    catch
    (
        mtlCount = 0
    )

    if mtlCount > 0 do
    (
        for i = 1 to mtlCount do
        (
            local childMtl = undefined

            try
            (
                childMtl = getSubMtl obj i
            )
            catch
            (
                childMtl = undefined
            )

            if childMtl != undefined do
            (
                SLC_CollectDependencies childMtl
            )
        )
    )

    true
)


fn SLC_CleanSlate =
(
    SLC_KEEP_REFS = #()
    SLC_ROOT_REFS = #()

    local viewCount = 0
    local allVisibleRefs = #()
    local refsToDelete = #()

    local inspectedNodes = 0
    local deletedNodes = 0

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
        messageBox "No Slate Material Editor views were found." title:"Slate Orphan Cleaner"
        return false
    )

    local gltfRoots = #()
    local multiRoots = #()

    try
    (
        gltfRoots = getClassInstances glTFMaterial
    )
    catch
    (
        gltfRoots = #()
    )

    try
    (
        multiRoots = getClassInstances MultiMaterial
    )
    catch
    (
        multiRoots = #()
    )

    for m in gltfRoots do SLC_AddUnique SLC_ROOT_REFS m
    for m in multiRoots do SLC_AddUnique SLC_ROOT_REFS m

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
            local n = undefined
            local refObj = undefined

            try
            (
                n = v.GetNode nIndex
            )
            catch
            (
                n = undefined
            )

            if n != undefined do
            (
                try
                (
                    refObj = n.reference
                )
                catch
                (
                    refObj = undefined
                )

                if refObj != undefined do
                (
                    inspectedNodes += 1
                    SLC_AddUnique allVisibleRefs refObj

                    if SLC_IsProtectedRoot refObj do
                    (
                        SLC_AddUnique SLC_ROOT_REFS refObj
                    )
                )
            )
        )
    )

    for rootObj in SLC_ROOT_REFS do
    (
        SLC_CollectDependencies rootObj
    )

    for refObj in allVisibleRefs do
    (
        if SLC_IsProtectedRoot refObj then
        (
            SLC_AddUnique SLC_KEEP_REFS refObj
        )
        else
        (
            if (findItem SLC_KEEP_REFS refObj) == 0 do
            (
                SLC_AddUnique refsToDelete refObj
            )
        )
    )

    undo "Clean Slate Orphan Nodes" on
    (
        for vIndex = 1 to viewCount do
        (
            local v = sme.GetView vIndex
            local deleteInThisView = #()

            for refObj in refsToDelete do
            (
                if not (SLC_IsProtectedRoot refObj) do
                (
                    local nodeInView = undefined

                    try
                    (
                        nodeInView = v.GetNodeByRef refObj
                    )
                    catch
                    (
                        nodeInView = undefined
                    )

                    if nodeInView != undefined do
                    (
                        SLC_AddUnique deleteInThisView refObj
                    )
                )
            )

            if deleteInThisView.count > 0 do
            (
                try
                (
                    v.SelectNone()
                    v.SetSelectedNodes deleteInThisView
                    v.DeleteSelection()

                    deletedNodes += deleteInThisView.count
                )
                catch
                (
                    format "WARNING: Could not delete nodes in Slate view %.\n" vIndex
                )
            )
        )
    )

    redrawViews()

    local msg = \
        ("Finished.\n\n" + \
         "Protected roots: " + (SLC_ROOT_REFS.count as string) + "\n" + \
         "Slate nodes inspected: " + (inspectedNodes as string) + "\n" + \
         "Protected dependency refs: " + (SLC_KEEP_REFS.count as string) + "\n" + \
         "Orphan refs found: " + (refsToDelete.count as string) + "\n" + \
         "Slate nodes deleted: " + (deletedNodes as string) + "\n\n" + \
         "glTFMaterial and Multi/Sub-Object were protected.")

    messageBox msg title:"Slate Orphan Cleaner"

    true
)


SLC_CleanSlate()
