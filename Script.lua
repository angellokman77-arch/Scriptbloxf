--====================================
-- BLOX FRUITS – SEA 1 FULL AUTO FARM (Reliable Pirate + Auto-Reexec)
-- Self-contained: auto Pirate, fruit scan, pick/store, server hop
-- Includes auto re-execute after teleport
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
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer

--====================================
-- SETTINGS
--====================================
local PLACE_ID = 2753915549
local TWEEN_SPEED = 120
local SERVER_API = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
local visitedServers = {}
local FRUIT_RESPAWN_TIME = 600
local SCAN_DELAY = 1

--====================================
-- UTILITY
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
        task.wait(5)
        return serverHop()
    end

    local servers = serversData.data
    shuffle(servers)
    local now = os.time()
    for _, server in pairs(servers) do
        if not visitedServers[server.id] or now - visitedServers[server.id] > FRUIT_RESPAWN_TIME then
            if server.playing < server.maxPlayers then
                visitedServers[server.id] = now
                TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, player)
                return
            end
        end
    end
    task.wait(10)
    serverHop()
end

--====================================
-- RELIABLE PIRATE CLICK (Recursive Search + VirtualUser)
--====================================
local function autoPickPirate()
    local timeout = tick() + 20 -- wait up to 20s
    while tick() < timeout do
        local gui = player:FindFirstChild("PlayerGui")
        if gui then
            local function searchForPirate(obj)
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("TextButton") and child.Name:lower():find("pirate") then
                        return child
                    else
                        local found = searchForPirate(child)
                        if found then return found end
                    end
                end
            end
            local btn = searchForPirate(gui)
            if btn then
                -- simulate real click
                VirtualUser:Button1Down(Vector2.new(0,0))
                task.wait(0.1)
                VirtualUser:Button1Up(Vector2.new(0,0))
                print("🏴‍☠️ Pirate button clicked!")
                return true
            end
        end
        task.wait(0.2)
    end
    warn("⚠️ Pirate button not found after 20s.")
    return false
end

--====================================
-- WAIT FOR CHARACTER
--====================================
local function waitForCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    return char, root
end

--====================================
-- FRUIT DETECTION
--====================================
local function findAllFruits(root)
    local fruits = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then
            table.insert(fruits, v)
        end
    end
    table.sort(fruits, function(a,b)
        return (a.Handle.Position - root.Position).Magnitude < (b.Handle.Position - root.Position).Magnitude
    end)
    return fruits
end

--====================================
-- TWEEN TO FRUIT
--====================================
local function tweenTo(root, pos)
    local dist = (root.Position - pos).Magnitude
    local t = dist / TWEEN_SPEED
    local tw = TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos + Vector3.new(0,3,0))})
    tw:Play()
    tw.Completed:Wait()
end

--====================================
-- PICK FRUIT
--====================================
local function pickAndStoreFruit(root, fruit)
    if not root or not fruit or not fruit:FindFirstChild("Handle") then return false end
    local bp = player:WaitForChild("Backpack")
    local name = fruit.Name
    for _, item in pairs(bp:GetChildren()) do
        if item.Name == name then
            return false
        end
    end
    tweenTo(root, fruit.Handle.Position)
    firetouchinterest(root, fruit.Handle, 0)
    task.wait(0.1)
    firetouchinterest(root, fruit.Handle, 1)
    print("🍏 picked", name)
    return true
end

--====================================
-- MAIN AUTOMATION LOOP
--====================================
local function startAutomation()
    autoPickPirate()
    local _, root = waitForCharacter()
    task.wait(1.5)

    while true do
        local fruits = findAllFruits(root)
        if #fruits == 0 then
            print("❌ No fruits left, server hopping...")
            serverHop()
            return
        end

        local pickedAny = false
        for _, f in ipairs(fruits) do
            if pickAndStoreFruit(root, f) then
                pickedAny = true
            end
            task.wait(SCAN_DELAY)
        end

        if not pickedAny then
            print("Inventory may be full or duplicate fruit, server hopping...")
            serverHop()
            return
        end

        task.wait(0.5)
    end
end

--====================================
-- EXECUTE IMMEDIATELY AND ON RESPAWN
--====================================
task.spawn(startAutomation)
player.CharacterAdded:Connect(function()
    task.spawn(startAutomation)
end)
