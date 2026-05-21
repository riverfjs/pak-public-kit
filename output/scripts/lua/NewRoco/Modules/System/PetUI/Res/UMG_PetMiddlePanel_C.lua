local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUIModuleEnum = reload("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetMiddlePanel_C = _G.NRCViewBase:Extend("UMG_PetMiddlePanel_C")
local RedPointModuleEvent = require("NewRoco.Modules.System.RedPoint.RedPointModuleEvent")
local isMovePetModel = false
local movePetModelTargetPos = 0
local movePetModelSpeed = 300

function UMG_PetMiddlePanel_C:Initialize(Initializer)
end

function UMG_PetMiddlePanel_C:OnConstruct()
  self:SetChildViews(self.UMG_PetEvoLevelUP_fx, self.petImage3D)
  local SHOW_STATE = {ST_BASE_INFO = 1, ST_EVOLUTION = 2}
  self.uiData = {}
  self.uiItem = {}
  self.ShowDebug = false
  self.CameraTrackType = 0
  self.isSleep = false
  self.uiItem.evoStars = {
    self.evoStar1,
    self.evoStar2
  }
  self.HatchUpdateTime = _G.DataConfigManager:GetPetGlobalConfig("hatch_refresh_time").num
  self.hatchSakeTime1 = _G.DataConfigManager:GetPetGlobalConfig("hatch_shake_time1").numList
  self.hatchSakeTime2 = _G.DataConfigManager:GetPetGlobalConfig("hatch_shake_time2").numList
  self.hatchSakeTime3 = _G.DataConfigManager:GetPetGlobalConfig("hatch_shake_time3").numList
  self.hatchSakeTime4 = _G.DataConfigManager:GetPetGlobalConfig("hatch_shake_time4").numList
  self.hatchSakeTime5 = _G.DataConfigManager:GetPetGlobalConfig("hatch_shake_time5").numList
  self.hatchJumpPercent = _G.DataConfigManager:GetPetGlobalConfig("hatch_jump_percent").num
  self:OnAddEventListener()
  self.SHOW_STATE = SHOW_STATE
  self.curShowState = SHOW_STATE.ST_BASE_INFO
  self.data = self.module:GetData("PetUIModuleData")
  self:updatePanelItemShowState()
end

function UMG_PetMiddlePanel_C:BuildTypeFx()
  if self.TypeFx then
    return
  end
  self.TypeFx = {
    self.Fx_putongxi,
    self.Fx_caoxi,
    self.Fx_huoxi,
    self.Fx_shuixi,
    self.Fx_guangxi,
    self.Fx_tuxi,
    self.Fx_tuxi,
    self.Loop,
    self.Loop,
    self.Loop,
    self.Loop,
    self.Fx_chongzi,
    self.Loop,
    self.Fx_yixi,
    self.Loop,
    self.Loop,
    self.Fx_emoxi,
    self.Loop,
    self.Loop
  }
end

function UMG_PetMiddlePanel_C:OnDeactive()
  self.petImage3D:OnDeactive()
  self.UMG_PetEvoLevelUP_fx:OnDeactive()
end

function UMG_PetMiddlePanel_C:OnDestruct()
  self:Log("UMG_PetMiddlePanel_C:OnDestruct")
  self:OnRemoveEventListener()
  table.clear(self.uiItem)
  self.uiData = nil
  self.uiItem = nil
  self:Log("destruct template", self.iconSelect1, self.iconSelect2, self.iconSelect3, self.iconSelect4, self.iconSelect5)
  self.iconSelect1:Destruct()
  self.iconSelect2:Destruct()
  self.iconSelect3:Destruct()
  self.iconSelect4:Destruct()
  self.iconSelect5:Destruct()
  self:EndEggTime()
end

function UMG_PetMiddlePanel_C:OnEnable()
end

function UMG_PetMiddlePanel_C:OnDisable()
end

function UMG_PetMiddlePanel_C:OnTick(_inDeltaTime)
  if self.starEggTimer and self.curEggSchedule and self.curEggSchedule < 100 then
    self.eggTimer = self.eggTimer + _inDeltaTime
    if self.eggTimer >= self.HatchUpdateTime then
      self.eggTimer = 0
      if self.curEggGid then
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ZoneGetHatchStatusReq)
      end
    end
  end
  if isMovePetModel then
    local moveDistance = _inDeltaTime * movePetModelSpeed
    local curPos = self.Panel_Info.Slot:GetPosition()
    local curPosX = curPos.X
    if curPosX < movePetModelTargetPos then
      curPosX = curPosX + moveDistance
      if curPosX >= movePetModelTargetPos then
        curPosX = movePetModelTargetPos
        isMovePetModel = false
      end
    else
      curPosX = curPosX - moveDistance
      if curPosX <= movePetModelTargetPos then
        curPosX = movePetModelTargetPos
        isMovePetModel = false
      end
    end
    curPos.X = curPosX
  end
end

function UMG_PetMiddlePanel_C:MovePetModelToRight()
  movePetModelTargetPos = 210
  isMovePetModel = true
