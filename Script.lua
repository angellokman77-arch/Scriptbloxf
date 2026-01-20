--====================================
-- BLOX FRUITS – SEA 1 AUTO FARM (Reliable Team Tap & Auto Hop)
-- Insert this entire script as Script.lua on GitHub RAW
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
-- SERVER HOP
--====================================
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

local function serverHop()
    local success, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(SERVER_API))
    end)
    if not success or not data or not data.data then
        task.wait(5)
        return serverHop()
    end
    local servers = data.data
    shuffle(servers)
    local now = os.time()
    for _, s in ipairs(servers) do
        if (not visitedServers[s.id]) or (now - visitedServers[s.id] > FRUIT_RESPAWN_TIME) then
            if s.playing < s.maxPlayers then
                visitedServers[s.id] = now
                TeleportService:TeleportToPlaceInstance(PLACE_ID, s.id, player)
                return
            end
        end
    end
    task.wait(10)
    serverHop()
end

--====================================
-- RELIABLE AUTO PIRATE TEAM CLICK
--====================================
local function autoPickPirate()
    local gui = player:WaitForChild("PlayerGui", 10)
    if not gui then return end

    local main = gui:FindFirstChild("Main")
    if not main then return end

    local choose = main:FindFirstChild("ChooseTeam")
    if not choose then return end

    -- Wait until visible
    repeat task.wait() until choose.Visible

    local container = choose:FindFirstChild("Container")
    if not container then return end

    local piratesFrame = container:FindFirstChild("Pirates")
    if not piratesFrame then return end

    local viewport = piratesFrame:FindFirstChild("Frame")
    if viewport then
        local btn = viewport:FindFirstChild("ViewportFrame")
        if btn then
            local textBtn = btn:FindFirstChildWhichIsA("TextButton")
            if textBtn then
                -- invoke all activated connections
                for _, conn in pairs(getconnections(textBtn.Activated)) do
                    pcall(conn.Function)
                end
                print("🏴‍☠️ Pirate team chosen!")
                return
            end
        end
    end
end

--====================================
-- CHARACTER / ROOT
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
    table.sort(fruits, function(a, b)
        return (a.Handle.Position - root.Position).Magnitude < (b.Handle.Position - root.Position).Magnitude
    end)
    return fruits
end

--====================================
-- MOVE TWEEN
--====================================
local function tweenTo(root, pos)
    local dist = (root.Position - pos).Magnitude
    local time = dist / TWEEN_SPEED
    local tw = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))})
    tw:Play()
    tw.Completed:Wait()
end

--====================================
-- PICK & STORE FRUIT
--====================================
local function pickAndStoreFruit(root, fruit)
    local bp = player:WaitForChild("Backpack")
    for _, item in ipairs(bp:GetChildren()) do
        if item.Name == fruit.Name then
            return false
        end
    end
    tweenTo(root, fruit.Handle.Position)
    firetouchinterest(root, fruit.Handle, 0)
    task.wait(0.1)
    firetouchinterest(root, fruit.Handle, 1)
    return true
end

--====================================
-- MAIN AUTOMATION
--====================================
local function startAutomation()
    autoPickPirate()
    local _, root = waitForCharacter()
    task.wait(1.5)
    while true do
        local fruits = findAllFruits(root)
        if #fruits == 0 then
            print("❌ No fruits found — hopping...")
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
            print("Inventory full or same fruits — hopping...")
            serverHop()
            return
        end
        task.wait(0.5)
    end
end

--====================================
-- EXECUTE AUTOMATION
--====================================
task.spawn(startAutomation)
player.CharacterAdded:Connect(function()
    task.spawn(startAutomation)
end)
