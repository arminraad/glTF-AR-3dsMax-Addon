/*
    AR glTF Material Forge - MZP Installer
    Version 1.2.0
*/

fn ARGltf_CopyReplace src dst =
(
    local dstDir = getFilenamePath dst
    if dstDir != "" do makeDir dstDir all:true

    if doesFileExist dst do
    (
        try(deleteFile dst)catch()
    )

    if not (copyFile src dst) then
    (
        throw ("Could not copy: " + src + " -> " + dst)
    )
    true
)

fn ARGltf_Install =
(
    local installerDir = getFilenamePath (getSourceFileName())
    local payloadDir = installerDir + "payload\\"

    local installRoot = (getDir #userScripts) + "\\AR_glTF_Material_Forge\\"
    local scriptsRoot = installRoot + "scripts\\"
    local iconsRoot = installRoot + "icons\\"

    makeDir installRoot all:true
    makeDir scriptsRoot all:true
    makeDir iconsRoot all:true

    local rootFiles = #(
        "ar_gltf_material_forge.py",
        "startup.py",
        "open_panel.py"
    )

    local scriptFiles = #(
        "Remove_VRay2Sided_Keep_glTF.ms",
        "Replace_VRayBlendMtl_With_Base_glTF.ms",
        "Clean_glTF_Keep_Only_BaseColor.ms",
        "glTF_Flatten_BaseColor_To_Bitmap_v2.ms",
        "Clean_Slate_Orphans_Protected_Roots_v2_1.ms",
        "Purge_Unused_Scene_Materials.ms",
        "Disable_glTF_Advanced_Extensions.ms",
        "Show_All_Scene_Textures_In_Viewport.ms"
    )

    local iconFiles = #(
        "app.svg",
        "wrap.svg",
        "blend.svg",
        "basecolor.svg",
        "flatten.svg",
        "clean.svg",
        "purge.svg",
        "off.svg",
        "eye.svg",
        "close.svg"
    )

    for f in rootFiles do
    (
        ARGltf_CopyReplace (payloadDir + f) (installRoot + f)
    )

    for f in scriptFiles do
    (
        ARGltf_CopyReplace (payloadDir + "scripts\\" + f) (scriptsRoot + f)
    )

    for f in iconFiles do
    (
        ARGltf_CopyReplace (payloadDir + "icons\\" + f) (iconsRoot + f)
    )

    local macroDst = (getDir #userMacros) + "\\AR_glTF_Material_Forge.mcr"
    local startupDst = (getDir #userStartupScripts) + "\\AR_glTF_Material_Forge_startup.ms"
    local iconDst = (getDir #userIcons) + "\\AR_glTF_Material_Forge.svg"

    ARGltf_CopyReplace (payloadDir + "AR_glTF_Material_Forge.mcr") macroDst
    ARGltf_CopyReplace (payloadDir + "AR_glTF_Material_Forge_startup.ms") startupDst
    ARGltf_CopyReplace (payloadDir + "icons\\app.svg") iconDst

    try(fileIn macroDst quiet:true)catch()

    local openPanel = installRoot + "open_panel.py"
    if doesFileExist openPanel do python.ExecuteFile openPanel

    messageBox \
        ("AR glTF Material Forge v1.2.0 installed successfully.\n\n" + \
         "A toolbar button has been added to 3ds Max.\n" + \
         "The tool will load automatically in future sessions.\n\n" + \
         "Installed to:\n" + installRoot) \
        title:"AR glTF Material Forge"

    true
)

try
(
    ARGltf_Install()
)
catch
(
    messageBox \
        ("Installation failed.\n\n" + (getCurrentException())) \
        title:"AR glTF Material Forge - Install Error"
)
