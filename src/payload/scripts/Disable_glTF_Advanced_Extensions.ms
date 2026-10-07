/*
    Disable_glTF_Advanced_Extensions.ms
    -----------------------------------
    Disables these options on ALL glTFMaterial instances in the scene:

      - Sheen
      - Specular
      - Transmission
      - Volume
      - IOR

    It does NOT delete maps or change Multi/Sub IDs.
*/

fn DisableGLTFAdvancedExtensions =
(
    local mats = #()
    local changed = 0
    local failed = 0

    try
    (
        mats = getClassInstances glTFMaterial
    )
    catch
    (
        mats = #()
    )

    if mats.count == 0 then
    (
        messageBox "No glTFMaterial instances were found in the scene." title:"glTF Extensions OFF"
        return false
    )

    undo "Disable glTF Advanced Extensions" on
    (
        for m in mats do
        (
            local ok = true

            try (m.enableSheen = false) catch (ok = false)
            try (m.enableSpecular = false) catch (ok = false)
            try (m.enableTransmission = false) catch (ok = false)
            try (m.enableVolume = false) catch (ok = false)
            try (m.enableIndexOfRefraction = false) catch (ok = false)

            if ok then
            (
                changed += 1
                format "[OFF] %\n" m.name
            )
            else
            (
                failed += 1
                format "[WARNING] Could not change one or more properties on: %\n" m.name
            )
        )
    )

    redrawViews()

    local msg =
        ("Finished.\n\n" +
         "glTF materials found: " + mats.count as string + "\n" +
         "Updated successfully: " + changed as string + "\n" +
         "Warnings: " + failed as string + "\n\n" +
         "Disabled:\n" +
         "Sheen\n" +
         "Specular\n" +
         "Transmission\n" +
         "Volume\n" +
         "IOR\n\n" +
         "Maps and Multi/Sub Material IDs were not changed.")

    messageBox msg title:"glTF Extensions OFF"

    true
)

DisableGLTFAdvancedExtensions()
