--[[
 DRAGON HUB v2.1 | Blox Fruits | Farm Level quest detection repair
 Source references: Dragon hub.txt and DatThgV2.restored.lua / GD3 feature index.
 IMPORTANT: Not runtime-tested in Roblox; remote commands and game data may change.
 This file does not evaluate/download the VM from DatThg, or load remote code.
 All automation toggles start OFF on every new load.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local environment = _G
if type(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then environment = env end
end

-- Shut down an earlier v2 instance before creating any new listeners/tasks.
local oldRuntime = environment.DragonHubRuntimeV2
if type(oldRuntime) == "table" and type(oldRuntime.Shutdown) == "function" then
    pcall(function() oldRuntime:Shutdown("reload") end)
end

local defaults = {
    FarmMode = "Off", -- Off | Level | Selected Mob | Nearest | Boss | All Boss | Bone | Chest
    SelectedMob = "Grand Devotee",
    SelectedBoss = "Longma",
    WeaponType = "Melee",
    FarmDistance = 8,
    TweenSpeed = 280,
    BringMob = false, -- local-only changes; not guaranteed to replicate
    AttackAura = false,
    AutoBuso = false,
    AutoRaceV3 = false,
    AutoAwakening = false,
    AutoDragonHunter = false,
    AutoDragonEmber = false,
    AutoKitsunePray = false,
    AutoCollectBerries = false,
    AutoGrabFruits = false,
    AutoFirePrompts = false,
    AutoStatsMelee = false,
    AutoStatsDefense = false,
    AutoStatsSword = false,
    AutoStatsGun = false,
    AutoStatsFruit = false,
    AutoStoreFruit = false,
    FruitSniper = false,
    SniperFruit = "Dough",
    SniperMaxPrice = 5000000,
    EspPlayers = false,
    EspMobs = false,
    EspFruits = false,
    EspChests = false,
    EspIslands = false,
    EspMirage = false,
    EspBerries = false,
    NoClip = false,
    FPSBoost = false,
    RemoveFog = false,
    MaxZoom = false,
    WalkSpeed = 16,
    JumpPower = 50,
    MovementOverride = false,
}
local config = {}
local previous = environment.DragonHub
for key, value in pairs(defaults) do
    if type(previous) == "table" and previous[key] ~= nil then
        config[key] = previous[key]
    else
        config[key] = value
    end
end
-- Do not auto-start old tasks/remote calls when a script is reloaded.
for key, value in pairs(defaults) do
    if type(value) == "boolean" then config[key] = false end
end
config.FarmMode = "Off"
environment.DragonHub = config

local Runtime = {
    active = true,
    connections = {},
    highlights = {},
    collisionOriginal = setmetatable({}, { __mode = "k" }),
    visualOriginal = setmetatable({}, { __mode = "k" }),
    fogOriginal = nil,
    zoomOriginal = nil,
    cooldowns = {},
    lastError = {},
    tween = nil,
    tweenEnded = nil,
    target = nil,
    startedAt = 0,
    motionProbe = nil,
    questPending = nil,
    lastQuestTrace = nil,
    status = nil,
    gui = nil,
}
environment.DragonHubRuntimeV2 = Runtime

local function Clock() return os.clock() end
local function ReportError(where, err)
    local message = tostring(err)
    local key = tostring(where) .. ":" .. message
    if Clock() - (Runtime.lastError[key] or -100) < 8 then return end
    Runtime.lastError[key] = Clock()
    warn("[Dragon Hub v2.1] " .. tostring(where) .. ": " .. message)
    if Runtime.status and Runtime.status.Parent then
        Runtime.status.Text = "Lỗi " .. tostring(where) .. " (xem Output)"
    end
end
local function Safely(where, fn, ...)
    local ok, a, b = pcall(fn, ...)
    if not ok then ReportError(where, a) end
    return ok, a, b
end
local function Info(message)
    if Runtime.status and Runtime.status.Parent then Runtime.status.Text = tostring(message) end
    print("[Dragon Hub v2.1] " .. tostring(message))
end
local function Notify(title, message)
    Info(title .. ": " .. message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Dragon Hub v2.1 | " .. title,
            Text = tostring(message), Duration = 4,
        })
    end)
end
local function Connect(signal, handler)
    local connection = signal:Connect(handler)
    table.insert(Runtime.connections, connection)
    return connection
end
local function Throttle(key, interval)
    local now = Clock()
    if (Runtime.cooldowns[key] or -10000) + interval > now then return false end
    Runtime.cooldowns[key] = now
    return true
end

local function GetCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return nil end
    return char, humanoid, root
end
local function Remote(name)
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    return folder and folder:FindFirstChild(name)
end
local function NetRemote(name)
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")
    return net and net:FindFirstChild(name)
end
local function Invoke(remote, key, gap, ...)
    if not remote or not remote:IsA("RemoteFunction") then return false, "remote unavailable" end
    if not Throttle("rf:" .. key, gap or 1) then return false, "cooldown" end
    return Safely("Invoke:" .. key, function(...) return remote:InvokeServer(...) end, ...)
end
local function Fire(remote, key, gap, ...)
    if not remote or not remote:IsA("RemoteEvent") then return false, "remote unavailable" end
    if not Throttle("re:" .. key, gap or 1) then return false, "cooldown" end
    return Safely("Fire:" .. key, function(...) remote:FireServer(...); return true end, ...)
end
local function Comm(action, gap, ...)
    return Invoke(Remote("CommF_"), "CommF:" .. tostring(action), gap or 1, action, ...)
end

-- Tween manager: one owner, replace stale targets, stop on respawn/reload.
local function StopMovement()
    Runtime.target = nil
    Runtime.startedAt = 0
    Runtime.motionProbe = nil
    local current = Runtime.tween
    Runtime.tween = nil
    if Runtime.tweenEnded then
        Runtime.tweenEnded:Disconnect()
        Runtime.tweenEnded = nil
    end
    if current then pcall(function() current:Cancel() end) end
end
local function MoveTo(cf)
    if typeof(cf) ~= "CFrame" or not Runtime.active then return false end
    local _, _, root = GetCharacter()
    if not root then return false end
    local dist = (root.Position - cf.Position).Magnitude
    if dist < 6 then
        StopMovement()
        return true
    end
    if Runtime.tween and Runtime.target then
        local changed = (Runtime.target.Position - cf.Position).Magnitude
        -- Old v2 restarted the same tween after 3s; distant targets could never finish.
        if changed < 10 and Clock() - Runtime.startedAt < 15 then
            local probe = Runtime.motionProbe
            if probe and Clock() - probe.at >= 2.5 then
                local madeProgress = (root.Position - probe.position).Magnitude
                if madeProgress < 2 and dist > 25 then
                    if Throttle("stalledTween", 12) then
                        Info("Tween đã bắt đầu nhưng nhân vật không đi. Đang thử Humanoid:MoveTo; nếu tiếp tục đứng yên, máy chủ có thể chặn di chuyển.")
                    end
                    StopMovement()
                    local _, humanoid = GetCharacter()
                    if humanoid then Safely("WalkFallback", function() humanoid:MoveTo(cf.Position) end) end
                    return false
                end
                Runtime.motionProbe = { at = Clock(), position = root.Position }
            end
            return true
        end
        if Clock() - Runtime.startedAt < 0.3 then return false end
    end
    StopMovement()
    local speed = math.clamp(tonumber(config.TweenSpeed) or 280, 60, 450)
    local info = TweenInfo.new(math.clamp(dist / speed, 0.15, 15), Enum.EasingStyle.Linear)
    local ok, tween = Safely("TweenCreate", function()
        return TweenService:Create(root, info, { CFrame = cf })
    end)
    if not ok or not tween then return false end
    Runtime.tween = tween
    Runtime.target = cf
    Runtime.startedAt = Clock()
    Runtime.motionProbe = { at = Clock(), position = root.Position }
    Runtime.tweenEnded = tween.Completed:Connect(function()
        if Runtime.tween == tween then
            Runtime.tween = nil
            Runtime.target = nil
            if Runtime.tweenEnded then
                Runtime.tweenEnded:Disconnect()
                Runtime.tweenEnded = nil
            end
        end
    end)
    local started = Safely("TweenPlay", function() tween:Play() end)
    if not started then
        StopMovement()
        return false
    end
    return true
end

local function GetEquipped()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Tool")
end
local function EquipWeapon()
    local char, hum = GetCharacter()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end
    local chosen = config.WeaponType
    local equipped = GetEquipped()
    if equipped then
        local typ = equipped:GetAttribute("WeaponType") or equipped.ToolTip
        if typ == chosen or (chosen == "Any" and equipped) then return end
    end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local kind = tool:GetAttribute("WeaponType") or tool.ToolTip
            if chosen == "Any" or kind == chosen or (chosen == "Fruit" and kind == "Demon Fruit") then
                Safely("EquipTool", function() hum:EquipTool(tool) end)
                return
            end
        end
    end
end
local function Attack()
    local tool = GetEquipped()
    if tool and tool.Enabled then
        Safely("ToolActivate", function() tool:Activate() end)
    end
end
local function Buso()
    if not config.AutoBuso or not Throttle("busoCheck", 9) then return end
    local char = GetCharacter()
    if char and not char:FindFirstChild("HasBuso") and not char:GetAttribute("BusoEnabled") then
        Comm("Buso", 9)
    end
end
local function ValidEnemy(model)
    if not model or not model:IsA("Model") then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return nil end
    return root
end
local function FindEnemy(matcher)
    local enemies = Workspace:FindFirstChild("Enemies")
    local _, _, root = GetCharacter()
    if not enemies or not root then return nil end
    local best, bestDistance
    for _, enemy in ipairs(enemies:GetChildren()) do
        local enemyRoot = ValidEnemy(enemy)
        if enemyRoot and matcher(enemy.Name) then
            local distance = (enemyRoot.Position - root.Position).Magnitude
            if not bestDistance or distance < bestDistance then
                best, bestDistance = enemy, distance
            end
        end
    end
    return best
end
local function BringMobs(name, targetPosition)
    -- This is a local-only best-effort operation, not a guaranteed server change.
    if not config.BringMob then return end
    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then return end
    local moved = 0
    for _, mob in ipairs(folder:GetChildren()) do
        local root = ValidEnemy(mob)
        if root and mob.Name == name and (root.Position - targetPosition).Magnitude < 120 then
            Safely("BringMob", function() root.CFrame = CFrame.new(targetPosition) end)
            moved = moved + 1
            if moved >= 8 then break end
        end
    end
end
local function Engage(enemy)
    local root = ValidEnemy(enemy)
    if not root then return false end
    Buso()
    EquipWeapon()
    MoveTo(root.CFrame * CFrame.new(0, tonumber(config.FarmDistance) or 25, 0))
    if config.BringMob then BringMobs(enemy.Name, root.Position) end
    return true
end

-- Original Sea-3 quest records retained from Dragon hub.txt; unverified in 2026 game build.
local LevelQuests = {
    { min = 2550, id = "TikiQuest3", tier = 2, mob = "Skull Slayer", quest = CFrame.new(-16661.89, 105.28, 1576.69), camp = CFrame.new(-16885.20, 114.12, 1627.94) },
    { min = 2525, id = "TikiQuest2", tier = 2, mob = "Isle Champion", quest = CFrame.new(-16539.07, 55.68, 1051.57), camp = CFrame.new(-16641.67, 235.78, 1031.28) },
    { min = 2450, id = "TikiQuest1", tier = 1, mob = "Isle Outlaw", quest = CFrame.new(-16547.74, 61.13, -173.41), camp = CFrame.new(-16442.81, 116.13, -264.46) },
    { min = 2300, id = "ChocQuest1", tier = 1, mob = "Cocoa Warrior", quest = CFrame.new(233.22, 29.87, -12201.23), camp = CFrame.new(-21.55, 80.57, -12352.38) },
    { min = 1500, id = "PiratePortQuest", tier = 1, mob = "Pirate Millionaire", quest = CFrame.new(-290.07, 42.90, 5581.58), camp = CFrame.new(-245.99, 47.30, 5584.10) },
}
local MobPositions = {
    ["Grand Devotee"] = CFrame.new(9620.5, -1994.2, 9871.7),
    ["High Disciple"] = CFrame.new(9778.4, -1994.3, 9877.0),
    ["Ocean Prophet"] = CFrame.new(11129.8, -2008.9, 10051.5),
    ["Jack o' Lantern"] = CFrame.new(-12486.4, 334.6, -7440.8),
    ["Mythological Pirate"] = CFrame.new(-13456.0, 468.5, -7040.0),
    ["Forest Pirate"] = CFrame.new(-13345.5, 331.3, -7630.8),
}
local BossPositions = {
    Longma = CFrame.new(-10156.2, 331.6, -9445.9),
    Stone = CFrame.new(-1109.9, 51.6, 6811.7),
    Urban = CFrame.new(4486.7, 1208.3, -8.9),
    indra = CFrame.new(-12483.6, 332.1, -7769.2),
}
local BoneEnemies = { ["Reborn Skeleton"] = true, ["Living Zombie"] = true,
    ["Demonic Soul"] = true, ["Posessed Mummy"] = true, ["Possessed Mummy"] = true }
local NPCs = {
    {"Blox Fruit Gacha", CFrame.new(-12488.7, 336.3, -7445.8)},
    {"Blox Fruit Dealer", CFrame.new(-12510.5, 335.6, -7441.7)},
    {"Set Home Point", CFrame.new(-12551.0, 336.3, -7409.5)},
    {"Barista", CFrame.new(-12460.0, 337.0, -7431.8)},
    {"Awakenings Expert", CFrame.new(-12646.3, 374.3, -7557.4)},
    {"Titles Specialist", CFrame.new(-12655.8, 336.3, -7518.7)},
    {"Bounty/Honor Expert", CFrame.new(-12646.1, 374.0, -7492.6)},
    {"Nerd", CFrame.new(-12455.1, 374.0, -7522.8)},
    {"tort", CFrame.new(-12485.2, 336.3, -7565.1)},
    {"Witch", CFrame.new(-12517.9, 331.9, -7613.7)},
    {"Citizen", CFrame.new(-12441.6, 330.8, -7676.2)},
    {"Indra", CFrame.new(-12483.6, 332.1, -7769.2)},
    {"Pirate Recruiter", CFrame.new(-12259.0, 331.1, -7399.9)},
    {"Marine Recruiter", CFrame.new(-12798.6, 331.1, -7699.2)},
}
-- QUEST / FARM LEVEL FIX v2.1
-- Keep explicit quest UI evidence separate from predicted quest-by-level.
local function QuestForLevel(level)
    for _, quest in ipairs(LevelQuests) do
        if level >= quest.min then return quest end
    end
    return nil
end

local function NameMatchesMob(label, mob)
    -- Workspace.Enemies names are sometimes suffixed with [Lv. ...] or pluralized.
    if type(label) ~= "string" or type(mob) ~= "string" then return false end
    return string.find(string.lower(label), string.lower(mob), 1, true) ~= nil
end

local function QuestForTitle(text)
    if type(text) ~= "string" or text == "" then return nil end
    for _, quest in ipairs(LevelQuests) do
        if NameMatchesMob(text, quest.mob) then return quest end
    end
    return nil
end

local function IsDisplayedGui(instance)
    local node, depth = instance, 0
    while node and depth < 15 do
        if node:IsA("GuiObject") and node.Visible == false then return false end
        if node:IsA("ScreenGui") and node.Enabled == false then return false end
        node, depth = node.Parent, depth + 1
    end
    return true
end

local function LabelTextIn(root)
    local texts = {}
    for _, child in ipairs(root:GetDescendants()) do
        if (child:IsA("TextLabel") or child:IsA("TextButton"))
            and IsDisplayedGui(child) and type(child.Text) == "string" and child.Text ~= "" then
            texts[#texts + 1] = child.Text
        end
    end
    return string.lower(table.concat(texts, " "))
end

local lastQuestScan, cachedQuestActive, cachedQuestText, cachedQuestSource = -100, false, "", "none"
local function QuestStatus(force)
    if not force and Clock() - lastQuestScan < 0.7 then
        return cachedQuestActive, cachedQuestText, cachedQuestSource
    end
    lastQuestScan = Clock()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then
        cachedQuestActive, cachedQuestText, cachedQuestSource = false, "", "no PlayerGui"
        return cachedQuestActive, cachedQuestText, cachedQuestSource
    end
    local main = gui:FindFirstChild("Main")
    local direct = main and main:FindFirstChild("Quest", true)
    if direct and IsDisplayedGui(direct) then
        local text = LabelTextIn(direct)
        if text ~= "" then
            cachedQuestActive, cachedQuestText, cachedQuestSource = true, text, "Main.Quest"
            return cachedQuestActive, cachedQuestText, cachedQuestSource
        end
    end
    -- Roblox's UI hierarchy changes. Look for another *visible* quest panel.
    -- Never match the Dragon Hub UI itself.
    for _, obj in ipairs(gui:GetDescendants()) do
        local low = string.lower(tostring(obj.Name or ""))
        if obj ~= direct and obj:IsA("GuiObject") and IsDisplayedGui(obj)
            and (low == "quest" or low == "questframe" or low == "questgui" or low == "questcontainer") then
            local text = LabelTextIn(obj)
            if text ~= "" and (QuestForTitle(text) or string.find(text, "defeat", 1, true)
                or string.find(text, "đánh bại", 1, true)) then
                cachedQuestActive, cachedQuestText, cachedQuestSource = true, text, obj.Name
                return cachedQuestActive, cachedQuestText, cachedQuestSource
            end
        end
    end
    -- Last resort: visible objective label with both mission verb and a known mob.
    -- NPC dialogues/list menus without an objective verb are not treated as accepted.
    for _, obj in ipairs(gui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and IsDisplayedGui(obj)
            and type(obj.Text) == "string" then
            local text = string.lower(obj.Text)
            if QuestForTitle(text) and (string.find(text, "defeat", 1, true)
                or string.find(text, "đánh bại", 1, true)) then
                cachedQuestActive, cachedQuestText, cachedQuestSource = true, text, "objective-label"
                return cachedQuestActive, cachedQuestText, cachedQuestSource
            end
        end
    end
    cachedQuestActive, cachedQuestText, cachedQuestSource = false, "", "not found"
    return cachedQuestActive, cachedQuestText, cachedQuestSource
end

local function QuestDebug()
    local data = LocalPlayer:FindFirstChild("Data")
    local levelObj = data and data:FindFirstChild("Level")
    local level = levelObj and tonumber(levelObj.Value)
    local active, title, source = QuestStatus(true)
    local quest = (active and QuestForTitle(title)) or (level and QuestForLevel(level))
    local _, _, root = GetCharacter()
    local target = quest and FindEnemy(function(name) return NameMatchesMob(name, quest.mob) end)
    local targetRoot = target and ValidEnemy(target)
    local message = string.format("Mode=%s | Lv=%s | QuestUI=%s (%s) | mob=%s | target=%s | HRP=%s",
        tostring(config.FarmMode), tostring(level), tostring(active), tostring(source),
        tostring(quest and quest.mob or "none"), tostring(target and target.Name or "none"),
        tostring(root ~= nil))
    if root and targetRoot then
        message = message .. string.format(" | enemy distance=%.0f", (targetRoot.Position - root.Position).Magnitude)
    end
    print("[Dragon Hub v2.1][QUEST DEBUG] " .. message .. " | text=" .. tostring(title):sub(1, 130))
    if Runtime.status then Runtime.status.Text = message end
    return message
end

local function FarmLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    local levelObj = data and data:FindFirstChild("Level")
    local level = levelObj and tonumber(levelObj.Value)
    local _, _, root = GetCharacter()
    if not level or not root then
        if Throttle("farmNotReady", 8) then Info("Auto Level: thiếu Data.Level hoặc HumanoidRootPart") end
        return
    end

    local active, title, source = QuestStatus()
    -- An accepted quest wins over level-based recommendations. Important for Lv. 2802
    -- with the accepted 'Defeat 8 Skull Slayers' quest visible in the screenshot.
    local quest = active and QuestForTitle(title) or QuestForLevel(level)
    if active and not QuestForTitle(title) then
        if Throttle("questNotMapped", 8) then
            Info("Đã thấy quest nhưng chưa nhận diện tên quái: " .. tostring(title):sub(1, 75))
        end
        return
    end
    if not quest then
        if Throttle("noQuest", 8) then Info("Auto Level: chưa có dữ liệu quest cho level này") end
        return
    end

    if active then
        Runtime.questPending = nil
        local enemy = FindEnemy(function(name) return NameMatchesMob(name, quest.mob) end)
        if enemy then
            Engage(enemy)
            if Throttle("farmTarget", 7) then
                Info("Đang tới và đánh " .. enemy.Name .. " (Quest: " .. quest.mob .. ")")
            end
        else
            MoveTo(quest.camp * CFrame.new(0, 12, 0))
            if Throttle("farmCamp", 7) then
                Info("Đã nhận quest " .. quest.mob .. "; chưa thấy quái. Đang đến bãi spawn.")
            end
        end
        return
    end

    -- When StartQuest returns successfully but the quest GUI was not found,
    -- move toward the camp temporarily instead of looping at the NPC forever.
    local pending = Runtime.questPending
    if pending and pending.quest == quest and Clock() < pending.expires then
        MoveTo(quest.camp * CFrame.new(0, 12, 0))
        if Throttle("questPending", 7) then
            Info("Đã gửi StartQuest; đang tìm xác nhận giao diện nhiệm vụ / tới bãi quái")
        end
        return
    end
    Runtime.questPending = nil
    if (root.Position - quest.quest.Position).Magnitude > 12 then
        MoveTo(quest.quest)
        if Throttle("farmToNPC", 8) then Info("Chưa thấy bảng quest; tới NPC " .. quest.id) end
    else
        local ok, result = Comm("StartQuest", 5, quest.id, quest.tier)
        if ok and result ~= false then
            Runtime.questPending = { quest = quest, expires = Clock() + 9 }
            QuestStatus(true)
            if Throttle("questRequested", 5) then Info("Đã gửi StartQuest " .. quest.id .. "; chuyển tới bãi quái") end
        elseif result ~= "cooldown" and Throttle("questFailed", 8) then
            Info("Không xác nhận được StartQuest: " .. tostring(result))
        end
    end
end
local function FindChest()
    local _, _, root = GetCharacter()
    if not root then return nil end
    local best, bestDistance
    local scanned = 0
    for _, part in ipairs(Workspace:GetDescendants()) do
        scanned = scanned + 1
        if scanned > 16000 then break end
        local name = string.lower(part.Name)
        if string.find(name, "chest", 1, true) and (part:IsA("BasePart") or part:IsA("Model")) then
            local cf
            if part:IsA("BasePart") then cf = part.CFrame
            elseif part.PrimaryPart then cf = part.PrimaryPart.CFrame end
            if cf then
                local distance = (cf.Position - root.Position).Magnitude
                if not bestDistance or distance < bestDistance then best, bestDistance = cf, distance end
            end
        end
    end
    return best
end
local lastChestScan, cachedChest = 0, nil
local function FarmTick()
    local mode = config.FarmMode
    if mode == "Off" then return end
    local enemy
    if mode == "Level" then
        FarmLevel()
        return
    elseif mode == "Selected Mob" then
        enemy = FindEnemy(function(name) return name == config.SelectedMob end)
        if not enemy and MobPositions[config.SelectedMob] then MoveTo(MobPositions[config.SelectedMob]) end
    elseif mode == "Nearest" then
        enemy = FindEnemy(function() return true end)
    elseif mode == "Boss" then
        local needle = string.lower(tostring(config.SelectedBoss))
        enemy = FindEnemy(function(name) return string.find(string.lower(name), needle, 1, true) ~= nil end)
        if not enemy and BossPositions[config.SelectedBoss] then MoveTo(BossPositions[config.SelectedBoss]) end
    elseif mode == "All Boss" then
        enemy = FindEnemy(function(name)
            local low = string.lower(name)
            for boss in pairs(BossPositions) do
                if string.find(low, string.lower(boss), 1, true) then return true end
            end
            return string.find(low, "[boss]", 1, true) ~= nil
        end)
    elseif mode == "Bone" then
        enemy = FindEnemy(function(name) return BoneEnemies[name] == true end)
    elseif mode == "Chest" then
        if Clock() - lastChestScan > 2 then
            lastChestScan = Clock()
            cachedChest = FindChest()
        end
        if cachedChest then MoveTo(cachedChest * CFrame.new(0, 3, 0)) end
        return
    end
    if enemy then Engage(enemy) end
end

local function IsFruitTool(item)
    return item and item:IsA("Tool") and string.find(string.lower(item.Name), "fruit", 1, true) ~= nil
end
local function StoreFruit()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    for _, holder in ipairs({ backpack, char }) do
        if holder then
            for _, item in ipairs(holder:GetChildren()) do
                if IsFruitTool(item) and Throttle("store:" .. item.Name, 15) then
                    local normalized = item.Name
                    -- DatThg identifies the StoreFruit action, but precise server schema is version-dependent.
                    local ok, result = Comm("StoreFruit", 3, normalized, item)
                    if ok and result ~= false then Info("Đã gửi yêu cầu StoreFruit: " .. normalized) end
                end
            end
        end
    end
end
local function FruitStockName(record)
    if type(record) ~= "table" then return nil end
    return record.Name or record.name or record[1]
end
local function FruitSniperTick()
    if not config.FruitSniper or not Throttle("sniperQuery", 15) then return end
    local ok, stock = Comm("GetFruits", 14)
    if not ok or type(stock) ~= "table" then return end
    for _, record in pairs(stock) do
        local name = FruitStockName(record)
        if type(name) == "string" and string.find(string.lower(name), string.lower(config.SniperFruit), 1, true) then
            local onSale = record.OnSale or record.onSale
            local price = tonumber(record.Price or record.price)
            if onSale == true and price and price <= config.SniperMaxPrice then
                local bought, outcome = Comm("PurchaseRawFruit", 18, name, false)
                if bought and outcome ~= false then Notify("Fruit Sniper", "Đã gửi yêu cầu mua: " .. name) end
                return
            end
        end
    end
end
local function FindIsland(name)
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    for _, child in ipairs(map:GetChildren()) do
        if string.find(string.lower(child.Name), string.lower(name), 1, true) then
            if child:IsA("Model") and child.PrimaryPart then return child.PrimaryPart.CFrame end
            if child:IsA("BasePart") then return child.CFrame end
            local pivotPart = child:FindFirstChildWhichIsA("BasePart", true)
            if pivotPart then return pivotPart.CFrame end
        end
    end
    return nil
end
local function FindNPC(name)
    local npcs = Workspace:FindFirstChild("NPCs") or Workspace
    for _, obj in ipairs(npcs:GetDescendants()) do
        if obj:IsA("Model") and string.find(string.lower(obj.Name), string.lower(name), 1, true) then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if part then return part.CFrame end
        end
    end
    return nil
end
local function TeleportToServer(newJobId)
    if not Runtime.active then return end
    Safely("Teleport", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, newJobId, LocalPlayer)
    end)
end
local function ServerHop()
    -- Public Roblox game-server directory; never executes response text as code.
    if not Throttle("serverHop", 30) then return end
    local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId)
        .. "/servers/Public?sortOrder=Asc&limit=100"
    local ok, body = Safely("ServerDirectory", function()
        -- getgenv executor API may be absent: fail visibly, not silently.
        if type(game.HttpGet) == "function" then return game:HttpGet(url) end
        error("HttpGet không khả dụng trong môi trường này")
    end)
    if not ok or type(body) ~= "string" then return end
    local parsedOk, payload = Safely("ServerJSON", function() return HttpService:JSONDecode(body) end)
    if not parsedOk or type(payload) ~= "table" or type(payload.data) ~= "table" then return end
    for _, server in ipairs(payload.data) do
        if type(server) == "table" and type(server.id) == "string"
            and server.id ~= game.JobId and tonumber(server.playing) and tonumber(server.maxPlayers)
            and server.playing < server.maxPlayers then
            TeleportToServer(server.id)
            return
        end
    end
    Info("Không tìm thấy máy chủ trống từ danh sách nhận được")
end

-- ESP uses Roblox Highlight instances, with explicit limits and cleanup.
local function AddESP(target, color, label)
    if Runtime.highlights[target] then return end
    if not target or not target.Parent then return end
    local h = Instance.new("Highlight")
    h.Name = "DragonHubESP"
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.8
    h.OutlineTransparency = 0.15
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = target
    h.Parent = target
    Runtime.highlights[target] = { visual = h, target = target, label = label }
end
local function RefreshESP()
    local should = {}
    local count = 0
    local function add(kind, target, color, text)
        if count >= 28 or not target or not target.Parent then return end
        count = count + 1
        should[target] = true
        AddESP(target, color, text)
    end
    if config.EspPlayers then
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= LocalPlayer and other.Character then
                add("player", other.Character, Color3.fromRGB(255, 80, 65), other.Name)
            end
        end
    end
    if config.EspMobs then
        local folder = Workspace:FindFirstChild("Enemies")
        if folder then
            for _, mob in ipairs(folder:GetChildren()) do
                if ValidEnemy(mob) then add("mob", mob, Color3.fromRGB(255, 168, 46), mob.Name) end
            end
        end
    end
    if config.EspFruits or config.EspChests or config.EspBerries then
        local scanned = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            scanned = scanned + 1
            if scanned > 12000 or count >= 28 then break end
            local name = string.lower(obj.Name)
            if config.EspFruits and IsFruitTool(obj) then
                local handle = obj:FindFirstChild("Handle")
                if handle then add("fruit", handle, Color3.fromRGB(180, 80, 255), obj.Name) end
            elseif config.EspChests and (obj:IsA("Model") or obj:IsA("BasePart"))
                and string.find(name, "chest", 1, true) then
                add("chest", obj, Color3.fromRGB(255, 210, 45), obj.Name)
            elseif config.EspBerries and obj:IsA("BasePart")
                and string.find(name, "berry", 1, true) then
                add("berry", obj, Color3.fromRGB(80, 235, 125), obj.Name)
            end
        end
    end
    if config.EspMirage or config.EspIslands then
        local map = Workspace:FindFirstChild("Map")
        if map then
            for _, object in ipairs(map:GetChildren()) do
                local low = string.lower(object.Name)
                if (config.EspMirage and (string.find(low, "mystic", 1, true) or string.find(low, "mirage", 1, true)))
                    or config.EspIslands then
                    add("island", object, Color3.fromRGB(90, 245, 240), object.Name)
                end
            end
        end
    end
    for target, record in pairs(Runtime.highlights) do
        if not should[target] or not record.target.Parent then
            record.visual:Destroy()
            Runtime.highlights[target] = nil
        end
    end
end
local function ApplyNoClip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, item in ipairs(char:GetDescendants()) do
        if item:IsA("BasePart") then
            if Runtime.collisionOriginal[item] == nil then Runtime.collisionOriginal[item] = item.CanCollide end
            item.CanCollide = false
        end
    end
end
local function RestoreCollision()
    for part, original in pairs(Runtime.collisionOriginal) do
        if part and part.Parent then pcall(function() part.CanCollide = original end) end
        Runtime.collisionOriginal[part] = nil
    end
end
local function RemoveFog(enabled)
    if enabled then
        if not Runtime.fogOriginal then
            Runtime.fogOriginal = { fogEnd = Lighting.FogEnd, atmos = {} }
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("Atmosphere") then
                    table.insert(Runtime.fogOriginal.atmos, { object = obj, density = obj.Density })
                end
            end
        end
        Lighting.FogEnd = 100000
        for _, old in ipairs(Runtime.fogOriginal.atmos) do
            if old.object.Parent then old.object.Density = 0 end
        end
    elseif Runtime.fogOriginal then
        Lighting.FogEnd = Runtime.fogOriginal.fogEnd
        for _, old in ipairs(Runtime.fogOriginal.atmos) do
            if old.object.Parent then old.object.Density = old.density end
        end
        Runtime.fogOriginal = nil
    end
end
local function MaxZoom(enabled)
    if enabled then
        if not Runtime.zoomOriginal then Runtime.zoomOriginal = LocalPlayer.CameraMaxZoomDistance end
        LocalPlayer.CameraMaxZoomDistance = 600
    elseif Runtime.zoomOriginal then
        LocalPlayer.CameraMaxZoomDistance = Runtime.zoomOriginal
        Runtime.zoomOriginal = nil
    end
end
local function FPSBoost(enabled)
    if enabled then
        local changed = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if not Runtime.visualOriginal[obj] then
                    Runtime.visualOriginal[obj] = { obj.Material, obj.Reflectance }
                end
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                changed = changed + 1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                if not Runtime.visualOriginal[obj] then Runtime.visualOriginal[obj] = { obj.Transparency } end
                obj.Transparency = 1
                changed = changed + 1
            end
            if changed >= 10000 then break end
        end
        Info("FPS Boost bật (chỉ thay đổi hình ảnh phía máy khách)")
    else
        for obj, old in pairs(Runtime.visualOriginal) do
            if obj and obj.Parent then
                pcall(function()
                    if obj:IsA("BasePart") then
                        obj.Material, obj.Reflectance = old[1], old[2]
                    else
                        obj.Transparency = old[1]
                    end
                end)
            end
            Runtime.visualOriginal[obj] = nil
        end
        Info("FPS Boost tắt; đã thử khôi phục vật liệu")
    end
end

-- UI (native, no external UI library, keyboard + touch friendly).
local host = LocalPlayer:WaitForChild("PlayerGui", 8)
if not host then
    ReportError("UI", "PlayerGui chưa sẵn sàng")
    Runtime.active = false
    environment.DragonHubRuntimeV2 = nil
    return
end
local existing = host:FindFirstChild("DragonHub_MainGUI")
if existing then existing:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "DragonHub_MainGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = host
Runtime.gui = gui
local function StyleCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end
local function StyleStroke(parent, color)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(110, 58, 48)
    s.Thickness = 1
    s.Parent = parent
    return s
end
local function Label(parent, text, height, fontSize, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, height or 24)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(239, 226, 220)
    l.Font = Enum.Font.Gotham
    l.TextSize = fontSize or 12
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end
local window = Instance.new("Frame")
window.Name = "Main"
window.BackgroundColor3 = Color3.fromRGB(19, 18, 23)
window.BorderSizePixel = 0
window.ClipsDescendants = true
window.AnchorPoint = Vector2.new(0.5, 0.5)
local size = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
local width = math.min(720, math.max(260, size.X - 24))
local height = math.min(500, math.max(260, size.Y - 46))
window.Size = UDim2.fromOffset(width, height)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Parent = gui
StyleCorner(window, 11)
StyleStroke(window, Color3.fromRGB(211, 66, 45))
local header = Instance.new("Frame")
header.BackgroundColor3 = Color3.fromRGB(44, 24, 25)
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 45)
header.Parent = window
local title = Label(header, "DRAGON HUB v2.1   |   Quest Fix + Sea 3", 45, 14, Color3.fromRGB(255, 209, 127))
title.Size = UDim2.new(1, -95, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.Font = Enum.Font.GothamBold
local function TopButton(text, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(33, 29)
    b.Position = UDim2.new(1, x, 0, 8)
    b.BackgroundColor3 = Color3.fromRGB(112, 39, 37)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.Text = text
    b.Parent = header
    StyleCorner(b, 7)
    return b
end
local hideButton = TopButton("−", -80)
local exitButton = TopButton("×", -42)
local sideWidth = width < 430 and 107 or 156
local tabSide = Instance.new("ScrollingFrame")
tabSide.BackgroundColor3 = Color3.fromRGB(29, 24, 29)
tabSide.BorderSizePixel = 0
tabSide.ScrollBarThickness = 3
tabSide.Size = UDim2.new(0, sideWidth, 1, -79)
tabSide.Position = UDim2.fromOffset(8, 48)
tabSide.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabSide.CanvasSize = UDim2.fromOffset(0, 0)
tabSide.Parent = window
StyleCorner(tabSide, 8)
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 5)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = tabSide
local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 7)
sidePad.PaddingLeft = UDim.new(0, 6)
sidePad.PaddingRight = UDim.new(0, 6)
sidePad.PaddingBottom = UDim.new(0, 7)
sidePad.Parent = tabSide
local content = Instance.new("Frame")
content.BackgroundColor3 = Color3.fromRGB(25, 23, 27)
content.BorderSizePixel = 0
content.Size = UDim2.new(1, -(sideWidth + 22), 1, -79)
content.Position = UDim2.fromOffset(sideWidth + 14, 48)
content.Parent = window
StyleCorner(content, 8)
Runtime.status = Label(window, "Sẵn sàng • Mọi Auto đang tắt", 24, 11, Color3.fromRGB(172, 200, 189))
Runtime.status.Size = UDim2.new(1, -18, 0, 24)
Runtime.status.Position = UDim2.new(0, 10, 1, -26)

