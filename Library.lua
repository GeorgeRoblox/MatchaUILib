--!strict
-- ZenithUiLib - Library.lua
-- Main UI framework, window/tabs/sections/controls
-- Completely original implementation, desktop-inspired aesthetic

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

export type WindowOptions = {
    Title: string,
    Size: UDim2,
    Theme: string,
    Center: boolean?,
    Draggable: boolean?,
    Acrylic: boolean?,
}

export type ControlCallback<T> = (value: T) -> ()

export type LibraryType = {
    CreateWindow: (self: LibraryType, options: WindowOptions) -> WindowType,
    Notify: (self: LibraryType, data: NotificationData) -> (),
    Watermark: (self: LibraryType, text: string) -> (),
    SetThemeManager: (self: LibraryType, tm: any) -> (),
    GetThemeManager: (self: LibraryType) -> any,
}

export type WindowType = {
    AddTab: (self: WindowType, name: string, icon: string?) -> TabType,
    SetWatermark: (self: WindowType, text: string) -> (),
    SetFPSCounter: (self: WindowType, enabled: boolean) -> (),
    SetSearchBar: (self: WindowType, enabled: boolean) -> (),
    Minimize: (self: WindowType) -> (),
    Close: (self: WindowType) -> (),
    GetScreenGui: (self: WindowType) -> ScreenGui,
}

export type TabType = {
    AddLeftSection: (self: TabType, name: string) -> SectionType,
    AddRightSection: (self: TabType, name: string) -> SectionType,
    SetIcon: (self: TabType, icon: string?) -> (),
}

export type SectionType = {
    AddButton: (self: SectionType, data: ButtonData) -> ButtonControl,
    AddToggle: (self: SectionType, data: ToggleData) -> ToggleControl,
    AddSlider: (self: SectionType, data: SliderData) -> SliderControl,
    AddDropdown: (self: SectionType, data: DropdownData) -> DropdownControl,
    AddMultiDropdown: (self: SectionType, data: MultiDropdownData) -> MultiDropdownControl,
    AddColorPicker: (self: SectionType, data: ColorPickerData) -> ColorPickerControl,
    AddKeybind: (self: SectionType, data: KeybindData) -> KeybindControl,
    AddTextbox: (self: SectionType, data: TextboxData) -> TextboxControl,
    AddLabel: (self: SectionType, text: string) -> LabelControl,
    AddParagraph: (self: SectionType, text: string) -> ParagraphControl,
    AddDivider: (self: SectionType) -> DividerControl,
    AddToggleColorPicker: (self: SectionType, toggleData: ToggleData, colorData: ColorPickerData) -> ToggleColorControl,
    AddToggleKeybind: (self: SectionType, toggleData: ToggleData, keybindData: KeybindData) -> ToggleKeybindControl,
}

export type NotificationData = {
    Title: string,
    Content: string,
    Duration: number?,
}

export type ButtonData = {
    Text: string,
    Callback: ControlCallback<nil>?,
}

export type ToggleData = {
    Text: string,
    Default: boolean?,
    Callback: ControlCallback<boolean>?,
}

export type SliderData = {
    Text: string,
    Min: number,
    Max: number,
    Default: number?,
    Rounding: number?,
    Callback: ControlCallback<number>?,
}

export type DropdownData = {
    Text: string,
    Values: {string},
    Multi: boolean?,
    Default: string?,
    Callback: ControlCallback<string>?,
}

export type MultiDropdownData = {
    Text: string,
    Values: {string},
    Default: {string}?,
    Callback: ControlCallback<{string}>?,
}

export type ColorPickerData = {
    Text: string,
    Default: Color3?,
    TransparencyDefault: number?,
    Callback: ControlCallback<Color3>?,
}

export type KeybindData = {
    Text: string,
    Default: Enum.KeyCode,
    Callback: ControlCallback<Enum.KeyCode>?,
}

export type TextboxData = {
    Text: string,
    Placeholder: string?,
    Callback: ControlCallback<string>?,
}

-- Forward declarations for control types (simple records)
export type ButtonControl = { SetText: (self: ButtonControl, text: string) -> () }
export type ToggleControl = { Set: (self: ToggleControl, value: boolean) -> (), Get: (self: ToggleControl) -> boolean }
export type SliderControl = { Set: (self: SliderControl, value: number) -> (), Get: (self: SliderControl) -> number }
export type DropdownControl = { Set: (self: DropdownControl, value: string) -> (), Get: (self: DropdownControl) -> string }
export type MultiDropdownControl = { Set: (self: MultiDropdownControl, values: {string}) -> (), Get: (self: MultiDropdownControl) -> {string} }
export type ColorPickerControl = { Set: (self: ColorPickerControl, color: Color3) -> (), Get: (self: ColorPickerControl) -> Color3 }
export type KeybindControl = { Set: (self: KeybindControl, key: Enum.KeyCode) -> (), Get: (self: KeybindControl) -> Enum.KeyCode }
export type TextboxControl = { Set: (self: TextboxControl, text: string) -> (), Get: (self: TextboxControl) -> string }
export type LabelControl = {}
export type ParagraphControl = {}
export type DividerControl = {}
export type ToggleColorControl = {}
export type ToggleKeybindControl = {}

-- Utility

local function tween(instance: Instance, info: TweenInfo, props: {[string]: any})
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function createStroke(color: Color3, thickness: number)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return stroke
end

