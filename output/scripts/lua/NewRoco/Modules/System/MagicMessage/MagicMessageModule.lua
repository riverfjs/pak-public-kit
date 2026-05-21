local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MagicMessageUtils = require("NewRoco.Modules.System.MagicMessage.MagicMessageUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local TraceType = {
  Message = 1,
  Flower = 2,
  Video = 4
}
local TipsType = {
  Message = 1,
  LifeFlower = 2,
  EnergeFlower = 3
}
local ShowTipCD = _G.DataConfigManager:GetGlobalConfig("MARK_MAGIC_FLOWER_TIPS_CD")
local MagicMessageModule = NRCModuleBase:Extend("MagicMessageModule")

function MagicMessageModule:OnConstruct()
  _G.MagicMessageModuleCmd = reload("NewRoco.Modules.System.MagicMessage.MagicMessageModuleCmd")
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_FEED_INFO_NOTIFY, self.OnReceiveFeedNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_TEXT_NOTIFY, self.OnReceiveTextNotify)
  self.bDrawDebugFlag = false
  _G.UpdateManager:Register(self)
  self.FeedToDelete = {}
  self.FeedsByGrid = {}
  self.StoryFlag = false
  self.SceneFlag = true
  self.IsFullHp = true
  self.IsFullEnergy = true
  self.uinToName = {}
  self.BeforeEnsure = {}
  self.TraceOnWater = _G.MakeWeakTable()
  self.Timestamp = {}
  self.VideoUploading = {}
  local Info = _G.DataModelMgr.PlayerDataModel:GetFeedInfo()
  if Info then
    self:OnReceiveFeedNotify(Info)
  end
end

function MagicMessageModule:OnActive()
  local storyFlags = _G.DataModelMgr.PlayerDataModel:GetStoryFlags()
  if storyFlags then
    for _, storyFlag in pairs(storyFlags) do
      local NpcStory = _G.DataConfigManager:GetFunctionStoryFlagConf(storyFlag, true)
      if NpcStory and NpcStory.story_flag_action_type and NpcStory.story_flag_action_type == _G.Enum.StoryFlagAction.SFA_MARK_VISABLE_CLOSE then
        self.StoryFlag = true
        break
      end
    end
  end
  self.Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:CheckPlayerHPFull()
  self:CheckPetEnergyFull()
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, self.OnStoryFlagAdd)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_REMOVED, self.OnStoryFlagRemove)
  _G.NRCEventCenter:RegisterEvent("MagicMessageModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:RegisterEvent("MagicMessageModule", self, _G.NRCGlobalEvent.Water_Move_For_Trace, self.OnWaterMove)
  _G.NRCEventCenter:RegisterEvent("MagicMessageModule", self, _G.NRCGlobalEvent.Water_Stop_Move_For_Trace, self.OnWaterStopMove)
  _G.NRCEventCenter:RegisterEvent("MagicMessageModule", self, _G.TaskModuleEvent.BattleStart, self.OnEnterBattle)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.CheckPetEnergyFull)
  _G.NRCEventCenter:RegisterEvent("MagicMessageModule", self, MagicReplayModuleEvent.UpdateUploadFileList, self.OnReceiveVideoEvent)
end

function MagicMessageModule:OnEnterBattle()
  if next(self.BeforeEnsure) then
    for _, npc in pairs(self.BeforeEnsure) do
      if npc then
        MagicMessageUtils.DeleteLocalNpc(npc)
      end
    end
  end
  self.BeforeEnsure = {}
end

function MagicMessageModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, self.OnStoryFlagAdd)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_REMOVED, self.OnStoryFlagRemove)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.Water_Move_For_Trace, self.OnWaterMove)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.Water_Stop_Move_For_Trace, self.OnWaterStopMove)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.TaskModuleEvent.BattleStart, self.OnEnterBattle)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.CheckPetEnergyFull)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.UpdateUploadFileList, self.OnReceiveVideoEvent)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_FEED_INFO_NOTIFY, self.OnReceiveFeedNotify)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_TEXT_NOTIFY, self.OnReceiveTextNotify)
end

function MagicMessageModule:GetPlayerHpFull()
  return self.IsFullHp
end

function MagicMessageModule:GetPetEnergyFull()
  return self.IsFullEnergy
end

function MagicMessageModule:CheckPlayerHPFull()
  local preHpFull = self.IsFullHp
  local roleHpComp = self.Player.roleHPComponent
  if not roleHpComp then
    self.IsFullHp = true
  end
  local _cachedHp = roleHpComp:GetRoleHP()
  local _cachedMaxHp = roleHpComp:GetMaxVRoleHP()
  if _cachedHp and _cachedMaxHp and _cachedHp < _cachedMaxHp then
    self.IsFullHp = false
  else
    self.IsFullHp = true
  end
  if preHpFull ~= self.IsFullHp then
    self.Player:SendEvent(PlayerModuleEvent.ON_ROLE_HP_CHANGE_FOR_TRACE_RAW)
  end
end

function MagicMessageModule:CheckPetEnergyFull()
  local preEnergyFull = self.IsFullEnergy
  local flag = false
  local PetTeam = _G.DataModelMgr.PlayerDataModel:GetPlayerMainPetTeam()
  if not PetTeam or not PetTeam.pet_infos then
    self.IsFullEnergy = true
  else
    for _, petInfo in pairs(PetTeam.pet_infos) do
      if petInfo and petInfo.pet_gid then
        local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petInfo.pet_gid)
        if PetData then
          local petEnergy = PetData.energy
          local MaxPetEnergy
          if PetData.base_conf_id then
            MaxPetEnergy = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
          end
          if not MaxPetEnergy then
            self.IsFullEnergy = true
            break
          end
          local num = MaxPetEnergy.max_energy
          if petEnergy and num and petEnergy < num then
            self.IsFullEnergy = false
            flag = true
            break
          end
        end
      end
    end
  end
  if not flag then
    self.IsFullEnergy = true
  end
  if preEnergyFull ~= self.IsFullEnergy then
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetEnergyChangeForTrace)
  end
end

function MagicMessageModule:OnWaterMove()
  for _, Feed in pairs(self.TraceOnWater) do
    if Feed then
      if Feed.MessageNpc then
        MagicMessageUtils.DeleteLocalNpc(self.FeedsByGrid[Feed.MessageInfo.grid_id].MessageList[Feed.MessageInfo.feed_id].MessageNpc)
      elseif Feed.FlowerInfo then
        MagicMessageUtils.DeleteLocalNpc(self.FeedsByGrid[Feed.FlowerInfo.grid_id].FlowerList[Feed.FlowerInfo.feed_id].FlowerNpc)
      end
    end
  end
end

function MagicMessageModule:OnWaterStopMove()
  for _, Feed in pairs(self.TraceOnWater) do
    if Feed then
      if Feed.MessageInfo then
        local WaterInfo = MagicMessageUtils.GetWaterInfo(Feed.MessageInfo.create_pos)
        local WaterHeight
        if WaterInfo then
          WaterHeight = WaterInfo.position.Z
        end
        local LandInfo = MagicMessageUtils.GetLandInfo(Feed.MessageInfo.create_pos)
        local LandHeight
        if LandInfo then
          LandHeight = LandInfo.position.Z
        end
        if WaterHeight and LandHeight and WaterHeight > LandHeight then
          self:CreateFinalNpc(Feed.MessageInfo, Feed.MessageInfo.grid_id, TraceType.Message)
        else
          self.FeedsByGrid[Feed.MessageInfo.grid_id].MessageList[Feed.MessageInfo.feed_id] = nil
          self.TraceOnWater[Feed.MessageInfo.feed_id] = nil
        end
      elseif Feed.FlowerInfo then
        self.TraceOnWater[Feed.FlowerInfo.feed_id] = nil
        self:CreateFinalNpc(Feed.FlowerInfo, Feed.FlowerInfo.grid_id, TraceType.Flower)
      end
    end
  end
end

