local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_Pet_GroupWarfare_C = _G.NRCPanelBase:Extend("UMG_Pet_GroupWarfare_C")

function UMG_Pet_GroupWarfare_C:OnConstruct()
  self.TeammateHPList = {
    self.GroupWarfare_Item,
    self.GroupWarfare_Item1,
    self.GroupWarfare_Item2,
    self.GroupWarfare_Item3
  }
  for _, TeammateHP in ipairs(self.TeammateHPList) do
    TeammateHP:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.OwnPet = nil
  self.IsDead = false
  self.EnemySkillList = {}
  self.WaitPlayAddOrRemoveSkillAnim = {}
  self.BattlePetList = {}
  self.petTypeIcons = {
    self.Attr1_1,
    self.Attr2_1
  }
  self.TypePanel = {
    self.SizeBox1,
    self.SizeBox2
  }
  self.TypeIconBg = {
    self.PetTypeBg1,
    self.PetTypeBg2
  }
  self.genderIcons = {
    self.ImagePetGender2,
    self.ImagePetGender1
  }
  self.List_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:OnAddEventListener()
  self.Department1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Department2:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pet_GroupWarfare_C:WaitingRecycle()
  self.UMG_Pet_ProgressBar_Big:WaitingRecycle()
  self:OnRemoveEventListener()
end

function UMG_Pet_GroupWarfare_C:OnDestruct()
  if _G.OpenRecordSkillList then
    self:SaveText()
  end
  table.clear(self.TeammateHPList)
  table.clear(self.petTypeIcons)
  table.clear(self.TypePanel)
  table.clear(self.TypeIconBg)
  self.TeammateHPList = nil
  self.petTypeIcons = nil
  self.TypePanel = nil
  self.TypeIconBg = nil
  self.BattlePetList = nil
  self.EnemySkillList = nil
  self.WaitPlayAddOrRemoveSkillAnim = nil
  self.OwnPet = nil
  self.IsDead = nil
  self.EnemySkillList = nil
  self:OnRemoveEventListener()
end

function UMG_Pet_GroupWarfare_C:OnAddEventListener()
  self:AddButtonListener(self.BtnRechristen_1, self.OnBtnRechristen_1Click)
  self:AddButtonListener(self.BloodBtn, self.OnBloodBtn)
  _G.BattleEventCenter:Bind(self, BattleEvent.PLAYER_CHOOSE_SKILL, BattleEvent.PLAYER_PERFORM_OVER, BattleEvent.TEAM_BATTLE_CATCH, BattleEvent.BATTLE_PET_DIE, BattleEvent.Replay_RefreshRoundIdx, BattleEvent.BLOOD_SHOW_MONEY, BattleEvent.BLOOD_HIDE_MONEY, BattleEvent.HIDE_TEAM_HP, BattleEvent.PET_SPAWNED, BattleEvent.HIDE_TEAMBATTLE_HP, BattleEvent.SHOW_TEAMBATTLE_HP, BattleEvent.TEAM_SWAP_SELECT_START, BattleEvent.UPDATE_TEAMBOSS_HP, BattleEvent.PLAYER_LEAVE_GAME)
  self:AddButtonListener(self.HeadIconBtn, self.OnOpenPetTips)
end

function UMG_Pet_GroupWarfare_C:OnRemoveEventListener()
  _G.BattleEventCenter:UnBind(self)
  self:RemoveButtonListener(self.HeadIconBtn, self.OnOpenPetTips)
end

function UMG_Pet_GroupWarfare_C:OnActive()
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.Text_reminder:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self:IsPCMode() then
    self:PCModeScreenSetting()
  end
  self:SetRecoveryItemInfo()
  self:TryInitData()
end

