AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:Initialize()
  self:SetModel( self.lootModel )
  self:PhysicsInit( SOLID_VPHYSICS )
  self:SetMoveType( MOVETYPE_VPHYSICS )
  self:SetSolid( SOLID_VPHYSICS )
  local phys = self:GetPhysicsObject()
  if (phys:IsValid()) then
    phys:Wake()
  end

  self:SetUseType( ONOFF_USE )
  self:SetNWBool( "isLoot", true )
  self:SetNWInt( "timeToLoot", self.timeToLoot )
  self:SetNWInt( "nextSearch", 0 )
  self.UsingPlayer = nil
  self.UseStart = nil  
  self.BeingUsed = false
  self.NextSearch = 0
  self.LootProgress = 0
  self.NextSound = 0
end

function ENT:SpawnFunction(ply, tr, class)

  if (!tr.Hit) then return end

  local Angs = ply:EyeAngles()
  Angs.p = 0
  Angs.y = Angs.y + 180

  local ent = ents.Create(class)
  ent:SetPos(tr.HitPos + tr.HitNormal * 50)
  ent:SetAngles(Angs)
  ent:Spawn()
  ent:DropToFloor()
  ent:Activate()

  return ent
end

function ENT:Loot( ply )
  self:SetNWInt( "nextSearch", CurTime() + self.cooldownTime )
  self.NextSearch = CurTime() + self.cooldownTime
  
  if hook.Run("XeLootingSystemDropStart", self, ply) then return end
  
  local chc, minChc, maxChc = 0
  local lootChc = {}
  local lootClass = ""
      local loot
  for k, v in pairs ( self.lootList ) do
    lootChc[k] = { min = chc+1, max = chc + v }
    chc = chc + v
  end
  local rNumber = math.random( 1, chc )
  for k, v in pairs ( lootChc ) do
    if ( rNumber >= v.min and rNumber <= v.max ) then
      lootClass = k
    end
  end
  
  if hook.Run("XeLootingSystemDropResultDetermined", self, ply, lootClass) then return end
  
  if ( lootClass ~= "nothing" ) then
    loot = ents.Create( lootClass )
    if ( loot ~= NULL ) then
    loot:SetPos( self:GetPos() + ( self:GetAngles():Forward() * self.lootPos.forward ) + ( self:GetAngles():Right() * self.lootPos.right ) + ( self:GetAngles():Up() * self.lootPos.up ) )
    loot:SetAngles( self:GetAngles() )
    loot:Spawn()
    end
  end
  
  hook.Run("XeLootingSystemDropFinish", self, ply, loot)
end

function ENT:Use( activator, caller, usetype )
  if not caller:IsPlayer() then return end
  if luctus_loot_blacklist_jobs[RPExtraTeams[caller:Team()].name] then return end
  if usetype == USE_ON and not self.BeingUsed and self.NextSearch < CurTime() then
    self:StartUse(caller)
  elseif usetype == USE_OFF and self.BeingUsed then
    self:CancelUse()
  end
end

function ENT:StartUse(ply)
  self:EnableProgressBar(ply, true)
  self.UsingPlayer = ply
  self.UseStart = CurTime()
  self.BeingUsed = true
end

function ENT:CancelUse()
  self:EnableProgressBar(self.UsingPlayer, false)
  self.UsingPlayer = nil
  self.UseStart = nil  
  self.BeingUsed = false
  
end

function ENT:EnableProgressBar(ply, enabled)
  net.Start("lootsystem_enable_hud")
    net.WriteBool(enabled)
  net.Send(ply)
end
 
function ENT:Think()

  if self.BeingUsed then
    if not IsValid(self.UsingPlayer) or !self.UsingPlayer:KeyDown(IN_USE) or self.NextSearch > CurTime() or self.UsingPlayer:GetEyeTraceNoCursor().Entity != self or self:GetPos():DistToSqr(self.UsingPlayer:GetPos()) > 256*256 then self:CancelUse() return end
    if luctus_loot_blacklist_jobs[RPExtraTeams[self.UsingPlayer:Team()].name] then return end
    if self.NextSound < CurTime() then
      self:EmitSound("npc/combine_soldier/gear5.wav", 50, 100)
      self.NextSound = CurTime() + 1
    end
    self.LootProgress = ((CurTime() - self.UseStart) / self.timeToLoot) * 100

    if self.LootProgress >= 100 then 
      self:Loot(self.UsingPlayer) 
      self:EnableProgressBar(self.UsingPlayer, false) 
      self:CancelUse() 
      return 
    end
    
  end
  self:NextThink(CurTime() + 0.3)
end