local function createCorner(radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function createShadow()
    local shadow = Instance.new("ImageLabel")
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.ZIndex = 0
    return shadow
end

local function makeDraggable(frame: Frame, dragHandle: GuiObject?)
    local dragging = false
    local dragStart: Vector2? = nil
    local startPos: UDim2? = nil

    dragHandle = dragHandle or frame

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Theme manager hook (injected from ThemeManager.lua)
local ThemeManager: any = nil

local Library: LibraryType = {} :: any
Library.__index = Library

local WindowClass = {}
WindowClass.__index = WindowClass

local TabClass = {}
TabClass.__index = TabClass

local SectionClass = {}
SectionClass.__index = SectionClass

-- Notification manager (per-library)
local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new(rootGui: ScreenGui, theme: any)
    local self = setmetatable({}, NotificationManager)
    self.RootGui = rootGui
    self.Theme = theme
    self.Container = Instance.new("Frame")
    self.Container.Name = "ZenithNotifications"
    self.Container.AnchorPoint = Vector2.new(1, 1)
    self.Container.Position = UDim2.new(1, -20, 1, -20)
    self.Container.Size = UDim2.new(0, 320, 1, -40)
    self.Container.BackgroundTransparency = 1
    self.Container.Parent = rootGui

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = self.Container

    return self
end

function NotificationManager:Push(data: NotificationData)
    local theme = self.Theme

    local holder = Instance.new("Frame")
    holder.BackgroundColor3 = theme.BackgroundLayer2
    holder.Size = UDim2.new(1, 0, 0, 70)
    holder.BackgroundTransparency = 0
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.Parent = self.Container

    createCorner(8).Parent = holder
    createStroke(theme.Outline, 1).Parent = holder

    local shadow = createShadow()
    shadow.Parent = holder

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextColor3 = theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = data.Title
    title.Position = UDim2.new(0, 12, 0, 8)
    title.Size = UDim2.new(1, -24, 0, 18)
    title.Parent = holder

    local content = Instance.new("TextLabel")
    content.BackgroundTransparency = 1
    content.Font = Enum.Font.Gotham
    content.TextSize = 13
    content.TextColor3 = theme.TextMuted
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextWrapped = true
    content.Text = data.Content
    content.Position = UDim2.new(0, 12, 0, 26)
    content.Size = UDim2.new(1, -24, 0, 32)
    content.Parent = holder

    local progress = Instance.new("Frame")
    progress.BackgroundColor3 = theme.Accent
    progress.BorderSizePixel = 0
    progress.Size = UDim2.new(0, 0, 0, 2)
    progress.Position = UDim2.new(0, 0, 1, -2)
    progress.Parent = holder

    local duration = data.Duration or 4
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, 0)

    tween(holder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 70),
    })

    tween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 2),
    })

    task.delay(duration, function()
        tween(holder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
        }).Completed:Wait()
        holder:Destroy()
    end)
end

-- Window

