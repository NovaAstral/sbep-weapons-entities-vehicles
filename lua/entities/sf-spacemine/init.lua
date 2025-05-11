AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
--include('entities/base_wire_entity/init.lua')
include( 'shared.lua' )

util.PrecacheSound( "explode_9" )
util.PrecacheSound( "explode_8" )
util.PrecacheSound( "explode_5" )

ENT.CDSIgnore = true -- Stops crashing from Space Combat when the mine explodes from taking damage

function ENT:Initialize()
	self.Entity:SetModel( "models/Slyfo/spacemine.mdl" )
	self.Entity:SetName("Mine")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	if WireAddon then
		self.Inputs = WireLib.CreateSpecialInputs(self.Entity,{"Arm"})
		self.Outputs = WireLib.CreateSpecialOutputs(self.Entity,{"Health"});
	end

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(false)
		phys:EnableDrag(false)
		phys:EnableCollisions(true)
	end

	self.EntHP = 100
	self.MaxHP = 100
	Wire_TriggerOutput(self.Entity,"Health",self.EntHP)
	
	--self:SetHealth(self.Health)
	--self:MaxHealth(self.MaxHealth)
	
    --self.Entity:SetKeyValue("rendercolor", "0 0 0")
	self.PhysObj = self.Entity:GetPhysicsObject()
	self.CAng = self.Entity:GetAngles()

	self.Entity:Arm() --perhaps undo this later
end

function ENT:TriggerInput(iname, value)
	if (iname == "Arm") then
		if (value > 0) then
			self.Entity:Arm()
		end
	end
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,60)
	
	local ent = ents.Create("SF-SpaceMine")
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
	
	return ent
	
end

function ENT:PhysicsCollide( data, physobj )
	if (!self.Exploded and self.Armed) then
		self:Splode()
	end
end

function ENT:OnTakeDamage(damage)
	local dmg = damage:GetDamage()
	
	if (!self.Exploded and self.Armed) then
		self.EntHP = math.Clamp(self.EntHP - dmg,0,self.MaxHP)
		Wire_TriggerOutput(self.Entity,"Health",self.EntHP)

		if(self.EntHP <= 0) then
			self:Splode()
		end
	end
	
end

function ENT:Arm()
	self.Armed = true
	self.Entity:SetArmed(true)
	self.PhysObj:EnableGravity(false)
end

function ENT:Splode()
	if(!self.Exploded) then
		self.Exploded = true
		
		util.BlastDamage(self.Entity, self.Entity, self.Entity:GetPos(), 750, 750)

		local targets = ents.FindInSphere( self.Entity:GetPos(), 2000)
		
		for _,i in pairs(targets) do
			if i:GetPhysicsObject() and i:GetPhysicsObject():IsValid() and !i.MineProof and !i:IsPlayer() then
				i:GetPhysicsObject():ApplyForceOffset( Vector(500000,500000,500000), self.Entity:GetPos())
			end
		end
		
		self.Entity:EmitSound("explode_9")
		
		local effectdata = EffectData()
		effectdata:SetOrigin(self.Entity:GetPos())
		effectdata:SetStart(self.Entity:GetPos())
		util.Effect( "BigTorpSplode", effectdata )
		self.Exploded = true
		
		local ShakeIt = ents.Create( "env_shake" )
		ShakeIt:SetName("Shaker")
		ShakeIt:SetKeyValue("amplitude", "200" )
		ShakeIt:SetKeyValue("radius", "200" )
		ShakeIt:SetKeyValue("duration", "5" )
		ShakeIt:SetKeyValue("frequency", "255" )
		ShakeIt:SetPos( self.Entity:GetPos() )
		ShakeIt:Fire("StartShake", "", 0);
		ShakeIt:Spawn()
		ShakeIt:Activate()
		
		ShakeIt:Fire("kill", "", 6)
	end
	
	self.Entity:Remove()
	
end

function ENT:PreEntityCopy()
	if WireAddon then
		duplicator.StoreEntityModifier(self,"WireDupeInfo",WireLib.BuildDupeInfo(self.Entity))
	end
end

function ENT:PostEntityPaste(ply, ent, createdEnts)
	local emods = ent.EntityMods
	if not emods then return end
	if WireAddon then
		WireLib.ApplyDupeInfo(ply, ent, emods.WireDupeInfo, function(id) return createdEnts[id] end)
	end
	ent.SPL = ply
end