local open = Instance.new("TextButton")
open.Name = "OpenDragonHub"
open.Size = UDim2.fromOffset(140, 38)
open.Position = UDim2.new(0, 12, 0.3, 0)
open.BackgroundColor3 = Color3.fromRGB(54, 24, 27)
open.TextColor3 = Color3.fromRGB(255, 211, 127)
open.Text = "DRAGON HUB"
open.Font = Enum.Font.GothamBold
open.TextSize = 13
open.Visible = false
open.Parent = gui
StyleCorner(open, 8)
StyleStroke(open, Color3.fromRGB(230, 75, 48))

local dragState = nil
local function Draggable(handle, moving)
    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragState = { input = input, moving = moving, pointer = input.Position, position = moving.Position }
        end
    end)
    Connect(handle.InputEnded, function(input)
        if dragState and dragState.input == input then dragState = nil end
    end)
end
Draggable(header, window)
Draggable(open, open)
Connect(UserInputService.InputChanged, function(input)
    local drag = dragState
    if not drag or not Runtime.active then return end
    if input == drag.input or (input.UserInputType == Enum.UserInputType.MouseMovement and drag.input.UserInputType == Enum.UserInputType.MouseButton1) then
        local delta = input.Position - drag.pointer
        drag.moving.Position = UDim2.new(drag.position.X.Scale, drag.position.X.Offset + delta.X,
            drag.position.Y.Scale, drag.position.Y.Offset + delta.Y)
    end
end)
local function Show(isVisible)
    window.Visible = isVisible
    open.Visible = not isVisible
