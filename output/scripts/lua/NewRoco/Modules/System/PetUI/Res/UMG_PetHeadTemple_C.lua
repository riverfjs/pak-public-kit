require("UnLuaEx")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local UMG_PetHeadTemple_C = Base:Extend("UMG_PetHeadTemple_C")
local EnumPetInfoChangeReasonType = {None = 0, TraceBack = 1}
local BG1 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_HeadDragableBg1_png.img_HeadDragableBg1_png'"
local BG2 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_HeadDragableBg2_png.img_HeadDragableBg2_png'"
local IMG_DRAG_HOVER = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_Drag_png.img_Drag_png'"

function UMG_PetHeadTemple_C:Initialize(Initializer)
  self.SelectTimes = 0
end

function UMG_PetHeadTemple_C:OnConstruct()
  Log.Debug("UMG_PetHeadTemple_C OnConstruct~~~~ ")
  self.IsMDT_GLASS = false
  self.imageNormal:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.imageSelect:SetVisibility(UE4.ESlateVisibility.Hidden)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange)
end

function UMG_PetHeadTemple_C:OnDestruct()
  self.uiData = nil
  self.SkillId = nil
  if _G.DataModelMgr.PlayerDataModel:HasListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange) then
    _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange)
  end
  if self.TraceBackDelayHandle then
    _G.DelayManager:CancelDelay(self.TraceBackDelayHandle)
    self.TraceBackDelayHandle = nil
  end
  self.HeadIcon:ReleaseForce()
  self.petHp:Destruct()
end

function UMG_PetHeadTemple_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.uiData = _data
  self:SetData(self.uiData)
end

function UMG_PetHeadTemple_C:SetData(_petInfo, datalistInfo)
  if self.IsSetData then
  else
    self.PetLevel:SetRenderOpacity(0)
  end
  self.IsSetData = true
  self.uiData = _petInfo
  self.parent = _petInfo.parent
  self:SwitchToActive()
  self.clickable = true
  self:SetBaseInfo()
  if _petInfo and _petInfo.gid and _petInfo.gid > 0 then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petInfo.base_conf_id)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      if modelConf then
        self.HeadIcon:SetIconPathAndMaterial(_petInfo.base_conf_id, _petInfo.petData.mutation_type, _petInfo.petData.glass_info)
        self.PetLevel:SetText(self.uiData.level)
        self.PetLevel:SetVisibility(UE4.ESlateVisibility.Visible)
        self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Visible)
        self.imageNormal:SetVisibility(UE4.ESlateVisibility.Visible)
        self.headIcon_Mask:SetPath(modelConf.icon)
      end
    end
    self:SetRenderOpacity(1)
    if self.uiData.showPetHp and self:UpdatePetHP() then
      self.Panel_HP:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.uiData.FirstOpenPanel then
      if 1 == self.index then
        self:OnItemSelected(true)
      end
      self:SetClickable(false)
    end
  else
    self:SwitchToEmpty()
    self.NrcRedPoint:SetupKey(0)
    self.NrcRedPoint_1:SetupKey(0)
    self.NrcRedPoint_93:SetupKey(0)
    self.NrcRedPoint_142:SetupKey(0)
    return
  end
  self.SelectedName:SetText(self.uiData.petData.name)
  self.UnSelectedName:SetText(self.uiData.petData.name)
  self.SelectedGrade:SetText(self.uiData.level)
  self.UnSelectedGrade:SetText(self.uiData.level)
  self:UpdateTxtColor(nil)
  self.MenAndWomen:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if 1 == self.uiData.petData.gender then
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif 2 == self.uiData.petData.gender then
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    Log.Error("\230\128\167\229\136\171\228\184\141\230\152\142 ", self.uiData.petData.gender)
  end
  self:ShowEvoTip()
  self:SetRed()
end

function UMG_PetHeadTemple_C:UpdatePetName(_petData)
  self.uiData.petData = _petData
  self.UnSelectedName:SetText(self.uiData.petData.name)
  self.SelectedName:SetText(self.uiData.petData.name)
end

