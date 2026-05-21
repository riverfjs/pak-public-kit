local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleRogueModuleEvent = require("NewRoco.Modules.System.BattleRogue.BattleRogueModuleEvent")
local UMG_PetItemTemplate_C = Base:Extend("UMG_PetItemTemplate_C")

function UMG_PetItemTemplate_C:OnConstruct()
  self.PetList = nil
  self.SelectPet = nil
end

function UMG_PetItemTemplate_C:OnDestruct()
  self.TipsBtn.OnClicked:Remove(self, self.OnButtonClicked)
end

function UMG_PetItemTemplate_C:OnActive()
end

function UMG_PetItemTemplate_C:OpItem(opType)
  if 2 == opType.type then
    if self.PetList and self.PetList.PetData and self.PetList.PetData.gid ~= opType.curPetData.gid then
      self.Selected:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  elseif 1 == opType.type then
    if not self.PetList.PetData then
    elseif self.PetList.PetData.gid == opType.curPetData.gid then
      if opType.curPetData.partner_mark and opType.curPetData.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE and not self.PetList.PetData.IsMainTeam then
        self.Star:SetPath(PetUtils.GetPetCollectTagIcon(opType.curPetData.partner_mark))
        self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  elseif 3 == opType.type then
    self.NotOpenAnim = true
  elseif 4 == opType.type and self.PetList.PetData.gid == opType.curPetData.gid then
    self.PetList.PetData.PetBaseInfo = opType.curPetData
  end
end

function UMG_PetItemTemplate_C:OnItemUpdate(_Petdata, _datalist, index)
  self.index = index
  self.PetList = _Petdata
  self.parent = _Petdata.parent
  self.datalist = _datalist
  self.NotOpenAnim = false
  self:SetData()
  self.TipsBtn.OnClicked:Remove(self, self.OnButtonClicked)
  self.TipsBtn.OnClicked:Add(self, self.OnButtonClicked)
end

function UMG_PetItemTemplate_C:OnButtonClicked()
  if self.PetList.PetData.IsTeams or self.PetList.PetData.IsPvPTeam then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2092)
  elseif self.PetList.PetData.IsTravel then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petwarehousemain_5)
  elseif self.PetList.banFree and 1 == self.PetList.banFree then
    local text = _G.DataConfigManager:GetLocalizationConf("remove_dimo_tips").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, text)
  end
end

