local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local DummyTable = require("Common.DummyTable")
local UMG_Battle_SpEnergy_List_C = _G.NRCPanelBase:Extend("UMG_Battle_SpEnergy_List_C")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")

function UMG_Battle_SpEnergy_List_C:OnConstruct()
  self.battleManager = _G.BattleManager
  self.SpEnergyUIs = {}
  self.lastGetEnergyRecord = {}
  self.SpEnergyNumber = 0
  self.WillRemoveSPNumber = 0
  self.energyFlyDetal = 0.1
  self.energyFlyStartTime = 0
  self.spFlyNumber = 0
  self.BattleMainWindow = nil
  self.EffectPlayer = {}
  self.isInitPos = false
  self:AddListeners()
  self.spEnergyQueue = Queue()
  self.isValidToPop = true
end

function UMG_Battle_SpEnergy_List_C:OnDestruct()
  self:RemoveListeners()
  self.battleManager = nil
  self.SpEnergyUIs = {}
  self.lastGetEnergyRecord = {}
  self.BattleMainWindow = nil
  for i = 1, #self.EffectPlayer do
    self.EffectPlayer[i]:K2_DestroyActor()
  end
end

function UMG_Battle_SpEnergy_List_C:AddListeners()
  BattleEventCenter:Bind(self, BattlePerformEvent.SpEnergyChange, BattleEvent.SP_ENERGY_TRIGGER)
end

function UMG_Battle_SpEnergy_List_C:RemoveListeners()
  BattleEventCenter:UnBind(self)
end

function UMG_Battle_SpEnergy_List_C:Hide()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_SpEnergy_List_C:Show()
  self:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Battle_SpEnergy_List_C:TriggerEnergy(damType)
  local itemUI = self.SpEnergyUIs[damType]
  if itemUI then
    itemUI:Trigger(damType)
  end
end

function UMG_Battle_SpEnergy_List_C:ToHalfAlpha(half)
  if half ~= self.isHalfAlpha and self.SpEnergyUIs then
    self.isHalfAlpha = half
    for _, item in pairs(self.SpEnergyUIs) do
      item:ToHalfAlpha()
    end
  end
end

function UMG_Battle_SpEnergy_List_C:GetPosInList(posInserver)
  local posInList = 0
  for i, v in pairs(self.SpEnergyUIs) do
    if v and posInserver > v.PosInServer then
      posInList = posInList + 1
    end
  end
  return posInList
end

function UMG_Battle_SpEnergy_List_C:InitByData()
end

function UMG_Battle_SpEnergy_List_C:LoadSpUI()
  _G.BattleResourceManager:LoadResAsync(self, _G.UEPath.UMG_Battle_SpEnergy, self.LoadSpUIOver)
end

function UMG_Battle_SpEnergy_List_C:LoadSpUIOver(res)
  local data = _G.BattleManager.battleRuntimeData.spEnergyElementList
  if data then
    for _, v in ipairs(data) do
      local pos = 0
      if v.stack > 0 then
        local itemUI = self.SpEnergyUIs[v.dam_type]
        if not itemUI then
          itemUI = UE4.UWidgetBlueprintLibrary.Create(UE4Helper.GetCurrentWorld(), res)
          itemUI:InitByData(self, v)
          itemUI:SetServerPos(pos)
          self.SpEnergyList:InsertChildToHorizontalBox(pos, itemUI)
          self.SpEnergyNumber = self.SpEnergyNumber + 1
          self.SpEnergyUIs[v.dam_type] = itemUI
        end
        pos = pos + 1
        itemUI:SetStack(v.stack)
      end
    end
  end
end

function UMG_Battle_SpEnergy_List_C:OnBattleEvent(eventName, ...)
  if eventName == BattlePerformEvent.SpEnergyChange then
    local changeData = (...)
    self:DoPopup(changeData)
  elseif eventName == BattleEvent.SP_ENERGY_TRIGGER then
    self:TriggerEnergy(...)
  end
