local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local Base = NPCActionBase
local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local NPCActionOpenPVPRankedMatchUI = Base:Extend("NPCActionOpenPVPRankedMatchUI")

function NPCActionOpenPVPRankedMatchUI:Ctor(Owner, Config, Info)
  NPCActionBase.Ctor(self, Owner, Config, Info)
end

function NPCActionOpenPVPRankedMatchUI:ExecuteWithModel()
  Log.Debug("SeasonOpen Progress: PVPRankedMatchModule:ExecuteWithModel")
  self:OpenBlackScreen()
  self:AddListener()
end

function NPCActionOpenPVPRankedMatchUI:EndAction()
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.SetCurMatchPvpId, nil)
  _G.FunctionBanManager:RemovePlayerConditionType(_G.Enum.PlayerConditionType.PCT_PVP_RANK_MAIN_UI)
  _G.NRCEventCenter:UnRegisterEvent(self, PVPRankedMatchModuleEvent.ExistPVPQualifierPanel, self.ExistingOpenBlackScreen)
  _G.NRCEventCenter:UnRegisterEvent(self, PVPRankedMatchModuleEvent.StartRankMatch, self.OnStartRankMatch)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
  if _G.PVPRankedMatchCameraActor and UE.UObject.IsValid(_G.PVPRankedMatchCameraActor) then
    _G.PVPRankedMatchCameraActor:K2_DestroyActor()
  end
  _G.BattleEventCenter:UnBind(self)
  self.skillClass = nil
  self.skill = nil
  if self.skillComponent and UE4.UObject.IsValid(self.skillComponent) then
    self.skillComponent:ClearAllPassiveSkillObjs()
  end
  self.skillComponent = nil
  if self.NoNpc then
    if self.caller and self.callBack then
      self.callBack(self.caller)
    end
    self.NoNpc = nil
    self.caller = nil
    self.callBack = nil
  else
    self:Finish()
  end
end

function NPCActionOpenPVPRankedMatchUI:OpenBlackScreen()
  Log.Debug("SeasonOpen Progress: NPCActionOpenPVPRankedMatchUI:OpenBlackScreen")
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.SetCurMatchPvpId, 5001)
  _G.FunctionBanManager:AddPlayerConditionType(_G.Enum.PlayerConditionType.PCT_PVP_RANK_MAIN_UI)
  if self.NoNpc then
    self:ResetPlayerPos()
    self:ShowEndSkill()
  else
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OpenPVPCutto, "NPCActionOpenPVPRankedMatchUI", self, self.ShowSkill, false, false)
  end
end

function NPCActionOpenPVPRankedMatchUI:ResetPlayerPos()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  local pos = UE4.FVector(-802984, -779258, 29972)
  Player:SetActorLocation(pos)
  local targetRotation = UE4.FRotator(0, 90, 0)
  Player:SetActorRotation(targetRotation)
  Player:GetUEController():ResetCamera()
end

function NPCActionOpenPVPRankedMatchUI:ShowSkill()
  local resPath = "/Game/ArtRes/Effects/G6Skill/PVP/G6_PVP_Matching.G6_PVP_Matching_C"
  local resRequest = _G.NRCResourceManager:LoadResAsync(self, resPath, 255, 0, self.OnSkillLoaded, nil, nil)
end

function NPCActionOpenPVPRankedMatchUI:OnSkillLoaded(resRequest, skillAsset)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.skillClass = skillAsset
  local myPlayer = _G.BattleUtils.GetPlayerModel()
  self.skillComponent = myPlayer.RocoSkill
  self.skillComponent:ClearAllPassiveSkillObjs()
  self.skill = self.skillComponent:FindOrAddSkillObj(self.skillClass)
  local PointActor = self:GetCasterActor()
  self.skill:RegisterEventCallback("CameraShowEnd", self, self.OnCameraShowEnd)
  self.skill:RegisterEventCallback("ClearPlayerSkill", self, self.OnSkillEnd)
  self.skill:RegisterEventCallback("PostStart", self, self.OnPostStart)
  self.skill:RegisterEventCallback("RunAnim", self, self.OnRunAnim)
  self.skill:SetCaster(player.viewObj)
  self.skill:SetTargets({PointActor})
  self.skill:SetPassive(true)
  self.skillComponent:LoadAndPlaySkill(self.skill)
  DialogueUtils.StopLookAt(player)
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ClosePVPCutto)
end

