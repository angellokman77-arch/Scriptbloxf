--====================================
-- BLOX FRUITS – SEA 1 FULL AUTO FARM
-- Self-contained: auto fruit scan, pick/store, auto server hop
-- JJsploit safe | Auto-run | Queue-on-teleport included
--====================================

--=============================
-- AUTO RE-EXECUTE AFTER SERVER HOP
--=============================
local SCRIPT_URL = "https://raw.githubusercontent.com/angellokman77-arch/Scriptbloxf/refs/heads/main/Script.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"..SCRIPT_URL.."'))()")
    print("🔁 Script queued for next server")
end

--=============================
-- SERVICES
--=============================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

--=============================
-- SETTINGS
--=============================
local PLACE_ID = 2753915549 -- Sea 1
local TWEEN_SPEED = 120
local SERVER_API = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
local FRUIT_RESPAWN_TIME = 600 -- seconds
local visitedServers = {}

--=============================
-- UTILITY FUNCTIONS
--=============================
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

--=============================
-- SERVER HOP
--=============================
local function serverHop()
    local success, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(SERVER_API))
    end)
    if not success or not data or not data.data then
        warn("⚠️ Failed to get server list, retrying in 5s")
        task.wait(5)
        return serverHop()
    end

    shuffle(data.data)
    local now = os.time()

    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers then
            if not visitedServers[server.id] or now - visitedServers[server.id] > FRUIT_RESPAWN_TIME then
                visitedServers[server.id] = now
                print("➡️ Teleporting to server:", server.id)
                TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, player)
                return
            end
        end
    end

    print("⚠️ No suitable servers, retrying in 10s...")
    task.wait(10)
    serverHop()
end

--=============================
-- WAIT FOR CHARACTER
--=============================
local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    return char, root
end

--=============================
-- FIND FRUITS
--=============================
local function findFruits(root)
    local fruits = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Tool")
        and v:FindFirstChild("Handle")
        and v.Handle:IsA("BasePart")
        and v.Parent == workspace then
            table.insert(fruits, v)
        end
    end
    table.sort(fruits, function(a, b)
        return (a.Handle.Position - root.Position).Magnitude <
               (b.Handle.Position - root.Position).Magnitude
    end)
    return fruits
end

--=============================
-- TWEEN TO FRUIT
--=============================
local function tweenTo(root, pos)
    local dist = (root.Position - pos).Magnitude
    local time = dist / TWEEN_SPEED
    local tween = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos + Vector3.new(0,3,0))})
    tween:Play()
    tween.Completed:Wait()
end

--=============================
-- PICK FRUIT
--=============================
local function pickFruit(root, fruit)
    if not fruit or not fruit:FindFirstChild("Handle") then return false end
    local Backpack = player:WaitForChild("Backpack")
    local fruitName = fruit.Name

    -- Already have the fruit?
    for _, item in pairs(Backpack:GetChildren()) do
        if item.Name == fruitName then
            print("❌ Already have "..fruitName)
            return false
        end
    end

    print("🍏 Moving to "..fruitName)
    tweenTo(root, fruit.Handle.Position)

    if fruit.Handle and fruit.Handle:IsDescendantOf(workspace) then
        firetouchinterest(root, fruit.Handle, 0)
        task.wait(0.1)
        firetouchinterest(root, fruit.Handle, 1)
        task.wait(0.3)
        print("✅ Picked "..fruitName)
        return true
    end

    return false
end

--=============================
-- MAIN LOOP
--=============================
local function startFarm()
    print("🚀 Starting auto fruit farm")
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
            print("Inventory full or duplicate fruit. Server hopping...")
            serverHop()
            break
        end

        task.wait(1) -- small delay before next scan
    end
end

--=============================
-- RUN AUTOMATION
--=============================
task.spawn(startFarm)
player.CharacterAdded:Connect(function()
    task.spawn(startFarm)
end)
