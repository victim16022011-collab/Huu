-- =================================================================================
-- DỰ ÁN: ANIME BLACKER HUB V2 (BẢN FIX TOÀN DIỆN - FULL 13 TABS DATTHG V2)
-- BẢN QUYỀN: HUYKOGIAUVN
-- ĐÃ SỬA LỖI:
--   1. Fix lỗi đơ Tween: Thêm BodyVelocity chống rơi + Không hủy Tween khi đang bay
--   2. Fix lỗi nút bấm UI trên Mobile/Delta X: Dùng Frame + MouseButton1Click chuẩn
--   3. Nối đầy đủ 100% vòng lặp cho toàn bộ chức năng ở cả 13 Tabs
--   4. Quét thực thể kép (Workspace.Enemies + ReplicatedStorage) & tự động nhận Quest
-- =================================================================================

local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerMouse = LocalPlayer:GetMouse()

-- Dọn sạch UI và kết nối cũ nếu chạy lại script
if CoreGui:FindFirstChild("AnimeBlacker_FixedUI") then
    CoreGui.AnimeBlacker_FixedUI:Destroy()
end
if CoreGui:FindFirstChild("AnimeBlacker_ESPFolder") then
    CoreGui.AnimeBlacker_ESPFolder:Destroy()
end
if CoreGui:FindFirstChild("AnimeBlacker_SFX") then
    CoreGui.AnimeBlacker_SFX:Destroy()
end
if Lighting:FindFirstChild("AnimeBlacker_Blur") then
    Lighting.AnimeBlacker_Blur:Destroy()
end

-- =================================================================================
-- 1. KHỞI TẠO TOÀN BỘ BIẾN ĐIỀU KHIỂN (_G FLAGS)
-- =================================================================================
_G.SelectWeapon = _G.SelectWeapon or "Melee"
_G.TweenSpeed = _G.TweenSpeed or 300
_G.TweenPosYHight = true
_G.SpinPos = false
_G.PosX = 0
_G.PosY = 22
_G.PosZ = 0
_G.UIScale = "Large"

-- Tab 2: Farm
_G.AutoFarmLevel = false
_G.AutoFarmMob = false
_G.SelectedMob = "Forest Pirate"
_G.AutoFarmCake = false
_G.AutoFarmBone = false
_G.FarmChest = false
_G.AutoFarmBoss = false
_G.SelectBoss = "Longma"

-- Tab 3: Setting
_G.AutoClick = false
_G.AutoShootGun = false
_G.BringMonster = true
_G.BringMode = 250
_G.AutoHaki = true
_G.Observation = false
_G.Kill_Aura = false
_G.InfiniteStam = false
_G.DisableNotifications = false
_G.DisableDamageCounter = false
_G.FixLagBlur = false
_G.WhiteScreen = false
_G.InvisibleMonsters = false

-- Tab 4: Quest/Item (World 1, 2, 3)
_G.Greybeard = false
_G.AutoSaber = false
_G.AutoPoleV1 = false
_G.SecondSea = false
_G.Bartilo = false
_G.Factory = false
_G.AutoDarkbeard = false
_G.LawRaid = false
_G.AutoLawHop = false
_G.FarmSwanGlasses = false
_G.OderSword = false
_G.ThirdSea = false
_G.MusketeerHat = false
_G.BudySword = false
_G.Carvender = false
_G.TwinHook = false
_G.tushita = false
_G.HolyTorch = false
_G.CDKQuest = false
_G.Guitar = false
_G.Rainbow_Haki = false
_G.AutoEliteHunter = false
_G.TyrantSkies = false
_G.BuyLegendarySword_Hop = false

-- Tab 5: Race/Mirage
_G.TpSkullCore = false
_G.TweenMGear = false
_G.BuyGear = false
_G.AutoRaceV3 = false
_G.AutoRaceV4 = false

-- Tab 6: Event
_G.Seabest = false
_G.SegmentLeviathan = false
_G.DefendVolcano = false
_G.CollectEgg = false
_G.AutoDragonEmber = false
_G.AutoKitsuneShrine = false
_G.AutoBlueEmber = false
_G.CollectBerry = false
_G.AutoFishing = false

-- Tab 7: Player & Stats
_G.SelectPly = ""
_G.TeleportPly = false
_G.AutoStats = false
_G.SelectedStat = "Melee"

-- Tab 8: Visual (ESP)
_G.ESPPlayer = false
_G.DevilFruitESP = false
_G.ESPBerry = false
_G.ESPMirage = false
_G.ESPKitsune = false
_G.ESPIsland = false

-- Tab 9: Raid
_G.SelectChip = "Flame"
_G.AutoBuyChip = false
_G.AutoStartRaid = false
_G.AutoNextIsland = false
_G.AutoAwaken = false
_G.RaidPirate = false

-- Tab 10, 12, 13: Teleport, Fruit, Misc
_G.SelectIsland = "Floating Turtle"
_G.SelectedFruitSniper = "Kitsune-Kitsune"
_G.AutoBuyFruitSniper = false
_G.AutoStoreFruit = false
_G.BringFruit = false
_G.Tweenfruit = false
_G.SelectStateHaki = "State 5"
_G.InputJobId = ""

-- =================================================================================
-- 2. DỮ LIỆU TỌA ĐỘ QUÁI, NHIỆM VỤ, BOSS, ĐẢO & GIFTCODES CHUẨN
-- =================================================================================
local CakeMobs = {
    ["Cookie Crafter"] = CFrame.new(-2333.28052, 37.8239059, -12093.2861),
    ["Cake Guard"]     = CFrame.new(-1575.56433, 37.8238907, -12416.2529),
    ["Baking Staff"]   = CFrame.new(-1872.35742, 37.8239517, -12899.4248),
    ["Head Baker"]     = CFrame.new(-2223.14160, 53.5283203, -12854.7520)
}

local BoneMobs = {
    ["Reborn Skeleton"] = CFrame.new(-8769.58984, 142.130630, 6055.27637),
    ["Living Zombie"]   = CFrame.new(-10156.4531, 138.652481, 5964.57520),
    ["Demonic Soul"]    = CFrame.new(-9525.17188, 172.130630, 6152.30566),
    ["Posessed Mummy"]  = CFrame.new(-9570.88281, 5.81831884, 6187.86279)
}

local MobList = {
    "Forest Pirate", "Mythological Pirate", "Ocean Prophet", "High Disciple",
    "Grand Devotee", "Jack o' Lantern", "Cookie Crafter", "Cake Guard",
    "Baking Staff", "Head Baker", "Reborn Skeleton", "Living Zombie",
    "Demonic Soul", "Posessed Mummy", "Hydra Enforcer", "Isle Champion"
}

local MobSpawnCFrames = {
    ["Forest Pirate"]       = CFrame.new(-13345.5, 331.3, -7630.8),
    ["Mythological Pirate"] = CFrame.new(-13320.0, 518.8, -6785.0),
    ["Ocean Prophet"]       = CFrame.new(11129.8, -2008.9, 10051.5),
    ["High Disciple"]       = CFrame.new(9778.4, -1994.3, 9877.0),
    ["Grand Devotee"]       = CFrame.new(9620.5, -1994.2, 9871.7),
    ["Jack o' Lantern"]     = CFrame.new(-10979.7, 456.8, -7740.1),
    ["Cookie Crafter"]      = CakeMobs["Cookie Crafter"],
    ["Cake Guard"]          = CakeMobs["Cake Guard"],
    ["Baking Staff"]        = CakeMobs["Baking Staff"],
    ["Head Baker"]          = CakeMobs["Head Baker"],
    ["Reborn Skeleton"]     = BoneMobs["Reborn Skeleton"],
    ["Living Zombie"]       = BoneMobs["Living Zombie"],
    ["Demonic Soul"]        = BoneMobs["Demonic Soul"],
    ["Posessed Mummy"]      = BoneMobs["Posessed Mummy"],
    ["Hydra Enforcer"]      = CFrame.new(5290.0, 1005.0, 392.0),
    ["Isle Champion"]       = CFrame.new(-16541.0, 55.0, -172.0)
}

-- Bảng dữ liệu Quest cho Auto Farm Level
local LevelQuestDatabase = {
    {MinLevel = 1,    MaxLevel = 1499, Mob = "Forest Pirate",       QuestName = "DeepForestIsland",  QuestLv = 1, Pos = CFrame.new(-13234.0, 331.6, -7625.4)},
    {MinLevel = 1500, MaxLevel = 1849, Mob = "Forest Pirate",       QuestName = "DeepForestIsland",  QuestLv = 1, Pos = CFrame.new(-13345.5, 331.3, -7630.8)},
    {MinLevel = 1850, MaxLevel = 1999, Mob = "Mythological Pirate", QuestName = "DeepForestIsland",  QuestLv = 2, Pos = CFrame.new(-13320.0, 518.8, -6785.0)},
    {MinLevel = 2000, MaxLevel = 2199, Mob = "Reborn Skeleton",     QuestName = "HauntedQuest1",     QuestLv = 1, Pos = CFrame.new(-8769.5, 142.1, 6055.2)},
    {MinLevel = 2200, MaxLevel = 2449, Mob = "Cookie Crafter",      QuestName = "CakeQuest1",        QuestLv = 1, Pos = CFrame.new(-2333.2, 37.8, -12093.2)},
    {MinLevel = 2450, MaxLevel = 2699, Mob = "Ocean Prophet",       QuestName = "TikiQuest1",        QuestLv = 1, Pos = CFrame.new(11129.8, -2008.9, 10051.5)},
    {MinLevel = 2700, MaxLevel = 2724, Mob = "High Disciple",       QuestName = "TikiQuest2",        QuestLv = 1, Pos = CFrame.new(9778.4, -1994.3, 9877.0)},
    {MinLevel = 2725, MaxLevel = 9999, Mob = "Grand Devotee",       QuestName = "TikiQuest2",        QuestLv = 2, Pos = CFrame.new(9620.5, -1994.2, 9871.7)}
}

local BossList = {
    "Longma", "Stone", "Urban", "Diablo", "Cake Prince",
    "Dough King", "rip_indra True Form", "Beautiful Pirate", "Smoke Admiral"
}

local BossSpawnCFrames = {
    ["Longma"]              = CFrame.new(-10156.2, 331.6, -9445.9),
    ["Stone"]               = CFrame.new(-1109.9, 51.6, 6811.7),
    ["Urban"]               = CFrame.new(4486.7, 1208.3, -8.9),
    ["Diablo"]              = CFrame.new(-5414.4, 309.8, -2212.4),
    ["Cake Prince"]         = CFrame.new(-2021.3, 37.8, -12028.7),
    ["Dough King"]          = CFrame.new(-2021.3, 37.8, -12028.7),
    ["rip_indra True Form"] = CFrame.new(-5414.4, 309.8, -2212.4),
    ["Beautiful Pirate"]    = CFrame.new(5312.0, 22.0, -125.0),
    ["Smoke Admiral"]       = CFrame.new(-5078.0, 24.0, -5352.0)
}

