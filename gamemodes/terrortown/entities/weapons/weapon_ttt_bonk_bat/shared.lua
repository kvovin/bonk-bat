if SERVER then
  AddCSLuaFile()
  util.AddNetworkString("Bonk Bat Primary Hit")
else
  SWEP.PrintName="Bonk Bat"
  SWEP.Author="ajwuk2"
  SWEP.Slot=7

  SWEP.ViewModelFOV=70
  SWEP.ViewModelFlip=false

  SWEP.Icon="VGUI/ttt/icon_bonk_bat.jpg"
  SWEP.EquipMenuData={
    type="Melee Weapon",
    desc="Left click to send to horny jail!\n"
  }

  sound.Add{
    name="Bat.Swing",
    channel=CHAN_STATIC,
    volume=1,
    level=40,
    pitch=100,
    sound="weapons/iceaxe/iceaxe_swing1.wav"
  }

  sound.Add{
    name="Bat.Bonk",
    channel=CHAN_STATIC,
    volume=1,
    level=90,
    pitch=100,
    sound="ttt_bonk_bat/bonk (1)-[AudioTrimmer.com].wav"
  }
end

SWEP.Base="weapon_tttbase"

SWEP.ViewModel=Model("models/weapons/gamefreak/v_nessbat.mdl")
SWEP.WorldModel=Model("models/weapons/gamefreak/w_nessbat.mdl")

SWEP.HoldType="melee"

SWEP.Primary.Damage=10
SWEP.Primary.Delay=.5
SWEP.Primary.ClipSize=3
SWEP.Primary.DefaultClip=3
SWEP.Primary.Automatic=true
SWEP.Primary.Ammo="none"

SWEP.AutoSpawnable=false
SWEP.Kind=WEAPON_EQUIP2
SWEP.CanBuy={ROLE_DETECTIVE}
SWEP.LimitedStock=true

SWEP.DeployDelay=0.9
SWEP.Range=100
SWEP.VelocityBoostAmount=500
SWEP.DeploySpeed = 10

function SWEP:Deploy()
  self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
  self:SetNextPrimaryFire(CurTime()+self.DeployDelay)
  return self.BaseClass.Deploy(self)
end

function SWEP:OnRemove()
  if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
    RunConsoleCommand("lastinv")
  end
end