function UMG_Pet_GroupWarfare_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PLAYER_CHOOSE_SKILL then
    self:ShowEnemySkillListByChooseSkill(...)
  elseif eventName == BattleEvent.PLAYER_PERFORM_OVER then
    self:UpdateEnemySkillList(...)
  elseif eventName == BattleEvent.TEAM_BATTLE_CATCH then
    self:ShowTipTime()
    self:ShowCatchInfo()
  elseif eventName == BattleEvent.BATTLE_PET_DIE then
    self:PetDleUpdatePanel(...)
  elseif eventName == BattleEvent.Replay_RefreshRoundIdx then
    self:UpdateRound(...)
  elseif eventName == BattleEvent.HIDE_TEAM_HP then
    self:HideHp()
  elseif eventName == BattleEvent.PET_SPAWNED then
    self:OnPetSpawnEvent(...)
  elseif eventName == BattleEvent.HIDE_TEAMBATTLE_HP then
    self:HideTeamBattleHp()
  elseif eventName == BattleEvent.SHOW_TEAMBATTLE_HP then
    self:ShowTeamBattleHp()
  elseif eventName == BattleEvent.TEAM_SWAP_SELECT_START then
    self:OnSelfSelectPet()
  elseif eventName == BattleEvent.UPDATE_TEAMBOSS_HP then
    self:OnPetSpawnEvent(...)
  elseif eventName == BattleEvent.BLOOD_SHOW_MONEY then
    self:OpenMoneyBtn()
  elseif eventName == BattleEvent.BLOOD_HIDE_MONEY then
    self:HideMoneyBtn()
  elseif eventName == BattleEvent.PLAYER_LEAVE_GAME then
    self:OnPlayerLeaveGame(...)
  end
end

function UMG_Pet_GroupWarfare_C:OnPlayerLeaveGame(player)
  if not self.TeammateHPList then
    return
  end
  for i, TeammateHP in ipairs(self.TeammateHPList) do
    if 1 ~= i and TeammateHP.battlePet and TeammateHP.battlePet.player == player then
      TeammateHP:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Pet_GroupWarfare_C:HideHp()
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.EnemyPet and self.EnemyPet.battlePetComponents then
    self.EnemyPet.battlePetComponents:HideCatchConsume(false)
    self.EnemyPet:ShowTipTime(-1, BattleEnum.Operation.ENUM_CATCH)
  end
end

function UMG_Pet_GroupWarfare_C:PlayOpen()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.open)
end

function UMG_Pet_GroupWarfare_C:ShowPanel()
  self:StopAllAnimations()
  self:PlayOpen()
end

function UMG_Pet_GroupWarfare_C:HidePanel()
  self:StopAllAnimations()
  self:PlayAnimation(self.Close)
end

function UMG_Pet_GroupWarfare_C:HideTeamBattleHp()
  for i, TeammateHP in ipairs(self.TeammateHPList) do
    if 1 ~= i then
      TeammateHP:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self.List_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pet_GroupWarfare_C:ShowTeamBattleHp()
  for i, TeammateHP in ipairs(self.TeammateHPList) do
    if 1 ~= i then
      TeammateHP:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  self:UpdateSkillInoList()
end

function UMG_Pet_GroupWarfare_C:OnSelfSelectPet()
  for i, TeammateHP in ipairs(self.TeammateHPList) do
    TeammateHP:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.ResurrectionCountDown:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self:PlayAnimation(self.Out)
  end
  self:RefreshChildClickAnim()
end

function UMG_Pet_GroupWarfare_C:TryInitData()
  local Pets = _G.BattleManager.battlePawnManager:GetAllPets()
  for i, Pet in ipairs(Pets) do
    self:OnPetSpawnEvent(Pet)
  end
end

function UMG_Pet_GroupWarfare_C:OnPetSpawnEvent(pet)
  if pet.teamEnm == BattleEnum.Team.ENUM_ENEMY or not _G.BattleManager:CheckActiveState(BattleEnum.StateNames.SwapSelect) then
    self:InitView(pet)
  end
end