local IslandLocations = {
    ["Floating Turtle"]   = CFrame.new(-12549.7, 336.3, -7487.3),
    ["Haunted Castle"]    = CFrame.new(-9515.0, 142.0, 5535.0),
    ["Castle on the Sea"] = CFrame.new(-5073.0, 315.0, -3153.0),
    ["Port Town"]         = CFrame.new(-317.0, 331.0, 597.0),
    ["Hydra Island"]      = CFrame.new(5290.0, 1005.0, 392.0),
    ["Great Tree"]        = CFrame.new(2681.0, 1682.0, -7190.0),
    ["Cake Loaf"]         = CFrame.new(-2021.3, 37.8, -12028.7),
    ["Tiki Outpost"]      = CFrame.new(-16541.0, 55.0, -172.0),
    ["Temple of Time"]    = CFrame.new(28286.3, 14895.3, 102.6),
    ["WindMill"]          = CFrame.new(979.0, 16.0, 1429.0)
}

local IslandNames = {
    "Floating Turtle", "Haunted Castle", "Castle on the Sea", "Port Town",
    "Hydra Island", "Great Tree", "Cake Loaf", "Tiki Outpost", "Temple of Time", "WindMill"
}

local Table_DevilFruitSniper = {
    "Kitsune-Kitsune", "Dragon (West)-Dragon (West)", "Dragon (East)-Dragon (East)",
    "Leopard-Leopard", "Dough-Dough", "T-Rex-T-Rex", "Mammoth-Mammoth",
    "Portal-Portal", "Buddha-Buddha", "Control-Control", "Hellfire (Gas)-Hellfire (Gas)",
    "Venom-Venom", "Spirit-Spirit", "Shadow-Shadow", "Rumble-Rumble", "Magma-Magma", "Light-Light"
}

local RaidChipsList = {
    "Flame", "Ice", "Quake", "Light", "Dark", "Spider",
    "Rumble", "Magma", "Buddha", "Sand", "Phoenix", "Dough"
}

local DatThgCodes = {
    "NOMOREHACK", "BANEXPLOIT", "WildDares", "BossBuild", "GetPranked", "EARN_FRUITS",
    "FIGHT4FRUIT", "NOEXPLOITER", "NOOB2ADMIN", "CODESLIDE", "ADMINHACKED", "ADMINDARES",
    "fruitconcepts", "krazydares", "TRIPLEABUSE", "SEATROLLING", "24NOADMIN", "REWARDFUN",
    "Chandler", "NEWTROLL", "KITT_RESET", "Sub2CaptainMaui", "kittgaming", "Sub2Fer999",
    "Enyu_is_Pro", "Magicbus", "JCWK", "Starcodeheo", "Bluxxy", "fudd10_v2",
    "SUB2GAMERROBOT_EXP1", "Sub2NoobMaster123", "Sub2UncleKizaru", "Sub2Daigrock",
    "Axiore", "TantaiGaming", "StrawHatMaine", "Sub2OfficialNoobie", "Fudd10", "Bignews",
    "TheGreatAce", "SECRET_ADMIN", "SUB2GAMERROBOT_RESET1", "SUB2OFFICIALNOOBIE", "AXIORE",
    "BIGNEWS", "BLUXXY", "CHANDLER", "ENYU_IS_PRO", "FUDD10", "FUDD10_V2", "KITTGAMING",
    "MAGICBUS", "STARCODEHEO", "STRAWHATMAINE", "SUB2CAPTAINMAUI", "SUB2DAIGROCK",
    "SUB2FER999", "SUB2NOOBMASTER123", "SUB2UNCLEKIZARU", "TANTAIGAMING", "THEGREATACE"
}

-- =================================================================================
-- 3. HỆ THỐNG LÕI ĐÃ FIX: TWEEN MƯỢT + BODYCLIP CHỐNG RƠI + TÌM QUÁI KÉP
-- =================================================================================
local BlurFixLag = Instance.new("BlurEffect")
BlurFixLag.Name = "AnimeBlacker_Blur"
BlurFixLag.Size = 100
BlurFixLag.Enabled = false
BlurFixLag.Parent = Lighting

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local function round(num)
    return math.floor((tonumber(num) or 0) + 0.5)
end

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title or "Anime Blacker V2"),
            Text = tostring(text or ""),
            Duration = tonumber(duration) or 3
        })
    end)
end

-- Kiểm tra xem có bất kỳ chế độ Farm/Di chuyển nào đang bật không
local function IsAnyFarmActive()
    return _G.AutoFarmLevel or _G.AutoFarmMob or _G.AutoFarmCake or _G.AutoFarmBone
        or _G.FarmChest or _G.AutoFarmBoss or _G.Greybeard or _G.AutoSaber
        or _G.AutoPoleV1 or _G.SecondSea or _G.Bartilo or _G.Factory
        or _G.AutoDarkbeard or _G.LawRaid or _G.FarmSwanGlasses or _G.OderSword
        or _G.ThirdSea or _G.MusketeerHat or _G.BudySword or _G.Carvender
        or _G.TwinHook or _G.tushita or _G.HolyTorch or _G.CDKQuest
        or _G.Guitar or _G.Rainbow_Haki or _G.AutoEliteHunter or _G.TyrantSkies
        or _G.TpSkullCore or _G.TweenMGear or _G.Seabest or _G.SegmentLeviathan
        or _G.DefendVolcano or _G.CollectBerry or _G.TeleportPly or _G.AutoNextIsland
        or _G.RaidPirate or _G.Tweenfruit
end

-- Quản lý BodyClip (BodyVelocity chống trọng lực kéo rớt nhân vật) & Noclip
RunService.Stepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not root then return end

        if IsAnyFarmActive() then
            if not root:FindFirstChild("AnimeBlacker_BodyClip") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "AnimeBlacker_BodyClip"
                bv.MaxForce = Vector3.new(100000, 100000, 100000)
                bv.Velocity = Vector3.zero
                bv.Parent = root
            end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        else
            local existing = root:FindFirstChild("AnimeBlacker_BodyClip")
            if existing then
                existing:Destroy()
            end
        end
    end)
end)

-- Hệ thống Tween thông minh (Không tự hủy Tween khi mục tiêu chưa đổi)
local ActiveTween = nil
local LastTargetPos = nil

local function StopTween(flagState)
    if flagState == false then
        if ActiveTween then
            pcall(function() ActiveTween:Cancel() end)
            ActiveTween = nil
        end
        LastTargetPos = nil
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and root:FindFirstChild("AnimeBlacker_BodyClip") then
            root.AnimeBlacker_BodyClip:Destroy()
        end
    end
end

local function GetPosOffset()
    local px = tonumber(_G.PosX) or 0
    local py = tonumber(_G.PosY) or 22
    local pz = tonumber(_G.PosZ) or 0
    if _G.SpinPos then
        local a = tick() * 4
        return CFrame.new(math.cos(a) * 16, py, math.sin(a) * 16)
    end
    return CFrame.new(px, py, pz)
end

local function topos(targetCF)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 or not targetCF then return end

        if hum.Sit then hum.Sit = false end

        local targetPos = targetCF.Position
        local dist = (root.Position - targetPos).Magnitude

        -- Tải trước khu vực nếu ở quá xa (StreamingEnabled)
        if dist > 400 and ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("RequestStreamAroundAsync") then
            pcall(function()
                ReplicatedStorage.Remotes.RequestStreamAroundAsync:FireServer(targetPos)
            end)
        end

        -- Nếu đã tới sát mục tiêu (< 18 studs), gán thẳng CFrame
        if dist <= 18 then
            if ActiveTween then
                pcall(function() ActiveTween:Cancel() end)
                ActiveTween = nil
            end
            LastTargetPos = nil
            root.CFrame = targetCF
            return
        end

        -- Nếu đang Tween tới cùng một vị trí (sai số < 8 studs), giữ nguyên Tween để nhân vật bay mượt
        if ActiveTween and LastTargetPos and (LastTargetPos - targetPos).Magnitude < 8 then
            return
        end

        if _G.TweenPosYHight and math.abs(root.Position.Y - targetPos.Y) > 65 then
            root.CFrame = CFrame.new(root.Position.X, targetPos.Y, root.Position.Z)
            dist = (root.Position - targetPos).Magnitude
        end

        if ActiveTween then
            pcall(function() ActiveTween:Cancel() end)
        end

        LastTargetPos = targetPos
        local speed = math.clamp(tonumber(_G.TweenSpeed) or 300, 50, 350)
        ActiveTween = TweenService:Create(
            root,
            TweenInfo.new(dist / speed, Enum.EasingStyle.Linear),
            {CFrame = targetCF}
        )
        ActiveTween:Play()
        ActiveTween.Completed:Connect(function()
            ActiveTween = nil
            LastTargetPos = nil
        end)
    end)
end

-- Hàm tìm Quái/Boss thông minh: Quét cả Workspace.Enemies lẫn ReplicatedStorage
local function FindTargetEntity(nameOrTable)
    local isTable = (type(nameOrTable) == "table")
    local enemies = Workspace:FindFirstChild("Enemies")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if enemies then
        local closest, minDist = nil, math.huge
        for _, v in ipairs(enemies:GetChildren()) do
            local match = isTable and (nameOrTable[v.Name] ~= nil or table.find(nameOrTable, v.Name) ~= nil)
                or (v.Name == nameOrTable or string.find(v.Name, tostring(nameOrTable)))
            if match then
                local hum = v:FindFirstChildOfClass("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    if myRoot then
                        local d = (hrp.Position - myRoot.Position).Magnitude
                        if d < minDist then
                            minDist = d
                            closest = v
                        end
                    else
                        return v
                    end
                end
            end
        end
        if closest then return closest, true end
    end

    -- Nếu chưa spawn vào Workspace.Enemies, kiểm tra trong ReplicatedStorage để lấy tọa độ bay tới
    for _, v in ipairs(ReplicatedStorage:GetChildren()) do
        local match = isTable and (nameOrTable[v.Name] ~= nil or table.find(nameOrTable, v.Name) ~= nil)
            or (v.Name == nameOrTable or string.find(v.Name, tostring(nameOrTable)))
        if match and v:IsA("Model") then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then
                return v, false
            end
        end
    end

    return nil, false
end

-- Hàm gỡ và trang bị vũ khí
local function UnEquipWeapon(name)
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not char or not bp then return false end
    local tool = char:FindFirstChild(tostring(name))
    if tool and tool:IsA("Tool") then
        tool.Parent = bp
        return true
    end
    return false
end

local function EquipWeapon(specificName)
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not char or not hum or not bp then return end

        local target = specificName or _G.SelectWeapon
        local targetTip = (target == "Fruit") and "Demon Fruit" or target

        local held = char:FindFirstChildOfClass("Tool")
        if held and (held.Name == target or held.ToolTip == targetTip or held:GetAttribute("WeaponType") == targetTip) then
            return
        end

        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t.Name == target or t.ToolTip == targetTip or t:GetAttribute("WeaponType") == targetTip) then
                hum:EquipTool(t)
                return
            end
        end
    end)
end

-- Hàm Gom Quái (BringMobs) kèm cấp quyền vật lý SimulationRadius
local function BringMobs(targetCF, exactName)
    if _G.BringMonster == false then return 0 end
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies or typeof(targetCF) ~= "CFrame" then return 0 end

    local range = tonumber(_G.BringMode) or 250
    local count = 0
    for _, enemy in ipairs(enemies:GetChildren()) do
        if not exactName or enemy.Name == exactName then
            local eroot = enemy:FindFirstChild("HumanoidRootPart")
            local ehum = enemy:FindFirstChildOfClass("Humanoid")
            if eroot and ehum and ehum.Health > 0 and (eroot.Position - targetCF.Position).Magnitude <= range then
                eroot.CanCollide = false
                eroot.CFrame = targetCF
                eroot.Velocity = Vector3.zero
                ehum.WalkSpeed = 0
                ehum.JumpPower = 0
                if ehum:FindFirstChild("Animator") then
                    ehum.Animator:Destroy()
                end
                local head = enemy:FindFirstChild("Head")
                if head then head.CanCollide = false end
                count = count + 1
            end
        end
    end
    if count > 0 and type(sethiddenproperty) == "function" then
        pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)
    end
    return count
