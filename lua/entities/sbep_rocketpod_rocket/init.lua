--[[
	
	Developed By Dubby
		
	Copyright (c) Dubby 2009
	
]]--
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

util.PrecacheSound( "explode_9" )

function ENT:Initialize()
	self.Entity:SetModel( "models/weapons/w_missile_launch.mdl" )
	self.Entity:SetName( "Homing Rocket" )
	self.Entity:PhysicsInit( SOLID_BBOX )
	self.Entity:SetMoveType( MOVETYPE_FLY )
	self.Entity:SetSolid( SOLID_BBOX )
	self.Entity:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
	
	self.SB_Ignore = true --make spacebuild ignore me
	self.warhead = true
	self.Untouchable = true
	self.Unconstrainable = true
	self.PhysgunDisabled = true
	self.CanTool = function( ply, trace, mode )
		return false
	end
end

function ENT:Setup( src, vec, tar, ply, dur )
	self.launcher = src
	self.vector = vec
	self.target = tar
	self.Owner = ply
	self:Fire( "kill", "", math.Clamp( dur, 2, 30 ) )
end

function ENT:GetTargetData( clk ) --we need the think's clk for motion prediction of a target entity
	local dir, pos = ( self:GetForward() + self.forward ):GetNormal(), self:GetPos()
	local vec = dir * 1000 + pos
	if IsValid( self.target ) then
		if self.target:IsPlayer() then
			if self.target:Alive() then
				if self.target:InVehicle() then
					--target vehicle
					vec = self.target:GetVehicle():NearestPoint( pos ) + self.target:GetVelocity() * clk
				elseif self.target:Crouching() then
					--lower vector
					vec = self.target:GetPos() + self.target:GetVelocity() * clk
				else
					vec = self.target:GetShootPos() + self.target:GetVelocity() * clk
				end
			elseif not self.target:Alive() then
				self.target = nil
				vec = ( dir * 0.75 + VectorRand() * 0.25 ):GetNormal() * 1000 + pos
			end
		else
			vec = self.target:GetPos() + self.target:OBBCenter() + self.target:GetVelocity() * clk --( self.target:NearestPoint( pos ) - self.target:GetPos() ):GetNormal() * self.target:BoundingRadius() + self.target:GetPos() + self.target:GetVelocity() * clk
		end
		dir = ( vec - pos ):GetNormal()
	elseif self.vector and self.vector ~= vector_origin then
		vec = self.vector
		dir = ( vec - pos ):GetNormal()
	end
	return vec, dir
end

function RealNormal(vec)
	
	return vec/math.sqrt(vec[1]^2 + vec[2]^2 + vec[3]^2)

end

function ENT:Think()
	local ct, clk = CurTime(), 0.1
	if not self.spawned then 
		clk = math.Rand( 0.2, 0.4 )
		self.prehoming = ct + 2 + clk
		self.spawned = true
		self.forward = self:GetForward()
		if IsValid( self.launcher ) then
			self.speed = self:GetVelocity():Length() 
		else
			self.speed = 2000
			self:Fire( "kill", "", 8 )
		end
		--SC_Rockets[ self:EntIndex() ] = self.Entity --this just makes sure I always get included in the rockets table for devices that track/shootdown rockets!
	else
		local vec, dir = self:GetTargetData( clk )
		if ct < self.prehoming then
			--we do this for a second after the rocket is launched to make sure the rocket can orient itself towards the target properly, as not to end up as "dead on arrival"
			self.speed = self:GetVelocity():Length() + 25
			dir = RealNormal( RealNormal(self:GetVelocity()) * 0.55 + dir * 0.45 )
			if dir:DotProduct( RealNormal( vec - self:GetPos() ) ) > 0.9 then
				--we've aligned with the target, so we can stop prehoming now
				self.prehoming = 0
			end
		else
			self.speed = self:GetVelocity():Length() + 200
			local pos = self:GetPos()
			local dst = pos:Distance( vec )
			local min, max = 50, 200
			if IsValid( self.target ) then 
				local sizes = self.target:OBBMaxs() - self.target:OBBMins()
				max = math.min( ( sizes.x + sizes.y + sizes.z ) / 3 + 50, 400 )
			end
			if dst <= min then
				--rocket is close enough that it should explode anyways, so force the rocket to fire it's explosion
				if IsValid( self.target ) then
					self:Touch( self.target )
					return false
				end
			elseif dst > max then
				--this nasty bit of math tells the rocket how to turn itself towards the target. 
				--it incorporates a wobble in movement, and allows for a rocket to 'miss' a target if it flies (relatively) perpendicular to the target. 
				--a player can dodge the rocket much the same way a bull fighter dodges the bull - by side stepping at the last moment. 
				local aim, wobble = RealNormal( vec - pos ), 0.06
				local wvec = VectorRand()
				local mult = math.deg( math.min( math.acos( dir:DotProduct( aim ) ), 30 ) ) / 180
				local turn = math.Clamp( math.abs( mult - ( 1 - mult * mult ) ), 0, 1 - wobble )
				local dval = 1 - math.Clamp( turn, 0, 0.99 )
				local aval = math.Clamp( 1 - dval - wobble, 0, 0.12 )
					  dval = 1 - wobble - aval
				dir = aim * aval + dir * dval + wvec * wobble
			end
		end
		
		self.forward = dir
		self:SetAngles( dir:Angle() )
		if self.speed < 8000 then --speed limit
			--if we don't overwrite the old velocity, the rockets will end up orbiting instead of striking.
			self:SetVelocity( dir * self.speed - self:GetVelocity() )
		end
	end	
			
		/*
		else
			self.speed = self:GetVelocity():Length() + 200 --harder to outrun, but they can be dodged
			// i am a little bothered about getting the velocity's length every think, but alas, without it, rockets could slam into their launchers and blow up their own ship.
	
			if IsValid( self.launcher ) then
				--still getting info for flight
				if IsValid( self.target ) then
				--target still exists
				vec = self:GetTargetPosition( self.target ) + self.target:GetVelocity() * clk
			else
				if self.launcher.vec ~= vector_origin then
					--has valid position it wants me to go to
					vec = self.launcher.vec
				elseif self.vector ~= vector_origin then
					--go here as a backup
					vec = self.vector
				else
					--fly straight
					vec = dir * 10000 + self:GetPos()
					--clk = 1
				end
			end
		else
			--on my own now
			if IsValid( self.target ) then
				--target still exists
				vec = self:GetTargetPosition( self.target ) + self.target:GetVelocity() * clk
			else
				if self.vector and self.vector ~= vector_origin then
					--still have valid location to go to
					vec = self.vector
				else
					--fly straight, turn off thinking
					--print("Woops!")
					self:Fire( "kill", "", 8 )
					self:SetAngles( VectorRand():Angle() )
					self:SetVelocity( dir * 5000 - self:GetVelocity() )
					self.Think = function() end
					return
				end
			end
		end
		*/
	
	self.Entity:NextThink( ct + FrameTime() + clk )
	return true
