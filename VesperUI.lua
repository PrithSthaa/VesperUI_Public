-- ================================================================
-- Vesper UI Library — v3.3  (modified)
-- CHANGES over stock v3.3:
--   • Bubble: circular logo quick-access icon (no pill/buttons).
--     Clicking toggles the main window. Stroke pulses Negative
--     when hidden, returns to Accent when visible.
--     Set DISCORD_LINK below to your server invite.
--   • Header: small Discord icon button added to the left of the
--     mac-style minimize dot. Uses the same link as above.
--   • Sidebar logo text size increased (18 → 22).
--   • Transparent Background (GlassMode) defaults to ON.
-- ================================================================
local LOGO_ASSET_ID    = "rbxassetid://137569557880178"
local LOGO_FILL        = 0.62
local DISCORD_LOGO_ID  = "rbxassetid://76181608348088"   -- actual Discord Clyde logo

-- ▼ Set your Discord invite link here
local DISCORD_LINK  = "https://discord.gg/placeholder"

local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local TextService  = game:GetService("TextService")
local Players      = game:GetService("Players")
local LP           = Players.LocalPlayer

-- ────────────────────────────────────────────────────────────────
-- INTERNAL UTILITIES
-- ────────────────────────────────────────────────────────────────
local function TweenPlay(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props):Play()
end
local function AddCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 6)
    return c
end
local function AddStroke(p, col, thick, trans)
    local s = Instance.new("UIStroke", p)
    s.Color        = col   or Color3.new(1,1,1)
    s.Thickness    = thick or 1
    s.Transparency = trans or 0
    return s
end
local function AddPad(p, top, bot, left, right)
    local u = Instance.new("UIPadding", p)
    u.PaddingTop    = UDim.new(0, top   or 0)
    u.PaddingBottom = UDim.new(0, bot   or 0)
    u.PaddingLeft   = UDim.new(0, left  or 0)
    u.PaddingRight  = UDim.new(0, right or 0)
    return u
end
local function AddList(p, pad, dir)
    local l = Instance.new("UIListLayout", p)
    l.Padding             = UDim.new(0, pad or 0)
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    return l
end
local function MakeDraggable(handle, frame)
    local drag, inp, sp, sm = false, nil, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; sp = frame.Position; sm = i.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then inp = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == inp and drag then
            local d = i.Position - sm
            TweenPlay(frame, {Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y)}, 0.06, Enum.EasingStyle.Linear)
        end
    end)
end
local function Ripple(btn, color)
    local r = Instance.new("Frame", btn)
    r.BackgroundColor3       = color or Color3.fromRGB(139,92,246)
    r.BackgroundTransparency = 0.7
    r.AnchorPoint            = Vector2.new(0.5, 0.5)
    r.ZIndex                 = btn.ZIndex + 2
    AddCorner(r, 100)
    local mp = UIS:GetMouseLocation()
    local ab = btn.AbsolutePosition
    r.Position = UDim2.new(0, mp.X - ab.X, 0, mp.Y - ab.Y)
    r.Size     = UDim2.new(0, 0, 0, 0)
    local sz   = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.5
    TweenPlay(r, {Size = UDim2.new(0,sz,0,sz), BackgroundTransparency = 1}, 0.5, Enum.EasingStyle.Quint)
    task.delay(0.5, function() r:Destroy() end)
end

-- ────────────────────────────────────────────────────────────────
-- LOGO BUILDER (used in sidebar only — bubble no longer uses this)
-- ────────────────────────────────────────────────────────────────
local function MakeLogoClipped(parent, containerPx, position, anchor, zindex)
    local clip = Instance.new("Frame", parent)
    clip.BackgroundTransparency = 1
    clip.Size                   = UDim2.new(0, containerPx, 0, containerPx)
    clip.Position               = position or UDim2.new(0.5, 0, 0.5, 0)
    clip.ClipsDescendants       = true
    if anchor then clip.AnchorPoint = anchor end
    if zindex then clip.ZIndex      = zindex end

    local imgPx    = math.ceil(containerPx / LOGO_FILL)
    local overflow = imgPx - containerPx
    local img = Instance.new("ImageLabel", clip)
    img.BackgroundTransparency = 1
    img.Size                   = UDim2.new(0, imgPx, 0, imgPx)
    img.Position               = UDim2.new(0, -overflow / 2, 0, -overflow / 2)
    img.Image                  = LOGO_ASSET_ID
    img.ScaleType              = Enum.ScaleType.Fit
    img.ZIndex                 = (zindex or 1) + 1
    return clip
end

-- ────────────────────────────────────────────────────────────────
-- ICONS
-- ────────────────────────────────────────────────────────────────
local Icons = {}
pcall(function()
    Icons = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/src/Icons.lua"))().assets
end)
if not Icons or not next(Icons) then
    Icons = setmetatable({}, {__index = function() return "rbxassetid://0" end})
end
local function Icon(name) return Icons[name] or Icons["lucide-box"] or "" end

-- ────────────────────────────────────────────────────────────────
-- THEMES
-- ────────────────────────────────────────────────────────────────
local Themes = {
    Dark = {
        Background  = Color3.fromRGB(13,13,17),    Surface     = Color3.fromRGB(20,20,26),
        SurfaceHigh = Color3.fromRGB(28,28,36),    Sidebar     = Color3.fromRGB(10,10,14),
        SidebarHover= Color3.fromRGB(30,30,38),    Border      = Color3.fromRGB(38,38,50),
        BorderHigh  = Color3.fromRGB(55,55,70),    Text        = Color3.fromRGB(240,240,248),
        SubText     = Color3.fromRGB(130,130,155), Muted       = Color3.fromRGB(70,70,90),
        Accent      = Color3.fromRGB(139,92,246),  AccentDim   = Color3.fromRGB(100,65,190),
        Positive    = Color3.fromRGB(52,211,153),  Negative    = Color3.fromRGB(248,113,113),
        Warning     = Color3.fromRGB(251,191,36),  Track       = Color3.fromRGB(35,35,45),
        InputBg     = Color3.fromRGB(16,16,22),
    },
    Midnight = {
        Background  = Color3.fromRGB(7,7,18),      Surface     = Color3.fromRGB(12,12,28),
        SurfaceHigh = Color3.fromRGB(19,18,42),    Sidebar     = Color3.fromRGB(5,5,14),
        SidebarHover= Color3.fromRGB(22,20,50),    Border      = Color3.fromRGB(32,28,72),
        BorderHigh  = Color3.fromRGB(56,48,120),   Text        = Color3.fromRGB(232,228,255),
        SubText     = Color3.fromRGB(118,112,182), Muted       = Color3.fromRGB(60,56,104),
        Accent      = Color3.fromRGB(132,98,255),  AccentDim   = Color3.fromRGB(92,64,195),
        Positive    = Color3.fromRGB(52,211,153),  Negative    = Color3.fromRGB(248,113,113),
        Warning     = Color3.fromRGB(251,191,36),  Track       = Color3.fromRGB(18,16,46),
        InputBg     = Color3.fromRGB(9,8,22),
    },
    Ember = {
        Background  = Color3.fromRGB(15,10,10),    Surface     = Color3.fromRGB(24,16,15),
        SurfaceHigh = Color3.fromRGB(33,22,20),    Sidebar     = Color3.fromRGB(11,7,7),
        SidebarHover= Color3.fromRGB(38,26,24),    Border      = Color3.fromRGB(55,32,30),
        BorderHigh  = Color3.fromRGB(80,48,44),    Text        = Color3.fromRGB(248,240,235),
        SubText     = Color3.fromRGB(160,120,112), Muted       = Color3.fromRGB(90,60,55),
        Accent      = Color3.fromRGB(251,146,60),  AccentDim   = Color3.fromRGB(194,100,35),
        Positive    = Color3.fromRGB(52,211,153),  Negative    = Color3.fromRGB(248,113,113),
        Warning     = Color3.fromRGB(251,191,36),  Track       = Color3.fromRGB(38,22,20),
        InputBg     = Color3.fromRGB(14,9,8),
    },
}

-- ────────────────────────────────────────────────────────────────
-- LIBRARY
-- ────────────────────────────────────────────────────────────────
local Vesper = {
    Version = "3.3",
    Themes  = Themes,
    Theme   = Themes.Midnight,
    Options = {},
    _window = nil,
}

function Vesper:SetTheme(name)
    self.Theme = Themes[name] or Themes.Midnight
    if self._window and self._window.RefreshTheme then
        self._window:RefreshTheme()
    end
end

