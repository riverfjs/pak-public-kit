local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local Enum = require("Data.Config.Enum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local Timer = require("Utils.Timer")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_Battle_HP_C = NRCUmgClass:Extend("")

function UMG_Battle_HP_C:Construct()
  self.curHp = 0
  self.curPerformHP = 0
  self.curPerformLife = 1
  self.curPerformHPBG = 0
  self.IsPlayFrozen = false
  self.maxHp = 1
  self.targetHp = 0
  self.timer = Timer()
  self.battleManager = _G.BattleManager
  self.OldFrozenParent = 0
  self.leaderTimer = Timer()
  self.isLeaderBattle = false
  self.energyBar = nil
  self.bFirstShow = false
  self.bIsLight = false
  self.HPUILength = self.HpBarSub.Slot:GetSize().X
  self.HPUILeftX = self.HpBarSub.Slot:GetPosition().X - self.HPUILength / 2
  self.HpBarAdd.WidgetStyle.FillImage.TintColor = UE4.UNRCStatics.HexToSlateColor(BattleConst.HpBarColor.Add)
  self.setHpValueQueue = {}
  self.setHpValueContextId = 0
  self.props = {}
  local blood_pr_low = _G.DataConfigManager:GetBattleGlobalConfig("blood_pr_low")
  self.BloodRedPercent = blood_pr_low.numList and blood_pr_low.numList[2] / 10000 or 0.2
  local blood_pr_middle = _G.DataConfigManager:GetBattleGlobalConfig("blood_pr_middle")
  self.BloodYellowPercent = blood_pr_middle.numList and blood_pr_middle.numList[2] / 10000 or 0.5
  self:AddListeners()
  self:SetHPBackEffect(0)
  if self.TxtHp then
    self.TxtHp:SetText("")
  end
  if self.TxtHp2 then
    self.TxtHp2:SetText("")
  end
end

function UMG_Battle_HP_C:WaitingRecycle()
  self:RemoveListeners()
end

function UMG_Battle_HP_C:Destruct()
  if self.battlePet then
    self.battlePet = nil
  end
  self.timer:Clear()
  self.timer = nil
  self:RemoveListeners()
  if self.BarMaterial then
    self.BarMaterial:Release()
  end
  self.energyBar = nil
  self.battleManager = nil
  self.props = {}
  NRCUmgClass.Destruct(self)
end

function UMG_Battle_HP_C:ClearTimer()
  self.timer:Clear()
  self.leaderTimer:Clear()
  self.HPNiagara:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_HP_C:AddListeners()
  BattleEventCenter:Bind(self, BattlePerformEvent.HealBattlePet, BattlePerformEvent.HitBattlePet, BattleEvent.ROUND_START, BattleEvent.DIRECT_UPDATE_UI, BattleEvent.START_BATTLE_PERFORM, BattleEvent.NightmareShieldBreak, BattlePerformEvent.FrozenChange, BattlePerformEvent.WillEnterRewardRound, BattlePerformEvent.EnterRewardRoundPlayOver, BattlePerformEvent.PetHpChange)
end

function UMG_Battle_HP_C:RemoveListeners()
  BattleEventCenter:UnBind(self)
end

function UMG_Battle_HP_C:Tick(geometry, deltaTime)
  self.timer:Update(deltaTime)
  self.leaderTimer:Update(deltaTime)
  self:UpdateSetHpValue(deltaTime)
end

function UMG_Battle_HP_C:ReceiveProps(props)
  self.props = props
end

function UMG_Battle_HP_C:OnRoundStart()
  if self.battlePet then
    self:RefreshHp()
    if self.battlePet.card.isNightMarePet and self.battlePet.card.haveNightMareShield == false then
      self.RoundStartShieldBreak = true
    end
    self:InitFrozenState()
    self:InitWorldLeaderReward()
  end
end

function UMG_Battle_HP_C:OnBattleEvent(eventName, ...)
  if eventName == BattlePerformEvent.HealBattlePet or eventName == BattlePerformEvent.HitBattlePet or eventName == BattlePerformEvent.PetHpChange then
    local option = (...)
    local petId = option.petId
    local change_val = option.change_val
    local imme = option.imme
    local sourceBuffOrSkillOrEffectId = option.sourceBuffOrSkillOrEffectId
    local delaySeconds = option.delaySeconds or 0
    local canInterruptSameTypeContext = true
    local isHeal = eventName == BattlePerformEvent.HealBattlePet
    if self.battlePet and self.battlePet.guid == petId then
      local prevHaveNightMareShield = self.haveNightMareShield
      if self.battlePet.health then
        self.haveNightMareShield = self.battlePet.health:GetMaxShield() > 0
      else
        self.haveNightMareShield = self.battlePet.card.max_shield > 0
      end
      if self.haveNightMareShield ~= prevHaveNightMareShield and self.haveNightMareShield == false then
        self:StartSetHpValue(self.battlePet.health:GetShield(), self.battlePet.health:GetMaxShield(), false, 0, false, true, isHeal)
      end
      if self.battlePet.health then
        if self.haveNightMareShield then
          self:StartSetHpValue(self.battlePet.health:GetShield(), self.battlePet.health:GetMaxShield(), imme, delaySeconds, canInterruptSameTypeContext, true, isHeal)
        else
          self:StartSetHpValue(self.battlePet.health:GetHp(), self.battlePet.health:GetMaxHp(), imme, delaySeconds, canInterruptSameTypeContext, false, isHeal)
        end
      elseif self.haveNightMareShield then
        self:StartSetHpValue(self.battlePet.card.shield, self.battlePet.card.max_shield, imme, delaySeconds, canInterruptSameTypeContext, true, isHeal)
      else
        self:StartSetHpValue(self.battlePet.card.hp, self.battlePet.card.max_hp, imme, delaySeconds, canInterruptSameTypeContext, false, isHeal)
      end
    end
    return true
  elseif eventName == BattleEvent.ROUND_START then
    self:OnRoundStart()
    return true
  elseif eventName == BattleEvent.DIRECT_UPDATE_UI then
    local ignoreOptions = (...)
    if ignoreOptions and ignoreOptions.ignoreHp and self.battlePet and self.battlePet.guid and ignoreOptions.ignoreHp[self.battlePet.guid] then
      return true
    end
    self:OnRoundStart()
    return true
  elseif eventName == BattleEvent.START_BATTLE_PERFORM then
    self:SaveBattlePerformS(...)
    return true
  elseif eventName == BattleEvent.NightmareShieldBreak then
    local targetPet = (...)
    if targetPet == self.battlePet then
      self:NightmareShieldBreak()
    end
    return true
  elseif eventName == BattlePerformEvent.FrozenChange then
    local petGuid = (...)
    if self.battlePet and self.battlePet.guid == petGuid then
      self:TryUpdateFrozen()
    end
    return true
  elseif eventName == BattlePerformEvent.WillEnterRewardRound then
    if self.destroy_Loop then
      self:PlayAnimation(self.destroy_Loop, 0, 0)
    end
    return true
  elseif eventName == BattlePerformEvent.EnterRewardRoundPlayOver then
    if self.destroy_Loop then
      self:StopAnimation(self.destroy_Loop)
      self:PlayAnimation(self.destroy_pause)
    end
    self:InitWorldLeaderReward()
    return true
  end
end

function UMG_Battle_HP_C:SaveBattlePerformS(performPlayer, cmd)
  if self.IsPlayFrozen then
    return
  end
  if self.battlePet and self.battlePet.health then
    self.BattlePerformS = cmd
  end
end

function UMG_Battle_HP_C:TryUpdateFrozen()
  if self.IsPlayFrozen then
    return
  end
  local nextFrozenPercent = 0
  local battleCard = self.battlePet and self.battlePet.card
  local petInfo = battleCard and battleCard.petInfo
  local battle_inside_pet_info = petInfo and petInfo.battle_inside_pet_info
  local kill_info = battle_inside_pet_info and battle_inside_pet_info.kill_info
  local killAtHp = kill_info and kill_info.kill_at_hp or 0
  local petState = battleCard and battleCard.petState
  local isDead = petState and petState:GetDead()
  if isDead then
    killAtHp = 0
  end
  local healComponent = self.battlePet and self.battlePet.health
  local hpValue = healComponent and healComponent:GetHp()
  if nil == hpValue then
    hpValue = battleCard and battleCard:GetHp() or 0
  end
  local MaxHp = healComponent and healComponent:GetMaxHp()
  if nil == MaxHp then
    MaxHp = battleCard and battleCard:GetMaxHp() or 0
  end
  local shieldValue = healComponent and healComponent:GetShield()
  if nil == shieldValue then
    shieldValue = battleCard and battleCard:GetShield() or 0
  end
  local maxShield = healComponent and healComponent:GetMaxShield()
  if nil == maxShield then
    maxShield = battleCard and battleCard:GetMaxShield() or 0
  end
  if self.isLeaderBattle then
    nextFrozenPercent = self:CalcLeaderBattleHpPercent(killAtHp, MaxHp)
  else
    local maxValue = MaxHp
    if shieldValue > 0 and maxShield > 0 then
      maxValue = maxShield
    end
    if 0 == maxValue then
      nextFrozenPercent = 0
    else
      nextFrozenPercent = killAtHp / maxValue
    end
  end
  nextFrozenPercent = math.clamp(nextFrozenPercent, 0, 1)
  if self.OldFrozenParent == nextFrozenPercent then
    return
  end
  self:PlayFrozenAnim(nextFrozenPercent)
end

function UMG_Battle_HP_C:PlayFrozenAnim(_Percent)
  if _Percent == self.OldFrozenParent then
    return
  end
  self:SetCurFrozenState(true)
  local ani, aniTime, StartTime, endTime
  if _Percent > self.OldFrozenParent then
    ani = self.Frozen
    aniTime = ani:GetEndTime() - ani:GetStartTime()
    StartTime = aniTime * self.OldFrozenParent
    endTime = aniTime * _Percent
  else
    ani = self.ReverseFrozen
    aniTime = ani:GetEndTime() - ani:GetStartTime()
    StartTime = aniTime - aniTime * self.OldFrozenParent
    endTime = aniTime - aniTime * _Percent
  end
  local playTimeSeconds = 0.5
  local playSpeed = math.max(endTime - StartTime, 0.05) / playTimeSeconds
  self:PlayAnimationTimeRange(ani, StartTime, endTime, 1, 0, playSpeed)
  self.OldFrozenParent = _Percent
  self.IsPlayFrozen = true
  if self.UMG_Battle_HP_Fxnoise then
    self.UMG_Battle_HP_Fxnoise:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Battle_HP_Fxnoise:PlayAnimation(self.UMG_Battle_HP_Fxnoise.Ice_noise_in)
  end
end

function UMG_Battle_HP_C:SetCurFrozenState(_IsPlay)
  if _IsPlay then
    self.Fx_bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Fx_light:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.HpBarFrozen:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.HpBarFrozen_1 then
      self.HpBarFrozen_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.HpBarFrozen_2 then
      self.HpBarFrozen_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.HpBarFrozen_3 then
      self.HpBarFrozen_3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.Fx_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Fx_light:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HpBarFrozen:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.HpBarFrozen_1 then
      self.HpBarFrozen_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.HpBarFrozen_1:SetPercent(self.OldFrozenParent)
    end
    if self.HpBarFrozen_2 then
      self.HpBarFrozen_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.HpBarFrozen_3 then
      self.HpBarFrozen_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.HpBarFrozen:SetPercent(self.OldFrozenParent)
    self.IsPlayFrozen = false
  end
end

function UMG_Battle_HP_C:InitView(battlePet)
  self:ResetView()
  if battlePet and not battlePet.destroyed then
    self.bIsNone = false
    self:StopAndCancelAllSetHpContext()
    self:SetPetInfo(battlePet, battlePet.card)
    self:ClearTimer()
    if battlePet.health then
      if self.isNightMarePet and self.haveNightMareShield then
        if self:IsAnimationPlaying(self.Red_Out) then
          self:StopAnimation(self.Red_Out)
        end
        self:StartSetHpValue(battlePet.health:GetShield(), battlePet.health:GetMaxShield(), true)
        if battlePet.health:GetShield() == battlePet.health:GetMaxShield() then
          self.shouldPlayNightMareAnim = true
        end
      else
        self:StartSetHpValue(battlePet.health:GetHp(), battlePet.health:GetMaxHp(), true)
      end
    end
    self:InitWorldLeaderReward(true)
  end
end

function UMG_Battle_HP_C:ResetView()
  self:ResetNightMareHPUI()
end

function UMG_Battle_HP_C:InitWorldLeaderReward(IsPlayAnim)
  if self.LeaderStunIcon and self.VertigoIcon then
    if self.battlePet and self.battlePet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      local rewardPercent = BattleUtils.GetWorldLeaderRewardPercent()
      if rewardPercent > 0 then
        self.VertigoIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if BattleUtils.CanEnterWorldLeaderReward() then
          self.LeaderStunIcon:SetColorAndOpacity(UE.FLinearColor(1, 1, 1, 1))
        else
          self.LeaderStunIcon:SetColorAndOpacity(UE.FLinearColor(0.12, 0.12, 0.12, 1))
        end
        local TotalLength = self.VertigoIcon.Slot.LayoutData.Offsets.Right
        local TargetLength = TotalLength * (rewardPercent / 10000)
        local initPos = self.LeaderStunIcon.Slot:GetPosition()
        self.LeaderStunIcon.Slot:SetPosition(UE.FVector2D(TargetLength, initPos.Y))
        initPos = self.RewardLine.Slot:GetPosition()
        self.RewardLine.Slot:SetPosition(UE.FVector2D(TargetLength, initPos.Y))
        if IsPlayAnim then
          self:PlayAnimation(self.destroy_in)
        end
      else
        self.VertigoIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.VertigoIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Battle_HP_C:InitSurpriseBoxHPUI()
  if self.HpBarSurprise then
    self.HpBarSurprise:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HpBarSurprise:SetRenderOpacity(1)
  end
end

function UMG_Battle_HP_C:ResetSurpriseBoxHPUI()
  if self.HpBarSurprise then
    self.HpBarSurprise:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_HP_C:InitNightMareHPUI()
  if self.isSurpriseBoxPet then
    self:InitSurpriseBoxHPUI()
    return
  end
  if self.isNightMarePet and self.haveNightMareShield then
    if self.shouldPlayNightMareAnim then
      self.shouldPlayNightMareAnim = false
      self:PlayAnimation(self.Red_In)
    end
    self.HpBarShield:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HpBarShieldMax:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HpBarShield:SetRenderOpacity(1)
    self.HpBarShieldMax:SetRenderOpacity(1)
  end
end

function UMG_Battle_HP_C:ResetNightMareHPUI()
  self:ResetSurpriseBoxHPUI()
  if self.HpBarShield then
    self.HpBarShield:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.HpBarShieldMax then
    self.HpBarShieldMax:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.Red_Out then
    local redOutEndTime = self.Red_Out:GetEndTime()
    self:PlayAnimation(self.Red_Out, redOutEndTime)
  end
end

function UMG_Battle_HP_C:SetPetInfo(battlePet, card)
  self.battlePet = battlePet
  if self.battlePet and self.battlePet.health then
  else
    Log.Error("UMG_Battle_HP_C: self.battlePet is nil")
  end
  local health = battlePet and battlePet.health
  local shield = health and health:GetShield() or 0
  local battlePetCard = battlePet and battlePet.card
  self.haveNightMareShield = shield > 0
  self.isNightMarePet = battlePetCard and battlePetCard.isNightMarePet
  self.isSurpriseBoxPet = battlePetCard and battlePetCard.isSurpriseBoxPet
  self:InitFrozenState()
  if not self:IsShowHPValue(self.battlePet) and not self:IsShowHPPercent(self.battlePet) and self.TxtHp then
    self.TxtHp:SetText("")
    if self.TxtHp2 then
      self.TxtHp2:SetText("")
    end
  end
end

function UMG_Battle_HP_C:InitFrozenState()
  if self.Fx_bg then
    local killAtHp = self.battlePet.card.petInfo.battle_inside_pet_info and self.battlePet.card.petInfo.battle_inside_pet_info.kill_info and self.battlePet.card.petInfo.battle_inside_pet_info.kill_info.kill_at_hp
    local battlePet = self.battlePet
    local battleCard = battlePet and battlePet.card
    local battlePetHealComponent = battlePet and battlePet.health
    local MaxHp = battlePetHealComponent and battlePetHealComponent:GetMaxHp()
    local shield = battlePetHealComponent and battlePetHealComponent:GetShield()
    local maxShield = battlePetHealComponent and battlePetHealComponent:GetMaxShield()
    if nil == MaxHp then
      MaxHp = battleCard and battleCard.max_hp
    end
    if nil == shield then
      shield = battleCard and battleCard.shield
    end
    if nil == maxShield then
      maxShield = battleCard and battleCard.max_shield
    end
    shield = shield or 0
    maxShield = maxShield or 0
    local maxValue = MaxHp
    if shield > 0 and maxShield > 0 then
      maxValue = maxShield
    end
    local Percent
    if nil ~= killAtHp and nil ~= maxValue and 0 ~= maxValue then
      Percent = killAtHp / maxValue
    end
    if nil ~= Percent and Percent > 0 then
      Percent = math.clamp(Percent, 0, 1)
      self.OldFrozenParent = Percent
      self:SetCurFrozenState(false)
      if self.UMG_Battle_HP_Fxnoise then
        self.UMG_Battle_HP_Fxnoise:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.UMG_Battle_HP_Fxnoise:PlayAnimation(self.UMG_Battle_HP_Fxnoise.Ice_noise_in)
      end
    else
      self.OldFrozenParent = 0
      self.Fx_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Fx_light:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.HpBarFrozen:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if self.UMG_Battle_HP_Fxnoise then
        self.UMG_Battle_HP_Fxnoise:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.HpBarFrozen_1 then
        self.HpBarFrozen_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.HpBarFrozen_2 then
        self.HpBarFrozen_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.HpBarFrozen_3 then
        self.HpBarFrozen_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_Battle_HP_C:SetProgressDirectional(Pet)
  if Pet.teamEnm == BattleEnum.Team.ENUM_TEAM then
  elseif Pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    self.HpBarSub:SetBarFillType(UE4.EProgressBarFillType.RightToLeft)
    self.HpBarAdd:SetBarFillType(UE4.EProgressBarFillType.RightToLeft)
    self.HpBarPink:SetBarFillType(UE4.EProgressBarFillType.RightToLeft)
    self.HpBarYellow:SetBarFillType(UE4.EProgressBarFillType.RightToLeft)
    self.HpBarGreen:SetBarFillType(UE4.EProgressBarFillType.RightToLeft)
    if self.HpBarFrozen then
      self.HpBarFrozen:SetBarFillType(UE4.EProgressBarFillType.RightToLeft)
    end
  end
end

function UMG_Battle_HP_C:SwitchToNormalBattle()
  self.isLeaderBattle = false
  if self.energyBar then
    self.energyBar:SetLeaderFight(false)
  end
end

function UMG_Battle_HP_C:SwitchToLeaderBattle()
  self.isLeaderBattle = true
  if self.energyBar then
    self.energyBar:SetLeaderFight(true)
  end
end

function UMG_Battle_HP_C:AssignEnergyBar(energyBar)
  self.energyBar = energyBar
end

function UMG_Battle_HP_C:CalLimitPos(widget)
  local pos = UE4.USlateBlueprintLibrary.LocalToAbsolute(widget:GetCachedGeometry(), UE4.FVector2D(0, 0))
  self.LimitPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(self.HPNiagara:GetParent():GetCachedGeometry(), pos)
  self.LimitPos.X = self.LimitPos.X + 80
end

function UMG_Battle_HP_C:ShowSetHpValue(context, targetHp, maxHp, imme, duration)
  if not maxHp then
    Log.Error("UMG_Battle_HP_C:ShowSetHpValue", "maxHp is nil")
    return
  end
  local newPercent = 0 == targetHp and 0 or targetHp / maxHp
  local curHpPercent = self.curHp / maxHp
  local isAddHp = targetHp > self.curPerformHP
  if imme then
    self:RefreshHpText(self.battlePet, targetHp, maxHp, newPercent)
    self:SetHPPercent(context, newPercent)
    self:SetHPBackPercent(newPercent, isAddHp)
    self.curPerformHP = targetHp
    self.curPerformHPBG = targetHp
  else
    local curPercent = self.curPerformHP / maxHp
    if isAddHp then
      curPercent = self.curPerformHPBG / maxHp
    end
    self:SetHPBackPercent(self.curPerformHPBG / maxHp, isAddHp)
    local battlePet = self.battlePet
    local firstChangeFunc = isAddHp and function(p)
      self:SetHPBackPercent(p, true)
      self.curPerformHPBG = math.round(maxHp * p)
    end or function(p)
      self:SetHPPercent(context, p)
      self.curPerformHP = math.round(maxHp * p)
      self:RefreshHpText(battlePet, self.curPerformHP, maxHp, p)
    end
    local secondChangeFunc = isAddHp and function(p)
      self:SetHPPercent(context, p)
      self.curPerformHP = math.round(maxHp * p)
      self:RefreshHpText(battlePet, self.curPerformHP, maxHp, p)
    end or function(p)
      self:SetHPBackPercent(p, false)
      self.curPerformHPBG = math.round(maxHp * p)
    end
    if self:IsAnimationPlaying(self.AddBlood) then
      self:StopAnimation(self.AddBlood)
    end
    if self:IsAnimationPlaying(self.SubBlood) then
      self:StopAnimation(self.SubBlood)
    end
    if isAddHp then
      self:PlayAnimation(self.AddBlood, 0, 1, 0, 1, true)
    else
      self:PlayAnimation(self.SubBlood, 0, 1, 0, 1, true)
      self:PlayAnimation(self.ShakeAll)
    end
    local data = {percent = curPercent}
    local hpFirstDuringTimerHandler = self.timer:Tween(0.5 * duration, data, {percent = newPercent}, "out-quart")
    table.insert(context.HPDuringTimerHandlers, hpFirstDuringTimerHandler)
    hpFirstDuringTimerHandler = self.timer:During(0.5 * duration, function()
      firstChangeFunc(data.percent)
    end, function()
      firstChangeFunc(newPercent)
      local hpAfterFirstDuringTimerHandler = self.timer:After(0.1 * duration, function()
        local NewData = {
          percent = self.curPerformHPBG / maxHp
        }
        if isAddHp then
          NewData.percent = self.curPerformHP / maxHp
          local hpAfterSecondDuringTimerHandler = self.timer:Tween(0.2 * duration, NewData, {percent = newPercent}, "out-quart")
          table.insert(context.HPDuringTimerHandlers, hpAfterSecondDuringTimerHandler)
          hpAfterSecondDuringTimerHandler = self.timer:During(0.2 * duration, function()
            secondChangeFunc(NewData.percent)
          end, function()
            secondChangeFunc(newPercent)
          end)
          table.insert(context.HPDuringTimerHandlers, hpAfterSecondDuringTimerHandler)
        else
          self.HPNiagara:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.HPNiagara:SetActivate(true)
          local moveData = {
            pos = self.HPUILeftX + self.HPUILength * NewData.percent
          }
          local posData = {
            percent = self.curPerformHPBG / maxHp,
            effect = 0
          }
          local newPos = UE4.FVector2D(moveData.pos, self.HPNiagara.Slot:GetPosition().Y)
          self.HPNiagara:SetRenderTranslation(UE4.FVector2D(0, 0))
          self.HPNiagara.Slot:SetPosition(newPos)
          local hpEffectDuringTimerHandler = self.timer:After(0.2 * duration, function()
            local hpEffectDuringAfterTimerHandler = self.timer:Tween(0.5 * duration, moveData, {
              pos = self.HPUILeftX + self.HPUILength * newPercent
            })
            table.insert(context.HPEffectDuringTimerHandlers, hpEffectDuringAfterTimerHandler)
            hpEffectDuringAfterTimerHandler = self.timer:During(0.5 * duration, function()
              local newPos = UE4.FVector2D(moveData.pos, self.HPNiagara.Slot:GetPosition().Y)
              self.HPNiagara.Slot:SetPosition(newPos)
            end, function()
              self.HPNiagara:SetRenderTranslation(UE4.FVector2D(10000, 0))
            end)
            table.insert(context.HPEffectDuringTimerHandlers, hpEffectDuringAfterTimerHandler)
          end)
          table.insert(context.HPEffectDuringTimerHandlers, hpEffectDuringTimerHandler)
          hpEffectDuringTimerHandler = self.timer:After(0.5 * duration, function()
            local hpEffectDuringAfterTimerHandler = self.timer:Tween(0.5 * duration, posData, {percent = newPercent, effect = 0.5})
            table.insert(context.HPEffectDuringTimerHandlers, hpEffectDuringAfterTimerHandler)
            hpEffectDuringAfterTimerHandler = self.timer:During(0.5 * duration, function()
              self:SetHPBackEffect(posData.effect)
              secondChangeFunc(posData.percent)
            end, function()
              secondChangeFunc(newPercent)
              self:SetHPBackEffect(0)
            end)
            table.insert(context.HPEffectDuringTimerHandlers, hpEffectDuringAfterTimerHandler)
          end)
          table.insert(context.HPEffectDuringTimerHandlers, hpEffectDuringTimerHandler)
        end
      end)
      table.insert(context.HPDuringTimerHandlers, hpAfterFirstDuringTimerHandler)
    end)
    table.insert(context.HPDuringTimerHandlers, hpFirstDuringTimerHandler)
  end
end

function UMG_Battle_HP_C:StartSetHpValue(targetHp, maxHp, imme, delaySeconds, canInterruptSameTypeContext, isSetNightmareHpBar, isHeal)
  delaySeconds = delaySeconds or 0
  canInterruptSameTypeContext = canInterruptSameTypeContext or false
  if nil == isSetNightmareHpBar then
    isSetNightmareHpBar = self.haveNightMareShield
  end
  if nil == isHeal then
    isHeal = false
  end
  self.setHpValueContextId = self.setHpValueContextId + 1
  local context = {
    id = self.setHpValueContextId,
    targetHp = targetHp,
    maxHp = maxHp,
    immediate = imme,
    delaySeconds = delaySeconds,
    HPDuringTimerHandlers = {},
    HPEffectDuringTimerHandlers = {},
    LeaderHpDuringTimerHandlers = {},
    canInterruptSameTypeContext = canInterruptSameTypeContext,
    isSetNightmareHpBar = isSetNightmareHpBar,
    isHeal = isHeal,
    hpAnimTimeMultiplier = 1
  }
  table.insert(self.setHpValueQueue, context)
  self.isSetHpValueQueueChanged = true
  Log.TraceFormat("UMG_Battle_HP_C:StartSetHpValue context id = %s, pet guid = %s, target hp = %s", tostring(context.id), tostring(self.battlePet and self.battlePet.guid), tostring(targetHp))
end

function UMG_Battle_HP_C:OnSetHpContextChanged()
  local nextSetHpValueQueue = {}
  local currentSetHpValueQueue = self.setHpValueQueue
  for i, contextItem in ipairs(currentSetHpValueQueue) do
    local lastContextIndex = #nextSetHpValueQueue
    local lastContext = nextSetHpValueQueue[lastContextIndex]
    local isReplace = false
    if lastContext then
      local isSameType = self:IsSetHpContextSameType(lastContext, contextItem)
      local canInterrupt = contextItem.canInterruptSameTypeContext
      local lastContextNeedDelay = contextItem.delaySeconds and contextItem.delaySeconds > 0
      local currentContextNeedDelay = contextItem.delaySeconds and contextItem.delaySeconds > 0
      if isSameType and canInterrupt and not lastContextNeedDelay and not currentContextNeedDelay then
        nextSetHpValueQueue[lastContextIndex] = contextItem
        isReplace = true
      end
    end
    if not isReplace then
      table.insert(nextSetHpValueQueue, contextItem)
    end
  end
  self.setHpValueQueue = nextSetHpValueQueue
  local animContextList = {}
  for i, contextItem in ipairs(self.setHpValueQueue) do
    local needDelay = contextItem.delaySeconds and contextItem.delaySeconds > 0
    local immediate = contextItem.immediate
    if not immediate and not needDelay then
      table.insert(animContextList, contextItem)
    end
  end
  table.reverse(animContextList)
  local currentTotalTimeMultiplier = 0
  local minHpAnimTimeMultiplier = 0.05
  for i, contextItem in ipairs(animContextList) do
    contextItem.hpAnimTimeMultiplier = 1 / i
    currentTotalTimeMultiplier = currentTotalTimeMultiplier + contextItem.hpAnimTimeMultiplier
  end
  for i, contextItem in ipairs(animContextList) do
    local hpAnimTimeMultiplier = contextItem.hpAnimTimeMultiplier / currentTotalTimeMultiplier
    hpAnimTimeMultiplier = math.max(hpAnimTimeMultiplier, minHpAnimTimeMultiplier)
    contextItem.hpAnimTimeMultiplier = hpAnimTimeMultiplier
  end
  self.isSetHpValueQueueChanged = false
end

function UMG_Battle_HP_C:SetHpValue(context, targetHp, maxHp, imme)
  if self.isLeaderBattle then
    local firstFiveHp = math.floor(maxHp / 6)
    local lastHp = maxHp - firstFiveHp * 5
    local HpLifes = {
      firstFiveHp,
      firstFiveHp,
      firstFiveHp,
      firstFiveHp,
      firstFiveHp,
      lastHp
    }
    local targetCount = targetHp
    local targetLife = 1
    for _, v in ipairs(HpLifes) do
      if v < targetCount then
        targetCount = targetCount - v
        targetLife = targetLife + 1
      end
    end
    if imme then
      self.leaderTimer:Clear()
      self:ShowSetHpValue(context, targetCount, HpLifes[targetLife], imme, 0.0)
      if self.energyBar then
        self.energyBar:SetLeftLife(targetLife)
      end
      self.curPerformLife = targetLife
    else
      self:RecurSetHp(context, targetLife, targetCount, HpLifes, 1.0 / (math.abs(self.curPerformLife - targetLife) + 1))
    end
  else
    local hpAnimTimeBase = 1.0
    local hpAnimTimeMultiplier = context and context.hpAnimTimeMultiplier or 1
    local hpAnimTime = hpAnimTimeBase * hpAnimTimeMultiplier
    self:ShowSetHpValue(context, targetHp, maxHp, imme, hpAnimTime)
  end
  self.curHp = targetHp
  self.maxHp = maxHp
end

function UMG_Battle_HP_C:UpdateSetHpValue(deltaTime)
  if self.isSetHpValueQueueChanged then
    self:OnSetHpContextChanged()
  end
  if self.currentSetHpValueContext then
    local context = self.currentSetHpValueContext
    if self:CheckSetHpContextCompleted(context) then
      Log.InfoFormat("UMG_Battle_HP_C:UpdateSetHpValue set hp value completed context id = %s, pet guid = %s, target hp = %s", tostring(context.id), tostring(self.battlePet and self.battlePet.guid), tostring(context.targetHp))
      self:CancelSetHpContext(context)
      self.currentSetHpValueContext = nil
      if self.props and self.props.AnimStateChangeCallback then
        tcall(self.props.AnimStateChangeCallbackOwner, self.props.AnimStateChangeCallback)
      end
    end
  end
  do
    local firstContext
    if #self.setHpValueQueue > 0 then
      firstContext = self.setHpValueQueue[1]
    end
    if firstContext then
      local canInterruptOtherSameTypeContext = firstContext.canInterruptSameTypeContext and self.currentSetHpValueContext and self:IsSetHpContextSameType(firstContext, self.currentSetHpValueContext)
      local canSolveFirstContext = not self.currentSetHpValueContext or canInterruptOtherSameTypeContext
      if canSolveFirstContext then
        local firstContextNeedDelay = firstContext.delaySeconds and firstContext.delaySeconds > 0
        local needWaitForFrozenAnimation = self.IsPlayFrozen
        local needWaitForShieldBreakAnimation = self.isPlayingShieldBreakAnim
        local canExecuteFirstContext = not firstContextNeedDelay and not needWaitForFrozenAnimation and not needWaitForShieldBreakAnimation
        if canExecuteFirstContext then
          if canInterruptOtherSameTypeContext then
            local context = self.currentSetHpValueContext
            Log.InfoFormat("UMG_Battle_HP_C:UpdateSetHpValue set hp value interrupt context id = %s, pet guid = %s, target hp = %s", tostring(context.id), tostring(self.battlePet and self.battlePet.guid), tostring(context.targetHp))
            self:CancelSetHpContext(context)
            self.currentSetHpValueContext = nil
          end
          table.remove(self.setHpValueQueue, 1)
          Log.InfoFormat("UMG_Battle_HP_C:UpdateSetHpValue actually set hp value context id = %s, pet guid = %s, target hp = %s", tostring(firstContext.id), tostring(self.battlePet and self.battlePet.guid), tostring(firstContext.targetHp))
          self:SetHpValue(firstContext, firstContext.targetHp, firstContext.maxHp, firstContext.immediate)
          self.currentSetHpValueContext = firstContext
          if self.props and self.props.AnimStateChangeCallback then
            tcall(self.props.AnimStateChangeCallbackOwner, self.props.AnimStateChangeCallback)
          end
        end
      end
    end
  end
  for i, context in ipairs(self.setHpValueQueue) do
    if context.delaySeconds > 0 then
      context.delaySeconds = context.delaySeconds - deltaTime
      if context.delaySeconds <= 0 then
        self.isSetHpValueQueueChanged = true
      end
    end
  end
  if not self.battlePet or self.currentSetHpValueContext then
  end
end

function UMG_Battle_HP_C:CheckSetHpContextCompleted(context)
  if not context then
    return false
  end
  if context.delaySeconds > 0 then
    return false
  end
  for i, handler in ipairs(context.HPDuringTimerHandlers) do
    if self.timer.functions[handler] ~= nil and handler.count > 0 then
      return false
    end
  end
  for i, handler in ipairs(context.HPEffectDuringTimerHandlers) do
    if self.timer.functions[handler] ~= nil and handler.count > 0 then
      return false
    end
  end
  return true
end

function UMG_Battle_HP_C:IsSetHpContextSameType(contextA, contextB)
  if not contextA or not contextB then
    return false
  end
  return contextA.isSetNightmareHpBar == contextB.isSetNightmareHpBar and contextA.immediate == contextB.immediate and contextA.isHeal == contextB.isHeal
end

function UMG_Battle_HP_C:CancelSetHpContext(context)
  if not context then
    return
  end
  for i, handler in ipairs(context.HPDuringTimerHandlers) do
    self.timer:Cancel(handler)
  end
  for i, handler in ipairs(context.HPEffectDuringTimerHandlers) do
    self.timer:Cancel(handler)
  end
  context.HPDuringTimerHandler = {}
  context.HPEffectDuringTimerHandlers = {}
end

function UMG_Battle_HP_C:CalcLeaderBattleHpPercent(targetHp, maxHp)
  local firstFiveHp = math.floor(maxHp / 6)
  local lastHp = maxHp - firstFiveHp * 5
  local HpLifes = {
    firstFiveHp,
    firstFiveHp,
    firstFiveHp,
    firstFiveHp,
    firstFiveHp,
    lastHp
  }
  local targetCount = targetHp
  local targetLife = 1
  for _, v in ipairs(HpLifes) do
    if v < targetCount then
      targetCount = targetCount - v
      targetLife = targetLife + 1
    end
  end
  local Percent = targetCount / HpLifes[targetLife]
  return Percent
end

function UMG_Battle_HP_C:RefreshHp()
  if self.battlePet then
    if self.battlePet.health then
      if self.battlePet.card.haveNightMareShield then
        self:StartSetHpValue(self.battlePet.health:GetShield(), self.battlePet.health:GetMaxShield(), true)
      else
        self:StartSetHpValue(self.battlePet.health:GetHp(), self.battlePet.health:GetMaxHp(), true)
      end
    elseif self.battlePet.card then
      if self.battlePet.card.haveNightMareShield then
        if self.battlePet.card.shield and self.battlePet.card.max_shield then
          self:StartSetHpValue(self.battlePet.card.shield, self.battlePet.card.max_shield, true)
        end
      elseif self.battlePet.card.hp and self.battlePet.card.max_hp then
        self:StartSetHpValue(self.battlePet.card.hp, self.battlePet.card.max_hp, true)
      end
    end
  end
end

function UMG_Battle_HP_C:RecurSetHp(context, targetLife, targetCount, HpLifes, duration)
  if self.curPerformLife == targetLife then
    self:ShowSetHpValue(context, targetCount, HpLifes[self.curPerformLife], false, duration)
    if 0 == targetCount then
      self.leaderTimer:After(duration, function()
        self.curPerformLife = math.max(self.curPerformLife - 1, 1)
        if self.energyBar then
          self.energyBar:SetLeftLife(self.curPerformLife)
        end
      end)
    end
  elseif targetLife < self.curPerformLife then
    self:ShowSetHpValue(context, 0, HpLifes[self.curPerformLife], false, duration)
    self.leaderTimer:After(2 * duration, function()
      if self.curPerformLife > targetLife then
        self.curPerformLife = self.curPerformLife - 1
        if self.energyBar then
          self.energyBar:SetLeftLife(self.curPerformLife)
        end
        self.curPerformHP = HpLifes[self.curPerformLife]
        self:RecurSetHp(context, targetLife, targetCount, HpLifes, duration)
      end
    end)
  elseif targetLife > self.curPerformLife then
    self:ShowSetHpValue(context, HpLifes[self.curPerformLife], HpLifes[self.curPerformLife], false, duration)
    self.leaderTimer:After(duration, function()
      if self.curPerformLife < targetLife then
        self.curPerformLife = self.curPerformLife + 1
        if self.energyBar then
          self.energyBar:SetLeftLife(self.curPerformLife)
        end
        self.curPerformHP = 0
        self:RecurSetHp(context, targetLife, targetCount, HpLifes, duration)
      end
    end)
  end
  if self.energyBar then
    self.energyBar:SetLeftLife(self.curPerformLife)
  end
end

function UMG_Battle_HP_C:HideHud(event, delayTime)
  local offset = 0
  if self.battlePet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    offset = 2
  end
  self:DelaySeconds(delayTime, function()
    _G.BattleEventCenter:Dispatch(event, self.battlePet.index + offset)
  end)
end

function UMG_Battle_HP_C:SetParent(Parent)
  self.Parent = Parent
end

function UMG_Battle_HP_C:SetHPPercent(context, hpPercent)
  if self.isSurpriseBoxPet then
    self.HpBarShield:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HpBarShield:SetRenderOpacity(0)
    self.HpBarShieldMax:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HpBarShieldMax:SetRenderOpacity(0)
    if self.HpBarSurprise then
      self.HpBarSurprise:SetVisibility(UE4.ESlateVisibility.Visible)
      self.HpBarSurprise:SetRenderOpacity(1)
      self.HpBarSurprise:SetPercent(hpPercent)
    end
    self.HpBarPink:SetPercent(0)
    self.HpBarYellow:SetPercent(0)
    self.HpBarGreen:SetPercent(0)
    return
  elseif self.isNightMarePet and context.isSetNightmareHpBar then
    if self.isPlayingShieldBreakAnim then
      return
    end
    self.HpBarShield:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HpBarShield:SetRenderOpacity(1)
    self.HpBarShield:SetPercent(hpPercent)
    self.HpBarShieldMax:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HpBarShieldMax:SetRenderOpacity(1)
    self.HpBarShieldMax:SetPercent(1)
    if self.HpBarSurprise then
      self.HpBarSurprise:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.HpBarSurprise:SetRenderOpacity(0)
    end
    self.HpBarPink:SetPercent(0)
    self.HpBarYellow:SetPercent(0)
    self.HpBarGreen:SetPercent(0)
    if 0 == hpPercent then
      self.haveNightMareShield = false
    end
    return
  elseif self.HpBarShield then
  end
  if self.HpBarSurprise then
    self.HpBarSurprise:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HpBarSurprise:SetRenderOpacity(0)
  end
  local subHpBarTintColor = UE4.FSlateColor()
  local hpLevelType = BattleUtils.EvaluateHpLevel(hpPercent)
  if hpLevelType == BattleEnum.HpLevelType.Red then
    self.HpBarPink:SetPercent(hpPercent)
    self.HpBarYellow:SetPercent(0)
    self.HpBarGreen:SetPercent(0)
    subHpBarTintColor = UE4.UNRCStatics.HexToSlateColor(BattleConst.HpBarColor.Sub.Red)
  elseif hpLevelType == BattleEnum.HpLevelType.Yellow then
    self.HpBarPink:SetPercent(0)
    self.HpBarYellow:SetPercent(hpPercent)
    self.HpBarGreen:SetPercent(0)
    subHpBarTintColor = UE4.UNRCStatics.HexToSlateColor(BattleConst.HpBarColor.Sub.Yellow)
  else
    self.HpBarPink:SetPercent(0)
    self.HpBarYellow:SetPercent(0)
    self.HpBarGreen:SetPercent(hpPercent)
    subHpBarTintColor = UE4.UNRCStatics.HexToSlateColor(BattleConst.HpBarColor.Sub.Green)
  end
  self.HpBarSub.WidgetStyle.FillImage.TintColor = subHpBarTintColor
  self:SetHPPercent_Hit(hpPercent, hpLevelType)
end

function UMG_Battle_HP_C:SetHPPercent_Hit(hpPercent, hpLevelType)
  if not self.HpBar_Hit or not self.Hit_loop then
    return
  end
  if hpLevelType ~= BattleEnum.HpLevelType.Green and _G.BattleManager.battleRuntimeData.battleType == Enum.BattleType.BT_WORLDLEADER then
    local color = hpLevelType == BattleEnum.HpLevelType.Yellow and BattleConst.HpBarColor.Normal.Yellow or BattleConst.HpBarColor.Normal.Red
    self.HpBar_Hit:SetPercent(hpPercent)
    self.HPBar_Hit.WidgetStyle.FillImage.TintColor = UE4.UNRCStatics.HexToSlateColor(color)
    self:PlayAnimation(self.Hit_loop, 0, 0)
  else
    self.HpBar_Hit:SetPercent(0)
    self:StopAnimation(self.Hit_loop)
  end
end

function UMG_Battle_HP_C:SetHPBackPercent(hpPercent, add)
  if self.isPlayingShieldBreakAnim then
    return
  end
  if self.isNightMarePet and self.haveNightMareShield then
    self.HpBarSub:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HpBarAdd:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  else
    if self.isSurpriseBoxPet then
      self.HpBarSub:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.HpBarAdd:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    else
    end
  end
  if add then
    self.HpBarAdd:SetPercent(hpPercent)
    self.HpBarAdd:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.HpBarSub:SetPercent(0)
    self.HpBarSub:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.HpBarAdd:SetPercent(0)
    self.HpBarAdd:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HpBarSub:SetPercent(hpPercent)
    self.HpBarSub:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Battle_HP_C:SetHPBackEffect(value)
  if not self.BarMaterial then
    self.BarMaterial = self.HpBarSub:GetFillImageDynamicMaterial()
  end
  if self.BarMaterial then
    self.BarMaterial:SetScalarParameterValue("DissExp", value)
  else
    Log.Trace("UMG_Battle_HP_C:SetHPBackEffect")
  end
end

function UMG_Battle_HP_C:PlayerLeave()
  self:TryUpdateFrozen()
  self.battlePet = nil
end

function UMG_Battle_HP_C:StopAndCancelAllSetHpContext()
  self.setHpValueQueue = {}
  if self.currentSetHpValueContext then
    self:CancelSetHpContext(self.currentSetHpValueContext)
    self.currentSetHpValueContext = nil
  end
end

function UMG_Battle_HP_C:PetNone()
  self.bIsNone = true
  self:StartSetHpValue(0, self.maxHp, true)
end

function UMG_Battle_HP_C:OnAnimationFinished(Animation)
  if Animation == self.Frozen or Animation == self.ReverseFrozen then
    self:SetCurFrozenState(false)
    self:TryUpdateFrozen()
    if self.props.AnimStateChangeCallback then
      tcall(self.props.AnimStateChangeCallbackOwner, self.props.AnimStateChangeCallback)
    end
    if self.battlePet == nil or self.battlePet.destroyed or self.battlePet.card and 0 == self.battlePet.card:GetFrozenPercent() then
      self.HpBarFrozen:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if self.HpBarFrozen_1 then
        self.HpBarFrozen_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.UMG_Battle_HP_Fxnoise then
        self.UMG_Battle_HP_Fxnoise:PlayAnimation(self.UMG_Battle_HP_Fxnoise.Ice_noise_out)
      end
    end
  end
  if Animation == self.Red_Out then
    self.isPlayingShieldBreakAnim = false
  end
end

function UMG_Battle_HP_C:IsShowHPValue(pet)
  if BattleUtils.IsTeam() then
    return true
  end
  return pet and pet.teamEnm ~= BattleEnum.Team.ENUM_ENEMY or BattleConst.DebugFlags.ShowPetHP
end

function UMG_Battle_HP_C:IsShowHPPercent(pet)
  return pet and pet.teamEnm == BattleEnum.Team.ENUM_ENEMY
end

function UMG_Battle_HP_C:RefreshHpText(battlePet, performHp, maxHp, hpPercent)
  local hpText = ""
  local hpText2 = ""
  if self:IsShowHPValue(battlePet) then
    hpText = tostring(math.floor(performHp))
    hpText2 = string.format("%s%d", "/", maxHp)
  elseif self:IsShowHPPercent(battlePet) then
    local hpPercentValue = UMG_Battle_HP_C.GetPercentForShow(hpPercent)
    hpText = tostring(hpPercentValue)
    hpText2 = "%"
  end
  if self.TxtHp then
    self.TxtHp:SetText(hpText)
  end
  if self.TxtHp2 then
    self.TxtHp2:SetText(hpText2)
  end
end

function UMG_Battle_HP_C.GetPercentForShow(percent)
  local value = math.clamp(percent, 0, 1) * 100
  if value > 99 then
    return math.floor(value)
  end
  return value > 0 and math.max(1, math.ceil(value)) or 0
end

function UMG_Battle_HP_C:SurpriseBoxBreak()
  if self.HpBarSurprise then
    self.HpBarSurprise:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.battlePet then
      self:StartSetHpValue(self.battlePet.health:GetHp(), self.battlePet.health:GetMaxHp(), true)
    end
  end
end

function UMG_Battle_HP_C:NightmareShieldBreak()
  if self.isSurpriseBoxPet then
    self:SurpriseBoxBreak()
    return
  end
  if self.isNightMarePet then
    self:PlayAnimation(self.Red_Out)
    self.HpBarShield:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HpBarShieldMax:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.battlePet then
      self:StartSetHpValue(self.battlePet.health:GetHp(), self.battlePet.health:GetMaxHp(), true)
    end
    self.isPlayingShieldBreakAnim = true
  end
end

function UMG_Battle_HP_C:IsPerformingAnim()
  return self.currentSetHpValueContext and not self:CheckSetHpContextCompleted(self.currentSetHpValueContext) or #self.setHpValueQueue > 0 or self.IsPlayFrozen
end

return UMG_Battle_HP_C
