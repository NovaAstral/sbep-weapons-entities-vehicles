
include('shared.lua')
--killicon.AddFont("seeker_missile", "CSKillIcons", "C", Color(255,80,0,255))


function ENT:Initialize()
	self.WInfo = "8x Missile Pod - Shots: "
	self.Shots = self.Entity:GetNetworkedInt( "Shots" ) or 0
end

function ENT:Draw()
	
	self.Entity:DrawModel()

end

function ENT:Think()
	self.Shots = self.Entity:GetNetworkedInt( "Shots" ) or 0
	self.WInfo = "8x Missile Pod - Shots: "..self.Shots
end