-- ============================================
-- FROGASAURUS.LOL - NO-MODULE (UPDATE PROOF)
-- ============================================

local reps = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local runs = game:GetService("RunService")
local cs = game:GetService("CollectionService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local lplr = plrs.LocalPlayer
local cam = workspace.CurrentCamera

getgenv().Config = getgenv().Config or {
    FOVRadius = 1500,
    ShowFOV = true,
    Enabled = true,
    ESPEnabled = false,
    SilentAim = false,
    MaxDistance = 1000,
}

-- ============================================
-- 1. ESP MODULE
-- ============================================
local ESP = {}
ESP.Config = {
	Enabled = false,
	ShowTracers = true,
	TracerOrigin = "Center",
	TracerThickness = 2,
	TeammatesOnly = false,
	ShowEnemies = true,
	ShowNames = true,
	ShowDistance = true,
	MaxDistance = getgenv().Config.MaxDistance,
	FillTransparency = 0.6,
	OutlineTransparency = 0,
	TeamColor = Color3.fromRGB(0, 255, 120),
	EnemyColor = Color3.fromRGB(255, 60, 60),
    DeadColor = Color3.fromRGB(120, 120, 120),
}

local CONFIG = ESP.Config
local tracked = {}
local connections = {}

local espScreenGui = Instance.new("ScreenGui")
espScreenGui.Name = "ESPTracers"
espScreenGui.ResetOnSpawn = false
espScreenGui.IgnoreGuiInset = true
espScreenGui.DisplayOrder = 998
espScreenGui.Parent = lplr:WaitForChild("PlayerGui")

function ESP.SetEnabled(value) CONFIG.Enabled = value end
function ESP.SetTracers(value) CONFIG.ShowTracers = value end
function ESP.SetNames(value) CONFIG.ShowNames = value end

local function isTeammate(player)
	return lplr.Team ~= nil and player.Team == lplr.Team
end

local function cleanup(player)
	local data = tracked[player]
	if not data then return end
	if data.highlight then data.highlight:Destroy() end
	if data.billboard then data.billboard:Destroy() end
	if data.tracer then data.tracer:Destroy() end
	tracked[player] = nil
end

local function createESP(player, character)
	cleanup(player)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end
	task.wait(0.15)

	local highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = CONFIG.FillTransparency
	highlight.OutlineTransparency = CONFIG.OutlineTransparency
	highlight.Adornee = character
	highlight.Enabled = CONFIG.Enabled
	highlight.Parent = character

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 40)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = root
	billboard.Enabled = CONFIG.Enabled
	billboard.Parent = character

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextStrokeTransparency = 0.4
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = billboard

	local tracer = Instance.new("Frame")
	tracer.AnchorPoint = Vector2.new(0.5, 0.5)
	tracer.BorderSizePixel = 0
	tracer.Visible = false
	tracer.Parent = espScreenGui

	tracked[player] = { highlight = highlight, billboard = billboard, label = label, tracer = tracer, root = root }
end

local function onPlayerAdded(player)
	if player == lplr then return end
	if player.Character then task.spawn(createESP, player, player.Character) end
	table.insert(connections, player.CharacterAdded:Connect(function(character) createESP(player, character) end))
	table.insert(connections, player.CharacterRemoving:Connect(function() cleanup(player) end))
end

for _, player in ipairs(plrs:GetPlayers()) do onPlayerAdded(player) end
plrs.PlayerAdded:Connect(onPlayerAdded)
plrs.PlayerRemoving:Connect(cleanup)