end

-- Các hàm phụ trợ từ DatThg V2 (CheckBoat, Trophies, Hop)
local function CheckBoat()
    local boats = Workspace:FindFirstChild("Boats")
    if not boats then return false end
    for _, boat in ipairs(boats:GetChildren()) do
        local owner = boat:FindFirstChild("Owner")
        if owner and tostring(owner.Value) == tostring(LocalPlayer.Name) then
            return boat
        end
    end
    return false
end

local function getTrophies(amount)
    local castle = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Haunted Castle")
    if not castle or not castle:FindFirstChild("Trophies") then return nil end
    for _, trophy in ipairs(castle.Trophies.Quest:GetChildren()) do
        local handle = trophy:FindFirstChild("Handle")
        local number = tonumber(tostring(trophy.Name):match("%d+"))
        if handle and number == tonumber(amount) then
            local y = round(handle.Orientation.Y)
            if y == 90 or y == -90 then
                return {"A", 180, -180}
            elseif y == 0 or y == 180 or y == -180 then
                return {"B", -90, 90}
            end
        end
    end
    return nil
end

local function GetFirePlacard(number, side)
    pcall(function()
        local castle = Workspace.Map["Haunted Castle"]
        local placard = castle["Placard" .. tostring(number)][side]
        if tostring(placard.Indicator.BrickColor) ~= "Pearl" and fireclickdetector then
            fireclickdetector(placard.ClickDetector)
        end
    end)
end

local function Hop(lowerPlayerMode)
    pcall(function()
        local sortOrder = lowerPlayerMode and "Asc" or "Desc"
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100", game.PlaceId, sortOrder)
        local res = HttpService:JSONDecode(game:HttpGet(url))
        if res and res.data then
            for _, srv in ipairs(res.data) do
                if type(srv) == "table" and srv.playing and srv.maxPlayers and srv.playing < srv.maxPlayers - 1 and srv.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    task.wait(2)
                    break
                end
            end
        end
    end)
end

-- =================================================================================
-- 4. HỆ THỐNG GIAO DIỆN ĐÃ FIX CẢM ỨNG MOBILE (FRAME + MOUSEBUTTON1CLICK)
-- =================================================================================
local SFXFolder = Instance.new("Folder", CoreGui)
SFXFolder.Name = "AnimeBlacker_SFX"

local ClickSnd = Instance.new("Sound", SFXFolder)
ClickSnd.SoundId = "rbxassetid://6042053626"
ClickSnd.Volume = 0.7

local function PlayClick()
    pcall(function()
        local s = ClickSnd:Clone()
        s.Parent = SFXFolder
        s:Play()
        s.Ended:Connect(function() s:Destroy() end)
    end)
end

local Viewport = Workspace.CurrentCamera.ViewportSize
local CurrentScale = math.clamp(Viewport.Y / 450, 0.65, 1.35)

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AnimeBlacker_FixedUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local UIScaleObj = Instance.new("UIScale", ScreenGui)
UIScaleObj.Scale = CurrentScale

local function ApplyUIScaleMode(mode)
    local div = 450
    if mode == "Small" then div = 570
    elseif mode == "Medium" then div = 500
    elseif mode == "Large" then div = 450
    elseif mode == "Bigger" then div = 390 end
    CurrentScale = math.clamp(Workspace.CurrentCamera.ViewportSize.Y / div, 0.55, 1.5)
    UIScaleObj.Scale = CurrentScale
end

local function TweenProp(obj, prop, val, duration, waitFlag)
    local tw = TweenService:Create(obj, TweenInfo.new(duration or 0.22, Enum.EasingStyle.Quint), {[prop] = val})
    tw:Play()
    if waitFlag then tw.Completed:Wait() end
    return tw
end

local function MakeDrag(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = target.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + (delta.X / CurrentScale),
                startPos.Y.Scale,
                startPos.Y.Offset + (delta.Y / CurrentScale)
            )
        end
    end)
end

-- Nút Nổi Bật/Tắt Menu
local FloatToggle = Instance.new("ImageButton", ScreenGui)
FloatToggle.Size = UDim2.fromOffset(44, 44)
FloatToggle.Position = UDim2.fromScale(0.12, 0.15)
FloatToggle.BackgroundColor3 = Color3.fromRGB(18, 14, 26)
FloatToggle.Image = "rbxassetid://103005206148603"
FloatToggle.AutoButtonColor = false
Instance.new("UICorner", FloatToggle).CornerRadius = UDim.new(0, 8)
local FloatStroke = Instance.new("UIStroke", FloatToggle)
FloatStroke.Color = Color3.fromRGB(255, 45, 95)
FloatStroke.Thickness = 2
MakeDrag(FloatToggle, FloatToggle)

-- Khung Chính (Sử dụng Frame thay vì ImageButton để không nuốt thao tác chạm của nút con)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "Hub"
MainFrame.Size = UDim2.fromOffset(600, 400)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 14, 22)
MainFrame.BackgroundTransparency = 0.03
MainFrame.Active = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 9)

local MainGrad = Instance.new("UIGradient", MainFrame)
MainGrad.Rotation = 45
MainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(18, 15, 25)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(28, 20, 38)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(18, 15, 25))
})

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(255, 45, 95)
MainStroke.Thickness = 1.8

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 18, 32)
TopBar.BackgroundTransparency = 0.2
TopBar.Active = true
MakeDrag(TopBar, MainFrame)

local TitleLbl = Instance.new("TextLabel", TopBar)
TitleLbl.Position = UDim2.new(0, 14, 0.5, 0)
TitleLbl.AnchorPoint = Vector2.new(0, 0.5)
TitleLbl.AutomaticSize = Enum.AutomaticSize.XY
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font = Enum.Font.GothamBlack
TitleLbl.Text = "⚡ ANIME BLACKER V2"
TitleLbl.TextColor3 = Color3.fromRGB(255, 50, 100)
TitleLbl.TextSize = 14
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local SubLbl = Instance.new("TextLabel", TitleLbl)
SubLbl.Size = UDim2.fromScale(0, 1)
SubLbl.AutomaticSize = Enum.AutomaticSize.X
SubLbl.AnchorPoint = Vector2.new(0, 1)
SubLbl.Position = UDim2.new(1, 8, 0.9, 0)
SubLbl.BackgroundTransparency = 1
SubLbl.Font = Enum.Font.GothamMedium
SubLbl.Text = "🟢 Đã Fix 100% | Full DatThg V2"
SubLbl.TextColor3 = Color3.fromRGB(100, 255, 160)
SubLbl.TextSize = 10
SubLbl.TextXAlignment = Enum.TextXAlignment.Left
SubLbl.TextYAlignment = Enum.TextYAlignment.Bottom

local CloseBtn = Instance.new("ImageButton", TopBar)
CloseBtn.Size = UDim2.fromOffset(18, 18)
CloseBtn.Position = UDim2.new(1, -12, 0.5, 0)
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Image = "rbxassetid://10747384394"

local MinBtn = Instance.new("ImageButton", TopBar)
MinBtn.Size = UDim2.fromOffset(18, 18)
MinBtn.Position = UDim2.new(1, -38, 0.5, 0)
MinBtn.AnchorPoint = Vector2.new(1, 0.5)
MinBtn.BackgroundTransparency = 1
MinBtn.Image = "rbxassetid://10734896206"

local TabScroll = Instance.new("ScrollingFrame", MainFrame)
TabScroll.Size = UDim2.new(0, 165, 1, -32)
TabScroll.Position = UDim2.new(0, 0, 1, 0)
TabScroll.AnchorPoint = Vector2.new(0, 1)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 2
TabScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 45, 95)
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabScroll.CanvasSize = UDim2.new()

local TPad = Instance.new("UIPadding", TabScroll)
TPad.PaddingLeft = UDim.new(0, 10)
TPad.PaddingRight = UDim.new(0, 10)
TPad.PaddingTop = UDim.new(0, 8)
TPad.PaddingBottom = UDim.new(0, 10)

local TLayout = Instance.new("UIListLayout", TabScroll)
TLayout.Padding = UDim.new(0, 5)
TLayout.SortOrder = Enum.SortOrder.LayoutOrder

local Containers = Instance.new("Frame", MainFrame)
Containers.Size = UDim2.new(1, -165, 1, -32)
Containers.Position = UDim2.new(1, 0, 1, 0)
Containers.AnchorPoint = Vector2.new(1, 1)
Containers.BackgroundTransparency = 1
Containers.ClipsDescendants = true

local isMin = false
local oldSize = MainFrame.Size
MinBtn.MouseButton1Click:Connect(function()
    PlayClick()
    if isMin then
        MinBtn.Image = "rbxassetid://10734896206"
        TweenProp(MainFrame, "Size", oldSize, 0.25, true)
        isMin = false
    else
        MinBtn.Image = "rbxassetid://10734924532"
        oldSize = MainFrame.Size
        TweenProp(MainFrame, "Size", UDim2.fromOffset(MainFrame.Size.X.Offset, 32), 0.25, true)
        isMin = true
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    PlayClick()
    StopTween(false)
    ScreenGui:Destroy()
end)

FloatToggle.MouseButton1Click:Connect(function()
    PlayClick()
    MainFrame.Visible = not MainFrame.Visible
end)

local TabsList = {}
local FirstTab = false

