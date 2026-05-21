local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleRoundAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Round.BattleRoundAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleDebugger = require("NewRoco.Modules.Core.Battle.Debugger.BattleDebugger_Declare")
local Base = BattleRoundAction
local RoundItemAction = Base:Extend("RoundItemAction")
FsmUtils.MergeMembers(Base, RoundItemAction, {})

function RoundItemAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.PlayerSkill = nil
  self:SetActionType(BattleActionBase.ActionType.ClientPlayerSelectAction)
end

function RoundItemAction:OnEnter()
  Base.OnEnter(self)
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_ITEM, BattleEvent.BATTLE_CLICKED_PLAYERSKILL, BattleEvent.BATTLE_CLICKED_CANCELPLAYERSKILL, BattleEvent.BATTLE_CLICKED_PET, BattleEvent.BATTLE_USE_PLAYERSKILL_SUCCESS, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.UI_HIDE)
  if self.CurrentEnemyPets and self.CurrentPlayer then
    for _, v in ipairs(self.CurrentEnemyPets) do
      v:SetLookAt(self.CurrentPlayer.model)
    end
  end
  if self.CurrentPlayer then
    self.CurrentPlayer:ShowBag(true)
    self.CurrentPlayer:HoldBag(true)
    self.CurrentPlayer.lastTakenItemIsCompass = false
    local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
    self.PlayerSkill = activedPlayerSkillInfo
    Log.Debug(playerSkillPhase, "RoundItemAction:OnEnter")
    if playerSkillPhase == BattleEnum.PlayerSkillPhase.NoSkill then
      local Item = self:GetFirstItem(ProtoEnum.BagItemType.BI_ITEM)
      if Item then
        self.CurrentPlayer:TakeItemWithID(Item.item_conf_id or 0)
      else
        self:TakeCompass()
      end
    else
      self.CurrentPlayer:PrepareCompassSkill(true)
      self:TakeCompass()
    end
  end
end

function RoundItemAction:TakeCompass()
  local PlayerSkillItem = self:GetFirstItem(ProtoEnum.BagItemType.BI_PLAYERSKILL)
  if PlayerSkillItem then
    self.CurrentPlayer:TakeCompassWithID(PlayerSkillItem.item_conf_id or 0)
  elseif self.CurrentPlayer and self.CurrentPlayer.model then
    self.CurrentPlayer.model:PlayAnimByName(BattleConst.AnimNamePlayer_Idle.Idle, 1, -1, 0.25, 0.25, -1, -1)
  end
end

function RoundItemAction:TryUsePlayerSkill(itemData)
  local Text
  if itemData.canCharge and itemData.remainCnt <= 0 then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.rounditemaction_1)
    return false
  elseif itemData.playerMagicRemainCnt <= 0 then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.player_magic_use_time)
    return false
  elseif self.CurrentPlayer.roleInfo.magic_skill_info.state ~= ProtoEnum.SkillState.SKILL_READY then
    Text = _G.DataConfigManager:GetLocalizationConf("Battle_Skill_CD").msg
  else
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(itemData.conf_id)
    if BagItemConf and BagItemConf.player_skill_id then
      local PlayerMagicConf = _G.DataConfigManager:GetPlayerMagicConf(BagItemConf.player_skill_id)
      if PlayerMagicConf then
        if BattleUtils.GetFBCallNameMagicId() == PlayerMagicConf.skill_id then
          local nameBuffId = DataConfigManager:GetBattleGlobalConfig("a1_finalbattle_name_buff_ID").num
          for i, v in ipairs(self.Pet.card.petInfo.battle_inside_pet_info.buffs) do
            if nameBuffId == v.buff_id then
              return true
            end
          end
          Text = _G.DataConfigManager:GetLocalizationConf("A1FB_Tips_name_the_named").msg
        elseif BattleUtils.GetFBCallArthurMagicId() == PlayerMagicConf.skill_id then
          return true
        else
          local SkillConf = _G.DataConfigManager:GetSkillConf(PlayerMagicConf.skill_id)
          local IsBlood = false
          local PetData = self.Pet.card.petInfo.battle_common_pet_info
          if SkillConf then
            local BloodLimit = SkillConf.target_blood_limit
            for i, BloodId in ipairs(BloodLimit) do
              if BloodId == PetData.blood_id then
                IsBlood = true
              end
            end
            local errorDesc = _G.DataConfigManager:GetLocalizationConf("Error_Code_30061")
            Text = errorDesc and errorDesc.msg or "Error"
            local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
            if PetBaseConf then
              if PetBaseConf.bosspetbase_rule == BattleEnum.BloodItemRule.Default and IsBlood then
                return true
              elseif PetBaseConf.bosspetbase_rule == BattleEnum.BloodItemRule.DiMo then
                for i, type in ipairs(PetData.skill_dam_type) do
                  for j, BloodId in ipairs(SkillConf.target_blood_limit) do
                    local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(BloodId)
                    if PetBloodConf and type == PetBloodConf.blood_type then
                      return true
                    end
                  end
                end
              elseif PetBaseConf.bosspetbase_rule == BattleEnum.BloodItemRule.BossPet and IsBlood and PetBaseConf.bosspetbase_rule_param and #PetBaseConf.bosspetbase_rule_param > 0 then
                return true
              end
            end
          end
        end
      end
    end
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Text)
  self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.NoSkill)
  return false
