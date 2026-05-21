local PopupData = require("NewRoco.Modules.Core.Battle.Entity.Components.BuffEffectPopup.PopupData")
local PopupAttributeInfo = require("NewRoco.Modules.Core.Battle.Entity.Components.BuffEffectPopup.PopupAttributeInfo")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleComponent = require("NewRoco.Modules.Core.Battle.Entity.BattleComponent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattlePopupUMGPool = require("NewRoco.Modules.Core.Battle.Entity.Components.BuffEffectPopup.BattlePopupUMGPool")
local Base = BattleComponent
local BuffAEffectPopupComponent = BattleComponent:Extend("BuffAEffectPopupComponent")
local TIME_EACH = 0.2
local BUFF_TIME_EACH = _G.DataConfigManager:GetBattleGlobalConfig("buff_tip_show_time_cd").num / 1000
local POP_ONCE_TIME = 0.7

function BuffAEffectPopupComponent:Ctor(owner)
  Base.Ctor(self)
  self.owner = owner
  self.popupQueue = Queue()
  self.buffPopupQueue = Queue()
  self.replayArray = {}
  self.popupLeftTime = 0
  self.buffPopupLeftTime = 0
  self.popTime = 0
  self.popTimeTable = {}
  self.DamageUmgMap = {}
  WeakTable(self.DamageUmgMap)
  self:SetEnable(true)
  self.umgPool = BattlePopupUMGPool(self.owner)
end

function BuffAEffectPopupComponent:OnTick(deltaTime)
  if self.popupLeftTime >= 0 then
    self.popupLeftTime = self.popupLeftTime - deltaTime
    if self.popupLeftTime < 0 and self.popupQueue:Size() > 0 then
      self:DoPopup(self.popupQueue:Dequeue())
      self.popupLeftTime = TIME_EACH
    end
  end
  if self.buffPopupLeftTime >= 0 then
    self.buffPopupLeftTime = self.buffPopupLeftTime - deltaTime
    if self.buffPopupLeftTime < 0 and self.buffPopupQueue:Size() > 0 then
      self:DoPopup(self.buffPopupQueue:Dequeue())
      self.buffPopupLeftTime = BUFF_TIME_EACH
    end
  end
end

function BuffAEffectPopupComponent:PopupDamageNumber(num, isHealing, damage_info)
  local data = PopupData.MakePopup(num, ProtoEnum.AddIcon.AI_DAMAGE)
  data:SetHeal(isHealing)
  if damage_info then
    data:SetCritical(damage_info.is_critical and damage_info.is_critical[1] or false)
    data:SetRestraintType(damage_info.restraint_type)
    data:SetDamageNumber(self:GetDamageTotalDamage(damage_info), damage_info.curDamageNumber, num)
    data:SetSourceId(damage_info.source_id)
    data:SetDamageType(damage_info.dam_type)
  end
  self:Popup(data)
end

function BuffAEffectPopupComponent:GetDamageTotalDamage(damage_info)
  return damage_info.totalDamageNumber
end

function BuffAEffectPopupComponent:ReplayDamageNumber(num, damage_info)
  local umg = self.DamageUmgMap[damage_info.source_id]
  if umg then
    self:DoReplayDamageNumber(umg, num, damage_info)
  else
    local damage = {
      curDamageNumber = damage_info.curDamageNumber,
      totalDamageNumber = self:GetDamageTotalDamage(damage_info),
      source_id = damage_info.source_id
    }
    local replayData = {num, damage}
    table.insert(self.replayArray, 1, replayData)
  end
end

function BuffAEffectPopupComponent:DoReplayDamageNumber(umg, num, damage_info)
  if not UE4.UObject.IsValid(umg) then
    self.DamageUmgMap[damage_info.source_id] = nil
    return
  end
  umg:RePlay(damage_info.curDamageNumber, num)
  if damage_info.curDamageNumber >= self:GetDamageTotalDamage(damage_info) then
    self.DamageUmgMap[damage_info.source_id] = nil
  end
end

function BuffAEffectPopupComponent:PopupBuff(buffID, attachOrTrigger)
  self:PopupBuffQueue(PopupData.FromBuffID(buffID, attachOrTrigger))
end

function BuffAEffectPopupComponent:PopupEffect(effectConf, effectUINum)
  self:PopupBuffQueue(PopupData.FromEffectConf(effectConf, effectUINum))
end

function BuffAEffectPopupComponent:Popup(data)
  if not data then
    return
  end
  self.popupQueue:Enqueue(data)
  self.popupLeftTime = math.max(0, self.popupLeftTime)
  self:OnTick(0.001)
end

function BuffAEffectPopupComponent:PopupBuffQueue(data)
  if not data then
    return
  end
  self.buffPopupQueue:Enqueue(data)
  self.buffPopupLeftTime = math.max(0, self.buffPopupLeftTime)
end

function BuffAEffectPopupComponent:IsSameBuffPopupData(a, b)
  if a == b then
    return true
  end
  if not a or not b then
    return false
  end
  if a.popupShowType ~= b.popupShowType then
    return false
  end
  if a.content ~= b.content then
    return false
  end
  local aInfo = a.attrInfo
  local bInfo = b.attrInfo
  if aInfo == bInfo then
    return true
  end
  if not aInfo or not bInfo then
    return false
  end
  if aInfo.attrType ~= bInfo.attrType then
    return false
  end
  if aInfo.id ~= bInfo.id then
    return false
  end
  return true
end

function BuffAEffectPopupComponent:DedupBuffPopupQueue(equalFunc)
  local queue = self.buffPopupQueue
  if not queue or queue:Size() <= 6 then
    return 0
  end
  local isSame = equalFunc or function(a, b)
    return self:IsSameBuffPopupData(a, b)
  end
  local uniqueList = {}
  local removedCount = 0
  local originalSize = queue:Size()
  for _ = 1, originalSize do
    local item = queue:Dequeue()
    local duplicated = false
    for i = 1, #uniqueList do
      if isSame(uniqueList[i], item) then
        duplicated = true
        break
      end
    end
    if duplicated then
      removedCount = removedCount + 1
    else
      uniqueList[#uniqueList + 1] = item
    end
  end
  for i = 1, #uniqueList do
    queue:Enqueue(uniqueList[i])
  end
  return removedCount
end

function BuffAEffectPopupComponent:PopupImmediately(data)
  if not data then
    return
  end
  self:DoPopup(data)
end

function BuffAEffectPopupComponent:GetFatherPanelBType(popupData)
  local fatherPanel, initPos
  if self.owner and self.owner.battlePetComponents then
    if popupData.popupShowType == ProtoEnum.AddIcon.AI_UP then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(50, 70)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_DOWN then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(50, -10)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_DAMAGE then
      if popupData.isHealing then
        fatherPanel, initPos = self.owner.battlePetComponents.PopupDamagePanel, UE4.FVector2D(80, 110)
      else
        fatherPanel, initPos = self.owner.battlePetComponents.PopupDamagePanel, UE4.FVector2D(100, 55)
      end
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_CRITICAL then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(-40, 10)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_DEBUFF then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(-40, 10)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_BUFF then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(-40, 10)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_POISON then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(-40, 10)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_FIRE then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(0, 10)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_SEED then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(-40, 10)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_FREEZEN then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(-40, 10)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_BLOOD then
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(-40, 10)
    else
      fatherPanel, initPos = self.owner.battlePetComponents.PopupUIFather, UE4.FVector2D(-40, 10)
    end
    local SpecialMap = {
      [ProtoEnum.AddIcon.AI_UP] = true,
      [ProtoEnum.AddIcon.AI_DOWN] = true,
      [ProtoEnum.AddIcon.AI_DAMAGE] = true
    }
    if not SpecialMap[popupData.popupShowType] then
      initPos = self.owner.battlePetComponents:GetValidPopupNormalPos(initPos)
    end
    return fatherPanel, initPos
  end
  return nil, UE4.FVector2D(0, 0)
end

function BuffAEffectPopupComponent:DoPopup(popupData)
  local isDelay = self:PreAddCheckPopupChildPanel(popupData)
  if isDelay then
    self.d_OnUMGLoad = _G.DelayManager:DelayFrames(2, function()
      popupData:GetUMG(self, self.OnUMGLoad)
    end)
  else
    popupData:GetUMG(self, self.OnUMGLoad)
  end
end

function BuffAEffectPopupComponent:OnUMGLoad(_UMG, popupData)
  if not _UMG then
    return
  end
  _UMG:SetCallBack(self, self.CheckPopupChildPanel, popupData)
  self:ProcessUMG(_UMG, popupData)
end

function BuffAEffectPopupComponent:GetFatherPanel(popupData)
  Log.Debug("rcGetFatherPanel", popupData.isHit)
  if popupData.isHit then
    local panel, Pos = self:GetFatherPanelBType(popupData)
    return panel
  else
    local BattleMain = BattleUtils.GetMainWindow()
    if not BattleMain then
      return
    end
    return BattleMain.DamageNumber
  end
end

function BuffAEffectPopupComponent:ProcessUMG(_UMG, popupData)
  if not _UMG or not UE.UObject.IsValid(_UMG) then
    return
  end
  if not self.owner or self.owner.destroyed then
    return
  end
  if popupData.isHit then
    local panel, Pos = self:GetFatherPanelBType(popupData)
    if popupData.popupShowType == ProtoEnum.AddIcon.AI_DAMAGE then
      local currentTime = os.clock()
      if currentTime - self.popTime >= POP_ONCE_TIME then
        self.popTimeTable = {}
        if _UMG.Slot then
          _UMG.Slot:SetPosition(Pos)
        end
      else
        local continueTimes = #self.popTimeTable + 1
        for i, v in ipairs(self.popTimeTable) do
          if currentTime - v >= POP_ONCE_TIME * 2 then
            continueTimes = i
            break
          end
        end
        Pos.Y = Pos.Y + (self:GetRandPosByType(popupData, continueTimes) or 0)
        self.popTimeTable[continueTimes] = currentTime
        if _UMG.Slot then
          _UMG.Slot:SetPosition(Pos)
        end
      end
      self.popTime = currentTime
    elseif _UMG.Slot then
      _UMG.Slot:SetPosition(Pos)
    end
  else
    local vP = UE4.FVector2D(0, 0)
    vP = PetUtils.GetBattlePetSocketPosition2D(self.owner)
    if _UMG.Slot then
      _UMG.Slot:SetPosition(vP)
    end
  end
  _UMG:Play()
  if popupData.SourceId and popupData.CurDamageNumber < popupData.TotalDamageNumber then
    if self.DamageUmgMap[popupData.SourceId] then
      Log.Error("Appear a repeat UMG ", popupData.SourceId)
    end
    self.DamageUmgMap[popupData.SourceId] = _UMG
    for i = #self.replayArray, 1, -1 do
      if self.replayArray[i][2].source_id == popupData.SourceId then
        self:DoReplayDamageNumber(_UMG, self.replayArray[i][1], self.replayArray[i][2])
        table.remove(self.replayArray, i)
      end
    end
  end
end

function BuffAEffectPopupComponent:GetRandPosByType(popupData, continueTimes)
  if self.owner and self.owner.battlePetComponents then
    if popupData.popupShowType == ProtoEnum.AddIcon.AI_DAMAGE then
      if popupData.isHealing then
        return math.rand(20, 60)
      else
        local minNum = continueTimes * 30 - 10
        local maxNum = minNum + 10
        return math.rand(minNum, maxNum)
      end
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_DEBUFF then
      return math.rand(20, 50)
    elseif popupData.popupShowType == ProtoEnum.AddIcon.AI_UP then
      return 0
    else
      return math.rand(20, 50)
    end
  end
end

function BuffAEffectPopupComponent:CheckPopupVisibilityEffect(effectConf)
  local BattleMain = BattleUtils.GetMainWindow()
  if not BattleMain then
    return
  end
  return true
end

function BuffAEffectPopupComponent:PreAddCheckPopupChildPanel(popupData)
  if not popupData.isHit or not self.owner.battlePetComponents then
    return false
  end
  if popupData.popupShowType == ProtoEnum.AddIcon.AI_DAMAGE then
    return self.owner.battlePetComponents:PreAddPopupDamageChildPanel()
  else
    return self.owner.battlePetComponents:PreAddPopupNormalChildPanel()
  end
end

function BuffAEffectPopupComponent:CheckPopupChildPanel(popupData)
  if not popupData.isHit or not self.owner.battlePetComponents then
    return
  end
  if popupData.popupShowType == ProtoEnum.AddIcon.AI_DAMAGE then
    self.owner.battlePetComponents:DeletePopupDamageChildPanel()
  else
    self.owner.battlePetComponents:DeletePopupNormalChildPanel()
  end
end

function BuffAEffectPopupComponent:RecycleUMG(_UMG, umgPath)
  if not _UMG or not UE.UObject.IsValid(_UMG) then
    return
  end
  if string.IsNilOrEmpty(umgPath) then
    local popupData = _UMG.Popup
    if popupData then
      umgPath = popupData and popupData.umgPath or nil
    end
  end
  if _UMG.RemoveFromParent then
    _UMG:RemoveFromParent()
  end
  if self.umgPool and umgPath then
    self.umgPool:Release(_UMG, umgPath)
  end
end

function BuffAEffectPopupComponent:PreloadUMGPool(callback, callbackOwner)
  if not self.umgPool then
    if callback then
      callback(callbackOwner, false)
    end
    return
  end
  self.umgPool:Preload(callback, callbackOwner)
end

function BuffAEffectPopupComponent:_DestroyUMGPool()
  if self.umgPool then
    self.umgPool:Destroy()
    self.umgPool = nil
    Log.Debug("[BuffAEffectPopupComponent] UMG pool destroyed")
  end
end

function BuffAEffectPopupComponent:OnDestroy()
  self:_DestroyUMGPool()
  self.d_OnUMGLoad = _G.DelayManager:CancelDelayByIdEx(self.d_OnUMGLoad)
end

return BuffAEffectPopupComponent
