local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_Battle_Operate_C = NRCPanelBase:Extend("UMG_Battle_Operate_C")
local inputActionInfoListWhenIsShow = {
  {
    name = "IA_BattleSkillStart",
    method = "SelectSkillOperateStart"
  },
  {
    name = "IA_BattleRunAwayStart",
    method = "SelectRunAwayOperateStart"
  },
  {
    name = "IA_BattleChangeStart",
    method = "SelectChangeOperateStart"
  },
  {
    name = "IA_BattleBagStart",
    method = "SelectBagOperateStart"
  },
  {
    name = "IA_BattleCatchStart",
    method = "SelectCatchOperateStart"
  },
  {
    name = "IA_BattleRunAwayEnd",
    method = "SelectRunAwayOperateEnd"
  },
  {
    name = "IA_BattleBagEnd",
    method = "SelectBagOperateEnd"
  },
  {
    name = "IA_BattleCatchEnd",
    method = "SelectCatchOperateEnd"
  },
  {
    name = "IA_BattleChangeEnd",
    method = "SelectChangeOperateEnd"
  },
  {
    name = "IA_BattleSkillEnd",
    method = "SelectSkillOperateEnd"
  }
}

function UMG_Battle_Operate_C:Construct()
  self.curIndex = -1
  self.battleManager = _G.BattleManager
  self.bindActionSucceed = false
  self.toggles = {
    [self.BtnEscape.CheckBoxName] = {
      index = 0,
      toggle = self.BtnEscape
    },
    [self.ItemToggle.CheckBoxName] = {
      index = 1,
      toggle = self.ItemToggle
    },
    [self.CatchToggle.CheckBoxName] = {
      index = 2,
      toggle = self.CatchToggle
    },
    [self.ChangePetToggle.CheckBoxName] = {
      index = 3,
      toggle = self.ChangePetToggle
    },
    [self.SkillToggle.CheckBoxName] = {
      index = 4,
      toggle = self.SkillToggle
    },
    [self.SurrenderToggle.CheckBoxName] = {
      index = 5,
      toggle = self.SurrenderToggle
    },
    [self.ItemToggle_1.CheckBoxName] = {
      index = 6,
      toggle = self.ItemToggle_1
    },
    [self.StepAwayToggle.CheckBoxName] = {
      index = 7,
      toggle = self.StepAwayToggle
    },
    [self.GiveUpToggle.CheckBoxName] = {
      index = 8,
      toggle = self.GiveUpToggle
    }
  }
  self.ClickAnimName = {
    self.Click_EscapePanel,
    self.Click_Item,
    self.Click_Catch,
    self.Click_changePet,
    self.Click_Skill,
    self.Click_Surrender,
    self.Click_Item1,
    self.Click_StepAway,
    self.Click_GiveUp
  }
  self.UnClickAnimName = {
    self.Unclick_EscapePanel,
    self.Unclick_Item,
    self.Unclick_Catch,
    self.Unclick_changePet,
    self.Unclick_Skill,
    self.Unclick_Surrender,
    self.UnClick_Item1,
    self.Unclick_StepAway,
    self.Unclick_GiveUp
  }
  self.SelectImage = {
    self.NRCImage_1,
    self.NRCImage_2,
    self.NRCImage_59,
    self.NRCImage_3,
    self.NRCImage_4,
    self.NRCImage,
    self.NRCImage,
    self.NRCImage_5,
    self.NRCImage_6
  }
  self.OperateName = {
    self.TextBlock_3,
    self.TextBlock_2,
    self.TextBlock_1,
    self.TextBlock,
    self.TextBlock_367,
    self.TextBlock_4,
    self.TextBlock_4,
    self.TextBlock_5,
    self.TextBlock_6
  }
  self.AllowChange = true
  self.IsPlayAnimDaoju = false
  self.IsPlayerSkillSuccess = false
  self.BeginUsePlayerSkill = false
  self.IsDeath = false
  self.guid = nil
  self.CurPet = nil
  self.FirstOpen = false
  self:RefreshPanel()
  self:AddListener()
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_PLAYERSKILL, BattleEvent.BATTLE_CLICKED_UI_CANCELPLAYERSKILL, BattleEvent.UI_HIDE, BattleEvent.BATTLE_USE_PLAYERSKILL_SUCCESS, BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL, BattleEvent.TEAM_BATTLE_CATCH, BattleEvent.RefreshVisitCatch, BattleEvent.BATTLE_PET_DIE, BattleEvent.ROUND_START, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.UI_UPDATE_PLAYERSKILL_TUTORIAL, BattleEvent.REFRESH_BUFF, BattleEvent.REMOVE_BUFF)
  _G.NRCEventCenter:RegisterEvent("UMG_Battle_Operate_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  self.conditionList = {}
  self.isForceToggle = false
end

function UMG_Battle_Operate_C:SetNameRenderOpacity()
  for i, Name in ipairs(self.OperateName) do
    Name:SetRenderOpacity(0.7)
  end
end

function UMG_Battle_Operate_C:SetGuid(_guid, pet)
  self.guid = _guid
  self.CurPet = pet
  self:UpdateChangeBanImage()
  self:UpdateBuffType145Image(_guid)
end

function UMG_Battle_Operate_C:RefreshPanel()
  self.changeToRunAway = false
  self:PCKeySetting()
  self:UpdateCatchPanel()
  self:UpdateItemPanel()
  self:UpdateSurrenderPanel()
  self:SetIsCanChangePet()
  self.BtnEscape:SetVisibility(UE4.ESlateVisibility.Visible)
  self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  self:UpdateChangeBanImage()
  self:CheckToFinalBattleMode()
  self:CheckB1FinalBattleP2UI()
end

function UMG_Battle_Operate_C:UpdateChangeBanImage()
  if not self.IsCanChange or not self.ChangeBanImage then
    return
  end
  if BattleUtils.IsPvpScare() then
    local changePetConfig = BattleUtils.GetCanChangePetConfig()
    if changePetConfig > 2 then
      self.ChangePetButton:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ChangeBanImage:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.ChangePetToggle:SetVisibility(UE4.ESlateVisibility.Visible)
    elseif 2 == changePetConfig then
      self.ChangePetButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ChangeBanImage:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ChangePetToggle:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.ChangePetButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ChangeBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ChangePetToggle:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  else
    self.ChangePetButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if BattleUtils.HasLockChangePetState(self.CurPet) then
      self.ChangeBanImage:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ChangePetToggle:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.ChangeBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ChangePetToggle:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_Battle_Operate_C:UpdateBuffType145Image(petId)
  if self.guid ~= petId then
    return
  end
  local battlePet = self.CurPet
  local battleCard = battlePet and battlePet.card
  local buffComponent = battlePet and battlePet.buffComponent
  local buffs = buffComponent and buffComponent:GetAllBuffsByOrderType(ProtoEnum.BuffType.BFT_O_FORTYFIVE) or {}
  local buffsListCount = #buffs
  if buffsListCount > 0 then
    self.showBuffType145Ui = true
  else
    self.showBuffType145Ui = false
  end
end

function UMG_Battle_Operate_C:PCKeySetting()
  self:SetUpPCKey()
end

function UMG_Battle_Operate_C:SetUpPCKey()
  if SystemSettingModuleCmd then
    if self.PCKey_1 then
      self.PCKey_1:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSkillStart")
      if "" ~= image then
        self.PCKey_1:SetImageMode(image)
      else
        self.PCKey_1:SetText(text)
      end
    end
    if self.PCKey then
      self.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleChangeStart")
      if "" ~= image then
        self.PCKey:SetImageMode(image)
      else
        self.PCKey:SetText(text)
      end
    end
    if self.PCKey_2 then
      self.PCKey_2:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleCatchStart")
      if "" ~= image then
        self.PCKey_2:SetImageMode(image)
      else
        self.PCKey_2:SetText(text)
      end
    end
    if self.PCKey_3 then
      self.PCKey_3:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleBagStart")
      if "" ~= image then
        self.PCKey_3:SetImageMode(image)
      else
        self.PCKey_3:SetText(text)
      end
    end
    if self.PCKey_5 then
      self.PCKey_5:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleRunAwayStart")
      if "" ~= image then
        self.PCKey_5:SetImageMode(image)
      else
        self.PCKey_5:SetText(text)
      end
    end
    if self.PCKey_4 then
      self.PCKey_4:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleRunAwayStart")
      if "" ~= image then
        self.PCKey_4:SetImageMode(image)
      else
        self.PCKey_4:SetText(text)
      end
    end
  end
end

function UMG_Battle_Operate_C:UpdateSurrenderPanel()
  if BattleUtils.IsEscapeBattleMode() then
    if BattleUtils.IsCrowdBattle() and 1 == _G.DataConfigManager:GetBattleGlobalConfig("1vn_battle_surrender").num then
      self.Surrender:SetVisibility(UE4.ESlateVisibility.Visible)
      self.SurrenderToggle:SetVisibility(UE4.ESlateVisibility.Visible)
      self.EscapePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BtnEscape:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Surrender:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.SurrenderToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.EscapePanel:SetVisibility(UE4.ESlateVisibility.Visible)
      self.BtnEscape:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  else
    self.Surrender:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SurrenderToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.EscapePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnEscape:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Operate_C:SetIsCanChangePet()
  if BattleUtils.IsTeam() or BattleUtils.IsPvpScare() and not BattleUtils.IsCanChangePetBattleMode() then
    self:IsCanChangePet(false)
  else
    self:IsCanChangePet(true)
  end
end

function UMG_Battle_Operate_C:IsCanChangePet(_IsCanChange)
  if not self.ChangePanel then
    return
  end
  self.IsCanChange = _IsCanChange
  if _IsCanChange then
    self.ChangePanel:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ChangePetToggle:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ChangePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ChangePetToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Operate_C:UpdateCatchPanel()
  Log.Debug(BattleUtils.IsCatchBattleMode(), "UMG_Battle_Operate_C:UpdateCatchPanel")
  if not UE.UObject.IsValid(self) then
    return
  end
  if self.isDestruct then
    return
  end
  if (BattleUtils.IsTeam() or not BattleUtils.IsCatchBattleMode()) and not BattleManager.IsTeamBossToCatch then
    self.CatchPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.CatchToggle then
      self.CatchToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.CatchPanel:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.CatchToggle then
      self.CatchToggle:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_Battle_Operate_C:UpdateItemPanel()
  if not UE.UObject.IsValid(self) then
    return
  end
  if BattleUtils.IsUseItemBattleMode() then
    self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ItemToggle:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ItemToggle_1:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemToggle_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Operate_C:SwitchToRidOfSelectPet()
  self.Surrender:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CatchPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Operate_C:SwitchToRunAway()
  self.changeToRunAway = true
  self.ChangePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CatchPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Operate_C:SwitchToWatchBattleMode()
  self.EscapePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Operate_C:IsChangeItemToggleState(_IsChange)
  if _IsChange then
    self.ItemToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemToggle_1:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ItemToggle:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ItemToggle_1:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Battle_Operate_C:WaitingRecycle()
  self:UnBindInputAction()
  self:RemoveListener()
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.BattleEventCenter:UnBind(self)
end

function UMG_Battle_Operate_C:Destruct()
  Log.Debug("UMG_Battle_Operate_C Destruct")
  self:RemoveListener()
  if self.toggles then
    for _, item in pairs(self.toggles) do
      item.toggle = nil
    end
  end
  table.clear(self.toggles)
  self.toggles = nil
  self:UnBindInputAction()
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.BattleEventCenter:UnBind(self)
  NRCUmgClass.Destruct(self)
end

function UMG_Battle_Operate_C:OnBattleEvent(eventName, ...)
  if self.isDestruct or not UE.UObject.IsValid(self) then
    return
  end
  if eventName == BattleEvent.BATTLE_CLICKED_PLAYERSKILL then
    self:OnClickedPlayerSkill()
  elseif eventName == BattleEvent.BATTLE_CLICKED_UI_CANCELPLAYERSKILL then
    self:OnCancelPlayerSkill()
  elseif eventName == BattleEvent.UI_HIDE then
    self:OnCancelPlayerSkill()
  elseif eventName == BattleEvent.BATTLE_USE_PLAYERSKILL_SUCCESS then
    self:PlayerSkillSuccess()
  elseif eventName == BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL then
    self:SetBeginUsePlayerSkill()
  elseif eventName == BattleEvent.TEAM_BATTLE_CATCH then
    if self.changeToRunAway then
      self:RefreshPanel()
    end
    self:UpdateOperationPanel()
  elseif eventName == BattleEvent.RefreshVisitCatch then
    self:UpdateCatchPanel()
  elseif eventName == BattleEvent.BATTLE_PET_DIE then
    if BattleUtils.IsWorldLeaderFight() then
      self:IsCanChangePet(true)
    end
  elseif eventName == BattleEvent.ROUND_START then
    if not self.bInitVisitCatch then
      self:UpdateCatchPanel()
    end
    if BattleUtils.GetEnemyIsNightMare() then
      if BattleUtils.GetEnemyHasNightMareShield() then
        self:BanCatch()
      else
        self:CanCatch()
      end
    else
      self:CanCatch()
    end
    self:CheckFinalBattleEnergyIsFull()
  elseif eventName == BattleEvent.CHANGE_OPERATE_TYPE then
    self:PlaySelectAnimation(...)
  elseif eventName == BattleEvent.UI_UPDATE_PLAYERSKILL_TUTORIAL then
    self:OnUpdatePlayerSkillTutorial(...)
  elseif eventName == BattleEvent.REFRESH_BUFF or eventName == BattleEvent.REMOVE_BUFF then
    local battlePet = (...)
    local battleCard = battlePet and battlePet.card
    local petId = battleCard and battleCard.guid
    self:UpdateChangeBanImage()
    self:UpdateBuffType145Image(petId)
  end
end

function UMG_Battle_Operate_C:PlayClose()
  self:StopAnimation(self.open)
  self:PlayAnimation(self.close)
end

function UMG_Battle_Operate_C:PlayOpen()
  if not self.SelectImage then
    return
  end
  local Index = self.curIndex
  if self.curIndex >= 0 then
    self:ShowSelectImage(Index + 1)
  end
  self:StopAnimation(self.close)
  self:PlayAnimation(self.open)
  local currDisplay = self.showBuffType145UiDisplay or false
  local nextDisplay = self.showBuffType145Ui or false
  self.showBuffType145UiDisplay = nextDisplay
  if currDisplay ~= nextDisplay then
    if not currDisplay and nextDisplay then
      self.Arrow:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.Arrow_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.ChangePanel_Highlight)
    elseif currDisplay and not nextDisplay then
      self.Arrow:SetVisibility(UE.ESlateVisibility.Collapsed)
      self.Arrow_1:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Battle_Operate_C:PlayCallingNamesEffect()
  self:PlayAnimation(self.BagHighlight_Loop, 0, 0)