end

function UMG_PetMiddlePanel_C:MovePetModelToLeft()
  movePetModelTargetPos = 0
  isMovePetModel = true
end

function UMG_PetMiddlePanel_C:OnAddEventListener()
  self:AddButtonListener(self.btnEvolutionPrev, self.OnBtnEvolutionPrevClick)
  self:AddButtonListener(self.btnEvolutionNext, self.OnBtnEvolutionNextClick)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_RIGHT_SUBPANEL_CHANGE, self.OnRightSubPanelChange)
  self:RegisterEvent(self, PetUIModuleEvent.PET_EVOLUTION_SUCCESS, self.OnEvolutionSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_MODEL_PLAY_ANIM, self.OnModelPlayAnim)
  NRCEventCenter:RegisterEvent("PetUI", self, PetUIModuleEvent.DebugPetUIPercentage, self.OnUIPercentageChange)
  NRCEventCenter:RegisterEvent("PetUI", self, PetUIModuleEvent.DebugPetPosOffset, self.OnUIPetPosOffsetChange)
  NRCEventCenter:RegisterEvent("PetUI", self, PetUIModuleEvent.DebugCameraSpin, self.OnUICameraSpinChange)
  NRCEventCenter:RegisterEvent("PetUI", self, PetUIModuleEvent.ApplyPetUIParameters, self.ApplyChanges)
  NRCEventCenter:RegisterEvent("PetUI", self, PetUIModuleEvent.ShowDebug, self.OnShowDebug)
  NRCEventCenter:RegisterEvent("PetUI", self, PetUIModuleEvent.UseAnimZ, self.OnUseZ)
  NRCEventCenter:RegisterEvent("RedPointModule", self, RedPointModuleEvent.RedPointChange, self.OnUpdateRedPointData)
  self:RegisterEvent(self, PetUIModuleEvent.SetPetModelLocation, self.SetPetLocation)
  self:RegisterEvent(self, PetUIModuleEvent.SetPetHiddenInGame, self.OnSetPetHiddenInGame)
  self:RegisterEvent(self, PetUIModuleEvent.DestroyHavingModelInfoEvent, self.DestroyHavingModelInfo)
  self:RegisterEvent(self, PetUIModuleEvent.SetHavingLocationByIsHasHaving, self.SetHavingLocationByIsHasHavingInfo)
  self:RegisterEvent(self, PetUIModuleEvent.HavingModelMove, self.HavingModelMoveChange)
  self:RegisterEvent(self, PetUIModuleEvent.HavingModelSelect, self.OnHavingModelSelect)
  self:RegisterEvent(self, PetUIModuleEvent.SetHavingColor, self.OnSetHavingColor)
  self:RegisterEvent(self, PetUIModuleEvent.GetHavingScreenPositionInfo, self.OnGetHavingScreenPositionInfo)
  self:RegisterEvent(self, PetUIModuleEvent.OpenDetailCameraLocation, self.OnOpenDetailCameraLocation)
  self:RegisterEvent(self, PetUIModuleEvent.SelectPetEgg, self.updateEggModelInfo)
  _G.NRCEventCenter:RegisterEvent(self.name, self, PetUIModuleEvent.OnUpdateHatchSecs, self.OnUpdateHatchSecs)
  self:RegisterEvent(self, PetUIModuleEvent.OnClickPetImage3d, self.OnClickPetImage3D)
  self:RegisterEvent(self, PetUIModuleEvent.OnEggPerformChange, self.OnEggPerformChange)
  self:RegisterEvent(self, PetUIModuleEvent.OnCrackEgg, self.OnCrackEgg)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange)
  self:RegisterEvent(self, PetUIModuleEvent.UpdatePetModelAnimStatue, self.updatePetModelBaseInfoAnimStatue)
  self:RegisterEvent(self, PetUIModuleEvent.OnRefreshEvoPetModel, self.RefreshEvoPetModel)
  if self.shadowHeight then
    self:AddDelegateListener(self.shadowHeight.OnValueChanged, self.OnShadowHeightChanged)
  end
  if self.shadowScale then
    self:AddDelegateListener(self.shadowScale.OnValueChanged, self.OnShadowScaleChanged)
  end
  if self.modelScale then
    self:AddDelegateListener(self.modelScale.OnValueChanged, self.OnModelScaleChanged)
  end
end

function UMG_PetMiddlePanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnUpdateHatchSecs, self.OnUpdateHatchSecs)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnClickPetImage3d, self.OnClickPetImage3D)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnCrackEgg, self.OnCrackEgg)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnEggPerformChange, self.OnEggPerformChange)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.DebugPetUIPercentage, self.OnUIPercentageChange)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.DebugPetPosOffset, self.OnUIPetPosOffsetChange)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.ApplyPetUIParameters, self.ApplyChanges)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.DebugCameraSpin, self.OnUICameraSpinChange)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.ShowDebug, self.OnShowDebug)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.UseAnimZ, self.OnUseZ)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.SelectPetEgg, self.updateEggModelInfo)
  NRCEventCenter:UnRegisterEvent(self, RedPointModuleEvent.RedPointChange, self.OnUpdateRedPointData)
  if _G.DataModelMgr.PlayerDataModel:HasListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange) then
    _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange)
  end
