local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetFreeCaptiveAnimals_C = _G.NRCPanelBase:Extend("UMG_PetFreeCaptiveAnimals_C")

function UMG_PetFreeCaptiveAnimals_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
  self.icon1 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/pet_img_quxiao_png.pet_img_quxiao_png'"
  self.icon2 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/btn_fangsheng_png.btn_fangsheng_png'"
  self:OnAddEventListener()
end

function UMG_PetFreeCaptiveAnimals_C:OnDestruct()
end

function UMG_PetFreeCaptiveAnimals_C:OnAddEventListener()
end

function UMG_PetFreeCaptiveAnimals_C:OnActive(_data, stateType, coverRewardList)
  stateType = stateType or PetUIModuleEnum.PetFreeCaptivePanelStateType.None
  self:LoadAnimation(0)
  self.uiData = {}
  self.uiData.petList = _data
  self.stateType = stateType
  self.uiData.gid = {}
  self.uiData.PetFreeAward = {}
  self.uiData.UnlockedHabitItemNum = {}
  self.coverRewardList = coverRewardList
  self:SetCommonPopUpInfo()
  self:SetUpList()
  self:SetNewBelowList()
  self:UpdateList()
end

function UMG_PetFreeCaptiveAnimals_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if self.stateType == PetUIModuleEnum.PetFreeCaptivePanelStateType.None then
    CommonPopUpData.Desc = _G.DataConfigManager:GetLocalizationConf("pet_remove_text").msg
  elseif self.stateType == PetUIModuleEnum.PetFreeCaptivePanelStateType.IncludeCanTraceBackPet then
    CommonPopUpData.Desc = _G.DataConfigManager:GetLocalizationConf("pet_free_return_tip").msg
  end
  CommonPopUpData.Btn_RightText = LuaText.umg_petfreecaptiveanimals_2
  CommonPopUpData.Btn_LeftText = LuaText.umg_petfreecaptiveanimals_1
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtnCancelClick
  CommonPopUpData.Btn_RightHandler = self.OnBtnOkClick
  CommonPopUpData.ClosePanelHandler = self.OnBtnWhiteClick
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp3:SetPanelInfo(CommonPopUpData)
end

function UMG_PetFreeCaptiveAnimals_C:SetButtonIcon(okIcon, cancelIcon)
  if string.IsNilOrEmpty(okIcon) then
    self.BtnOk.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BtnOk.Icon:SetPath(okIcon)
    self.BtnOk.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if string.IsNilOrEmpty(cancelIcon) then
    self.BtnCancel.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BtnCancel.Icon:SetPath(cancelIcon)
    self.BtnCancel.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetFreeCaptiveAnimals_C:SetNewBelowList()
  if self.coverRewardList ~= nil then
    Log.Debug("UMG_PetFreeCaptiveAnimals_C:SetNewBelowList, coverRewardList ~= nil, return")
    return
  end
  local petData = self.uiData.petList
  for i, _petData in ipairs(petData) do
    local AwardList = PetUtils.GetPetFreeAwradList(_petData)
    self.uiData.PetFreeAward = PetUtils.AddRewardToItemList(AwardList, self.uiData.PetFreeAward)
    self:GetNewBaseInfoReward(_petData)
  end
end

function UMG_PetFreeCaptiveAnimals_C:GetNewBaseInfoReward(_PetData)
  local itemCfg
  local _petData = _PetData
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.catch_base_id)
  if petBaseConf then
    local PetGrowLevel, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(_petData)
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
                if self.uiData.PetFreeAward and self.uiData.PetFreeAward[itemCfg.id] then
                  self.uiData.PetFreeAward[itemCfg.id].Count = self.uiData.PetFreeAward[itemCfg.id].Count + ConsumeNum
                else
                  local Rewards = {}
                  Rewards.Count = ConsumeNum
                  Rewards.Id = itemCfg.id
                  Rewards.Type = ""
                  self.uiData.PetFreeAward[itemCfg.id] = Rewards
                end
              end
            end
          end
        end
      end
    end
  end
end