function UMG_Pet_GroupWarfare_C:ShowCatchInfo()
  if BattleUtils.IsTeam() and not BattleUtils.IsBeastTeam() then
    self.IsDead = true
    if self.EnemyPet and self.EnemyPet.battlePetComponents then
      self.EnemyPet.battlePetComponents:HideCatchConsume(true)
    else
      Log.Debug("\230\178\161\230\156\137\230\149\140\230\150\185\229\174\160\231\137\169\230\149\176\230\141\174")
    end
    if self.ResurrectionCountDown:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self:PlayAnimation(self.Out)
    end
  elseif self.EnemyPet and self.EnemyPet.battlePetComponents then
    self.EnemyPet.battlePetComponents:HideCatchConsume(false)
  else
    Log.Debug("\230\178\161\230\156\137\230\149\140\230\150\185\229\174\160\231\137\169\230\149\176\230\141\174")
  end
  self:UpdateSkillList()
end

function UMG_Pet_GroupWarfare_C:ShowTipTime()
  local params = {}
  if not _G.DataModelMgr.PlayerDataModel:IsVisitState() or _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
  else
    repeat
      do
        local PlayerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
        if self.EnemyPet then
          local PetInfo = self.EnemyPet.card.petInfo
          local isGlass = PetInfo.battle_common_pet_info.mutation_type == ProtoEnum.MutationDiffType.MDT_GLASS
          local contentId = PetInfo.battle_inside_pet_info.refresh_content_id
          if isGlass and contentId and contentId > 0 then
            local glass_limit_type = _G.DataConfigManager:GetNpcRefreshContentConf(PetInfo.battle_inside_pet_info.refresh_content_id).glass_limit_type
            isGlass = glass_limit_type == ProtoEnum.GlassLimitType.GLT_TEAM_BATTLE or glass_limit_type == ProtoEnum.GlassLimitType.GLT_WILD_MONSTER
          else
            isGlass = false
          end
          local visitCatchTimes = isGlass and PlayerPetInfo.visit_remain_shiny_catch_times or 1
          params.isInVisitCatch = visitCatchTimes
          params.isInVisitGlassCatch = isGlass
          if BattleUtils.IsBloodTeam() and params.isInVisitGlassCatch then
            self.EnemyPet:ShowTipTime(1, BattleEnum.Operation.ENUM_CATCH, params)
          else
            self.EnemyPet:ShowTipTime(-1, BattleEnum.Operation.ENUM_CATCH, params)
            break -- pseudo-goto
          end
        end
      end
    until true
  end
end

function UMG_Pet_GroupWarfare_C:UpdateSkillList()
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseSkillTips)
end

function UMG_Pet_GroupWarfare_C:PetDleUpdatePanel(battlePet)
  if self.OwnPet and self.OwnPet.guid == battlePet.guid then
    self:UpdateRound()
  end
end

function UMG_Pet_GroupWarfare_C:UpdateRound(Round)
  if self.OwnPet and self.OwnPet:IsDead() and self.OwnPet.player:GetSummonNumber() > 0 then
    local RoundInfo
    if Round then
      RoundInfo = self.OwnPet.card.petInfo.battle_inside_pet_info.revive_round - Round
    else
      RoundInfo = self.OwnPet.card.petInfo.battle_inside_pet_info.revive_rounds
    end
    RoundInfo = math.max(0, RoundInfo + 1)
    Log.Warning("UMG_Pet_GroupWarfare_C:UpdateRound ", RoundInfo, self.OwnPet.card.petInfo.battle_inside_pet_info.revive_round, self.OwnPet.card.petInfo.battle_inside_pet_info.revive_rounds, Round)
    self.CountDown:SetText(RoundInfo)
    if RoundInfo > 0 and self.ResurrectionCountDown:GetVisibility() == UE4.ESlateVisibility.Collapsed then
      self.ResurrectionCountDown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.In)
    end
  elseif self.ResurrectionCountDown:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self:PlayAnimation(self.Out)
  end
end

function UMG_Pet_GroupWarfare_C:InitView(battlePet)
  if battlePet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    self.EnemyPet = battlePet
    self.UMG_Pet_ProgressBar_Big:InitView(battlePet)
    self:SetEnemyPetInfo(battlePet)
  else
    self:SetTeamPetInfo(battlePet)
    if self.OwnPet and self.OwnPet.guid == battlePet.guid then
      self:SetPanelInfo()
    end
  end
end

