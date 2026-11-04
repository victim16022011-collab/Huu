-- =================================================================================
-- DỰ ÁN: ANIME BLACKER HUB (SỬ DỤNG LÕI ENGINE & UI REDZ V5 TỪ DATTHG V2)
-- BẢN QUYỀN: HUYKOGIAUVN
-- ĐẶC ĐIỂM:
--   + Nhúng trực tiếp thư viện redzlib V5 nguyên bản từ DatThgV2
--   + Bê nguyên hệ thống bay topos + TP2 + CheckNearestTeleporter + requestEntrance
--   + Chống giật (Anti-Rubberband) và chống rơi (BodyClip + Y-Axis Sync)
--   + Đầy đủ 13 Tabs và toàn bộ hàm KillMob, BringEnemies, BringMobs của DatThg V2
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

local Player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

-- =================================================================================
-- PHẦN 1: THƯ VIỆN UI REDZ V5 NGUYÊN BẢN TỪ DATTHG V2 (THEME ANIME BLACKER)
-- =================================================================================
local redzlib = {
    Themes = {
        Darker = {
            ["Color Hub 1"] = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(18, 15, 25)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(28, 22, 38)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(18, 15, 25))
            }),
            ["Color Hub 2"] = Color3.fromRGB(26, 22, 36),
            ["Color Stroke"] = Color3.fromRGB(45, 38, 62),
            ["Color Theme"] = Color3.fromRGB(255, 45, 95),
            ["Color Text"] = Color3.fromRGB(245, 245, 255),
            ["Color Dark Text"] = Color3.fromRGB(180, 180, 205)
        }
    },
    Info = {
        Version = "2.0.0"
    },
    Save = {
        UISize = {550, 380},
        TabSize = 160,
        Theme = "Darker"
    },
    Settings = {},
    Connection = {},
    Instances = {},
    Elements = {},
    Options = {},
    Flags = {},
    Tabs = {},
    Icons = {}
}

local ViewportSize = Workspace.CurrentCamera.ViewportSize
local UIScale = ViewportSize.Y / 450

local Settings = redzlib.Settings
local Flags = redzlib.Flags

local function VerifyTheme(ThemeName)
    for name, _ in pairs(redzlib.Themes) do
        if name == ThemeName then
            return true
        end
    end
    return false
end

local SetProps, SetChildren, InsertTheme, Create do
    InsertTheme = function(InstanceObj, Type)
        table.insert(redzlib.Instances, {
            Instance = InstanceObj,
            Type = Type
        })
        return InstanceObj
    end

    SetChildren = function(InstanceObj, Children)
        if Children then
            for _, Child in ipairs(Children) do
                Child.Parent = InstanceObj
            end
        end
        return InstanceObj
    end

    SetProps = function(InstanceObj, Props)
        if Props then
            for prop, value in pairs(Props) do
                InstanceObj[prop] = value
            end
        end
        return InstanceObj
    end

    Create = function(...)
        local args = {...}
        local new = Instance.new(args[1])
        if type(args[2]) == "table" then
            SetProps(new, args[2])
            SetChildren(new, args[3])
        elseif typeof(args[2]) == "Instance" then
            new.Parent = args[2]
            SetProps(new, args[3])
            SetChildren(new, args[4])
        end
        return new
    end

    local function LoadSavedUI(file)
        if readfile and isfile and isfile(file) then
            local ok, decode = pcall(function()
                return HttpService:JSONDecode(readfile(file))
            end)
            if ok and type(decode) == "table" then
                if rawget(decode, "UISize") then redzlib.Save["UISize"] = decode["UISize"] end
                if rawget(decode, "TabSize") then redzlib.Save["TabSize"] = decode["TabSize"] end
                if rawget(decode, "Theme") and VerifyTheme(decode["Theme"]) then redzlib.Save["Theme"] = decode["Theme"] end
            end
        end
    end
    pcall(LoadSavedUI, "AnimeBlacker_RedzV5.json")
end

local Funcs = {} do
    function Funcs:InsertCallback(tab, func)
        if type(func) == "function" then
            table.insert(tab, func)
        end
        return func
    end

    function Funcs:FireCallback(tab, ...)
        for _, v in ipairs(tab) do
            if type(v) == "function" then
                task.spawn(v, ...)
            end
        end
    end

    function Funcs:ToggleVisible(Obj, Bool)
        Obj.Visible = Bool ~= nil and Bool or Obj.Visible
    end

    function Funcs:GetConnectionFunctions(ConnectedFuncs, func)
        local Connected = { Function = func, Connected = true }
        function Connected:Disconnect()
            if self.Connected then
                table.remove(ConnectedFuncs, table.find(ConnectedFuncs, self.Function))
                self.Connected = false
            end
        end
        function Connected:Fire(...)
            if self.Connected then
                task.spawn(self.Function, ...)
            end
        end
        return Connected
    end

    function Funcs:GetCallback(Configs, index)
        local func = Configs[index] or Configs.Callback or function() end
        if type(func) == "table" then
            return ({function(Value) func[1][func[2]] = Value end})
        end
        return {func}
    end
end

local Connections, Connection = {}, redzlib.Connection do
    local function NewConnectionList(List)
        for _, CoName in ipairs(List) do
            local ConnectedFuncs, Connect = {}, {}
            Connection[CoName] = Connect
            Connections[CoName] = ConnectedFuncs
            Connect.Name = CoName

            function Connect:Connect(func)
                if type(func) == "function" then
                    table.insert(ConnectedFuncs, func)
                    return Funcs:GetConnectionFunctions(ConnectedFuncs, func)
                end
            end
        end
    end

    function Connection:FireConnection(CoName, ...)
        local tbl = type(CoName) == "string" and Connections[CoName] or Connections[CoName.Name]
        if tbl then
            for _, Func in pairs(tbl) do
                task.spawn(Func, ...)
            end
        end
    end

    NewConnectionList({"FlagsChanged", "ThemeChanged", "FileSaved", "ThemeChanging", "OptionAdded"})
end

local GetFlag, SetFlag, CheckFlag do
    CheckFlag = function(Name)
        return type(Name) == "string" and Flags[Name] ~= nil
    end
    GetFlag = function(Name)
        return type(Name) == "string" and Flags[Name]
    end
    SetFlag = function(Flag, Value)
        if Flag and (Value ~= Flags[Flag] or type(Value) == "table") then
            Flags[Flag] = Value
            Connection:FireConnection("FlagsChanged", Flag, Value)
        end
    end
end

local ScreenGui = Create("ScreenGui", CoreGui, {
    Name = "AnimeBlacker_RedzV5"
}, {
    Create("UIScale", {
        Scale = UIScale,
        Name = "Scale"
    })
})

for _, old in ipairs(CoreGui:GetChildren()) do
    if old.Name == ScreenGui.Name and old ~= ScreenGui then
        old:Destroy()
    end
end

local function GetStr(val)
    if type(val) == "function" then return val() end
    return val
end

local function ConnectSave(InstanceObj, func)
    InstanceObj.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                task.wait()
            end
            func()
        end
    end)
end

local function CreateTween(Configs)
    local InstanceObj = Configs[1] or Configs.Instance
    local Prop = Configs[2] or Configs.Prop
    local NewVal = Configs[3] or Configs.NewVal
    local Time = Configs[4] or Configs.Time or 0.5
    local TweenWait = Configs[5] or Configs.wait or false
    local TweenInfoObj = TweenInfo.new(Time, Enum.EasingStyle.Quint)

    local Tween = TweenService:Create(InstanceObj, TweenInfoObj, {[Prop] = NewVal})
    Tween:Play()
    if TweenWait then
        Tween.Completed:Wait()
    end
    return Tween
end

local function MakeDrag(InstanceObj)
    task.spawn(function()
        SetProps(InstanceObj, {
            Active = true,
            AutoButtonColor = false
        })
        local DragStart, StartPos, InputOn
        local function Update(Input)
            local delta = Input.Position - DragStart
            local Position = UDim2.new(
                StartPos.X.Scale,
                StartPos.X.Offset + delta.X / UIScale,
                StartPos.Y.Scale,
                StartPos.Y.Offset + delta.Y / UIScale
            )
            CreateTween({InstanceObj, "Position", Position, 0.25})
        end
        InstanceObj.MouseButton1Down:Connect(function()
            InputOn = true
        end)
        InstanceObj.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                StartPos = InstanceObj.Position
                DragStart = Input.Position
                while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    RunService.Heartbeat:Wait()
                    if InputOn then Update(Input) end
                end
                InputOn = false
            end
        end)
        UserInputService.InputChanged:Connect(function(Input)
            if InputOn and Input.UserInputType == Enum.UserInputType.Touch then
                Update(Input)
            end
        end)
        UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
                InputOn = false
            end
        end)
    end)
    return InstanceObj
end

local function SaveJson(FileName, save)
    if writefile then
        pcall(function()
            writefile(FileName, HttpService:JSONEncode(save))
        end)
    end
end

local Theme = redzlib.Themes[redzlib.Save.Theme]

local function AddEle(Name, Func)
    redzlib.Elements[Name] = Func
end

local function Make(Ele, InstanceObj, props, ...)
    return redzlib.Elements[Ele](InstanceObj, props, ...)
end

AddEle("Corner", function(parent, CornerRadius)
    return Create("UICorner", parent, {
        CornerRadius = CornerRadius or UDim.new(0, 7)
    })
end)

AddEle("Stroke", function(parent, props, ...)
    local args = {...}
    return InsertTheme(SetProps(Create("UIStroke", parent, {
        Color = args[1] or Theme["Color Stroke"],
        Thickness = args[2] or 1,
        ApplyStrokeMode = "Border"
    }), props), "Stroke")
end)

AddEle("Button", function(parent, props, ...)
    local args = {...}
    local New = InsertTheme(SetProps(Create("TextButton", parent, {
        Text = "",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme["Color Hub 2"],
        AutoButtonColor = false
    }), props), "Frame")

    New.MouseEnter:Connect(function() New.BackgroundTransparency = 0.4 end)
    New.MouseLeave:Connect(function() New.BackgroundTransparency = 0 end)
    if args[1] then New.Activated:Connect(args[1]) end
    return New
end)

AddEle("Gradient", function(parent, props)
    return InsertTheme(SetProps(Create("UIGradient", parent, {
        Color = Theme["Color Hub 1"]
    }), props), "Gradient")
end)

