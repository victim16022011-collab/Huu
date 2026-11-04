-- AMETHYST HORIZON HUB 1.0 | Blox Fruits Sea 3
-- Independent, source-readable Luau client assistant.
-- Evidence: "text 5.txt" (Amethyst Deep Scanner Pro) and prior Dragon Hub examples.
-- This is NOT a server exploit / remote brute-forcer. Remote names alone do NOT reveal arguments.
-- Supported features: quest tracking, farm assistance, ESP, NPC guide, local utilities, diagnostics.
-- Quest completion, damage, server permissions and game version are controlled by the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
if not player then
    warn("[AMETHYST HORIZON] Requires a local player context")
    return
end

local env = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then env = result end
end
if type(env.AmethystHorizonShutdown) == "function" then
    pcall(env.AmethystHorizonShutdown)
end

local GuiName = "AmethystHorizon_Hub_v1"
local hub = {
    alive = true,
    connections = {},
    overlays = {},
    logs = {},
    errors = {},
    timers = {},
    selectedNPC = 1,
    selectedMob = "Skull Slayer",
    moving = { goal = nil, label = "", lastSend = 0, lastPosition = nil,
               lastProgress = 0, lastPath = 0, path = nil, index = 1 },
    settings = {
        FarmAssist = false, AutoEquip = false, ToolActivate = false,
        ESPPlayers = false, ESPEnemies = false, ESPFruits = false,
        ESPNPCs = false, ESPChests = false, ShowNames = true,
        ClearFog = false, LowGraphics = false, MaxZoom = false,
    },
}

local function now() return os.clock() end
local function stamp() return os.date("%H:%M:%S") end
local function appendLog(level, message)
    if not hub.alive then return end
    local row = string.format("[%s] %s: %s", stamp(), level, tostring(message))
    table.insert(hub.logs, 1, row)
    while #hub.logs > 26 do table.remove(hub.logs) end
    if level == "ERROR" then
        table.insert(hub.errors, 1, row)
        while #hub.errors > 15 do table.remove(hub.errors) end
        warn("[AMETHYST HORIZON] " .. row)
    end
end
local function safe(label, fn, ...)
    local ok, value = pcall(fn, ...)
    if not ok then
        if (hub.timers["err:" .. label] or 0) + 4 <= now() then
            hub.timers["err:" .. label] = now()
            appendLog("ERROR", label .. " | " .. tostring(value))
        end
    end
    return ok, value
end
local function track(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(hub.connections, connection)
    return connection
end
local function notify(message)
    appendLog("INFO", message)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "AMETHYST HORIZON",
            Text = tostring(message), Duration = 4 })
    end)
end

local function throttle(key, seconds)
    if now() < (hub.timers[key] or 0) then return false end
    hub.timers[key] = now() + seconds
    return true
end
local function formatDist(dist)
    if not dist then return "?" end
    return string.format("%.0f studs", dist)
end
local function lower(s) return string.lower(tostring(s or "")) end
local function has(haystack, needle)
    return string.find(lower(haystack), lower(needle), 1, true) ~= nil
end
local function charParts()
    local character = player.Character
    if not character then return nil, nil, nil end
    return character, character:FindFirstChildOfClass("Humanoid"),
        character:FindFirstChild("HumanoidRootPart")
end
local function rootOf(model)
    if model:IsA("BasePart") then return model end
    if model:IsA("Tool") then return model:FindFirstChild("Handle") end
    if model:IsA("Model") then
        return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end
local function modelAlive(model)
    if not model or not model.Parent or not model:IsA("Model") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and rootOf(model) ~= nil
end

-- Positions here are the fourteen Workspace.NPCs positions that appear in text 5.txt.
-- They are a single-server snapshot; live NPC positions take priority.
local NPCs = {
    {"Witch", Vector3.new(-12517.9, 331.9, -7613.7)},
    {"Titles Specialist", Vector3.new(-12655.8, 336.3, -7518.7)},
    {"Awakenings Expert", Vector3.new(-12646.3, 374.3, -7557.4)},
    {"Bounty/Honor Expert", Vector3.new(-12646.1, 374.0, -7492.6)},
    {"tort", Vector3.new(-12485.2, 336.3, -7565.1)},
    {"Barista", Vector3.new(-12460.0, 337.0, -7431.8)},
    {"Pirate Recruiter", Vector3.new(-12259.0, 331.1, -7399.9)},
    {"Citizen", Vector3.new(-12441.6, 330.8, -7676.2)},
    {"Blox Fruit Gacha", Vector3.new(-12488.7, 336.3, -7445.8)},
    {"Marine Recruiter", Vector3.new(-12798.6, 331.1, -7699.2)},
    {"Set Home Point", Vector3.new(-12551.0, 336.3, -7409.5)},
    {"Nerd", Vector3.new(-12455.1, 374.0, -7522.8)},
    {"Blox Fruit Dealer", Vector3.new(-12510.5, 335.6, -7441.7)},
    {"Indra", Vector3.new(-12483.6, 332.1, -7769.2)},
}
local knownMobs = {
    "Skull Slayer", "Grand Devotee", "High Disciple", "Ocean Prophet",
    "Isle Champion", "Isle Outlaw", "Cocoa Warrior", "Pirate Millionaire",
    "Forest Pirate", "Mythological Pirate", "Jack o' Lantern",
    "Longma", "Stone", "Urban", "rip_indra",
}
-- Only this fallback mob spot comes from the user's earlier Dragon Hub, NOT from the scanner.
local legacySpots = {
    ["Skull Slayer"] = Vector3.new(-16885.20, 114.12, 1627.94),
}

