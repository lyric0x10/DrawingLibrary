-- Roblox Drawing Library Implementation
-- Replicates Synapse X Drawing Library functionality using Roblox GUI elements

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Create main ScreenGui container
local DrawingGui = Instance.new("ScreenGui")
DrawingGui.Name = "DrawingLibrary"
DrawingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
DrawingGui.ResetOnSpawn = false
DrawingGui.Parent = PlayerGui

-- Drawing Library Module
local DrawingLibrary = {}
DrawingLibrary.__index = DrawingLibrary

-- Static properties and methods
local DrawingObjects = {}
local NextZIndex = 1

-- Utility functions
local function CreateFrame(parent)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent or DrawingGui
    return frame
end

local function CreateTextLabel(parent)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Parent = parent or DrawingGui
    return label
end

local function CreateImageLabel(parent)
    local label = Instance.new("ImageLabel")
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Parent = parent or DrawingGui
    return label
end

local function Vector2ToUDim2(vector2)
    return UDim2.new(0, vector2.X, 0, vector2.Y)
end

local function Color3ToHex(color3)
    return string.format("#%02X%02X%02X", 
        math.floor(color3.R * 255), 
        math.floor(color3.G * 255), 
        math.floor(color3.B * 255))
end

-- Base Drawing Object Class
local DrawingObject = {}
DrawingObject.__index = DrawingObject

function DrawingObject.new(objectType)
    local self = setmetatable({}, DrawingObject)
    self.Type = objectType
    self.Visible = true
    self.ZIndex = NextZIndex
    self.Transparency = 0
    self.Color = Color3.new(1, 1, 1)
    self.Position = Vector2.new(0, 0)
    self.Size = Vector2.new(100, 100)
    self._destroyed = false
    
    NextZIndex = NextZIndex + 1
    table.insert(DrawingObjects, self)
    
    return self
end

function DrawingObject:Remove()
    if self._destroyed then return end
    
    self._destroyed = true
    if self._instance then
        self._instance:Destroy()
    end
    
    -- Remove from DrawingObjects table
    for i, obj in ipairs(DrawingObjects) do
        if obj == self then
            table.remove(DrawingObjects, i)
            break
        end
    end
end

function DrawingObject:Destroy()
    self:Remove()
end

function DrawingObject:_UpdateProperty(property, value)
    if self._destroyed then return end
    
    if property == "Visible" then
        if self._instance then
            self._instance.Visible = value
        end
    elseif property == "ZIndex" then
        if self._instance then
            self._instance.ZIndex = value
        end
    elseif property == "Position" then
        if self._instance then
            self._instance.Position = Vector2ToUDim2(value)
        end
    elseif property == "Transparency" then
        self:_UpdateTransparency()
    elseif property == "Color" then
        self:_UpdateColor()
    end
end

function DrawingObject:_UpdateTransparency()
    -- Override in subclasses
end

function DrawingObject:_UpdateColor()
    -- Override in subclasses
end

-- Line Drawing Object
local Line = setmetatable({}, {__index = DrawingObject})
Line.__index = Line

function Line.new()
    local self = setmetatable(DrawingObject.new("Line"), Line)
    self.From = Vector2.new(0, 0)
    self.To = Vector2.new(100, 100)
    self.Thickness = 1
    
    self._instance = CreateFrame()
    self._instance.BackgroundColor3 = self.Color
    self._instance.BorderSizePixel = 0
    self._instance.ZIndex = self.ZIndex
    
    self:_UpdateLine()
    return self
end

function Line:_UpdateLine()
    if self._destroyed or not self._instance then return end
    
    local from = self.From
    local to = self.To
    local thickness = math.max(1, self.Thickness)
    
    local distance = (to - from).Magnitude
    local angle = math.atan2(to.Y - from.Y, to.X - from.X)
    
    local center = Vector2.new((from.X + to.X) / 2, (from.Y + to.Y) / 2)
    
    self._instance.Size = UDim2.new(0, distance, 0, thickness)
    self._instance.Position = UDim2.new(0, center.X - distance/2, 0, center.Y - thickness/2)
    self._instance.Rotation = math.deg(angle)