function MagicMessageModule:OnStoryFlagAdd(flag, bIsHomeOwner)
  if bIsHomeOwner then
    return
  end
  local NpcStory = _G.DataConfigManager:GetFunctionStoryFlagConf(flag, true)
  if NpcStory and NpcStory.story_flag_action_type and NpcStory.story_flag_action_type == _G.Enum.StoryFlagAction.SFA_MARK_VISABLE_CLOSE then
    self.StoryFlag = true
    for _, Grid in pairs(self.FeedsByGrid) do
      for _, Message in pairs(Grid.MessageList) do
        if Message and Message.MessageNpc then
          MagicMessageUtils.DeleteLocalNpc(Message.MessageNpc)
          Message.MessageNpc = nil
        end
      end
      for _, Flower in pairs(Grid.FlowerList) do
        if Flower and Flower.FlowerNpc then
          MagicMessageUtils.DeleteLocalNpc(Flower.FlowerNpc)
          Flower.FlowerNpc = nil
        end
      end
      for _, Video in pairs(Grid.VideoList) do
        if Video and Video.VideoInfo then
          MagicMessageUtils.DeleteLocalNpc(Video.VideoInfo)
          Video.VideoNpc = nil
        end
      end
    end
  end
end

function MagicMessageModule:OnStoryFlagRemove(flag, bIsHomeOwner)
  if bIsHomeOwner then
    return
  end
  local NpcStory = _G.DataConfigManager:GetFunctionStoryFlagConf(flag, true)
  if NpcStory and NpcStory.story_flag_action_type and NpcStory.story_flag_action_type == _G.Enum.StoryFlagAction.SFA_MARK_VISABLE_CLOSE then
    self.StoryFlag = false
    for _, Grid in pairs(self.FeedsByGrid) do
      for _, Message in pairs(Grid.MessageList) do
        if Message and Message.MessageInfo and not Message.MessageNpc then
          self:CreateFinalNpc(Message.MessageInfo, Message.MessageInfo.grid_id, TraceType.Message)
        end
      end
      for _, Flower in pairs(Grid.FlowerList) do
        if Flower and Flower.FlowerInfo and not Flower.FlowerNpc then
          self:CreateFinalNpc(Flower.FlowerInfo, Flower.FlowerInfo.grid_id, TraceType.Flower)
        end
      end
      for _, Video in pairs(Grid.VideoList) do
        if Video and Video.VideoInfo and not Video.VideoNpc then
          self:CreateFinalNpc(Video.VideoInfo, Video.VideoInfo.grid_id, TraceType.Video)
        end
      end
    end
  end
end

function MagicMessageModule:OnVisitPlayerInfoSyncNotify(rsp)
  if rsp.online_visit_owner then
    for _, Grid in pairs(self.FeedsByGrid) do
      if Grid then
        for _, Message in pairs(Grid.MessageList) do
          if Message and Message.MessageInfo then
            self:DeleteNpcWithoutSkill(Message.MessageInfo, TraceType.Message)
          end
        end
        for _, Flower in pairs(Grid.FlowerList) do
          if Flower and Flower.FlowerInfo then
            self:DeleteNpcWithoutSkill(Flower.FlowerInfo, TraceType.Flower)
          end
        end
        for _, Video in pairs(Grid.VideoList) do
          if Video and Video.VideoInfo then
            self:DeleteNpcWithoutSkill(Video.VideoInfo, TraceType.Video)
          end
        end
      end
    end
    self.FeedsByGrid = {}
  end
end

function MagicMessageModule:CheckShieldTip(timeName)
  local Ban, Msg = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_MAGIC_FLOWER_NOT_RESPON, false, false)
  if Ban then
    Log.Debug("\228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170\233\173\148\230\179\149Tips")
    return true
  end
  if _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CmdHasConfirmTeleportTips) then
    Log.Debug("\230\156\137\230\173\187\228\186\161\229\164\141\230\180\187\231\149\140\233\157\162...\230\139\166\230\136\170\233\173\148\230\179\149Tips")
    return true
  end
  if self:GetLayerVisiblePanelCount(_G.Enum.UILayerType.UI_LAYER_LEVEL_LOADING) > 0 then
    Log.Debug("\230\156\137\229\133\168\229\177\143\231\149\140\233\157\162UI_LAYER_LEVEL_LOADING...\230\139\166\230\136\170\233\173\148\230\179\149Tips")
    return true
  end
  if ShowTipCD then
    local CD = ShowTipCD.num
    if CD then
      local CurrentTime = _G.ZoneServer:GetServerTime() / 1000
      if self.Timestamp[timeName] then
        if CD < CurrentTime - self.Timestamp[timeName] then
          self.Timestamp[timeName] = CurrentTime
          return false
        else
          return true
        end
      else
        self.Timestamp[timeName] = CurrentTime
        return false
      end
    else
      return false
    end
  else
    return false
  end
end

function MagicMessageModule:GetLayerVisiblePanelCount(panelLayer)
  local Ctrl = _G.NRCPanelManager.layerCenter:GetLayerCtrl(panelLayer)
  local Panels = Ctrl:GetAllWindow()
  local Count = 0
  if Panels then
    for _, Panel in ipairs(Panels) do
      if Panel.enableView then
        Count = Count + 1
        Log.Debug("Visible!", table.getKeyName(_G.Enum.UILayerType, panelLayer), Panel.panelName)
      end
    end
  end
  return Count
end

function MagicMessageModule:OnReceiveTextNotify(Notify)
  if self.StoryFlag then
    return
  end
  local textInfo = Notify.text_info
  if textInfo then
    local text_id = textInfo.text_id
    if "mark_respon_life_flower" == text_id then
      if self:CheckShieldTip(TipsType.LifeFlower) then
        return
      end
    elseif "mark_respon_energe_flower" == text_id and self:CheckShieldTip(TipsType.EnergeFlower) then
      return
    end
    if "mark_create_energe_flower" == text_id then
      local d = _G.DelayManager:DelaySeconds(2, function()
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("mark_create_energe_flower").msg, nil, nil, 3, nil)
      end)
      return
    end
    local formatStr = _G.DataConfigManager:GetLocalizationConf(text_id).msg
    local args = textInfo.args
    if args and args[1] and args[1].param and formatStr then
      formatStr = string.format(formatStr, args[1].param)
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, formatStr, nil, nil, 3, nil)
    if "mark_create_life_flower" ~= text_id and "mark_get_life_flower" ~= text_id and "mark_get_energe_flower" ~= text_id then
      local player = SceneUtils.GetPlayer()
      if player and player.viewObj then
        _G.NRCAudioManager:PlaySound3DWithActorAuto(1077, player.viewObj, "MagicMessageModule")
      end
    end
  end
end

