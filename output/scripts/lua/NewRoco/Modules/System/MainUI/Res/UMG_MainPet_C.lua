local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local TipsModuleEvent = reload("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local PetUtils = require("NewRoco.Utils.PetUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local BattleBossChallengeUtils = require("NewRoco.Modules.Core.Battle.Common.BattleBossChallengeUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local UMG_MainPet_C = _G.NRCPanelBase:Extend("UMG_MainPet_C")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")

function UMG_MainPet_C:OnConstruct()
  self.uiData = {}
  self.selectedPetGid = 0
  self.selectedIndex = 0
  self.firstAlivePetIndex = 0
  self.playAimNum = 0
  self.petOldInfo = {}
  self.OldPetInfo = {}
  self.OldUpdateInfos = {}
  self.curPetSessionList = {}
  self:SetMainPetInfo()
  self.MainPetList:SetItemCanClickChecker(self.CheckItemCanClick, self)
  self.MainPetList:SetItemCanSelectChecker(self.CheckItemCanClick, self)
  self.refresh = true
  self.petUIOpen = false
  self.isManuiOpen = true
  self.isHaveOnePet = false
  self.CanPress = true
  self.PetGidItemMap = nil
  self:OnAddEventListener()
  self.Item = self.MainPetList:GetItemByIndex(0)
  self.isOpenPetPanel = false
  self.tipsDisplayController = _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.GetDisplayController, TipEnum.TipObjectType.MainPetTips)
  if self.tipsDisplayController then
    self.tipsDisplayController:BindView(self)
    self.tipsDisplayController:GetExecutor():StartTipDispatchStateListener()
  end
end

function UMG_MainPet_C:CheckItemCanClick(Item, tabIndex)
  local isAmining = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAimState)
  if isAmining and Item.uiData.RecycleState == true then
    local tipText = _G.DataConfigManager:GetLocalizationConf("Cannot_Switch").msg
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipText)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainPetRecycleSelect)
    return false
  end
  return true
end

function UMG_MainPet_C:OnAddEventListener()
  _G.NRCModuleManager:GetModule("PetUIModule"):RegisterEvent(self, PetUIModuleEvent.OpenedOrCloseMain, self.OpenedOrClosePetMain)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.MAINUIOPEN, self.ManuiOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.MAINUICLOSE, self.ManuiClose)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.OnFinshBattleUpdatePetData, self.OnUpdatePetEnergyInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.OnMainPetListAimNumberChange, self.OnMainPetListAimNumberChange)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.OnMainPetRecycleSelect, self.OnPetRecycleSelect)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, BagModuleEvent.GoodChangeTypeEnum.GT_PET_EN, self.ChangeEnergyPet)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.OnForceUpdateFriendRideState, self.OnForceUpdateFriendRideState)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.OnUpdateMainPetTipsShowState, self.OnUpdateMainPetTipsShowState)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.OnUIFuncVisibilityChange)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.PET_EXP_CHANGED, self.OnPetExpChanged)
end

function UMG_MainPet_C:OnDestruct()
  local petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  if petUIModule then
    _G.NRCModuleManager:GetModule("PetUIModule"):UnRegisterEvent(self, PetUIModuleEvent.OpenedOrCloseMain, self.OpenedOrClosePetMain)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.ManuiClose)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUIOPEN, self.ManuiOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnFinshBattleUpdatePetData, self.OnUpdatePetEnergyInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnMainPetListAimNumberChange, self.OnMainPetListAimNumberChange)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnMainPetRecycleSelect, self.OnPetRecycleSelect)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_PET_EN, self.ChangeEnergyPet)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnUpdateMainPetTipsShowState, self.OnUpdateMainPetTipsShowState)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.PET_EXP_CHANGED, self.OnPetExpChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.OnUIFuncVisibilityChange)
  if self.delayRemoveBlockTip then
    _G.DelayManager:CancelDelayById(self.delayRemoveBlockTip)
  end
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
    self.tipsDisplayController = nil
  end
end

function UMG_MainPet_C:OnActive()
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  if teamInfo then
    local curMainTeam = teamInfo.teams[teamInfo.main_team_idx + 1]
    if curMainTeam and curMainTeam.pet_infos and #curMainTeam.pet_infos > 0 then
      return
    end
    local ValidIndex = 0
    local Num = teamInfo.teams and #teamInfo.teams > 0 and #teamInfo.teams
    if Num then
      for i = 1, Num do
        local curTeam = teamInfo.teams[i]
        if curTeam and curTeam.pet_infos and #curTeam.pet_infos > 0 then
          ValidIndex = i
          break
        end
      end
    end
    if ValidIndex > 0 then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, ValidIndex - 1, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
    end
  end
end

function UMG_MainPet_C:OnDeactive()
end

