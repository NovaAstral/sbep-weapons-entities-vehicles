
include('shared.lua')
killicon.AddFont("seeker_missile", "CSKillIcons", "C", Color(255,80,0,255))

function ENT:Initialize()
	self.emitter = ParticleEmitter( self:GetPos() )
end

function ENT:Draw()
	self.Entity:DrawModel()
end

function ENT:Think()
	local pos = self:GetPos()
	
	local smoke = self.emitter:Add( "particles/smokey", pos )
	if smoke then
		smoke:SetPos( self:GetPos() + self:GetForward() * ( -3  ) )
		smoke:SetVelocity( self:GetForward() * -math.random( 5 ) )
		smoke:SetLifeTime( 0 )
		smoke:SetDieTime( 0.5 )
		smoke:SetStartAlpha( math.random( 30 ) + 30 )
		smoke:SetEndAlpha( 0 )
		smoke:SetStartSize( math.random( 10 ) + 5 )
		smoke:SetEndSize( math.random( 15 ) + 35 )
		smoke:SetRoll( math.random( 359 ) + 1 )
		smoke:SetRollDelta( math.random( -2, 2 ) )
		smoke:SetColor( 175, 175, 175 )
	end

	local particle = self.emitter:Add( "particles/flamelet"..math.random(1,5), pos + ( self:GetForward() * -10 ) )
	if (particle) then
		particle:SetVelocity((self:GetForward() * -5) )
		particle:SetLifeTime( 0 )
		particle:SetDieTime( 0.1 )
		particle:SetStartAlpha( math.Rand( 230, 255 ) )
		particle:SetEndAlpha( 0 )
		particle:SetStartSize( 17 )
		particle:SetEndSize( 0 )
		particle:SetRoll( math.Rand(0, 360) )
		particle:SetRollDelta( math.Rand(-10, 10) )
		particle:SetColor( 255 , 255 , 255 ) 
	end
end