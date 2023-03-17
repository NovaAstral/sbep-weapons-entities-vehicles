AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "Warp Drive"

function ENT:SpawnFunction(ply, tr)
	local ent = ents.Create("warpdrivev2")
	ent:SetPos(tr.HitPos + Vector(0, 0, 20))
	ent:Spawn()
	return ent 
end 

function ENT:Initialize()

	util.PrecacheModel("models/Slyfo/ftl_drive.mdl")
	util.PrecacheSound("ftldrives/ftl_in.wav")
	util.PrecacheSound("ftldrives/ftl_out.wav")
	
	self.Entity:SetModel("models/Slyfo/ftl_drive.mdl")
	
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Entity:DrawShadow(false)
	
	local phys = self.Entity:GetPhysicsObject()
	
	self.NTime = 0
	
	if(phys:IsValid()) then
		phys:SetMass(100)
		phys:EnableGravity(true)
		phys:Wake()
	end

	self.JumpCoords = {}
	WireLib.CreateSpecialInputs(self.Entity,{"Warp","Destination"},{[2] = "VECTOR"}); 
end

function ENT:TriggerInput(iname, value)
	if(iname == "Destination") then
		self.JumpCoords.Vec = value
	elseif(iname == "Warp" and value >= 1) then
		self.JumpCoords.Dest = self.JumpCoords.Vec

		if (CurTime()-self.NTime) > 4 and !timer.Exists("wait") and self.JumpCoords.Dest ~= self.Entity:GetPos() and util.IsInWorld(self.JumpCoords.Dest) then
			self.NTime=CurTime()
			self.Entity:EmitSound("WarpDrive/warp.wav",450,70)
			timer.Create("wait",1,1,function() self.Entity:Jump() end, self)

			local plys = player.GetAll()
			local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)

			for _, ply in pairs(plys) do
				local tr = util.TraceLine({
					start = ply:GetPos(),
					endpos = ply:GetPos() + Vector(0,0,-200)
				})
				print(tr.Entity)

				if(tr.Entity:IsValid()) then
					local const = constraint.Find(tr.Entity,self.Entity)
					print(const)

					if(IsValid(const)) then
						PlyPos = tr.Entity:WorldToLocal(ply:GetPos())
						timer.Create("plytp", 1, 1, function() ply:SetPos(tracedown.Entity:LocalToWorld(PlyPos)) end)
					end
				end
			end
		else
			self.Entity:EmitSound("WarpDrive/error2.wav",450,70)
		end
	end
end

function ENT:Jump()
	local WarpDrivePos = self.Entity:GetPos()
	local ConstrainedEnts = constraint.GetAllConstrainedEntities(self.Entity)

	for _, entity in pairs(ConstrainedEnts) do	
		if(IsValid(entity)) then
			self:SharedJump(entity)
		end
	end

	local effectdata = EffectData()
		effectdata:SetEntity(self)
		local Dir = (self.JumpCoords.Dest - self:GetPos())
		Dir:Normalize()
		effectdata:SetOrigin(self:GetPos() + Dir * math.Clamp( self:BoundingRadius() * 5, 180, 4092))
		util.Effect("jump_out", effectdata, true, true)

		DoPropSpawnedEffect(self)

		for _, ent in pairs(ConstrainedEnts) do
			local effectdata = EffectData()
			effectdata:SetEntity(ent)
			effectdata:SetOrigin(self:GetPos() + Dir * math.Clamp(self:BoundingRadius() * 5, 180, 4092))
			util.Effect("jump_out", effectdata, true, true)
		end
end

function ENT:SharedJump(ent)
	local WarpDrivePos = self.Entity:GetPos()
	local phys = ent:GetPhysicsObject()

	if !(ent:IsPlayer() or ent:IsNPC()) then 
		ent = phys
	end

	if(!phys:IsMoveable()) then
		phys:EnableMotion(true)
		phys:EnableMotion(false)
	end

	ent:SetPos(self.JumpCoords.Dest + (ent:GetPos() - WarpDrivePos))

	phys:Wake()
end

function ENT:PreEntityCopy()
	if WireAddon then
		duplicator.StoreEntityModifier(self,"WireDupeInfo",WireLib.BuildDupeInfo(self.Entity))
	end
end

function ENT:PostEntityPaste(ply, ent, createdEnts)
	if WireAddon then
		local emods = ent.EntityMods
		if not emods then return end
		WireLib.ApplyDupeInfo(ply, ent, emods.WireDupeInfo, function(id) return createdEnts[id] end)
	end
end

function ENT:OnRemove()
	timer.Remove("wait")
	self.Entity:StopSound("WarpDrive/warp.wav")
	self.Entity:StopSound("WarpDrive/error2.wav")
end
