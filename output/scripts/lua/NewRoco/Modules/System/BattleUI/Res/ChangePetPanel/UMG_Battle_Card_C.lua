local Base = _G.NRCPanelBase
local UMG_Battle_Card_C = Base:Extend("UMG_Battle_Card_C")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")

function UMG_Battle_Card_C:OnConstruct()
  Log.Debug("UMG_Battle_Card_C:Construct")
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_PET, BattleEvent.BATTLE_CLICKED_BAG_PET, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL)
  self.TouchButton.OnPressed:Add(self, self._OnItemPressed)
  self.TouchButton.OnReleased:Add(self, self._OnItemRelease)
  self.CardIndex = nil
  self.conf = nil
  self.card = nil
  self._timer = 0
  self._longPressThreshold = BattleConst.ItemLongPressThreshold
  self._pressed = false
  self._covered = false
  self._isSelect = false
  self._canClick = true
  self.curOperateType = BattleEnum.Operation.ENUM_CHANGE
  self.Bg:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Bg_1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Bg_2:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Bg_3:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Battle_Card_C:OnDestruct()
  _G.BattleEventCenter:UnBind(self)
  self.TouchButton.OnPressed:Remove(self, self._OnItemPressed)
  self.TouchButton.OnReleased:Remove(self, self._OnItemRelease)
end

function UMG_Battle_Card_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_CLICKED_PET then
    self:OnPetClicked(...)
  elseif eventName == BattleEvent.BATTLE_CLICKED_BAG_PET then
    self:OnPetIconClicked(...)
  elseif eventName == BattleEvent.CHANGE_OPERATE_TYPE then
    self:OnOperatePanelChanged(...)
  elseif eventName == BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL then
    self:BeginUsePlayerSkill()
  end
end

function UMG_Battle_Card_C:ResetSelect()
  self._isSelect = false
  self:PlayAnimation(self.Btn_Normal)
end

function UMG_Battle_Card_C:Select()
  self._isSelect = true
  if self:IsAnyAnimationPlaying(self.Btn_Normal) then
    self:StopAnimation(self.Btn_Normal)
  end
  self:PlayAnimation(self.Btn_Click)
end

function UMG_Battle_Card_C:DisSelect()
  self._isSelect = false
  if self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.Visible or self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    if self:IsAnyAnimationPlaying(self.Btn_Normal) then
      self:StopAnimation(self.Btn_Normal)
    end
    self:PlayAnimation(self.Btn_Notclick)
  end
end

function UMG_Battle_Card_C:OnOperatePanelChanged(operateType)
  Log.Debug("UMG_Battle_Card_C:OnOperatePanelChanged", operateType)
  self.curOperateType = operateType
  if operateType == BattleEnum.Operation.ENUM_CHANGE then
  else
  end
end

function UMG_Battle_Card_C:OnPetIconClicked(id)
  if not self.card or id ~= self.card.guid then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1004, "UMG_Battle_Card_C:OnPetIconClicked")
  end
end

function UMG_Battle_Card_C:OnPetClicked(pet)
  if self._isSelect and _G.BattleManager.battleRuntimeData.operateType == BattleEnum.Operation.ENUM_CHANGE then
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_CHANGEPET, self.card, pet)
  end
end

function UMG_Battle_Card_C:OnMouseEnter(MyGeometry, MouseEvent)
  self:_OnItemHovered()
end

function UMG_Battle_Card_C:OnMouseLeave(MouseEvent)
  self:_OnItemUnHovered()
end

function UMG_Battle_Card_C:_OnItemPressed()
  Log.Debug("UMG_Battle_Card_C:_OnItemPressed")
  if not self.card then
    return
  end
  self._pressed = true
  self._covered = true
  self._timer = self._longPressThreshold
end

function UMG_Battle_Card_C:_OnItemHovered()
  self._covered = true
  if self.fatherList then
    self.fatherList:CheckShouldTip(self, true)
  end
end

function UMG_Battle_Card_C:OnItemPressed()
  self:_OnItemPressed()
end

function UMG_Battle_Card_C:OnItemRelease()
  self:_OnItemRelease()
end

function UMG_Battle_Card_C:_OnItemUnHovered()
  self._covered = false
end

function UMG_Battle_Card_C:_OnItemRelease()
  if not self.card then
    return
  end
  if self._pressed then
    self:DoClick()
  else
  end
  self._pressed = false
  self._covered = false
end

function UMG_Battle_Card_C:DoClick()
  if not (self.curOperateType == BattleEnum.Operation.ENUM_CHANGE and not BattleUtils.IsWatchingBattle() and self.card and self._canClick) or self.card:IsModelInBattle() then
  elseif self.card:GetHp() > 0 then
    self.UMG_BattleClickFX:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    local onPetClickCallback = self.onPetClickCallback
    local card = self.card
    local guid = card and card.guid
    tcall(nil, onPetClickCallback, guid)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.PET_ALREADY_DEAD)
  end
