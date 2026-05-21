local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local StarChainEnum = require("NewRoco.Modules.System.StarChain.StarChainEnum")
local BattleShowTeamBeastCatchUIAction = BattleActionBase:Extend("BattleShowTeamBeastCatchUIAction")

function BattleShowTeamBeastCatchUIAction:OnEnter()
  self.BossShinyOver = true
  self.BossPet = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  if BattleUtils.IsReplayMode() then
    self.CloseCatchUI = true
    self:SafeDelaySeconds("d_BossToBeCatch", 1, self.BossToBeCatch, self)
  else
    self.IsConfirmCatchUI = false
    self.fsm:Pause()
    self:SetTimeoutValue(BattleActionBase.MaxTimeoutValue)
    self.timeout = BattleActionBase.MaxTimeoutValue
    self:TryOpenLegendIFCatchPanel()
  end
  _G.BattleEventCenter:Bind(self, BattleEvent.CLICKED_Result_Close, BattleEvent.CloseIFCatchPanel, BattleEvent.CLICKED_RewardsPanel_Close, BattleEvent.OnSkillResLoaded)
end

function BattleShowTeamBeastCatchUIAction:GetTimeoutValue()
  return BattleActionBase.MaxTimeoutValue
end

function BattleShowTeamBeastCatchUIAction:TryOpenLegendIFCatchPanel()
  if not (not self.finished and BattleManager.isInBattle) or self.IsConfirmCatchUI then
    Log.Error("zgx BattleShowTeamBeastCatchUIAction is finished")
    return
  end
  local BattleUIModule = _G.NRCModuleManager:GetModule("BattleUIModule")
  if BattleUIModule:HasPanel("Pet_RecoveryTime") then
    return
  end
  self:OpenLegendIFCatchPanel()
  self:SafeDelaySeconds("d_ReTryOpenLegend", 2, self.TryOpenLegendIFCatchPanel, self)
end

function BattleShowTeamBeastCatchUIAction:ReOpenLegendIFCatchPanel()
  if self.finished or not BattleManager.isInBattle then
    Log.Error("zgx BattleShowTeamBeastCatchUIAction is finished")
    return
  end
  self:OpenLegendIFCatchPanel()
end

function BattleShowTeamBeastCatchUIAction:OpenLegendIFCatchPanel()
  self.CloseCatchUI = false
  self.SkillFinish = false
  self.ToCatchBoss = false
  self.GetCatchConfirmRsp = false
  local OpenLegendIFCatchPanelFunc = function()
    local Ctx = DialogContext()
    local consumeTicket = DataConfigManager:GetLegendaryGlobalConfig("ticket_cost").num
    local tips = string.format(LuaText.legendary_battle_tips_1, consumeTicket)
    Ctx:SetContent(tips)
    Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
    Ctx:SetConsumeItem(Enum.VisualItem.VI_LEGENDARY_COIN, consumeTicket)
    Ctx:SetTitle(LuaText.TIPS)
    Ctx:SetButtonText(LuaText.umg_bag_13, LuaText.umg_minigame_giveup_1)
    Ctx:SetBanFullScreenBtn()
    Ctx:SetReOpenFunc(OpenLegendIFCatchPanelFunc)
    Ctx:SetCallback(self, self.CloseIFCatchPanel)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog2, Ctx)
  end
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OPenPetRecoveryTime)
end

function BattleShowTeamBeastCatchUIAction:CloseIFCatchPanel(isEnterCatch)
  if self.finished or not BattleManager.isInBattle then
    Log.Error("zgx BattleShowTeamBeastCatchUIAction is finished")
    return
  end
  if not _G.ZoneServer:IsConnected() then
    self:SafeDelaySeconds("d_ReOpenLegendIFCatchPanel", 0.2, self.ReOpenLegendIFCatchPanel, self)
    return
  end
  self:SafeCancelDelayById("d_ReTryOpenLegend")
  self.IsConfirmCatchUI = true
  if isEnterCatch.IsConfirm then
    self:SendCatchConfirm(isEnterCatch.ticket_id)
  else
    self:SendEscapeReq()
  end
end