function UMG_MainPet_C:OnPlayTips(tip)
  local successPlay = false
  local petTipsData = tip.customData
  if petTipsData then
    if not self.PetGidItemMap then
      self.PetGidItemMap = {}
      for i, data in pairs(self.uiData or {}) do
        if data and data.PetData and data.PetData.gid then
          local item = self.MainPetList:GetItemByIndex(i - 1)
          if item then
            self.PetGidItemMap[data.PetData.gid] = {index = i, item = item}
          end
        end
      end
    end
    local invalidPetGid = {}
    for petGid, petTipsItem in pairs(petTipsData or {}) do
      local isFound = false
      if petGid then
        local MainPetTemplateItem = self.PetGidItemMap[petGid].item
        if MainPetTemplateItem then
          if self.CachePetListPlayTipsMap == nil then
            self.CachePetListPlayTipsMap = {}
          end
          self.CachePetListPlayTipsMap[self.PetGidItemMap[petGid].index] = {petGid = petGid, petTipsItem = petTipsItem}
          successPlay = true
          isFound = true
          MainPetTemplateItem:PlayTips(petGid, petTipsItem)
        end
      end
      if not isFound then
        table.insert(invalidPetGid, petGid)
      end
    end
    for _, petGid in ipairs(invalidPetGid) do
      petTipsData.petTips[petGid] = nil
    end
  end
  if not successPlay and self.tipsDisplayController then
    self.tipsDisplayController:GetExecutor():ConsumeNextTip()
  end
end

function UMG_MainPet_C:OnMainPetTemplateTipsPlayEnd(index, petGid, petTipsItem)
  Log.Debug("UMG_MainPet_C:OnMainPetTemplateTipsPlayEnd, index=[", index, "], petGid=[", petGid, "]")
  for i, cacheItem in pairs(self.CachePetListPlayTipsMap or {}) do
    if cacheItem and cacheItem.petGid and petGid and cacheItem.petGid == petGid then
      self.CachePetListPlayTipsMap[i] = nil
      break
    end
  end
  self:SetMainPetTipsFinished(petGid, petTipsItem)
end

function UMG_MainPet_C:OnAllTipsFinished()
end

function UMG_MainPet_C:OnPlayTipStatusChange(pause)
  local count = self.MainPetList:GetItemCount()
  for i = 1, count do
    local item = self.MainPetList:GetItemByIndex(i - 1)
    if item then
      item:OnPlayTipStatusChange(pause)
    end
  end
end

function UMG_MainPet_C:SetMainPetTipsFinished(petGid, petTipsItem)
  if not petGid or not petTipsItem then
    return
  end
  local tip = self.tipsDisplayController and self.tipsDisplayController:GetExecutor():GetDisplayingTip()
  if tip then
    local petTipsData = tip.customData
    if petTipsData and petTipsData[petGid] == petTipsItem then
      petTipsData[petGid] = nil
    end
    if table.isEmpty(petTipsData) and self.tipsDisplayController then
      self.tipsDisplayController:GetExecutor():ConsumeNextTip()
    end
  end
end

function UMG_MainPet_C:TipShowOrHide(on)
  if on then
    if self.isManuiOpen == true then
      self.refresh = true
      self:RefreshSelectedState(true)
    end
  else
    self.refresh = false
  end
end

function UMG_MainPet_C:OnSceneLeave(Same, bReconnecting, id)
end

function UMG_MainPet_C:ManuiOpen()
  Log.Debug("UMG_MainPet_C:ManuiOpen")
  local bHasPVPRankedMatch = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CheckHasPVPRankedMatch)
  if bHasPVPRankedMatch then
    return
  end
  self.refresh = true
  self.isManuiOpen = true
  for i = 1, #self.uiData do
    self.uiData[i].isMainUIOpen = true
  end
  if true == self.petUIOpen then
    self.petUIOpen = false
    for i = 1, #self.uiData do
      local petdata = self.uiData[i]
      local oldData = self:GetOldPetData(petdata.PetData.gid)
      if nil ~= oldData and oldData.lv then
        self.uiData[i].oldlv = oldData.lv
        self.uiData[i].oldExp = oldData.exp
        self.uiData[i].PetUIOpen = false
      end
    end
    table.clear(self.petOldInfo)
    self:RefreshSelectedState()
  else
    self:IsOpenPetUI(false)
    self:ChangePetInfo()
    self:RefreshSelectedState()
  end
end

function UMG_MainPet_C:ManuiClose()
  self.OldPetInfo = self.uiData
  self.refresh = false
  self.isManuiOpen = false
  self.PetGidItemMap = nil
end

function UMG_MainPet_C:MainOpenOrClose(_IsOpenMain)
  if _IsOpenMain then
    self.refresh = true
    self.isManuiOpen = true
    if true == self.petUIOpen then
      self.petUIOpen = false
      for i = 1, #self.uiData do
        local petdata = self.uiData[i]
        local oldData = self:GetOldPetData(petdata.PetData.gid)
        if nil ~= oldData and oldData.lv then
          self.uiData[i].oldlv = oldData.lv
          self.uiData[i].oldExp = oldData.exp
          self.uiData[i].PetUIOpen = true
        end
      end
      table.clear(self.petOldInfo)
      self:RefreshSelectedState()
    else
      self:IsOpenPetUI(false)
      self:RefreshSelectedState()
    end
  else
    self.refresh = false
    self.isManuiOpen = false
  end
end

function UMG_MainPet_C:IsOpenPetUI(_ISOpen)
  for i = 1, #self.uiData do
    self.uiData[i].PetUIOpen = _ISOpen
  end
end

