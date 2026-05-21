local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_FreeCaptivePet_C = _G.NRCPanelBase:Extend("UMG_FreeCaptivePet_C")

function UMG_FreeCaptivePet_C:OnConstruct()
  self.UMG_Btn1:SetBtnText(LuaText.umg_petfreecaptiveanimals_1)
  self.UMG_Btn2:SetBtnText(LuaText.umg_petfreecaptiveanimals_2)
  self:OnAddEventListener()
end

function UMG_FreeCaptivePet_C:OnActive(_data)
  self:PlayAnimation(self.appeat)
  self.uiData = {}
  self.uiData.petList = _data
  self.uiData.gid = {}
  self.uiData.PetFreeAward = {}
  self.uiData.UnlockedHabitItemNum = {}
  self:SetUpList()
  self:SetBelowList()
  self:UpdateList()
end

function UMG_FreeCaptivePet_C:SetUpList()
  local PetFreeList = {}
  local petData = self.uiData.petList
  local gid = {}
  for i, _petData in ipairs(petData) do
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.base_conf_id)
    self.NameText:SetText(_petData.name)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      table.insert(gid, _petData.gid)
      table.insert(PetFreeList, {
        IconListInfo = _petData.level,
        gid = _petData.gid,
        PetIcon = modelConf,
        IsTeamPet = false,
        PetBasicProperty = petBaseConf.quality
      })
    end
  end
  self.uiData.gid = gid
  self.uiData.PetFreeInfo = PetFreeList
  self.UpList:InitList(PetFreeList)
  local LocalizationConf = _G.DataConfigManager:GetLocalizationConf("pet_remove_text")
  local MainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule and MainUIModule:HasPanel("GameInfoMain") then
    self.Hint_1:SetText(LocalizationConf.msg)
    self.Switcher_Bg:SetActiveWidgetIndex(0)
  else
    self.Hint_3:SetText(LocalizationConf.msg)
    self.Switcher_Bg:SetActiveWidgetIndex(1)
  end
end

function UMG_FreeCaptivePet_C:SetBelowList()
  local petData = self.uiData.petList
  self:GetMaxHabitReward()
  for i, _petData in ipairs(petData) do
    self:GetBaseInfoReward(_petData)
    self:GetCarryonBagItemList(_petData)
    self:GetTalentRankAward(_petData)
    self:GetHabitReward(_petData)
  end
end

function UMG_FreeCaptivePet_C:GetBaseInfoReward(_PetData)
  local itemCfg, itemCount
  local _petData = _PetData
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.catch_base_id)
  if petBaseConf then
    local abilities = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PETFREE_CONF):GetAllDatas()
    local PetGrowLevel, GrowOrder = PetUtils.GetPetGrowLevel(_petData)
    if PetGrowLevel >= 999 then
      GrowOrder = 6
    end
    local reward = self:GetReward(abilities, petBaseConf.petfree_sort, _petData.level, GrowOrder - 1)
    local RewardConf = _G.DataConfigManager:GetRewardConf(reward)
    if RewardConf then
      for j, rewardConf in ipairs(RewardConf.RewardItem) do
        local IshasItem = false
        for n, freeaware in ipairs(self.uiData.PetFreeAward) do
          if freeaware.Id == rewardConf.Id then
            freeaware.Count = freeaware.Count + rewardConf.Count
            IshasItem = true
            break
          end
        end
        if false == IshasItem then
          table.insert(self.uiData.PetFreeAward, {
            Count = rewardConf.Count,
            Id = rewardConf.Id
          })
        end
      end
    end
    local BreakNumberAllConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_NUMBER_CONF):GetAllDatas()
    if petBaseConf and GrowOrder - 1 >= 1 and GrowOrder - 1 <= #BreakNumberAllConf then
      local breakItemConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_ITEM_CONF):GetAllDatas()
      local BreakNumberConf = _G.DataConfigManager:GetBreakNumberConf(GrowOrder - 1)
      petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.base_conf_id)
      local UnitType = petBaseConf.unit_type
      for z, v in ipairs(UnitType) do
        if UnitType[z] then
          local ConsumeNum = BreakNumberConf.free_type_item_number
          for j, k in ipairs(breakItemConf) do
            if v == k.unit_type and GrowOrder - 1 == k.break_level then
              if #UnitType > 1 then
                ConsumeNum = ConsumeNum // #UnitType
              end
              if ConsumeNum > 0 then
                itemCfg = k.break_type_item > 1 and _G.DataConfigManager:GetBagItemConf(k.break_type_item) or nil
                itemCount = PetUtils.getItemCount(k.break_type_item)
                table.insert(self.uiData.PetFreeAward, {
                  Count = ConsumeNum,
                  Id = itemCfg.id
                })
              end
            end
          end
        end
      end
    end
  end