function UMG_Pet_GroupWarfare_C:UpdateStarChain()
  local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
  local stamina = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
  local StaminaProportion = string.format("%s%s%s", StarNum, "/", stamina.num)
  self.MoneyBtn2_1:SetInfo(_G.Enum.VisualItem.VI_STAR, StaminaProportion, true)
  self.MoneyBtn2_1:SetSourceReturnFlagAndFunc(true, self.OpenMoneyBtn)
  self.MoneyBtn2_1:SetHandler(self, self.HideMoneyBtn)
end

function UMG_Pet_GroupWarfare_C:HideMoneyBtn()
  self.CanvasPanel_40:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pet_GroupWarfare_C:OpenMoneyBtn()
  self.CanvasPanel_40:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Pet_GroupWarfare_C:SetPanelInfo()
  self:UpdateRound()
  self.CanvasPanel_202:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pet_GroupWarfare_C:SetRecoveryItemInfo()
  local StarDebrisNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS)
  StarDebrisNum = StarDebrisNum or 0
  local staminaA = _G.DataConfigManager:GetRoleGlobalConfig("star_debris_top_limit")
  local StaminaProportionA = ""
  if StarDebrisNum == staminaA.num then
    self.MoneyBtn2.SumNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("FFC65FFF"))
    StaminaProportionA = string.format("%s   \230\187\161", staminaA.num)
  elseif StarDebrisNum >= 0 then
    StaminaProportionA = string.format("%s", StarDebrisNum)
  end
  self.MoneyBtn2:SetInfo(_G.Enum.VisualItem.VI_STAR_DEBRIS, StaminaProportionA, true)
  local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
  local staminaB = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
  local StaminaProportionB = string.format("%s%s%s", StarNum, "/", staminaB.num)
  self.MoneyBtn2_1:SetInfo(_G.Enum.VisualItem.VI_STAR, StaminaProportionB, true)
  self.MoneyBtn2_1:SetSourceReturnFlagAndFunc(true, self.OpenMoneyBtn)
  self.MoneyBtn2_1:SetHandler(self, self.HideMoneyBtn)
  self.MoneyBtn2:SetSourceReturnFlagAndFunc(true, self.OpenMoneyBtn)
  self.MoneyBtn2:SetHandler(self, self.HideMoneyBtn)
  local RecoveryItemList = {}
  table.insert(RecoveryItemList, {
    itemType = _G.Enum.VisualItem.VI_STAR
  })
  table.insert(RecoveryItemList, {
    itemType = _G.Enum.VisualItem.VI_STAR_DEBRIS
  })
  self.SummaryRecall:InitGridView(RecoveryItemList)
  local CostStar = _G.DataConfigManager:GetPetGlobalConfig("team_battle_starlink")
  if StarDebrisNum >= CostStar.num and StarNum >= CostStar.num then
    self.SummaryRecall:SelectItemByIndex(0)
  elseif StarDebrisNum < CostStar.num and StarNum >= CostStar.num then
    local starDebrisItem = self.SummaryRecall:GetItemByIndex(1)
    starDebrisItem.GreyOut:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SummaryRecall:SelectItemByIndex(0)
  elseif StarDebrisNum >= CostStar.num and StarNum < CostStar.num then
    self.SummaryRecall:SelectItemByIndex(1)
  elseif StarDebrisNum < CostStar.num and StarNum < CostStar.num then
    local starDebrisItem = self.SummaryRecall:GetItemByIndex(1)
    starDebrisItem.GreyOut:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SummaryRecall:SelectItemByIndex(0)
  end
end