runs.RenderStepped:Connect(function()
	local screenSize = cam.ViewportSize
	local startPoint = CONFIG.TracerOrigin == "Bottom" and Vector2.new(screenSize.X / 2, screenSize.Y) or Vector2.new(screenSize.X / 2, screenSize.Y / 2)

	for player, data in pairs(tracked) do
		if not data.root or not data.root.Parent or not player.Character then continue end

		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local isDead = humanoid and humanoid.Health <= 0
		local distance = math.floor((cam.CFrame.Position - data.root.Position).Magnitude)
		local isTeam = isTeammate(player)
		
		local show = CONFIG.Enabled and (distance <= CONFIG.MaxDistance)
		
		if CONFIG.TeammatesOnly and not isTeam then show = false end
		if not CONFIG.ShowEnemies and not isTeam then show = false end
		
		local color = isTeam and CONFIG.TeamColor or CONFIG.EnemyColor
		if isDead then color = CONFIG.DeadColor end

		data.highlight.Enabled = show
		data.highlight.FillColor = color
		data.highlight.OutlineColor = color
		
		data.billboard.Enabled = show and CONFIG.ShowNames
		data.label.TextColor3 = color
		
		local nameText = isDead and (player.Name .. " [DEAD]") or player.Name
		data.label.Text = CONFIG.ShowDistance and string.format("%s [%dm]", nameText, distance) or nameText

		if show and CONFIG.ShowTracers and not isDead then
			local screenPos, onScreen = cam:WorldToViewportPoint(data.root.Position)
			if onScreen then
				data.tracer.Visible = true
				local endPoint = Vector2.new(screenPos.X, screenPos.Y)
				local length = (endPoint - startPoint).Magnitude
				local angle = math.atan2(endPoint.Y - startPoint.Y, endPoint.X - startPoint.X)
				
				data.tracer.BackgroundColor3 = color
				data.tracer.Size = UDim2.new(0, length, 0, CONFIG.TracerThickness)
				data.tracer.Position = UDim2.new(0, (startPoint.X + endPoint.X) / 2, 0, (startPoint.Y + endPoint.Y) / 2)
				data.tracer.Rotation = math.deg(angle)
			else
				data.tracer.Visible = false
			end
		else
			data.tracer.Visible = false
		end
	end
end)

-- ============================================
-- 2. PRO UI LIBRARY
-- ============================================
local parentGui = Instance.new("ScreenGui")
parentGui.Name = "FrogasaurusUI"
parentGui.ResetOnSpawn = false
parentGui.IgnoreGuiInset = true
parentGui.DisplayOrder = 999
parentGui.Parent = lplr:WaitForChild("PlayerGui")

local COLORS = {
    bg = Color3.fromRGB(15, 15, 18),
    bgAlt = Color3.fromRGB(22, 22, 26),
    stroke = Color3.fromRGB(50, 50, 65),
    accent = Color3.fromRGB(100, 80, 255),
    accent2 = Color3.fromRGB(180, 100, 255),
    text = Color3.fromRGB(245, 245, 255),
    textDim = Color3.fromRGB(160, 160, 180),
    off = Color3.fromRGB(60, 60, 75),
}

local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function corner(parent, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local function stroke(parent, color, thick)
    return new("UIStroke", { Color = color or COLORS.stroke, Thickness = thick or 1.5, Parent = parent })
end

local toggleBtn = new("TextButton", {
    Size = UDim2.new(0, 52, 0, 52),
    Position = UDim2.new(0, 20, 0.5, -26),
    BackgroundColor3 = COLORS.bgAlt,
    Text = "FROG",
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    AutoButtonColor = false,
    Parent = parentGui,
})
corner(toggleBtn, 26)
local toggleStroke = stroke(toggleBtn, COLORS.accent, 2)

local uiGradient = new("UIGradient", {
    Color = ColorSequence.new(COLORS.accent, COLORS.accent2),
    Rotation = 45,
    Parent = toggleStroke
})

local main = new("Frame", {
    Size = UDim2.new(0, 275, 0, 440),
    Position = UDim2.new(0, 40, 0, 60),
    BackgroundColor3 = COLORS.bg,
    Visible = false,
    Parent = parentGui,
})
corner(main, 14)
stroke(main, COLORS.stroke, 1.5)

local topGlow = new("Frame", {
    Size = UDim2.new(1, -20, 0, 3),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Parent = main,
})
corner(topGlow, 2)
local glowGradient = new("UIGradient", {
    Color = ColorSequence.new(COLORS.accent, COLORS.accent2),
    Rotation = 0,
    Parent = topGlow
})

local titleBar = new("Frame", {
    Size = UDim2.new(1, 0, 0, 45),
    BackgroundColor3 = COLORS.bgAlt,
    Parent = main,
})
corner(titleBar, 14)
new("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = COLORS.bgAlt, Parent = titleBar })

new("TextLabel", {
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.new(0, 18, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "frogasaurus.lol",
    TextSize = 16,
    TextColor3 = COLORS.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = titleBar,
})

local bottomBar = new("Frame", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 1, -18),
    BackgroundColor3 = COLORS.bgAlt,
    Parent = main,
})
corner(bottomBar, 14)

local uiVisible = false
local dragging, dragStart, startPos
local btnDragging = false
local btnDragStart, btnStartPos
local dragMoved = false
local TAP_THRESHOLD = 6

local function startDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end
titleBar.InputBegan:Connect(startDrag)
bottomBar.InputBegan:Connect(startDrag)

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        dragMoved = false
        btnDragStart = input.Position
        btnStartPos = toggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                btnDragging = false
                if not dragMoved then
                    uiVisible = not uiVisible
                    main.Visible = uiVisible
                end
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - btnDragStart
        if delta.Magnitude > TAP_THRESHOLD then dragMoved = true end
        toggleBtn.Position = UDim2.new(0, btnStartPos.X.Offset + delta.X, 0, btnStartPos.Y.Offset + delta.Y)
    elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
    end
end)

