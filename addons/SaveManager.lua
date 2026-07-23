--!strict
-- ZenithUiLib - SaveManager.lua
-- Simple JSON-based config system using HttpService and Folder hierarchy

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local SaveManager = {}
SaveManager.__index = SaveManager

export type SaveManagerType = {
    SetLibrary: (self: SaveManagerType, lib: any) -> (),
    SetFolder: (self: SaveManagerType, name: string) -> (),
    Save: (self: SaveManagerType, name: string) -> (),
    Load: (self: SaveManagerType, name: string) -> (),
    Delete: (self: SaveManagerType, name: string) -> (),
}

local function getRootFolder(): Folder
    local root = ServerStorage:FindFirstChild("ZenithConfigs")
    if not root then
        root = Instance.new("Folder")
        root.Name = "ZenithConfigs"
        root.Parent = ServerStorage
    end
    return root
end

function SaveManager.new(): SaveManagerType
    local self = setmetatable({}, SaveManager)
    self.Library = nil
    self.FolderName = "Default"
    return self
end

function SaveManager:SetLibrary(lib: any)
    self.Library = lib
end

function SaveManager:SetFolder(name: string)
    self.FolderName = name
end

local function getConfigFolder(folderName: string): Folder
    local root = getRootFolder()
    local folder = root:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = root
    end
    return folder
end

local function getConfigValue(folder: Folder, name: string): StringValue?
    local value = folder:FindFirstChild(name)
    if not value then
        return nil
    end
    if value:IsA("StringValue") then
        return value
    end
    return nil
end

local function setConfigValue(folder: Folder, name: string, json: string)
    local value = getConfigValue(folder, name)
    if not value then
        value = Instance.new("StringValue")
        value.Name = name
        value.Parent = folder
    end
    value.Value = json
end

function SaveManager:Save(name: string)
    if not self.Library or not self.Library._globalWindow then
        return
    end

    local window = self.Library._globalWindow
    local data = {
        Toggles = {},
        Sliders = {},
        Dropdowns = {},
        Colors = {},
        Keybinds = {},
    }

    for _, tab in ipairs(window.Tabs) do
        for _, section in ipairs(tab.Sections) do
            for _, controlFrame in ipairs(section.ControlFrames) do
                local label = controlFrame:FindFirstChild("Label")
                if label and label:IsA("TextLabel") then
                    local key = label.Text
                    local toggle = controlFrame:FindFirstChild("Switch")
                    local sliderBar = controlFrame:FindFirstChild("Frame")
                    local dropdownBox = controlFrame:FindFirstChild("TextButton")
                    local preview = controlFrame:FindFirstChild("Frame")
                    local keybindBox = controlFrame:FindFirstChild("TextButton")

                    if toggle and toggle:IsA("Frame") then
                        local knob = toggle:FindFirstChild("Knob")
                        if knob then
                            local enabled = toggle.BackgroundColor3 ~= window.Theme.BackgroundLayer4
                            data.Toggles[key] = enabled
                        end
                    end

                    if sliderBar and sliderBar:IsA("Frame") and sliderBar.Size.Y.Offset == 6 then
                        local fill = sliderBar:FindFirstChildOfClass("Frame")
                        if fill then
                            data.Sliders[key] = fill.Size.X.Scale
                        end
                    end

                    if dropdownBox and dropdownBox:IsA("TextButton") and dropdownBox.Text ~= "" then
                        data.Dropdowns[key] = dropdownBox.Text
                    end

                    if preview and preview:IsA("Frame") and preview.Size == UDim2.new(0, 32, 0, 32) then
                        data.Colors[key] = {
                            R = preview.BackgroundColor3.R,
                            G = preview.BackgroundColor3.G,
                            B = preview.BackgroundColor3.B,
                        }
                    end

                    if keybindBox and keybindBox:IsA("TextButton") and keybindBox.Text ~= "" and keybindBox.Text ~= "Press key..." then
                        data.Keybinds[key] = keybindBox.Text
                    end
                end
            end
        end
    end

    local json = HttpService:JSONEncode(data)
    local folder = getConfigFolder(self.FolderName)
    setConfigValue(folder, name, json)
end

function SaveManager:Load(name: string)
    if not self.Library or not self.Library._globalWindow then
        return
    end

    local window = self.Library._globalWindow
    local folder = getConfigFolder(self.FolderName)
    local value = getConfigValue(folder, name)
    if not value then
        return
    end

    local data = HttpService:JSONDecode(value.Value)

    for _, tab in ipairs(window.Tabs) do
        for _, section in ipairs(tab.Sections) do
            for _, controlFrame in ipairs(section.ControlFrames) do
                local label = controlFrame:FindFirstChild("Label")
                if label and label:IsA("TextLabel") then
                    local key = label.Text

                    if data.Toggles and data.Toggles[key] ~= nil then
                        local toggle = controlFrame:FindFirstChild("Switch")
                        if toggle and toggle:IsA("Frame") then
                            local knob = toggle:FindFirstChild("Knob")
                            if knob then
                                local enabled = data.Toggles[key]
                                local theme = window.Theme
                                toggle.BackgroundColor3 = enabled and theme.Accent or theme.BackgroundLayer4
                                knob.Position = enabled and UDim2.new(1, -17, 0, 1) or UDim2.new(0, 1, 0, 1)
                            end
                        end
                    end

                    if data.Sliders and data.Sliders[key] ~= nil then
                        local sliderBar = controlFrame:FindFirstChild("Frame")
                        if sliderBar and sliderBar:IsA("Frame") and sliderBar.Size.Y.Offset == 6 then
                            local fill = sliderBar:FindFirstChildOfClass("Frame")
                            if fill then
                                fill.Size = UDim2.new(data.Sliders[key], 0, 1, 0)
                            end
                        end
                    end

                    if data.Dropdowns and data.Dropdowns[key] ~= nil then
                        local dropdownBox = controlFrame:FindFirstChild("TextButton")
                        if dropdownBox and dropdownBox:IsA("TextButton") then
                            dropdownBox.Text = data.Dropdowns[key]
                        end
                    end

                    if data.Colors and data.Colors[key] ~= nil then
                        local preview = controlFrame:FindFirstChild("Frame")
                        if preview and preview:IsA("Frame") and preview.Size == UDim2.new(0, 32, 0, 32) then
                            local c = data.Colors[key]
                            preview.BackgroundColor3 = Color3.new(c.R, c.G, c.B)
                        end
                    end

                    if data.Keybinds and data.Keybinds[key] ~= nil then
                        local keybindBox = controlFrame:FindFirstChild("TextButton")
                        if keybindBox and keybindBox:IsA("TextButton") then
                            keybindBox.Text = data.Keybinds[key]
                        end
                    end
                end
            end
        end
    end
end

function SaveManager:Delete(name: string)
    local folder = getConfigFolder(self.FolderName)
    local value = getConfigValue(folder, name)
    if value then
        value:Destroy()
    end
end

return SaveManager