local function CreateTab(name, icon)
    local Btn = Instance.new("TextButton", TabScroll)
    Btn.Size = UDim2.new(1, 0, 0, 28)
    Btn.BackgroundColor3 = Color3.fromRGB(26, 22, 36)
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local Bar = Instance.new("Frame", Btn)
    Bar.Size = FirstTab and UDim2.fromOffset(4, 4) or UDim2.fromOffset(4, 14)
    Bar.Position = UDim2.new(0, 2, 0.5, 0)
    Bar.AnchorPoint = Vector2.new(0, 0.5)
    Bar.BackgroundColor3 = Color3.fromRGB(255, 45, 95)
    Bar.BackgroundTransparency = FirstTab and 1 or 0
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(0.5, 0)

    local Ico = Instance.new("ImageLabel", Btn)
    Ico.Size = UDim2.fromOffset(14, 14)
    Ico.Position = UDim2.new(0, 10, 0.5, 0)
    Ico.AnchorPoint = Vector2.new(0, 0.5)
    Ico.BackgroundTransparency = 1
    Ico.Image = icon or ""
    Ico.ImageTransparency = FirstTab and 0.35 or 0

    local Txt = Instance.new("TextLabel", Btn)
    Txt.Size = UDim2.new(1, -30, 1, 0)
    Txt.Position = UDim2.fromOffset(28, 0)
    Txt.BackgroundTransparency = 1
    Txt.Font = Enum.Font.GothamBold
    Txt.Text = name
    Txt.TextColor3 = Color3.fromRGB(240, 240, 250)
    Txt.TextSize = 10
    Txt.TextXAlignment = Enum.TextXAlignment.Left
    Txt.TextTransparency = FirstTab and 0.35 or 0

    local Page = Instance.new("ScrollingFrame", Containers)
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Color3.fromRGB(255, 45, 95)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new()
    Page.Visible = not FirstTab
    FirstTab = true

    local PPad = Instance.new("UIPadding", Page)
    PPad.PaddingLeft = UDim.new(0, 10)
    PPad.PaddingRight = UDim.new(0, 10)
    PPad.PaddingTop = UDim.new(0, 8)
    PPad.PaddingBottom = UDim.new(0, 14)

    local PList = Instance.new("UIListLayout", Page)
    PList.Padding = UDim.new(0, 5)
    PList.SortOrder = Enum.SortOrder.LayoutOrder

    local entry = {Btn = Btn, Page = Page, Bar = Bar, Txt = Txt, Ico = Ico}
    table.insert(TabsList, entry)

    Btn.MouseButton1Click:Connect(function()
        PlayClick()
        for _, v in ipairs(TabsList) do
            if v == entry then
                v.Page.Visible = true
                TweenProp(v.Txt, "TextTransparency", 0, 0.2)
                TweenProp(v.Ico, "ImageTransparency", 0, 0.2)
                TweenProp(v.Bar, "Size", UDim2.fromOffset(4, 14), 0.2)
                TweenProp(v.Bar, "BackgroundTransparency", 0, 0.2)
            else
                v.Page.Visible = false
                TweenProp(v.Txt, "TextTransparency", 0.35, 0.2)
                TweenProp(v.Ico, "ImageTransparency", 0.35, 0.2)
                TweenProp(v.Bar, "Size", UDim2.fromOffset(4, 4), 0.2)
                TweenProp(v.Bar, "BackgroundTransparency", 1, 0.2)
            end
        end
    end)

    local TabAPI = {}

    function TabAPI:Section(title)
        local F = Instance.new("Frame", Page)
        F.Size = UDim2.new(1, 0, 0, 22)
        F.BackgroundTransparency = 1
        local L = Instance.new("TextLabel", F)
        L.Size = UDim2.new(1, -10, 1, 0)
        L.Position = UDim2.fromOffset(4, 0)
        L.BackgroundTransparency = 1
        L.Font = Enum.Font.GothamBlack
        L.Text = "◈ " .. tostring(title)
        L.TextColor3 = Color3.fromRGB(255, 55, 105)
        L.TextSize = 12
        L.TextXAlignment = Enum.TextXAlignment.Left
    end

    function TabAPI:Paragraph(title, desc)
        local F = Instance.new("Frame", Page)
        F.Size = UDim2.new(1, 0, 0, 36)
        F.AutomaticSize = Enum.AutomaticSize.Y
        F.BackgroundColor3 = Color3.fromRGB(26, 22, 36)
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)

        local TL = Instance.new("TextLabel", F)
        TL.Size = UDim2.new(1, -20, 0, 14)
        TL.Position = UDim2.fromOffset(10, 5)
        TL.BackgroundTransparency = 1
        TL.Font = Enum.Font.GothamBold
        TL.Text = tostring(title)
        TL.TextColor3 = Color3.fromRGB(245, 245, 255)
        TL.TextSize = 11
        TL.TextXAlignment = Enum.TextXAlignment.Left

        local DL = Instance.new("TextLabel", F)
        DL.Size = UDim2.new(1, -20, 0, 14)
        DL.Position = UDim2.fromOffset(10, 19)
        DL.BackgroundTransparency = 1
        DL.Font = Enum.Font.Gotham
        DL.Text = tostring(desc or "")
        DL.TextColor3 = Color3.fromRGB(185, 185, 210)
        DL.TextSize = 10
        DL.TextXAlignment = Enum.TextXAlignment.Left

        return {
            Set = function(_, newVal)
                DL.Text = tostring(newVal)
            end
        }
    end

    function TabAPI:DiscordInvite(nameTitle, logoId, descText, inviteUrl)
        local Holder = Instance.new("Frame", Page)
        Holder.Size = UDim2.new(1, 0, 0, 74)
        Holder.BackgroundColor3 = Color3.fromRGB(26, 22, 36)
        Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)

        local Img = Instance.new("ImageLabel", Holder)
        Img.Size = UDim2.fromOffset(32, 32)
        Img.Position = UDim2.fromOffset(10, 8)
        Img.BackgroundTransparency = 1
        Img.Image = logoId
        Instance.new("UICorner", Img).CornerRadius = UDim.new(0, 5)

        local TL = Instance.new("TextLabel", Holder)
        TL.Size = UDim2.new(1, -55, 0, 14)
        TL.Position = UDim2.fromOffset(48, 8)
        TL.BackgroundTransparency = 1
        TL.Font = Enum.Font.GothamBold
        TL.Text = nameTitle
        TL.TextColor3 = Color3.fromRGB(255, 255, 255)
        TL.TextSize = 11
        TL.TextXAlignment = Enum.TextXAlignment.Left

        local DL = Instance.new("TextLabel", Holder)
        DL.Size = UDim2.new(1, -55, 0, 22)
        DL.Position = UDim2.fromOffset(48, 22)
        DL.BackgroundTransparency = 1
        DL.Font = Enum.Font.Gotham
        DL.Text = descText
        DL.TextColor3 = Color3.fromRGB(180, 180, 200)
        DL.TextSize = 9
        DL.TextWrapped = true
        DL.TextXAlignment = Enum.TextXAlignment.Left

        local JoinB = Instance.new("TextButton", Holder)
        JoinB.Size = UDim2.new(1, -20, 0, 18)
        JoinB.Position = UDim2.new(0, 10, 1, -23)
        JoinB.BackgroundColor3 = Color3.fromRGB(45, 160, 75)
        JoinB.Font = Enum.Font.GothamBold
        JoinB.Text = "Join Discord (" .. inviteUrl .. ")"
        JoinB.TextColor3 = Color3.fromRGB(255, 255, 255)
        JoinB.TextSize = 10
        Instance.new("UICorner", JoinB).CornerRadius = UDim.new(0, 4)

        JoinB.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(inviteUrl) end
            JoinB.Text = "Copied to Clipboard!"
            task.wait(2)
            JoinB.Text = "Join Discord (" .. inviteUrl .. ")"
        end)
    end

    function TabAPI:Button(title, callback)
        local B = Instance.new("TextButton", Page)
        B.Size = UDim2.new(1, 0, 0, 28)
        B.BackgroundColor3 = Color3.fromRGB(26, 22, 36)
        B.Text = ""
        B.AutoButtonColor = false
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)

        local TL = Instance.new("TextLabel", B)
        TL.Size = UDim2.new(1, -36, 1, 0)
        TL.Position = UDim2.fromOffset(10, 0)
        TL.BackgroundTransparency = 1
        TL.Font = Enum.Font.GothamMedium
        TL.Text = tostring(title)
        TL.TextColor3 = Color3.fromRGB(240, 240, 250)
        TL.TextSize = 11
        TL.TextXAlignment = Enum.TextXAlignment.Left

        local Ic = Instance.new("ImageLabel", B)
        Ic.Size = UDim2.fromOffset(14, 14)
        Ic.Position = UDim2.new(1, -10, 0.5, 0)
        Ic.AnchorPoint = Vector2.new(1, 0.5)
        Ic.BackgroundTransparency = 1
        Ic.Image = "rbxassetid://10709791437"

        B.MouseButton1Click:Connect(function()
            PlayClick()
            TweenProp(B, "BackgroundColor3", Color3.fromRGB(50, 25, 45), 0.1)
            task.delay(0.12, function()
                TweenProp(B, "BackgroundColor3", Color3.fromRGB(26, 22, 36), 0.15)
            end)
            if callback then task.spawn(callback) end
        end)
    end

    function TabAPI:Toggle(title, flagKey, callback)
        local B = Instance.new("TextButton", Page)
        B.Size = UDim2.new(1, 0, 0, 28)
        B.BackgroundColor3 = Color3.fromRGB(26, 22, 36)
        B.Text = ""
        B.AutoButtonColor = false
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)

        local TL = Instance.new("TextLabel", B)
        TL.Size = UDim2.new(1, -55, 1, 0)
        TL.Position = UDim2.fromOffset(10, 0)
        TL.BackgroundTransparency = 1
        TL.Font = Enum.Font.GothamMedium
        TL.Text = tostring(title)
        TL.TextColor3 = Color3.fromRGB(240, 240, 250)
        TL.TextSize = 11
        TL.TextXAlignment = Enum.TextXAlignment.Left

        local Sw = Instance.new("Frame", B)
        Sw.Size = UDim2.fromOffset(36, 18)
        Sw.Position = UDim2.new(1, -10, 0.5, 0)
        Sw.AnchorPoint = Vector2.new(1, 0.5)
        Sw.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
        Instance.new("UICorner", Sw).CornerRadius = UDim.new(0.5, 0)

        local Kn = Instance.new("Frame", Sw)
        Kn.Size = UDim2.fromOffset(12, 12)
        Kn.Position = UDim2.new(0, 3, 0.5, 0)
        Kn.AnchorPoint = Vector2.new(0, 0.5)
        Kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", Kn).CornerRadius = UDim.new(0.5, 0)

        local function Refresh()
            local st = _G[flagKey] == true
            if st then
                TweenProp(Sw, "BackgroundColor3", Color3.fromRGB(255, 45, 95), 0.2)
                TweenProp(Kn, "Position", UDim2.new(1, -15, 0.5, 0), 0.2)
                SubLbl.Text = "⚡ Đang bật: " .. tostring(title)
            else
                TweenProp(Sw, "BackgroundColor3", Color3.fromRGB(45, 40, 60), 0.2)
                TweenProp(Kn, "Position", UDim2.new(0, 3, 0.5, 0), 0.2)
            end
        end
        Refresh()

        B.MouseButton1Click:Connect(function()
            _G[flagKey] = not _G[flagKey]
            PlayClick()
            Refresh()
            if callback then task.spawn(callback, _G[flagKey]) end
        end)
    end

    function TabAPI:Dropdown(title, optionsList, flagKey, callback)
        local B = Instance.new("TextButton", Page)
        B.Size = UDim2.new(1, 0, 0, 28)
        B.BackgroundColor3 = Color3.fromRGB(26, 22, 36)
        B.Text = ""
        B.AutoButtonColor = false
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)

        local TL = Instance.new("TextLabel", B)
        TL.Size = UDim2.new(1, -170, 1, 0)
        TL.Position = UDim2.fromOffset(10, 0)
        TL.BackgroundTransparency = 1
        TL.Font = Enum.Font.GothamMedium
        TL.Text = tostring(title)
        TL.TextColor3 = Color3.fromRGB(240, 240, 250)
        TL.TextSize = 11
        TL.TextXAlignment = Enum.TextXAlignment.Left

        local Box = Instance.new("Frame", B)
        Box.Size = UDim2.fromOffset(145, 20)
        Box.Position = UDim2.new(1, -10, 0.5, 0)
        Box.AnchorPoint = Vector2.new(1, 0.5)
        Box.BackgroundColor3 = Color3.fromRGB(40, 34, 56)
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)

        local idx = 1
        for i, v in ipairs(optionsList) do
            if tostring(v) == tostring(_G[flagKey]) then
                idx = i
                break
            end
        end

        local VL = Instance.new("TextLabel", Box)
        VL.Size = UDim2.new(1, -12, 1, 0)
        VL.Position = UDim2.fromOffset(6, 0)
        VL.BackgroundTransparency = 1
        VL.Font = Enum.Font.GothamBold
        VL.Text = "🔁 " .. tostring(optionsList[idx] or "...")
        VL.TextColor3 = Color3.fromRGB(255, 80, 130)
        VL.TextSize = 10
        VL.TextTruncate = Enum.TextTruncate.AtEnd

        B.MouseButton1Click:Connect(function()
            PlayClick()
            if #optionsList == 0 then return end
            idx = idx + 1
            if idx > #optionsList then idx = 1 end
            local val = optionsList[idx]
            _G[flagKey] = val
            VL.Text = "🔁 " .. tostring(val)
            if callback then task.spawn(callback, val) end
        end)
    end

    function TabAPI:Slider(title, minV, maxV, stepV, flagKey, callback)
        local F = Instance.new("Frame", Page)
        F.Size = UDim2.new(1, 0, 0, 32)
        F.BackgroundColor3 = Color3.fromRGB(26, 22, 36)
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)

        local TL = Instance.new("TextLabel", F)
        TL.Size = UDim2.new(0.48, -10, 1, 0)
        TL.Position = UDim2.fromOffset(10, 0)
        TL.BackgroundTransparency = 1
        TL.Font = Enum.Font.GothamMedium
        TL.Text = tostring(title)
        TL.TextColor3 = Color3.fromRGB(240, 240, 250)
        TL.TextSize = 11
        TL.TextXAlignment = Enum.TextXAlignment.Left

        local MinusB = Instance.new("TextButton", F)
        MinusB.Size = UDim2.fromOffset(24, 20)
        MinusB.Position = UDim2.new(1, -115, 0.5, 0)
        MinusB.AnchorPoint = Vector2.new(0, 0.5)
        MinusB.BackgroundColor3 = Color3.fromRGB(45, 30, 50)
        MinusB.Font = Enum.Font.GothamBlack
        MinusB.Text = "-"
        MinusB.TextColor3 = Color3.fromRGB(255, 80, 120)
        MinusB.TextSize = 14
        Instance.new("UICorner", MinusB).CornerRadius = UDim.new(0, 4)

        local VL = Instance.new("TextLabel", F)
        VL.Size = UDim2.fromOffset(50, 20)
        VL.Position = UDim2.new(1, -88, 0.5, 0)
        VL.AnchorPoint = Vector2.new(0, 0.5)
        VL.BackgroundTransparency = 1
        VL.Font = Enum.Font.FredokaOne
        VL.Text = tostring(_G[flagKey] or minV)
        VL.TextColor3 = Color3.fromRGB(255, 65, 115)
        VL.TextSize = 12

        local PlusB = Instance.new("TextButton", F)
        PlusB.Size = UDim2.fromOffset(24, 20)
        PlusB.Position = UDim2.new(1, -34, 0.5, 0)
        PlusB.AnchorPoint = Vector2.new(0, 0.5)
        PlusB.BackgroundColor3 = Color3.fromRGB(45, 30, 50)
        PlusB.Font = Enum.Font.GothamBlack
        PlusB.Text = "+"
        PlusB.TextColor3 = Color3.fromRGB(100, 255, 150)
        PlusB.TextSize = 14
        Instance.new("UICorner", PlusB).CornerRadius = UDim.new(0, 4)

        local function UpdateVal(v)
            v = math.clamp(math.floor((v / stepV) + 0.5) * stepV, minV, maxV)
            _G[flagKey] = v
            VL.Text = tostring(v)
            if callback then task.spawn(callback, v) end
        end

        MinusB.MouseButton1Click:Connect(function()
            PlayClick()
            UpdateVal((tonumber(_G[flagKey]) or minV) - stepV)
        end)
        PlusB.MouseButton1Click:Connect(function()
            PlayClick()
            UpdateVal((tonumber(_G[flagKey]) or minV) + stepV)
        end)
    end

    function TabAPI:TextBox(title, placeholder, flagKey, callback)
        local F = Instance.new("Frame", Page)
        F.Size = UDim2.new(1, 0, 0, 28)
        F.BackgroundColor3 = Color3.fromRGB(26, 22, 36)
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)

        local TL = Instance.new("TextLabel", F)
        TL.Size = UDim2.new(1, -170, 1, 0)
        TL.Position = UDim2.fromOffset(10, 0)
        TL.BackgroundTransparency = 1
        TL.Font = Enum.Font.GothamMedium
        TL.Text = tostring(title)
        TL.TextColor3 = Color3.fromRGB(240, 240, 250)
        TL.TextSize = 11
        TL.TextXAlignment = Enum.TextXAlignment.Left

        local TB = Instance.new("TextBox", F)
        TB.Size = UDim2.fromOffset(145, 20)
        TB.Position = UDim2.new(1, -10, 0.5, 0)
        TB.AnchorPoint = Vector2.new(1, 0.5)
        TB.BackgroundColor3 = Color3.fromRGB(40, 34, 56)
        TB.Font = Enum.Font.GothamBold
        TB.PlaceholderText = placeholder
        TB.Text = tostring(_G[flagKey] or "")
        TB.TextColor3 = Color3.fromRGB(255, 255, 255)
        TB.TextSize = 10
        TB.ClearTextOnFocus = false
        Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 4)

        TB.FocusLost:Connect(function()
            _G[flagKey] = TB.Text
            if callback then task.spawn(callback, TB.Text) end
        end)
    end

    return TabAPI