end

function UMG_Battle_Card_C:BeginUsePlayerSkill()
  self.curOperateType = BattleEnum.Operation.ENUM_CHANGE
end

function UMG_Battle_Card_C:OnAnimationStarted(Animation)
  local OnAnimationStartCallback = self.OnAnimationStartCallback
  if OnAnimationStartCallback then
    tcall(nil, OnAnimationStartCallback, Animation)
  end
end

function UMG_Battle_Card_C:OnAnimationFinished(Animation)
  if self.Btn_Click == Animation then
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif self.Btn_Notclick == Animation then
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local OnAnimationFinishCallback = self.OnAnimationFinishCallback
  if OnAnimationFinishCallback then
    tcall(nil, OnAnimationFinishCallback, Animation)
  end
end

function UMG_Battle_Card_C:GetIsCover()
  return self._covered
end

function UMG_Battle_Card_C:DoLongClick()
  self._pressed = false
  self._timer = 0
  self:OnPetInfoShow()
end

function UMG_Battle_Card_C:Tick(geometry, deltaTime)
  if not self._pressed then
    return
  end
  self._timer = self._timer - deltaTime
  if self._timer <= 0 then
    self:DoLongClick()
  end
end

function UMG_Battle_Card_C:OnPetInfoShow()
  local data = {
    cardData = self.card,
    petData = {
      base_conf_id = self.card.petBaseConf.id,
      extra_sdt = self.card.petInfo.battle_inside_pet_info.extra_sdt
    }
  }
  NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenBattleChangePetConfirmPanel, data)
end

function UMG_Battle_Card_C:OnPetInfoUpdate()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.UpdateChangePetConfirm, self.card, true)
end

function UMG_Battle_Card_C:OnPetInfoClose()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.HideChangePetConfirm, true, true)
end

function UMG_Battle_Card_C:SetData(CardEntity, father)
  self.fatherList = father
  if not CardEntity then
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    self.card = nil
    self:_Refresh(nil)
    return
  end
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self.card = CardEntity
  self.CardIndex = CardEntity.CardIndex
  self.conf = CardEntity.config
  self:_Refresh(CardEntity)
end

function UMG_Battle_Card_C:_Refresh(CardEntity)
  if not CardEntity then
    self.Text_PCKey:SetKeyVisibility(false)
    self.emptyImage:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCSwitcher_BG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_1031:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.StatusTxt:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HealthBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Level:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.statImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetTypeIcon1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetTypeIcon2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetTypeBg1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetTypeBg2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.LevelBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Stars:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_91:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BeastSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetIsWindEffect(false)
    return
  else
    self.emptyImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_BG:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCSwitcher_1031:SetVisibility(UE4.ESlateVisibility.Visible)
    self.StatusTxt:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HealthBar:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Level:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.statImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetTypeIcon1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PetTypeIcon2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PetTypeBg1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PetTypeBg2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.LevelBg:SetVisibility(UE4.ESlateVisibility.Visible)
    self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_91:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local lock = true
  if CardEntity:GetHp() <= 0 then
    self.StatusTxt:SetText("")
  elseif CardEntity:IsModelInBattle() then
    self.StatusTxt:SetText(LuaText.umg_battle_card_1)
  else
    self.StatusTxt:SetText("")
    lock = false
  end
  local hpPercent = CardEntity:GetHpPercent()
  self.HealthBar:SetHP(hpPercent)
  local frozenPercent = CardEntity:GetFrozenPercent()
  self.HealthBar:SetFrozenHp(frozenPercent)
  self.Level:SetText(tostring(CardEntity:GetEnergy()))
  self.HeadIcon:SetIconPathAndMaterial(CardEntity.petBaseConf.id, CardEntity.petInfo.battle_common_pet_info.mutation_type, CardEntity.petInfo.battle_common_pet_info.glass_info)
  if lock then
    self:SetColor(UE4.FLinearColor(0.2, 0.2, 0.2, 1))
  else
    self:SetColor(UE4.FLinearColor(1, 1, 1, 1))
  end
  local petTypeIcons = {
    self.PetTypeIcon1,
    self.PetTypeIcon2
  }
  local baseConf = _G.DataConfigManager:GetPetbaseConf(CardEntity.petInfo.battle_common_pet_info.base_conf_id)
  for index = 1, #baseConf.unit_type do
    local petType = baseConf.unit_type[index]
    if not petType then
      Log.Warning("petType nil")
      return
    end
    local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
    if not typeDic then
      Log.Warning("petType nil")
      return
    end
    petTypeIcons[index]:SetPath(typeDic.type_icon)
  end
  if 1 == #baseConf.unit_type then
    petTypeIcons[2]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetTypeBg2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if baseConf.is_pet_legendary > 0 then
    self.BeastSkill:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.HeartPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PetCostHp:SetText(baseConf.consume_role_hp)
  else
    self.BeastSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeartPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if not BattleUtils:IsFirstMeetAllEnemyPet(_G.BattleManager.battlePawnManager.playerTeam.player) then
    self.restrainType = CardEntity:GetRestraint()
    if self.restrainType == BattleEnum.TypeRestraint.ENUM_NORMAL then
      self.EffectSwitcher:SetActiveWidgetIndex(1)
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_RESTRAINT then
      self.EffectSwitcher:SetActiveWidgetIndex(0)
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_RESTRAINT_DOUBLE then
      self.EffectSwitcher:SetActiveWidgetIndex(3)
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_WEAK then
      self.EffectSwitcher:SetActiveWidgetIndex(2)
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_WEAK_DOUBLE then
      self.EffectSwitcher:SetActiveWidgetIndex(4)
    elseif self.restrainType == BattleEnum.TypeRestraint.ENUM_NONE then
      self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if BattleUtils.IsPetCanCastFastWindSkill(CardEntity) then
    self:SetIsWindEffect(true)
  else
    self:SetIsWindEffect(false)
  end
  local switcherIndex = 0
  local petInfo = CardEntity and CardEntity.petInfo
  local insideInfo = petInfo and petInfo.battle_inside_pet_info
  local sourcePetId = insideInfo and insideInfo.buff145_source_pet or 0
  if 0 ~= sourcePetId then
    switcherIndex = 1
    if CardEntity:GetHp() <= 0 then
      switcherIndex = 3
    elseif CardEntity:GetEnergy() <= 0 then
      switcherIndex = 2
    end
  end
  self.NRCSwitcher_BG:SetActiveWidgetIndex(switcherIndex)
  self.NRCSwitcher_1031:SetActiveWidgetIndex(switcherIndex)
