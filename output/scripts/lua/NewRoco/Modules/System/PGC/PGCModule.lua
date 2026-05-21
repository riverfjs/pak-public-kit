local PGCModule = NRCModuleBase:Extend("PGCModule")
local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTIManager = require("NewRoco.Modules.System.PGC.RTTI.RTTIManager")

function PGCModule:OnConstruct()
  self.data = self:SetData("PGCModuleData", "NewRoco.Modules.System.PGC.PGCModuleData")
  self:RegPanel(PGCModuleEnum.PanelNames.DataView, "/Game/NewRoco/Modules/System/PGC/Res/UMG_DataView", _G.Enum.UILayerType.UI_LAYER_MAIN, "In", "Out")
  self:RegPanel(PGCModuleEnum.PanelNames.EnumView, "/Game/NewRoco/Modules/System/PGC/Res/FieldViews/UMG_EnumView", _G.Enum.UILayerType.UI_LAYER_MAIN, "In", "Out")
end

function PGCModule:OnDestruct()
  if self.DelayList then
    for _, id in pairs(self.DelayList) do
      if id then
        _G.DelayManager:CancelDelayById(id)
      end
    end
    self.DelayList = nil
  end
end

function PGCModule:OnActive()
end

function PGCModule:OnDeactive()
end

function PGCModule:RegPanel(name, path, layer, openAnimName, closeAnimName, enablePcEsc, customDisableRendering)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = enablePcEsc or false
  registerData.customDisableRendering = customDisableRendering or false
  self:RegisterPanel(registerData)
end

local function CreateActionNotifyBase()
  local rsp = {}
  rsp.space_base_data = {}
  rsp.space_base_data.space_time_ms = UE4.UNRCStatics.GetTimestampMS()
  rsp.space_base_data.operator_obj_id = 0
  rsp.space_base_data.simulate = true
  rsp.acts = {}
  return rsp
end

function PGCModule:OnOpenDataView()
  self:OpenPanel(PGCModuleEnum.PanelNames.DataView, {TypeName = "NPC_CONF", PrimaryKey = 10011})
end

function PGCModule:OnCloseDataView()
  local DataView = self:GetPanel(PGCModuleEnum.PanelNames.DataView)
  local DataList = DataView and DataView.DataList
  if not DataList then
    return
  end
  DataList:ForeachItemData(function(ItemData)
    RTTIBase.RemoveDataFlag(ItemData.Record, RTTIBase.DataFlagType.InEdit)
  end)
  DataList:ClearList(false)
  self:ClosePanel(PGCModuleEnum.PanelNames.DataView)
end

function PGCModule:OnLoadRecord(TypeName, PrimaryKey)
  local DataView = self:GetPanel(PGCModuleEnum.PanelNames.DataView)
  local DataList = DataView and DataView.DataList
  if not DataList then
    return
  end
  local Record = RTTIManager:QueryByPrimaryKey(TypeName, PrimaryKey)
  if Record and not RTTIBase.HasDataFlag(Record, RTTIBase.DataFlagType.InEdit) then
    local ItemData = {TypeName = TypeName, Record = Record}
    local Index = DataList:AppendData(ItemData)
    DataList:SelectItemByIndex(Index)
    RTTIBase.AddDataFlag(Record, RTTIBase.DataFlagType.InEdit)
  end
end

function PGCModule:OnSaveRecord(TypeName)
  local Result = RTTIManager:SaveDirtyBucket(TypeName)
  for _, SaveResult in ipairs(Result.Results) do
    if SaveResult.Success then
      self:OnRefreshDataState(TypeName, SaveResult.PrimaryKey)
    end
  end
end

function PGCModule:OnCloseRecord(TypeName, PrimaryKey)
  local DataView = self:GetPanel(PGCModuleEnum.PanelNames.DataView)
  local DataList = DataView and DataView.DataList
  if not DataList then
    return
  end
  local Record = RTTIManager:QueryByPrimaryKey(TypeName, PrimaryKey)
  if Record and RTTIBase.HasDataFlag(Record, RTTIBase.DataFlagType.InEdit) and not RTTIBase.HasDataFlag(Record, RTTIBase.DataFlagType.Dirty) then
    local Index = DataList:GetIndexByData(Record, function(DataRecord, ItemData)
      return ItemData.Record == DataRecord
    end)
    if Index then
      DataList:RemoveDataAt(Index)
      RTTIBase.RemoveDataFlag(Record, RTTIBase.DataFlagType.InEdit)
      local ActiveItemCount = DataList:GetActiveItemCount()
      if 0 == ActiveItemCount then
        self:OnShowDataDetail(nil)
      else
        if Index == ActiveItemCount then
          Index = Index - 1
        end
        DataList:SelectItemByIndex(Index)
      end
    end
  end