end

function Line:_UpdateTransparency()
    if self._instance then
        self._instance.BackgroundTransparency = self.Transparency
    end
end

function Line:_UpdateColor()
    if self._instance then
        self._instance.BackgroundColor3 = self.Color
    end
end

function Line:_UpdateProperty(property, value)
    DrawingObject._UpdateProperty(self, property, value)
    if property == "From" or property == "To" or property == "Thickness" then
        self:_UpdateLine()
    end
end

-- Square Drawing Object
local Square = setmetatable({}, {__index = DrawingObject})
Square.__index = Square

function Square.new()
    local self = setmetatable(DrawingObject.new("Square"), Square)
    self.Thickness = 1
    self.Filled = false
    
    self._instance = CreateFrame()
    self._instance.BackgroundTransparency = 1
    self._instance.BorderSizePixel = 0
    self._instance.ZIndex = self.ZIndex
    
    -- Create outline frames
    self._outlineFrames = {}
    for i = 1, 4 do
        local frame = CreateFrame(self._instance)
        frame.BackgroundColor3 = self.Color
        frame.BorderSizePixel = 0
        table.insert(self._outlineFrames, frame)
    end
    
    self:_UpdateSquare()
    return self
end

function Square:_UpdateSquare()
    if self._destroyed or not self._instance then return end
    
    local pos = self.Position
    local size = self.Size
    local thickness = math.max(1, self.Thickness)
    
    self._instance.Position = Vector2ToUDim2(pos)
    self._instance.Size = Vector2ToUDim2(size)
    
    if self.Filled then
        self._instance.BackgroundTransparency = self.Transparency
        self._instance.BackgroundColor3 = self.Color
        for _, frame in ipairs(self._outlineFrames) do
            frame.Visible = false
        end
    else
        self._instance.BackgroundTransparency = 1
        
        -- Top
        self._outlineFrames[1].Position = UDim2.new(0, 0, 0, 0)
        self._outlineFrames[1].Size = UDim2.new(1, 0, 0, thickness)
        
        -- Bottom
        self._outlineFrames[2].Position = UDim2.new(0, 0, 1, -thickness)
        self._outlineFrames[2].Size = UDim2.new(1, 0, 0, thickness)
        
        -- Left
        self._outlineFrames[3].Position = UDim2.new(0, 0, 0, 0)
        self._outlineFrames[3].Size = UDim2.new(0, thickness, 1, 0)
        
        -- Right
        self._outlineFrames[4].Position = UDim2.new(1, -thickness, 0, 0)
        self._outlineFrames[4].Size = UDim2.new(0, thickness, 1, 0)
        
        for _, frame in ipairs(self._outlineFrames) do
            frame.Visible = true
        end
    end
end

function Square:_UpdateTransparency()
    if self._instance then
        if self.Filled then
            self._instance.BackgroundTransparency = self.Transparency
        else
            for _, frame in ipairs(self._outlineFrames) do
                frame.BackgroundTransparency = self.Transparency
            end
        end
    end
end

function Square:_UpdateColor()
    if self._instance then
        self._instance.BackgroundColor3 = self.Color
        for _, frame in ipairs(self._outlineFrames) do
            frame.BackgroundColor3 = self.Color
        end
    end
end

function Square:_UpdateProperty(property, value)
    DrawingObject._UpdateProperty(self, property, value)
    if property == "Size" or property == "Thickness" or property == "Filled" then
        self:_UpdateSquare()
    end
end

-- Circle Drawing Object
local Circle = setmetatable({}, {__index = DrawingObject})
Circle.__index = Circle