function UMG_PetHeadTemple_C:UpdateNewData(_petData, _base_conf_id, PetInfoChangeReasonType)
  if PetInfoChangeReasonType == EnumPetInfoChangeReasonType.TraceBack then
    Log.Debug("UMG_PetHeadTemple_C:UpdateNewData TraceBack")
    if not self:IsAnimationPlaying(self.TraceBack) then
      self.TimeRewindFxPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.imageSelect_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.TraceBack)
    end
  end
  if self.TraceBackDelayHandle then
    _G.DelayManager:CancelDelay(self.TraceBackDelayHandle)
    self.TraceBackDelayHandle = nil
  end
  self.uiData.petData = _petData
  self.uiData.level = _petData.level
  self.uiData.base_conf_id = _base_conf_id
  if self.uiData and self.uiData.gid and self.uiData.gid > 0 then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.uiData.base_conf_id)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      if modelConf then
        self.PetLevel:SetText(self.uiData.level)
        self.SelectedGrade:SetText(self.uiData.level)
        self.UnSelectedGrade:SetText(self.uiData.level)
        self.HeadIcon:SetIconPathAndMaterial(_petData.base_conf_id, _petData.mutation_type, _petData.glass_info)
        self.UnSelectedName:SetText(self.uiData.petData.name)
        self.SelectedName:SetText(self.uiData.petData.name)
        self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Visible)
        self.headIcon_Mask:SetPath(modelConf.icon)
        self:ShowEvoTip()
        self:UpdateTxtColor()
      end
    end
  end
end

function UMG_PetHeadTemple_C:SetBaseInfo()
  self.imageNormal:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.isSelect then
    self.imageSelect:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.imageSelect:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  self.imageMainFightIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.Panel_HP:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.PetLevel:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.PetDisabled:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_PetHeadTemple_C:SetRed()
  self.NrcRedPoint:SetupKey(131, {
    self.uiData.gid
  })
  self.NrcRedPoint_1:SetupKey(131, {
    self.uiData.gid
  })
  self.NrcRedPoint_93:SetupKey(180, {
    self.uiData.gid
  })
  self.NrcRedPoint_142:SetupKey(180, {
    self.uiData.gid
  })
end

function UMG_PetHeadTemple_C:GetAllSkills(_petData)
  local skills = {}
  if _petData then
    for i, skillData in ipairs(_petData.skill.skill_data) do
      if skillData.is_learned and 1 == skillData.type then
        table.insert(skills, {
          skillData = skillData,
          mode = self.uiData.mode,
          petData = self.uiData.petData
        })
      end
    end
  end
  return skills
end

function UMG_PetHeadTemple_C:SetRedState(state)
  self.NRCImagejinhuatip_2:SetVisibility(state and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Hidden)
end

function UMG_PetHeadTemple_C:UpdatePetHP(_petData)
  local uiData = self.uiData
  if not (uiData and uiData.gid) or uiData.gid <= 0 then
    return false
  end
  local petData = _petData
  petData = petData or _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(uiData.gid)
  if not petData then
    return false
  end
  local petHpPercent
  local maxHp, hp = self:GetPetHP(petData)
  if maxHp > 0 and hp >= 0 then
    petHpPercent = hp / maxHp
    if petHpPercent > 1 then
      petHpPercent = 1
    end
  end
  self.petHp:SetHP(petHpPercent or 0)
  if hp <= 0 then
    self.PetLevel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetDisabled:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(0.3, 0.3, 0.3, 1))
  else
    self.PetLevel:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PetDisabled:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
  end
  return true
end

function UMG_PetHeadTemple_C:OnPlayerPetHPChange(_petData)
  if _petData and self.uiData and _petData.gid == self.uiData.gid then
    self:UpdatePetHP(_petData)
  end
end

function UMG_PetHeadTemple_C:GetData()
  return self.uiData
end

function UMG_PetHeadTemple_C:GetPetHP(_petData)
  return PetUtils.GetPetAdditionalByType(_petData, _G.Enum.AttributeType.AT_HPMAX), PetUtils.GetPetAdditionalByType(_petData, _G.Enum.AttributeType.AT_HPCUR)
end