-- ════════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ════════════════════════════════════════════════════════════════
function Vesper:CreateWindow(cfg)
    local T = setmetatable({}, {
        __index    = function(_, k) return Vesper.Theme[k] end,
        __newindex = function() end,
    })

    cfg = cfg or {}
    local titleText    = cfg.Title       or "Vesper"
    local subtitleText = cfg.Subtitle    or nil
    local hotkey       = cfg.MinimizeKey or Enum.KeyCode.RightControl
    local tag          = cfg.Tag         or "v" .. self.Version

    local gui_parent = (pcall(function() return gethui() end) and gethui()) or CoreGui
    if not gui_parent then gui_parent = LP:WaitForChild("PlayerGui") end
    for _, v in pairs(gui_parent:GetChildren()) do
        if v.Name == "VesperUI" then v:Destroy() end
    end

    local Screen = Instance.new("ScreenGui")
    Screen.Name           = "VesperUI"
    Screen.Parent         = gui_parent
    Screen.ResetOnSpawn   = false
    Screen.DisplayOrder   = 999
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local NotifHolder = Instance.new("Frame", Screen)
    NotifHolder.BackgroundTransparency = 1
    NotifHolder.AnchorPoint = Vector2.new(1, 1)
    NotifHolder.Position    = UDim2.new(1, -16, 1, -16)
    NotifHolder.Size        = UDim2.new(0, 290, 1, -32)
    local NLayout = AddList(NotifHolder, 8)
    NLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    local Main = Instance.new("Frame", Screen)
    Main.Name             = "Main"
    Main.BackgroundColor3 = T.Background
    Main.AnchorPoint      = Vector2.new(0.5, 0.5)
    Main.Position         = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size             = UDim2.new(0, 730, 0, 520)
    Main.ClipsDescendants = false
    Main.Visible          = false
    local MainCorner = AddCorner(Main, 10)
    local MainStroke = AddStroke(Main, T.Border, 1.5)

    local WinGlow = Instance.new("ImageLabel", Main)
    WinGlow.BackgroundTransparency = 1
    WinGlow.Position          = UDim2.new(0, -40, 0, -40)
    WinGlow.Size              = UDim2.new(1, 80, 1, 80)
    WinGlow.Image             = "rbxassetid://4996891970"
    WinGlow.ImageColor3       = T.Accent
    WinGlow.ImageTransparency = 0.82
    WinGlow.ZIndex            = 0

    local WinScale = Instance.new("UIScale", Main); WinScale.Scale = 0

    local Sidebar = Instance.new("Frame", Main)
    Sidebar.BackgroundColor3 = T.Sidebar
    Sidebar.Size             = UDim2.new(0, 190, 1, 0)
    Sidebar.BorderSizePixel  = 0
    AddCorner(Sidebar, 10)

    local SideFlat = Instance.new("Frame", Sidebar)
    SideFlat.BackgroundColor3 = T.Sidebar
    SideFlat.Position         = UDim2.new(1, -10, 0, 0)
    SideFlat.Size             = UDim2.new(0, 10, 1, 0)
    SideFlat.BorderSizePixel  = 0
    SideFlat.ZIndex           = 0

    local SideLine = Instance.new("Frame", Sidebar)
    SideLine.BackgroundColor3 = T.Border
    SideLine.Position         = UDim2.new(1, -1, 0, 0)
    SideLine.Size             = UDim2.new(0, 1, 1, 0)
    SideLine.BorderSizePixel  = 0

    local Window       = {}
    Window._active     = nil
    Window._tabs       = {}
    Window._dropdownClosers = {}   -- tracks all dropdown ClosePanel functions
    Window.Main        = Main
    Window.Sidebar     = Sidebar
    Vesper._window     = Window

    -- Helper: close every open dropdown panel (called on minimize / close)
    local function CloseAllDropdowns()
        for _, closeFn in ipairs(Window._dropdownClosers) do
            pcall(closeFn)
        end
    end

    local _tracked = {}
    local function TC(obj, prop, themeKey)
        obj[prop] = Vesper.Theme[themeKey]
        table.insert(_tracked, { obj = obj, prop = prop, key = themeKey })
    end
    local function TCS(stroke, themeKey)
        stroke.Color = Vesper.Theme[themeKey]
        table.insert(_tracked, { obj = stroke, prop = "Color", key = themeKey })
    end

    function Window:RefreshTheme()
        for _, item in ipairs(_tracked) do
            if item.obj and item.obj.Parent then
                item.obj[item.prop] = Vesper.Theme[item.key]
            end
        end
        MainStroke.Color = Vesper.Theme.Border
        if WinGlow then WinGlow.ImageColor3 = Vesper.Theme.Accent end
        for _, tab in ipairs(Window._tabs) do
            if tab._btn and tab._btn.Parent then
                local isActive = (Window._active == tab)
                tab._btn.BackgroundColor3 = isActive and Vesper.Theme.SidebarHover or Vesper.Theme.Sidebar
                tab._bar.BackgroundColor3 = Vesper.Theme.Accent
                tab._lbl.TextColor3       = isActive and Vesper.Theme.Text    or Vesper.Theme.SubText
                tab._sub.TextColor3       = isActive and Vesper.Theme.SubText or Vesper.Theme.Muted
            end
            if tab._ico and tab._ico.Parent then
                local isActive = (Window._active == tab)
                tab._ico.ImageColor3 = isActive and Vesper.Theme.Accent or Vesper.Theme.Muted
            end
        end
    end

    TC(Main,     "BackgroundColor3", "Background")
    TC(Sidebar,  "BackgroundColor3", "Sidebar")
    TC(SideFlat, "BackgroundColor3", "Sidebar")
    TC(SideLine, "BackgroundColor3", "Border")

    -- ── Sidebar logo ──────────────────────────────────────────────
    local LogoFrame = Instance.new("Frame", Sidebar)
    LogoFrame.BackgroundTransparency = 1
    LogoFrame.Size                   = UDim2.new(1, 0, 0, 130)

    local LogoCell = Instance.new("Frame", LogoFrame)
    LogoCell.BackgroundTransparency = 1
    LogoCell.Position               = UDim2.new(0, 0, 0, 0)
    LogoCell.Size                   = UDim2.new(0, 100, 1, 0)
    LogoCell.ClipsDescendants       = true

    do
        local cellPx   = 100
        local imgPx    = math.ceil(cellPx / LOGO_FILL)
        local overflow = imgPx - cellPx
        local img = Instance.new("ImageLabel", LogoCell)
        img.BackgroundTransparency = 1
        img.Size                   = UDim2.new(0, imgPx, 0, imgPx)
        img.Position               = UDim2.new(0, -overflow / 2, 0.5, -imgPx / 2)
        img.Image                  = LOGO_ASSET_ID
        img.ScaleType              = Enum.ScaleType.Fit
        img.ZIndex                 = 2
    end

    local TextCell = Instance.new("Frame", LogoFrame)
    TextCell.BackgroundTransparency = 1
    TextCell.Position               = UDim2.new(0, 104, 0, 0)
    TextCell.Size                   = UDim2.new(1, -108, 1, 0)

    local LogoName = Instance.new("TextLabel", TextCell)
    LogoName.BackgroundTransparency = 1
    LogoName.AnchorPoint    = Vector2.new(0, 0.5)
    LogoName.Position       = UDim2.new(0, 0, 0.5, -12)
    LogoName.Size           = UDim2.new(1, 0, 0, 26)
    LogoName.Font           = Enum.Font.GothamBold
    LogoName.Text           = "Vesper"
    LogoName.TextColor3     = T.Text
    LogoName.TextSize       = 22  -- ▲ increased from 18
    LogoName.TextXAlignment = Enum.TextXAlignment.Left
    TC(LogoName, "TextColor3", "Text")

    local LogoTag = Instance.new("TextLabel", TextCell)
    LogoTag.BackgroundTransparency = 1
    LogoTag.AnchorPoint     = Vector2.new(0, 0.5)
    LogoTag.Position        = UDim2.new(0, 0, 0.5, 14)
    LogoTag.Size            = UDim2.new(1, 0, 0, 14)
    LogoTag.Font            = Enum.Font.Gotham
    LogoTag.Text            = tag
    LogoTag.TextColor3      = T.Accent
    LogoTag.TextSize        = 10
    LogoTag.TextXAlignment  = Enum.TextXAlignment.Left
    TC(LogoTag, "TextColor3", "Accent")

    local LogoDiv = Instance.new("Frame", Sidebar)
    LogoDiv.BackgroundColor3 = T.Border
    LogoDiv.Position         = UDim2.new(0, 12, 0, 130)
    LogoDiv.Size             = UDim2.new(1, -24, 0, 1)
    LogoDiv.BorderSizePixel  = 0
    TC(LogoDiv, "BackgroundColor3", "Border")

    local TabList = Instance.new("ScrollingFrame", Sidebar)
    TabList.BackgroundTransparency = 1
    TabList.Position               = UDim2.new(0, 0, 0, 138)
    TabList.Size                   = UDim2.new(1, 0, 1, -138)
    TabList.ScrollBarThickness     = 0
    TabList.CanvasSize             = UDim2.new(0, 0, 0, 0)
    AddPad(TabList, 6, 6, 8, 8)
    local TabListLayout = AddList(TabList, 2)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- ── Header ────────────────────────────────────────────────────
    local Header = Instance.new("Frame", Main)
    Header.BackgroundTransparency = 1
    Header.Position               = UDim2.new(0, 190, 0, 0)
    Header.Size                   = UDim2.new(1, -190, 0, 52)
    MakeDraggable(Header, Main)

    local TitleLabel = Instance.new("TextLabel", Header)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position       = UDim2.new(0, 16, 0, 10)
    TitleLabel.Size           = UDim2.new(0.65, 0, 0, 18)
    TitleLabel.Font           = Enum.Font.GothamBold
    TitleLabel.Text           = titleText
    TitleLabel.RichText       = true
    TitleLabel.TextColor3     = T.Text
    TitleLabel.TextSize       = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TC(TitleLabel, "TextColor3", "Text")

    local SubLabel = Instance.new("TextLabel", Header)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Position       = UDim2.new(0, 16, 0, 30)
    SubLabel.Size           = UDim2.new(0.7, 0, 0, 14)
    SubLabel.Font           = Enum.Font.Gotham
    SubLabel.Text           = subtitleText or "Loading..."
    SubLabel.TextColor3     = T.SubText
    SubLabel.TextSize       = 11
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    TC(SubLabel, "TextColor3", "SubText")

    if not subtitleText then
        task.spawn(function()
            pcall(function()
                local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
                SubLabel.Text = info.Name .. "  ·  " .. os.date("%A, %B %d")
            end)
        end)
    end

    local function MakeDot(color, xOff)
        local dot = Instance.new("TextButton", Header)
        dot.BackgroundColor3 = color
        dot.AnchorPoint      = Vector2.new(1, 0.5)
        dot.Position         = UDim2.new(1, -xOff, 0.5, 0)
        dot.Size             = UDim2.new(0, 12, 0, 12)
        dot.Text             = ""; dot.AutoButtonColor = false
        AddCorner(dot, 100)
        local dim = Color3.new(color.R * .6, color.G * .6, color.B * .6)
        dot.MouseEnter:Connect(function() TweenPlay(dot, {BackgroundColor3 = color},  0.1)  end)
        dot.MouseLeave:Connect(function() TweenPlay(dot, {BackgroundColor3 = dim},   0.12) end)
        TweenPlay(dot, {BackgroundColor3 = dim}, 0)
        return dot
    end

    -- Dots: Close at xOff 14, Minimize at xOff 32 (unchanged)
    local CloseBtn    = MakeDot(T.Negative, 14)
    local MinimizeBtn = MakeDot(T.Warning,  32)
    table.insert(_tracked, { obj = CloseBtn,    prop = "BackgroundColor3", key = "Negative" })
    table.insert(_tracked, { obj = MinimizeBtn, prop = "BackgroundColor3", key = "Warning"  })

    -- ── Discord header button (left of minimize dot) ──────────────
    -- Sits at xOff 52 — just to the left of the yellow dot.
    local DiscordColor = Color3.fromRGB(88, 101, 242)   -- official Discord Blurple

    local HeaderDiscord = Instance.new("TextButton", Header)
    HeaderDiscord.BackgroundColor3       = DiscordColor
    HeaderDiscord.BackgroundTransparency = 1           -- transparent bg, logo only
    HeaderDiscord.AnchorPoint            = Vector2.new(1, 0.5)
    HeaderDiscord.Position               = UDim2.new(1, -50, 0.5, 0)
    HeaderDiscord.Size                   = UDim2.new(0, 18, 0, 18)
    HeaderDiscord.Text                   = ""
    HeaderDiscord.AutoButtonColor        = false

    -- Actual Discord logo
    local HDIco = Instance.new("ImageLabel", HeaderDiscord)
    HDIco.BackgroundTransparency = 1
    HDIco.AnchorPoint            = Vector2.new(0.5, 0.5)
    HDIco.Position               = UDim2.new(0.5, 0, 0.5, 0)
    HDIco.Size                   = UDim2.new(1, 0, 1, 0)
    HDIco.Image                  = DISCORD_LOGO_ID
    HDIco.ImageColor3            = DiscordColor
    HDIco.ScaleType              = Enum.ScaleType.Fit

    -- Hover / click feedback
    HeaderDiscord.MouseEnter:Connect(function()
        TweenPlay(HDIco, {ImageColor3 = Color3.fromRGB(130, 142, 255)}, 0.1)
    end)
    HeaderDiscord.MouseLeave:Connect(function()
        TweenPlay(HDIco, {ImageColor3 = DiscordColor}, 0.12)
    end)
    HeaderDiscord.MouseButton1Click:Connect(function()
        TweenPlay(HDIco, {ImageColor3 = Color3.fromRGB(68, 80, 200)}, 0.08)
        task.delay(0.12, function()
            TweenPlay(HDIco, {ImageColor3 = DiscordColor}, 0.15)
        end)
        -- Open in browser (executor context)
        pcall(function()
            game:GetService("GuiService"):OpenBrowserWindow(DISCORD_LINK)
        end)
        -- Fallback: copy to clipboard
        pcall(function() setclipboard(DISCORD_LINK) end)
    end)

    local HDivider = Instance.new("Frame", Header)
    HDivider.BackgroundColor3 = T.Border
    HDivider.Position         = UDim2.new(0, 0, 1, -1)
    HDivider.Size             = UDim2.new(1, 0, 0, 1)
    HDivider.BorderSizePixel  = 0
    TC(HDivider, "BackgroundColor3", "Border")

    local ContentArea = Instance.new("Frame", Main)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Position              = UDim2.new(0, 190, 0, 52)
    ContentArea.Size                  = UDim2.new(1, -190, 1, -52)
    ContentArea.ClipsDescendants      = true

    -- ════════════════════════════════════════════════════════════
    --  TAB SWITCHING
    -- ════════════════════════════════════════════════════════════
    local function SwitchTab(tab)
        if Window._active == tab then return end
        if Window._active then
            local old = Window._active
            TweenPlay(old._btn, {BackgroundColor3 = T.Sidebar}, 0.18)
            TweenPlay(old._bar, {BackgroundTransparency = 1,
                Size = UDim2.new(0, 2, 0.5, 0)}, 0.18)
            old._lbl.TextColor3 = T.SubText
            old._sub.TextColor3 = T.Muted
            if old._ico then old._ico.ImageColor3 = T.Muted end
            old._page.Visible = false
        end
        Window._active = tab
        TweenPlay(tab._btn, {BackgroundColor3 = T.SidebarHover}, 0.18)
        TweenPlay(tab._bar, {BackgroundTransparency = 0,
            Size = UDim2.new(0, 3, 0.65, 0)}, 0.22, Enum.EasingStyle.Back)
        tab._lbl.TextColor3 = T.Text
        tab._sub.TextColor3 = T.SubText
        if tab._ico then tab._ico.ImageColor3 = T.Accent end
        tab._page.Visible = true
    end

    -- ════════════════════════════════════════════════════════════
    --  WINDOW:ADDTAB
    -- ════════════════════════════════════════════════════════════
    local function AddTab(tabCfg)
        local tabName = tabCfg.Title    or tabCfg[1] or "Tab"
        local tabSub  = tabCfg.Subtitle or tabCfg[2] or ""
        local tabIcon = tabCfg.Icon     or tabCfg[3]

        local Btn = Instance.new("TextButton", TabList)
        Btn.BackgroundColor3 = T.Sidebar
        Btn.BorderSizePixel  = 0
        Btn.Size             = UDim2.new(1, 0, 0, 48)
        Btn.Text             = ""; Btn.AutoButtonColor = false
        Btn.ClipsDescendants = false
        AddCorner(Btn, 7)

        Btn.MouseEnter:Connect(function()
            if Window._active and Window._active._btn == Btn then return end
            TweenPlay(Btn, {BackgroundColor3 = T.SidebarHover}, 0.12)
        end)
        Btn.MouseLeave:Connect(function()
            if Window._active and Window._active._btn == Btn then return end
            TweenPlay(Btn, {BackgroundColor3 = T.Sidebar}, 0.12)
        end)

        local Bar = Instance.new("Frame", Btn)
        Bar.BackgroundColor3      = T.Accent
        Bar.BackgroundTransparency= 1
        Bar.AnchorPoint           = Vector2.new(0, 0.5)
        Bar.Position              = UDim2.new(0, -2, 0.5, 0)
        Bar.Size                  = UDim2.new(0, 2, 0.5, 0)
        AddCorner(Bar, 4)

        local xOff   = tabIcon and 34 or 10
        local IcoRef = nil
        if tabIcon then
            local Ico = Instance.new("ImageLabel", Btn)
            Ico.BackgroundTransparency = 1
            Ico.Position    = UDim2.new(0, 10, 0.5, -10)
            Ico.Size        = UDim2.new(0, 20, 0, 20)
            Ico.Image       = Icon(tabIcon)
            Ico.ImageColor3 = T.Muted
            Ico.ZIndex      = Btn.ZIndex + 1
            IcoRef = Ico
        end

        local Lbl = Instance.new("TextLabel", Btn)
        Lbl.BackgroundTransparency = 1
        Lbl.Position       = UDim2.new(0, xOff, 0, (tabSub ~= "") and 8 or 15)
        Lbl.Size           = UDim2.new(1, -xOff - 4, 0, 18)
        Lbl.Font           = Enum.Font.GothamBold
        Lbl.Text           = tabName
        Lbl.TextColor3     = T.SubText
        Lbl.TextSize       = 13
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.TextTruncate   = Enum.TextTruncate.AtEnd
        Lbl.ZIndex         = Btn.ZIndex + 1

        local Sub = Instance.new("TextLabel", Btn)
        Sub.BackgroundTransparency = 1
        Sub.Position       = UDim2.new(0, xOff, 0, 27)
        Sub.Size           = UDim2.new(1, -xOff - 4, 0, 13)
        Sub.Font           = Enum.Font.Gotham
        Sub.Text           = tabSub
        Sub.TextColor3     = T.Muted
        Sub.TextSize       = 10
        Sub.TextXAlignment = Enum.TextXAlignment.Left
        Sub.TextTruncate   = Enum.TextTruncate.AtEnd
        Sub.ZIndex         = Btn.ZIndex + 1
        Sub.Visible        = (tabSub ~= "")

        TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabList.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 12)
        end)

        local Page = Instance.new("ScrollingFrame", ContentArea)
        Page.BackgroundTransparency = 1
        Page.Size                   = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness     = 3
        Page.ScrollBarImageColor3   = T.Accent
        Page.CanvasSize             = UDim2.new(0, 0, 0, 0)
        Page.Visible                = false
        AddPad(Page, 12, 12, 12, 12)
        TC(Page, "ScrollBarImageColor3", "Accent")

        local ColHolder = Instance.new("Frame", Page)
        ColHolder.BackgroundTransparency = 1
        ColHolder.Size          = UDim2.new(1, 0, 0, 0)
        ColHolder.AutomaticSize = Enum.AutomaticSize.Y
        local ColList = Instance.new("UIListLayout", ColHolder)
        ColList.FillDirection     = Enum.FillDirection.Horizontal
        ColList.Padding           = UDim.new(0, 8)
        ColList.VerticalAlignment = Enum.VerticalAlignment.Top
        ColList.SortOrder         = Enum.SortOrder.LayoutOrder

        local LeftCol = Instance.new("Frame", ColHolder)
        LeftCol.BackgroundTransparency = 1
        LeftCol.Size          = UDim2.new(0.5, -4, 0, 0)
        LeftCol.AutomaticSize = Enum.AutomaticSize.Y
        AddList(LeftCol, 8)

        local RightCol = Instance.new("Frame", ColHolder)
        RightCol.BackgroundTransparency = 1
        RightCol.Size          = UDim2.new(0.5, -4, 0, 0)
        RightCol.AutomaticSize = Enum.AutomaticSize.Y
        AddList(RightCol, 8)

        ColHolder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, ColHolder.AbsoluteSize.Y + 24)
        end)

        local tabObj = {
            _btn   = Btn,   _bar   = Bar,
            _lbl   = Lbl,   _sub   = Sub,
            _ico   = IcoRef,
            _page  = Page,  _left  = LeftCol,
            _right = RightCol, _col = true,
        }
        Btn.MouseButton1Click:Connect(function() SwitchTab(tabObj) end)
        if not Window._active then SwitchTab(tabObj) end
        table.insert(Window._tabs, tabObj)

        local TabAPI = {}

        function TabAPI:CreateSection(cfg2)
            local secName = type(cfg2) == "string" and cfg2 or (cfg2.Title or cfg2[1] or "Section")
            local secIcon = type(cfg2) == "table"  and cfg2.Icon or nil

            local col    = tabObj._col and tabObj._left or tabObj._right
            tabObj._col  = not tabObj._col

            local SBase = Instance.new("Frame", col)
            SBase.BackgroundColor3 = T.Surface
            SBase.BorderSizePixel  = 0
            SBase.Size             = UDim2.new(1, 0, 0, 42)
            SBase.AutomaticSize    = Enum.AutomaticSize.Y
            AddCorner(SBase, 8)
            TCS(AddStroke(SBase, T.Border, 1), "Border")
            TC(SBase, "BackgroundColor3", "Surface")

            local TopLine = Instance.new("Frame", SBase)
            TopLine.BackgroundColor3 = T.Accent
            TopLine.Size             = UDim2.new(1, 0, 0, 2)
            TopLine.BorderSizePixel  = 0
            AddCorner(TopLine, 8)
            TC(TopLine, "BackgroundColor3", "Accent")

            local SHeader = Instance.new("Frame", SBase)
            SHeader.BackgroundTransparency = 1
            SHeader.Size = UDim2.new(1, 0, 0, 38)

            local xOff3 = 12
            if secIcon then
                local SI = Instance.new("ImageLabel", SHeader)
                SI.BackgroundTransparency = 1
                SI.Position    = UDim2.new(0, 10, 0.5, -8)
                SI.Size        = UDim2.new(0, 16, 0, 16)
                SI.Image       = Icon(secIcon)
                SI.ImageColor3 = T.Accent
                xOff3 = 32
                TC(SI, "ImageColor3", "Accent")
            end

            local STitle = Instance.new("TextLabel", SHeader)
            STitle.BackgroundTransparency = 1
            STitle.Position       = UDim2.new(0, xOff3, 0, 0)
            STitle.Size           = UDim2.new(1, -xOff3 - 12, 1, 0)
            STitle.Font           = Enum.Font.GothamBold
            STitle.Text           = secName
            STitle.TextColor3     = T.Text
            STitle.TextSize       = 12
            STitle.TextXAlignment = Enum.TextXAlignment.Left
            TC(STitle, "TextColor3", "Text")

            local SDiv = Instance.new("Frame", SBase)
            SDiv.BackgroundColor3 = T.Border
            SDiv.Position         = UDim2.new(0, 8, 0, 38)
            SDiv.Size             = UDim2.new(1, -16, 0, 1)
            SDiv.BorderSizePixel  = 0
            TC(SDiv, "BackgroundColor3", "Border")

            local EBox = Instance.new("Frame", SBase)
            EBox.BackgroundTransparency = 1
            EBox.Position        = UDim2.new(0, 0, 0, 42)
            EBox.Size            = UDim2.new(1, 0, 0, 0)
            EBox.AutomaticSize   = Enum.AutomaticSize.Y
            AddPad(EBox, 8, 10, 10, 10)
            AddList(EBox, 6)

            local SecAPI = {}

            local function MakeRow(height)
                local row = Instance.new("Frame", EBox)
                row.BackgroundColor3 = T.SurfaceHigh
                row.BorderSizePixel  = 0
                row.Size             = UDim2.new(1, 0, 0, height or 32)
                AddCorner(row, 6)
                TCS(AddStroke(row, T.Border, 1), "Border")
                TC(row, "BackgroundColor3", "SurfaceHigh")
                return row
            end

            local function MakeTitle(parent, title, desc, xOff4)
                xOff4 = xOff4 or 10
                local tl = Instance.new("TextLabel", parent)
                tl.BackgroundTransparency = 1
                tl.Position       = UDim2.new(0, xOff4, 0, 7)
                tl.Size           = UDim2.new(1, -80, 0, 18)
                tl.Font           = Enum.Font.GothamBold
                tl.Text           = title
                tl.TextColor3     = T.Text
                tl.TextSize       = 12
                tl.TextXAlignment = Enum.TextXAlignment.Left
                tl.TextTruncate   = Enum.TextTruncate.AtEnd
                TC(tl, "TextColor3", "Text")
                if desc then
                    local dl = Instance.new("TextLabel", parent)
                    dl.BackgroundTransparency = 1
                    dl.Position       = UDim2.new(0, xOff4, 0, 25)
                    dl.Size           = UDim2.new(1, -80, 0, 12)
                    dl.Font           = Enum.Font.Gotham
                    dl.Text           = desc
                    dl.TextColor3     = T.SubText
                    dl.TextSize       = 10
                    dl.TextXAlignment = Enum.TextXAlignment.Left
                    dl.TextTruncate   = Enum.TextTruncate.AtEnd
                    TC(dl, "TextColor3", "SubText")
                end
                return tl
            end

            function SecAPI:CreateLabel(cfg3)
                local text = type(cfg3) == "string" and cfg3 or (cfg3.Title or cfg3[1] or "")
                local body = type(cfg3) == "table"  and cfg3.Content or nil
                local F = Instance.new("Frame", EBox)
                F.BackgroundTransparency = 1
                F.Size = UDim2.new(1, 0, 0, 0); F.AutomaticSize = Enum.AutomaticSize.Y
                local L = Instance.new("TextLabel", F)
                L.BackgroundTransparency = 1
                L.Size = UDim2.new(1, 0, 0, 0); L.AutomaticSize = Enum.AutomaticSize.Y
                L.Font = Enum.Font.Gotham
                L.Text = body and ("<b>" .. text .. "</b>\n" .. body) or text
                L.RichText = true; L.TextColor3 = T.SubText; L.TextSize = 12
                L.TextXAlignment = Enum.TextXAlignment.Left; L.TextWrapped = true
                TC(L, "TextColor3", "SubText")
                local api = {}
                function api:SetValue(t) L.Text = t end
                return api
            end

            function SecAPI:CreateParagraph(cfg3)
                local title = type(cfg3) == "string" and cfg3 or (cfg3.Title or cfg3[1] or "")
                local body  = type(cfg3) == "table"  and (cfg3.Content or cfg3[2] or "") or ""
                local F = Instance.new("Frame", EBox)
                F.BackgroundColor3 = T.SurfaceHigh; F.BorderSizePixel = 0
                F.Size = UDim2.new(1, 0, 0, 0); F.AutomaticSize = Enum.AutomaticSize.Y
                AddCorner(F, 5); AddPad(F, 8, 8, 10, 10); AddList(F, 4)
                TC(F, "BackgroundColor3", "SurfaceHigh")
                local TL = Instance.new("TextLabel", F)
                TL.BackgroundTransparency = 1; TL.Size = UDim2.new(1, 0, 0, 16)
                TL.Font = Enum.Font.GothamBold; TL.Text = title
                TL.TextColor3 = T.Text; TL.TextSize = 12
                TL.TextXAlignment = Enum.TextXAlignment.Left
                TC(TL, "TextColor3", "Text")
                local BL = Instance.new("TextLabel", F)
                BL.BackgroundTransparency = 1
                BL.Size = UDim2.new(1, 0, 0, 0); BL.AutomaticSize = Enum.AutomaticSize.Y
                BL.Font = Enum.Font.Gotham; BL.Text = body
                BL.TextColor3 = T.SubText; BL.TextSize = 11
                BL.TextXAlignment = Enum.TextXAlignment.Left; BL.TextWrapped = true
                TC(BL, "TextColor3", "SubText")
                local api = {}
                function api:SetValue(t, b) TL.Text = t or TL.Text; BL.Text = b or BL.Text end
                return api
            end

            function SecAPI:CreateSeparator(cfg3)
                local label = type(cfg3) == "string" and cfg3
                    or (type(cfg3) == "table" and cfg3.Title) or nil
                local F = Instance.new("Frame", EBox)
                F.BackgroundTransparency = 1
                F.Size = UDim2.new(1, 0, 0, label and 18 or 6)
                if label then
                    local L = Instance.new("TextLabel", F)
                    L.BackgroundTransparency = 1; L.Size = UDim2.new(1, 0, 0, 12)
                    L.Font = Enum.Font.GothamBold; L.Text = label:upper()
                    L.TextColor3 = T.Muted; L.TextSize = 9
                    L.TextXAlignment = Enum.TextXAlignment.Left; L.TextTransparency = 0.3
                    TC(L, "TextColor3", "Muted")
                end
                local Line = Instance.new("Frame", F)
                Line.BackgroundColor3 = T.Border; Line.AnchorPoint = Vector2.new(0, 1)
                Line.Position = UDim2.new(0, 0, 1, 0); Line.Size = UDim2.new(1, 0, 0, 1)
                Line.BorderSizePixel = 0
                TC(Line, "BackgroundColor3", "Border")
            end

            function SecAPI:CreateDynamicLabel(cfg3)
                local name  = type(cfg3) == "string" and cfg3 or (cfg3.Title or cfg3[1] or "Label")
                local value = type(cfg3) == "table"  and (cfg3.Value or cfg3[2] or "—") or "—"
                local color = type(cfg3) == "table"  and cfg3.Color or nil
                local F = Instance.new("Frame", EBox)
                F.BackgroundTransparency = 1; F.Size = UDim2.new(1, 0, 0, 18)
                local NL = Instance.new("TextLabel", F)
                NL.BackgroundTransparency = 1; NL.Size = UDim2.new(0.55, 0, 1, 0)
                NL.Font = Enum.Font.Gotham; NL.Text = name
                NL.TextColor3 = T.SubText; NL.TextSize = 12
                NL.TextXAlignment = Enum.TextXAlignment.Left
                TC(NL, "TextColor3", "SubText")
                local VL = Instance.new("TextLabel", F)
                VL.BackgroundTransparency = 1; VL.Position = UDim2.new(0.55, 0, 0, 0)
                VL.Size = UDim2.new(0.45, 0, 1, 0); VL.Font = Enum.Font.GothamBold
                VL.Text = tostring(value); VL.TextColor3 = color or T.Accent; VL.TextSize = 12
                VL.TextXAlignment = Enum.TextXAlignment.Right
                if not color then TC(VL, "TextColor3", "Accent") end
                local api = {}
                function api:SetValue(v, c)
                    VL.Text = tostring(v)
                    if c then TweenPlay(VL, {TextColor3 = c}, 0.2) end
                end
                function api:OnChanged(fn) api._cb = fn end
                return api
            end

            function SecAPI:CreateButton(cfg3)
                local title  = cfg3.Title or cfg3[1] or "Button"
                local desc   = cfg3.Description or cfg3.Desc or cfg3[2] or nil
                local cb     = cfg3.Callback or function() end
                local height = desc and 44 or 32
                local row    = MakeRow(height); row.ClipsDescendants = true
                MakeTitle(row, title, desc)
                local Arrow = Instance.new("ImageLabel", row)
                Arrow.BackgroundTransparency = 1; Arrow.AnchorPoint = Vector2.new(1, 0.5)
                Arrow.Position = UDim2.new(1, -10, 0.5, 0); Arrow.Size = UDim2.new(0, 14, 0, 14)
                Arrow.Image = Icon("lucide-chevron-right"); Arrow.ImageColor3 = T.Muted
                TC(Arrow, "ImageColor3", "Muted")
                local clickable = Instance.new("TextButton", row)
                clickable.BackgroundTransparency = 1; clickable.Size = UDim2.new(1, 0, 1, 0)
                clickable.Text = ""; clickable.ZIndex = row.ZIndex + 1
                clickable.MouseEnter:Connect(function()
                    TweenPlay(row,   {BackgroundColor3 = T.BorderHigh}, 0.12)
                    TweenPlay(Arrow, {ImageColor3      = T.Accent},     0.12)
                end)
                clickable.MouseLeave:Connect(function()
                    TweenPlay(row,   {BackgroundColor3 = T.SurfaceHigh}, 0.12)
                    TweenPlay(Arrow, {ImageColor3      = T.Muted},       0.12)
                end)
                clickable.MouseButton1Click:Connect(function()
                    Ripple(row, T.Accent)
                    TweenPlay(row, {BackgroundColor3 = T.AccentDim}, 0.08)
                    task.delay(0.08, function() TweenPlay(row, {BackgroundColor3 = T.SurfaceHigh}, 0.25) end)
                    task.spawn(cb)
                end)
                local api = {}
                function api:SetValue() end
                return api
            end

            function SecAPI:CreateToggle(key, cfg3)
                if type(key) == "table" then cfg3 = key; key = nil end
                cfg3 = cfg3 or {}
                local title   = cfg3.Title or cfg3[1] or "Toggle"
                local desc    = cfg3.Description or cfg3.Desc or cfg3[2] or nil
                local default = cfg3.Default ~= nil and cfg3.Default or false
                local cb      = cfg3.Callback or function() end
                local toggled = default
                local row     = MakeRow(desc and 44 or 32)
                MakeTitle(row, title, desc, 10)
                local Track = Instance.new("Frame", row)
                Track.AnchorPoint      = Vector2.new(1, 0.5)
                Track.Position         = UDim2.new(1, -10, 0.5, 0)
                Track.Size             = UDim2.new(0, 36, 0, 20)
                Track.BackgroundColor3 = toggled and T.Accent or T.Track
                AddCorner(Track, 100)
                local Knob = Instance.new("Frame", Track)
                Knob.BackgroundColor3 = Color3.new(1, 1, 1); Knob.AnchorPoint = Vector2.new(0, 0.5)
                Knob.Position = UDim2.new(0, toggled and 18 or 2, 0.5, 0)
                Knob.Size = UDim2.new(0, 16, 0, 16); AddCorner(Knob, 100)
                local function Refresh(val)
                    TweenPlay(Track, {BackgroundColor3 = val and T.Accent or T.Track}, 0.2)
                    TweenPlay(Knob,  {Position = UDim2.new(0, val and 18 or 2, 0.5, 0)},
                        0.22, Enum.EasingStyle.Back)
                end
                local clickable = Instance.new("TextButton", row)
                clickable.BackgroundTransparency = 1; clickable.Size = UDim2.new(1, 0, 1, 0)
                clickable.Text = ""; clickable.ZIndex = row.ZIndex + 1; clickable.AutoButtonColor = false
                local _onChanged = nil
                clickable.MouseButton1Click:Connect(function()
                    toggled = not toggled; Refresh(toggled); task.spawn(cb, toggled)
                    if _onChanged then task.spawn(_onChanged, toggled) end
                end)
                local api = { Value = toggled, Default = default }
                if key then Vesper.Options[key] = api end
                function api:SetValue(val)
                    if toggled == val then return end
                    toggled = val; self.Value = val; Refresh(val); task.spawn(cb, val)
                    if _onChanged then task.spawn(_onChanged, val) end
                end
                function api:GetState() return toggled end
                function api:OnChanged(fn) _onChanged = fn end
                return api
            end

            function SecAPI:CreateSlider(key, cfg3)
                if type(key) == "table" then cfg3 = key; key = nil end
                cfg3 = cfg3 or {}
                local title    = cfg3.Title or cfg3[1] or "Slider"
                local desc     = cfg3.Description or cfg3.Desc or nil
                local min      = cfg3.Min      or 0
                local max      = cfg3.Max      or 100
                local default  = cfg3.Default  or min
                local rounding = cfg3.Rounding or 0
                local suffix   = cfg3.Suffix   or ""
                local cb       = cfg3.Callback or function() end
                local function Round(n)
                    if rounding == 0 then return math.floor(n + 0.5) end
                    local m = 10^rounding; return math.floor(n*m+0.5)/m
                end
                local val  = Round(math.clamp(default, min, max))
                local row  = MakeRow(desc and 54 or 48)
                local TL   = Instance.new("TextLabel", row)
                TL.BackgroundTransparency = 1; TL.Position = UDim2.new(0, 10, 0, 7)
                TL.Size = UDim2.new(0.6, 0, 0, 16); TL.Font = Enum.Font.GothamBold
                TL.Text = title; TL.TextColor3 = T.Text; TL.TextSize = 12
                TL.TextXAlignment = Enum.TextXAlignment.Left; TC(TL, "TextColor3", "Text")
                local VL = Instance.new("TextLabel", row)
                VL.BackgroundTransparency = 1; VL.Position = UDim2.new(0.6, 0, 0, 7)
                VL.Size = UDim2.new(0.4, -12, 0, 16); VL.Font = Enum.Font.GothamBold
                VL.Text = tostring(val) .. suffix; VL.TextColor3 = T.Accent; VL.TextSize = 12
                VL.TextXAlignment = Enum.TextXAlignment.Right; TC(VL, "TextColor3", "Accent")
                if desc then
                    local DL = Instance.new("TextLabel", row)
                    DL.BackgroundTransparency = 1; DL.Position = UDim2.new(0, 10, 0, 24)
                    DL.Size = UDim2.new(1, -20, 0, 11); DL.Font = Enum.Font.Gotham
                    DL.Text = desc; DL.TextColor3 = T.SubText; DL.TextSize = 10
                    DL.TextXAlignment = Enum.TextXAlignment.Left
                    DL.TextTruncate = Enum.TextTruncate.AtEnd; TC(DL, "TextColor3", "SubText")
                end
                local trackY = desc and 37 or 32
                local Track  = Instance.new("TextButton", row)
                Track.BackgroundColor3 = T.Track; Track.BorderSizePixel = 0
                Track.Position = UDim2.new(0, 10, 0, trackY); Track.Size = UDim2.new(1, -20, 0, 8)
                Track.Text = ""; Track.AutoButtonColor = false; AddCorner(Track, 100)
                TC(Track, "BackgroundColor3", "Track")
                local Fill = Instance.new("Frame", Track)
                Fill.BackgroundColor3 = T.Accent
                Fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0); Fill.BorderSizePixel = 0
                AddCorner(Fill, 100); TC(Fill, "BackgroundColor3", "Accent")
                local FillGlow = Instance.new("ImageLabel", Fill)
                FillGlow.BackgroundTransparency = 1; FillGlow.AnchorPoint = Vector2.new(1, 0.5)
                FillGlow.Position = UDim2.new(1, 0, 0.5, 0); FillGlow.Size = UDim2.new(0, 22, 0, 22)
                FillGlow.Image = "rbxassetid://4996891970"; FillGlow.ImageColor3 = T.Accent
                FillGlow.ImageTransparency = 0.5; TC(FillGlow, "ImageColor3", "Accent")
                local Knob = Instance.new("Frame", Track)
                Knob.BackgroundColor3 = Color3.new(1, 1, 1); Knob.AnchorPoint = Vector2.new(0.5, 0.5)
                Knob.Position = UDim2.new((val-min)/(max-min), 0, 0.5, 0); Knob.Size = UDim2.new(0, 14, 0, 14)
                AddCorner(Knob, 100); AddStroke(Knob, Color3.new(0, 0, 0), 1, 0.7)
                local dragging = false; local _onChanged = nil
                local function SetValFromPx(px)
                    local pct = math.clamp((px - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    val = Round(min + (max-min)*pct)
                    local p = (val-min)/(max-min)
                    TweenPlay(Fill,  {Size     = UDim2.new(p, 0, 1, 0)}, 0.05)
                    TweenPlay(Knob,  {Position = UDim2.new(p, 0, 0.5, 0)}, 0.05)
                    VL.Text = tostring(val) .. suffix; task.spawn(cb, val)
                    if _onChanged then task.spawn(_onChanged, val) end
                end
                Track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true; SetValFromPx(i.Position.X) end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        SetValFromPx(i.Position.X) end
                end)
                local api = { Value = val, Default = default }
                if key then Vesper.Options[key] = api end
                function api:SetValue(v)
                    val = Round(math.clamp(v, min, max)); self.Value = val
                    local p = (val-min)/(max-min)
                    TweenPlay(Fill,  {Size     = UDim2.new(p, 0, 1, 0)}, 0.1)
                    TweenPlay(Knob,  {Position = UDim2.new(p, 0, 0.5, 0)}, 0.1)
                    VL.Text = tostring(val) .. suffix
                end
                function api:GetState() return val end
                function api:OnChanged(fn) _onChanged = fn end
                return api
            end

            function SecAPI:CreateDropdown(key, cfg3)
                if type(key) == "table" then cfg3 = key; key = nil end
                cfg3 = cfg3 or {}
                local title  = cfg3.Title or cfg3[1] or "Dropdown"
                local desc   = cfg3.Description or cfg3.Desc or nil
                local items  = cfg3.Values or cfg3.Options or cfg3[2] or {}
                local multi  = cfg3.Multi or false
                local cb     = cfg3.Callback or function() end
                local MAX_VIS = 5
                local selected = {}
                if cfg3.Default then
                    if type(cfg3.Default) == "string" then selected = {cfg3.Default}
                    elseif type(cfg3.Default) == "table" then
                        if cfg3.Default[1] then selected = cfg3.Default
                        else for k, v in pairs(cfg3.Default) do if v then table.insert(selected, k) end end end
                    elseif type(cfg3.Default) == "number" then
                        selected = items[cfg3.Default] and {items[cfg3.Default]} or {}
                    end
                end
                local isOpen = false
                local height = desc and 44 or 32
                local wrap   = MakeRow(height); wrap.ClipsDescendants = false; wrap.ZIndex = 5
                local TopBtn = Instance.new("TextButton", wrap)
                TopBtn.BackgroundTransparency = 1; TopBtn.Size = UDim2.new(1, 0, 0, height)
                TopBtn.Text = ""; TopBtn.AutoButtonColor = false; TopBtn.ZIndex = 6
                MakeTitle(wrap, title, desc, 10)
                local DispTxt = Instance.new("TextLabel", TopBtn)
                DispTxt.BackgroundTransparency = 1; DispTxt.AnchorPoint = Vector2.new(1, 0.5)
                DispTxt.Position = UDim2.new(1, -30, 0.5, 0); DispTxt.Size = UDim2.new(0.5, -35, 0, 14)
                DispTxt.Font = Enum.Font.Gotham; DispTxt.TextColor3 = T.Accent; DispTxt.TextSize = 11
                DispTxt.TextXAlignment = Enum.TextXAlignment.Right
                DispTxt.TextTruncate = Enum.TextTruncate.AtEnd; DispTxt.ZIndex = 6
                TC(DispTxt, "TextColor3", "Accent")
                local Chev = Instance.new("ImageLabel", TopBtn)
                Chev.BackgroundTransparency = 1; Chev.AnchorPoint = Vector2.new(1, 0.5)
                Chev.Position = UDim2.new(1, -8, 0.5, 0); Chev.Size = UDim2.new(0, 16, 0, 16)
                Chev.Image = Icon("lucide-chevron-down"); Chev.ImageColor3 = T.Muted; Chev.ZIndex = 6
                TC(Chev, "ImageColor3", "Muted")
                local Panel = Instance.new("Frame", Screen) -- parented to ScreenGui for overlay
                Panel.BackgroundColor3 = T.Surface; Panel.BorderSizePixel = 0
                Panel.Size = UDim2.new(0, 0, 0, 0) -- will be sized dynamically
                Panel.ClipsDescendants = true; Panel.Visible = false; Panel.ZIndex = 100
                AddCorner(Panel, 6)
                TCS(AddStroke(Panel, T.Border, 1), "Border")
                TC(Panel, "BackgroundColor3", "Surface")

                -- Full-screen invisible backdrop — catches clicks outside the dropdown
                local Backdrop = Instance.new("TextButton", Screen)
                Backdrop.BackgroundTransparency = 1
                Backdrop.Size     = UDim2.new(1, 0, 1, 0)
                Backdrop.Position = UDim2.new(0, 0, 0, 0)
                Backdrop.Text     = ""
                Backdrop.ZIndex   = 99  -- just below Panel (100)
                Backdrop.Visible  = false
                Backdrop.AutoButtonColor = false

                -- Helper: position Panel below the dropdown button in screen space
                local function RepositionPanel()
                    local absPos  = wrap.AbsolutePosition
                    local absSize = wrap.AbsoluteSize
                    Panel.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
                    Panel.Size     = UDim2.new(0, absSize.X, 0, Panel.Size.Y.Offset)
                end

                local SearchBox = Instance.new("TextBox", Panel)
                SearchBox.BackgroundColor3 = T.InputBg; SearchBox.BorderSizePixel = 0
                SearchBox.Position = UDim2.new(0, 6, 0, 6); SearchBox.Size = UDim2.new(1, -12, 0, 22)
                SearchBox.Font = Enum.Font.Gotham; SearchBox.PlaceholderText = "Search..."
                SearchBox.Text = ""; SearchBox.TextColor3 = T.Text
                SearchBox.PlaceholderColor3 = T.Muted; SearchBox.TextSize = 11
                SearchBox.ClearTextOnFocus = false; SearchBox.ZIndex = 102
                AddCorner(SearchBox, 5); AddPad(SearchBox, 0, 0, 6, 6)
                TC(SearchBox, "BackgroundColor3", "InputBg")
                TC(SearchBox, "TextColor3",       "Text")
                TC(SearchBox, "PlaceholderColor3","Muted")
                local ItemScroll = Instance.new("ScrollingFrame", Panel)
                ItemScroll.BackgroundTransparency = 1
                ItemScroll.Position = UDim2.new(0, 6, 0, 32); ItemScroll.Size = UDim2.new(1, -12, 1, -38)
                ItemScroll.ScrollBarThickness = 2; ItemScroll.ScrollBarImageColor3 = T.Accent
                ItemScroll.CanvasSize = UDim2.new(0, 0, 0, 0); ItemScroll.ZIndex = 102
                AddList(ItemScroll, 2); TC(ItemScroll, "ScrollBarImageColor3", "Accent")
                local _onChanged = nil
                local function GetDisplayText()
                    if #selected == 0     then return multi and "None" or "Select..."
                    elseif #selected == 1 then return selected[1]
                    elseif #selected <= 2 then return table.concat(selected, ", ")
                    else                       return #selected .. " selected" end
                end
                local function RefreshDisplay() DispTxt.Text = GetDisplayText() end
                local itemBtns = {}

                -- Close helper (reused in multiple places)
                local function ClosePanel()
                    if not isOpen then return end
                    isOpen = false
                    Backdrop.Visible = false
                    TweenPlay(Panel, {Size=UDim2.new(0, Panel.Size.X.Offset, 0, 0)}, 0.18, Enum.EasingStyle.Quint)
                    TweenPlay(Chev,  {Rotation=0}, 0.18)
                    task.delay(0.18, function() Panel.Visible = false end)
                end

                -- Click backdrop = close dropdown
                Backdrop.MouseButton1Click:Connect(ClosePanel)

                -- Register this dropdown's closer so minimize/close can dismiss it
                table.insert(Window._dropdownClosers, ClosePanel)

                local function BuildList(filter)
                    for _, b in pairs(itemBtns) do b:Destroy() end; itemBtns = {}
                    local count = 0
                    for _, item in ipairs(items) do
                        if filter == "" or string.find(item:lower(), filter:lower(), 1, true) then
                            local isSel = false
                            for _, s in ipairs(selected) do if s == item then isSel = true; break end end
                            local IBtn = Instance.new("TextButton", ItemScroll)
                            IBtn.BackgroundColor3 = isSel and T.AccentDim or T.SurfaceHigh
                            IBtn.BorderSizePixel = 0; IBtn.Size = UDim2.new(1, 0, 0, 26)
                            IBtn.Font = Enum.Font.Gotham; IBtn.Text = "  " .. item
                            IBtn.TextColor3 = isSel and T.Text or T.SubText; IBtn.TextSize = 11
                            IBtn.TextXAlignment = Enum.TextXAlignment.Left; IBtn.ZIndex = 103; AddCorner(IBtn, 5)
                            IBtn.MouseEnter:Connect(function()
                                if not isSel then TweenPlay(IBtn,{BackgroundColor3=T.SidebarHover},0.1) end end)
                            IBtn.MouseLeave:Connect(function()
                                if not isSel then TweenPlay(IBtn,{BackgroundColor3=T.SurfaceHigh},0.1) end end)
                            IBtn.MouseButton1Click:Connect(function()
                                if multi then
                                    isSel = not isSel
                                    if isSel then table.insert(selected, item)
                                    else for i, v in ipairs(selected) do if v==item then table.remove(selected,i); break end end end
                                    IBtn.BackgroundColor3 = isSel and T.AccentDim or T.SurfaceHigh
                                    IBtn.TextColor3       = isSel and T.Text or T.SubText
                                    RefreshDisplay(); task.spawn(cb, selected)
                                    if _onChanged then task.spawn(_onChanged, selected) end
                                else
                                    selected = {item}; RefreshDisplay(); task.spawn(cb, item)
                                    if _onChanged then task.spawn(_onChanged, item) end
                                    ClosePanel()
                                end
                            end)
                            table.insert(itemBtns, IBtn); count = count + 1
                        end
                    end
                    ItemScroll.CanvasSize = UDim2.new(0, 0, 0, count * 28)
                    if isOpen then
                        local pw = Panel.Size.X.Offset
                        local ph = math.min(count, MAX_VIS) * 28 + 40
                        TweenPlay(Panel, {Size=UDim2.new(0, pw, 0, ph)}, 0.15)
                    end
                end
                SearchBox:GetPropertyChangedSignal("Text"):Connect(function() BuildList(SearchBox.Text) end)
                TopBtn.MouseButton1Click:Connect(function()
                    if isOpen then
                        ClosePanel()
                        return
                    end
                    -- Close any other open dropdowns first
                    CloseAllDropdowns()
                    isOpen = true
                    RepositionPanel()
                    Backdrop.Visible = true
                    SearchBox.Text = ""; Panel.Visible = true; BuildList("")
                    local pw = wrap.AbsoluteSize.X
                    local ph = math.min(#items, MAX_VIS) * 28 + 40
                    Panel.Size = UDim2.new(0, pw, 0, 0)
                    TweenPlay(Panel, {Size=UDim2.new(0, pw, 0, ph)}, 0.22, Enum.EasingStyle.Back)
                    TweenPlay(Chev,  {Rotation=180}, 0.2)
                end)
                RefreshDisplay()
                local api = { Value = multi and selected or (selected[1] or nil), Default = cfg3.Default }
                if key then Vesper.Options[key] = api end
                function api:SetValue(v)
                    if multi then
                        selected = {}
                        if type(v) == "table" then
                            if v[1] then selected = v
                            else for k, s in pairs(v) do if s then table.insert(selected, k) end end end
                        else table.insert(selected, tostring(v)) end
                    else selected = {tostring(v)} end
                    self.Value = multi and selected or (selected[1] or nil); RefreshDisplay()
                end
                function api:GetState() return multi and selected or (selected[1] or nil) end
                function api:OnChanged(fn) _onChanged = fn end
                function api:Refresh(newItems) items = newItems; BuildList(SearchBox.Text or "") end
                return api
            end

            function SecAPI:CreateTextBox(key, cfg3)
                if type(key) == "table" then cfg3 = key; key = nil end
                cfg3 = cfg3 or {}
                local title    = cfg3.Title or cfg3[1] or "Input"
                local desc     = cfg3.Description or cfg3.Desc or nil
                local default  = cfg3.Default or ""
                local ph       = cfg3.Placeholder or "Type here..."
                local numeric  = cfg3.Numeric  or false
                local finished = cfg3.Finished or false
                local cb       = cfg3.Callback or function() end
                local height   = desc and 56 or 50
                local F        = MakeRow(height); MakeTitle(F, title, desc, 10)
                local InputBg  = Instance.new("Frame", F)
                InputBg.BackgroundColor3 = T.InputBg; InputBg.BorderSizePixel = 0
                InputBg.Position = UDim2.new(0, 8, 0, desc and 38 or 28)
                InputBg.Size     = UDim2.new(1, -16, 0, 18)
                AddCorner(InputBg, 4)
                TCS(AddStroke(InputBg, T.Border, 1), "Border")
                TC(InputBg, "BackgroundColor3", "InputBg")
                local Box = Instance.new("TextBox", InputBg)
                Box.BackgroundTransparency = 1; Box.Position = UDim2.new(0, 6, 0, 0)
                Box.Size = UDim2.new(1, -12, 1, 0); Box.Font = Enum.Font.Gotham
                Box.PlaceholderText = ph; Box.PlaceholderColor3 = T.Muted
                Box.Text = tostring(default); Box.TextColor3 = T.Text; Box.TextSize = 11
                Box.ClearTextOnFocus = false
                TC(Box, "TextColor3", "Text"); TC(Box, "PlaceholderColor3", "Muted")
                local _onChanged = nil
                Box.Focused:Connect(function()   TweenPlay(InputBg, {BackgroundColor3 = T.Surface},  0.15) end)
                Box.FocusLost:Connect(function(enter)
                    TweenPlay(InputBg, {BackgroundColor3 = T.InputBg}, 0.15)
                    if finished and not enter then return end
                    local v = Box.Text
                    if numeric then v = tonumber(v) or 0; Box.Text = tostring(v) end
                    task.spawn(cb, v)
                    if _onChanged then task.spawn(_onChanged, v) end
                end)
                if not finished then
                    Box:GetPropertyChangedSignal("Text"):Connect(function()
                        if _onChanged then task.spawn(_onChanged, Box.Text) end
                    end)
                end
                local api = { Value = default, Default = default }
                if key then Vesper.Options[key] = api end
                function api:SetValue(v) Box.Text = tostring(v); self.Value = v end
                function api:GetState() return Box.Text end
                function api:OnChanged(fn) _onChanged = fn end
                return api
            end

            function SecAPI:CreateKeybind(key, cfg3)
                if type(key) == "table" then cfg3 = key; key = nil end
                cfg3 = cfg3 or {}
                local title     = cfg3.Title or cfg3[1] or "Keybind"
                local desc      = cfg3.Description or cfg3.Desc or nil
                local mode      = cfg3.Mode or "Toggle"
                local cb        = cfg3.Callback or function() end
                local changedCb = cfg3.ChangedCallback or function() end
                local currentKey
                local defaultStr = cfg3.Default or "E"
                if type(defaultStr) == "string" then currentKey = Enum.KeyCode[defaultStr] or Enum.KeyCode.E
                else currentKey = defaultStr end
                local listening = false; local holdState = false; local toggleState = false
                local _onClick = nil; local _onChanged2 = nil
                local row = MakeRow(desc and 44 or 32); MakeTitle(row, title, desc, 10)
                local KeyBtn = Instance.new("TextButton", row)
                KeyBtn.BackgroundColor3 = T.Track; KeyBtn.AnchorPoint = Vector2.new(1, 0.5)
                KeyBtn.Position = UDim2.new(1, -8, 0.5, 0); KeyBtn.Size = UDim2.new(0, 0, 0, 22)
                KeyBtn.AutomaticSize = Enum.AutomaticSize.X; KeyBtn.Font = Enum.Font.GothamBold
                KeyBtn.Text = currentKey.Name; KeyBtn.TextColor3 = T.Accent; KeyBtn.TextSize = 11
                KeyBtn.AutoButtonColor = false; AddCorner(KeyBtn, 5); AddPad(KeyBtn, 0, 0, 8, 8)
                TC(KeyBtn, "BackgroundColor3", "Track"); TC(KeyBtn, "TextColor3", "Accent")
                KeyBtn.MouseButton1Click:Connect(function()
                    listening = true; KeyBtn.Text = "..."; KeyBtn.TextColor3 = T.Warning end)
                UIS.InputBegan:Connect(function(i, processed)
                    if listening and i.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = i.KeyCode; KeyBtn.Text = currentKey.Name
                        KeyBtn.TextColor3 = T.Accent; listening = false
                        task.spawn(changedCb, currentKey)
                        if _onChanged2 then task.spawn(_onChanged2, currentKey) end; return
                    end
                    if not listening and not processed and i.KeyCode == currentKey then
                        if mode == "Toggle" then
                            toggleState = not toggleState; task.spawn(cb, toggleState)
                            if _onClick then task.spawn(_onClick) end
                        elseif mode == "Hold"   then holdState = true; task.spawn(cb, true)
                        elseif mode == "Always" then task.spawn(cb, true) end
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if mode == "Hold" and i.KeyCode == currentKey then holdState = false; task.spawn(cb, false) end
                end)
                local api = { Value = currentKey, Default = currentKey }
                if key then Vesper.Options[key] = api end
                function api:SetValue(k, m)
                    if type(k) == "string" then currentKey = Enum.KeyCode[k] or currentKey
                    else currentKey = k end
                    if m then mode = m end; KeyBtn.Text = currentKey.Name; self.Value = currentKey
                end
                function api:GetState()
                    if mode == "Toggle" then return toggleState
                    elseif mode == "Hold" then return holdState end; return false
                end
                function api:OnClick(fn)   _onClick    = fn end
                function api:OnChanged(fn) _onChanged2 = fn end
                return api
            end

            function SecAPI:CreateColorPicker(key, cfg3)
                if type(key) == "table" then cfg3 = key; key = nil end
                cfg3 = cfg3 or {}
                local title    = cfg3.Title or cfg3[1] or "Color"
                local desc     = cfg3.Description or cfg3.Desc or nil
                local default  = cfg3.Default or Color3.fromRGB(139, 92, 246)
                local useAlpha = cfg3.Transparency ~= nil
                local alpha    = 1 - (cfg3.Transparency or 0)
                local cb       = cfg3.Callback or function() end
                local color    = default; local h, s, v = color:ToHSV()
                local isOpen   = false; local _onChanged = nil
                local rowH     = desc and 44 or 32
                local wrap     = MakeRow(rowH); wrap.ClipsDescendants = true
                local CHeader  = Instance.new("TextButton", wrap)
                CHeader.BackgroundTransparency = 1; CHeader.Size = UDim2.new(1, 0, 0, rowH)
                CHeader.Text = ""; CHeader.AutoButtonColor = false
                MakeTitle(wrap, title, desc, 10)
                local Preview = Instance.new("Frame", wrap)
                Preview.BackgroundColor3 = color; Preview.AnchorPoint = Vector2.new(1, 0.5)
                Preview.Position = UDim2.new(1, -10, 0.5, 0); Preview.Size = UDim2.new(0, 38, 0, 18)
                AddCorner(Preview, 5)
                TCS(AddStroke(Preview, T.Border, 1), "Border")
                local Panel2 = Instance.new("Frame", wrap)
                Panel2.BackgroundTransparency = 1
                Panel2.Position = UDim2.new(0, 8, 0, rowH + 6)
                Panel2.Size     = UDim2.new(1, -16, 0, useAlpha and 148 or 128)
                local SVMap = Instance.new("TextButton", Panel2)
                SVMap.BackgroundColor3 = Color3.fromHSV(h,1,1)
                SVMap.Position = UDim2.new(0,0,0,0); SVMap.Size = UDim2.new(1,-22,0,100)
                SVMap.Text = ""; SVMap.AutoButtonColor = false; AddCorner(SVMap, 5)
                local WG = Instance.new("UIGradient", SVMap)
                WG.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
                WG.Color = ColorSequence.new(Color3.new(1,1,1))
                local Ov = Instance.new("Frame", SVMap)
                Ov.BackgroundColor3 = Color3.new(0,0,0); Ov.BorderSizePixel = 0
                Ov.Size = UDim2.new(1,0,1,0); AddCorner(Ov, 5)
                local OvG = Instance.new("UIGradient", Ov); OvG.Rotation = 90
                OvG.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
                local SVCur = Instance.new("Frame", SVMap)
                SVCur.BackgroundColor3 = Color3.new(1,1,1); SVCur.AnchorPoint = Vector2.new(0.5,0.5)
                SVCur.Position = UDim2.new(s,0,1-v,0); SVCur.Size = UDim2.new(0,8,0,8); SVCur.ZIndex = 5
                AddCorner(SVCur,100); AddStroke(SVCur,Color3.new(0,0,0),1,0.4)
                local HueBar = Instance.new("TextButton", Panel2)
                HueBar.BackgroundColor3 = Color3.new(1,1,1); HueBar.AnchorPoint = Vector2.new(1,0)
                HueBar.Position = UDim2.new(1,0,0,0); HueBar.Size = UDim2.new(0,14,0,100)
                HueBar.Text = ""; HueBar.AutoButtonColor = false; AddCorner(HueBar,6)
                local HG = Instance.new("UIGradient", HueBar); HG.Rotation = 90
                HG.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,     Color3.fromRGB(255,0,0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
                    ColorSequenceKeypoint.new(0.5,   Color3.fromRGB(0,255,255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
                    ColorSequenceKeypoint.new(1,     Color3.fromRGB(255,0,0)),
                })
                local HueCur = Instance.new("Frame", HueBar)
                HueCur.BackgroundColor3 = Color3.new(1,1,1); HueCur.AnchorPoint = Vector2.new(0.5,0.5)
                HueCur.Position = UDim2.new(0.5,0,h,0); HueCur.Size = UDim2.new(1,4,0,4); HueCur.ZIndex = 5
                AddCorner(HueCur,100); AddStroke(HueCur,Color3.new(0,0,0),1,0.4)
                local HexBg = Instance.new("Frame", Panel2)
                HexBg.BackgroundColor3 = T.InputBg; HexBg.BorderSizePixel = 0
                HexBg.Position = UDim2.new(0,0,0,106); HexBg.Size = UDim2.new(1,-22,0,20)
                AddCorner(HexBg,4); TC(HexBg,"BackgroundColor3","InputBg")
                local HexHash = Instance.new("TextLabel", HexBg)
                HexHash.BackgroundTransparency = 1; HexHash.Position = UDim2.new(0,6,0,0)
                HexHash.Size = UDim2.new(0,12,1,0); HexHash.Font = Enum.Font.GothamBold
                HexHash.Text = "#"; HexHash.TextColor3 = T.Muted; HexHash.TextSize = 10
                TC(HexHash,"TextColor3","Muted")
                local HexBox = Instance.new("TextBox", HexBg)
                HexBox.BackgroundTransparency = 1; HexBox.Position = UDim2.new(0,18,0,0)
                HexBox.Size = UDim2.new(1,-24,1,0); HexBox.Font = Enum.Font.Gotham
                HexBox.Text = string.format("%02X%02X%02X",
                    math.floor(color.R*255),math.floor(color.G*255),math.floor(color.B*255))
                HexBox.TextColor3 = T.Text; HexBox.TextSize = 10; HexBox.ClearTextOnFocus = false
                TC(HexBox,"TextColor3","Text")
                local AlphaTrack, AlphaFill, AlphaCur
                if useAlpha then
                    local AlphaBg = Instance.new("Frame", Panel2)
                    AlphaBg.BackgroundColor3 = T.InputBg; AlphaBg.BorderSizePixel = 0
                    AlphaBg.Position = UDim2.new(0,0,0,132); AlphaBg.Size = UDim2.new(1,-22,0,16)
                    AddCorner(AlphaBg,100); TC(AlphaBg,"BackgroundColor3","InputBg")
                    AlphaTrack = Instance.new("TextButton", AlphaBg)
                    AlphaTrack.BackgroundTransparency = 1; AlphaTrack.Size = UDim2.new(1,0,1,0)
                    AlphaTrack.Text = ""; AlphaTrack.AutoButtonColor = false
                    AlphaFill = Instance.new("Frame", AlphaBg)
                    AlphaFill.BackgroundColor3 = T.Accent; AlphaFill.BorderSizePixel = 0
                    AlphaFill.Size = UDim2.new(alpha,0,1,0); AddCorner(AlphaFill,100)
                    TC(AlphaFill,"BackgroundColor3","Accent")
                    AlphaCur = Instance.new("Frame", AlphaBg)
                    AlphaCur.BackgroundColor3 = Color3.new(1,1,1); AlphaCur.AnchorPoint = Vector2.new(0.5,0.5)
                    AlphaCur.Position = UDim2.new(alpha,0,0.5,0); AlphaCur.Size = UDim2.new(0,12,0,12)
                    AddCorner(AlphaCur,100); AddStroke(AlphaCur,Color3.new(0,0,0),1,0.5)
                end
                local function UpdateColor()
                    color = Color3.fromHSV(h,s,v)
                    SVMap.BackgroundColor3 = Color3.fromHSV(h,1,1); Preview.BackgroundColor3 = color
                    HexBox.Text = string.format("%02X%02X%02X",
                        math.floor(color.R*255),math.floor(color.G*255),math.floor(color.B*255))
                    if AlphaFill then TweenPlay(AlphaFill,{BackgroundColor3=color},0.05) end
                    task.spawn(cb,color,1-alpha)
                    if _onChanged then task.spawn(_onChanged) end
                end
                local trackSV, trackHue, trackAlpha = false, false, false
                local function pct(i, obj, axis)
                    if axis=="X" then return math.clamp((i.Position.X-obj.AbsolutePosition.X)/obj.AbsoluteSize.X,0,1) end
                    return math.clamp((i.Position.Y-obj.AbsolutePosition.Y)/obj.AbsoluteSize.Y,0,1)
                end
                SVMap.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        trackSV=true; s=pct(i,SVMap,"X"); v=1-pct(i,SVMap,"Y"); SVCur.Position=UDim2.new(s,0,1-v,0); UpdateColor() end end)
                HueBar.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        trackHue=true; h=pct(i,HueBar,"Y"); HueCur.Position=UDim2.new(0.5,0,h,0); UpdateColor() end end)
                if AlphaTrack then
                    AlphaTrack.InputBegan:Connect(function(i)
                        if i.UserInputType==Enum.UserInputType.MouseButton1 then
                            trackAlpha=true; alpha=pct(i,AlphaTrack,"X")
                            AlphaFill.Size=UDim2.new(alpha,0,1,0); AlphaCur.Position=UDim2.new(alpha,0,0.5,0); UpdateColor() end end)
                end
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then trackSV=false; trackHue=false; trackAlpha=false end end)
                UIS.InputChanged:Connect(function(i)
                    if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
                    if trackSV then s=pct(i,SVMap,"X"); v=1-pct(i,SVMap,"Y"); SVCur.Position=UDim2.new(s,0,1-v,0); UpdateColor()
                    elseif trackHue then h=pct(i,HueBar,"Y"); HueCur.Position=UDim2.new(0.5,0,h,0); UpdateColor()
                    elseif trackAlpha then alpha=pct(i,AlphaTrack,"X"); AlphaFill.Size=UDim2.new(alpha,0,1,0); AlphaCur.Position=UDim2.new(alpha,0,0.5,0); UpdateColor() end end)
                HexBox.FocusLost:Connect(function()
                    local hex=HexBox.Text:gsub("[^%x]",""):sub(1,6)
                    if #hex==6 then
                        local r=tonumber(hex:sub(1,2),16)/255; local g=tonumber(hex:sub(3,4),16)/255; local b=tonumber(hex:sub(5,6),16)/255
                        h,s,v=Color3.new(r,g,b):ToHSV(); SVCur.Position=UDim2.new(s,0,1-v,0); HueCur.Position=UDim2.new(0.5,0,h,0); UpdateColor() end end)
                CHeader.MouseButton1Click:Connect(function()
                    isOpen=not isOpen
                    local target=isOpen and rowH+(useAlpha and 160 or 140) or rowH
                    TweenPlay(wrap,{Size=UDim2.new(1,0,0,target)},0.22,Enum.EasingStyle.Back) end)
                local api={Value=color, Transparency=1-alpha, Default=default}
                if key then Vesper.Options[key]=api end
                function api:SetValue(c) h,s,v=c:ToHSV(); SVCur.Position=UDim2.new(s,0,1-v,0); HueCur.Position=UDim2.new(0.5,0,h,0); UpdateColor() end
                function api:SetValueRGB(c) api:SetValue(c) end
                function api:GetState() return color end
                function api:OnChanged(fn) _onChanged=fn end
                return api
            end

            return SecAPI
        end -- CreateSection

        return TabAPI
    end -- AddTab

    Window.AddTab    = function(self_or_cfg, cfg) return AddTab(cfg or self_or_cfg) end
    Window.CreateTab = Window.AddTab

    -- ════════════════════════════════════════════════════════════
    --  BUBBLE  — circular logo quick-access icon
    --  Matches the reference: a filled circle showing the Vesper
    --  logo artwork, clipped cleanly inside the circle.
    --  Click to toggle the main window.  Fully draggable.
    -- ════════════════════════════════════════════════════════════
    local BUBBLE_SIZE = 56   -- diameter of the circle in px

    local Bubble = Instance.new("Frame", Screen)
    Bubble.BackgroundTransparency = 1   -- fully transparent — the V logo image IS the circle
    Bubble.AnchorPoint      = Vector2.new(0, 0)
    Bubble.Position         = UDim2.new(0, 20, 0, 20)
    Bubble.Size             = UDim2.new(0, BUBBLE_SIZE, 0, BUBBLE_SIZE)
    Bubble.ClipsDescendants = false
    local BubbleStroke -- no stroke on transparent bubble

    -- V logo image — the image itself contains the dark circle with V cutout
    local BubbleLogo = Instance.new("ImageLabel", Bubble)
    BubbleLogo.BackgroundTransparency = 1
    BubbleLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    BubbleLogo.Position    = UDim2.new(0.5, 0, 0.5, 0)
    BubbleLogo.Size        = UDim2.new(1, 0, 1, 0)
    BubbleLogo.Image       = LOGO_ASSET_ID
    BubbleLogo.ScaleType   = Enum.ScaleType.Fit
    BubbleLogo.ZIndex      = 2

    -- Clickable / draggable overlay
    local BubbleBtn = Instance.new("TextButton", Bubble)
    BubbleBtn.BackgroundTransparency = 1
    BubbleBtn.Size   = UDim2.new(1, 0, 1, 0)
    BubbleBtn.Text   = ""
    BubbleBtn.ZIndex = 10
    MakeDraggable(BubbleBtn, Bubble)

    -- Toggle / Minimize logic
    local minimized = false
    local _uiReady = false
    local function ToggleUI()
        if not _uiReady then return end
        minimized = not minimized
        if minimized then
            -- Close any open dropdown panels before hiding
            CloseAllDropdowns()
            -- Dim the logo to hint "hidden"
            TweenPlay(BubbleLogo, {ImageTransparency = 0.5}, 0.18)
            TweenPlay(WinScale, {Scale = 0}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(0.28, function() Main.Visible = false end)
        else
            TweenPlay(BubbleLogo, {ImageTransparency = 0}, 0.18)
            Main.Visible = true
            TweenPlay(WinScale, {Scale = 1}, 0.45, Enum.EasingStyle.Elastic)
        end
    end

    -- Hide bubble until key is verified
    Bubble.Visible = false

    -- Wait for key verification before showing UI
    task.spawn(function()
        local function isKeyVerified()
            local ok, result = pcall(function()
                return getgenv().SCRIPT_KEY
            end)
            return ok and result
        end

        -- Wait until key is verified (blocks UI until key gate passes)
        if not isKeyVerified() then
            while not isKeyVerified() do
                task.wait(0.1)
            end
            -- Wait for key gate exit animation to complete
            task.wait(1.8)
        end

        -- Now reveal the UI
        _uiReady = true
        Main.Visible = true
        Bubble.Visible = true
        TweenPlay(WinScale, {Scale = 1}, 0.5, Enum.EasingStyle.Elastic)
    end)

    -- Apply GlassMode on first load since Default = true
    Main.BackgroundTransparency    = 0.32
    Sidebar.BackgroundTransparency = 0.35
    MainStroke.Transparency        = 0.65
    MainStroke.Thickness           = 1.8

    -- Hover pulse on the bubble — scale effect since background is transparent
    BubbleBtn.MouseEnter:Connect(function()
        TweenPlay(BubbleLogo, {Size = UDim2.new(1, 4, 1, 4)}, 0.15, Enum.EasingStyle.Back)
    end)
    BubbleBtn.MouseLeave:Connect(function()
        TweenPlay(BubbleLogo, {Size = UDim2.new(1, 0, 1, 0)}, 0.18)
    end)
    BubbleBtn.MouseButton1Click:Connect(ToggleUI)

    -- Header button connections (kept for completeness)
    MinimizeBtn.MouseButton1Click:Connect(ToggleUI)
    CloseBtn.MouseButton1Click:Connect(function()
        CloseAllDropdowns()
        TweenPlay(WinScale, {Scale = 0}, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.22, function() Main.Visible = false end)
    end)

    UIS.InputBegan:Connect(function(i, p)
        if not p and i.KeyCode == hotkey then ToggleUI() end
    end)

    function Window:Toggle(state)
        if state ~= nil then if state == (not minimized) then return end end
        ToggleUI()
    end

    -- ════════════════════════════════════════════════════════════
    --  NOTIFICATIONS
    -- ════════════════════════════════════════════════════════════
    function Window:Notify(cfg2)
        cfg2 = cfg2 or {}
        local title    = cfg2.Title      or "Notice"
        local content  = cfg2.Content    or ""
        local sub      = cfg2.SubContent or nil
        local duration = cfg2.Duration   or cfg2.Time or 5
        local icon2    = cfg2.Icon       or "lucide-bell"
        local ntype    = cfg2.Type       or "default"
        if sub and sub ~= "" then content = content .. "\n" .. sub end
        local accent2 = ({
            default = T.Accent,   success = T.Positive,
            error   = T.Negative, warning = T.Warning,
        })[ntype] or T.Accent
        local textH   = TextService:GetTextSize(content, 11, Enum.Font.Gotham, Vector2.new(246, 9999)).Y
        local targetH = math.max(64, textH + 52)
        local N = Instance.new("Frame", NotifHolder)
        N.BackgroundColor3 = T.Surface; N.BorderSizePixel = 0
        N.Size = UDim2.new(1, 0, 0, 0); N.ClipsDescendants = false
        AddCorner(N, 8); AddStroke(N, accent2, 1, 0.5)
        local Bar2 = Instance.new("Frame", N)
        Bar2.BackgroundColor3 = accent2; Bar2.BorderSizePixel = 0
        Bar2.Size = UDim2.new(0, 3, 1, 0); AddCorner(Bar2, 4)
        local TL2 = Instance.new("Frame", N)
        TL2.BackgroundColor3 = accent2; TL2.Size = UDim2.new(1, 0, 0, 2); TL2.BorderSizePixel = 0
        local NI = Instance.new("ImageLabel", N)
        NI.BackgroundTransparency = 1; NI.Position = UDim2.new(0, 12, 0, 12)
        NI.Size = UDim2.new(0, 18, 0, 18); NI.Image = Icon(icon2); NI.ImageColor3 = accent2
        local NT = Instance.new("TextLabel", N)
        NT.BackgroundTransparency = 1; NT.Position = UDim2.new(0, 36, 0, 10)
        NT.Size = UDim2.new(1, -44, 0, 16); NT.Font = Enum.Font.GothamBold
        NT.Text = title; NT.TextColor3 = T.Text; NT.TextSize = 13
        NT.TextXAlignment = Enum.TextXAlignment.Left
        local ND = Instance.new("TextLabel", N)
        ND.BackgroundTransparency = 1; ND.Position = UDim2.new(0, 36, 0, 30)
        ND.Size = UDim2.new(1, -44, 0, textH); ND.Font = Enum.Font.Gotham
        ND.Text = content; ND.TextColor3 = T.SubText; ND.TextSize = 11
        ND.TextWrapped = true; ND.TextXAlignment = Enum.TextXAlignment.Left
        local PBase = Instance.new("Frame", N)
        PBase.BackgroundColor3 = T.Track; PBase.AnchorPoint = Vector2.new(0, 1)
        PBase.Position = UDim2.new(0, 8, 1, -4); PBase.Size = UDim2.new(1, -16, 0, 2)
        PBase.BorderSizePixel = 0; AddCorner(PBase, 100)
        local PFill = Instance.new("Frame", PBase)
        PFill.BackgroundColor3 = accent2; PFill.BorderSizePixel = 0
        PFill.Size = UDim2.new(1, 0, 1, 0); AddCorner(PFill, 100)
        TweenPlay(N, {Size = UDim2.new(1, 0, 0, targetH)}, 0.3, Enum.EasingStyle.Back)
        if duration then
            TweenPlay(PFill, {Size = UDim2.new(0, 0, 1, 0)}, duration - 0.3, Enum.EasingStyle.Linear)
            task.delay(duration, function()
                TweenPlay(N, {Size = UDim2.new(1, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quint)
                task.delay(0.25, function() N:Destroy() end)
            end)
        end
    end

    -- ════════════════════════════════════════════════════════════
    --  DIALOG
    -- ════════════════════════════════════════════════════════════
    function Window:Dialog(cfg2)
        cfg2 = cfg2 or {}
        local dtitle   = cfg2.Title   or "Dialog"
        local dcontent = cfg2.Content or ""
        local buttons  = cfg2.Buttons or {}
        local Overlay  = Instance.new("Frame", Screen)
        Overlay.BackgroundColor3       = Color3.new(0,0,0)
        Overlay.BackgroundTransparency = 0.4
        Overlay.Size = UDim2.new(1,0,1,0); Overlay.ZIndex = 50
        local Box = Instance.new("Frame", Overlay)
        Box.BackgroundColor3 = T.Surface; Box.AnchorPoint = Vector2.new(0.5,0.5)
        Box.Position = UDim2.new(0.5,0,0.5,0); Box.Size = UDim2.new(0,340,0,0)
        Box.AutomaticSize = Enum.AutomaticSize.Y; Box.ZIndex = 51
        AddCorner(Box, 10); AddStroke(Box, T.Border, 1.5)
        AddPad(Box, 20, 20, 20, 20); AddList(Box, 12)
        local BoxScale = Instance.new("UIScale", Box); BoxScale.Scale = 0.8
        TweenPlay(BoxScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back)
        local DTitle = Instance.new("TextLabel", Box)
        DTitle.BackgroundTransparency = 1; DTitle.Size = UDim2.new(1,0,0,20)
        DTitle.Font = Enum.Font.GothamBold; DTitle.Text = dtitle
        DTitle.TextColor3 = T.Text; DTitle.TextSize = 15
        DTitle.TextXAlignment = Enum.TextXAlignment.Left
        local DContent = Instance.new("TextLabel", Box)
        DContent.BackgroundTransparency = 1; DContent.Size = UDim2.new(1,0,0,0)
        DContent.AutomaticSize = Enum.AutomaticSize.Y; DContent.Font = Enum.Font.Gotham
        DContent.Text = dcontent; DContent.TextColor3 = T.SubText; DContent.TextSize = 12
        DContent.TextXAlignment = Enum.TextXAlignment.Left; DContent.TextWrapped = true
        local BtnRow = Instance.new("Frame", Box)
        BtnRow.BackgroundTransparency = 1; BtnRow.Size = UDim2.new(1,0,0,34)
        local BL2 = Instance.new("UIListLayout", BtnRow)
        BL2.FillDirection = Enum.FillDirection.Horizontal; BL2.Padding = UDim.new(0,8)
        BL2.HorizontalAlignment = Enum.HorizontalAlignment.Right
        local function Close()
            TweenPlay(BoxScale,{Scale=0.8},0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
            TweenPlay(Overlay,{BackgroundTransparency=1},0.2)
            task.delay(0.2, function() Overlay:Destroy() end)
        end
        for _, btnDef in ipairs(buttons) do
            local isConfirm = btnDef.Title=="Confirm" or btnDef.Primary
            local B = Instance.new("TextButton", BtnRow)
            B.BackgroundColor3 = isConfirm and T.Accent or T.SurfaceHigh; B.BorderSizePixel = 0
            B.Size = UDim2.new(0,0,1,0); B.AutomaticSize = Enum.AutomaticSize.X
            B.Font = Enum.Font.GothamBold; B.Text = btnDef.Title or "OK"
            B.TextColor3 = T.Text; B.TextSize = 12; B.AutoButtonColor = false
            AddCorner(B,6); AddPad(B,0,0,14,14)
            AddStroke(B, isConfirm and T.AccentDim or T.Border, 1)
            B.MouseButton1Click:Connect(function()
                Close(); if btnDef.Callback then task.spawn(btnDef.Callback) end end)
        end
        if #buttons == 0 then
            local OkBtn = Instance.new("TextButton", BtnRow)
            OkBtn.BackgroundColor3 = T.Accent; OkBtn.BorderSizePixel = 0
            OkBtn.Size = UDim2.new(0,80,1,0); OkBtn.Font = Enum.Font.GothamBold
            OkBtn.Text = "OK"; OkBtn.TextColor3 = T.Text; OkBtn.TextSize = 12
            OkBtn.AutoButtonColor = false; AddCorner(OkBtn,6)
            OkBtn.MouseButton1Click:Connect(Close)
        end
    end

    function Window:SelectTab(index)
        local tab = Window._tabs[index]
        if tab then SwitchTab(tab) end
    end

    function Window:BuildUISection(tabAPI)
        local sec = tabAPI:CreateSection({ Title = "Interface", Icon = "lucide-layout" })
        sec:CreateToggle(nil, {
            Title="Show Quick-Access Pill", Description="Floating pill buttons when UI is hidden",
            Default=true, Callback=function(val) Bubble.Visible = val end,
        })
        sec:CreateToggle("GlassMode", {
            Title="Transparent Background", Description="Semi-transparent glass-style effect",
            Default=true, Callback=function(enabled)
                Main.BackgroundTransparency    = enabled and 0.32 or 0
                Sidebar.BackgroundTransparency = enabled and 0.35 or 0
                local stroke = Main:FindFirstChildOfClass("UIStroke")
                if stroke then
                    stroke.Transparency = enabled and 0.65 or 0
                    stroke.Thickness    = enabled and 1.8  or 1.5
                end
            end,
        })
        sec:CreateButton({
            Title="Reset UI to Defaults", Description="Restores all toggles, sliders, themes, and values",
            Callback=function()
                for _, elem in pairs(Vesper.Options) do
                    if elem and elem.SetValue and elem.Default ~= nil then elem:SetValue(elem.Default) end
                end
                Vesper:SetTheme("Midnight")
                if Vesper.Options.GlassMode then Vesper.Options.GlassMode:SetValue(false) end
                Vesper:Notify({Title="UI Reset Complete",Content="Every setting restored to default state.",
                    Type="warning",Duration=4})
            end,
        })
        sec:CreateKeybind(nil, {
            Title="Toggle UI Hotkey", Description="Key that shows / hides the window",
            Default=hotkey.Name, Mode="Always",
            ChangedCallback=function(newKey) hotkey = newKey end,
        })
        return sec
    end

    return Window
end -- CreateWindow

-- ════════════════════════════════════════════════════════════════
--  GLOBAL NOTIFY
-- ════════════════════════════════════════════════════════════════
function Vesper:Notify(cfg2)
    if self._window then self._window:Notify(cfg2) end
end

-- ════════════════════════════════════════════════════════════════
--  SAVE MANAGER
-- ════════════════════════════════════════════════════════════════
Vesper.SaveManager = (function()
    local SM = { _folder="VesperConfigs", _ignored={}, _autoload=nil, _library=nil }
    local function GetWriteFile()
        if not writefile then warn("[SaveManager] writefile not available."); return false end; return true end
    local function EnsureFolder(p) if not isfolder(p) then pcall(function() makefolder(p) end) end end
    local function ConfigPath(n) return SM._folder.."/"..n..".json" end
    local function SerColor(c)   return {R=c.R,G=c.G,B=c.B} end
    local function DeserColor(t) return Color3.new(t.R,t.G,t.B) end
    function SM:SetFolder(p)    self._folder=p; EnsureFolder(p) end
    function SM:IgnoreKeys(l)   for _,k in ipairs(l) do self._ignored[k]=true end end
    SM.IgnoreThemeSettings=function() end
    function SM:SetIgnoreIndexes(l) for _,k in ipairs(l) do self._ignored[k]=true end end
    function SM:SetLibrary(lib) self._library=lib end
    function SM:_Collect()
        local data={}
        for key,elem in pairs(Vesper.Options) do
            if not (self._ignored and self._ignored[key]) then
                local val
                if elem.GetState then local ok,r=pcall(function() return elem:GetState() end); val=ok and r or elem.Value
                else val=elem.Value end
                local t=typeof(val)
                if t=="boolean" or t=="number" or t=="string" then data[key]=val
                elseif t=="table"   then data[key]=val
                elseif t=="Color3"  then data[key]=SerColor(val)
                elseif t=="EnumItem" then data[key]=val.Name end
            end
        end; return data
    end
    function SM:_Apply(data)
        for key,val in pairs(data) do
            local elem=Vesper.Options[key]
            if elem and elem.SetValue then
                if type(val)=="table" and val.R~=nil then elem:SetValue(DeserColor(val))
                else elem:SetValue(val) end end end
    end
    function SM:Save(name)
        if not GetWriteFile() then return end; EnsureFolder(self._folder)
        local ok,err=pcall(function()
            writefile(ConfigPath(name), game:GetService("HttpService"):JSONEncode(self:_Collect())) end)
        if ok then if Vesper._window then
            Vesper._window:Notify({Title="Config Saved",Content='Saved as "'..name..'"',Type="success",Duration=3}) end
        else warn("[SaveManager] Save failed:",err) end
    end
    function SM:Load(name)
        if not GetWriteFile() then return end
        local path=ConfigPath(name)
        if not isfile(path) then
            if Vesper._window then Vesper._window:Notify({Title="Config Not Found",
                Content='"'..name..'" does not exist.',Type="error",Duration=4}) end; return end
        local ok,data=pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(path)) end)
        if ok and data then self:_Apply(data)
            if Vesper._window then Vesper._window:Notify({Title="Config Loaded",
                Content='Loaded "'..name..'"',Type="success",Duration=3}) end
        else warn("[SaveManager] Load failed:",data) end
    end
    function SM:Delete(name)
        if not GetWriteFile() then return end
        local path=ConfigPath(name); if isfile(path) then pcall(function() delfile(path) end) end end
    function SM:SetAutoload(name)
        self._autoload=name; EnsureFolder(self._folder)
        pcall(function() writefile(self._folder.."/_autoload.txt",name) end)
        if Vesper._window then Vesper._window:Notify({Title="Autoload Set",
            Content='"'..name..'" will load on next inject.',Duration=3}) end end
    function SM:LoadAutoloadConfig()
        if self._autoload then self:Load(self._autoload); return end
        local path=self._folder.."/_autoload.txt"
        if not GetWriteFile() then return end
        if isfile(path) then
            local ok,name=pcall(function() return readfile(path) end)
            if ok and name and name~="" then
                self._autoload=name; task.delay(0.5,function() self:Load(name) end) end end end
    function SM:GetConfigs()
        if not GetWriteFile() then return {} end; EnsureFolder(self._folder)
        local list={}
        pcall(function()
            for _,f in ipairs(listfiles(self._folder)) do
                local name=f:match("([^/\\]+)%.json$"); if name then table.insert(list,name) end end end)
        return list end
    function SM:BuildConfigSection(tabAPI)
        local sec=tabAPI:CreateSection({Title="Configuration",Icon="lucide-save"}); local self2=self
        local nameInput=sec:CreateTextBox("_cfgName",{Title="Config Name",Placeholder="my-config",Default="default",Finished=false})
        sec:CreateButton({Title="Save Config",Description="Saves all current values",
            Callback=function() local n=nameInput:GetState(); if n and n~="" then self2:Save(n) end end})
        sec:CreateButton({Title="Load Config",Description="Loads the named config",
            Callback=function() local n=nameInput:GetState(); if n and n~="" then self2:Load(n) end end})
        sec:CreateButton({Title="Set as Autoload",Description="Automatically loads on next inject",
            Callback=function() local n=nameInput:GetState(); if n and n~="" then self2:SetAutoload(n) end end})
        sec:CreateButton({Title="Clear Autoload",Callback=function()
            self2._autoload=nil; pcall(function() delfile(self2._folder.."/_autoload.txt") end)
            if Vesper._window then Vesper._window:Notify({Title="Autoload Cleared",Duration=2}) end end})
        local function GetConfigs() return self2:GetConfigs() end
        local configDrop=sec:CreateDropdown("_cfgDrop",{Title="Saved Configs",Values=GetConfigs(),
            Multi=false, Callback=function(v) nameInput:SetValue(v) end})
        sec:CreateButton({Title="Refresh List",Callback=function() configDrop:Refresh(GetConfigs()) end})
        sec:CreateButton({Title="Delete Config",Description="Permanently deletes the named config",
            Callback=function()
                local n=nameInput:GetState()
                if n and n~="" then self2:Delete(n); configDrop:Refresh(GetConfigs())
                    if Vesper._window then Vesper._window:Notify({Title="Config Deleted",
                        Content='"'..n..'" removed.',Type="warning",Duration=3}) end end end})
    end
    return SM
end)()

-- ════════════════════════════════════════════════════════════════
--  KEY SYSTEM — ShowKeyGate(cfg)
--  Built-in key verification overlay using Junkie API.
--  • Premium key gate UI (no external libraries)
--  • Key input + Verify / Copy-Link buttons
--  • KEY_VALID / KEYLESS support
--  • Saved key auto-login
--  • Smooth unlock animation
--  • getgenv().SCRIPT_KEY blocking loop compatible
-- ════════════════════════════════════════════════════════════════
function Vesper:ShowKeyGate(cfg)
    cfg = cfg or {}
    local Junkie     = cfg.Junkie      or error("[VesperKey] Junkie SDK required")
    local gateTitle  = cfg.Title       or "Vesper Hub"
    local gateSub    = cfg.Subtitle    or "Enter your key to continue"
    local saveKey    = cfg.SaveKey     ~= false
    local saveFolder = cfg.SaveFolder  or "VesperHub"
    local onSuccess  = cfg.OnSuccess   or function() end

    local T = Vesper.Theme or Themes.Midnight

    -- ── File-based key persistence ─────────────────────────────
    local KEY_FILE = saveFolder .. "/saved_key.txt"
    local function EnsureFolderK(path)
        if not isfolder then return end
        if not isfolder(path) then pcall(makefolder, path) end
    end
    local function SaveKeyFile(key)
        if not saveKey or not writefile then return end
        EnsureFolderK(saveFolder)
        pcall(function() writefile(KEY_FILE, key) end)
    end
    local function LoadSavedKey()
        if not saveKey or not readfile or not isfile then return nil end
        if not isfile(KEY_FILE) then return nil end
        local ok, data = pcall(readfile, KEY_FILE)
        if ok and data and data ~= "" then return data end
        return nil
    end

    -- ── ScreenGui ──────────────────────────────────────────────
    local gui_parent = (pcall(function() return gethui() end) and gethui()) or CoreGui
    if not gui_parent then gui_parent = LP:WaitForChild("PlayerGui") end
    for _, v in pairs(gui_parent:GetChildren()) do
        if v.Name == "VesperKeyGate" then v:Destroy() end
    end

    local KScreen = Instance.new("ScreenGui")
    KScreen.Name           = "VesperKeyGate"
    KScreen.Parent         = gui_parent
    KScreen.ResetOnSpawn   = false
    KScreen.DisplayOrder   = 10000
    KScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- ── Overlay (dark backdrop with floating dots) ──────────────
    local Overlay = Instance.new("Frame", KScreen)
    Overlay.BackgroundColor3       = Color3.fromRGB(2, 2, 8)
    Overlay.BackgroundTransparency = 0
    Overlay.Size                   = UDim2.new(1, 0, 1, 0)
    Overlay.ZIndex                 = 1

    -- Full-screen input blocker — prevents interaction with anything behind key gate
    local InputBlocker = Instance.new("TextButton", KScreen)
    InputBlocker.BackgroundTransparency = 1
    InputBlocker.Size            = UDim2.new(1, 0, 1, 0)
    InputBlocker.Text            = ""
    InputBlocker.ZIndex          = 2
    InputBlocker.AutoButtonColor = false
    InputBlocker.Active          = true

    task.spawn(function()
        for i = 1, 25 do
            local dot = Instance.new("Frame", Overlay)
            dot.BackgroundColor3       = T.Accent
            dot.BackgroundTransparency = math.random(85, 95) / 100
            dot.AnchorPoint            = Vector2.new(0.5, 0.5)
            local sz = math.random(2, 5)
            dot.Size     = UDim2.new(0, sz, 0, sz)
            dot.Position = UDim2.new(math.random() * 1, 0, math.random() * 1, 0)
            dot.ZIndex   = 2
            AddCorner(dot, 100)
            task.spawn(function()
                while dot and dot.Parent do
                    TweenPlay(dot, {Position = UDim2.new(math.random(), 0, math.random(), 0)},
                        math.random(8, 20), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(math.random(8, 20))
                end
            end)
        end
    end)

    -- ── Card ───────────────────────────────────────────────────
    local Card = Instance.new("Frame", KScreen)
    Card.BackgroundColor3       = T.Surface
    Card.BackgroundTransparency = 0.05
    Card.AnchorPoint            = Vector2.new(0.5, 0.5)
    Card.Position               = UDim2.new(0.5, 0, 0.5, 0)
    Card.Size                   = UDim2.new(0, 420, 0, 380)
    Card.ZIndex                 = 10
    Card.ClipsDescendants       = false
    AddCorner(Card, 14)
    local CardStroke = AddStroke(Card, T.Border, 1.5)

    local CardGlow = Instance.new("ImageLabel", Card)
    CardGlow.BackgroundTransparency = 1
    CardGlow.Position          = UDim2.new(0, -50, 0, -50)
    CardGlow.Size              = UDim2.new(1, 100, 1, 100)
    CardGlow.Image             = "rbxassetid://4996891970"
    CardGlow.ImageColor3       = T.Accent
    CardGlow.ImageTransparency = 0.78
    CardGlow.ZIndex            = 9

    local CardScale = Instance.new("UIScale", Card); CardScale.Scale = 0
    TweenPlay(CardScale, {Scale = 1}, 0.55, Enum.EasingStyle.Back)

    -- Top accent bar
    local TopAccent = Instance.new("Frame", Card)
    TopAccent.BackgroundColor3 = T.Accent
    TopAccent.Size             = UDim2.new(1, 0, 0, 3)
    TopAccent.BorderSizePixel  = 0
    TopAccent.ZIndex           = 11
    AddCorner(TopAccent, 14)

    -- Logo
    local LogoCont = Instance.new("Frame", Card)
    LogoCont.BackgroundTransparency = 1
    LogoCont.AnchorPoint = Vector2.new(0.5, 0)
    LogoCont.Position    = UDim2.new(0.5, 0, 0, 24)
    LogoCont.Size        = UDim2.new(0, 64, 0, 64)
    LogoCont.ZIndex      = 11
    LogoCont.ClipsDescendants = true
    AddCorner(LogoCont, 100)

    local LogoGlowK = Instance.new("ImageLabel", LogoCont)
    LogoGlowK.BackgroundTransparency = 1
    LogoGlowK.Position          = UDim2.new(0, -8, 0, -8)
    LogoGlowK.Size              = UDim2.new(1, 16, 1, 16)
    LogoGlowK.Image             = "rbxassetid://4996891970"
    LogoGlowK.ImageColor3       = T.Accent
    LogoGlowK.ImageTransparency = 0.5
    LogoGlowK.ZIndex            = 10

    do
        local imgPx    = math.ceil(64 / LOGO_FILL)
        local overflow = imgPx - 64
        local img = Instance.new("ImageLabel", LogoCont)
        img.BackgroundTransparency = 1
        img.Size     = UDim2.new(0, imgPx, 0, imgPx)
        img.Position = UDim2.new(0, -overflow / 2, 0, -overflow / 2)
        img.Image    = LOGO_ASSET_ID
        img.ScaleType= Enum.ScaleType.Fit
        img.ZIndex   = 12
    end

    -- Pulsing logo glow
    task.spawn(function()
        while LogoGlowK and LogoGlowK.Parent do
            TweenPlay(LogoGlowK, {ImageTransparency = 0.3}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.5)
            TweenPlay(LogoGlowK, {ImageTransparency = 0.7}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.5)
        end
    end)

    -- Title
    local KTitle = Instance.new("TextLabel", Card)
    KTitle.BackgroundTransparency = 1; KTitle.AnchorPoint = Vector2.new(0.5, 0)
    KTitle.Position = UDim2.new(0.5, 0, 0, 96); KTitle.Size = UDim2.new(0.9, 0, 0, 24)
    KTitle.Font = Enum.Font.GothamBold; KTitle.Text = gateTitle
    KTitle.TextColor3 = T.Text; KTitle.TextSize = 20; KTitle.ZIndex = 11

    local KSub = Instance.new("TextLabel", Card)
    KSub.BackgroundTransparency = 1; KSub.AnchorPoint = Vector2.new(0.5, 0)
    KSub.Position = UDim2.new(0.5, 0, 0, 122); KSub.Size = UDim2.new(0.9, 0, 0, 16)
    KSub.Font = Enum.Font.Gotham; KSub.Text = gateSub
    KSub.TextColor3 = T.SubText; KSub.TextSize = 12; KSub.ZIndex = 11

    -- Divider
    local KDiv1 = Instance.new("Frame", Card)
    KDiv1.BackgroundColor3 = T.Border; KDiv1.AnchorPoint = Vector2.new(0.5, 0)
    KDiv1.Position = UDim2.new(0.5, 0, 0, 148); KDiv1.Size = UDim2.new(0.85, 0, 0, 1)
    KDiv1.BorderSizePixel = 0; KDiv1.ZIndex = 11

    -- Key input
    local InputBg = Instance.new("Frame", Card)
    InputBg.BackgroundColor3 = T.InputBg; InputBg.AnchorPoint = Vector2.new(0.5, 0)
    InputBg.Position = UDim2.new(0.5, 0, 0, 164); InputBg.Size = UDim2.new(0.85, 0, 0, 42)
    InputBg.ZIndex = 11; AddCorner(InputBg, 8)
    local KInputStroke = AddStroke(InputBg, T.Border, 1)

    local KIcon = Instance.new("ImageLabel", InputBg)
    KIcon.BackgroundTransparency = 1; KIcon.AnchorPoint = Vector2.new(0, 0.5)
    KIcon.Position = UDim2.new(0, 12, 0.5, 0); KIcon.Size = UDim2.new(0, 18, 0, 18)
    KIcon.Image = Icon("lucide-key-round"); KIcon.ImageColor3 = T.Muted; KIcon.ZIndex = 12

    local KBox = Instance.new("TextBox", InputBg)
    KBox.BackgroundTransparency = 1; KBox.Position = UDim2.new(0, 38, 0, 0)
    KBox.Size = UDim2.new(1, -46, 1, 0); KBox.Font = Enum.Font.Gotham
    KBox.PlaceholderText = "Paste your key here..."; KBox.PlaceholderColor3 = T.Muted
    KBox.Text = ""; KBox.TextColor3 = T.Text; KBox.TextSize = 13
    KBox.ClearTextOnFocus = false; KBox.ZIndex = 12

    KBox.Focused:Connect(function()
        TweenPlay(KInputStroke, {Color = T.Accent}, 0.2)
        TweenPlay(KIcon, {ImageColor3 = T.Accent}, 0.2)
    end)
    KBox.FocusLost:Connect(function()
        TweenPlay(KInputStroke, {Color = T.Border}, 0.2)
        TweenPlay(KIcon, {ImageColor3 = T.Muted}, 0.2)
    end)

    -- Status label
    local KStatus = Instance.new("TextLabel", Card)
    KStatus.BackgroundTransparency = 1; KStatus.AnchorPoint = Vector2.new(0.5, 0)
    KStatus.Position = UDim2.new(0.5, 0, 0, 214); KStatus.Size = UDim2.new(0.85, 0, 0, 16)
    KStatus.Font = Enum.Font.Gotham; KStatus.Text = ""; KStatus.TextColor3 = T.SubText
    KStatus.TextSize = 11; KStatus.ZIndex = 11; KStatus.TextXAlignment = Enum.TextXAlignment.Left

    local function KSetStatus(text, color, duration)
        KStatus.Text = text; KStatus.TextColor3 = color or T.SubText
        if duration then
            task.delay(duration, function()
                if KStatus.Text == text then
                    TweenPlay(KStatus, {TextColor3 = T.Muted}, 0.3)
                    task.delay(0.5, function()
                        if KStatus.Text == text then KStatus.Text = "" end
                    end)
                end
            end)
        end
    end

    -- Buttons
    local KBtnFrame = Instance.new("Frame", Card)
    KBtnFrame.BackgroundTransparency = 1; KBtnFrame.AnchorPoint = Vector2.new(0.5, 0)
    KBtnFrame.Position = UDim2.new(0.5, 0, 0, 240); KBtnFrame.Size = UDim2.new(0.85, 0, 0, 42)
    KBtnFrame.ZIndex = 11
    local KBtnLayout = Instance.new("UIListLayout", KBtnFrame)
    KBtnLayout.FillDirection = Enum.FillDirection.Horizontal; KBtnLayout.Padding = UDim.new(0, 10)
    KBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    KBtnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    KBtnLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function MakeKBtn(text, icon, color, width, order)
        local Btn = Instance.new("TextButton", KBtnFrame)
        Btn.BackgroundColor3 = color; Btn.Size = UDim2.new(0, width, 0, 38)
        Btn.Text = ""; Btn.AutoButtonColor = false; Btn.ZIndex = 12
        Btn.LayoutOrder = order; Btn.ClipsDescendants = true; AddCorner(Btn, 8)
        AddStroke(Btn, Color3.new(math.min(color.R*1.3,1), math.min(color.G*1.3,1), math.min(color.B*1.3,1)), 1, 0.5)
        if icon then
            local Ico = Instance.new("ImageLabel", Btn)
            Ico.BackgroundTransparency = 1; Ico.AnchorPoint = Vector2.new(0, 0.5)
            Ico.Position = UDim2.new(0, 12, 0.5, 0); Ico.Size = UDim2.new(0, 16, 0, 16)
            Ico.Image = Icon(icon); Ico.ImageColor3 = Color3.new(1,1,1); Ico.ZIndex = 13
        end
        local Lbl = Instance.new("TextLabel", Btn)
        Lbl.BackgroundTransparency = 1; Lbl.Position = UDim2.new(0, icon and 34 or 0, 0, 0)
        Lbl.Size = UDim2.new(1, icon and -42 or 0, 1, 0); Lbl.Font = Enum.Font.GothamBold
        Lbl.Text = text; Lbl.TextColor3 = Color3.new(1,1,1); Lbl.TextSize = 13; Lbl.ZIndex = 13
        local hc = Color3.new(math.min(color.R*1.15,1), math.min(color.G*1.15,1), math.min(color.B*1.15,1))
        Btn.MouseEnter:Connect(function() TweenPlay(Btn, {BackgroundColor3 = hc}, 0.12) end)
        Btn.MouseLeave:Connect(function() TweenPlay(Btn, {BackgroundColor3 = color}, 0.15) end)
        return Btn
    end

    local VerifyBtn = MakeKBtn("Verify Key", "lucide-shield-check", T.Accent, 165, 1)
    local CopyBtn   = MakeKBtn("Get Key",    "lucide-link",         T.SurfaceHigh, 155, 2)

    -- Bottom divider
    local KDiv2 = Instance.new("Frame", Card)
    KDiv2.BackgroundColor3 = T.Border; KDiv2.AnchorPoint = Vector2.new(0.5, 0)
    KDiv2.Position = UDim2.new(0.5, 0, 0, 296); KDiv2.Size = UDim2.new(0.85, 0, 0, 1)
    KDiv2.BorderSizePixel = 0; KDiv2.ZIndex = 11

    local KInfo = Instance.new("TextLabel", Card)
    KInfo.BackgroundTransparency = 1; KInfo.AnchorPoint = Vector2.new(0.5, 0)
    KInfo.Position = UDim2.new(0.5, 0, 0, 308); KInfo.Size = UDim2.new(0.85, 0, 0, 14)
    KInfo.Font = Enum.Font.Gotham; KInfo.Text = "Need help? Join our Discord server"
    KInfo.TextColor3 = T.Muted; KInfo.TextSize = 10; KInfo.ZIndex = 11

    local KPowered = Instance.new("TextLabel", Card)
    KPowered.BackgroundTransparency = 1; KPowered.AnchorPoint = Vector2.new(0.5, 1)
    KPowered.Position = UDim2.new(0.5, 0, 1, -12); KPowered.Size = UDim2.new(0.85, 0, 0, 12)
    KPowered.Font = Enum.Font.Gotham; KPowered.RichText = true
    KPowered.Text = '<font color="rgb(118,112,182)">Powered by </font><font color="rgb(132,98,255)">Vesper</font><font color="rgb(118,112,182)"> × Junkie</font>'
    KPowered.TextColor3 = T.Muted; KPowered.TextSize = 9; KPowered.ZIndex = 11

    -- ── Inline notification toasts ─────────────────────────────
    local KNotifHolder = Instance.new("Frame", KScreen)
    KNotifHolder.BackgroundTransparency = 1; KNotifHolder.AnchorPoint = Vector2.new(1, 0)
    KNotifHolder.Position = UDim2.new(1, -16, 0, 16); KNotifHolder.Size = UDim2.new(0, 300, 0, 0)
    KNotifHolder.AutomaticSize = Enum.AutomaticSize.Y; KNotifHolder.ZIndex = 20
    AddList(KNotifHolder, 8)

    local function KNotify(ntitle, ncontent, ntype, nduration)
        nduration = nduration or 4
        local accent = ({success=T.Positive, error=T.Negative, warning=T.Warning, info=T.Accent})[ntype] or T.Accent
        local nicon  = ({success="lucide-check-circle", error="lucide-x-circle", warning="lucide-alert-triangle", info="lucide-info"})[ntype] or "lucide-bell"
        local textH   = TextService:GetTextSize(ncontent, 11, Enum.Font.Gotham, Vector2.new(240, 9999)).Y
        local targetH = math.max(52, textH + 40)
        local N = Instance.new("Frame", KNotifHolder)
        N.BackgroundColor3 = T.Surface; N.BorderSizePixel = 0
        N.Size = UDim2.new(1, 0, 0, 0); N.ClipsDescendants = true; N.ZIndex = 21
        AddCorner(N, 8); AddStroke(N, accent, 1, 0.4)
        local NLine = Instance.new("Frame", N); NLine.BackgroundColor3 = accent
        NLine.Size = UDim2.new(1, 0, 0, 2); NLine.BorderSizePixel = 0; NLine.ZIndex = 22
        local NBar = Instance.new("Frame", N); NBar.BackgroundColor3 = accent
        NBar.Size = UDim2.new(0, 3, 1, 0); NBar.BorderSizePixel = 0; NBar.ZIndex = 22; AddCorner(NBar, 4)
        local NI = Instance.new("ImageLabel", N); NI.BackgroundTransparency = 1
        NI.Position = UDim2.new(0, 12, 0, 10); NI.Size = UDim2.new(0, 16, 0, 16)
        NI.Image = Icon(nicon); NI.ImageColor3 = accent; NI.ZIndex = 22
        local NT = Instance.new("TextLabel", N); NT.BackgroundTransparency = 1
        NT.Position = UDim2.new(0, 34, 0, 8); NT.Size = UDim2.new(1, -42, 0, 16)
        NT.Font = Enum.Font.GothamBold; NT.Text = ntitle; NT.TextColor3 = T.Text
        NT.TextSize = 12; NT.TextXAlignment = Enum.TextXAlignment.Left; NT.ZIndex = 22
        local NC = Instance.new("TextLabel", N); NC.BackgroundTransparency = 1
        NC.Position = UDim2.new(0, 34, 0, 26); NC.Size = UDim2.new(1, -42, 0, textH)
        NC.Font = Enum.Font.Gotham; NC.Text = ncontent; NC.TextColor3 = T.SubText
        NC.TextSize = 11; NC.TextWrapped = true; NC.TextXAlignment = Enum.TextXAlignment.Left; NC.ZIndex = 22
        local PBase = Instance.new("Frame", N); PBase.BackgroundColor3 = T.Track
        PBase.AnchorPoint = Vector2.new(0, 1); PBase.Position = UDim2.new(0, 6, 1, -4)
        PBase.Size = UDim2.new(1, -12, 0, 2); PBase.BorderSizePixel = 0; PBase.ZIndex = 22; AddCorner(PBase, 100)
        local PFill = Instance.new("Frame", PBase); PFill.BackgroundColor3 = accent
        PFill.BorderSizePixel = 0; PFill.Size = UDim2.new(1, 0, 1, 0); PFill.ZIndex = 23; AddCorner(PFill, 100)
        TweenPlay(N, {Size = UDim2.new(1, 0, 0, targetH)}, 0.3, Enum.EasingStyle.Back)
        TweenPlay(PFill, {Size = UDim2.new(0, 0, 1, 0)}, nduration - 0.3, Enum.EasingStyle.Linear)
        task.delay(nduration, function()
            TweenPlay(N, {Size = UDim2.new(1, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quint)
            task.delay(0.25, function() N:Destroy() end)
        end)
    end

    -- ── Unlock animation ───────────────────────────────────────
    local kVerified = false

    local function KUnlock(mode)
        kVerified = true
        TweenPlay(CardStroke, {Color = T.Positive}, 0.3)
        TweenPlay(TopAccent, {BackgroundColor3 = T.Positive}, 0.3)
        KSetStatus("✓  Key verified — " .. (mode or "KEY_VALID"), T.Positive)
        KNotify("Access Granted",
            (mode == "KEYLESS" and "Keyless mode activated" or "Key verified successfully") .. ". Loading UI...",
            "success", 4)
        KBox.TextEditable = false; VerifyBtn.Active = false; CopyBtn.Active = false
        TweenPlay(VerifyBtn, {BackgroundColor3 = T.Positive}, 0.3)
        task.delay(1.5, function()
            TweenPlay(CardScale, {Scale = 0.85}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            TweenPlay(Card, {BackgroundTransparency = 1}, 0.4)
            TweenPlay(CardStroke, {Transparency = 1}, 0.3)
            TweenPlay(CardGlow, {ImageTransparency = 1}, 0.3)
            TweenPlay(Overlay, {BackgroundTransparency = 1}, 0.5)
            for _, desc in ipairs(Card:GetDescendants()) do
                pcall(function()
                    if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                        TweenPlay(desc, {TextTransparency = 1}, 0.3) end
                    if desc:IsA("ImageLabel") then
                        TweenPlay(desc, {ImageTransparency = 1}, 0.3) end
                    if desc:IsA("Frame") and desc.BackgroundTransparency < 1 then
                        TweenPlay(desc, {BackgroundTransparency = 1}, 0.3) end
                    if desc:IsA("UIStroke") then
                        TweenPlay(desc, {Transparency = 1}, 0.3) end
                end)
            end
            task.delay(0.6, function() KScreen:Destroy() end)
        end)
    end

    -- ── Verify logic ───────────────────────────────────────────
    local kVerifying = false
    local function KDoVerify(key)
        if kVerifying or kVerified then return end
        if not key or key == "" then
            KSetStatus("⚠  Please enter a key", T.Warning, 3)
            KNotify("Missing Key", "Please enter your key before verifying.", "warning", 3)
            local origPos = InputBg.Position
            for i = 1, 4 do
                TweenPlay(InputBg, {Position = origPos + UDim2.new(0, (i%2==0 and 4 or -4), 0, 0)}, 0.04, Enum.EasingStyle.Linear)
                task.wait(0.04)
            end
            TweenPlay(InputBg, {Position = origPos}, 0.06)
            return
        end
        kVerifying = true
        KSetStatus("⏳  Verifying key...", T.Accent)
        TweenPlay(VerifyBtn, {BackgroundColor3 = T.AccentDim}, 0.08)
        task.delay(0.1, function()
            if not kVerified then TweenPlay(VerifyBtn, {BackgroundColor3 = T.Accent}, 0.15) end
        end)
        task.spawn(function()
            local ok, result = pcall(function() return Junkie.check_key(key) end)
            if not ok then
                kVerifying = false
                KSetStatus("✕  Network error — try again", T.Negative, 5)
                KNotify("Error", "Could not reach verification server.", "error", 5)
                return
            end
            if result and result.valid then
                local message = result.message or ""
                if message == "KEYLESS" then
                    getgenv().SCRIPT_KEY = "KEYLESS"; SaveKeyFile("KEYLESS")
                    task.spawn(onSuccess, "KEYLESS", "KEYLESS"); KUnlock("KEYLESS")
                elseif message == "KEY_VALID" then
                    getgenv().SCRIPT_KEY = key; SaveKeyFile(key)
                    task.spawn(onSuccess, key, "KEY_VALID"); KUnlock("KEY_VALID")
                else
                    getgenv().SCRIPT_KEY = key; SaveKeyFile(key)
                    task.spawn(onSuccess, key, message); KUnlock(message)
                end
            else
                kVerifying = false
                local errMsg = (result and result.message) or (result and result.error) or "Invalid key"
                KSetStatus("✕  " .. errMsg, T.Negative, 5)
                KNotify("Invalid Key", errMsg .. ". Check your key and try again.", "error", 5)
                TweenPlay(KInputStroke, {Color = T.Negative}, 0.15)
                task.delay(1.5, function()
                    if not kVerified then TweenPlay(KInputStroke, {Color = T.Border}, 0.3) end
                end)
            end
        end)
    end

    -- ── Copy link logic ────────────────────────────────────────
    local kCopying = false
    local function KDoCopy()
        if kCopying or kVerified then return end
        kCopying = true; KSetStatus("⏳  Getting key link...", T.Accent)
        TweenPlay(CopyBtn, {BackgroundColor3 = T.AccentDim}, 0.08)
        task.delay(0.15, function() TweenPlay(CopyBtn, {BackgroundColor3 = T.SurfaceHigh}, 0.15) end)
        task.spawn(function()
            local ok, link, err = pcall(function() return Junkie.get_key_link() end)
            if not ok then
                kCopying = false; KSetStatus("✕  Could not get link", T.Negative, 4)
                KNotify("Error", "Failed to fetch key link.", "error", 4); return
            end
            if link then
                pcall(function() if setclipboard then setclipboard(link) end end)
                KSetStatus("✓  Link copied to clipboard!", T.Positive, 5)
                KNotify("Link Copied", "Complete the steps, then paste your key.", "success", 6)
            else
                KSetStatus("✕  " .. (err or "Failed"), T.Negative, 4)
                KNotify("Error", err or "Could not retrieve link.", "error", 4)
            end
            kCopying = false
        end)
    end

    -- ── Connect buttons ────────────────────────────────────────
    VerifyBtn.MouseButton1Click:Connect(function() KDoVerify(KBox.Text) end)
    KBox.FocusLost:Connect(function(enter) if enter then KDoVerify(KBox.Text) end end)
    CopyBtn.MouseButton1Click:Connect(function() KDoCopy() end)

    -- ── Auto-login ─────────────────────────────────────────────
    task.spawn(function()
        local saved = LoadSavedKey()
        if saved and saved ~= "" then
            KBox.Text = saved
            KSetStatus("🔑  Saved key found — auto-verifying...", T.Accent)
            KNotify("Auto-Login", "Found saved key. Verifying...", "info", 3)
            task.wait(0.8)
            KDoVerify(saved)
        end
    end)

    return KScreen
end

return Vesper
--[[
USAGE:
local Vesper      = loadstring(game:HttpGet("YOUR_RAW_URL"))()
local SaveManager = Vesper.SaveManager

-- Set your Discord link at the top of this file:  DISCORD_LINK = "https://discord.gg/yourserver"

local Window = Vesper:CreateWindow({
    Title = 'Vesper Hub <font color="rgb(139,92,246)">v3</font>',
    Subtitle = "by you",
    MinimizeKey = Enum.KeyCode.RightControl,
    Tag = "Premium Build",
})

local Tabs = {
    Main     = Window:AddTab({ Title="Main",     Icon="lucide-home"     }),
    Combat   = Window:AddTab({ Title="Combat",   Icon="lucide-swords"   }),
    Settings = Window:AddTab({ Title="Settings", Icon="lucide-settings" }),
}

local General = Tabs.Main:CreateSection({ Title="General", Icon="lucide-zap" })
General:CreateParagraph({ Title="Welcome", Content="Vesper v3.3" })
General:CreateToggle("SpeedHack",{ Title="Speed Hack", Default=false, Callback=function(s) end })
General:CreateSlider("SpeedValue",{ Title="Walk Speed", Default=16, Min=16, Max=500, Suffix=" sp" })

SaveManager:SetFolder("VesperHub/MyGame")
SaveManager:SetIgnoreIndexes({"_cfgName","_cfgDrop"})
SaveManager:BuildConfigSection(Tabs.Settings)
Window:BuildUISection(Tabs.Settings)
Window:SelectTab(1)
Vesper:Notify({Title="Vesper Loaded",Content="Injected.",Type="success",Duration=6})
SaveManager:LoadAutoloadConfig()
]]