function Circle.new()
    local self = setmetatable(DrawingObject.new("Circle"), Circle)
    self.Thickness = 1
    self.Filled = false
    self.Radius = 50
    self.NumSides = 32
    
    self._instance = CreateFrame()
    self._instance.BackgroundTransparency = 1
    self._instance.BorderSizePixel = 0
    self._instance.ZIndex = self.ZIndex
    
    -- Create circle using UICorner for filled circles
    self._fillFrame = CreateFrame(self._instance)
    self._fillFrame.BackgroundColor3 = self.Color
    self._fillFrame.BorderSizePixel = 0
    
    self._corner = Instance.new("UICorner")
    self._corner.Parent = self._fillFrame
    
    -- Create outline frames for non-filled circles
    self._outlineFrames = {}
    
    self:_UpdateCircle()
    return self
end

function Circle:_UpdateCircle()
    if self._destroyed or not self._instance then return end
    
    local pos = self.Position
    local radius = math.max(1, self.Radius)
    local size = Vector2.new(radius * 2, radius * 2)
    
    self._instance.Position = Vector2ToUDim2(Vector2.new(pos.X - radius, pos.Y - radius))
    self._instance.Size = Vector2ToUDim2(size)
    
    if self.Filled then
        self._fillFrame.Visible = true
        self._fillFrame.Position = UDim2.new(0, 0, 0, 0)
        self._fillFrame.Size = UDim2.new(1, 0, 1, 0)
        self._fillFrame.BackgroundTransparency = self.Transparency
        self._corner.CornerRadius = UDim.new(0.5, 0)
        
        -- Hide outline frames
        for _, frame in ipairs(self._outlineFrames) do
            frame:Destroy()
        end
        self._outlineFrames = {}
    else
        self._fillFrame.Visible = false
        
        -- Create outline using multiple small frames (simplified approach)
        -- Clear existing outline frames
        for _, frame in ipairs(self._outlineFrames) do
            frame:Destroy()
        end
        self._outlineFrames = {}
        
        -- Create outer and inner circles for outline effect
        local outerFrame = CreateFrame(self._instance)
        outerFrame.Position = UDim2.new(0, 0, 0, 0)
        outerFrame.Size = UDim2.new(1, 0, 1, 0)
        outerFrame.BackgroundColor3 = self.Color
        outerFrame.BackgroundTransparency = self.Transparency
        
        local outerCorner = Instance.new("UICorner")
        outerCorner.CornerRadius = UDim.new(0.5, 0)
        outerCorner.Parent = outerFrame
        
        local innerFrame = CreateFrame(outerFrame)
        local thickness = math.max(1, self.Thickness)
        innerFrame.Position = UDim2.new(0, thickness, 0, thickness)
        innerFrame.Size = UDim2.new(1, -thickness * 2, 1, -thickness * 2)
        innerFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        innerFrame.BackgroundTransparency = 1
        
        local innerCorner = Instance.new("UICorner")
        innerCorner.CornerRadius = UDim.new(0.5, 0)
        innerCorner.Parent = innerFrame
        
        table.insert(self._outlineFrames, outerFrame)
        table.insert(self._outlineFrames, innerFrame)
    end
end

function Circle:_UpdateTransparency()
    if self._instance then
        if self.Filled then
            self._fillFrame.BackgroundTransparency = self.Transparency
        else
            for _, frame in ipairs(self._outlineFrames) do
                if frame.BackgroundTransparency ~= 1 then
                    frame.BackgroundTransparency = self.Transparency
                end
            end
        end
    end
end

function Circle:_UpdateColor()
    if self._instance then
        self._fillFrame.BackgroundColor3 = self.Color
        for _, frame in ipairs(self._outlineFrames) do
            if frame.BackgroundTransparency ~= 1 then
                frame.BackgroundColor3 = self.Color
            end
        end
    end
end

function Circle:_UpdateProperty(property, value)
    DrawingObject._UpdateProperty(self, property, value)
    if property == "Radius" or property == "Thickness" or property == "Filled" then
        self:_UpdateCircle()
    end
end

-- Triangle Drawing Object
local Triangle = setmetatable({}, {__index = DrawingObject})
Triangle.__index = Triangle

