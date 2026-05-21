require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local PetHUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.PetHUDComponent")
local BP_NPCHealGrassForTrace_C = Base:Extend("BP_NPCHealGrassForTrace_C")

function BP_NPCHealGrassForTrace_C:Init()
  Base.Init(self)
  self.bActivated = false
end

function BP_NPCHealGrassForTrace_C:OnFrameLoad(distanceRatio)
  local npc = self.sceneCharacter
  local hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
  if not hudClass then
    Log.Error("BP_NPCHealGrassForTrace_C:OnVisible _G.NRCBigWorldPreloader:Get(PET_HUD) First Failed")
    hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
    if not hudClass then
      Log.Error("BP_NPCHealGrassForTrace_C:OnVisible _G.NRCBigWorldPreloader:Get(PET_HUD) Second Failed")
      return
    end
    return
  end
  local hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
  if not hud then
    Log.Error("BP_NPCHealGrassForTrace_C:OnVisible Create hud First Failed")
    hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
    if not hud then
      Log.Error("BP_NPCHealGrassForTrace_C:OnVisible Create hud Second Failed")
      return
    end
  end
  if hud and npc then
    self.HeadWidget:SetWidget(hud)
    hud:SetParentHUD(self.HeadWidget)
    local hudComp = npc:EnsureComponent(PetHUDComponent)
    hudComp:OnSetViewObj()
    hudComp:ForceUpdate()
  end
  Base.OnFrameLoad(self, distanceRatio)
end

function BP_NPCHealGrassForTrace_C:OnLeaveBattle()
  Base.OnLeaveBattle(self)
  local npc = self.sceneCharacter
  if not npc then
    return
  end
  local hudComp = npc:EnsureComponent(PetHUDComponent)
  local Hud = hudComp._headHud
  if not Hud then
    return
  end
  Hud:ShowTopMessage(true, npc)
end

return BP_NPCHealGrassForTrace_C