end

function UMG_Battle_SpEnergy_List_C:OnRoundStart()
  local data = _G.BattleManager.battleRuntimeData.spEnergyElementList
  local oldData = _G.BattleManager.battleRuntimeData.preRoundSpEnergyList
  if data then
    for k, v in ipairs(data) do
      local old = oldData[k]
      if not old or old.stack ~= v.stack then
        local nowStack = 0
        if old then
          nowStack = old.stack
        end
        if nowStack < v.stack then
          self:AddSpEnergy(v, ProtoEnum.BattleSpEnergyChange.SP_ENERGY_SRC.SRC_WEATHER, v.stack - nowStack)
        else
          self:DelSpEnergy(v)
        end
      end
    end
    for k, v in ipairs(oldData) do
      if not data[k] then
        self:RemoveSpEnergyByType(v.dam_type)
      end
    end
  end
end

function UMG_Battle_SpEnergy_List_C:DelSpEnergy(spEnergyElement)
  local itemUI = self.SpEnergyUIs[spEnergyElement.dam_type]
  if itemUI then
    itemUI:DecreaseEnergy(spEnergyElement.stack)
  end
  if spEnergyElement.stack <= 0 then
    self.SpEnergyUIs[spEnergyElement.dam_type] = nil
    self.SpEnergyNumber = self.SpEnergyNumber - 1
  end
end

function UMG_Battle_SpEnergy_List_C:RemoveSpEnergyByType(damType)
  local itemUI = self.SpEnergyUIs[damType]
  if itemUI then
    itemUI:Remove()
  end
  self.SpEnergyUIs[damType] = nil
  self.SpEnergyNumber = self.SpEnergyNumber - 1
end

function UMG_Battle_SpEnergy_List_C:RemoveSpEnergy(spEnergyElement)
  local itemUI = self.SpEnergyUIs[spEnergyElement.dam_type]
  if itemUI then
    itemUI:Remove()
  end
  self.SpEnergyUIs[spEnergyElement.dam_type] = nil
  self.SpEnergyNumber = self.SpEnergyNumber - 1
end

function UMG_Battle_SpEnergy_List_C:ReplaceSpEnergy(changeData)
  local itemUI = self.SpEnergyUIs[changeData.replaced_dam_type]
  if itemUI then
    itemUI:Remove()
  end
  self.SpEnergyUIs[changeData.replaced_dam_type] = nil
  if not self.SpEnergyUIs[changeData.ele.dam_type] and itemUI then
    itemUI.isRemove = false
    self.SpEnergyUIs[changeData.ele.dam_type] = itemUI
  else
    self.SpEnergyNumber = self.SpEnergyNumber - 1
  end
end

function UMG_Battle_SpEnergy_List_C:ComputeStartPos(source, petId, effectPlayer)
  if effectPlayer then
    local pos = effectPlayer.UIShowPos:GetRelativeTransform().Translation
    pos = UE4.UKismetMathLibrary.TransformLocation(effectPlayer:Abs_GetTransform(), pos)
    local vP = UE4.FVector2D(0, 0)
    local uP = UE4.FVector2D(0, 0)
    local fieldRoot = self.battleManager.battlePawnManager.VBattleField.battleFieldConf
    UE4.UGameplayStatics.Abs_ProjectWorldToScreen(UE4.UGameplayStatics.GetPlayerController(fieldRoot, 0), pos, uP, false)
    UE4.USlateBlueprintLibrary.ScreenToViewport(_G.UE4Helper.GetCurrentWorld(), uP, vP)
    return vP
  else
    return UE4.FVector2D(0, 0)
  end
end

