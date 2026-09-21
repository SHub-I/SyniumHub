-- tabs/auto_tab.lua
return function(Window, rank, Exclusions, tabName)
    local HttpService = game:GetService("HttpService")
    local owner, repo, branch = "SHub-I", "SyniumHub", "main"
    local baseRaw = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(owner, repo, branch)
    local apiTree = ("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1"):format(owner, repo, branch)

    local function httpGet(u)
        local ok,res = pcall(function() return game:HttpGet(u) end)
        return ok and res or nil
    end

    local function listScripts(folder)
        local raw = httpGet(apiTree)
        if not raw then return {} end
        local tree = HttpService:JSONDecode(raw)
        local out = {}
        local prefix = "scripts/"..folder.."/"
        for _,e in ipairs(tree.tree) do
            if e.type=="blob" and e.path:sub(1,#prefix)==prefix and e.path:match("%.lua$") then
                table.insert(out,e.path)
            end
        end
        table.sort(out)
        return out
    end

    local function loadScript(path)
        local raw = httpGet(baseRaw..path.."?ts="..os.time())
        if not raw then return nil end

        local ok,fn = pcall(function() return loadstring(raw) end)
        if not ok or type(fn)~="function" then return nil end

        local registeredName, registeredCallback
        local env = {
            Register = function(name,cb)
                registeredName, registeredCallback = name, cb
            end,
            print=print, pcall=pcall, pairs=pairs, ipairs=ipairs,
            string=string, table=table, math=math,
            os={time=os.time}, wait=task.wait or wait
        }
        if setfenv then setfenv(fn,env) end

        local ok2,ret = pcall(fn)
        if not ok2 then return nil end

        if registeredCallback then
            return registeredName, registeredCallback
        end

        if type(ret)=="table" and type(ret.Run)=="function" then
            return ret.Name or path, ret.Run
        end

        if type(ret)=="function" then
            local name = path:match("([^/]+)$"):gsub("%.lua$","")
            return name, ret
        end

        return nil
    end

    local Tab = Window:CreateTab(tabName:sub(1,1):upper()..tabName:sub(2), 4483345998)
    Tab:CreateSection(tabName:sub(1,1):upper()..tabName:sub(2).." Scripts")

    for _,path in ipairs(listScripts(tabName)) do
        local name,cb = loadScript(path)
        if name and cb then
            Tab:CreateButton({
                Name = name,
                Callback = function()
                    pcall(cb)
                end
            })
        else
            Tab:CreateLabel({ Text = "Failed: "..path })
        end
    end
end
