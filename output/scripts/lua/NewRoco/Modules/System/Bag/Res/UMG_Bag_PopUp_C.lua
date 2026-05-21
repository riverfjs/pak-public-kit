local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local UMG_Bag_PopUp_C = _G.NRCPanelBase:Extend("UMG_Bag_PopUp_C")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")

function UMG_Bag_PopUp_C:OnConstruct()
  self.WaitUseItemRsp = false
  self.Type = nil
  self.SelectItemData = nil
  self.IsCanClose = true
  self:SetChildViews(self.PopUp4)
end

function UMG_Bag_PopUp_C:OnActive(petSkillinfo, _Type, _SelectItemData)
  self.moduleData = self.module:GetData("BagModuleData")
  self.LearningSkillInfo = _SelectItemData
  self.Type = _Type
  self.skillConfRec = nil
  self:SetCommonPopUpInfo(self.PopUp4)
  if self.Type and self.Type == self.moduleData.CustomEnum.PetToSKILL_MACHINE then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petSkillinfo.base_conf_id)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      if modelConf then
        self.HeadIcon:SetIconPathAndMaterial(petSkillinfo.base_conf_id, petSkillinfo.mutation_type, petSkillinfo.glass_info)
        self.NumText:SetText(petSkillinfo.level)
      end
    end
    self.PopUp4:SetTitleTextInfo(LuaText.UMG_Bag_UseSkillStone_Title)
    self.PopUp4:SetBtnLeftText(LuaText.umg_bag_popup_3)
    self.PopUp4:SetBtnRightText(LuaText.umg_bag_popup_2)
    local CurSelectedItemData = _SelectItemData
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(CurSelectedItemData.id)
    local skillMachineid = bagItemInfo.item_behavior[1].ratio[1]
    local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
    local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
    self.SkillIcon:SetPath(skillConf.icon)
    self.TxtSkillName:SetText(skillConf.name)
    local Name, Path
    if typeDic then
      Path = typeDic.tips_res
    end
    if 1 ~= skillConf.damage_type then
      Name = tostring(skillConf.dam_para[1])
    else
      Name = "-"
    end
    local SkillTypeList = {
      {Name = Name, Path = Path}
    }
    self.Attr:InitGridView(SkillTypeList)
    self.TxtPnum:SetText(skillConf.energy_cost[1])
    local allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp9").msg
    self.PopUp4:SetDescInfo(string.format(allText, petSkillinfo.name, skillConf.name))
    self.PopUp4:SetBtnRightEnableStateNew(true)
    self.Switcher:SetActiveWidgetIndex(1)
    self.NormalBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BossBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemData = {petSkillinfo}
  else
    _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_Bag_BXTips_C:OnClose")
    self.Switcher:SetActiveWidgetIndex(0)
    self.PopUp4:SetBtnLeftText(LuaText.umg_bag_popup_1)
    self.PopUp4:SetBtnRightText(LuaText.umg_bag_popup_2)
    self.ItemData = nil
    self.module = NRCModuleManager:GetModule("BagModule")
    self.SelectItemData = _SelectItemData
    local petListInfo = {}
    for i = 1, #petSkillinfo do
      if 0 == petSkillinfo[i][2] then
        table.insert(petListInfo, petSkillinfo[i])
      end
    end
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.SelectItemData.id)
    self.PopUp4:SetTitleTextInfo(BagItemConf.name)
    self.PopUp4:SetTitleIconInfo(BagItemConf.icon)
    local allText = ""
    if self.Type and self.Type == self.moduleData.CustomEnum.SKILL_MACHINE then
      allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp7").msg
    else
      allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp1").msg
    end
    self.PopUp4:SetDescInfo(allText)
    self.PopUp4:SetBtnRightEnableStateNew(false)
    self:InitData(petListInfo, self.List, true)
  end
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:LoadAnimation(0)
  self:OnAddEventListener()
end

function UMG_Bag_PopUp_C:OnDeactive()
  self:UnRegisterEvent(self, BagModuleEvent.SetChoosePetskillItem)
end

function UMG_Bag_PopUp_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtnLeftClicked
  CommonPopUpData.Btn_RightHandler = self.OnBtnRightClicked
  CommonPopUpData.ClosePanelHandler = self.OnClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Bag_PopUp_C:InitData(petSkillinfo, List, Canclick)
  local data = petSkillinfo
  List:InitGridView(data)
  if data and #data > 0 and self.Type and self.Type == self.moduleData.CustomEnum.OPTIONAL_TREASUREBOX then
    for i, _ in ipairs(data) do
      local Item = List:GetItemByIndex(i - 1)
      if not Canclick then
        Item.clickable = false
      end
      Item:ShowBloodPulse()
    end
  end