function MagicMessageModule:OnReceiveFeedNotify(Notify)
  if self.Player then
    self.Player:RemoveEventListener(self, PlayerModuleEvent.ON_ROLE_HP_CHANGE_RAW, self.CheckPlayerHPFull)
    self.Player = nil
  end
  self.Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:CheckPlayerHPFull()
  self.Player:AddEventListener(self, PlayerModuleEvent.ON_ROLE_HP_CHANGE_RAW, self.CheckPlayerHPFull)
  local IsEnteringOrSwitching = _G.ZoneServer:IsEnteringOrSwitchingCell()
  if IsEnteringOrSwitching then
    self.CacheNotify = Notify
    if self.SceneFlag then
      self.SceneFlag = false
      _G.NRCEventCenter:RegisterEvent("MagicMessageModule", self, _G.SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnReceiveFeedNotify)
    end
    return
  end
  if self.CacheNotify then
    Notify = self.CacheNotify
    self.CacheNotify = nil
    if not self.SceneFlag then
      self.SceneFlag = true
      _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnReceiveFeedNotify)
    end
  end
  for _, Grid in pairs(self.FeedsByGrid) do
    if Grid then
      Grid.MarkForDelete = true
      for _, Message in pairs(Grid.MessageList) do
        if Message and Message.MessageInfo then
          Message.MessageInfo.MarkForDelete = true
        end
      end
      for _, Flower in pairs(Grid.FlowerList) do
        if Flower and Flower.FlowerInfo then
          Flower.FlowerInfo.MarkForDelete = true
        end
      end
      for _, Video in pairs(Grid.VideoList) do
        if Video and Video.VideoInfo then
          Video.VideoInfo.MarkForDelete = true
        end
      end
    end
  end
  if not Notify or not Notify.data then
    return
  end
  local GridList = Notify.data.grid_list
  if not GridList then
    return
  end
  for _, GridId in pairs(GridList) do
    if GridId then
      if nil == self.FeedsByGrid[GridId] then
        self.FeedsByGrid[GridId] = {}
        self.FeedsByGrid[GridId].grid_id = GridId
        self.FeedsByGrid[GridId].MessageList = {}
        self.FeedsByGrid[GridId].FlowerList = {}
        self.FeedsByGrid[GridId].VideoList = {}
      end
      self.FeedsByGrid[GridId].MarkForDelete = false
    end
  end
  for _, Grid in pairs(self.FeedsByGrid) do
    if Grid.MarkForDelete then
      for _, Message in pairs(Grid.MessageList) do
        if Message and Message.MessageInfo then
          self:DeleteNpcWithoutSkill(Message.MessageInfo, TraceType.Message)
        end
      end
      for _, Flower in pairs(Grid.FlowerList) do
        if Flower and Flower.FlowerInfo then
          self:DeleteNpcWithoutSkill(Flower.FlowerInfo, TraceType.Flower)
        end
      end
      for _, Video in pairs(Grid.VideoList) do
        if Video and Video.VideoInfo then
          self:DeleteNpcWithoutSkill(Video.VideoInfo, TraceType.Video)
        end
      end
      self.FeedsByGrid[Grid.grid_id] = nil
    end
  end
  local FeedList = Notify.data.grid_feed_list
  if not FeedList then
    return
  end
  for _, Feeds in pairs(FeedList) do
    if self.FeedsByGrid[Feeds.grid_id] then
      if Feeds.magic_feeds then
        for _, MessageInfo in pairs(Feeds.magic_feeds) do
          if nil == MessageInfo.content then
            self:RandomContent(MessageInfo, TraceType.Message)
          end
          self:CreateNpc(MessageInfo, Feeds.grid_id, TraceType.Message)
        end
      end
      if Feeds.system_magic_feeds then
        for _, MessageInfo in pairs(Feeds.system_magic_feeds) do
          if nil == MessageInfo.content then
            self:RandomContent(MessageInfo, TraceType.Message)
          end
          self:CreateNpc(MessageInfo, Feeds.grid_id, TraceType.Message)
        end
      end
      if Feeds.flower_feeds then
        for _, FlowerInfo in pairs(Feeds.flower_feeds) do
          self:CreateNpc(FlowerInfo, Feeds.grid_id, TraceType.Flower)
        end
      end
      if Feeds.my_magic_feeds then
        for _, My_MessageInfo in pairs(Feeds.my_magic_feeds) do
          if nil == My_MessageInfo.content then
            self:RandomContent(My_MessageInfo, TraceType.Message)
          end
          self:CreateNpc(My_MessageInfo, Feeds.grid_id, TraceType.Message)
        end
      end
      if Feeds.magic_videos then
        for _, VideoInfo in pairs(Feeds.magic_videos) do
          if nil == VideoInfo.content then
            self:RandomContent(VideoInfo, TraceType.Video)
          end
          self:CreateNpc(VideoInfo, Feeds.grid_id, TraceType.Video)
        end
      end
      if Feeds.my_magic_videos then
        for _, My_VideoInfo in pairs(Feeds.my_magic_videos) do
          if nil == My_VideoInfo.content then
            self:RandomContent(My_VideoInfo, TraceType.Video)
          end
          self:CreateNpc(My_VideoInfo, Feeds.grid_id, TraceType.Video)
        end
      end
    end
  end
  for _, Feeds in pairs(FeedList) do
    if self.FeedsByGrid[Feeds.grid_id] then
      for _, Message in pairs(self.FeedsByGrid[Feeds.grid_id].MessageList) do
        if Message.MessageInfo and Message.MessageInfo.MarkForDelete then
          self:DeleteNpcWithoutSkill(Message.MessageInfo, TraceType.Message)
        end
      end
      for _, Flower in pairs(self.FeedsByGrid[Feeds.grid_id].FlowerList) do
        if Flower.FlowerInfo and Flower.FlowerInfo.MarkForDelete then
          self:DeleteNpcWithoutSkill(Flower.FlowerInfo, TraceType.Flower)
        end
      end
      for _, Video in pairs(self.FeedsByGrid[Feeds.grid_id].VideoList) do
        if Video.VideoInfo and Video.VideoInfo.MarkForDelete then
          self:DeleteNpcWithoutSkill(Video.VideoInfo, TraceType.Video)
        end
      end
    end
  end
  self:UpdateMinExpireTime()
end

function MagicMessageModule:RandomContent(MessageInfo, type)
  local num = MessageInfo.feed_id % 10 + 1
  local str = ""
  if type == TraceType.Message then
    str = string.format("mark_music_random_message_%d", num)
  else
    str = string.format("mark_video_random_message_%d", num)
  end
  local content = _G.DataConfigManager:GetLocalizationConf(str)
  if content and content.msg then
    MessageInfo.content = content.msg
  end
end

function MagicMessageModule:OnReceiveVideoEvent()
  local Info = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetCurrentClientFileUploadInfo, true, true)
  if Info and next(Info) then
    for _, file in pairs(Info) do
      if self.VideoUploading[file.file_name] then
        local npc = self.VideoUploading[file.file_name]
        if npc then
          npc.serverData.base.videoUploading = true
          if npc.viewObj then
            npc.viewObj:Select()
            npc.viewObj:SetTopMessageVisible()
          else
            self:CreateUploadingVideo(file)
          end
        else
          self:CreateUploadingVideo(file)
        end
      else
        self:CreateUploadingVideo(file)
      end
    end
  end
end

function MagicMessageModule:AddVideoToList(file_name, fake_id)
  for _, npc in pairs(self.BeforeEnsure) do
    if npc.serverData.base.actor_id == fake_id then
      self.VideoUploading[file_name] = npc
      return
    end
  end
end

function MagicMessageModule:GetVideoByFileName(file_name)
  if file_name then
    for key, value in pairs(self.VideoUploading) do
      if key == file_name then
        return value.serverData.base.actor_id
      end
    end
  end
end

function MagicMessageModule:GetVideoByFakeId(Fake_Id)
  if Fake_Id then
    for key, npc in pairs(self.BeforeEnsure) do
      if key == Fake_Id then
        return npc
      end
    end
  end
end

function MagicMessageModule:CreateNpc(Info, grid_id, type)
  Info.MarkForDelete = false
  if self.uinToName[Info.uin] then
    Info.name = self.uinToName[Info.uin]
  end
  local MessageFeed = self:GetFeedByGridAndFeedId(grid_id, Info.feed_id, TraceType.Message)
  local FlowerFeed = self:GetFeedByGridAndFeedId(grid_id, Info.feed_id, TraceType.Flower)
  local VideoFeed = self:GetFeedByGridAndFeedId(grid_id, Info.feed_id, TraceType.Video)
  if MessageFeed and MessageFeed.MessageInfo then
    MessageFeed.MessageInfo = Info
    local npc = MessageFeed.MessageNpc
    if npc then
      npc.serverData.MagicFeedInfo = Info
    end
  elseif FlowerFeed and FlowerFeed.FlowerInfo then
    FlowerFeed.FlowerInfo = Info
    local npc = FlowerFeed.FlowerNpc
    if npc then
      npc.serverData.MagicFeedInfo = Info
    end
  elseif VideoFeed and VideoFeed.VideoInfo then
    VideoFeed.VideoInfo = Info
    local npc = VideoFeed.VideoNpc
    if npc then
      npc.serverData.MagicFeedInfo = Info
    end
  elseif self.StoryFlag then
    if type == TraceType.Message then
      local temp = {MessageInfo = Info, MessageNpc = nil}
      self.FeedsByGrid[grid_id].MessageList[Info.feed_id] = temp
    elseif type == TraceType.Flower then
      local temp = {FlowerInfo = Info, FlowerNpc = nil}
      self.FeedsByGrid[grid_id].FlowerList[Info.feed_id] = temp
    elseif type == TraceType.Video then
      local temp = {VideoInfo = Info, VideoNpc = nil}
      self.FeedsByGrid[grid_id].VideoList[Info.feed_id] = temp
    end
  else
    self:CreateFinalNpc(Info, grid_id, type)
  end
end

