require("UnLuaEx")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local UMG_Battle_EnergyView_C = NRCUmgClass:Extend("")

function UMG_Battle_EnergyView_C:Construct()
  self.battleManager = _G.BattleManager
  self.lastGetEnergyRecord = {
    {time = 0, count = 0},
    {time = 0, count = 0}
  }
  self:AddListeners()
end

function UMG_Battle_EnergyView_C:Destruct()
  self:RemoveListeners()
  self.battleManager = nil
  self.lastGetEnergyRecord = {}
  self.Overridden.Destruct(self)
end

function UMG_Battle_EnergyView_C:AddListeners()
  BattleEventCenter:Bind(self, BattlePerformEvent.CostEnergy, BattlePerformEvent.GainEnergy, BattleEvent.UI_UPDATE_ENERGY, BattleEvent.DIRECT_UPDATE_UI, BattleEvent.ROUND_START)
end

function UMG_Battle_EnergyView_C:RemoveListeners()
  BattleEventCenter:UnBind(self)
end

function UMG_Battle_EnergyView_C:InitView(pet)
  self.FlyingEnergy = 0
  if pet then
    self.battlePet = pet
    self.EnergyView:SetSyncCount(pet:GetEnergy())
    self.EnergyView:SetSlots(pet:GetEnergy())
    self.EnergyView:SetSyncCount(self.EnergyView.CurrentCount)
    self:CheckB1FinalBattleP1UI()
  end
end

function UMG_Battle_EnergyView_C:PlayerLeave()
  self.battlePet = nil
end

function UMG_Battle_EnergyView_C:Hide()
  self:SetRenderOpacity(0)
end

function UMG_Battle_EnergyView_C:Show()
  self:SetRenderOpacity(1)
end

function UMG_Battle_EnergyView_C:OnBattleEvent(eventName, ...)
  if self:IsB1FinalBattleP1Enemy() then
    return
  end
  if eventName == BattlePerformEvent.CostEnergy then
    local petId, changeValue = ...
    if _G.BattleUtils.IsB1FinalBattleP2() or _G.BattleUtils.IsB1FinalBattleP3() then
      self:OnDirectUpdateEnergy(changeValue, true)
      return
    end
    if self.battlePet and self.battlePet.guid == petId then
      self:OnDirectUpdateEnergy(changeValue)
    end
  elseif eventName == BattlePerformEvent.GainEnergy then
    local petId, changeValue, sourceId, isFly = ...
    if _G.BattleUtils.IsB1FinalBattleP2() or _G.BattleUtils.IsB1FinalBattleP3() then
      self:OnDirectUpdateEnergy(changeValue)
      return
    end
    if self.battlePet and self.battlePet.guid == petId then
      if isFly then
        if sourceId > 0 then
          local effect = _G.DataConfigManager:GetEffectConf(sourceId, true)
          if effect and effect.effect_order == Enum.EffectType.ET_STEAL_ENERGY then
            local Pet
            if self.battlePet.teamEnm == BattleEnum.Team.ENUM_TEAM then
              Pet = _G.BattleManager.battlePawnManager:GetInFieldPet(BattleEnum.Team.ENUM_ENEMY)
            else
              Pet = _G.BattleManager.battlePawnManager:GetInFieldPet(BattleEnum.Team.ENUM_TEAM)
            end
            if Pet then
              self:UpdateEnergyTrack(Pet, changeValue)
            else
              self:OnUpdateEnergy(changeValue)
            end
          else
            self:OnUpdateEnergy(changeValue)
          end
        else
          self:OnUpdateEnergy(changeValue)
        end
      else
        self:OnDirectUpdateEnergy(changeValue)
      end
    end
  elseif eventName == BattleEvent.UI_UPDATE_ENERGY then
    self:OnDirectUpdateEnergy(...)
  elseif eventName == BattleEvent.DIRECT_UPDATE_UI then
    self:OnDirectUpdateEnergy()
  elseif eventName == BattleEvent.ROUND_START then
    self:OnDirectUpdateEnergy(...)
  end
end

function UMG_Battle_EnergyView_C:OnDirectUpdatePoint(isFormEnergyConvergence)
  if not self.battlePet then
    return
  end
  local newPoint = self.battlePet:GetEnergy()
  self.EnergyView:SetGradePoint(newPoint, isFormEnergyConvergence)
end