local function ButtonFrame(InstanceObj, Title, Description, HolderSize)
    local TitleL = InsertTheme(Create("TextLabel", {
        Font = Enum.Font.GothamMedium,
        TextColor3 = Theme["Color Text"],
        Size = UDim2.new(1, -20),
        AutomaticSize = "Y",
        Position = UDim2.new(0, 0, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        TextTruncate = "AtEnd",
        TextSize = 10,
        TextXAlignment = "Left",
        Text = "",
        RichText = true
    }), "Text")

    local DescL = InsertTheme(Create("TextLabel", {
        Font = Enum.Font.Gotham,
        TextColor3 = Theme["Color Dark Text"],
        Size = UDim2.new(1, -20),
        AutomaticSize = "Y",
        Position = UDim2.new(0, 12, 0, 15),
        BackgroundTransparency = 1,
        TextWrapped = true,
        TextSize = 8,
        TextXAlignment = "Left",
        Text = "",
        RichText = true
    }), "DarkText")

    local Frame = Make("Button", InstanceObj, {
        Size = UDim2.new(1, 0, 0, 25),
        AutomaticSize = "Y",
        Name = "Option"
    })
    Make("Corner", Frame, UDim.new(0, 6))

    local LabelHolder = Create("Frame", Frame, {
        AutomaticSize = "Y",
        BackgroundTransparency = 1,
        Size = HolderSize,
        Position = UDim2.new(0, 10, 0),
        AnchorPoint = Vector2.new(0, 0)
    }, {
        Create("UIListLayout", {
            SortOrder = "LayoutOrder",
            VerticalAlignment = "Center",
            Padding = UDim.new(0, 2)
        }),
        Create("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 5)
        }),
        TitleL,
        DescL
    })

    local Label = {}
    function Label:SetTitle(NewTitle)
        if type(NewTitle) == "string" and NewTitle:gsub(" ", ""):len() > 0 then
            TitleL.Text = NewTitle
        end
    end
    function Label:SetDesc(NewDesc)
        if type(NewDesc) == "string" and NewDesc:gsub(" ", ""):len() > 0 then
            DescL.Visible = true
            DescL.Text = NewDesc
            LabelHolder.Position = UDim2.new(0, 10, 0)
            LabelHolder.AnchorPoint = Vector2.new(0, 0)
        else
            DescL.Visible = false
            DescL.Text = ""
            LabelHolder.Position = UDim2.new(0, 10, 0.5)
            LabelHolder.AnchorPoint = Vector2.new(0, 0.5)
        end
    end

    Label:SetTitle(Title)
    Label:SetDesc(Description)
    return Frame, Label
end

function redzlib:GetIcon(index)
    if type(index) ~= "string" or index:find("rbxassetid://") or #index == 0 then
        return index
    end
    return index
end

function redzlib:SetScale(NewScale)
    NewScale = ViewportSize.Y / math.clamp(NewScale, 300, 2000)
    UIScale, ScreenGui.Scale.Scale = NewScale, NewScale
end