local function getQuestPanel()
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return nil end
    local main = gui:FindFirstChild("Main")
    local panel = (main and main:FindFirstChild("Quest", true))
        or gui:FindFirstChild("Quest", true)
    if not panel or not panel:IsA("GuiObject") then return nil end
    local node = panel
    while node and node ~= gui do
        if node:IsA("GuiObject") and not node.Visible then return nil end
        if node:IsA("ScreenGui") and not node.Enabled then return nil end
        node = node.Parent
    end
    return panel
end
local function questInfo()
    local panel = getQuestPanel()
    if not panel then return { active = false, text = "Chưa thấy bảng Quest", target = nil } end
    local texts = {}
    for _, child in ipairs(panel:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            if child.Text and child.Text ~= "" then
                texts[#texts + 1] = child.Text
                if #texts >= 35 then break end
            end
        end
    end
    local joined = table.concat(texts, " | ")
    local target
    for _, name in ipairs(knownMobs) do
        if has(joined, name) then target = name; break end
    end
    -- Handles e.g. "Defeat 8 Skull Slayers" in the user's earlier screenshot.
    return { active = true, text = joined ~= "" and joined or "Quest đang hiển thị", target = target }
end
local function getLevel()
    local data = player:FindFirstChild("Data")
    local level = data and data:FindFirstChild("Level")
    if level and level:IsA("ValueBase") then return tostring(level.Value) end
    return "?"
end
local function findEnemy(name)
    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then return nil, 0 end
    local _, _, hrp = charParts()
    local best, bestD, count = nil, math.huge, 0
    for _, candidate in ipairs(folder:GetChildren()) do
        if modelAlive(candidate) and (name == "" or has(candidate.Name, name)) then
            local part = rootOf(candidate)
            local d = hrp and (hrp.Position - part.Position).Magnitude or math.huge
            count = count + 1
            if d < bestD then best, bestD = candidate, d end
        end
    end
    return best, count
end
local function snapshotNPC(rec)
    local folder = Workspace:FindFirstChild("NPCs")
    local instance = folder and folder:FindFirstChild(rec[1])
    if instance then
        local part = rootOf(instance)
        if part then return part.Position, true, instance end
    end
    return rec[2], false, nil
end

local function clearNavigation(reason)
    hub.moving.goal = nil
    hub.moving.label = ""
    hub.moving.path = nil
    hub.moving.index = 1
    local _, hum, root = charParts()
    if hum and root then pcall(function() hum:MoveTo(root.Position) end) end
    if reason then appendLog("INFO", reason) end
end
local function setGoal(position, label)
    if not position then return false end
    if hub.moving.blockedPos and now() < (hub.moving.blockedUntil or 0)
        and (hub.moving.blockedPos - position).Magnitude <= 35 then
        return false
    end
    local old = hub.moving.goal
    if not old or (old - position).Magnitude > 18 then
        hub.moving.path = nil
        hub.moving.index = 1
        hub.moving.lastPath = 0
        hub.moving.lastProgress = now()
        local _, _, hrp = charParts()
        hub.moving.lastPosition = hrp and hrp.Position or nil
    end
    hub.moving.goal = position
    hub.moving.label = label or "Mục tiêu"
    return true
end
local function navigationTick()
    local nav = hub.moving
    if not nav.goal then return end
    local _, humanoid, root = charParts()
    if not humanoid or not root or humanoid.Health <= 0 then
        clearNavigation()
        return
    end
    local dist = (root.Position - nav.goal).Magnitude
    if dist <= 9 then
        local destinationLabel = nav.label
        clearNavigation()
        hub.status = "Đã tới " .. destinationLabel
        return
    end
    if nav.lastPosition and (nav.lastPosition - root.Position).Magnitude > 3 then
        nav.lastPosition = root.Position
        nav.lastProgress = now()
    elseif not nav.lastPosition then
        nav.lastPosition = root.Position
        nav.lastProgress = now()
    end
    if now() - nav.lastProgress > 16 then
        nav.blockedPos = nav.goal
        nav.blockedUntil = now() + 45
        hub.status = "Di chuyển bị kẹt; hãy đến gần hơn hoặc dùng tàu"
        clearNavigation("Điều hướng dừng sau 16 giây không có tiến triển")
        return
    end
    -- For far destinations, walk a bounded section. No client teleport / anti-cheat bypass.
    if dist > 260 then
        if throttle("navDirect", 2) then
            humanoid:MoveTo(root.Position + (nav.goal - root.Position).Unit * 145)
            hub.status = "Đang di chuyển: " .. nav.label .. " · " .. formatDist(dist)
        end
        return
    end
    if not nav.path and now() - nav.lastPath > 5 then
        nav.lastPath = now()
        local ok, path = pcall(function()
            local result = PathfindingService:CreatePath({AgentCanJump = true, WaypointSpacing = 10})
            result:ComputeAsync(root.Position, nav.goal)
            return result
        end)
        if not hub.alive then return end
        if ok and path.Status == Enum.PathStatus.Success then
            nav.path = path:GetWaypoints()
            nav.index = (#nav.path > 1) and 2 or 1
        else
            nav.path = nil
        end
    end
    local nextPos = nav.goal
    if nav.path then
        while nav.index <= #nav.path do
            local step = nav.path[nav.index]
            if (root.Position - step.Position).Magnitude <= 7 then
                nav.index = nav.index + 1
            else
                nextPos = step.Position
                if step.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
                break
            end
        end
    end
    if throttle("navSend", 1.5) then
        humanoid:MoveTo(nextPos)
        hub.status = "Đang tới " .. nav.label .. " · " .. formatDist(dist)
    end
end

local function equipTool()
    local char, hum = charParts()
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not hum or not backpack or not char then return nil end
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then return equipped end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            hum:EquipTool(item)
            return item
        end
    end
    return nil
end
local function farmTick()
    if not hub.settings.FarmAssist then return end
    local q = questInfo()
    if not q.active then
        hub.status = "Farm: cần nhận quest trong game trước"
        return
    end
    if not q.target then
        hub.status = "Farm: chưa đọc được loại quái từ bảng nhiệm vụ"
        return
    end
    local target, count = findEnemy(q.target)
    local _, hum, root = charParts()
    if not root or not hum or hum.Health <= 0 then
        hub.status = "Farm: chờ nhân vật hồi sinh"
        return
    end
    if target then
        local mobRoot = rootOf(target)
        local dist = (root.Position - mobRoot.Position).Magnitude
        if dist > 14 then
            if setGoal(mobRoot.Position, q.target) then
                hub.status = "Farm: theo " .. q.target .. " · " .. formatDist(dist)
            else
                hub.status = "Farm: đường đi bị kẹt, tạm nghỉ 45 giây"
            end
        else
            -- Never attack through undocumented RegisterHit/RegisterAttack argument formats.
            if hub.moving.goal then clearNavigation() end
            if hub.settings.AutoEquip then safe("Equip tool", equipTool) end
            if hub.settings.ToolActivate and throttle("toolActivate", 0.6) then
                local char = player.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if tool then safe("Tool.Activate", function() tool:Activate() end) end
            end
            hub.status = "Farm: ở gần " .. q.target .. " (" .. tostring(count) .. ")"
        end
        return
    end
    local fallback = legacySpots[q.target]
    if fallback then
        if setGoal(fallback, q.target .. " (vị trí tham khảo)") then
            hub.status = "Chưa thấy " .. q.target .. " trong Workspace.Enemies; tới vùng tham khảo"
        else
            hub.status = "Farm: không thể đi tới vùng tham khảo, tạm nghỉ 45 giây"
        end
    else
        hub.status = "Không thấy quái " .. q.target .. " đang được tải trong client"
    end
end

local function localFruit(instance)
    if not instance or not instance:IsA("Tool") then return false end
    return has(instance.Name, "fruit") or has(instance.Name, "blox fruit")
end
local function chestRoot(instance)
    local n = lower(instance.Name)
    if not string.match(n, "^chest[0-9]*$") and n ~= "chest" then return nil end
    return rootOf(instance)
end
local function nearestWorldItem(test, maxItems)
    local _, _, playerRoot = charParts()
    if not playerRoot then return nil, nil end
    local best, bestPos, bestDist = nil, nil, math.huge
    local descendants = Workspace:GetDescendants()
    local limit = math.min(#descendants, maxItems or 14000)
    for i = 1, limit do
        local instance = descendants[i]
        if test(instance) then
            local part = rootOf(instance)
            if part then
                local dist = (playerRoot.Position - part.Position).Magnitude
                if dist < bestDist then
                    best, bestPos, bestDist = instance, part.Position, dist
                end
            end
        end
    end
    return best, bestPos, bestDist
end

local function addOverlay(target, root, kind, label, color)
    if not target or not root or not target.Parent then return end
    local record = hub.overlays[target]
    if not record then
        local ok, highlight = pcall(function()
            local h = Instance.new("Highlight")
            h.Name = "AH_Highlight"
            local highlightHost = target:IsA("Model") and target or root
            h.Adornee = highlightHost
            h.FillColor = color
            h.OutlineColor = color
            h.FillTransparency = 0.78
            h.OutlineTransparency = 0.12
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = highlightHost
            return h
        end)
        if not ok then return end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "AH_Name"
        billboard.Adornee = root
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.fromOffset(180, 34)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
        billboard.Parent = hub.gui
        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 0.35
        text.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        text.TextColor3 = color
        text.TextStrokeTransparency = 0.5
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        text.Size = UDim2.fromScale(1, 1)
        text.Parent = billboard
        record = { highlight = highlight, billboard = billboard, text = text }
        hub.overlays[target] = record
    end
    record.seen = now()
    local _, _, ourRoot = charParts()
    local dist = ourRoot and (root.Position - ourRoot.Position).Magnitude or nil
    record.text.Text = label .. "  " .. (dist and string.format("%.0fm", dist) or "")
    record.billboard.Enabled = hub.settings.ShowNames
end
local function clearOverlay(target, record)
    if record.highlight then pcall(function() record.highlight:Destroy() end) end
    if record.billboard then pcall(function() record.billboard:Destroy() end) end
    hub.overlays[target] = nil
end
local function espTick()
    local cfg = hub.settings
    local add = addOverlay
    if cfg.ESPPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local part = rootOf(p.Character)
                if part then add(p.Character, part, "P", p.DisplayName, Color3.fromRGB(190, 133, 255)) end
            end
        end
    end
    if cfg.ESPEnemies then
        local folder = Workspace:FindFirstChild("Enemies")
        if folder then
            local n = 0
            for _, mob in ipairs(folder:GetChildren()) do
                if modelAlive(mob) then
                    n = n + 1
                    if n > 110 then break end
                    add(mob, rootOf(mob), "M", mob.Name, Color3.fromRGB(245, 95, 117))
                end
            end
        end
    end
    if cfg.ESPNPCs then
        local folder = Workspace:FindFirstChild("NPCs")
        if folder then
            for _, npc in ipairs(folder:GetChildren()) do
                local part = rootOf(npc)
                if part then add(npc, part, "N", npc.Name, Color3.fromRGB(96, 216, 235)) end
            end
        end
    end
    if cfg.ESPFruits then
        local n = 0
        for _, item in ipairs(Workspace:GetChildren()) do
            if localFruit(item) then
                local part = rootOf(item)
                if part then
                    n = n + 1
                    if n > 75 then break end
                    add(item, part, "F", item.Name, Color3.fromRGB(166, 255, 153))
                end
            end
        end
    end
    if cfg.ESPChests and throttle("chestScan", 8) then
        local n = 0
        for _, instance in ipairs(Workspace:GetDescendants()) do
            local part = chestRoot(instance)
            if part then
                n = n + 1
                if n > 100 then break end
                add(instance, part, "C", instance.Name, Color3.fromRGB(255, 200, 90))
            end
        end
    end
    local checkTime = now()
    for target, record in pairs(hub.overlays) do
        local limit = cfg.ESPChests and 10 or 5
        if not target.Parent or checkTime - (record.seen or 0) > limit then
            clearOverlay(target, record)
        end
    end
end

local originalLighting = {
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    Brightness = Lighting.Brightness,
}
local originalCamera = player.CameraMaxZoomDistance
local originalEffects = {}
local function setFog(disabled)
    Lighting.FogEnd = disabled and 100000 or originalLighting.FogEnd
    Lighting.FogStart = disabled and 0 or originalLighting.FogStart
end
local function lowGraphics(enabled)
    Lighting.GlobalShadows = enabled and false or originalLighting.GlobalShadows
    if enabled then
        local changed = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                if originalEffects[obj] == nil then originalEffects[obj] = obj.Enabled end
                obj.Enabled = false
                changed = changed + 1
                if changed >= 400 then break end
            end
        end
    else
        for obj, value in pairs(originalEffects) do
            if obj.Parent then pcall(function() obj.Enabled = value end) end
            originalEffects[obj] = nil
        end
    end
end
local function zoom(enabled)
    player.CameraMaxZoomDistance = enabled and 300 or originalCamera
end
local function remoteExists(segments, class)
    local current = ReplicatedStorage
    for _, part in ipairs(segments) do
        if not current then return false end
        current = current:FindFirstChild(part)
    end
    return current ~= nil and current:IsA(class)
end
local remoteList = {
    {"Quest data", {"Remotes", "QuestUpdate"}, "RemoteEvent"},
    {"Common commands", {"Remotes", "CommF_"}, "RemoteFunction"},
    {"Race abilities", {"Remotes", "CommE"}, "RemoteEvent"},
    {"Attack", {"Modules", "Net", "RE/RegisterAttack"}, "RemoteEvent"},
    {"Hit", {"Modules", "Net", "RE/RegisterHit"}, "RemoteEvent"},
    {"Dragon Hunter", {"Modules", "Net", "RF/DragonHunter"}, "RemoteFunction"},
    {"Berry claim", {"Modules", "Net", "RF/ClaimBerry"}, "RemoteFunction"},
    {"Dungeon", {"Modules", "Net", "RF/DungeonNPCNetworkFunction"}, "RemoteFunction"},
}

-- UI. No imported library, HTTP requests, or hidden remote invocations.
local host = player:WaitForChild("PlayerGui", 10)
if type(gethui) == "function" then
    local ok, gui = pcall(gethui)
    if ok and gui then host = gui end
end
if not host then host = player:FindFirstChild("PlayerGui") end
if not host then warn("[AMETHYST HORIZON] PlayerGui is unavailable"); return end
local existing = host:FindFirstChild(GuiName)
if existing then existing:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = GuiName
screen.IgnoreGuiInset = true
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = host
hub.gui = screen

local function corner(obj, pixels)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, pixels or 9)
    c.Parent = obj
end
local function makeText(parent, text, size, color, height, bold)
    local obj = Instance.new("TextLabel")
    obj.BackgroundTransparency = 1
    obj.Size = UDim2.new(1, 0, 0, height or 25)
    obj.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    obj.TextColor3 = color or Color3.new(1, 1, 1)
    obj.TextSize = size or 13
    obj.Text = text
    obj.TextXAlignment = Enum.TextXAlignment.Left
    obj.TextWrapped = true
    obj.Parent = parent
    return obj
end
local theme = {
    background = Color3.fromRGB(17, 14, 27),
    panel = Color3.fromRGB(27, 23, 42),
    panel2 = Color3.fromRGB(38, 32, 54),
    purple = Color3.fromRGB(169, 122, 255),
    gold = Color3.fromRGB(255, 209, 121),
    muted = Color3.fromRGB(180, 173, 197),
    green = Color3.fromRGB(137, 235, 171),
    red = Color3.fromRGB(245, 112, 130),
}
local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.fromOffset(700, 470)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = theme.background
window.BorderSizePixel = 0
window.Parent = screen
corner(window, 14)
local border = Instance.new("UIStroke")
border.Color = theme.purple
border.Transparency = 0.3
border.Thickness = 2
border.Parent = window
local scale = Instance.new("UIScale")
scale.Parent = window

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 49)
header.BackgroundColor3 = theme.panel
header.BorderSizePixel = 0
header.Parent = window
corner(header, 14)
local heading = makeText(header, "✦  AMETHYST HORIZON   |   SEA 3", 18, theme.gold, 43, true)
heading.Position = UDim2.fromOffset(16, 2)
heading.Size = UDim2.new(1, -120, 0, 43)

local function makeButton(parent, label, size, position, callback)
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Size = size or UDim2.new(1, 0, 0, 36)
    if position then button.Position = position end
    button.BackgroundColor3 = theme.panel2
    button.TextColor3 = theme.gold
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.TextWrapped = true
    button.Text = label
    button.AutoButtonColor = true
    button.BorderSizePixel = 0
    button.Parent = parent
    corner(button, 8)
    track(button.Activated, function()
        safe("UI " .. label, callback)
    end)
    return button
end
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 142, 1, -62)
sidebar.Position = UDim2.fromOffset(8, 55)
sidebar.BackgroundColor3 = theme.panel
sidebar.BorderSizePixel = 0
sidebar.Parent = window
corner(sidebar, 9)
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 7)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = sidebar
local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 9)
sidePad.PaddingLeft = UDim.new(0, 7)
sidePad.PaddingRight = UDim.new(0, 7)
sidePad.Parent = sidebar

