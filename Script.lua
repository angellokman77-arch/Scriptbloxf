--====================================
-- BLOX FRUITS – SEA 1 FULL AUTO FARM
-- Self-contained script: auto Pirate, fruit scan, pick/store, server hop
-- Queues itself automatically on server hop (Option 1)
--====================================

--=============================
-- AUTO RE-EXECUTE AFTER SERVER HOP
--=============================
local SCRIPT_URL = "https://raw.githubusercontent.com/angellokman77-arch/Scriptbloxf/refs/heads/main/Script.lua"

if queue_on_teleport then
    queue_on_teleport(SCRIPT_URL)
    print("🔁 Script queued for execution after server hop!")
end

--====================================
-- SERVICES
--====================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

--====================================
-- SETTINGS
--====================================
local PLACE_ID = 2753915549
local TWEEN_SPEED = 120
local SERVER_API = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
local visitedServers = {}
local FRUIT_RESPAWN_TIME = 600 -- 10 minutes
local SCAN_DELAY = 1 -- seconds between fruit scans

--====================================
-- UTILITY FUNCTIONS
--====================================
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(1,i)
        t[i], t[j] = t[j], t[i]
    end
end

--====================================
-- SERVER HOP
--====================================
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
-- WAIT FOR CHARACTER
--====================================
local function waitForCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    return character, root
end

--====================================
-- AUTO PIRATE TEAM PICK (RELIABLE)
--====================================
local function autoPickPirate()
    local startTime = tick()
    while tick() - startTime < 12 do -- wait up to 12s for GUI
        local success, gui = pcall(function()
            return player:FindFirstChild("PlayerGui")
        end)
        if success and gui then
            local mainGui = gui:FindFirstChild("MainGui")
            if mainGui then
                local teamFrame = mainGui:FindFirstChild("TeamSelectionFrame")
                if teamFrame then
                    local pirateBtn = teamFrame:FindFirstChild("Pirate")
                    if pirateBtn and pirateBtn:IsA("TextButton") and pirateBtn.Visible then
                        pirateBtn:Activate()
                        print("🏴‍☠️ Pirate team selected!")
                        task.wait(1) -- ensure server registers
                        return
                    end
                end
            end
        end
        task.wait(0.3)
    end
    warn("⚠️ Pirate button not found within timeout.")
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
-- TWEEN FUNCTION
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

    -- Already have the fruit?
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
-- EXECUTE AUTOMATION IMMEDIATELY & ON CHARACTER SPAWN
--====================================
task.spawn(startAutomation)
player.CharacterAdded:Connect(function()
    task.spawn(startAutomation)
end)