function redzlib:MakeWindow(Configs)
    local WTitle = Configs[1] or Configs.Name or Configs.Title or "ANIME BLACKER HUB"
    local WMiniText = Configs[2] or Configs.SubTitle or "by HUYKOGIAUVN"
    Settings.ScriptFile = Configs[3] or Configs.SaveFolder or false

    local UISizeX, UISizeY = unpack(redzlib.Save.UISize)
    local MainFrame = InsertTheme(Create("ImageButton", ScreenGui, {
        Size = UDim2.fromOffset(UISizeX, UISizeY),
        Position = UDim2.new(0.5, -UISizeX/2, 0.5, -UISizeY/2),
        BackgroundTransparency = 0.03,
        Name = "Hub"
    }), "Main")
    Make("Gradient", MainFrame, {Rotation = 45})
    Make("Stroke", MainFrame, nil, Theme["Color Theme"], 1.5)
    MakeDrag(MainFrame)

    local MainCorner = Make("Corner", MainFrame)
    local Components = Create("Folder", MainFrame, {Name = "Components"})
    local DropdownHolder = Create("Folder", ScreenGui, {Name = "Dropdown"})

    local TopBar = Create("Frame", Components, {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Name = "Top Bar"
    })

    local Title = InsertTheme(Create("TextLabel", TopBar, {
        Position = UDim2.new(0, 15, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        AutomaticSize = "XY",
        Text = WTitle,
        TextXAlignment = "Left",
        TextSize = 12,
        TextColor3 = Theme["Color Theme"],
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Name = "Title"
    }, {
        InsertTheme(Create("TextLabel", {
            Size = UDim2.fromScale(0, 1),
            AutomaticSize = "X",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(1, 6, 0.9),
            Text = WMiniText,
            TextColor3 = Theme["Color Dark Text"],
            BackgroundTransparency = 1,
            TextXAlignment = "Left",
            TextYAlignment = "Bottom",
            TextSize = 8,
            Font = Enum.Font.Gotham,
            Name = "SubTitle"
        }), "DarkText")
    }), "Text")

    local MainScroll = InsertTheme(Create("ScrollingFrame", Components, {
        Size = UDim2.new(0, redzlib.Save.TabSize, 1, -TopBar.Size.Y.Offset),
        ScrollBarImageColor3 = Theme["Color Theme"],
        Position = UDim2.new(0, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        ScrollBarThickness = 1.5,
        BackgroundTransparency = 1,
        ScrollBarImageTransparency = 0.2,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = "Y",
        ScrollingDirection = "Y",
        BorderSizePixel = 0,
        Name = "Tab Scroll"
    }, {
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        }),
        Create("UIListLayout", {Padding = UDim.new(0, 5)})
    }), "ScrollBar")

    local Containers = Create("Frame", Components, {
        Size = UDim2.new(1, -MainScroll.Size.X.Offset, 1, -TopBar.Size.Y.Offset),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Name = "Containers"
    })

    local ButtonsFolder = Create("Folder", TopBar, {Name = "Buttons"})
    local CloseButton = Create("ImageButton", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(1, -10, 0.5),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10747384394",
        AutoButtonColor = false,
        Name = "Close"
    })
    local MinimizeButton = SetProps(CloseButton:Clone(), {
        Position = UDim2.new(1, -35, 0.5),
        Image = "rbxassetid://10734896206",
        Name = "Minimize"
    })
    SetChildren(ButtonsFolder, {CloseButton, MinimizeButton})

    local Minimized, SaveSize, WaitClick
    local Window, FirstTab = {}, false

    function Window:CloseBtn()
        ScreenGui:Destroy()
    end
    function Window:MinimizeBtn()
        if WaitClick then return end
        WaitClick = true
        if Minimized then
            MinimizeButton.Image = "rbxassetid://10734896206"
            CreateTween({MainFrame, "Size", SaveSize, 0.25, true})
            Minimized = false
        else
            MinimizeButton.Image = "rbxassetid://10734924532"
            SaveSize = MainFrame.Size
            CreateTween({MainFrame, "Size", UDim2.fromOffset(MainFrame.Size.X.Offset, 28), 0.25, true})
            Minimized = true
        end
        WaitClick = false
    end
    function Window:Minimize()
        MainFrame.Visible = not MainFrame.Visible
    end
    function Window:AddMinimizeButton(Configs)
        local Button = MakeDrag(Create("ImageButton", ScreenGui, {
            Size = UDim2.fromOffset(40, 40),
            Position = UDim2.fromScale(0.15, 0.15),
            BackgroundTransparency = 0,
            BackgroundColor3 = Theme["Color Hub 2"],
            AutoButtonColor = false
        }))
        local Stroke, Corner
        if Configs.Corner then
            Corner = Make("Corner", Button)
            SetProps(Corner, Configs.Corner)
        end
        Stroke = Make("Stroke", Button, nil, Theme["Color Theme"], 1.5)
        SetProps(Button, Configs.Button)
        Button.Activated:Connect(Window.Minimize)
        return {Stroke = Stroke, Corner = Corner, Button = Button}
    end

    local ContainerList = {}
    function Window:T(paste, Configs)
        if type(paste) == "table" then Configs = paste end
        local TName = Configs[1] or Configs.Title or "Tab!"
        local TIcon = Configs[2] or Configs.Icon or ""

        TIcon = redzlib:GetIcon(TIcon)
        if not TIcon:find("rbxassetid://") or TIcon:gsub("rbxassetid://", ""):len() < 6 then
            TIcon = false
        end

        local TabSelect = Make("Button", MainScroll, {Size = UDim2.new(1, 0, 0, 24)})
        Make("Corner", TabSelect)

        local LabelTitle = InsertTheme(Create("TextLabel", TabSelect, {
            Size = UDim2.new(1, TIcon and -25 or -15, 1),
            Position = UDim2.fromOffset(TIcon and 25 or 15),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = TName,
            TextColor3 = Theme["Color Text"],
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = (FirstTab and 0.3) or 0,
            TextTruncate = "AtEnd"
        }), "Text")

        local LabelIcon = InsertTheme(Create("ImageLabel", TabSelect, {
            Position = UDim2.new(0, 8, 0.5),
            Size = UDim2.new(0, 13, 0, 13),
            AnchorPoint = Vector2.new(0, 0.5),
            Image = TIcon or "",
            BackgroundTransparency = 1,
            ImageTransparency = (FirstTab and 0.3) or 0
        }), "Text")

        local Selected = InsertTheme(Create("Frame", TabSelect, {
            Size = FirstTab and UDim2.new(0, 4, 0, 4) or UDim2.new(0, 4, 0, 13),
            Position = UDim2.new(0, 1, 0.5),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Theme["Color Theme"],
            BackgroundTransparency = FirstTab and 1 or 0
        }), "Theme")
        Make("Corner", Selected, UDim.new(0.5, 0))

        local Container = InsertTheme(Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 1),
            AnchorPoint = Vector2.new(0, 1),
            ScrollBarThickness = 1.5,
            BackgroundTransparency = 1,
            ScrollBarImageTransparency = 0.2,
            ScrollBarImageColor3 = Theme["Color Theme"],
            AutomaticCanvasSize = "Y",
            ScrollingDirection = "Y",
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            Name = ("Container %i [ %s ]"):format(#ContainerList + 1, TName)
        }, {
            Create("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10)
            }),
            Create("UIListLayout", {Padding = UDim.new(0, 5)})
        }), "ScrollBar")

        table.insert(ContainerList, Container)
        if not FirstTab then Container.Parent = Containers end

        local Tab = {}
        local function ActivateTab()
            if Container.Parent then return end
            for _, Frame in pairs(ContainerList) do
                if Frame:IsA("ScrollingFrame") and Frame ~= Container then
                    Frame.Parent = nil
                end
            end
            Container.Parent = Containers
            Container.Size = UDim2.new(1, 0, 1, 150)
            for _, TabEntry in pairs(redzlib.Tabs) do
                if TabEntry.Cont ~= Container then
                    TabEntry.func:Disable()
                end
            end
            CreateTween({Container, "Size", UDim2.new(1, 0, 1, 0), 0.3})
            CreateTween({LabelTitle, "TextTransparency", 0, 0.35})
            CreateTween({LabelIcon, "ImageTransparency", 0, 0.35})
            CreateTween({Selected, "Size", UDim2.new(0, 4, 0, 13), 0.35})
            CreateTween({Selected, "BackgroundTransparency", 0, 0.35})
        end
        TabSelect.Activated:Connect(ActivateTab)

        FirstTab = true
        table.insert(redzlib.Tabs, {TabInfo = {Name = TName, Icon = TIcon}, func = Tab, Cont = Container})
        Tab.Cont = Container

        function Tab:Disable()
            Container.Parent = nil
            CreateTween({LabelTitle, "TextTransparency", 0.3, 0.35})
            CreateTween({LabelIcon, "ImageTransparency", 0.3, 0.35})
            CreateTween({Selected, "Size", UDim2.new(0, 4, 0, 4), 0.35})
            CreateTween({Selected, "BackgroundTransparency", 1, 0.35})
        end
        function Tab:Enable() ActivateTab() end

        function Tab:Section(Configs)
            local SectionName = type(Configs) == "string" and Configs or Configs[1] or Configs.Name or Configs.Title
            local SectionFrame = Create("Frame", Container, {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Name = "Option"
            })
            local SectionLabel = InsertTheme(Create("TextLabel", SectionFrame, {
                Font = Enum.Font.GothamBold,
                Text = SectionName,
                TextColor3 = Theme["Color Theme"],
                Size = UDim2.new(1, -25, 1, 0),
                Position = UDim2.new(0, 5),
                BackgroundTransparency = 1,
                TextTruncate = "AtEnd",
                TextSize = 12,
                TextXAlignment = "Left"
            }), "Text")
            return {
                Set = function(_, New) if New then SectionLabel.Text = GetStr(New) end end
            }
        end

        function Tab:Paragraph(Configs)
            local PName = Configs[1] or Configs.Title or "Paragraph"
            local PDesc = Configs[2] or Configs.Text or Configs.Desc or ""
            local Frame, LabelFunc = ButtonFrame(Container, PName, PDesc, UDim2.new(1, -20))
            return {
                SetTitle = function(_, Val) LabelFunc:SetTitle(GetStr(Val)) end,
                SetDesc = function(_, Val) LabelFunc:SetDesc(GetStr(Val)) end,
                Set = function(_, Val1, Val2)
                    if Val1 and Val2 then
                        LabelFunc:SetTitle(GetStr(Val1))
                        LabelFunc:SetDesc(GetStr(Val2))
                    elseif Val1 then
                        LabelFunc:SetDesc(GetStr(Val1))
                    end
                end
            }
        end

        function Tab:Button(Configs)
            local BName = Configs[1] or Configs.Name or Configs.Title or "Button!"
            local BDescription = Configs.Desc or Configs.Description or ""
            local Callback = Funcs:GetCallback(Configs, 2)
            local FButton, LabelFunc = ButtonFrame(Container, BName, BDescription, UDim2.new(1, -20))
            Create("ImageLabel", FButton, {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -10, 0.5),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://10709791437"
            })
            FButton.Activated:Connect(function() Funcs:FireCallback(Callback) end)
            return {
                Set = function(_, Val1, Val2)
                    if type(Val1) == "string" and type(Val2) == "string" then
                        LabelFunc:SetTitle(Val1)
                        LabelFunc:SetDesc(Val2)
                    elseif type(Val1) == "string" then
                        LabelFunc:SetTitle(Val1)
                    end
                end
            }
        end

        function Tab:Toggle(Configs)
            local TName = Configs[1] or Configs.Name or Configs.Title or "Toggle"
            local TDesc = Configs.Desc or Configs.Description or ""
            local Callback = Funcs:GetCallback(Configs, 3)
            local Flag = Configs[4] or Configs.Flag or false
            local Default = Configs[2]
            if Default == nil then Default = Configs.Default or false end
            if CheckFlag(Flag) then Default = GetFlag(Flag) end

            local Button, LabelFunc = ButtonFrame(Container, TName, TDesc, UDim2.new(1, -38))
            local ToggleHolder = InsertTheme(Create("Frame", Button, {
                Size = UDim2.new(0, 35, 0, 18),
                Position = UDim2.new(1, -10, 0.5),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme["Color Stroke"]
            }), "Stroke")
            Make("Corner", ToggleHolder, UDim.new(0.5, 0))

            local Slider = Create("Frame", ToggleHolder, {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.8, 0, 0.8, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5)
            })

            local ToggleKnob = InsertTheme(Create("Frame", Slider, {
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(0, 0, 0.5),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme["Color Theme"]
            }), "Theme")
            Make("Corner", ToggleKnob, UDim.new(0.5, 0))

            local WaitToggle
            local function SetToggle(Val)
                if WaitToggle then return end
                WaitToggle, Default = true, Val
                SetFlag(Flag, Default)
                Funcs:FireCallback(Callback, Default)
                if Default then
                    CreateTween({ToggleKnob, "Position", UDim2.new(1, 0, 0.5), 0.25})
                    CreateTween({ToggleKnob, "BackgroundTransparency", 0, 0.25})
                    CreateTween({ToggleKnob, "AnchorPoint", Vector2.new(1, 0.5), 0.25})
                else
                    CreateTween({ToggleKnob, "Position", UDim2.new(0, 0, 0.5), 0.25})
                    CreateTween({ToggleKnob, "BackgroundTransparency", 0.8, 0.25})
                    CreateTween({ToggleKnob, "AnchorPoint", Vector2.new(0, 0.5), 0.25})
                end
                WaitToggle = false
            end
            task.spawn(SetToggle, Default)

            Button.Activated:Connect(function() SetToggle(not Default) end)
            return {
                Set = function(_, Val1)
                    if type(Val1) == "boolean" then task.spawn(SetToggle, Val1) end
                end
            }
        end

        function Tab:Dropdown(Configs)
            local DName = Configs[1] or Configs.Name or Configs.Title or "Dropdown"
            local DDesc = Configs.Desc or Configs.Description or ""
            local DOptions = Configs[2] or Configs.Options or {}
            local OpDefault = Configs[3] or Configs.Default or {}
            local Flag = Configs[5] or Configs.Flag or false
            local DMultiSelect = Configs.MultiSelect or false
            local Callback = Funcs:GetCallback(Configs, 4)

            local Button, LabelFunc = ButtonFrame(Container, DName, DDesc, UDim2.new(1, -180))
            local SelectedFrame = InsertTheme(Create("Frame", Button, {
                Size = UDim2.new(0, 150, 0, 18),
                Position = UDim2.new(1, -10, 0.5),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme["Color Stroke"]
            }), "Stroke")
            Make("Corner", SelectedFrame, UDim.new(0, 4))

            local ActiveLabel = InsertTheme(Create("TextLabel", SelectedFrame, {
                Size = UDim2.new(0.85, 0, 0.85, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextScaled = true,
                TextColor3 = Theme["Color Text"],
                Text = "..."
            }), "Text")

            local Arrow = Create("ImageLabel", SelectedFrame, {
                Size = UDim2.new(0, 15, 0, 15),
                Position = UDim2.new(0, -5, 0.5),
                AnchorPoint = Vector2.new(1, 0.5),
                Image = "rbxassetid://10709791523",
                BackgroundTransparency = 1
            })

            local NoClickFrame = Create("TextButton", DropdownHolder, {
                Name = "AntiClick",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Visible = false,
                Text = ""
            })

            local DropFrame = Create("Frame", NoClickFrame, {
                Size = UDim2.new(SelectedFrame.Size.X, 0, 0),
                BackgroundTransparency = 0.1,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                AnchorPoint = Vector2.new(0, 1),
                Name = "DropdownFrame",
                ClipsDescendants = true,
                Active = true
            })
            Make("Corner", DropFrame)
            Make("Stroke", DropFrame)
            Make("Gradient", DropFrame, {Rotation = 60})

            local ScrollFrame = InsertTheme(Create("ScrollingFrame", DropFrame, {
                ScrollBarImageColor3 = Theme["Color Theme"],
                Size = UDim2.new(1, 0, 1, 0),
                ScrollBarThickness = 1.5,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.new(),
                ScrollingDirection = "Y",
                AutomaticCanvasSize = "Y",
                Active = true
            }, {
                Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 5),
                    PaddingBottom = UDim.new(0, 5)
                }),
                Create("UIListLayout", {Padding = UDim.new(0, 4)})
            }), "ScrollBar")

            local ScrollSize, WaitDrop = 5
            local function Disable()
                WaitDrop = true
                CreateTween({Arrow, "Rotation", 0, 0.2})
                CreateTween({DropFrame, "Size", UDim2.new(0, 152, 0, 0), 0.2, true})
                CreateTween({Arrow, "ImageColor3", Color3.fromRGB(255, 255, 255), 0.2})
                Arrow.Image = "rbxassetid://10709791523"
                NoClickFrame.Visible = false
                WaitDrop = false
            end

            local function GetFrameSize()
                return UDim2.fromOffset(152, ScrollSize)
            end

            local function CalculateSize()
                local Count = 0
                for _, Frm in pairs(ScrollFrame:GetChildren()) do
                    if Frm:IsA("Frame") or Frm.Name == "Option" then
                        Count = Count + 1
                    end
                end
                ScrollSize = (math.clamp(Count, 0, 10) * 25) + 10
                if NoClickFrame.Visible then
                    CreateTween({DropFrame, "Size", GetFrameSize(), 0.2, true})
                end
            end

            local function ToggleDrop()
                if WaitDrop then return end
                WaitDrop = true
                if NoClickFrame.Visible then
                    Arrow.Image = "rbxassetid://10709791523"
                    CreateTween({Arrow, "ImageColor3", Color3.fromRGB(255, 255, 255), 0.2})
                    CreateTween({DropFrame, "Size", UDim2.new(0, 152, 0, 0), 0.2, true})
                    NoClickFrame.Visible = false
                else
                    NoClickFrame.Visible = true
                    Arrow.Image = "rbxassetid://10709790948"
                    CreateTween({Arrow, "ImageColor3", Theme["Color Theme"], 0.2})
                    CreateTween({DropFrame, "Size", GetFrameSize(), 0.2, true})
                end
                WaitDrop = false
            end

            local function CalculatePos()
                local FramePos = SelectedFrame.AbsolutePosition
                local ScreenSize = ScreenGui.AbsoluteSize
                local ClampX = math.clamp((FramePos.X / UIScale), 0, ScreenSize.X / UIScale - DropFrame.Size.X.Offset)
                local ClampY = math.clamp((FramePos.Y / UIScale), 0, ScreenSize.Y / UIScale)
                local NewPos = UDim2.fromOffset(ClampX, ClampY)
                local AnchorPoint = FramePos.Y > ScreenSize.Y / 1.4 and 1 or ScrollSize > 80 and 0.5 or 0
                DropFrame.AnchorPoint = Vector2.new(0, AnchorPoint)
                CreateTween({DropFrame, "Position", NewPos, 0.1})
            end

            local Default = type(OpDefault) ~= "table" and {OpDefault} or OpDefault
            local Options = {}
            local SelectedVal = DMultiSelect and {} or CheckFlag(Flag) and GetFlag(Flag) or Default[1]

            local function CallbackSelected()
                SetFlag(Flag, DMultiSelect and SelectedVal or tostring(SelectedVal))
                Funcs:FireCallback(Callback, SelectedVal)
            end

            local function UpdateLabel()
                ActiveLabel.Text = tostring(SelectedVal or "...")
            end

            local function UpdateSelected()
                for _, v in pairs(Options) do
                    local Slt = v.Value == SelectedVal
                    local nodes = v.nodes
                    CreateTween({nodes[2], "BackgroundTransparency", Slt and 0 or 1, 0.35})
                    CreateTween({nodes[2], "Size", Slt and UDim2.fromOffset(4, 14) or UDim2.fromOffset(4, 4), 0.35})
                    CreateTween({nodes[3], "TextTransparency", Slt and 0 or 0.4, 0.35})
                end
                UpdateLabel()
            end

            local function Select(Option)
                SelectedVal = Option.Value
                CallbackSelected()
                UpdateSelected()
            end

            local function AddOption(index, Value)
                local Name = tostring(type(index) == "string" and index or Value)
                if Options[Name] then return end
                Options[Name] = {index = index, Value = Value, Name = Name}

                local OptBtn = Make("Button", ScrollFrame, {
                    Name = "Option",
                    Size = UDim2.new(1, 0, 0, 21),
                    Position = UDim2.new(0, 0, 0.5),
                    AnchorPoint = Vector2.new(0, 0.5)
                })
                Make("Corner", OptBtn, UDim.new(0, 4))

                local IsSelected = InsertTheme(Create("Frame", OptBtn, {
                    Position = UDim2.new(0, 1, 0.5),
                    Size = UDim2.new(0, 4, 0, 4),
                    BackgroundColor3 = Theme["Color Theme"],
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0, 0.5)
                }), "Theme")
                Make("Corner", IsSelected, UDim.new(0.5, 0))

                local OptionName = InsertTheme(Create("TextLabel", OptBtn, {
                    Size = UDim2.new(1, 0, 1),
                    Position = UDim2.new(0, 10),
                    Text = Name,
                    TextColor3 = Theme["Color Text"],
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = "Left",
                    BackgroundTransparency = 1,
                    TextTransparency = 0.4
                }), "Text")

                OptBtn.Activated:Connect(function() Select(Options[Name]) end)
                Options[Name].nodes = {OptBtn, IsSelected, OptionName}
            end

            for k, v in pairs(DOptions) do AddOption(k, v) end
            CallbackSelected()
            UpdateSelected()

            Button.Activated:Connect(ToggleDrop)
            NoClickFrame.MouseButton1Down:Connect(Disable)
            NoClickFrame.MouseButton1Click:Connect(Disable)
            MainFrame:GetPropertyChangedSignal("Visible"):Connect(Disable)
            SelectedFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(CalculatePos)
            Button.Activated:Connect(CalculateSize)
            CalculatePos()
            CalculateSize()
            return {}
        end

        function Tab:Slider(Configs)
            local SName = Configs[1] or Configs.Name or Configs.Title or "Slider!"
            local SDesc = Configs.Desc or Configs.Description or ""
            local Min = Configs[2] or Configs.MinValue or Configs.Min or 10
            local Max = Configs[3] or Configs.MaxValue or Configs.Max or 100
            local Increase = Configs[4] or Configs.Increase or 1
            local Callback = Funcs:GetCallback(Configs, 6)
            local Flag = Configs[7] or Configs.Flag or false
            local Default = Configs[5] or Configs.Default or 25
            if CheckFlag(Flag) then Default = GetFlag(Flag) end
            Min, Max = Min / Increase, Max / Increase

            local Button, LabelFunc = ButtonFrame(Container, SName, SDesc, UDim2.new(1, -180))
            local SliderHolder = Create("TextButton", Button, {
                Size = UDim2.new(0.45, 0, 1),
                Position = UDim2.new(1),
                AnchorPoint = Vector2.new(1, 0),
                AutoButtonColor = false,
                Text = "",
                BackgroundTransparency = 1
            })

            local SliderBar = InsertTheme(Create("Frame", SliderHolder, {
                BackgroundColor3 = Theme["Color Stroke"],
                Size = UDim2.new(1, -20, 0, 6),
                Position = UDim2.new(0.5, 0, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5)
            }), "Stroke")
            Make("Corner", SliderBar)

            local Indicator = InsertTheme(Create("Frame", SliderBar, {
                BackgroundColor3 = Theme["Color Theme"],
                Size = UDim2.fromScale(0.3, 1),
                BorderSizePixel = 0
            }), "Theme")
            Make("Corner", Indicator)

            local SliderIcon = Create("Frame", SliderBar, {
                Size = UDim2.new(0, 6, 0, 12),
                BackgroundColor3 = Color3.fromRGB(220, 220, 220),
                Position = UDim2.fromScale(0.3, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 0.2
            })
            Make("Corner", SliderIcon)

            local LabelVal = InsertTheme(Create("TextLabel", SliderHolder, {
                Size = UDim2.new(0, 14, 0, 14),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(0, 0, 0.5),
                BackgroundTransparency = 1,
                TextColor3 = Theme["Color Text"],
                Font = Enum.Font.FredokaOne,
                TextSize = 12
            }), "Text")

            local BaseMousePos = Create("Frame", SliderBar, {
                Position = UDim2.new(0, 0, 0.5, 0),
                Visible = false
            })

            local function UpdateLabel(NewValue)
                local Number = tonumber(NewValue * Increase)
                Number = math.floor(Number * 100) / 100
                Default, LabelVal.Text = Number, tostring(Number)
                Funcs:FireCallback(Callback, Default)
            end

            local function ControlPos()
                local MousePos = Player:GetMouse()
                local APos = MousePos.X - BaseMousePos.AbsolutePosition.X
                local ConfigureDpiPos = APos / SliderBar.AbsoluteSize.X
                SliderIcon.Position = UDim2.new(math.clamp(ConfigureDpiPos, 0, 1), 0, 0.5, 0)
            end

            local function UpdateValues()
                Indicator.Size = UDim2.new(SliderIcon.Position.X.Scale, 0, 1, 0)
                local SliderPos = SliderIcon.Position.X.Scale
                local NewValue = math.floor(((SliderPos * Max) / Max) * (Max - Min) + Min)
                UpdateLabel(NewValue)
            end

            SliderHolder.MouseButton1Down:Connect(function()
                CreateTween({SliderIcon, "Transparency", 0, 0.3})
                Container.ScrollingEnabled = false
                while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    task.wait()
                    ControlPos()
                end
                CreateTween({SliderIcon, "Transparency", 0.2, 0.3})
                Container.ScrollingEnabled = true
                SetFlag(Flag, Default)
            end)

            local function SetSlider(NewValue)
                if type(NewValue) ~= "number" then return end
                local MinVal, MaxVal = Min * Increase, Max * Increase
                local SliderPos = (NewValue - MinVal) / (MaxVal - MinVal)
                SetFlag(Flag, NewValue)
                CreateTween({SliderIcon, "Position", UDim2.fromScale(math.clamp(SliderPos, 0, 1), 0.5), 0.3, true})
            end
            SetSlider(Default)
            SliderIcon:GetPropertyChangedSignal("Position"):Connect(UpdateValues)
            UpdateValues()
            return {}
        end

        function Tab:TextBox(Configs)
            local TName = Configs[1] or Configs.Name or Configs.Title or "Text Box"
            local TDesc = Configs.Desc or Configs.Description or ""
            local TPlaceholderText = Configs[5] or Configs.PlaceholderText or "Input"
            local TClearText = Configs[3] or Configs.ClearText or false
            local Callback = Funcs:GetCallback(Configs, 4)

            local Button, LabelFunc = ButtonFrame(Container, TName, TDesc, UDim2.new(1, -38))
            local SelectedFrame = InsertTheme(Create("Frame", Button, {
                Size = UDim2.new(0, 150, 0, 18),
                Position = UDim2.new(1, -10, 0.5),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Theme["Color Stroke"]
            }), "Stroke")
            Make("Corner", SelectedFrame, UDim.new(0, 4))

            local TextBoxInput = InsertTheme(Create("TextBox", SelectedFrame, {
                Size = UDim2.new(0.85, 0, 0.85, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextScaled = true,
                TextColor3 = Theme["Color Text"],
                ClearTextOnFocus = TClearText,
                PlaceholderText = TPlaceholderText,
                Text = ""
            }), "Text")

            local function Input()
                local Text = TextBoxInput.Text
                if Text:gsub(" ", ""):len() > 0 then
                    Funcs:FireCallback(Callback, Text)
                end
            end
            TextBoxInput.FocusLost:Connect(Input)
            return {}
        end

        function Tab:DiscordInvite(Configs)
            local TitleTxt = Configs[1] or Configs.Name or Configs.Title or "Discord"
            local Desc = Configs.Desc or Configs.Description or ""
            local Logo = Configs[2] or Configs.Logo or ""
            local Invite = Configs[3] or Configs.Invite or ""

            local InviteHolder = Create("Frame", Container, {
                Size = UDim2.new(1, 0, 0, 80),
                Name = "Option",
                BackgroundTransparency = 1
            })
            Create("TextLabel", InviteHolder, {
                Size = UDim2.new(1, 0, 0, 15),
                Position = UDim2.new(0, 5),
                TextColor3 = Color3.fromRGB(40, 150, 255),
                Font = Enum.Font.GothamBold,
                TextXAlignment = "Left",
                BackgroundTransparency = 1,
                TextSize = 10,
                Text = Invite
            })
            local FrameHolder = InsertTheme(Create("Frame", InviteHolder, {
                Size = UDim2.new(1, 0, 0, 65),
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1),
                BackgroundColor3 = Theme["Color Hub 2"]
            }), "Frame")
            Make("Corner", FrameHolder)

            local ImageLabel = Create("ImageLabel", FrameHolder, {
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(0, 7, 0, 7),
                Image = Logo,
                BackgroundTransparency = 1
            })
            Make("Corner", ImageLabel, UDim.new(0, 4))
            Make("Stroke", ImageLabel)

            InsertTheme(Create("TextLabel", FrameHolder, {
                Size = UDim2.new(1, -52, 0, 15),
                Position = UDim2.new(0, 44, 0, 7),
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme["Color Text"],
                TextXAlignment = "Left",
                BackgroundTransparency = 1,
                TextSize = 10,
                Text = TitleTxt
            }), "Text")

            InsertTheme(Create("TextLabel", FrameHolder, {
                Size = UDim2.new(1, -52, 0, 0),
                Position = UDim2.new(0, 44, 0, 22),
                TextWrapped = true,
                AutomaticSize = "Y",
                Font = Enum.Font.Gotham,
                TextColor3 = Theme["Color Dark Text"],
                TextXAlignment = "Left",
                BackgroundTransparency = 1,
                TextSize = 8,
                Text = Desc
            }), "DarkText")

            local JoinButton = Create("TextButton", FrameHolder, {
                Size = UDim2.new(1, -14, 0, 16),
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -7),
                Text = "Join",
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(220, 220, 220),
                BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            })
            Make("Corner", JoinButton, UDim.new(0, 5))

            local ClickDelay
            JoinButton.Activated:Connect(function()
                if setclipboard then setclipboard(Invite) end
                if ClickDelay then return end
                ClickDelay = true
                SetProps(JoinButton, {
                    Text = "Copied to Clipboard",
                    BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                })
                task.wait(3)
                SetProps(JoinButton, {
                    Text = "Join",
                    BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                })
                ClickDelay = false
            end)
            return {}
        end
        return Tab
    end

    CloseButton.Activated:Connect(Window.CloseBtn)
    MinimizeButton.Activated:Connect(Window.MinimizeBtn)
    return Window