function BattleShowTeamBeastCatchUIAction:SendCatchConfirm(ticket_id)
  if not (not self.finished and BattleManager.isInBattle) or self.GetCatchConfirmRsp then
    Log.Error("zgx BattleShowTeamBeastCatchUIAction is finished")
    return
  end
  local req = ProtoMessage:newZoneBattleCatchConfirmReq()
  self.ticket_id = ticket_id
  req.ticket_id = ticket_id
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CATCH_CONFIRM_REQ, req, self, self.GetBattleCatchConfirmRsp)
  self:SafeDelaySeconds("d_ReSendCatchConfirm", 3, self.SendCatchConfirm, self, ticket_id)
end

function BattleShowTeamBeastCatchUIAction:SendEscapeReq()
  if self.finished or not BattleManager.isInBattle then
    Log.Error("zgx BattleShowTeamBeastCatchUIAction is finished")
    return
  end
  _G.BattleNetManager:SendEscapeReqWithHandle(self, self.GetEscapeRsp, BattleEnum.RunAwayType.TeamBeastNoCatch)
  self:SafeDelaySeconds("d_ReSendEscapeReq", 3, self.SendEscapeReq, self)
end

function BattleShowTeamBeastCatchUIAction:GetEscapeRsp(rsp)
  self:SafeCancelDelayById("d_ReSendEscapeReq")
  self.fsm:Resume()
  self:Finish()
end

function BattleShowTeamBeastCatchUIAction:GetBattleCatchConfirmRsp(rsp)
  self:SafeCancelDelayById("d_ReSendCatchConfirm")
  if not self.GetCatchConfirmRsp then
    if 0 == rsp.ret_info.ret_code then
      self.ZoneBattleCatchConfirmRsp = rsp
      self.GetCatchConfirmRsp = true
      _G.BattleManager.battlePawnManager.TeamatePlayer.itemInfo = rsp.items
      if rsp.boss_shiny and rsp.boss_shiny > 0 and self.BossPet then
        self.BossPet.card:InternalOverwriteByServer({
          battle_common_pet_info = rsp.boss_data
        })
        self.BossPet.card:RefreshByServerPetData()
        self.BossPet.card:ClearBuffs()
        self.BossPet.card.petInfo.battle_inside_pet_info.kill_info = nil
        self:PrepareBossShiny()
      end
      if self.BossShinyOver then
        self:TryOpenRewardPanel()
      end
      self:BossToBeCatch()
      _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.SetTicketID, self.ticket_id)
    else
      Log.Error("zgx GetBattleCatchConfirmRsp error code", rsp.ret_info.ret_code)
      self:ReOpenLegendIFCatchPanel()
    end
  end
end

function BattleShowTeamBeastCatchUIAction:TryOpenRewardPanel()
  if not self.ZoneBattleCatchConfirmRsp then
    return
  end
  if self.ZoneBattleCatchConfirmRsp.ret_info.goods_reward and self.ZoneBattleCatchConfirmRsp.ret_info.goods_reward.rewards and #self.ZoneBattleCatchConfirmRsp.ret_info.goods_reward.rewards > 0 then
    local msg = _G.DataConfigManager:GetLocalizationConf("get_report_reward").msg
    NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, self.ZoneBattleCatchConfirmRsp.ret_info.goods_reward.rewards, msg, nil, nil, true)
  else
    self:CloseResult()
  end
end

function BattleShowTeamBeastCatchUIAction:PrepareBossShiny()
  self.BossShinyOver = false
  self.loadedResCount = 0
  self.resList = {
    BattleConst.TeamBeastShiny
  }
  BattleSkillManager:PreLoadRes(self.resList, true)
end

function BattleShowTeamBeastCatchUIAction:PlayBossShiny()
  if not self.active then
    return
  end
  if not BattleManager:IsInBattle(true) then
    return
  end
  if not self.BossPet or not self.BossPet.model then
    Log.Warning("There is no model in Boss !!!")
    self:BossShinySkillOver()
    return
  end
  local skillComponent = self.BossPet.model.RocoSkill
  if not skillComponent then
    Log.Warning("There is no RocoSkill in Boss !!!")
    self:BossShinySkillOver()
    return
  end
  local MyCastObject = CastSkillObject.FromSkillResID(self.resList[1])
  if MyCastObject then
    MyCastObject:SetIsPassive(true)
    MyCastObject:SetCallbackOwner(self)
    MyCastObject:SetCaster(self.BossPet.model)
    MyCastObject:SetTargetPets({
      self.BossPet
    })
    MyCastObject:SetCompleteCallback(self.BossShinySkillOver)
    MyCastObject:SetExtraEvents({
      ActionStart = self.BossChangeToShiny
    })
    local _, skill = BattleSkillManager:PrepareSkill(self.BossPet, skillComponent, MyCastObject)
    if not skill then
      Log.WarningFormat("Can't find or load skill object %s %s", MyCastObject.ResID)
      self:BossShinySkillOver()
      return
    end
    skillComponent:PlaySkill(skill)
  else
    Log.Error("zgx res is vaild!!", self.resList[1])
    self:BossShinySkillOver()
  end