function UMG_PetHeadTemple_C:SetSelect(_flag, openSelect)
  self:StopAllAnimations()
  self.isSelect = _flag
  Log.Debug(_flag, openSelect, "UMG_PetHeadTemple_C:SetSelect")
  if _flag then
    if _flag and self.SelectTimes and self.SelectTimes < 2 then
      self.SelectTimes = self.SelectTimes + 1
    end
    self.imageSelect:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.Expansion:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      if self.SelectTimes and self.SelectTimes >= 2 then
        self.SelectTimes = 0
        self:PlayAnimation(self.Expansion_Select)
        return
      else
      end
      if openSelect then
        self:PlayAnimation(self.OpenXqAni_Famjio_Select)
      end
      self:PlayAnimation(self.Expansion_Select)
      self.Select:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self:PlayAnimation(self.Tiao_In)
      self:PlayAnimation(self.change1)
    end
  else
    self.SelectTimes = 0
    self.imageSelect_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.Expansion:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self.imageSelect:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
    end
    if self.Expansion:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self:PlayAnimation(self.Expansion_UnSelect)
    else
      self:PlayAnimation(self.Tiao_Out)
      self:PlayAnimation(self.cancel)
    end
  end
end

function UMG_PetHeadTemple_C:UpdateItemInfo(_petInfo)
  self.uiData = _petInfo
  self.PetLevel:SetText(self.uiData.level)
end

function UMG_PetHeadTemple_C:SetFirstOpenPanelState(_FirstOpenPanel)
  if self.uiData then
    self.uiData.FirstOpenPanel = _FirstOpenPanel
  end
end

function UMG_PetHeadTemple_C:OnItemSelected(_bSelected)
  self:UpdateTxtColor(_bSelected)
  if _bSelected then
    if self.sayNothing then
      self.sayNothing = false
    else
      local PetIndex, PetData = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectPetIndex)
      if not self.uiData then
        Log.Error("self.uiData is Nil Value")
        return
      end
      local IsTeamPet = _G.DataModelMgr.PlayerDataModel:GetIsTeamPetByGid(self.uiData.petData.gid)
      if IsTeamPet then
        if self.parent and self.parent.GetIsOpenWithOne and self.parent:GetIsOpenWithOne() then
        else
          _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.PET, self.uiData.petData)
        end
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, self.uiData.gid)
      end
      local NotChangePetModel = self.NotChangePetModel and true or false
      if not self.SkipSetData then
        if not self.bFirstOpen then
          self:SetSelect(_bSelected, self.NeedOpenDoubleSelectAnim)
          _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, self._index, self.uiData, true, NotChangePetModel)
        elseif self.bRefreshSelect then
          self:SetSelect(_bSelected)
          _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, self._index, self.uiData, true, NotChangePetModel)
        elseif PetIndex ~= self._index or PetData and PetData.gid ~= self.uiData.gid then
          self:SetSelect(_bSelected)
          _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, self._index, self.uiData, true, NotChangePetModel)
        elseif NotChangePetModel then
          self:SetSelect(_bSelected)
          _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, self._index, self.uiData, true, NotChangePetModel)
        end
      elseif not self.bFirstOpen then
        self:SetSelect(_bSelected, self.NeedOpenDoubleSelectAnim)
      elseif PetIndex ~= self._index or PetData and PetData.gid ~= self.uiData.gid then
        self:SetSelect(_bSelected)
      elseif NotChangePetModel then
        self:SetSelect(_bSelected)
      end
      self.NeedOpenDoubleSelectAnim = false
      self.NotChangePetModel = false
      self.bFirstOpen = true
      self.SkipSetData = false
      _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, self.index, self.uiData.petData)
    end
    self.CanvasPanel_tip:SetVisibility(UE4.ESlateVisibility.Hidden)
    if self.uiData.gid == nil then
      self:SwitchToEmpty()
    else
    end
  else
    if self.uiData.gid == nil then
      self.CanvasPanel_tip:SetVisibility(UE4.ESlateVisibility.Hidden)
      self:SwitchToEmpty()
    else
      self.CanvasPanel_tip:SetVisibility(UE4.ESlateVisibility.Visible)
      self:ShowEvoTip()
    end
    self:SetSelect(_bSelected)
  end
end