end

function UMG_Battle_Operate_C:StopCallingNamesEffect()
  if self:IsAnimationPlaying(self.BagHighlight_Loop) then
    self:StopAnimation(self.BagHighlight_Loop)
  end
end

function UMG_Battle_Operate_C:PlaySelectAnimation(Index)
  Log.Debug(Index, self.curIndex, self.ClickAnimName[Index + 1], "UMG_Battle_Operate_C:PlaySelectAnimation")
  if not self:IsAnimationPlaying(self.open) then
    if self.ClickAnimName[Index + 1] then
      if self:IsAnimationPlaying(self.UnClickAnimName[Index + 1]) then
        self:StopAnimation(self.UnClickAnimName[Index + 1])
      end
      self:PlayAnimation(self.ClickAnimName[Index + 1])
    end
  elseif self.SelectImage[Index + 1] then
    self:ShowSelectImage(Index + 1)
  end
end

function UMG_Battle_Operate_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Battle_Operate_C:ShowSelectImage(Index)
  Log.Debug(self.curIndex, Index, "UMG_Battle_Operate_C:ShowSelectImage")
  self.SelectImage[Index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SelectImage[Index]:SetRenderOpacity(1)
end

function UMG_Battle_Operate_C:PlayUnClickAnima(Index)
  Log.Debug(Index, self.curIndex, self.UnClickAnimName[Index + 1], "UMG_Battle_Operate_C:PlayUnClickAnima")
  if self.UnClickAnimName[Index + 1] then
    if self:IsAnimationPlaying(self.ClickAnimName[Index + 1]) then
      self:StopAnimation(self.ClickAnimName[Index + 1])
    end
    self:PlayAnimation(self.UnClickAnimName[Index + 1])
    self.OperateName[Index + 1]:SetRenderOpacity(0.7)
  end
end

function UMG_Battle_Operate_C:UpdateOperationPanel()
  self.IsDeath = true
  self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ChangePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ChangePetToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SkillToggle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CatchPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CatchToggle:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.CatchToggle:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.CatchToggle:BindLuaCallBack({
      self,
      self.OnToggleGroupChanged
    }, {
      self,
      self.OnCheckBoxCondition
    })
  end
  _G.BattleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_CATCH)
  if BattleUtils.IsBeastTeam() then
    self:SwitchToLegendaryCatch()
  end
