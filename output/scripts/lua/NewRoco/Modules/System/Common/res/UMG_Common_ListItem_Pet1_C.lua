local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_Common_ListItem_Pet1_C = Base:Extend("UMG_Common_ListItem_Pet1_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ItemState = {
  Normal = 0,
  CanExchange = 1,
  CanAddIn = 2,
  LockNormal = 3,
  Lock = 4,
  RandomPet = 5
}
UMG_Common_ListItem_Pet1_C.ItemState = ItemState

function UMG_Common_ListItem_Pet1_C:OnConstruct()
  self.isSelect = false
  self.isSelectDisplay = false
  self.isAnimPlaying = false
  self.uiData = nil
  self.data = nil
end

function UMG_Common_ListItem_Pet1_C:OnDestruct()
  if self.Module then
    self.Module:UnRegisterEvent(self, PetUIModuleEvent.PetTeamWarehouseItemLocked, self.OnPetTeamWarehouseItemLocked)
    self.Module:UnRegisterEvent(self, PetUIModuleEvent.PetTeamFastFormationRefreshed, self.OnPetTeamFastFormationRefreshed)
  end
end

function UMG_Common_ListItem_Pet1_C:RefreshItem()
  self:OnItemUpdate(self.uiData, nil, nil, true)
end

function UMG_Common_ListItem_Pet1_C:OnItemUpdate(_data, datalist, index, IsRefreshItem)
  local prevData = self.data
  local prevKey = prevData and prevData.key
  local currKey = _data and _data.key
  self.curIndex = index or -1
  self.Module = _G.NRCModuleManager:GetModule("PetUIModule")
  self.Module:UnRegisterEvent(self, PetUIModuleEvent.PetTeamWarehouseItemLocked, self.OnPetTeamWarehouseItemLocked)
  self.uiData = _data
  self.data = _data
  local iconNum = _data.itemNum
  local NRCSwitcherTopLeftVisibility = UE4.ESlateVisibility.Collapsed
  local NRCSwitcherTopLeftActiveIndex = 0
  local NRCSwitcherPetVisibility = UE4.ESlateVisibility.Collapsed
  local NRCSwitcherPetActiveIndex = 0
  local imageIconPath = ""
  local textQuantityText = ""
  if _data.isHasPet then
    if iconNum then
      self.Text_Quantity:SetText(iconNum)
    end
    NRCSwitcherPetVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
    if self.Switcher then
      self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if _data.PetData.gid then
      local petInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(_data.PetData.gid, true)
      if petInfo and petInfo.base_conf_id then
        self.pet:SetIconPathAndMaterial(petInfo.base_conf_id, petInfo.mutation_type, petInfo.glass_info)
      end
      if petInfo and petInfo.partner_mark and petInfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
        self.Star:SetPath(PetUtils.GetPetCollectTagIcon(petInfo.partner_mark))
        self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      if _data.PetData.PetBaseInfo.partner_mark and _data.PetData.PetBaseInfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
        self.Star:SetPath(PetUtils.GetPetCollectTagIcon(_data.PetData.PetBaseInfo.partner_mark))
        self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.pet:SetIconPathAndMaterial(_data.PetData.base_conf_id)
    end
    local isRandomPet = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, _data.PetData.gid)
    textQuantityText = tostring(_data.PetData.level)
    if _data.PetData.is_trial_pet then
      NRCSwitcherTopLeftActiveIndex = 0
      NRCSwitcherTopLeftVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
    elseif isRandomPet then
      local randomPetData = _data.PetData
      local typeInfo = randomPetData and randomPetData.type
      local typeInfoParam = typeInfo and typeInfo.param
      local skillDamType = typeInfoParam
      NRCSwitcherPetActiveIndex = 1
      if 0 == skillDamType then
        NRCSwitcherTopLeftActiveIndex = 2
      else
        NRCSwitcherTopLeftActiveIndex = 1
        local damType = skillDamType
        local typeDictionaryConf = _G.DataConfigManager:GetTypeDictionary(damType)
        local icon = typeDictionaryConf and typeDictionaryConf.type_icon
        if icon then
          imageIconPath = icon
        end
      end
      textQuantityText = "??"
      NRCSwitcherTopLeftVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
    else
      NRCSwitcherTopLeftVisibility = UE4.ESlateVisibility.Collapsed
    end
  else
    if self.Switcher then
      if _data.isLockUp then
        self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Switcher:SetActiveWidgetIndex(2)
      else
        self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Text_Quantity:SetText("--")
    self.TryOut:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.Switcher_bg and _data.isPetListItem then
    self.Switcher_bg:SetActiveWidgetIndex(0)
  else
  end
  if self.NRCSwitcher_TopLeft then
    self.NRCSwitcher_TopLeft:SetVisibility(NRCSwitcherTopLeftVisibility)
    self.NRCSwitcher_TopLeft:SetActiveWidgetIndex(NRCSwitcherTopLeftActiveIndex)
  end
  if self.NRCSwitcher_Pet then
    self.NRCSwitcher_Pet:SetVisibility(NRCSwitcherPetVisibility)
    self.NRCSwitcher_Pet:SetActiveWidgetIndex(NRCSwitcherPetActiveIndex)
  end
  self.Text_Quantity:SetText(textQuantityText)
  self.Image_Icon:SetPath(imageIconPath)
  self.Module:RegisterEvent(self, PetUIModuleEvent.PetTeamWarehouseItemLocked, self.OnPetTeamWarehouseItemLocked)
  local curMode = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetTeamReplaceGetCurMode)
  self.rightShowNumber = _data and _data.rightShowNumber
  if self.rightShowNumber == nil then
    self.number:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.number:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text_number:SetText(tostring(self.rightShowNumber))
  end
  local prevIsSelect = prevData and prevData.isSelect or false
  local isSelect = _data and _data.isSelect or false
  local needInit = prevKey ~= currKey or nil == currKey
  if needInit then
    self:InitSelectState()
  end
  self:SetIsSelect(isSelect)
  local prevExchangePetData = prevData and prevData.exchangePetData
  local currExchangePetData = _data and _data.exchangePetData
  local prevExchangeIsInTeam = prevData and prevData.exchangeIsInTeam
  local currExchangeIsInTeam = _data and _data.exchangeIsInTeam
  if prevExchangePetData ~= currExchangePetData or prevExchangeIsInTeam ~= currExchangeIsInTeam or prevIsSelect ~= isSelect then
    self:OnPetTeamWarehouseItemExChanging(currExchangeIsInTeam, currExchangePetData)
  end
