local Base = require("NewRoco/Modules/System/LoadingUIModule/Res/UMG_FastLoadingUI_Base_C")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local UMG_FastLoadingUI_Protagonist_C = Base:Extend("UMG_FastLoadingUI_Protagonist_C")

function UMG_FastLoadingUI_Protagonist_C:Ctor()
  Base.Ctor(self)
end

function UMG_FastLoadingUI_Protagonist_C:OnDestruct()
  self:Log("[OnDestruct]")
  Base.OnDestruct(self)
end

function UMG_FastLoadingUI_Protagonist_C:OnActive(content, tips, switch_reason, teleport_id)
  Base.OnActive(self, content, tips, switch_reason, teleport_id)
  self.OutDuration = self.FadeOut and self.FadeOut:GetEndTime() - self.FadeOut:GetStartTime() or 0.5
  self:SetData(content, tips, switch_reason, teleport_id)
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_FastLoadingUI_Protagonist_C:OnDeactive()
  Base.OnDeactive(self)
end

function UMG_FastLoadingUI_Protagonist_C:OnEnable()
  Base.OnEnable(self)
  UE4Helper.SetDesiredShowCursor(true, "UMG_FastLoadingUI_Protagonist_C")
  ScenePlayerInputManager.Pause()
  self:StopAllAnimations()
  self:PlayAnimation(self.FadeIn)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1258, "UMG_FastLoadingUI_Protagonist_C:OnEnable")
  local bIsBlockPCInput = true
  _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_OPENED, bIsBlockPCInput)
  self:ShowBackGround(_G.GlobalConfig.SetFastLoadingWorldRendering == false)
  local bIsMale = _G.DataModelMgr.PlayerDataModel:IsMale()
  self:PlayAnimation(bIsMale and self.Loading_Nan or self.Loading_Nv, 0, 9999)
end

function UMG_FastLoadingUI_Protagonist_C:OnDisable()
  Base.OnDisable(self)
  UE4Helper.ReleaseDesiredShowCursor("UMG_FastLoadingUI_Protagonist_C")
  ScenePlayerInputManager.Resume()
  local bIsBlockPCInput = false
  _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_CLOSED, bIsBlockPCInput)
  _G.GlobalConfig.SetFastLoadingWorldRendering = false
end

function UMG_FastLoadingUI_Protagonist_C:OnViewTick(deltaTime)
  Base.OnViewTick(self, deltaTime)
  local curProcess = self.panel.curProcess
  if self.enableView and not self.FxPlayed and 100 == curProcess then
    self.FxPlayed = true
    self.FxFinished = true
    self:Log("[OnViewTick] curProcess == 100")
    _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_PRECLOSED)
  end
end

function UMG_FastLoadingUI_Protagonist_C:SetData(content, tips, switch_reason, teleport_id)
  Base.SetData(self, content, tips, switch_reason, teleport_id)
  self:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_FastLoadingUI_Protagonist_C:ShowBackGround(bShow)
  if bShow then
    self.Bg:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Bg:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_FastLoadingUI_Protagonist_C:OnAnimationFinished(anim)
  self:Log("OnAnimationFinished ", UE.UObject.GetName(anim))
  if anim == self.FadeIn and self.panel.IsClosing == false and false == _G.GlobalConfig.SetFastLoadingWorldRendering then
    UE4Helper.SetEnableWorldRendering(false)
  end
end

function UMG_FastLoadingUI_Protagonist_C:PlayOutAnimation()
  self:Log("[PlayOutAnimation]")
  self:PlayAnimation(self.FadeOut)
end

function UMG_FastLoadingUI_Protagonist_C:StopOutAnimation()
  self:Log("[StopOutAnimation]")
  self:StopAnimation(self.FadeOut)
end

function UMG_FastLoadingUI_Protagonist_C:StopInAnimation()
  self:Log("[StopInAnimation]")
  self:StopAnimation(self.FadeIn)
end

return UMG_FastLoadingUI_Protagonist_C