end

function UMG_Bag_PopUp_C:SetBtnAbleAndItemData(_data)
  self.ItemData = _data
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(_data[1].gid)
  local allText
  if self.Type and self.Type == self.moduleData.CustomEnum.SKILL_MACHINE then
    allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp8").msg
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(self.SelectItemData.id)
    local skillMachineid = bagItemInfo.item_behavior[1].ratio[1]
    local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
    self.PopUp4:SetDescInfo(string.format(allText, petData.name, skillConf.name))
  else
    allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp2").msg
    self.PopUp4:SetDescInfo(string.format(allText, petData.name))
  end
  self.PopUp4:SetBtnRightEnableStateNew(true)
end

function UMG_Bag_PopUp_C:OnAddEventListener()
  self:RegisterEvent(self, BagModuleEvent.SetChoosePetskillItem, self.SetBtnAbleAndItemData)
  self:AddButtonListener(self.Tipsbtn, self.OpenChangePetConfirm)
  self:AddButtonListener(self.OpenSkillDetailsBtn, self.OnOpenSkillDetailsBtn)
end

function UMG_Bag_PopUp_C:OnBtnLeftClicked()
  local switcherIndex = self.Switcher:GetActiveWidgetIndex()
  if 0 == switcherIndex then
    self:OnClose()
  elseif 1 == switcherIndex then
    if self.skillConfRec and self:SkillIsEquip(self.skillConfRec.id) == false then
      self.skipClosePanelType = 1
    else
      self:OpenPetSkillPanel()
    end
    self:OnClose()
  end
end

function UMG_Bag_PopUp_C:OnBtnRightClicked()
  local switcherIndex = self.Switcher:GetActiveWidgetIndex()
  if 0 == switcherIndex then
    if self.Success then
      return
    end
    self:OnBtnOKClick()
  elseif 1 == switcherIndex then
    self:OnClose()
  end
end

function UMG_Bag_PopUp_C:SetIsCanClose(_IsCanClose)
  self.IsCanClose = _IsCanClose
end

function UMG_Bag_PopUp_C:OnClose()
  self:StopAllAnimations()
  if not self.IsCanClose then
    return
  end
  if self.WaitUseItemRsp then
    self.Success = false
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_Bag_BXTips_C:OnClose")
  self:RemoveButtonListener(self.Tipsbtn, self.OpenChangePetConfirm)
  self.PopUp4:SetLock(false)
  self:LoadAnimation(2)
end

function UMG_Bag_PopUp_C:OpenChangePetConfirm()
  local PetSkillItemData
  if self.moduleData.displayMode == BagModuleEnum.DisplayMode.SkillMachine then
    PetSkillItemData = self.ItemData
  else
    PetSkillItemData = self.moduleData:GetCurSelectedPetSkillItemData()
  end
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.ShowChangePetConfirm, PetSkillItemData[1])
end

function UMG_Bag_PopUp_C:OnOpenSkillDetailsBtn()
  local CurSelectedItemData = self.LearningSkillInfo
  if CurSelectedItemData.id then
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(CurSelectedItemData.id)
    local skillMachineid = bagItemInfo.item_behavior[1].ratio[1]
    local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenSkillTips, {skillData = skillConf, HideClose = false}, true)
    self:SetIsCanClose(false)
  end
end

function UMG_Bag_PopUp_C:OpenPetSkillPanel()
  local data = self.ItemData
  if self.moduleData.displayMode == BagModuleEnum.DisplayMode.SkillMachine then
    if self.module.IsPetInfoMainToPanel then
      local openPetData, index, bIsRevertMainPanel = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
      if not openPetData then
        bIsRevertMainPanel = true
      end
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.EnablePanelPetMain)
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(data[1].gid)
      local bagItemInfo = _G.DataConfigManager:GetBagItemConf(self.LearningSkillInfo.id)
      local skillMachineid = bagItemInfo.item_behavior[1].ratio[1]
      local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 2, bIsRevertMainPanel, 0, skillConf)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.RefreshPetRightPanel, true)
      _G.NRCModuleManager:DoCmd(BagModuleCmd.CloseBagMainPanel)
    else
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(data[1].gid)
      local bagItemInfo = _G.DataConfigManager:GetBagItemConf(self.LearningSkillInfo.id)
      local skillMachineid = bagItemInfo.item_behavior[1].ratio[1]
      local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 2, false, 0, skillConf)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsBagToOpenPanel)
      NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
        subPanelIndex = 4,
        callback = self.OnUMGLoadFinished
      })
      self:DoClose()
    end
  elseif nil ~= data then
    if self.Type and self.Type == self.moduleData.CustomEnum.SKILL_MACHINE then
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(data[1].gid)
      if self.skillConfRec then
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 2, false, 0, self.skillConfRec)
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsBagToOpenPanel)
        NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
          subPanelIndex = 4,
          callback = self.OnUMGLoadFinished
        })
        self:DoClose()
      end
    else
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsBagToOpenPanel)
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(data[1].gid)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 2, false, 1)
      NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
        subPanelIndex = 4,
        callback = self.OnUMGLoadFinished
      })
      self:DoClose()
    end
  else
    self:DoClose()
  end