function WindowClass.new(options: WindowOptions)
    local self = setmetatable({}, WindowClass)

    self.Options = options
    self.Tabs = {}
    self.ActiveTab = nil
    self.Theme = ThemeManager and ThemeManager:GetTheme(options.Theme) or ThemeManager

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZenithUiLib"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    self.ScreenGui = screenGui

    -- Acrylic blur
    if options.Acrylic then
        local blur = Instance.new("BlurEffect")
        blur.Name = "ZenithBlur"
        blur.Size = 0
        blur.Parent = Lighting
        tween(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = 12,
        })
        self.Blur = blur
    end

    -- Root window
    local root = Instance.new("Frame")
    root.Name = "ZenithWindow"
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Size = options.Size
    root.Position = options.Center and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, -options.Size.X.Offset/2, 0.5, -options.Size.Y.Offset/2)
    root.BackgroundColor3 = self.Theme.BackgroundLayer1
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Parent = screenGui

    createCorner(12).Parent = root
    createStroke(self.Theme.Outline, 1).Parent = root

    local shadow = createShadow()
    shadow.Parent = root

    self.Root = root

    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.BackgroundColor3 = self.Theme.BackgroundLayer2
    topBar.BorderSizePixel = 0
    topBar.Size = UDim2.new(1, 0, 0, 36)
    topBar.Parent = root

    createCorner(12).Parent = topBar
    createStroke(self.Theme.OutlineMuted, 1).Parent = topBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = self.Theme.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = options.Title
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.Size = UDim2.new(0.5, -12, 1, 0)
    titleLabel.Parent = topBar

    self.TitleLabel = titleLabel

    -- Minimize / Close buttons
    local buttonHolder = Instance.new("Frame")
    buttonHolder.BackgroundTransparency = 1
    buttonHolder.Size = UDim2.new(0, 80, 1, 0)
    buttonHolder.Position = UDim2.new(1, -80, 0, 0)
    buttonHolder.Parent = topBar

    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 6)
    buttonLayout.Parent = buttonHolder

    local function createTopButton(text: string)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = self.Theme.BackgroundLayer3
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(0, 32, 0, 22)
        btn.Text = text
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextColor3 = self.Theme.TextMuted
        btn.AutoButtonColor = false
        btn.Parent = buttonHolder

        createCorner(6).Parent = btn
        createStroke(self.Theme.OutlineMuted, 1).Parent = btn

        btn.MouseEnter:Connect(function()
            tween(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = self.Theme.BackgroundLayer4,
                TextColor3 = self.Theme.Text,
            })
        end)

        btn.MouseLeave:Connect(function()
            tween(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = self.Theme.BackgroundLayer3,
                TextColor3 = self.Theme.TextMuted,
            })
        end)

        return btn
    end

    local minimizeButton = createTopButton("_")
    local closeButton = createTopButton("×")

    minimizeButton.MouseButton1Click:Connect(function()
        self:Minimize()
    end)

    closeButton.MouseButton1Click:Connect(function()
        self:Close()
    end)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundColor3 = self.Theme.BackgroundLayer2
    sidebar.BorderSizePixel = 0
    sidebar.Size = UDim2.new(0, 220, 1, -36)
    sidebar.Position = UDim2.new(0, 0, 0, 36)
    sidebar.Parent = root

    createCorner(12).Parent = sidebar
    createStroke(self.Theme.OutlineMuted, 1).Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 12)
    sidebarPadding.PaddingBottom = UDim.new(0, 12)
    sidebarPadding.PaddingLeft = UDim.new(0, 12)
    sidebarPadding.PaddingRight = UDim.new(0, 12)
    sidebarPadding.Parent = sidebar

    local sidebarList = Instance.new("UIListLayout")
    sidebarList.FillDirection = Enum.FillDirection.Vertical
    sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarList.Padding = UDim.new(0, 6)
    sidebarList.Parent = sidebar

    self.Sidebar = sidebar
    self.SidebarList = sidebarList

    -- Sidebar selection indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "SelectionIndicator"
    indicator.BackgroundColor3 = self.Theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Size = UDim2.new(0, 3, 0, 24)
    indicator.Position = UDim2.new(0, 0, 0, 0)
    indicator.Parent = sidebar

    createCorner(4).Parent = indicator
    self.SidebarIndicator = indicator

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundColor3 = self.Theme.BackgroundLayer1
    content.BorderSizePixel = 0
    content.Size = UDim2.new(1, -220, 1, -36)
    content.Position = UDim2.new(0, 220, 0, 36)
    content.ClipsDescendants = true
    content.Parent = root

    createCorner(12).Parent = content
    createStroke(self.Theme.OutlineMuted, 1).Parent = content

    self.Content = content

    -- Watermark
    local watermark = Instance.new("TextLabel")
    watermark.Name = "Watermark"
    watermark.BackgroundTransparency = 1
    watermark.Font = Enum.Font.Gotham
    watermark.TextSize = 12
    watermark.TextColor3 = self.Theme.TextMuted
    watermark.TextXAlignment = Enum.TextXAlignment.Left
    watermark.Text = ""
    watermark.Position = UDim2.new(0, 12, 1, -24)
    watermark.Size = UDim2.new(0.5, 0, 0, 20)
    watermark.Parent = root
    self.WatermarkLabel = watermark

    -- FPS counter
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSCounter"
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Font = Enum.Font.Gotham
    fpsLabel.TextSize = 12
    fpsLabel.TextColor3 = self.Theme.TextMuted
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
    fpsLabel.Text = ""
    fpsLabel.Position = UDim2.new(1, -12, 1, -24)
    fpsLabel.Size = UDim2.new(0.5, 0, 0, 20)
    fpsLabel.Parent = root
    self.FPSLabel = fpsLabel
    self.FPSEnabled = false

    -- Search bar (optional)
    local searchHolder = Instance.new("Frame")
    searchHolder.Name = "SearchHolder"
    searchHolder.BackgroundTransparency = 1
    searchHolder.Size = UDim2.new(1, -24, 0, 26)
    searchHolder.Position = UDim2.new(0, 12, 0, 8)
    searchHolder.Parent = content

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.BackgroundColor3 = self.Theme.BackgroundLayer3
    searchBox.BorderSizePixel = 0
    searchBox.Size = UDim2.new(0, 220, 1, 0)
    searchBox.Position = UDim2.new(1, -220, 0, 0)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 12
    searchBox.TextColor3 = self.Theme.TextMuted
    searchBox.PlaceholderText = "Search controls..."
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchHolder

    createCorner(8).Parent = searchBox
    createStroke(self.Theme.OutlineMuted, 1).Parent = searchBox

    self.SearchBox = searchBox
    self.SearchEnabled = false

    -- Content container below search
    local contentHolder = Instance.new("Frame")
    contentHolder.Name = "ContentHolder"
    contentHolder.BackgroundTransparency = 1
    contentHolder.Size = UDim2.new(1, -24, 1, -40)
    contentHolder.Position = UDim2.new(0, 12, 0, 36)
    contentHolder.Parent = content
    self.ContentHolder = contentHolder

    -- Open animation
    root.Size = UDim2.new(0, 0, 0, 0)
    root.BackgroundTransparency = 1
    tween(root, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = options.Size,
        BackgroundTransparency = 0,
    })

    if options.Draggable then
        makeDraggable(root, topBar)
    end

    -- FPS loop
    RunService.RenderStepped:Connect(function(dt)
        if self.FPSEnabled then
            local fps = math.floor(1 / dt)
            self.FPSLabel.Text = string.format("FPS: %d", fps)
        end
    end)

    -- Search filtering (simple text match on control labels)
    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if not self.SearchEnabled then
            return
        end

        local query = string.lower(self.SearchBox.Text)
        for _, tab in ipairs(self.Tabs) do
            for _, section in ipairs(tab.Sections) do
                for _, controlFrame in ipairs(section.ControlFrames) do
                    local label = controlFrame:FindFirstChild("Label")
                    if label and label:IsA("TextLabel") then
                        local text = string.lower(label.Text)
                        controlFrame.Visible = query == "" or string.find(text, query, 1, true) ~= nil
                    end
                end
            end
        end
    end)

    -- Notifications
    self.NotificationManager = NotificationManager.new(screenGui, self.Theme)

    return self
end

