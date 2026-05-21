local MusicCollectionModuleEvent = require("NewRoco.Modules.System.MusicCollection.MusicCollectionModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local UMG_MusicCollectionPanel_C = _G.NRCPanelBase:Extend("UMG_MusicCollectionPanel_C")

function UMG_MusicCollectionPanel_C:OnActive(InMusicId, OpenType)
  self.InMusicId = InMusicId
  self.OpenType = OpenType
  self:OnAddEventListener()
  self.SoundSession = -1
  self.data = self.module:GetData("MusicCollectionModuleData")
  self.FirstOpenPanel = true
  self.FirstSelectTimer = 3
  self.SelectLoopTimer = 8
  self.UpdateTime = 0
  if self.Spine then
    self.Spine:ClearTracks()
    self.Spine:SetAnimation(0, "animation", true)
  end
  self:SetCommonTitle()
  self:RefreshInfo()
  self.MusicList:SetItemClickAble(false)
  self:PlayAnimation(self.In)
  self.UpdateSoundTime = 0
  self.fAudioPercent = 0
  self:BindInputAction()
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
end

function UMG_MusicCollectionPanel_C:RefreshInfo()
  local MusicList = self.data.MusicList
  self.TabList:InitGridView(MusicList)
  self.OpenMusicIndex = 0
  local TypeIndex = 0
  for i = 1, #MusicList do
    local List = MusicList[i].List
    local Find = false
    for j = 1, #List do
      if List[j].id == self.InMusicId then
        TypeIndex = i - 1
        self.OpenMusicIndex = j - 1
        self.FirstMusicConf = _G.DataConfigManager:GetMusicConf(List[j].id)
        if List[j].ApplyId then
          self.FirstApplyConf = _G.DataConfigManager:GetMusicApplyListConf(List[j].ApplyId)
        end
        Find = true
        break
      end
    end
    if Find then
      break
    end
  end
  self.TabList:SelectItemByIndex(TypeIndex)
end

function UMG_MusicCollectionPanel_C:RefreshSettingInfo(MusicApplyInfo)
  local num = self.MusicList:GetItemCount()
  for i = 1, num do
    local item = self.MusicList:GetItemByIndex(i - 1)
    item:SetApplyRefreshInfo(MusicApplyInfo)
  end
  if MusicApplyInfo.apply_list_id then
    local ApplyCf = _G.DataConfigManager:GetMusicApplyListConf(MusicApplyInfo.apply_list_id)
    if ApplyCf then
      self.UMG_Btn7.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_Btn7.CornerMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_Btn7:SetTitleTextAndIcon(nil, nil, nil, nil, string.format(LuaText.music_set_interface_desc, ApplyCf.list_name))
      self.ApplyPanelId = ApplyCf.id
    else
      self.UMG_Btn7.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_Btn7.CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ApplyPanelId = nil
    end
  else
    self.UMG_Btn7.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_Btn7.CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ApplyPanelId = nil
  end
end

function UMG_MusicCollectionPanel_C:RefreshTabList()
  local num = self.TabList:GetItemCount()
  for i = 1, num do
    local item = self.TabList:GetItemByIndex(i - 1)
    for _, v in pairs(self.data.MusicList) do
      if v.Type == item.data.Type then
        item.data = v
      end
    end
  end
end

function UMG_MusicCollectionPanel_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_MusicCollectionPanel_C:OnDeactive()
  self:StopSound()
  self:UnBindInputAction()
end

function UMG_MusicCollectionPanel_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_MenuClose")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseMenu")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "OnPcClose")
end

function UMG_MusicCollectionPanel_C:UnBindInputAction()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseMenu")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_MenuClose")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_MusicCollectionPanel_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:ClosePanel()
end

function UMG_MusicCollectionPanel_C:OnTick(deltaTime)
  self.Spine:Tick(deltaTime, false)
  if not (self.UpdateTime and self.SelectTypeIndex) or not self.UpdateSoundTime then
    return
  end
  self.UpdateSoundTime = self.UpdateSoundTime + deltaTime
  if self.UpdateSoundTime >= 0.2 and self.SoundSession and -1 ~= self.SoundSession then
    self.UpdateSoundTime = 0
    local PlayPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
    self:SetTimePosText(math.floor(PlayPositionMs / 1000))
  end
