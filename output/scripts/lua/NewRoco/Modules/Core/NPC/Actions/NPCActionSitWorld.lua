local NPCActionSit = require("NewRoco.Modules.Core.NPC.Actions.NPCActionSit")
local Base = NPCActionSit
local NPCActionSitWorld = Base:Extend("NPCActionSitWorld")

function NPCActionSitWorld:StartSit(SeatSlot, SpecialG6, FadeType)
  local Player = self:GetPlayer()
  if not Player or not Player.playerToyComponent then
    return
  end
  local SeatConf = _G.DataConfigManager:GetSeatConf(self.OwnerNpc.config.id)
  if not SeatConf or not SeatConf.seat_point then
    Log.Error("NPCActionSitWorld:StartSit - seat_conf not found for NPC:", self.OwnerNpc.config.id)
    return
  end
  local SeatIdx = tonumber(string.match(SeatSlot, "Seat_(%d+)"))
  if not SeatIdx then
    Log.Error("NPCActionSitWorld:StartSit - invalid SeatSlot:", SeatSlot)
    return
  end
  local SeatPointConf = SeatConf.seat_point[SeatIdx]
  if not SeatPointConf then
    Log.Error("NPCActionSitWorld:StartSit - seat_point not found for SeatIdx:", SeatIdx)
    return
  end
  Player.playerToyComponent:PlayerSitToSceneSeat(self:GetOwnerNPC(), nil, self.ImmediatelySit, SeatPointConf, FadeType)
end

return NPCActionSitWorld
