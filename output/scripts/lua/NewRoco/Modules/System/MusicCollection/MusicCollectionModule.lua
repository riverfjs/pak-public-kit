local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local MusicCollectionUtils = require("NewRoco.Modules.System.MusicCollection.MusicCollectionUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local TipsDisplayController = require("NewRoco.Modules.System.TipsModule.TipsDisplayController")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local MusicCollectionModule = NRCModuleBase:Extend("MusicCollectionModule")

function MusicCollectionModule:OnConstruct()
  _G.MusicCollectionModuleCmd = reload("NewRoco.Modules.System.MusicCollection.MusicCollectionModuleCmd")
  self.data = self:SetData("MusicCollectionModuleData", "NewRoco.Modules.System.MusicCollection.MusicCollectionModuleData")
  self:RegPanel("MusicCollectTips", "UMG_CollectTips", Enum.UILayerType.UI_LAYER_POPUP, nil, true, true):SetEnableTouchMask(false)
  self:RegPanel("MusicSetting", "UMG_MusicSetting", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MusicCollectionPanel", "UMG_MusicCollectionPanel", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil, "Out")
  self.getMusicCollectUnlockTipsController = TipsDisplayController(TipEnum.TipObjectType.MusicCollectUnlockTips, self, self.OnPlayTips)
  self.IsWaitChangeRsp = false
  self.IsPauseUiBgm = false
  _G.NRCEventCenter:RegisterEvent("MusicCollectionModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnected)
  _G.NRCEventCenter:RegisterEvent("MusicCollectionModule", self, BattleEvent.LeaveBattle, self.ResumeUiBgm)
  _G.NRCEventCenter:RegisterEvent("MusicCollectionModule", self, BattleEvent.EnterBattle, self.PauseUiBgm)
end

function MusicCollectionModule:OnActive()
end

function MusicCollectionModule:IsPauseUiBgm()
  Log.Debug(self.IsPauseUiBgm, "MusicCollectionModule:IsPauseUiBgm")
  return self.IsPauseUiBgm
end

function MusicCollectionModule:PauseUiBgm()
  Log.Debug("MusicCollectionModule:PauseUiBgm")
  self.IsPauseUiBgm = true
  if _G.BattleManager and _G.BattleManager:IsInBattle() and _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel.PanelMusicList and _G.DataModelMgr.PlayerDataModel.playerInfo then
    local PanelMusicList = _G.DataModelMgr.PlayerDataModel.PanelMusicList
    if PanelMusicList and #PanelMusicList > 0 then
      _G.NRCAudioManager:BatchSetState("UI_Music;None")
    end
  end
end

function MusicCollectionModule:ResumeUiBgm()
  Log.Debug("MusicCollectionModule:ResumeUiBgm")
  self.IsPauseUiBgm = false
  if _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel.PanelMusicList and _G.DataModelMgr.PlayerDataModel.playerInfo then
    local PanelMusicList = _G.DataModelMgr.PlayerDataModel.PanelMusicList
    if PanelMusicList and #PanelMusicList > 0 then
      local applyType = PanelMusicList[#PanelMusicList]
      local StateGroup = MusicCollectionUtils.GetBgmStateGroupByApplyType(Enum.MusicApplyType.MAT_UI, applyType)
      if StateGroup then
        _G.NRCAudioManager:BatchSetState(StateGroup)
      end
    end
  end
end

function MusicCollectionModule:OnReconnected()
  if self.IsWaitChangeRsp then
    self.IsWaitChangeRsp = false
  end
  _G.DataModelMgr.PlayerDataModel:ClearPanelMusicList()
  if self:HasPanel("MusicCollectionPanel") then
    self:ClosePanel("MusicCollectionPanel")
  end
end

function MusicCollectionModule:OnCmdMusicUPanelPause()
  if self:HasPanel("MusicCollectionPanel") then
    local panel = self:GetPanel("MusicCollectionPanel")
    panel:Pause()
  end
end

function MusicCollectionModule:OnCmdMusicUPanelPlay()
  if self:HasPanel("MusicCollectionPanel") then
    local panel = self:GetPanel("MusicCollectionPanel")
    panel:Play()
  end
end

function MusicCollectionModule:CmdSetMusicToPanel(MusicId, ApplyId)
  if self.IsWaitChangeRsp then
    return
  end
  self.IsWaitChangeRsp = true
  self.changeApplyInfo = _G.ProtoMessage:newMusicApplyInfo()
  self.changeApplyInfo.music_id = MusicId
  self.changeApplyInfo.apply_list_id = ApplyId
  if ApplyId then
    self:SendZoneApplyMusicReq(self.changeApplyInfo)
  else
    self:SendZoneUnsetMusicReq(MusicId)
  end
end

function MusicCollectionModule:SendZoneUnsetMusicReq(music_id)
  if not music_id or music_id <= 0 then
    Log.Error("MusicCollectionModule:SendZoneUnsetMusicReq music_id is nil")
    return
  end
  local req = _G.ProtoMessage:newZoneUnsetMusicReq()
  req.music_id = music_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UNSET_MUSIC_REQ, req, self, self.OnZoneApplyMusicRsp)
end

function MusicCollectionModule:SendZoneApplyMusicReq(MusicApplyInfo)
  if not (MusicApplyInfo and MusicApplyInfo.music_id) or 0 == MusicApplyInfo.music_id then
    Log.Error("MusicCollectionModule:SendZoneApplyMusicReq music_id is nil")
    return
  end
  local req = _G.ProtoMessage:newZoneApplyMusicReq()
  req.apply_info = MusicApplyInfo
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_APPLY_MUSIC_REQ, req, self, self.OnZoneApplyMusicRsp)
end

function MusicCollectionModule:OnZoneApplyMusicRsp(rsp)
  if self.IsWaitChangeRsp then
    self.IsWaitChangeRsp = false
  end
  if 0 == rsp.ret_info.ret_code then
    self:RefreshMusicData()
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

local function SortMusicList(a, b)
  if a.ApplyId and b.ApplyId then
    return a.id < b.id
  elseif not a.ApplyId and not b.ApplyId then
    return a.id < b.id
  elseif a.ApplyId then
    return true
  elseif b.ApplyId then
    return false
  end
end

function MusicCollectionModule:RefreshMusicData()
  local MusicId = self.changeApplyInfo.music_id
  local ApplyId = self.changeApplyInfo.apply_list_id
  local Panel = self:GetPanel("MusicCollectionPanel")
  Panel:RefreshSettingInfo(self.changeApplyInfo)
  _G.DataModelMgr.PlayerDataModel:SetPlayerMusicApplyInfo(self.changeApplyInfo)
  self:OnSetMusicListData()
  Panel:RefreshTabList()
  if ApplyId then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.music_set_tips)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.music_set_cancel_succeed)
  end
  self.changeApplyInfo = nil