end

function UMG_Battle_Card_C:SetColor(color)
  self.Bg:SetColorAndOpacity(color)
  self.NRCImage:SetColorAndOpacity(color)
  self.HeadIcon:SetColorAndOpacity(color)
end

function UMG_Battle_Card_C:IsSelect()
  return self._isSelect
end

function UMG_Battle_Card_C:DelayPlayOpenAnimation(_IsOpen, i, changingBetweenSubPanels)
  local interval = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenInterval or 0.04
  self:DelaySeconds(i * interval, self.PlayOpenAnimation, self, _IsOpen, changingBetweenSubPanels)
end

function UMG_Battle_Card_C:CancelOpenAnimation()
  self:CancelDelayByFunc(self.PlayOpenAnimation)
end

function UMG_Battle_Card_C:PlayOpenAnimation(_IsOpen, changingBetweenSubPanels)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self:IsAnimationPlaying(self.Change_open) then
    self:StopAnimation(self.Change_open)
  end
  if self:IsAnimationPlaying(self.TweenIn) then
    self:StopAnimation(self.TweenIn)
  end
  if self:IsAnimationPlaying(self.Change_close) then
    self:StopAnimation(self.Change_close)
  end
  if self:IsAnimationPlaying(self.TweenOut) then
    self:StopAnimation(self.TweenOut)
  end
  self.CanvasPanel_0:SetRenderTransformPivot(UE.FVector2D(0.5, 0.5))
  if _IsOpen then
    local openAnimSpeedRate = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenAnimSpeedRate or 1
    if changingBetweenSubPanels then
      self:PlayAnimation(self.Change_open, 0, 1, 0, openAnimSpeedRate)
    else
      self:PlayAnimation(self.TweenIn, 0, 1, 0, openAnimSpeedRate)
    end
  elseif changingBetweenSubPanels then
    self:PlayAnimation(self.Change_close)
  else
    self:PlayAnimation(self.TweenOut)
  end
end

function UMG_Battle_Card_C:OnTipsOpen()
  self.OpenTips = true
end

function UMG_Battle_Card_C:OnTipsClose()
  self.OpenTips = false
end

function UMG_Battle_Card_C:SetOnPetClickCallback(callback, callbackOwner)
  self.onPetClickCallback = _G.MakeWeakFunctor(callbackOwner, callback)
end

function UMG_Battle_Card_C:SetIsWindEffect(isWindEffect)
  if isWindEffect then
    if not self:IsAnimationPlaying(self.Buff_wind_loop) then
      self:PlayAnimation(self.Buff_wind_loop, 0, 999, 0, 1, false)
    end
  else
    if self:IsAnimationPlaying(self.Buff_wind_loop) then
      self:StopAnimation(self.Buff_wind_loop)
    end
    self.Buff_wind:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Card_C:SetOnAnimationStartCallback(callback, callbackOwner)
  self.OnAnimationStartCallback = _G.MakeWeakFunctor(callbackOwner, callback)
end

function UMG_Battle_Card_C:SetOnAnimationFinishCallback(callback, callbackOwner)
  self.OnAnimationFinishCallback = _G.MakeWeakFunctor(callbackOwner, callback)
end

return UMG_Battle_Card_C