end

function UMG_Battle_Operate_C:InitializePlayerSkill()
  local pet = _G.BattleManager.battlePawnManager:GetPetByGuid(self.guid)
  if not pet then
    return
  end
  local player = pet.player
  if player and player.roleInfo and player.roleInfo.magic_op_info and player.roleInfo.magic_op_info.player_skill_id and self.guid == player.roleInfo.magic_op_info.pet_id and BattleUtils.GetFBCallNameMagicId() ~= player.roleInfo.magic_op_info.player_skill_id then
    self.IsPlayAnimDaoju = true
    self:PlayerSkillSuccess()
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_RECOVER_PLAYERSKILL)
  end
end

function UMG_Battle_Operate_C:OnClickedPlayerSkill()
  self.IsPlayAnimDaoju = true
end

function UMG_Battle_Operate_C:OnCancelPlayerSkill()
  self.IsPlayAnimDaoju = false
  self.IsPlayerSkillSuccess = false
  if self:IsPlayingAnimation() then
    self:PlayAnimation(self.ChangeBack_daoju)
  end
end

function UMG_Battle_Operate_C:ChangeOpeRate(curIndex)
  if self.IsPlayAnimDaoju and not self.IsPlayerSkillSuccess and not self.BeginUsePlayerSkill then
    self:OnCancelPlayerSkill()
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CANCEL_USE_PLAYERSKILL, curIndex)
  end