end

function RoundItemAction:TryUseItem(itemData)
  return BattleUtils.TryUseItem(itemData)
end

function RoundItemAction:TryUseItemOnPet(pet)
  if not self.itemData then
    Log.Error("\230\160\185\230\156\172\230\178\161\230\156\137\231\137\169\229\147\129\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    return false
  end
  if pet.card.petState:GetDrill() then
    local tip = _G.DataConfigManager:GetBattleGlobalConfig("drill_forbid_props").str
    tip = string.format(tip, pet.card.name)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
    return false
  elseif pet.card.petState:GetStatic() then
    local tip = _G.DataConfigManager:GetBattleGlobalConfig("static_forbid_props").str
    tip = string.format(tip, pet.card.name)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
    return false
  elseif pet.card.petState:GetMimic() and pet.teamEnm ~= BattleEnum.Team.ENUM_TEAM then
    local tip = _G.DataConfigManager:GetBattleGlobalConfig("mimic_forbid_props").str
    tip = string.format(tip, pet.card.name)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
    return false
  end
  if self.itemData.ItemType ~= Enum.BagItemType.BI_PLAYERSKILL then
    local itemBattleCfg = _G.DataConfigManager:GetBattleItemConf(self.itemData.conf_id)
    if itemBattleCfg.use_effect_type_in_battle == ProtoEnum.BattleUseEffect.BE_HINTLEVEL and (BattleUtils.IsPvw() or BattleUtils.IsLeaderFight()) then
      local info = BattleUtils.GetSkillPredictionByPlayer(pet)
      if info.hint_level == _G.ProtoEnum.SkillHintLevel.LEVEL_F then
        local tip = _G.DataConfigManager:GetLocalizationConf("Battle_Skill_Prediction_Level_Min").msg
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
        return false
      elseif info.hint_level == _G.ProtoEnum.SkillHintLevel.LEVEL_S then
        local tip = _G.DataConfigManager:GetLocalizationConf("Battle_Skill_Prediction_Level_Max").msg
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
        return false
      end
    end
  end
  return true
end

function RoundItemAction:OnClickedItem(itemData)
  Log.Debug("RoundItemAction:OnClickedItem")
  self.itemData = itemData
  self.SelectMarkerManager:ClearSelection()
  self.SelectMarkerManager:HideTipTime()
  self.SelectMarkerManager:HideClickTipUI()
  self:ResetRestPets()
  if not self:TryUseItem(itemData) then
    self:ResetPetsLight()
    self:SetEnemyPetHighlight(false)
    self:SetTeamPetHighlight(false)
    self:ToggleDarkScene(false)
    return
  end
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  if playerSkillPhase ~= BattleEnum.PlayerSkillPhase.NoSkill then
    self:OnCancelPlayerSkill()
  end
  local itemBattleCfg = _G.DataConfigManager:GetBattleItemConf(itemData.conf_id)
  Log.Dump(itemBattleCfg, "RoundItemAction:OnClickedItem")
  if 1 == itemBattleCfg.legally_used_object then
    self:PlayCurrentTeamPetsAnim(itemData)
  elseif 2 == itemBattleCfg.legally_used_object then
    if itemBattleCfg.use_effect_type_in_battle == ProtoEnum.BattleUseEffect.BE_HINTLEVEL then
      self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_ENEMY)
      self:SetEnemyPetHighlight(false)
      if self.CurrentEnemyPets then
        for _, enemy in pairs(self.CurrentEnemyPets) do
          if enemy:CanBePredicted() and enemy.card:IsCanSelect() then
            enemy:ShowTipTime(itemData.allowCnt, BattleEnum.Operation.ENUM_ITEM)
            enemy:SetHighlight(true, true)
            enemy:ShowClickTipUI()
          end
        end
      end
    else
      self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_ENEMY)
      if self.CurrentEnemyPets then
        for _, enemy in pairs(self.CurrentEnemyPets) do
          if enemy.card:IsCanSelect() then
            enemy:SetHighlight(true, true)
            enemy:ShowClickTipUI()
            enemy:ShowTipTime(itemData.allowCnt, BattleEnum.Operation.ENUM_ITEM)
          end
        end
      end
    end
    if self.CurrentEnemyPets then
      self:SetTeamPetHighlight(false)
      self:SetRestPetHighlight(false)
      self:ToggleDarkScene(true)
    end
  else
    Log.ErrorFormat("legally object should be team or enemy, %d", itemBattleCfg.legally_used_object)
  end
  self.CurrentPlayer:ShowBag(false)
  self.CurrentPlayer:HoldBag(true)
