local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local GetFrameCount = _ENV.GetFrameCount
local FPointerEvent_GetCursorDelta = _ENV.FPointerEvent_GetCursorDelta
local BasePos = UE4.FVector2D(0.0, -50.0)
local BasePosFly = UE4.FVector2D(0.0, -300.0)
local UMG_Activity_ElfAdventure_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfAdventure_C")

function UMG_Activity_ElfAdventure_C:OnActive()
  if self.module:HasPanel("ElfAdventureBg") or self.module:IsPanelInOpening("ElfAdventureBg") then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.ChangeShowPetTimer = 5
  self.ChangeShowPetDeltaTime = 0
  self.UpdateStateDeltaTime = 0
  self.UpdateStateDeltaTimer = 1
  self.consumedTouchMoveFrameCount = 0
  self.deltaXSinceLastFrame = 0
  self.deltaYSinceLastFrame = 0
  local PetTripActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PET_TRIP)
  if PetTripActivityInst and #PetTripActivityInst > 0 then
    self.activityInst = PetTripActivityInst[1]
  end
  self.DetailTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.activityInst then
    local conf = self.activityInst:GetActivityPetTripConf()
    self.ChangeShowPetTimer = conf and conf.change_time or 5
    self:UpdateUI(true)
  else
    self:DoClose()
    return
  end
  self:AddBGM()
  self:OnAddEventListener()
  self:RegisterEvent(self, ActivityModuleEvent.RefreshActivityPetTripData, self.RefreshData)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_Activity_ElfAdventure_C:OnPlayerDataUpdate(Type)
  if Type and Type == _G.Enum.GoodsType.GT_PET then
    self:CreatePetItem()
  end
end

function UMG_Activity_ElfAdventure_C:RefreshData()
  if self.activityInst then
    local ShowType, activityShowTime = self.activityInst:GetShowActivityTime()
    if ShowType ~= self.activityInst.ActivityShowStatus.TripIng then
      self:ClearPetItemWidget()
    end
  end
  self:UpdateUI()
  self:CheckNeedRemovePetItem()
end

function UMG_Activity_ElfAdventure_C:OnPcClose()
  if self.RightPanel.IsShow then
    self.RightPanel:OnBtnClose()
  else
    self:OnBtnClose()
  end
end

function UMG_Activity_ElfAdventure_C:PlayInAnimation()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.BG_1:PlayAnimation(self.BG_1.In_0)
  self.BG:PlayInAnimation()
end

function UMG_Activity_ElfAdventure_C:CheckAutoAddPet(init, init_auto_trip)
  if init_auto_trip ~= self.auto_trip and true == init_auto_trip and not init and self.activityData and self.activityData.cur_pet_trip_info and #self.activityData.cur_pet_trip_info > 0 then
    local curTripNum = self.activityData.cur_pet_trip_info and #self.activityData.cur_pet_trip_info or 0
    local LastTripNum = self.LastTripPet and #self.LastTripPet or 0
    if curTripNum - LastTripNum > 1 then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.pet_trip_45, curTripNum - LastTripNum))
    else
      for i, tripInfo in ipairs(self.activityData.cur_pet_trip_info) do
        local _isFind = false
        if self.LastTripPet and #self.LastTripPet > 0 then
          for j, LastTripInfo in ipairs(self.LastTripPet) do
            if LastTripInfo.pet_gid == tripInfo.pet_gid then
              _isFind = true
              break
            end
          end
        end
        if not _isFind then
          local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(tripInfo.pet_gid)
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.pet_trip_44, petData and petData.name or ""))
          break
        end
      end
    end
  end
  self.LastTripPet = self.activityData.cur_pet_trip_info
  self.auto_trip = init_auto_trip
end