end

function UMG_PetMiddlePanel_C:GetPetViewCameraActor()
  Log.Debug("UMG_PetMiddlePanel_C:GetPetViewCameraActor")
  return self.petImage3D:GetCameraActor()
end

function UMG_PetMiddlePanel_C:SetPetLocation(_location)
  self.petImage3D:SetModelLocation(_location)
end

function UMG_PetMiddlePanel_C:OnSetPetHiddenInGame(_IsHide)
  self.petImage3D:SetShowOrHidePet(_IsHide)
end

function UMG_PetMiddlePanel_C:DestroyHavingModelInfo()
  self.petImage3D:DestroyHavingModel()
end

function UMG_PetMiddlePanel_C:SetHavingLocationByIsHasHavingInfo(_IsHasHaving)
  self.petImage3D:SetHavingLocationByIsHasHaving(_IsHasHaving)
end

function UMG_PetMiddlePanel_C:HavingModelMoveChange(_CurrentSelectIndex, _MoveTime)
  self.petImage3D:OnHavingModelMove(_CurrentSelectIndex, _MoveTime)
end

function UMG_PetMiddlePanel_C:OnHavingModelSelect(_IsSelect, _Pos, _CurrentSelectIndex, _Time)
  self.petImage3D:HavingModelSelect(_IsSelect, _Pos, _CurrentSelectIndex, _Time)
end

function UMG_PetMiddlePanel_C:OnSetHavingColor(_pos, _quality, _IsLerp)
  self.petImage3D:SetHavingColorInfo(_pos, _quality, _IsLerp)
end

function UMG_PetMiddlePanel_C:OnGetHavingScreenPositionInfo()
  local HavingScreenPosition = self.petImage3D:GetHavingScreenPosition()
  self:DispatchEvent(PetUIModuleEvent.SetHavingUIPosition, HavingScreenPosition)
end

function UMG_PetMiddlePanel_C:OnShowDebug()
  if self.ShowDebug == false then
    self.ShowDebug = true
  else
    self.ShowDebug = false
  end
end

function UMG_PetMiddlePanel_C:OnUseZ()
  if self.petImage3D.UseZ == false then
    self.petImage3D.UseZ = true
  else
    self.petImage3D.UseZ = false
  end
end

function UMG_PetMiddlePanel_C:OnShadowHeightChanged(_v)
end

function UMG_PetMiddlePanel_C:OnShadowScaleChanged(_v)
end

function UMG_PetMiddlePanel_C:OnUIPercentageChange(Percent)
  self.petImage3D.PetUIPercent = Percent or 0.7
end

function UMG_PetMiddlePanel_C:OnUIPetPosOffsetChange(X, Y, Z)
  self.petImage3D.PetPosOffset = UE4.FVector(X, Y, Z)
end

function UMG_PetMiddlePanel_C:OnUICameraSpinChange(X, Y, Z)
  self.petImage3D.CamSpin = UE4.FRotator(X, Y, Z)
end

function UMG_PetMiddlePanel_C:ApplyChanges()
  local petBaseCfg = self.uiData.petBaseCfg
  self:updatePetModelInfoDebug(petBaseCfg)
end

function UMG_PetMiddlePanel_C:OnModelScaleChanged(_v)
  self.petImage3D:SetModelScale(_v)
  if self.uiData and self.uiData.cur3dModelPetBaseCfg then
    self.uiData.cur3dModelPetBaseCfg.petpage_ui_percentage = _v
  end
end

function UMG_PetMiddlePanel_C:OnOpenDetailCameraLocation(_CameraTrackType)
  local isPetAttrOpen = self:GetPetAttributeIsOpen()
  local IsPetBagOpen = self:GetPetBagIsOpen()
  self.petImage3D:OpenDetailCameraLocation(_CameraTrackType, isPetAttrOpen, IsPetBagOpen)
  local menuIndex = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetUiMenuIndex)
  self.CameraTrackType = _CameraTrackType
  if 4 == menuIndex then
    self:SetPetSleepAnimState()
  end
end

function UMG_PetMiddlePanel_C:SetPetSleepAnimState()
  if 1 == self.CameraTrackType then
    self.petImage3D:PlaySleepAnim()
    self.isSleep = true
  elseif 0 == self.CameraTrackType then
    self.petImage3D:PlayOutSleepAnim()
    self.isSleep = false
  end
end

function UMG_PetMiddlePanel_C:OnBtnEvolutionPrevClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1001, "UMG_PetMiddlePanel_C:OnBtnEvolutionPrevClick")
  local uiData = self.uiData
  local curEvolutionCount = uiData.curEvolutionCount or 0
  local curEvolutionIndex = uiData.curEvolutionIndex or -1
  if curEvolutionCount < 1 then
    return
  end
  curEvolutionIndex = curEvolutionIndex - 1
  if curEvolutionIndex < 1 then
    curEvolutionIndex = 1
  end
  uiData.curEvolutionIndex = curEvolutionIndex
  self:updateEvolutionInfo(false)
  self:DispatchEvent(PetUIModuleEvent.PET_UI_EVOLUTION_INDEX_CHANGE, uiData.curEvolutionIndex)