end

function RoundItemAction:OnClickedPlayerSkill(itemData)
  self.itemData = itemData
  self.SelectMarkerManager:ClearSelection()
  self.SelectMarkerManager:HideTipTime()
  self.SelectMarkerManager:HideClickTipUI()
  self:ResetRestPets()
  if BattleUtils.IsAssignMagicItem(itemData.conf_id, BattleUtils.GetFBCallArthurMagicId()) then
    self:ShowFBEnemyHighlight(true)
    _G.BattleManager.vBattleField.battleCraneCamera:ChangeCameraTagDirect(UE4.EBattleCameraTags.A1FBSPlayerMagicYaSe, 0.3, true)
  else
    self:PlayCurrentTeamPetsAnim(itemData, true)
    _G.BattleManager.vBattleField.battleCraneCamera:ChangeToPlayerMagic(0.3, true)
  end
  self.CurrentPlayer:ShowBag(false)
  self.CurrentPlayer:HoldBag(true)
  self.PlayerSkill = self.CurrentPlayer:GetPlayerSkillInfo()
  self.PlayerSkill:Init(itemData, "NewRoco.Modules.Core.Battle.BattleCore.Pieces.Instances.BattlePiecePlayerSkillChangePet", self.CurrentPlayer)
  self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.TryToActive)
  self.CurrentPlayer:TakeCompassWithID(itemData.conf_id or 0)
end

function RoundItemAction:ConfirmPlayerSkill()
  local EffectType = self.PlayerSkill:GetEffectType()
  Log.Debug(EffectType, "RoundItemAction:ConfirmPlayerSkill")
  if EffectType == Enum.EffectType.ET_ROLE_CHANGE_PET then
    self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.TryToPetActive)
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL, self.PlayerSkill:GetEffectType())
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_BEGING_USE_CHANGE_PET_SKILL, self.PlayerSkill:GetBloodLimit(), true)
    _G.BattleManager.battleRuntimeData.operateType = BattleEnum.Operation.ENUM_CHANGE
    self:SendFsmEventInfo(BattleEvent.RoundEvent.EnterSwap)
  else
    local BattleRoundFlowReqList = {}
    local BattleRoundFlowReq = {}
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(self.Pet.card.petBaseConf.id)
    local req = BattleNetManager:BuildBattleCmdPushbackReq()
    req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_ROLE_MAGIC
    BattleRoundFlowReq.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_ROLE_MAGIC
    BattleRoundFlowReq.magic_op = {}
    BattleRoundFlowReq.magic_op.target_pet_id = self.Pet.card.guid
    BattleRoundFlowReq.magic_op.target_pet_pos = self.Pet.card.pos
    if PetBaseConf then
      BattleRoundFlowReq.magic_op.boss_petbase_id = PetBaseConf.bosspetbase_id_arry and PetBaseConf.bosspetbase_id_arry[1]
    end
    table.insert(BattleRoundFlowReqList, BattleRoundFlowReq)
    req.req = BattleRoundFlowReqList
    local skillID = self.PlayerSkill.data.conf_id
    if skillID and 104009 == skillID then
      NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenCallNamePanel, req)
    else
      self:SendPushbackReq(req)
    end
  end
end

