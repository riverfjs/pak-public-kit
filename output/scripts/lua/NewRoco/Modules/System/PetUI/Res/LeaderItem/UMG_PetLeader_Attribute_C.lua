local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UMG_PetLeader_Attribute_C = _G.NRCPanelBase:Extend("UMG_PetLeader_Attribute_C")

function UMG_PetLeader_Attribute_C:OnConstruct()
  self.data = self.module:GetData("PetUIModuleData")
  self.LeaderPet = nil
  self:OnAddEventListener()
end

function UMG_PetLeader_Attribute_C:OnDestruct()
end

function UMG_PetLeader_Attribute_C:OnActive()
  local SelectLeaderItem = self.data:GetSelectLeaderItem()
  local LeaderPetList = self.data:GetLeaderPetList()
  if SelectLeaderItem then
    self.LeaderPet = LeaderPetList[SelectLeaderItem.BagItemConf.id]
    local AllLeaderBeforePetConfigMap = self.data:GetAllLeaderBeforePetConfigMap()
    if self.LeaderPet and self.LeaderPet[1] and self.LeaderPet[1].id then
      self.LeadBeforePetConfigList = AllLeaderBeforePetConfigMap[self.LeaderPet[1].id]
      self:SetPanelInfo()
    end
  end
  self:PlayAnimation(self.Open_0)
end

function UMG_PetLeader_Attribute_C:OnDeactive()
end

function UMG_PetLeader_Attribute_C:OnAddEventListener()
  self:AddButtonListener(self.SwitchButton, self.OnSwitchButton)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnBtnClose)
  self:AddButtonListener(self.BtnRechristen, self.OnBtnRechristen)
  self:AddButtonListener(self.UMG_Details.btnLevelUp, self.OnOpenPetInfoPanel)
  self:RegisterEvent(self, PetUIModuleEvent.SelectLeaderItemEvent, self.SetRightPanelInfo)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetSkillChange, self.OnPetSkillChange)
end

function UMG_PetLeader_Attribute_C:OnAnimationFinished(Anim)
  if Anim == self.Close_0 then
    self:ClosePanel()
  end
end

function UMG_PetLeader_Attribute_C:SetRightPanelInfo(ItemInfo)
  local LeaderPetList = self.data:GetLeaderPetList()
  self.LeaderPet = LeaderPetList[ItemInfo.BagItemConf.id]
  local AllLeaderBeforePetConfigList = self.data:GetAllLeaderBeforePetConfigMap()
  self.LeadBeforePetConfigList = AllLeaderBeforePetConfigList[self.LeaderPet[1].id]
  self:SetPanelInfo()
end

function UMG_PetLeader_Attribute_C:OnPetSkillChange(IsPlayPetSkill)
  if IsPlayPetSkill then
    self.SwitchButton:SetIsEnabled(false)
  else
    self.SwitchButton:SetIsEnabled(true)
  end
end

function UMG_PetLeader_Attribute_C:SetPanelInfo()
  self.PetName:SetText(self.LeaderPet[1].name)
  self:updatePetTypeIcon(self.LeaderPet[1].unit_type)
  local ShowList = self:SortLeadBeforePetConfigList()
  self.List:InitList(ShowList)
  self.List.Slot:SetAutoSize(true)
end

function UMG_PetLeader_Attribute_C:SortLeadBeforePetConfigList()
  if not self.LeadBeforePetConfigList then
    Log.Error("UMG_PetLeader_Attribute_C:SortLeadBeforePetConfigList LeadBeforePetConfigList is nil")
  end
  local FinalList = {}
  local SplitPetConfigList = self:SplitArrayBy4(self.LeadBeforePetConfigList)
  for _, PetConfigGroup in ipairs(SplitPetConfigList or {}) do
    if PetConfigGroup then
      table.sort(PetConfigGroup, function(a, b)
        if a.pet_evolution_id ~= nil and b.pet_evolution_id ~= nil and a.pet_evolution_id[1] ~= nil and b.pet_evolution_id[1] ~= nil then
          return a.pet_evolution_id[1] > b.pet_evolution_id[1]
        end
        return false
      end)
      for i, v in pairs(PetConfigGroup) do
        table.insert(FinalList, v)
      end
    end
  end
  return FinalList
end

function UMG_PetLeader_Attribute_C:SplitArrayBy4(Arr)
  local Result = {}
  local Group = {}
  for i = 1, #Arr do
    table.insert(Group, Arr[i])
    if 4 == #Group then
      table.insert(Result, Group)
      Group = {}
    end
  end
  if #Group > 0 then
    table.insert(Result, Group)
  end
  return Result
end

function UMG_PetLeader_Attribute_C:updatePetTypeIcon(_dicTypes)
  local typeList = {}
  local BloodTypeList = {}
  for i, Type in ipairs(_dicTypes) do
    table.insert(typeList, Type)
  end
  self.Attr1:InitGridView(typeList)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(Enum.PetBloodType.PBT_BOSS)
  if PetBloodConf then
    table.insert(BloodTypeList, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
  end
  self.Attr:InitGridView(BloodTypeList)
end

function UMG_PetLeader_Attribute_C:OnBtnRechristen()
  local petData = {}
  petData.base_conf_id = self.LeaderPet[1].id
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, {petData = petData}, _G.Enum.GoodsType.GT_PET)
end

function UMG_PetLeader_Attribute_C:OnOpenPetInfoPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_ChallengeItem_C:OnOpenPetInfoPanel")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, self.LeaderPet[1].id, true)
end

function UMG_PetLeader_Attribute_C:OnSwitchButton()
  self:DispatchEvent(PetUIModuleEvent.ShowOrHideLeaderRight, true)
  self:DoClose()
end

function UMG_PetLeader_Attribute_C:OnBtnClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Leader_Item_C:OnSwitchButton")
  self.module:ClosePetLeaderAttribute()
  self:PlayAnimation(self.Close_0)
end

function UMG_PetLeader_Attribute_C:ClosePanel()
  self:DoClose()
end

return UMG_PetLeader_Attribute_C