end

-- =================================================================================
-- PHẦN 2: HỆ THỐNG DI CHUYỂN BAY (TOPOS / TP2 / PORTAL ENTRANCE) NGUYÊN BẢN DATTHG V2
-- =================================================================================
local PlaceId = game.PlaceId
World1 = (PlaceId == 2753915549)
World2 = (PlaceId == 4442272183)
World3 = (PlaceId == 7449423635 or PlaceId == 100117331123089 or (not World1 and not World2))

_G.SelectWeapon = "Melee"
_G.TweenPosYHight = true
_G.SpinPos = false
_G.PosX = 0
_G.PosY = 20
_G.PosZ = 0
_G.BringMonster = true
_G.BringMode = 200
_G.AutoHaki = true
_G.Auto_CFrame = true
getgenv().TweenSpeed = 350

Pos = CFrame.new(0, 20, 0)
PosLv = CFrame.new(0, 25, 0)

-- Cập nhật Pos từ PosX, PosY, PosZ hoặc SpinPos như trong DatThg V2
task.spawn(function()
    local angle = 0
    while task.wait(0.05) do
        if _G.SpinPos then
            angle = angle + 0.35
            Pos = CFrame.new(math.cos(angle) * 18, tonumber(_G.PosY) or 20, math.sin(angle) * 18)
            PosLv = Pos
        else
            Pos = CFrame.new(tonumber(_G.PosX) or 0, tonumber(_G.PosY) or 20, tonumber(_G.PosZ) or 0)
            PosLv = CFrame.new(tonumber(_G.PosX) or 0, tonumber(_G.PosY) or 25, tonumber(_G.PosZ) or 0)
        end
    end
end)