function UMG_PetHeadTemple_C:UpdateTxtColor(bIsSelected)
  if not self.uiData then
    Log.Error("\230\178\161\230\156\137uiData\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
    return
  end
  local petData = self.uiData and self.uiData.petData
  local base_conf_id = petData and petData.base_conf_id
  local PetConf = _G.DataConfigManager:GetPetbaseConf(base_conf_id)
  local currentEnergy = petData and petData.energy
  if not PetConf then
    Log.Error("petData\233\135\140\233\157\162\231\154\132baseId\233\133\141\231\189\174\228\184\141\229\173\152\229\156\168\239\188\140\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174", base_conf_id)
    return
  end
  local maxEnergy = PetConf.max_energy
  self.SelectedTxtNeng:SetText(string.format("%02d", currentEnergy))
  self.UnSelectedTxtNeng:SetText(string.format("%02d", currentEnergy))
  self.MaxEnergy:SetText(string.format("/%d", maxEnergy))
  self.MaxEnergy_1:SetText(string.format("/%d", maxEnergy))
  local SlateColor
  if currentEnergy <= 5 then
    SlateColor = UE4.UNRCStatics.HexToSlateColor("#af3d3e")
    self.SelectedTxtNeng:SetColorAndOpacity(SlateColor)
    self.UnSelectedTxtNeng:SetColorAndOpacity(SlateColor)
  else
    local GreyColor = UE4.UNRCStatics.HexToSlateColor("#4F4B4BFF")
    local WhiteColor = UE4.UNRCStatics.HexToSlateColor("#FFFFFF7F")
    self.SelectedTxtNeng:SetColorAndOpacity(GreyColor)
    self.UnSelectedTxtNeng:SetColorAndOpacity(WhiteColor)
  end
end

function UMG_PetHeadTemple_C:ShowEvoTip()
end

function UMG_PetHeadTemple_C:ShowDetail(_IsFirstIn)
  if self:IsAnimationPlaying(self.OpenXqAni) then
    self:StopAnimation(self.OpenXqAni)
  end
  if self.uiData then
    self.SelectedGrade:SetText(self.uiData.level)
    self.UnSelectedGrade:SetText(self.uiData.level)
  end
  if true == _IsFirstIn then
    self.Expansion:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Unexpanded:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.imageSelectTop:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif not self:IsAnimationPlaying(self.OpenXqAni_Famjio) then
    self.Expansion:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.OpenXqAni_Famjio)
  end
end

function UMG_PetHeadTemple_C:SetIsRefreshSelect(InRefreshSelect)
  self.bRefreshSelect = InRefreshSelect
end

function UMG_PetHeadTemple_C:GetIsRefreshSelect()
  return self.bRefreshSelect
end

function UMG_PetHeadTemple_C:PlayAnimationIn()
  self:PlayAnimation(self.Open_jinglingye)
end

function UMG_PetHeadTemple_C:HideDetail()
  if self:IsAnimationPlaying(self.OpenXqAni) then
    self:StopAnimation(self.OpenXqAni)
  end
  self:PlayAnimation(self.OpenXqAni)
  self.Unexpanded:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.imageSelectTop:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetHeadTemple_C:SwitchToEmpty()
  self.clickable = false
  self.Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NotSelected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Empty:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.imageNormal:SetVisibility(UE4.ESlateVisibility.Visible)
  self.MenAndWomen:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.CanvasPanel_tip:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_PetHeadTemple_C:SwitchToActive()
  self.NotSelected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.imageNormal:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.MenAndWomen:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CanvasPanel_tip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetHeadTemple_C:OnAnimationFinished(Animation)
  if Animation == self.OpenXqAni then
    self.Expansion:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Unexpanded:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.imageSelectTop:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PetLevel:SetRenderOpacity(1)
  elseif Animation == self.OpenXqAni_Famjio then
    self.Unexpanded:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.imageSelectTop:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.PetLevel:SetRenderOpacity(0)
  elseif Animation == self.Tiao_In then
    self.Select:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif Animation == self.Tiao_Out then
    self.NotSelected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif Animation == self.cancel then
    self.imageSelect:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif Animation == self.Open_jinglingye then
    if self.uiData and self.uiData.gid and self.uiData.gid > 0 then
      self:SetClickable(true)
    end
  elseif Animation == self.Move_Out then
    self.Selected_Select:SetPath(BG1)
    self.Selected_Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Selected_Normal:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Selected_Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.imageNormal_Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetHeadTemple_C:OnTouchStarted(_MyGeometry, _InTouchEvent)
  Base.OnTouchStarted(self, _MyGeometry, _TouchEvent)
  if self.parent and self.uiData and self.uiData.gid and 0 ~= self.uiData.gid then
    self.parent:SetDragItemTemp(self)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetHeadTemple_C:GetShortRect()
  local isEmpty = not self.uiData or not self.uiData.gid or 0 == self.uiData.gid
  local widget = isEmpty and self.imageNormal or self.HeadIcon
  local geo = widget:GetCachedGeometry()
  return {
    pos = UE4.USlateBlueprintLibrary.LocalToAbsolute(geo, UE4.FVector2D(0, 0)),
    size = UE4.USlateBlueprintLibrary.GetAbsoluteSize(geo)
  }