local tabBar = new("Frame", { Size = UDim2.new(1, -20, 0, 34), Position = UDim2.new(0, 10, 0, 55), BackgroundTransparency = 1, Parent = main })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = tabBar })
local tabHolder = new("Frame", { Size = UDim2.new(1, -20, 1, -115), Position = UDim2.new(0, 10, 0, 95), BackgroundTransparency = 1, Parent = main })

local tabs = {}
local function createTab(name, order)
    local btn = new("TextButton", { Size = UDim2.new(0, 78, 1, 0), BackgroundColor3 = COLORS.bgAlt, Text = name, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = COLORS.textDim, AutoButtonColor = false, LayoutOrder = order, Parent = tabBar })
    corner(btn, 6); stroke(btn, COLORS.stroke, 1)
    local page = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = tabHolder })
    tabs[name] = { Button = btn, Page = page }
    btn.MouseButton1Click:Connect(function()
        for n, t in pairs(tabs) do
            t.Page.Visible = (n == name)
            TS:Create(t.Button, TweenInfo.new(0.15), {
                BackgroundColor3 = (n == name) and COLORS.accent or COLORS.bgAlt,
                TextColor3 = (n == name) and COLORS.text or COLORS.textDim
            }):Play()
        end
    end)
    return page
end

local generalPage = createTab("General", 1)
local visualPage  = createTab("Visual", 2)
local configPage  = createTab("Config", 3)

local function makeSwitch(parent, initial, callback, posY)
    local on = initial
    local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 42), Position = UDim2.new(0, 0, 0, posY), BackgroundColor3 = COLORS.bgAlt, Parent = parent })
    corner(holder, 8); stroke(holder, COLORS.stroke, 1)
    
    local track = new("Frame", { Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -52, 0.5, -11), BackgroundColor3 = on and COLORS.accent or COLORS.off, Parent = holder })
    corner(track, 11)
    local knob = new("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.new(1,1,1), Parent = track })
    corner(knob, 8)
    
    local btn = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = holder })
    btn.MouseButton1Click:Connect(function()
        on = not on
        track.BackgroundColor3 = on and COLORS.accent or COLORS.off
        knob.Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        if callback then callback(on) end
    end)
end

local function makeLabeledSwitch(parent, text, initial, callback, posY)
    makeSwitch(parent, initial, callback, posY)
    new("TextLabel", { Size = UDim2.new(1, -60, 0, 42), Position = UDim2.new(0, 16, 0, posY), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = text, TextSize = 13, TextColor3 = COLORS.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent })
end