end

function UMG_Bag_PopUp_C:OnBtnOKClick()
  if self.WaitUseItemRsp then
    return
  end
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  local allText
  local PetSkillItemData = self.moduleData:GetCurSelectedPetSkillItemData()
  if not PetSkillItemData then
    if self.Type and self.Type == self.moduleData.CustomEnum.SKILL_MACHINE then
      local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_LEARN_SKILL, true)
      if isBan then
        return
      end
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.UMG_Bag_PopUp7)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.UMG_Bag_PopUp1)
    end
    return
  end
  self.WaitUseItemRsp = true
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(PetSkillItemData[1].base_conf_id)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    if modelConf then
      self.HeadIcon:SetIconPathAndMaterial(PetSkillItemData[1].base_conf_id, PetSkillItemData[1].mutation_type, PetSkillItemData[1].glass_info)
      self.NumText:SetText(PetSkillItemData[1].level)
    end
  end
  if self.Type and self.Type == self.moduleData.CustomEnum.SKILL_MACHINE then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_LEARN_SKILL, true)
    if isBan then
      self.WaitUseItemRsp = false
      return
    end
    self.NormalBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BossBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local CurSelectedItemData = self.moduleData:GetCurSelectedItemData()
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(CurSelectedItemData.id)
    local skillMachineid = bagItemInfo.item_behavior[1].ratio[1]
    local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
    self.skillConfRec = skillConf
    local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
    if true == self.List:IsHaveItemIndexSelected() then
      self.SkillIcon:SetPath(skillConf.icon)
      self.TxtSkillName:SetText(skillConf.name)
      local Name, Path
      if typeDic then
        Path = typeDic.tips_res
      end
      if 1 ~= skillConf.damage_type then
        Name = tostring(skillConf.dam_para[1])
      else
        Name = "-"
      end
      local SkillTypeList = {
        {Name = Name, Path = Path}
      }
      self.Attr:InitGridView(SkillTypeList)
      self.TxtPnum:SetText(skillConf.energy_cost[1])
      allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp9").msg
      self.Success = true
      _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, CurSelectedItemData.gid, CurSelectedItemData.id, 1, PetSkillItemData[1].gid)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.UMG_Bag_PopUp_Tips1)
    end
  else
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.SelectItemData.id)
    local use_action = BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].ratio[1]
    if use_action then
      local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(use_action)
      if PetBloodConf.blood ~= Enum.PetBloodType.PBT_BOSS then
        local Pos = UE4.FVector2D(-264.0, -56.0)
        self.HeadCanvas.Slot:SetPosition(Pos)
        self.NormalBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.BossBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
        local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, PetSkillItemData[1].base_conf_id)
        local skillConf = self:GetSkillData(PetBloodConf.id, LevelSkillConf)
        if skillConf then
          self.SkillIcon:SetPath(skillConf.icon)
          self.TxtSkillName:SetText(skillConf.name)
          self.TxtPnum:SetText(skillConf.energy_cost[1])
        else
        end
        local typeDic = _G.DataConfigManager:GetTypeDictionary(PetBloodConf.blood_type)
        if typeDic then
          PetSkillItemData[1].blood_id = PetBloodConf.id
          if LevelSkillConf.blood_skill_level_point <= PetSkillItemData[1].level then
            allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp3").msg
            self.PopUp4:SetDescInfo(string.format(allText, PetSkillItemData[1].name, typeDic.type_name))
          else
            allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp3").msg .. "(" .. _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp4").msg .. ")"
            self.PopUp4:SetDescInfo(string.format(allText, PetSkillItemData[1].name, typeDic.type_name, LevelSkillConf.blood_skill_level_point))
          end
        end
        local Name, Path
        if typeDic then
          Path = typeDic.tips_res
        end
        if skillConf and 1 ~= skillConf.damage_type then
          Name = tostring(skillConf.dam_para[1])
        else
          Name = "-"
        end
        local SkillTypeList = {
          {Name = Name, Path = Path}
        }
        self.Attr:InitGridView(SkillTypeList)
      else
        local Pos = UE4.FVector2D(-376.0, -56.0)
        self.HeadCanvas.Slot:SetPosition(Pos)
        self.NormalBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.BossBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.NRCText_78:SetText(LuaText.UMG_Bag_PopUp16)
        allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp3").msg
        self.PopUp4:SetDescInfo(string.format(allText, PetSkillItemData[1].name, PetBloodConf.blood_name))
      end
      self.PopUp4:SetBtnRightEnableStateNew(true)
      self.Success = true
      local CurSelectedItemData = self.moduleData:GetCurSelectedItemData()
      _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, CurSelectedItemData.gid, CurSelectedItemData.id or 0, 1, PetSkillItemData[1].gid)
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Bag_PopUp_C:OnBtnOKClick")
end

