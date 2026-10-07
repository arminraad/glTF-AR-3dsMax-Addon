/*
    AR glTF Material Forge - MZP Bootstrap
    Version 1.3.0

    Dragging/running the MZP opens the installer/updater UI.
    No files are changed until the user presses Install or Update.
*/

try
(
    local packageRoot = getFilenamePath (getSourceFileName())
    local installerPy = packageRoot + "payload\\installer.py"

    if doesFileExist installerPy then
    (
        python.ExecuteFile installerPy
    )
    else
    (
        messageBox \
            ("Installer UI was not found.\n\nExpected:\n" + installerPy) \
            title:"AR glTF Material Forge - Installer Error"
    )
)
catch
(
    messageBox \
        ("Could not start the installer.\n\n" + (getCurrentException())) \
        title:"AR glTF Material Forge - Installer Error"
)
