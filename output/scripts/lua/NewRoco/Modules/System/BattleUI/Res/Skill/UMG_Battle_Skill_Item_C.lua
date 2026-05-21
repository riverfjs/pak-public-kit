local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ProtoEnum = require("Data.PB.ProtoEnum")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local luaText = require("LuaText")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local SkillUtils = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.SkillUtils")
local UMG_Common_Skill_Tips_C = require("NewRoco.Modules.System.BattleUI.Res.UMG_Common_Skill_Tips_C")
local BattleTutorialGuideModuleEvent = require("NewRoco.Modules.System.BattleTutorialGuide.BattleTutorialGuideModuleEvent")
local UMG_Battle_Skill_Item_C = NRCUmgClass:Extend("")
local StarState = {
  Invalid = -1,
  GrayStar = 0,
  NormalStar = 1,
  RedStar = 2,
  GreenStar = 3,
  RedHeart = 4,
  GradePoint = 5
}
local ESlateVisibility = {
  Visible = UE4.ESlateVisibility.Visible,
  Collapsed = UE4.ESlateVisibility.Collapsed,
  Hidden = UE4.ESlateVisibility.Hidden,
  HitTestInvisible = UE4.ESlateVisibility.HitTestInvisible,
  SelfHitTestInvisible = UE4.ESlateVisibility.SelfHitTestInvisible,
  ESlateVisibility_MAX = UE4.ESlateVisibility.ESlateVisibility_MAX
}
local RestraintEffectIndexType = {
  None = -1,
  Restraint = 0,
  Normal = 1,
  Weak = 2,
  RestraintDouble = 3,
  WeakDouble = 4,
  Max = 5
}

function UMG_Battle_Skill_Item_C:Construct()
  self.Overridden.Construct(self)
  self.BtnSkill.OnPressed:Add(self, self._OnItemPressed)
  self.BtnSkill.OnReleased:Add(self, self._OnItemRelease)
  self.BtnSkill.OnHovered:Add(self, self._OnItemHovered)
  self.BtnSkill.OnUnhovered:Add(self, self._OnItemUnHovered)
  self.skill = nil
  self.id = -1
  self.newSkill = nil
  self._timer = 0
  self._longPressThreshold = BattleConst.ItemLongPressThreshold
  self._pressed = false
  self._covered = false
  self.config = nil
  self.canCast = false
  self.CastPet = nil
  self.bFantastic = nil
  self.fantasticBackgroundPath = ""
  self.restrainType = nil
  self.IsCancel = false
  self.StartTime = 0
  self.EndTime = 1
  self.IsTimeLimit = false
  self.CurrentType = 0
  self.widgetVisibilityMap = {}
  self.waitingForUpdateVisibilityWidgetMap = {}
  self.widgetToNameMap = {}
  self.StarListForAttr1 = {
    self.Star1_1,
    self.Star3_1,
    self.Star4_1,
    self.Star5_1,
    self.Fx_Attr_light
  }
  self.StarListForEffect = {
    self.Star1_2,
    self.Star2_1,
    self.Star3_2,
    self.Star6_1,
    self.Fx_effect_light
  }
  self.OnOpenAnimFinishedDelegate = {
    self,
    self.OnOpenAnimationFinished
  }
  self.newDataModel = {}
  BattleEventCenter:Bind(self, BattlePerformEvent.SkillSync, BattleEvent.BATTLE_CLICKED_SKILL, BattleEvent.ChangeGatherState)
end

function UMG_Battle_Skill_Item_C:Destruct()
  NRCUmgClass.Log(self, "UMG_Battle_Skill_Item_C Destruct")
  self.BtnSkill.OnPressed:Remove(self, self._OnItemPressed)
  self.BtnSkill.OnReleased:Remove(self, self._OnItemRelease)
  self.BtnSkill.OnHovered:Remove(self, self._OnItemHovered)
  self.BtnSkill.OnUnhovered:Remove(self, self._OnItemUnHovered)
  self:CancelAllOpenAnimationDelay()
  if self.updateWidgetVisibilityInWaitingListDelayHandler then
    _G.DelayManager:CancelDelayById(self.updateWidgetVisibilityInWaitingListDelayHandler)
    self.updateWidgetVisibilityInWaitingListDelayHandler = nil
  end
  self.StarListForAttr1 = {}
  self.StarListForEffect = {}
  NRCUmgClass.Destruct(self)
  BattleEventCenter:UnBind(self)
end

function UMG_Battle_Skill_Item_C:CancelAllOpenAnimationDelay()
  if self.delayPlayOpenAnimationHandler then
    _G.DelayManager:CancelDelayById(self.delayPlayOpenAnimationHandler)
    self.delayPlayOpenAnimationHandler = nil
  end
  if self.delayHideRelativeChangeSkillPosItemHandler then
    _G.DelayManager:CancelDelayById(self.delayHideRelativeChangeSkillPosItemHandler)
    self.delayHideRelativeChangeSkillPosItemHandler = nil
  end
  if self.delayRefreshIconsWithDataModelHandler then
    _G.DelayManager:CancelDelayById(self.delayRefreshIconsWithDataModelHandler)
    self.delayRefreshIconsWithDataModelHandler = nil
  end
end

function UMG_Battle_Skill_Item_C:ShowB1FinalP2Dialogue()
  _G.NRCModuleManager:DoCmd(_G.B1FinalBattleModuleCmd.SetIsFirstDialogue, nil)
  local dialogCfg = _G.DataConfigManager:GetBattleGlobalConfig("B1_FINAL_BATTLE_STATE2_SIGN_DIALOGUE", true)
  if dialogCfg then
    local dialogId = dialogCfg.num
    local teamPlayer = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
    _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.StartDialogueInBattle, teamPlayer, dialogId)
  end
end

function UMG_Battle_Skill_Item_C:CheckB1FinalP2Dialogue()
  local State2SignSkillCfg = _G.DataConfigManager:GetBattleGlobalConfig("B1_FINAL_BATTLE_STATE2_SIGN_SKILL", true)
  if not State2SignSkillCfg or not State2SignSkillCfg.num then
    return false
  end
  local targetSkillId = State2SignSkillCfg.num * 100
  if self.skill.id == targetSkillId then
    local isFirstDialogue = _G.NRCModuleManager:DoCmd(_G.B1FinalBattleModuleCmd.GetIsFirstDialogue)
    if isFirstDialogue then
      return true
    end
  end
  return false
end

function UMG_Battle_Skill_Item_C:B1FinalP3SkillClick()
  if UE4.UObject.IsValid(self) and self.skill then
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_SKILL, self.skill)
  end
end