end
Connect(hideButton.MouseButton1Click, function() Show(false) end)
Connect(open.MouseButton1Click, function() Show(true) end)

local pages = {}
local function Tab(tabName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(43, 31, 37)
    btn.Text = tabName
    btn.TextWrapped = true
    btn.TextColor3 = Color3.fromRGB(239, 213, 195)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = tabSide
    StyleCorner(btn, 6)
    local page = Instance.new("ScrollingFrame")
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.fromScale(1, 1)
    page.ScrollBarThickness = 4
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.Visible = false
    page.Parent = content
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 15)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = page
    local entry = { btn = btn, page = page }
    table.insert(pages, entry)
    Connect(btn.MouseButton1Click, function()
        for _, p in ipairs(pages) do
            p.page.Visible = p == entry
            p.btn.BackgroundColor3 = p == entry and Color3.fromRGB(133, 49, 44) or Color3.fromRGB(43, 31, 37)
        end
    end)
    if #pages == 1 then
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(133, 49, 44)
    end
    return page
end
local function Section(page, text)
    local l = Label(page, text, 27, 13, Color3.fromRGB(255, 193, 106))
    l.Font = Enum.Font.GothamBold
end
local function Note(page, text)
    local h = #text > 150 and 84 or (#text > 85 and 61 or 39)
    Label(page, text, h, 11, Color3.fromRGB(186, 178, 181))
