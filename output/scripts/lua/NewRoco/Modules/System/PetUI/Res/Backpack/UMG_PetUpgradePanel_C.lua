local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetUpgradePanel_C = _G.NRCPanelBase:Extend("UMG_PetUpgradePanel_C")

function UMG_PetUpgradePanel_C:OnConstruct()
  _G.PetUIModuleCmd = require("NewRoco.Modules.System.PetUI.PetUIModuleCmd")
  self:PlayAnimation(self.Appear_new)
  self.Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/btn_jineng_png.btn_jineng_png'"
  self.Icon1 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Having/Frames/img_suo_png.img_suo_png'"
  self.name = LuaText.umg_petupgradepanel_1
  _G.NRCEventCenter:RegisterEvent("UMG_PetUpgradePanel_C", self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnApplicationActive)
end

function UMG_PetUpgradePanel_C:OnDestruct()
  self:CancelDelay()
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnApplicationActive)
end

function UMG_PetUpgradePanel_C:OnActive(before_data, _data, _petInfoMainCtrl, beforelevel)
  Log.Debug("UMG_PetUpgradePanel_C:OnActive")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002022, "UMG_PetUpgradePanel_C:OnActive")
  local PetbeforeInfo = before_data
  self.beforelevel = beforelevel
  self.uiData = _data
  self.LearnSkillNum = 0
  self.petInfoMainCtrl = _petInfoMainCtrl
  self.btnCloseRenamePanel:SetIsEnabled(false)
  self.AcquireNewSkills:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:UpdategradePanelInfo(PetbeforeInfo)
  self:SetBaseInfo()
  self:OnAddEventListener()
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule:HasPanel("PetLevelUp") then
    local panel = PetUIModule:GetPanel("PetLevelUp")
    panel:DoClose()
  end
end

function UMG_PetUpgradePanel_C:OnApplicationActive()
  if self.SkillList then
    self.SkillList:SetRenderOpacity(1)
  end
end

function UMG_PetUpgradePanel_C:SetBaseInfo()
  if not self.uiData or not self.uiData.petInfo then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    return
  end
  if self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.PetExp then
    self.NRCSwitcher_2:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_2:SetActiveWidgetIndex(1)
    self.PetEffortImg:SetPath(self.Petproperty[1].icon)
  end
end

function UMG_PetUpgradePanel_C:UpdategradePanelInfo(petbeforeinfo)
  local petdata = self.uiData.PetData
  if not petdata or not self.uiData.petInfo then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    return
  end
  self.NRC_Subtitle_1:SetText(self.uiData.petInfo.curLevel)
  if self.beforelevel then
    self.NRC_Subtitle_2:SetText(self.beforelevel)
  end
  self.Petproperty = {}
  for i = 1, 6 do
    local attribute = _G.DataConfigManager:GetAttributeConf(i)
    if self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.PetExp then
      table.insert(self.Petproperty, {
        icon = attribute.attribute_icon,
        attributevalue = attribute.attribute_name,
        petbeforeproperty = PetUtils.GetPetAdditionalByType(petbeforeinfo, i),
        petlaterproperty = PetUtils.GetPetAdditionalByType(petdata, i)
      })
    elseif attribute.attribute == self.uiData.petInfo.AttributeType then
      table.insert(self.Petproperty, {
        icon = attribute.attribute_icon,
        attributevalue = attribute.attribute_name,
        petbeforeproperty = PetUtils.GetPetAdditionalByType(petbeforeinfo, i),
        petlaterproperty = PetUtils.GetPetAdditionalByType(petdata, i)
      })
    end
  end
  if self.Petproperty and #self.Petproperty > 0 then
    self.NRCGridView_45:InitGridView(self.Petproperty)
  end
  self.newSkillList = {}
  for i, petDataSkill in ipairs(petdata.skill.skill_data) do
    if petDataSkill and petbeforeinfo and petDataSkill.is_learned and petbeforeinfo.skill and petbeforeinfo.skill.skill_data and petbeforeinfo.skill.skill_data[i] and petbeforeinfo.skill.skill_data[i].is_learned == false then
      self.LearnSkillNum = self.LearnSkillNum + 1
      table.insert(self.newSkillList, {
        skillID = petDataSkill.id,
        unlockLv = petDataSkill.unlock_need_lv
      })
    end
  end
  if self.LearnSkillNum > 0 then
    table.sort(self.newSkillList, function(a, b)
      return a.unlockLv < b.unlockLv
    end)
    self.AcquireNewSkills:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SkillList:InitGridView(self.newSkillList)
  end
  if self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.PetExp then
    self.NRCSwitcher_139:SetActiveWidgetIndex(0)
    self.NRCSwitcher_60:SetActiveWidgetIndex(0)
  else
    if self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.HpExp then
      self.AddExpType:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Evolution/Frames/img_PetEffortIcon_png.img_PetEffortIcon_png'")
    elseif self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.AtkExp then
      self.AddExpType:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Evolution/Frames/img_PetAtkIcon_png.img_PetAtkIcon_png'")
    elseif self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.SpAtkExp then
      self.AddExpType:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Evolution/Frames/img_PetMagIcon_png.img_PetMagIcon_png'")
    elseif self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.DefExp then
      self.AddExpType:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Evolution/Frames/img_PetDefIcon_png.img_PetDefIcon_png'")
    elseif self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.SpDefExp then
      self.AddExpType:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Evolution/Frames/img_PetMdefIcon_png.img_PetMdefIcon_png'")
    elseif self.uiData.petInfo.AddExpType == PetUIModuleEnum.AddExpType.SpeedExp then
      self.AddExpType:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Evolution/Frames/img_PetSpdIcon_png.img_PetSpdIcon_png'")
    end
    self.NRCSwitcher_139:SetActiveWidgetIndex(1)
    self.NRCSwitcher_60:SetActiveWidgetIndex(1)
    local Text = string.format("%s%s", self.uiData.petInfo.LevelName, LuaText.umg_petupgradepanel_2)
    self.NRCTitle_1:SetText(Text)
    Text = self.uiData.petInfo.LevelName
    self.NRC_Subtitle:SetText(Text)
  end
  self:SetNumber()
  self:SetUpgradeTime()
