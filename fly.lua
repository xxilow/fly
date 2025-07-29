-- FlyMenu.lua (LocalScript)

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera

local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- Fly state
local flying = false
local speed = 100
local direction = Vector3.zero
local bodyGyro
local bodyVelocity

-- Create UI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "FlyMenuUI"
screenGui.ResetOnSpawn = false

-- Menu Frame (rounded)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Visible = true
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- Instruction Label (centered, not italic, disappears after 10s)
local instruction = Instance.new("TextLabel", screenGui)
instruction.Size = UDim2.new(0, 700, 0, 60) -- un peu plus grand
instruction.AnchorPoint = Vector2.new(0.5, 0.5)
instruction.Position = UDim2.new(0.5, 0, 0.5, 0)
instruction.BackgroundTransparency = 1
instruction.Text = "[INSERT] pour ouvrir/fermer le menu"
instruction.TextColor3 = Color3.new(255, 255, 255) -- couleur noire
instruction.Font = Enum.Font.SourceSansBold
instruction.TextSize = 40 -- plus grand
instruction.TextStrokeTransparency = 1 -- léger contour pour la visibilité
instruction.TextWrapped = true


task.delay(10, function()
	if instruction then
		instruction:Destroy()
	end
end)

-- Fly Toggle Button
local flyButton = Instance.new("TextButton", frame)
flyButton.Size = UDim2.new(1, -20, 0, 40)
flyButton.Position = UDim2.new(0, 10, 0, 10)
flyButton.Text = "Fly: OFF"
flyButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
flyButton.TextColor3 = Color3.new(1, 1, 1)
flyButton.Font = Enum.Font.SourceSansBold
flyButton.TextSize = 20

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 8)
flyCorner.Parent = flyButton

-- Speed Slider label
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size = UDim2.new(1, -20, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 60)
speedLabel.Text = "Speed: 100"
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 16

-- Speed Slider
local speedSlider = Instance.new("TextButton", frame)
speedSlider.Size = UDim2.new(1, -20, 0, 20)
speedSlider.Position = UDim2.new(0, 10, 0, 90)
speedSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
speedSlider.Text = ""
speedSlider.AutoButtonColor = false

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 6)
sliderCorner.Parent = speedSlider

local sliderKnob = Instance.new("Frame", speedSlider)
sliderKnob.Size = UDim2.new(0, 10, 1, 0)
sliderKnob.Position = UDim2.new(speed / 300, 0, 0, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(0, 4)
knobCorner.Parent = sliderKnob

-- Functions
local function updateSpeedSlider()
	speedLabel.Text = "Speed: " .. math.floor(speed)
	sliderKnob.Position = UDim2.new(speed / 300, 0, 0, 0)
end

local function startFly()
	if flying then return end
	flying = true
	flyButton.Text = "Fly: ON"
	flyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

	local hrp = char:WaitForChild("HumanoidRootPart")

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.P = 9e4
	bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.CFrame = hrp.CFrame
	bodyGyro.Parent = hrp

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyVelocity.Parent = hrp

	runService.RenderStepped:Connect(function()
		if not flying then return end
		local moveDir = Vector3.zero

		if direction.Magnitude > 0 then
			moveDir = camera.CFrame:VectorToWorldSpace(direction).Unit * speed
		end

		bodyVelocity.Velocity = moveDir
		bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + camera.CFrame.LookVector)
	end)
end

local function stopFly()
	flying = false
	flyButton.Text = "Fly: OFF"
	flyButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	if bodyGyro then bodyGyro:Destroy() end
	if bodyVelocity then bodyVelocity:Destroy() end
end

local function toggleFly()
	if flying then
		stopFly()
	else
		startFly()
	end
end

-- Button click
flyButton.MouseButton1Click:Connect(toggleFly)

-- Slider drag
local dragging = false

speedSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
	end
end)

uis.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

uis.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local rel = input.Position.X - speedSlider.AbsolutePosition.X
		local percent = math.clamp(rel / speedSlider.AbsoluteSize.X, 0, 1)
		speed = math.floor(percent * 300)
		updateSpeedSlider()
	end
end)

-- Movement keys
uis.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Enum.KeyCode.W then
		direction += Vector3.new(0, 0, -1)
	elseif input.KeyCode == Enum.KeyCode.S then
		direction += Vector3.new(0, 0, 1)
	elseif input.KeyCode == Enum.KeyCode.A then
		direction += Vector3.new(-1, 0, 0)
	elseif input.KeyCode == Enum.KeyCode.D then
		direction += Vector3.new(1, 0, 0)
	elseif input.KeyCode == Enum.KeyCode.Space then
		direction += Vector3.new(0, 1, 0)
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		direction += Vector3.new(0, -1, 0)
	elseif input.KeyCode == Enum.KeyCode.Insert then
		frame.Visible = not frame.Visible
	end
end)

uis.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		direction -= Vector3.new(0, 0, -1)
	elseif input.KeyCode == Enum.KeyCode.S then
		direction -= Vector3.new(0, 0, 1)
	elseif input.KeyCode == Enum.KeyCode.A then
		direction -= Vector3.new(-1, 0, 0)
	elseif input.KeyCode == Enum.KeyCode.D then
		direction -= Vector3.new(1, 0, 0)
	elseif input.KeyCode == Enum.KeyCode.Space then
		direction -= Vector3.new(0, 1, 0)
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		direction -= Vector3.new(0, -1, 0)
	end
end)

-- Init UI
updateSpeedSlider()