end

function UMG_PetMiddlePanel_C:OnBtnEvolutionNextClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1001, "UMG_PetMiddlePanel_C:OnBtnEvolutionNextClick")
  local uiData = self.uiData
  local curEvolutionCount = uiData.curEvolutionCount or 0
  local curEvolutionIndex = uiData.curEvolutionIndex or -1
  if curEvolutionCount < 1 then
    return
  end
  curEvolutionIndex = curEvolutionIndex + 1
  if curEvolutionCount < curEvolutionIndex then
    curEvolutionIndex = curEvolutionCount
  end
  uiData.curEvolutionIndex = curEvolutionIndex
  self:updateEvolutionInfo(false)
  self:DispatchEvent(PetUIModuleEvent.PET_UI_EVOLUTION_INDEX_CHANGE, uiData.curEvolutionIndex)
end

function UMG_PetMiddlePanel_C:OnEvolutionSelectBtnClick(_index)
  local uiData = self.uiData
  local curEvolutionCount = uiData.curEvolutionCount or 0
  local curEvolutionIndex = uiData.curEvolutionIndex or -1
  if curEvolutionCount < 1 or curEvolutionIndex == _index then
    return
  end
  uiData.curEvolutionIndex = _index
  self:updateEvolutionInfo(false)
  self:DispatchEvent(PetUIModuleEvent.PET_UI_EVOLUTION_INDEX_CHANGE, uiData.curEvolutionIndex)
end

function UMG_PetMiddlePanel_C:OnSelectPetChange(_petData)
end

function UMG_PetMiddlePanel_C:OnSelectPetInfoUpdate(_petInfo, _petData, NotChangeAnim)
  self.uiData.petInfo = _petInfo
  self.uiData.petData = _petData
  self.NotChangeAnim = NotChangeAnim
  local baseConf
  if _petInfo.base_conf_id and _petInfo.base_conf_id > 0 then
    baseConf = _G.DataConfigManager:GetPetbaseConf(_petInfo.base_conf_id)
  end
  self.uiData.petBaseCfg = baseConf
  self.uiData.curEvolutionIndex = -1
  self:updatePanelInfo()
  self:EndEggTime()
end

function UMG_PetMiddlePanel_C:OnSelectEmpty()
  self.petImage3D.PetBaseConf = nil
  self.petImage3D:SetEmptyView()
  self.petImage3D.isEgg = false
end

function UMG_PetMiddlePanel_C:OnLeftSubPanelChange(_subPanelIndex)
  if _subPanelIndex and _subPanelIndex > 0 then
    self.petImage3D:ResSetActorRotation(210)
  else
    self.petImage3D:ResSetActorRotation(150)
  end
  self:updatePetModelBaseInfoAnimStatue(_subPanelIndex, false)
end

function UMG_PetMiddlePanel_C:OnRightSubPanelChange(_subPanelIndex)
  if _subPanelIndex and _subPanelIndex > 0 then
    local SHOW_STATE = self.SHOW_STATE
    self:changeShowState(SHOW_STATE.ST_BASE_INFO)
    if 4 == _subPanelIndex then
      self.petImage3D:PlaySleepAnim()
      self.isSleep = true
    else
      if self.isSleep then
        self.petImage3D:PlayOutSleepAnim()
      end
      self.isSleep = false
    end
  end
end