function Triangle.new()
    local self = setmetatable(DrawingObject.new("Triangle"), Triangle)
    self.PointA = Vector2.new(0, 0)
    self.PointB = Vector2.new(50, 100)
    self.PointC = Vector2.new(100, 0)
    self.Thickness = 1
    self.Filled = false
    
    self._instance = CreateFrame()
    self._instance.BackgroundTransparency = 1
    self._instance.BorderSizePixel = 0
    self._instance.ZIndex = self.ZIndex
    
    -- Create lines for triangle outline
    self._lines = {}
    for i = 1, 3 do
        local line = CreateFrame(self._instance)
        line.BackgroundColor3 = self.Color
        line.BorderSizePixel = 0
        table.insert(self._lines, line)
    end
    
    self:_UpdateTriangle()
    return self
end

function Triangle:_UpdateTriangle()
    if self._destroyed or not self._instance then return end
    
    local a, b, c = self.PointA, self.PointB, self.PointC
    
    -- Calculate bounding box
    local minX = math.min(a.X, b.X, c.X)
    local maxX = math.max(a.X, b.X, c.X)
    local minY = math.min(a.Y, b.Y, c.Y)
    local maxY = math.max(a.Y, b.Y, c.Y)
    
    local size = Vector2.new(maxX - minX, maxY - minY)
    local pos = Vector2.new(minX, minY)
    
    self._instance.Position = Vector2ToUDim2(pos)
    self._instance.Size = Vector2ToUDim2(size)
    
    -- Adjust points relative to the frame
    local relA = Vector2.new(a.X - minX, a.Y - minY)
    local relB = Vector2.new(b.X - minX, b.Y - minY)
    local relC = Vector2.new(c.X - minX, c.Y - minY)
    
    -- Create lines for each side
    local sides = {
        {relA, relB},
        {relB, relC},
        {relC, relA}
    }
    
    for i, side in ipairs(sides) do
        local from, to = side[1], side[2]
        local line = self._lines[i]
        
        local distance = (to - from).Magnitude
        local angle = math.atan2(to.Y - from.Y, to.X - from.X)
        local center = Vector2.new((from.X + to.X) / 2, (from.Y + to.Y) / 2)
        local thickness = math.max(1, self.Thickness)
        
        line.Size = UDim2.new(0, distance, 0, thickness)
        line.Position = UDim2.new(0, center.X - distance/2, 0, center.Y - thickness/2)
        line.Rotation = math.deg(angle)
        line.BackgroundTransparency = self.Transparency
    end
end

function Triangle:_UpdateTransparency()
    if self._instance then
        for _, line in ipairs(self._lines) do
            line.BackgroundTransparency = self.Transparency
        end
    end
end

function Triangle:_UpdateColor()
    if self._instance then
        for _, line in ipairs(self._lines) do
            line.BackgroundColor3 = self.Color
        end
    end
end

function Triangle:_UpdateProperty(property, value)
    DrawingObject._UpdateProperty(self, property, value)
    if property == "PointA" or property == "PointB" or property == "PointC" or property == "Thickness" then
        self:_UpdateTriangle()
    end
end

-- Text Drawing Object
local Text = setmetatable({}, {__index = DrawingObject})
Text.__index = Text

function Text.new()
    local self = setmetatable(DrawingObject.new("Text"), Text)
    self.Text = ""
    self.Font = Enum.Font.Arial
    self.Size = 18
    self.Center = false
    self.Outline = false
    self.OutlineColor = Color3.new(0, 0, 0)
    
    self._instance = CreateTextLabel()
    self._instance.BackgroundTransparency = 1
    self._instance.TextColor3 = self.Color
    self._instance.Font = self.Font
    self._instance.TextSize = self.Size
    self._instance.ZIndex = self.ZIndex
    self._instance.TextStrokeTransparency = 1
    
    self:_UpdateText()
    return self
end