end

function BattleShowTeamBeastCatchUIAction:BossChangeToShiny()
  if not self.active then
    return
  end
  local bossCard = self.BossPet.card
  if self.BossPet and bossCard then
    if bossCard.petInfo and not bossCard:CheckIsMimic() then
      local mutationPetData = {
        mutation_type = bossCard.petInfo.battle_common_pet_info.mutation_type,
        nature = bossCard.petInfo.battle_common_pet_info.nature,
        glass_info = bossCard.petInfo.battle_common_pet_info.glass_info,
        base_conf_id = bossCard.petInfo.battle_common_pet_info.base_conf_id
      }
      if bossCard.petState:GetNightmare() or bossCard.petState:GetNightmareOne() then
        mutationPetData.mutation_type = mutationPetData.mutation_type & ~_G.Enum.MutationDiffType.MDT_CHAOS
        mutationPetData.mutation_type = mutationPetData.mutation_type & ~_G.Enum.MutationDiffType.MDT_CHAOS_TWO
        mutationPetData.mutation_type = mutationPetData.mutation_type & ~_G.Enum.MutationDiffType.MDT_CHAOS_THREE
      end
      PetMutationUtils.DoMutation(self.BossPet.model, mutationPetData)
    end
    _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_TEAMBOSS_HP, self.BossPet)
  end
end

function BattleShowTeamBeastCatchUIAction:BossShinySkillOver()
  if not self.active then
    return
  end
  if self.BossShinyOver then
    return
  end
  self.BossShinyOver = true
  self:TryOpenRewardPanel()
  self:TryFinish()
end

function BattleShowTeamBeastCatchUIAction:OpenLegendaryBattleClosePanelByRsp()
  if self.ZoneBattleCatchConfirmRsp then
    NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.OpenLegendaryBattleClosePanelByRsp, self.ZoneBattleCatchConfirmRsp)
  end
end

function BattleShowTeamBeastCatchUIAction:BossToBeCatch()
  if self.BossPet then
    self.BossPet.card.petState:SetCatchStun(true)
  end
  self.SkillFinish = true
  self.ToCatchBoss = true
  self:TryFinish()
end

function BattleShowTeamBeastCatchUIAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.CLICKED_Result_Close then
    self:CloseResult()
    return true
  elseif eventName == BattleEvent.CloseIFCatchPanel then
    self:CloseIFCatchPanel(...)
    return true
  elseif eventName == BattleEvent.CLICKED_RewardsPanel_Close then
    self:CloseResult()
    return true
  elseif eventName == BattleEvent.OnSkillResLoaded and self.resList then
    local value = (...)
    for i = 1, #self.resList do
      if value == self.resList[i] then
        self.loadedResCount = self.loadedResCount + 1
      end
    end
    if self.loadedResCount == #self.resList then
      self:PlayBossShiny()
    end
    return true
  end
end

function BattleShowTeamBeastCatchUIAction:CloseResult()
  if not self.active then
    Log.Error("zgx BattleShowTeamBeastCatchUIAction is finished")
    return
  end
  if self.CloseCatchUI then
    return
  end
  self.CloseCatchUI = true
  self:TryFinish()
end

function BattleShowTeamBeastCatchUIAction:TryFinish()
  if self.SkillFinish and self.CloseCatchUI and self.BossShinyOver then
    self:Finish()
  end
end

function BattleShowTeamBeastCatchUIAction:OnFinish()
  _G.BattleEventCenter:UnBind(self)
  if self.ZoneBattleCatchConfirmRsp then
    self.ZoneBattleCatchConfirmRsp = nil
  end
  self.BossPet = nil
  if self.ToCatchBoss then
    _G.BattleEventCenter:Dispatch(BattleEvent.TEAM_BATTLE_CATCH)
    self.fsm:SendEvent(BattleEvent.EnterRoundSelect, self, {
      self.state.name
    })
  end
end

return BattleShowTeamBeastCatchUIAction
