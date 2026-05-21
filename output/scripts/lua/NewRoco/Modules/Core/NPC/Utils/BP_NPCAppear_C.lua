require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local NPCAppearComponent = require("NewRoco.Modules.Core.NPC.ViewNPCComponent.NPCAppearComponent")
local HomeNpcInfoComponent = require("NewRoco.Modules.System.Home.Components.HomeNpcInfoComponent")
local BP_NPCAppear_C = Base:Extend("BP_NPCAppear_C")

function BP_NPCAppear_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
end

function BP_NPCAppear_C:Init()
  Base.Init(self)
  self.bEmptyNPC = true
end

function BP_NPCAppear_C:LuaBeginPlay()
  Base.LuaBeginPlay(self)
end

function BP_NPCAppear_C:LoadLockEffect()
end

function BP_NPCAppear_C:PlayUnlockEffect(lockNum)
end

function BP_NPCAppear_C:OnFrameLoad(distanceRatio)
  if self.HeadWidget then
    self:InitWidgetComponent(self.HeadWidget)
    local HeadWidget = self.HeadWidget
    local config = self.sceneCharacter and self.sceneCharacter.config
    local icon_height = config and config.icon_height or 0
    if 0 ~= icon_height then
      HeadWidget:K2_SetRelativeLocation(UE4.FVector(0, 0, icon_height), false, nil, false)
    end
  end
  self:TryFixArtFurniture()
  Base.OnFrameLoad(self, distanceRatio)
end

function BP_NPCAppear_C:TryFixArtFurniture()
  local SceneNpc = self.sceneCharacter
  if SceneNpc then
    if not SceneNpc:IsViewArtFurniture() then
      return
    end
    local HomeDataComp = SceneNpc:GetComponent(HomeNpcInfoComponent)
    if HomeDataComp then
      local HomeActor = HomeDataComp:GetFurnitureActor()
      if HomeActor then
        local ForwardVec = HomeActor:GetActorUpVector()
        local CurrentPos = self:Abs_K2_GetActorLocation()
        self:Abs_K2_SetActorLocation_WithoutHit(CurrentPos + ForwardVec * 20, false, false)
        Log.Debug("fix art furniture pos!")
      end
    end
  end
end

return BP_NPCAppear_C