end

function UMG_Battle_Operate_C:PlayerSkillSuccess()
  self.IsPlayerSkillSuccess = true
  if not self:IsPlayingAnimation() then
    self:PlayAnimation(self.Change_daoju)
  end
end

function UMG_Battle_Operate_C:SetBeginUsePlayerSkill()
  self.BeginUsePlayerSkill = true
  self:PlayAnimation(self.Change_daoju)
end

function UMG_Battle_Operate_C:BindInputAction()
  if self.bindActionSucceed then
    return
  end
  local mappingContext = self:GetInputMappingContext(BattleConst.ImcBattleName)
  if mappingContext then
    local actions = inputActionInfoListWhenIsShow or {}
    for _, action in ipairs(actions) do
      local name = action and action.name
      local method = action and action.method
      mappingContext:BindAction(name, self, method, UE.ETriggerEvent.Triggered)
    end
    self.bindActionSucceed = true
  else
    self.bindActionSucceed = false
  end
end

function UMG_Battle_Operate_C:recordInputActionTrigger(inputActionName)
  self.triggerInputActionName = inputActionName
end

function UMG_Battle_Operate_C:UnBindInputAction()
  if not self.bindActionSucceed then
    return
  end
  local mappingContext = self:GetInputMappingContext(BattleConst.ImcBattleName)
  if mappingContext then
    local actions = inputActionInfoListWhenIsShow or {}
    for _, action in ipairs(actions) do
      local name = action and action.name
      mappingContext:UnBindAction(name)
    end
    self.bindActionSucceed = false
  end