end

function UMG_Common_ListItem_Pet1_C:OnPetTeamWarehouseItemChanged(_PetData)
end

function UMG_Common_ListItem_Pet1_C:SetObturationPet()
  if self.data.isHasPet then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.data.PetData.base_conf_id, true)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      self.Obturation_Pet:SetPath(modelConf.icon)
      self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_ListItem_Pet1_C:ChangeItemState(Sate)
  local isObturationVisible = false
  if Sate == ItemState.Normal then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Sate == ItemState.CanExchange then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher:SetActiveWidgetIndex(0)
    isObturationVisible = true
    self:SetObturationPet()
  elseif Sate == ItemState.CanAddIn then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher:SetActiveWidgetIndex(1)
    isObturationVisible = true
    self:SetObturationPet()
  elseif Sate == ItemState.LockNormal then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher:SetActiveWidgetIndex(2)
    self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Sate == ItemState.Lock then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Switcher:SetActiveWidgetIndex(2)
    isObturationVisible = true
    self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetObturationVisible(isObturationVisible)
end

function UMG_Common_ListItem_Pet1_C:SetObturationVisible(isVisible)
  if not UE.UObject.IsValid(self.Obturation) then
    return
  end
  if isVisible then
    self.Obturation:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Obturation:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_ListItem_Pet1_C:OnPetTeamWarehouseItemExChanging(isInTeam, PetData)
  if self.Switcher then
    self:ChangeItemState(ItemState.Normal)
    if self.data and self.data.isPetListItem then
      local state = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetTeamReplaceGetCurExChangeState)
      if not state then
        if self.curIndex > self.data.canInTeamNum then
          self:ChangeItemState(ItemState.Lock)
          return
        end
        if self.data.isHasPet then
          if isInTeam then
            if PetData and self.data.PetData.gid ~= PetData.gid then
              self:ChangeItemState(ItemState.CanExchange)
            end
          elseif PetData then
            local hasCommon = _G.NRCModeManager:DoCmd(PetUIModuleCmd.PetTeamHasCommonEvolution, PetData.gid)
            if hasCommon then
              if PetUtils.IsCommonEvolution(PetData.gid, self.data.PetData.gid) then
                self:ChangeItemState(ItemState.CanExchange)
              else
                self:ChangeItemState(ItemState.Normal)
              end
            else
              self:ChangeItemState(ItemState.CanExchange)
            end
          end
        elseif PetData and not isInTeam then
          local hasCommon = _G.NRCModeManager:DoCmd(PetUIModuleCmd.PetTeamHasCommonEvolution, PetData.gid)
          if hasCommon then
            self:ChangeItemState(ItemState.Normal)
          else
            self:ChangeItemState(ItemState.CanAddIn)
          end
        end
      else
        if self.curIndex > self.data.canInTeamNum then
          self:ChangeItemState(ItemState.LockNormal)
          return
        end
        self:ChangeItemState(ItemState.Normal)
      end
    end
  end