end
local switches = {}
local function Toggle(page, key, text, description, callback)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.fromRGB(34, 30, 35)
    row.Size = UDim2.new(1, 0, 0, 53)
    row.Parent = page
    StyleCorner(row, 7)
    local label = Label(row, text, 23, 12)
    label.Size = UDim2.new(1, -66, 0, 23)
    label.Position = UDim2.fromOffset(10, 2)
    local detail = Label(row, description or "", 25, 10, Color3.fromRGB(177, 157, 155))
    detail.Size = UDim2.new(1, -66, 0, 25)
    detail.Position = UDim2.fromOffset(10, 25)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(47, 26)
    button.Position = UDim2.new(1, -54, 0.5, -13)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Parent = row
    StyleCorner(button, 6)
    local function refresh()
        local on = config[key] == true
        button.Text = on and "BẬT" or "TẮT"
        button.BackgroundColor3 = on and Color3.fromRGB(167, 59, 45) or Color3.fromRGB(66, 54, 58)
        button.TextColor3 = on and Color3.fromRGB(255, 228, 160) or Color3.fromRGB(196, 185, 181)
    end
    switches[key] = refresh
    refresh()
    Connect(button.MouseButton1Click, function()
        config[key] = not config[key]
        if callback then Safely("UI:" .. key, callback, config[key]) end
        refresh()
    end)