function UMG_Pet_GroupWarfare_C:UpdateSkillInoList()
  self.List_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Pet_GroupWarfare_C:SetTeamPetInfo(battlePet)
  local Uin = battlePet.player.roleInfo.base.role_uin
  local PlayerUin
  local myTeam = BattleManager.battlePawnManager:GetPlayerMyTeam()
  if myTeam then
    PlayerUin = myTeam.guid
  end
  Log.Warning(Uin, PlayerUin, battlePet.card.name, battlePet.player.TeamNumber, battlePet.card.posInField, "UMG_Pet_GroupWarfare_C:SetTeamPetInfo")
  if Uin == PlayerUin then
    self.OwnPet = battlePet
    self.TeammateHPList[1]:InitView(battlePet)
    self.TeammateHPList[1]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    local index = battlePet.card.posInField
    if index > #self.TeammateHPList and index <= 0 then
      Log.Error("zgx index is error", index)
      return
    end
    self.TeammateHPList[index]:InitView(battlePet)
    self.TeammateHPList[index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Pet_GroupWarfare_C:SelectRecoveryItem(selectItemIndex)
  for i = 1, self.SummaryRecall:GetItemCount() do
    if i - 1 == selectItemIndex then
      local item = self.SummaryRecall:GetItemByIndex(i - 1)
      item:SetSelectState(true)
    end
  end
end

function UMG_Pet_GroupWarfare_C:FindPetPos(pet_id)
  for i, TeammateHP in ipairs(self.TeammateHPList) do
    if TeammateHP.battlePet then
      if TeammateHP.battlePet.card.guid == pet_id then
        return TeammateHP.Pos
      end
    else
      Log.Error("zgx battlePet is nil", TeammateHP)
    end
  end
  return nil
end

function UMG_Pet_GroupWarfare_C:FindOwnPet(pet_id)
  local PlayerUin = BattleManager.battlePawnManager:GetPlayerMyTeam().guid
  for i, TeammateHP in ipairs(self.TeammateHPList) do
    if TeammateHP.battlePet then
      if TeammateHP.battlePet.card.guid == pet_id and TeammateHP.battlePet.player.roleInfo.base.role_uin == PlayerUin then
        return true
      end
    else
      Log.Error("zgx battlePet is nil", TeammateHP)
    end
  end
  return false
end

function UMG_Pet_GroupWarfare_C:SetEnemyPetInfo(battlePet)
  if battlePet then
    self.Text_Name:SetText(battlePet.card.name)
    if battlePet.card.lv then
      self.TxtLevel:SetText(string.format(LuaText.umg_petskilltemple2_1, battlePet.card.lv))
    else
      Log.Error("UMG_Pet_GroupWarfare_C:SetEnemyPetInfo card.lv is nil")
    end
    self:SetTypes(battlePet.card)
    self:SetBloodPulseIcon(battlePet.card.petInfo.battle_common_pet_info)
    self:updatePetGender(battlePet.card.petInfo.battle_common_pet_info.gender)
  end
  if self.EnemyPet then
    self.HeadIcon:SetIconPathAndMaterial(self.EnemyPet.card.petBaseConf.id, self.EnemyPet.card.petInfo.battle_common_pet_info.mutation_type, self.EnemyPet.card.petInfo.battle_common_pet_info.glass_info)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Pet_GroupWarfare_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Pet_GroupWarfare_C:SetTypes(card)
  if card.IsFirstMeet or card.petState:GetMimic() then
    for i, uiIcon in ipairs(self.petTypeIcons) do
      local TypePanel = self.TypePanel[i]
      local TypeIconBg = self.TypeIconBg[i]
      uiIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      TypePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      TypeIconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    local Types = card.petBaseConf.unit_type
    for i, uiIcon in ipairs(self.petTypeIcons) do
      local TypePanel = self.TypePanel[i]
      local TypeIconBg = self.TypeIconBg[i]
      uiIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      TypePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      TypeIconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      local petType = Types[#Types - i + 1]
      if petType then
        local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
        if typeDic then
          uiIcon:SetPath(typeDic.type_icon)
          uiIcon:SetVisibility(UE4.ESlateVisibility.Visible)
          TypePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          TypeIconBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          Log.Warning("petType\233\133\141\231\189\174\230\137\190\228\184\141\229\136\176, \229\142\187\231\156\139\231\156\139\233\133\141\231\189\174\232\161\168\229\144\167 ", typeDic)
        end
      end
    end
  end
end

function UMG_Pet_GroupWarfare_C:SetBloodPulseIcon(_petData)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(_petData.blood_id)
  if PetBloodConf then
    self.icon_1:SetPath(PetBloodConf.icon)
  end
end

function UMG_Pet_GroupWarfare_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Pet_GroupWarfare_C:PCModeScreenSetting()
  local Padding = UE4.FMargin()
  Padding.Left = -245
  Padding.Top = -66
  Padding.Right = -244
  Padding.Bottom = -74
  self.NRCSafeZone_16:SetRenderScale(UE4.FVector2D(0.88, 0.88))
  self.NRCSafeZone_16.Slot:SetOffsets(Padding)
end

function UMG_Pet_GroupWarfare_C:OnBtnRechristen_1Click()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpenPetTips, self.EnemyPet.card.petInfo.battle_common_pet_info)
end

function UMG_Pet_GroupWarfare_C:OnBloodBtn()
  if not self.EnemyPet then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_PetBaseInfo_C:OnBloodPulse")
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBattleBloodPulse, self.EnemyPet.card.petInfo.battle_common_pet_info)
end

