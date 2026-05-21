local MusicCollectionUtils = require("NewRoco.Modules.System.MusicCollection.MusicCollectionUtils")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local UMG_Pass_Accomplish_C = _G.NRCPanelBase:Extend("UMG_Pass_Accomplish_C")

function UMG_Pass_Accomplish_C:OnActive(tips, parent)
  self.parent = parent
  self.CurTips = tips
  self.taskConf = _G.DataConfigManager:GetTaskConf(self.CurTips.tipData.id)
  self:SetThemeRes()
  local taskName = self.taskConf.name
  self.Title:SetText(taskName)
  self:PlayAnimation(self.In)
  self.CanvasPanel_22:SetVisibility(UE4.ESlateVisibility.Visible)
  self:DelaySeconds(5, function()
    self:PlayAnimation(self.Out)
  end)
end

function UMG_Pass_Accomplish_C:OnDeactive()
end

function UMG_Pass_Accomplish_C:OnDestruct()
  self:CancelDelay()
end

function UMG_Pass_Accomplish_C:OnAddEventListener()
  self:AddButtonListener(self.Button_57, self.OnClickButton_57)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_Accomplish_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_Pass_Accomplish_C:SetThemeRes()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_Accomplish", self)
end

function UMG_Pass_Accomplish_C:OnConstruct()
  self:OnAddEventListener()
  self:PCKeySetting()
end

function UMG_Pass_Accomplish_C:OnDestruct()
end

function UMG_Pass_Accomplish_C:PCKeySetting()
  if SystemSettingModuleCmd then
    local InputAction = string.format("IA_MessageDetails")
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, InputAction)
    if "" ~= image then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
    self.PCKey:SetKeyVisibility(true)
  end
end

function UMG_Pass_Accomplish_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self.parent:TipsNext()
  end
end

function UMG_Pass_Accomplish_C:OnClickButton_57()
  local taskId = self.taskConf.id
  MusicCollectionUtils.GetBgmStateGroupByApplyType(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
  _G.NRCModeManager:DoCmd(_G.BattlePassModuleCmd.OpenPassAwardMainPanel, taskId)
  self.CanvasPanel_22:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:PlayAnimation(self.Out)
end

return UMG_Pass_Accomplish_C