function RoundItemAction:PlayCurrentTeamPetsAnim(itemData, toggleDarkScene)
  if nil == toggleDarkScene then
    toggleDarkScene = true
  end
  local restPets = self.CurrentPlayer.team.RestPets
  if self.CurrentMyPets then
    self:SetEnemyPetHighlight(false)
    self:SetTeamPetHighlight(false)
    for i, v in pairs(self.CurrentMyPets) do
      local player = v
      Log.Debug(player.card.name, player.card.guid, "RoundItemAction:PlayCurrentTeamPetsAnim")
      if restPets[i] then
        player:SetClickable(false)
        player:HideTipTime()
      else
        player:SetHighlight(true, true)
        player:ShowClickTipUI()
        player:SetClickable(true)
        if itemData.ItemType ~= Enum.BagItemType.BI_PLAYERSKILL then
          local itemConfigId = itemData and itemData.conf_id
          local battleItemConf = _G.DataConfigManager:GetBattleItemConf(itemConfigId, true)
          local use_time_in_battle = battleItemConf and battleItemConf.use_time_in_battle or 0
          local needShowTipTime = true
          if use_time_in_battle > 0 then
            needShowTipTime = false
          end
          if needShowTipTime then
            player:ShowTipTime(itemData.allowCnt, BattleEnum.Operation.ENUM_ITEM)
          end
        else
          player:PlayAnimByName("Show")
        end
      end
    end
    if toggleDarkScene then
      self:ToggleDarkScene(true)
    end
  end
end

function RoundItemAction:ShowFBEnemyHighlight()
  self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_ENEMY)
  if self.CurrentEnemyPets then
    for _, enemy in pairs(self.CurrentEnemyPets) do
      enemy:SetHighlight(true, true)
      enemy:ShowClickTipUI()
    end
  end
  if self.CurrentEnemyPets then
    self:SetTeamPetHighlight(false)
    self:SetRestPetHighlight(false)
    self:ToggleDarkScene(true)
  end
end

function RoundItemAction:OnCancelPlayerSkill(itemData)
  self:ClearPlayerSkillState()
  self:ResetRestPets()
  local Item = self:GetFirstItem(ProtoEnum.BagItemType.BI_ITEM)
  if Item then
    self.CurrentPlayer:TakeItemWithID(Item.item_conf_id or 0)
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_UI_CANCELPLAYERSKILL)
  _G.BattleManager.battleRuntimeData.PlayerSkillManager:SetIsPlayerSkillSuccess(false)
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  Log.Debug(playerSkillPhase, "RoundItemAction:OnCancelPlayerSkill")
  if playerSkillPhase == BattleEnum.PlayerSkillPhase.WaitingToPerform then
    local req = _G.ProtoMessage:newZoneBattleCmdPopbackReq()
    req.role_magic_op = true
    local EffectType = activedPlayerSkillInfo:GetEffectType()
    if EffectType == Enum.EffectType.ET_ROLE_CHANGE_PET then
      Log.Debug("\230\146\164\233\148\128\230\141\162\229\174\160\228\184\187\232\167\146\233\173\148\230\179\149")
      local ClickPet, UpPet = activedPlayerSkillInfo:GetClickPetAndUpPet()
      req.pet_id = UpPet.guid
    else
      if self.Pet then
        req.pet_id = self.Pet.card.guid
      else
        req.pet_id = self.CurrentPet.card.guid
      end
      Log.Debug("\230\146\164\233\148\128\230\138\128\232\131\189\228\184\187\232\167\146\233\173\148\230\179\149")
    end
    Log.Dump(req, 6, "RoundItemAction:OnCancelPlayerSkill")
    self:SendPopbackReq(req)
  else
    self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.NoSkill)
    _G.BattleManager.vBattleField.battleCameraManager:ChangeByOperateType(BattleEnum.Operation.ENUM_ITEM)
  end
end

