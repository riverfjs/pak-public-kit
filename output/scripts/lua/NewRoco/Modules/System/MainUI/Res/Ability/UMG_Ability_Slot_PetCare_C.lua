local Base = require("NewRoco.Modules.System.MainUI.Res.Ability.UMG_Ability_Slot_C")
local UMG_Ability_Slot_PetCare_C = Base:Extend("UMG_Ability_Slot_PetCare_C")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local NPCModuleCmd = require("NewRoco.Modules.Core.NPC.NPCModuleCmd")

function UMG_Ability_Slot_PetCare_C:OnConstruct()
  Base.OnConstruct(self)
  self._isVisible = false
  self:AddEventListener()
  self:RefreshUI()
end

local CALLIN_BEHAVIOR

local function GetCallinBehavior()
  if CALLIN_BEHAVIOR then
    return CALLIN_BEHAVIOR
  end
  local conf = _G.DataConfigManager:GetNpcGlobalConfig("home_callin_behavior_group", true)
  CALLIN_BEHAVIOR = conf.num or 0
  return CALLIN_BEHAVIOR
end

function UMG_Ability_Slot_PetCare_C:AddEventListener()
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:RegisterEvent(self, HomeModuleEvent.OnEnterHomeMap, self.RefreshUI)
    homeModule:RegisterEvent(self, HomeModuleEvent.OnExitHomeMap, self.RefreshUI)
  end
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_HOME_PET_CALL, self, self.OnFunctionBan)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_PetCare_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
end

function UMG_Ability_Slot_PetCare_C:OnFunctionBan()
  self:RefreshUI()
end

function UMG_Ability_Slot_PetCare_C:RefreshUI()
  local visible = false
  local isBan = _G.FunctionBanManager:GetFunctionState(_G.Enum.PlayerFunctionBanType.PFBT_HOME_PET_CALL)
  if isBan then
    visible = false
  elseif _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InLocalMasterIndoor() then
    visible = true
  else
    visible = false
  end
  if nil ~= visible and self._isVisible ~= visible then
    self._isVisible = visible
    if self.FoundationPCKey then
      self.FoundationPCKey:SetVisibility(self._isVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
    if self.ParentPanel then
      self.ParentPanel:SetVisibility(self._isVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
    if UE4Helper.IsPCMode() then
      if self._isVisible then
        self:PlayAnimation(self.show)
      else
        self:PlayAnimation(self.out)
      end
    end
    self:SetVisible(self._isVisible)
  end
end

function UMG_Ability_Slot_PetCare_C:OnSlotPressed()
  local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_HOME_PET_CALL, false, false)
  if Ban or not self:IsVisible() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_Home_Property_C:OnActive")
  if not self:IsPlayingAnimation() then
    self:PlayAnimation(self.Press)
  end
  if not _G.HomeIndoorSandbox or _G.HomeIndoorSandbox:InOtherHomeIndoor() then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player.statusComponent then
    if player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_HOME_PET_CALL) then
      return
    end
    local canApply, overrideValues, opCode = player.statusComponent:PreApplyStatus(Enum.WorldPlayerStatusType.WPST_HOME_PET_CALL)
    if not canApply then
      return
    end
  end
  local homePetInfo = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePetInfo)
  if homePetInfo and type(homePetInfo) == "table" and #homePetInfo > 0 then
    local behavior = GetCallinBehavior()
    local npcs = _G.NRCModeManager:DoCmd(NPCModuleCmd.GetAllNPC)
    if npcs then
      for _, petInfo in pairs(homePetInfo) do
        local npc = npcs[petInfo.base.actor_id]
        if npc and npc.AIComponent and npc.AIComponent:IsActive() then
          npc.AIComponent:OverrideBehavior(behavior, _G.Enum.BehaviorOverridePriority.BOP_B)
          npc.AIComponent:NotifyDotsWorldEvent(_G.Enum.DotsAIWorldEventType.DAWET_HOME_PET_CALLIN)
        end
      end
    end
    if player.statusComponent then
      player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_HOME_PET_CALL)
    end
    if player and player.viewObj then
      local skillComp = player.viewObj.RocoSkill
      if skillComp and UE4.UObject.IsValid(skillComp) then
        local skillPath = _G.DataConfigManager:GetHomeGlobalConfig("call_resource_path").str
        local skill = RocoSkillProxy.Create(skillPath, skillComp)
        if skill then
          if player.viewObj.CharacterMovement then
            player.viewObj.CharacterMovement:ConsumeInputVector()
            player.viewObj.CharacterMovement:StopMovementImmediately()
          end
          skill:RegisterEventCallback("End", self, self.OnSkillEnd)
          skill:RegisterEventCallback("ActivateFailed", self, self.OnSkillEnd)
          skill:RegisterEventCallback("Interrupt", self, self.OnSkillEnd)
          skill:SetWithLoadAndPlay(true)
          skill:SetCaster(player.viewObj)
          skill:SetPassive(false)
          skill:PlaySkill()
        end
      end
    end
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.home_call_pet_2)
  end
end

function UMG_Ability_Slot_PetCare_C:OnSkillEnd()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player.statusComponent then
    player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_HOME_PET_CALL)
  end
end

function UMG_Ability_Slot_PetCare_C:OnReconnectFinish()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player.statusComponent then
    player.statusComponent:ClearStatus(ProtoEnum.WorldPlayerStatusType.WPST_HOME_PET_CALL)
  end
end

function UMG_Ability_Slot_PetCare_C:OnPCKey()
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if _G.FriendModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  end
  self:OnSlotPressed()
end

function UMG_Ability_Slot_PetCare_C:OnDestruct()
  Base.OnDestruct(self)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_GOODS_REWARD_NOTIFY, self.OnZoneGoodsRewardNotify)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEnterHomeMap)
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnExitHomeMap)
  end
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_HOME_PET_CALL, self, self.OnFunctionBan)
end

function UMG_Ability_Slot_PetCare_C:OnPlayerStatusChanged(status, value, opCode)
  Base:OnPlayerStatusChanged(status, value, opCode)
  self:RefreshUI()
end

return UMG_Ability_Slot_PetCare_C
