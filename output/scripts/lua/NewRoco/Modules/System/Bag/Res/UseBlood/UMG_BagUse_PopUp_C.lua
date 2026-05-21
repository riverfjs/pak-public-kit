local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_BagUse_PopUp_C = _G.NRCPanelBase:Extend("UMG_BagUse_PopUp_C")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
UMG_BagUse_PopUp_C.CloseEnum = {
  Cancel = 0,
  OK = 1,
  Change = 2,
  SuccessClose = 3,
  FantasticTip = 4
}

function UMG_BagUse_PopUp_C:OnConstruct()
  self:SetChildViews(self.PopUp4)
end

function UMG_BagUse_PopUp_C:OnDestruct()
end

function UMG_BagUse_PopUp_C:OnActive(Success, Param)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").OK
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
  if Param then
    self:SetRenderOpacity(0)
    self.param = Param
    self.Success = Success
    self.PetItemData = Param.PetData
    self.BagItem = Param.BagItem
    self.ChangeBlood = Param.ChangeBlood or self.PetItemData.blood_id
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.BagItem.id)
    self.BagItemConf = BagItemConf
    self:SetCommonPopUpInfo(self.PopUp4, BagItemConf.name, BagItemConf.icon, true)
    self:SetPetIcon()
    self:OnAddEventListener()
    local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.ChangeBlood)
    self.EmptyCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeadBloodIcon:SetPath(PetBloodConf.icon)
    if BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].use_action ~= Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS then
      if PetBloodConf.id == Enum.PetBloodType.PBT_FANTASTIC then
        local typeList = {}
        if PetBloodConf then
          table.insert(typeList, {
            Name = PetBloodConf.blood_name,
            Path = PetBloodConf.icon
          })
        end
        self.Attr7:InitGridView(typeList)
        self.QiyiBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      elseif PetBloodConf.id >= Enum.PetBloodType.PBT_BOSS then
        local typeList = {
          {
            Path = PetBloodConf.icon,
            Name = PetBloodConf.blood_name
          }
        }
        self.Attr4:InitGridView(typeList)
        local tipsDesc = self:GetBossBloodDesc()
        self.NRCText_78:SetText(tipsDesc)
        self.BossBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.PetItemData.base_conf_id)
        local typeList = {}
        if PetBloodConf then
          table.insert(typeList, {
            Name = PetBloodConf.blood_name,
            Path = PetBloodConf.icon
          })
        end
        self.Attr3:InitGridView(typeList)
        local skillConf = PetUtils.GetSkillBloodData(PetBloodConf.id, LevelSkillConf) or PetUtils.GetPetCurBloodSkillConf(self.PetItemData)
        if skillConf then
          local Name, Path
          self.ChangeSkillId = skillConf.id
          self.TxtSkillName_1:SetText(skillConf.name)
          self.SkillIcon_1:SetPath(skillConf.icon)
          if 1 ~= skillConf.damage_type then
            Name = tostring(skillConf.dam_para[1])
          else
            Name = "-"
          end
          self.TxtPnum_1:SetText(skillConf.energy_cost[1])
          local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
          if typeDic then
            Path = typeDic.tips_res
          end
          local SkillTypeList = {
            {Name = Name, Path = Path}
          }
          self.Attr6:InitGridView(SkillTypeList)
        end
        self.NormalBlood_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      local tipsDesc = self:GetBossBloodDesc()
      self.NRCText_78:SetText(tipsDesc)
      local typeList = {
        {
          Path = PetBloodConf.icon,
          Name = PetBloodConf.blood_name
        }
      }
      self.Attr4:InitGridView(typeList)
      self.BossBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:SetSuccessPanel()
    return
  end
  self.data = self.module:GetData("BagModuleData")
  if self.module.PetOpenUseAction then
    self.PopUp4:SetBtnLeftText("\229\143\150\230\182\136")
  else
    self.PopUp4:SetBtnLeftText("\230\155\180\230\141\162\231\178\190\231\129\181")
  end
  self.BagItem = self.data:GetCurSelectedItemData()
  if not self.BagItem then
    Log.Error("BagItem is nil")
    return
  end
  self.PetItemData = self.data.PetBloodItem
  self.CloseState = self.CloseEnum.Cancel
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.BagItem.id)
  self.BagItemConf = BagItemConf
  self:SetCommonPopUpInfo(self.PopUp4, BagItemConf.name, BagItemConf.icon)
  self:SetPetIcon()
  self:OnAddEventListener()
  if BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD then
    self.data.ChangeBlood = BagItemConf.item_behavior[1].ratio[1]
    self.ChangeBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS then
    self.data.ChangeBlood = Enum.PetBloodType.PBT_BOSS
    self.ChangeBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC then
    self.data.ChangeBlood = Enum.PetBloodType.PBT_FANTASTIC
    self.ChangeBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local pos1 = self.TxtSkillName_1.Slot:GetPosition()
    local pos2 = self.Attr6.Slot:GetPosition()
    pos1.x = 179.0
    pos2.x = 200.0
    self.TxtSkillName_1.Slot:SetPosition(pos1)
    self.Attr6.Slot:SetPosition(pos2)
    self.ChangeBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.data.ChangeBlood then
    local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.data.ChangeBlood)
    self.EmptyCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeadBloodIcon:SetPath(PetBloodConf.icon)
    if BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].use_action ~= Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS then
      if PetBloodConf.id == Enum.PetBloodType.PBT_FANTASTIC then
        local typeList = {}
        if PetBloodConf then
          table.insert(typeList, {
            Name = PetBloodConf.blood_name,
            Path = PetBloodConf.icon
          })
        end
        self.Attr7:InitGridView(typeList)
        self.QiyiBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      elseif PetBloodConf.id >= Enum.PetBloodType.PBT_BOSS then
        local typeList = {
          {
            Path = PetBloodConf.icon,
            Name = PetBloodConf.blood_name
          }
        }
        self.Attr4:InitGridView(typeList)
        local tipsDesc = self:GetBossBloodDesc()
        self.NRCText_78:SetText(tipsDesc)
        self.BossBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.PetItemData.base_conf_id)
        local typeList = {}
        if PetBloodConf then
          table.insert(typeList, {
            Name = PetBloodConf.blood_name,
            Path = PetBloodConf.icon
          })
        end
        self.Attr3:InitGridView(typeList)
        local skillConf = PetUtils.GetSkillBloodData(PetBloodConf.id, LevelSkillConf) or PetUtils.GetPetCurBloodSkillConf(self.PetItemData)
        if skillConf then
          local Name, Path
          self.ChangeSkillId = skillConf.id
          self.TxtSkillName_1:SetText(skillConf.name)
          self.SkillIcon_1:SetPath(skillConf.icon)
          if 1 ~= skillConf.damage_type then
            Name = tostring(skillConf.dam_para[1])
          else
            Name = "-"
          end
          self.TxtPnum_1:SetText(skillConf.energy_cost[1])
          local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
          if typeDic then
            Path = typeDic.tips_res
          end
          local SkillTypeList = {
            {Name = Name, Path = Path}
          }
          self.Attr6:InitGridView(SkillTypeList)
        end
        self.NormalBlood_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      local tipsDesc = self:GetBossBloodDesc()
      self.NRCText_78:SetText(tipsDesc)
      local typeList = {
        {
          Path = PetBloodConf.icon,
          Name = PetBloodConf.blood_name
        }
      }
      self.Attr4:InitGridView(typeList)
      self.BossBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.Success = Success
    if self.Success then
      self:SetUseSuccess()
    else
      local allTextStr = string.format(LuaText.all_nature_blood_attribute_chose, self.PetItemData.name, PetBloodConf.blood_name)
      if self.BagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS then
        allTextStr = string.format(LuaText.boss_blood_pet_chose, self.PetItemData.name)
      elseif self.BagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC then
        allTextStr = string.format(LuaText.fantastic_blood_pet_chose, self.PetItemData.name)
      end
      self.PopUp4:SetDescInfo(allTextStr)
    end
  else
    self.EmptyCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PopUp4:SetDescInfo("\232\175\183\233\128\137\230\139\169\233\156\128\232\166\129\228\191\174\230\148\185\231\154\132\232\161\128\232\132\137\229\177\158\230\128\167")
  end
  self:LoadAnimation(0)
  self:BindInputAction()