function round(num)
    return math.floor(tonumber(num) + 0.5)
end

function GetDistance(target)
    local pos = typeof(target) == "CFrame" and target.Position or target
    return LocalPlayer:DistanceFromCharacter(pos)
end

function requestEntrance(vectorPos)
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", vectorPos)
    end)
end

-- Hàm CheckNearestTeleporter nguyên bản từ DatThg V2 giúp bay xa không bị giật ngược
function CheckNearestTeleporter(targetCFrame)
    local vcspos = targetCFrame.Position
    local min = math.huge
    local chosenPortal = nil
    local TableLocations = {}

    if World3 then
        TableLocations = {
            ["Mansion"] = Vector3.new(-12471.169921875, 374.94024658203, -7551.677734375),
            ["Castle On The Sea"] = Vector3.new(-5075.50927734375, 314.5155029296875, -3150.0224609375),
            ["Hydra"] = Vector3.new(5661.5322265625, 1013.0907592773438, -334.9619140625),
            ["Temple Of Time"] = Vector3.new(28286.35546875, 14895.3017578125, 102.62469482421875)
        }
    elseif World2 then
        TableLocations = {
            ["Mansion"] = Vector3.new(-390.48, 331.88, 673.92),
            ["Flamingo"] = Vector3.new(2284.912109375, 15.537666320801, 905.48291015625),
            ["OutShip"] = Vector3.new(-6508.5581054688, 89.034996032715, -132.83953857422),
            ["InShip"] = Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)
        }
    elseif World1 then
        TableLocations = {
            ["Sky1"] = Vector3.new(-4654.82, 872.54, -1759.56),
            ["Sky2"] = Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047),
            ["UnderWater"] = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875),
            ["Whirlpool"] = Vector3.new(3864.6884765625, 6.7369503974915, -1926.2141113281)
        }
    end

    for _, v in pairs(TableLocations) do
        local dist = (v - vcspos).Magnitude
        if dist <= min then
            min = dist
            chosenPortal = v
        end
    end

    local playerDist = GetDistance(targetCFrame)
    if chosenPortal and min < (playerDist - 600) then
        return chosenPortal
    end
    return nil
end

local ActiveTween = nil

function StopTween(targetBool)
    if not targetBool then
        _G.StopTween = true
        if ActiveTween then
            pcall(function() ActiveTween:Cancel() end)
            ActiveTween = nil
        end
        pcall(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if root:FindFirstChild("BodyClip") then
                    root.BodyClip:Destroy()
                end
                root.CFrame = root.CFrame
            end
        end)
        _G.StopTween = false
    end
end

-- Hàm topos chuẩn DatThg V2 (Cân bằng Y, gọi Portal nếu xa, giữ BodyClip chống giật)
function topos(targetCFrame)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not char or not root or not hum or hum.Health <= 0 then return end

        if hum.Sit then hum.Sit = false end

        local Distance = (targetCFrame.Position - root.Position).Magnitude

        -- Tải trước bản đồ xung quanh điểm đến để không bị rơi vào vùng chưa load
        if Distance > 350 and ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("RequestStreamAroundAsync") then
            pcall(function()
                ReplicatedStorage.Remotes.RequestStreamAroundAsync:FireServer(targetCFrame.Position)
            end)
        end

        if Distance <= 20 then
            if ActiveTween then
                pcall(function() ActiveTween:Cancel() end)
                ActiveTween = nil
            end
            root.CFrame = targetCFrame
            return
        end

        -- Kiểm tra cổng dịch chuyển gần nhất nếu khoảng cách > 2200 studs
        local nearestPortal = CheckNearestTeleporter(targetCFrame)
        if nearestPortal and Distance > 2200 then
            if ActiveTween then
                pcall(function() ActiveTween:Cancel() end)
                ActiveTween = nil
            end
            requestEntrance(nearestPortal)
            task.wait(0.6)
            return
        end

        -- Tạo BodyClip giữ nhân vật trên không để không bị trọng lực kéo giật
        if not root:FindFirstChild("BodyClip") then
            local Noclip = Instance.new("BodyVelocity")
            Noclip.Name = "BodyClip"
            Noclip.Parent = root
            Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
            Noclip.Velocity = Vector3.new(0, 0, 0)
        end

        -- Đồng bộ độ cao Y trước khi bay ngang (Chuẩn DatThg V2)
        if _G.TweenPosYHight and math.abs(root.Position.Y - targetCFrame.Position.Y) > 15 then
            root.CFrame = CFrame.new(root.Position.X, targetCFrame.Position.Y, root.Position.Z)
        end

        local speed = tonumber(getgenv().TweenSpeed) or 350
        local tweenTime = (targetCFrame.Position - root.Position).Magnitude / speed
        ActiveTween = TweenService:Create(
            root,
            TweenInfo.new(tweenTime, Enum.EasingStyle.Linear),
            {CFrame = targetCFrame}
        )
        ActiveTween:Play()
    end)
end

function TP2(targetCFrame)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local dist = (targetCFrame.Position - root.Position).Magnitude
        if dist <= 180 then
            root.CFrame = targetCFrame
        else
            topos(targetCFrame)
        end
    end)
end

-- Luồng Noclip tự động khi có BodyClip
RunService.Stepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if char and root and root:FindFirstChild("BodyClip") then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end)
end)

-- =================================================================================
-- PHẦN 3: CÁC HÀM LÕI COMBAT, EQUIP, BRINGMOBS, KILLMOB TỪ DATTHG V2
-- =================================================================================
function UnEquipWeapon(Weapon)
    if LocalPlayer.Character:FindFirstChild(Weapon) then
        _G.NotAutoEquip = true
        task.wait(0.5)
        LocalPlayer.Character[Weapon].Parent = LocalPlayer.Backpack
        task.wait(0.1)
        _G.NotAutoEquip = false
    end
end

function EquipWeapon(ToolSe)
    if _G.NotAutoEquip then return end
    pcall(function()
        local target = ToolSe or _G.SelectWeapon
        local targetTip = (target == "Fruit") and "Demon Fruit" or target
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not char or not bp then return end

        local held = char:FindFirstChildOfClass("Tool")
        if held and (held.Name == target or held.ToolTip == targetTip or held:GetAttribute("WeaponType") == targetTip) then
            return
        end

        if bp:FindFirstChild(target) then
            char.Humanoid:EquipTool(bp:FindFirstChild(target))
            return
        end

        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and (tool.ToolTip == targetTip or tool:GetAttribute("WeaponType") == targetTip) then
                char.Humanoid:EquipTool(tool)
                return
            end
        end
    end)
end

function BringMobs(targetCFrame, mobName)
    if _G.BringMonster == false then return 0 end
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return 0 end
    local range = tonumber(_G.BringMode) or 250
    local moved = 0
    for _, enemy in ipairs(enemies:GetChildren()) do
        if not mobName or enemy.Name == mobName then
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 and (root.Position - targetCFrame.Position).Magnitude <= range then
                root.CanCollide = false
                root.CFrame = targetCFrame
                root.Velocity = Vector3.zero
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                if hum:FindFirstChild("Animator") then
                    hum.Animator:Destroy()
                end
                local head = enemy:FindFirstChild("Head")
                if head then head.CanCollide = false end
                moved = moved + 1
            end
        end
    end
    if moved > 0 and type(sethiddenproperty) == "function" then
        pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)
    end
    return moved
end

local CakeAndBoneTable = {
    ["Cake"] = {
        ["Cookie Crafter"] = CFrame.new(-2333.28052, 37.8239059, -12093.2861),
        ["Cake Guard"]     = CFrame.new(-1575.56433, 37.8238907, -12416.2529),
        ["Baking Staff"]   = CFrame.new(-1872.35742, 37.8239517, -12899.4248),
        ["Head Baker"]     = CFrame.new(-2223.14160, 53.5283203, -12854.7520)
    },
    ["Bone"] = {
        ["Reborn Skeleton"] = CFrame.new(-8769.58984, 142.130630, 6055.27637),
        ["Living Zombie"]   = CFrame.new(-10156.4531, 138.652481, 5964.57520),
        ["Demonic Soul"]    = CFrame.new(-9525.17188, 172.130630, 6152.30566),
        ["Posessed Mummy"]  = CFrame.new(-9570.88281, 5.81831884, 6187.86279)
    }
}

function BringEnemies(modeKey)
    local group = CakeAndBoneTable[modeKey]
    if not group or not _G.BringMonster then return end
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end
    for _, v in ipairs(enemies:GetChildren()) do
        if group[v.Name] and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            BringMobs(v.HumanoidRootPart.CFrame, v.Name)
            break
        end
    end
end

function GetClosestEnemyPart()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local enemies = Workspace:FindFirstChild("Enemies")
    if not root or not enemies then return nil end
    local best, minDist = nil, math.huge
    for _, v in ipairs(enemies:GetChildren()) do
        local hrp = v:FindFirstChild("HumanoidRootPart")
        local hum = v:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local d = (hrp.Position - root.Position).Magnitude
            if d < minDist then
                minDist = d
                best = hrp
            end
        end
    end
    return best
