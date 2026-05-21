local UMG_ReplacementSkills_C = _G.NRCPanelBase:Extend("UMG_ReplacementSkills_C")
local enum = reload("Data.Config.Enum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")

function UMG_ReplacementSkills_C:OnConstruct()
  self:SetChildViews(self.PopUp4)
  self:OnAddEventListener()
  self:SetCommonPopUpInfo()
end

function UMG_ReplacementSkills_C:OnActive(petGid, operationType, operationSkillId)
  self:LoadAnimation(0)
  self:PlayAnimation(self.open)
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if not self.petData then
    Log.Error("Get PetData is nil, petGid\239\188\154" .. petGid)
    return
  end
  self.btnClickLock = false
  self.OnOperationSuccess = false
  self.operationType = operationType
  self.operationSkill = nil
  self.operationSkillConf = nil
  self.toOperationSkillList = {}
  self.toOperationSkill = nil
  self.toOperationConf = nil
  self.OperationEnvironment = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetCurEquipSkillType, self.petData.gid)
  if self.petData.skill.skill_data then
    for i, v in ipairs(self.petData.skill.skill_data) do
      v.notSelect = false
      if v.id == operationSkillId then
        self.operationSkill = table.deepCopy(v)
        self.operationSkillConf = _G.DataConfigManager:GetSkillConf(v.id)
      end
      if self.OperationEnvironment == PetUIModuleEnum.PetEquipSkillType.PetBag and v.is_equipped and v.pos > 0 and v.pos < 5 then
        if operationType == PetUIModuleEnum.PetSkillOperationType.Exchange then
          if v.id ~= operationSkillId then
            table.insert(self.toOperationSkillList, table.deepCopy(v))
          end
        else
          table.insert(self.toOperationSkillList, table.deepCopy(v))
        end
      end
    end
  end
  local posToIdDic = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, self.petData.gid)
  local opSkillPos, toOpSkillList = self:GetOpSkillAndToOpSkillList(operationSkillId, posToIdDic)
  if opSkillPos then
    self.operationSkill.pos = opSkillPos
  end
  self.toOperationSkillList = toOpSkillList
  if #self.toOperationSkillList > 1 then
    table.sort(self.toOperationSkillList, function(a, b)
      return a.pos < b.pos
    end)
  end
  if operationType == PetUIModuleEnum.PetSkillOperationType.Exchange then
    self:ExchangeSkillRefresh()
  elseif operationType == PetUIModuleEnum.PetSkillOperationType.Replacement then
    self:ReplacementSkillRefresh()
  end
  self:RefreshCommonPopUpInfo()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    if modelConf then
      local data = {
        IconListInfo = self.petData.level,
        gid = self.petData.gid,
        PetIcon = modelConf,
        IsTeamPet = false,
        PetBasicProperty = petBaseConf.quality,
        PetBaseId = self.petData.base_conf_id,
        mutation_typ = self.petData.mutation_type,
        glass_info = self.petData.glass_info
      }
      self.PopUp4.PetList:OnItemUpdate(data)
      self.PopUp4.ItemSwitcher:SetActiveWidgetIndex(1)
      self.PopUp4.ItemSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_ReplacementSkills_C:GetOpSkillAndToOpSkillList(opSkillId, posToIdDic)
  local opSkillPos
  local toOpSkillList = {}
  if posToIdDic then
    for pos, id in pairs(posToIdDic) do
      if self.operationType == PetUIModuleEnum.PetSkillOperationType.Exchange then
        if id ~= opSkillId then
          table.insert(toOpSkillList, {
            is_equipped = true,
            id = id,
            pos = pos
          })
        end
      else
        table.insert(toOpSkillList, {
          is_equipped = true,
          id = id,
          pos = pos
        })
      end
      if opSkillId == id then
        opSkillPos = pos
      end
    end
  end
  return opSkillPos, toOpSkillList
end

function UMG_ReplacementSkills_C:OnDeactive()
  self:RemoveAllButtonListener()
  self:UnRegisterAllEvent()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnOperationSuccessStar)
  _G.NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnPetSkillChanged, self.OnOperationSuccessStar)
end

function UMG_ReplacementSkills_C:OnAddEventListener()
  self:AddButtonListener(self.OpenSkillDetailsBtn, self.OpenSkillDetailsBtnClick)
  self:AddButtonListener(self.OpenSkillDetailsBtn_1, self.OpenSkillDetailsBtn2)
  self:RegisterEvent(self, PetUIModuleEvent.EQUIP_SKILL_SUCCESS, self.OnOperationSuccessStar)
  self:RegisterEvent(self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnOperationSuccessStar)
  _G.NRCEventCenter:RegisterEvent("UMG_ReplacementSkills_C", self, PetUIModuleEvent.PvpPetTeamEquipPetSkills, self.OnOperationSuccessStar)
  _G.NRCEventCenter:RegisterEvent("UMG_ReplacementSkills_C", self, WeeklyChallengeBattleModuleEvent.OnPetSkillChanged, self.OnOperationSuccessStar)