function UMG_PetMiddlePanel_C:OnEvolutionSuccess(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetMiddlePanel_C:OnPlayerPetHPChange(_petData)
  if self.uiData and self.uiData.petData and _petData.gid == self.uiData.petData.gid then
    if _petData.level > self.uiData.petData.level then
      self.UMG_PetEvoLevelUP_fx:PlayLevelUpEffect()
    end
    self.uiData.petData.level = _petData.level
  end
end

function UMG_PetMiddlePanel_C:OnModelPlayAnim(_aniName)
  if _aniName then
    self.petImage3D:PlayAnimByName(_aniName, 1)
  end
end

function UMG_PetMiddlePanel_C:checkCurPetInfoChange(_changes)
  local curPetData = self.uiData.petData
  if not curPetData or not _changes then
    return
  end
  for i, changItem in ipairs(_changes) do
    if changItem.type == _G.ProtoEnum.GoodsType.GT_PET then
      local petData = changItem.pet_data
      if curPetData.gid == petData.gid then
        self.uiData.petData = petData
        local baseConf
        if petData.base_conf_id and petData.base_conf_id > 0 then
          baseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
        end
        self.uiData.petBaseCfg = baseConf
        self:updatePanelInfo()
      end
    end
  end
end

function UMG_PetMiddlePanel_C:changeShowState(_state)
  if self.curShowState ~= _state then
    self.curShowState = _state
    self:updatePanelItemShowState()
    self:updatePanelInfo()
  end
end

function UMG_PetMiddlePanel_C:updatePanelItemShowState()
  self:setActive(self.panelEvolutionStar, false)
  self:setActive(self.changeEvolutionButtons, false)
end

function UMG_PetMiddlePanel_C:updatePanelInfo()
  local SHOW_STATE = self.SHOW_STATE
  if self.curShowState == SHOW_STATE.ST_BASE_INFO then
    self:updatePetBaseInfo()
  elseif self.curShowState == SHOW_STATE.ST_EVOLUTION then
    self:updateEvolutionInfo(true)
  else
    self:updatePetBaseInfo()
  end
end

function UMG_PetMiddlePanel_C:updatePetBaseInfo()
  local petInfo = self.uiData.petInfo
  local petBaseCfg = self.uiData.petBaseCfg
  self:updatePetModelInfo(petBaseCfg)
  local idx = self:getLeftSubPanelIndex()
end

function UMG_PetMiddlePanel_C:updateEvolutionInfo(_updateSelectPanelCount)
  local uiData = self.uiData
  local petData = uiData.petData
  local petInfo = uiData.petInfo
  local petBaseCfg = uiData.petBaseCfg
  local evolutionCount = 0
  local evolutionPetIdList = petBaseCfg.evolution_pet_id
  if evolutionPetIdList then
    evolutionCount = #evolutionPetIdList
  end
  uiData.curEvolutionCount = evolutionCount
  local isAcceptTask = petData.evolution_task and petData.evolution_task > 0
  if isAcceptTask then
    uiData.curEvolutionIndex = petData.evolution_chosen_idx and petData.evolution_chosen_idx + 1 or 1
  end
  local curPetBaseCfg
  if evolutionCount > 0 then
    local curEvolutionIndex = uiData.curEvolutionIndex or -1
    if curEvolutionIndex <= 0 or evolutionCount < curEvolutionIndex then
      curEvolutionIndex = 1
      uiData.curEvolutionIndex = 1
    end
    local evolutionPetId = evolutionPetIdList[curEvolutionIndex]
    local evolutionPetBaseConf = _G.DataConfigManager:GetPetbaseConf(evolutionPetId)
    curPetBaseCfg = evolutionPetBaseConf
  else
    curPetBaseCfg = petBaseCfg
  end
  local typeDic = self:updateEvolutionBackGround(curPetBaseCfg)
  self:updatePetModelInfo(curPetBaseCfg, evolutionCount > 0, typeDic.evo_banding_color)
  self:updateStateEvolutionButton(_updateSelectPanelCount)
  self.petImage3D:PlayAnimByName("Idle", -1)
  self.petImage3D:SetAnimList(nil, nil)
end

function UMG_PetMiddlePanel_C:OnUpdateRedPointData(notify)
  if notify.rp_group then
    for _, group in pairs(notify.rp_group) do
      if group.reason_type == _G.Enum.RedPointReason.RPR_EGG_HATCH_COMPLETE and group.point_data and #group.point_data > 0 then
        self:DispatchEvent(PetUIModuleEvent.UpdateEggSpeedIcon, group.point_data)
        for i, gid in pairs(group.point_data) do
          if self.curEggGid == tonumber(gid) then
            _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ZoneGetHatchStatusReq)
          end
        end
      end
    end
  end
end

function UMG_PetMiddlePanel_C:updateEggModelInfo(eggInfo, index, bUpdateEggModel)
  if not self.petImage3D.IsOnActive then
    self:initEggModelInfo(eggInfo)
    return
  end
  if not bUpdateEggModel and (nil == eggInfo or self.curEggGid == eggInfo.gid) then
    if nil == eggInfo then
      self.curEggGid = nil
      self.petImage3D:SetPath("", false, nil)
    end
    return
  end
  if eggInfo then
    self.curEggGid = eggInfo.gid
  end
  self:SetEggPetImage3DInfo(eggInfo)
end

function UMG_PetMiddlePanel_C:initEggModelInfo(eggInfo)
  self:SetEggPetImage3DInfo(eggInfo, true)
end

function UMG_PetMiddlePanel_C:SetEggPetImage3DInfo(eggInfo, bInit)
  self.curEggData = eggInfo.eggData
  self.curEggGid = eggInfo.gid
  self.animaTapIndex = 0
  local eggData = eggInfo.eggData
  local eggConf, petBaseConf
  if 0 ~= eggData.conf_id then
    local petBaseId = _G.DataConfigManager:GetPetConf(eggInfo.eggData.conf_id).base_id
    eggConf = _G.DataConfigManager:GetPetEggConf(eggData.conf_id)
    petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    self.petImage3D.PetBaseConf = petBaseConf
  elseif eggData.random_egg_conf then
    eggConf = _G.DataConfigManager:GetPetRandomEggConf(eggData.random_egg_conf)
    self.petImage3D.eggData = eggData
    self.petImage3D.PetBaseConf = nil
  end
  if nil == eggConf then
    Log.Error("UMG_PetMiddlePanel_C:SetEggPetImage3DInfo eggConf is nil")
    return
  end
  local moduleConf = _G.DataConfigManager:GetModelConf(eggConf.model_id)
  local modulePath = moduleConf.path
  if bInit then
    self.petImage3D:OnActive(petBaseConf, "PetInfoMain", modulePath)
  end
  self.petImage3D.eggData = eggData
  self.petImage3D.isEgg = true
  self.petImage3D.eggModuleScale = 0.65
  self.petImage3D:SetPath(modulePath, false, nil)