function UMG_MainPet_C:ChangePetInfo()
  local uiData = self.uiData
  local olduiData = self.OldPetInfo
  if uiData and olduiData then
    if #uiData > #olduiData then
      self:GetUpdatePetGid(uiData, olduiData)
    else
      self:GetUpdatePetGid(olduiData, uiData)
    end
  end
end

function UMG_MainPet_C:GetUpdatePetGid(_olduiData, _uiData)
  local olduiData = _olduiData
  local uiData = _uiData
  local GidList = {}
  for i, v in ipairs(olduiData) do
    local IsHas = false
    for j, k in ipairs(uiData) do
      if v.PetData.gid == k.PetData.gid then
        IsHas = true
        break
      end
    end
    if false == IsHas then
      table.insert(GidList, v.PetData.gid)
    end
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.PetHeadInfoChange, GidList)
end

function UMG_MainPet_C:OpenedOrClosePetMain(open)
  if open then
    self.refresh = false
    self.petUIOpen = true
    self.OldPetInfo = self.uiData
    self:RecordPetOldLV()
  else
    self:ChangePetInfo()
  end
end

function UMG_MainPet_C:RecordPetOldLV()
  for i = 1, #self.uiData do
    local petdata = self.uiData[i]
    if petdata and self:GetOldPetData(petdata.PetData.gid) == nil then
      local data = {}
      data.gid = petdata.PetData.gid
      data.lv = petdata.PetData.level
      data.exp = petdata.PetData.exp
      table.insert(self.petOldInfo, data)
    end
  end
end

function UMG_MainPet_C:GetOldPetData(gid)
  for i = 1, #self.petOldInfo do
    if self.petOldInfo[i].gid == gid then
      return self.petOldInfo[i]
    end
  end
  return nil
end

function UMG_MainPet_C:SetMainPetInfo()
  local CatchPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  local MainPetInfo = {}
  for i = 1, #CatchPetInfo do
    table.insert(MainPetInfo, {
      PetData = CatchPetInfo[i],
      RecycleState = false,
      SelectedState = false,
      IsNewPet = false,
      Session = {},
      bTipsAlreadyShow = true
    })
  end
  self.uiData = MainPetInfo
  self.MainPetList:Clear()
  self:RefreshSelectedState()
end

function UMG_MainPet_C:UpdateUIData(curUIData, srcUIData)
  if nil == curUIData or nil == srcUIData then
    return true
  end
  if self:IsSameArray(curUIData, srcUIData) then
    return false
  end
  for i = 1, #srcUIData do
    curUIData[i] = srcUIData[i]
  end
  for i = #srcUIData + 1, #curUIData do
    curUIData[i] = nil
  end
  return true
end