function UMG_Activity_ElfAdventure_C:UpdateUI(init)
  self.activityData = self.activityInst:GetActivityData()
  self:CheckAutoAddPet(init, self.activityData.auto_trip)
  local happy_value = self.activityData.happy_value or 0
  self.RightPanel:UpdateUI(self.activityInst, self.activityData, true)
  self.Text1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Text2:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Text1:SetText(happy_value)
  local curTripNum = self.activityData.cur_pet_trip_info and #self.activityData.cur_pet_trip_info or 0
  local NumText = string.format("%s/%s", curTripNum, self.activityData.max_pet_num)
  local PetTripConf = self.activityInst:GetActivityPetTripConf()
  local happiness_num_list = PetTripConf.condition_group1
  for i, v in ipairs(happiness_num_list) do
    if happy_value < v.happiness_num then
      self.Title_Details:SetText(string.format(LuaText.pet_trip_25, v.happiness_num, v.add_quota))
      break
    end
  end
  local maxNum = PetTripConf.initial_quota
  for i, v in ipairs(happiness_num_list) do
    maxNum = maxNum + v.add_quota
  end
  if self.activityData.pet_trip_record_info and #self.activityData.pet_trip_record_info > 0 then
    self.BtnTravelLog:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.BtnTravelLog:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.BtnDetails:SetVisibility(self.activityData.max_pet_num == maxNum and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  self.Text2:SetText(NumText)
  self.NRCText_Schedule:SetText(NumText)
  self:CreatePetItem()
  local hasReward = self:CheckPetHappyReward()
  if hasReward then
    self.BtnRewards:SetVisibility(UE4.ESlateVisibility.Visible)
    self.redPointNew:SetupKey(483)
  else
    self.redPointNew:SetupKey(0)
    self.BtnRewards:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_ElfAdventure_C:AddBGM()
  local petTripConf = self.activityInst:GetActivityPetTripConf()
  local bgm_state = petTripConf and petTripConf.bgm or ""
  if "" ~= bgm_state then
    _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PET_TRIP)
    local isPauseBgm = _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.IsPauseUiBgm)
    if not isPauseBgm then
      _G.NRCAudioManager:SetStateByName("UI_Music", "UI_Music")
      _G.NRCAudioManager:SetStateByName("UI_Type", bgm_state)
    end
  end
end

function UMG_Activity_ElfAdventure_C:CheckPetHappyReward()
  self.Reward_List = {}
  local received_reward_stage = self.activityData.received_reward_stage or 0
  local petTripConf = self.activityInst:GetActivityPetTripConf()
  if petTripConf and petTripConf.condition_group2 then
    for i, v in ipairs(petTripConf.condition_group2) do
      if v.happiness_stage <= (self.activityData.happy_value or 0) and i > received_reward_stage then
        table.insert(self.Reward_List, i - 1)
      end
    end
  end
  if self.Reward_List and #self.Reward_List > 0 then
    return true
  end
  return false
end

function UMG_Activity_ElfAdventure_C:ClearPetItemWidget()
  self.IsDestroyWidget = true
  if self.petItemWidgets and #self.petItemWidgets > 0 then
    for _, widget in ipairs(self.petItemWidgets) do
      if widget then
        widget:RemoveFromParent()
      end
    end
    self.petItemWidgets = {}
    self.PetItemBasePosList = {}
    self.PetItemIndexBasePosList = {}
    self.PetItemTargetPosList = {}
    self.PetItemCurrentPosList = {}
  end
end

function UMG_Activity_ElfAdventure_C:OnDeactive()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:ClearPetItemWidget()
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_PET_TRIP)
end

function UMG_Activity_ElfAdventure_C:SetRandomIndexList(petItemNum)
  self.randomIndexList = {}
  for j = 0, petItemNum - 1 do
    table.insert(self.randomIndexList, j)
  end
  for j = #self.randomIndexList, 2, -1 do
    local k = math.random(j)
    self.randomIndexList[j], self.randomIndexList[k] = self.randomIndexList[k], self.randomIndexList[j]
  end
end