end

function PGCModule:OnAddRecord(TypeName)
  local Instance = RTTIManager:CreateInstance(TypeName)
  if nil ~= Instance then
    local PrimaryKeyValue = RTTIManager:GetPrimaryKeyValue(TypeName, Instance)
    self:OnLoadRecord(TypeName, PrimaryKeyValue)
  end
end

function PGCModule:OnRemoveRecord(TypeName, PrimaryKey)
  if RTTIManager:DestroyInstance(TypeName, PrimaryKey) then
    self:OnRefreshDataState(TypeName, PrimaryKey)
  end
end

function PGCModule:OnCreateNPC(PrimaryKey, Position)
  self:OnSimulateServerNPCEnter(PrimaryKey, Position)
end

function PGCModule:OnRefreshDataState(TypeName, PrimaryKey)
  local DataView = self:GetPanel(PGCModuleEnum.PanelNames.DataView)
  local DataList = DataView and DataView.DataList
  if not DataList then
    return
  end
  local Record = RTTIManager:QueryByPrimaryKey(TypeName, PrimaryKey)
  if Record then
    local Index = DataList:GetIndexByData(Record, function(DataRecord, ItemData)
      return ItemData.Record == DataRecord
    end)
    if Index then
      local DataItem = DataList:GetItemByIndex(Index)
      if DataItem and DataItem.RefreshState then
        DataItem:RefreshState()
      end
    end
  end
end

function PGCModule:OnShowDataSummary(TypeName, PrimaryKey)
  local DataView = self:GetPanel(PGCModuleEnum.PanelNames.DataView)
  if DataView then
    DataView.TypeName:SetText(TypeName)
    DataView.PrimaryKey:SetValue(PrimaryKey)
  end
end

function PGCModule:OnShowDataDetail(Data)
  local DataView = self:GetPanel(PGCModuleEnum.PanelNames.DataView)
  local DataDetail = DataView and DataView.DataDetail
  if DataDetail then
    DataDetail:ClearList(true)
    local Record = Data and Data.Record
    if Record then
      local TypeInfo = RTTIManager:GetTypeInfo(Data.TypeName)
      local FieldOrder = TypeInfo and TypeInfo.FieldOrder
      if FieldOrder then
        local FieldList = {}
        for _, FieldName in ipairs(FieldOrder) do
          local FieldInfo = TypeInfo.FieldInfos[FieldName]
          if FieldInfo then
            local FieldData = {
              RTTI = {TypeInfo = TypeInfo, FieldInfo = FieldInfo},
              Record = Data.Record
            }
            table.insert(FieldList, FieldData)
          end
        end
        DataDetail:InitList(FieldList)
      end
    end
  end
end

function PGCModule:OnShowEnumData(Values, Slot, State, OnItemSelected)
  self:ClosePanel(PGCModuleEnum.PanelNames.EnumView)
  if Values then
    local Data = {
      Values = Values,
      Slot = Slot,
      State = State,
      OnItemSelected = OnItemSelected
    }
    self:OpenPanel(PGCModuleEnum.PanelNames.EnumView, Data)
  end
end