function UMG_MainPet_C:RefreshMainPetInfo(type, petInfo)
  Log.Debug(type, "UMG_MainPet_C:RefreshMainPetInfo")
  Log.Dump(petInfo, 6, "UMG_MainPet_C:RefreshMainPetInfo_Dump_petInfo")
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if 0 == type then
    if petInfo.num > 0 then
      do
        local isremove = true
        for i = 1, #self.uiData do
          for j = 1, #battlePetList do
            if battlePetList[j].gid == self.uiData[i].PetData.gid then
              isremove = false
              break
            end
          end
          if isremove then
            table.remove(self.uiData, i)
            break
          else
            isremove = true
          end
        end
        for i = 1, #self.uiData do
          if petInfo.pet_data and petInfo.pet_data.gid == self.uiData[i].PetData.gid then
            self:RecordOldPetData(i)
            self.uiData[i].PetData = petInfo.pet_data
            if petInfo.first_get == true then
              self.uiData[i].IsNewPet = true
            end
            if petInfo.src_type and petInfo.src_type == ProtoEnum.GoodsType.GT_VITEM then
              self.uiData[i].IsPlayAnim = true
            end
            self:RefreshSelectedState()
            return
          end
        end
        if #self.uiData < 6 then
          local isMainTeamIndex, teamIndex = _G.DataModelMgr.PlayerDataModel:GetIsBigWorldMainTeamIndexByGid(petInfo and petInfo.pet_data and petInfo.pet_data.gid)
          if isMainTeamIndex then
            table.insert(self.uiData, {
              PetData = petInfo.pet_data,
              RecycleState = false,
              SelectedState = false,
              IsNewPet = true,
              Session = {}
            })
          else
            Log.Error(petInfo and petInfo.pet_data and petInfo.pet_data.gid, "GID\228\184\141\229\164\132\228\186\142\228\184\187\231\188\150\233\152\159\231\154\132\231\178\190\231\129\181")
          end
        else
        end
      end
    end
  elseif 1 == type then
    local SessionList = self.curPetSessionList
    local petGidSort = {}
    local curPetList = {}
    local num = math.min(#petInfo, 6)
    local BagPet = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
    local BagPetInfo = BagPet.pet_data
    for i = 1, num do
      local hasSame = false
      for j = 1, #self.uiData do
        if petInfo[i].gid == self.uiData[j].PetData.gid then
          self.uiData[j].PetData = petInfo[i]
          table.insert(curPetList, self.uiData[j])
          hasSame = true
        end
      end
      if false == hasSame then
        for k = 1, #BagPetInfo do
          if petInfo[i].gid == BagPetInfo[k].gid then
            table.insert(curPetList, {
              PetData = BagPetInfo[k],
              RecycleState = false,
              SelectedState = false,
              IsNewPet = false,
              Session = {}
            })
            break
          end
        end
      end
      table.insert(petGidSort, petInfo[i].gid)
    end
    if SessionList then
      for i = 1, #SessionList do
        local isValid = false
        for j = 1, #petGidSort do
          if petGidSort[j] == SessionList[i].petData.gid then
            isValid = true
          end
        end
        if false == isValid and _G.NRCModuleManager:IsModuleActive("TaskPetFollowModule") and not _G.NRCModuleManager:DoCmd(_G.TaskPetFollowModuleCmd.CheckPetInTaskFollow, SessionList[i].petData.gid, 4) then
          self:RecyclePet(SessionList[i])
        end
      end
    end
    local bChanged = self:UpdateUIData(self.uiData, curPetList)
    if not bChanged then
      return
    end
  elseif 2 == type then
    local curHp = PetUtils.GetPetAdditionalByType(petInfo, _G.ProtoEnum.AttributeType.AT_HPCUR)
    for i = 1, #self.uiData do
      if petInfo.gid == self.uiData[i].PetData.gid then
        if curHp > 0 then
          self.uiData[i].DiedState = false
        else
          self.uiData[i].DiedState = true
        end
        self:RefreshSinglePetView(i, PetUIModuleEnum.MainPetTemplateOpType.DiedState)
      end
    end
    return
  elseif 3 == type then
    local CatchPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    local itemIndex = -1
    for i = 1, #self.uiData do
      if petInfo.gid == self.uiData[i].PetData.gid then
        itemIndex = i
      end
    end
    if itemIndex > 0 then
      for i = 1, #CatchPetInfo do
        if CatchPetInfo[i].gid == petInfo.gid then
          self.uiData[itemIndex].PetData = CatchPetInfo[i]
          self:RefreshSinglePetView(i, PetUIModuleEnum.MainPetTemplateOpType.All)
          return
        end
      end
    end
  elseif 4 == type then
    for i = 1, #self.uiData do
      if petInfo.pet_data.gid == self.uiData[i].PetData.gid then
        self:RecordOldPetData(i)
        self.uiData[i].PetData = petInfo
        self:RefreshSinglePetView(i, PetUIModuleEnum.MainPetTemplateOpType.All)
        return
      end
    end
  elseif 5 == type then
  end
  self:RefreshSelectedState()
end

function UMG_MainPet_C:RecyclePetNotInTeam(petInfo)
  local SessionList = self.curPetSessionList
  local petGidSort = {}
  local curPetList = {}
  local num = math.min(#petInfo, 6)
  local BagPet = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local BagPetInfo = BagPet.pet_data
  for i = 1, num do
    local hasSame = false
    for j = 1, #self.uiData do
      if petInfo[i].gid == self.uiData[j].PetData.gid then
        self.uiData[j].PetData = petInfo[i]
        table.insert(curPetList, self.uiData[j])
        hasSame = true
      end
    end
    if false == hasSame then
      for k = 1, #BagPetInfo do
        if petInfo[i].gid == BagPetInfo[k].gid then
          table.insert(curPetList, {
            PetData = BagPetInfo[k],
            RecycleState = false,
            SelectedState = false,
            IsNewPet = false,
            Session = {}
          })
          break
        end
      end
    end
    table.insert(petGidSort, petInfo[i].gid)
  end
  if SessionList then
    for i = 1, #SessionList do
      local isValid = false
      for j = 1, #petGidSort do
        if petGidSort[j] == SessionList[i].petData.gid then
          isValid = true
        end
      end
      if false == isValid then
        self:RecyclePet(SessionList[i])
      end
    end
  end
end

function UMG_MainPet_C:IsSameArray(arr1, arr2)
  if #arr1 ~= #arr2 then
    return false
  end
  for i = 1, #arr1 do
    if arr1[i] ~= arr2[i] then
      return false
    end
  end
  return true
end

function UMG_MainPet_C:GetSelectPetIndex()
  local selectPetIndex, petData = _G.NRCModeManager:DoCmd(MainUIModuleCmd.GetSelectPetIndex)
  if selectPetIndex and petData then
    local index
    index = selectPetIndex % 6 - 1
    local item = self.MainPetList:GetItemByIndex(index)
    if petData and item and item.uiData and item.uiData.PetData and item.uiData.PetData.gid ~= petData.gid then
      return nil, nil
    end
  end
  if nil ~= selectPetIndex and nil ~= self.selectedPetGid and selectPetIndex > 0 and self.selectedPetGid > 0 then
    self.selectedIndex = _G.NRCModeManager:DoCmd(MainUIModuleCmd.GetSelectPetIndex)
  end
  if self.selectedIndex > 0 then
    if self.selectedIndex <= #self.uiData then
      if self.uiData[self.selectedIndex].DiedState == false then
        return self.selectedIndex - 1
      else
        return self:GetFirstAlivePetIndex()
      end
    else
      return self:GetFirstAlivePetIndex()
    end
  elseif false == self.isHaveOnePet and self.uiData and 1 == #self.uiData then
    return 0, true
  end
end

function UMG_MainPet_C:DoSelectPet(SelectIndex, bDelaySelect)
  if nil == SelectIndex then
    return
  end
  if SelectIndex >= #self.uiData then
    Log.Error("UMG_MainPet_C:DoSelectPet: SelectIndex is out of range")
    return
  end
  if bDelaySelect then
    if self.isHaveOnePet == false and self.uiData and 1 == #self.uiData then
      self:DelaySeconds(0.1, function()
        local CurSelectItemId = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetSelectedItemId)
        if 0 ~= (CurSelectItemId or 0) then
          return
        end
        self.MainPetList:SelectItemByIndex(0)
      end)
    end
  else
    self.MainPetList:SelectItemByIndex(SelectIndex)
  end
end

function UMG_MainPet_C:UpdateSelectPetIndex()
  local SelectIndex, bDelaySelect = self:GetSelectPetIndex()
  self:DoSelectPet(SelectIndex, bDelaySelect)
  self.isHaveOnePet = self.uiData and 1 == #self.uiData
end

function UMG_MainPet_C:RefreshSinglePetView(Index, OpType)
  self.MainPetList:OpItemByIndex(Index, OpType)
  self:PetMedalUpdate()
  self:UpdateNewPetByIndex(Index, false)
  local SelectIndex, bDelaySelect = self:GetSelectPetIndex()
  if SelectIndex and SelectIndex + 1 == Index and OpType ~= PetUIModuleEnum.MainPetTemplateOpType.FriendRideState then
    self:DoSelectPet(SelectIndex, bDelaySelect)
    self.isHaveOnePet = self.uiData and 1 == #self.uiData
  end
  self:UpdateOldUpdateInfos(Index)
  self:UpdateEnergyPet(Index)
end

function UMG_MainPet_C:RefreshMainPetView()
  if self.MainPetList == nil then
    return
  end
  self:UpdateEnergyPet()
  for i = 1, #self.uiData do
    if self.CachePetListPlayTipsMap and self.CachePetListPlayTipsMap[i] and self.uiData[i].PetData.gid and self.CachePetListPlayTipsMap[i].petGid ~= self.uiData[i].PetData.gid then
      self:OnMainPetTemplateTipsPlayEnd(i, self.CachePetListPlayTipsMap[i].petGid, self.CachePetListPlayTipsMap[i].petTipsItem)
      self.MainPetList:OpItemByIndex(i, PetUIModuleEnum.MainPetTemplateOpType.ForceClearTips, self.uiData[i], PetUIModuleEnum.MainPetTemplateOpReasonType.LobbyMainUIShow)
    end
  end
  if self.MainPetList:GetItemCount() ~= #self.uiData then
    self.MainPetList:Clear()
    self.MainPetList:InitGridView(self.uiData)
  else
    for i = 1, #self.uiData do
      if self.uiData[i] and self.uiData[i].PetData and self.uiData[i].PetData.gid then
        local throwSession = ThrowSession.GetWithGID(self.uiData[i].PetData.gid)
        local _Session = throwSession or {}
        local _RecycleState = false
        if throwSession and not throwSession:IsDestroyed() and not throwSession:IsInHand() then
          _RecycleState = true
        end
        self.uiData[i].Session = _Session
        self.uiData[i].RecycleState = _RecycleState
      end
      self.MainPetList:OpItemByIndex(i, PetUIModuleEnum.MainPetTemplateOpType.All, self.uiData[i], PetUIModuleEnum.MainPetTemplateOpReasonType.LobbyMainUIShow)
    end
  end
  self:PetMedalUpdate()
  self:UpdateNewPet(false)
  self:IsOpenPetUI(false)
  self:UpdateSelectPetIndex()
  self:UpdateOldUpdateInfos()
end

function UMG_MainPet_C:UpdatePetData()
  if BattleBossChallengeUtils.IsInLeaderChallengeDungeon() then
    local CatchPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfoByTeamType(Enum.PlayerTeamType.PTT_PVE_BOSS_CHALLENGE_FIGHT)
    for i = 1, #CatchPetInfo do
      if self.uiData[i] and self.uiData[i].PetData then
        self:RecordOldPetData(i)
        self.uiData[i].PetData = CatchPetInfo[i]
      end
    end
  else
    local CatchPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    for i = 1, #CatchPetInfo do
      if self.uiData[i] and self.uiData[i].PetData then
        self:RecordOldPetData(i)
        self.uiData[i].PetData = CatchPetInfo[i]
      end
    end
  end
end

function UMG_MainPet_C:UpdateNewPetByIndex(_Index, _IsUpdate)
  local data = self.uiData[_Index]
  if nil == data then
    return
  end
  data.IsNewPet = _IsUpdate
  data.IsPlayAnim = _IsUpdate
end

function UMG_MainPet_C:UpdateNewPet(_IsUpdate)
  local uiData = self.uiData
  for i, v in ipairs(uiData) do
    v.IsNewPet = _IsUpdate
    v.IsPlayAnim = _IsUpdate
  end
end

function UMG_MainPet_C:UpdateEnergyPet(Index)
  local uiData = self.uiData
  local isWaitEnergy = self:GetIsWaitEnergy()
  self.playAimNum, self.isOnePlay, self.itemIndex = self:GetPlayAimNum()
  if Index then
    local Data = uiData[Index]
    if Data then
      Data.IsWaitEnergy = isWaitEnergy
      Data.EneryDiff = self:GetDifferenceEnergy(Data.PetData.gid)
    end
  else
    for i, v in ipairs(uiData) do
      v.IsWaitEnergy = isWaitEnergy
      v.EneryDiff = self:GetDifferenceEnergy(v.PetData.gid)
    end
  end
end

function UMG_MainPet_C:CopyOldUpdateInfos(OldUpdateInfo, petDataSrc)
  if nil == petDataSrc or nil == OldUpdateInfo then
    return
  end
  OldUpdateInfo.gid = petDataSrc.gid
  OldUpdateInfo.energy = petDataSrc.energy
  OldUpdateInfo.level = petDataSrc.level
  OldUpdateInfo.exp = petDataSrc.exp
end

function UMG_MainPet_C:ResizeOldUpdateInfos()
  if self.uiData == nil or #self.uiData <= 0 or nil == self.OldUpdateInfos or #self.uiData == #self.OldUpdateInfos then
    return
  end
  local uiDataCount = #self.uiData
  local oldCount = #self.OldUpdateInfos
  for i = 1, uiDataCount do
    if i > oldCount then
      local OldUpdateInfo = {}
      self.OldUpdateInfos[i] = OldUpdateInfo
      local petDataSrc = self.uiData[i].PetData
      self:CopyOldUpdateInfos(OldUpdateInfo, petDataSrc)
    end
  end
  if uiDataCount < oldCount then
    for i = uiDataCount + 1, oldCount do
      self.OldUpdateInfos[i] = nil
    end
  end
end

function UMG_MainPet_C:UpdateOldUpdateInfos(Index)
  self:ResizeOldUpdateInfos()
  if nil == Index then
    for i, v in ipairs(self.uiData) do
      local OldUpdateInfo = self.OldUpdateInfos[i]
      local petDataSrc = self.uiData[i].PetData
      self:CopyOldUpdateInfos(OldUpdateInfo, petDataSrc)
    end
  else
    local OldUpdateInfo = self.OldUpdateInfos[Index]
    local petDataSrc = self.uiData[Index].PetData
    self:CopyOldUpdateInfos(OldUpdateInfo, petDataSrc)
  end
end

function UMG_MainPet_C:ChangeEnergyPetByGid(gid, energy)
  for i, v in ipairs(self.uiData) do
    if v.PetData.gid == gid then
      v.PetData.energy = energy
    end
  end
end

function UMG_MainPet_C:ChangeEnergyPet(item, cmdID)
  self:ChangeEnergyPetByGid(item.gid, item.num)
end

function UMG_MainPet_C:OnForceUpdateFriendRideState(CurMainTeamIndex)
  for i = 1, #self.uiData do
    if self.uiData[i] and self.uiData[i].PetData and self.uiData[i].PetData.gid then
      local PetGID = self.uiData[i].PetData.gid
      if PetGID then
        self.uiData[i].FriendRideState = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.CheckPetIsFriendRiding, PetGID) or false
        self:RefreshSinglePetView(i, PetUIModuleEnum.MainPetTemplateOpType.FriendRideState)
      end
    end
  end