end

function UMG_Common_ListItem_Pet1_C:OnPetTeamWarehouseItemLocked(_PetData, teamPetList)
  do return end
  if not self.data.isHasPet then
    return
  end
  self.IsLock = false
  if not self.data.isPetListItem then
    for _, petData in ipairs(teamPetList) do
      if (not _PetData or petData.gid ~= _PetData.gid) and PetUtils.IsCommonEvolution(self.data.PetData.gid, petData.gid) then
        self.IsLock = true
        break
      end
    end
  end
  local isObturationVisible = false
  if self.IsLock then
    isObturationVisible = true
    self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetObturationVisible(isObturationVisible)
end

function UMG_Common_ListItem_Pet1_C:OnSpawn()
  self:OnSpawn2()
end

function UMG_Common_ListItem_Pet1_C:OnSpawn1()
  local curMode = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetTeamReplaceGetCurMode)
  if curMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
    local data = self.data
    if data and data.PetData then
      self:OnPetTeamFastFormationRefreshed(self.teamInfoDic)
    end
  else
    local data = self.data
    if data and data.PetData then
      local curSelectGid = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetTeamReplaceGetCurSelPetDataGid)
      if data.PetData.gid == curSelectGid then
      else
      end
    end
  end
end

function UMG_Common_ListItem_Pet1_C:OnPetTeamWarehouseItemSelected(_PetData)
  local state = true
  if not self.uiData.bFromShiningWeekend then
    state = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetTeamReplaceGetCurExChangeState)
  end
  if not state then
    return
  end
  local isSelect = false
  if self.data and self.data.PetData and _PetData and self.data.PetData.gid == _PetData.gid then
    isSelect = true
  else
  end
  goto lbl_35
  ::lbl_35::
  self:SetIsSelect(isSelect)
end

function UMG_Common_ListItem_Pet1_C:UpdateCollectCanvas()
end

function UMG_Common_ListItem_Pet1_C:OnPetTeamFastFormationRefreshed(newTeamInfoDic)
  local data = self.data
  self.number:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.teamInfoDic = newTeamInfoDic
  local isSelect = false
  if data and data.PetData then
    if newTeamInfoDic and newTeamInfoDic[data.PetData.gid] then
      isSelect = true
      self.rightShowNumber = newTeamInfoDic[data.PetData.gid]
      if self.rightShowNumber and data.canInTeamNum and self.rightShowNumber <= data.canInTeamNum then
        self.number:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self.Text_number:SetText(self.rightShowNumber)
      if self.data.PetData.PetBaseInfo.partner_mark and self.data.PetData.PetBaseInfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
        self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      if self.data.PetData.PetBaseInfo.partner_mark and self.data.PetData.PetBaseInfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
        self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
      end
    end
  end
  self:SetIsSelect(isSelect)
end

function UMG_Common_ListItem_Pet1_C:ResetUI()
end

function UMG_Common_ListItem_Pet1_C:OnPetTeamFastFormationChanged(newTeamInfoDic)
  local data = self.data
  self.teamInfoDic = newTeamInfoDic
  local isSelect = false
  if data and data.PetData then
    if newTeamInfoDic and newTeamInfoDic[data.PetData.gid] then
      isSelect = true
      self.rightShowNumber = newTeamInfoDic[data.PetData.gid]
      self.Text_number:SetText(self.rightShowNumber)
      if self.rightShowNumber > data.canInTeamNum then
        self.number:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.number:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if not self.data.PetData.PetBaseInfo.partner_mark or self.data.PetData.PetBaseInfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
        end
      end
    else
      self.rightShowNumber = nil
      if not self.data.PetData.PetBaseInfo.partner_mark or self.data.PetData.PetBaseInfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
      else
      end
    end
  end
  self:SetIsSelect(isSelect)