end

-- Hàm KillMob chuẩn DatThg V2
function KillMob(v)
    pcall(function()
        if v and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            EquipWeapon(_G.SelectWeapon)
            PosMon = v.HumanoidRootPart.CFrame
            BringMobs(PosMon, v.Name)
            TP2(v.HumanoidRootPart.CFrame * Pos)
        end
    end)
end

-- Hệ thống Fast Attack & Combat Heartbeat
local lastCombat = 0
RunService.Heartbeat:Connect(function()
    if tick() - lastCombat < 0.08 then return end
    lastCombat = tick()

    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum or hum.Health <= 0 then return end

        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return end

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

        local targetPart = GetClosestEnemyPart()
        if targetPart and (targetPart.Position - root.Position).Magnitude <= 75 then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
                if tool:FindFirstChild("LeftClickRemote") then
                    tool.LeftClickRemote:FireServer(Vector3.new(0, -1, 0), 1)
                elseif tool:FindFirstChild("RemoteEvent") then
                    tool.RemoteEvent:FireServer(targetPart.Position)
                end
            end

            local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
            if net then
                if net:FindFirstChild("RE/RegisterAttack") then net["RE/RegisterAttack"]:FireServer(0) end
                if net:FindFirstChild("RE/RegisterHit") then net["RE/RegisterHit"]:FireServer(targetPart, {}) end
                if _G.AutoShootGun and net:FindFirstChild("RE/ShootGunEvent") then
                    net["RE/ShootGunEvent"]:FireServer(targetPart.Position)
                end
            end

            if _G.AutoClick then
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(1280, 672))
            end
        end
    end)
end)

-- =================================================================================
-- PHẦN 4: KHỞI TẠO CỬA SỔ ANIME BLACKER HUB & TOÀN BỘ 13 TABS CỦA DATTHG V2
-- =================================================================================
local Window = redzlib:MakeWindow({
    Title = "⚡ ANIME BLACKER HUB",
    SubTitle = "Full DatThg V2 Engine | by HUYKOGIAUVN",
    SaveFolder = "AnimeBlacker_DatThg.lua"
})

Window:AddMinimizeButton({
    Button = {
        Image = "rbxassetid://103005206148603",
        BackgroundTransparency = 0
    },
    Corner = {
        CornerRadius = UDim.new(0, 6)
    }
})

local TabDiscord  = Window:T({"Discord",       "rbxassetid://10723415903"})
local TabFarm     = Window:T({"Farm",          "rbxassetid://10723407389"})
local TabSetting  = Window:T({"Setting",       "rbxassetid://10734950309"})
local TabQuest    = Window:T({"Quest/Item",    "rbxassetid://10734975692"})
local TabRace     = Window:T({"Race/Mirage",   "rbxassetid://10747372167"})
local TabEvent    = Window:T({"Event",         "rbxassetid://10709783577"})
local TabPlayer   = Window:T({"Player",        "rbxassetid://10747373176"})
local TabVisual   = Window:T({"Visual",        "rbxassetid://10723346959"})
local TabRaid     = Window:T({"Raid",          "rbxassetid://10723345749"})
local TabTeleport = Window:T({"Teleport",      "rbxassetid://10723434557"})
local TabShop     = Window:T({"Shop",          "rbxassetid://10734952479"})
local TabFruit    = Window:T({"Devil Fruit",   "rbxassetid://10709761889"})
local TabMisc     = Window:T({"Miscellaneous", "rbxassetid://10709782582"})

-- ---------------------------------------------------------------------------------
-- TAB 1: DISCORD & STATUS PLAYER
-- ---------------------------------------------------------------------------------
TabDiscord:Section("Join Discord")
TabDiscord:DiscordInvite({
    Name = "Anime Blacker x DatThg",
    Logo = "rbxassetid://103005206148603",
    Description = "Join our discord community to receive information about the next update",
    Invite = "https://discord.com/invite/E2N7w35zkt"
})
TabDiscord:Section("Status Player")
local P_Time   = TabDiscord:Paragraph({Title = "Executer Time", Desc = ""})
local P_Race   = TabDiscord:Paragraph({Title = "Race", Desc = ""})
local P_Beli   = TabDiscord:Paragraph({Title = "Beli", Desc = ""})
local P_Frag   = TabDiscord:Paragraph({Title = "Fragments", Desc = ""})
local P_Bounty = TabDiscord:Paragraph({Title = "Bounty", Desc = ""})
local P_Fruit  = TabDiscord:Paragraph({Title = "Devil Fruit", Desc = ""})

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

-- ---------------------------------------------------------------------------------
-- TAB 2: FARM
-- ---------------------------------------------------------------------------------
TabFarm:Section("Farm Mode")
TabFarm:Dropdown({
    Name = "Select Weapon",
    Default = "Melee",
    Options = {"Melee", "Sword", "Fruit", "Gun"},
    Callback = function(v) _G.SelectWeapon = v end
})
TabFarm:Dropdown({
    Name = "UI Scale",
    Default = "Large",
    Options = {"Small", "Medium", "Large", "Bigger"},
    Callback = function(v)
        if v == "Small" then redzlib:SetScale(580)
        elseif v == "Medium" then redzlib:SetScale(500)
        elseif v == "Large" then redzlib:SetScale(450)
        elseif v == "Bigger" then redzlib:SetScale(380) end
    end
})

TabFarm:Section("Farming")
TabFarm:Toggle({"Auto Farm Level", false, function(v)
    _G.AutoFarmLevel = v
    StopTween(v)
end})
TabFarm:Toggle({"Auto Farm Cake Prince", false, function(v)
    _G.AutoFarmCake = v
    StopTween(v)
end})
TabFarm:Toggle({"Auto Farm Bone", false, function(v)
    _G.AutoFarmBone = v
    StopTween(v)
end})
TabFarm:Toggle({"Auto Farm Chest", false, function(v)
    _G.FarmChest = v
    StopTween(v)
end})

local MobNames = {
    "Forest Pirate", "Mythological Pirate", "Ocean Prophet", "High Disciple",
    "Grand Devotee", "Jack o' Lantern", "Cookie Crafter", "Cake Guard",
    "Baking Staff", "Head Baker", "Reborn Skeleton", "Living Zombie",
    "Demonic Soul", "Posessed Mummy"
}
TabFarm:Dropdown({
    Name = "Select Mob",
    Default = "Forest Pirate",
    Options = MobNames,
    Callback = function(v) _G.SelectedMob = v end
})
TabFarm:Toggle({"Auto Farm Selected Mob", false, function(v)
    _G.AutoFarmMob = v
    StopTween(v)
end})

TabFarm:Section("Boss Farming")
local BossNames = {
    "Longma", "Stone", "Urban", "Diablo", "Cake Prince",
    "Dough King", "rip_indra True Form", "Beautiful Pirate", "Smoke Admiral"
}
TabFarm:Dropdown({
    Name = "Select Boss",
    Default = "Longma",
    Options = BossNames,
    Callback = function(v) _G.SelectBoss = v end
})
TabFarm:Toggle({"Auto Farm Boss", false, function(v)
    _G.AutoFarmBoss = v
    StopTween(v)
end})

-- ---------------------------------------------------------------------------------
-- TAB 3: SETTING
-- ---------------------------------------------------------------------------------
TabSetting:Section("Speed Tween")
TabSetting:Slider({"Tween Speed", 50, 350, 5, 350, function(v)
    getgenv().TweenSpeed = v
end})
TabSetting:Toggle({"Tween PosY Hight", true, function(v) _G.TweenPosYHight = v end})
TabSetting:Toggle({"Spin Pos", false, function(v) _G.SpinPos = v end})
TabSetting:Slider({"Select PosX", 1, 100, 5, 0, function(v) _G.PosX = v end})
TabSetting:Slider({"Select PosY", 1, 100, 5, 20, function(v) _G.PosY = v end})
TabSetting:Slider({"Select PosZ", 1, 100, 5, 0, function(v) _G.PosZ = v end})
TabSetting:Button({
    Name = "Stop All Tween",
    Callback = function() StopTween(false) end
})

TabSetting:Section("Setting Farming")
TabSetting:Toggle({"Auto Click", false, function(v) _G.AutoClick = v end})
TabSetting:Toggle({"Auto Shoot Gun", false, function(v) _G.AutoShootGun = v end})
TabSetting:Toggle({"Bring Mob", true, function(v) _G.BringMonster = v end})
TabSetting:Dropdown({
    Name = "Bring Mob Mode",
    Default = "200",
    Options = {"100", "200", "300", "350", "400", "500"},
    Callback = function(v) _G.BringMode = tonumber(v) or 200 end
})
TabSetting:Toggle({"Auto Haki", true, function(v) _G.AutoHaki = v end})
TabSetting:Toggle({"Auto Ken", false, function(v) _G.Observation = v end})
TabSetting:Toggle({"Kill Aura", false, function(v) _G.Kill_Aura = v end})
TabSetting:Toggle({"Disabled Notifications", false, function(v) _G.DisableNotifications = v end})
TabSetting:Toggle({"Disabled Damage Counter", false, function(v) _G.DisableDamageCounter = v end})

local BlurEffect = Instance.new("BlurEffect", Lighting)
BlurEffect.Size = 100
BlurEffect.Enabled = false
TabSetting:Toggle({"Fix Lag Screen", false, function(v) BlurEffect.Enabled = v end})
TabSetting:Toggle({"White Screen", false, function(v)
    _G.WhiteScreen = v
    pcall(function() RunService:Set3dRenderingEnabled(not v) end)
end})
TabSetting:Toggle({"Invisible Monsters", false, function(v) _G.InvisibleMonsters = v end})
TabSetting:Toggle({"Fps Boost", false, function(v)
    if v then
        pcall(function()
            if setfpscap then setfpscap(9999999) end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Texture") or obj:IsA("Decal") then
                    obj.Transparency = 1
                elseif obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
        end)
    end
end})

-- ---------------------------------------------------------------------------------
-- TAB 4: QUEST / ITEM (ĐẦY ĐỦ SEA 1, SEA 2, SEA 3)
-- ---------------------------------------------------------------------------------
TabQuest:Paragraph({Title = "Sea 1 / Sea 2 / Sea 3", Desc = "Full Quest & Item System from DatThg V2"})
TabQuest:Section("World 1 - Quest And Item")
TabQuest:Toggle({"Auto Greybeard", false, function(v) _G.Greybeard = v; StopTween(v) end})
TabQuest:Toggle({"Auto Saber", false, function(v) _G.AutoSaber = v; StopTween(v) end})
TabQuest:Toggle({"Auto Pole v1", false, function(v) _G.AutoPoleV1 = v; StopTween(v) end})