end

function UMG_BagUse_PopUp_C:SetPetIcon()
  self.NumText:SetText(self.PetItemData.level)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.PetItemData.base_conf_id)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    if modelConf then
      self.PetHeadIcon:SetIconPathAndMaterial(self.PetItemData.base_conf_id, self.PetItemData.mutation_type, self.PetItemData.glass_info)
    end
  end
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.PetItemData.blood_id)
  local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.PetItemData.base_conf_id)
  if PetBloodConf.id == Enum.PetBloodType.PBT_BOSS then
    self.NormalBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BossBlood_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local typeList = {
      {
        Path = PetBloodConf.icon,
        Name = PetBloodConf.blood_name
      }
    }
    self.Attr2:InitGridView(typeList)
    local tipsDesc = self:GetBossBloodDesc()
    self.NRCText_1:SetText(tipsDesc)
  else
    self.NormalBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BossBlood_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local typeList = {}
    if PetBloodConf then
      table.insert(typeList, {
        Name = PetBloodConf.blood_name,
        Path = PetBloodConf.icon
      })
    end
    self.Attr1:InitGridView(typeList)
    local skillConf
    if PetBloodConf.id == Enum.PetBloodType.PBT_FANTASTIC then
      local skill_data = self.PetItemData.skill.skill_data
      for _, skill in pairs(skill_data) do
        if skill.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
          skillConf = _G.DataConfigManager:GetSkillConf(skill.id)
          break
        end
      end
    else
      skillConf = PetUtils.GetSkillBloodData(PetBloodConf.id, LevelSkillConf) or PetUtils.GetPetCurBloodSkillConf(self.PetItemData)
    end
    if skillConf then
      local Name, Path
      self.SkillId = skillConf.id
      self.TxtSkillName:SetText(skillConf.name)
      self.SkillIcon:SetPath(skillConf.icon)
      if 1 ~= skillConf.damage_type then
        Name = tostring(skillConf.dam_para[1])
      else
        Name = "-"
      end
      self.TxtPnum:SetText(skillConf.energy_cost[1])
      local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
      if typeDic then
        Path = typeDic.tips_res
      end
      local SkillTypeList = {
        {Name = Name, Path = Path}
      }
      self.Attr5:InitGridView(SkillTypeList)
    end
  end
