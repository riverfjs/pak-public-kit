local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PromptList_C = Base:Extend("UMG_PromptList_C")

function UMG_PromptList_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_PromptList_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_PromptList_C:OnAddEventListener()
  self:AddButtonListener(self.ClickBtn, self.OnTransBtnClicked)
end

function UMG_PromptList_C:OnRemoveEventListener()
end

function UMG_PromptList_C:OnTransBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PromptList_C:OnTransBtnClicked")
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SetMapCenterByNPC, self.uiData.refreshId, 0.5, nil, nil, SceneUtils.GetSceneResId())
end

function UMG_PromptList_C:OnItemUpdate(_data, datalist, index)
  if _data and _data.redDotKey and 0 ~= _data.redDotKey then
    self.RedDot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RedDot:SetupKey(_data.redDotKey)
  else
    self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.uiData = _data
  self.Text:SetText(_data.title)
  if _data.icon and self.Icon then
    self.Icon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Icon:SetPath(_data.icon)
  end
  if index == #datalist then
    self.Line:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_PromptList_C:OnItemSelected(_bSelected)
  if _bSelected then
  end
end

function UMG_PromptList_C:OnDeactive()
end

return UMG_PromptList_C