end

function MusicCollectionModule:OnSetMusicListData()
  table.clear(self.data.MusicList)
  self.data.MusicList = {}
  local MusicTypeList = _G.DataConfigManager:GetAllByName("MUSIC_TYPE_CONF")
  for i = 1, #MusicTypeList do
    local List = {}
    local playerMusicInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerMusicInfo()
    if playerMusicInfo.music_id_list then
      for j, v in pairs(playerMusicInfo.music_id_list) do
        local MusicConf = _G.DataConfigManager:GetMusicConf(v)
        if MusicTypeList[i].music_type == MusicConf.music_type then
          local ApplyId
          if playerMusicInfo.apply_list and #playerMusicInfo.apply_list > 0 then
            for k, ApplyInfo in pairs(playerMusicInfo.apply_list) do
              if ApplyInfo.music_id == MusicConf.id then
                ApplyId = ApplyInfo.apply_list_id
                break
              end
            end
          end
          table.insert(List, {
            id = MusicConf.id,
            ApplyId = ApplyId
          })
        end
      end
    end
    if self.OpenType == "MagicMessage" then
      local freeMusicList = _G.DataConfigManager:GetAllByName("MUSIC_FREEMIUM_CONF")
      for j = 1, #freeMusicList do
        local freeMusicConf = freeMusicList[j]
        local MusicConf = _G.DataConfigManager:GetMusicConf(freeMusicConf.music_id)
        if MusicTypeList[i].music_type == MusicConf.music_type then
          local bHas = false
          if playerMusicInfo.music_id_list then
            for k = 1, #playerMusicInfo.music_id_list do
              if playerMusicInfo.music_id_list[k] == freeMusicConf.music_id then
                bHas = true
                break
              end
            end
          end
          if not bHas then
            local startTime = ActivityUtils.ToTimestamp(freeMusicConf.start_time)
            local endTime = ActivityUtils.ToTimestamp(freeMusicConf.end_time)
            local currentTime = _G.ZoneServer:GetServerTime() / 1000
            if startTime <= currentTime and endTime > currentTime then
              table.insert(List, {
                id = MusicConf.id,
                ApplyId = nil
              })
            end
          end
        end
      end
      if MusicTypeList[i].music_type == Enum.MusicType.MT_MARK_EXCLUSIVE then
        local allMusicList = _G.DataConfigManager:GetAllByName("MUSIC_CONF")
        for _, v in pairs(allMusicList) do
          if v.music_type == Enum.MusicType.MT_MARK_EXCLUSIVE then
            table.insert(List, {
              id = v.id,
              ApplyId = nil
            })
          end
        end
      end
    end
    if #List > 0 then
      table.sort(List, SortMusicList)
      local MusicType = {
        Type = MusicTypeList[i].music_type_name,
        List = List,
        TypeEnum = MusicTypeList[i].music_type
      }
      table.insert(self.data.MusicList, MusicType)
    end
  end