end

function UMG_MainPet_C:GetOldPetInfo(gid)
  if self.OldUpdateInfos == nil then
    return nil
  end
  for i = 1, #self.OldUpdateInfos do
    if self.OldUpdateInfos[i].gid == gid then
      return self.OldUpdateInfos[i]
    end
  end
  return nil
end

function UMG_MainPet_C:GetIsWaitEnergy()
  local uiData = self.uiData
  local isWaitEnergy = false
  for i, v in ipairs(uiData) do
    local curData = v.PetData
    local oldData = self:GetOldPetInfo(curData.gid)
    if nil == oldData or nil == oldData.energy then
      break
    end
    if curData.energy > oldData.energy then
      isWaitEnergy = true
      break
    end
  end
  return isWaitEnergy
end

function UMG_MainPet_C:GetDifferenceEnergy(gid)
  local uiData = self.uiData
  for i, v in ipairs(uiData) do
    local curData = v.PetData
    if curData.gid == gid then
      local oldData = self:GetOldPetInfo(curData.gid)
      if nil == oldData then
        return 0
      end
      if nil == oldData.energy then
        return 0
      end
      if curData.energy > oldData.energy then
        return curData.energy - oldData.energy
      end
    end
  end
  return 0
end

function UMG_MainPet_C:GetPlayAimNum()
  local uiData = self.uiData
  local num = 0
  local itemIndex
  for i, v in ipairs(uiData) do
    local curData = v.PetData
    local oldData = self:GetOldPetInfo(curData.gid)
    if nil == oldData then
      return 0
    end
    if oldData.exp ~= curData.exp or oldData.level ~= curData.level then
      num = num + 1
      itemIndex = i
    end
  end
  return num, 1 == num, itemIndex
