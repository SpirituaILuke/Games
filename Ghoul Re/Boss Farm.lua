-- By @Spirit

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

local Webhook = loadstring(game:HttpGet("https://pastebin.com/raw/9YZiENVd", true))()
local debugWebhook = Webhook.new('https://discord.com/api/webhooks/1352050830060032032/hFRmFdIObq-ySnM4hRun45b0Oitq7TKx20I4m4ZzmrEeltFsPidr9k4CZHVz0zCj_tWr')

getgenv().Dependencies = {
	Notifier = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))(),
}

getgenv().Adjustments = {
	Noro = 20,
	Tatara = 30,
	Eto = 20,
}

getgenv().noClip = false;
getgenv().voidBoss = false;
getgenv().stopFarm = false;
getgenv().LogI = false;

getgenv().lastHealth = 0;
getgenv().FFLifeTime = 40;

getgenv().Maid = {};
getgenv().Tweens = {};

local Players = GetService("Players")
local TweenService = GetService("TweenService")
local Workspace = GetService("Workspace")
local RunService = GetService("RunService")
local ReplicatedStorage = GetService("ReplicatedStorage")
local HttpService = GetService("HttpService")

local Player = Players.LocalPlayer

local EntitiesFolder = Workspace.Entities
local FallenHeight = Workspace.FallenPartsDestroyHeight

local BridgenetFolder = ReplicatedStorage.Bridgenet2Main
local BridgeRemote = BridgenetFolder.dataRemoteEvent

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

