-- Draw Obby / Find Nulla0.2
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- === GUI LIMPA (PRA YOUTUBE) ===
local gui = Instance.new("ScreenGui")
gui.Name = "InkObbyHub"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 180)
frame.Position = UDim2.new(1, -340, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "Draw Obby"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.Parent = frame

-- BOTÃO INK
local inkBtn = Instance.new("TextButton")
inkBtn.Size = UDim2.new(0.95, 0, 0, 45)
inkBtn.Position = UDim2.new(0.025, 0, 0, 45)
inkBtn.Text = "INK"
inkBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
inkBtn.TextColor3 = Color3.new(1, 1, 1)
inkBtn.Font = Enum.Font.SourceSansBold
inkBtn.TextSize = 26
inkBtn.Parent = frame

local inkCorner = Instance.new("UICorner")
inkCorner.CornerRadius = UDim.new(0, 12)
inkCorner.Parent = inkBtn

-- BOTÃO OBBY
local obbyBtn = Instance.new("TextButton")
obbyBtn.Size = UDim2.new(0.95, 0, 0, 45)
obbyBtn.Position = UDim2.new(0.025, 0, 0, 100)
obbyBtn.Text = "AUTO OBBY"
obbyBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
obbyBtn.TextColor3 = Color3.new(1, 1, 1)
obbyBtn.Font = Enum.Font.SourceSansBold
obbyBtn.TextSize = 26
obbyBtn.Parent = frame

local obbyCorner = Instance.new("UICorner")
obbyCorner.CornerRadius = UDim.new(0, 12)
obbyCorner.Parent = obbyBtn

-- DRAG
local dragging = false
local dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
frame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ========================================
-- === INFINITE INK ===
-- ========================================
local inkActive = false
local inkConnection = nil
local function startInfiniteInk()
    if inkActive then return end
    inkActive = true
    inkBtn.Text = "INK ∞"
    inkBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    inkConnection = RunService.Heartbeat:Connect(function()
        local success1, profiles = pcall(require, ReplicatedStorage.Libraries.Modules.Profiles)
        if success1 then
            local replica = profiles:GetPlayerReplica(player)
            if replica and replica.Data then
                replica.Data.hints = 999999
            end
        end
        local success2, Draw = pcall(require, ReplicatedStorage.Libraries.Game.Draw)
        if success2 then
            pcall(function() Draw.ink = 999999 end)
            pcall(function() Draw:SetInk(999999) end)
        end
        local DrawUI = player.PlayerGui:FindFirstChild("DrawUI")
        if DrawUI and DrawUI.Buttons.Hint then
            DrawUI.Buttons.Hint.Content.Label.Text = "Hints(∞)"
        end
    end)
end
inkBtn.MouseButton1Click:Connect(function()
    if not inkActive then startInfiniteInk() end
end)

-- ========================================
-- === AUTO OBBY (CFrame TELEPORT) ===
-- ========================================
local obbyActive = false
local collectedStars = {}  -- [key] = true
local loopConnection = nil
local spawnConnection = nil

-- === DETECTA COLETA MANUAL (TOUCHED) ===
local function setupManualTouchDetection()
    local function connectStar(star)
        if not star or not star:IsA("BasePart") then return end
        local key = star.Name .. "_" .. tostring(star.Position)
        if collectedStars[key] then return end

        star.Touched:Connect(function(hit)
            if hit and hit.Parent == player.Character then
                if not collectedStars[key] then
                    collectedStars[key] = true
                end
            end
        end)
    end

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:lower():find("star") and obj:IsA("BasePart") then
            connectStar(obj)
        end
    end

    workspace.ChildAdded:Connect(function(child)
        if child.Name:lower():find("star") and child:IsA("BasePart") then
            connectStar(child)
        end
    end)
end

-- === TELEPORT CFrame (INSTANTÂNEO) ===
local function teleportToStar(star)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not star or not star:IsA("BasePart") then return end

    local key = star.Name .. "_" .. tostring(star.Position)
    if collectedStars[key] then return end

    -- Teleporta
    root.CFrame = CFrame.new(star.Position + Vector3.new(0, 20, 0))
    
    -- Marca como coletada
    collectedStars[key] = true
end

-- === LOOP PRINCIPAL ===
local function startAutoObby()
    if obbyActive then return end
    obbyActive = true
    obbyBtn.Text = "AUTO OBBY ON"
    obbyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)

    loopConnection = RunService.Heartbeat:Connect(function()
        if not obbyActive then return end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:lower():find("star") and obj:IsA("BasePart") then
                teleportToStar(obj)
            end
        end
    end)

    spawnConnection = workspace.ChildAdded:Connect(function(child)
        if not obbyActive then return end
        task.wait(0.1)
        if child.Name:lower():find("star") and child:IsA("BasePart") then
            teleportToStar(child)
        end
    end)
end

-- === DESATIVAR ===
local function stopAutoObby()
    obbyActive = false
    obbyBtn.Text = "AUTO OBBY"
    obbyBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    if loopConnection then loopConnection:Disconnect() end
    if spawnConnection then spawnConnection:Disconnect() end
end

obbyBtn.MouseButton1Click:Connect(function()
    if not obbyActive then
        startAutoObby()
    else
        stopAutoObby()
    end
end)

-- ========================================
-- === INICIAR ===
-- ========================================
player.CharacterAdded:Connect(function()
    task.wait(1)
    setupManualTouchDetection()
end)
if player.Character then
    task.spawn(setupManualTouchDetection)
end

print("INK ∞ + AUTO OBBY (CFrame) CARREGADO!")
print("NUNCA VOLTA | NUNCA TRAVA | LIMPO")