TabQuest:Section("World 2 - Quest And Item")
TabQuest:Toggle({"Auto Second Sea", false, function(v) _G.SecondSea = v; StopTween(v) end})
TabQuest:Toggle({"Auto Bartilo", false, function(v) _G.Bartilo = v; StopTween(v) end})
TabQuest:Toggle({"Auto Factory", false, function(v) _G.Factory = v; StopTween(v) end})
TabQuest:Toggle({"Auto Darkbeard", false, function(v) _G.AutoDarkbeard = v; StopTween(v) end})
TabQuest:Toggle({"Auto Swan Glasses", false, function(v) _G.FarmSwanGlasses = v; StopTween(v) end})
TabQuest:Toggle({"Auto Oder Sword", false, function(v) _G.OderSword = v; StopTween(v) end})

TabQuest:Section("Misc KoKo Sword")
TabQuest:Toggle({"Auto Law", false, function(v) _G.LawRaid = v; StopTween(v) end})
TabQuest:Toggle({"Auto Law Hop", false, function(v) _G.AutoLawHop = v; StopTween(v) end})
TabQuest:Button({
    Name = "Buy Microchip Law Boss",
    Callback = function()
        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward", "Microchip", "2") end)
    end
})
TabQuest:Button({
    Name = "Start Go To Raid Law Boss",
    Callback = function()
        pcall(function()
            fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
        end)
    end
})

TabQuest:Section("World 3 - Quest And Item")
TabQuest:Toggle({"Auto Third Sea", false, function(v) _G.ThirdSea = v; StopTween(v) end})
TabQuest:Toggle({"Auto Musketeer Hat", false, function(v) _G.MusketeerHat = v; StopTween(v) end})
TabQuest:Toggle({"Auto Buddy Sword", false, function(v) _G.BudySword = v; StopTween(v) end})
TabQuest:Toggle({"Auto Cavander", false, function(v) _G.Carvender = v; StopTween(v) end})
TabQuest:Toggle({"Auto Twin Hooks", false, function(v) _G.TwinHook = v; StopTween(v) end})
TabQuest:Toggle({"Auto Tushita", false, function(v) _G.tushita = v; StopTween(v) end})
TabQuest:Toggle({"Auto Holy Torch", false, function(v) _G.HolyTorch = v; StopTween(v) end})
TabQuest:Toggle({"Auto CDK Quest", false, function(v) _G.CDKQuest = v; StopTween(v) end})
TabQuest:Toggle({"Auto Soul Guitar", false, function(v) _G.Guitar = v; StopTween(v) end})
TabQuest:Toggle({"Auto Rainbow Haki", false, function(v) _G.Rainbow_Haki = v; StopTween(v) end})
TabQuest:Toggle({"Auto Elite Hunter", false, function(v) _G.AutoEliteHunter = v; StopTween(v) end})
TabQuest:Toggle({"Auto Tyrant of the Skies", false, function(v) _G.TyrantSkies = v; StopTween(v) end})
TabQuest:Toggle({"Auto Buy Legendary Sword Hop", false, function(v) _G.BuyLegendarySword_Hop = v end})

-- ---------------------------------------------------------------------------------
-- TAB 5: RACE / MIRAGE
-- ---------------------------------------------------------------------------------
TabRace:Section("Mirage Island & Race V4")
TabRace:Toggle({"Teleport To Temple of Time", false, function(v) _G.TpSkullCore = v; StopTween(v) end})
TabRace:Toggle({"Tween Mirage Gear", false, function(v) _G.TweenMGear = v; StopTween(v) end})
TabRace:Toggle({"Auto Buy Gear", false, function(v) _G.BuyGear = v end})
TabRace:Toggle({"Auto Race V3", false, function(v) _G.AutoRaceV3 = v end})
TabRace:Toggle({"Auto Awakening Race V4", false, function(v) _G.AutoRaceV4 = v end})

-- ---------------------------------------------------------------------------------
-- TAB 6: EVENT
-- ---------------------------------------------------------------------------------
TabEvent:Section("Sea Events & Prehistoric")
TabEvent:Toggle({"Auto Sea Beast", false, function(v) _G.Seabest = v; StopTween(v) end})
TabEvent:Toggle({"Auto Segment Leviathan", false, function(v) _G.SegmentLeviathan = v; StopTween(v) end})
TabEvent:Toggle({"Auto Defend Volcano", false, function(v) _G.DefendVolcano = v; StopTween(v) end})
TabEvent:Toggle({"Auto Collect Dragon Egg", false, function(v) _G.CollectEgg = v end})
TabEvent:Toggle({"Auto Collect Berry", false, function(v) _G.CollectBerry = v; StopTween(v) end})
TabEvent:Toggle({"Auto Kitsune Shrine", false, function(v) _G.AutoKitsuneShrine = v end})
TabEvent:Toggle({"Auto Fishing", false, function(v) _G.AutoFishing = v end})

