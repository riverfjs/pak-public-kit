local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local UMG_Callname_C = _G.NRCPanelBase:Extend("UMG_Callname_C")
local petName

function UMG_Callname_C:OnActive(req)
  self.req = req
  self:OnAddEventListener()
  local curRound = _G.BattleManager.battleRuntimeData.roundIndex
  if 2 == curRound then
    self.CloseBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif curRound > 2 then
    self.CloseBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    NRCModuleManager:DoCmd(BattleUIModuleCmd.WishPowerInVisible)
  end
  if BattleUtils.IsFinalBattleP2() then
    self.CloseBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local str = _G.DataConfigManager:GetBattleGlobalConfig("a1_finalbattle_summonbox_text").str
    self.Name:SetHintText(str)
  else
    self.Name:SetHintText(LuaText.a1_finalbattle_summonbox_text_p1)
  end
end

function UMG_Callname_C:OnDeactive()
  local curRound = _G.BattleManager.battleRuntimeData.roundIndex
  if curRound > 2 then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.WishPowerVisible)
  end
end

function UMG_Callname_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn, self.OnBtnCancelClick)
  self:AddButtonListener(self.Button, self.OnBtnOkClick)
end

function UMG_Callname_C:OnBtnCancelClick()
  local CurRound = _G.BattleManager:GetCurRound()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Callname_C:OnBtnCancelClick")
  if 2 == CurRound then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\230\151\160\230\179\149\229\143\150\230\182\136")
    return
  end
  self:OnClose()
end

function UMG_Callname_C:OnBtnOkClick()
  local name = self.Name:GetText()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Callname_C:OnOk")
  if BattleUtils.IsFinalBattleP1() then
    if not self.HasSend then
      self.HasSend = true
      self.req.req[1].magic_op.name = name
      _G.BattleNetManager:SendBattleCmdPushbackReq(self.req, self, self.OnRsp, nil, true)
    end
  elseif BattleUtils.IsFinalBattleP2() then
    if self.HasCallSucc then
      return
    end
    local req = ProtoMessage:newZoneBattleFinalBattleP2SummonReq()
    req.name = name
    req.confirmed = 0
    self.name = name
    self.p2SummonReq = req
    petName = name
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINAL_BATTLE_P2_SUMMON_REQ, req, self, self.OnFinalBattle2Rsp, nil, true)
  end
end

function UMG_Callname_C:SendPushbackReq(req)
  return
end

function UMG_Callname_C:OnRsp(rsp)
  local code = rsp.ret_info.ret_code
  if 0 == code then
    if _G.BattleManager then
      _G.BattleEventCenter:Dispatch(BattleEvent.PUSHBACK_CMD_SENT, rsp)
    end
    self:StopAllAnimations()
    self:PlayAnimation(self.Out)
  elseif code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ILLEGAL_CHAR then
    self.HasSend = false
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_3, 0)
  else
    self.HasSend = false
  end
end

function UMG_Callname_C:OnFinalBattle2Rsp(rsp)
  if not self or not UE4.UObject.IsValid(self) then
    Log.Error("UMG_Callname_C:OnFinalBattle2Rsp: self is destroyed")
    return
  end
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_COMMON_CORO_TIMEOUT then
    Log.Warning("UMG_Callname_C:OnFinalBattle2Rsp: \230\163\128\230\181\139\229\136\176\232\182\133\230\151\182\239\188\140\233\135\141\230\150\176\229\143\145\233\128\129\232\175\183\230\177\130")
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINAL_BATTLE_P2_SUMMON_REQ, self.p2SummonReq, self, self.OnFinalBattle2Rsp, nil, true)
    return
  end
  if 0 == rsp.ret_info.ret_code then
    if self.HasCallSucc then
      return
    end
    if self.Button then
      self.Button:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
    self.HasCallSucc = true
    petName = rsp.pet.name
    NRCModuleManager:DoCmd(BattleUIModuleCmd.SaveFinalBattlePetData, rsp.pet)
    self:ShowDialogue()
    if UE4.UObject.IsValid(self) then
      self:StopAllAnimations()
      self:PlayAnimation(self.Out)
    end
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_FINAL_BATTLE_SUMMON_TIME_MAX then
    if self.HasCallSucc then
      return
    end
    if self.Button then
      self.Button:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
    petName = rsp.pet.name
    self.HasCallSucc = true
    local str = _G.DataConfigManager:GetBattleGlobalConfig("a1_finalbattle_autosummon_tips").str
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str, 0)
    NRCModuleManager:DoCmd(BattleUIModuleCmd.SaveFinalBattlePetData, rsp.pet)
    self:ShowDialogue()
    if UE4.UObject.IsValid(self) then
      self:StopAllAnimations()
      self:PlayAnimation(self.Out)
    end
  elseif -1 == rsp.ret_info.ret_code then
    local str = _G.DataConfigManager:GetBattleGlobalConfig("a1_finalbattle_summon_failed").str
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str, 0)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ILLEGAL_CHAR then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_characterpick_3, 0)
  else
    self:DoClose()
  end
end

function UMG_Callname_C:OnAnimationFinished(anim)
  if anim == self.In then
    self:PlayAnimation(self.Normal, nil, 999999)
  elseif anim == self.Out then
    self:DoClose()
  end
end

function UMG_Callname_C:ShowDialogue()
  local player = _G.BattleManager.battlePawnManager:GetTeamPlayer(BattleEnum.Team.ENUM_TEAM)
  if player and player.model then
    local dialogId = 1302018
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.AddOverrideCallback, "SelectText", self, self.AddOverrideCallback)
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.StartDialogueInBattle, player, dialogId, self, self.StartDialogue)
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.OverridePropertiesInBattleFsm, {ReturnCamera = false})
  end
end

function UMG_Callname_C:StartDialogue()
end

function UMG_Callname_C:AddOverrideCallback(SelectID, EntryType)
  Log.Debug("UMG_Callname_C:AddOverrideCallback ", SelectID, EntryType)
  if 160000409 == SelectID and "SelectText" == EntryType then
    return petName .. "!"
  end
end

return UMG_Callname_C