function UMG_Battle_Skill_Item_C:OnItemClick()
  Log.Debug("UMG_Battle_Skill_Item_C canCast:", self.canCast)
  if BattleUtils.IsB1FinalBattleP3() and self.bIsB1FinalP3FinalSkill then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1602, "UMG_Battle_Skill_Item_C:OnItemClick")
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1004, "UMG_Battle_Skill_Item_C:OnItemClick")
  end
  if not self.skill then
    return
  end
  if BattleUtils.IsB1FinalBattleP3() and self.bIsB1FinalP3FinalSkill then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.TryBattleUltimateSkillClick, self, self.B1FinalP3SkillClick)
    return
  end
  if not self.canCast then
    if self.skill:IsBan() then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Battle_Ban_Skill)
    elseif self.skill:IsLegendaryBan() then
      local globalConfig = _G.DataConfigManager:GetBattleGlobalConfig("battle_character1")
      if globalConfig then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, globalConfig.str)
      end
    elseif self.skill:IsLegendaryTimeLimitBan() then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.legendaryskill_tips)
    elseif self.skill:IsTeamBan() then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.effect49_tips)
    elseif self.skill:IsFeverBan() then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Battle_Skill_In_Crazy)
    elseif self.skill:IsEnvBan() then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Env_Ban_Tip)
    elseif BuffUtils.IsGatherBuffEx(self.isLeaderBattlePreCalcGather, self.CastPet) then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Gather_Tips)
    elseif self.skill:IsSealBan() then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("2006004").msg)
    else
      if self.skill:IsBloodEnergy() and self.CastPet.card:GetHp() <= self.skill.skillData.cost_hp then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Battle_Skill_Hp_Not_Enough)
        return
      end
      if self.skill.curCD > 0 then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Battle_Skill_CD)
        return
      end
      if self.skill:IsCostEnergy() and self.CastPet:GetEnergy() < self.skill.energy then
        if BattleUtils.IsB1FinalBattleP2() and self:CheckB1FinalP2Dialogue() then
          self:ShowB1FinalP2Dialogue()
          return
        end
        if BattleUtils.IsB1FinalBattleP2() or BattleUtils.IsB1FinalBattleP3() then
          local tips = _G.DataConfigManager:GetLocalizationConf("Battle_Skill_PhantomPoint_Not_Enough").msg
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
        else
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Battle_Skill_Energy_Not_Enough)
        end
        return
      end
    end
    return
  end
  if self.isLeaderBattlePreCalcGather and self.skill.skill_id ~= 7000010 and not self.skill.skillData.enable_on_charging then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.Gather_Tips)
    return
  end
  if self.skill.config.type == ProtoEnum.SkillActiveType.SAT_IDLE then
    self:OnBtnIdleClick()
  elseif self.skill.config.type == ProtoEnum.SkillActiveType.SAT_LACKENERGY then
    if self.IsTimeLimit then
      return
    end
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_SKILL, self.skill)
  else
    if self.IsTimeLimit then
      return
    end
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_SKILL, self.skill)
  end
end

function UMG_Battle_Skill_Item_C:SetOnClickTimeLimit()
  if BattleUtils.IsWorldLeaderFight() then
    self.IsTimeLimit = true
  end
end

function UMG_Battle_Skill_Item_C:OnAnimationStarted(Animation)
  if Animation == self.Skill_Change_In or Animation == self.Skill_change_non then
  end
end

function UMG_Battle_Skill_Item_C:OnAnimationFinished(Animation)
  if self.skill then
  end
  if Animation == self.Btn_one_Click then
    self:PlayAnimation(self.Btn_one_Max)
  elseif Animation == self.open or Animation == self.Change_open then
  elseif Animation == self.Buff_steal_loop then
    self:SetWidgetVisibilityByName("Cover_effect", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("Cover_effect_star", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("Fx_icon_light", ESlateVisibility.Collapsed)
  elseif Animation == self.Skill_Change_In then
    self:PlayAnimation(self.Skill_Change_Out)
  elseif Animation == self.Btn_one_Max then
    if self.skill then
      self:_Refresh(self.skill, self.currentStateName)
    end
  elseif Animation == self.Aspiration_loop then
    self.normalBG:SetRenderOpacity(1)
    self.normalBG_1:SetRenderOpacity(0)
  end
end

function UMG_Battle_Skill_Item_C:GetSpecialShowState(stateName)
  if stateName == BattleEnum.StateNames.B1FinalBattleP1ToP2 or stateName == BattleEnum.StateNames.PrePlay or stateName == BattleEnum.StateNames.Standby then
    return true
  end
  return false
end

function UMG_Battle_Skill_Item_C:DoClick()
  Log.Debug("UMG_Battle_Skill_Item_C:DoClick")
  if self:GetSpecialShowState(self.currentStateName) then
    return
  end
  local ForbidClickState = _G.NRCModuleManager:DoCmd(_G.BattleTutorialGuideModuleCmd.GetIsForBidSkillClick)
  if ForbidClickState and ForbidClickState == Enum.BattleLeadFinishType.BLFT_BUTTON_LONG_PRESS then
    return
  end
  if ForbidClickState and ForbidClickState == Enum.BattleLeadFinishType.BLFT_BUTTON_SHORT_PRESS then
    local eventParam = self:GetBattleGuidanceLocationByIndex()
    if eventParam then
      _G.NRCEventCenter:DispatchEvent(BattleTutorialGuideModuleEvent.BtnClickEvent, eventParam)
    end
  end
  if self.skill and not BattleUtils.IsWatchingBattle() then
    if self.canCast then
      if self.restrainType == BattleEnum.TypeRestraint.ENUM_RESTRAINT then
        self:SetWidgetVisibilityByName("UMG_BattleClickFX_Max", ESlateVisibility.HitTestInvisible)
      else
        self:SetWidgetVisibilityByName("UMG_BattleClickFX", ESlateVisibility.HitTestInvisible)
      end
      if self.skill.type ~= ProtoEnum.SkillActiveType.SAT_GLOBAL and not self:IsAnimationPlaying(self.Btn_one_Click) and not self:IsAnimationPlaying(self.Btn_one_Max) then
        self:PlayAnimation(self.Btn_one_Click)
      end
    end
    self:OnItemClick()
  end
  if self.IsCancel and self.undoSelect then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1179, "UMG_Battle_Skill_Item_C:DoClick")
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1180, "UMG_Battle_Skill_Item_C:DoClick")
    local req = _G.ProtoMessage:newZoneBattleCmdPopbackReq()
    req.pet_id = self.CastPet.guid
    _G.BattleManager.battleNetManager:SendBattleCmdPopbackReq(req, self.undoSelectCaller, self.undoSelect)
  end
end

function UMG_Battle_Skill_Item_C:SetUndoCallback(caller, undoSelect)
  self.undoSelectCaller = caller
  self.undoSelect = undoSelect
end