local surface = Instance.new("Frame")
surface.Size = UDim2.new(1, -167, 1, -62)
surface.Position = UDim2.fromOffset(159, 55)
surface.BackgroundColor3 = theme.panel
surface.BorderSizePixel = 0
surface.Parent = window
corner(surface, 9)

local tabButtons = {}
local tabs = {}
local function selectTab(name)
    for tabName, page in pairs(tabs) do
        page.Visible = (tabName == name)
        local btn = tabButtons[tabName]
        btn.BackgroundColor3 = (tabName == name) and theme.purple or theme.panel2
        btn.TextColor3 = (tabName == name) and theme.background or theme.gold
    end
end
local function tab(name, title)
    local button = makeButton(sidebar, title, UDim2.new(1, 0, 0, 36), nil, function() selectTab(name) end)
    tabButtons[name] = button
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = theme.purple
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.Visible = false
    page.Parent = surface
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 13)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 13)
    padding.PaddingRight = UDim.new(0, 13)
    padding.Parent = page
    tabs[name] = page
    return page
end
local function section(page, text)
    return makeText(page, text, 15, theme.purple, 26, true)
end
local function explain(page, text, height)
    local label = makeText(page, text, 12, theme.muted, height or 40, false)
    label.TextWrapped = true
    return label
end
local function action(page, text, callback)
    return makeButton(page, text, UDim2.new(1, 0, 0, 36), nil, callback)