function UMG_PetFreeCaptiveAnimals_C:SetUpList()
  local PetFreeList = {}
  local petData = self.uiData.petList
  local gid = {}
  if petData then
    for i, _petData in ipairs(petData) do
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.base_conf_id)
      if petBaseConf then
        local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
        table.insert(gid, _petData.gid)
        table.insert(PetFreeList, {
          IconListInfo = _petData.level,
          gid = _petData.gid,
          PetIcon = modelConf,
          IsTeamPet = false,
          PetBasicProperty = petBaseConf.quality,
          PetBaseId = _petData.base_conf_id,
          mutation_typ = _petData.mutation_type,
          glass_info = _petData.glass_info
        })
      end
    end
  end
  self.uiData.gid = gid
  PetFreeList = self:SortFreePetList(PetFreeList)
  self.uiData.PetFreeInfo = PetFreeList
  self.UpList1:InitGridView(PetFreeList)
  self.Switcher_Bg:SetActiveWidgetIndex(0)
end

function UMG_PetFreeCaptiveAnimals_C:SortFreePetList(_PetFreeList)
  table.sort(_PetFreeList, function(a, b)
    if a.PetBasicProperty < b.PetBasicProperty then
      return a.PetBasicProperty < b.PetBasicProperty
    elseif a.PetBasicProperty == b.PetBasicProperty and a.IconListInfo < b.IconListInfo then
      return a.IconListInfo < b.IconListInfo
    elseif a.PetBasicProperty == b.PetBasicProperty and a.IconListInfo == b.IconListInfo and a.gid < b.gid then
      return a.gid < b.gid
    end
  end)
  return _PetFreeList
end

function UMG_PetFreeCaptiveAnimals_C:SetBelowList()
  local petData = self.uiData.petList
  self:GetMaxHabitReward()
  for i, _petData in ipairs(petData) do
    self:GetBaseInfoReward(_petData)
    self:GetCarryonBagItemList(_petData)
    self:GetTalentRankAward(_petData)
    self:GetHabitReward(_petData)
  end
end

function UMG_PetFreeCaptiveAnimals_C:GetBaseInfoReward(_PetData)
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

function UMG_PetFreeCaptiveAnimals_C:GetCarryonBagItemList(_PetData)
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

function UMG_PetFreeCaptiveAnimals_C:GetTalentRankAward(_PetData)
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

function UMG_PetFreeCaptiveAnimals_C:SetAttributeAward(_PetAttributeData, Type)
  local PetAttributeData = _PetAttributeData or 0
  local PetEffortsList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_EFFORTS_LEVEL):GetAllDatas()
  for i, PetEfforts in pairs(PetEffortsList) do
    if type(PetAttributeData) == "table" and PetEfforts.attribute_type == Type and PetEfforts.free_item_id and 0 ~= PetEfforts.free_item_id then
      local wardItemInfo = self.uiData.PetFreeAward
      local IsHaveItem = false
      for j, item in ipairs(wardItemInfo) do
        if item.Id == PetEfforts.free_item_id then
          IsHaveItem = true
          local num = item.Count + PetEfforts.free_item_data
          item.Count = num
        end
      end
      if not IsHaveItem then
        table.insert(self.uiData.PetFreeAward, {
          Count = PetEfforts.free_item_data,
          Id = PetEfforts.free_item_id
        })
      end
      break
    end
  end
end

function UMG_PetFreeCaptiveAnimals_C:GetMaxHabitReward()
  local petData = self.uiData.petList
  for i, _petData in ipairs(petData) do
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.base_conf_id)
    if PetBaseConf then
      local group_id = PetBaseConf.belong_habit_group
      if group_id and 0 ~= group_id then
        local ItemNum = PetUtils.GetPetUnlockedHabitItemNum(group_id, _petData.habit_level)
        if ItemNum > 0 and PetBaseConf.petfree_extra_item_id then
          if self.uiData.UnlockedHabitItemNum[PetBaseConf.petfree_extra_item_id] then
            local Num = self.uiData.UnlockedHabitItemNum[group_id] or 0
            self.uiData.UnlockedHabitItemNum[PetBaseConf.petfree_extra_item_id] = Num + ItemNum
          else
            self.uiData.UnlockedHabitItemNum[PetBaseConf.petfree_extra_item_id] = ItemNum
          end
        end
      end
    end
  end
