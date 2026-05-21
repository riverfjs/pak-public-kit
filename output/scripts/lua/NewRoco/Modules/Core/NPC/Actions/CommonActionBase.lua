local Class = _G.MakeSimpleClass
local EventDispatcher = require("Common.EventDispatcher")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local CommonActionBase = Class("CommonActionBase", nil, 16)
local MinExecuteInterval = 0.3
CommonActionBase:SetMemberCount(16)
EventDispatcher.BindClass(CommonActionBase)

function CommonActionBase:PreCtor()
  self.SkipSubmit = nil
  self.playerId = nil
  self.LastExecuteTime = -1
  self.DisableInterval = false
end

function CommonActionBase:Ctor(Owner, Config)
  EventDispatcher(2, 2, true):Attach(self)
  self.Owner = Owner
  self.Config = Config
end

function CommonActionBase:GetPlayer()
  if self.playerId then
    local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.playerId)
    return Player
  end
  local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  return Player
end

function CommonActionBase:RegisterThisActionToPlayer()
  if not self:HasLocalPerform() then
    return
  end
  if not self:IsLocalAction() then
    return
  end
  if self.SkipSubmit then
    return
  end
  local Player = self:GetPlayer()
  if Player then
    Player.interactionComponent:SetInteractingAction(self)
  else
    self:LogError("NPCActionBase:RegisterThisActionToPlayer  Player is nil")
  end
end

function CommonActionBase:UnregisterThisActionToPlayer()
  if not self:HasLocalPerform() then
    return
  end
  if not self:IsLocalAction() then
    return
  end
  if self.SkipSubmit then
    return
  end
  local Player = self:GetPlayer()
  if not Player or not Player.interactionComponent then
    return
  end
  Player.interactionComponent:ClearInteractingAction(self)
end

function CommonActionBase:HasLocalPerform()
  return DialogueUtils.IsClientCommit(self.Config and self.Config.action_type)
end

function CommonActionBase:IsLocalAction()
  if self.playerId then
    local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    return Player.serverData.base.actor_id == self.playerId
  else
    return true
  end
end

local function CheckSceneFullyEntered()
  return _G.SceneModuleCmd and _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.CheckSceneFullyEntered) or false
end

