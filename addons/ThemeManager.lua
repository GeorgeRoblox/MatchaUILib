--!strict
-- ZenithUiLib - ThemeManager.lua
-- Handles themes, accent colors, and applying styles to controls

local ThemeManager = {}
ThemeManager.__index = ThemeManager

export type Theme = {
    Name: string,
    BackgroundLayer1: Color3,
    BackgroundLayer2: Color3,
    BackgroundLayer3: Color3,
    BackgroundLayer4: Color3,
    BackgroundLayer5: Color3,
    Outline: Color3,
    OutlineMuted: Color3,
    Text: Color3,
    TextMuted: Color3,
    Accent: Color3,
    AccentHover: Color3,
    ScrollBar: Color3,
}

local themes: {[string]: Theme} = {}

local function defineTheme(theme: Theme)
    themes[theme.Name] = theme
end

-- Built-in themes

defineTheme({
    Name = "Dark",
    BackgroundLayer1 = Color3.fromRGB(16, 18, 22),
    BackgroundLayer2 = Color3.fromRGB(20, 22, 26),
    BackgroundLayer3 = Color3.fromRGB(24, 26, 30),
    BackgroundLayer4 = Color3.fromRGB(30, 32, 36),
    BackgroundLayer5 = Color3.fromRGB(40, 42, 46),
    Outline = Color3.fromRGB(60, 64, 72),
    OutlineMuted = Color3.fromRGB(40, 44, 52),
    Text = Color3.fromRGB(230, 235, 240),
    TextMuted = Color3.fromRGB(150, 155, 165),
    Accent = Color3.fromRGB(45, 140, 255),
    AccentHover = Color3.fromRGB(65, 160, 255),
    ScrollBar = Color3.fromRGB(80, 85, 95),
})

defineTheme({
    Name = "Darker",
    BackgroundLayer1 = Color3.fromRGB(10, 12, 14),
    BackgroundLayer2 = Color3.fromRGB(14, 16, 18),
    BackgroundLayer3 = Color3.fromRGB(18, 20, 22),
    BackgroundLayer4 = Color3.fromRGB(22, 24, 26),
    BackgroundLayer5 = Color3.fromRGB(28, 30, 32),
    Outline = Color3.fromRGB(50, 54, 60),
    OutlineMuted = Color3.fromRGB(36, 40, 46),
    Text = Color3.fromRGB(230, 235, 240),
    TextMuted = Color3.fromRGB(150, 155, 165),
    Accent = Color3.fromRGB(45, 140, 255),
    AccentHover = Color3.fromRGB(65, 160, 255),
    ScrollBar = Color3.fromRGB(80, 85, 95),
})

defineTheme({
    Name = "Light",
    BackgroundLayer1 = Color3.fromRGB(235, 238, 242),
    BackgroundLayer2 = Color3.fromRGB(245, 248, 252),
    BackgroundLayer3 = Color3.fromRGB(255, 255, 255),
    BackgroundLayer4 = Color3.fromRGB(240, 243, 247),
    BackgroundLayer5 = Color3.fromRGB(230, 233, 237),
    Outline = Color3.fromRGB(200, 205, 215),
    OutlineMuted = Color3.fromRGB(210, 215, 225),
    Text = Color3.fromRGB(40, 45, 55),
    TextMuted = Color3.fromRGB(110, 115, 125),
    Accent = Color3.fromRGB(45, 140, 255),
    AccentHover = Color3.fromRGB(65, 160, 255),
    ScrollBar = Color3.fromRGB(150, 155, 165),
})

defineTheme({
    Name = "Midnight",
    BackgroundLayer1 = Color3.fromRGB(8, 10, 18),
    BackgroundLayer2 = Color3.fromRGB(12, 14, 22),
    BackgroundLayer3 = Color3.fromRGB(16, 18, 26),
    BackgroundLayer4 = Color3.fromRGB(20, 22, 30),
    BackgroundLayer5 = Color3.fromRGB(26, 28, 36),
    Outline = Color3.fromRGB(60, 64, 80),
    OutlineMuted = Color3.fromRGB(40, 44, 60),
    Text = Color3.fromRGB(230, 235, 240),
    TextMuted = Color3.fromRGB(150, 155, 165),
    Accent = Color3.fromRGB(45, 140, 255),
    AccentHover = Color3.fromRGB(65, 160, 255),
    ScrollBar = Color3.fromRGB(80, 85, 95),
})