function MagicMessageModule:CreateFinalNpc(Info, grid_id, type)
  if self.uinToName[Info.uin] then
    Info.name = self.uinToName[Info.uin]
  end
  local ActorInfo = ProtoMessage:newActorInfo_Npc()
  ActorInfo.MagicFeedInfo = Info
  local FakeId
  if type == TraceType.Message then
    FakeId = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ConvertFeed, Info.feed_id, TraceType.Message)
    ActorInfo.npc_base.npc_cfg_id = 55561
  elseif type == TraceType.Flower then
    FakeId = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ConvertFeed, Info.feed_id, TraceType.Flower)
    if 1 == Info.type then
      ActorInfo.npc_base.npc_cfg_id = 55562
    else
      ActorInfo.npc_base.npc_cfg_id = 55563
    end
  elseif type == TraceType.Video then
    FakeId = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ConvertFeed, Info.feed_id, TraceType.Video)
    ActorInfo.npc_base.npc_cfg_id = 55591
  end
  local FeedBase = ProtoMessage:newActorInfo_Base()
  FeedBase.actor_id = FakeId
  FeedBase.pt.pos = Info.create_pos
  FeedBase.lv = 60
  ActorInfo.base = FeedBase
  local Npc = MagicMessageUtils.CreateLocalNPCWithActorInfo(ActorInfo)
  Npc.serverData.pet_info = nil
  if type == TraceType.Message then
    Npc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.SceneNpcLoadOver)
  elseif type == TraceType.Flower then
    Npc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.MagicFlowerLoadOver)
  elseif type == TraceType.Video then
    Npc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.MagicVideoLoadOver)
  end
  Npc:AddEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.DeleteNPCFromList)
  if type == TraceType.Message then
    local temp = {MessageInfo = Info, MessageNpc = Npc}
    self.FeedsByGrid[grid_id].MessageList[Info.feed_id] = temp
    if Npc.serverData.MagicFeedInfo.ext_info == tostring(ProtoEnum.FeedMagicNpcValidType.FEED_MAGIC_NPC_VALID_TYPE_WATER) then
      self.TraceOnWater[Info.feed_id] = self:GetFeedByGridAndFeedId(grid_id, Info.feed_id, TraceType.Message)
    end
  elseif type == TraceType.Flower then
    local temp = {FlowerInfo = Info, FlowerNpc = Npc}
    self.FeedsByGrid[grid_id].FlowerList[Info.feed_id] = temp
  elseif type == TraceType.Video then
    local temp = {VideoInfo = Info, VideoNpc = Npc}
    self.FeedsByGrid[grid_id].VideoList[Info.feed_id] = temp
  end
end

function MagicMessageModule:CreateUploadingVideo(file)
  local ActorInfo = ProtoMessage:newActorInfo_Npc()
  local npcModule = NRCModuleManager:GetModule("NPCModule")
  local FakeId = npcModule:AcquireFakeID()
  ActorInfo.npc_base.npc_cfg_id = 55591
  local FeedBase = ProtoMessage:newActorInfo_Base()
  FeedBase.actor_id = FakeId
  FeedBase.pt.pos = file.create_pos
  FeedBase.lv = 60
  FeedBase.filename = file.file_name
  ActorInfo.base = FeedBase
  local Npc = MagicMessageUtils.CreateLocalNPCWithActorInfo(ActorInfo)
  self.BeforeEnsure[FakeId] = Npc
  self.VideoUploading[file.file_name] = Npc
  Npc.serverData.pet_info = nil
  Npc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.MagicVideoUploading)
  Npc:AddEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.DeleteNPCFromUploading)
end

function MagicMessageModule:MagicVideoUploading(viewObj)
  if viewObj then
    viewObj:Select()
    local npc = viewObj.sceneCharacter
    if not npc then
      return
    end
    npc.serverData.base.videoUploading = true
    viewObj:SetTopMessageVisible()
    npc:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.MagicVideoUploading)
  end
end

function MagicMessageModule:DeleteNPCFromUploading(npc)
  if not npc then
    return
  end
  npc:RemoveEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.DeleteNPCFromList)
  local filename = npc.serverData.base.filename
  if filename then
    self.VideoUploading[filename] = nil
    self.BeforeEnsure[npc.serverData.base.actor_id] = nil
  end
end

function MagicMessageModule:SceneNpcLoadOver(viewObj)
  if viewObj then
    local npc = viewObj.sceneCharacter
    if not npc then
      return
    end
    npc:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.SceneNpcLoadOver)
    local MagicFeedInfo = npc.serverData.MagicFeedInfo
    if not MagicFeedInfo then
      return
    end
    if MagicFeedInfo.ext_info and MagicFeedInfo.ext_info == tostring(ProtoEnum.FeedMagicNpcValidType.FEED_MAGIC_NPC_VALID_TYPE_WATER) then
      local WaterInfo = MagicMessageUtils.GetWaterInfo(viewObj:K2_GetActorLocation())
      local WaterHeight
      if WaterInfo then
        WaterHeight = WaterInfo.position.Z
      end
      local LandInfo = MagicMessageUtils.GetLandInfo(viewObj:K2_GetActorLocation())
      local LandHeight
      if LandInfo then
        LandHeight = LandInfo.position.Z
      end
      if not (WaterHeight and LandInfo) or WaterHeight < LandHeight then
        self:DeleteNpcWithoutSkill(MagicFeedInfo, TraceType.Message)
        return
      end
    end
    MagicMessageUtils.NpcSnapToGround(npc, true)
    self:CreateFakeOptionInfo(npc)
    viewObj.NRCChildActor:GetChildActor():SetPenMat()
    viewObj:SetTopMessageVisible()
  end
end

function MagicMessageModule:MagicFlowerLoadOver(viewObj)
  if viewObj then
    local npc = viewObj.sceneCharacter
    if not npc then
      return
    end
    npc:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.MagicFlowerLoadOver)
    local MagicFeedInfo = npc.serverData.MagicFeedInfo
    if not MagicFeedInfo then
      return
    end
    if MagicMessageUtils.CheckOnIllegal(viewObj:K2_GetActorLocation()) then
      self:DeleteNpcWithoutSkill(MagicFeedInfo, TraceType.Flower)
      return
    end
    local type = MagicMessageUtils.FlowerSnapToGround(npc)
    if type == MagicMessageUtils.NpcValidType.Water then
      self.TraceOnWater[MagicFeedInfo.feed_id] = self:GetFeedByGridAndFeedId(MagicFeedInfo.grid_id, MagicFeedInfo.feed_id, TraceType.Flower)
    end
    self:CreateFakeOptionInfo(npc)
  end
end

function MagicMessageModule:MagicVideoLoadOver(viewObj)
  if viewObj then
    local npc = viewObj.sceneCharacter
    if not npc then
      return
    end
    npc:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.MagicVideoLoadOver)
    local MagicFeedInfo = npc.serverData.MagicFeedInfo
    if not MagicFeedInfo then
      return
    end
    MagicMessageUtils.NpcSnapToGround(npc, true)
    self:CreateFakeOptionInfo(npc)
    viewObj.NRCChildActor:GetChildActor():SetHourglassMat()
    viewObj:SetTopMessageVisible()
  end
end

function MagicMessageModule:DeleteNPCFromList(npc)
  if not npc then
    return
  end
  npc:RemoveEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.DeleteNPCFromList)
  local ServerData = npc.serverData
  local FeedInfo = ServerData and ServerData.MagicFeedInfo
  if not FeedInfo then
    return
  end
  local GridId = FeedInfo.grid_id
  local FeedID = FeedInfo.feed_id
  if GridId and FeedID and self.FeedsByGrid[GridId] then
    self.FeedsByGrid[GridId].MessageList[FeedID] = nil
    self.FeedsByGrid[GridId].FlowerList[FeedID] = nil
    self.FeedsByGrid[GridId].VideoList[FeedID] = nil
  end
end

function MagicMessageModule:OnPickUpFlower(MagicFeedInfo)
  if not MagicFeedInfo then
    return
  end
  self:DeleteNpcWithoutSkill(MagicFeedInfo, TraceType.Flower)
end