end

function UMG_ReplacementSkills_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnClose
  CommonPopUpData.Btn_LeftHandler = self.OnClose
  CommonPopUpData.Btn_RightHandler = self.OnConFirm
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp4:SetPanelInfo(CommonPopUpData)
  self.PopUp4.Btn_Left.Title_1:SetText(LuaText.umg_dialog_1)
  self.PopUp4.Btn_Right_GrayState:SetIsEnabled(false)
  self.PopUp4.Btn_Right_GrayState.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ReplacementSkills_C:RefreshCommonPopUpInfo(operationOver)
  if operationOver then
    local title, tips, rightBtnTxt = ""
    if self.operationType == PetUIModuleEnum.PetSkillOperationType.Exchange then
      title = LuaText.skill_change_title_4
      if self.operationSkill and self.operationSkill.pos then
        tips = string.format(LuaText.skill_change_tips_6, self.operationSkill.pos, self.toOperationSkill.pos)
      end
      rightBtnTxt = LuaText.skill_change_text_2
    elseif self.operationType == PetUIModuleEnum.PetSkillOperationType.Replacement then
      title = LuaText.skill_change_title_2
      tips = string.format(LuaText.skill_change_tips_3, self.toOperationSkill.pos, self.toOperationConf.name, (self.operationSkillConf or {}).name or "")
      rightBtnTxt = LuaText.skill_change_text_1
    end
    self.PopUp4:SetTitleTextInfo(title)
    self.PopUp4:SetDescInfo(tips)
    self.PopUp4:SetBtnRightText(rightBtnTxt)
    self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp4.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local title, tips, rightBtnTxt = ""
    if self.operationType == PetUIModuleEnum.PetSkillOperationType.Exchange then
      title = LuaText.skill_change_title_3
      if self.toOperationSkill ~= nil and self.operationSkill ~= nil then
        tips = string.format(LuaText.skill_change_tips_5, self.operationSkill.pos, (self.operationSkillConf or {}).name or "", self.toOperationSkill.pos, self.toOperationConf.name)
        rightBtnTxt = LuaText.skill_change_text_2
      else
        tips = LuaText.skill_change_tips_4
        rightBtnTxt = LuaText.skill_change_text_2
      end
    elseif self.operationType == PetUIModuleEnum.PetSkillOperationType.Replacement then
      title = LuaText.skill_change_title_1
      if self.toOperationSkill ~= nil then
        tips = string.format(LuaText.skill_change_tips_2, self.toOperationSkill.pos, self.toOperationConf.name, (self.operationSkillConf or {}).name or "")
        rightBtnTxt = LuaText.skill_change_text_1
      else
        tips = LuaText.skill_change_tips_1
        rightBtnTxt = LuaText.skill_change_text_1
      end
    end
    self.PopUp4:SetTitleTextInfo(title)
    self.PopUp4:SetDescInfo(tips)
    self.PopUp4:SetBtnRightText(rightBtnTxt)
    self.PopUp4.Btn_Right_GrayState:SetBtnText(rightBtnTxt)
    if self.toOperationSkill == nil then
      self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Visible)
      self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_ReplacementSkills_C:ExchangeSkillRefresh()
  self.Switcher:SetActiveWidgetIndex(0)
  self.operationSkill.notSelect = true
  self.Item:InitGridView({
    self.operationSkill
  })
  self.ItemList1:InitGridView(self.toOperationSkillList)
end

function UMG_ReplacementSkills_C:ReplacementSkillRefresh()
  self.Switcher:SetActiveWidgetIndex(1)
  self.ItemList2:InitGridView(self.toOperationSkillList)
end

function UMG_ReplacementSkills_C:OpenSkillDetailsBtnClick()
  if self.toOperationConf then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBagSKillTips, self.toOperationConf.id)
  end
end

function UMG_ReplacementSkills_C:OpenSkillDetailsBtn2()
  if self.operationSkillConf then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBagSKillTips, self.operationSkillConf.id)
  end
end

function UMG_ReplacementSkills_C:OnOperationSuccessStar()
  self.btnClickLock = false
  self.skipClosePanelType = 1
  self:OnClose()
end