end

function UMG_BagUse_PopUp_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon, HideBtn)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  if HideBtn then
    CommonPopUpData.HideBtn = true
  else
    CommonPopUpData.Btn_LeftHandler = self.OnCancelOrClose
    CommonPopUpData.Btn_RightHandler = self.OnOK
  end
  CommonPopUpData.ClosePanelHandler = self.CloseBtnClick
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_BagUse_PopUp_C:GetBossBloodDesc()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.PetItemData.base_conf_id)
  local BossPetBaseId = petBaseConf.bosspetbase_id_arry[1]
  local BossPetBaseConf = _G.DataConfigManager:GetPetbaseConf(BossPetBaseId)
  local tipsDesc = ""
  if BossPetBaseConf then
    tipsDesc = string.format(LuaText.boss_blood_explain_1, BossPetBaseConf.name)
  end
  return tipsDesc
end

function UMG_BagUse_PopUp_C:OnDeactive()
end

function UMG_BagUse_PopUp_C:OnAddEventListener()
  self:AddButtonListener(self.Tipsbtn, self.OpenTips)
  self:AddButtonListener(self.ChangeBtn, self.ChangeBtnClick)
  self:AddButtonListener(self.ChangeSkillBtn, self.ChangeSkillBtnClick)
  self:AddButtonListener(self.SkillBtn, self.SkillBtnClick)