end

function UMG_MainPet_C:OnMainPetListAimNumberChange()
  Log.Debug("UMG_MainPet_C:OnMainPetListAimNumberChange")
  self.playAimNum = self.playAimNum - 1
  if self.playAimNum <= 0 then
    self.playAimNum = 0
    local count = self.MainPetList:GetItemCount()
    for i = 1, count do
      local item = self.MainPetList:GetItemByIndex(i - 1)
      item:OnAllWaitFinsh(self.isOnePlay, self.itemIndex)
    end
  end
end

function UMG_MainPet_C:OnUpdatePetEnergyInfo(notify)
  if self.OldUpdateInfos and notify.pet_info then
    for i = 1, #self.OldUpdateInfos do
      for j = 1, #notify.pet_info do
        local finish_info = notify.pet_info[j]
        if finish_info.pet_gid == self.OldUpdateInfos[i].gid then
          self.OldUpdateInfos[i].energy = finish_info.remain_energy
        end
      end
    end
  end
end

function UMG_MainPet_C:RefreshSelectedState(bRefreshAll)
  if self.uiData == nil then
    return
  end
  if self.petUIOpen == true then
    self:IsOpenPetUI(true)
    self:RecordPetOldLV()
    return
  end
  if self.refresh == false then
    return
  end
  self:UpdatePetData()
  if not self.selectedPetGid or self.selectedPetGid <= 0 then
    self.selectedIndex = 0
    for _, uiData in ipairs(self.uiData) do
      uiData.SelectedState = false
    end
  else
    for i = 1, #self.uiData do
      if self.uiData[i].PetData and self.selectedPetGid == self.uiData[i].PetData.gid then
        self.uiData[i].SelectedState = true
        self.selectedIndex = i
      else
        self.uiData[i].SelectedState = false
      end
    end
  end
  if false == bRefreshAll then
    self:UpdateSelectPetIndex()
  else
    self:RefreshMainPetView()
  end