end

function UMG_Battle_Operate_C:SelectSkillOperateStart()
  if self.toggles == nil then
    return
  end
  if self.SkillPanel:GetVisibility() == UE4.ESlateVisibility.Visible then
    if self.triggerInputActionName then
      return
    else
      _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER, "IA_BattleSkillStart")
    end
    self.SkillToggle:OnNRCCheckBoxIsClickableCallback(true)
  end
end

function UMG_Battle_Operate_C:SelectChangeOperateStart()
  if self.toggles == nil then
    return
  end
  if self.ChangePanel:GetVisibility() == UE4.ESlateVisibility.Visible then
    if BattleUtils.HasLockChangePetState(self.CurPet) then
      return
    end
    if self.triggerInputActionName then
      return
    else
      _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER, "IA_BattleChangeStart")
    end
    self.ChangePetToggle:OnNRCCheckBoxIsClickableCallback(true)
  end
end

function UMG_Battle_Operate_C:SelectCatchOperateStart()
  if self.toggles == nil then
    return
  end
  if UE4.UObject.IsValid(self.CatchToggle) and UE4.UObject.IsValid(self.CatchPanel) and self.CatchPanel:GetVisibility() == UE4.ESlateVisibility.Visible then
    if self.CatchBanImage:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and self.CatchBanImage:GetVisibility() ~= UE4.ESlateVisibility.Hidden then
      self:BanCatchBtnClick()
      return
    end
    if self.triggerInputActionName then
      return
    else
      _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER, "IA_BattleCatchStart")
    end
    self.CatchToggle:OnNRCCheckBoxIsClickableCallback(true)
  end
end

function UMG_Battle_Operate_C:SelectBagOperateStart()
  if self.toggles == nil then
    return
  end
  if self.ItemPanel:GetVisibility() == UE4.ESlateVisibility.Visible then
    if self.triggerInputActionName then
      return
    else
      _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER, "IA_BattleBagStart")
    end
    self.ItemToggle:OnNRCCheckBoxIsClickableCallback(true)
  end
end

function UMG_Battle_Operate_C:SelectRunAwayOperateStart()
  if self.toggles == nil then
    return
  end
  if self.triggerInputActionName then
    return
  else
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER, "IA_BattleRunAwayStart")
  end
  if UE4.UObject.IsValid(self.EscapePanel) and UE4.UObject.IsValid(self.BtnEscape) and UE4.UObject.IsValid(self.StepAwayPanel) then
    if self.EscapePanel:GetVisibility() == UE4.ESlateVisibility.Visible and self.BtnEscape:GetVisibility() == UE4.ESlateVisibility.Visible then
      self.BtnEscape:OnNRCCheckBoxIsClickableCallback(true)
    elseif self.StepAwayPanel:GetVisibility() == UE4.ESlateVisibility.Visible then
      self.StepAwayToggle:OnNRCCheckBoxIsClickableCallback(true)
    end
  end
end

function UMG_Battle_Operate_C:SelectSkillOperateEnd()
  if self.toggles == nil then
    return
  end
  if self.triggerInputActionName ~= "IA_BattleSkillStart" then
    return
  end
  if not self.conditionList[4] then
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  self.SkillToggle:SetCheckBoxState(true)
end

function UMG_Battle_Operate_C:SelectChangeOperateEnd()
  if self.toggles == nil then
    return
  end
  if self.ChangePanel:GetVisibility() == UE4.ESlateVisibility.Visible then
    if self.triggerInputActionName ~= "IA_BattleChangeStart" then
      return
    end
    if not self.conditionList[3] then
      _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
      return
    end
    self.ChangePetToggle:SetCheckBoxState(true)
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
end

function UMG_Battle_Operate_C:SelectCatchOperateEnd()
  if self.toggles == nil then
    return
  end
  if self.triggerInputActionName ~= "IA_BattleCatchStart" then
    return
  end
  if not self.conditionList[2] then
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  self.CatchToggle:SetCheckBoxState(true)
end

function UMG_Battle_Operate_C:SelectBagOperateEnd()
  if self.toggles == nil then
    return
  end
  if self.triggerInputActionName ~= "IA_BattleBagStart" then
    return
  end
  if not self.conditionList[1] then
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  self.ItemToggle:SetCheckBoxState(true)
end

function UMG_Battle_Operate_C:SelectRunAwayOperateEnd()
  if self.toggles == nil then
    return
  end
  if self.triggerInputActionName ~= "IA_BattleRunAwayStart" then
    return
  end
  if not self.conditionList[0] and not self.conditionList[7] then
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  if self.EscapePanel:GetVisibility() == UE4.ESlateVisibility.Visible and self.BtnEscape:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.BtnEscape:SetCheckBoxState(true)
  elseif self.StepAwayPanel:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.StepAwayToggle:SetCheckBoxState(true)
  end