function SWEP:PrimaryAttack()
  local ply,wep=self.Owner,self.Weapon
  wep:SetNextPrimaryFire(CurTime()+self.Primary.Delay)
  if !IsValid(ply) or wep:Clip1()<=0 then return end

  ply:SetAnimation(PLAYER_ATTACK1)
  wep:SendWeaponAnim(ACT_VM_MISSCENTER)
  wep:EmitSound("Bat.Swing")

  local av,spos,tr=ply:GetAimVector(),ply:GetShootPos()
  local epos=spos+av*self.Range
  local kmins = Vector(1,1,1) * 7
  local kmaxs = Vector(1,1,1) * 7

  self.Owner:LagCompensation( true )

  local tr = util.TraceHull({start=spos, endpos=epos, filter=ply, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

  -- Hull might hit environment stuff that line does not hit
  if not IsValid(tr.Entity) then
    tr = util.TraceLine({start=spos, endpos=epos, filter=ply, mask=MASK_SHOT_HULL})
  end

  self.Owner:LagCompensation( false )

  local ent=tr.Entity

  if !tr.Hit or !(tr.HitWorld or IsValid(ent)) then return end

  if ent:GetClass()=="prop_ragdoll" then
    ply:FireBullets{Src=spos,Dir=av,Tracer=0,Damage=0}
  end

  if CLIENT then return end

  net.Start("Bonk Bat Primary Hit")
  net.WriteTable(tr)
  net.WriteEntity(ply)
  net.WriteEntity(wep)
  net.Broadcast()

  local isply=ent:IsPlayer()

  do
    local dmg=DamageInfo()
    dmg:SetDamage(isply and self.Primary.Damage or self.Primary.Damage*.5)
    dmg:SetAttacker(ply)
    dmg:SetInflictor(wep)
    dmg:SetDamageForce(av*2000)
    dmg:SetDamagePosition(ply:GetPos())
    dmg:SetDamageType(DMG_CLUB)
    ent:DispatchTraceAttack(dmg,tr)
  end

  if wep:Clip1()<=0 then
    timer.Simple(0.49,function() if IsValid(self) then self:Remove() RunConsoleCommand("lastinv") end end)
  end

  -- grenade to stop detective getting stuck in jail
  local gren = ents.Create("jail_discombob")
  gren:SetPos( ent:GetPos() )
  gren:SetOwner(ent)
  gren:SetThrower(ent)
  gren:Spawn()
  gren:SetDetonateExact(CurTime())

  -- making the jail
  timer.Create("jaildiscombob", 0.7, 1, function()
    -- far side
    jail = ents.Create( "prop_physics" )
		jail:SetModel("models/props_building_details/Storefront_Template001a_Bars.mdl" )
    jail:SetPos( ent:GetPos() - Vector(0, 25, -50) )
    jail:SetAngles(Angle(0, 275 ,0))
    jail:Spawn()
    local physobj = jail:GetPhysicsObject()
    if physobj:IsValid() then
      physobj:EnableMotion(false)
      physobj:Sleep(false)
    end
    -- close side
    jail2 = ents.Create( "prop_physics" )
		jail2:SetModel("models/props_building_details/Storefront_Template001a_Bars.mdl" )
    jail2:SetPos( ent:GetPos() + Vector(0, 25, 50) )
    jail2:SetAngles(Angle(0, 275 ,0))
    jail2:Spawn()
    local physobj = jail2:GetPhysicsObject()
    if physobj:IsValid() then
      physobj:EnableMotion(false)
      physobj:Sleep(false)
    end
    -- left side
    jail3 = ents.Create( "prop_physics" )
		jail3:SetModel("models/props_building_details/Storefront_Template001a_Bars.mdl" )
    jail3:SetPos( ent:GetPos() - Vector(25, 0, -50) )
    jail3:SetAngles(Angle(0, 180 ,0))
    jail3:Spawn()
    local physobj = jail3:GetPhysicsObject()
    if physobj:IsValid() then
      physobj:EnableMotion(false)
      physobj:Sleep(false)
    end
    -- right side
    jail4 = ents.Create( "prop_physics" )
		jail4:SetModel("models/props_building_details/Storefront_Template001a_Bars.mdl" )
    jail4:SetPos( ent:GetPos() + Vector(25, 0, 50) )
    jail4:SetAngles(Angle(0, 180 ,0))
    jail4:Spawn()
    local physobj = jail4:GetPhysicsObject()
    if physobj:IsValid() then
      physobj:EnableMotion(false)
      physobj:Sleep(false)
    end
    for _,v in pairs(player.GetAll()) do
      v:ChatPrint(ent:Name() .. " has been sent to horny jail!")
    end
  end)

  timer.Simple(15, function()
    -- remove the jail
    jail:Remove()
    jail2:Remove()
    jail3:Remove()
    jail4:Remove()
  end)

end

if CLIENT then
  net.Receive("Bonk Bat Primary Hit",function()
      local tr,ply,wep=net.ReadTable(),net.ReadEntity(),net.ReadEntity()
      local ent=tr.Entity

      local edata=EffectData()
      edata:SetStart(tr.StartPos)
      edata:SetOrigin(tr.HitPos)
      edata:SetNormal(tr.Normal)
      edata:SetSurfaceProp(tr.SurfaceProps)
      edata:SetHitBox(tr.HitBox)
      edata:SetEntity(ent)

      local isply=ent:IsPlayer()

      if isply or ent:GetClass()=="prop_ragdoll" then
        if isply then
          if IsValid(ent) and IsValid(wep) then
            if ent:Alive() then
              wep:EmitSound("Bat.Bonk") -- change this to bonk noise
            end
          end
        end
        util.Effect("BloodImpact", edata)
      else
        util.Effect("Impact",edata)
      end
    end)
end

hook.Add( "TTTPrepareRound", "removetimers", function()
  timer.Remove("jaildiscombob")
end)