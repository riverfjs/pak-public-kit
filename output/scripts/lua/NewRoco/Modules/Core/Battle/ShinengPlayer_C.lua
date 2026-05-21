local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local ShinengPlayer_C = NRCClass:Extend("ShinengPlayer_C")

function ShinengPlayer_C:StartPlay(particle)
  self.ParticleSystem:SetTemplate(particle)
  self.IsOver = false
  self.ParticleSystem:Activate(true)
  _G.NRCAudioManager:PlaySound2DAuto(self.SoundId, "ShinengPlayer_C:StartPlay")
  self.delayId = _G.DelayManager:DelaySeconds(1.3, self.SpEnergyUI.CheckAndLoadUI, self.SpEnergyUI, self.ChangeNumber, self.SpEnergyElement)
end

function ShinengPlayer_C:SetData(posNumArray, posIndex, spUI, spEnergyElement, changeNumber, soundId)
  self.PosNumber = posNumArray
  self.PosIndex = posIndex
  self.SpEnergyUI = spUI
  self.ChangeNumber = changeNumber
  self.SpEnergyElement = spEnergyElement
  self.SoundId = soundId
end

function ShinengPlayer_C:OverPlay()
  if self.PosNumber then
    self.PosNumber[self.PosIndex] = self.PosNumber[self.PosIndex] - 1
  end
  _G.DelayManager:CancelDelay(self.delayId)
  self.delayId = nil
  self.PosNumber = nil
  self.IsOver = true
  self.SpEnergyUI = nil
end

return ShinengPlayer_C
