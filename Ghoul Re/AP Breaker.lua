local GetService = setmetatable({}, {
	__call = function(self, key)
		local service = rawget(self, key)
		if not service then
			local function errorHandler(err)
				warn("Error getting service '" .. key .. "': " .. err)
				return nil 
			end

			local success, result = xpcall(function() return game:GetService(key) end, errorHandler)
			if success then
				service = cloneref(result)
			else
				service = nil
			end

			rawset(self, key, service)
		end
		return service
	end
})

local Players = GetService("Players")
local ReplicatedStorage = GetService("ReplicatedStorage")
local Workspace = GetService("Workspace")
local RunService = GetService("RunService")

local Player = Players.LocalPlayer

local ReplicatedModules = ReplicatedStorage.ReplicatedModules
local CombatAnimations = ReplicatedModules.ModuleListFei.EffectModuleMain.ClientAnimations.Combat

local WallyUI = loadstring(game:HttpGet(('https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3')))()
local Window = WallyUI:CreateWindow("Ghoul Re")
local b = Window:CreateFolder("Break AP")

local statusLabel = b:Label("[Disabled]", {
	TextSize = 25;
	TextColor = Color3.fromRGB(255, 255, 255);
	BgColor = Color3.fromRGB(69, 69, 69);
	Font = Enum.Font.GothamBold; 
})


getgenv().Maid = {};
getgenv().Utility = {};

getgenv().AntiParry = false;
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:GiveTask(task)
	local taskType = typeof(task)
	if taskType == "RBXScriptConnection" then
		table.insert(self._tasks, function() task:Disconnect() end)
	elseif taskType == "function" then
		table.insert(self._tasks, task)
	elseif taskType == "Instance" and task.Destroy then
		table.insert(self._tasks, function() task:Destroy() end)
	end
end

function Maid:Cleanup()
	for _, task in ipairs(self._tasks) do
		if typeof(task) == "function" then
			task()
		elseif typeof(task) == "RBXScriptConnection" then
			task:Disconnect()
		elseif typeof(task) == "Instance" and task.Destroy then
			task:Destroy()
		end
	end
	table.clear(self._tasks)
end

Maid.Destroy = Maid.Cleanup
local RandomAnimations = {}

for _, v in next, CombatAnimations.Fists:GetDescendants() do
	if (v.Name:lower():find('swing')) then
		table.insert(RandomAnimations, v); print('Inserted!')
	end
end

for i = #RandomAnimations, 2, -1 do
	local j = math.random(i)
	RandomAnimations[i], RandomAnimations[j] = RandomAnimations[j], RandomAnimations[i]
end

RandomAnimations = RandomAnimations[1]

Utility.AttachListener = function(instance, event, callback)
	return instance[event]:Connect(callback);
end

local BreakAutoParry, UpdateLabel do
	UpdateLabel = function(Toggle)
		if Toggle then
			statusLabel:Refresh("[Active]")
		else
			statusLabel:Refresh("[Disabled]")
		end
	end
	
	BreakAutoParry = function(Toggle)
		if not Toggle then
			if AntiParry then
				AntiParry:Cleanup(); AntiParry = nil
				return
			end
		end

		if not AntiParry then
			local maid = Maid.new()
			AntiParry = maid

			maid:GiveTask(RunService.Heartbeat:Connect(function()
				local Humanoid = Player.Character:FindFirstChild("Humanoid")
				if Humanoid and Humanoid.Health > 0 then
					pcall(function()
						local animTrack = Humanoid.Animator:LoadAnimation(RandomAnimations)

						task.delay(1, function()
							animTrack:Stop(); animTrack:Destroy();
						end)

						animTrack:play(9999, 0, 0)
					end)
				end
			end))
		end
	end
end

b:Toggle("Toggle", function(State)
	UpdateLabel(State); BreakAutoParry(State)
end)
