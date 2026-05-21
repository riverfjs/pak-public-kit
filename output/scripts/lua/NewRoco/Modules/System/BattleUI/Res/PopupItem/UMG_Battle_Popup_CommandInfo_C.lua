require("UnLuaEx")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_Battle_Popup_CommandInfo_C = NRCViewBase:Extend("")

function UMG_Battle_Popup_CommandInfo_C:Construct()
  NRCViewBase.Construct(self)
  self.IsHide = true
  self.IsCanRepeat = true
  self.IsPlayIn = false
  self:SetRenderOpacity(0)
end

function UMG_Battle_Popup_CommandInfo_C:OnDestruct()
end

function UMG_Battle_Popup_CommandInfo_C:SetLeftOrRight(isLeft)
  self.isLeft = isLeft
  local slot = self.SizeFather.Slot
  local Achors = UE4.FAnchors()
  if not self.isLeft then
    self.Bg:SetRenderScale(UE4.FVector2D(-1, 1))
    self.SizeFather.Slot:SetAlignment(UE4.FVector2D(1, 0.5))
    self.Slot:SetAlignment(UE4.FVector2D(1, 0))
    self.Effect.Slot:SetAlignment(UE4.FVector2D(1, 0))
    Achors.Minimum = UE4.FVector2D(0, 0.5)
    Achors.Maximum = UE4.FVector2D(0, 0.5)
    self.SizeFather.Slot:SetAnchors(Achors)
    self.SizeFather.Slot:SetPosition(UE4.FVector2D(873, 0))
    Achors.Minimum = UE4.FVector2D(1, 0)
    Achors.Maximum = UE4.FVector2D(1, 0)
    self.Slot:SetAnchors(Achors)
    self.Effect.Slot:SetAnchors(Achors)
  else
    self.SizeFather.Slot:SetAlignment(UE4.FVector2D(0, 0))
    self.Slot:SetAlignment(UE4.FVector2D(0, 0))
    self.Effect.Slot:SetAlignment(UE4.FVector2D(0, 0))
    Achors.Minimum = UE4.FVector2D(0, 0)
    Achors.Maximum = UE4.FVector2D(0, 0)
    self.SizeFather.Slot:SetAnchors(Achors)
    self.Slot:SetAnchors(Achors)
    self.Effect.Slot:SetAnchors(Achors)
  end
end