defineTheme({
    Name = "Purple",
    BackgroundLayer1 = Color3.fromRGB(18, 16, 24),
    BackgroundLayer2 = Color3.fromRGB(24, 20, 32),
    BackgroundLayer3 = Color3.fromRGB(30, 24, 40),
    BackgroundLayer4 = Color3.fromRGB(36, 28, 48),
    BackgroundLayer5 = Color3.fromRGB(42, 32, 56),
    Outline = Color3.fromRGB(80, 60, 110),
    OutlineMuted = Color3.fromRGB(60, 44, 90),
    Text = Color3.fromRGB(235, 235, 245),
    TextMuted = Color3.fromRGB(170, 170, 190),
    Accent = Color3.fromRGB(160, 90, 255),
    AccentHover = Color3.fromRGB(180, 110, 255),
    ScrollBar = Color3.fromRGB(110, 90, 140),
})

defineTheme({
    Name = "Emerald",
    BackgroundLayer1 = Color3.fromRGB(12, 18, 16),
    BackgroundLayer2 = Color3.fromRGB(16, 24, 20),
    BackgroundLayer3 = Color3.fromRGB(20, 30, 24),
    BackgroundLayer4 = Color3.fromRGB(24, 36, 28),
    BackgroundLayer5 = Color3.fromRGB(30, 42, 34),
    Outline = Color3.fromRGB(60, 90, 80),
    OutlineMuted = Color3.fromRGB(44, 70, 60),
    Text = Color3.fromRGB(230, 240, 235),
    TextMuted = Color3.fromRGB(160, 170, 165),
    Accent = Color3.fromRGB(60, 190, 140),
    AccentHover = Color3.fromRGB(80, 210, 160),
    ScrollBar = Color3.fromRGB(90, 120, 110),
})

defineTheme({
    Name = "Crimson",
    BackgroundLayer1 = Color3.fromRGB(20, 12, 14),
    BackgroundLayer2 = Color3.fromRGB(26, 16, 18),
    BackgroundLayer3 = Color3.fromRGB(32, 20, 22),
    BackgroundLayer4 = Color3.fromRGB(38, 24, 26),
    BackgroundLayer5 = Color3.fromRGB(44, 28, 30),
    Outline = Color3.fromRGB(90, 60, 70),
    OutlineMuted = Color3.fromRGB(70, 44, 54),
    Text = Color3.fromRGB(235, 230, 230),
    TextMuted = Color3.fromRGB(175, 160, 160),
    Accent = Color3.fromRGB(220, 70, 90),
    AccentHover = Color3.fromRGB(240, 90, 110),
    ScrollBar = Color3.fromRGB(120, 80, 90),
})

defineTheme({
    Name = "Ocean",
    BackgroundLayer1 = Color3.fromRGB(10, 16, 22),
    BackgroundLayer2 = Color3.fromRGB(14, 20, 26),
    BackgroundLayer3 = Color3.fromRGB(18, 24, 30),
    BackgroundLayer4 = Color3.fromRGB(22, 28, 34),
    BackgroundLayer5 = Color3.fromRGB(26, 32, 38),
    Outline = Color3.fromRGB(60, 80, 100),
    OutlineMuted = Color3.fromRGB(44, 64, 84),
    Text = Color3.fromRGB(230, 235, 240),
    TextMuted = Color3.fromRGB(150, 160, 170),
    Accent = Color3.fromRGB(45, 140, 255),
    AccentHover = Color3.fromRGB(65, 160, 255),
    ScrollBar = Color3.fromRGB(90, 110, 130),
})

local currentTheme: Theme = themes["Dark"]
local accentOverride: Color3? = nil

function ThemeManager:SetTheme(name: string)
    local theme = themes[name]
    if theme then
        currentTheme = theme
    end
end

function ThemeManager:SetAccent(color: Color3)
    accentOverride = color
end

function ThemeManager:GetTheme(name: string?): Theme
    local theme = name and themes[name] or currentTheme
    if accentOverride then
        theme = table.clone(theme)
        theme.Accent = accentOverride
        theme.AccentHover = accentOverride:Lerp(Color3.new(1, 1, 1), 0.2)
    end
    return theme
end

function ThemeManager:Apply(window: any)
    -- Window already pulls theme via ThemeManager:GetTheme
    -- This function exists for API completeness and future per-control updates.
end

return ThemeManager