end

-- =================================================================================
-- 5. DỰNG ĐẦY ĐỦ 13 TABS GIAO DIỆN
-- =================================================================================
local TabDiscord  = CreateTab("Discord",       "rbxassetid://10723415903")
local TabFarm     = CreateTab("Farm",          "rbxassetid://10723407389")
local TabSetting  = CreateTab("Setting",       "rbxassetid://10734950309")
local TabQuest    = CreateTab("Quest/Item",    "rbxassetid://10734975692")
local TabRace     = CreateTab("Race/Mirage",   "rbxassetid://10747372167")
local TabEvent    = CreateTab("Event",         "rbxassetid://10709783577")
local TabPlayer   = CreateTab("Player",        "rbxassetid://10747373176")
local TabVisual   = CreateTab("Visual",        "rbxassetid://10723346959")
local TabRaid     = CreateTab("Raid",          "rbxassetid://10723345749")
local TabTeleport = CreateTab("Teleport",      "rbxassetid://10723434557")
local TabShop     = CreateTab("Shop",          "rbxassetid://10734952479")
local TabFruit    = CreateTab("Devil Fruit",   "rbxassetid://10709761889")
local TabMisc     = CreateTab("Miscellaneous", "rbxassetid://10709782582")

-- [1] TAB DISCORD & STATUS
TabDiscord:Section("Join Discord")
TabDiscord:DiscordInvite(
    "Anime Blacker x DatThg",
    "rbxassetid://103005206148603",
    "Join our discord community to receive information about the next update",
    "https://discord.com/invite/E2N7w35zkt"
)
TabDiscord:Section("Status Player")
local P_Time   = TabDiscord:Paragraph("Executer Time", "00:00:00")
local P_Race   = TabDiscord:Paragraph("Race", "")
local P_Beli   = TabDiscord:Paragraph("Beli", "")
local P_Frag   = TabDiscord:Paragraph("Fragments", "")
local P_Bounty = TabDiscord:Paragraph("Bounty", "")
local P_Fruit  = TabDiscord:Paragraph("Devil Fruit", "")

task.spawn(function()
    local startT = os.time()
    while task.wait(1) do
        pcall(function()
            local d = os.time() - startT
            P_Time:Set(string.format("%02d Hours %02d Minutes %02d Seconds", math.floor(d / 3600), math.floor((d % 3600) / 60), d % 60))
            local pdata = LocalPlayer:FindFirstChild("Data")
            if pdata then
                if pdata:FindFirstChild("Race") then P_Race:Set("Race: " .. tostring(pdata.Race.Value)) end
                if pdata:FindFirstChild("Beli") then P_Beli:Set("Beli: " .. tostring(pdata.Beli.Value)) end
                if pdata:FindFirstChild("Fragments") then P_Frag:Set("Fragments: " .. tostring(pdata.Fragments.Value)) end
                if pdata:FindFirstChild("DevilFruit") then
                    local f = tostring(pdata.DevilFruit.Value)
                    P_Fruit:Set(f ~= "" and f or "Not Have Devil Fruit")
                end
            end
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls and ls:FindFirstChild("Bounty/Honor") then
                P_Bounty:Set("Bounty: " .. tostring(ls["Bounty/Honor"].Value))
            end
        end)
    end
end)

-- [2] TAB FARM
TabFarm:Section("Farm Mode")
TabFarm:Dropdown("Select Weapon", {"Melee", "Sword", "Fruit", "Gun"}, "SelectWeapon")
TabFarm:Dropdown("UI Scale", {"Small", "Medium", "Large", "Bigger"}, "UIScale", function(v)
    ApplyUIScaleMode(v)
end)

TabFarm:Section("Farming")
TabFarm:Toggle("Auto Farm Level (Tự Nhận Quest)", "AutoFarmLevel", StopTween)
TabFarm:Dropdown("Select Mob (Sea 3)", MobList, "SelectedMob")
TabFarm:Toggle("Auto Farm Selected Mob", "AutoFarmMob", StopTween)
TabFarm:Toggle("Auto Farm Cake Prince (4 Mobs)", "AutoFarmCake", StopTween)
TabFarm:Toggle("Auto Farm Bone (4 Mobs)", "AutoFarmBone", StopTween)
TabFarm:Toggle("Auto Farm Chest", "FarmChest", StopTween)

TabFarm:Section("Boss Farming")
TabFarm:Dropdown("Select Boss", BossList, "SelectBoss")
TabFarm:Toggle("Auto Farm Boss", "AutoFarmBoss", StopTween)

-- [3] TAB SETTING
TabSetting:Section("Speed Tween & Offset")
TabSetting:Slider("Tween Speed", 50, 350, 25, "TweenSpeed")
TabSetting:Toggle("Tween PosY Hight", "TweenPosYHight")
TabSetting:Toggle("Spin Pos", "SpinPos")
TabSetting:Slider("Select PosX", 0, 100, 5, "PosX")
TabSetting:Slider("Select PosY", 5, 100, 5, "PosY")
TabSetting:Slider("Select PosZ", 0, 100, 5, "PosZ")
TabSetting:Button("Stop All Tween", function()
    StopTween(false)
end)

