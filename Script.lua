--====================================
-- BLOX FRUITS – SEA 1 AUTO FARM WITH QUEUE_ON_TELEPORT
-- Fully automated: Pirate click, fruit scan, pick/store, server hop
--====================================

--=============================
-- QUEUE SCRIPT ON SERVER HOP
--=============================
if queue_on_teleport then
    queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/angellokman77-arch/Scriptbloxf/refs/heads/main/Script"))
    print("🔁 Script queued for execution after server hop!")
end

-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- SETTINGS
local PLACE_ID = 2753915549
local TWEEN_SPEED = 120
local SERVER_API = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
local visitedServers = {}
local FRUIT_RESPAWN_TIME = 600 -- 10 minutes
local SCAN_DELAY = 1 -- seconds between fruit scans

--====================================
-- SERVER HOP UTILITY
--====================================
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(1,i)
        t[i], t[j] = t[j], t[i]
    end
end

local function serverHop()
    local success, serversData = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(SERVER_API))
    end)
    if not success or not serversData or not serversData.data then
        warn("⚠️ Failed to fetch servers. Retrying in 5s...")
        task.wait(5)
        return serverHop()
    end

    local servers = serversData.data
    shuffle(servers)
    local currentTime = os.time()

    for _, server in pairs(servers) do
        if visitedServers[server.id] and currentTime - visitedServers[server.id] < FRUIT_RESPAWN_TIME then
            continue
        end

        if server.playing > 0 and server.playing < server.maxPlayers then
            visitedServers[server.id] = currentTime
            print("➡️ Teleporting to server:", server.id)
            TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, player)
            return
        end
    end

    print("⚠️ No suitable servers found. Retrying in 10s...")
    task.wait(10)
    serverHop()
end

--====================================
-- CHARACTER / ROOT
--====================================
local function waitForCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    return character, root
end

--====================================
-- AUTO PIRATE TEAM PICK (RELIABLE LOOP)
--====================================
local function autoPickPirate()
    local success, _ = pcall(function()
        local gui = player:WaitForChild("PlayerGui")
        local mainGui = gui:WaitForChild("MainGui", 15)
        local teamFrame = mainGui:WaitForChild("TeamSelectionFrame", 15)
        local pirateButton = teamFrame:FindFirstChild("Pirate")
        if pirateButton then
            local timer = 0
            while timer < 10 do
                if pirateButton.Visible then
                    pirateButton:Activate()
                    print("🏴‍☠️ Pirate team selected!")
                    break
                end
                task.wait(0.5)
                timer = timer + 0.5
            end
        end
    end)
end

--====================================
-- FRUIT DETECTION
--====================================
local function findAllFruits(root)
    local fruits = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") and v.Handle:IsA("BasePart") and v.Parent == workspace then
            table.insert(fruits, v)
        end
    end
    table.sort(fruits, function(a,b)
        return (a.Handle.Position - root.Position).Magnitude < (b.Handle.Position - root.Position).Magnitude
    end)
    return fruits
end

--====================================
-- TWEEN TO POSITION
--====================================
local function tweenTo(root, pos)
    if not root or not pos then return end
    local distance = (root.Position - pos).Magnitude
    local time = distance / TWEEN_SPEED
    local tween = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos + Vector3.new(0,3,0))})
    tween:Play()
    tween.Completed:Wait()
end

--====================================
-- PICK & STORE FRUIT
--====================================
local function pickAndStoreFruit(root, fruit)
    if not root or not fruit or not fruit:FindFirstChild("Handle") then return false end
    local Backpack = player:WaitForChild("Backpack")
    local fruitName = fruit.Name

    for _, item in pairs(Backpack:GetChildren()) do
        if item.Name == fruitName then
            print("❌ Already have this fruit.")
            return false
        end
    end

    print("🍏 Moving to fruit:", fruitName)
    tweenTo(root, fruit.Handle.Position)

    if fruit.Handle and fruit.Handle:IsDescendantOf(workspace) then
        firetouchinterest(root, fruit.Handle, 0)
        task.wait(0.1)
        firetouchinterest(root, fruit.Handle, 1)
        task.wait(0.5)
        print("✅ Picked & stored fruit:", fruitName)
        return true
    end
    return false
end

--====================================
-- MAIN AUTOMATION LOOP
--====================================
local function startAutomation()
    autoPickPirate()
    local character, root = waitForCharacter()
    task.wait(1.5) -- wait for world to fully load

    while true do
        local fruits = findAllFruits(root)
        if #fruits == 0 then
            print("❌ No fruits left. Server hopping...")
            serverHop()
            break
        end

        local picked = false
        for _, fruit in ipairs(fruits) do
            picked = pickAndStoreFruit(root, fruit) or picked
            task.wait(SCAN_DELAY)
        end

        if not picked then
            print("Inventory may be full or duplicate fruit. Server hopping...")
            serverHop()
            break
        end

        task.wait(0.5)
    end
end

--====================================
-- EXECUTE IMMEDIATELY & ON CHARACTER SPAWN
--====================================
task.spawn(startAutomation)
player.CharacterAdded:Connect(function()
    task.spawn(startAutomation)
end)