end
local function Options(page, name, key, values, callback)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.fromRGB(34, 30, 35)
    row.Size = UDim2.new(1, 0, 0, 43)
    row.Parent = page
    StyleCorner(row, 6)
    local titleLabel = Label(row, name, 41, 11)
    titleLabel.Size = UDim2.new(0.46, -5, 1, 0)
    titleLabel.Position = UDim2.fromOffset(8, 0)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.52, -9, 0, 29)
    btn.Position = UDim2.new(0.48, 0, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(77, 39, 42)
    btn.TextColor3 = Color3.fromRGB(255, 221, 158)
    btn.TextSize = 11
    btn.TextWrapped = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = row
    StyleCorner(btn, 6)
    local currentIndex = 1
    for i, value in ipairs(values) do
        if value == config[key] then currentIndex = i; break end
    end
    local function refresh()
        btn.Text = tostring(config[key]) .. "  ›"
        for i, value in ipairs(values) do
            if value == config[key] then currentIndex = i; break end
        end
    end
    if not Runtime.optionRefresh then Runtime.optionRefresh = {} end
    Runtime.optionRefresh[key] = refresh
    refresh()
    Connect(btn.MouseButton1Click, function()
        currentIndex = currentIndex % #values + 1
        config[key] = values[currentIndex]
        if callback then Safely("Select:" .. key, callback, config[key]) end
        refresh()
    end)
end
local function Button(page, titleText, desc, fn)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 41)
    button.BackgroundColor3 = Color3.fromRGB(66, 37, 43)
    button.TextColor3 = Color3.fromRGB(255, 217, 165)
    button.TextWrapped = true
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Text = titleText .. (desc and desc ~= "" and (" — " .. desc) or "")
    button.Parent = page
    StyleCorner(button, 7)
    Connect(button.MouseButton1Click, function()
        task.spawn(function()
            if Runtime.active then Safely("Button:" .. titleText, fn) end
        end)
    end)