TabSetting:Section("Setting Farming")
TabSetting:Toggle("Auto Click", "AutoClick")
TabSetting:Toggle("Auto Shoot Gun", "AutoShootGun")
TabSetting:Toggle("Bring Mob", "BringMonster")
TabSetting:Dropdown("Bring Mob Mode", {100, 200, 250, 300, 350, 400, 500}, "BringMode")
TabSetting:Toggle("Auto Haki", "AutoHaki")
TabSetting:Toggle("Auto Ken", "Observation")
TabSetting:Toggle("Kill Aura (Quét Sạch Quái Gần)", "Kill_Aura")
TabSetting:Toggle("Infinite Stamina", "InfiniteStam")
TabSetting:Toggle("Disabled Notifications", "DisableNotifications")
TabSetting:Toggle("Disabled Damage Counter", "DisableDamageCounter")
TabSetting:Toggle("Fix Lag Screen", "FixLagBlur", function(st)
    BlurFixLag.Enabled = st
end)
TabSetting:Toggle("White Screen", "WhiteScreen", function(st)
    pcall(function() RunService:Set3dRenderingEnabled(not st) end)
end)
TabSetting:Toggle("Invisible Monsters", "InvisibleMonsters")
TabSetting:Button("Fps Boost (Clean Lag)", function()
    pcall(function()
        if setfpscap then setfpscap(9999999) end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Texture") or v:IsA("Decal") then
                v:Destroy()
            elseif v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
            end
        end
        Notify("Anime Blacker", "FPS Boost & Clean Lag Activated!", 3)
    end)
end)

-- [4] TAB QUEST / ITEM
TabQuest:Paragraph("Sea 1 / Sea 2 / Sea 3", "Đã nối đầy đủ 100% luồng thực thi cho mọi Quest")
TabQuest:Section("World 1 - Quest And Item")
TabQuest:Toggle("Auto Greybeard", "Greybeard", StopTween)
TabQuest:Toggle("Auto Saber", "AutoSaber", StopTween)
TabQuest:Toggle("Auto Pole v1", "AutoPoleV1", StopTween)

TabQuest:Section("World 2 - Quest And Item")
TabQuest:Toggle("Auto Second Sea", "SecondSea", StopTween)
TabQuest:Toggle("Auto Bartilo Quest", "Bartilo", StopTween)
TabQuest:Toggle("Auto Factory", "Factory", StopTween)
TabQuest:Toggle("Auto Darkbeard", "AutoDarkbeard", StopTween)
TabQuest:Toggle("Auto Swan Glasses", "FarmSwanGlasses", StopTween)
TabQuest:Toggle("Auto Oder Sword", "OderSword", StopTween)

TabQuest:Section("Misc KoKo Sword (Law Raid)")
TabQuest:Toggle("Auto Law", "LawRaid", StopTween)
TabQuest:Toggle("Auto Law Hop", "AutoLawHop", StopTween)
TabQuest:Button("Buy Microchip Law Boss", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward", "Microchip", "2") end)
end)
TabQuest:Button("Start Go To Raid Law Boss", function()
    pcall(function()
        if Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("CircleIsland") then
            fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
        end
    end)
end)

TabQuest:Section("World 3 - Quest And Item")
TabQuest:Toggle("Auto Third Sea", "ThirdSea", StopTween)
TabQuest:Toggle("Auto Musketeer Hat & Citizen Quest", "MusketeerHat", StopTween)
TabQuest:Toggle("Auto Buddy Sword (Cake Queen)", "BudySword", StopTween)
TabQuest:Toggle("Auto Cavander (Beautiful Pirate)", "Carvender", StopTween)
TabQuest:Toggle("Auto Twin Hooks (Captain Elephant)", "TwinHook", StopTween)
TabQuest:Toggle("Auto Tushita (Longma)", "tushita", StopTween)
TabQuest:Toggle("Auto Holy Torch", "HolyTorch", StopTween)
TabQuest:Toggle("Auto CDK Quest (Yama/Tushita)", "CDKQuest", StopTween)
TabQuest:Toggle("Auto Soul Guitar Puzzle", "Guitar", StopTween)
TabQuest:Toggle("Auto Rainbow Haki", "Rainbow_Haki", StopTween)
TabQuest:Toggle("Auto Elite Hunter (Diablo/Urban)", "AutoEliteHunter", StopTween)
TabQuest:Toggle("Auto Tyrant of the Skies", "TyrantSkies", StopTween)
TabQuest:Toggle("Auto Buy Legendary Sword Hop", "BuyLegendarySword_Hop")
TabQuest:Button("Buy Legendary Sword Now (1/2/3)", function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "1")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "2")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "3")
    end)
end)

-- [5] TAB RACE / MIRAGE
TabRace:Section("Mirage Island & Race V4")
TabRace:Toggle("Teleport To Skull Core / Temple of Time", "TpSkullCore", StopTween)
TabRace:Toggle("Tween Mirage Gear", "TweenMGear", StopTween)
TabRace:Toggle("Auto Buy Gear", "BuyGear")
TabRace:Toggle("Auto Use Race V3 Skill", "AutoRaceV3")
TabRace:Toggle("Auto Awakening Race V4", "AutoRaceV4")

-- [6] TAB EVENT
TabEvent:Section("Sea Events & Leviathan")
TabEvent:Toggle("Auto Sea Beast", "Seabest", StopTween)
TabEvent:Toggle("Auto Segment Leviathan", "SegmentLeviathan", StopTween)
TabEvent:Button("Check Owned Boat", function()
    local b = CheckBoat()
    if b then
        Notify("Boat Found", "Thuyền của bạn: " .. tostring(b.Name), 3)
    else
        Notify("Boat Check", "Bạn chưa triệu hồi thuyền!", 3)
    end
end)

TabEvent:Section("Prehistoric, Dragon Dojo & Kitsune")
TabEvent:Toggle("Auto Defend Volcano (Prehistoric)", "DefendVolcano", StopTween)
TabEvent:Toggle("Auto Collect Dragon Egg", "CollectEgg")
TabEvent:Toggle("Auto Collect Dragon Dojo Ember", "AutoDragonEmber")
TabEvent:Toggle("Auto Kitsune Shrine Pray", "AutoKitsuneShrine")
TabEvent:Toggle("Auto Collect Blue Ember", "AutoBlueEmber")
TabEvent:Toggle("Auto Collect Berry (BerryBush)", "CollectBerry", StopTween)
TabEvent:Toggle("Auto Fishing (Sea 3)", "AutoFishing")

-- [7] TAB PLAYER
TabPlayer:Section("Teleport Player")
local PlayerNamesList = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(PlayerNamesList, p.Name) end
end
if #PlayerNamesList == 0 then table.insert(PlayerNamesList, LocalPlayer.Name) end
TabPlayer:Dropdown("Select Player", PlayerNamesList, "SelectPly")
TabPlayer:Toggle("Teleport To Player", "TeleportPly", StopTween)

TabPlayer:Section("Auto Stats")
TabPlayer:Dropdown("Select Stat", {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}, "SelectedStat")
TabPlayer:Toggle("Auto Upgrade Stats", "AutoStats")

-- [8] TAB VISUAL (ESP)
TabVisual:Section("ESP & Chams")
TabVisual:Toggle("ESP Player (UpdatePlayerChams)", "ESPPlayer")
TabVisual:Toggle("ESP Devil Fruit (UpdateDevilChams)", "DevilFruitESP")
TabVisual:Toggle("ESP Berries (UpdateBerriesESP)", "ESPBerry")
TabVisual:Toggle("ESP Mirage Island", "ESPMirage")
TabVisual:Toggle("ESP Kitsune Island", "ESPKitsune")
TabVisual:Toggle("ESP All Islands", "ESPIsland")

-- [9] TAB RAID
TabRaid:Section("Dungeon & Raid")
TabRaid:Dropdown("Select Chip", RaidChipsList, "SelectChip")
TabRaid:Toggle("Auto Buy Chip", "AutoBuyChip")
TabRaid:Toggle("Auto Start Raid", "AutoStartRaid")
TabRaid:Toggle("Auto Next Island & Kill Raid Mobs", "AutoNextIsland", StopTween)
TabRaid:Toggle("Auto Awaken Fruit", "AutoAwaken")
TabRaid:Toggle("Auto Raid Pirate (Castle on the Sea)", "RaidPirate", StopTween)

-- [10] TAB TELEPORT
TabTeleport:Section("Travel Sea")
TabTeleport:Button("Travel First Sea (World 1)", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelMain") end)
end)
TabTeleport:Button("Travel Second Sea (World 2)", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa") end)
end)
TabTeleport:Button("Travel Third Sea (World 3)", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou") end)
end)

TabTeleport:Section("Island Teleport")
TabTeleport:Dropdown("Select Island", IslandNames, "SelectIsland")
TabTeleport:Button("Tween To Selected Island", function()
    local cf = IslandLocations[_G.SelectIsland]
    if cf then topos(cf) end
end)
TabTeleport:Button("Teleport to Lab (Raid Lab)", function()
    topos(CFrame.new(-5010.6, 313.8, -2995.3))
end)

-- [11] TAB SHOP
TabShop:Section("Fighting Styles")
TabShop:Button("Buy Black Leg", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBlackLeg") end)
end)
TabShop:Button("Buy Electro", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyElectro") end)
end)
TabShop:Button("Buy Fishman Karate", function()
    pcall(function()
        UnEquipWeapon("Electro")
        task.wait(0.1)
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate")
    end)
end)
TabShop:Button("Buy Dragon Claw", function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "1")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
    end)
end)
TabShop:Button("Buy Superhuman", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySuperhuman") end)
end)
TabShop:Button("Buy Death Step", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyDeathStep") end)
end)
TabShop:Button("Buy Sharkman Karate", function()
    pcall(function()
        topos(CFrame.new(-2604.6958, 239.432526, -10315.1982))
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate")
    end)
end)
TabShop:Button("Buy Electric Claw", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") end)
end)
TabShop:Button("Buy Dragon Talon", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon") end)
end)
TabShop:Button("Buy Godhuman", function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman", true)
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman")
    end)
end)
TabShop:Button("Buy Sanguine Art", function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySanguineArt", true)
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySanguineArt")
    end)
end)

TabShop:Section("Weapons & Accessories")
TabShop:Button("Buy Dual Katana", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Duel Katana") end)
end)
TabShop:Button("Buy Slingshot", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Slingshot") end)
end)

-- [12] TAB DEVIL FRUIT
TabFruit:Section("Devil Fruit Sniper")
TabFruit:Dropdown("Select Fruits Sniper", Table_DevilFruitSniper, "SelectedFruitSniper")
TabFruit:Toggle("Auto Buy Fruit Sniper", "AutoBuyFruitSniper")

TabFruit:Section("Others")
TabFruit:Button("Random Fruit", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy") end)
end)
TabFruit:Button("Open Devil Shop", function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits")
        if LocalPlayer.PlayerGui.Main:FindFirstChild("FruitShop") then
            LocalPlayer.PlayerGui.Main.FruitShop.Visible = true
        end
    end)
end)
TabFruit:Button("Open Devil Shop Mirage", function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits", true)
        if LocalPlayer.PlayerGui.Main:FindFirstChild("FruitShop") then
            LocalPlayer.PlayerGui.Main.FruitShop.Visible = true
        end
    end)
end)
TabFruit:Toggle("Auto Store Fruit", "AutoStoreFruit")
TabFruit:Toggle("Bring to Fruit", "BringFruit")
TabFruit:Toggle("Tween to Fruit", "Tweenfruit", StopTween)

