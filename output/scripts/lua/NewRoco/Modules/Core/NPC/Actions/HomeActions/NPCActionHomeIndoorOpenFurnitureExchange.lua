local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local SkillSeqProxy = require("NewRoco/Modules/System/Home/IndoorSandbox/Proxy/SkillSeqProxy")
local M = Base:Extend("NPCActionHomeIndoorOpenFurnitureExchange")

function M:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function M:Execute()
  Base.Execute(self)
  local owner = self:GetOwnerNPC()
  if not owner or not owner.viewObj then
    self:Finish(true)
    return
  end
  local player = self:GetPlayer()
  if player then
    player:SetVisible(false)
  end
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, true)
  HomeIndoorSandbox.World:HideCurrRoomFurniture(true)
  HomeIndoorSandbox:RegisterEvent(HomeIndoorSandbox.Event.OnReqToggleFurnitureBoxShadow, self, self.OnRspToggleFurnitureBoxShadow)
  self.SkillSeqProxy = SkillSeqProxy()
  local StartConf = SkillSeqProxy.CreateSkillElemConfig("DD_NPC", "/Game/ArtRes/Effects/G6Skill/Home/G6_Home_ThrowBox_Start", true)
  StartConf:SetTargetKeys({"BOX_NPC"})
  StartConf:SetSkillEvent("PreStart", function(Elem)
    Elem:ShowActor("BOX_NPC")
    Elem:HideActor("P2_NPC")
    Elem:HideActor("P3_NPC")
    Elem:HideActor("P4_NPC")
    local Box = self.SkillSeqProxy:GetActor("BOX_NPC")
    local Light = self.SkillSeqProxy:GetActor("Light1")
    Light:K2_AttachToActor(Box, "", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
    if Light and UE.UObject.IsValid(Light) then
      Light:SetShadowVisibility(false)
    end
  end)
  StartConf:SetSkillEvent("End", function(Elem)
    if not self.bSkillFinish then
      self.bSkillFinish = true
      self:TryOpenFurniturePanel()
    end
  end)
  StartConf:SetTargetKeys({"BOX_NPC"})
  StartConf:SetSkillEvent("EnterBox", function()
    if not self.bSkillFinish then
      self.bSkillFinish = true
      local Light = self.SkillSeqProxy:GetActor("Light1", true)
      if Light and UE.UObject.IsValid(Light) then
        Light:SetShadowVisibility(true)
      end
      self:TryOpenFurniturePanel()
    end
  end)
  local WorkConf = SkillSeqProxy.CreateSkillElemConfig("BOX_NPC", "/Game/ArtRes/Effects/G6Skill/Home/G6_Home_ThrowBox_Work", false)
  WorkConf:SetCharacterKeys({
    [BattleConst.CharacterIndex.Player1] = "BOX_NPC",
    [BattleConst.CharacterIndex.Player2] = "P2_NPC",
    [BattleConst.CharacterIndex.Player3] = "P3_NPC",
    [BattleConst.CharacterIndex.Player4] = "P4_NPC"
  })
  WorkConf:SetSkillEvent("PreStart", function(Elem)
    Elem:DestroyActor("Light1")
    Elem:DestroyActor("Light3")
    local Box = self.SkillSeqProxy:GetActor("BOX_NPC")
    local Light = self.SkillSeqProxy:GetActor("Light2")
    Light:K2_AttachToActor(Box, "", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
    if Box and Box.HiddenSceneFx then
      Box:HiddenSceneFx(true)
    end
  end)
  WorkConf:SetSkillEvent("Start", function(Elem)
    Elem:ShowActor("P2_NPC")
    Elem:ShowActor("P3_NPC")
    Elem:ShowActor("P4_NPC")
    Elem:ShowActor("Light2")
  end)
  WorkConf:SetPrepareSkillDelegate(function(self, skill)
    skill:GetBlackboard():SetValueAsBool("Loop", false)
  end)
  WorkConf:SetSkillEvent("PreEndWork", function()
    self:CopySetTempWorkingCamera()
  end)
  WorkConf:SetSkillEvent("End", function()
    local Box = self.SkillSeqProxy:GetActor("BOX_NPC")
    if Box and Box.HiddenSceneFx then
      Box:HiddenSceneFx(false)
    end
    self:OnPreEnterEnd()
  end)
  local EndConf = SkillSeqProxy.CreateSkillElemConfig("BOX_NPC", "/Game/ArtRes/Effects/G6Skill/Home/G6_Home_ThrowBox_End", false)
  EndConf:SetCharacterKeys({
    [BattleConst.CharacterIndex.Player1] = "BOX_NPC",
    [BattleConst.CharacterIndex.Player2] = "P2_NPC",
    [BattleConst.CharacterIndex.Player3] = "P3_NPC",
    [BattleConst.CharacterIndex.Player4] = "P4_NPC"
  })
  EndConf:SetSkillEvent("End", function(Elem)
    Elem:DestroyActor("Light2")
    local Box = self.SkillSeqProxy:GetActor("BOX_NPC")
    local Light = self.SkillSeqProxy:GetActor("Light3")
    if Box and Light and UE.UObject.IsValid(Box) and UE.UObject.IsValid(Light) then
      Light:K2_AttachToActor(Box, "", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
    end
  end)
  EndConf:SetPrepareSkillDelegate(function(self, skill)
    skill:GetBlackboard():SetValueAsBool("Loop", true)
  end)
  EndConf:SetSkillEvent("EndWork", function(Elem)
    self:RemoveWorkingTempCamera()
    self:OnWorkStop()
  end)
  self.EndConf = EndConf
  self.WorkSeq = {WorkConf, EndConf}
  self.SkillSeqProxy:AddActor("DD_NPC", owner.viewObj)
  self.SkillSeqProxy:AddResourcePaths("BOX_NPC", "/Game/NewRoco/Modules/Core/NPC/Home/House/BP_NPC_SKM_Homerld_Case_001.BP_NPC_SKM_Homerld_Case_001_C")
  self.SkillSeqProxy:AddResourcePaths("P2_NPC", "/Game/ArtRes/BP/Scene/NPC_09802/BP_Scene_NPC_09802.BP_Scene_NPC_09802_C")
  self.SkillSeqProxy:AddResourcePaths("P3_NPC", "/Game/ArtRes/BP/Scene/NPC_09803/BP_Scene_NPC_09803.BP_Scene_NPC_09803_C")
  self.SkillSeqProxy:AddResourcePaths("P4_NPC", "/Game/ArtRes/BP/Scene/NPC_09801/BP_Scene_NPC_09801.BP_Scene_NPC_09801_C")
  self.SkillSeqProxy:AddResourcePaths("Light1", "/Game/ArtRes/Level/Game/Homeworld/BP/BP_ThrowBoxLightStart.BP_ThrowBoxLightStart_C")
  self.SkillSeqProxy:AddResourcePaths("Light2", "/Game/ArtRes/Level/Game/Homeworld/BP/BP_ThrowBoxLightWork.BP_ThrowBoxLightWork_C")
  self.SkillSeqProxy:AddResourcePaths("Light3", "/Game/ArtRes/Level/Game/Homeworld/BP/BP_ThrowBoxLightStartNoTimeLine.BP_ThrowBoxLightStartNoTimeLine_C")
  self.SkillSeqProxy:AddResourcePaths("Light4", "/Game/ArtRes/Level/Game/Homeworld/BP/BP_ThrowBoxPointLight.BP_ThrowBoxPointLight_C")
  self.SkillSeqProxy:AddSkillElemConfig(StartConf)
  self.SkillSeqProxy:AddSkillElemConfig(WorkConf)
  self.SkillSeqProxy:AddSkillElemConfig(EndConf)
  self.SkillSeqProxy:Play(function()
    self:Finish(true)
  end)
  _G.NRCEventCenter:RegisterEvent("NPCActionHomeIndoorOpenFurnitureExchange", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnReconnect)
  HomeIndoorSandbox.Server:ReqFurnitureCreationList(function(bSuccess, ProtoData)
    if self.bFinishThisAction then
      return
    end
    if not bSuccess or not ProtoData then
      self:OnReconnect()
      return
    end
    self.ProtoData = ProtoData
    self:TryOpenFurniturePanel()
  end)
  self.bWorkPerformFinish = true
  HomeIndoorSandbox:RegisterEvent(HomeIndoorSandbox.Event.OnReqPlayWorkAnimStart, self, self.PlayWork)
  HomeIndoorSandbox:RegisterEvent(HomeIndoorSandbox.Event.OnReqStopEndWork, self, self.EndWork)
  HomeIndoorSandbox.ResMgr:ReqResource(function()
  end, HomeIndoorSandbox.Enum.FurnitureCreationCapture_C)
end

function M:CopySetTempWorkingCamera()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not (localPlayer and localPlayer.viewObj) or not UE.UObject.IsValid(localPlayer.viewObj) then
    return
  end
  local playerController = localPlayer:GetUEController()
  if not playerController or not UE.UObject.IsValid(playerController) then
    return
  end
  local curCamActor = playerController:GetViewTarget()
  if not curCamActor then
    return
  end
  local bLookAtBoxCamera = UE.UObject.IsA(curCamActor, UE.ACameraActor)
  if not bLookAtBoxCamera then
    return
  end
  local Transform = curCamActor:Abs_GetTransform()
  local TempCam = UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE.ACameraActor, Transform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  local CamComp = TempCam:GetComponentByClass(UE.UCameraComponent)
  local CurCamComp = curCamActor:GetComponentByClass(UE.UCameraComponent)
  CamComp:SetFieldOfView(CurCamComp.FieldOfView)
  CamComp:SetConstraintAspectRatio(CurCamComp.bConstrainAspectRatio)
  playerController:SetViewTargetWithBlend(TempCam, 0, nil, nil, true)
  self.WorkingTempCam = TempCam
end

function M:RemoveWorkingTempCamera()
  if self.WorkingTempCam and UE.UObject.IsValid(self.WorkingTempCam) then
    self.WorkingTempCam:K2_DestroyActor()
    self.WorkingTempCam = nil
  end
end

function M:EndWork()
  Log.Debug("\230\137\147\233\128\160\232\161\168\230\188\148\231\187\136\230\173\162\228\184\173\239\188\140\229\133\179\230\142\137\228\186\134\229\165\150\229\138\177\231\149\140\233\157\162...")
  self.EndConf:HideActor("P2_NPC", true)
  self.EndConf:HideActor("P3_NPC", true)
  self.EndConf:HideActor("P4_NPC", true)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not (localPlayer and localPlayer.viewObj) or not UE.UObject.IsValid(localPlayer.viewObj) then
    return
  end
  local playerController = localPlayer:GetUEController()
  if not playerController or not UE.UObject.IsValid(playerController) then
    return
  end
  local curCamActor = playerController:GetViewTarget()
  if not curCamActor then
    return
  end
  local Transform = curCamActor:Abs_GetTransform()
  local bLookAtBoxCamera = UE.UObject.IsA(curCamActor, UE.ACameraActor)
  local TempCam
  if bLookAtBoxCamera then
    TempCam = UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE.ACameraActor, Transform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    local CamComp = TempCam:GetComponentByClass(UE.UCameraComponent)
    local CurCamComp = curCamActor:GetComponentByClass(UE.UCameraComponent)
    CamComp:SetFieldOfView(CurCamComp.FieldOfView)
    CamComp:SetConstraintAspectRatio(CurCamComp.bConstrainAspectRatio)
  end
  self.SkillSeqProxy:StopElemConfigSeq()
  if TempCam then
    self:ReturnCamera(TempCam)
  end
end

function M:PlayWork()
  Log.Debug("\230\137\147\233\128\160\232\161\168\230\188\148\229\188\128\229\167\139...")
  self.bWorkPerformFinish = false
  self:RecordCamera()
  self.SkillSeqProxy:ReplayElemConfigSeq(self.WorkSeq)
  HomeIndoorSandbox.Module:PreLoadPanel("HomeCreationSuccess")
end

function M:ReturnCamera(TempCam)
  if self.boxCameraActor then
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local playerController = localPlayer:GetUEController()
    if UE.UObject.IsValid(TempCam) then
      playerController:SetViewTargetWithBlend(TempCam, 0)
    end
    playerController:SetViewTargetWithBlend(self.boxCameraActor, 0.15, UE4.EViewTargetBlendFunction.VTBlend_Linear, 2)
    DelayManager:DelaySeconds(1, function()
      if UE.UObject.IsValid(TempCam) then
        TempCam:K2_DestroyActor()
      end
    end)
  end
end

function M:RecordCamera()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerController = localPlayer:GetUEController()
  local curCamActor = playerController:GetViewTarget()
  self.boxCameraActor = curCamActor
end

function M:OnWorkStop()
  if not self.bWorkPerformFinish then
    self.bWorkPerformFinish = true
    Log.Debug("\230\137\147\233\128\160\232\161\168\230\188\148\229\174\140\230\136\144\239\188\140\230\152\190\231\164\186\229\165\150\229\138\177\231\149\140\233\157\162...")
    HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnRspPlayWorkAnimEnd)
  end
end

function M:OnPreEnterEnd()
  if not self.bWorkPerformFinish then
    HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnPreEnterWorkAnimEnd)
  end
end

function M:OnClosePanel(PanelData)
  local Name = PanelData.panelName
  if "HomeFurnitureCreation" == Name then
    self.bFinishCompleted = true
    self:Finish(true)
    _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  end
end

function M:TryOpenFurniturePanel()
  if self.bSkillFinish and self.ProtoData then
    _G.NRCEventCenter:RegisterEvent("NPCActionHomeIndoorOpenFurnitureExchange", self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
    NRCModuleManager:DoCmd(HomeModuleCmd.OpenHomeFurnitureExchangePanel, self.ProtoData, {
      BoxNpc = self.SkillSeqProxy:GetActor("BOX_NPC"),
      FurniturePointLight = self.SkillSeqProxy:GetActor("Light4")
    })
    _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  end
end

function M:OnReconnect()
  self:Finish(true)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function M:Finish(...)
  Base.Finish(self, ...)
  self.bFinishThisAction = true
  self.SkillSeqProxy:Destroy()
  local owner = self:GetOwnerNPC()
  if owner and owner.viewObj then
    owner.viewObj:SetActorHiddenInGame(false)
  end
  local player = self:GetPlayer()
  if player then
    player:SetVisible(true)
  end
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false)
  HomeIndoorSandbox.World:HideCurrRoomFurniture(false)
  HomeIndoorSandbox:UnRegisterEvent(HomeIndoorSandbox.Event.OnReqPlayWorkAnimStart, self)
  HomeIndoorSandbox:UnRegisterEvent(HomeIndoorSandbox.Event.OnReqStopEndWork, self)
  if not self.bFinishCompleted then
    HomeIndoorSandbox.Module:ClosePanel("HomeFurnitureCreation")
  end
  HomeIndoorSandbox:UnRegisterEvent(HomeIndoorSandbox.Event.OnReqToggleFurnitureBoxShadow, self)
  self:RemoveWorkingTempCamera()
end

function M:OnRspToggleFurnitureBoxShadow(bEnable)
  local Light = self.SkillSeqProxy.Actors.Light3 or self.SkillSeqProxy.Actors.Light1
  if Light then
    local Comp = Light.Plane2
    if Comp then
      Comp:SetVisibility(bEnable)
    end
  end
end

return M
