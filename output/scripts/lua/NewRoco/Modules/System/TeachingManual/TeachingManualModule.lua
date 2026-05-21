local TeachingManualModuleEvent = require("NewRoco.Modules.System.TeachingManual.TeachingManualModuleEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local RedPointModuleEvent = require("NewRoco.Modules.System.RedPoint.RedPointModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local TipsDisplayController = require("NewRoco.Modules.System.TipsModule.TipsDisplayController")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local TeachingManualModule = NRCModuleBase:Extend("TeachingManualModule")

function TeachingManualModule:OnConstruct()
  _G.TeachingManualModuleCmd = reload("NewRoco.Modules.System.TeachingManual.TeachingManualModuleCmd")
  self.data = self:SetData("TeachingManualModuleData", "NewRoco.Modules.System.TeachingManual.TeachingManualModuleData")
  self:RegTeachManualPanel("TeachingManual", "UMG_TeachingManual", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "Page_Out")
  self:RegTeachManualPanel("TeachingUnlockTips", "UMG_TeachingUnlockTips", _G.Enum.UILayerType.UI_LAYER_POPUP, "Page_Out", true, true):SetEnableTouchMask(false)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_TEACH_UNLOCK_NOTIFY, self.OnPlayerTeachUnlockNotify)
  _G.NRCEventCenter:RegisterEvent("TeachingManualModule", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
  NRCEventCenter:RegisterEvent("TeachingManualModule", self, RedPointModuleEvent.RedPointChange, self.OnUpdateRedPointData)
  self.TipsTeachId = nil
  self.NeedOpenNew = false
  self.teachId = nil
  self.HasNewTeach = false
  self.hasSendTriggerEnumList = {}
  self.getTeachingUnlockTipsController = TipsDisplayController(TipEnum.TipObjectType.TeachingUnlockTips, self, self.OnPlayTips)
end

function TeachingManualModule:OnOpenMainPanel(NeedOpenNew, teachId)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_GUIDE, true)
  if isBan then
    return
  end
  self:MarkPanelWaitingOpen("TeachingManual")
  self.NeedOpenNew = NeedOpenNew
  self.teachId = teachId
  self:GetPlayerTeachInfoReq()
end

function TeachingManualModule:OnPlayTips()
  if self:HasPanel("TeachingUnlockTips") then
    self:ClosePanel("TeachingUnlockTips")
  end
  self:OpenPanel("TeachingUnlockTips")
end

function TeachingManualModule:OnEnterSceneFinishNtyAckCallBack(notify, isReconnecting, isEnteringCell)
  if isEnteringCell or isReconnecting then
    self:GetPlayerTeachInfoReq(true)
  end
end

function TeachingManualModule:EnableMainPanel()
  local panel = self:GetPanel("TeachingManual")
  if panel then
    panel:EnableAndShouldBanWorldRendering()
  end
end

function TeachingManualModule:PreLoadMainPanel()
  self:PreLoadPanel("TeachingManual", 10)
end

function TeachingManualModule:CmdOpenMainPanelByTeachId(teachId)
  self:OnOpenMainPanel(true, teachId)
end

function TeachingManualModule:GetIsShowRed()
  if self.data.TeachManualList and #self.data.TeachManualList > 0 then
    local num = #self.data.TeachManualList
    for i = 1, num do
      local TeachList = self.data.TeachManualList[i].TeachList
      for j = 1, #TeachList do
        if TeachList[j].Status ~= ProtoEnum.PlayerTeachInfo.TeachStatus.READED then
          return true
        end
      end
      if i == num then
        if self.HasNewTeach then
          return true
        else
          return false
        end
      end
    end
  else
    return true
  end
end

function TeachingManualModule:OnActive()
end

function TeachingManualModule:IsPCMode()
  if RocoEnv.IS_EDITOR then
    return _G.GlobalConfig.bEditorAsPcInTeachManual or false
  else
    return RocoEnv.PLATFORM == "PLATFORM_WINDOWS"
  end
end