end

function ENT:PassesTriggerFilters( ent )
	if IsValid( self.launcher ) then
		local core = self.launcher.SC_CoreEnt
		if IsValid( core ) then
			if core == ent.SC_CoreEnt then
				return false
			end
		end
	end
	return true
end

function ENT:PhysicsCollide()
end

function ENT:Touch()
end

function ENT:StartTouch( ent )
	if IsValid( self.launcher ) and ent == self.launcher then
		// extremely bizarre error. when rockets from different launchers bump into each other, they think they're bumping into the launcher - even though they are obviously not. it happens alot. 
		return
	else
		if IsValid( ent ) then
			if ent:IsWorld() then
				self:Explode( self )
			else
				self:Explode( ent )
			end
		else
			self:Explode( self )
		end
	end
end

function ENT:OnTakeDamage()
end

function ENT:EndTouch()
end

function ENT:OnRemove()
	--SC_Rockets[ self:EntIndex() ] = nil
end

function ENT:Explode(e)
	--local pos, extra = self:GetPos(), math.random(1,21) * 25
	local pos, extra = self:GetPos(), math.random(0,5)*100
	
	
	local multi = 1
	if e.SC_CoreEnt and e.SC_CoreEnt.sigrad then
		multi = math.Clamp( ((e.SC_CoreEnt.sigrad/39.3700787)/50)^2,0.1,1)
	end
	local dmg = (1000+extra) * multi
	local expdmg = 250
	--cbt_hcgexplode( pos, 100, 200, 25, self.Owner )
	SC_Explode(pos, 100, {EM=0,EXP=expdmg*0.8,KIN=expdmg*0.1,THERM=expdmg*0.1}, self.Owner, self )
	
	if e:GetClass() == "shield" then
		--e:Hit( self, pos, (975+extra)*4, -1 * self:GetForward():Normalize() ) //5250 was 750
		e:Hit( self, pos, (500+extra)*2, -1 * self:GetForward():Normalize() ) //5250 was 750
	else
		/*
		if e:IsPlayer() or e:IsNPC() then
			cbt_dealhcghit( e, 1500, 0, e:GetPos(), pos, self.Owner ) //1500 was 150
		else
			cbt_dealhcghit( e, (975+extra)*multi, 0, e:GetPos(), pos, self.Owner ) //1750 was 250
		end
		*/
		SC_ApplyDamage(e, {EM=0,EXP=dmg*0.6,KIN=dmg*0.3,THERM=dmg*0.1}, self.Owner, self, self:GetPos())
	end

	self:EmitSound("explode_9",300,100)

	local effectdata = EffectData()
	effectdata:SetAngles( self:GetForward():Angle() )
	effectdata:SetOrigin( pos )
	effectdata:SetStart( pos )
	util.Effect( "SmallSplode", effectdata )

	self:Remove()
end