end

function UMG_Common_ListItem_Pet1_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_Common_ListItem_Pet1_C:OnItemSelected(_bSelected, _bScrollSelected)
  if _bScrollSelected then
    return
  end
  if self.uiData.isLockUp then
    return
  end
  if self.uiData and self.uiData.PetData and self.uiData.PetData.is_trial_pet and self.uiData.PetData.refreshTime then
    local servetTime = ActivityUtils.GetSvrTimestamp()
    if servetTime > self.uiData.PetData.refreshTime then
      local tips = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_trial_pet_character4").str
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
      _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.SendZonePvpInfoQueryReq)
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AnimClosePetTeamReplacePanel)
      return
    end
  end
  if _bSelected then
    if not _bScrollSelected and self.IsLock then
      local nameLessCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_same_pet")
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, nameLessCfg.str)
      return
    end
    local curMode = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetTeamReplaceGetCurMode)
    local canSelect = false
    if curMode == PetUIModuleEnum.ModifyPetMode.SingleEdit then
      local state = true
      if not self.uiData.bFromShiningWeekend then
        state = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetTeamReplaceGetCurExChangeState)
      end
      if state then
        canSelect = true
      else
        local isInTeam = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.PetTeamReplaceGetCurSelectIsInTeam)
        if isInTeam then
          if self.uiData.PetData then
            canSelect = true
          end
        elseif self.uiData.PetData then
          canSelect = true
        elseif self.uiData.isPetListItem then
          canSelect = true
        end
      end
      if canSelect then
      end
    elseif curMode == PetUIModuleEnum.ModifyPetMode.QuickEdit then
      canSelect = true
    end
    local data = self.uiData
    local petData = data.PetData
    local callbackOwner = data and data.CallbackOwner
    local onSelectCallback = data and data.OnSelectCallback
    if canSelect and onSelectCallback then
      tcall(callbackOwner, onSelectCallback, petData)
    end
  end
end

function UMG_Common_ListItem_Pet1_C:OnDeactive()
  self.uiData = nil
  self.data = nil
end

function UMG_Common_ListItem_Pet1_C:OnSpawn2()
  local data = self.data
  local callbackOwner = data and data.CallbackOwner
  local onSpawnCallback = data and data.OnSpawnCallback
  if onSpawnCallback then
    tcall(callbackOwner, onSpawnCallback, data)
  end
end

function UMG_Common_ListItem_Pet1_C:OnAnimationFinished(Animation)
  if Animation == self.In or Animation == self.Out then
    self.isAnimPlaying = false
    self:RefreshIsSelectDisplay()
  end
end

function UMG_Common_ListItem_Pet1_C:InitSelectState()
  self.isSelect = false
  self.isSelectDisplay = false
  self:StopAllAnimations()
  local normalEndTime = self.Normal:GetEndTime()
  self:PlayAnimation(self.Normal, normalEndTime)
end

function UMG_Common_ListItem_Pet1_C:SetIsSelect(isSelect)
  local data = self.uiData
  if data then
    data.isSelect = isSelect
  end
  self.isSelect = isSelect
  self:RefreshIsSelectDisplay()
end

function UMG_Common_ListItem_Pet1_C:RefreshIsSelectDisplay()
  if self.isAnimPlaying then
    return
  end
  local prevIsSelectDisplay = self.isSelectDisplay or false
  local nextIsSelectDisplay = self.isSelect or false
  if prevIsSelectDisplay == nextIsSelectDisplay then
    return
  end
  self.isSelectDisplay = nextIsSelectDisplay
  if prevIsSelectDisplay and not nextIsSelectDisplay then
    self.isAnimPlaying = true
    self:PlayAnimation(self.Out)
  elseif not prevIsSelectDisplay and nextIsSelectDisplay then
    self.isAnimPlaying = true
    self:PlayAnimation(self.In)
  end
end

return UMG_Common_ListItem_Pet1_C
