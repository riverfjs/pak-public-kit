local Base = require("NewRoco/Modules/System/LoadingUIModule/Res/UMG_FastLoadingUI_Base_C")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local UMG_LoadingPanel_MagicAcademy_C = Base:Extend("UMG_LoadingPanel_MagicAcademy_C")

function UMG_LoadingPanel_MagicAcademy_C:Ctor()
  Base.Ctor(self)
  self.bOutAnimationPlayed = false
end

function UMG_LoadingPanel_MagicAcademy_C:OnDestruct()
  self:Log("[OnDestruct]")
  Base.OnDestruct(self)
end

function UMG_LoadingPanel_MagicAcademy_C:OnActive(content, tips, switch_reason, teleport_id)
  Base.OnActive(self, content, tips, switch_reason, teleport_id)
  self:SetData(content, tips, switch_reason, teleport_id)
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_LoadingPanel_MagicAcademy_C:OnDeactive()
  Base.OnDeactive(self)
end

function UMG_LoadingPanel_MagicAcademy_C:OnEnable()
  Base.OnEnable(self)
  self.bOutAnimationPlayed = false
  UE4Helper.SetDesiredShowCursor(true, "UMG_LoadingPanel_MagicAcademy_C")
  ScenePlayerInputManager.Pause()
  self:StopAllAnimations()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1258, "UMG_LoadingPanel_MagicAcademy_C:OnEnable")
  local bIsBlockPCInput = true
  _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_OPENED, bIsBlockPCInput)
  self:ShowBackGround(false == _G.GlobalConfig.SetFastLoadingWorldRendering)
  self:PlayAnimation(self.Loop)
  if false == _G.GlobalConfig.SetFastLoadingWorldRendering then
    UE4Helper.SetEnableWorldRendering(false)
  end
end

function UMG_LoadingPanel_MagicAcademy_C:OnDisable()
  Base.OnDisable(self)
  UE4Helper.ReleaseDesiredShowCursor("UMG_LoadingPanel_MagicAcademy_C")
  ScenePlayerInputManager.Resume()
  local bIsBlockPCInput = false
  _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_CLOSED, bIsBlockPCInput)
  _G.GlobalConfig.SetFastLoadingWorldRendering = false
end

function UMG_LoadingPanel_MagicAcademy_C:OnViewTick(deltaTime)
  Base.OnViewTick(self, deltaTime)
  local curProcess = self.panel.curProcess
  if self.enableView then
    if not self.FxPlayed and 100 == curProcess then
      self.FxPlayed = true
      self:Log("[OnViewTick] curProcess == 100")
      self:PlayAnimation(self.Out)
    elseif curProcess < 50 and self.FxPlayed then
      self.FxPlayed = false
      self:PlayAnimation(self.Out, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 100, false)
    end
    if self.LoadingProgress then
      self.LoadingProgress:SetPercent(curProcess / 100.0)
    end
  end
end

function UMG_LoadingPanel_MagicAcademy_C:SetData(content, tips, switch_reason, teleport_id, teleport_rule_id)
  Base.SetData(self, content, tips, switch_reason, teleport_id, teleport_rule_id)
end

function UMG_LoadingPanel_MagicAcademy_C:ShowBackGround(bShow)
  if bShow then
    self.CanvasPanel_58:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.CanvasPanel_58:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_LoadingPanel_MagicAcademy_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self.FxFinished = true
    self.bOutAnimationPlayed = true
    _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_PRECLOSED)
  end
end

function UMG_LoadingPanel_MagicAcademy_C:PlayOutAnimation()
  self:Log("[PlayOutAnimation]")
end

function UMG_LoadingPanel_MagicAcademy_C:StopOutAnimation()
  self:Log("[StopOutAnimation]")
end

function UMG_LoadingPanel_MagicAcademy_C:StopInAnimation()
  self:Log("[StopInAnimation]")
end

function UMG_LoadingPanel_MagicAcademy_C:SetHeadLineText(headLineText)
  if self.TwoPeople then
    if headLineText then
      self.TwoPeople:SetText(headLineText or "")
      self.TwoPeople:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.TwoPeople:SetText("")
      self.TwoPeople:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

return UMG_LoadingPanel_MagicAcademy_C