end

function UMG_PetMiddlePanel_C:OnUpdateHatchSecs(rsp)
  if self.curEggData then
    local index
    for i = 1, #rsp.egg_gid do
      if rsp.egg_gid[i] == self.curEggGid then
        index = i
      end
    end
    local secs = 0
    if index and rsp.hatched_secs[index] then
      secs = rsp.hatched_secs[index]
    end
    local schedule
    if self.curEggData.conf_id and 0 ~= self.curEggData.conf_id then
      local eggConf = _G.DataConfigManager:GetPetEggConf(self.curEggData.conf_id)
      schedule = secs / eggConf.hatch_data * 100
    elseif self.curEggData.max_hatched_secs and self.curEggData.max_hatched_secs > 0 then
      schedule = secs / self.curEggData.max_hatched_secs * 100
    end
    if schedule then
      self.curEggSchedule = schedule
      local index = 0
      if schedule >= self.hatchSakeTime5[2] then
        index = 6
      elseif schedule >= self.hatchSakeTime5[1] and schedule < self.hatchSakeTime5[2] then
        index = 5
      elseif schedule >= self.hatchSakeTime4[1] and schedule < self.hatchSakeTime4[2] then
        index = 4
      elseif schedule >= self.hatchSakeTime3[1] and schedule < self.hatchSakeTime3[2] then
        index = 3
      elseif schedule >= self.hatchSakeTime2[1] and schedule < self.hatchSakeTime2[2] then
        index = 2
      elseif schedule >= self.hatchSakeTime1[1] and schedule < self.hatchSakeTime1[2] then
        index = 1
      else
        index = 1
      end
      self:SetEggAnimList(index)
    end
  end
end

function UMG_PetMiddlePanel_C:IsContainPetImageAnimName(name, time)
  if self.petImage3D and self.petImage3D.animList then
    local animListIdleTime = self.petImage3D.maxAnimListIdleTime
    for i = 1, #self.petImage3D.animList do
      local animaName = self.petImage3D.animList[i]
      if animaName == name and animListIdleTime == time then
        return true
      end
    end
  end
  return false
end

function UMG_PetMiddlePanel_C:SetEggAnimList(index)
  self.animaTapIndex = index
  if 1 == index then
    local sakeTime = self.hatchSakeTime1[3]
    if self:IsContainPetImageAnimName("Relax", sakeTime) == false then
      self.petImage3D:SetAnimationList({"Relax"}, sakeTime)
    end
  elseif 2 == index then
    local sakeTime = self.hatchSakeTime2[3]
    if self:IsContainPetImageAnimName("Relax", sakeTime) == false then
      self.petImage3D:SetAnimationList({"Relax"}, sakeTime)
    end
  elseif 3 == index then
    local sakeTime = self.hatchSakeTime3[3]
    if self:IsContainPetImageAnimName("Relax", sakeTime) == false then
      self.petImage3D:SetAnimationList({"Relax"}, sakeTime)
    end
  elseif 4 == index then
    local sakeTime = self.hatchSakeTime4[3]
    if self:IsContainPetImageAnimName("Relax", sakeTime) == false then
      self.petImage3D:SetAnimationList({"Relax"}, sakeTime)
    end
  elseif 5 == index then
    local sakeTime = self.hatchSakeTime5[3]
    if self:IsContainPetImageAnimName("Relax", sakeTime) == false then
      self.petImage3D:SetAnimationList({"Relax"}, sakeTime)
    end
  elseif 6 == index then
    local sakeTime = 1
    if false == self:IsContainPetImageAnimName("Hatch", sakeTime) then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1220002040, "UMG_PetMiddlePanel_C:SetEggAnimList")
      self.petImage3D:SetAnimationList({"Hatch"}, sakeTime)
    end
  else
    local sakeTime = self.hatchSakeTime1[3]
    if self:IsContainPetImageAnimName("Relax", sakeTime) == false then
      self.petImage3D:SetAnimationList({"Relax"}, sakeTime)
    end
  end
end

function UMG_PetMiddlePanel_C:OnEggPerformChange(notFinst)
  if false == notFinst then
    self.petImage3D:CloseAllLight()
    self.curEggGid = nil
  end
end