function RoundItemAction:UndoBattleSelectRsp(rsp)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(rsp)
  Log.Dump(rsp, 6, "RoundItemAction:UndoBattleSelectRsp")
  if not rsp or 0 ~= rsp.ret_info.ret_code then
    return
  end
  local BattlePet
  if rsp.req and rsp.req.req_type == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_ROLE_MAGIC then
    local MagicInfo = rsp.req.magic_op
    local OpPet = self.BattleManager.battlePawnManager:GetPetByGuid(MagicInfo.target_pet_id)
    OpPet:InitOp()
    local EffectType = self.PlayerSkill:GetEffectType()
    if self.Pet then
      BattlePet = self.Pet
    else
      BattlePet = self.CurrentPet
    end
    if EffectType == Enum.EffectType.ET_ROLE_CHANGE_SKILL or EffectType == Enum.EffectType.ET_ADD_BUFF_BY_BLOOD or EffectType == Enum.EffectType.ET_BOSS_BLOOD then
      local sync_data = rsp.sync_data
      local battleInfoManager = _G.BattleManager.battleInfoManager
      local rspRound = rsp and rsp.round
      if sync_data and sync_data.pet_info then
        local PetInfo = sync_data.pet_info
        for i, Pet in ipairs(PetInfo) do
          if BattlePet then
            local petId = OpPet and OpPet.guid
            battleInfoManager:AddBattlePetInfoDataFromPushPop(petId, Pet, rspRound)
            BattlePet:OverwriteByServer(Pet)
            BattlePet:RefreshByServer()
          else
            Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174")
          end
        end
      end
      _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_UI_ON_ROUND_SELECT, sync_data)
      _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_DATA, self.CurrentPet, true)
    elseif EffectType == Enum.EffectType.ET_ROLE_CHANGE_PET then
      OpPet = self.BattleManager.battlePawnManager:GetPetByGuid(MagicInfo.up_pet_id)
      OpPet:InitOp()
      self.PlayerSkill:Cancel()
      local ClickPet, UpPet = self.PlayerSkill:GetClickPetAndUpPet()
      BattlePet = UpPet.BattlePet
      _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_DATA, self.CurrentPet, true)
    end
    do
      local playerUin = self.CurrentPlayer and self.CurrentPlayer.guid
      local rspRound = rsp and rsp.round
      local roleInfo = {}
      local magicOpInfo = _G.ProtoMessage:newBattleRoleMagicOpInfo()
      roleInfo.magic_op_info = magicOpInfo
      local battleInfoManager = _G.BattleManager.battleInfoManager
      battleInfoManager:AddBattleRoleInfoDataFromPushPop(playerUin, roleInfo, rspRound)
    end
    self.PlayerSkill:CancelLinkEffect()
    self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.NoSkill)
    self.CurrentPlayer:ClearMagicOpInfo()
    _G.BattleManager.vBattleField.battleCameraManager:ChangeByOperateType(BattleEnum.Operation.ENUM_ITEM)
  end
end

function RoundItemAction:SendFsmEventInfo(curEvent)
  if curEvent then
    self.fsm:SendEvent(curEvent)
    self.fsm:SetProperty("StateEvent", curEvent)
  end
end

function RoundItemAction:SetRestPetHighlight(highlight)
  if not self.BattleManager.battlePawnManager then
    return
  end
  if not self.BattleManager.battlePawnManager.playerTeam then
    return
  end
  local restPets = self.BattleManager.battlePawnManager.playerTeam.RestPets
  for _, v in pairs(restPets) do
    v:SetHighlight(highlight)
  end
end

function RoundItemAction:OnPetClicked(Pet)
  Log.Debug("RoundItemAction:OnPetClicked")
  self.Pet = Pet
  if not self:TryUseItemOnPet(Pet) then
    return
  end
  BattleManager.SelectTargetManager:SelectByPet(Pet)
  if self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL then
    if not self:TryUsePlayerSkill(self.itemData) then
      Pet:ShowClickTipUI()
      return
    end
    self.PlayerSkill:SetClickPetAndUpPet(Pet)
    self:ConfirmPlayerSkill()
    return
  elseif not self:TryUseItem(self.itemData) then
    return
  end
  self:ResetAllPetState(Pet)
  local BattleRoundFlowReqList = {}
  local BattleRoundFlowReq = {}
  local req = BattleNetManager:BuildBattleCmdPushbackReq()
  req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_USE_ITEM
  BattleRoundFlowReq.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_USE_ITEM
  BattleRoundFlowReq.use_item = {}
  BattleRoundFlowReq.use_item.target_pet_id = Pet.card.guid
  BattleRoundFlowReq.use_item.item_id = self.itemData.id
  BattleRoundFlowReq.use_item.player_id = self.CurrentPlayer.guid
  BattleRoundFlowReq.use_item.target_pet_pos = Pet.card.pos
  table.insert(BattleRoundFlowReqList, BattleRoundFlowReq)
  req.req = BattleRoundFlowReqList
  Log.Dump(req, nil, "RoundItemAction:OnPetClicked")
  self:SendPushbackReq(req)
