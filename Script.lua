--====================================
-- BLOX FRUITS – SEA 1 AUTO FRUIT FARM
-- Full self-contained | Auto-run | Auto-hop
--====================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local PLACE_ID = 2753915549
local TWEEN_SPEED = 120
local SERVER_API = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
local FRUIT_RESPAWN_TIME = 600
local visitedServers = {}

--=============================
-- QUEUE FOR NEXT SERVER
--=============================
if queue_on_teleport then
    queue_on_teleport([[
        -- reloads this script after teleport
        loadstring(game:HttpGet("https://raw.githubusercontent.com/angellokman77-arch/Scriptbloxf/refs/heads/main/Script.lua"))()
    ]])
    print("🔁 Script queued for next server")
end

--=============================
-- UTILITIES
--=============================
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    return char, root
end

--=============================
-- FRUIT FUNCTIONS
--=============================
local function findFruits(root)
    local fruits = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") and v.Handle:IsA("BasePart") and v.Parent == workspace then
            table.insert(fruits, v)
        end
    end
    table.sort(fruits, function(a,b)
        return (a.Handle.Position - root.Position).Magnitude < (b.Handle.Position - root.Position).Magnitude
    end)
    return fruits
end

local function tweenTo(root, pos)
    if not root or not pos then return end
    local dist = (root.Position - pos).Magnitude
    local time = dist / TWEEN_SPEED
    local tween = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos + Vector3.new(0,3,0))})
    tween:Play()
    tween.Completed:Wait()
end

local function pickFruit(root, fruit)
    if not fruit or not fruit:FindFirstChild("Handle") then return false end
    local Backpack = player:WaitForChild("Backpack")
    local fruitName = fruit.Name

    for _, item in pairs(Backpack:GetChildren()) do
        if item.Name == fruitName then
            return false -- already have it
        end
    end

    tweenTo(root, fruit.Handle.Position)
    firetouchinterest(root, fruit.Handle, 0)
    task.wait(0.1)
    firetouchinterest(root, fruit.Handle, 1)
    task.wait(0.3)
    return true
end

--=============================
-- SERVER HOP
--=============================
local function serverHop()
    local success, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(SERVER_API))
    end)
    if not success or not data or not data.data then
        task.wait(5)
        return serverHop()
    end

    shuffle(data.data)
    local now = os.time()
    for _, s in ipairs(data.data) do
        if s.playing < s.maxPlayers and (not visitedServers[s.id] or now - visitedServers[s.id] > FRUIT_RESPAWN_TIME) then
            visitedServers[s.id] = now
            TeleportService:TeleportToPlaceInstance(PLACE_ID, s.id, player)
            return
        end
    end

    task.wait(5)
    serverHop()
end

--=============================
-- MAIN LOOP
--=============================
local function startFarm()
    local char, root = getCharacter()
    task.wait(1)

    while true do
        local fruits = findFruits(root)
        if #fruits == 0 then
            print("❌ No fruits found. Server hopping...")
            serverHop()
            break
        end

        local pickedAny = false
        for _, fruit in ipairs(fruits) do
            pickedAny = pickFruit(root, fruit) or pickedAny
            task.wait(0.5)
        end

        if not pickedAny then
            print("Inventory full. Server hopping...")
            serverHop()
            break
        end

        task.wait(1)
    end
end

--=============================
-- EXECUTE
--=============================
task.spawn(startFarm)
player.CharacterAdded:Connect(function()
    task.spawn(startFarm)
end)
