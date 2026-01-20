--====================================
-- BLOX FRUITS – SEA 1 AUTO FRUIT FARM
-- JJsploit SAFE | Auto-run | Auto-hop
--====================================

--=============================
-- AUTO RE-EXECUTE AFTER SERVER HOP (JJsploit FIX)
--=============================
local SCRIPT_URL = "https://raw.githubusercontent.com/angellokman77-arch/Scriptbloxf/refs/heads/main/Script.lua"

if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('"https://raw.githubusercontent.com/angellokman77-arch/Scriptbloxf/refs/heads/main/Script.lua"'))()")
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
local SERVER_API =
    "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"

local FRUIT_RESPAWN_TIME = 600
local visitedServers = {}

--=============================
-- WAIT FOR CHARACTER
--=============================
local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    return char, root
end

--=============================
-- FIND WORLD FRUITS
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
-- TWEEN MOVE
--=============================
local function tweenTo(root, pos)
    local dist = (root.Position - pos).Magnitude
    local time = dist / TWEEN_SPEED

    local tween = TweenService:Create(
        root,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))}
    )
    tween:Play()
    tween.Completed:Wait()
end

--=============================
-- PICK FRUIT
--=============================
local function pickFruit(root, fruit)
    if not fruit or not fruit:FindFirstChild("Handle") then return false end

    print("🍏 Moving to", fruit.Name)
    tweenTo(root, fruit.Handle.Position)

    if fruit.Handle:IsDescendantOf(workspace) then
        firetouchinterest(root, fruit.Handle, 0)
        task.wait(0.1)
        firetouchinterest(root, fruit.Handle, 1)
        task.wait(0.3)
        return true
    end

    return false
end

--=============================
-- SERVER HOP
--=============================
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function serverHop()
    local data = HttpService:JSONDecode(game:HttpGet(SERVER_API))
    shuffle(data.data)

    local now = os.time()

    for _, s in ipairs(data.data) do
        if s.playing < s.maxPlayers then
            if not visitedServers[s.id]
            or now - visitedServers[s.id] > FRUIT_RESPAWN_TIME then
                visitedServers[s.id] = now
                print("➡️ Server hopping...")
                TeleportService:TeleportToPlaceInstance(PLACE_ID, s.id, player)
                return
            end
        end
    end

    task.wait(5)
    serverHop()
end

--=============================
-- MAIN AUTO FARM
--=============================
local function start()
    print("🚀 Auto fruit farm started")

    local _, root = getCharacter()
    task.wait(1)

    local fruits = findFruits(root)

    if #fruits == 0 then
        print("❌ No fruits found")
        serverHop()
        return
    end

    for _, fruit in ipairs(fruits) do
        pickFruit(root, fruit)
        task.wait(0.5)
    end

    serverHop()
end

--=============================
-- RUN
--=============================
task.spawn(start)