end

function MusicCollectionModule:OnCmdOpenMainPanel(MusicId, OpenType)
  local canOpen = false
  if "MagicMessage" == OpenType then
    local freeMusicList = _G.DataConfigManager:GetAllByName("MUSIC_FREEMIUM_CONF")
    for i = 1, #freeMusicList do
      local freeMusicConf = freeMusicList[i]
      local MusicConf = _G.DataConfigManager:GetMusicConf(freeMusicConf.music_id)
      if MusicConf then
        local startTime = ActivityUtils.ToTimestamp(freeMusicConf.start_time)
        local endTime = ActivityUtils.ToTimestamp(freeMusicConf.end_time)
        local currentTime = _G.ZoneServer:GetServerTime() / 1000
        if startTime <= currentTime and endTime > currentTime then
          canOpen = true
          break
        end
      end
    end
  else
    canOpen = not _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MUSIC, true)
  end
  if canOpen then
    self.OpenType = OpenType
    self:OnSetMusicListData()
    self:OpenPanel("MusicCollectionPanel", MusicId, OpenType)
  end
end

function MusicCollectionModule:EnableMainPanel()
  local panel = self:GetPanel("MusicCollectionPanel")
  if panel then
    panel:EnableAndShouldBanWorldRendering()
  end
end

function MusicCollectionModule:PreLoadMainPanel()
  self:PreLoadPanel("MusicCollectionPanel", 10)
end

function MusicCollectionModule:OnCmdMusicSettingPanel(MusicId, ApplyList, PanelId)
  self:OpenPanel("MusicSetting", MusicId, ApplyList, PanelId)
end

function MusicCollectionModule:OnRelogin()
end

function MusicCollectionModule:OnPlayTips()
  if self:HasPanel("MusicCollectTips") then
    self:ClosePanel("MusicCollectTips")
  end
  self:OpenPanel("MusicCollectTips")
end

function MusicCollectionModule:OnMusicUnlockNotify(MusicId)
  Log.Debug(MusicId, "MusicCollectionModule:OnMusicUnlockNotify")
  local id = MusicId or 1002
  local uiData = {}
  uiData.UnlockId = id
  local MusicConf = _G.DataConfigManager:GetMusicConf(id)
  if MusicConf.is_born_unlock and 1 == MusicConf.is_born_unlock then
    return
  end
  uiData.Name = MusicConf.music_name
  uiData.TypeName = _G.DataConfigManager:GetMusicTypeConf(MusicConf.music_type).music_type_name
  uiData.countdown = _G.DataConfigManager:GetGlobalConfig("main_music_tips_showtime").num or 5
  uiData.countdownStr = "\231\130\185\229\135\187\230\159\165\231\156\139\239\188\136%d\231\167\146\239\188\137"
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.AddTip, TipObject.CreateMusicCollectUnlockTips(uiData))
end

function MusicCollectionModule:OnDeactive()
end

function MusicCollectionModule:OnDestruct()
end

function MusicCollectionModule:RegPanel(name, path, layer, customDisableRendering, disablePcEsc, disableLoadBlock, closeAnimName)
  local Data = _G.NRCPanelRegisterData()
  Data.panelName = name
  Data.panelPath = string.format("/Game/NewRoco/Modules/System/MusicCollection/Res/%s", path)
  Data.panelLayer = layer
  Data.customDisableRendering = customDisableRendering or false
  Data.enablePcEsc = not disablePcEsc
  Data.disableLoadBlock = disableLoadBlock
  Data.closeAnimName = closeAnimName
  self:RegisterPanel(Data)
  return Data
end

return MusicCollectionModule