end

function UMG_Battle_Operate_C:AddListener()
  self.BtnEscape:BindLuaCallBack({
    self,
    self.OnToggleGroupChanged
  }, {
    self,
    self.OnCheckBoxCondition
  })
  if self.ItemToggle:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.ItemToggle:BindLuaCallBack({
      self,
      self.OnToggleGroupChanged
    }, {
      self,
      self.OnCheckBoxCondition
    })
    self.ItemToggle_1:BindLuaCallBack({
      self,
      self.OnToggleGroupChanged
    }, {
      self,
      self.OnCheckBoxCondition
    })
  end
  if self.CatchToggle:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.CatchToggle:BindLuaCallBack({
      self,
      self.OnToggleGroupChanged
    }, {
      self,
      self.OnCheckBoxCondition
    })
  end
  self.ChangePetToggle:BindLuaCallBack({
    self,
    self.OnToggleGroupChanged
  }, {
    self,
    self.OnCheckBoxCondition
  })
  self.SkillToggle:BindLuaCallBack({
    self,
    self.OnToggleGroupChanged
  }, {
    self,
    self.OnCheckBoxCondition
  })
  if self.SurrenderToggle:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.SurrenderToggle:BindLuaCallBack({
      self,
      self.OnToggleGroupChanged
    }, {
      self,
      self.OnCheckBoxCondition
    })
  end
  if self.StepAwayToggle:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.StepAwayToggle:BindLuaCallBack({
      self,
      self.OnToggleGroupChanged
    }, {
      self,
      self.OnCheckBoxCondition
    })
  end
  if self.GiveUpToggle:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.GiveUpToggle:BindLuaCallBack({
      self,
      self.OnToggleGroupChanged
    }, {
      self,
      self.OnCheckBoxCondition
    })
  end
  if self.BanCatchClickBtn.OnClicked then
    self.BanCatchClickBtn.OnClicked:Add(self, self.BanCatchBtnClick)
  else
    Log.Error("self.BanCatchClickBtn.OnClicked \228\184\186\231\169\186")
  end
  if self.ChangePetButton.OnClicked then
    self.ChangePetButton.OnClicked:Add(self, self.OnChangePetClick)
  else
    Log.Error("self.ChangePetButton.OnClicked \228\184\186\231\169\186")
  end
end

function UMG_Battle_Operate_C:GetToggleByIndex(index)
  if self.toggles then
    for _, value in pairs(self.toggles) do
      if value.index == index then
        return value.toggle
      end
    end
  end
end

function UMG_Battle_Operate_C:RemoveListener()
  if not self.isRemoveListener then
    self.toggles = {}
    self.BtnEscape:DoDestruct()
    self.ItemToggle:DoDestruct()
    self.CatchToggle:DoDestruct()
    self.ChangePetToggle:DoDestruct()
    self.SkillToggle:DoDestruct()
    self.SurrenderToggle:DoDestruct()
    self.ItemToggle_1:DoDestruct()
    self.StepAwayToggle:DoDestruct()
    self.GiveUpToggle:DoDestruct()
    if self.BanCatchClickBtn and self.BanCatchClickBtn.OnClicked then
      self.BanCatchClickBtn.OnClicked:Remove(self, self.BanCatchBtnClick)
    end
    if self.ChangePetButton and self.ChangePetButton.OnClicked then
      self.ChangePetButton.OnClicked:Remove(self, self.OnChangePetClick)
    end
    self.isRemoveListener = true
  end
end

function UMG_Battle_Operate_C:Show()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Battle_Operate_C:Hide()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.curIndex >= 0 then
    self:GetToggleByIndex(self.curIndex).SetCheckBoxState(false)
    self.curIndex = -1
  end
end

function UMG_Battle_Operate_C:SetSkillCheckedState()
  self:PlayUnClickAnima(self.curIndex)
  self.SkillToggle:SetCheckedState(UE4.ECheckBoxState.Unchecked)
end

function UMG_Battle_Operate_C:ChangeToIndex(index)
  Log.Debug(index, self.curIndex, "UMG_Battle_Operate_C:ChangeToIndex")
  self.isForceToggle = true
  if self.curIndex ~= index then
    local lastToggle = self:GetToggleByIndex(self.curIndex)
    if lastToggle then
      self:PlayUnClickAnima(self.curIndex)
      lastToggle:SetCheckBoxState(false)
    end
    self.curIndex = index
    local toggle = self:GetToggleByIndex(index)
    if toggle then
      toggle:SetCheckBoxState(true)
      _G.BattleEventCenter:Dispatch(BattleEvent.CHANGE_OPERATE_TYPE, self.curIndex, true)
    else
      self.NoneToggle:SetCheckBoxState(true)
    end
  else
    _G.BattleEventCenter:Dispatch(BattleEvent.CHANGE_OPERATE_TYPE, self.curIndex, true)
  end
  self.isForceToggle = false
