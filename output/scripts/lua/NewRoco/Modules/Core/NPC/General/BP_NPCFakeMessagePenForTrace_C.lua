require("UnLuaEx")
local PetHUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.PetHUDComponent")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local BP_NPCFakeMessagePenForTrace_C = Base:Extend("BP_NPCFakeMessagePenForTrace_C")

function BP_NPCFakeMessagePenForTrace_C:Init()
  Base.Init(self)
end

function BP_NPCFakeMessagePenForTrace_C:OnFrameLoad(distanceRatio)
  local npc = self.sceneCharacter
  if npc then
    local hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
    if not hudClass then
      Log.Error("BP_NPCFakeMessagePenForTrace_C:OnVisible _G.NRCBigWorldPreloader:Get(PET_HUD) First Failed")
      hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
      if not hudClass then
        Log.Error("BP_NPCFakeMessagePenForTrace_C:OnVisible _G.NRCBigWorldPreloader:Get(PET_HUD) Second Failed")
        return
      end
      return
    end
    local hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
    if not hud then
      Log.Error("BP_NPCFakeMessagePenForTrace_C:OnVisible Create hud First Failed")
      hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
      if not hud then
        Log.Error("BP_NPCFakeMessagePenForTrace_C:OnVisible Create hud Second Failed")
        return
      end
    end
    self.HeadWidget:SetWidget(hud)
    hud:SetParentHUD(self.HeadWidget)
    self.hudComp = npc:EnsureComponent(PetHUDComponent)
    if self.hudComp then
      self.hudComp:OnSetViewObj()
      self.hudComp:ForceUpdate()
    end
  end
  Base.OnFrameLoad(self, distanceRatio)
end

return BP_NPCFakeMessagePenForTrace_C