function UMG_Battle_SpEnergy_List_C:ComputeEndPos(damageType)
  if damageType and self.SpEnergyUIs[damageType] then
    local _, pos = UE4.USlateBlueprintLibrary.LocalToViewport(UE4Helper.GetCurrentWorld(), self.SpEnergyUIs[damageType].SpEnergyImage:GetCachedGeometry(), UE4.FVector2D(17, 17))
    return pos
  else
    local _, pos = UE4.USlateBlueprintLibrary.LocalToViewport(UE4Helper.GetCurrentWorld(), self.SpEnergyList:GetCachedGeometry(), UE4.FVector2D(0, 37))
    if self.SpEnergyNumber > 0 then
      pos.X = pos.X + self.SpEnergyNumber * 35 + 17
    end
    return pos
  end
end

function UMG_Battle_SpEnergy_List_C:ComputeOffset(flyNumber, source)
  local time = UE4Helper.GetTime()
  local moveOffset = 0
  if not self.lastGetEnergyRecord[source] then
    self.lastGetEnergyRecord[source] = {time = 0, count = 0}
  end
  local record = self.lastGetEnergyRecord[source]
  if time - record.time > 0.5 then
    record.time = time
    record.count = flyNumber
  else
    record.count = record.count + flyNumber
    moveOffset = record.count
  end
  return moveOffset
end

function UMG_Battle_SpEnergy_List_C:FlySpEnergyEffect(flyNumber, spEnergyElement, source, effectPlayer, petId)
  if flyNumber > 0 then
    local startPos = self:ComputeStartPos(source, petId, effectPlayer)
    local endPos = self:ComputeEndPos(spEnergyElement.dam_type)
    for i = 1, flyNumber do
      BattleResourceManager:LoadWidgetAsyncWithParam(self, BattleConst.UI.UMG_Battle_SpEnergy_FlyTrack, nil, self.OnUmgLoad, nil, self.BattleMainWindow, i, startPos, endPos, spEnergyElement)
    end
  else
    Log.Error("spEnergy fly number is error ", flyNumber)
  end
end

function UMG_Battle_SpEnergy_List_C:OnUmgLoad(retUMG, idx, startPos, endPos, spEnergyElement)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1098, "BattleUtils.ProcessEnergyTrack")
  self.BattleMainWindow.DamageNumber:AddChildtoCanvas(retUMG)
  retUMG:SetMovingModeFromList(idx)
  retUMG.Slot:SetAlignment(UE4.FVector2D(0.5, 0.5))
  retUMG.Slot:SetAutoSize(true)
  retUMG:Fly(startPos, endPos, self, spEnergyElement)
end

function UMG_Battle_SpEnergy_List_C:FlyEffectCallBack(res, spEnergyElement)
  self.spFlyNumber = self.spFlyNumber - 1
  if self.spFlyNumber <= 0 then
    self.spFlyNumber = 0
    self.isValidToPop = true
  end
  local itemUI = self.SpEnergyUIs[spEnergyElement.dam_type]
  local curStack = self.battleManager.battleRuntimeData:GetSpEnergyStackByType(spEnergyElement.dam_type)
  if not itemUI then
    if curStack <= 0 then
      return
    end
    local pos = self.battleManager.battleRuntimeData:GetSpEnergyPosByType(spEnergyElement.dam_type)
    itemUI = UE4.UWidgetBlueprintLibrary.Create(self.BattleMainWindow, res)
    itemUI:InitByData(self, spEnergyElement)
    itemUI:SetServerPos(pos)
    self.SpEnergyList:InsertChildToHorizontalBox(self:GetPosInList(pos), itemUI)
    self.SpEnergyNumber = self.SpEnergyNumber + 1
    self.SpEnergyUIs[spEnergyElement.dam_type] = itemUI
  end
  if itemUI.dam_type ~= spEnergyElement.dam_type then
    itemUI:InitByData(self, spEnergyElement)
  end
  itemUI:AddEnergy(math.min(curStack, itemUI.StackNum + 1))
end

