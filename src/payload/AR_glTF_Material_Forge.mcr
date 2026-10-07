macroScript AR_glTF_Material_Forge
category:"AR glTF Material Forge"
toolTip:"Open AR glTF Material Forge"
buttonText:"AR glTF Forge"
iconName:"AR_glTF_Material_Forge"
(
    on execute do
    (
        local toolFile = (getDir #userScripts) + "\\AR_glTF_Material_Forge\\open_panel.py"
        if doesFileExist toolFile then
        (
            python.ExecuteFile toolFile
        )
        else
        (
            messageBox "AR glTF Material Forge is not installed correctly. Re-run the MZP installer." title:"AR glTF Material Forge"
        )
    )
)