end

function UMG_FreeCaptivePet_C:GetCarryonBagItemList(_PetData)
  local _petData = _PetData
  local bagitems = {}
  local carryon = _petData.possession.item
  if carryon and #carryon > 0 then
    for j = 1, #carryon do
      local carryonItem = carryon[j]
      if carryonItem.conf_id and carryonItem.conf_id > 0 then
        if bagitems[carryonItem.conf_id] ~= nil then
          bagitems[carryonItem.conf_id].Count = bagitems[carryonItem.conf_id].Count + 1
        else
          bagitems[carryonItem.conf_id] = {
            Count = 1,
            Id = carryonItem.conf_id
          }
        end
      end
    end
  end
  for i, bagitem in pairs(bagitems) do
    table.insert(self.uiData.PetFreeAward, bagitem)
  end
end

function UMG_FreeCaptivePet_C:GetTalentRankAward(_PetData)
  local _petData = _PetData
  local Hp = _petData.attribute_info.hp
  local Attack = _petData.attribute_info.attack
  local SpecialAttack = _petData.attribute_info.special_attack
  local Defense = _petData.attribute_info.defense
  local specialdefense = _petData.attribute_info.special_defense
  local Speed = _petData.attribute_info.speed
  self:SetAttributeAward(Hp, Enum.AttributeType.AT_HPMAX)
  self:SetAttributeAward(Attack, Enum.AttributeType.AT_PHYATK)
  self:SetAttributeAward(SpecialAttack, Enum.AttributeType.AT_SPEATK)
  self:SetAttributeAward(Defense, Enum.AttributeType.AT_PHYDEF)
  self:SetAttributeAward(specialdefense, Enum.AttributeType.AT_SPEDEF)
  self:SetAttributeAward(Speed, Enum.AttributeType.AT_SPEED)
end

function UMG_FreeCaptivePet_C:SetAttributeAward(_PetAttributeData, Type)
  local PetAttributeData = _PetAttributeData or 0
  local PetEffortsList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_EFFORTS_LEVEL):GetAllDatas()
  for i, PetEfforts in pairs(PetEffortsList) do
    if type(PetAttributeData) == "table" and PetEfforts.attribute_type == Type and PetEfforts.free_item_id and 0 ~= PetEfforts.free_item_id then
      table.insert(self.uiData.PetFreeAward, {
        Count = PetEfforts.free_item_data,
        Id = PetEfforts.free_item_id
      })
      break
    end
  end
end

function UMG_FreeCaptivePet_C:GetMaxHabitReward()
  local petData = self.uiData.petList
  for i, _petData in ipairs(petData) do
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.base_conf_id)
    if PetBaseConf then
      local group_id = PetBaseConf.belong_habit_group
      if group_id and 0 ~= group_id then
        local ItemNum = PetUtils.GetPetUnlockedHabitItemNum(group_id, _petData.habit_level)
        if ItemNum > 0 and PetBaseConf.petfree_extra_item_id then
          if self.uiData.UnlockedHabitItemNum[PetBaseConf.petfree_extra_item_id] then
            self.uiData.UnlockedHabitItemNum[PetBaseConf.petfree_extra_item_id] = self.uiData.UnlockedHabitItemNum[group_id] + ItemNum
          else
            self.uiData.UnlockedHabitItemNum[PetBaseConf.petfree_extra_item_id] = ItemNum
          end
        end
      end
    end
  end
end