end

function UMG_Battle_Operate_C:ConditionalShow()
  if not self.FirstOpen then
    self.FirstOpen = true
  end
  self:InitializePlayerSkill()
  self:HideAllBanImage()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Battle_Operate_C:HideAllBanImage()
  self:UpdateChangeBanImage()
  if not self.IsDeath and BattleUtils.IsTeam() and BattleUtils.TeamIsCanCatch() then
    self.CatchBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.SkillBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.EscapeBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SurrenderBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.StepAwayBanImage_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.GiveUpBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Operate_C:OnCheckBoxCondition(GroupId, CheckBoxName, IsClickable)
  Log.Debug(CheckBoxName, "UMG_Battle_Operate_C:OnCheckBoxCondition")
  local toggle = self.toggles[CheckBoxName].toggle
  local Index = self.toggles[CheckBoxName].index
  self.conditionList[Index] = nil
  if BattleUtils.IsWatchingBattle() and not BattleUtils.BattleOperationIsAllowInCurrentWatchingBattleMode(Index) then
    toggle:SetIsClickable(false)
    return false
  end
  if Index == BattleEnum.Operation.ENUM_ESCAPE or Index == BattleEnum.Operation.ENUM_SURRENDER or Index == BattleEnum.Operation.ENUM_STEPAWAY or Index == BattleEnum.Operation.ENUM_GIVEUP then
    self.conditionList[Index] = true
    toggle:SetIsClickable(true)
    return true
  end
  if Index == BattleEnum.Operation.ENUM_CHANGE then
    local ret, msg = BattleUtils.CheckCanChangePet()
    if not ret and msg then
      self.conditionList[Index] = nil
      toggle:SetIsClickable(false)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, msg)
    else
      self.conditionList[Index] = true
      toggle:SetIsClickable(true)
    end
    return ret
  end
  if not self.AllowChange then
    self.conditionList[Index] = nil
    toggle:SetIsClickable(false)
    return false
  end
  if Index == BattleEnum.Operation.ENUM_CATCH then
    local ret, msg = BattleUtils.CheckCanCatchMonster()
    if not ret and msg then
      self.conditionList[Index] = nil
      toggle:SetIsClickable(false)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, msg)
    else
      self.conditionList[Index] = true
      toggle:SetIsClickable(true)
    end
    return ret
  else
    self.conditionList[Index] = true
    toggle:SetIsClickable(true)
    return true
  end
end

function UMG_Battle_Operate_C:FocusOnCurOperate()
  self.AllowChange = false
end

function UMG_Battle_Operate_C:FreeOperate()
  self.AllowChange = true
end

function UMG_Battle_Operate_C:OnToggleGroupChanged(GroupId, CheckBoxName)
  Log.Debug(self.curIndex, "UMG_Battle_Operate_C:OnToggleGroupChanged")
  _G.BattleEventCenter:Dispatch(BattleEvent.OnBallChanged, 100002)
  local toggle = self.toggles[CheckBoxName].toggle
  local isChecked = toggle.CheckedState == UE4.ECheckBoxState.Checked
  if isChecked then
    local selfRes = self.curIndex
    self.curIndex = self.toggles[CheckBoxName].index
    if "ItemToggle" == CheckBoxName or "ItemToggle_1" == CheckBoxName then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008036, "UMG_Battle_Operate_C:OnToggleGroupChanged")
      self.curIndex = self.toggles.ItemToggle.index
      self.ItemClick:PlaySelectAnimation()
    elseif "CatchToggle" == CheckBoxName then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1028, "UMG_Battle_Operate_C:OnToggleGroupChanged")
      self.CatchClick:PlaySelectAnimation()
      _G.NRCModuleManager:DoCmd(NewbieGuideModuleCmd.BtnClick, "CatchToggleGuide")
    elseif "ChangePetToggle" == CheckBoxName then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1021, "UMG_Battle_Operate_C:OnToggleGroupChanged")
      self.PetClick:PlaySelectAnimation()
    elseif "SkillToggle" == CheckBoxName then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1022, "UMG_Battle_Operate_C:OnToggleGroupChanged")
      self.SkillClick:PlaySelectAnimation()
    elseif "BtnEscape" == CheckBoxName then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1023, "UMG_Battle_Operate_C:OnToggleGroupChanged")
      self.EscapeClick:PlaySelectAnimation()
    elseif "SurrenderToggle" == CheckBoxName then
      self.SurrenderClick:PlaySelectAnimation()
    elseif "StepAwayToggle" == CheckBoxName then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1023, "UMG_Battle_Operate_C:OnToggleGroupChanged")
      self.StepAwayClick:PlaySelectAnimation()
    elseif "GiveUpToggle" == CheckBoxName then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1023, "UMG_Battle_Operate_C:OnToggleGroupChanged")
      self.GiveUpClick:PlaySelectAnimation()
    end
    if selfRes == self.toggles[CheckBoxName].index then
      return
    end
    self:ChangeOpeRate(self.curIndex)
  else
    if "ItemToggle" == CheckBoxName or "ItemToggle_1" == CheckBoxName then
      self.ItemClick:PlayUnselectAnimation()
    elseif "CatchToggle" == CheckBoxName then
      self.CatchClick:PlayUnselectAnimation()
    elseif "ChangePetToggle" == CheckBoxName then
      self.PetClick:PlayUnselectAnimation()
    elseif "SkillToggle" == CheckBoxName then
      self.SkillClick:PlayUnselectAnimation()
    elseif "BtnEscape" == CheckBoxName then
      self.EscapeClick:PlayUnselectAnimation()
    elseif "SurrenderToggle" == CheckBoxName then
      self.SurrenderClick:PlayUnselectAnimation()
    elseif "StepAwayToggle" == CheckBoxName then
      self.StepAwayClick:PlayUnselectAnimation()
    elseif "GiveUpToggle" == CheckBoxName then
      self.GiveUpClick:PlayUnselectAnimation()
    end
    self:PlayUnClickAnima(self.curIndex)
    self.curIndex = -1
  end
  if not self.isForceToggle then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.HideBattlePopupPanel)
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.CHANGE_OPERATE_TYPE, self.curIndex, isChecked, self.IsPlayerSkillSuccess)
end

