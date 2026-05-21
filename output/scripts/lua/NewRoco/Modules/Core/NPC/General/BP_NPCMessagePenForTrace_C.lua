require("UnLuaEx")
local PetHUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.PetHUDComponent")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local ShowFxDisConf = _G.DataConfigManager:GetNpcGlobalConfig("mark_music_vfx_show_distance")
local WarningConf = _G.DataConfigManager:GetGlobalConfigByKey("mark_music_play_alarm_range")
local MusicPlayConf = _G.DataConfigManager:GetGlobalConfigByKey("mark_music_play_range")
local MusicWarnTipConf = _G.DataConfigManager:GetLocalizationConf("mark_music_stop_alarm")
local MagicMessageUtils = require("NewRoco.Modules.System.MagicMessage.MagicMessageUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local MessageEnum = ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_MASSAGE
local BP_NPCMessagePenForTrace_C = Base:Extend("BP_NPCMessagePenForTrace_C")

function BP_NPCMessagePenForTrace_C:Init()
  Base.Init(self)
  self.StartTick = false
  self.ShowFxDis = 0
  self.WarningDis = 0
  self.MusicPlayDis = 0
  self.NextShowTime = 0
  self.ShowFxFlag = true
  self.MusicWarnTip = "no music warn tip"
  if ShowFxDisConf then
    local ShowFx = ShowFxDisConf.num
    if ShowFx then
      self.ShowFxDis = ShowFx * ShowFx
      self:AddCustomTickDistance(self.ShowFxDis)
    end
  end
  if WarningConf then
    local Warning = WarningConf.num
    if Warning then
      self.WarningDis = Warning * Warning
      self:AddCustomTickDistance(self.WarningDis)
    end
  end
  if MusicPlayConf then
    local MusicPlay = MusicPlayConf.num
    if MusicPlay then
      self.MusicPlayDis = MusicPlay * MusicPlay
      self:AddCustomTickDistance(self.MusicPlayDis)
    end
  end
  if MusicWarnTipConf then
    local MusicWarnTip = MusicWarnTipConf.msg
    if MusicWarnTip then
      self.MusicWarnTip = MusicWarnTip
    end
  end
  self.ShowTipFlag = true
end

function BP_NPCMessagePenForTrace_C:OnVisible()
  Base.OnVisible(self)
  self.Child = self.NRCChildActor:GetChildActor()
end

function BP_NPCMessagePenForTrace_C:LoadMapStart()
  self.sceneCharacter:OnPlayerTeleportStart()
end

function BP_NPCMessagePenForTrace_C:ReceiveDestroyed()
  Base.ReceiveDestroyed(self)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.LoadMapStart)
end

function BP_NPCMessagePenForTrace_C:SetSceneCharacter(sceneCharacter)
  Base.SetSceneCharacter(self, sceneCharacter)
  if not sceneCharacter then
    return
  end
  local FeedInfo = sceneCharacter.serverData.MagicFeedInfo
  if FeedInfo then
    if FeedInfo.sub_type then
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
          local path = "Blueprint'/Game/NewRoco/Modules/Core/NPC/General/BP_NPCCommonMessage.BP_NPCCommonMessage'"
          local magicId = wandConf.magic_list[MessageEnum]
          local avatarSystem = UE4.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(_G.UE4Helper.GetCurrentWorld(), UE4.UAvatarSubsystem)
          local AvatarConfig = avatarSystem:GetAvatarConfig()
          local RowKey = AvatarConfig:GetWandDataRowKeyByMagic(magicId, MessageEnum)
          local wandData = UE4.FAvatarWandInfo_Message()
          UE.UDataTableFunctionLibrary.GetTableDataRowFromName(AvatarConfig.AvatarWandDataMap:Find(MessageEnum), RowKey, wandData)
          local magicConfig = wandData.MessageMagicResource
          if magicConfig then
            path = UE4.UNRCStatics.GetSoftObjPath(magicConfig.MessageItem)
          end
          sceneCharacter.viewObj.NRCChildActor:SetPath(path)
        end
      end
    end
  else
    local wandData = MagicMessageUtils.GetAvatarWandConfig(ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE)
    local path = "Blueprint'/Game/NewRoco/Modules/Core/NPC/General/BP_NPCCommonMessage.BP_NPCCommonMessage'"
    if wandData then
      path = UE4.UNRCStatics.GetSoftObjPath(wandData.MessageItem)
    end
    sceneCharacter.viewObj.NRCChildActor:SetPath(path)
  end
  _G.NRCEventCenter:RegisterEvent("BP_NPCMessagePenForTrace_C", self, SceneEvent.LoadMapStart, self.LoadMapStart)