function NPCActionOpenPVPRankedMatchUI:ShowEndSkill()
  Log.Debug("SeasonOpen Progress: NPCActionOpenPVPRankedMatchUI:ShowEndSkill")
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ClosePVPRankedMatch)
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OpenPVPRankedMatch)
  Log.Debug("SeasonOpen Progress: NPCActionOpenPVPRankedMatchUI:PVPRankedMatchModuleCmd.ClosePVPCutto")
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ClosePVPCutto)
end

function NPCActionOpenPVPRankedMatchUI:GetCasterActor()
  local CurrentWorld = UE4Helper.GetCurrentWorld()
  local foundActors = UE4.UGameplayStatics.GetAllActorsOfClassWithTag(CurrentWorld, UE4.ANote, "PvpRankMatchActor"):ToTable()
  if foundActors and #foundActors > 0 then
    self.CenterActor = foundActors[1]
  end
  return self.CenterActor
end

function NPCActionOpenPVPRankedMatchUI:CalRotation(player, PointActor)
  if not player or not PointActor then
    return
  end
  local playerRelPos = player:K2_GetActorLocation()
  playerRelPos.X = playerRelPos.X - 10
  local PointActorPos = PointActor:K2_GetActorLocation()
  local Forward = PointActorPos - playerRelPos
  Forward:Normalize()
  local Euler = Forward:ToRotator()
  player:K2_SetActorRotation(Euler, false)
end

function NPCActionOpenPVPRankedMatchUI:OnRunAnim(Event, Skill)
  local player = Skill:GetCaster()
  local pointActor = Skill:GetTargets()[1]
  if pointActor and player then
    self:CalRotation(player, pointActor)
  end
end

function NPCActionOpenPVPRankedMatchUI:OnPostStart(Event, Skill)
  _G.PVPRankedMatchCameraActor = Skill.Blackboard:GetValueAsObject("camActor_0001")
  Skill.Blackboard:RemoveObjectValue("camActor_0001")
end

function NPCActionOpenPVPRankedMatchUI:OnSkillEnd(Event, Skill)
end

function NPCActionOpenPVPRankedMatchUI:OnCameraShowEnd(Event, Skill)
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OpenPVPRankedMatch)
end

function NPCActionOpenPVPRankedMatchUI:AddListener()
  _G.NRCEventCenter:UnRegisterEvent(self, PVPRankedMatchModuleEvent.ExistPVPQualifierPanel, self.ExistingOpenBlackScreen)
  _G.NRCEventCenter:UnRegisterEvent(self, PVPRankedMatchModuleEvent.StartRankMatch, self.OnStartRankMatch)
  _G.NRCEventCenter:RegisterEvent("NPCActionOpenPVPRankedMatchUI", self, PVPRankedMatchModuleEvent.ExistPVPQualifierPanel, self.ExistingOpenBlackScreen)
  _G.NRCEventCenter:RegisterEvent("NPCActionOpenPVPRankedMatchUI", self, PVPRankedMatchModuleEvent.StartRankMatch, self.OnStartRankMatch)
  _G.NRCEventCenter:RegisterEvent("NPCActionOpenPVPRankedMatchUI", self, _G.NRCGlobalEvent.ON_CONNECTED, self.OnConnected)
end

function NPCActionOpenPVPRankedMatchUI:OnExistPVPQualifierPanel()
  self:EndAction()
end

function NPCActionOpenPVPRankedMatchUI:OnConnected()
  self:EndAction()
end

function NPCActionOpenPVPRankedMatchUI:OnStartRankMatch()
  self:EndAction()
end

function NPCActionOpenPVPRankedMatchUI:ExistingOpenBlackScreen()
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.TransferToRankMatchTutor)
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ClosePVPCutto)
  self:EndAction()
end

function NPCActionOpenPVPRankedMatchUI:SetNoNpc(caller, callBack)
  self.caller = caller
  self.callBack = callBack
  self.NoNpc = true
end

return NPCActionOpenPVPRankedMatchUI