function UMG_Battle_Skill_Item_C:SetCancel(pet)
  self:SetWidgetVisibilityByName("energyNormalBG", ESlateVisibility.Collapsed)
  self.CastPet = pet
  self.skill = nil
  self.id = -1
  self.IsCancel = true
  self:SetWidgetVisibilityByName("TxtCDNew", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("emptyImage", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("normalBG", ESlateVisibility.HitTestInvisible)
  self:SetWidgetVisibilityByName("normalBG_1", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("IconMask", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("Name", ESlateVisibility.HitTestInvisible)
  self:SetWidgetVisibilityByName("ppBg", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("TxtPP", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("EffectSwitcher", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("powerBg", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("Attr1", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("Attr2", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("AttrBg1", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("AttrBg2", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("TxtPower", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("BanImage", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("TxtRepeat", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("energyNormalBG", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("StarBlocker", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("Cancel", ESlateVisibility.HitTestInvisible)
  self.TxtSkillName:SetText(LuaText.umg_battle_skill_item_1)
  self:SetTopStarState(StarState.Invalid)
  self:SetRestrainEffect(true)
end

function UMG_Battle_Skill_Item_C:OnBattleEvent(eventName, ...)
  if eventName == BattlePerformEvent.SkillSync then
    local skillId = (...)
    if self.skill and self.skill.id == skillId then
      self:_Refresh(self.skill)
    end
  elseif eventName == BattleEvent.BATTLE_CLICKED_SKILL then
    self:SetOnClickTimeLimit()
  elseif eventName == BattleEvent.ChangeGatherState then
    local intoGatherState, skillID, guid = ...
    self:ChangeGatherState(intoGatherState, skillID, guid)
  end
end

function UMG_Battle_Skill_Item_C:ChangeGatherState(intoGatherState, skillID, guid)
  if self.CastPet == nil or guid and guid ~= self.CastPet.guid then
    return
  end
  if not self.skill then
    return
  end
  if self.skill.id == skillID then
    return
  end
  if intoGatherState then
    self.isLeaderBattlePreCalcGather = true
    self:SetBubbleColor(false)
    self:SetWidgetVisibilityByName("Mask", ESlateVisibility.Visible)
  else
    self.isLeaderBattlePreCalcGather = intoGatherState
  end
end

function UMG_Battle_Skill_Item_C:SetB1FinalP3FinalSkill(state)
  self.bIsB1FinalP3FinalSkill = state
end

function UMG_Battle_Skill_Item_C:SetIndex(Index)
  self.curIndex = Index
end

function UMG_Battle_Skill_Item_C:SetData(skillEntity, stateName, pet, father, showEmpty, fantasticBackgroundPath)
  self:SetWidgetVisibilityByName("energyNormalBG", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("BeastSkill", ESlateVisibility.Collapsed)
  self.CastPet = pet
  self.IsCancel = false
  self.fatherList = father
  self.bRestrainEffectOpen = -1
  self.currentStateName = stateName
  self.fantasticBackgroundPath = fantasticBackgroundPath
  self:SetVisibility(ESlateVisibility.Visible)
  self.newDataModel = {}
  local dataModelRound = _G.BattleManager:GetCurRound()
  dataModelRound = BattleUtils.IsTeam() and _G.BattleManager.battleRuntimeData.startRoundSelectRoundIndex or dataModelRound
  self.newDataModel.round = dataModelRound
  if skillEntity then
    self:SetWidgetVisibilityByName("CanvasPanel_0", ESlateVisibility.SelfHitTestInvisible)
    self:SetWidgetVisibilityByName("EmptyCanvas", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("emptyImage", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("normalBG", ESlateVisibility.Visible)
    self:SetWidgetVisibilityByName("IconMask", ESlateVisibility.Visible)
    self:SetWidgetVisibilityByName("Name", ESlateVisibility.Visible)
    self:SetWidgetVisibilityByName("TxtCDNew", ESlateVisibility.Visible)
    self:SetWidgetVisibilityByName("ppBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("TxtPP", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("EffectSwitcher", ESlateVisibility.SelfHitTestInvisible)
    self:SetWidgetVisibilityByName("BanImage", ESlateVisibility.Collapsed)
    self:SetRestrainEffect(false)
  else
    self.skill = nil
    self.id = -1
    if showEmpty then
      self:SetWidgetVisibilityByName("CanvasPanel_0", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("EmptyCanvas", ESlateVisibility.SelfHitTestInvisible)
    else
      self:SetWidgetVisibilityByName("EmptyCanvas", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("CanvasPanel_0", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("emptyImage", ESlateVisibility.Visible)
      self:SetWidgetVisibilityByName("normalBG", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("IconMask", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("Name", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("TxtCDNew", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("ppBg", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("TxtPP", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("EffectSwitcher", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("BanImage", ESlateVisibility.Collapsed)
      self:SetRestrainEffect(false)
      self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("powerBg", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("Attr1", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("Attr2", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("AttrBg1", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("AttrBg2", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("TxtPower", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("TxtRepeat", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("energyNormalBG", ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("StarBlocker", ESlateVisibility.Collapsed)
      self:SetTopStarState(StarState.Invalid)
    end
    return
  end
  self.skill = skillEntity
  self.newSkill = _G.BattleManager.battleRuntimeData:GetNewSkillBySpEnergy(skillEntity)
  local canCast, reason = skillEntity:CanCast()
  local castStateMap = {
    [BattleEnum.StateNames.RoundSelect] = true,
    [BattleEnum.StateNames.B1FinalBattleP3FinalSkill] = true
  }
  self.canCast = canCast and (castStateMap[stateName] or self:GetSpecialShowState(stateName))
  local GlobalSkill = self.CastPet.skillComponent:GetSkillWithType(Enum.SkillActiveType.SAT_GLOBAL)
  if BuffUtils.IsGatherBuffEx(self.isLeaderBattlePreCalcGather, self.CastPet) and self.skill ~= GlobalSkill[1] then
    if self.skill.id == self.CastPet.card:GetCurrentGatherSkill() then
      self.canCast = true
    else
      self.canCast = self.canCast and self.skill.skillData.enable_on_charging
    end
  end
  self.id = skillEntity.config.id
  self.config = skillEntity.config
  self:_Refresh(skillEntity, stateName)
  self:ShowSkillId()
  local damageType = self.skill.skillData.damage_type or self.config.damage_type
  if 1 ~= damageType and not BattleUtils:IsFirstMeetAllEnemyPet(_G.BattleManager.battlePawnManager.playerTeam.player) then
    self.restrainType = self.skill:GetRestraint()
    if self.restrainType == BattleEnum.TypeRestraint.ENUM_NORMAL then
      self.EffectSwitcher:SetActiveWidgetIndex(RestraintEffectIndexType.Normal)
      self.newDataModel.EffectSwitcherType = RestraintEffectIndexType.Normal
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_RESTRAINT then
      self.EffectSwitcher:SetActiveWidgetIndex(RestraintEffectIndexType.Restraint)
      self.newDataModel.EffectSwitcherType = RestraintEffectIndexType.Restraint
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_WEAK then
      self.EffectSwitcher:SetActiveWidgetIndex(RestraintEffectIndexType.Weak)
      self.newDataModel.EffectSwitcherType = RestraintEffectIndexType.Weak
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_RESTRAINT_DOUBLE then
      self.EffectSwitcher:SetActiveWidgetIndex(RestraintEffectIndexType.RestraintDouble)
      self.newDataModel.EffectSwitcherType = RestraintEffectIndexType.RestraintDouble
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_WEAK_DOUBLE then
      self.EffectSwitcher:SetActiveWidgetIndex(RestraintEffectIndexType.WeakDouble)
      self.newDataModel.EffectSwitcherType = RestraintEffectIndexType.WeakDouble
    else
      self:SetWidgetVisibilityByName("EffectSwitcher", ESlateVisibility.Collapsed)
    end
  else
    self:SetWidgetVisibilityByName("EffectSwitcher", ESlateVisibility.Collapsed)
  end
  self:SetSkillType(skillEntity)
  self:CheckB1FinalBattleP2UI()
  self:SetWidgetVisibilityByName("Cancel", ESlateVisibility.Collapsed)
  local petGuid = self.CastPet and self.CastPet.guid
  if self.fatherList then
    self.fatherList:UpdateItemDataModel(petGuid, self:GetDataModelSkillId(), self.newDataModel)
  end
  self.newDataModel = {}
end

function UMG_Battle_Skill_Item_C:SetGrayColor()
  self:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#878787FF"))
end

function UMG_Battle_Skill_Item_C:RecoverColor()
  self:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFFFFFFF"))
end

function UMG_Battle_Skill_Item_C:SetInb1FinalP3FinalSkill()
  self.isInb1FinalP3FinalSkill = true
  self:SetWidgetVisibilityByName("powerBg", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("TxtPower", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("energyNormalBG", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("ppBg", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("TxtPP", ESlateVisibility.Collapsed)
  self:UpdateWidgetVisibilityInWaitingList()
end

function UMG_Battle_Skill_Item_C:PlayGradePointLoopAnim()
  self:PlayAnimation(self.Grade_light_loop, 0, 0)
end

function UMG_Battle_Skill_Item_C:StopGradePointLoopAnim()
  self:StopAnimation(self.Grade_light_loop)
  self.Fx_Grade_light:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Skill_Item_C:CheckB1FinalBattleP2UI()
  if not BattleUtils.IsB1FinalBattleP2() and not BattleUtils.IsB1FinalBattleP3() then
    return
  end
  local GlobalSkill = self.CastPet.skillComponent:GetSkillWithType(Enum.SkillActiveType.SAT_GLOBAL)
  if self.skill == GlobalSkill[1] then
    return
  end
  self:SetWidgetVisibilityByName("Fx_Grade", ESlateVisibility.SelfHitTestInvisible)
  self:SetWidgetVisibilityByName("GradePointAverage_1", ESlateVisibility.SelfHitTestInvisible)
  self:SetWidgetVisibilityByName("sppBg_GradePointAverage", ESlateVisibility.SelfHitTestInvisible)
  self:CheckShowB1FinalBattleP3GuideLight()
end

function UMG_Battle_Skill_Item_C:CheckShowB1FinalBattleP3GuideLight()
  if not BattleUtils.IsB1FinalBattleP3() then
    return
  end
  local roundIndex = _G.BattleManager.battleRuntimeData.roundIndex
  if roundIndex and 1 == roundIndex then
    if BattleUtils.CheckIfSkillB1FinalBan(nil, self.skill) then
      self:SetGrayColor()
    else
      self:PlayGradePointLoopAnim()
    end
  else
    self:RecoverColor()
    self:StopGradePointLoopAnim()
  end
end

function UMG_Battle_Skill_Item_C:ShowSkillId()
  if _G.ShowSKillIdInSkillPanel then
    self:SetWidgetVisibilityByName("SkillId", ESlateVisibility.SelfHitTestInvisible)
    self.SkillId:SetText(self.skill.id)
    self.SkillId:SetText(self.skill.skill_id)
  else
    self:SetWidgetVisibilityByName("SkillId", ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Skill_Item_C:SetIconInfo(pet)
  self:SetWidgetVisibilityByName("IconMask", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("rest", ESlateVisibility.SelfHitTestInvisible)
  self:SetWidgetVisibilityByName("Name", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("normalBG_1", ESlateVisibility.Collapsed)
  local petEnergy = pet:GetEnergy()
  local petMaxEnergy = pet:GetMaxEnergy()
  if BattleUtils.IsB1FinalBattleP2() then
    self.Txt:SetText(petEnergy)
  else
    local restEnergyTextTemplate = "%s/%s"
    self.Txt:SetText(string.format(restEnergyTextTemplate, petEnergy, petMaxEnergy))
  end
  if self.skill then
    self.NRCText_78:SetText(self.skill.config.name)
  end
  if self.newSkill and BattleUtils.IsB1FinalBattleP2() then
    self.NRCImage_63:SetPath(self.newSkill.icon)
  end
end

function UMG_Battle_Skill_Item_C:SetSkillType(skillEntity)
  local SkillTypes = self:RemoveSameSkillType(skillEntity.skillData.extra_damage_type)
  if skillEntity.skillData.disable_conf_dam_type then
    if SkillTypes and 1 == #SkillTypes then
    elseif not SkillTypes or 2 == #SkillTypes then
    end
    self:SetTypeIcon(skillEntity, 1)
  else
    self:SetTypeIcon(skillEntity, 2)
    if skillEntity.config.skill_dam_type ~= Enum.SkillDamType.SDT_RELAX then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(skillEntity.config.skill_dam_type)
      local iconPath = typeDic and typeDic.type_icon or nil
      if iconPath then
        self:SetWidgetVisibilityByName("Attr1", ESlateVisibility.SelfHitTestInvisible)
        self.newDataModel.Attr1IconPath = iconPath
        self.newDataModel.DamageType1 = skillEntity.config.skill_dam_type or -1
        self.Attr1:SetPath(iconPath)
        self:SetWidgetVisibilityByName("AttrBg1", ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
end

function UMG_Battle_Skill_Item_C:RemoveSameSkillType(_ExtraDamageType)
  return SkillUtils.GetUniqueExtraDamageTypes(_ExtraDamageType)
end

function UMG_Battle_Skill_Item_C:SetTypeIcon(skillEntity, Index)
  local SkillTypes = self:RemoveSameSkillType(skillEntity.skillData.extra_damage_type)
  local Count = 1
  if SkillTypes and #SkillTypes > 0 then
    for i = Index, 3 do
      local SkillType = SkillTypes[Count]
      if SkillType then
        local typeDic = _G.DataConfigManager:GetTypeDictionary(SkillType)
        if self["Attr" .. i] then
          local iconPath = typeDic and typeDic.type_icon or nil
          if iconPath then
            self:SetWidgetVisibilityByName("Attr" .. i, ESlateVisibility.SelfHitTestInvisible)
            self:SetWidgetVisibilityByName("AttrBg" .. i, ESlateVisibility.SelfHitTestInvisible)
            self.newDataModel["Attr" .. i .. "IconPath"] = iconPath
            self.newDataModel["DamageType" .. i] = SkillType or -1
            self["Attr" .. i]:SetPath(iconPath)
          else
            self:SetWidgetVisibilityByName("Attr" .. i, ESlateVisibility.Collapsed)
            self:SetWidgetVisibilityByName("AttrBg" .. i, ESlateVisibility.Collapsed)
          end
        end
      elseif self["Attr" .. i] then
        self:SetWidgetVisibilityByName("Attr" .. i, ESlateVisibility.Collapsed)
        self:SetWidgetVisibilityByName("AttrBg" .. i, ESlateVisibility.Collapsed)
      end
      Count = Count + 1
    end
  else
    self:SetWidgetVisibilityByName("Attr1", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("Attr2", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("AttrBg1", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("AttrBg2", ESlateVisibility.Collapsed)
  end
  local Length = SkillTypes and #SkillTypes or 0
  if Length and self.CurrentType and (Length > 0 or self.CurrentType > 0) then
    if Length > self.CurrentType then
    elseif Length < self.CurrentType then
    end
    self.CurrentType = Length
  end
end

function UMG_Battle_Skill_Item_C:SetWidgetVisibilityByName(widgetName, visibility)
  if nil == widgetName then
    return
  end
  if not self.widgetVisibilityMap then
    Log.Warning("UMG_Battle_Skill_Item_C widgetVisibilityMap is nil")
    return
  end
  if self.widgetVisibilityMap[widgetName] == visibility then
    return
  end
  self.widgetVisibilityMap[widgetName] = visibility
  if self.waitingForUpdateVisibilityWidgetMap[widgetName] then
    return
  end
  self.waitingForUpdateVisibilityWidgetMap[widgetName] = true
  if nil == self.updateWidgetVisibilityInWaitingListDelayHandler then
    self.updateWidgetVisibilityInWaitingListDelayHandler = _G.DelayManager:DelayFrames(2, self.UpdateWidgetVisibilityInWaitingList, self)
  end
end

function UMG_Battle_Skill_Item_C:SetWidgetVisibility(widget, visibility)
  if nil == widget then
    return
  end
  if not self.widgetToNameMap[widget] then
    self.widgetToNameMap[widget] = widget:GetName()
  end
  self:SetWidgetVisibilityByName(self.widgetToNameMap[widget], visibility)
end

function UMG_Battle_Skill_Item_C:UpdateWidgetVisibilityInWaitingList()
  Log.Debug("UMG_Battle_Skill_Item_C:UpdateWidgetVisibilityInWaitingList, waitingForUpdateVisibilityWidgetList")
  self.updateWidgetVisibilityInWaitingListDelayHandler = nil
  for widgetName, _ in pairs(self.waitingForUpdateVisibilityWidgetMap) do
    local widget = self[widgetName]
    if UE4.UObject.IsValid(widget) and widget:IsA(UE4.UWidget) then
      widget:SetVisibility(self.widgetVisibilityMap[widgetName])
    else
      Log.Error("UMG_Battle_Skill_Item_C:UpdateWidgetVisibilityInWaitingList\239\188\140\230\156\170\230\173\163\231\161\174\232\142\183\229\143\150\229\136\176 UWidget\239\188\140\232\175\183\230\163\128\230\159\165 UMG_Battle_Skill_Item_C.SetWidgetVisibility \228\188\160\229\133\165\229\143\130\230\149\176\230\152\175\229\144\166\230\173\163\231\161\174", widgetName)
    end
  end
  self.waitingForUpdateVisibilityWidgetMap = {}
end

function UMG_Battle_Skill_Item_C:SetGroupVisibility(widgets, flag)
  local n = widgets:Length()
  for i = 1, n do
    local widget = widgets:Get(i)
    if widget then
      self:SetWidgetVisibility(widget, flag)
    end
  end
end

function UMG_Battle_Skill_Item_C:SetRestrainEffect(bOpen)
  if self.bRestrainEffectOpen ~= bOpen then
    self.bRestrainEffectOpen = bOpen
    if bOpen then
      if not self:IsAnimationPlaying(self.Btn_Max) then
        self:SetGroupVisibility(self.CriWidgets, ESlateVisibility.HitTestInvisible)
      end
    else
      self:SetGroupVisibility(self.CriWidgets, ESlateVisibility.Collapsed)
      self:StopAnimation(self.Btn_Max)
    end
  end
end

function UMG_Battle_Skill_Item_C:OpenLockIcon()
  self.TxtSkillName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("929086FF"))
  self.normalBG:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("c4c2b6FF"))
end

function UMG_Battle_Skill_Item_C:CloseLockIcon()
  self.TxtSkillName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("272727FF"))
  self.normalBG:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F5EEE1FF"))
end

function UMG_Battle_Skill_Item_C:_Refresh(skillEntity, roundStateType)
  self.IconMask:SetRetainRendering(false)
  self.TxtSkillName:SetText(self.skill.config.name)
  if self.newDataModel then
    self.newDataModel.skillName = self.skill.config.name
  end
  self.Icon:SetPath(self.newSkill.icon, nil)
  local fantasticBackgroundPath = self.fantasticBackgroundPath or ""
  local selectNm3Visibility = UE4.ESlateVisibility.Collapsed
  if not string.IsNilOrEmpty(fantasticBackgroundPath) then
    selectNm3Visibility = UE4.ESlateVisibility.SelfHitTestInvisible
  end
  self.Select_NM_3:SetPath(fantasticBackgroundPath)
  self.Select_NM_3:SetVisibility(selectNm3Visibility)
  if self.newDataModel then
    self.newDataModel.iconPath = self.newSkill.icon
  end
  self:SetEnable(self.canCast)
  self:CloseLockIcon()
  if self.skill:IsBan() or self.skill:IsFeverBan() or self.skill:IsEnvBan() or self.skill:IsLegendaryBan() or self.skill:IsSealBan() or self.skill:IsLegendaryTimeLimitBan() then
    self:SetWidgetVisibilityByName("BanImage", ESlateVisibility.SelfHitTestInvisible)
    self:OpenLockIcon()
  end
  if skillEntity.curCD > 0 then
    Log.Debug("UMG_Battle_Skill_Item_C curCD:", skillEntity.curCD)
    self.TxtCDNew:SetText(tostring(skillEntity.curCD))
    self:SetRestrainEffect(false)
    self:OpenLockIcon()
  else
    self.TxtCDNew:SetText("")
    if self.canCast and skillEntity.skillData then
      self.restrainType = self.skill:GetRestraint()
      if skillEntity.skillData.type == ProtoEnum.SkillActiveType.SAT_ULTIMATE or self.restrainType == BattleEnum.TypeRestraint.ENUM_RESTRAINT then
        self:SetRestrainEffect(true)
      else
        self:SetRestrainEffect(false)
      end
    end
  end
  local energyIsEnough = self.skill:IsCostEnergy() and self.CastPet:GetEnergy() >= self.skill.energy
  local bloodIsEnough = self.skill:IsBloodEnergy() and skillEntity.skillData.cost_hp and self.CastPet.card:GetHp() >= skillEntity.skillData.cost_hp
  if not energyIsEnough and not bloodIsEnough then
    self:OpenLockIcon()
  end
  if not self.canCast then
    self:OpenLockIcon()
  end
  if skillEntity.skillData and self.skill:GetCastCount() > 1 then
    self:SetRestrainEffect(true)
  end
  self:_RefreshEnergy(skillEntity)
  if skillEntity:IsFeverSkill() then
    self:SetRestrainEffect(true)
  end
  if self:_RefreshByType(skillEntity) and self.CastPet.card.petState:GetGather() and self.skill.id == self.CastPet.card:GetCurrentGatherSkill() then
    self:SetTopStarState(StarState.Invalid)
    self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.Collapsed)
  end
  if _G.SkillUtils.IsSkillInFirstTurnState(skillEntity, self.CastPet) then
    if not self:IsAnimationPlaying(self.Buff_Elect_loop) then
      self:PlayAnimation(self.Buff_Elect_loop, 0, 999, 0, 1, true)
    end
  elseif self:IsAnimationPlaying(self.Buff_Elect_loop) then
    self:StopAnimation(self.Buff_Elect_loop)
  end
  local fxAspirationVisibility = ESlateVisibility.Collapsed
  local aspiration3Visibility = ESlateVisibility.Collapsed
  if _G.SkillUtils.IsSkillIsAspiration(skillEntity, self.CastPet) then
    fxAspirationVisibility = ESlateVisibility.SelfHitTestInvisible
    aspiration3Visibility = ESlateVisibility.SelfHitTestInvisible
    if not self:IsAnimationPlaying(self.Aspiration_loop) then
      self:PlayAnimation(self.Aspiration_loop, 0, 9999, 0, 1, true)
    end
  elseif self:IsAnimationPlaying(self.Aspiration_loop) then
    self:StopAnimation(self.Aspiration_loop)
  end
  self:SetWidgetVisibilityByName("Cover_effect", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("Cover_effect_star", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("Fx_icon_light", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("Fx_Aspiration", fxAspirationVisibility)
  self:SetWidgetVisibilityByName("Aspiration_3", aspiration3Visibility)
end

function UMG_Battle_Skill_Item_C:_OnIconImageLoaded()
  if self._bSkillChangeInPlayed then
    self:PlayAnimation(self.Skill_Change_Out)
  else
    self._bIconImageLoaded = true
  end
end

function UMG_Battle_Skill_Item_C:_RefreshEnergy(skillEntity)
  if not skillEntity:IsCostEnergy() then
    return
  end
  
  local function setDam()
    local oriDam = self.newSkill.dam_para[1]
    local serverDam = skillEntity:GetHighestDamage() or oriDam
    local damContent
    if 0 ~= serverDam then
      self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.Collapsed)
      if oriDam < serverDam then
        damContent = string.format(self.PowerStyleInHigh, serverDam)
      elseif serverDam == oriDam then
        damContent = string.format(self.PowerStyleNormal, serverDam)
      else
        damContent = string.format(self.PowerStyleInLow, serverDam)
      end
    else
      damContent = self.PowerStyleZero
      self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.HitTestInvisible)
    end
    self.TxtPower:SetText(damContent)
    self.newDataModel.TxtPowerContent = damContent
  end
  
  if not skillEntity.skillData or skillEntity.skillData.type ~= ProtoEnum.SkillActiveType.SAT_GLOBAL then
    self:SetGroupVisibility(self.PowerWidgets, ESlateVisibility.HitTestInvisible)
    setDam()
  else
    self:SetGroupVisibility(self.PowerWidgets, ESlateVisibility.Collapsed)
  end
  self:SetGroupVisibility(self.PPZeroWidgets, ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.Visible)
  if skillEntity.type == ProtoEnum.SkillActiveType.SAT_GLOBAL then
    self:SetWidgetVisibilityByName("emptyImage", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("normalBG", ESlateVisibility.Collapsed)
  else
    self:SetWidgetVisibilityByName("energyNormalBG", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("normalBG", ESlateVisibility.Visible)
  end
  if not skillEntity.skillData then
    return
  end
  self.skill.skillData = skillEntity.skillData
  self:SetWidgetVisibilityByName("TxtRepeat", ESlateVisibility.Collapsed)
  if skillEntity.skillData.display_hp and skillEntity.skillData.cost_hp and skillEntity.skillData.cost_hp > 0 then
    self:SetTopStarState(StarState.RedHeart)
    self:SetWidgetVisibilityByName("StarBlocker", ESlateVisibility.Visible)
    local CostHp = skillEntity.skillData.cost_hp
    if CostHp > self.CastPet.card:GetHp() then
      self.canCast = false
    end
    self.TxtSPP:SetText(string.format("<black>%d</>", math.floor(CostHp)))
    self.newDataModel.TxtSppContent = string.format("<black>%d</>", math.floor(CostHp))
    if self.canCast then
      if skillEntity.curCD > 0 then
        self:SetBubbleColor(false)
        self:SetWidgetVisibilityByName("Mask", ESlateVisibility.Visible)
      else
        self:SetBubbleColor(true)
        self:SetWidgetVisibilityByName("Mask", ESlateVisibility.Collapsed)
      end
    else
      self:SetBubbleColor(false)
      self:SetWidgetVisibilityByName("Mask", ESlateVisibility.Visible)
    end
  elseif skillEntity:IsCostEnergy() and 0 == skillEntity.energy and 0 == skillEntity.config.energy_cost[1] then
    self:SetTopStarState(StarState.Invalid)
    self:SetWidgetVisibilityByName("StarBlocker", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.Collapsed)
  else
    self:SetWidgetVisibilityByName("StarBlocker", ESlateVisibility.Collapsed)
    local CostEnergy = skillEntity.energy
    self.TxtSPP:SetText(string.format("<black>%d</>", CostEnergy))
    self.newDataModel.TxtSppContent = string.format("<black>%d</>", CostEnergy)
    self:SetEnergyChangeState(skillEntity)
  end
end

function UMG_Battle_Skill_Item_C:_RefreshByType(skillEntity)
  if skillEntity.config.type == ProtoEnum.SkillActiveType.SAT_IDLE then
    self:SetWidgetVisibilityByName("Attr1", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("Attr2", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("AttrBg1", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("AttrBg2", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("ppBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("TxtPP", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("powerBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("normalBG", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("energyNormalBG", ESlateVisibility.SelfHitTestInvisible)
    self:SetTopStarState(StarState.Invalid)
    self:SetEnable(true)
    return false
  elseif skillEntity.config.type == ProtoEnum.SkillActiveType.SAT_LACKENERGY then
    self:SetWidgetVisibilityByName("Attr1", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("Attr2", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("AttrBg1", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("AttrBg2", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("ppBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("TxtPP", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("powerBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.Collapsed)
    if 0 ~= skillEntity.energy then
      self.TxtSPP:SetText(string.format("<black>%d</>", skillEntity.energy))
      self.newDataModel.TxtSppContent = string.format("<black>%d</>", skillEntity.energy)
      self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.SelfHitTestInvisible)
      self:SetTopStarState(StarState.NormalStar)
    else
      self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.Collapsed)
      self:SetTopStarState(StarState.Invalid)
    end
    self:SetWidgetVisibilityByName("normalBG", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("energyNormalBG", ESlateVisibility.SelfHitTestInvisible)
    self:SetEnable(true)
    return false
  elseif skillEntity.config.type == ProtoEnum.SkillActiveType.SAT_GLOBAL then
    self:SetWidgetVisibilityByName("Attr1", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("Attr2", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("AttrBg1", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("AttrBg2", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("ppBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("TxtPP", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("powerBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.Collapsed)
    self:SetWidgetVisibilityByName("normalBG", ESlateVisibility.Collapsed)
    self:SetTopStarState(StarState.Invalid)
    self:SetEnable(true)
    return false
  elseif skillEntity.config.type == ProtoEnum.SkillActiveType.SAT_LEGENDARY then
    self:SetWidgetVisibilityByName("BeastSkill", ESlateVisibility.SelfHitTestInvisible)
    return true
  end
end

function UMG_Battle_Skill_Item_C:SetTopStarState(state)
  if state == StarState.Invalid then
    self:SetWidgetVisibilityByName("TopStarSwitcher", ESlateVisibility.Collapsed)
  else
    if BattleUtils.IsB1FinalBattleP2() or BattleUtils.IsB1FinalBattleP3() then
      state = StarState.GradePoint
    end
    self:SetWidgetVisibilityByName("TopStarSwitcher", ESlateVisibility.SelfHitTestInvisible)
    self.TopStarSwitcher:SetActiveWidgetIndex(state)
  end
  if self.newDataModel then
    self.newDataModel.TopStarSwitcherType = state
  end
end

function UMG_Battle_Skill_Item_C:SetEnergyChangeState(skillEntity)
  if skillEntity then
    local energy_change = skillEntity:GetEnergyChangeValue()
    if nil ~= energy_change then
      if energy_change > 0 then
        self.TxtSPP:SetText(string.format("<red>%d</>", skillEntity.energy))
        self.newDataModel.TxtSppContent = string.format("<red>%d</>", skillEntity.energy)
        self:SetTopStarState(StarState.RedStar)
      elseif 0 == energy_change then
        self.TxtSPP:SetText(string.format("<black>%d</>", skillEntity.energy))
        self.newDataModel.TxtSppContent = string.format("<black>%d</>", skillEntity.energy)
        self:SetTopStarState(StarState.NormalStar)
      else
        self.TxtSPP:SetText(string.format("<pow_green>%d</>", skillEntity.energy))
        self.newDataModel.TxtSppContent = string.format("<pow_green>%d</>", skillEntity.energy)
        self:SetTopStarState(StarState.GreenStar)
      end
    end
  end
end

function UMG_Battle_Skill_Item_C:SetColor(color)
  self.BtnSkill:SetColorAndOpacity(color)
end

function UMG_Battle_Skill_Item_C:SetEnable(flag)
  if flag then
    self:SetWidgetVisibilityByName("Mask", ESlateVisibility.Collapsed)
  else
    self:SetWidgetVisibilityByName("Mask", ESlateVisibility.HitTestInvisible)
  end
  self:SetBubbleColor(flag)
end

function UMG_Battle_Skill_Item_C:OnItemPressed()
  self:_OnItemPressed()
end

function UMG_Battle_Skill_Item_C:_OnItemPressed()
  self._pressed = true
  self._covered = true
  self._timer = self._longPressThreshold
end

function UMG_Battle_Skill_Item_C:_OnItemHovered()
  self._covered = true
  if self.fatherList then
    self.fatherList:CheckShouldTip(self, true)
  end
end

function UMG_Battle_Skill_Item_C:_OnItemUnHovered()
  self._covered = false
end

function UMG_Battle_Skill_Item_C:_OnItemRelease()
  if self._pressed then
    self:DoClick()
  end
  self._pressed = false
  self._covered = false
end

function UMG_Battle_Skill_Item_C:OnItemRelease()
  self:_OnItemRelease()
end

function UMG_Battle_Skill_Item_C:GetIsCover()
  return self._covered
end

function UMG_Battle_Skill_Item_C:DoLongClick()
  self._pressed = false
  self._timer = 0
  local ForbidClickState = _G.NRCModuleManager:DoCmd(_G.BattleTutorialGuideModuleCmd.GetIsForBidSkillClick)
  if ForbidClickState and ForbidClickState == Enum.BattleLeadFinishType.BLFT_BUTTON_SHORT_PRESS then
    return
  end
  if ForbidClickState and ForbidClickState == Enum.BattleLeadFinishType.BLFT_BUTTON_LONG_PRESS then
    local eventParam = self:GetBattleGuidanceLocationByIndex()
    if eventParam then
      _G.NRCEventCenter:DispatchEvent(BattleTutorialGuideModuleEvent.BtnClickEvent, eventParam)
    end
  end
  self:ShowTips()
end

function UMG_Battle_Skill_Item_C:ShowTips()
  if self.skill then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenSkillTips, {
      skillData = self.skill.skillData,
      skillEntity = self.skill,
      HideClose = false,
      closeInputActionType = UMG_Common_Skill_Tips_C.CloseInputActionType.BattleSkillItem,
      callbackOwner = self,
      openCallback = self.OnSkillTipsOpen,
      closeCallback = self.OnSkillTipsClose
    })
  end
end

function UMG_Battle_Skill_Item_C:GetBattleGuidanceLocationByIndex()
  if 1 == self.curIndex then
    return Enum.BattleGuidanceLocation.BGL_SKILL_1
  elseif 2 == self.curIndex then
    return Enum.BattleGuidanceLocation.BGL_SKILL_2
  elseif 3 == self.curIndex then
    return Enum.BattleGuidanceLocation.BGL_SKILL_3
  elseif 4 == self.curIndex then
    return Enum.BattleGuidanceLocation.BGL_SKILL_4
  end
  return nil
end

function UMG_Battle_Skill_Item_C:UpdateTips()
  if self.skill then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.UpdateSkillTips, {
      skillData = self.skill.skillData,
      skillEntity = self.skill,
      HideClose = false
    })
  end
end

function UMG_Battle_Skill_Item_C:CloseTips()
  self._pressed = false
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseSkillTips)
end

function UMG_Battle_Skill_Item_C:Tick(geometry, deltaTime)
  if self.IsTimeLimit then
    self.StartTime = self.StartTime + 1
    if self.StartTime >= self.EndTime then
      self.StartTime = 0
      self.IsTimeLimit = false
    end
  end
  if not self._pressed then
    return
  end
  self._timer = self._timer - deltaTime
  if self._timer <= 0 then
    self:DoLongClick()
  end
end

function UMG_Battle_Skill_Item_C:OnBtnIdleClick()
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PET_SELECT_IDLE)
end

function UMG_Battle_Skill_Item_C:OnDialogCallback(result)
  if result then
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PET_SELECT_IDLE)
  end
end

function UMG_Battle_Skill_Item_C:PlayMagic()
  self:PlayAnimation(self.Btn_noe_Magic)
end

function UMG_Battle_Skill_Item_C:GetNewSkill()
  return self.newSkill
end

function UMG_Battle_Skill_Item_C:HidePoint()
  self:SetWidgetVisibilityByName("point0", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("point1", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("point2", ESlateVisibility.Collapsed)
  self:SetWidgetVisibilityByName("point3", ESlateVisibility.Collapsed)
end

function UMG_Battle_Skill_Item_C:HideBubble()
end

function UMG_Battle_Skill_Item_C:OnDestruct()
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
    self.delayID = nil
  end
end

function UMG_Battle_Skill_Item_C:DelayPlayAnim(_IsOpen, i)
  self:StopAllInfoChangeAnimations()
  self:CancelAllOpenAnimationDelay()
  if self.fatherList then
    local petGuid = self.CastPet and self.CastPet.guid
    local dataModelChange = self.fatherList:GetItemDataModelChangeInfo(petGuid, self:GetDataModelSkillId())
    if dataModelChange and dataModelChange.before then
      local before = dataModelChange.before
      local after = dataModelChange.after
      self:RefreshWithDataModel(before)
      local skillData = self.skill and self.skill.skillData
      local change_src_skill = skillData and skillData.change_src_skill
      local dataModelSkillId = self:GetDataModelSkillId()
      if change_src_skill and 0 ~= change_src_skill and dataModelSkillId ~= self.id then
        if after.iconPath then
          self.Icon_1:SetPath(after.iconPath)
        end
        if before.iconPath then
          self.Icon_2:SetPath(before.iconPath)
        end
      else
        self.Icon:SetPath(after.iconPath)
      end
    end
  end
  local interval = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenInterval or 0.04
  if self.delayPlayOpenAnimationHandler then
    _G.DelayManager:CancelDelayById(self.delayPlayOpenAnimationHandler)
  end
  self.delayPlayOpenAnimationHandler = _G.DelayManager:DelaySeconds(i * interval, self.PlayOpenAnimation, self, _IsOpen)
end

function UMG_Battle_Skill_Item_C:StopCurrentOpenAnimation()
  if self:IsAnimationPlaying(self.open) then
    self:StopAnimation(self.open)
  end
  if self:IsAnimationPlaying(self.Change_open) then
    self:StopAnimation(self.Change_open)
  end
  if self:IsAnimationPlaying(self.Skill_change2) then
    self:StopAnimation(self.Skill_change2)
  end
end

function UMG_Battle_Skill_Item_C:PlayOpenAnimation(_IsOpen)
  if self.delayPlayOpenAnimationHandler then
    _G.DelayManager:CancelDelayById(self.delayPlayOpenAnimationHandler)
    self.delayPlayOpenAnimationHandler = nil
  end
  self:HidePoint()
  if _IsOpen then
    self:RandVisiblePoint()
    local openAnimSpeedRate = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenAnimSpeedRate or 1
    if not BattleUtils.IsMainWindowChangingBetweenSubPanels() then
      local petGuid = self.CastPet and self.CastPet.guid
      local skillId = self:GetDataModelSkillId()
      if self.fatherList and self.fatherList:ShouldPlayChangeSkill2(petGuid, skillId) then
        self.CanvasPanel_0:SetRenderOpacity(1)
        self.CanvasPanel_0:SetRenderScale(UE4.FVector2D(1, 1))
        self:PlayAnimation(self.Skill_change2)
        self:BindToAnimationFinished(self.Skill_change2, self.OnOpenAnimFinishedDelegate)
        self.delayHideRelativeChangeSkillPosItemHandler = _G.DelayManager:DelaySeconds(0.2, function()
          if self.fatherList and UE.UObject.IsValid(self.fatherList) then
            self.fatherList:HideRelativeChangePositionSkillItem(petGuid, skillId)
          end
        end)
        _G.NRCAudioManager:PlaySound2DAuto(BattleConst.ChangeSkillPositionParams.SkillChange2AudioId, "UMG_Battle_Skill_Item_C:PlayOpenAnimation")
      else
        self:PlayAnimation(self.open, 0, 1, 0, openAnimSpeedRate)
        self:BindToAnimationFinished(self.open, self.OnOpenAnimFinishedDelegate)
      end
    else
      self:PlayAnimation(self.Change_open, 0, 1, 0, openAnimSpeedRate)
      self:BindToAnimationFinished(self.Change_open, self.OnOpenAnimFinishedDelegate)
    end
  else
    self:StopAllInfoChangeAnimations()
    if self.fatherList then
      local petGuid = self.CastPet and self.CastPet.guid
      local dataModelChange = self.fatherList:GetItemDataModelChangeInfo(petGuid, self:GetDataModelSkillId())
      if dataModelChange and dataModelChange.after then
        self:RefreshWithDataModel(dataModelChange.after)
      end
    end
    if not BattleUtils.IsMainWindowChangingBetweenSubPanels() then
      self:PlayAnimation(self.close)
    else
      self:PlayAnimation(self.Change_close)
    end
  end
end

function UMG_Battle_Skill_Item_C:RandVisiblePoint()
  if self.skill then
    local Rand = math.random(0, 3)
    if self["point" .. Rand] then
      if self.Mask:GetVisibility() == ESlateVisibility.Visible or self.Mask:GetVisibility() == ESlateVisibility.SelfHitTestInvisible then
        self["point" .. Rand]:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFFFFFFF"))
      else
        self["point" .. Rand]:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#000000B3"))
      end
      self:SetWidgetVisibilityByName("point" .. Rand, ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_Battle_Skill_Item_C:SetBubbleColor(IsWhite)
  if not IsWhite then
    self.Bubble:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#C4C2B6FF"))
  else
    self.Bubble:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#F5EEE1FF"))
  end
end

function UMG_Battle_Skill_Item_C:SetNewSkillData(skillEntity, stateName, pet, father)
  self:playAnimation(self.Skill_Change_In)
  self.newSkillData = skillEntity
  self.newStateName = stateName
  self.newPet = pet
  self.newFather = father
end

function UMG_Battle_Skill_Item_C:SetNewSkillUI()
  self:SetData(self.newSkillData, self.newStateName, self.newPet, self.newFather)
end

function UMG_Battle_Skill_Item_C:OnSkillTipsOpen()
  self.OpenCommonTips = true
end

function UMG_Battle_Skill_Item_C:OnSkillTipsClose()
  self.OpenCommonTips = false
end

function UMG_Battle_Skill_Item_C:OnOpenAnimationFinished()
  self:UnbindFromAnimationFinished(self.open, self.OnOpenAnimFinishedDelegate)
  self:UnbindFromAnimationFinished(self.Change_open, self.OnOpenAnimFinishedDelegate)
  self:UnbindFromAnimationFinished(self.Skill_change2, self.OnOpenAnimFinishedDelegate)
  self:PlayInfoChangeAnimation()
end

function UMG_Battle_Skill_Item_C:PlayInfoChangeAnimation()
  local petGuid = self.CastPet and self.CastPet.guid
  Log.Info("UMG_Battle_Skill_Item_C:PlayInfoChangeAnimation", self:GetDataModelSkillId())
  if not self.fatherList then
    return
  end
  local dataModelChange = self.fatherList:GetItemDataModelChangeInfo(petGuid, self:GetDataModelSkillId())
  if not dataModelChange then
    return
  end
  local afterDataModel = dataModelChange.after
  local beforeDataModel = dataModelChange.before
  self.fatherList:ClearItemDataModelBefore(petGuid, self:GetDataModelSkillId())
  if not afterDataModel then
    return
  end
  self:RefreshWithDataModel(afterDataModel, true)
  if afterDataModel and beforeDataModel then
    if beforeDataModel.TxtPowerContent ~= afterDataModel.TxtPowerContent then
      self:PlayAnimation(self.Powertxt_change)
    end
    if beforeDataModel.TopStarSwitcherType ~= afterDataModel.TopStarSwitcherType or beforeDataModel.TxtSppContent ~= afterDataModel.TxtSppContent then
      self:PlayAnimation(self.TopStarSwitcher_change)
    end
    if beforeDataModel.Attr1IconPath ~= afterDataModel.Attr1IconPath then
      self:PlayAnimation(self.Attr_change)
      if afterDataModel.DamageType1 then
        local colorHex = BattleConst.DamageTypeColor[afterDataModel.DamageType1]
        for i, star in ipairs(self.StarListForAttr1) do
          star.Brush.TintColor = UE4.UNRCStatics.HexToSlateColor(colorHex)
        end
      end
    end
    if beforeDataModel.EffectSwitcherType ~= afterDataModel.EffectSwitcherType then
      self:PlayAnimation(self.ResultBg_change)
      local type = afterDataModel.EffectSwitcherType or -1
      local colorHex = BattleConst.EffectTypeColor[type]
      for i, star in ipairs(self.StarListForEffect) do
        star.Brush.TintColor = UE4.UNRCStatics.HexToSlateColor(colorHex)
      end
    end
    local change_src_skill = self.skill and self.skill.skillData.change_src_skill
    local dataModelSkillId = self:GetDataModelSkillId()
    if change_src_skill and 0 ~= change_src_skill and dataModelSkillId ~= self.id then
      local stealAnimSpeedRate = _G.BattleManager.battleRuntimeData.widgetSpeed.RandomChangeSkillAnimSpeedRate or 1
      self:PlayAnimation(self.Buff_steal_loop, 0, 1, 0, stealAnimSpeedRate)
      self:SetWidgetVisibilityByName("Cover_effect", ESlateVisibility.Visible)
      self:SetWidgetVisibilityByName("Cover_effect_star", ESlateVisibility.Visible)
      self:SetWidgetVisibilityByName("Fx_icon_light", ESlateVisibility.Visible)
      if afterDataModel.iconPath then
        self.Icon_1:SetPath(afterDataModel.iconPath)
      else
        self.Icon_1:SetRenderOpacity(0)
      end
      if beforeDataModel.iconPath then
        self.Icon_2:SetPath(beforeDataModel.iconPath)
      else
        self.Icon_2:SetRenderOpacity(0)
      end
    end
  end
end

function UMG_Battle_Skill_Item_C:StopAllInfoChangeAnimations()
  self:UnbindFromAnimationFinished(self.open, self.OnOpenAnimFinishedDelegate)
  self:UnbindFromAnimationFinished(self.Change_open, self.OnOpenAnimFinishedDelegate)
  self:UnbindFromAnimationFinished(self.Skill_change2, self.OnOpenAnimFinishedDelegate)
  self:StopCurrentOpenAnimation()
end

function UMG_Battle_Skill_Item_C:RefreshWithDataModel(dataModel, followAnim)
  if not dataModel then
    return
  end
  local iconDelaySeconds = followAnim and 0.2 or 0
  if self.delayRefreshIconsWithDataModelHandler then
    _G.DelayManager:CancelDelayById(self.delayRefreshIconsWithDataModelHandler)
    self.delayRefreshIconsWithDataModelHandler = nil
  end
  self.delayRefreshIconsWithDataModelHandler = _G.DelayManager:DelaySeconds(iconDelaySeconds, function()
    self.delayRefreshIconsWithDataModelHandler = nil
    self:RefreshIconsWithDataModel(dataModel)
  end)
  if dataModel.TxtPowerContent ~= nil then
    local canShowPowerWidgets = true
    if self.isInb1FinalP3FinalSkill then
      canShowPowerWidgets = false
    end
    if canShowPowerWidgets then
      self:SetGroupVisibility(self.PowerWidgets, ESlateVisibility.HitTestInvisible)
    end
    self.TxtPower:SetText(dataModel.TxtPowerContent)
    if dataModel.TxtPowerContent == "" then
      self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.SelfHitTestInvisible)
    else
      self:SetWidgetVisibilityByName("powerZeroBg", ESlateVisibility.Collapsed)
    end
  else
    self:SetGroupVisibility(self.PowerWidgets, ESlateVisibility.Collapsed)
  end
  if dataModel.TxtSppContent then
    self.TxtSPP:SetText(dataModel.TxtSppContent)
    self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetWidgetVisibilityByName("TxtSPP", ESlateVisibility.Collapsed)
  end
  if dataModel.TopStarSwitcherType and dataModel.TopStarSwitcherType >= 0 then
    self:SetWidgetVisibilityByName("TopStarSwitcher", ESlateVisibility.SelfHitTestInvisible)
    self.TopStarSwitcher:SetActiveWidgetIndex(dataModel.TopStarSwitcherType)
  else
    self:SetWidgetVisibilityByName("TopStarSwitcher", ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Skill_Item_C:RefreshIconsWithDataModel(dataModel)
  for i = 1, 3 do
    if self["Attr" .. i] and dataModel["Attr" .. i .. "IconPath"] then
      local iconPath = dataModel["Attr" .. i .. "IconPath"]
      self:SetWidgetVisibilityByName("Attr" .. i, ESlateVisibility.SelfHitTestInvisible)
      self:SetWidgetVisibilityByName("AttrBg" .. i, ESlateVisibility.SelfHitTestInvisible)
      dataModel["Attr" .. i .. "IconPath"] = iconPath
      self["Attr" .. i]:SetPath(iconPath)
    elseif self["Attr" .. i] then
      self:SetWidgetVisibilityByName("Attr" .. i, ESlateVisibility.Collapsed)
      self:SetWidgetVisibilityByName("AttrBg" .. i, ESlateVisibility.Collapsed)
    end
  end
  if dataModel.EffectSwitcherType ~= nil then
    self:SetWidgetVisibilityByName("EffectSwitcher", ESlateVisibility.SelfHitTestInvisible)
    self.EffectSwitcher:SetActiveWidgetIndex(dataModel.EffectSwitcherType)
  else
    self:SetWidgetVisibilityByName("EffectSwitcher", ESlateVisibility.Collapsed)
  end
  if dataModel.iconPath then
    Log.Info("UMG_Battle_Skill_Item_C:RefreshIconsWithDataModel icon path = ", dataModel.iconPath)
    self.Icon:SetPath(dataModel.iconPath)
  end
end

function UMG_Battle_Skill_Item_C:GetDataModelSkillId()
  local id = self.id
  local change_src_skill = self.skill and self.skill.skillData.change_src_skill
  if change_src_skill and 0 ~= change_src_skill then
    local skill = self.CastPet and self.CastPet.skillComponent:GetHeadOfChangeSrcSkillChain(self.skill)
    id = _G.SkillUtils.CheckSkillId(skill.id)
  end
  return id
end

return UMG_Battle_Skill_Item_C
