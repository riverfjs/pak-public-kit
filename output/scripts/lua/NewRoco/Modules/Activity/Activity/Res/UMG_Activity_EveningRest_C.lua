local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_EveningRest_C = Base:Extend("UMG_Activity_EveningRest_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco/Modules/System/Activity/ActivityModuleEvent")

function UMG_Activity_EveningRest_C:BindUIElements()
  local uiElements = {}
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.bgImage = self.BG
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_EveningRest_C:OnConstruct()
  Base.OnConstruct(self)
  local _activityInst = self.activityInst
  local mix_conf = _activityInst:GetMixCfg()
  local drop_base_id = _G.DataConfigManager:GetActivityConf(mix_conf.slot_group[1].param).base_id[1]
  local dropConf = _G.DataConfigManager:GetActivityDropConf(drop_base_id)
  self.dayLimit = dropConf.day_got_limit
  local path = ActivityUtils.GetItemIconAndQuality(dropConf.goods_type, dropConf.goods_id)
  self.TextDesc:SetText(dropConf.drop_num_tips)
  self.Icon:SetPath(path)
  self:SetProcess()
  local option_ids = {}
  for i = 2, #mix_conf.slot_group do
    table.insert(option_ids, mix_conf.slot_group[i].option_id)
  end
  local option_conf = _G.DataConfigManager:GetActivityOptionConf(option_ids[1])
  self.LocalMap_1:SetPath(option_conf.image_path)
  self.PlaceName_1:SetText(option_conf.option_param1)
  if option_ids[2] then
    option_conf = _G.DataConfigManager:GetActivityOptionConf(option_ids[2])
    self.LocalMap:SetPath(option_conf.image_path)
    self.PlaceName:SetText(option_conf.option_param1)
  else
    self.BtnActivityEntrance:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:RegisterEvent(self, ActivityModuleEvent.OnBaseMixActivityExpired, function()
    self.Text_TimeRemaining:SetText(_G.LuaText.activity_expired_show_tip)
  end)
  self.Text_TimeRemaining:SetText(_G.LuaText.activity_eveningrelax_time_show)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshActivityDropData, self.SetProcess)
  self:AddButtonListener(self.BtnActivityEntrance_1, self.GotoMap1)
  self:AddButtonListener(self.BtnActivityEntrance, self.GotoMap2)
end

function UMG_Activity_EveningRest_C:SetProcess()
  local getNum = self.activityInst:DoOperate(1)
  self.Quantity:SetText(string.format(_G.LuaText.Activity_PlayerCoCreation_task, getNum, self.dayLimit))
end

function UMG_Activity_EveningRest_C:GotoMap1()
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_Activity_EveningRest_C:GotoMap1")
  if self.activityInst:IsInProgress() then
    self.activityInst:DoOperate(2, true)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
  end
  self:PlayAnimation(self.Select_2)
end

function UMG_Activity_EveningRest_C:GotoMap2()
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_Activity_EveningRest_C:GotoMap2")
  if self.activityInst:IsInProgress() then
    self.activityInst:DoOperate(3, true)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
  end
  self:PlayAnimation(self.Select_1)
end

function UMG_Activity_EveningRest_C:OnDestruct()
  Base.OnDestruct(self)
  self:UnRegisterEvent(self, ActivityModuleEvent.OnBaseMixActivityExpired)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshActivityDropData)
  self:RemoveButtonListener(self.BtnActivityEntrance_1)
  self:RemoveButtonListener(self.BtnActivityEntrance)
end

return UMG_Activity_EveningRest_C