function MagicMessageModule:UpdateMinExpireTime()
  table.clear(self.FeedToDelete)
  local minExpireFeed, MaxExpireTime = nil, 0
  
  local function UpdateTime(npc)
    if npc and npc.serverData then
      local MagicFeedInfo = npc.serverData.MagicFeedInfo
      if MagicFeedInfo then
        local expireTime = MagicFeedInfo.expire_timestamp
        if expireTime and (not minExpireFeed or expireTime < minExpireFeed) then
          minExpireFeed = expireTime
        end
      end
    end
  end
  
  local function AddToTable(npc)
    if npc and npc.serverData then
      local MagicFeedInfo = npc.serverData.MagicFeedInfo
      if MagicFeedInfo then
        local expireTime = MagicFeedInfo.expire_timestamp
        if expireTime and minExpireFeed and expireTime <= minExpireFeed + 2 then
          if expireTime > MaxExpireTime then
            MaxExpireTime = expireTime
          end
          if npc then
            table.insert(self.FeedToDelete, npc)
          end
        end
      end
    end
  end
  
  for _, Feeds in pairs(self.FeedsByGrid) do
    if Feeds and Feeds.MessageList then
      for _, Message in pairs(Feeds.MessageList) do
        if Message and Message.MessageNpc then
          local npc = Message.MessageNpc
          UpdateTime(npc)
        end
      end
    end
    if Feeds and Feeds.FlowerList then
      for _, Flower in pairs(Feeds.FlowerList) do
        if Flower and Flower.FlowerNpc then
          local npc = Flower.FlowerNpc
          UpdateTime(npc)
        end
      end
    end
    if Feeds and Feeds.VideoList then
      for _, Video in pairs(Feeds.VideoList) do
        if Video and Video.VideoNpc then
          local npc = Video.VideoNpc
          UpdateTime(npc)
        end
      end
    end
    if Feeds and Feeds.MessageList then
      for _, Message in pairs(Feeds.MessageList) do
        if Message and Message.MessageNpc then
          local npc = Message.MessageNpc
          AddToTable(npc)
        end
      end
    end
    if Feeds and Feeds.FlowerList then
      for _, Flower in pairs(Feeds.FlowerList) do
        if Flower and Flower.FlowerNpc then
          local npc = Flower.FlowerNpc
          AddToTable(npc)
        end
      end
    end
    if Feeds and Feeds.VideoList then
      for _, Video in pairs(Feeds.VideoList) do
        if Video and Video.VideoNpc then
          local npc = Video.VideoNpc
          AddToTable(npc)
        end
      end
    end
  end
  self.minExpireFeed = MaxExpireTime
end

function MagicMessageModule:OnTick(DeltaTime)
  if not self.FeedsByGrid then
    _G.UpdateManager:UnRegister(self)
  end
  if not self.minExpireFeed or not next(self.FeedToDelete) then
    return
  end
  local CurrentTime = _G.ZoneServer:GetServerTime() / 1000
  if CurrentTime >= self.minExpireFeed then
    for i = #self.FeedToDelete, 1, -1 do
      local npc = self.FeedToDelete[i]
      if npc and npc.serverData then
        table.remove(self.FeedToDelete, i)
        local ServerData = npc.serverData
        local FeedInfo = ServerData and ServerData.MagicFeedInfo
        if FeedInfo then
          local GridId = FeedInfo.grid_id
          local FeedID = FeedInfo.feed_id
          if GridId and FeedID then
            local Feeds = self.FeedsByGrid[GridId]
            if Feeds then
              if Feeds.MessageList[FeedID] then
                if FeedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
                  self:DeleteNpcWithoutSkill(FeedInfo, TraceType.Message)
                  _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.Close_Message_Panel, GridId, FeedID)
                end
              elseif Feeds.FlowerList[FeedID] then
                self:DeleteNpcWithoutSkill(FeedInfo, TraceType.Flower)
              elseif Feeds.VideoList[FeedID] then
                self:DeleteNpcWithoutSkill(FeedInfo, TraceType.Video)
                _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.Close_Message_Panel, GridId, FeedID)
              end
            end
          end
        end
      end
    end
  end
  if not self.LastUpdateTime then
    self.LastUpdateTime = CurrentTime
  end
  if CurrentTime - self.LastUpdateTime < 1 then
    return
  end
  self.LastUpdateTime = CurrentTime
  self:UpdateMinExpireTime()
end

function MagicMessageModule:CreateFakeOptionInfo(npc)
  local ActorOptionInfo = ProtoMessage:newActorInfo_NpcOptionInfo()
  ActorOptionInfo.option_id = npc.config.option_id[1]
  self.OptionConf = _G.DataConfigManager:GetNpcOptionConf(ActorOptionInfo.option_id)
  ActorOptionInfo.enabled = true
  ActorOptionInfo.executable_times = -1
  ActorOptionInfo.cur_action_info.act_type = self.OptionConf.action.action_type
  ActorOptionInfo.cur_action_info.act_status = _G.ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Executing
  ActorOptionInfo.cur_action_info.act_exec_success = true
  ActorOptionInfo.cur_action_info.bound_dialog_id = 0
  ActorOptionInfo.cur_action_info.btle_cfg_id = 0
  ActorOptionInfo.cur_action_info.act_result_type = _G.ProtoEnum.ActionResultType.ART_NONE
  ActorOptionInfo.cur_action_info.next_dialog_id = 0
  local InteractionComponent = npc.InteractionComponent
  if InteractionComponent then
    InteractionComponent:Inter_AddOption(ActorOptionInfo.option_id, ActorOptionInfo)
    InteractionComponent:CalcCheckOpts()
    InteractionComponent:UpdateCachedOptions()
  end
end