function UMG_Battle_SpEnergy_List_C:CheckAndLoadUI(flyNumber, spEnergyElement)
  local itemUI = self.SpEnergyUIs[spEnergyElement.dam_type]
  if not itemUI then
    _G.BattleResourceManager:LoadResAsyncWithParam(self, _G.UEPath.UMG_Battle_SpEnergy, self.StartUIAnim, nil, flyNumber, spEnergyElement)
  end
end

function UMG_Battle_SpEnergy_List_C:StartUIAnim(res, flyNumber, spEnergyElement)
  if not self.BattleMainWindow then
    return
  end
  self.spFlyNumber = self.spFlyNumber - flyNumber
  if self.spFlyNumber <= 0 then
    self.spFlyNumber = 0
    self.isValidToPop = true
  end
  local itemUI = self.SpEnergyUIs[spEnergyElement.dam_type]
  local curStack = self.battleManager.battleRuntimeData:GetSpEnergyStackByType(spEnergyElement.dam_type)
  if not itemUI then
    if curStack <= 0 then
      return
    end
    if not res then
      Log.Error("UMG_Battle_SpEnergy_List_C load res is nil")
      return
    end
    local pos = self.battleManager.battleRuntimeData:GetSpEnergyPosByType(spEnergyElement.dam_type)
    itemUI = UE4.UWidgetBlueprintLibrary.Create(self.BattleMainWindow, res)
    itemUI:InitByData(self, spEnergyElement)
    itemUI:SetServerPos(pos)
    self.SpEnergyList:InsertChildToHorizontalBox(self:GetPosInList(pos), itemUI)
    self.SpEnergyNumber = self.SpEnergyNumber + 1
    self.SpEnergyUIs[spEnergyElement.dam_type] = itemUI
  end
  if itemUI.dam_type ~= spEnergyElement.dam_type then
    itemUI:InitByData(self, spEnergyElement)
  end
  itemUI:AddEnergy(math.min(curStack, itemUI.StackNum + flyNumber))
end

function UMG_Battle_SpEnergy_List_C:OnTick()
  if self.spEnergyQueue:Size() > 0 and self.isValidToPop then
    self:DoPopup(self.spEnergyQueue:Dequeue())
  end
end

function UMG_Battle_SpEnergy_List_C:Push(changeData)
  if not changeData then
    return
  end
  self.spEnergyQueue:Enqueue(changeData)
end

function UMG_Battle_SpEnergy_List_C:DoPopup(changeData)
  if changeData.type == ProtoEnum.BattleSpEnergyChange.SP_ENERGY_CHANGE_TYPE.SP_ENERGY_ADD then
    self:AddSpEnergy(changeData.ele, changeData.src, changeData.change_value, changeData.caster_id)
  elseif changeData.type == ProtoEnum.BattleSpEnergyChange.SP_ENERGY_CHANGE_TYPE.SP_ENERGY_REMOVE then
    self:RemoveSpEnergy(changeData.ele)
  elseif changeData.type == ProtoEnum.BattleSpEnergyChange.SP_ENERGY_CHANGE_TYPE.SP_ENERGY_REPLACE then
    self:ReplaceSpEnergy(changeData)
    self:AddSpEnergy(changeData.ele, changeData.src, changeData.change_value, changeData.caster_id)
  elseif changeData.change_value >= 0 then
    self:AddSpEnergy(changeData.ele, changeData.src, changeData.change_value, changeData.caster_id)
  else
    self:DelSpEnergy(changeData.ele)
  end
end