function UMG_Battle_EnergyView_C:OnDirectUpdateEnergy(flyNum, isFormEnergyConvergence)
  if not self.battlePet then
    return
  end
  if _G.BattleUtils.IsB1FinalBattleP2() or _G.BattleUtils.IsB1FinalBattleP3() then
    self:OnDirectUpdatePoint(isFormEnergyConvergence)
    return
  end
  self.EnergyView:SetSyncCount(self.battlePet:GetEnergy())
  local performNum = self.EnergyView:GetPerformCount()
  local syncNum = self.EnergyView:GetSyncCount()
  flyNum = flyNum or 0
  if syncNum > flyNum + performNum + self.FlyingEnergy then
    flyNum = syncNum - performNum - self.FlyingEnergy
  end
  self.EnergyView:SetEnergy(performNum + flyNum)
end

function UMG_Battle_EnergyView_C:OnUpdateEnergy(flyNum)
  self:UpdateEnergyTrack(self.battlePet, flyNum)
end

function UMG_Battle_EnergyView_C:UpdateEnergyTrack(Pet, flyNum)
  if not self.battlePet then
    return
  end
  local vP = PetUtils.GetBattlePetSocketPosition2D(Pet)
  flyNum = flyNum or 0
  local real = self.battlePet:GetEnergy() - self.EnergyView:GetSyncCount()
  local UINum = 0
  if flyNum > 0 and real > 0 then
    UINum = math.max(real, flyNum)
  else
    UINum = real
  end
  local moveOffset = 0
  self.EnergyView:SetSyncCount(self.battlePet:GetEnergy())
  if 0 ~= UINum then
    if UINum > 0 then
      local time = UE4Helper.GetTime()
      local recordId = self.battlePet.player == Pet.player and 1 or 2
      local record = self.lastGetEnergyRecord[recordId]
      if time - record.time > 0.5 then
        record.time = time
        record.count = UINum
      else
        record.count = record.count + UINum
        moveOffset = record.count
      end
    end
    BattleUtils.ProcessEnergyTrack(vP, self, BattleUtils.EnergyTrackType.DirectFly, UINum, self, BattleUtils.OnProcessEnergyTrackComplete, moveOffset)
  end
end

function UMG_Battle_EnergyView_C:IncreaseEnergy(num, flyEnd)
  local prevCount = self.EnergyView.CurrentCount or 0
  local nextCount = math.min(prevCount + num, self.EnergyView:GetSyncCount())
  self.EnergyView:PlayStarUpDownAnim(prevCount, nextCount)
  self.EnergyView:SetEnergy(nextCount)
  if flyEnd then
    self.FlyingEnergy = self.FlyingEnergy - 1
    if self.FlyingEnergy < 0 then
      self.FlyingEnergy = 0
      Log.Error("\232\131\189\233\135\143\233\163\158\232\161\140\230\149\176\231\155\174\229\135\186\233\148\153\239\188\129\239\188\129\239\188\129")
    end
  end
end

function UMG_Battle_EnergyView_C:DecreaseEnergy(num)
  local prevCount = self.EnergyView.CurrentCount or 0
  local nextCount = math.max(prevCount - num, 0)
  self.EnergyView:PlayStarUpDownAnim(prevCount, nextCount)
  self.EnergyView:SetEnergy(nextCount)
end

function UMG_Battle_EnergyView_C:IsB1FinalBattleP1Enemy()
  if not _G.BattleUtils.IsB1FinalBattleP1() then
    return false
  end
  if not self.battlePet then
    return false
  end
  if self.battlePet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return true
  end
  return false
end

function UMG_Battle_EnergyView_C:CheckB1FinalBattleP1UI()
  if self:IsB1FinalBattleP1Enemy() then
    self.EnergyView:CheckB1FinalBattleP1UI()
  end
end

function UMG_Battle_EnergyView_C:DirectUpdateEnergy()
  if self.battlePet then
    local energy = self.battlePet:GetEnergy()
    self.EnergyView:SetSyncCount(energy)
    if energy > self.EnergyView.CurrentCount then
      self:IncreaseEnergy(energy - self.EnergyView.CurrentCount)
    elseif energy < self.EnergyView.CurrentCount then
      self:IncreaseEnergy(self.EnergyView.CurrentCount - energy)
    end
  end
end

return UMG_Battle_EnergyView_C