end

function UMG_MainPet_C:SetMedalGid(MedalItem, AcquireType)
  local Gid
  if MedalItem.owner_id and MedalItem.owner_id > 0 and MedalItem.obtain_pet_gid and MedalItem.obtain_pet_gid > 0 then
    Gid = MedalItem.obtain_pet_gid
  else
    Gid = MedalItem.owner_id
  end
  self.Gid = Gid
  self.AcquireType = AcquireType
  self.MedalItem = MedalItem
end

function UMG_MainPet_C:PetMedalUpdate()
  if self.Gid then
    for i, Pet in ipairs(self.uiData) do
      if Pet.PetData.gid == self.Gid then
        local Item = self.MainPetList:GetItemByIndex(i - 1)
        if Item then
          Item:SetMedalInfo(self.AcquireType, self.isManuiOpen, self.MedalItem)
        end
        self.Gid = nil
        self.AcquireType = nil
        self.MedalItem = nil
        break
      end
    end
  end
end

function UMG_MainPet_C:SetSelectedGid(gid)
  local bChanged = gid ~= self.selectedPetGid
  self.selectedPetGid = gid
  if bChanged then
    self:RefreshSelectedState(true)
  end
end

function UMG_MainPet_C:GetCurSelectedGid()
  return self.selectedPetGid
end

function UMG_MainPet_C:UpdateThrowPetCanClick(bThrow)
  for i = 1, #self.uiData do
    self.MainPetList:OpItemByIndex(i, PetUIModuleEnum.MainPetTemplateOpType.updateThrowPetSelect, {bThrow = bThrow})
  end
end

function UMG_MainPet_C:UpdataRecycleState(Session, Status)
  if self.uiData == nil then
    return
  end
  for i = 1, #self.uiData do
    if Session.petData.gid == self.uiData[i].PetData.gid then
      if Status == ThrowSessionStatusEnum.InHand or Status == ThrowSessionStatusEnum.Destroyed then
        self.uiData[i].RecycleState = false
        if Status == ThrowSessionStatusEnum.Destroyed then
          self.uiData[i].Session = nil
        end
      else
        self.uiData[i].Session = Session
        self.uiData[i].RecycleState = true
      end
      self:RefreshSinglePetView(i, PetUIModuleEnum.MainPetTemplateOpType.RecycleState)
    end
  end
end

function UMG_MainPet_C:UpdateFriendRideState(ridingPetGid, IsFriendRiding)
  if nil == ridingPetGid then
    return
  end
  if nil == self.uiData then
    return
  end
  for i = 1, #self.uiData do
    if ridingPetGid == self.uiData[i].PetData.gid then
      self.uiData[i].FriendRideState = IsFriendRiding
      self:RefreshSinglePetView(i, PetUIModuleEnum.MainPetTemplateOpType.FriendRideState)
    end
  end
end

function UMG_MainPet_C:OnUIFuncVisibilityChange(FuncId, bHide)
  if FuncId == Enum.FunctionEntrance.FE_PET_LIST then
  end
end

function UMG_MainPet_C:GetFirstAlivePetIndex()
  for i = 1, #self.uiData do
    if PetUtils.GetPetAdditionalByType(self.uiData[i].PetData, _G.ProtoEnum.AttributeType.AT_HPCUR) > 0 then
      self.firstAlivePetIndex = i - 1
      return i - 1
    end
  end
  return 0
end

function UMG_MainPet_C:RecyclePet(session)
  session:Recycle()
end