function MagicMessageModule:DeleteNpcByGridAndFeedId(Grid_Id, Feed_Id, FeedType)
  if 0 == FeedType then
    Log.Debug("DeleteNpcByGridAndFeedId: \230\156\172\229\156\176NPC\239\188\140\230\151\160\233\156\128\229\164\132\231\144\134")
    return
  elseif FeedType == TraceType.Message then
    local feed = self:GetFeedByGridAndFeedId(Grid_Id, Feed_Id, TraceType.Message)
    if feed then
      if feed.MessageNpc then
        local viewObj = feed.MessageNpc.viewObj
        if viewObj then
          local ChildActor = viewObj.NRCChildActor:GetChildActor()
          if viewObj.sceneCharacter.InteractionComponent then
            viewObj.sceneCharacter.InteractionComponent:TryDisableInteraction()
          end
          viewObj:SetHidden()
          local SkillComp = viewObj.RocoSkill
          SkillComp:StopCurrentSkill()
          local path = "'/Game/ArtRes/Effects/G6Skill/SceneEffect/Messages/G6_Scene_Messages_Hidden.G6_Scene_Messages_Hidden'"
          local FeedInfo = feed.MessageNpc.serverData.MagicFeedInfo
          if FeedInfo and FeedInfo.sub_type then
            local config = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MARK_MESSAGE_CHILD_CONF):GetAllDatas()
            local wand_id
            for _, value in pairs(config) do
              if value.child_type == FeedInfo.sub_type then
                wand_id = value.wand_id
                break
              end
            end
            if wand_id then
              local wandConf = _G.DataConfigManager:GetFashionWandConf(wand_id, true)
              if wandConf then
                local magicId = wandConf.magic_list[ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_MASSAGE]
                local avatarSystem = UE4.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(_G.UE4Helper.GetCurrentWorld(), UE4.UAvatarSubsystem)
                local AvatarConfig = avatarSystem:GetAvatarConfig()
                local RowKey = AvatarConfig:GetWandDataRowKeyByMagic(magicId, ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_MASSAGE)
                local wandData = UE4.FAvatarWandInfo_Message()
                UE.UDataTableFunctionLibrary.GetTableDataRowFromName(AvatarConfig.AvatarWandDataMap:Find(ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_MASSAGE), RowKey, wandData)
                local magicConfig = wandData.MessageMagicResource
                if magicConfig then
                  path = UE4.UNRCStatics.GetSoftObjPath(magicConfig.HiddenSkill)
                end
              end
            end
          end
          local Skill = RocoSkillProxy.Create(path, SkillComp, PriorityEnum.Active_Player_Action)
          Skill:SetAdditions("NPC", feed.MessageNpc)
          Skill:SetCaster(ChildActor)
          Skill:RegisterEventCallback("End", self, self.PlayHiddenSkillFinish)
          Skill:PlaySkill(self, self.OnHiddenSkillCallBack)
        end
      end
    else
      Log.Error("DeleteNpcByFeedId\231\138\182\230\128\12901: \230\156\170\230\137\190\229\136\176")
      return
    end
  elseif FeedType == TraceType.Flower then
    local feed = self:GetFeedByGridAndFeedId(Grid_Id, Feed_Id, TraceType.Flower)
    if feed then
      if feed.FlowerNpc then
        MagicMessageUtils.DeleteLocalNpc(feed.FlowerNpc)
      end
      self.FeedsByGrid[Grid_Id].FlowerList[Feed_Id] = nil
      self.TraceOnWater[Feed_Id] = nil
    else
      Log.Error("DeleteNpcByFeedId\231\138\182\230\128\12910: \230\156\170\230\137\190\229\136\176")
      return
    end
  elseif FeedType == TraceType.Video then
    local feed = self:GetFeedByGridAndFeedId(Grid_Id, Feed_Id, TraceType.Video)
    if feed then
      if feed.VideoNpc then
        local viewObj = feed.VideoNpc.viewObj
        if viewObj then
          local ChildActor = viewObj.NRCChildActor:GetChildActor()
          if viewObj.sceneCharacter.InteractionComponent then
            viewObj.sceneCharacter.InteractionComponent:TryDisableInteraction()
          end
          viewObj:SetHidden()
          local SkillComp = viewObj.RocoSkill
          SkillComp:StopCurrentSkill()
          local path = "'/Game/ArtRes/Effects/G6Skill/SceneEffect/MovieMagic/G6_Scene_MovieMagic_Hidden.G6_Scene_MovieMagic_Hidden'"
          local FeedInfo = feed.VideoNpc.serverData.MagicFeedInfo
          if FeedInfo and FeedInfo.sub_type then
            local config = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MARK_MESSAGE_CHILD_CONF):GetAllDatas()
            local wand_id
            for _, value in pairs(config) do
              if value.child_type == FeedInfo.sub_type then
                wand_id = value.wand_id
                break
              end
            end
            if wand_id then
              local wandConf = _G.DataConfigManager:GetFashionWandConf(wand_id, true)
              if wandConf then
                local magicId = wandConf.magic_list[ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_VIDEO]
                local avatarSystem = UE4.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(_G.UE4Helper.GetCurrentWorld(), UE4.UAvatarSubsystem)
                local AvatarConfig = avatarSystem:GetAvatarConfig()
                local RowKey = AvatarConfig:GetWandDataRowKeyByMagic(magicId, ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_VIDEO)
                local wandData = UE4.FAvatarWandInfo_Video()
                UE.UDataTableFunctionLibrary.GetTableDataRowFromName(AvatarConfig.AvatarWandDataMap:Find(ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_VIDEO), RowKey, wandData)
                local magicConfig = wandData.VideoMagicResource
                if magicConfig then
                  path = UE4.UNRCStatics.GetSoftObjPath(magicConfig.HiddenSkill)
                end
              end
            end
          end
          local Skill = RocoSkillProxy.Create(path, SkillComp, PriorityEnum.Active_Player_Action)
          Skill:SetAdditions("NPC", feed.VideoNpc)
          Skill:SetCaster(ChildActor)
          Skill:RegisterEventCallback("End", self, self.PlayHiddenVideoFinish)
          Skill:PlaySkill(self, self.OnHiddenVideoCallBack)
        end
      end
    else
      Log.Error("DeleteNpcByFeedId\231\138\182\230\128\12911: \230\156\170\230\137\190\229\136\176")
      return
    end
  else
    Log.Error("DeleteNpcByFeedId \233\148\153\232\175\175\231\138\182\230\128\129")
  end
  self:UpdateMinExpireTime()
end

function MagicMessageModule:OnHiddenSkillCallBack(skillProxy, result)
  if result ~= UE4.ESkillStartResult.Success then
    Log.Error("OnHiddenSkillCallBack failed to play skill!", result, skillProxy)
    self:PlayHiddenSkillFinish()
  end
end

function MagicMessageModule:OnHiddenVideoCallBack(skillProxy, result)
  if result ~= UE4.ESkillStartResult.Success then
    Log.Error("OnHiddenVideoCallBack failed to play skill!", result, skillProxy)
    self:PlayHiddenVideoFinish()
  end
end

function MagicMessageModule:PlayHiddenVideoFinish(Name, Skill)
  local NPC = Skill:GetAddition("NPC")
  if NPC then
    local MagicFeedInfo = NPC.serverData.MagicFeedInfo
    MagicMessageUtils.DeleteLocalNpc(NPC)
    self.FeedsByGrid[MagicFeedInfo.grid_id].VideoList[MagicFeedInfo.feed_id] = nil
    self.TraceOnWater[MagicFeedInfo.feed_id] = nil
  end
end

function MagicMessageModule:PlayHiddenSkillFinish(Name, Skill)
  local NPC = Skill:GetAddition("NPC")
  if NPC then
    local MagicFeedInfo = NPC.serverData.MagicFeedInfo
    MagicMessageUtils.DeleteLocalNpc(NPC)
    self.FeedsByGrid[MagicFeedInfo.grid_id].MessageList[MagicFeedInfo.feed_id] = nil
    self.TraceOnWater[MagicFeedInfo.feed_id] = nil
  end
end

function MagicMessageModule:UpdateNpcByGridAndFeedId(Grid_ID, Feed_Id, FeedInfo)
  local FeedType = FeedInfo.category
  if 0 == FeedType then
    Log.Debug("UpdateNpcByGridAndFeedId\231\138\182\230\128\12900: \230\156\172\229\156\176NPC\239\188\140\230\151\160\233\156\128\229\164\132\231\144\134")
    return
  elseif FeedType == TraceType.Message or FeedType == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
    local Feed = self:GetFeedByGridAndFeedId(Grid_ID, Feed_Id, TraceType.Message)
    if Feed then
      if FeedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
        self.uinToName[FeedInfo.uin] = FeedInfo.name
      end
      Feed.MessageInfo = FeedInfo
      local npc = Feed.MessageNpc
      if npc then
        npc.serverData.MagicFeedInfo = FeedInfo
        local viewObj = npc.viewObj
        if viewObj and viewObj.hudComp and viewObj.hudComp._headHud then
          viewObj.hudComp._headHud:ShowTopMessage(true, npc)
        end
      end
    else
      Log.Error("UpdateNpcByGridAndFeedId\231\138\182\230\128\12901: \230\156\170\230\137\190\229\136\176")
      return
    end
  elseif FeedType == TraceType.Flower then
    local Feed = self:GetFeedByGridAndFeedId(Grid_ID, Feed_Id, TraceType.Flower)
    if Feed then
      self.uinToName[FeedInfo.uin] = FeedInfo.name
      Feed.FlowerInfo = FeedInfo
      local npc = Feed.FlowerNpc
      npc.serverData.MagicFeedInfo = FeedInfo
      local viewObj = npc.viewObj
      if viewObj and viewObj.hudComp and viewObj.hudComp._headHud then
        viewObj.hudComp._headHud:ShowTopMessage(true, npc)
      end
    else
      Log.Error("UpdateNpcByGridAndFeedId\231\138\182\230\128\12910: \230\156\170\230\137\190\229\136\176")
      return
    end
  elseif FeedType == TraceType.Video then
    local Feed = self:GetFeedByGridAndFeedId(Grid_ID, Feed_Id, TraceType.Video)
    if Feed then
      self.uinToName[FeedInfo.uin] = FeedInfo.name
      Feed.VideoInfo = FeedInfo
      local npc = Feed.VideoNpc
      npc.serverData.MagicFeedInfo = FeedInfo
      local viewObj = npc.viewObj
      if viewObj and viewObj.hudComp and viewObj.hudComp._headHud then
        viewObj.hudComp._headHud:ShowTopMessage(true, npc)
      end
    else
      Log.Error("UpdateNpcByGridAndFeedId\231\138\182\230\128\12911: \230\156\170\230\137\190\229\136\176")
      return
    end
  else
    Log.Error("UpdateNpcByGridAndFeedId \233\148\153\232\175\175\231\138\182\230\128\129")
  end
  self:UpdateMinExpireTime()
end