function UMG_PetMiddlePanel_C:OnClickPetImage3D()
  if self:CheckIsSelectBtn() then
    return
  end
  if self.curEggGid == nil then
    return
  end
  if 6 == self.animaTapIndex then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, true)
    isBan = isBan or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG_GET_BACK, true)
    if isBan then
      return
    end
    if self.curEggData and self.curEggData.ball_id and 0 ~= self.curEggData.ball_id then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ZoneCrackEggReq, self.curEggGid, nil, nil)
      return
    end
    return
  end
  if self.curEggSchedule and self.hatchJumpPercent and self.curEggSchedule >= self.hatchJumpPercent then
    local isPlaying = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckIsEggPlayAnima, self.curEggGid)
    if isPlaying then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetEggPlayAnimaTime, self.curEggGid)
      self.petImage3D:PlayAnimByName("Relax")
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002029, "UMG_PetMiddlePanel_C:OnClickPetImage3D")
    end
  end
end

function UMG_PetMiddlePanel_C:OnCrackEgg(petGid, eggGid, eggBallItemId)
  self:PlayEggEffect(petGid, eggBallItemId)
end

function UMG_PetMiddlePanel_C:PlayEggEffect(petGid, eggBallItemId)
  if self.curEggData then
    self.petImage3D:PlayEggEffect(petGid, eggBallItemId)
  end
end

function UMG_PetMiddlePanel_C:StarEggTime()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ZoneGetHatchStatusReq)
  self.starEggTimer = true
  self.eggTimer = 0
end

function UMG_PetMiddlePanel_C:EndEggTime()
  self.curEggGid = nil
  self.curEggData = nil
  self.animaTapIndex = 0
  self.starEggTimer = false
  self.curEggSchedule = nil
end

function UMG_PetMiddlePanel_C:OnSelectLeaderItem(ItemInfo)
end

function UMG_PetMiddlePanel_C:UpdateDefaultPetModel(_petBaseCfg)
  local modelConf = _G.DataConfigManager:GetModelConf(_petBaseCfg.model_conf)
  if modelConf then
    self.uiData.cur3dModelPetBaseCfg = _petBaseCfg
    self.petImage3D.PetBaseConf = _petBaseCfg
    local DefaultPetData = {
      base_conf_id = _petBaseCfg.id,
      mutation_type = _G.Enum.MutationDiffType.MDT_NONE
    }
    self.petImage3D:SetPath(modelConf.path, false, nil, DefaultPetData, self.NotChangeAnim)
  end
end

function UMG_PetMiddlePanel_C:updatePetModelInfo(_petBaseCfg, _isEvolution, _evoMaterialColor)
  if _evoMaterialColor and not string.StartsWith(_evoMaterialColor, "#") then
    _evoMaterialColor = "#" .. _evoMaterialColor
  end
  if _petBaseCfg then
    local modelConf = _G.DataConfigManager:GetModelConf(_petBaseCfg.model_conf)
    if modelConf then
      self.uiData.cur3dModelPetBaseCfg = _petBaseCfg
      self.petImage3D.PetBaseConf = _petBaseCfg
      self.petImage3D:SetPath(modelConf.path, _isEvolution, _evoMaterialColor, self.uiData.petData, self.NotChangeAnim)
      self.petImage3D.isEgg = false
    end
  end
end

function UMG_PetMiddlePanel_C:updatePetModelInfoDebug(_petBaseCfg, _isEvolution)
  if _petBaseCfg then
    local modelScale = _petBaseCfg.petpage_ui_percentage and _petBaseCfg.petpage_ui_percentage > 0 and _petBaseCfg.petpage_ui_percentage or 1
    local modelConf = _G.DataConfigManager:GetModelConf(_petBaseCfg.model_conf)
    if modelConf then
      self.uiData.cur3dModelPetBaseCfg = _petBaseCfg
      self.petImage3D.PetBaseConf = _petBaseCfg
      self.petImage3D:SetPath(modelConf.path, _isEvolution)
      self.petImage3D:SetModelScale(modelScale)
      self.petImage3D.isEgg = false
    end
  end
end

function UMG_PetMiddlePanel_C:updatePetModelBaseInfoAnimStatue(_leftSubPanelIndex, _playFirstAnim)
  local panelIndex = self:getLeftSubPanelIndex()
  _leftSubPanelIndex = _leftSubPanelIndex or panelIndex
  if 0 == _leftSubPanelIndex then
    if _playFirstAnim then
    end
    local DefaultAnimList = {"Alert", "Relax"}
    local DefaultRandomAnimList = {
      "Alert",
      "Becute",
      "Happy",
      "Fear",
      "Relax",
      "Shock",
      "Sad"
    }
    local PetAnimList = DefaultAnimList
    local PetRandomAnimList = DefaultRandomAnimList
    if self.uiData.petInfo and self.uiData.petInfo.base_conf_id and self.uiData.petInfo.base_conf_id > 0 then
      local animBlackList = _G.DataConfigManager:GetPetpageBlacklist(self.uiData.petInfo.base_conf_id, true)
      if animBlackList then
        PetAnimList = {}
        PetRandomAnimList = {}
        for _, _anim in pairs(DefaultAnimList) do
          if 1 ~= animBlackList[_anim] then
            table.insert(PetAnimList, _anim)
          end
        end
        for _, _anim in pairs(DefaultRandomAnimList) do
          if 1 ~= animBlackList[_anim] then
            table.insert(PetRandomAnimList, _anim)
          end
        end
      end
    end
    self.petImage3D:SetAnimList(PetAnimList, #PetAnimList, PetRandomAnimList)
  elseif 1 == _leftSubPanelIndex then
    self.petImage3D:SetAnimList(nil)
  elseif 2 == _leftSubPanelIndex then
    self.petImage3D:SetAnimList(nil)
  elseif 3 == _leftSubPanelIndex then
    self.petImage3D:SetAnimList(nil)
  else
    if 4 == _leftSubPanelIndex then
    else
    end
  end
  if self.curEggGid ~= nil then
    self:StarEggTime()
  end
  local menuIndex = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetUiMenuIndex)
  if 4 == menuIndex then
    self.petImage3D:PlaySleepAnim()
    self.isSleep = true
  end
