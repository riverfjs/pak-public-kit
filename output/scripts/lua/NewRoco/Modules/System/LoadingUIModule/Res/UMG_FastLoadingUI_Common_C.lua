local Base = require("NewRoco.Modules.System.LoadingUIModule.Res.UMG_FastLoadingUI_Base_C")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local UMG_FastLoadingUI_Common_C = Base:Extend("UMG_FastLoadingUI_Common_C")

function UMG_FastLoadingUI_Common_C:Ctor()
  Base.Ctor(self)
  if self.JinduProgressBar then
    self.JinduProgressBar:SetPercent(0)
  end
end

function UMG_FastLoadingUI_Common_C:OnDestruct()
  Base.OnDestruct(self)
end

function UMG_FastLoadingUI_Common_C:OnActive(content, tips, switch_reason, teleport_id)
  Base.OnActive(self, content, tips, switch_reason, teleport_id)
  if self.JinduProgressBar then
    self.JinduProgressBar:SetPercent(0)
  end
end

function UMG_FastLoadingUI_Common_C:OnDeactive()
  Base.OnDeactive(self)
end

function UMG_FastLoadingUI_Common_C:OnEnable()
  Base.OnEnable(self)
  local bIsMale = _G.DataModelMgr.PlayerDataModel:IsMale()
  if bIsMale then
    self.nanzhu_all:SetRenderOpacity(1)
    self.nvzhu_all:SetRenderOpacity(0)
  else
    self.nanzhu_all:SetRenderOpacity(0)
    self.nvzhu_all:SetRenderOpacity(1)
  end
  self:StopAllAnimations()
  self:PlayAnimation(self.In)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1258, "UMG_FastLoadingUI_Common_C:OnEnable")
  if not SceneUtils.debugClosePIELoading then
    self:PlayAnimation(self.Loop, 0, 99999)
  end
end

function UMG_FastLoadingUI_Common_C:OnDisable()
  Base.OnDisable(self)
  self:ClearFX()
end

function UMG_FastLoadingUI_Common_C:OnViewTick(deltaTime)
  Base.OnViewTick(self, deltaTime)
  local curProcess = self.panel.curProcess
  if self.enableView then
    if self.ProcessText then
      self.ProcessText:SetText(math.floor(curProcess) .. "%")
    end
    self.JinduProgressBar:SetPercent(curProcess / 100)
    if not self.FxPlayed and 100 == curProcess then
      self:Log("Start Playing Animation Loading")
      self.FxPlayed = true
      self:PlayAnimation(self.Loading, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1, false)
      self:DelaySeconds(0.233, function(this)
        this:ResetNiagaraInNewWorld()
      end, self)
    elseif curProcess < 50 and self.FxPlayed then
      self.FxPlayed = false
      self.FxFinished = false
      self:PlayAnimation(self.Loading, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 100, false)
    end
  end
end

function UMG_FastLoadingUI_Common_C:SetData(content, tips, switch_reason, teleport_id, teleport_rule_id)
  Base.SetData(self, content, tips, switch_reason, teleport_id, teleport_rule_id)
  self.teleportId = teleport_id
  if nil ~= tips then
    self.TipsText:SetText(tips)
  end
  if nil ~= content then
    self.ContentText:SetText(content)
  end
end

function UMG_FastLoadingUI_Common_C:SetHeadLineText(headLineText)
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

function UMG_FastLoadingUI_Common_C:ShowBackGround(bShow)
  if bShow or self.NeedForceShow then
    if self.NeedForceShow then
      self.NeedForceShow = false
    end
    self.content:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Image_65:SetVisibility(UE4.ESlateVisibility.Visible)
    self.LoadingAnimation:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.content:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Image_65:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.LoadingAnimation:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_FastLoadingUI_Common_C:OnAnimationFinished(anima)
  self:Log("OnAnimationFinished", self.panel.IsClosing, UE.UObject.GetName(anima), UE.UObject.GetName(self.In), UE.UObject.GetName(self.Out))
  if anima == self.In and self.panel.IsClosing == false then
    if false == _G.GlobalConfig.SetFastLoadingWorldRendering then
      UE4Helper.SetEnableWorldRendering(false, false, "UMG_FastLoading_C")
    end
  elseif anima == self.Loading then
    self.FxFinished = true
    _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_PRECLOSED)
  elseif anima == self.Out then
    self.IsSetTipsData = false
    self:PlayAnimation(self.Loading, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1000, false)
  end
end

function UMG_FastLoadingUI_Common_C:PlayOutAnimation()
  self:PlayAnimation(self.Out)
end

function UMG_FastLoadingUI_Common_C:StopOutAnimation()
  self:StopAnimation(self.Out)
end

function UMG_FastLoadingUI_Common_C:StopInAnimation()
  self:StopAnimation(self.In)
end

return UMG_FastLoadingUI_Common_C