function Text:_UpdateText()
    if self._destroyed or not self._instance then return end
    
    self._instance.Text = self.Text
    self._instance.Position = Vector2ToUDim2(self.Position)
    self._instance.Font = self.Font
    self._instance.TextSize = self.Size
    
    -- Auto-size based on text content
    local textBounds = game:GetService("TextService"):GetTextSize(
        self.Text,
        self.Size,
        self.Font,
        Vector2.new(math.huge, math.huge)
    )
    
    self._instance.Size = UDim2.new(0, textBounds.X, 0, textBounds.Y)
    
    if self.Center then
        self._instance.Position = UDim2.new(0, self.Position.X - textBounds.X/2, 0, self.Position.Y - textBounds.Y/2)
    end
    
    if self.Outline then
        self._instance.TextStrokeTransparency = 0
        self._instance.TextStrokeColor3 = self.OutlineColor
    else
        self._instance.TextStrokeTransparency = 1
    end
end

function Text:_UpdateTransparency()
    if self._instance then
        self._instance.TextTransparency = self.Transparency
    end
end

function Text:_UpdateColor()
    if self._instance then
        self._instance.TextColor3 = self.Color
    end
end

function Text:_UpdateProperty(property, value)
    DrawingObject._UpdateProperty(self, property, value)
    if property == "Text" or property == "Font" or property == "Size" or 
       property == "Center" or property == "Outline" or property == "OutlineColor" then
        self:_UpdateText()
    end
end

-- Image Drawing Object
local Image = setmetatable({}, {__index = DrawingObject})
Image.__index = Image

function Image.new()
    local self = setmetatable(DrawingObject.new("Image"), Image)
    self.Data = ""
    self.Uri = ""
    self.Rounding = 0
    
    self._instance = CreateImageLabel()
    self._instance.BackgroundTransparency = 1
    self._instance.ScaleType = Enum.ScaleType.Stretch
    self._instance.ZIndex = self.ZIndex
    
    self._corner = Instance.new("UICorner")
    self._corner.Parent = self._instance
    
    self:_UpdateImage()
    return self
end

function Image:_UpdateImage()
    if self._destroyed or not self._instance then return end
    
    self._instance.Position = Vector2ToUDim2(self.Position)
    self._instance.Size = Vector2ToUDim2(self.Size)
    
    if self.Uri ~= "" then
        self._instance.Image = self.Uri
    end
    
    if self.Rounding > 0 then
        self._corner.CornerRadius = UDim.new(0, self.Rounding)
    else
        self._corner.CornerRadius = UDim.new(0, 0)
    end
end

function Image:_UpdateTransparency()
    if self._instance then
        self._instance.ImageTransparency = self.Transparency
    end
end

function Image:_UpdateColor()
    if self._instance then
        self._instance.ImageColor3 = self.Color
    end
end

function Image:_UpdateProperty(property, value)
    DrawingObject._UpdateProperty(self, property, value)
    if property == "Uri" or property == "Rounding" then
        self:_UpdateImage()
    end
end

-- Quad Drawing Object
local Quad = setmetatable({}, {__index = DrawingObject})
Quad.__index = Quad

function Quad.new()
    local self = setmetatable(DrawingObject.new("Quad"), Quad)
    self.PointA = Vector2.new(0, 0)
    self.PointB = Vector2.new(100, 0)
    self.PointC = Vector2.new(100, 100)
    self.PointD = Vector2.new(0, 100)
    self.Thickness = 1
    self.Filled = false
    
    self._instance = CreateFrame()
    self._instance.BackgroundTransparency = 1
    self._instance.BorderSizePixel = 0
    self._instance.ZIndex = self.ZIndex
    
    -- Create lines for quad outline
    self._lines = {}
    for i = 1, 4 do
        local line = CreateFrame(self._instance)
        line.BackgroundColor3 = self.Color
        line.BorderSizePixel = 0
        table.insert(self._lines, line)
    end
    
    self:_UpdateQuad()
    return self
end