function UMG_Battle_SpEnergy_List_C:AddSpEnergy(spEnergyElement, source, changeNumber, petId)
  if source == ProtoEnum.BattleSpEnergyChange.SP_ENERGY_SRC.SRC_WEATHER or source == ProtoEnum.BattleSpEnergyChange.SP_ENERGY_SRC.SRC_MAP then
    local curTime = UE4Helper.GetTime()
    local waitDelay = 0
    if curTime >= self.energyFlyStartTime then
      self.energyFlyStartTime = curTime + self.energyFlyDetal * changeNumber
    else
      waitDelay = self.energyFlyStartTime - curTime
      self.energyFlyStartTime = self.energyFlyStartTime + self.energyFlyDetal * changeNumber
    end
    for i = 1, changeNumber do
      local delay = waitDelay + self.energyFlyDetal * (i - 1)
      if delay < 0.05 then
        self:PlayParticleEffect(spEnergyElement, source, 1, petId)
      else
        self:DelaySeconds(delay, self.PlayParticleEffect, self, spEnergyElement, source, 1, petId)
      end
    end
  else
    self:CheckAndLoadUI(changeNumber, spEnergyElement)
  end
end

function UMG_Battle_SpEnergy_List_C:InitEffectPos()
  self.battleCenter = self.battleManager.battlePawnManager.VBattleField.battleFieldConf:Abs_GetTransform()
  local rightCamera = self.battleManager.battlePawnManager.VBattleField.battleCameraManager.CurrentCamera:GetActorRightVector()
  local forwardCamera = self.battleManager.battlePawnManager.VBattleField.battleCameraManager.CurrentCamera:GetActorForwardVector()
  local upCamera = self.battleManager.battlePawnManager.VBattleField.battleCameraManager.CurrentCamera:GetActorUpVector()
  local cameraPos = self.battleManager.battlePawnManager.VBattleField.battleCameraManager.CurrentCamera:Abs_K2_GetActorLocation()
  local cameraRate = self.battleManager.battlePawnManager.VBattleField.battleCameraManager.CurrentCamera.CameraComponent.AspectRatio
  local posOffset = upCamera * 60
  self.groudPos = {}
  self.groudPosNumber = {}
  table.insert(self.groudPos, self.battleCenter.Translation + posOffset)
  local xoffset = 0
  local zoffset = 0
  for i = 1, 3 do
    table.insert(self.groudPos, self.battleCenter.Translation + rightCamera * i * 100 + posOffset)
    table.insert(self.groudPos, self.battleCenter.Translation + rightCamera * i * -100 + posOffset)
  end
  posOffset = upCamera * 60
  self.skyPos = {}
  self.skyPosNumber = {}
  for i = 1, #self.groudPos do
    table.insert(self.skyPos, self.groudPos[i] + posOffset)
  end
  self.myPetPos = {}
  self.myPetPosNumber = {}
  self.enemyPetPos = {}
  self.enemyPetPosNumber = {}
  local basePos = forwardCamera * -20
  table.insert(self.myPetPos, basePos + upCamera * 50)
  table.insert(self.myPetPos, basePos + rightCamera * -50)
  table.insert(self.myPetPos, basePos + rightCamera * 50)
  table.insert(self.myPetPos, basePos + upCamera * -50)
  table.insert(self.myPetPos, basePos)
  basePos = forwardCamera * -100
  table.insert(self.enemyPetPos, basePos + upCamera * 50)
  table.insert(self.enemyPetPos, basePos + rightCamera * -50)
  table.insert(self.enemyPetPos, basePos + rightCamera * 50)
  table.insert(self.enemyPetPos, basePos + upCamera * -50)
  table.insert(self.enemyPetPos, basePos)
end

function UMG_Battle_SpEnergy_List_C:ChoosePos(posArray, posNumberArray)
  local effectPos
  local chooseIndex = 1
  local samePosNumber = math.huge
  for i = 1, #posArray do
    if not posNumberArray[i] then
      posNumberArray[i] = 0
      effectPos = posArray[i]
      chooseIndex = i
      break
    elseif samePosNumber > posNumberArray[i] then
      samePosNumber = posNumberArray[i]
      effectPos = posArray[i]
      chooseIndex = i
      if samePosNumber <= 0 then
        break
      end
    end
  end
  effectPos = effectPos or posArray[1]
  if not posNumberArray[chooseIndex] then
    posNumberArray[chooseIndex] = 0
  end
  posNumberArray[chooseIndex] = posNumberArray[chooseIndex] + 1
  return effectPos, chooseIndex