end

function RoundItemAction:ResetAllPetState(Pet)
  self:ResetPetsLight()
  self:ToggleDarkScene(false)
  Pet:SetHighlight(false)
  self:ResetRestPets()
  self.SelectMarkerManager:HideClickTipUI()
  self.SelectMarkerManager:ClearSelection()
end

function RoundItemAction:UsePlayerSkillSuccess()
  self:ResetAllPetState(self.Pet)
  if BattleUtils.IsFinalBattleP1() then
    self:PlayEffectCallback()
  else
    self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.WaitingToPerform)
    self.PlayerSkill:PlayLinkEffect(self.Pet, self.PlayEffectCallback)
  end
end

function RoundItemAction:ChangeOpeRate()
  if not self.CurrentPlayer then
    return
  end
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  Log.Debug(playerSkillPhase, "RoundItemAction:ChangeOpeRate")
  if playerSkillPhase == BattleEnum.PlayerSkillPhase.TryToActive then
    self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.NoSkill)
  end
end

function RoundItemAction:PlayEffectCallback()
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PLAY_PLAYERSKILL_SUCCESS)
end

function RoundItemAction:SendFsmEvent()
  if self.curEvent then
    self.fsm:SendEvent(self.curEvent)
    self.fsm:SetProperty("StateEvent", self.curEvent)
  end
end

function RoundItemAction:GetPlayerSkillItem()
  local item = {}
  item.item_conf_id = 104000
  return item
end

function RoundItemAction:GetFirstItem(ItemType)
  local player = _G.BattleManager.battlePawnManager.TeamatePlayer
  local ItemInfos = player.itemInfo or {}
  for _, item in ipairs(ItemInfos) do
    if item.item_type == ItemType then
      return item
    end
  end
  return nil
end

function RoundItemAction:ResetRestPets()
  if not self.BattleManager or not self.BattleManager.battlePawnManager then
    return
  end
  if not self.BattleManager.battlePawnManager.playerTeam then
    return
  end
  local restPets = self.BattleManager.battlePawnManager.playerTeam.RestPets
  for _, v in pairs(restPets) do
    v:SetDark(false)
    v:HideClickTipUI()
    v:SetClickable(false)
    v:HideTipTime()
    v:SetHighlight(false)
    v:HideRestraintUI()
  end
end

function RoundItemAction:ClearPlayerSkillState()
  if self.SelectMarkerManager then
    self.SelectMarkerManager:ClearSelection()
    self.SelectMarkerManager:HideTipTime()
    self.SelectMarkerManager:HideClickTipUI()
    self.SelectMarkerManager:HideAllSelectMarkers()
  end
  self:ResetPetsLight()
  self:SetEnemyPetHighlight(false)
  self:SetTeamPetHighlight(false)
end

function RoundItemAction:OnExit()
  _G.BattleEventCenter:UnBind(self)
  self.SelectMarkerManager:ClearSelection()
  self.SelectMarkerManager:HideTipTime()
  self.SelectMarkerManager:HideClickTipUI()
  self:ResetPetsLight()
  self:SetEnemyPetHighlight(false)
  self:SetTeamPetHighlight(false)
  self:ResetRestPets()
  Base.OnExit(self)
end

function RoundItemAction:OnBattleEvent(eventName, ...)
  Log.Debug("RoundItemAction:OnBattleEvent:", eventName)
  if eventName == BattleEvent.BATTLE_CLICKED_ITEM then
    self:OnClickedItem(...)
    return true
  elseif eventName == BattleEvent.BATTLE_CLICKED_PLAYERSKILL then
    self:OnClickedPlayerSkill(...)
    return true
  elseif eventName == BattleEvent.BATTLE_CLICKED_CANCELPLAYERSKILL then
    self:ToggleDarkScene(false)
    self:OnCancelPlayerSkill(...)
    return true
  elseif eventName == BattleEvent.BATTLE_CLICKED_PET then
    self:OnPetClicked(...)
    return true
  elseif eventName == BattleEvent.BATTLE_USE_PLAYERSKILL_SUCCESS then
    self:UsePlayerSkillSuccess()
    return true
  elseif eventName == BattleEvent.CHANGE_OPERATE_TYPE then
    self:ChangeOpeRate()
    return true
  elseif eventName == BattleEvent.UI_HIDE then
    if self.CurrentPlayer then
      self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.NoSkill)
    end
    return true
  end
end

return RoundItemAction