end

function UMG_PetHeadTemple_C:GetLongRect()
  local isEmpty = not self.uiData or not self.uiData.gid or 0 == self.uiData.gid
  local widget = isEmpty and self.EmptyBg or self.isSelect and self.Bg_2 or self.Bg
  local geo = widget:GetCachedGeometry()
  return {
    pos = UE4.USlateBlueprintLibrary.LocalToAbsolute(geo, UE4.FVector2D(0, 0)),
    size = UE4.USlateBlueprintLibrary.GetAbsoluteSize(geo)
  }
end

function UMG_PetHeadTemple_C:SetDragHover(bHover, bLong)
  self.isDragHover = bHover
  local isEmpty = not self.uiData or not self.uiData.gid or 0 == self.uiData.gid
  
  local function show(w)
    w:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  
  local function hide(w)
    w:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  
  if bLong then
    self:StopAnimation(self.Move_In)
    self:StopAnimation(self.Move_Out)
    if bHover then
      self:PlayAnimation(self.Move_In)
      if self.isSelect then
        self.Selected_Select:SetPath(BG2)
        show(self.Selected_Select)
        show(self.BgLong_Mask)
        show(self.Change)
      elseif not isEmpty then
        show(self.Selected_Normal)
        show(self.Bg_Mask)
        show(self.Change)
      else
        show(self.Selected_Empty)
        show(self.Put2)
      end
    else
      self:PlayAnimation(self.Move_Out)
      hide(self.BgLong_Mask)
      hide(self.Bg_Mask)
      hide(self.Change)
      hide(self.Selected_Empty)
      hide(self.Put2)
    end
  elseif bHover then
    self:StopAnimation(self.Move_In)
    self:StopAnimation(self.Move_Out)
    self:PlayAnimation(self.Move_In)
    show(self.imageNormal_Selected)
    if not isEmpty then
      show(self.HeadMask)
      show(self.headIcon_Mask)
      show(self.Change_1)
    else
      show(self.Put_2)
    end
  else
    hide(self.HeadMask)
    hide(self.headIcon_Mask)
    hide(self.Change_1)
    hide(self.Put_2)
    self:StopAnimation(self.Move_In)
    self:StopAnimation(self.Move_Out)
    self:PlayAnimation(self.Move_Out)
  end
end

function UMG_PetHeadTemple_C:SetPutVisibility(visibility, bLong)
  local isEmpty = not self.uiData or not self.uiData.gid or 0 == self.uiData.gid
  if not isEmpty then
    return
  end
  local widget = bLong and self.Put or self.Put0
  if widget then
    widget:SetVisibility(visibility)
  end
end

function UMG_PetHeadTemple_C:SetDragSelectState(bDrag)
  if not self.isSelect then
    return
  end
  if bDrag then
    self.imageSelect:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.imageNormal_Selected_White:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.imageNormal_Selected_White:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.imageSelect:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetHeadTemple_C:SetDragSelf(bDrag, bLong)
  self.isDragSelf = bDrag
  local SHOW = UE4.ESlateVisibility.SelfHitTestInvisible
  local HIDE = UE4.ESlateVisibility.Collapsed
  if bLong then
    self.Selected_Select:SetPath(BG1)
    if self.isSelect then
      self.BgLong_Mask:SetVisibility(bDrag and SHOW or HIDE)
      self.Selected_Select:SetVisibility(bDrag and SHOW or HIDE)
      self:StopAnimation(self.Move_In)
      self:StopAnimation(self.Move_Out)
      self:PlayAnimation(self.Move_In)
    else
      self.Bg_Mask:SetVisibility(bDrag and SHOW or HIDE)
    end
  else
    self.HeadMask:SetVisibility(bDrag and SHOW or HIDE)
    self.headIcon_Mask:SetVisibility(bDrag and SHOW or HIDE)
    if bDrag then
      self.Change_1:SetVisibility(HIDE)
    end
  end
end

return UMG_PetHeadTemple_C