function UMG_Battle_Popup_CommandInfo_C:ShowPopup(msg, isleft, flag)
  if not self.Slot then
    Log.Error("zgx Slot is nil, can't find C++ object")
    return
  end
  self:SetLeftOrRight(isleft)
  if not msg or 0 == #msg then
    return false
  end
  self.flag = flag
  self:ClearNameMask()
  self.fantasticBackgroundPath = ""
  if msg[1] == BattleEnum.InfoPopupType.SummonPet then
    if 3 ~= #msg then
      Log.Error("Popup SummonPet have error param")
      Log.Dump(msg, 2)
      return false
    end
    local SplayerName = msg[2].roleInfo.base.name
    local SpetName = msg[3].medalName
    if isleft or not _G.BattleManager.battleRuntimeData.battleStartParam.isSeriesFight then
      self:CheckFillTextNameMask(msg)
      if self.hasLoadNameMask then
        SpetName = LuaText.A1_finalbattle_unknown_pet_name
      end
      self.Popinfo:SetText(string.format(LuaText.INFO_POPUP_SUMMON_PET, SplayerName, SpetName))
    else
      self.Popinfo:SetText(string.format(LuaText.INFO_POPUP_MULTIBATTLE_ENEMY, SpetName))
    end
  elseif msg[1] == BattleEnum.InfoPopupType.UseSkill or msg[1] == BattleEnum.InfoPopupType.UseSkillCountered then
    if 3 ~= #msg then
      Log.Error("zgx Popup UseSkill have error param")
      Log.Dump(msg, 2)
      return false
    end
    self.isEffectOver = false
    self.isTimeUp = false
    self.AttackPlayer = msg[3]
    local SpetName = self.AttackPlayer.Caster.card.medalName
    self:CheckNameMask(msg)
    if self.AttackPlayer.Caster.card:IsCheerPet() then
      SpetName = LuaText.umg_battle_popup_commandinfo_1 .. SpetName
    end
    if self.hasLoadNameMask then
      SpetName = LuaText.A1_finalbattle_unknown_pet_name
    end
    local needOverride = false
    local SkillConf = _G.SkillUtils.GetSkillConf(self.AttackPlayer.skill_cast.skill_id)
    if SkillConf.type == ProtoEnum.SkillActiveType.SAT_FEATURE then
      needOverride = false
    else
      needOverride = self.AttackPlayer.Caster.card.petState:GetSleep() or self.AttackPlayer.Caster.card.petState:GetDrill() or self.AttackPlayer.Caster.card.petState:GetStatic() or self.AttackPlayer.Caster.card.petState:GetMimic() or self.AttackPlayer.Caster.card.petState:GetThunder() or self.AttackPlayer.Caster.card.petState:GetTrail() or self.AttackPlayer.Caster.card.petState:GetDiving()
    end
    local fantasticBackgroundPath = ""
    if needOverride then
      if self.AttackPlayer.Caster.card.petState:GetSleep() then
        local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("sleep_skill_tip", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
        self.Popinfo:SetText(string.format(tip, SpetName))
      elseif self.AttackPlayer.Caster.card.petState:GetDrill() then
        local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("drill_skill_tip", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
        self.Popinfo:SetText(string.format(tip, SpetName))
      elseif self.AttackPlayer.Caster.card.petState:GetStatic() then
        local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("static_skill_tip", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
        self.Popinfo:SetText(string.format(tip, SpetName))
      elseif self.AttackPlayer.Caster.card.petState:GetMimic() then
        local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("mimic_skill_tip", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
        self.PopInfo:SetText(tip)
      elseif self.AttackPlayer.Caster.card.petState:GetThunder() then
        local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("thunder_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
        self.Popinfo:SetText(string.format(tip, SpetName))
      elseif self.AttackPlayer.Caster.card.petState:GetTrail() then
        local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("trail_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
        self.Popinfo:SetText(string.format(tip, SpetName))
      elseif self.AttackPlayer.Caster.card.petState:GetDiving() then
        local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("diving_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
        self.Popinfo:SetText(string.format(tip, SpetName))
      end
    else
      local SskillName
      if SkillConf.skill_feature == Enum.SkillFilterTitleType.SFTT_SPECIAL then
        SskillName = string.format("<orange>%s</>", SkillConf.name)
        self.Popinfo:SetText(string.format(LuaText.INFO_POPUP_SPECIAL_SKILL, SskillName))
      elseif msg[1] == BattleEnum.InfoPopupType.UseSkillCountered then
        SskillName = string.format("<orange>%s</>", SkillConf.name)
        local Text
        local battleAttackPlayer = msg[3]
        local skillCast = battleAttackPlayer and battleAttackPlayer.skill_cast
        local performFlag = skillCast and skillCast.perform_flag
        local petId = skillCast and skillCast.caster_id
        local skillId = skillCast and skillCast.skill_id
        local checkedSkillId = skillId and _G.SkillUtils.CheckSkillId(skillId)
        local seasonId = skillCast and skillCast.season_id
        if performFlag == _G.ProtoEnum.PET_SKILL_PERFORM_FLAG.PET_SKILL_PERFORM_FLAG_FANTASTIC then
          Text = string.format(LuaText.INFO_POPUP_COUNTER_FANTASTIC_SKILL, SpetName, SskillName)
          local paths = BattleUtils.GetFantasticBackgroundPathWithSkillAndSeason(checkedSkillId, seasonId)
          if paths then
            fantasticBackgroundPath = paths.stripNm3 or fantasticBackgroundPath
          end
        else
          Text = string.format(LuaText.INFO_POPUP_COUNTER_SKILL, SpetName, SskillName)
        end
        self.Popinfo:SetText(Text)
      else
        local energyText = "<white>0</>"
        local starText = "<img id=\"Star\"/>"
        if self.AttackPlayer.performInfo.sync_data then
          local petInfo = self.AttackPlayer.performInfo.sync_data.pet_sync_info or {}
          for i, v in ipairs(petInfo) do
            if v.pet_id == self.AttackPlayer.Caster.guid then
              local useEnergy = math.abs(v.energy_change)
              energyText = string.format("<white>%d</>", useEnergy)
              if useEnergy > SkillConf.energy_cost[1] then
                SskillName = string.format("<red>%s</>", SkillConf.name)
                energyText = string.format("<red>%d</>", useEnergy)
                starText = "<img id=\"Star_Red\"/>"
                break
              end
              if useEnergy == SkillConf.energy_cost[1] then
                SskillName = string.format("<orange>%s</>", SkillConf.name)
                break
              end
              SskillName = string.format("<pow_green>%s</>", SkillConf.name)
              energyText = string.format("<pow_green>%d</>", useEnergy)
              starText = "<img id=\"Star_Green\"/>"
              break
            end
          end
        end
        SskillName = SskillName or string.format("<orange>%s</>", SkillConf.name)
        local Text
        local battleAttackPlayer = msg[3]
        local skillCast = battleAttackPlayer and battleAttackPlayer.skill_cast
        local performFlag = skillCast and skillCast.perform_flag
        local petId = skillCast and skillCast.caster_id
        local skillId = skillCast and skillCast.skill_id
        local checkedSkillId = skillId and _G.SkillUtils.CheckSkillId(skillId)
        local seasonId = skillCast and skillCast.season_id
        if performFlag == _G.ProtoEnum.PET_SKILL_PERFORM_FLAG.PET_SKILL_PERFORM_FLAG_FANTASTIC then
          local stringFormat = LuaText.INFO_POPUP_USE_FANTASTIC_SKILL
          if not isleft and self:IsB1FinalBattle() then
            Text = string.format(stringFormat, SpetName, "", "", SskillName)
          else
            Text = string.format(stringFormat, SpetName, starText, energyText, SskillName)
          end
          local paths = BattleUtils.GetFantasticBackgroundPathWithSkillAndSeason(checkedSkillId, seasonId)
          if paths then
            fantasticBackgroundPath = paths.stripNm3 or fantasticBackgroundPath
          end
        elseif battleAttackPlayer.skill_cast.perform_flag == _G.ProtoEnum.PET_SKILL_PERFORM_FLAG.PET_SKILL_PERFORM_FLAG_ESCPAPE_NOTIFY then
          local stringFormat = LuaText.INFO_POPUP_USE_ESCAPE_NOTICE_SKILL
          Text = string.format(stringFormat, SpetName)
        else
          local stringFormat = LuaText.INFO_POPUP_USE_SKILL
          if _G.BattleUtils.IsB1FinalBattleP1() then
            if not isleft then
              Text = string.format(stringFormat, SpetName, "", "", SskillName)
            else
              Text = string.format(stringFormat, SpetName, starText, energyText, SskillName)
            end
          elseif _G.BattleUtils.IsB1FinalBattleP2() or _G.BattleUtils.IsB1FinalBattleP3() then
            Text = string.format(stringFormat, SpetName, "", "", SskillName)
          else
            Text = string.format(stringFormat, SpetName, starText, energyText, SskillName)
          end
        end
        self.Popinfo:SetText(Text)
      end
    end
    if not string.IsNilOrEmpty(fantasticBackgroundPath) then
      self.fantasticBackgroundPath = fantasticBackgroundPath
    end
    if not self.AttackPlayer.skill_cast.combo_index or 0 == self.AttackPlayer.skill_cast.combo_index then
      self:DelayFrames(6, self.TimeUp, self)
    else
      self:TimeUp()
    end
  elseif msg[1] == BattleEnum.InfoPopupType.UseSpEnergy then
    if 4 ~= #msg then
      Log.Error("Popup UseSpEnergy have error param")
      Log.Dump(msg, 2)
      return false
    end
    self.Popinfo:SetText(LuaText.umg_battle_popup_commandinfo_2)
  elseif msg[1] == BattleEnum.InfoPopupType.UseBuff then
    if 4 ~= #msg then
      Log.Error("Popup UseBuff have error param")
      Log.Dump(msg, 2)
      return false
    end
    local BuffConf = _G.DataConfigManager:GetBuffConf(msg[4].buff_id)
    if not BuffConf then
      return false
    end
    local check = false
    for _, sign in ipairs(BuffConf.buff_groupsigns) do
      if sign == ProtoEnum.BuffGroupSign.BGS_SPE then
        check = true
        break
      end
    end
    if not check then
      return false
    end
    local BuffConfName = string.format("<orange>%s</>", BuffConf.name)
    self.Popinfo:SetText(string.format(LuaText.INFO_POPUP_SPECIAL_SKILL, BuffConfName))
  elseif msg[1] == BattleEnum.InfoPopupType.UseEffect then
    if 4 ~= #msg then
      Log.Error("Popup UseBuff have error param")
      Log.Dump(msg, 2)
      return false
    end
    local EffectConf = _G.DataConfigManager:GetEffectConf(msg[4].buff_id)
    if not EffectConf or 0 == EffectConf.is_special then
      return false
    end
    local EffectName = string.format("<orange>%s</>", EffectConf.name)
    self.Popinfo:SetText(string.format(LuaText.INFO_POPUP_SPECIAL_SKILL, EffectName))
  elseif msg[1] == BattleEnum.InfoPopupType.PetRest then
    if 3 ~= #msg then
      Log.Error("Popup PetRest have error param")
      Log.Dump(msg, 2)
      return false
    end
    local SpetName = msg[3].medalName or msg[3].name
    self.Popinfo:SetText(string.format(LuaText.INFO_POPUP_PET_RESET, SpetName))
  elseif msg[1] == BattleEnum.InfoPopupType.PlainText then
    self.PopInfo:SetText(msg[3])
  elseif msg[1] == BattleEnum.InfoPopupType.PetStatus then
    if 4 ~= #msg then
      Log.Error("Popup PetStatus have error param")
      Log.Dump(msg, 2)
      return false
    end
    local SPetName = string.format(LuaText.PET_CONDITION_CHANGE, msg[3])
    local SCondition = msg[4]
    local Content = string.format(SCondition, SPetName)
    self.PopInfo:SetText(Content)
  elseif msg[1] == BattleEnum.InfoPopupType.PetRunAwayCondition then
    if 4 ~= #msg then
      Log.Error("Popup PetRunAwayCondition have error param")
      Log.Dump(msg, 2)
      return false
    end
    local SPetName = msg[3]
    local SCondition = msg[4]
    self.PopInfo:SetText(string.format(LuaText.RUN_AWAY_CONDITION, SCondition, SPetName))
  elseif msg[1] == BattleEnum.InfoPopupType.WaitingOther then
    self.PopInfo:SetText(LuaText.umg_battle_popup_commandinfo_3)
  elseif msg[1] == BattleEnum.InfoPopupType.EnemyEscape then
    self.PopInfo:SetText(LuaText.umg_battle_popup_commandinfo_4)
  elseif msg[1] == BattleEnum.InfoPopupType.PVPNoOp then
    if isleft then
      self.PopInfo:SetText(LuaText.umg_battle_popup_commandinfo_5)
    else
      self.PopInfo:SetText(LuaText.umg_battle_popup_commandinfo_6)
    end
  elseif msg[1] == BattleEnum.InfoPopupType.Sleeping then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("sleep_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.WakeUp then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("sleep_buff_end", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
    _G.NRCAudioManager:PlaySound2DAuto(1009, "UMG_Battle_Popup_CommandInfo_C.WeakUp")
  elseif msg[1] == BattleEnum.InfoPopupType.IsBacking then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("backstab_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsNotBacking then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("backstab_buff_end", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
    _G.NRCAudioManager:PlaySound2DAuto(1009, "UMG_Battle_Popup_CommandInfo_C.backstab")
  elseif msg[1] == BattleEnum.InfoPopupType.IsDrill then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("drill_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsStopDrill then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("drill_buff_end", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsStatic then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("static_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsStopStatic then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("static_buff_end", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsMimic then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("mimic_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(tip)
  elseif msg[1] == BattleEnum.InfoPopupType.IsStopMimic then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("mimic_buff_end", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsStun then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("magic_stun_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsStopStun then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("magic_stun_end", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsCatchDrill then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("drill_forbid_catch", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsCatchStatic then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("static_forbid_catch", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsCatchMimic then
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("mimic_forbid_catch", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(tip)
  elseif msg[1] == BattleEnum.InfoPopupType.IsStopLeaderStun then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetLocalizationConf("dizzy_recover_tip").msg
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.CheerPetEnter then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("1vn_battle_cheer_pet_enter", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
    self:DelaySeconds(1, self.HidePopup, self)
  elseif msg[1] == BattleEnum.InfoPopupType.PetJoin1VN then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("1vn_battle_pet_join_1vn", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
    self:DelaySeconds(1, self.HidePopup, self)
  elseif msg[1] == BattleEnum.InfoPopupType.CheerPetEscape then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("1vn_battle_cheer_pet_escape", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.IsThunder then
    local pet = msg[2]
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("thunder_buff_loop", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "")
    self.PopInfo:SetText(string.format(tip, pet.card.medalName))
  elseif msg[1] == BattleEnum.InfoPopupType.TeamCatch then
    local player = msg[2]
    local ballName = ""
    local bagItem = _G.DataConfigManager:GetBagItemConf(msg[3], true)
    if nil ~= bagItem then
      ballName = bagItem.name or ""
    end
    local tip = _G.DataConfigManager:GetGlobalConfigStrByKeyType("syn_battle_catch_tip", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG, "%s use %s to catch pet!!")
    self.PopInfo:SetText(string.format(tip, player.roleInfo.base.name, ballName))
    self:DelaySeconds(2, self.HidePopup, self)
  end
  local fantasticBackgroundPath = self.fantasticBackgroundPath or ""
  local selectNm3Visibility = UE4.ESlateVisibility.Collapsed
  if not string.IsNilOrEmpty(fantasticBackgroundPath) then
    self.fantasticBackgroundPath = fantasticBackgroundPath
    selectNm3Visibility = UE4.ESlateVisibility.SelfHitTestInvisible
  end
  self.Select_NM_3:SetPath(fantasticBackgroundPath)
  self.Select_NM_3:SetVisibility(selectNm3Visibility)
  self:StopAllAnimations()
  self.IsHide = false
  self.IsPlayIn = false
  self.IsCanRepeat = false
  self.AdaptNum = 5
  self:PlayAnimation(self.FadeIn)
  if self.isLeft then
    self:PlayAnimation(self.LeftIn)
  else
    self:PlayAnimation(self.RightIn)
  end
  self:DelayFrames(1, self.AdaptSize, self)
  return true
end

function UMG_Battle_Popup_CommandInfo_C:IsB1FinalBattle()
  if _G.BattleUtils.IsB1FinalBattleP1() or _G.BattleUtils.IsB1FinalBattleP2() or _G.BattleUtils.IsB1FinalBattleP3() then
    return true
  else
    return false
  end
end

function UMG_Battle_Popup_CommandInfo_C:SetEnergyChangeState(skillEntity, name)
  local SkillName
  if skillEntity then
    local energy_change = skillEntity:GetEnergyChangeValue()
    if nil ~= energy_change then
      if energy_change > 0 then
        SkillName = string.format("<red>%s</>", name)
      elseif 0 == energy_change then
        SkillName = string.format("<orange>%s</>", name)
      else
        SkillName = string.format("<pow_green>%s</>", name)
      end
    end
  else
    SkillName = string.format("<orange>%s</>", name)
  end
  return SkillName
end

function UMG_Battle_Popup_CommandInfo_C:AdaptSize()
  if self.SizeFather then
    local slot = self.SizeFather.Slot
    local length = self.PopInfo:GetDesiredSize().X
    if length <= 0 then
      self:DelayFrames(1, self.AdaptSize, self)
      return
    end
    slot:SetSize(UE4.FVector2D(length + 170, 82))
    self.Effect.Slot:SetSize(UE4.FVector2D(length + 70, 82))
    if self.AdaptNum > 0 then
      self.AdaptNum = self.AdaptNum - 1
      self:DelayFrames(1, self.AdaptSize, self)
    end
  end
end

function UMG_Battle_Popup_CommandInfo_C:ClearNameMask()
  if self.hasLoadNameMask and self.NameMask then
    self.hasLoadNameMask = false
    self.NameMask:UnLoadPanel(false)
  end
end

function UMG_Battle_Popup_CommandInfo_C:HidePopup()
  if not self.Slot then
    Log.Error("zgx Slot is nil, can't find C++ object")
    return
  end
  self.IsHide = true
  self.flag = nil
  self.AttackPlayer = nil
  if 0 == self:GetRenderOpacity() then
    self.IsCanRepeat = true
    return
  end
  if not self:IsAnimationPlaying(self.FadeOut) and self.IsPlayIn then
    self:StopAllAnimations()
    self:PlayAnimation(self.FadeOut)
  end
end

function UMG_Battle_Popup_CommandInfo_C:OnAnimationStarted(Animation)
  self:SetRenderOpacity(1)
end

function UMG_Battle_Popup_CommandInfo_C:OnAnimationFinished(Animation)
  if self.FadeOut == Animation then
    self:SetRenderOpacity(0)
    self:ClearNameMask()
    if self.IsPlayIn and self.IsHide and not self.IsCanRepeat then
      self.IsPlayIn = false
      self.IsCanRepeat = true
      _G.BattleEventCenter:Dispatch(BattleEvent.Popup_CommandInfo_End, self.isLeft, self)
    end
    self.Select_NM_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.LeftIn == Animation or self.RightIn == Animation then
    if self.AttackPlayer then
      self.AttackPlayer.performNode:SyncEnergyForSkillPlayer(SkillUtils.InstSkillIdToCfgId(self.AttackPlayer.skill_cast.skill_id), self.AttackPlayer.performInfo.sync_data)
      if not self.isEffectOver then
        self.isEffectOver = true
        self:SendAttackStart()
      end
    end
    self.IsPlayIn = true
    if self.RightIn == Animation and not self.IsHide then
      _G.BattleEventCenter:Dispatch(BattleEvent.Popup_CommandInfo)
    end
    if self.IsHide then
      self:HidePopup()
    end
  end
end

function UMG_Battle_Popup_CommandInfo_C:TimeUp()
  if not self.isTimeUp then
    self.isTimeUp = true
    self:SendAttackStart()
  end
end

function UMG_Battle_Popup_CommandInfo_C:SendAttackStart()
  if self.AttackPlayer and self.isTimeUp and self.isEffectOver then
    _G.BattleEventCenter:Dispatch(BattleEvent.START_BATTLE_ATTACK, self.AttackPlayer)
  end
end

function UMG_Battle_Popup_CommandInfo_C:CheckNameMask(msg)
  if not BattleUtils.IsFinalBattle() then
    return
  end
  local hasNameMask = false
  local AttackPlayer = msg[3]
  local buffComponent
  if AttackPlayer and AttackPlayer.Caster and AttackPlayer.Caster.buffComponent then
    buffComponent = self.AttackPlayer.Caster.buffComponent
  end
  if buffComponent then
    local buffs = buffComponent.buffs
    if buffs and #buffs > 0 then
      for i, buff in ipairs(buffs) do
        if BuffUtils.IsNameInvisibleBuff(buff.id) and buff.stack > 0 and self.NameMask then
          local name = AttackPlayer.Caster.card.medalName
          self.NameMask:LoadPanel(nil, name, false)
          self.hasLoadNameMask = true
          hasNameMask = true
        end
      end
    end
  end
  if false == hasNameMask then
    self.hasLoadNameMask = false
    if self.NameMask then
      self.NameMask:UnLoadPanel(false)
    end
  end
end

function UMG_Battle_Popup_CommandInfo_C:CheckFillTextNameMask(msg)
  if not BattleUtils.IsFinalBattle() then
    return
  end
  local hasNameMask = false
  if msg[3] and msg[3].BattlePet and msg[3].BattlePet.buffComponent then
    local buffs = msg[3].BattlePet.buffComponent.buffs
    if buffs and #buffs > 0 then
      for i, buff in ipairs(buffs) do
        if BuffUtils.IsNameInvisibleBuff(buff.id) and buff.stack > 0 and self.NameMask then
          local SplayerName = msg[2].roleInfo.base.name
          local fillText = string.format(LuaText.INFO_POPUP_SUMMON_PET, SplayerName, "")
          local name = msg[3].medalName or msg[3].name
          self.NameMask:LoadPanel(nil, name, false, fillText)
          self.hasLoadNameMask = true
          hasNameMask = true
        end
      end
    end
  end
  if false == hasNameMask then
    self.hasLoadNameMask = false
    if self.NameMask then
      self.NameMask:UnLoadPanel(false)
    end
  end
end

return UMG_Battle_Popup_CommandInfo_C
