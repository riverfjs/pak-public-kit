require("UnLuaEx")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local BattleUIModuleCmd = reload("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local BP_LobbyMainCompass_C = NRCClass()

function BP_LobbyMainCompass_C:Initialize(Initializer)
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.playerCtrl = UE4.UGameplayStatics.GetPlayerControllerFromID(self.player.viewObj, 0)
  self.curTilt = UE4.FVector(0, 0, 0)
  local amplitude_bag = _G.DataConfigManager:GetGlobalConfigByKeyType("amplitude_dip_bag", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
  local amplitude_pet = _G.DataConfigManager:GetGlobalConfigByKeyType("amplitude_dip_pet", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
  local amplitude_battle = _G.DataConfigManager:GetGlobalConfigByKeyType("amplitude_dip_battle", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
  local amplitude_map = _G.DataConfigManager:GetGlobalConfigByKeyType("amplitude_dip_map", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
  local amplitude_task = _G.DataConfigManager:GetGlobalConfigByKeyType("amplitude_dip_task", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
  local amplitude_handbook = _G.DataConfigManager:GetGlobalConfigByKeyType("amplitude_dip_handbook", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
  self.amplitudeList = {
    amplitude_battle,
    amplitude_map,
    amplitude_task,
    amplitude_pet,
    amplitude_bag,
    amplitude_handbook
  }
end

function BP_LobbyMainCompass_C:ReceiveBeginPlay()
  _G.NRCEventCenter:RegisterEvent("BP_LobbyMainCompass_C", self, HandbookModuleEvent.OnHandBookChanged, self.OnHandBookChanged)
  self:UpdateRedDot()
end

function BP_LobbyMainCompass_C:ReceiveEndPlay(EndPlayReason)
  _G.NRCEventCenter:UnRegisterEvent(self, HandbookModuleEvent.OnHandBookChanged, self.OnHandBookChanged)
end

function BP_LobbyMainCompass_C:OnHandBookChanged()
  self:UpdateRedDot()
end

function BP_LobbyMainCompass_C:UpdateRedDot()
  local handBookRedPoint = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.CheckTopRedPoint)
  if self.BookRedDotWidget then
    self.BookRedDotWidget:SetVisibility(handBookRedPoint)
  end
end

function BP_LobbyMainCompass_C:ReceiveTick(DeltaSeconds)
  local tilt1, rotationrate, gravity, acceleration = self.playerCtrl:GetInputMotionState()
  self.curTilt = tilt1
  local tilt2 = self.curTilt - self.startTilt
  if tilt2 then
    local tilt = UE4.FVector(0, tilt2.Y, 0)
    self.PVP:K2_SetRelativeRotation(tilt * 20)
    self.Map:K2_SetRelativeRotation(tilt * 20)
    self.Task:K2_SetRelativeRotation(tilt * 20)
    self.Pet:K2_SetRelativeRotation(tilt * 20)
    self.Bag:K2_SetRelativeRotation(tilt * 20)
    self.Book:K2_SetRelativeRotation(tilt * 20)
  end
end

function BP_LobbyMainCompass_C:SetStartRelativeRotation()
  self.startTilt = self.playerCtrl:GetInputMotionState()
  self.startPosList = {
    self.PVP.RelativeRotation,
    self.Map.RelativeRotation,
    self.Task.RelativeRotation,
    self.Pet.RelativeRotation,
    self.Bag.RelativeRotation,
    self.Book.RelativeRotation
  }
end

function BP_LobbyMainCompass_C:OnClickSkeletalMesh(StaticMesh)
end

return BP_LobbyMainCompass_C