end
local function toggle(page, key, text, hint)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, hint and 57 or 42)
    row.BackgroundColor3 = theme.panel2
    row.BorderSizePixel = 0
    row.Parent = page
    corner(row, 8)
    local title = makeText(row, text, 13, Color3.new(1, 1, 1), 20, true)
    title.Position = UDim2.fromOffset(10, hint and 5 or 10)
    title.Size = UDim2.new(1, -97, 0, 20)
    if hint then
        local desc = makeText(row, hint, 11, theme.muted, 25)
        desc.Position = UDim2.fromOffset(10, 26)
        desc.Size = UDim2.new(1, -90, 0, 25)
    end
    local b
    b = makeButton(row, "OFF", UDim2.fromOffset(65, 29), UDim2.new(1, -75, 0.5, -14), function()
        hub.settings[key] = not hub.settings[key]
        if key == "FarmAssist" and not hub.settings[key] then clearNavigation("Tắt hỗ trợ Farm") end
        if key == "ClearFog" then safe("Fog", setFog, hub.settings[key]) end
        if key == "LowGraphics" then safe("Low graphics", lowGraphics, hub.settings[key]) end
        if key == "MaxZoom" then safe("Zoom", zoom, hub.settings[key]) end
        if key == "ESPChests" then hub.timers.chestScan = 0 end
        b.Text = hub.settings[key] and "ON" or "OFF"
        b.TextColor3 = hub.settings[key] and theme.green or theme.gold
        appendLog("INFO", text .. " = " .. tostring(hub.settings[key]))
    end)
    b.Text = hub.settings[key] and "ON" or "OFF"
    hub.toggleButtons = hub.toggleButtons or {}
    hub.toggleButtons[key] = b
    return row