end

function UMG_PetMiddlePanel_C:RefreshEvoPetModel(petData)
  self.petImage3D:RefreshEvoPetModel(petData)
end

function UMG_PetMiddlePanel_C:updateStateEvolutionButton(_updateSelectPanelCount)
  local uiData = self.uiData
  local petData = uiData.petData
  local curEvolutionCount = uiData.curEvolutionCount or 0
  local curEvolutionIndex = uiData.curEvolutionIndex or -1
  local evoStars = self.uiItem.evoStars
  local isAcceptTask = petData.evolution_task and petData.evolution_task > 0
  if curEvolutionCount <= 1 or isAcceptTask then
    self:setActive(self.changeEvolutionButtons, false)
    self:setActive(self.panelEvolutionStar, false)
    return
  end
  self:setActive(self.changeEvolutionButtons, true)
  self:setActive(self.panelEvolutionStar, true)
  self:setVisible(self.btnEvolutionPrev, curEvolutionCount > 1 and curEvolutionIndex > 1)
  self:setVisible(self.btnEvolutionNext, curEvolutionCount > 1 and curEvolutionCount > curEvolutionIndex)
  for idx, uiStar in ipairs(evoStars) do
    self:setActive(uiStar, idx == curEvolutionIndex)
  end
end

function UMG_PetMiddlePanel_C:updateEvolutionBackGround(_petBaseCfg)
  local unit_type = _petBaseCfg.unit_type[1]
  local typeDic = _G.DataConfigManager:GetTypeDictionary(unit_type)
  if unit_type == self.uiData.curEvolutionUnitType then
    return typeDic
  end
  if typeDic and typeDic.evo_bg_path then
    local path1 = string.format("/Game/NewRoco/Modules/System/PetUI/Raw/Texture/evo_bg/%s_faguang", typeDic.evo_bg_path)
    local path2 = string.format("/Game/NewRoco/Modules/System/PetUI/Raw/Texture/evo_bg/%s_bg", typeDic.evo_bg_path)
    local tex_fg = LoadObject(path1)
    local tex_bj = LoadObject(path2)
    self.petImage3D:SetEvolutionBackGround(tex_bj)
  end
  self.uiData.curEvolutionUnitType = unit_type
  return typeDic
end

function UMG_PetMiddlePanel_C:setActive(_uiItem, _isShow)
  if _uiItem then
    if _isShow then
      _uiItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      _uiItem:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_PetMiddlePanel_C:MiddlePlayCameraRegressionSequence()
  local PetAttributeVisibleState = self:GetAttributeIsVisible()
  self.petImage3D:PlayCameraRegressionSequence(PetAttributeVisibleState)
end

function UMG_PetMiddlePanel_C:setVisible(_uiItem, _isShow)
  if _uiItem then
    if _isShow then
      _uiItem:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      _uiItem:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_PetMiddlePanel_C:setPetInfoMainCtrl(_petInfoMainCtrl)
  self.petInfoMainCtrl = _petInfoMainCtrl
end

function UMG_PetMiddlePanel_C:GetAttributeIsVisible()
  if self.petInfoMainCtrl then
    return self.petInfoMainCtrl:GetPetAttributeVisibleState()
  end
end

function UMG_PetMiddlePanel_C:GetPetBagIsVisible()
  if self.petInfoMainCtrl then
    return self.petInfoMainCtrl:GetPetBagVisibleState()
  end
end

function UMG_PetMiddlePanel_C:GetPetAttributeIsOpen()
  if self.petInfoMainCtrl then
    return self.petInfoMainCtrl:GetAttributeOpenState()
  end
end

function UMG_PetMiddlePanel_C:GetPetBagIsOpen()
  if self.petInfoMainCtrl then
    return self.petInfoMainCtrl:GetPetBagOpenState()
  end
end

function UMG_PetMiddlePanel_C:getLeftSubPanelIndex()
  if self.petInfoMainCtrl then
    return self.petInfoMainCtrl:getLeftPanelSubPanelIndex()
  end
  return 0
end

function UMG_PetMiddlePanel_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "PetUIModule", "PetHatchingPanel")
end

return UMG_PetMiddlePanel_C