end

function BP_NPCMessagePenForTrace_C:OnLeaveBattle()
  Base.OnLeaveBattle(self)
  local npc = self.sceneCharacter
  if not npc then
    return
  end
  local hudComp = npc:EnsureComponent(PetHUDComponent)
  local Hud = hudComp._headHud
  if not Hud then
    return
  end
  Hud:ShowTopMessage(true, npc)
end

function BP_NPCMessagePenForTrace_C:SetPosition(InitPosition, SelectPosition)
  self.InitialPosition = InitPosition
  self.SelectPosition = SelectPosition
  if not self.Child then
    self.Child = self.NRCChildActor:GetChildActor()
  end
  self.Child.InitialPosition = InitPosition
  self.Child.SelectPosition = SelectPosition
end

function BP_NPCMessagePenForTrace_C:SetTopMessageVisible()
  local npc = self.sceneCharacter
  if npc then
    self.music_id = npc.serverData.MagicFeedInfo.music_id
    local hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
    if not hudClass then
      Log.Error("BP_NPCMessagePenForTrace_C:SetTopMessageVisible _G.NRCBigWorldPreloader:Get(PET_HUD) First Failed")
      hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
      if not hudClass then
        Log.Error("BP_NPCMessagePenForTrace_C:SetTopMessageVisible _G.NRCBigWorldPreloader:Get(PET_HUD) Second Failed")
        return
      end
      return
    end
    local hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
    if not hud then
      Log.Error("BP_NPCMessagePenForTrace_C:SetTopMessageVisible Create hud First Failed")
      hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
      if not hud then
        Log.Error("BP_NPCMessagePenForTrace_C:SetTopMessageVisible Create hud Second Failed")
        return
      end
    end
    self.HeadWidget:SetWidget(hud)
    hud:SetParentHUD(self.HeadWidget)
    self.hudComp = npc:EnsureComponent(PetHUDComponent)
    if self.hudComp then
      self.hudComp:OnSetViewObj()
      self.hudComp:ForceUpdate()
    end
  end
end

function BP_NPCMessagePenForTrace_C:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
  if self.music_id == nil or 0 == self.music_id or not self.Child then
    return
  end
  local Dis2Local = self.sceneCharacter.squaredDis2Local
  if Dis2Local < self.ShowFxDis then
    if UE4.UObject.IsValid(self.Child) and self.Child.SetMusicFx and self.ShowFxFlag then
      self.Child:SetMusicFx()
      self.ShowFxFlag = false
    end
    if not self.ShowTipFlag then
      self.ShowTipFlag = true
    end
  elseif UE4.UObject.IsValid(self.Child) and self.Child.SetMusicFxDeactive and not self.ShowFxFlag then
    self.Child:SetMusicFxDeactive()
    self.ShowFxFlag = true
  end
  if not self.StartTick then
    return
  end
  if Dis2Local > self.WarningDis and Dis2Local < self.MusicPlayDis then
    if self.ShowTipFlag then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, self.MusicWarnTip)
      self.ShowTipFlag = false
    end
  elseif Dis2Local > self.MusicPlayDis then
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.ExitMusicMessage)
  elseif Dis2Local < self.WarningDis and not self.ShowTipFlag then
    self.ShowTipFlag = true
  end
end

function BP_NPCMessagePenForTrace_C:SetTickStart(IsStart)
  self.StartTick = IsStart
  if IsStart then
    self.ShowTipFlag = true
  end
end

return BP_NPCMessagePenForTrace_C