function WindowClass:AddTab(name: string, icon: string?): TabType
    local tab = setmetatable({}, TabClass)
    tab.Name = name
    tab.Icon = icon
    tab.Window = self
    tab.Sections = {}

    -- Sidebar button
    local theme = self.Theme

    local button = Instance.new("TextButton")
    button.Name = "Tab_" .. name
    button.BackgroundColor3 = theme.BackgroundLayer3
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, 28)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 13
    button.TextColor3 = theme.TextMuted
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.Text = name
    button.Parent = self.Sidebar

    createCorner(8).Parent = button
    createStroke(theme.OutlineMuted, 1).Parent = button

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.TextSize = 14
    iconLabel.TextColor3 = theme.TextMuted
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.Text = icon or ""
    iconLabel.Size = UDim2.new(0, 24, 1, 0)
    iconLabel.Position = UDim2.new(0, 4, 0, 0)
    iconLabel.Parent = button

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamSemibold
    textLabel.TextSize = 13
    textLabel.TextColor3 = theme.TextMuted
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = name
    textLabel.Size = UDim2.new(1, -32, 1, 0)
    textLabel.Position = UDim2.new(0, 32, 0, 0)
    textLabel.Parent = button

    tab.Button = button
    tab.ButtonText = textLabel

    -- Content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "TabContent_" .. name
    contentFrame.BackgroundTransparency = 1
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.Visible = false
    contentFrame.Parent = self.ContentHolder

    local leftColumn = Instance.new("ScrollingFrame")
    leftColumn.Name = "LeftColumn"
    leftColumn.BackgroundTransparency = 1
    leftColumn.BorderSizePixel = 0
    leftColumn.Size = UDim2.new(0.5, -6, 1, 0)
    leftColumn.Position = UDim2.new(0, 0, 0, 0)
    leftColumn.ScrollBarThickness = 4
    leftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
    leftColumn.ScrollBarImageColor3 = theme.ScrollBar
    leftColumn.Parent = contentFrame

    local leftPadding = Instance.new("UIPadding")
    leftPadding.PaddingTop = UDim.new(0, 4)
    leftPadding.PaddingBottom = UDim.new(0, 4)
    leftPadding.PaddingLeft = UDim.new(0, 4)
    leftPadding.PaddingRight = UDim.new(0, 4)
    leftPadding.Parent = leftColumn

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.FillDirection = Enum.FillDirection.Vertical
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Padding = UDim.new(0, 8)
    leftLayout.Parent = leftColumn

    local rightColumn = Instance.new("ScrollingFrame")
    rightColumn.Name = "RightColumn"
    rightColumn.BackgroundTransparency = 1
    rightColumn.BorderSizePixel = 0
    rightColumn.Size = UDim2.new(0.5, -6, 1, 0)
    rightColumn.Position = UDim2.new(0.5, 6, 0, 0)
    rightColumn.ScrollBarThickness = 4
    rightColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
    rightColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
    rightColumn.ScrollBarImageColor3 = theme.ScrollBar
    rightColumn.Parent = contentFrame

    local rightPadding = Instance.new("UIPadding")
    rightPadding.PaddingTop = UDim.new(0, 4)
    rightPadding.PaddingBottom = UDim.new(0, 4)
    rightPadding.PaddingLeft = UDim.new(0, 4)
    rightPadding.PaddingRight = UDim.new(0, 4)
    rightPadding.Parent = rightColumn

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.FillDirection = Enum.FillDirection.Vertical
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Padding = UDim.new(0, 8)
    rightLayout.Parent = rightColumn

    tab.ContentFrame = contentFrame
    tab.LeftColumn = leftColumn
    tab.RightColumn = rightColumn

    -- Hover animation
    button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = theme.BackgroundLayer4,
            })
        end
    end)

    button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = theme.BackgroundLayer3,
            })
        end
    end)

    -- Active tab animation
    button.MouseButton1Click:Connect(function()
        self:SetActiveTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        self:SetActiveTab(tab)
    end

    return tab
end

function WindowClass:SetActiveTab(tab: TabType)
    if self.ActiveTab == tab then
        return
    end

    local theme = self.Theme

    if self.ActiveTab then
        self.ActiveTab.ContentFrame.Visible = false
        tween(self.ActiveTab.Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = theme.BackgroundLayer3,
        })
        self.ActiveTab.ButtonText.TextColor3 = theme.TextMuted
    end

    self.ActiveTab = tab
    tab.ContentFrame.Visible = true

    tween(tab.Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = theme.BackgroundLayer4,
    })
    tab.ButtonText.TextColor3 = theme.Text

    -- Move indicator
    local targetY = tab.Button.Position.Y.Offset
    tween(self.SidebarIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, targetY + 2),
    })
end

function WindowClass:SetWatermark(text: string)
    self.WatermarkLabel.Text = text
end

function WindowClass:SetFPSCounter(enabled: boolean)
    self.FPSEnabled = enabled
    self.FPSLabel.Visible = enabled
end

function WindowClass:SetSearchBar(enabled: boolean)
    self.SearchEnabled = enabled
    self.SearchBox.Visible = enabled
end

function WindowClass:Minimize()
    tween(self.Root, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    })
    if self.Blur then
        tween(self.Blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = 0,
        })
    end
end

function WindowClass:Close()
    tween(self.Root, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }).Completed:Wait()

    if self.Blur then
        tween(self.Blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = 0,
        }).Completed:Wait()
        self.Blur:Destroy()
    end

    self.ScreenGui:Destroy()
end

function WindowClass:GetScreenGui(): ScreenGui
    return self.ScreenGui
end

-- Sections

function TabClass:AddLeftSection(name: string): SectionType
    return self:_addSection(name, self.LeftColumn)
end

function TabClass:AddRightSection(name: string): SectionType
    return self:_addSection(name, self.RightColumn)
end

function TabClass:_addSection(name: string, parent: ScrollingFrame): SectionType
    local section = setmetatable({}, SectionClass)
    section.Name = name
    section.Tab = self
    section.Window = self.Window
    section.ControlFrames = {}

    local theme = self.Window.Theme

    local frame = Instance.new("Frame")
    frame.Name = "Section_" .. name
    frame.BackgroundColor3 = theme.BackgroundLayer2
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.ClipsDescendants = true
    frame.Parent = parent

    createCorner(10).Parent = frame
    createStroke(theme.OutlineMuted, 1).Parent = frame

    local shadow = createShadow()
    shadow.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "SectionTitle"
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 13
    title.TextColor3 = theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = name
    title.Size = UDim2.new(1, 0, 0, 18)
    title.Parent = frame

    section.Frame = frame
    section.Layout = layout

    return section