end

function UMG_BagUse_PopUp_C:OnCancelOrClose()
  if self.Success then
    self.data.PetBloodItem = nil
    self.data.ChangeBlood = nil
    if self.PopUp4.Btn_Left.Title_2:GetText() == LuaText.skill_change_title_1 then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenSkillOperationPanel, self.PetItemData.gid, PetUIModuleEnum.PetSkillOperationType.Replacement, self.changeSkillId)
      self:DoClose()
      return
    end
    if self.module.IsPetInfoMainToPanel then
      local openPetData, index, bIsRevertMainPanel = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
      if not openPetData then
        bIsRevertMainPanel = true
      end
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.EnablePanelPetMain)
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.PetItemData.gid)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 1, bIsRevertMainPanel, 1)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.RefreshPetRightPanel, true)
      _G.NRCModuleManager:DoCmd(BagModuleCmd.CloseBagMainPanel)
    else
      if self.PetItemData and self.curPetLevelSkillConf and self.PetItemData.level < self.curPetLevelSkillConf.blood_skill_level_point or 0 == self.changeSkillId then
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsBagToOpenPanel)
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.PetItemData.gid)
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 1, false, 1)
        NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
          subPanelIndex = 4,
          callback = self.OnUMGLoadFinished
        })
      end
      self:DoClose()
    end
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_Bag_BXTips_C:OnClose")
    self.CloseState = self.CloseEnum.Cancel
    self:LoadAnimation(2)
  end
end

function UMG_BagUse_PopUp_C:SetSuccessPanel()
  self.Success = true
  self.PopUp4:SetBtnLeftText("\230\159\165\231\156\139\231\178\190\231\129\181")
  self.PopUp4:SetTitleTextInfo("\228\189\191\231\148\168\230\136\144\229\138\159")
  self.HeadBloodIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.ChangeBlood)
  local allTextStr
  if self.ChangeBlood == Enum.PetBloodType.PBT_BOSS then
    allTextStr = string.format(LuaText.boss_blood_pet_changed, self.PetItemData.name, PetBloodConf.blood_name)
  elseif PetBloodConf then
    allTextStr = string.format(LuaText.all_nature_blood_changed, self.PetItemData.name, PetBloodConf.blood_name)
  end
  local typeList = {}
  if PetBloodConf then
    table.insert(typeList, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
  end
  self.Attr3:InitGridView(typeList)
  local skillConf
  local skill_data = self.PetItemData.skill.skill_data
  if skill_data then
    for _, skill in pairs(skill_data) do
      if skill.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
        skillConf = _G.DataConfigManager:GetSkillConf(skill.id)
        break
      end
    end
  end
  if skillConf then
    local Name, Path
    self.ChangeSkillId = skillConf.id
    self.TxtSkillName_1:SetText(skillConf.name)
    self.SkillIcon_1:SetPath(skillConf.icon)
    if 1 ~= skillConf.damage_type then
      Name = tostring(skillConf.dam_para[1])
    else
      Name = "-"
    end
    self.TxtPnum_1:SetText(skillConf.energy_cost[1])
    local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
    if typeDic then
      Path = typeDic.tips_res
    end
    local SkillTypeList = {
      {Name = Name, Path = Path}
    }
    self.Attr6:InitGridView(SkillTypeList)
  end
  self.QiyiBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PopUp4:SetDescInfo(allTextStr)
  if self.ChangeBlood >= Enum.PetBloodType.PBT_BOSS and self.ChangeBlood ~= Enum.PetBloodType.PBT_FANTASTIC then
    self.NormalBlood_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BossBlood:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Attr4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.BossUse, self.BossUse:GetEndTime())
  elseif self.ChangeBlood == Enum.PetBloodType.PBT_FANTASTIC then
    self.NormalBlood_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BossBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IconCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_new:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Normal_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.fx:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_9:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.QiUse_0, self.QiUse_0:GetEndTime())
  else
    self.NormalBlood_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BossBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IconCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_new:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Use, self.Use:GetEndTime())
  end