function UMG_Pet_GroupWarfare_C:OnDeactive()
end

function UMG_Pet_GroupWarfare_C:UpdateEnemySkillList(_curRound)
  if self:IsChangePetRound(_curRound) then
    Log.Debug("\230\141\162\229\174\160\233\152\182\230\174\181,\228\184\141\233\156\128\232\166\129\229\136\183\230\150\176\232\161\128\232\132\137\230\138\128\232\131\189list")
    return
  end
  self:PlayRemoveAnim(_curRound)
end

function UMG_Pet_GroupWarfare_C:RefreshCatchConsumeInfo(itemType)
  if self.EnemyPet and self.EnemyPet.battlePetComponents then
    self.EnemyPet.battlePetComponents:RefreshCatchConsumeInfo(itemType)
  end
end

function UMG_Pet_GroupWarfare_C:PlayRemoveAnim(_curRound)
  local Item = self.List_1:GetItemByIndex(0)
  if Item then
    if Item.IsPlayAddOrRemoveAnim then
      if Item:IsPlayAddOrRemoveAnim() then
        table.insert(self.WaitPlayAddOrRemoveSkillAnim, _curRound)
      else
        self.curRound = _curRound
        Item:UnbindFromAnimationFinished(Item.Out, {
          self,
          self.UpdateList
        })
        Item:BindToAnimationFinished(Item.Out, {
          self,
          self.UpdateList
        })
        self.List_1:AddOrRemoveItem(false, 1, nil, true)
      end
    else
      Log.Error("Item\229\173\152\229\156\168\228\189\134\230\152\175\233\135\140\233\157\162\229\135\189\230\149\176\230\142\165\229\143\163\228\184\186\231\169\186,\230\159\165\231\156\139\229\142\159\229\155\160")
    end
    Item:Release()
  end
end