end

function UMG_PetFreeCaptiveAnimals_C:GetHabitReward(_PetData)
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

function UMG_PetFreeCaptiveAnimals_C:AddReward(BagItemId, Num)
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

function UMG_PetFreeCaptiveAnimals_C:UpdateList()
  local wardItemInfo = self.uiData.PetFreeAward
  if self.coverRewardList then
    wardItemInfo = self.coverRewardList
  end
  local itemInfo = {}
  for i, item in pairs(wardItemInfo) do
    if self.coverRewardList == nil then
      local itemCfg = item.Id > 0 and _G.DataConfigManager:GetBagItemConf(item.Id) or nil
      table.insert(itemInfo, {
        itemCfg = itemCfg,
        itemId = item.Id,
        itemCount = item.Count,
        itemType = item.Type
      })
    else
      local itemCfg = item.id > 0 and _G.DataConfigManager:GetBagItemConf(item.id) or nil
      table.insert(itemInfo, {
        itemCfg = itemCfg,
        itemId = item.id,
        itemCount = item.num,
        itemType = item.Type
      })
    end
  end
  
  local function compare(a, b)
    if a.itemCfg.item_quality ~= b.itemCfg.item_quality then
      return a.itemCfg.item_quality > b.itemCfg.item_quality
    else
      return a.itemCfg.sort_id < b.itemCfg.sort_id
    end
  end
  
  table.sort(itemInfo, compare)
  local rewardsTable = {}
  for k, v in ipairs(itemInfo) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = _G.Enum.GoodsType.GT_BAGITEM
    rewards.itemId = v.itemId
    rewards.itemNum = v.itemCount
    rewards.bShowNum = true
    rewards.bShowTip = true
    table.insert(rewardsTable, rewards)
  end
  self.BelowList1:InitGridView(rewardsTable)
end

function UMG_PetFreeCaptiveAnimals_C:GetReward(_abilities, _petfree_sort, _level, GrowOrder)
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

function UMG_PetFreeCaptiveAnimals_C:OnBtnCancelClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_PetWarehouse_C:OnNRCButtonB")
  self:LoadAnimation(2)
  self:DispatchEvent(PetUIModuleEvent.PET_FREE_CANCEL)
end

function UMG_PetFreeCaptiveAnimals_C:OnBtnWhiteClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401014, "UMG_PetWarehouse_C:OnNRCButtonB")
  self:LoadAnimation(2)
end

function UMG_PetFreeCaptiveAnimals_C:OnBtnOkClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_FREE, true)
  if isBan then
    return
  end
  local IsPrecious, TypeString = PetUtils.IsPreciousPet(self.uiData.petList)
  if IsPrecious then
    self:OpenPreciousDialogPanel(TypeString)
    return
  end
  self:OnFreeOk()
end

function UMG_PetFreeCaptiveAnimals_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_PetFreeCaptiveAnimals_C:OnFreeOk()
  local gid = self.uiData.gid
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_PetWarehouse_C:OnNRCButtonB")
  NRCModuleManager:DoCmd(PetUIModuleCmd.SendFangShengPet, gid)
  self:DoClose()
end

function UMG_PetFreeCaptiveAnimals_C:OpenPreciousDialogPanel(PetTypeString)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local ContentTitle = _G.DataConfigManager:GetLocalizationConf("TIPS").msg
  local ContentText = string.format(LuaText.rare_pet_release_tips, PetTypeString)
  Context:SetTitle(ContentTitle):SetContent(ContentText):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel):SetCloseOnCancel(true):SetCallbackOkOnly(self, self.OnFreeOk):SetClickAnywhereClose(true)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_PetFreeCaptiveAnimals_C:OnDeactive()
end

return UMG_PetFreeCaptiveAnimals_C