end

function UMG_BagUse_PopUp_C:SkillIsEquip(skillId)
  if self.PetItemData then
    local posToIdDic, dataType = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetEquipSkillMap, self.PetItemData.gid)
    if posToIdDic then
      for pos, id in ipairs(posToIdDic) do
        if id == skillId then
          return true
        end
      end
    end
  end
  return false
end

function UMG_BagUse_PopUp_C:SkillIsLearned(skillId)
  if self.PetItemData then
    for i, v in ipairs(self.PetItemData.skill.skill_data) do
      if v.is_learned and v.id == skillId then
        return true
      end
    end
  end
  return false
end

function UMG_BagUse_PopUp_C:AutoEquipSkillHandle(skillId)
  if not self:SkillIsLearned(skillId) then
    return false
  end
  if self.PetItemData then
    if self:SkillIsEquip(skillId) then
      return false
    end
    local canEquip = false
    local posToIdDic, dataType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, self.PetItemData.gid)
    for i = 1, 4 do
      if posToIdDic and (not posToIdDic[i] or 0 == posToIdDic[i]) then
        posToIdDic[i] = skillId
        canEquip = true
        break
      end
    end
    if canEquip then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AutoCheckEnvironmentEquipPetSkill, self.PetItemData.gid, posToIdDic)
      return true
    end
  end
  return false
end