end

function UMG_MusicCollectionPanel_C:OnSelectedTabIndex(index, typeName, List)
  self.PlayAudioSelectedItem = false
  self.MusicList:InitGridView(List)
  self.SelectTypeIndex = index
  self.FirstSelect = true
  self.UpdateTime = 0
  if self.OpenType == nil then
    self:RefreshCommonTitle(index)
  end
  local ItemIndex = 0
  if not self.FirstOpenPanel then
    _G.NRCAudioManager:PlaySound2DAuto(1001, "UMG_LevelMain_C:OnSelecedTabIndex")
    self.MusicList:SelectItemByIndex(0)
  else
    if self.OpenMusicIndex then
      self.MusicList:SelectItemByIndex(self.OpenMusicIndex)
      ItemIndex = self.OpenMusicIndex
    end
    self.FirstOpenPanel = false
  end
  self.ScrollBox_84:ScrollWidgetIntoView(self.MusicList:GetItemByIndex(ItemIndex), false, UE4.EDescendantScrollDestination.Center)
end

function UMG_MusicCollectionPanel_C:RefreshCommonTitle(index)
  if 1 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif 2 == index and self.titleConf and self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
  end
end

function UMG_MusicCollectionPanel_C:OnSelectedItemIndex(MusicConf, ApplyConf)
  if self.PlayAudioSelectedItem then
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_MagicManual_Task_Tads_C:SelectTaskType")
  else
    self.PlayAudioSelectedItem = true
  end
  local MusicCf = MusicConf
  local ApplyCf = ApplyConf
  if not MusicConf then
    MusicCf = self.FirstMusicConf
    ApplyCf = self.FirstApplyConf
  end
  if self.MusicId == MusicCf.id then
    return
  end
  self.MusicId = MusicCf.id
  self.MusicEventName = MusicCf.EventName
  self.MusicConfApplyList = MusicCf.apply_list
  self.MusicalName:SetText(MusicCf.music_name)
  if self.OpenType == "MagicMessage" then
    if self.InMusicId then
      if self.MusicId == self.InMusicId then
        self.BtnSwitcher:SetActiveWidgetIndex(3)
      else
        self.BtnSwitcher:SetActiveWidgetIndex(2)
      end
    else
      self.BtnSwitcher:SetActiveWidgetIndex(1)
    end
  else
    self.BtnSwitcher:SetActiveWidgetIndex(0)
    self.UMG_Btn7:SetClickAble(true)
    self.UMG_Btn7:PlayAnimation(self.UMG_Btn7.open)
    self.UMG_Btn7:SetBtnText(LuaText.music_set_btn_desc)
    if ApplyCf then
      self.UMG_Btn7.TitleCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_Btn7.CornerMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_Btn7:SetTitleTextAndIcon(nil, nil, nil, nil, string.format(LuaText.music_set_interface_desc, ApplyCf.list_name))
      self.ApplyPanelId = ApplyCf.id
    else
      self.UMG_Btn7.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_Btn7.CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ApplyPanelId = nil
    end
  end
  self:CancelDelay()
  self.SoundTime = _G.NRCAudioManager:GetMaxTimeFromEventName(MusicCf.EventName)
  self:SetTimeMaxText(self.SoundTime)
  self:StopSound()
  self.SoundSession = _G.NRCAudioManager:PlaySound2DByEventNameAuto(MusicCf.EventName, "UMG_MusicCollectionPanel_C")
  local PlayPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
  self:SetTimePosText(math.floor(PlayPositionMs / 1000))
end

function UMG_MusicCollectionPanel_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  if self.OpenType == "MagicMessage" then
    self.Title1:SetSubtitle(LuaText.mark_music_share_title)
  else
    self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
end

function UMG_MusicCollectionPanel_C:Pause()
  if self.SoundSession and self.SoundSession > 0 and self.SoundSession and -1 ~= self.SoundSession then
    _G.NRCAudioManager:ReleaseSession(self.SoundSession, true, "UMG_MusicCollectionPanel_C")
    self.SoundSession = -1
    self.UpdateSoundTime = 0
  end