end

-- Controls creation helpers

local function createControlFrame(section: SectionType, height: number): Frame
    local theme = section.Window.Theme

    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = theme.BackgroundLayer3
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, height)
    frame.ClipsDescendants = true
    frame.Parent = section.Frame

    createCorner(8).Parent = frame
    createStroke(theme.OutlineMuted, 1).Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = ""
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.5, -10, 1, 0)
    label.Parent = frame

    table.insert(section.ControlFrames, frame)

    return frame
end

-- Button

function SectionClass:AddButton(data: ButtonData): ButtonControl
    local frame = createControlFrame(self, 28)
    local theme = self.Window.Theme

    local label = frame.Label :: TextLabel
    label.Text = data.Text

    local button = Instance.new("TextButton")
    button.BackgroundColor3 = theme.Accent
    button.BorderSizePixel = 0
    button.Size = UDim2.new(0, 80, 0, 22)
    button.Position = UDim2.new(1, -90, 0.5, -11)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = "Execute"
    button.AutoButtonColor = false
    button.Parent = frame

    createCorner(6).Parent = button

    button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = theme.AccentHover,
        })
    end)

    button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = theme.Accent,
        })
    end)

    button.MouseButton1Click:Connect(function()
        if data.Callback then
            data.Callback(nil)
        end
    end)

    local control: ButtonControl = {} :: any
    function control.SetText(_, text: string)
        label.Text = text
    end

    return control
end

-- Toggle

function SectionClass:AddToggle(data: ToggleData): ToggleControl
    local frame = createControlFrame(self, 28)
    local theme = self.Window.Theme

    local label = frame.Label :: TextLabel
    label.Text = data.Text

    local switch = Instance.new("Frame")
    switch.Name = "Switch"
    switch.BackgroundColor3 = theme.BackgroundLayer4
    switch.BorderSizePixel = 0
    switch.Size = UDim2.new(0, 40, 0, 18)
    switch.Position = UDim2.new(1, -50, 0.5, -9)
    switch.Parent = frame

    createCorner(9).Parent = switch
    createStroke(theme.OutlineMuted, 1).Parent = switch

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.BackgroundColor3 = theme.BackgroundLayer1
    knob.BorderSizePixel = 0
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 1, 0, 1)
    knob.Parent = switch

    createCorner(8).Parent = knob

    local enabled = data.Default or false

    local function updateVisual(animated: boolean)
        local targetPos = enabled and UDim2.new(1, -17, 0, 1) or UDim2.new(0, 1, 0, 1)
        local targetColor = enabled and theme.Accent or theme.BackgroundLayer4

        if animated then
            tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = targetPos,
            })
            tween(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = targetColor,
            })
        else
            knob.Position = targetPos
            switch.BackgroundColor3 = targetColor
        end
    end

    updateVisual(false)

    local function setValue(value: boolean)
        if enabled == value then
            return
        end
        enabled = value
        updateVisual(true)
        if data.Callback then
            data.Callback(enabled)
        end
    end

    switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setValue(not enabled)
        end
    end)

    local control: ToggleControl = {} :: any
    function control.Set(_, value: boolean)
        setValue(value)
    end
    function control.Get(_): boolean
        return enabled
    end

    return control
end

-- Slider

function SectionClass:AddSlider(data: SliderData): SliderControl
    local frame = createControlFrame(self, 40)
    local theme = self.Window.Theme

    local label = frame.Label :: TextLabel
    label.Text = data.Text

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 12
    valueLabel.TextColor3 = theme.TextMuted
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Text = ""
    valueLabel.Size = UDim2.new(0, 80, 0, 18)
    valueLabel.Position = UDim2.new(1, -90, 0, 0)
    valueLabel.Parent = frame

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = theme.BackgroundLayer4
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 1, -10)
    bar.Parent = frame

    createCorner(3).Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = theme.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Parent = bar

    createCorner(3).Parent = fill

    local rounding = data.Rounding or 0
    local min = data.Min
    local max = data.Max
    local current = data.Default or min

    local function formatValue(value: number): string
        if rounding <= 0 then
            return tostring(math.floor(value))
        else
            local factor = 10 ^ rounding
            return tostring(math.floor(value * factor) / factor)
        end
    end

    local function updateVisual(animated: boolean)
        local alpha = math.clamp((current - min) / (max - min), 0, 1)
        local targetSize = UDim2.new(alpha, 0, 1, 0)
        if animated then
            tween(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = targetSize,
            })
        else
            fill.Size = targetSize
        end
        valueLabel.Text = formatValue(current)
    end

    updateVisual(false)

    local dragging = false

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            local value = min + (max - min) * math.clamp(rel, 0, 1)
            current = value
            updateVisual(false)
            if data.Callback then
                data.Callback(current)
            end
        end
    end)

    local control: SliderControl = {} :: any
    function control.Set(_, value: number)
        current = math.clamp(value, min, max)
        updateVisual(true)
        if data.Callback then
            data.Callback(current)
        end
    end
    function control.Get(_): number
        return current
    end

    return control
end

-- Dropdown (single)