end

local tabFarm = Tab("AUTO FARM")
local tabEvent = Tab("RỒNG / RACE")
local tabItems = Tab("TRÁI / VẬT PHẨM")
local tabTP = Tab("DỊCH CHUYỂN")
local tabESP = Tab("ESP / HIỆU NĂNG")
local tabStats = Tab("STATS / TIỆN ÍCH")
local tabAbout = Tab("GHI CHÚ")

Section(tabFarm, "Chọn chế độ farm duy nhất")
Note(tabFarm, "Đổi chế độ sẽ dừng tween cũ. Thông tin quest/tọa độ Sea 3 lấy từ Dragon Hub gốc, cần đối chiếu trong game.")
Options(tabFarm, "Chế độ", "FarmMode", { "Off", "Level", "Selected Mob", "Nearest", "Boss", "All Boss", "Bone", "Chest" }, function()
    Runtime.questPending = nil
    StopMovement()
    Info("Auto Farm mode: " .. tostring(config.FarmMode))
end)
Button(tabFarm, "BẬT / TẮT AUTO FARM LEVEL", "Một chạm để chạy hoặc dừng Auto Level", function()
    config.FarmMode = config.FarmMode == "Level" and "Off" or "Level"
    StopMovement()
    Runtime.questPending = nil
    if Runtime.optionRefresh and Runtime.optionRefresh.FarmMode then Runtime.optionRefresh.FarmMode() end
    Notify("Auto Farm Level", "Chế độ hiện tại: " .. config.FarmMode)
    if config.FarmMode == "Level" then QuestDebug() end
end)
Button(tabFarm, "KIỂM TRA QUEST / FARM", "Hiện chẩn đoán vào thanh trạng thái và Output", QuestDebug)
Options(tabFarm, "Vũ khí", "WeaponType", { "Melee", "Sword", "Fruit", "Gun", "Any" })
Options(tabFarm, "Cự ly đứng", "FarmDistance", { 4, 6, 8, 12, 18, 25 })
Options(tabFarm, "Tween speed", "TweenSpeed", { 180, 240, 280, 340, 420 })
Options(tabFarm, "Quái", "SelectedMob", {
    "Grand Devotee", "High Disciple", "Ocean Prophet", "Jack o' Lantern", "Mythological Pirate", "Forest Pirate",
})
Options(tabFarm, "Boss", "SelectedBoss", { "Longma", "Stone", "Urban", "indra" })
Toggle(tabFarm, "AttackAura", "Đánh bằng Tool:Activate", "Dùng vũ khí đang cầm; không giả mạo gói hit server")
Toggle(tabFarm, "BringMob", "Gom quái (thử nghiệm)", "Chỉ thay đổi vị trí phía máy khách; mặc định tắt")
Toggle(tabFarm, "AutoBuso", "Tự bật Buso", "Có giới hạn tần suất gọi Remote")
Button(tabFarm, "DỪNG FARM", "Hủy tween và auto farm", function()
    config.FarmMode = "Off"
    StopMovement()
    if Runtime.optionRefresh and Runtime.optionRefresh.FarmMode then Runtime.optionRefresh.FarmMode() end
    Notify("Auto Farm", "Đã dừng")
end)

Section(tabEvent, "Dragon / Race — giới hạn tần suất Remote")
Toggle(tabEvent, "AutoDragonHunter", "Auto nhận Dragon Hunter quest", "Dữ liệu Remote từ Dragon Hub gốc")
Toggle(tabEvent, "AutoDragonEmber", "Tự gửi yêu cầu Ember / Egg", "Có thể chỉ hoạt động trong sự kiện tương ứng")
Toggle(tabEvent, "AutoKitsunePray", "Auto Kitsune Pray", "Chỉ gửi khi Remote tồn tại")
Toggle(tabEvent, "AutoRaceV3", "Auto kích hoạt V3", "Thử CommE ActivateAbility")
Toggle(tabEvent, "AutoAwakening", "Auto kích hoạt V4", "Yêu cầu công cụ Awakening")
Button(tabEvent, "Kích hoạt Draco Trial", "Một lần", function()
    local ok = Invoke(Remote("DracoTrial"), "DracoTrial", 8)
    if not ok then Notify("Trial", "Không thể gọi Remote DracoTrial") end
end)