end

function UMG_Battle_SpEnergy_List_C:PlayParticleEffect(spEnergyElement, source, changeNumber, petId)
  local playerActor
  for i = 1, #self.EffectPlayer do
    if self.EffectPlayer[i].IsOver then
      playerActor = self.EffectPlayer[i]
      break
    end
  end
  if not playerActor then
    local transform = UE4.FTransform(UE4.FQuat(), _G.FVectorZero)
    _G.BattleResourceManager:LoadActorAsyncWithParam(self, _G.UEPath.ShinengPlayer, transform, PriorityEnum.Passive_Battle_Panel, DummyTable, self.LoadPlayerOver, nil, spEnergyElement, source, changeNumber, petId)
  else
    self:ComputeEffectData(playerActor, spEnergyElement, source, changeNumber, petId)
  end
end

function UMG_Battle_SpEnergy_List_C:LoadPlayerOver(player, spEnergyElement, source, changeNumber, petId)
  self.EffectPlayer[#self.EffectPlayer + 1] = player
  player.ParticleSystem.OnSystemFinished:Add(player, player.OverPlay)
  self:ComputeEffectData(player, spEnergyElement, source, changeNumber, petId)
end

function UMG_Battle_SpEnergy_List_C:ComputeEffectData(playerActor, spEnergyElement, source, changeNumber, petId)
  if not self.isInitPos then
    self.isInitPos = true
    self:InitEffectPos()
  end
  local posArray, posNumberArray
  local chooseIndex = 1
  local effectPos
  local soundId = 1109
  local petInitPos = FVectorZero
  local effectAsset
  if source == ProtoEnum.BattleSpEnergyChange.SP_ENERGY_SRC.SRC_WEATHER then
    effectAsset = BattleConst.SpEnergy.WeatherSrcPath
    posArray = self.skyPos
    posNumberArray = self.skyPosNumber
  elseif source == ProtoEnum.BattleSpEnergyChange.SP_ENERGY_SRC.SRC_MAP then
    effectAsset = BattleConst.SpEnergy.GroundSrcPath
    posArray = self.groudPos
    posNumberArray = self.groudPosNumber
    soundId = 1110
  else
    effectAsset = BattleConst.SpEnergy.AttackSrcPath
    local pet = self.battleManager.battlePawnManager:GetPetByGuid(petId)
    if pet then
      petInitPos = pet.model:Abs_K2_GetActorLocation()
      if pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
        posArray = self.enemyPetPos
        posNumberArray = self.enemyPetPosNumber
      else
        posArray = self.myPetPos
        posNumberArray = self.myPetPosNumber
      end
    else
      Log.Error("\229\138\191\232\131\189\230\137\190\228\184\141\229\136\176\232\167\166\229\143\145\229\138\191\232\131\189\231\154\132\229\174\160\231\137\169  \229\174\160\231\137\169Id ", petId, source)
      posArray = self.myPetPos
      posNumberArray = self.myPetPosNumber
    end
  end
  effectPos, chooseIndex = self:ChoosePos(posArray, posNumberArray)
  if source ~= ProtoEnum.BattleSpEnergyChange.SP_ENERGY_SRC.SRC_WEATHER and source ~= ProtoEnum.BattleSpEnergyChange.SP_ENERGY_SRC.SRC_MAP then
    effectPos = effectPos + petInitPos
  end
  playerActor:Abs_K2_SetActorLocation_WithoutHit(effectPos)
  playerActor:ChangeByType(spEnergyElement.dam_type)
  playerActor:SetData(posNumberArray, chooseIndex, self, spEnergyElement, changeNumber, soundId)
  _G.BattleResourceManager:LoadResAsync(playerActor, effectAsset, playerActor.StartPlay)
end

return UMG_Battle_SpEnergy_List_C
