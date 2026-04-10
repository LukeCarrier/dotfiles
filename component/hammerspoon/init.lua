spaceName = hs.loadSpoon("SpaceName")
spaceName
    :start()
    :bindHotkeys({
        -- hotkey to change current space's name
        set={{"ctrl"}, "n"},
        -- hotkey to show menu with all spaces
        show={{"ctrl"}, "m"}
    })