function SectionClass:AddDropdown(data: DropdownData): DropdownControl
    local frame = createControlFrame(self, 32)
    local theme = self.Window.Theme

    local label = frame.Label :: TextLabel
    label.Text = data.Text

    local box = Instance.new("TextButton")
    box.BackgroundColor3 = theme.BackgroundLayer4
    box.BorderSizePixel = 0
    box.Size = UDim2.new(0, 140, 0, 22)
    box.Position = UDim2.new(1, -150, 0.5, -11)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = theme.TextMuted
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Text = data.Default or "Select..."
    box.AutoButtonColor = false
    box.Parent = frame

    createCorner(6).Parent = box
    createStroke(theme.OutlineMuted, 1).Parent = box

    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 12
    arrow.TextColor3 = theme.TextMuted
    arrow.Text = "▼"
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.Parent = box

    local listHolder = Instance.new("Frame")
    listHolder.BackgroundColor3 = theme.BackgroundLayer3
    listHolder.BorderSizePixel = 0
    listHolder.Size = UDim2.new(0, 140, 0, 0)
    listHolder.Position = UDim2.new(1, -150, 0, 26)
    listHolder.Visible = false
    listHolder.ClipsDescendants = true
    listHolder.Parent = frame

    createCorner(6).Parent = listHolder
    createStroke(theme.OutlineMuted, 1).Parent = listHolder

    local list = Instance.new("ScrollingFrame")
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Size = UDim2.new(1, -8, 1, -8)
    list.Position = UDim2.new(0, 4, 0, 4)
    list.ScrollBarThickness = 4
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.ScrollBarImageColor3 = theme.ScrollBar
    list.Parent = listHolder

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = list

    local current = data.Default or data.Values[1]

    local function setValue(value: string)
        current = value
        box.Text = value
        if data.Callback then
            data.Callback(value)
        end
    end

    for _, v in ipairs(data.Values) do
        local item = Instance.new("TextButton")
        item.BackgroundColor3 = theme.BackgroundLayer4
        item.BorderSizePixel = 0
        item.Size = UDim2.new(1, 0, 0, 20)
        item.Font = Enum.Font.Gotham
        item.TextSize = 12
        item.TextColor3 = theme.TextMuted
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.Text = v
        item.AutoButtonColor = false
        item.Parent = list

        createCorner(4).Parent = item

        item.MouseEnter:Connect(function()
            tween(item, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = theme.BackgroundLayer5,
            })
        end)

        item.MouseLeave:Connect(function()
            tween(item, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = theme.BackgroundLayer4,
            })
        end)

        item.MouseButton1Click:Connect(function()
            setValue(v)
            tween(listHolder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 140, 0, 0),
            }).Completed:Wait()
            listHolder.Visible = false
        end)
    end

    local open = false

    local function toggleOpen()
        open = not open
        listHolder.Visible = true
        local targetSize = open and UDim2.new(0, 140, 0, 120) or UDim2.new(0, 140, 0, 0)
        tween(listHolder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = targetSize,
        }).Completed:Wait()
        if not open then
            listHolder.Visible = false
        end
    end

    box.MouseButton1Click:Connect(function()
        toggleOpen()
    end)

    local control: DropdownControl = {} :: any
    function control.Set(_, value: string)
        setValue(value)
    end
    function control.Get(_): string
        return current
    end

    return control
end

-- MultiDropdown

function SectionClass:AddMultiDropdown(data: MultiDropdownData): MultiDropdownControl
    local frame = createControlFrame(self, 40)
    local theme = self.Window.Theme

    local label = frame.Label :: TextLabel
    label.Text = data.Text

    local box = Instance.new("TextButton")
    box.BackgroundColor3 = theme.BackgroundLayer4
    box.BorderSizePixel = 0
    box.Size = UDim2.new(0, 160, 0, 22)
    box.Position = UDim2.new(1, -170, 0, 0)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = theme.TextMuted
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Text = "Select..."
    box.AutoButtonColor = false
    box.Parent = frame

    createCorner(6).Parent = box
    createStroke(theme.OutlineMuted, 1).Parent = box

    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 12
    arrow.TextColor3 = theme.TextMuted
    arrow.Text = "▼"
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.Parent = box

    local listHolder = Instance.new("Frame")
    listHolder.BackgroundColor3 = theme.BackgroundLayer3
    listHolder.BorderSizePixel = 0
    listHolder.Size = UDim2.new(0, 160, 0, 0)
    listHolder.Position = UDim2.new(1, -170, 0, 26)
    listHolder.Visible = false
    listHolder.ClipsDescendants = true
    listHolder.Parent = frame

    createCorner(6).Parent = listHolder
    createStroke(theme.OutlineMuted, 1).Parent = listHolder

    local list = Instance.new("ScrollingFrame")
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Size = UDim2.new(1, -8, 1, -8)
    list.Position = UDim2.new(0, 4, 0, 4)
    list.ScrollBarThickness = 4
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.ScrollBarImageColor3 = theme.ScrollBar
    list.Parent = listHolder

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = list

    local selected: {string} = data.Default or {}

    local function updateBoxText()
        if #selected == 0 then
            box.Text = "Select..."
        else
            box.Text = table.concat(selected, ", ")
        end
    end

    local function setSelected(values: {string})
        selected = values
        updateBoxText()
        if data.Callback then
            data.Callback(selected)
        end
    end

    for _, v in ipairs(data.Values) do
        local item = Instance.new("TextButton")
        item.BackgroundColor3 = theme.BackgroundLayer4
        item.BorderSizePixel = 0
        item.Size = UDim2.new(1, 0, 0, 20)
        item.Font = Enum.Font.Gotham
        item.TextSize = 12
        item.TextColor3 = theme.TextMuted
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.Text = v
        item.AutoButtonColor = false
        item.Parent = list

        createCorner(4).Parent = item

        local check = Instance.new("Frame")
        check.BackgroundColor3 = theme.BackgroundLayer5
        check.BorderSizePixel = 0
        check.Size = UDim2.new(0, 12, 0, 12)
        check.Position = UDim2.new(1, -14, 0.5, -6)
        check.Parent = item

        createCorner(3).Parent = check

        local function isSelected(): boolean
            for _, s in ipairs(selected) do
                if s == v then
                    return true
                end
            end
            return false
        end

        local function updateCheck(animated: boolean)
            local targetColor = isSelected() and theme.Accent or theme.BackgroundLayer5
            if animated then
                tween(check, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = targetColor,
                })
            else
                check.BackgroundColor3 = targetColor
            end
        end

        updateCheck(false)

        item.MouseButton1Click:Connect(function()
            if isSelected() then
                local new = {}
                for _, s in ipairs(selected) do
                    if s ~= v then
                        table.insert(new, s)
                    end
                end
                setSelected(new)
            else
                local new = {}
                for _, s in ipairs(selected) do
                    table.insert(new, s)
                end
                table.insert(new, v)
                setSelected(new)
            end
            updateCheck(true)
        end)
    end

    updateBoxText()

    local open = false

    local function toggleOpen()
        open = not open
        listHolder.Visible = true
        local targetSize = open and UDim2.new(0, 160, 0, 140) or UDim2.new(0, 160, 0, 0)
        tween(listHolder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = targetSize,
        }).Completed:Wait()
        if not open then
            listHolder.Visible = false
        end
    end

    box.MouseButton1Click:Connect(function()
        toggleOpen()
    end)

    local control: MultiDropdownControl = {} :: any
    function control.Set(_, values: {string})
        setSelected(values)
    end
    function control.Get(_): {string}
        return selected
    end

    return control
