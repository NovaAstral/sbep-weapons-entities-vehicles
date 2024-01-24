include('shared.lua')

language.Add( "Cleanup_warpdrive", "Warp Drive v2" )
language.Add( "Cleaned_warpdrive", "Cleaned up Warp Drive v2" )

function ENT:Draw()
   -- self.BaseClass.Draw(self)
   self:DrawEntityOutline( 0.0 ) 			
   self.Entity:DrawModel() 					
end

function ENT:DrawEntityOutline()
return
end