function UMG_Activity_ElfAdventure_C:GetPreferredIndexForScreen(petItemNum, intervalWidth, usedIndices)
  local CurSceneCenterList = {}
  local RightPanelSize = 862
  if self.BG and self.BG.zhongjing and self.BG.zhongjing.Slot then
    local bgPos = self.BG.zhongjing.Slot:GetPosition()
    local screenCenterX = -bgPos.X
    for i, v in ipairs(self.randomIndexList) do
      if table.contains(usedIndices, v) then
      else
        local curPos = self.indexToScreenX[v]
        if curPos <= screenCenterX + (1170.0 - RightPanelSize) and curPos >= screenCenterX - 1170.0 then
          table.insert(CurSceneCenterList, v)
        end
      end
    end
    if #CurSceneCenterList > 0 then
      return CurSceneCenterList
    else
      for i, v in ipairs(self.randomIndexList) do
        if table.contains(usedIndices, v) then
        else
          local curPos = self.indexToScreenX[v]
          if curPos <= screenCenterX + 1170.0 and curPos >= screenCenterX - 1170.0 then
            table.insert(CurSceneCenterList, v)
          end
        end
      end
      return CurSceneCenterList
    end
  end
end

function UMG_Activity_ElfAdventure_C:RemovePetItemByGid(Gid)
  if self.petItemWidgets and #self.petItemWidgets > 0 then
    local _index
    if self.curShowPetList and #self.curShowPetList > 0 then
      for i, v in ipairs(self.curShowPetList) do
        if v.pet_gid == Gid then
          _index = i
          break
        end
      end
    end
    if not _index then
      if self.waitForShowPetList and #self.waitForShowPetList > 0 then
        for i, v in ipairs(self.waitForShowPetList) do
          if v.pet_gid == Gid then
            _index = i
            break
          end
        end
        table.remove(self.waitForShowPetList, _index)
      end
      return
    end
    if self.waitForShowPetList and #self.waitForShowPetList > 0 then
      local waitChangePet = table.remove(self.waitForShowPetList, 1)
      local changePetJlDataIndex
      for i, PetJlData in ipairs(self.PetJlData_List) do
        if PetJlData.tripInfo and PetJlData.tripInfo.pet_gid == Gid then
          changePetJlDataIndex = i
          break
        end
      end
      if not changePetJlDataIndex then
        return
      end
      table.remove(self.PetJlData_List, changePetJlDataIndex)
      local waitChangePetJlData = {}
      local _isFly = self:GetPetJlIsFly(waitChangePet.pet_base_id)
      waitChangePetJlData.tripInfo = waitChangePet
      waitChangePetJlData.isFly = _isFly
      local petItemWidget = self.petItemWidgets[_index]
      local _BasePos = _isFly and BasePosFly or BasePos
      local slot = petItemWidget.Slot
      local pos = slot:GetPosition()
      pos.Y = _BasePos.Y
      slot:SetPosition(pos)
      self.PetItemBasePosList[_index] = pos
      self.curShowPetList[_index] = waitChangePet
      petItemWidget:ChangePetBegin(waitChangePetJlData, _index)
    else
      for i, widget in ipairs(self.petItemWidgets) do
        if i == _index and widget then
          widget:RemoveFromParent()
          break
        end
      end
      table.remove(self.curShowPetList, _index)
      table.remove(self.petItemWidgets, _index)
      table.remove(self.PetItemBasePosList, _index)
      table.remove(self.PetItemIndexBasePosList, _index)
      table.remove(self.PetItemTargetPosList, _index)
      table.remove(self.PetItemCurrentPosList, _index)
    end
  end
end

