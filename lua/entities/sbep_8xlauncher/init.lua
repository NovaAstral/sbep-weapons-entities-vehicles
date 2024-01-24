
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('entities/base_wire_entity/init.lua')
include( 'shared.lua' )

local ENERGY = 1500 //energy used to create rocket during reload phase
local CLIP = 8 //total capacity of rockets
local RELOAD = 1 //seconds it takes to make each bomb
local ROCKET_LIFE = 6 //seconds the rockets last in flight --was 7

function ENT:Initialize()

	self:SetModel( "models/Slyfo/missile_pod_8.mdl" ) 
	self:SetName("Rocket Pod")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	local inNames = {"Fire","X","Y","Z","Vector","Target"}
	local inTypes = {"NORMAL","NORMAL","NORMAL","NORMAL","VECTOR","ENTITY"}
	self.Inputs = WireLib.CreateSpecialInputs( self,inNames,inTypes)
	self.Outputs = Wire_CreateOutputs( self, { "ShotsLeft", "CanFire" })
	
	self.PhysObj = self:GetPhysicsObject()
	if (self.PhysObj:IsValid()) then
		self.PhysObj:Wake()
		self.PhysObj:EnableGravity(true)
		self.PhysObj:EnableDrag(true)
		self.PhysObj:EnableCollisions(true)
	end

	self.SC_Immune = true
	self.Magazine = 0
	self.Firing = false
	self.ArmDelay = CurTime()	
	self.vec = Vector(0,0,0)

	RD_AddResource(self, "energy", 0)
end

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 29.7
	local ent = ents.Create( "rocketpod_8" )
	ent:SetAngles( tr.HitNormal:Angle() )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()
	ent.Owner = ply
	ent:GetPhysicsObject():Sleep()
	return ent
end

function ENT:OnRemove()
	Dev_Unlink_All(self.Entity)
	if not (WireAddon == nil) then Wire_Remove(self.Entity) end
end

function ENT:Use( ply )
	if self.Owner ~= ply and not ply:IsAdmin() then 
		ply:PrintMessage(HUD_PRINTCENTER,"You must own this [Rocket Pod] to view its detailed information!" )
		return false
	end
	ply:PrintMessage(HUD_PRINTCONSOLE,"[Rocket Pod] Information:" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"Time delay between firing each rocket = 1/4 second")
	ply:PrintMessage(HUD_PRINTCONSOLE,"Time needed for constructing each rocket = "..RELOAD.." seconds" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"Energy used to create one rocket = "..ENERGY.." Energy" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"Number of rockets which can be stored = "..CLIP.." rockets" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"Energy needed to create entire clip = "..tostring( ENERGY * CLIP ).." Energy" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"[Homing Rocket] Information:" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"Projectile Velocity = 1,000-5,000" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"Projectile Acceleration = 1,500/sec" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"Projectile Lifetime = "..ROCKET_LIFE.." seconds")
	ply:PrintMessage(HUD_PRINTCONSOLE,"Impact Damage vs Shields = 2,000-4,000" ) //775-1,000" ) --5,275-5,500"
	ply:PrintMessage(HUD_PRINTCONSOLE,"Impact Damage vs Ships = 1,000-1,500" ) //275-500" ) --1,775-2,000"
	ply:PrintMessage(HUD_PRINTCONSOLE,"Impact Damage Type = Explisive/Kinetic/Thermal" )
	ply:PrintMessage(HUD_PRINTCONSOLE,"Explosion Radius = 100")
	ply:PrintMessage(HUD_PRINTCONSOLE,"Explosion Damage Type = Explosive")
	ply:PrintMessage(HUD_PRINTCONSOLE,"Explosion Damage at Epicenter = 250")
	ply:PrintMessage(HUD_PRINTCONSOLE,"Explosion Shrapnel Damage = 25")
	ply:PrintMessage(HUD_PRINTTALK,"Detailed information about [Rocket Pod] has been posted to your console. Press [`] to open your console." )
	return false
end

function ENT:TriggerInput(iname, value)		
	if (iname == "Fire") then
		if (value > 0) then
			self.Firing = true
		else
			self.Firing = false
		end
	elseif (iname == "X") then
		self.vec.x = value
	elseif (iname == "Y") then
		self.vec.y = value
	elseif (iname == "Z") then
		self.vec.z = value
	elseif (iname == "Vector") then
		self.vec = value
	elseif (iname == "Target") then
		if (value:IsValid()) then
			self.Target = value
		else
			self.Target = nil
		end
	end
end

function ENT:HPFire()
	self.Firing = true
end

function ENT:Think()
	local clk = 0.1
	if self.Firing then
		if (self.Magazine > 0) then
			self.Magazine = self.Magazine - 1
			self:Launch()
			clk = 0.25
		else
			self.Firing = false
		end
	else
		if (self.Magazine < CLIP) then
			if (CurTime() > self.ArmDelay) then
				if (RD_GetResourceAmount(self, "energy") > ENERGY) then
					RD_ConsumeResource(self, "energy", ENERGY)
					self.Magazine = self.Magazine + 1
					self.ArmDelay = CurTime() + RELOAD
					self:EmitSound("Buttons.snd26")
				end
			end
		end
	end

	Wire_TriggerOutput(self, "ShotsLeft", self.Magazine)
	if (self.Magazine > 0) then 
		Wire_TriggerOutput(self, "CanFire", 1)
	else
		Wire_TriggerOutput(self, "CanFire", 0)
	end
	
	self.Entity:NextThink( CurTime() + FrameTime() + clk )
	return true
end

function ENT:Touch( ent )
	if ent.HasHardpoints then
		if ent.Cont && ent.Cont:IsValid() then HPLink( ent.Cont, ent.Entity, self ) end
	end
end

function ENT:Launch()
	local Rocket = ents.Create( "rocketpod_rocket" )
	if ( !Rocket:IsValid() ) then 
		return 
	else
		local Vel = self.PhysObj:GetVelocity()
		local Forward = self:GetForward()
		local y = math.Round(self.Magazine%2/8+1.4)*8-12
		local x = math.Round((self.Magazine%8+1)/2)*8-20
		Rocket:SetPos( self:GetPos() + self:GetUp()*y + self:GetRight()*x + Forward*44 + ( Vector(math.abs(Vel.x),math.abs(Vel.y),math.abs(Vel.z))*Forward ))
		Rocket:SetAngles( self:GetAngles() )
		Rocket:Setup( self.Entity, Vector(self.vec.x,self.vec.y,self.vec.z), self.Target, self.Owner, ROCKET_LIFE )
		if IsValid( self:GetParent() ) then
			Rocket:SetOwner( self:GetParent() )
		else
			Rocket:SetOwner( self.Entity )
		end
		Rocket:SetVelocity( Forward * 1000 + Vel / 4 )
		Rocket:Spawn()
		Rocket:Activate()

		self:EmitSound("Weapon_RPG.Single", math.random(30)+110, math.random(5)+95)
	end
end

function ENT:PreEntityCopy()
	RD_BuildDupeInfo(self.Entity)
	if not (WireAddon == nil) then
		local DupeInfo = WireLib.BuildDupeInfo(self.Entity)
		if DupeInfo then
			duplicator.StoreEntityModifier( self.Entity, "WireDupeInfo", DupeInfo )
		end
	end
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	RD_ApplyDupeInfo(Ent, CreatedEntities)
	if not (WireAddon == nil) and (Ent.EntityMods) and (Ent.EntityMods.WireDupeInfo) then
		WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
end