local GetEntity, GotoEntity, NormalizeName, RespawnCharacter, CheckHealth, KillBoss, TweenTeleport, NoPhysics, RoundVector, ClearTweens, NoPhysicsOff, GetComponents, EquipWeapon, LightAttack, NoClip, DetectFloor do    
	DetectFloor = function(startPos, voidPos)
		local ignoredParts = {}

		local direction = (voidPos - startPos).unit
		local distance = (startPos - voidPos).Magnitude
		local position = startPos

		while (position.Y > voidPos.Y) do
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = {Player.Character}

			local result = Workspace:Raycast(position, direction * -5, raycastParams)

			if result and result.Instance then
				local floorPart = result.Instance
				if floorPart:IsA("BasePart") and not ignoredParts[floorPart] then
					ignoredParts[floorPart] = {
						Transparency = floorPart.Transparency,
						CanCollide = floorPart.CanCollide
					}

					floorPart.Transparency = 1
					floorPart.CanCollide = false
				end
			end

			position = position - Vector3.new(0, 5, 0)
		end

		return ignoredParts
	end

	NoClip = function(Toggle)
		local Character, Humanoid, RootPart = GetComponents()
		if not Toggle then
			if noClip then
				noClip:Cleanup()
				noClip = nil

				for _, FakeHead in next, workspace.FakeHeads:GetChildren() do
					if FakeHead:IsA("BasePart") and string.find(FakeHead.Name, Player.Name) then
						FakeHead.CanCollide = true
					end
				end
			end
			return
		end

		if not noClip then
			local maid = Maid.new()
			noClip = maid

			maid:GiveTask(RunService.Heartbeat:Connect(function()
				for _, Part in next, Character:GetDescendants() do
					if Part:IsA("BasePart") then
						Part.CanCollide = false
					end
				end

				for _, FakeHead in next, workspace.FakeHeads:GetChildren() do
					if FakeHead:IsA("BasePart") and string.find(FakeHead.Name, Player.Name) then
						FakeHead.CanCollide = false
					end
				end
			end))
		end		
	end

	LightAttack = function()
		BridgeRemote:FireServer({
			[1] = {
				["Module"] = "M1"
			},
			[2] = utf8.char(5)
		})
	end

	EquipWeapon = function()
		BridgeRemote:FireServer({
			[1] = {
				["Module"] = "Toggle",
			},
			[2] = utf8.char(5)
		})
	end

	GetComponents = function()
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		local RootPart = Humanoid and Humanoid.RootPart

		if not Humanoid or not RootPart then
			return nil, nil, nil
		end

		return Character, Humanoid, RootPart
	end

	NoPhysicsOff = function()
		local Character, Humanoid, RootPart = GetComponents()

		if not Character then
			return
		end

		if not RootPart or not RootPart:FindFirstChild("NoPhysics") then
			return
		end

		NoClip(false)
		RootPart.NoPhysics:Destroy()
	end

	ClearTweens = function()
		for i, v in next, Tweens do
			v:Cancel(); Tweens[i] = nil
		end
	end

	RoundVector = function(vector)
		return Vector3.new(vector.X, 0, vector.Z)
	end

	NoPhysics = function(Options)
		local Character, Humanoid, RootPart = GetComponents()

		if not Character then
			return
		end

		if not RootPart or not RootPart:FindFirstChild("NoPhysics") then
			return
		end

		NoClip(true)
		RootPart.CFrame = CFrame.new(RootPart.CFrame.Position) * Options.offset.Rotation

		if (not RootPart or RootPart:FindFirstChild('NoPhysics')) then 
			return
		end

		local BV = Instance.new('BodyVelocity')
		BV.Name = 'NoPhysics'
		BV.MaxForce = Vector3.one * math.huge
		BV.Velocity = Vector3.zero
		BV.Parent = RootPart
	end

	TweenTeleport = function(Goal, Options)
		local Character, Humanoid, RootPart = GetComponents()

		if not Character then
			return
		end

		if (typeof(Goal) == 'Vector3') then
			Goal = CFrame.new(Goal)
		end

		Options = Options or {}

		Options.tweenSpeed = Options.tweenSpeed or 100
		Options.offset = Options.offset or CFrame.identity * Goal.Rotation

		if (Options.instant) then
			Options.tweenSpeed = 1000
		end

		if not Options.NoNoClip then
			NoClip(true)
		end

		NoPhysics(Options)

		local maid = Maid.new();
		local TotalDistance = (RootPart.Position - Goal.Position).Magnitude

		if (Options.tweenSpeedIgnoreY) then
			TotalDistance = RoundVector(RootPart.Position - Goal.Position).Magnitude
		end

		local tweenInfo = TweenInfo.new(TotalDistance / Options.tweenSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);
		local tween = TweenService:Create(RootPart, tweenInfo, {
			CFrame = Goal * Options.offset
		})

		Tweens[tween] = tween

		maid:GiveTask(RunService.Heartbeat:Connect(function()
			NoPhysics(Options)
		end))

		maid:GiveTask(function()
			Tweens[tween] = nil
		end)

		maid:GiveTask(tween.Completed:Connect(function()
			maid:Destroy()
		end))

		tween:Play()
		return tween
	end

	GetEntity = function()
		for _, Entity in next, EntitiesFolder:GetChildren() do
			if Entity:IsA("Model") and Entity:FindFirstChild("HumanoidRootPart") then
				if Players:GetPlayerFromCharacter(Entity) then
					continue
				end

				return Entity
			end

			return nil
		end
	end

	GotoEntity = function(Entity)
		local Character, Humanoid, RootPart = GetComponents()

		if not Character then
			return
		end

		local EntityHumanoid = Entity:FindFirstChildOfClass("Humanoid")
		local EntityRoot = EntityHumanoid and EntityHumanoid.RootPart

		if not EntityRoot or EntityHumanoid.Health <= 0 then
			return
		end

		local Distance = (RootPart.Position - EntityRoot.Position).Magnitude
		if (Distance > 10)  then
			repeat
				task.wait();
				Distance = RoundVector(RootPart.Position - EntityRoot.Position).Magnitude

				RootPart.CFrame = CFrame.lookAt(RootPart.Position, Vector3.new(EntityRoot.Position.X, RootPart.Position.Y, EntityRoot.Position.Z))

				TweenTeleport(CFrame.new(EntityRoot.Position), {
					tweenSpeedIgnoreY = true,
					offset = CFrame.new(0, 5, 0),
					tweenSpeed = 230,
				});
			until Distance <= 10
		end

		ClearTweens();
	end

	RespawnCharacter = function()
		local Character, Humanoid, RootPart = GetComponents()
		if not Character then
			return
		end

		if Character:FindFirstChild("ForceField") and FFLifeTime <= 0 then
			local Boss = GetEntity()
			if Boss then
				KillBoss({ Entity = Boss })
			end
			return
		end

		stopFarm = true

		local VoidPosition = Vector3.new(RootPart.Position.X, FallenHeight + 5, RootPart.Position.Z)
		local Distance = (RootPart.Position - VoidPosition).Magnitude

		task.spawn(function()
			while stopFarm do
				task.wait(0.1)
				for _, part in pairs(Player.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end

				for _, FakeHead in next, workspace.FakeHeads:GetChildren() do
					if FakeHead:IsA("BasePart") and string.find(FakeHead.Name, Player.Name) then
						FakeHead.CanCollide = false
					end
				end
			end
		end)

		repeat
			task.wait();
			Distance = (RootPart.Position - VoidPosition).Magnitude

			TweenTeleport(CFrame.new(VoidPosition), {
				tweenSpeedIgnoreY = false,
				offset = CFrame.new(0, -2, 0),
				tweenSpeed = 230,
				NoNoClip = true;
			});
		until Distance <= 5 or not Character:FindFirstChild("HumanoidRootPart")

		ClearTweens(); NoPhysicsOff()
		
		RunService.Heartbeat:Wait()
		stopFarm = false

		local newCharacter = Player.CharacterAdded:Wait()
		repeat task.wait() until newCharacter:FindFirstChild("HumanoidRootPart")

		local Boss = GetEntity()
		if Boss then
			KillBoss({ Entity = Boss })
		end
	end

	NormalizeName = function(String)
		return String:match("^[^_]+")
	end

	KillBoss = function(Data)
		task.wait(1)

		local Character, Humanoid, RootPart = GetComponents()

		if not Character:FindFirstChild("ForceField") then
			RespawnCharacter()
			return
		end

		if stopFarm then
			return
		end

		if FFLifeTime > 0 then
			local RTime = FFLifeTime - 5
			task.delay(RTime, function()
				if Character:FindFirstChild("ForceField") then
					RespawnCharacter();
				end
			end)
		end

		if not OldBackpack then
			getgenv().OldBackpack = {};

			for _, Item in next, Player.Backpack:GetChildren() do
				if not Item:IsA("Tool") then
					continue
				end

				if Item:GetAttribute("CooldownDuration") then
					continue -- Ignore skills
				end

				OldBackpack[Item.Name] = (Item:FindFirstChild("Quantity") and Item.Quantity.Value) or 1
			end
		end

		local EntityHumanoid = Data.Entity:FindFirstChildOfClass("Humanoid")
		local EntityRoot = EntityHumanoid and EntityHumanoid.RootPart

		local LastEquipCheck = 0;
		GotoEntity(Data.Entity);

		repeat
			task.wait(0.001)
			local CurrentTime = tick()

			local Percentage = (EntityHumanoid.Health / EntityHumanoid.MaxHealth) * 100
			if Percentage ~= nil then
				lastHealth = Percentage;
			end

			if Percentage <= 35 then
				if not voidBoss then
					local maid = Maid.new()
					voidBoss = maid

					Dependencies.Notifier:SendNotification("Info", `{NormalizeName(Data.Entity.Name)} is at {string.format("%.1f", Percentage)} % HP, attempting to void`, 5)

					maid:GiveTask(RunService.Heartbeat:Connect(function()
						sethiddenproperty(Player, "MaxSimulationRadius", math.huge);
						sethiddenproperty(Player, "SimulationRadius", math.huge);
					end))

					maid:GiveTask(task.spawn(function()
						while task.wait() do
							if EntityRoot and isnetworkowner(EntityRoot) then
								EntityHumanoid.Health = 0;
							end
						end
					end))
				end
			end

			if Character and not Character.Toggle.Value and (CurrentTime - LastEquipCheck) > 1 then
				EquipWeapon(); LastEquipCheck = CurrentTime;
			end

			local Distance = (RootPart.Position - EntityRoot.Position).Magnitude
			if (Distance > 10)  then
				GotoEntity(Data.Entity);
			end

			if Character.Toggle.Value and Distance < 10 and Character.Combo.Value < 4 then
				LightAttack();
			end

			if not Character:FindFirstChild("ForceField") then
				RespawnCharacter();
				break
			end

		until not Data.Entity.Parent or Data.Entity.Humanoid.Health <= 0 or stopFarm        
		if voidBoss then
			voidBoss:Cleanup(); voidBoss = nil
		end

		if lastHealth <= 35 and not LogI then
			LogI = true;

			Player.Backpack.ChildAdded:Wait()
			local NewBackpack = {}

			for _, Item in next, Player.Backpack:GetChildren() do
				if not Item:IsA("Tool") then
					continue
				end

				if Item:GetAttribute("CooldownDuration") then
					continue -- Ignore skills
				end

				NewBackpack[Item.Name] = (Item:FindFirstChild("Quantity") and Item.Quantity.Value) or 1
			end

			local newItems = {}
			local itemChanges = {}

			for itemName, newQuantity in pairs(NewBackpack) do
				local oldQuantity = OldBackpack[itemName] or 0
				if oldQuantity == 0 then
					table.insert(newItems, itemName)
				elseif newQuantity > oldQuantity then
					table.insert(itemChanges, { name = itemName, count = newQuantity - oldQuantity })
				end
			end

			local lootDescription = ""

			if #newItems > 0 then
				lootDescription = lootDescription .. "**New Items:**\n"
				for _, item in ipairs(newItems) do
					lootDescription = lootDescription .. "- " .. item .. "\n"
				end
			end

			if #itemChanges > 0 then
				lootDescription = lootDescription .. "**Increased Items:**\n"
				for _, item in ipairs(itemChanges) do
					lootDescription = lootDescription .. "- " .. item.name .. " x" .. item.count .. "\n"
				end
			end

			if lootDescription == "" then
				lootDescription = "No new items or increases."
			end

			local webhookData = {
				embeds = {
					{
						title = "Boss Defeated",
						description = string.format("Successfully killed the boss."),
						color = 0x00FF00,
						fields = {
							{ name = "Boss Name", value = NormalizeName(Data.Entity.Name), inline = true },
							{ name = "[Loot]", value = lootDescription, inline = false },
						},
					}
				}
			}

			debugWebhook:Send(webhookData)
		end
	end
end

if game.PlaceId ~= 89413197677760 then
	return Dependencies.Notifier:SendNotification("Error", `Script has been ran in the wrong place! Run it in the 'Boss Place'!`, 4)
end

if not (Player:GetAttribute("FULLYLOADED") and Player:GetAttribute("Loaded")) then
	Dependencies.Notifier:SendNotification("Info", "Not loaded, waiting for load...", 4)

	repeat
		task.wait()
	until Player:GetAttribute("FULLYLOADED") and Player:GetAttribute("Loaded")

	Dependencies.Notifier:SendNotification("Info", `Player has loaded in!`, 4)
end

local Boss = GetEntity()

if not Boss then
	Dependencies.Notifier:SendNotification("Warning", `Waiting for the boss to spawn in.`, 5)
	repeat 
		task.wait(); Boss = GetEntity()
	until Boss ~= nil
end

FFLifeTime = Adjustments[NormalizeName(Boss.Name)] or FFLifeTime;
KillBoss({ Entity = Boss });

task.spawn(function()
	while true do
		if not Boss.Parent and lastHealth >= 40 then
			local webhookData = {
				embeds = {
					{
						title = "Boss Failure",
						description = "Something went wrong during the boss fight.",
						color = 0xFF0000,
						fields = {
							{ name = "Last Boss Health", value = lastHealth .. "%", inline = true },
							{ name = "Boss", value = NormalizeName(Boss.Name), inline = true },

						},
						timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
					}
				}
			}

			debugWebhook:Send(webhookData)
			break
		end
		task.wait()
	end
end)