function UMG_Activity_ElfAdventure_C:CheckNeedRemovePetItem()
  if not self.PetJlData_List or 0 == #self.PetJlData_List then
    return
  end
  for i, PetJlData in ipairs(self.PetJlData_List) do
    local _isFind = false
    if self.activityData.cur_pet_trip_info then
      for j, curPetTripInfo in ipairs(self.activityData.cur_pet_trip_info) do
        if PetJlData.tripInfo and PetJlData.tripInfo.pet_gid == curPetTripInfo.pet_gid then
          _isFind = true
          break
        end
      end
    end
    if not _isFind then
      self:RemovePetItemByGid(PetJlData.tripInfo.pet_gid)
    end
  end
end

function UMG_Activity_ElfAdventure_C:CreatePetItem()
  local PetTripConf = self.activityInst:GetActivityPetTripConf()
  local petItemNum = PetTripConf.pet_max
  local intervalWidth = 4340 / petItemNum
  if not (self.activityData and self.activityData.cur_pet_trip_info) or 0 == #self.activityData.cur_pet_trip_info then
    return
  end
  self.ChangeShowPetDeltaTime = 0
  self.waitForShowPetList = {}
  if self.petItemWidgets and #self.petItemWidgets > 0 then
    if petItemNum <= #self.petItemWidgets then
      self:GetWaitForShowPetList()
      return
    end
    for i, tripInfo in ipairs(self.activityData.cur_pet_trip_info) do
      local _isFind = false
      local hasPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(tripInfo.pet_gid)
      for j, PetJlData in ipairs(self.PetJlData_List) do
        if PetJlData.tripInfo and PetJlData.tripInfo.pet_gid == tripInfo.pet_gid then
          _isFind = true
          break
        end
      end
      local PetJlData = {}
      if not _isFind and hasPetData then
        local _isFly = self:GetPetJlIsFly(tripInfo.pet_base_id)
        PetJlData.tripInfo = tripInfo
        PetJlData.isFly = _isFly
        table.insert(self.PetJlData_List, PetJlData)
      end
      if not _isFind and hasPetData and petItemNum > #self.petItemWidgets then
        local petItemWidget = UE4.UWidgetBlueprintLibrary.Create(self, self.PetItemClass)
        if petItemWidget then
          local _BasePos = PetJlData.isFly and BasePosFly or BasePos
          local suby = 0
          local preferredIndices = self:GetPreferredIndexForScreen(petItemNum, intervalWidth, self.usedIndexList)
          local randomIndex
          if preferredIndices and #preferredIndices > 0 then
            randomIndex = preferredIndices[math.random(1, #preferredIndices)]
            for j = #self.randomIndexList, 1, -1 do
              if self.randomIndexList[j] == randomIndex then
                table.remove(self.randomIndexList, j)
                break
              end
            end
          else
            randomIndex = table.remove(self.randomIndexList, 1)
          end
          table.insert(self.usedIndexList, randomIndex)
          local bgPos = self.BG.zhongjing.Slot:GetPosition()
          local screenCenterX = bgPos.X
          local randomPosX = self.indexToScreenX[randomIndex] + screenCenterX
          local randomX = math.random(-130, 130)
          local indexBasePos = UE4.FVector2D(randomPosX + _BasePos.X, _BasePos.Y + suby)
          local itemBasePos = UE4.FVector2D(randomPosX + _BasePos.X + randomX, _BasePos.Y + suby)
          local slot = self.CanvasPanel_0:AddChild(petItemWidget)
          slot:SetPosition(itemBasePos)
          slot:SetAutoSize(true)
          slot:SetZOrder(0)
          local Achors = UE4.FAnchors()
          Achors.Minimum = UE4.FVector2D(0.5, 0.5)
          Achors.Maximum = UE4.FVector2D(0.5, 0.5)
          slot:SetAnchors(Achors)
          petItemWidget:UpDateUI(PetJlData, self)
          petItemWidget:PlayAnimation(petItemWidget.In)
          table.insert(self.petItemWidgets, petItemWidget)
          table.insert(self.PetItemBasePosList, itemBasePos)
          table.insert(self.PetItemIndexBasePosList, indexBasePos)
          table.insert(self.PetItemTargetPosList, UE4.FVector2D(0, 0))
          table.insert(self.PetItemCurrentPosList, UE4.FVector2D(0, 0))
        end
        table.insert(self.curShowPetList, self.PetJlData_List[i].tripInfo)
      end
    end
    self:GetWaitForShowPetList()
  else
    self.usedIndexList = {}
    self.indexToScreenX = {}
    self.petItemWidgets = {}
    self.PetJlData_List = {}
    self.curShowPetList = {}
    self.PetItemBasePosList = {}
    self.PetItemIndexBasePosList = {}
    self.PetItemTargetPosList = {}
    self.PetItemCurrentPosList = {}
    self:SetRandomIndexList(petItemNum)
    for i = 0, petItemNum - 1 do
      local posX = i * intervalWidth + intervalWidth / 2 - 2170.0
      self.indexToScreenX[i] = posX
    end
    for i, tripInfo in ipairs(self.activityData.cur_pet_trip_info) do
      local hasPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(tripInfo.pet_gid)
      if hasPetData then
        local PetJlData = {}
        local _isFly = self:GetPetJlIsFly(tripInfo.pet_base_id)
        PetJlData.tripInfo = tripInfo
        PetJlData.isFly = _isFly
        table.insert(self.PetJlData_List, PetJlData)
      end
    end
    for i = 1, petItemNum do
      if self.PetJlData_List[i] then
        local preferredIndices = self:GetPreferredIndexForScreen(petItemNum, intervalWidth, self.usedIndexList)
        local randomIndex
        if preferredIndices and #preferredIndices > 0 then
          randomIndex = preferredIndices[math.random(1, #preferredIndices)]
          for j = #self.randomIndexList, 1, -1 do
            if self.randomIndexList[j] == randomIndex then
              table.remove(self.randomIndexList, j)
              break
            end
          end
        else
          randomIndex = table.remove(self.randomIndexList, 1)
        end
        table.insert(self.usedIndexList, randomIndex)
        local petItemWidget = UE4.UWidgetBlueprintLibrary.Create(self, self.PetItemClass)
        if petItemWidget then
          local _BasePos = self.PetJlData_List[i].isFly and BasePosFly or BasePos
          local suby = 0
          local bgPos = self.BG.zhongjing.Slot:GetPosition()
          local screenCenterX = bgPos.X
          local randomPosX = self.indexToScreenX[randomIndex] + screenCenterX
          local randomX = math.random(-130, 130)
          local itemBasePos = UE4.FVector2D(randomPosX + _BasePos.X + randomX, _BasePos.Y + suby)
          local indexBasePos = UE4.FVector2D(randomPosX + _BasePos.X, _BasePos.Y + suby)
          local slot = self.CanvasPanel_0:AddChild(petItemWidget)
          slot:SetPosition(itemBasePos)
          slot:SetAutoSize(true)
          slot:SetZOrder(0)
          local Achors = UE4.FAnchors()
          Achors.Minimum = UE4.FVector2D(0.5, 0.5)
          Achors.Maximum = UE4.FVector2D(0.5, 0.5)
          slot:SetAnchors(Achors)
          petItemWidget:UpDateUI(self.PetJlData_List[i], self)
          petItemWidget:PlayAnimation(petItemWidget.In)
          table.insert(self.petItemWidgets, petItemWidget)
          table.insert(self.PetItemBasePosList, itemBasePos)
          table.insert(self.PetItemIndexBasePosList, indexBasePos)
          table.insert(self.PetItemTargetPosList, UE4.FVector2D(0, 0))
          table.insert(self.PetItemCurrentPosList, UE4.FVector2D(0, 0))
        end
        table.insert(self.curShowPetList, self.PetJlData_List[i].tripInfo)
      end
    end
    self:GetWaitForShowPetList()
  end
end

function UMG_Activity_ElfAdventure_C:GetWaitForShowPetList()
  self.waitForShowPetList = {}
  if self.curShowPetList and #self.curShowPetList > 0 then
    for i, v in ipairs(self.activityData.cur_pet_trip_info) do
      local isFind = false
      local hasPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.pet_gid)
      for j, curShowPet in ipairs(self.curShowPetList) do
        if curShowPet.pet_gid == v.pet_gid then
          isFind = true
          break
        end
      end
      if not isFind and hasPetData then
        table.insert(self.waitForShowPetList, v)
      end
    end
  end
end

function UMG_Activity_ElfAdventure_C:OnTick(deltaTime)
  if self.TouchStartTime then
    self.TouchStartTime = self.TouchStartTime + deltaTime
  end
  if self.ChangeShowPetDeltaTime and self.ChangeShowPetTimer and self.curShowPetList and #self.curShowPetList > 0 and not self.IsDestroyWidget then
    self.ChangeShowPetDeltaTime = self.ChangeShowPetDeltaTime + deltaTime
    if self.ChangeShowPetDeltaTime >= self.ChangeShowPetTimer then
      self.ChangeShowPetDeltaTime = 0
      self:ChangeShowPet()
    end
  end
  if self.UpdateStateDeltaTime and self.UpdateStateDeltaTimer then
    self.UpdateStateDeltaTime = self.UpdateStateDeltaTime + deltaTime
    if self.UpdateStateDeltaTime >= self.UpdateStateDeltaTimer then
      self.UpdateStateDeltaTime = 0
      if self.activityInst then
        local ShowType, activityShowTime = self.activityInst:GetShowActivityTime()
        if ShowType ~= self.activityInst.ActivityShowStatus.TripIng then
          self.activityInst:SyncActivityDataOnAvailable()
          self:DoClose()
        end
      end
    end
  end
end

function UMG_Activity_ElfAdventure_C:ChangeShowPet()
  if not self.waitForShowPetList or 0 == #self.waitForShowPetList then
    return
  end
  local PetTripConf = self.activityInst:GetActivityPetTripConf()
  local petItemNum = PetTripConf.pet_max
  if petItemNum > #self.curShowPetList then
    return
  end
  local bgPos = self.BG.zhongjing.Slot:GetPosition()
  local screenCenterX = bgPos.X
  local CurSceneCenterList = {}
  for i, v in ipairs(self.PetItemBasePosList) do
    if v.x <= screenCenterX + 1170.0 and v.x >= screenCenterX - 1170.0 then
      table.insert(CurSceneCenterList, i)
    end
  end
  local RandIndex = math.random(1, #CurSceneCenterList)
  local changePetIndex = CurSceneCenterList[RandIndex]
  local waitChangePetIndex = math.random(1, #self.waitForShowPetList)
  local changePet = self.curShowPetList[changePetIndex]
  local waitChangePet = self.waitForShowPetList[waitChangePetIndex]
  local changePetJlDataIndex = changePetIndex
  local waitChangePetJlData = {}
  local _isFly = self:GetPetJlIsFly(waitChangePet.pet_base_id)
  waitChangePetJlData.tripInfo = waitChangePet
  waitChangePetJlData.isFly = _isFly
  local petItemWidget = self.petItemWidgets[changePetJlDataIndex]
  local _BasePos = _isFly and BasePosFly or BasePos
  local slot = petItemWidget.Slot
  local pos = slot:GetPosition()
  pos.Y = _BasePos.Y
  slot:SetPosition(pos)
  self.PetItemBasePosList[changePetJlDataIndex] = pos
  petItemWidget:ChangePetBegin(waitChangePetJlData, changePetJlDataIndex)
  table.remove(self.curShowPetList, changePetIndex)
  table.remove(self.waitForShowPetList, waitChangePetIndex)
  table.insert(self.curShowPetList, changePetIndex, waitChangePet)
  table.insert(self.waitForShowPetList, changePet)
end

function UMG_Activity_ElfAdventure_C:OnChangePetEnd(changePetJlDataIndex)
  local petItemWidget = self.petItemWidgets[changePetJlDataIndex]
  local indexBasePos = self.PetItemIndexBasePosList[changePetJlDataIndex]
  local slot = petItemWidget.Slot
  local pos = slot:GetPosition()
  local randomX = math.random(-130, 130)
  pos.x = indexBasePos.x + randomX
  slot:SetPosition(pos)
  self.PetItemBasePosList[changePetJlDataIndex] = pos
end

function UMG_Activity_ElfAdventure_C:UpdatePetItemMovement(_deltaTime)
  if not self.petItemWidgets or 0 == #self.petItemWidgets then
    return
  end
  local lerpSpeed = 3.0
  for i, widget in ipairs(self.petItemWidgets) do
    if widget and not widget.IsInChange and widget.Slot and self.PetItemTargetPosList[i] and self.PetItemCurrentPosList[i] then
      local currentPos = self.PetItemCurrentPosList[i]
      local targetPos = self.PetItemTargetPosList[i]
      local distance = UE4.UKismetMathLibrary.VSize2D(UE4.FVector2D(targetPos.X - currentPos.X, targetPos.Y - currentPos.Y))
      if distance < 1.0 then
        local offsetX = math.random(-30.0, 30.0)
        local offsetY = math.random(-30.0, 30.0)
        self.PetItemTargetPosList[i] = UE4.FVector2D(offsetX, offsetY)
      end
      local deltaTime = _deltaTime
      local alpha = lerpSpeed * deltaTime
      local newPos = UE4.FVector2D(UE4.UKismetMathLibrary.Lerp(currentPos.X, self.PetItemTargetPosList[i].X, alpha), UE4.UKismetMathLibrary.Lerp(currentPos.Y, self.PetItemTargetPosList[i].Y, alpha))
      self.PetItemCurrentPosList[i] = newPos
      widget:SetRenderTranslation(newPos)
    end
  end
end

function UMG_Activity_ElfAdventure_C:GetPetJlIsFly(pet_base_id)
  local ridePetConfig = _G.DataConfigManager:GetAllRidePet(pet_base_id)
  if not (ridePetConfig and ridePetConfig.basic_movement_list) or 0 == #ridePetConfig.basic_movement_list then
    return false
  end
  local basicMovementId = ridePetConfig.basic_movement_list[1]
  if not basicMovementId then
    return false
  end
  local globalConfig136 = _G.DataConfigManager:GetActivityGlobalConfig("PET_TRIP_FLY_PICTURE")
  if not (globalConfig136 and globalConfig136.numList) or 0 == #globalConfig136.numList then
    return false
  end
  for _, num in ipairs(globalConfig136.numList) do
    if num == basicMovementId then
      return true
    end
  end
  return false
end

function UMG_Activity_ElfAdventure_C:OnBtnRewards()
  if self.Reward_List and #self.Reward_List > 0 then
    self.activityInst:SendGetPetTripHappyRewardReq(self.Reward_List)
  end
end

function UMG_Activity_ElfAdventure_C:OnBtnDetails()
  if self:IsAnyAnimationPlaying() then
    return
  end
  if self.DetailTips:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_Activity_ElfAdventure_C:OnBtnDetails")
    self.DetailTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Press)
    self.DetailsCloseBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_Activity_ElfAdventure_C:OnBtnDetails")
    self:PlayAnimation(self.Out)
    self.DetailsCloseBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_ElfAdventure_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self.DetailTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_ElfAdventure_C:OnBtnChoose()
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_Activity_ElfAdventure_C:OnBtnChoose")
  self.RightPanel:PlayInAnimation()
end

function UMG_Activity_ElfAdventure_C:OnBtnTravelLog()
  if self.activityData.pet_trip_record_info and #self.activityData.pet_trip_record_info > 0 then
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenElfAdventureTravelLog)
  end
end

function UMG_Activity_ElfAdventure_C:OnBtnDetailsClose()
  if self:IsAnyAnimationPlaying() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_Activity_ElfAdventure_C:OnBtnDetailsClose")
  self:PlayAnimation(self.Out)
  self.DetailsCloseBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_ElfAdventure_C:OnBtnClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Activity_ElfAdventure_C:OnBtnClose")
  self:DoClose()
end

function UMG_Activity_ElfAdventure_C:OnAddEventListener()
  self:AddButtonListener(self.BtnClose.btnClose, self.OnBtnClose)
  self:AddButtonListener(self.BtnRewards, self.OnBtnRewards)
  self:AddButtonListener(self.BtnChoose, self.OnBtnChoose)
  self:AddButtonListener(self.BtnDetails.btnLevelUp, self.OnBtnDetails)
  self:AddButtonListener(self.BtnTravelLog.btnLevelUp, self.OnBtnTravelLog)
  self:AddButtonListener(self.DetailsCloseBtn, self.OnBtnDetailsClose)
end

function UMG_Activity_ElfAdventure_C:OnTouchStarted(_MyGeometry, _InTouchEvent)
  self.TouchStartTime = 0
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Activity_ElfAdventure_C:OnTouchMoved(_MyGeometry, _InTouchEvent)
  local deltaX, deltaY = FPointerEvent_GetCursorDelta(_InTouchEvent)
  local currentFrameCount = GetFrameCount()
  if self.consumedTouchMoveFrameCount ~= currentFrameCount then
    local bConsumed = self:TryConsumeTouchMoved(self.deltaXSinceLastFrame)
    if bConsumed then
      self.consumedTouchMoveFrameCount = currentFrameCount
      self.deltaXSinceLastFrame = 0
      self.deltaYSinceLastFrame = 0
    end
  end
  self.deltaXSinceLastFrame = self.deltaXSinceLastFrame + deltaX
  self.deltaYSinceLastFrame = self.deltaYSinceLastFrame + deltaY
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Activity_ElfAdventure_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  self.TouchStartTime = nil
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_Activity_ElfAdventure_C:TryConsumeTouchMoved(deltaX)
  if self.TouchStartTime and self.TouchStartTime < 0.075 then
    return false
  end
  local pos1 = self.BG.beijing.Slot:GetPosition()
  local pos2 = self.BG.yuanjing.Slot:GetPosition()
  local pos3 = self.BG.zhongjing.Slot:GetPosition()
  local pos4 = self.BG_1.Slot:GetPosition()
  pos1 = pos1 + UE4.FVector2D(deltaX * 0.8, 0)
  pos2 = pos2 + UE4.FVector2D(deltaX * 0.8, 0)
  pos3 = pos3 + UE4.FVector2D(deltaX, 0)
  pos4 = pos4 + UE4.FVector2D(deltaX * 2, 0)
  if math.abs(pos3.X) < 1260 then
    self.BG.beijing.Slot:SetPosition(pos1)
    self.BG.yuanjing.Slot:SetPosition(pos2)
    self.BG.zhongjing.Slot:SetPosition(pos3)
    self.BG_1.Slot:SetPosition(pos4)
    if self.PetItemBasePosList and #self.PetItemBasePosList > 0 then
      for i, v in ipairs(self.PetItemBasePosList) do
        self.PetItemBasePosList[i] = self.PetItemBasePosList[i] + UE4.FVector2D(deltaX, 0)
        self.PetItemIndexBasePosList[i] = self.PetItemIndexBasePosList[i] + UE4.FVector2D(deltaX, 0)
        self.petItemWidgets[i].Slot:SetPosition(self.PetItemBasePosList[i])
      end
    end
  end
  return true
end

return UMG_Activity_ElfAdventure_C