function PGCModule:OnSimulateServerNPCEnter(configId, position)
  local rsp = CreateActionNotifyBase()
  local actor_enter = ProtoMessage:newSpaceAct_ActorEnter()
  local act = {actor_enter = actor_enter}
  table.insert(rsp.acts, act)
  local actor = {}
  table.insert(actor_enter.actors, actor)
  actor.actor_detail_type = ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Scene
  local npc_info = {}
  actor.npc = npc_info
  local base = {}
  npc_info.base = base
  base.detail_type = ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Scene
  base.actor_id = NRCModuleManager:DoCmd(NPCModuleCmd.AcquireFakeID)
  base.logic_id = base.actor_id
  base.born_time = rsp.space_base_data.space_time_ms / 1000
  base.enter_scene_times = 1
  base.lv = 1
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.serverData and localPlayer.serverData.base then
    base.owner_id = localPlayer.serverData.base.actor_id
  else
    base.owner_id = 0
  end
  if position then
    base.born_pt = {
      pos = {
        x = position.X + 200,
        y = position.Y,
        z = position.Z
      },
      dir = {
        x = 0,
        y = 0,
        z = 963
      }
    }
    base.pt = {
      pos = {
        x = position.X + 200,
        y = position.Y,
        z = position.Z
      },
      dir = {
        x = 0,
        y = 0,
        z = 963
      }
    }
  end
  local npc_base = {}
  npc_info.npc_base = npc_base
  npc_base.npc_cfg_id = configId
  local npcConf = DataConfigManager:GetNpcConf(configId)
  if not npcConf then
    Log.Error(string.format("[PGCModule] NPC\233\133\141\231\189\174\228\184\141\229\173\152\229\156\168\239\188\140\230\151\160\230\179\149\229\136\155\229\187\186NPC\239\188\140npc_cfg_id=%d", configId))
    return
  end
  local contentConfTable = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.NPC_REFRESH_CONTENT_CONF)
  local allContentConfs = contentConfTable:GetAllDatas()
  local foundContentId
  for contentId, contentConf in pairs(allContentConfs) do
    if contentConf.npc_id == configId then
      foundContentId = contentId
      break
    end
  end
  if not foundContentId then
    Log.Error(string.format("[PGCModule] NPC\229\136\183\230\150\176\229\134\133\229\174\185\233\133\141\231\189\174\228\184\141\229\173\152\229\156\168\239\188\140\230\151\160\230\179\149\229\136\155\229\187\186NPC\239\188\140npc_cfg_id=%d\227\128\130\232\175\183\230\163\128\230\159\165NPC_REFRESH_CONTENT_CONF\233\133\141\231\189\174\232\161\168\228\184\173\230\152\175\229\144\166\229\173\152\229\156\168npc_id=%d\231\154\132\232\174\176\229\189\149", configId, configId))
    return
  end
  npc_base.npc_content_cfg_id = foundContentId
  npc_base.height_scale = 1.0
  npc_base.refresh_point = 0
  npc_base.refresh_src = 1
  if localPlayer and localPlayer.serverData and localPlayer.serverData.base then
    npc_base.create_avatar_id = localPlayer.serverData.base.actor_id
  else
    npc_base.create_avatar_id = 0
  end
  local attrs = {}
  npc_info.attrs = attrs
  attrs.hp = 0
  attrs.hp_max = 0
  local npc_interact = {}
  npc_info.npc_interact = npc_interact
  if npcConf.option_id and #npcConf.option_id > 0 then
    local option_infos = {}
    npc_interact.option_infos = option_infos
    for _, optionId in ipairs(npcConf.option_id) do
      local optionConf = DataConfigManager:GetNpcOptionConf(optionId)
      if optionConf then
        local optionInfo = {}
        optionInfo.option_id = optionId
        optionInfo.enabled = true
        optionInfo.executable_times = optionConf.option_times or -1
        local action_type = optionConf.action and optionConf.action.action_type or Enum.ActionType.ACT_NONE
        if action_type == Enum.ActionType.ACT_DIALOG or action_type == Enum.ActionType.ACT_DIALOG_REALTIME or action_type == Enum.ActionType.ACT_DIALOGUE_LOCAL then
          local dialogId = tonumber(optionConf.action.action_param1)
          optionInfo.first_dialog_id = dialogId or 0
        else
          optionInfo.first_dialog_id = 0
        end
        table.insert(option_infos, optionInfo)
      end
    end
  end
  ZoneServer:BroadcastProcotolEvent(0, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY, rsp)
end

function PGCModule:OnSimulateServerNPCLeave(configId)
  local rsp = CreateActionNotifyBase()
  local actor_leave = ProtoMessage:newSpaceAct_ActorLeave()
  local act = {actor_leave = actor_leave}
  actor_leave.actor_ids = {configId}
  table.insert(rsp.acts, act)
  ZoneServer:BroadcastProcotolEvent(0, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY, rsp)
end