function Quad:_UpdateQuad()
    if self._destroyed or not self._instance then return end
    
    local a, b, c, d = self.PointA, self.PointB, self.PointC, self.PointD
    
    -- Calculate bounding box
    local minX = math.min(a.X, b.X, c.X, d.X)
    local maxX = math.max(a.X, b.X, c.X, d.X)
    local minY = math.min(a.Y, b.Y, c.Y, d.Y)
    local maxY = math.max(a.Y, b.Y, c.Y, d.Y)
    
    local size = Vector2.new(maxX - minX, maxY - minY)
    local pos = Vector2.new(minX, minY)
    
    self._instance.Position = Vector2ToUDim2(pos)
    self._instance.Size = Vector2ToUDim2(size)
    
    -- Adjust points relative to the frame
    local relA = Vector2.new(a.X - minX, a.Y - minY)
    local relB = Vector2.new(b.X - minX, b.Y - minY)
    local relC = Vector2.new(c.X - minX, c.Y - minY)
    local relD = Vector2.new(d.X - minX, d.Y - minY)
    
    -- Create lines for each side
    local sides = {
        {relA, relB},
        {relB, relC},
        {relC, relD},
        {relD, relA}
    }
    
    for i, side in ipairs(sides) do
        local from, to = side[1], side[2]
        local line = self._lines[i]
        
        local distance = (to - from).Magnitude
        local angle = math.atan2(to.Y - from.Y, to.X - from.X)
        local center = Vector2.new((from.X + to.X) / 2, (from.Y + to.Y) / 2)
        local thickness = math.max(1, self.Thickness)
        
        line.Size = UDim2.new(0, distance, 0, thickness)
        line.Position = UDim2.new(0, center.X - distance/2, 0, center.Y - thickness/2)
        line.Rotation = math.deg(angle)
        line.BackgroundTransparency = self.Transparency
    end
end

function Quad:_UpdateTransparency()
    if self._instance then
        for _, line in ipairs(self._lines) do
            line.BackgroundTransparency = self.Transparency
        end
    end
end

function Quad:_UpdateColor()
    if self._instance then
        for _, line in ipairs(self._lines) do
            line.BackgroundColor3 = self.Color
        end
    end
end

function Quad:_UpdateProperty(property, value)
    DrawingObject._UpdateProperty(self, property, value)
    if property == "PointA" or property == "PointB" or property == "PointC" or 
       property == "PointD" or property == "Thickness" then
        self:_UpdateQuad()
    end
end

-- Property metatable for all drawing objects
local function CreatePropertyMetatable(obj)
    return setmetatable({}, {
        __index = function(t, k)
            return obj[k]
        end,
        __newindex = function(t, k, v)
            if obj._destroyed then return end
            obj[k] = v
            obj:_UpdateProperty(k, v)
        end
    })
end

-- Apply property metatable to all drawing objects
for _, class in pairs({Line, Square, Circle, Triangle, Text, Image, Quad}) do
    local originalNew = class.new
    class.new = function(...)
        local obj = originalNew(...)
        return CreatePropertyMetatable(obj)
    end
end

-- Main Drawing API
local Drawing = {}

function Drawing.new(objectType)
    local objectType = objectType:lower()
    
    if objectType == "line" then
        return Line.new()
    elseif objectType == "square" then
        return Square.new()
    elseif objectType == "circle" then
        return Circle.new()
    elseif objectType == "triangle" then
        return Triangle.new()
    elseif objectType == "text" then
        return Text.new()
    elseif objectType == "image" then
        return Image.new()
    elseif objectType == "quad" then
        return Quad.new()
    else
        error("Invalid drawing object type: " .. tostring(objectType))
    end
end

function Drawing.clear()
    for i = #DrawingObjects, 1, -1 do
        DrawingObjects[i]:Remove()
    end
    DrawingObjects = {}
    NextZIndex = 1
end

-- Cleanup on game shutdown
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == Player then
        Drawing.clear()
    end
end)