function UMG_BagUse_PopUp_C:SetUseSuccess()
  if not self.data or not self.data.PetBloodItem then
    Log.Error("UMG_BagUse_PopUp_C:SetUseSuccess(): PetBloodItem is nil")
    return
  end
  self.PetItemData = self.data.PetBloodItem
  self.Success = true
  self.changeSkillId = 0
  self.curPetLevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.PetItemData.base_conf_id)
  local ChangeBloodSkillConf
  if self.curPetLevelSkillConf then
    ChangeBloodSkillConf = PetUtils.GetSkillBloodData(self.data.ChangeBlood, self.curPetLevelSkillConf) or PetUtils.GetPetCurBloodSkillConf(self.PetItemData)
    if ChangeBloodSkillConf then
      self.changeSkillId = ChangeBloodSkillConf.id
    end
  end
  self.HeadBloodIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.data.ChangeBlood)
  local allTextStr
  if self.data.ChangeBlood == Enum.PetBloodType.PBT_BOSS then
    allTextStr = string.format(LuaText.boss_blood_pet_changed, self.PetItemData.name, PetBloodConf.blood_name)
  elseif self.data.ChangeBlood == Enum.PetBloodType.PBT_FANTASTIC then
    allTextStr = string.format(LuaText.fantastic_blood_pet_changed, self.PetItemData.name, PetBloodConf.blood_name)
  else
    allTextStr = string.format(LuaText.all_nature_blood_changed, self.PetItemData.name, PetBloodConf.blood_name)
  end
  local autoEquipSkill = self:AutoEquipSkillHandle(self.changeSkillId)
  if autoEquipSkill or self:SkillIsEquip(self.changeSkillId) then
    if ChangeBloodSkillConf then
      if self.data.ChangeBlood > 18 then
        allTextStr = string.format(LuaText.UMG_Bag_PopUp14, self.PetItemData.name, PetBloodConf.blood_name, ChangeBloodSkillConf.name)
      else
        allTextStr = string.format(LuaText.UMG_Bag_PopUp11, self.PetItemData.name, PetBloodConf.blood_name, ChangeBloodSkillConf.name)
      end
    end
    self.PopUp4:ShowOrHideBtnLeft(false)
    self.PopUp4:ShowOrHideBtnRight(false)
  elseif self.PetItemData.level < self.curPetLevelSkillConf.blood_skill_level_point and self.data.ChangeBlood ~= Enum.PetBloodType.PBT_BOSS then
    if self.data.ChangeBlood > 18 then
      allTextStr = string.format(LuaText.UMG_Bag_PopUp15, self.PetItemData.name, PetBloodConf.blood_name, self.curPetLevelSkillConf.blood_skill_level_point)
    else
      allTextStr = string.format(LuaText.UMG_Bag_PopUp4, self.PetItemData.name, PetBloodConf.blood_name, self.curPetLevelSkillConf.blood_skill_level_point)
    end
    self.PopUp4:SetBtnLeftText(LuaText.UMG_PetHatching_end)
    self.PopUp4:SetTitleTextInfo(LuaText.BAG_USE_ITEM_SUCCESS)
  elseif ChangeBloodSkillConf then
    if self.data.ChangeBlood > 18 then
      allTextStr = string.format(LuaText.UMG_Bag_PopUp13, self.PetItemData.name, PetBloodConf.blood_name, ChangeBloodSkillConf.name)
    else
      allTextStr = string.format(LuaText.UMG_Bag_PopUp12, self.PetItemData.name, PetBloodConf.blood_name, ChangeBloodSkillConf.name)
    end
    self.PopUp4:SetBtnLeftText(LuaText.skill_change_title_1)
    self.PopUp4:SetTitleTextInfo(LuaText.skill_unlock_title_6)
  else
    self.PopUp4:SetBtnLeftText(LuaText.UMG_PetHatching_end)
    self.PopUp4:SetTitleTextInfo(LuaText.skill_unlock_title_6)
  end
  local pos1 = self.TxtSkillName_1.Slot:GetPosition()
  local pos2 = self.Attr6.Slot:GetPosition()
  pos1.x = 299.0
  pos2.x = 315.0
  self.TxtSkillName_1.Slot:SetPosition(pos1)
  self.Attr6.Slot:SetPosition(pos2)
  if self.data.ChangeBlood == Enum.PetBloodType.PBT_FANTASTIC then
    local typeList = {}
    if PetBloodConf then
      table.insert(typeList, {
        Name = PetBloodConf.blood_name,
        Path = PetBloodConf.icon
      })
    end
    self.Attr3:InitGridView(typeList)
    local skillConf
    local skill_data = self.PetItemData.skill.skill_data
    for _, skill in pairs(skill_data) do
      if skill.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
        skillConf = _G.DataConfigManager:GetSkillConf(skill.id)
        break
      end
    end
    if skillConf then
      local Name, Path
      self.ChangeSkillId = skillConf.id
      self.TxtSkillName_1:SetText(skillConf.name)
      self.SkillIcon_1:SetPath(skillConf.icon)
      if 1 ~= skillConf.damage_type then
        Name = tostring(skillConf.dam_para[1])
      else
        Name = "-"
      end
      self.TxtPnum_1:SetText(skillConf.energy_cost[1])
      local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
      if typeDic then
        Path = typeDic.tips_res
      end
      local SkillTypeList = {
        {Name = Name, Path = Path}
      }
      self.Attr6:InitGridView(SkillTypeList)
    end
    self.NormalBlood_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.PopUp4:SetDescInfo(allTextStr)
  if self.data.ChangeBlood >= Enum.PetBloodType.PBT_BOSS and self.data.ChangeBlood ~= Enum.PetBloodType.PBT_FANTASTIC then
    self.Attr4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.BossUse)
  elseif self.data.ChangeBlood == Enum.PetBloodType.PBT_FANTASTIC then
    self.IconCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Normal_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.fx:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_9:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.QiUse_0)
  else
    self.IconCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Use)
  end
  if self.PetItemData.level < self.curPetLevelSkillConf.blood_skill_level_point and self.data.ChangeBlood ~= Enum.PetBloodType.PBT_FANTASTIC then
    self.NRCImage_new:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCImage_new:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BagUse_PopUp_C:OnOK()
  if self.Success then
    self.CloseState = self.CloseEnum.SuccessClose
    self:LoadAnimation(2)
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Bag_BXTips_C:OnClose")
    if not self.data.ChangeBlood then
      local tipsStr = LuaText.all_nature_blood_attribute_not_choose
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipsStr)
    elseif self.PetItemData.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
      self.CloseState = self.CloseEnum.FantasticTip
      self:LoadAnimation(2)
    else
      self.module:SetChangePetGid(self.PetItemData.gid)
      self.module:ChangePetBloodSuccess()
    end
  end