end

function UMG_PetUpgradePanel_C:SetNumber()
  local petdata = self.uiData.PetData
  local petHandbook = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_HANDBOOK):GetAllDatas()
  for k, HandbookConf in pairs(petHandbook) do
    if HandbookConf.name == petdata.name then
      local PetIdList = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnGetHandbookPetIds, HandbookConf.id)
      for i = 1, #PetIdList do
        if petdata.base_conf_id == PetIdList[i] then
          local NumberInfo = string.format("%03d", HandbookConf.id)
          self.NRCText_50:SetText(NumberInfo)
          return
        end
      end
    end
  end
end

function UMG_PetUpgradePanel_C:SetUpgradeTime()
  local nowTimePoke = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  local ban_time = os.date("%Y.%m.%d", nowTimePoke)
  self.NRCText_96:SetText(ban_time)
end

function UMG_PetUpgradePanel_C:OnDeactive()
end

function UMG_PetUpgradePanel_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseRenamePanel, self.OnCloseButtonClicked)
  self:RegisterEvent(self, PetUIModuleEvent.CloseUpGradePanel, self.OnCloseUpGradePanel)
end

function UMG_PetUpgradePanel_C:OnCloseButtonClicked()
  self:PlayAnimation(self.Disappear)
  self:DispatchEvent(PetUIModuleEvent.IsCloseMask, true)
  self.btnCloseRenamePanel:SetIsEnabled(false)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002022, "UMG_PetUpgradePanel_C:OnbtnCloseRenamePanel")
end

function UMG_PetUpgradePanel_C:OnCloseUpGradePanel()
  self:PlayAnimation(self.Disappear)
end

function UMG_PetUpgradePanel_C:OnAnimationFinished(Animation)
  if not self then
    return
  end
  if Animation == self.Appear_new then
    if self.LearnSkillNum and self.LearnSkillNum > 0 then
      self:DelaySeconds(1.18, function()
        self.btnCloseRenamePanel:SetIsEnabled(true)
      end)
    else
      self.btnCloseRenamePanel:SetIsEnabled(true)
    end
  end
  if Animation == self.Disappear then
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.PET_UI_UPDATECURSTATE)
    local petLevel
    if self.uiData and self.uiData.PetData and self.uiData.PetData.level then
      petLevel = self.uiData.PetData.level
    end
    local petMax = _G.DataConfigManager:GetPetGlobalConfig("pet_level_toplimit").num
    local Close = false
    if petLevel and petLevel >= petMax then
      Close = true
    end
    NRCModuleManager:DoCmd(PetUIModuleCmd.ShowPetLevelUp, Close)
    self:DoClose()
  end
end

return UMG_PetUpgradePanel_C