Section(tabItems, "Fruit — bổ sung từ danh mục DatThg")
Toggle(tabItems, "AutoGrabFruits", "Auto nhặt trái gần", "Chỉ thử di chuyển Handle phía máy khách")
Toggle(tabItems, "AutoStoreFruit", "Auto Store Fruit (beta)", "Dùng CommF_ StoreFruit; cấu trúc Remote có thể thay đổi")
Toggle(tabItems, "FruitSniper", "Auto Buy Fruit Sniper (beta)", "Chỉ thử mua khi GetFruits báo OnSale và có giá")
Options(tabItems, "Trái cần mua", "SniperFruit", { "Dough", "Dragon", "Leopard", "Kitsune", "Buddha", "T-Rex", "Portal", "Spirit", "Venom" })
Options(tabItems, "Giá trần", "SniperMaxPrice", { 1000000, 2500000, 5000000, 10000000 })
Toggle(tabItems, "AutoCollectBerries", "Auto Collect Berries", "Dữ liệu RF/ClaimBerry từ Dragon Hub gốc")
Toggle(tabItems, "AutoFirePrompts", "Tự kích hoạt prompt gần", "Cần fireproximityprompt của executor")
Button(tabItems, "Random Fruit", "Mua một lần", function()
    local ok = Comm("Cousin", 10, "Buy")
    if not ok then
        Fire(NetRemote("RE/SpinGacha"), "SpinGacha", 10)
    end
end)
Button(tabItems, "Store Fruits một lần", "Thử cất tất cả Tool là Fruit", StoreFruit)

Section(tabTP, "Đổi Sea / Server — bổ sung từ DatThg")
Button(tabTP, "Sea 1", "TravelMain", function() Comm("TravelMain", 10) end)
Button(tabTP, "Sea 2", "TravelDressrosa", function() Comm("TravelDressrosa", 10) end)
Button(tabTP, "Sea 3", "TravelZou", function() Comm("TravelZou", 10) end)
Button(tabTP, "Đến Fruit gần nhất", "Tìm Tool có Handle trong Workspace", function()
    local _, _, root = GetCharacter()
    if not root then return end
    local nearest, distance
    for _, tool in ipairs(Workspace:GetChildren()) do
        if IsFruitTool(tool) and tool:FindFirstChild("Handle") then
            local cf = tool.Handle.CFrame
            local d = (cf.Position - root.Position).Magnitude
            if not distance or d < distance then nearest, distance = cf, d end
        end
    end
    if nearest then MoveTo(nearest * CFrame.new(0, 3, 0))
    else Notify("Fruit", "Không tìm thấy trái trên Workspace") end
end)
Button(tabTP, "Mirage Island", "Chỉ dịch chuyển nếu đảo có trên map", function()
    local cf = FindIsland("MysticIsland") or FindIsland("Mirage")
    if cf then MoveTo(cf * CFrame.new(0, 18, 0))
    else Notify("Mirage", "Chưa tìm thấy đảo trong Workspace.Map") end
end)
Button(tabTP, "Advanced Fruit Dealer", "Tìm NPC hiện có trên map", function()
    local cf = FindNPC("Advanced Fruit Dealer")
    if cf then MoveTo(cf * CFrame.new(0, 5, 0))
    else Notify("Dealer", "NPC không tồn tại / chưa spawn") end
end)
Button(tabTP, "Prehistoric Island", "Chỉ khi đảo đã xuất hiện", function()
    local cf = FindIsland("Prehistoric")
    if cf then MoveTo(cf * CFrame.new(0, 18, 0))
    else Notify("Prehistoric", "Chưa tìm thấy đảo hiện có") end
end)
for _, entry in ipairs({ {"Dragon Hunter NPC", "Dragon Hunter"}, {"Dojo Trainer NPC", "Dojo Trainer"}, {"Dragon Wizard NPC", "Dragon Wizard"} }) do
    Button(tabTP, entry[1], "Tìm NPC đang xuất hiện", function()
        local cf = FindNPC(entry[2])
        if cf then MoveTo(cf * CFrame.new(0, 5, 0))
        else Notify("NPC", "Không tìm thấy " .. entry[2]) end
    end)
end
Button(tabTP, "Dungeon Hub", "Gửi lệnh TeleportToDungeonHub", function()
    Invoke(NetRemote("RF/DungeonNPCNetworkFunction"), "DungeonHub", 8, "TeleportToDungeonHub", false)
end)
Button(tabTP, "Rejoin", "Vào lại server hiện tại", function() TeleportToServer(game.JobId) end)
Button(tabTP, "Server Hop", "Tìm server khác, cần HttpGet", ServerHop)
Button(tabTP, "Copy Job ID", "Nếu executor có setclipboard", function()
    if type(setclipboard) == "function" then setclipboard(game.JobId); Notify("Copy", "Đã sao chép Job ID")
    else Notify("Copy", "Không hỗ trợ clipboard") end
end)
Button(tabTP, "STOP TWEEN", "Dừng di chuyển", StopMovement)
Section(tabTP, "NPC Sea 3 (tọa độ từ Dragon Hub gốc)")
for _, npc in ipairs(NPCs) do
    Button(tabTP, npc[1], "đi tới", function() MoveTo(npc[2]) end)
end

Section(tabESP, "ESP bằng Highlight")
Toggle(tabESP, "EspPlayers", "ESP Players", "Hiện người chơi khác")
Toggle(tabESP, "EspMobs", "ESP Mobs", "Hiện quái")
Toggle(tabESP, "EspFruits", "ESP Fruits", "Hiện Tool Fruit")
Toggle(tabESP, "EspChests", "ESP Chests", "Bổ sung từ DatThg")
Toggle(tabESP, "EspIslands", "ESP Islands", "Bổ sung từ DatThg")
Toggle(tabESP, "EspMirage", "ESP Mirage", "Bổ sung từ DatThg")
Toggle(tabESP, "EspBerries", "ESP Berries", "Bổ sung từ DatThg")
Toggle(tabESP, "NoClip", "NoClip", "Lưu/khôi phục CanCollide khi tắt", function(on)
    if not on then RestoreCollision() end
end)
Toggle(tabESP, "FPSBoost", "FPS Boost (có hoàn tác)", "Lưu vật liệu/texture để khôi phục", FPSBoost)
Toggle(tabESP, "RemoveFog", "Remove Fog", "Có lưu/khôi phục FogEnd và Atmosphere", RemoveFog)
Toggle(tabESP, "MaxZoom", "Max Zoom", "Có thể trả lại giá trị Zoom ban đầu", MaxZoom)
Toggle(tabESP, "MovementOverride", "Walk Speed / Jump Power", "Dùng giá trị thiết lập phía máy khách")
Options(tabESP, "Walk Speed", "WalkSpeed", { 16, 22, 30, 40, 60 })
Options(tabESP, "Jump Power", "JumpPower", { 50, 65, 85, 110 })

Section(tabStats, "Tự cộng điểm — giới hạn theo điểm còn")
Toggle(tabStats, "AutoStatsMelee", "Auto Melee", "Ưu tiên đầu tiên nếu nhiều mục cùng bật")
Toggle(tabStats, "AutoStatsDefense", "Auto Defense", "Gửi tối đa 3 điểm/lần")
Toggle(tabStats, "AutoStatsSword", "Auto Sword", "Gửi tối đa 3 điểm/lần")
Toggle(tabStats, "AutoStatsGun", "Auto Gun", "Gửi tối đa 3 điểm/lần")
Toggle(tabStats, "AutoStatsFruit", "Auto Demon Fruit", "Gửi tối đa 3 điểm/lần")
Button(tabStats, "Redeem Code", "Thử các mã nguồn gốc (có thể hết hạn)", function()
    local remote = Remote("Redeem")
    local codes = { "KITTGAMING", "ENYU_IS_PRO", "FUDD10", "BIGNEWS", "THEGREATACE", "SUB2GAMERROBOT_EXP1" }
    for _, code in ipairs(codes) do
        if not Runtime.active then break end
        Invoke(remote, "Redeem:" .. code, 5, code)
        task.wait(0.3)
    end
    Notify("Redeem", "Đã gửi các yêu cầu; mã có thể đã hết hạn")
end)
Button(tabStats, "Xem lỗi", "Mở Developer Console (F9) để đọc Output", function()
    Notify("Thông báo", "Thông tin lỗi được ghi vào Output, không bị bỏ qua")
end)

