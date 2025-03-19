-- // Todo:
-- [Add 'Auto Void' when ever the boss reaches less then 50% health (Since If you void a boss when the health is above 50% you won't get anything)]

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

getgenv().noClip = false;
getgenv().Respawning = false;

getgenv().Maid = {};
getgenv().Tweens = {};

local Players = GetService("Players")
local TweenService = GetService("TweenService")
local Workspace = GetService("Workspace")
local RunService = GetService("RunService")
local ReplicatedStorage = GetService("ReplicatedStorage")

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

local GetEntity, GotoEntity, NormalizeName, RespawnCharacter, CheckHealth, KillBoss, TweenTeleport, NoPhysics, RoundVector, ClearTweens, NoPhysicsOff, PlayerAdded, CharacterAdded, GetComponents, EquipWeapon, LightAttack, NoClip, DetectFloor do
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
		local Character = Player.Character or Player.CharacterAdded:Wait()

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
					offset = CFrame.new(0, 5, 0)
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

		if Character:FindFirstChild("ForceField") then
			local Boss = GetEntity()
			if Boss then
				KillBoss({ Entity = Boss })
			end
			return
		end

		local VoidPosition = Vector3.new(RootPart.Position.X, FallenHeight + 5, RootPart.Position.Z)
		local FloorSegments = DetectFloor(RootPart.Position, VoidPosition)
		local Distance = (RootPart.Position - VoidPosition).Magnitude

		repeat
			task.wait();
			Distance = (RootPart.Position - VoidPosition).Magnitude

			TweenTeleport(CFrame.new(VoidPosition), {
				tweenSpeedIgnoreY = false,
				offset = CFrame.new(0, -2, 0),
				tweenSpeed = 180,
				NoNoClip = true;
			});
		until Distance <= 5 or not Character:FindFirstChild("HumanoidRootPart")

		ClearTweens(); NoPhysicsOff()
		RunService.Heartbeat:Wait()
		
		for FloorPart, Properties in next, FloorSegments do
			if FloorPart then
				FloorPart.Transparency = Properties.Transparency
				FloorPart.CanCollide = Properties.CanCollide
			end
		end
	
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
		task.wait(2)

		local Character, Humanoid, RootPart = GetComponents()

		if not Character:FindFirstChild("ForceField") then
			RespawnCharacter()
			return
		end

		local EntityHumanoid = Data.Entity:FindFirstChildOfClass("Humanoid")
		local EntityRoot = EntityHumanoid and EntityHumanoid.RootPart

		local LastEquipCheck = 0;
		GotoEntity(Data.Entity);

		repeat
			task.wait(0.001)
			local CurrentTime = tick()

			if Character and not Character.Toggle.Value and (CurrentTime - LastEquipCheck) > 1 then
				EquipWeapon(); LastEquipCheck = CurrentTime;
			end

			local Distance = (RootPart.Position - EntityRoot.Position).Magnitude
			if (Distance > 10)  then
				GotoEntity(Data.Entity);
			end

			if Character.Toggle.Value and Distance < 10 then
				LightAttack();
			end

			if not Character:FindFirstChild("ForceField") then
				RespawnCharacter();
				break
			end

		until not Data.Entity.Parent or Data.Entity.Humanoid.Health <= 0
	end
end

local Boss = GetEntity()
if not Boss then
	return warn(`No boss found.`)
end

--warn(`Found [{NormalizeName(Boss.Name)}]!`)

KillBoss({ Entity = Boss })

