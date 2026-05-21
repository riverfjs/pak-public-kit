local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_CandidateTips_C = _G.NRCPanelBase:Extend("UMG_CandidateTips_C")

function UMG_CandidateTips_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
end

function UMG_CandidateTips_C:OnDestruct()
end

function UMG_CandidateTips_C:OnActive(SortType, OpenType)
  self:SetCommonPopUpInfo(self.PopUp3)
  self.OpenType = OpenType
  self.firstSelectItem = true
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_BAG_SEQUENCE)
  local cfgDatas = cfgTable:GetAllDatas()
  self:LoadAnimation(0)
  self.DefaultSort = {}
  for i, v in ipairs(cfgDatas) do
    local InitSelect = false
    if SortType == v.sequence_default then
      InitSelect = true
    end
    if OpenType == PetUIModuleEnum.OpenSortType.WareHouseFree then
      if v.sequence_default <= Enum.PetSequenceDefault.SEQUENCE_RARITY_DOWN and v.sequence_default ~= Enum.PetSequenceDefault.SEQUENCE_CHEER_POINT_DOWN then
        table.insert(self.DefaultSort, {
          data = v,
          InitSelect = InitSelect,
          panel = self
        })
      end
    elseif OpenType == PetUIModuleEnum.OpenSortType.WeeklyChallengeBattle then
      table.insert(self.DefaultSort, {
        data = v,
        InitSelect = InitSelect,
        panel = self
      })
    elseif OpenType == PetUIModuleEnum.OpenSortType.BattleRogue then
      if v.sequence_default ~= Enum.PetSequenceDefault.SEQUENCE_CHEER_POINT_DOWN then
        table.insert(self.DefaultSort, {
          data = v,
          InitSelect = InitSelect,
          panel = self
        })
      end
    elseif v.sequence_default ~= Enum.PetSequenceDefault.SEQUENCE_CHEER_POINT_DOWN then
      table.insert(self.DefaultSort, {
        data = v,
        InitSelect = InitSelect,
        panel = self
      })
    end
  end
  self.SortType = _G.Enum.PetSequenceDefault.SEQUENCE_LEVEL_DOWN
  self.CandidateListGrid:InitGridView(self.DefaultSort)
  for i = 1, #self.DefaultSort do
    if self.DefaultSort[i].InitSelect then
      self.CandidateListGrid:SelectItemByIndex(i - 1)
    end
  end
  self:OnAddEventListener()
end

function UMG_CandidateTips_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.CancelClosePanel
  CommonPopUpData.Btn_RightHandler = self.ApplySort
  CommonPopUpData.ClosePanelHandler = self.ClosePanel
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_CandidateTips_C:OnSortItemSelect(SortType)
  if self.firstSelectItem then
    self.firstSelectItem = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  end
  self.SortType = SortType
end

function UMG_CandidateTips_C:OnDeactive()
end

function UMG_CandidateTips_C:OnAddEventListener()
end

function UMG_CandidateTips_C:CancelClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  self:LoadAnimation(2)
end

function UMG_CandidateTips_C:ClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  self:LoadAnimation(2)
end

function UMG_CandidateTips_C:OnPcClose()
  if self:IsPlayingAnimation() then
    return
  end
  self:ClosePanel()
end

function UMG_CandidateTips_C:ApplySort()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  NRCModuleManager:DoCmd(PetUIModuleCmd.PetSort, self.SortType, self.OpenType)
  self:LoadAnimation(2)
end

function UMG_CandidateTips_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_CandidateTips_C