function UMG_Bag_PopUp_C:SkillIsEquip(skillId)
  local PetSkillItemData = self.moduleData:GetCurSelectedPetSkillItemData()
  if PetSkillItemData and PetSkillItemData[1] and PetSkillItemData[1].gid then
    local posToIdDic, _ = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, PetSkillItemData[1].gid)
    if posToIdDic then
      for i = 1, 4 do
        if posToIdDic[i] and posToIdDic[i] == skillId then
          return true
        end
      end
    end
  end
  return false
end

function UMG_Bag_PopUp_C:AutoEquipSkillHandle(skillId)
  if self:SkillIsEquip(skillId) then
    return false
  end
  local PetSkillItemData = self.moduleData:GetCurSelectedPetSkillItemData()
  if PetSkillItemData and PetSkillItemData[1] and PetSkillItemData[1].gid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(PetSkillItemData[1].gid)
    if petData then
      local skillIsLearned = false
      for i, v in ipairs(petData.skill.skill_data) do
        if v.id == skillId then
          skillIsLearned = v.is_learned
          break
        end
      end
      if skillIsLearned then
        local posToIdDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, PetSkillItemData[1].gid)
        if #posToIdDic < 4 then
          table.insert(posToIdDic, skillId)
          _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AutoCheckEnvironmentEquipPetSkill, PetSkillItemData[1].gid, posToIdDic)
          return true
        end
      end
    end
  end
  return false
end

function UMG_Bag_PopUp_C:RefreshPopUpOnUseItemSuccess()
  local PetSkillItemData = self.moduleData:GetCurSelectedPetSkillItemData()
  local allText
  if self.Type and self.Type == self.moduleData.CustomEnum.SKILL_MACHINE then
    local CurSelectedItemData = self.moduleData:GetCurSelectedItemData()
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(self.use_bag_id or CurSelectedItemData.id)
    local skillMachineid = bagItemInfo.item_behavior[1].ratio[1]
    local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
    local autoEquip = self:AutoEquipSkillHandle(self.skillConfRec.id)
    if autoEquip or self:SkillIsEquip(self.skillConfRec.id) then
      allText = LuaText.UMG_Bag_PopUp10
      self.PopUp4:ShowOrHideBtnLeft(false)
      self.PopUp4:ShowOrHideBtnRight(false)
    else
      allText = LuaText.UMG_Bag_PopUp9
      self.PopUp4:SetBtnLeftText(LuaText.skill_change_title_1)
      self.PopUp4:ShowOrHideBtnLeft(true)
      self.PopUp4:ShowOrHideBtnRight(true)
    end
    self.PopUp4:SetTitleTextInfo(LuaText.UMG_Bag_UseSkillStone_Title)
    if self.List:IsHaveItemIndexSelected() == true then
      self.PopUp4:SetDescInfo(string.format(allText, PetSkillItemData[1].name, skillConf.name))
    end
  else
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.use_bag_id or self.SelectItemData.id)
    local use_action = BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].ratio[1]
    self.PopUp4:SetTitleTextInfo(LuaText.BAG_USE_ITEM_SUCCESS)
    self.PopUp4:SetBtnLeftText(LuaText.UMG_Bag_PopUp5)
    if use_action then
      local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(use_action)
      if PetBloodConf.blood ~= Enum.PetBloodType.PBT_BOSS then
        local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, PetSkillItemData[1].base_conf_id)
        local skillConf = self:GetSkillData(PetBloodConf.id, LevelSkillConf)
        local typeDic = _G.DataConfigManager:GetTypeDictionary(PetBloodConf.blood_type)
        if typeDic then
          PetSkillItemData[1].blood_id = PetBloodConf.id
          if LevelSkillConf.blood_skill_level_point <= PetSkillItemData[1].level then
            allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp3").msg
            self.PopUp4:SetDescInfo(string.format(allText, PetSkillItemData[1].name, typeDic.type_name))
          else
            allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp3").msg .. "(" .. _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp4").msg .. ")"
            self.PopUp4:SetDescInfo(string.format(allText, PetSkillItemData[1].name, typeDic.type_name, LevelSkillConf.blood_skill_level_point))
          end
        end
      else
        allText = _G.DataConfigManager:GetLocalizationConf("UMG_Bag_PopUp3").msg
        self.PopUp4:SetDescInfo(string.format(allText, PetSkillItemData[1].name, PetBloodConf.blood_name))
      end
    end
  end
  self.PopUp4:SetBtnRightEnableStateNew(true)