function UMG_MainPet_C:SetSessionList(sessionList)
  self.curPetSessionList = sessionList
end

function UMG_MainPet_C:SelectLongPressPet(_index)
  local Count = self.MainPetList:GetItemCount()
  if _index <= Count then
    self.MainPetList:SelectItemByIndex(_index - 1)
  end
end

function UMG_MainPet_C:OnPlayerDataUpdate()
  local count = self.MainPetList:GetItemCount()
  for i = 1, count do
    local item = self.MainPetList:GetItemByIndex(i - 1)
    item:ShowHanBookSkill()
  end
end

function UMG_MainPet_C:RecordOldPetData(index)
  if self.uiData and self.uiData[index] and self.uiData[index].PetData and (self.uiData[index].bTipsAlreadyShow == nil or self.uiData[index].bTipsAlreadyShow) then
    self.uiData[index].oldlv = self.uiData[index].PetData.level
    self.uiData[index].oldExp = self.uiData[index].PetData.exp
    self.uiData[index].bTipsAlreadyShow = false
    Log.Debug("UMG_MainPet_C:RecordOldPetData PetName=[", self.uiData[index].PetData.name, "], oldExp=[", self.uiData[index].PetData.exp, "]")
  end
end

function UMG_MainPet_C:OnPetExpChanged(OldPetData)
  Log.Debug("UMG_MainPet_C:OnPetExpChanged OldPetData.name=[", OldPetData.name or 0, "], OldPetData.exp=[", OldPetData.exp or 0, "], OldPetData.level=[", OldPetData.level or 0, "]")
  if OldPetData then
    for i = 1, #self.uiData do
      if self.uiData[i] and self.uiData[i].PetData and OldPetData.gid and self.uiData[i].PetData.gid == OldPetData.gid then
        self:RecordOldPetData(i)
        break
      end
    end
  end
end

function UMG_MainPet_C:OnUpdateMainPetTipsShowState(gid)
  Log.Debug("UMG_MainPet_C:OnUpdateMainPetTipsShowState gid=[", gid, "]")
  for i = 1, #self.uiData do
    if self.uiData[i] and self.uiData[i].PetData and gid and self.uiData[i].PetData.gid == gid then
      self.uiData[i].bTipsAlreadyShow = true
      break
    end
  end
end

function UMG_MainPet_C:OnPetRecycleSelect()
  local selectIndex = _G.NRCModeManager:DoCmd(MainUIModuleCmd.GetSelectPetIndex)
  if not selectIndex then
    return
  end
  if selectIndex <= 0 then
    return
  end
  local item = self.MainPetList:GetItemByIndex(selectIndex - 1)
  if UE4.UObject.IsValid(item) then
    item:StopAllAnimations()
    item:ShowSelected(true)
  end
end

function UMG_MainPet_C:OnPCSelectPet0(action_type, index)
  if _G.BattleManager:IsInBattle() then
    return
  end
  if 0 == action_type then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
    if self.CanPress then
      self.CanPress = false
      for i = 1, 6 do
        if index == i then
          local curHp = self.uiData[i] and self.uiData[i].PetData and self.uiData[i].PetData.attribute_new_info and self.uiData[i].PetData.attribute_new_info.addi_attr_data and PetUtils.GetPetAdditionalByType(self.uiData[i].PetData, _G.ProtoEnum.AttributeType.AT_HPCUR)
          if curHp and curHp > 0 then
            local x = tonumber(index)
            local count = self.MainPetList:GetItemCount()
            if x > count then
              return
            end
            self.MainPetList:SelectItemByIndex(i - 1)
            self.Item = self.MainPetList:GetItemByIndex(i - 1)
            self.Item:OpenPetInfoPanel(self, index)
          end
        end
      end
    end
  else
    self.CanPress = true
    self.Item:UnPetInfoPanel(self)
  end
end

function UMG_MainPet_C:SelectPetByGid(gid)
  local PetData = self.uiData
  for i, Pet in ipairs(PetData) do
    if Pet.PetData.gid == gid then
      self.MainPetList:SelectItemByIndex(i - 1)
      break
    end
  end
end

function UMG_MainPet_C:RecyclePetByGid(gid)
  local SessionList = self.curPetSessionList
  if SessionList then
    for i = 1, #SessionList do
      if gid == SessionList[i].petData.gid then
        self:RecyclePet(SessionList[i])
        return
      end
    end
  end
end

function UMG_MainPet_C:UpdatePetLock(bIsLock, Gid)
  if self.uiData then
    for i = 1, #self.uiData do
      if self.uiData[i].PetData.gid == Gid then
        self.uiData[i].IsLock = bIsLock
        self:RefreshSinglePetView(i, PetUIModuleEnum.MainPetTemplateOpType.Lock)
        break
      end
    end
  end
end

function UMG_MainPet_C:OnDisable()
  if self.uiData then
    for i = 1, #self.uiData do
      if self.uiData[i] and self.uiData[i].PetData and self.uiData[i].PetData.gid then
        local MainPetTemplateItem = self.MainPetList:GetItemByIndex(i - 1)
        if MainPetTemplateItem then
          MainPetTemplateItem:OnDisable()
        end
      end
    end
  end
end

return UMG_MainPet_C