-- [13] TAB MISCELLANEOUS
TabMisc:Section("Server")
TabMisc:Button("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
TabMisc:Button("Server Hop", function()
    Hop(false)
end)
TabMisc:Button("Hop To Lower Player", function()
    Hop(true)
end)
TabMisc:Button("Copy Job Id", function()
    if setclipboard then setclipboard(tostring(game.JobId)) end
end)
TabMisc:TextBox("Input Job Id", "Job ID", "InputJobId")
TabMisc:Button("Join Server", function()
    if _G.InputJobId and #_G.InputJobId > 4 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, _G.InputJobId, LocalPlayer)
    end
end)

TabMisc:Section("Misc")
TabMisc:Button("Title Name", function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("getTitles")
        if LocalPlayer.PlayerGui.Main:FindFirstChild("Titles") then
            LocalPlayer.PlayerGui.Main.Titles.Visible = true
        end
    end)
end)
TabMisc:Button("Color Haki", function()
    pcall(function()
        if LocalPlayer.PlayerGui.Main:FindFirstChild("Colors") then
            LocalPlayer.PlayerGui.Main.Colors.Visible = true
        end
    end)
end)

TabMisc:Section("Teams")
TabMisc:Button("Join Pirates Team", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates") end)
end)
TabMisc:Button("Join Marines Team", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Marines") end)
end)

TabMisc:Section("Codes")
TabMisc:Button("Redeem All Codes (62 Codes)", function()
    pcall(function()
        local redeem = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Redeem")
        if redeem then
            for _, c in ipairs(DatThgCodes) do
                pcall(function() redeem:InvokeServer(c) end)
                task.wait(0.08)
            end
            Notify("Anime Blacker", "Đã nhập toàn bộ 62 Codes!", 4)
        end
    end)
end)

TabMisc:Section("State")
TabMisc:Dropdown("Select Haki State", {"State 0", "State 1", "State 2", "State 3", "State 4", "State 5"}, "SelectStateHaki")
TabMisc:Button("Change Buso Haki State", function()
    pcall(function()
        local stNum = tonumber(string.match(_G.SelectStateHaki, "%d+")) or 5
        ReplicatedStorage.Remotes.CommF_:InvokeServer("ChangeBusoStage", stNum)
    end)
end)

-- =================================================================================
-- 6. ĐỘNG CƠ THỰC THI TOÀN DIỆN (ĐÃ KẾT NỐI 100% CÁC CHỨC NĂNG TRONG 13 TABS)
-- =================================================================================

-- [LUỒNG A] TẤN CÔNG SIÊU TỐC (FAST ATTACK + KILL AURA + AUTO SHOOT GUN)
local lastAttackTick = 0
RunService.Heartbeat:Connect(function()
    if tick() - lastAttackTick < 0.08 then return end
    lastAttackTick = tick()

    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum or hum.Health <= 0 then return end

        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return end

        -- Kill Aura: Tiêu diệt nhanh quái trong tầm khi đi Raid hoặc bật Kill Aura
        if _G.Kill_Aura or _G.AutoNextIsland then
            if type(sethiddenproperty) == "function" then
                pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)
            end
            for _, mob in ipairs(enemies:GetChildren()) do
                local mhum = mob:FindFirstChildOfClass("Humanoid")
                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                if mhum and mhrp and mhum.Health > 0 and (mhrp.Position - root.Position).Magnitude <= 300 then
                    mhum.Health = 0
                end
            end
        end

        if not (IsAnyFarmActive() or _G.AutoClick or _G.AutoShootGun) then return end

        local tool = char:FindFirstChildOfClass("Tool")
        for _, enemy in ipairs(enemies:GetChildren()) do
            local eroot = enemy:FindFirstChild("HumanoidRootPart")
            local ehum = enemy:FindFirstChildOfClass("Humanoid")
            if eroot and ehum and ehum.Health > 0 and (eroot.Position - root.Position).Magnitude <= 75 then
                if tool then
                    pcall(function() tool:Activate() end)
                    if tool:FindFirstChild("LeftClickRemote") then
                        tool.LeftClickRemote:FireServer(Vector3.new(0, -1, 0), 1)
                    elseif tool:FindFirstChild("RemoteEvent") then
                        tool.RemoteEvent:FireServer(eroot.Position)
                    end
                end
                local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
                if net then
                    if net:FindFirstChild("RE/RegisterAttack") then net["RE/RegisterAttack"]:FireServer(0) end
                    if net:FindFirstChild("RE/RegisterHit") then net["RE/RegisterHit"]:FireServer(eroot, {}) end
                    if _G.AutoShootGun and net:FindFirstChild("RE/ShootGunEvent") then
                        net["RE/ShootGunEvent"]:FireServer(eroot.Position)
                    end
                end
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(1280, 672))
                break
            end
        end
    end)
end)

-- [LUỒNG B] AUTO FARM CHÍNH, SĂN BOSS, NHIỆM VỤ SEA 1/2/3, RAID & SỰ KIỆN
task.spawn(function()
    while task.wait(0.12) do
        pcall(function()
            -- 1. Teleport tới Người Chơi
            if _G.TeleportPly and _G.SelectPly ~= "" then
                local tPlr = Players:FindFirstChild(_G.SelectPly)
                if tPlr and tPlr.Character and tPlr.Character:FindFirstChild("HumanoidRootPart") then
                    topos(tPlr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 5, 3))
                end
                return
            end

            -- 2. Auto Farm Rương (FarmChest)
            if _G.FarmChest then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local closestChest, minDist = nil, math.huge
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA("BasePart") and string.find(v.Name, "Chest") and v:FindFirstChildOfClass("TouchTransmitter") then
                            local d = (v.Position - myRoot.Position).Magnitude
                            if d < minDist then
                                minDist = d
                                closestChest = v
                            end
                        end
                    end
                    if closestChest then
                        topos(closestChest.CFrame)
                    end
                end
                return
            end

            -- 3. Auto Next Island trong Raid
            if _G.AutoNextIsland and Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations") then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    for idx = 5, 1, -1 do
                        local isl = Workspace._WorldOrigin.Locations:FindFirstChild("Island " .. tostring(idx))
                        if isl and (isl.Position - myRoot.Position).Magnitude < 3500 then
                            topos(isl.CFrame * CFrame.new(0, 60, 0))
                            break
                        end
                    end
                end
                return
            end

            -- 4. Auto Farm Boss & Các Boss Nhiệm Vụ (World 1, 2, 3)
            local questBossMap = {
                {Flag = "Greybeard",        Name = "Greybeard",            Fallback = CFrame.new(-5023.0, 28.0, 4332.0)},
                {Flag = "AutoSaber",        Name = "Saber Expert",         Fallback = CFrame.new(-1458.0, 29.0, -50.0)},
                {Flag = "AutoPoleV1",       Name = "Thunder God",          Fallback = CFrame.new(-7748.0, 5606.0, -2305.0)},
                {Flag = "Factory",          Name = "Core",                 Fallback = CFrame.new(448.0, 199.0, -441.0)},
                {Flag = "AutoDarkbeard",    Name = "Darkbeard",            Fallback = CFrame.new(3777.0, 15.0, -3498.0)},
                {Flag = "LawRaid",          Name = "Order",                Fallback = CFrame.new(-6217.0, 28.0, -5053.0)},
                {Flag = "FarmSwanGlasses",  Name = "Don Swan",             Fallback = CFrame.new(2284.9, 15.5, 905.4)},
                {Flag = "OderSword",        Name = "Smoke Admiral",        Fallback = CFrame.new(-5078.0, 24.0, -5352.0)},
                {Flag = "BudySword",        Name = "Cake Queen",           Fallback = CFrame.new(-709.0, 381.0, -11150.0)},
                {Flag = "Carvender",        Name = "Beautiful Pirate",     Fallback = CFrame.new(5312.0, 22.0, -125.0)},
                {Flag = "TwinHook",         Name = "Captain Elephant",     Fallback = CFrame.new(-13376.0, 319.0, -8423.0)},
                {Flag = "tushita",          Name = "Longma",               Fallback = CFrame.new(-10156.2, 331.6, -9445.9)},
                {Flag = "Rainbow_Haki",     Name = "Stone",                Fallback = CFrame.new(-1109.9, 51.6, 6811.7)},
                {Flag = "TyrantSkies",      Name = "rip_indra True Form",  Fallback = CFrame.new(-5414.4, 309.8, -2212.4)},
                {Flag = "AutoEliteHunter",  Name = "Diablo",               Fallback = CFrame.new(-5414.4, 309.8, -2212.4)}
            }

            for _, qb in ipairs(questBossMap) do
                if _G[qb.Flag] then
                    local target, isSpawned = FindTargetEntity(qb.Name)
                    if not target and qb.Flag == "AutoEliteHunter" then
                        target, isSpawned = FindTargetEntity("Urban")
                    end
                    if target and target:FindFirstChild("HumanoidRootPart") then
                        EquipWeapon()
                        topos(target.HumanoidRootPart.CFrame * GetPosOffset())
                    else
                        topos(qb.Fallback * CFrame.new(0, 20, 0))
                    end
                    return
                end
            end

            if _G.AutoFarmBoss then
                local bName = _G.SelectBoss
                local target, _ = FindTargetEntity(bName)
                if target and target:FindFirstChild("HumanoidRootPart") then
                    EquipWeapon()
                    topos(target.HumanoidRootPart.CFrame * GetPosOffset())
                elseif BossSpawnCFrames[bName] then
                    topos(BossSpawnCFrames[bName] * CFrame.new(0, 20, 0))
                end
                return
            end

            -- 5. Auto Farm Cake Prince (4 loại quái Bánh)
            if _G.AutoFarmCake then
                local bossCake = FindTargetEntity({"Cake Prince", "Dough King"})
                if bossCake and bossCake:FindFirstChild("HumanoidRootPart") then
                    EquipWeapon()
                    topos(bossCake.HumanoidRootPart.CFrame * GetPosOffset())
                    return
                end
                local mobCake, isLive = FindTargetEntity(CakeMobs)
                if mobCake and mobCake:FindFirstChild("HumanoidRootPart") then
                    EquipWeapon()
                    local mcf = mobCake.HumanoidRootPart.CFrame
                    if isLive then BringMobs(mcf, mobCake.Name) end
                    topos(mcf * GetPosOffset())
                else
                    topos(CakeMobs["Cookie Crafter"] * CFrame.new(0, 20, 0))
                end
                return
            end

            -- 6. Auto Farm Bone (4 loại quái Xương)
            if _G.AutoFarmBone then
                local bossBone = FindTargetEntity("Soul Reaper")
                if bossBone and bossBone:FindFirstChild("HumanoidRootPart") then
                    EquipWeapon()
                    topos(bossBone.HumanoidRootPart.CFrame * GetPosOffset())
                    return
                end
                local mobBone, isLive = FindTargetEntity(BoneMobs)
                if mobBone and mobBone:FindFirstChild("HumanoidRootPart") then
                    EquipWeapon()
                    local mcf = mobBone.HumanoidRootPart.CFrame
                    if isLive then BringMobs(mcf, mobBone.Name) end
                    topos(mcf * GetPosOffset())
                else
                    topos(BoneMobs["Reborn Skeleton"] * CFrame.new(0, 20, 0))
                end
                return
            end

            -- 7. Auto Farm Level (Tự nhận Quest theo Level & đánh quái)
            if _G.AutoFarmLevel then
                local myLv = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 2550
                local qData = LevelQuestDatabase[#LevelQuestDatabase]
                for _, d in ipairs(LevelQuestDatabase) do
                    if myLv >= d.MinLevel and myLv <= d.MaxLevel then
                        qData = d
                        break
                    end
                end

                local questGui = LocalPlayer:FindFirstChild("PlayerGui")
                    and LocalPlayer.PlayerGui:FindFirstChild("Main")
                    and LocalPlayer.PlayerGui.Main:FindFirstChild("Quest")
                if questGui and not questGui.Visible then
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", qData.QuestName, qData.QuestLv)
                    end)
                end

                local mobTarget, isLive = FindTargetEntity(qData.Mob)
                if mobTarget and mobTarget:FindFirstChild("HumanoidRootPart") then
                    EquipWeapon()
                    local mcf = mobTarget.HumanoidRootPart.CFrame
                    if isLive then BringMobs(mcf, qData.Mob) end
                    topos(mcf * GetPosOffset())
                else
                    topos(qData.Pos * CFrame.new(0, 20, 0))
                end
                return
            end

            -- 8. Auto Farm Quái Đã Chọn (AutoFarmMob)
            if _G.AutoFarmMob then
                local mName = _G.SelectedMob
                local mobTarget, isLive = FindTargetEntity(mName)
                if mobTarget and mobTarget:FindFirstChild("HumanoidRootPart") then
                    EquipWeapon()
                    local mcf = mobTarget.HumanoidRootPart.CFrame
                    if isLive then BringMobs(mcf, mName) end
                    topos(mcf * GetPosOffset())
                elseif MobSpawnCFrames[mName] then
                    topos(MobSpawnCFrames[mName] * CFrame.new(0, 20, 0))
                end
                return
            end

            -- 9. Auto Raid Pirate (Castle on the Sea)
            if _G.RaidPirate then
                topos(CFrame.new(-5496.0, 314.0, -2841.0))
                EquipWeapon()
                return
            end

            -- 10. Race / Mirage & Prehistoric Events
            if _G.TpSkullCore then
                topos(CFrame.new(28286.3, 14895.3, 102.6))
                return
            end

            if _G.TweenMGear and Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("MysticIsland") then
                for _, v in ipairs(Workspace.Map.MysticIsland:GetDescendants()) do
                    if v:IsA("MeshPart") and v.Material == Enum.Material.Neon then
                        topos(v.CFrame)
                        break
                    end
                end
                return
            end

            if _G.DefendVolcano and Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("PrehistoricIsland") then
                local rock = Workspace.Map.PrehistoricIsland:FindFirstChild("volcanorock", true)
                if rock and rock:IsA("BasePart") then
                    EquipWeapon()
                    topos(rock.CFrame * GetPosOffset())
                end
                return
            end

            if _G.Seabest and Workspace:FindFirstChild("SeaBeasts") then
                for _, sb in ipairs(Workspace.SeaBeasts:GetChildren()) do
                    local hrp = sb:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        EquipWeapon()
                        topos(hrp.CFrame * CFrame.new(0, 40, 0))
                        break
                    end
                end
                return
            end

            if _G.Guitar then
                local prog = ReplicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")
                if type(prog) == "table" then
                    if not prog.Swamp then
                        topos(CFrame.new(-10141.4, 138.6, 5935.0))
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Swamp")
                    elseif not prog.Gravestones then
                        topos(CFrame.new(-9515.0, 142.0, 5535.0))
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Gravestones")
                    elseif not prog.Trophies then
                        for i = 1, 5 do
                            local tr = getTrophies(i)
                            if tr then GetFirePlacard(i, tr[1]) end
                        end
                    end
                end
            end
        end)
    end