-- General Tab
new("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "GENERAL", TextSize = 10, TextColor3 = COLORS.textDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = generalPage })
makeLabeledSwitch(generalPage, "Enable Aim Assist", getgenv().Config.Enabled, function(v) getgenv().Config.Enabled = v end, 24)

new("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 80), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "FOV & DISTANCE", TextSize = 10, TextColor3 = COLORS.textDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = generalPage })
do
    local fovRow = new("Frame", { Size = UDim2.new(1, 0, 0, 64), Position = UDim2.new(0, 0, 0, 102), BackgroundColor3 = COLORS.bgAlt, Parent = generalPage })
    corner(fovRow, 8); stroke(fovRow, COLORS.stroke, 1)
    new("TextLabel", { Size = UDim2.new(1, -20, 0, 22), Position = UDim2.new(0, 16, 0, 8), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "FOV Radius", TextSize = 13, TextColor3 = COLORS.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = fovRow })
    
    local fovTextBox = new("TextBox", { Size = UDim2.new(0, 50, 0, 24), Position = UDim2.new(1, -66, 0, 8), BackgroundColor3 = COLORS.bg, Text = tostring(getgenv().Config.FOVRadius), TextColor3 = COLORS.accent2, Font = Enum.Font.GothamBold, TextSize = 13, ClearTextOnFocus = false, Parent = fovRow })
    corner(fovTextBox, 4); stroke(fovTextBox, COLORS.stroke, 1)
    
    local sliderBg = new("Frame", { Size = UDim2.new(1, -32, 0, 8), Position = UDim2.new(0, 16, 0, 44), BackgroundColor3 = COLORS.off, Parent = fovRow })
    corner(sliderBg, 4)
    local sliderFill = new("Frame", { Size = UDim2.new((getgenv().Config.FOVRadius - 50) / 4950, 0, 1, 0), BackgroundColor3 = COLORS.accent, Parent = sliderBg })
    corner(sliderFill, 4)
    local sliderBtn = new("TextButton", { Size = UDim2.new(1, 12, 0, 24), Position = UDim2.new(0, -6, 0.5, -12), BackgroundTransparency = 1, Text = "", Parent = sliderBg })
    
    local function updateFov(val)
        val = math.clamp(tonumber(val) or 50, 50, 5000)
        getgenv().Config.FOVRadius = val
        fovTextBox.Text = tostring(val)
        sliderFill.Size = UDim2.new((val - 50) / 4950, 0, 1, 0)
    end

    fovTextBox.FocusLost:Connect(function() updateFov(fovTextBox.Text) end)
    
    local sDrag = false
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sDrag = true end
    end)
    UIS.InputChanged:Connect(function(input)
        if sDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(50 + 4950 * rel)
            updateFov(val)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sDrag = false end
    end)
end
makeLabeledSwitch(generalPage, "Show FOV Circle", getgenv().Config.ShowFOV, function(v) getgenv().Config.ShowFOV = v end, 178)

-- Visual Tab
new("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "VISUALS", TextSize = 10, TextColor3 = COLORS.textDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = visualPage })
makeLabeledSwitch(visualPage, "Enable ESP", getgenv().Config.ESPEnabled, function(v) getgenv().Config.ESPEnabled = v; ESP.SetEnabled(v) end, 24)
makeLabeledSwitch(visualPage, "Name Tag", true, function(v) ESP.SetNames(v) end, 80)
makeLabeledSwitch(visualPage, "Tracers", true, function(v) ESP.SetTracers(v) end, 136)
makeLabeledSwitch(visualPage, "Silent Aim (Absolute)", getgenv().Config.SilentAim, function(v) getgenv().Config.SilentAim = v end, 192)

-- Config Tab (Info Only)
new("TextLabel", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "INFO", TextSize = 10, TextColor3 = COLORS.textDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = configPage })
new("TextLabel", { Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 24), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "Config saving is disabled to prevent executor crashes.", TextSize = 12, TextWrapped = true, TextColor3 = COLORS.textDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = configPage })

task.spawn(function()
    task.wait(0.1)
    tabs["General"].Button.BackgroundColor3 = COLORS.accent
    tabs["General"].Button.TextColor3 = COLORS.text
    tabs["General"].Page.Visible = true
    if getgenv().Config.ESPEnabled then ESP.SetEnabled(true) end
end)

-- FOV DRAW
local FOV
pcall(function()
    if Drawing then
        FOV = Drawing.new("Circle")
        FOV.Color = Color3.new(1,1,1)
        FOV.Thickness = 1.5
        FOV.Filled = false
    end
end)
runs.RenderStepped:Connect(function()
    if FOV then
        FOV.Position = cam.ViewportSize / 2
        FOV.Radius = getgenv().Config.FOVRadius
        FOV.Visible = getgenv().Config.ShowFOV
    end
end)

-- ============================================
-- 4. THE ULTIMATE TRICK (WORLD TO SCREEN + HOOKS)
-- ============================================
local silentAimTarget = nil
local silentAimOriginalIndex = nil
local silentAimHookActive = false

local function getClosestHead()
    if not getgenv().Config.Enabled or not getgenv().Config.SilentAim then return nil end
    local center = cam.ViewportSize / 2
    local bestPart, bestDist = nil, getgenv().Config.FOVRadius
    local myPos = cam.CFrame.Position
    
    for _, entity in cs:GetTagged("Entity") do
        if entity ~= lplr.Character then
            local head = entity:FindFirstChild("Head", true)
            if head and head:IsA("BasePart") th