end

function UMG_BagUse_PopUp_C:PopUpOpenHandler()
  self:LoadAnimation(0)
end

function UMG_BagUse_PopUp_C:PopUpHandler()
  self.module:SetChangePetGid(self.PetItemData.gid)
  self.module:ChangePetBloodSuccess()
end

function UMG_BagUse_PopUp_C:ChangeBtnClick()
  self.CloseState = self.CloseEnum.Change
  self:LoadAnimation(2)
end

function UMG_BagUse_PopUp_C:ChangeSkillBtnClick()
  if self.ChangeSkillId then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenBagSKillTips, self.ChangeSkillId, false)
  end
end

function UMG_BagUse_PopUp_C:SkillBtnClick()
  if self.SkillId then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenBagSKillTips, self.SkillId, false)
  end
end

function UMG_BagUse_PopUp_C:OpenTips()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.ShowChangePetConfirm, self.PetItemData)
end

function UMG_BagUse_PopUp_C:CloseBtnClick()
  if self.Success then
    self.CloseState = self.CloseEnum.SuccessClose
  else
    self.CloseState = self.CloseEnum.Cancel
  end
  self:LoadAnimation(2)
end

function UMG_BagUse_PopUp_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    if self.param then
      self:DoClose()
      return
    end
    if self.CloseState == self.CloseEnum.Cancel then
      self.data.ChangeBlood = nil
      _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.BagBloodPopup, false)
    elseif self.CloseState == self.CloseEnum.Change then
      _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.BagBloodChange, true)
    elseif self.CloseState == self.CloseEnum.FantasticTip then
      local remindData = _G.NRCCommonPopUpData()
      remindData.ContentText = LuaText.fantastic_blood_change_confirm
      remindData.RemindSwitch = 0
      remindData.Btn_LeftText = LuaText.CANCEL
      remindData.Btn_RightText = LuaText.tips_dialog_butten_accept
      remindData.PopUpOpenHandler = self.PopUpOpenHandler
      remindData.PopUpHandler = self.PopUpHandler
      remindData.Call = self
      _G.NRCModeManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, remindData)
    elseif self.CloseState == self.CloseEnum.SuccessClose then
      self.data.PetBloodItem = nil
      self.data.ChangeBlood = nil
      self:DoClose()
    end
  end
  if Animation == self.Use or Animation == self.BossUse or Animation == self.QiUse_0 then
    if self.param then
      self:SetRenderOpacity(1)
    end
    self.NormalBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BossBlood_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.QiyiBlood:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ChangeBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Arrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BagUse_PopUp_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_BagUsePopUp")
  if mappingContext then
    mappingContext:BindAction("IA_CloseBagUsePopUp", self, "OnPcClose2")
  end
end

function UMG_BagUse_PopUp_C:OnPcClose2()
  self:CloseBtnClick()
end

return UMG_BagUse_PopUp_C