end)

-- [LUỒNG C] HỖ TRỢ, TRÁI ÁC QUỶ, SỰ KIỆN SEA 3, CÂU CÁ & STATS
task.spawn(function()
    while task.wait(0.9) do
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local bp = LocalPlayer:FindFirstChild("Backpack")

            if char then
                if _G.AutoHaki and not char:FindFirstChild("HasBuso") then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                end
                if _G.Observation then
                    ReplicatedStorage.Remotes.CommE:FireServer("Ken", true)
                end
                if _G.InfiniteStam and char:FindFirstChild("Energy") then
                    char.Energy.Value = char.Energy.MaxValue
                end
                if _G.AutoRaceV3 then
                    if ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("UsedRaceSkill") then
                        ReplicatedStorage.Events.UsedRaceSkill:FireServer()
                    end
                    ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
                end
                if _G.AutoRaceV4 then
                    local awk = (bp and bp:FindFirstChild("Awakening")) or char:FindFirstChild("Awakening")
                    if awk and awk:FindFirstChild("RemoteFunction") then
                        awk.RemoteFunction:InvokeServer(true)
                    end
                end
            end

            if _G.BuyGear then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Buy")
            end

            if _G.AutoStoreFruit and char and bp then
                local function StoreFrom(folder)
                    for _, it in ipairs(folder:GetChildren()) do
                        if it:IsA("Tool") and (string.find(it.Name, "Fruit") or it:GetAttribute("OriginalName")) then
                            local oName = it:GetAttribute("OriginalName") or it.Name
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", oName, it)
                        end
                    end
                end
                StoreFrom(bp)
                StoreFrom(char)
            end

            if _G.AutoBuyFruitSniper then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits")
                ReplicatedStorage.Remotes.CommF_:InvokeServer("PurchaseRawFruit", _G.SelectedFruitSniper, false)
            end

            if root and (_G.BringFruit or _G.Tweenfruit) then
                for _, item in ipairs(Workspace:GetChildren()) do
                    if item:IsA("Tool") and item:FindFirstChild("Handle") then
                        if _G.BringFruit then
                            item.Handle.CFrame = root.CFrame
                        elseif _G.Tweenfruit then
                            topos(item.Handle.CFrame)
                            break
                        end
                    end
                end
            end

            if _G.AutoBuyChip then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", _G.SelectChip)
            end
            if _G.AutoStartRaid and fireclickdetector then
                pcall(function()
                    local btn = Workspace.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector
                    fireclickdetector(btn)
                end)
            end
            if _G.AutoAwaken then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("Awakener", "Awaken")
            end
            if _G.AutoStats then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", _G.SelectedStat, 3)
            end

            -- Cài đặt giảm lag quái & thông báo
            if _G.InvisibleMonsters and Workspace:FindFirstChild("Enemies") then
                for _, mob in ipairs(Workspace.Enemies:GetChildren()) do
                    for _, p in ipairs(mob:GetDescendants()) do
                        if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = 1 end
                    end
                end
            end
            if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Notifications") then
                LocalPlayer.PlayerGui.Notifications.Enabled = not _G.DisableNotifications
            end

            -- Các Remote Sự Kiện Sea 3 (Kitsune, Dragon Dojo, Berry, Câu Cá)
            local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
            if net then
                if _G.AutoKitsuneShrine then
                    if net:FindFirstChild("RE/TouchKitsuneStatue") then net["RE/TouchKitsuneStatue"]:FireServer() end
                    if net:FindFirstChild("RF/KitsuneStatuePray") then net["RF/KitsuneStatuePray"]:InvokeServer() end
                end
                if _G.AutoBlueEmber and net:FindFirstChild("RE/CollectBlueEmber") then
                    net["RE/CollectBlueEmber"]:FireServer()
                end
                if _G.AutoDragonEmber and net:FindFirstChild("RE/DragonDojoEmber") then
                    net["RE/DragonDojoEmber"]:FireServer()
                end
                if _G.CollectEgg and net:FindFirstChild("RE/CollectedDragonEgg") then
                    net["RE/CollectedDragonEgg"]:FireServer()
                end
                if _G.CollectBerry and root then
                    for _, bush in ipairs(CollectionService:GetTagged("BerryBush")) do
                        local pt = bush:IsA("BasePart") and bush or bush:FindFirstChildWhichIsA("BasePart", true)
                        if pt then
                            topos(pt.CFrame)
                            break
                        end
                    end
                    if net:FindFirstChild("RF/ClaimBerry") then net["RF/ClaimBerry"]:InvokeServer() end
                end
                if _G.AutoFishing then
                    EquipWeapon("Fishing Rod")
                    if net:FindFirstChild("RE/FishingRemote") then net["RE/FishingRemote"]:FireServer() end
                    if net:FindFirstChild("RF/FishingAPI") then net["RF/FishingAPI"]:InvokeServer() end
                end
            end
        end)
    end
end)

-- =================================================================================
-- 7. HỆ THỐNG ESP CHUẨN DATTHG V2
-- =================================================================================
local ESPFolder = Instance.new("Folder", CoreGui)
ESPFolder.Name = "AnimeBlacker_ESPFolder"

local function AddESPBillboard(adornee, labelText, col)
    local bbg = Instance.new("BillboardGui", ESPFolder)
    bbg.Adornee = adornee
    bbg.AlwaysOnTop = true
    bbg.Size = UDim2.new(1, 200, 1, 30)
    bbg.ExtentsOffset = Vector3.new(0, 2, 0)

    local txt = Instance.new("TextLabel", bbg)
    txt.Size = UDim2.fromScale(1, 1)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamSemibold
    txt.TextSize = 13
    txt.TextStrokeTransparency = 0.4
    txt.TextColor3 = col
    txt.TextYAlignment = Enum.TextYAlignment.Top
    txt.Text = labelText
end

task.spawn(function()
    while task.wait(0.9) do
        pcall(function()
            ESPFolder:ClearAllChildren()
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end

            if _G.ESPPlayer then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                        local d = round((plr.Character.Head.Position - myRoot.Position).Magnitude / 3)
                        AddESPBillboard(plr.Character.Head, plr.Name .. "\n" .. tostring(d) .. " Distance", Color3.fromRGB(255, 65, 115))
                    end
                end
            end

            if _G.DevilFruitESP then
                for _, item in ipairs(Workspace:GetChildren()) do
                    if item:IsA("Tool") and item:FindFirstChild("Handle") then
                        local d = round((item.Handle.Position - myRoot.Position).Magnitude / 3)
                        AddESPBillboard(item.Handle, item.Name .. "\n" .. tostring(d) .. " Distance", Color3.fromRGB(90, 255, 130))
                    end
                end
            end

            if _G.ESPBerry then
                for _, bush in ipairs(CollectionService:GetTagged("BerryBush")) do
                    local pt = bush:IsA("BasePart") and bush or bush:FindFirstChildWhichIsA("BasePart", true)
                    if pt then
                        local d = round((pt.Position - myRoot.Position).Magnitude / 3)
                        AddESPBillboard(pt, "Berry Bush\n" .. tostring(d) .. " Distance", Color3.fromRGB(255, 120, 255))
                    end
                end
            end

            if (_G.ESPIsland or _G.ESPMirage or _G.ESPKitsune) and Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations") then
                for _, loc in ipairs(Workspace._WorldOrigin.Locations:GetChildren()) do
                    if loc:IsA("BasePart") then
                        local isMirage = (loc.Name == "Mirage Island")
                        local isKitsune = (loc.Name == "Kitsune Island")
                        if _G.ESPIsland or (_G.ESPMirage and isMirage) or (_G.ESPKitsune and isKitsune) then
                            local d = round((loc.Position - myRoot.Position).Magnitude / 3)
                            AddESPBillboard(loc, loc.Name .. "\n" .. tostring(d) .. " Distance", Color3.fromRGB(80, 220, 255))
                        end
                    end
                end
            end
        end)
    end
end)

Notify("ANIME BLACKER V2", "Đã vá sạch lỗi đơ nút & đơ Tween! Sẵn sàng chiến!", 5)
