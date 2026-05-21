local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneLocalPlayerSimple = require("NewRoco.Modules.Core.Scene.Actor.SceneLocalPlayerSimple")
local PlayerModuleSimple = NRCModuleBase:Extend("PlayerModule")

function PlayerModuleSimple:OnConstruct()
  _G.PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
end

function PlayerModuleSimple:RegPanel(name, path, layer)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format(path)
  registerData.panelLayer = layer
  self:RegisterPanel(registerData)
end

function PlayerModuleSimple:OnActive()
  self:CreatePlayer()
  self:RegisterCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER, self.GetLocalPlayer)
  self:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE, self.OnInputMove)
  self:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TURN, self.OnInputTurn)
end

function PlayerModuleSimple:OnDestruct()
  self:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE)
  self:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TURN)
  self:UnRegisterCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.player:Destroy()
  self.player = nil
end

function PlayerModuleSimple:OnTick(deltaTime)
  if self.player then
    self.player:Update(deltaTime)
  end
end

function PlayerModuleSimple:CreatePlayer()
  self.player = SceneLocalPlayerSimple(self)
  self.player.isLocal = true
  self.playerActor = _G.UE4Helper.GetPlayerCharacter(0)
  self.player.playerActor = self.playerActor
  self.player:SetViewObj(self.playerActor)
  self.player:InitComponent()
  self.playerController = self.playerActor.Controller
  
  function self.player.GetUEController(selfParam)
    return self.playerController
  end
  
  local cameraMgr = self.player:GetUEController().PlayerCameraManager
  cameraMgr:RefreshPCCameraRotateSetting()
  cameraMgr:OnPossess(self.playerActor)
  cameraMgr.CustomBigWorldCamera = true
  self.player.FadeComponent:ApplyFadeRule()
  return self.player
end

function PlayerModuleSimple:GetLocalPlayer()
  return self.player
end

function PlayerModuleSimple:OnInputMove(dir, axis)
  local dir2D = UE4.FVector2D(dir.X, dir.Y)
  self.playerController:OnTouchMove(dir2D, axis)
end

function PlayerModuleSimple:OnInputTurn(dir, isRate)
  local TurnAccRate = 1
  local UMath = UE.UKismetMathLibrary
  dir = UMath.Multiply_Vector2DFloat(dir, TurnAccRate)
  local dir2D = UE4.FVector2D(dir.X, dir.Y)
  self.playerController:OnTouchTurn(dir2D, isRate)
end

return PlayerModuleSimple