function CommonActionBase:OnNpcAction()
  if not self.Owner then
    Log.Error("NPC option Owner\228\184\141\229\173\152\229\156\168\239\188\140\228\184\141\229\186\148\232\175\165\232\176\131\231\148\168\229\136\176OnNpcAction")
    return false
  end
  if self.Owner.NeedStatusNotify and self.Owner:NeedStatusNotify() then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\231\173\137\229\190\133\229\133\182\228\187\150\228\186\164\228\186\146\229\155\158\229\140\133")
    return false
  end
  if not _G.ZoneServer:IsEnteredCell() then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\229\156\186\230\153\175\231\138\182\230\128\129\228\184\141\229\175\185(\229\186\148\232\175\165\228\184\186EnteredCall)", _G.ZoneServer:GetOnlineState())
    return false
  end
  if not _G.ZoneServer:CanSendNetworkCmd() then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\229\189\147\229\137\141\230\151\160\230\179\149\229\143\145\229\140\133")
    return false
  end
  local SceneReady = CheckSceneFullyEntered()
  if not SceneReady then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\229\156\186\230\153\175\230\156\170\229\138\160\232\189\189\229\174\140\230\136\144")
    return false
  end
  local IsCinematicPlaying = _G.NRCModuleManager:DoCmd(_G.CinematicModuleCmd.IsPlaying)
  if IsCinematicPlaying then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\173\163\229\156\168Cinematic\228\184\173")
    return false
  end
  if _G.BattleManager:IsInBattle() then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\173\163\229\156\168\230\136\152\230\150\151\228\184\173")
    return false
  elseif _G.BattleManager.isSendWaiting then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\173\163\229\156\168\231\148\179\232\175\183\232\191\155\229\133\165\230\136\152\230\150\151\231\173\137\229\190\133\228\184\173")
    return false
  end
  if #_G.BattleManager.battleNetManager.cachedBattleNotify > 0 then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\156\137\229\190\133\229\164\132\231\144\134\231\154\132\230\136\152\230\150\151\229\141\143\232\174\174(\229\143\175\232\131\189\228\188\154\232\191\155\229\133\165\230\136\152\230\150\151)")
    return false
  end
  if _G.NRCPanelManager:GetLoadingPanelCount() > 0 then
    self:LogError("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\156\137\230\173\163\229\156\168\229\138\160\232\189\189\228\184\173\231\154\132\233\157\162\230\157\191")
    return false
  end
  if _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.IsOpenCamera) then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\229\176\143\230\184\184\230\136\143\232\191\144\233\149\156\228\184\173")
    return false
  end
  local Now = _G.UpdateManager.Timestamp
  if not self.DisableInterval and Now - self.LastExecuteTime < MinExecuteInterval then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\137\167\232\161\140\232\191\135\228\186\142\233\162\145\231\185\129", self.LastExecuteTime, Now)
    return false
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\151\160\230\179\149\232\142\183\229\143\150SceneLocalPlayer")
    return false
  end
  local HPComp = localPlayer.roleHPComponent
  if HPComp and 0 == HPComp:GetLocalRoleHP() then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\231\142\169\229\174\182\232\161\128\233\135\143\228\184\186\233\155\182")
    return false
  end
  local InterComp = localPlayer.interactionComponent
  if InterComp and InterComp:HasInteractingAction() then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\156\137\229\143\166\228\184\128\228\184\170Action\229\156\168\230\137\167\232\161\140", InterComp:GetInteractingActionDesc())
    return false
  end
  local IsFighting = localPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
  if IsFighting then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\229\144\142\229\143\176\232\174\164\228\184\186\231\142\169\229\174\182\232\191\152\229\156\168\230\136\152\230\150\151\228\184\173")
    return false
  end
  local NavComp = localPlayer.NavigationComponent
  if NavComp and NavComp.isLockPlayer then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:NavigationComponent\230\173\163\229\156\168\229\175\187\232\183\175")
    return false
  end
  if _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\229\183\178\231\187\143\229\175\185\232\175\157\228\184\173")
    return false
  end
  local InstanceModule = NRCModuleManager:GetModule("InstanceModule")
  if InstanceModule.bSwitching then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146, \230\173\163\229\156\168\231\173\137\229\190\133\229\137\175\230\156\172\230\181\129\231\168\139")
    return false
  end
  local ownerConfig = self.Owner and self.Owner.config
  local CD = ownerConfig and ownerConfig.touch_battle_cd
  if CD and CD > 0 then
    CD = CD / 1000
    local LastDialogue = self:DoCmd(DialogueModuleCmd.GetLastDialogueEndTime) or 0
    if Now < LastDialogue + CD then
      self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\229\175\185\232\175\157\229\136\154\229\136\154\231\187\147\230\157\159", LastDialogue, Now)
      return false
    end
    local LastBattle = self:DoCmd(NPCModuleCmd.GetLastBattleEndTime) or 0
    if Now < LastBattle + CD then
      self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\230\136\152\230\150\151\229\136\154\229\136\154\231\187\147\230\157\159", LastBattle, Now)
      return false
    end
  end
  local InteractType = ownerConfig and ownerConfig.npc_interact_type
  local NeedMsg = InteractType ~= Enum.InteractType.IT_NONE and InteractType ~= Enum.InteractType.IT_AUTO
  local Ban, _ = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_PLAYER_OPTION, NeedMsg, NeedMsg)
  if Ban then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:PFBT_PLAYER_OPTION\231\166\129\231\148\168\230\137\128\230\156\137\228\186\164\228\186\146")
    return false
  end
  local PartialBan, Msg = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_LOAD_BAN_ACTION_CONF, NeedMsg, false)
  if PartialBan then
    local Conds = _G.FunctionBanManager:GetPlayerConditions()
    for Key, _ in pairs(Conds) do
      local Banned = _G.FunctionBanManager:GetConditionCounter(Key)
      if not Banned then
      else
        local BanActionConf = _G.DataConfigManager:GetBanActionConf(Key, true)
        if not BanActionConf then
        elseif #BanActionConf.banned_cond_list > 0 then
          for _, Val in ipairs(BanActionConf.banned_cond_list) do
            if Val.banned_list == self.Config.action_type then
              self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\229\156\168BAN_ACTION_CONF.banned_cond_list\229\136\151\232\161\168\228\184\173", Key)
              if NeedMsg and not string.IsNilOrEmpty(Msg) then
                _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Msg)
              end
              return false
            end
          end
        elseif #BanActionConf.allow_list > 0 then
          local Found = false
          for _, Val in ipairs(BanActionConf.allow_list) do
            if Val.allowed_list == self.Config.action_type then
              Found = true
            end
          end
          if not Found then
            self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:\228\184\141\229\156\168BAN_ACTION_CONF.allow_list\229\136\151\232\161\168\228\184\173", Key)
            if NeedMsg and not string.IsNilOrEmpty(Msg) then
              _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Msg)
            end
            return false
          end
        end
      end
    end
  end
  if self.Owner.CheckOptionIsBan and self.Owner:CheckOptionIsBan(true) then
    self:Log("\230\151\160\230\179\149\232\167\166\229\143\145\228\186\164\228\186\146:isBan")
    return false
  end
  return self:OnNpcActionCustomized()
end

function CommonActionBase:OnNpcActionCustomized()
  return true
end

function CommonActionBase:GetDesc(Level)
  Level = Level or Log.LOG_LEVEL.ELogDebug
  if Level <= Log.GetLogLevel() then
    return "[NpcAction]"
  end
  local OwnerNpcInfo = self.OwnerNpc and self.OwnerNpc:DebugNPCNameAndID() or "Unknown"
  local OwnerConf = self.Owner and self.Owner.config
  local OwnerID = OwnerConf and OwnerConf.id or -1
  local ActionType = self.Config and self.Config.action_type or 0
  local ActionTypeName = ActionType >= 0 and table.getKeyName(Enum.ActionType, ActionType) or "Unknown"
  return string.format("[NpcAction][%s]NPC=%s,Option=%d,Action=%s", self.name, OwnerNpcInfo, OwnerID, ActionTypeName)
end

function CommonActionBase:Log(...)
  Log.Debug(self:GetDesc(Log.LOG_LEVEL.ELogDebug), ...)
end

function CommonActionBase:LogWarning(...)
  Log.Warning(self:GetDesc(Log.LOG_LEVEL.ELogWarn), ...)
end

function CommonActionBase:LogError(...)
  Log.Error(self:GetDesc(Log.LOG_LEVEL.ELogError), ...)
end

return CommonActionBase