function PGCModule:OnSimulateServerOptionChange(npc_id, cur_dialog_id)
  local npc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, npc_id)
  if not npc then
    Log.Error(string.format("[PGCModule] \230\151\160\230\179\149\230\137\190\229\136\176NPC\239\188\140\230\151\160\230\179\149\230\168\161\230\139\159\233\128\137\233\161\185\229\143\152\230\155\180\239\188\140npc_id=%s", tostring(npc_id)))
    return
  end
  local npcConf = DataConfigManager:GetNpcConf(npc.config.id)
  if not (npcConf and npcConf.option_id) or 0 == #npcConf.option_id then
    Log.Error(string.format("[PGCModule] NPC\230\178\161\230\156\137\233\133\141\231\189\174\228\186\164\228\186\146\233\128\137\233\161\185\239\188\140\230\151\160\230\179\149\230\168\161\230\139\159\233\128\137\233\161\185\229\143\152\230\155\180\239\188\140npc_cfg_id=%d", npc.config.id))
    return
  end
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    Log.Error("[PGCModule] \230\151\160\230\179\149\232\142\183\229\143\150\230\156\172\229\156\176\231\142\169\229\174\182\239\188\140\230\151\160\230\179\149\230\168\161\230\139\159\233\128\137\233\161\185\229\143\152\230\155\180")
    return
  end
  local rsp = CreateActionNotifyBase()
  for _, optionId in ipairs(npcConf.option_id) do
    local optionConf = DataConfigManager:GetNpcOptionConf(optionId)
    if optionConf then
      local npc_option_info_change = {}
      npc_option_info_change.npc_id = npc_id
      npc_option_info_change.option_id = optionId
      npc_option_info_change.enabled = true
      npc_option_info_change.executable_times = optionConf.option_times or -1
      npc_option_info_change.enable_opt_gid = 0
      npc_option_info_change.succ_exec_times = 0
      npc_option_info_change.ineteracting_avatar_id = localPlayer.serverData.base.actor_id
      local action_type = optionConf.action and optionConf.action.action_type or Enum.ActionType.ACT_NONE
      if action_type == Enum.ActionType.ACT_DIALOG or action_type == Enum.ActionType.ACT_DIALOG_REALTIME or action_type == Enum.ActionType.ACT_DIALOGUE_LOCAL then
        local dialogId = tonumber(optionConf.action.action_param1)
        npc_option_info_change.first_dialog_id = dialogId or 0
      else
        npc_option_info_change.first_dialog_id = 0
      end
      local act_info = {}
      npc_option_info_change.act_info = act_info
      act_info.act_exec_success = true
      act_info.act_result_type = ProtoEnum.ActionResultType.ART_NONE
      act_info.act_status = ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Executing
      act_info.act_type = optionConf.action.action_type
      act_info.bound_dialog_id = 0
      act_info.btle_cfg_id = 0
      act_info.dialog_id = npc_option_info_change.first_dialog_id
      local dialogueConf = cur_dialog_id and DataConfigManager:GetDialogueConf(cur_dialog_id)
      act_info.next_dialog_id = dialogueConf and dialogueConf.next_dialog_id or 0
      local act = {npc_option_info_change = npc_option_info_change}
      table.insert(rsp.acts, act)
    end
  end
  ZoneServer:BroadcastProcotolEvent(0, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY, rsp)
  Log.Debug(string.format("[PGCModule] \229\183\178\230\168\161\230\139\159NPC\233\128\137\233\161\185\229\143\152\230\155\180\233\128\154\231\159\165\239\188\140npc_id=%s, option_count=%d", tostring(npc_id), #rsp.acts))
end

function PGCModule:OnSimulateServerNextAction(req, caller, callback)
  self:OnSimulateServerOptionChange(req.npc_id, req.cur_dialog_id)
  local rsp = ProtoMessage:newZoneSceneNpcNextActRsp()
  rsp.ret_info.ret_code = 0
  rsp.simulate = true
  if caller and callback then
    self.DelayList = self.DelayList or {}
    local delayId = _G.DelayManager:DelayFrames(1, function()
      if self.DelayList then
        self.DelayList[delayId] = nil
      end
      callback(caller, rsp)
    end)
    self.DelayList[delayId] = delayId
  end
end

return PGCModule
