if SERVER then
  AddCSLuaFile()
  util.AddNetworkString("Bonk Bat Primary Hit")
else
  SWEP.PrintName = "Bonk Bat"
  SWEP.Author = "ajwuk2"
  SWEP.Slot = 7

  SWEP.ViewModelFOV = 70
  SWEP.ViewModelFlip = false

  SWEP.Icon = "VGUI/ttt/icon_bonk_bat.jpg"
  SWEP.EquipMenuData = {
    type = "Melee Weapon",
    desc = "Left click to send to horny jail!\n"
  }

  sound.Add{
    name = "Bat.Swing",
    channel = CHAN_STATIC,
    volume = 1,
    level = 40,
    pitch = 100,
    sound = "weapons/iceaxe/iceaxe_swing1.wav"
  }

  sound.Add{
    name = "Bat.Bonk",
    channel = CHAN_STATIC,
    volume = 1,
    level = 90,
    pitch = 100,
    sound = "ttt_bonk_bat/bonk (1)-[AudioTrimmer.com].wav"
  }
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = Model("models/weapons/gamefreak/v_nessbat.mdl")
SWEP.WorldModel = Model("models/weapons/gamefreak/w_nessbat.mdl")

SWEP.HoldType = "melee"

SWEP.Primary.Damage = 10
SWEP.Primary.Delay = 0.5
SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.AutoSpawnable = false
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_DETECTIVE}
SWEP.LimitedStock = true

SWEP.DeployDelay = 0.9
SWEP.Range = 100
SWEP.VelocityBoostAmount = 500
SWEP.DeploySpeed = 10

function SWEP:Deploy()
  self:SendWeaponAnim(ACT_VM_DRAW)
  self:SetNextPrimaryFire(CurTime() + self.DeployDelay)
  return self.BaseClass.Deploy(self)
end

function SWEP:OnRemove()
  if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
    RunConsoleCommand("lastinv")
  end
end

function SWEP:PrimaryAttack()
  local ply = self:GetOwner()
  self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
  if !IsValid(ply) or self:Clip1() <= 0 then return end

  ply:SetAnimation(PLAYER_ATTACK1)
  self:SendWeaponAnim(ACT_VM_MISSCENTER)
  self:EmitSound("Bat.Swing")

  local av, spos = ply:GetAimVector(), ply:GetShootPos()
  local epos = spos + av * self.Range
  local kmins = Vector(1,1,1) * 7
  local kmaxs = Vector(1,1,1) * 7

  ply:LagCompensation(true)

  local tr = util.TraceHull({start = spos, endpos = epos, filter = ply, mask = MASK_SHOT_HULL, mins = kmins, maxs = kmaxs})

  -- Hull might hit environment stuff that line does not hit
  if !IsValid(tr.Entity) then
    tr = util.TraceLine({start = spos, endpos = epos, filter = ply, mask = MASK_SHOT_HULL})
  end

  ply:LagCompensation( false )

  local ent = tr.Entity

  if !tr.Hit or !(tr.HitWorld or IsValid(ent)) then return end

  if ent:GetClass() == "prop_ragdoll" then
    ply:FireBullets{Src = spos, Dir = av, Tracer = 0, Damage = 0}
  end

  if CLIENT then return end

  net.Start("Bonk Bat Primary Hit")
    net.WriteTable(tr)
    net.WriteEntity(self)
  net.Broadcast()

  local dmg = DamageInfo()
  dmg:SetDamage(ent:IsPlayer() and self.Primary.Damage or self.Primary.Damage * 0.5)
  dmg:SetAttacker(ply)
  dmg:SetInflictor(self)
  dmg:SetDamageForce(av * 2000)
  dmg:SetDamagePosition(ply:GetPos())
  dmg:SetDamageType(DMG_CLUB)
  ent:DispatchTraceAttack(dmg, tr)

  if self:Clip1() <= 0 then
    timer.Simple(0.49,function() if IsValid(self) then self:Remove() RunConsoleCommand("lastinv") end end)
  end

  -- grenade to stop detective getting stuck in jail
  local gren = ents.Create("jail_discombob")
  gren:SetPos(ent:GetPos())
  gren:SetOwner(ent)
  gren:SetThrower(ent)
  gren:Spawn()
  gren:SetDetonateExact(CurTime())

  local jail = {}
  -- making the jail
  timer.Create("jaildiscombob", 0.7, 1, function()
    -- far side
    jail[0] = JailWall(Vector(0, 25, -50), Angle(0, 275 ,0))
    -- close side
    jail[1] = JailWall(Vector(0, 25, 50), Angle(0, 275 ,0))
    -- left side
    jail[2] = JailWall(Vector(25, 0, -50), Angle(0, 180, 0))
    -- right side
    jail[3] = JailWall(Vector(25, 0, 50), Angle(0, 180, 0))
    for _,v in pairs(player.GetAll()) do
      v:ChatPrint(ent:Name() .. " has been sent to horny jail!")
    end
  end)

  timer.Simple(15, function()
    -- remove the jail
    for _,v in pairs(jail) do
      v:Remove()
    end
  end)

end

function JailWall(pos, angle)
  wall = ents.Create( "prop_physics" )
  wall:SetModel("models/props_building_details/Storefront_Template001a_Bars.mdl" )
  wall:SetPos( ent:GetPos() + pos )
  wall:SetAngles(angle)
  wall:Spawn()
  local physobj = wall:GetPhysicsObject()
  if physobj:IsValid() then
    physobj:EnableMotion(false)
    physobj:Sleep(false)
  end
  return wall
end

if CLIENT then
  net.Receive("Bonk Bat Primary Hit", function()
      local tr, wep = net.ReadTable(), net.ReadEntity()
      local target = tr.Entity

      local edata = EffectData()
      edata:SetStart(tr.StartPos)
      edata:SetOrigin(tr.HitPos)
      edata:SetNormal(tr.Normal)
      edata:SetSurfaceProp(tr.SurfaceProps)
      edata:SetHitBox(tr.HitBox)
      edata:SetEntity(target)


      if target:IsPlayer() or target:GetClass() == "prop_ragdoll" then
        if target:IsPlayer() and IsValid(target) and IsValid(wep) and target:Alive() then
          target:EmitSound("Bat.Bonk") -- change this to bonk noise
        end
        util.Effect("BloodImpact", edata)
      else
        util.Effect("Impact", edata)
      end
    end)
end

hook.Add( "TTTPrepareRound", "removetimers", function()
  timer.Remove("jaildiscombob")
end)