end

function UMG_MusicCollectionPanel_C:Play()
  if self.MusicEventName then
    self.SoundTime = _G.NRCAudioManager:GetMaxTimeFromEventName(self.MusicEventName)
    self:SetTimeMaxText(self.SoundTime)
    self.SoundSession = _G.NRCAudioManager:PlaySound2DByEventNameAuto(self.MusicEventName, "UMG_MusicCollectionPanel_C")
    local PlayPositionMs = _G.NRCAudioManager:GetPlayPositionInMs(self.SoundSession)
    self:SetTimePosText(math.floor(PlayPositionMs / 1000))
  end
end

function UMG_MusicCollectionPanel_C:SetTimeMaxText(second)
  local minuteString, secondString = self:GetTimeString(second)
  self.Time2:SetText("/" .. minuteString .. ":" .. secondString)
end

function UMG_MusicCollectionPanel_C:SetTimePosText(second)
  local minuteString, secondString = self:GetTimeString(second)
  self.Time1:SetText(minuteString .. ":" .. secondString)
end

function UMG_MusicCollectionPanel_C:GetTimeString(second)
  local minutes = 0
  local seconds = 0
  local minuteString = ""
  local secondString = ""
  if second > 59 then
    minutes = math.floor(second / 60)
    seconds = math.floor(second - minutes * 60)
  else
    seconds = math.floor(second)
  end
  if minutes < 10 then
    minuteString = "0" .. tostring(minutes)
  else
    minuteString = tostring(minutes)
  end
  if seconds < 10 then
    secondString = "0" .. tostring(seconds)
  else
    secondString = tostring(seconds)
  end
  return minuteString, secondString
end

function UMG_MusicCollectionPanel_C:StopSound()
  if self.SoundSession and -1 ~= self.SoundSession then
    _G.NRCAudioManager:ReleaseSession(self.SoundSession, true, "UMG_MusicCollectionPanel_C")
    self.SoundSession = -1
  end
end

function UMG_MusicCollectionPanel_C:OnEnterBattle()
  self:StopSound()
end

function UMG_MusicCollectionPanel_C:OnLeaveBattle()
  self:Play()
end

function UMG_MusicCollectionPanel_C:OnAnimFinished(anim)
  if anim == self.In then
    self.MusicList:SetItemClickAble(true)
  end
end

function UMG_MusicCollectionPanel_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.ClosePanel)
  self:AddButtonListener(self.UMG_Btn7.btnLevelUp, self.OpenMusicSettingPanel)
  self:RegisterEvent(self, MusicCollectionModuleEvent.ChangeTabType, self.OnSelectedTabIndex)
  self:RegisterEvent(self, MusicCollectionModuleEvent.ChangeItem, self.OnSelectedItemIndex)
  self:AddButtonListener(self.Btn_Select.btnLevelUp, self.OnClickSelectMusic)
  self:AddButtonListener(self.Btn_Replace.btnLevelUp, self.OnClickSelectMusic)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleEvent.EnterBattle, self.OnEnterBattle)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
end

function UMG_MusicCollectionPanel_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, MusicCollectionModuleEvent.ChangeTabType)
  self:UnRegisterEvent(self, MusicCollectionModuleEvent.ChangeItem)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.EnterBattle, self.OnEnterBattle)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.LeaveBattle, self.OnLeaveBattle)
end

function UMG_MusicCollectionPanel_C:OpenMusicSettingPanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_MagicManual_Task_Tads_C:SelectTaskType")
  _G.NRCModuleManager:DoCmd(MusicCollectionModuleCmd.OnOpenMusicSettingPanel, self.MusicId, self.MusicConfApplyList, self.ApplyPanelId)
end

function UMG_MusicCollectionPanel_C:ClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_LevelMain_C:OnSelecedTabIndex")
  self:OnClose()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
end

function UMG_MusicCollectionPanel_C:OnClickSelectMusic()
  if self.OpenType == "MagicMessage" then
    _G.NRCEventCenter:DispatchEvent(MusicCollectionModuleEvent.SelectedMusicEvent, self.MusicId)
  end
  self:ClosePanel()
end

return UMG_MusicCollectionPanel_C