end

function UMG_Bag_PopUp_C:OnUseItemRsp(use_bag_id)
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  self.use_bag_id = use_bag_id
  self.WaitUseItemRsp = false
  self.PopUp4:SetLock(false)
  self:LoadAnimation(2)
end

function UMG_Bag_PopUp_C:GetSkillData(blood_id, LevelSkillConf)
  if blood_id == Enum.PetBloodType.PBT_COMMON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_COMMON)
  elseif blood_id == Enum.PetBloodType.PBT_GRASS then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_GRASS)
  elseif blood_id == Enum.PetBloodType.PBT_FIRE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_FIRE)
  elseif blood_id == Enum.PetBloodType.PBT_WATER then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_WATER)
  elseif blood_id == Enum.PetBloodType.PBT_LIGHT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_LIGHT)
  elseif blood_id == Enum.PetBloodType.PBT_STONE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_STONE)
  elseif blood_id == Enum.PetBloodType.PBT_ICE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_ICE)
  elseif blood_id == Enum.PetBloodType.PBT_DRAGON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_DRAGON)
  elseif blood_id == Enum.PetBloodType.PBT_ELECTRIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_ELECTRIC)
  elseif blood_id == Enum.PetBloodType.PBT_TOXIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_TOXIC)
  elseif blood_id == Enum.PetBloodType.PBT_INSECT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_INSECT)
  elseif blood_id == Enum.PetBloodType.PBT_FIGHT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_FIGHT)
  elseif blood_id == Enum.PetBloodType.PBT_WING then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_WING)
  elseif blood_id == Enum.PetBloodType.PBT_MOE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_MOE)
  elseif blood_id == Enum.PetBloodType.PBT_GHOST then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_GHOST)
  elseif blood_id == Enum.PetBloodType.PBT_DEMON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_DEMON)
  elseif blood_id == Enum.PetBloodType.PBT_MECHANIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_MECHANIC)
  elseif blood_id == Enum.PetBloodType.PBT_PHANTOM then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_PHANTOM)
  end
end

function UMG_Bag_PopUp_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if self.Success then
      self:StopAllAnimations()
      self.PopUp4:StopAllAnimations()
      self:DelaySeconds(0.2, function()
        self.Switcher:SetActiveWidgetIndex(1)
        self.PopUp4:SetBtnLeftText(LuaText.umg_bag_popup_3)
        self.PopUp4:SetBtnRightText(LuaText.umg_bag_popup_2)
        self:RefreshPopUpOnUseItemSuccess()
        self:LoadAnimation(0)
      end)
    elseif 1 == self.skipClosePanelType then
      self.skipClosePanelType = 0
      local PetSkillItemData = self.moduleData:GetCurSelectedPetSkillItemData()
      if PetSkillItemData and PetSkillItemData[1] and PetSkillItemData[1].gid and self.skillConfRec then
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenSkillOperationPanel, PetSkillItemData[1].gid, PetUIModuleEnum.PetSkillOperationType.Replacement, self.skillConfRec.id)
      end
      self:DoClose()
    else
      self.moduleData:SetCurSelectedPetSkillItemData(nil)
      self:DoClose()
    end
  elseif anim == self:GetAnimByIndex(0) then
    if self.Success then
      self.Success = false
    end
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

function UMG_Bag_PopUp_C:SetBagItemClickAble(clickable)
  self.List:SetItemClickAble(clickable)
end

return UMG_Bag_PopUp_C