end

-- Color picker (HSV/RGB/Hex, simple but functional)

function SectionClass:AddColorPicker(data: ColorPickerData): ColorPickerControl
    local frame = createControlFrame(self, 60)
    local theme = self.Window.Theme

    local label = frame.Label :: TextLabel
    label.Text = data.Text

    local preview = Instance.new("Frame")
    preview.BackgroundColor3 = data.Default or theme.Accent
    preview.BorderSizePixel = 0
    preview.Size = UDim2.new(0, 32, 0, 32)
    preview.Position = UDim2.new(1, -42, 0, 4)
    preview.Parent = frame

    createCorner(8).Parent = preview
    createStroke(theme.OutlineMuted, 1).Parent = preview

    local transparencyBar = Instance.new("Frame")
    transparencyBar.BackgroundColor3 = theme.BackgroundLayer4
    transparencyBar.BorderSizePixel = 0
    transparencyBar.Size = UDim2.new(1, -52, 0, 6)
    transparencyBar.Position = UDim2.new(0, 10, 1, -10)
    transparencyBar.Parent = frame

    createCorner(3).Parent = transparencyBar

    local transparencyFill = Instance.new("Frame")
    transparencyFill.BackgroundColor3 = theme.Accent
    transparencyFill.BorderSizePixel = 0
    transparencyFill.Size = UDim2.new(1, 0, 1, 0)
    transparencyFill.Parent = transparencyBar

    createCorner(3).Parent = transparencyFill

    local currentColor = data.Default or theme.Accent
    local currentTransparency = data.TransparencyDefault or 0

    local function updatePreview()
        preview.BackgroundColor3 = currentColor
        preview.BackgroundTransparency = currentTransparency
    end

    updatePreview()

    local pickerButton = Instance.new("TextButton")
    pickerButton.BackgroundTransparency = 1
    pickerButton.Size = UDim2.new(1, -52, 0, 32)
    pickerButton.Position = UDim2.new(0, 10, 0, 4)
    pickerButton.Text = ""
    pickerButton.AutoButtonColor = false
    pickerButton.Parent = frame

    local pickerHolder = Instance.new("Frame")
    pickerHolder.BackgroundColor3 = theme.BackgroundLayer3
    pickerHolder.BorderSizePixel = 0
    pickerHolder.Size = UDim2.new(0, 180, 0, 120)
    pickerHolder.Position = UDim2.new(0, 10, 1, 4)
    pickerHolder.Visible = false
    pickerHolder.ClipsDescendants = true
    pickerHolder.Parent = frame

    createCorner(8).Parent = pickerHolder
    createStroke(theme.OutlineMuted, 1).Parent = pickerHolder

    local hueBar = Instance.new("Frame")
    hueBar.BackgroundColor3 = Color3.new(1, 0, 0)
    hueBar.BorderSizePixel = 0
    hueBar.Size = UDim2.new(0, 12, 1, -8)
    hueBar.Position = UDim2.new(1, -16, 0, 4)
    hueBar.Parent = pickerHolder

    createCorner(4).Parent = hueBar

    local satVal = Instance.new("Frame")
    satVal.BackgroundColor3 = Color3.new(1, 1, 1)
    satVal.BorderSizePixel = 0
    satVal.Size = UDim2.new(1, -24, 1, -8)
    satVal.Position = UDim2.new(0, 4, 0, 4)
    satVal.Parent = pickerHolder

    createCorner(4).Parent = satVal

    local function hsvToColor(h: number, s: number, v: number): Color3
        return Color3.fromHSV(h, s, v)
    end

    local hue = 0
    local sat = 1
    local val = 1

    local draggingHue = false
    local draggingSatVal = false
    local draggingTransparency = false

    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue = true
        end
    end)

    hueBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue = false
        end
    end)

    satVal.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSatVal = true
        end
    end)

    satVal.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSatVal = false
        end
    end)

    transparencyBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingTransparency = true
        end
    end)

    transparencyBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingTransparency = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        if draggingHue then
            local rel = (input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y
            hue = math.clamp(rel, 0, 1)
            currentColor = hsvToColor(hue, sat, val)
            updatePreview()
            if data.Callback then
                data.Callback(currentColor)
            end
        elseif draggingSatVal then
            local relX = (input.Position.X - satVal.AbsolutePosition.X) / satVal.AbsoluteSize.X
            local relY = (input.Position.Y - satVal.AbsolutePosition.Y) / satVal.AbsoluteSize.Y
            sat = math.clamp(relX, 0, 1)
            val = 1 - math.clamp(relY, 0, 1)
            currentColor = hsvToColor(hue, sat, val)
            updatePreview()
            if data.Callback then
                data.Callback(currentColor)
            end
        elseif draggingTransparency then
            local rel = (input.Position.X - transparencyBar.AbsolutePosition.X) / transparencyBar.AbsoluteSize.X
            currentTransparency = 1 - math.clamp(rel, 0, 1)
            transparencyFill.Size = UDim2.new(rel, 0, 1, 0)
            updatePreview()
        end
    end)

    local open = false

    pickerButton.MouseButton1Click:Connect(function()
        open = not open
        pickerHolder.Visible = true
        local targetSize = open and UDim2.new(0, 180, 0, 120) or UDim2.new(0, 180, 0, 0)
        tween(pickerHolder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = targetSize,
        }).Completed:Wait()
        if not open then
            pickerHolder.Visible = false
        end
    end)

    local control: ColorPickerControl = {} :: any
    function control.Set(_, color: Color3)
        currentColor = color
        updatePreview()
    end
    function control.Get(_): Color3
        return currentColor
    end

    return control