function UMG_ReplacementSkills_C:OnOperationSuccessHandle()
  self:StopAllAnimations()
  self:LoadAnimation(0)
  self:PlayAnimation(self.open)
  self.OnOperationSuccess = true
  self:RefreshCommonPopUpInfo(true)
  if self.operationType == PetUIModuleEnum.PetSkillOperationType.Exchange then
    local pos = self.operationSkill.pos
    self.operationSkill.pos = self.toOperationSkill.pos
    self.toOperationSkill.pos = pos
    table.insert(self.toOperationSkillList, self.operationSkill)
    if #self.toOperationSkillList > 1 then
      table.sort(self.toOperationSkillList, function(a, b)
        return a.pos < b.pos
      end)
    end
    for i, v in pairs(self.toOperationSkillList) do
      v.notSelect = true
    end
    self:ReplacementSkillRefresh()
  elseif self.operationType == PetUIModuleEnum.PetSkillOperationType.Replacement then
    self.Number:SetText(self.toOperationSkill.pos)
    self.Number_1:SetText(self.toOperationSkill.pos)
    local skillConf = self.toOperationConf
    if skillConf then
      self.TxtSkillName:SetText(skillConf.name)
      self.SkillIcon:SetPath(skillConf.icon)
      self.TxtPnum:SetText(skillConf.energy_cost[1])
      local Name, Path
      if skillConf.damage_type == enum.DamageType.DT_NONE then
        Name = "--"
      else
        Name = skillConf.dam_para[1]
      end
      local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
      if typeDic then
        Path = typeDic.tips_res
      end
      local typeList = {
        {Name = Name, Path = Path}
      }
      self.Attr:InitGridView(typeList)
    end
    local skillConf2 = self.operationSkillConf
    if skillConf2 then
      self.TxtSkillName_1:SetText(skillConf2.name)
      self.SkillIcon_1:SetPath(skillConf2.icon)
      self.TxtPnum_1:SetText(skillConf2.energy_cost[1])
      local Name, Path
      if skillConf2.damage_type == enum.DamageType.DT_NONE then
        Name = "--"
      else
        Name = skillConf2.dam_para[1]
      end
      local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf2.skill_dam_type)
      if typeDic then
        Path = typeDic.tips_res
      end
      local typeList = {
        {Name = Name, Path = Path}
      }
      self.Attr_1:InitGridView(typeList)
    end
    self.Switcher:SetActiveWidgetIndex(2)
  end
end

function UMG_ReplacementSkills_C:OnClose()
  if self and UE4.UObject.IsValid(self) then
    if self.PopUp4.IsLock then
      self.PopUp4:SetLock(false)
    end
    self:LoadAnimation(2)
    self:PlayAnimation(self.close)
  end
end

function UMG_ReplacementSkills_C:OnConFirm()
  if self.btnClickLock then
    return
  end
  if self.petData and self.toOperationSkill and self.operationSkill then
    local skillIds = {}
    if self.operationType == PetUIModuleEnum.PetSkillOperationType.Exchange then
      for i, v in ipairs(self.toOperationSkillList) do
        if v.id == self.toOperationSkill.id then
          skillIds[v.pos] = self.operationSkill.id
        else
          skillIds[v.pos] = v.id
        end
      end
      skillIds[self.operationSkill.pos] = self.toOperationSkill.id
    elseif self.operationType == PetUIModuleEnum.PetSkillOperationType.Replacement then
      for i, v in ipairs(self.toOperationSkillList) do
        if v.id == self.toOperationSkill.id then
          skillIds[v.pos] = self.operationSkill.id
        else
          skillIds[v.pos] = v.id
        end
      end
    end
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AutoCheckEnvironmentEquipPetSkill, self.petData.gid, skillIds)
    if self.OperationEnvironment == PetUIModuleEnum.PetEquipSkillType.Assumption then
      self:OnOperationSuccessStar()
    else
      self.btnClickLock = true
    end
  end
end

function UMG_ReplacementSkills_C:OnSelectSkillOperationItem(skillId)
  if self.OnOperationSuccess then
    return
  end
  local hasSkillId = false
  for i, v in ipairs(self.toOperationSkillList) do
    if v.id == skillId then
      hasSkillId = true
      self.toOperationSkill = v
    end
  end
  if not hasSkillId then
    return
  end
  self.toOperationConf = _G.DataConfigManager:GetSkillConf(self.toOperationSkill.id)
  if not self.toOperationConf then
    Log.Error("\230\138\128\232\131\189id\230\178\161\230\156\137\233\133\141\231\189\174:" .. self.toOperationSkill.id)
    return
  end
  self:RefreshCommonPopUpInfo()
end

function UMG_ReplacementSkills_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if 1 == self.skipClosePanelType then
      self.skipClosePanelType = 0
      self:OnOperationSuccessHandle()
    else
      self:DoClose()
    end
  end
end

return UMG_ReplacementSkills_C