-- ---------------------------------------------------------------------------------
-- TAB 7: PLAYER
-- ---------------------------------------------------------------------------------
TabPlayer:Section("Player & Stats")
local PlyList = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(PlyList, p.Name) end
end
if #PlyList == 0 then table.insert(PlyList, LocalPlayer.Name) end
TabPlayer:Dropdown({
    Name = "Select Player",
    Default = PlyList[1],
    Options = PlyList,
    Callback = function(v) _G.SelectPly = v end
})
TabPlayer:Toggle({"Teleport To Player", false, function(v) _G.TeleportPly = v; StopTween(v) end})
TabPlayer:Dropdown({
    Name = "Select Stat",
    Default = "Melee",
    Options = {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"},
    Callback = function(v) _G.SelectedStat = v end
})
TabPlayer:Toggle({"Auto Stats", false, function(v) _G.AutoStats = v end})

-- ---------------------------------------------------------------------------------
-- TAB 8: VISUAL
-- ---------------------------------------------------------------------------------
TabVisual:Section("ESP")
TabVisual:Toggle({"ESP Player", false, function(v) _G.ESPPlayer = v end})
TabVisual:Toggle({"ESP Devil Fruit", false, function(v) _G.DevilFruitESP = v end})
TabVisual:Toggle({"ESP Berries", false, function(v) _G.ESPBerry = v end})
TabVisual:Toggle({"ESP Mirage Island", false, function(v) _G.ESPMirage = v end})
TabVisual:Toggle({"ESP Kitsune Island", false, function(v) _G.ESPKitsune = v end})
TabVisual:Toggle({"ESP All Islands", false, function(v) _G.ESPIsland = v end})

-- ---------------------------------------------------------------------------------
-- TAB 9: RAID
-- ---------------------------------------------------------------------------------
TabRaid:Section("Raid Dungeon")
TabRaid:Dropdown({
    Name = "Select Chip",
    Default = "Flame",
    Options = {"Flame", "Ice", "Quake", "Light", "Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand", "Phoenix", "Dough"},
    Callback = function(v) _G.SelectChip = v end
})
TabRaid:Toggle({"Auto Buy Chip", false, function(v) _G.AutoBuyChip = v end})
TabRaid:Toggle({"Auto Start Raid", false, function(v) _G.AutoStartRaid = v end})
TabRaid:Toggle({"Auto Next Island", false, function(v) _G.AutoNextIsland = v; StopTween(v) end})
TabRaid:Toggle({"Auto Awaken", false, function(v) _G.AutoAwaken = v end})
TabRaid:Toggle({"Auto Raid Pirate", false, function(v) _G.RaidPirate = v; StopTween(v) end})

-- ---------------------------------------------------------------------------------
-- TAB 10: TELEPORT
-- ---------------------------------------------------------------------------------
TabTeleport:Section("World Teleport")
TabTeleport:Button({Name = "Travel First Sea", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelMain") end) end})
TabTeleport:Button({Name = "Travel Second Sea", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa") end) end})
TabTeleport:Button({Name = "Travel Third Sea", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou") end) end})

local IslandDict = {
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
TabTeleport:Dropdown({
    Name = "Select Island",
    Default = "Floating Turtle",
    Options = {"Floating Turtle", "Haunted Castle", "Castle on the Sea", "Port Town", "Hydra Island", "Great Tree", "Cake Loaf", "Tiki Outpost", "Temple of Time", "WindMill"},
    Callback = function(v) _G.SelectIsland = v end
})
TabTeleport:Button({
    Name = "Teleport To Selected Island",
    Callback = function()
        if IslandDict[_G.SelectIsland] then topos(IslandDict[_G.SelectIsland]) end
    end
})
TabTeleport:Button({
    Name = "Teleport to Lab",
    Callback = function() topos(CFrame.new(-5010.67, 313.86, -2995.32)) end
})

-- ---------------------------------------------------------------------------------
-- TAB 11: SHOP
-- ---------------------------------------------------------------------------------
TabShop:Section("Fighting Styles")
TabShop:Button({Name = "Buy Black Leg", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBlackLeg") end) end})
TabShop:Button({Name = "Buy Electro", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyElectro") end) end})
TabShop:Button({Name = "Buy Fishman Karate", Callback = function() pcall(function() UnEquipWeapon("Electro"); task.wait(0.1); ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate") end) end})
TabShop:Button({Name = "Buy Superhuman", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySuperhuman") end) end})
TabShop:Button({Name = "Buy Death Step", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyDeathStep") end) end})
TabShop:Button({Name = "Buy Sharkman Karate", Callback = function() pcall(function() topos(CFrame.new(-2604.69, 239.43, -10315.19)); ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate") end) end})
TabShop:Button({Name = "Buy Electric Claw", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") end) end})
TabShop:Button({Name = "Buy Dragon Talon", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon") end) end})
TabShop:Button({Name = "Buy Godhuman", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman", true); ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman") end) end})
TabShop:Button({Name = "Buy Sanguine Art", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySanguineArt", true); ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySanguineArt") end) end})
TabShop:Section("Items")
TabShop:Button({Name = "Buy Dual Katana", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Duel Katana") end) end})
TabShop:Button({Name = "Buy Slingshot", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Slingshot") end) end})

-- ---------------------------------------------------------------------------------
-- TAB 12: DEVIL FRUIT
-- ---------------------------------------------------------------------------------
TabFruit:Section("Sniper")
TabFruit:Dropdown({
    Name = "Select Fruits Sniper",
    Default = "Kitsune-Kitsune",
    Options = {"Kitsune-Kitsune", "Dragon (West)-Dragon (West)", "Dragon (East)-Dragon (East)", "Leopard-Leopard", "Dough-Dough", "T-Rex-T-Rex", "Portal-Portal", "Buddha-Buddha", "Control-Control"},
    Callback = function(v) _G.SelectedFruitSniper = v end
})
TabFruit:Toggle({"Auto Buy Fruit Sniper", false, function(v) _G.AutoBuyFruitSniper = v end})
TabFruit:Section("Others")
TabFruit:Button({Name = "Random Fruit", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy") end) end})
TabFruit:Button({Name = "Open Devil Shop", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits"); LocalPlayer.PlayerGui.Main.FruitShop.Visible = true end) end})
TabFruit:Button({Name = "Open Devil Shop Mirage", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits", true); LocalPlayer.PlayerGui.Main.FruitShop.Visible = true end) end})
TabFruit:Toggle({"Auto Store Fruit", false, function(v) _G.AutoStoreFruit = v end})
TabFruit:Toggle({"Bring to Fruit", false, function(v) _G.BringFruit = v end})
TabFruit:Toggle({"Tween to Fruit", false, function(v) _G.Tweenfruit = v; StopTween(v) end})

-- ---------------------------------------------------------------------------------
-- TAB 13: MISCELLANEOUS
-- ---------------------------------------------------------------------------------
local AllCodes = {
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

TabMisc:Section("Server")
TabMisc:Button({Name = "Rejoin Server", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end})
TabMisc:Button({Name = "Server Hop", Callback = function() Hop(false) end})
TabMisc:Button({Name = "Hop To Lower Player", Callback = function() Hop(true) end})
TabMisc:Button({Name = "Copy Job Id", Callback = function() if setclipboard then setclipboard(tostring(game.JobId)) end end})
TabMisc:TextBox({Name = "Input Job Id", Default = "", PlaceholderText = "Job ID", Callback = function(v) _G.InputJobId = v end})
TabMisc:Button({Name = "Join Sever", Callback = function() if _G.InputJobId and #_G.InputJobId > 4 then TeleportService:TeleportToPlaceInstance(game.PlaceId, _G.InputJobId, LocalPlayer) end end})

TabMisc:Section("Misc")
TabMisc:Button({Name = "Title Name", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("getTitles"); LocalPlayer.PlayerGui.Main.Titles.Visible = true end) end})
TabMisc:Button({Name = "Color Haki", Callback = function() pcall(function() LocalPlayer.PlayerGui.Main.Colors.Visible = true end) end})

TabMisc:Section("Teams")
TabMisc:Button({Name = "Join Pirates Team", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates") end) end})
TabMisc:Button({Name = "Join Marines Team", Callback = function() pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Marines") end) end})

TabMisc:Section("Codes")
TabMisc:Button({
    Name = "Redeem All Codes",
    Callback = function()
        for _, code in ipairs(AllCodes) do
            pcall(function() ReplicatedStorage.Remotes.Redeem:InvokeServer(code) end)
            task.wait(0.08)
        end
    end
})

TabMisc:Section("State")
TabMisc:Dropdown({
    Name = "Select Haki State",
    Default = "State 5",
    Options = {"State 0", "State 1", "State 2", "State 3", "State 4", "State 5"},
    Callback = function(v) _G.SelectStateHaki = v end
})
TabMisc:Button({
    Name = "Change Buso Haki State",
    Callback = function()
        pcall(function()
            local num = tonumber(string.match(_G.SelectStateHaki, "%d+")) or 5
            ReplicatedStorage.Remotes.CommF_:InvokeServer("ChangeBusoStage", num)
        end)
    end
})

-- =================================================================================
-- PHẦN 5: VÒNG LẶP THỰC THI CHỨC NĂNG CHUẨN DATTHG V2
-- =================================================================================
local MobSpawnCFrames = {
    ["Forest Pirate"]       = CFrame.new(-13345.5, 331.3, -7630.8),
    ["Mythological Pirate"] = CFrame.new(-13320.0, 518.8, -6785.0),
    ["Ocean Prophet"]       = CFrame.new(11129.8, -2008.9, 10051.5),
    ["High Disciple"]       = CFrame.new(9778.4, -1994.3, 9877.0),
    ["Grand Devotee"]       = CFrame.new(9620.5, -1994.2, 9871.7),
    ["Jack o' Lantern"]     = CFrame.new(-10979.7, 456.8, -7740.1),
    ["Cookie Crafter"]      = CakeAndBoneTable["Cake"]["Cookie Crafter"],
    ["Cake Guard"]          = CakeAndBoneTable["Cake"]["Cake Guard"],
    ["Baking Staff"]        = CakeAndBoneTable["Cake"]["Baking Staff"],
    ["Head Baker"]          = CakeAndBoneTable["Cake"]["Head Baker"],
    ["Reborn Skeleton"]     = CakeAndBoneTable["Bone"]["Reborn Skeleton"],
    ["Living Zombie"]       = CakeAndBoneTable["Bone"]["Living Zombie"],
    ["Demonic Soul"]        = CakeAndBoneTable["Bone"]["Demonic Soul"],
    ["Posessed Mummy"]      = CakeAndBoneTable["Bone"]["Posessed Mummy"]
}

local BossSpawns = {
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

local LevelQuestTable = {
    {Min = 1,    Max = 1849, Mob = "Forest Pirate",       QName = "DeepForestIsland", QLv = 1, Pos = CFrame.new(-13345.5, 331.3, -7630.8)},
    {Min = 1850, Max = 1999, Mob = "Mythological Pirate", QName = "DeepForestIsland", QLv = 2, Pos = CFrame.new(-13320.0, 518.8, -6785.0)},
    {Min = 2000, Max = 2199, Mob = "Reborn Skeleton",     QName = "HauntedQuest1",    QLv = 1, Pos = CFrame.new(-8769.5, 142.1, 6055.2)},
    {Min = 2200, Max = 2449, Mob = "Cookie Crafter",      QName = "CakeQuest1",       QLv = 1, Pos = CFrame.new(-2333.2, 37.8, -12093.2)},
    {Min = 2450, Max = 2699, Mob = "Ocean Prophet",       QName = "TikiQuest1",       QLv = 1, Pos = CFrame.new(11129.8, -2008.9, 10051.5)},
    {Min = 2700, Max = 2724, Mob = "High Disciple",       QName = "TikiQuest2",       QLv = 1, Pos = CFrame.new(9778.4, -1994.3, 9877.0)},
    {Min = 2725, Max = 9999, Mob = "Grand Devotee",       QName = "TikiQuest2",       QLv = 2, Pos = CFrame.new(9620.5, -1994.2, 9871.7)}
}

-- Vòng lặp Auto Farm & Săn Boss
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local enemies = Workspace:FindFirstChild("Enemies")
            if not enemies then return end

            -- 1. Auto Farm Cake Prince
            if _G.AutoFarmCake then
                local boss = enemies:FindFirstChild("Cake Prince") or enemies:FindFirstChild("Dough King")
                if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                    KillMob(boss)
                    return
                end
                local found = false
                for _, v in ipairs(enemies:GetChildren()) do
                    if CakeAndBoneTable["Cake"][v.Name] and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        KillMob(v)
                        found = true
                        break
                    end
                end
                if not found then
                    topos(CFrame.new(-2021.32, 37.79, -12028.72))
                end
                return
            end

            -- 2. Auto Farm Bone
            if _G.AutoFarmBone then
                local boss = enemies:FindFirstChild("Soul Reaper")
                if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                    KillMob(boss)
                    return
                end
                local found = false
                for _, v in ipairs(enemies:GetChildren()) do
                    if CakeAndBoneTable["Bone"][v.Name] and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        KillMob(v)
                        found = true
                        break
                    end
                end
                if not found then
                    topos(CFrame.new(-9515.0, 142.0, 5535.0))
                end
                return
            end

            -- 3. Auto Farm Level
            if _G.AutoFarmLevel then
                local lv = (LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 2550
                local q = LevelQuestTable[#LevelQuestTable]
                for _, entry in ipairs(LevelQuestTable) do
                    if lv >= entry.Min and lv <= entry.Max then
                        q = entry
                        break
                    end
                end
                if LocalPlayer.PlayerGui.Main.Quest.Visible == false then
                    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", q.QName, q.QLv) end)
                end
                local target = enemies:FindFirstChild(q.Mob)
                if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
                    KillMob(target)
                else
                    topos(q.Pos * PosLv)
                end
                return
            end

            -- 4. Auto Farm Selected Mob
            if _G.AutoFarmMob then
                local m = enemies:FindFirstChild(_G.SelectedMob)
                if m and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                    KillMob(m)
                elseif MobSpawnCFrames[_G.SelectedMob] then
                    topos(MobSpawnCFrames[_G.SelectedMob] * PosLv)
                end
                return
            end

            -- 5. Auto Farm Boss
            if _G.AutoFarmBoss then
                local b = enemies:FindFirstChild(_G.SelectBoss)
                if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then
                    KillMob(b)
                elseif BossSpawns[_G.SelectBoss] then
                    topos(BossSpawns[_G.SelectBoss] * PosLv)
                end
                return
            end

            -- 6. Teleport To Player
            if _G.TeleportPly and _G.SelectPly ~= "" then
                local p = Players:FindFirstChild(_G.SelectPly)
                if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    topos(p.Character.HumanoidRootPart.CFrame)
                end
            end
        end)
    end
end)

-- Vòng lặp Hỗ Trợ, Haki, Trái Ác Quỷ, Sự Kiện & ESP
local ESPFolder = Instance.new("Folder", CoreGui)
ESPFolder.Name = "AnimeBlacker_ESPFolder"

local function DrawTag(adornee, txt, col)
    local bbg = Instance.new("BillboardGui", ESPFolder)
    bbg.Adornee = adornee
    bbg.AlwaysOnTop = true
    bbg.Size = UDim2.new(1, 200, 1, 30)
    bbg.ExtentsOffset = Vector3.new(0, 2, 0)
    local lbl = Instance.new("TextLabel", bbg)
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextStrokeTransparency = 0.4
    lbl.TextColor3 = col
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.Text = txt
end

task.spawn(function()
    while task.wait(0.8) do
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
            end

            if _G.AutoStoreFruit and char and bp then
                for _, cont in ipairs({bp, char}) do
                    for _, it in ipairs(cont:GetChildren()) do
                        if it:IsA("Tool") and (string.find(it.Name, "Fruit") or it:GetAttribute("OriginalName")) then
                            local orig = it:GetAttribute("OriginalName") or it.Name
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", orig, it)
                        end
                    end
                end
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

            if _G.AutoStats then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", _G.SelectedStat, 3)
            end

            -- Cập nhật ESP
            ESPFolder:ClearAllChildren()
            if not root then return end

            if _G.ESPPlayer then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                        local d = round((plr.Character.Head.Position - root.Position).Magnitude / 3)
                        DrawTag(plr.Character.Head, plr.Name .. "\n" .. tostring(d) .. " Distance", Color3.fromRGB(255, 65, 115))
                    end
                end
            end

            if _G.DevilFruitESP then
                for _, item in ipairs(Workspace:GetChildren()) do
                    if item:IsA("Tool") and item:FindFirstChild("Handle") then
                        local d = round((item.Handle.Position - root.Position).Magnitude / 3)
                        DrawTag(item.Handle, item.Name .. "\n" .. tostring(d) .. " Distance", Color3.fromRGB(90, 255, 130))
                    end
                end
            end

            if _G.ESPBerry then
                for _, bush in ipairs(CollectionService:GetTagged("BerryBush")) do
                    local pt = bush:IsA("BasePart") and bush or bush:FindFirstChildWhichIsA("BasePart", true)
                    if pt then
                        local d = round((pt.Position - root.Position).Magnitude / 3)
                        DrawTag(pt, "Berry Bush\n" .. tostring(d) .. " Distance", Color3.fromRGB(255, 120, 255))
                    end
                end
            end
        end)
    end
end)