end

local home = tab("Home", "⌂  Tổng quan")
local farm = tab("Farm", "⚔  Farm")
local esp = tab("ESP", "◈  ESP")
local npc = tab("NPC", "◎  NPC")
local util = tab("Utilities", "✦  Tiện ích")
local diag = tab("Diagnostics", "☷  Chẩn đoán")

section(home, "Tình trạng nhân vật")
local stateLevel = explain(home, "Cấp: ...", 22)
local stateQuest = explain(home, "Quest: ...", 56)
local stateFarm = explain(home, "Hành động: ...", 52)
section(home, "Nguyên tắc hoạt động")
explain(home, "Đây là hub hỗ trợ client độc lập. Không tự gọi Remote không rõ tham số. Farm cần nhận Quest trước; di chuyển bằng Humanoid + Pathfinding, không ép CFrame vượt anti-cheat.", 73)
action(home, "Hiện trạng thái Quest", function()
    local q = questInfo()
    notify("Quest: " .. (q.target or "chưa nhận diện") .. " | " .. q.text:sub(1, 85))
end)

section(farm, "Farm theo Quest đang hiển thị")
toggle(farm, "FarmAssist", "Hỗ trợ Farm (BETA)", "Tự tìm quái, di chuyển tới gần; không tự nhận nhiệm vụ")
toggle(farm, "AutoEquip", "Tự trang bị Tool", "Lấy Tool đầu tiên trong Backpack nếu chưa cầm")
toggle(farm, "ToolActivate", "Dùng Tool khi tới gần (BETA)", "Gọi Tool:Activate(); sát thương tùy hệ thống game")
action(farm, "DỪNG DI CHUYỂN", function() clearNavigation("Dừng di chuyển thủ công") end)
section(farm, "Tìm quái đang được tải")
local selectedMobLabel = explain(farm, "Chọn: " .. hub.selectedMob, 24)
action(farm, "Quái tiếp theo ▶", function()
    local idx = 1
    for i, name in ipairs(knownMobs) do
        if name == hub.selectedMob then idx = i; break end
    end
    hub.selectedMob = knownMobs[(idx % #knownMobs) + 1]
    selectedMobLabel.Text = "Chọn: " .. hub.selectedMob
end)
action(farm, "Tìm quái gần nhất", function()
    local mob, count = findEnemy(hub.selectedMob)
    if mob then
        local _, _, root = charParts()
        local part = rootOf(mob)
        local distance = root and (root.Position - part.Position).Magnitude or nil
        notify("Thấy " .. tostring(count) .. " " .. hub.selectedMob .. " | gần nhất " .. formatDist(distance))
        setGoal(part.Position, hub.selectedMob)
    else
        notify("Không thấy " .. hub.selectedMob .. " đang được tải")
    end
end)

section(farm, "Dẫn đường tới vật phẩm")
action(farm, "Tới trái gần nhất", function()
    local item, position, distance = nearestWorldItem(localFruit, 12000)
    if not item then notify("Không thấy trái dạng Tool đang được tải") return end
    notify("Trái: " .. item.Name .. " | " .. formatDist(distance))
    setGoal(position, item.Name)
end)
action(farm, "Tới rương gần nhất", function()
    local item, position, distance = nearestWorldItem(function(instance)
        return chestRoot(instance) ~= nil
    end, 14000)
    if not item then notify("Không thấy rương đang được tải") return end
    notify("Rương: " .. item.Name .. " | " .. formatDist(distance))
    setGoal(position, item.Name)
end)

section(esp, "Hiển thị đối tượng")
toggle(esp, "ESPPlayers", "Người chơi")
toggle(esp, "ESPEnemies", "Quái & Boss")
toggle(esp, "ESPFruits", "Trái rơi (Tool)")
toggle(esp, "ESPNPCs", "NPC")
toggle(esp, "ESPChests", "Rương")
toggle(esp, "ShowNames", "Hiện tên và khoảng cách")
explain(esp, "ESP chỉ hiện những đối tượng đã tải về client. Không đọc vị trí trên các đảo chưa stream.", 42)

section(npc, "14 NPC từ dữ liệu quét Sea 3")
local npcLabel = explain(npc, "Đang chọn: " .. NPCs[hub.selectedNPC][1], 34)
action(npc, "NPC tiếp theo ▶", function()
    hub.selectedNPC = (hub.selectedNPC % #NPCs) + 1
    npcLabel.Text = "Đang chọn: " .. NPCs[hub.selectedNPC][1]
end)
action(npc, "Xem vị trí NPC", function()
    local rec = NPCs[hub.selectedNPC]
    local position, live = snapshotNPC(rec)
    local _, _, root = charParts()
    local distance = root and (root.Position - position).Magnitude or nil
    notify(rec[1] .. " | " .. (live and "NPC đang tải" or "tọa độ từ scan") .. " | " .. formatDist(distance))
end)
action(npc, "Đi tới NPC đã chọn", function()
    local rec = NPCs[hub.selectedNPC]
    local pos, live = snapshotNPC(rec)
    if not live then
        notify("NPC chưa stream; dùng tọa độ từ file quét (có thể cũ)")
    end
    setGoal(pos, rec[1])
end)
explain(npc, "Khoảng cách quá xa hoặc có biển/vật cản thì Humanoid có thể không tới được. Hub sẽ báo kẹt thay vì giả vờ hoàn thành.", 56)

section(util, "Hiệu năng và góc nhìn")
toggle(util, "ClearFog", "Tắt sương mù", "Có hoàn tác khi tắt hub")
toggle(util, "LowGraphics", "Giảm hiệu ứng", "Giới hạn 400 hiệu ứng; có hoàn tác")
toggle(util, "MaxZoom", "Mở rộng Camera Zoom", "Có hoàn tác khi tắt hub")
action(util, "Dừng mọi chuyển động", function()
    hub.settings.FarmAssist = false
    if hub.toggleButtons and hub.toggleButtons.FarmAssist then
        hub.toggleButtons.FarmAssist.Text = "OFF"
        hub.toggleButtons.FarmAssist.TextColor3 = theme.gold
    end
    clearNavigation("Dừng tất cả chuyển động")
    notify("Đã dừng; công tắc Farm đã tắt")
end)
action(util, "Vào lại server hiện tại", function()
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end)
    if not ok then notify("Không thể vào lại: " .. tostring(err)) end
end)

section(diag, "Chẩn đoán — không gửi lệnh Remote")
local remoteStatus = explain(diag, "Đang kiểm tra Remote...", 165)
local logStatus = explain(diag, "Chưa có log", 158)
action(diag, "Kiểm tra lại Remote", function()
    local active = 0
    for _, spec in ipairs(remoteList) do
        if remoteExists(spec[2], spec[3]) then active = active + 1 end
    end
    notify("Remote đúng loại: " .. active .. "/" .. #remoteList .. " (không gọi thử lên server)")
end)
action(diag, "Kiểm tra Quest & quái", function()
    local q = questInfo()
    local mob, count = findEnemy(q.target or "")
    notify("Quest: " .. tostring(q.target) .. " | quái tải: " .. count .. " | mục tiêu: " .. (mob and mob.Name or "không có"))
end)
explain(diag, "Một Remote xuất hiện trong ReplicatedStorage không có nghĩa client biết cách gọi. Scan không chứa chữ ký tham số và server có thể từ chối.", 58)

local hide = makeButton(header, "—", UDim2.fromOffset(33, 28), UDim2.new(1, -80, 0, 10), function() window.Visible = false end)
local close = makeButton(header, "×", UDim2.fromOffset(33, 28), UDim2.new(1, -40, 0, 10), function()
    if type(env.AmethystHorizonShutdown) == "function" then env.AmethystHorizonShutdown() end
end)
close.TextColor3 = theme.red
local launcher = makeButton(screen, "✦ AMETHYST", UDim2.fromOffset(127, 39), UDim2.new(0, 15, 0.28, 0), function()
    window.Visible = not window.Visible
end)
launcher.BackgroundColor3 = theme.purple
launcher.TextColor3 = theme.background

local function drag(frame, handle)
    local dragging, dragStart, initial, observedInput = false, nil, nil, nil
    track(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            initial = frame.Position
            observedInput = input
        end
    end)
    track(handle.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            observedInput = input
        end
    end)
    track(UserInputService.InputChanged, function(input)
        if dragging and input == observedInput then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(initial.X.Scale, initial.X.Offset + d.X,
                initial.Y.Scale, initial.Y.Offset + d.Y)
        end
    end)
    track(UserInputService.InputEnded, function(input)
        if input == observedInput or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end
drag(window, header)
drag(launcher, launcher)
local function resize()
    local camera = Workspace.CurrentCamera
    local size = camera and camera.ViewportSize or Vector2.new(900, 600)
    scale.Scale = math.clamp(math.min((size.X - 22) / 700, (size.Y - 30) / 470), 0.52, 1)
end
resize()
track(Workspace:GetPropertyChangedSignal("CurrentCamera"), resize)
track(RunService.RenderStepped, function()
    -- A viewport may change during mobile rotation, but UI rescaling is cheap.
    if throttle("scale", 1.3) then safe("UI viewport", resize) end
end)
track(UserInputService.InputBegan, function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        window.Visible = not window.Visible
    end
end)

local function worker(name, interval, fn)
    task.spawn(function()
        while hub.alive do
            safe(name, fn)
            task.wait(interval)
        end
    end)
end
worker("Quest / Farm", 0.65, farmTick)
worker("Movement", 0.6, navigationTick)
worker("ESP", 2.0, espTick)
worker("Dashboard", 1.25, function()
    local q = questInfo()
    stateLevel.Text = "Cấp: " .. getLevel() .. "    |    PlaceId: " .. tostring(game.PlaceId)
    stateQuest.Text = "Quest: " .. (q.target or "không xác định") .. "\n" .. (q.text or ""):sub(1, 115)
    stateFarm.Text = "Hành động: " .. (hub.status or "Đang theo dõi")
end)
worker("Diagnostics", 4.5, function()
    local status = {}
    local found = 0
    for _, spec in ipairs(remoteList) do
        local yes = remoteExists(spec[2], spec[3])
        if yes then found = found + 1 end
        status[#status + 1] = (yes and "● " or "○ ") .. spec[1]
    end
    remoteStatus.Text = string.format("Remote đúng loại: %d/%d\n", found, #remoteList) .. table.concat(status, "   ")
    logStatus.Text = (#hub.logs == 0) and "Chưa có log" or table.concat(hub.logs, "\n"):sub(1, 720)
end)

function hub.Shutdown()
    if not hub.alive then return end
    hub.alive = false
    hub.settings.FarmAssist = false
    clearNavigation()
    for _, entry in pairs(hub.overlays) do
        if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
        if entry.billboard then pcall(function() entry.billboard:Destroy() end) end
    end
    hub.overlays = {}
    for _, conn in ipairs(hub.connections) do pcall(function() conn:Disconnect() end) end
    hub.connections = {}
    pcall(function() setFog(false) end)
    pcall(function() lowGraphics(false) end)
    pcall(function() zoom(false) end)
    pcall(function() screen:Destroy() end)
    if env.AmethystHorizonShutdown == hub.Shutdown then
        env.AmethystHorizonShutdown = nil
    end
    if env.AmethystHorizonRuntime == hub then env.AmethystHorizonRuntime = nil end
end
-- Assign the exact function object so old copies can shut down on reinjection.
env.AmethystHorizonShutdown = hub.Shutdown
env.AmethystHorizonRuntime = hub
hub.status = "Sẵn sàng; cần nhận Quest trước khi Farm"
selectTab("Home")
notify("Đã khởi tạo Amethyst Horizon 1.0 — mặc định không tự động Farm")