function UMG_FreeCaptivePet_C:GetHabitReward(_PetData)
  local _petData = _PetData
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.base_conf_id)
  if petBaseConf then
    local RewardItemNum = petBaseConf.petfree_extra_common_num
    local IsMixedBlood = PetUtils.GetPetIsMixedBlood(_petData, petBaseConf.unit_type)
    if IsMixedBlood then
      RewardItemNum = RewardItemNum + petBaseConf.petfree_extra_mixblood_num
    end
    if petBaseConf and 0 ~= petBaseConf.petfree_extra_item_id then
      if PetMutationUtils.GetMutationValue(_petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
        RewardItemNum = RewardItemNum + petBaseConf.petfree_extra_shining_num
      elseif PetMutationUtils.GetMutationValue(_petData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
        RewardItemNum = RewardItemNum + petBaseConf.petfree_extra_glass_num
      end
    end
    self:AddReward(petBaseConf.petfree_extra_item_id, RewardItemNum)
  end
end

function UMG_FreeCaptivePet_C:AddReward(BagItemId, Num)
  if not (BagItemId and Num) or 0 == Num then
    return
  end
  if not self.uiData.UnlockedHabitItemNum[BagItemId] then
    return
  end
  local MaxNum = self.uiData.UnlockedHabitItemNum[BagItemId]
  local BagItem = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, BagItemId)
  if BagItem then
    MaxNum = self.uiData.UnlockedHabitItemNum[BagItemId] - BagItem.num
  end
  if MaxNum <= 0 then
    return
  end
  local wardItemInfo = self.uiData.PetFreeAward
  local IsHaveItem = false
  for i, item in ipairs(wardItemInfo) do
    if item.Id == BagItemId then
      IsHaveItem = true
      local num = item.Count + Num
      if MaxNum <= num then
        num = MaxNum
      end
      item.Count = num
    end
  end
  if not IsHaveItem and 0 ~= MaxNum then
    if Num >= MaxNum then
      Num = MaxNum
    end
    table.insert(self.uiData.PetFreeAward, {Count = Num, Id = BagItemId})
  end
end

function UMG_FreeCaptivePet_C:UpdateList()
  local wardItemInfo = self.uiData.PetFreeAward
  local itemInfo = {}
  for i, item in ipairs(wardItemInfo) do
    local itemCfg = item.Id > 0 and _G.DataConfigManager:GetBagItemConf(item.Id) or nil
    table.insert(itemInfo, {
      itemCfg = itemCfg,
      itemId = item.Id,
      itemCount = item.Count,
      itemType = item.Type
    })
  end
  table.sort(itemInfo, function(a, b)
    if a.itemCfg.sort_id ~= b.itemCfg.sort_id then
      return a.itemCfg.sort_id < b.itemCfg.sort_id
    else
      return a.itemCfg.item_quality > b.itemCfg.item_quality
    end
  end)
  self.ItemList:InitGridView(itemInfo)
end

function UMG_FreeCaptivePet_C:GetReward(_abilities, _petfree_sort, _level, GrowOrder)
  local abilities = _abilities
  local petfree_sort = _petfree_sort
  local level = _level
  for i, v in pairs(abilities) do
    if petfree_sort == v.petfree_sort and level >= v.level_low and level <= v.level_high and GrowOrder >= v.star_low and GrowOrder <= v.star_high then
      return v.reward
    end
  end
  return
end

function UMG_FreeCaptivePet_C:OnDeactive()
end

function UMG_FreeCaptivePet_C:OnAddEventListener()
  self:AddButtonListener(self.UMG_Btn1.btnLevelUp, self.OnBtnOkClick)
  self:AddButtonListener(self.UMG_Btn2.btnLevelUp, self.OnBtnCancelClick)
end

function UMG_FreeCaptivePet_C:OnBtnOkClick()
  self.UMG_Btn1:SetIsEnabled(false)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_PetWarehouse_C:OnNRCButtonB")
  self:PlayAnimation(self.vanish)
end

function UMG_FreeCaptivePet_C:OnBtnCancelClick()
  local gid = self.uiData.gid
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_PetWarehouse_C:OnNRCButtonB")
  NRCModuleManager:DoCmd(PetUIModuleCmd.SendFangShengPet, gid)
  self.UMG_Btn2:SetIsEnabled(false)
  self:DoClose()
end

function UMG_FreeCaptivePet_C:OnAnimationFinished(Animation)
  if Animation == self.vanish then
    self:DoClose()
    self.UMG_Btn1:SetIsEnabled(true)
    self.UMG_Btn2:SetIsEnabled(true)
  end
end

return UMG_FreeCaptivePet_C
