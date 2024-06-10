local updateModule = nil
local repositoryUrl = "https://shelfwood-mpm-packages.netlify.app/"
local installModule = dofile("/mpm/Core/Commands/install.lua")

--[[
    This command updates the specified module or all modules if no module is specified.
    To update a module we need to:
    - Obtain the manifest.json
    - For each module in the manifest, download the module from the repository
    - Replace the existing module with the new module
    - For any modules that are no longer in the manifest, delete them
]]
updateModule = {
    usage = "mpm update <module>",

    run = function(...)
        local names = {...}
        -- If <module> names are specified, we only update those modules
        if #names > 0 then
            updateModule.updateModules(names)
        end

        -- If no <module> names are specified, we update all modules
        updateModule.updateModules(exports("Utils.File").list("/mpm/Packages/"))
    end,

    updateModules = function(modules)
        for _, module in ipairs(modules) do
            updateModule.updateSingleModule(module)
        end
    end,

    updateSingleModule = function(module)
        print("- @" .. module)
        local manifest = textutils.unserialiseJSON(http.get(repositoryUrl .. module .. "/manifest.json").readAll())
        for _, moduleName in ipairs(manifest.modules) do
            updateModule.updateSingleFile(module, moduleName)
        end

        updateModule.removeFilesNotInList(module, manifest.modules)
    end,

    updateSingleFile = function(module, filename)
        -- Obtain the file from the repository
        local content = http.get(repositoryUrl .. module .. "/" .. filename .. ".lua")

        -- If the file content is the same, return
        local installedContent = exports("Utils.File").get("/mpm/Packages/" .. module .. "/" .. filename .. '.lua')

        if installedContent == content then
            return
        end

        -- Replace the existing file with the new updated file
        exports("Utils.File").put("/mpm/Packages/" .. module .. "/" .. filename .. '.lua', content)

        -- Print the file name
        print("  - " .. filename)
    end,

    removeFilesNotInList = function(module, modules)
        local files = exports("Utils.File").list("/mpm/Packages/" .. module)
        for _, file in ipairs(files) do
            if not updateModule.isInList(file, modules) then
                exports("Utils.File").delete("/mpm/Packages/" .. module .. "/" .. file)
                -- Print the file name with an X to indicate it is deleted
                print("X - " .. file)
            end
        end
    end,

    isInList = function(file, list)
        for _, item in ipairs(list) do
            if item .. ".lua" == file then
                return true
            end
        end
        return false
    end
}

return updateModule