function UMG_Battle_Operate_C:OnAnimationFinished(Animation)
  if Animation == self.Change_daoju then
    self.BeginUsePlayerSkill = false
    self:PlayAnimation(self.DaojuLizi, 0, 99999)
  elseif Animation == self.ChangeBack_daoju then
    self:StopAnimation(self.DaojuLizi)
  elseif self.curIndex > 0 and (Animation == self.ClickAnimName[self.curIndex + 1] or Animation == self.open) and not self:IsAnimationPlaying(self.open) then
    self.OperateName[self.curIndex + 1]:SetRenderOpacity(1)
  end
  if Animation == self.Click_Skill and not self.hasShowFinalBattleTutorial1 and BattleUtils.IsFinalBattleP1() and 2 == self.battleManager.battleRuntimeData.roundIndex then
    self.hasShowFinalBattleTutorial1 = true
    NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowFinalBattleTutorial1)
  end
end

function UMG_Battle_Operate_C:SwitchToLegendaryCatch()
  self.StepAwayPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CatchPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  self.EscapePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Surrender:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ChangePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Operate_C:BanCatch()
  self.isCanCatch = false
  self.CatchBanImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.BanCatchClickBtn:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Battle_Operate_C:CanCatch()
  self.CatchBanImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.BanCatchClickBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Operate_C:BanCatchBtnClick()
  if self.visitCanCatch == false then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetGlobalConfig("visit_catch_number_notice").str)
  elseif BattleUtils.CheckEnemyIsSurpriseBoxPet() then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.cant_cache_box_elite_in_battle)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.cant_cache_nightmare_elite_in_battle)
  end
end

function UMG_Battle_Operate_C:OnChangePetClick()
  local changePetConfig = BattleUtils.GetCanChangePetConfig()
  if changePetConfig >= 3 then
    local tipKey = BattleUtils.GetChangePetTipKey(BattleUtils.GetCanChangePetConfig())
    local tipText = _G.DataConfigManager:GetLocalizationConf(tipKey, true)
    if tipText and tipText.msg then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipText.msg)
    else
      tipKey = BattleUtils.GetChangePetTipKey(3)
      tipText = _G.DataConfigManager:GetLocalizationConf(tipKey, true)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipText.msg)
    end
    return
  end
end

function UMG_Battle_Operate_C:CheckToFinalBattleMode()
  if BattleUtils.IsFinalBattle() then
    self.StepAwayPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CatchPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.GiveUpPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Surrender:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ChangePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Visible)
    if BattleUtils.IsFinalBattleP1() then
      self.EscapePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Visible)
    elseif BattleUtils.IsFinalBattleP2() then
      self.EscapePanel:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Battle_Operate_C:CheckB1FinalBattleP2UI()
  if not BattleUtils.IsB1FinalBattleP2() and not BattleUtils.IsB1FinalBattleP3() then
    return
  end
  self.StepAwayPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CatchPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.GiveUpPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.EscapePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Surrender:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ChangePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Battle_Operate_C:CheckFinalBattleEnergyIsFull()
  if BattleUtils.CheckFinalBattleEnergyIsFull() then
    self.SkillPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Operate_C:OnUpdatePlayerSkillTutorial(showPlayerSkillTutorialHighLight)
  if showPlayerSkillTutorialHighLight then
    self.ItemTutorialHighLightLoader:LoadPanel()
  else
    local itemTutorialHighLight = self.ItemTutorialHighLightLoader:GetPanel()
    if itemTutorialHighLight then
      itemTutorialHighLight:Hide()
    end
    self.ItemTutorialHighLightLoader:UnLoadPanel()
  end
end

return UMG_Battle_Operate_C