end

-- Keybind

function SectionClass:AddKeybind(data: KeybindData): KeybindControl
    local frame = createControlFrame(self, 32)
    local theme = self.Window.Theme

    local label = frame.Label :: TextLabel
    label.Text = data.Text

    local box = Instance.new("TextButton")
    box.BackgroundColor3 = theme.BackgroundLayer4
    box.BorderSizePixel = 0
    box.Size = UDim2.new(0, 120, 0, 22)
    box.Position = UDim2.new(1, -130, 0.5, -11)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = theme.TextMuted
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.Text = data.Default.Name
    box.AutoButtonColor = false
    box.Parent = frame

    createCorner(6).Parent = box
    createStroke(theme.OutlineMuted, 1).Parent = box

    local listening = false
    local currentKey = data.Default

    local function setKey(key: Enum.KeyCode)
        currentKey = key
        box.Text = key.Name
        if data.Callback then
            data.Callback(key)
        end
    end

    box.MouseButton1Click:Connect(function()
        listening = true
        box.Text = "Press key..."
        tween(box, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = theme.Accent,
            TextColor3 = Color3.new(1, 1, 1),
        })
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not listening then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            tween(box, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = theme.BackgroundLayer4,
                TextColor3 = theme.TextMuted,
            })
            setKey(input.KeyCode)
        end
    end)

    local control: KeybindControl = {} :: any
    function control.Set(_, key: Enum.KeyCode)
        setKey(key)
    end
    function control.Get(_): Enum.KeyCode
        return currentKey
    end

    return control
end

-- Textbox

function SectionClass:AddTextbox(data: TextboxData): TextboxControl
    local frame = createControlFrame(self, 32)
    local theme = self.Window.Theme

    local label = frame.Label :: TextLabel
    label.Text = data.Text

    local box = Instance.new("TextBox")
    box.BackgroundColor3 = theme.BackgroundLayer4
    box.BorderSizePixel = 0
    box.Size = UDim2.new(0, 160, 0, 22)
    box.Position = UDim2.new(1, -170, 0.5, -11)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = theme.Text
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.PlaceholderText = data.Placeholder or ""
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = frame

    createCorner(6).Parent = box
    createStroke(theme.OutlineMuted, 1).Parent = box

    box.FocusLost:Connect(function(enterPressed)
        if enterPressed and data.Callback then
            data.Callback(box.Text)
        end
    end)

    local control: TextboxControl = {} :: any
    function control.Set(_, text: string)
        box.Text = text
    end
    function control.Get(_): string
        return box.Text
    end

    return control
end

-- Label / Paragraph / Divider

function SectionClass:AddLabel(text: string): LabelControl
    local frame = createControlFrame(self, 24)
    local label = frame.Label :: TextLabel
    label.Text = text
    return {} :: LabelControl
end

function SectionClass:AddParagraph(text: string): ParagraphControl
    local frame = createControlFrame(self, 48)
    local label = frame.Label :: TextLabel
    label.TextWrapped = true
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = text
    return {} :: ParagraphControl
end

function SectionClass:AddDivider(): DividerControl
    local theme = self.Window.Theme
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = theme.BackgroundLayer4
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 1)
    frame.Parent = self.Frame
    return {} :: DividerControl
end

-- Toggle + ColorPicker

function SectionClass:AddToggleColorPicker(toggleData: ToggleData, colorData: ColorPickerData): ToggleColorControl
    local toggle = self:AddToggle(toggleData)
    local picker = self:AddColorPicker(colorData)
    return {} :: ToggleColorControl
end

-- Toggle + Keybind

function SectionClass:AddToggleKeybind(toggleData: ToggleData, keybindData: KeybindData): ToggleKeybindControl
    local toggle = self:AddToggle(toggleData)
    local keybind = self:AddKeybind(keybindData)
    return {} :: ToggleKeybindControl
end

-- Library methods

function Library:CreateWindow(options: WindowOptions): WindowType
    local window = WindowClass.new(options)
    return window :: any
end

function Library:Notify(data: NotificationData)
    if not self._globalWindow then
        return
    end
    self._globalWindow.NotificationManager:Push(data)
end

function Library:Watermark(text: string)
    if not self._globalWindow then
        return
    end
    self._globalWindow:SetWatermark(text)
end

function Library:SetThemeManager(tm: any)
    ThemeManager = tm
end

function Library:GetThemeManager()
    return ThemeManager
end

-- When first window is created, store reference for global notifications
local originalCreateWindow = Library.CreateWindow
function Library:CreateWindow(options: WindowOptions): WindowType
    local window = originalCreateWindow(self, options)
    self._globalWindow = window
    return window
end

return Library