function UMG_Pet_GroupWarfare_C:UpdateList()
  if not self.curRound then
    return
  end
  self:RemoveBeforeRound(self.curRound + 1)
  local ShowSkillList = self:ShowFirstFourSkills(self.curRound + 1, true)
  self.List_1:AddOrRemoveItem(true, #ShowSkillList, ShowSkillList[#ShowSkillList], true)
  if #self.WaitPlayAddOrRemoveSkillAnim > 0 then
    self:UpdateEnemySkillList(self.WaitPlayAddOrRemoveSkillAnim[1])
    table.remove(self.WaitPlayAddOrRemoveSkillAnim, 1)
  end
  self:RefreshChildClickAnim()
end

function UMG_Pet_GroupWarfare_C:ShowEnemySkillListByChooseSkill(_PetSkillList, _curRound)
  if not _PetSkillList then
    return
  end
  if _PetSkillList.is_change_pet then
    self:SetRemoveFlags(_curRound)
    return
  end
  local PetSkillList = _PetSkillList
  if PetSkillList.pkinfo then
    self:AddNewRound(_PetSkillList, _curRound)
    self:CheckRefreshVisibleSkillItems(_curRound)
    for i, Skill in ipairs(self.EnemySkillList) do
      if Skill.SkillId == PetSkillList.pkinfo.skill_id and PetSkillList.pkinfo.attack_pet_id and _curRound == Skill.curRound then
        Skill.pet_id = PetSkillList.pkinfo.attack_pet_id
        Skill.Pos = self:FindPetPos(PetSkillList.pkinfo.attack_pet_id)
        Skill.Own = self:FindOwnPet(PetSkillList.pkinfo.attack_pet_id)
        Skill.curRound = _curRound
        Skill.hide = false
        Skill.PetSkillId = PetSkillList.pkinfo.skill_id
        if PetSkillList.pkinfo.items then
          for i = #PetSkillList.pkinfo.items, 1, -1 do
            local v = PetSkillList.pkinfo.items[i]
            if v.change_pet_op and v.change_pet_op.round == _curRound then
            elseif v.skill_op and v.skill_op.caster == Skill.pet_id then
              v.Pos = Skill.Pos
              v.Own = Skill.Own
            end
          end
        end
        Skill.detailInfo = {
          items = PetSkillList.pkinfo.items,
          simple_pets = PetSkillList.pkinfo.simple_pets
        }
        Skill.is_set_info = true
        local Item = self.List_1:GetItemByIndex(i - 1)
        if Item then
          Item:SetPetPos(Skill)
          Item:SetIconShow(Skill)
          Item:PlayOutAnim()
          Item:Release()
        end
        self:PlayChildClickAnim(i)
      end
    end
  elseif #self.EnemySkillList <= 0 then
    local EnemySkillListS = {}
    local curRound = _curRound
    if PetSkillList.skills then
      for i, skill_id in ipairs(PetSkillList.skills) do
        table.insert(EnemySkillListS, {
          SkillId = skill_id.skill_id,
          curRound = curRound,
          hide = skill_id.hide,
          EnemyPet = self.EnemyPet
        })
        curRound = curRound + 1
      end
    end
    self.EnemySkillList = EnemySkillListS
    self:UpdateSkillInoList()
    self.List_1:InitList(self.EnemySkillList)
    self:PlayChildClickAnim(0)
  end
end

function UMG_Pet_GroupWarfare_C:IsChangePetRound(_curRound)
  local IsChangePet = false
  for i, Skill in ipairs(self.EnemySkillList) do
    if _curRound == Skill.curRound and Skill.is_change_pet then
      IsChangePet = true
      Skill.is_change_pet = false
    end
  end
  if IsChangePet then
    for i, Skill in ipairs(self.EnemySkillList) do
      Skill.curRound = Skill.curRound + 1
    end
  end
  return IsChangePet
end

function UMG_Pet_GroupWarfare_C:SetRemoveFlags(_curRound)
  for i, Skill in ipairs(self.EnemySkillList) do
    if _curRound == Skill.curRound then
      Skill.is_change_pet = true
    end
  end
end

function UMG_Pet_GroupWarfare_C:RefreshChildClickAnim()
  local targetPos
  local listCount = self.List_1:GetItemCount()
  for index = 1, listCount do
    local Item = self.List_1:GetItemByIndex(index - 1)
    if Item and Item.data and not Item.data.is_set_info then
      targetPos = index - 1
      break
    end
  end
  if targetPos then
    self:PlayChildClickAnim(targetPos)
  end
end

function UMG_Pet_GroupWarfare_C:PlayChildClickAnim(Index)
  if self:CheckIsWaitingOtherOrDie() then
    return
  end
  local Item = self.List_1:GetItemByIndex(Index)
  if Item then
    Item:PlayClickAnim()
    Item:Release()
  end
end

function UMG_Pet_GroupWarfare_C:IsSelfSelected()
  if self.EnemySkillList then
    for i, Skill in ipairs(self.EnemySkillList) do
      if Skill.Own == true and Skill.Pos and 1 == Skill.Pos then
        return true
      end
    end
  end
  return false
end

function UMG_Pet_GroupWarfare_C:CheckIsWaitingOtherOrDie()
  if self:IsSelfSelected() then
    return true
  end
  if BattleUtils.IsChangeToRunAway() then
    return true
  end
  return false
end

function UMG_Pet_GroupWarfare_C:RemoveBeforeRound(curRound)
  for i = #self.EnemySkillList, 1, -1 do
    if curRound > self.EnemySkillList[i].curRound then
      table.remove(self.EnemySkillList, i)
    end
  end
end

function UMG_Pet_GroupWarfare_C:ShowFirstFourSkills(curRound, _IsBoost)
  local ShowSkillList = {}
  local CurRound = 0
  if _IsBoost then
    CurRound = curRound + 4
  else
    CurRound = self.EnemySkillList[1].curRound + 4
  end
  for i, Skill in ipairs(self.EnemySkillList) do
    if CurRound > Skill.curRound then
      table.insert(ShowSkillList, Skill)
    end
  end
  if 4 ~= #ShowSkillList then
    Log.Error("\230\152\190\231\164\186\230\138\128\232\131\189\229\136\151\232\161\168\230\156\137\232\175\175,\229\186\148\232\175\165\229\143\170\230\152\190\231\164\186\229\155\155\228\184\170\230\138\128\232\131\189")
  end
  return ShowSkillList
end

function UMG_Pet_GroupWarfare_C:CheckRefreshVisibleSkillItems(_curRound)
  local needRefresh = false
  for i = #self.EnemySkillList, 1, -1 do
    local Skill = self.EnemySkillList[i]
    if _curRound > Skill.curRound and not Skill.is_set_info then
      needRefresh = true
      table.remove(self.EnemySkillList, i)
    end
  end
  if not needRefresh then
    return
  end
  Log.Debug("CheckRefreshVisibleSkillItems needRefresh!")
  self.WaitPlayAddOrRemoveSkillAnim = {}
  self.curRound = nil
  local listCount = self.List_1:GetItemCount()
  local ShowSkillList = self:ShowFirstFourSkills(_curRound, true)
  for i = 0, listCount - 1 do
    local Item = self.List_1:GetItemByIndex(i)
    local targetData = ShowSkillList[i + 1]
    Item:StopAllAnimations()
    if targetData then
      Item:OnItemUpdate(targetData, ShowSkillList, i + 1)
      if targetData.is_set_info then
        Item:SetPetPos(targetData)
        Item:SetIconShow(targetData)
        Item:PlayOutAnim()
        Item:Release()
      end
    end
  end
end

function UMG_Pet_GroupWarfare_C:AddNewRound(_PetSkillList, _curRound)
  local CurRound = _curRound
  if _PetSkillList.skills then
    for i, skill_id in ipairs(_PetSkillList.skills) do
      CurRound = CurRound + 1
      local IsHasSkill = false
      for j, Skill in ipairs(self.EnemySkillList) do
        if CurRound == Skill.curRound then
          IsHasSkill = true
          break
        end
      end
      if not IsHasSkill then
        table.insert(self.EnemySkillList, {
          SkillId = skill_id.skill_id,
          curRound = CurRound,
          hide = skill_id.hide,
          EnemyPet = self.EnemyPet
        })
      end
    end
  end
end

function UMG_Pet_GroupWarfare_C:SortRound()
  table.sort(self.EnemySkillList, function(a, b)
    if a.curRound < b.curRound then
      return a.curRound < b.curRound
    end
  end)
end

function UMG_Pet_GroupWarfare_C:OnAnimationFinished(Animation)
  if Animation == self.Out then
    self.ResurrectionCountDown:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Animation == self.Close then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_Pet_GroupWarfare_C:OnOpenPetTips()
  local config = BattleUtils.GetBattleConfig()
  if not config then
    Log.Warning("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174")
    return
  end
  if not self.EnemyPet then
    Log.Warning("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174")
    return
  end
  local data = {
    cardData = self.EnemyPet.card,
    petData = {
      base_conf_id = self.EnemyPet.card.petBaseConf.id,
      extra_sdt = self.EnemyPet.card.petInfo.battle_inside_pet_info.extra_sdt
    },
    forbidBuffList = config.teamB_prohibit_buff
  }
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.OpenBattleChangePetConfirmPanel, data)
end

return UMG_Pet_GroupWarfare_C