function UMG_PetItemTemplate_C:SetShowPetTeamIndex()
  if self.PetList and self.PetList.PetData.IsTeams then
    self.TeamMarker:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetItemTemplate_C:SetData()
  local petList = self.PetList
  self:ShowUpdate()
  self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetShowPetTeamIndex()
  if petList and petList.IsHasPet then
    if petList.IsbMultipleChoice then
      if petList.PetData.IsTeams or petList.PetData.IsTravel or petList.banFree and 1 == petList.banFree then
        if petList.PetData.IsTeams and petList.PetData.IsMainTeam then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(3)
        elseif petList.PetData.IsTeams then
          self.Text_Number:SetText(petList.PetData.TeamPos)
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(3)
        elseif petList.PetData.IsTravel then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(0)
        elseif petList.PetData.IsInBackPack then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(5)
        elseif petList.PetData.IsInHome then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(6)
        elseif petList.PetData.IsInGuard then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(7)
        else
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        self:SetClickable(false)
        self.TipsBtn:SetVisibility(UE4.ESlateVisibility.Visible)
        self.TheHoodBlack:SetVisibility(UE4.ESlateVisibility.Visible)
        self.ItemIconMask:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        self:SetClickable(true)
        self.TipsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.TheHoodBlack:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.ItemIconMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      if petList.PetData.IsOpenTeam then
        if petList.PetData.CanChangeTeam then
        end
        if petList.PetData.IsTeams then
          self.Text_Number:SetText(petList.PetData.TeamPos)
          if petList.PetData.IsMainTeam then
            self:PlayAnimation(self.loop, 0, 99999)
            self.TheHoodBlack:SetVisibility(UE4.ESlateVisibility.Visible)
            self.ItemIconMask:SetVisibility(UE4.ESlateVisibility.Visible)
            self.Selected:SetVisibility(UE4.ESlateVisibility.Visible)
            self.TextBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
          else
            self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.TextBG:SetVisibility(UE4.ESlateVisibility.Visible)
          end
        elseif petList.PetData.IsTravel then
          self:PlayAnimation(self.loop, 0, 0)
          self.State:SetVisibility(UE4.ESlateVisibility.Hidden)
          self.TheHoodBlack:SetVisibility(UE4.ESlateVisibility.Visible)
          self.ItemIconMask:SetVisibility(UE4.ESlateVisibility.Visible)
          self.Selected:SetVisibility(UE4.ESlateVisibility.Visible)
          self.TextBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
        else
          self.State:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
      else
        if petList.PetData.PetBaseInfo.partner_mark and petList.PetData.PetBaseInfo.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
          self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
          self.Star:SetPath(PetUtils.GetPetCollectTagIcon(petList.PetData.PetBaseInfo.partner_mark))
        end
        if petList.PetData.IsTeams and petList.PetData.IsMainTeam then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(3)
        elseif petList.PetData.IsTeams then
          self.Text_Number:SetText(petList.PetData.TeamPos)
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(3)
        elseif petList.PetData.IsTravel then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(0)
        elseif petList.PetData.IsInBackPack then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(5)
        elseif petList.PetData.IsInHome then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(6)
        elseif petList.PetData.IsInGuard then
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Visible)
          self.State:SetActiveWidgetIndex(7)
        else
          self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
      self:SetClickable(true)
      self.TipsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.TheHoodBlack:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ItemIconMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local icon = petList.PetData.PetIcon.icon
    if PetMutationUtils.GetMutationValue(petList.PetData.PetBaseInfo.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
      icon = petList.PetData.PetIcon.shiny_icon
    end
    self.ItemIcon:SetIconPathAndMaterial(petList.PetData.PetBaseInfo.base_conf_id, petList.PetData.PetBaseInfo.mutation_type, petList.PetData.PetBaseInfo.glass_info)
    self.ItemIconMask:SetPath(icon)
    self.NumText:SetText(petList.IconListInfo)
    if petList.PetData.IsOpenTeam then
      if petList.PetData.CanChangeTeam == false then
        self.TheHoodBlack:SetVisibility(UE4.ESlateVisibility.Visible)
        self.ItemIconMask:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        self.TheHoodBlack:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.ItemIconMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetItemTemplate_C:LoadSuccess(testInfo)
  self.NumText:SetText(testInfo)
end

function UMG_PetItemTemplate_C:ShowUpdate()
  self:PlayAnimation(self.normal)
  self:SetClickable(true)
  self.NumText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("908F85FF"))
  self.TipsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CheckCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TextBG_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TheHoodBlack:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemIconMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Visible)
  self.TextBG:SetVisibility(UE4.ESlateVisibility.Visible)
  self.NumText:SetVisibility(UE4.ESlateVisibility.Visible)
  self.TagIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetItemTemplate_C:SetSelect(_flag, bMultipleChoice, _IsFree)
  if _flag then
    self:StopAllAnimations()
    if not self.NotOpenAnim then
      self:PlayAnimation(self.select)
    else
      self.NotOpenAnim = false
      self:PlayAnimation(self.select)
    end
    if self.NumText then
      self.NumText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
    else
      Log.Error("UMG_PetItemTemplate_C,self.NumText Not Found")
    end
    self.TextBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Selected:SetVisibility(UE4.ESlateVisibility.Visible)
    self.TextBG_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if bMultipleChoice then
      if self.PetList.PetData.IsPvPTeam then
        self.CheckCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      elseif _IsFree then
        self:PlayAnimation(self.Tick_In)
        self.CheckCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        self:PlayAnimation(self.Tick_Out)
      end
    else
      self.CheckCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self:StopAllAnimations()
    if self.NumText then
      self.NumText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("908F85FF"))
    else
      Log.Error("UMG_PetItemTemplate_C,self.NumText Not Found")
    end
    self:PlayAnimation(self.Unselect)
    self.TextBG:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetItemTemplate_C:OnDespawn()
  if self._parent and self._parent._selectedItemIndex == self.index then
    self:StopAllAnimations()
    if self.NumText then
      self.NumText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("908F85FF"))
    end
    self:PlayAnimation(self.Unselect)
    self.TextBG:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetItemTemplate_C:OnItemSelected(_bSelected, _bScrollSelected)
  local canChangeSelect = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CanSelectWareHouseItem)
  if not canChangeSelect then
    return
  end
  if _bSelected then
    if _bScrollSelected then
      self:SetSelect(true)
      return
    end
    self.SelectPet = self.PetList
    if self.PetList.IsbMultipleChoice then
      if self.PetList.PetData.IsPvPTeam then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petwarehousemain_6)
      else
        local num = 1
        for i, v in ipairs(self.datalist) do
          if v.IsFree == true then
            num = num + 1
          end
        end
        if num > 30 and not self.PetList.IsFree then
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_remove_max)
          return
        end
        if self.PetList.IsFree then
          self.PetList.IsFree = false
          UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002006, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
        else
          self.PetList.IsFree = true
          UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002006, "UMG_PetItemTemplate_C:OnItemSelectedIsFree ")
        end
      end
    else
    end
    self:BroadcastMsg("OnItemSelected", self)
  elseif not self.PetList.IsbMultipleChoice and self.SelectPet and self.SelectPet.PetData.gid == self.PetList.PetData.gid and 4 == self.PetList.PetData.pet_status_flags then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetNewStateInfo, self.PetList)
  end
  self:SetSelect(_bSelected, self.PetList.IsbMultipleChoice, self.PetList.IsFree)
end

function UMG_PetItemTemplate_C:OnAnimationFinished(Animation)
  if Animation == self.Tick_Out then
    self.CheckCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Animation == self.select then
  end
end

function UMG_PetItemTemplate_C:OnDeactive()
end

return UMG_PetItemTemplate_C
