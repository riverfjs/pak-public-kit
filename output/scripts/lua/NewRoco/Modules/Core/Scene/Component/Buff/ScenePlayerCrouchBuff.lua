local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerBuff")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ScenePlayerCrouchBuff = Base:Extend("ScenePlayerCrouchBuff")

function ScenePlayerCrouchBuff:OnBegin(player)
  local playerBP = player.viewObj
  if playerBP then
    local characterMovement = playerBP.CharacterMovement
    playerBP.IsCrouch = true
    playerBP.bIsCrouch = true
    self.statCurveID = player.statComponent:ApplyStat(StatType.MAX_WALK_SPEED_CURVE, nil, nil, characterMovement)
    self.statSpeedID = player.statComponent:ApplyStat(StatType.MAX_WALK_SPEED, characterMovement.MaxWalkSpeedCrouched, nil, characterMovement)
    characterMovement.RM_MaxSpeed = 500
  end
  self.player = player
end

function ScenePlayerCrouchBuff:OnFinish()
  if self.player then
    local playerBP = self.player.viewObj
    if playerBP then
      local characterMovement = playerBP.CharacterMovement
      playerBP.IsCrouch = false
      playerBP.bIsCrouch = false
      self.player.statComponent:RemoveStat(StatType.MAX_WALK_SPEED_CURVE, self.statCurveID, characterMovement)
      self.player.statComponent:RemoveStat(StatType.MAX_WALK_SPEED, self.statSpeedID, characterMovement)
    end
    self.player = nil
  end
end

return ScenePlayerCrouchBuff