function TeachingManualModule:OnPlayerTeachUnlockNotify(_notify)
  Log.Debug(_notify.teach_id, "OnPlayerTeachUnlockNotify")
  local teachConf = _G.DataConfigManager:GetTeachConf(_notify.teach_id)
  self.TipsTeachId = _notify.teach_id
  self.HasNewTeach = true
  if not teachConf.unlock_remind then
    return
  end
  if teachConf.teach_platform == Enum.Teachplatform.PLAT_ALL then
  elseif teachConf.teach_platform == Enum.Teachplatform.PLAT_PC and not self:IsPCMode() then
    return
  elseif teachConf.teach_platform == Enum.Teachplatform.PLAT_MOBILE and self:IsPCMode() then
    return
  end
  local ShowTimeConf = _G.DataConfigManager:GetGlobalConfigByKeyType("teach_unlock_show_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG)
  local ShowTime = 3
  if ShowTimeConf and ShowTimeConf.num then
    ShowTime = ShowTimeConf.num
  end
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.AddTip, TipObject.CreateTeachingUnlockTips({
    TeachId = _notify.teach_id,
    countdown = ShowTime,
    priority = teachConf.unlock_remind_priority
  }))
end

function TeachingManualModule:GetPlayerTeachInfoReq(NotOpen)
  self.NotOpen = NotOpen
  local req = _G.ProtoMessage:newZoneGetPlayerTeachInfoReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_TEACH_INFO_REQ, req, self, self.OnZoneGetPlayerTeachInfoRsp)
end

function TeachingManualModule:OnZoneGetPlayerTeachInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    Log.Dump(rsp, 6, "TeachingManualModule:OnZoneGetPlayerTeachInfoRsp")
    self.data.TeachManualData = rsp.teach_infos
    self.data:InitializeInfo(self, self.OnTeachDataApplyFor, self.NeedOpenNew, self.teachId)
  else
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  end
end

function TeachingManualModule:OnZoneUnlockTeachConditionReq(unlockEnum)
  local req = _G.ProtoMessage:newZoneUnlockTeachConditionReq()
  req.client_trigger = unlockEnum
  local hasSend = false
  if #self.hasSendTriggerEnumList > 0 then
    for k, v in ipairs(self.hasSendTriggerEnumList) do
      if unlockEnum == v then
        hasSend = true
      end
    end
  end
  if false == hasSend then
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UNLOCK_TEACH_CONDITION_REQ, req, self, self.OnZoneUnlockTeachConditionRsp)
    table.insert(self.hasSendTriggerEnumList, unlockEnum)
  end
end

function TeachingManualModule:OnZoneUnlockTeachConditionRsp(rsp)
end

function TeachingManualModule:OnTeachDataApplyFor()
  if not self.NotOpen then
    self:OpenPanel("TeachingManual")
  end
end

function TeachingManualModule:OnRelogin()
end

function TeachingManualModule:OnUpdateRedPointData(notify)
end

function TeachingManualModule:OnDeactive()
end

function TeachingManualModule:OnDestruct()
  NRCEventCenter:UnRegisterEvent(self, RedPointModuleEvent.RedPointChange, self.OnUpdateRedPointData)
end

function TeachingManualModule:OnCmdSelectTeachIndex(TeachConf, _index)
  self.data:SetTeachSelectIndex(TeachConf.list_type, _index)
  self:DispatchEvent(TeachingManualModuleEvent.SelectTeachListIndex, TeachConf)
end

function TeachingManualModule:OnCmdGetSelectTeachManualIndex()
  return self.data:GetSelectTeachManualIndex()
end

function TeachingManualModule:OnCmdGetManualListByTeachManualIndex(_SelectTeachManualIndex)
  return self.data:GetManualListByTeachManualIndex(_SelectTeachManualIndex)
end

function TeachingManualModule:OnCmdSelectViewPicture(GuideStruct, _index)
  self:DispatchEvent(TeachingManualModuleEvent.SelectViewPicture, GuideStruct, _index)
end

function TeachingManualModule:RegTeachManualPanel(name, path, layer, closeAnimName, disablePcEsc, disableLoadBlock)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/TeachingManual/Res/%s", path)
  registerData.panelLayer = layer
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = not disablePcEsc
  registerData.disableLoadBlock = disableLoadBlock
  self:RegisterPanel(registerData)
  return registerData
end

function TeachingManualModule:ResetTeachId()
  self.teachId = nil
end

function TeachingManualModule:CloseTeachingManual()
  local hasPanel = self:HasPanel("TeachingManual")
  if hasPanel then
    local panel = self:GetPanel("TeachingManual")
    if panel then
      panel:OnCloseBtn()
    end
  end
end

function TeachingManualModule:JumpToRelatedFunction(cmd, ...)
  if not cmd or type(cmd) ~= "string" or string.IsNilOrEmpty(cmd) then
    Log.Error("TeachingManualModule:JumpToRelatedFunction \228\188\160\229\133\165cmd\233\157\158\230\179\149 %s\239\188\140\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174", cmd)
    return
  end
  _G.NRCModuleManager:DoCmd(cmd, ...)
end

return TeachingManualModule