function MagicMessageModule:GetNpcByGridAndFeedId(Grid_ID, Feed_Id, FeedType)
  if 0 == FeedType then
    Log.Debug("GetNpcByGridAndFeedId\231\138\182\230\128\12900: \230\156\172\229\156\176NPC\239\188\140\230\151\160\233\156\128\229\164\132\231\144\134")
    return
  elseif FeedType == TraceType.Message then
    if self.FeedsByGrid[Grid_ID] and self.FeedsByGrid[Grid_ID].MessageList[Feed_Id] and self.FeedsByGrid[Grid_ID].MessageList[Feed_Id].MessageNpc then
      return self.FeedsByGrid[Grid_ID].MessageList[Feed_Id].MessageNpc
    else
      Log.Error("GetNpcByGridAndFeedId\231\138\182\230\128\12901: \230\156\170\230\137\190\229\136\176")
      return
    end
  elseif FeedType == TraceType.Video then
    if self.FeedsByGrid[Grid_ID] and self.FeedsByGrid[Grid_ID].VideoList[Feed_Id] and self.FeedsByGrid[Grid_ID].VideoList[Feed_Id].VideoNpc then
      return self.FeedsByGrid[Grid_ID].VideoList[Feed_Id].VideoNpc
    else
      Log.Error("GetNpcByGridAndFeedId\231\138\182\230\128\12911: \230\156\170\230\137\190\229\136\176")
      return
    end
  else
    Log.Error("GetNpcByGridAndFeedId \233\148\153\232\175\175\231\138\182\230\128\129")
  end
end

function MagicMessageModule:DeleteNpcBeforeEnsure(Fake_Id, FeedType)
  if self.BeforeEnsure[Fake_Id] then
    local npc = self.BeforeEnsure[Fake_Id]
    local viewObj = npc.viewObj
    if viewObj then
      if FeedType == TraceType.Message then
        local ChildActor = viewObj.NRCChildActor:GetChildActor()
        self.DeleteTempFakeId = Fake_Id
        viewObj:SetCancel()
        local SkillComp = viewObj.RocoSkill
        SkillComp:StopCurrentSkill()
        local wandData = MagicMessageUtils.GetAvatarWandConfig(ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE)
        local path = "'/Game/ArtRes/Effects/G6Skill/SceneEffect/Messages/G6_Scene_Messages_cancel.G6_Scene_Messages_Cancel'"
        if wandData then
          path = UE4.UNRCStatics.GetSoftObjPath(wandData.CancelSkill)
        end
        local Skill = RocoSkillProxy.Create(path, SkillComp, PriorityEnum.Active_Player_Action)
        Skill:SetCaster(ChildActor)
        Skill:RegisterEventCallback("End", self, self.PlaySkillFinish)
        Skill:PlaySkill(self, self.OnSkillCallBack)
      elseif FeedType == TraceType.Video then
        local ChildActor = viewObj.NRCChildActor:GetChildActor()
        self.DeleteVideoFakeId = Fake_Id
        viewObj:SetCancel()
        local SkillComp = viewObj.RocoSkill
        SkillComp:StopCurrentSkill()
        local wandData = MagicMessageUtils.GetAvatarWandConfig(ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO)
        local path = "'/Game/ArtRes/Effects/G6Skill/SceneEffect/MovieMagic/G6_Scene_MovieMagic_Cancel.G6_Scene_MovieMagic_Cancel'"
        if wandData then
          path = UE4.UNRCStatics.GetSoftObjPath(wandData.CancelSkill)
        end
        local Skill = RocoSkillProxy.Create(path, SkillComp, PriorityEnum.Active_Player_Action)
        Skill:SetCaster(ChildActor)
        Skill:RegisterEventCallback("End", self, self.PlayVideoFinish)
        Skill:PlaySkill(self, self.OnVideoCallBack)
      end
    end
  end
end

function MagicMessageModule:PlaySkillFinish()
  if self.BeforeEnsure[self.DeleteTempFakeId] then
    local Id = self.DeleteTempFakeId
    MagicMessageUtils.DeleteLocalNpc(self.BeforeEnsure[Id])
    self.BeforeEnsure[Id] = nil
    self.DeleteTempFakeId = nil
  end
end

function MagicMessageModule:OnSkillCallBack(skillProxy, result)
  if result ~= UE4.ESkillStartResult.Success then
    Log.Error("OnSkillCallBack failed to play skill!", result, skillProxy)
    self:PlaySkillFinish()
  end
end

function MagicMessageModule:PlayVideoFinish()
  if self.BeforeEnsure[self.DeleteVideoFakeId] then
    local Id = self.DeleteVideoFakeId
    MagicMessageUtils.DeleteLocalNpc(self.BeforeEnsure[Id])
    self.BeforeEnsure[Id] = nil
    self.DeleteVideoFakeId = nil
  end
end

function MagicMessageModule:OnVideoCallBack(skillProxy, result)
  if result ~= UE4.ESkillStartResult.Success then
    Log.Error("OnVideoCallBack failed to play skill!", result, skillProxy)
    self:PlayVideoFinish()
  end
end

function MagicMessageModule:RegisterPreperform(npc)
  if nil == npc then
    return
  end
  local actor_id = npc.serverData.base.actor_id
  self.BeforeEnsure[actor_id] = npc
end

function MagicMessageModule:AddLocalNpcToList(rsp, fake_id, file_name)
  local FakeId = fake_id
  local npc = self.BeforeEnsure[FakeId]
  if not npc then
    for _, v in pairs(self.BeforeEnsure) do
      if v.serverData.base.filename == file_name then
        npc = v
        FakeId = v.serverData.base.actor_id
        break
      end
    end
  end
  if npc and rsp then
    npc.serverData.MagicFeedInfo = rsp
    npc.serverData.pet_info = nil
    local GridId = rsp.grid_id
    if not self.FeedsByGrid[GridId] then
      self.FeedsByGrid[GridId] = {}
      self.FeedsByGrid[GridId].grid_id = GridId
      self.FeedsByGrid[GridId].MessageList = {}
      self.FeedsByGrid[GridId].FlowerList = {}
      self.FeedsByGrid[GridId].VideoList = {}
    end
    local FeedType = rsp.category
    if FeedType == TraceType.Message then
      self.AddTempFakeId = FakeId
      local temp = {MessageInfo = rsp, MessageNpc = npc}
      self.FeedsByGrid[GridId].MessageList[rsp.feed_id] = temp
      npc:AddEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.DeleteNPCFromList)
      local viewObj = npc.viewObj
      if viewObj then
        local ChildActor = viewObj.NRCChildActor:GetChildActor()
        local SkillComp = viewObj.RocoSkill
        if not SkillComp then
          return
        end
        SkillComp:StopCurrentSkill()
        local wandData = MagicMessageUtils.GetAvatarWandConfig(ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE)
        local path = "'/Game/ArtRes/Effects/G6Skill/SceneEffect/Messages/G6_Scene_Messages_Change.G6_Scene_Messages_Change'"
        if wandData then
          path = UE4.UNRCStatics.GetSoftObjPath(wandData.ChangeSkill)
        end
        local Skill = RocoSkillProxy.Create(path, SkillComp, PriorityEnum.Active_Player_Action)
        Skill:SetCaster(ChildActor)
        Skill:RegisterEventCallback("End", self, self.AddLocalNpcFinish)
        Skill:PlaySkill(self, self.OnSkillCallBack)
      end
    elseif FeedType == TraceType.Video then
      self.AddVideoFakeId = FakeId
      local temp = {VideoInfo = rsp, VideoNpc = npc}
      self.FeedsByGrid[GridId].VideoList[rsp.feed_id] = temp
      npc:AddEventListener(self, NPCModuleEvent.On_NPC_Destroy, self.DeleteNPCFromList)
      local viewObj = npc.viewObj
      if viewObj then
        local ChildActor = viewObj.NRCChildActor:GetChildActor()
        local SkillComp = viewObj.RocoSkill
        if not SkillComp then
          return
        end
        SkillComp:StopCurrentSkill()
        local wandData = MagicMessageUtils.GetAvatarWandConfig(ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO)
        local path = "'/Game/ArtRes/Effects/G6Skill/SceneEffect/MovieMagic/G6_Scene_MovieMagic_Change.G6_Scene_MovieMagic_Change'"
        if wandData then
          path = UE4.UNRCStatics.GetSoftObjPath(wandData.ChangeSkill)
        end
        local Skill = RocoSkillProxy.Create(path, SkillComp, PriorityEnum.Active_Player_Action)
        Skill:SetCaster(ChildActor)
        Skill:RegisterEventCallback("End", self, self.AddVideoNpcFinish)
        Skill:PlaySkill(self, self.OnVideoCallBack)
      end
    end
    self:UpdateMinExpireTime()
  end