Section(tabAbout, "Nguồn và giới hạn")
Note(tabAbout, "Bản 2.0 dựa trên Dragon hub.txt, đối chiếu danh mục DatThgV2. Không chạy VM/XHider hoặc tải module ngoài.")
Note(tabAbout, "Mục mới: Farm Nearest/All Boss/Bone/Chest, Store Fruit, Fruit Sniper, ESP Chest/Berries/Island, Travel Sea 1-3, Mirage/Prehistoric, Dealer/Dojo NPC, Server Hop, NoClip.")
Note(tabAbout, "Các quest dài như Yama/Tushita/CDK, Soul Guitar, Dough King, Raid, Race Trial chưa có logic sạch đã kiểm chứng từ DatThg: KHÔNG thêm toggle giả.")
Note(tabAbout, "Không thể bảo đảm không lỗi trong Roblox khi chưa kiểm thử bằng client thật. Remote, tọa độ và tên sự kiện thay đổi theo phiên bản.")
Button(tabAbout, "Tắt tất cả Auto", "Không đóng giao diện", function()
    config.FarmMode = "Off"
    for key, value in pairs(defaults) do
        if type(value) == "boolean" and key ~= "FPSBoost" then config[key] = false end
    end
    StopMovement()
    RestoreCollision()
    if Runtime.optionRefresh and Runtime.optionRefresh.FarmMode then Runtime.optionRefresh.FarmMode() end
    for _, refresh in pairs(switches) do refresh() end
    Notify("An toàn", "Đã tắt tính năng tự động")
end)

local function ActiveFarm()
    return config.FarmMode ~= "Off"
end
-- Loop worker: bounded intervals, guard errors, stop when Runtime inactive.
local function Worker(name, interval, fn)
    task.spawn(function()
        while Runtime.active do
            local ok, err = pcall(fn)
            if not ok then ReportError(name, err) end
            task.wait(interval)
        end
    end)
end
Worker("Farm", 0.35, FarmTick)
Worker("Attack", 0.35, function()
    if config.AttackAura or (ActiveFarm() and config.FarmMode ~= "Chest") then Attack() end
end)
Worker("Events", 2.0, function()
    if config.AutoBuso and not ActiveFarm() then Buso() end
    if config.AutoRaceV3 then Fire(Remote("CommE"), "RaceV3", 14, "ActivateAbility") end
    if config.AutoAwakening then
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local tool = (backpack and backpack:FindFirstChild("Awakening")) or (char and char:FindFirstChild("Awakening"))
        if tool then Fire(tool:FindFirstChild("RemoteEvent"), "RaceV4", 12) end
    end
    if config.AutoDragonHunter then Invoke(NetRemote("RF/DragonHunter"), "DragonHunter", 12, { Context = "RequestQuest" }) end
    if config.AutoDragonEmber then
        Fire(NetRemote("RE/DragonDojoEmber"), "DragonEmber", 8)
        Fire(NetRemote("RE/CollectedDragonEgg"), "DragonEgg", 15)
    end
    if config.AutoKitsunePray then
        Fire(NetRemote("RE/TouchKitsuneStatue"), "TouchKitsuneStatue", 15)
        Invoke(NetRemote("RF/KitsuneStatuePray"), "KitsuneStatuePray", 15)
        Fire(NetRemote("RE/CollectBlueEmber"), "CollectBlueEmber", 8)
    end
    if config.AutoCollectBerries then Invoke(NetRemote("RF/ClaimBerry"), "ClaimBerry", 12) end
    if config.AutoStoreFruit then StoreFruit() end
    if config.FruitSniper then FruitSniperTick() end
end)
Worker("Items", 2.5, function()
    local _, _, root = GetCharacter()
    if config.AutoGrabFruits and root then
        local moved = 0
        for _, child in ipairs(Workspace:GetChildren()) do
            if IsFruitTool(child) then
                local handle = child:FindFirstChild("Handle")
                if handle and (handle.Position - root.Position).Magnitude <= 80 then
                    handle.CFrame = root.CFrame
                    moved = moved + 1
                    if moved >= 8 then break end
                end
            end
        end
    end
    if config.AutoFirePrompts and root and type(fireproximityprompt) == "function" then
        local activated = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled and obj.Parent and obj.Parent:IsA("BasePart")
                and (obj.Parent.Position - root.Position).Magnitude <= obj.MaxActivationDistance then
                fireproximityprompt(obj)
                activated = activated + 1
                if activated >= 3 then break end
            end
        end
    end
end)
Worker("Stats", 1.5, function()
    local opts = { { "AutoStatsMelee", "Melee" }, { "AutoStatsDefense", "Defense" },
        { "AutoStatsSword", "Sword" }, { "AutoStatsGun", "Gun" }, { "AutoStatsFruit", "Demon Fruit" } }
    local data = LocalPlayer:FindFirstChild("Data")
    local pointsObj = data and data:FindFirstChild("Points")
    local available = pointsObj and tonumber(pointsObj.Value) or 0
    if available <= 0 then return end
    for _, option in ipairs(opts) do
        if config[option[1]] then
            Comm("AddPoint", 1.4, option[2], math.min(3, math.floor(available)))
            break
        end
    end
end)
Worker("ESP", 3, function()
    RefreshESP()
end)
Worker("Humanoid", 0.8, function()
    if not config.MovementOverride then return end
    local _, hum = GetCharacter()
    if hum then
        hum.WalkSpeed = tonumber(config.WalkSpeed) or 16
        hum.JumpPower = tonumber(config.JumpPower) or 50
    end
end)
Connect(RunService.Stepped, function()
    if Runtime.active and (config.NoClip or ActiveFarm()) then ApplyNoClip()
    elseif next(Runtime.collisionOriginal) then RestoreCollision() end
end)
Connect(LocalPlayer.CharacterAdded, function()
    StopMovement()
    Runtime.questPending = nil
    RestoreCollision()
end)
Connect(UserInputService.InputBegan, function(input, consumed)
    if consumed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then Show(not window.Visible) end
end)

function Runtime:Shutdown(reason)
    if not self.active then return end
    self.active = false
    StopMovement()
    Runtime.questPending = nil
    RestoreCollision()
    if config.FPSBoost then FPSBoost(false) end
    if config.RemoveFog then RemoveFog(false) end
    if config.MaxZoom then MaxZoom(false) end
    for _, record in pairs(self.highlights) do
        pcall(function() record.visual:Destroy() end)
    end
    self.highlights = {}
    for _, connection in ipairs(self.connections) do
        pcall(function() connection:Disconnect() end)
    end
    self.connections = {}
    if self.gui then self.gui:Destroy(); self.gui = nil end
    config.FarmMode = "Off"
    for key, value in pairs(defaults) do
        if type(value) == "boolean" then config[key] = false end
    end
    if environment.DragonHubRuntimeV2 == self then environment.DragonHubRuntimeV2 = nil end
    print("[Dragon Hub v2.1] Shutdown: " .. tostring(reason or "manual"))
end
Connect(exitButton.MouseButton1Click, function() Runtime:Shutdown("close") end)

Notify("Dragon Hub v2.1", "Đã tải giao diện; tất cả Auto đang tắt. Hãy kiểm tra từng tính năng trong game.")
