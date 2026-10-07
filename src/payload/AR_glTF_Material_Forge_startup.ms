/* Auto-loader for AR glTF Material Forge */
try
(
    local toolFile = (getDir #userScripts) + "\\AR_glTF_Material_Forge\\startup.py"
    if doesFileExist toolFile do python.ExecuteFile toolFile
)
catch
(
    format "AR glTF Material Forge startup failed: %\n" (getCurrentException())
)