end

function MagicMessageModule:AddLocalNpcFinish()
  local Id = self.AddTempFakeId
  if not Id then
    Id = self.AddTempFakeId
    if not Id then
      Log.Error("MagicMessageModule:AddLocalNpcFinish Still not found Id")
      return
    end
  end
  local npc
  npc = self.BeforeEnsure[Id]
  if npc then
    local viewObj = npc.viewObj
    if viewObj and viewObj.SetTopMessageVisible and viewObj.SetMessageFx then
      viewObj:SetTopMessageVisible()
      viewObj:SetMessageFx()
    end
    npc.serverData.base.is_valid = nil
    self:CreateFakeOptionInfo(npc)
    local MagicFeedInfo = npc.serverData.MagicFeedInfo
    if MagicFeedInfo and MagicFeedInfo.ext_info and MagicFeedInfo.ext_info == tostring(ProtoEnum.FeedMagicNpcValidType.FEED_MAGIC_NPC_VALID_TYPE_WATER) then
      self.TraceOnWater[MagicFeedInfo.feed_id] = self:GetFeedByGridAndFeedId(MagicFeedInfo.grid_id, MagicFeedInfo.feed_id, TraceType.Message)
    end
  end
  self.BeforeEnsure[Id] = nil
  self.AddTempFakeId = nil
end

function MagicMessageModule:AddVideoNpcFinish()
  local Id = self.AddVideoFakeId
  if not Id then
    Id = self.AddVideoFakeId
    if not Id then
      Log.Error("MagicMessageModule:AddVideoNpcFinish Still not found Id")
      return
    end
  end
  local npc
  npc = self.BeforeEnsure[Id]
  if npc then
    local viewObj = npc.viewObj
    local base = npc.serverData.base
    base.videoUploading = false
    if viewObj and viewObj.hudComp and viewObj.hudComp._headHud then
      viewObj.hudComp._headHud:ShowTopMessage(true, npc)
    end
    if base.filename then
      self.VideoUploading[base.filename] = nil
      base.filename = nil
    end
    npc.serverData.base.is_valid = nil
    self:CreateFakeOptionInfo(npc)
    self.LocalVideo = false
  end
  self.BeforeEnsure[Id] = nil
  self.AddVideoFakeId = nil
end

function MagicMessageModule:SetNpcAppearance(npc, validType)
  if nil == npc then
    return
  end
  local viewObj = npc.viewObj
  if not viewObj then
    return
  end
  if nil == validType or validType == MagicMessageUtils.NpcValidType.Valid or validType == MagicMessageUtils.NpcValidType.Water then
    if viewObj.Select then
      npc.serverData.base.is_valid = true
      viewObj:Select()
    end
  elseif viewObj.NoSelect then
    npc.serverData.base.is_valid = false
    viewObj:NoSelect()
  end
end

function MagicMessageModule:OnReconnect()
end

function MagicMessageModule:CheckLandValid(center)
  local function checkIsOnWater(landInfo, waterHeight)
    if nil == waterHeight then
      return false
    end
    if nil == landInfo then
      return true
    end
    if waterHeight >= landInfo.position.Z then
      return true
    end
    return false
  end
  
  local centerWaterHeight = MagicMessageUtils.GetWaterHeight(center)
  local centerInfo = MagicMessageUtils.GetLandInfo(center)
  if checkIsOnWater(centerInfo, centerWaterHeight) then
    return MagicMessageUtils.NpcValidType.Water
  end
  return MagicMessageUtils.NpcValidType.Valid
end

function MagicMessageModule:GetCanDrawDebug()
  if _G.RocoEnv.IS_SHIPPING then
    return false
  end
  return self.bDrawDebugFlag == true
end

function MagicMessageModule:DrawDebugValidCheck(type, center, landInfo, waterHeight, isTolerated)
  if self:GetCanDrawDebug() ~= true then
    return
  end
  local duration = 0.03333333333333333
  local color = UE4.FLinearColor(1, 0.1, 0, 1)
  if isTolerated then
    color = UE4.FLinearColor(0.6, 0.4, 0, 1)
  end
  if type == MagicMessageUtils.NpcValidType.Planeness_NoLand then
    UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), center, "\230\151\160\229\156\176\233\157\162", nil, color, duration)
  elseif type == MagicMessageUtils.NpcValidType.Planeness_Angle then
    local arrowLength = 300
    if isTolerated then
      arrowLength = 150
    end
    local startPosition = UE4.FVector(landInfo.position.X, landInfo.position.Y, landInfo.position.Z)
    local endPosition = startPosition + UE4.FVector(landInfo.normal.X, landInfo.normal.Y, landInfo.normal.Z) * arrowLength
    UE4.UKismetSystemLibrary.DrawDebugArrow(_G.UE4Helper.GetCurrentWorld(), startPosition, endPosition, 10, color, duration, 2)
  elseif type == MagicMessageUtils.NpcValidType.Planeness_Height then
    UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), landInfo.position, landInfo.position.Z, nil, color, duration)
  elseif type == MagicMessageUtils.NpcValidType.Valid then
    UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), landInfo.position, landInfo.position.Z, nil, UE4.FLinearColor(0.2, 1, 0, 1), duration)
  elseif type == MagicMessageUtils.NpcValidType.Water and nil ~= landInfo and nil ~= waterHeight then
    local point = UE4.FVector(landInfo.position.X, landInfo.position.Y, landInfo.position.Z)
    point.Z = waterHeight
    UE4.UKismetSystemLibrary.DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), point, 20, 8, UE4.FLinearColor(0, 0, 1, 1), duration, 2)
  end
end

function MagicMessageModule:DeleteNpcWithoutSkill(Info, type)
  if not Info then
    return
  end
  if type == TraceType.Message then
    local npc = self:GetFeedByGridAndFeedId(Info.grid_id, Info.feed_id, type).MessageNpc
    self:MagicMessageDisableInteraction(npc)
    MagicMessageUtils.DeleteLocalNpc(npc)
    self.FeedsByGrid[Info.grid_id].MessageList[Info.feed_id] = nil
  elseif type == TraceType.Flower then
    local npc = self:GetFeedByGridAndFeedId(Info.grid_id, Info.feed_id, type).FlowerNpc
    self:MagicMessageDisableInteraction(npc)
    MagicMessageUtils.DeleteLocalNpc(npc)
    self.FeedsByGrid[Info.grid_id].FlowerList[Info.feed_id] = nil
  elseif type == TraceType.Video then
    local npc = self:GetFeedByGridAndFeedId(Info.grid_id, Info.feed_id, type).VideoNpc
    self:MagicMessageDisableInteraction(npc)
    MagicMessageUtils.DeleteLocalNpc(npc)
    self.FeedsByGrid[Info.grid_id].VideoList[Info.feed_id] = nil
  end
end

function MagicMessageModule:MagicMessageDisableInteraction(npc)
  if not npc then
    return
  end
  local viewObj = npc.viewObj
  if not viewObj then
    return
  end
  local sceneCharacter = viewObj.sceneCharacter
  if not sceneCharacter then
    return
  end
  local InteractionComponent = sceneCharacter.InteractionComponent
  if not InteractionComponent then
    return
  end
  InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.MESSAGE_BAN)
end

function MagicMessageModule:GetFeedByGridAndFeedId(grid_id, feed_id, type)
  if not self.FeedsByGrid[grid_id] then
    return nil
  end
  if type == TraceType.Message then
    return self.FeedsByGrid[grid_id].MessageList[feed_id]
  elseif type == TraceType.Flower then
    return self.FeedsByGrid[grid_id].FlowerList[feed_id]
  elseif type == TraceType.Video then
    return self.FeedsByGrid[grid_id].VideoList[feed_id]
  end
end

return MagicMessageModule
