local AlchemyModule = NRCModuleBase:Extend("AlchemyModule")
_G.AlchemyModuleEvent = require("NewRoco.Modules.System.Alchemy.AlchemyModuleEvent")
_G.AlchemyModuleCmd = require("NewRoco.Modules.System.Alchemy.AlchemyModuleCmd")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local AlchemyUtils = require("NewRoco.Modules.System.Alchemy.AlchemyUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local SkillShowComponent = require("NewRoco.Modules.Core.Scene.Component.Show.SkillShowComponent")
local ResQueue = require("NewRoco.Utils.ResQueue")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local AlchemyShowStatusEnum = {
  IDLE = 1,
  WAIT_RSP = 2,
  DO_ADD_MATERIAL = 3,
  WAIT_SHOW_RES = 4,
  DO_SHOW = 5,
  SHOW_REWARD = 6
}

function AlchemyModule:OnConstruct()
  self.data = self:SetData("AlchemyModuleData", "NewRoco.Modules.System.Alchemy.AlchemyModuleData")
  self.upgrade_item_id = 0
  self.upgrade_item_type = 0
  self.exchange_id = 0
  self.exchange_index = 0
  self.recipe_index = 0
  self.exchange_num = 0
  self.current_action = nil
  self.ironPan = nil
  self.origin_value = 0
  self.target_value = 0
  self.lastRoleLevel = -1
  self.lastWorldLevel = -1
  self.UnlockExchangeData = {}
  self.isBuildHash = false
  self.itemHash = {}
  self.status = AlchemyShowStatusEnum.IDLE
  self.should_skip = false
  self.waitingForRequestForUpgradeProtocol = nil
  self.materialExchangeId = 0
  self.materialItemNum = 0
  self.AlternateMaterials = {}
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenAlchemyPanel, self.OpenAlchemyPanel)
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenArdourPanel, self.OpenArdourUpPanel)
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenRecoverTimeUpPanel, self.OpenRecoverTimeUpPanel)
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenRecoverUpPanel, self.OpenRecoverUpPanel)
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenVitalityPanel, self.OpenVitalityPanel)
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenMagicStudyPanel, self.OpenMagicStudyPanel)
  self:RegisterCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.UpdateMaterialItems)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetMaterialItems, self.GetMaterialItems)
  self:RegisterCmd(_G.AlchemyModuleCmd.CloseMaterialItems, self.CloseMaterialItems)
  self:RegisterCmd(_G.AlchemyModuleCmd.DisappearAllMaterial, self.DisappearAllMaterial)
  self:RegisterCmd(_G.AlchemyModuleCmd.RequestExchangeInBattle, self.RequestExchangeInBattle)
  self:RegisterCmd(_G.AlchemyModuleCmd.RequestForExchange, self.RequestForExchange)
  self:RegisterCmd(_G.AlchemyModuleCmd.RequestForUpgrade, self.RequestForUpgrade)
  self:RegisterCmd(_G.AlchemyModuleCmd.HideUI, self.HideUI)
  self:RegisterCmd(_G.AlchemyModuleCmd.ShowUI, self.ShowUI)
  self:RegisterCmd(_G.AlchemyModuleCmd.HideMaterial1, self.HideMaterial1)
  self:RegisterCmd(_G.AlchemyModuleCmd.HideMaterial2, self.HideMaterial2)
  self:RegisterCmd(_G.AlchemyModuleCmd.HideMaterial3, self.HideMaterial3)
  self:RegisterCmd(_G.AlchemyModuleCmd.HideMaterial4, self.HideMaterial4)
  self:RegisterCmd(_G.AlchemyModuleCmd.ShowReward, self.ShowReward)
  self:RegisterCmd(_G.AlchemyModuleCmd.ShowRewardFinish, self.ShowRewardFinish)
  self:RegisterCmd(_G.AlchemyModuleCmd.RegisterIronPan, self.RegisterIronPan)
  self:RegisterCmd(_G.AlchemyModuleCmd.UnRegisterIronPan, self.UnRegisterIronPan)
  self:RegisterCmd(_G.AlchemyModuleCmd.EndCurrentAction, self.EndCurrentAction)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetRoleHpMaxData, self.GetRoleHpData)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetBottleTimeData, self.GetBottleTimeData)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetBottleVolumeData, self.GetBottleVolumeData)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetVitalityData, self.GetRoleVitalityData)
  self:RegisterCmd(_G.AlchemyModuleCmd.PlayPerformById, self.PlayPerformById)
  self:RegisterCmd(_G.AlchemyModuleCmd.IsBottleVolumeUpgradeEnable, self.IsBottleVolumeUpgradeEnable)
  self:RegisterCmd(_G.AlchemyModuleCmd.IsBottleTimeUpgradeEnable, self.IsBottleTimeUpgradeEnable)
  self:RegisterCmd(_G.AlchemyModuleCmd.IsRoleHpUpgradeEnable, self.IsRoleHpUpgradeEnable)
  self:RegisterCmd(_G.AlchemyModuleCmd.IsRolePowerUpgradeEnable, self.IsRolePowerUpgradeEnable)
  self:RegisterCmd(_G.AlchemyModuleCmd.ResumeRoleHpShow, self.ResumeRoleHpShow)
  self:RegisterCmd(_G.AlchemyModuleCmd.PauseRoleHpShow, self.PauseRoleHpShow)
  self:RegisterCmd(_G.AlchemyModuleCmd.DoRoleHpShow, self.DoRoleHpShow)
  self:RegisterCmd(_G.AlchemyModuleCmd.DoFixPerform, self.DoFixPerform)
  self:RegisterCmd(_G.AlchemyModuleCmd.ReleaseCamera, self.ReleaseCamera)
  self:RegisterCmd(_G.AlchemyModuleCmd.SetAlchemyItem, self.SetAlchemyItem)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetAlchemyItem, self.GetAlchemyItem)
  self:RegisterCmd(_G.AlchemyModuleCmd.EnableClick, self.EnableClick)
  self:RegisterCmd(_G.AlchemyModuleCmd.DisableClick, self.DisableClick)
  self:RegisterCmd(_G.AlchemyModuleCmd.OnMagicalStudyItemClicked, self.OnMagicalStudyItemClicked)
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenAlternativeFormula, self.OnCmdOpenAlternativeFormula)
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenAlchemySort, self.OnCmdOpenAlchemySort)
  self:RegisterCmd(_G.AlchemyModuleCmd.SelectManufactureBasicType, self.OnCmdSelectManufactureBasicType)
  self:RegisterCmd(_G.AlchemyModuleCmd.OpenAlternateMaterial, self.OnCmdOpenAlternateMaterial)
  self:RegisterCmd(_G.AlchemyModuleCmd.CloseAlternateMaterial, self.OnCmdCloseAlternateMaterial)
  self:RegisterCmd(_G.AlchemyModuleCmd.SetExchangeMaterial, self.OnCmdSetExchangeMaterial)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetCostMaterialItems, self.OnCmdGetCostMaterialItems)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetAlternateMaterials, self.OnCmdGetAlternateMaterials)
  self:RegisterCmd(_G.AlchemyModuleCmd.ResetAlternateMaterials, self.OnCmdResetAlternateMaterials)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetMaterialNum, self.OnCmdGetMaterialNum)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetSortGoodsList, self.OnCmdGetSortGoodsList)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetFilterBasicList, self.OnCmdGetFilterBasicList)
  self:RegisterCmd(_G.AlchemyModuleCmd.TestOpenAlchemyPanel, self.CmdTestOpenAlchemyPanel)
  self:RegisterCmd(_G.AlchemyModuleCmd.TestOpenMagicalStudy, self.CmdTestOpenMagicalStudy)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetUnlockExchange, self.GetUnlockExchange)
  self:RegisterCmd(_G.AlchemyModuleCmd.ShowMaterialItems, self.ShowMaterialItems)
  self:RegisterCmd(_G.AlchemyModuleCmd.SkipShow, self.SkipShow)
  self:RegisterCmd(_G.AlchemyModuleCmd.CheckExchangeAvailable, self.OnCmdCheckExchangeAvailable)
  self:RegisterCmd(_G.AlchemyModuleCmd.CheckExchangeUnlock, self.CheckExchangeUnlock)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetItemSynthesisInfo, self.OnCmdGetItemSynthesisInfo)
  self:RegisterCmd(_G.AlchemyModuleCmd.GetAlchemyStatus, self.OnCmdGetAlchemyStatus)
  self:RegisterCmd(_G.AlchemyModuleCmd.CheckWaitingFormRequestUpgradeProtocol, self.OnCmdCheckWaitingFormRequestUpgradeProtocol)
  _G.NRCEventCenter:RegisterEvent("AlchemyModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, SceneEvent.PreLoadMapStart, self.OnDialogueEnded)
  _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:RegisterEvent("UMG_AlchemyPanel_C", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDialogueEnded)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_UNLOCK_EXCHANGE_RECIPE_NOTIFY, self.OnZoneUnlockExchangeRecipeNotify)
  self:RegPanel("AlchemyPanel", "UMG_AlchemyPanel", _G.Enum.UILayerType.UI_LAYER_DIALOGUE, nil, nil, true, nil, true)
  self:RegPanel("ArdourUpPanel", "UMG_ArdourUpPanel", _G.Enum.UILayerType.UI_LAYER_DIALOGUE, nil, nil, true, nil, true)
  self:RegPanel("RecoverTimeUpPanel", "UMG_RecoverTimeUpPanel", _G.Enum.UILayerType.UI_LAYER_DIALOGUE, nil, nil, true, nil, true)
  self:RegPanel("RecoverUpPanel", "UMG_RecoverUpPanel", _G.Enum.UILayerType.UI_LAYER_DIALOGUE, nil, nil, true, nil, true)
  self:RegPanel("MaterialItems", "UMG_MaterialItemsPanel", _G.Enum.UILayerType.UI_LAYER_DIALOGUE, nil, nil, nil, true)
  self:RegPanel("VitalityPanel", "UMG_Alchemy_VitalityPanel", _G.Enum.UILayerType.UI_LAYER_DIALOGUE, nil, nil, true, nil, true)
  self:RegPanel("MagicalStudy", "UMG_MagicalStudy", _G.Enum.UILayerType.UI_LAYER_DIALOGUE, nil, nil, true)
  self:RegPanel("RecoverUpTips", "UMG_RecoverUpTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("RecoverTimeUpTips", "UMG_RecoverTimeUpTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ArdourUpTips", "UMG_ArdourUpTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AlchemyItem_tips", "UMG_AlchemyItem_tips", _G.Enum.UILayerType.UI_LAYER_POPUP, "In", "Out")
  self:RegPanel("VitalityUpTips", "UMG_Alchemy_VitalityUpTips", _G.Enum.UILayerType.UI_LAYER_POPUP, "In", "Out")
  self:RegPanel("AlternativeFormula", "UMG_AlternativeFormula", _G.Enum.UILayerType.UI_LAYER_POPUP, "In", "Out")
  self:RegPanel("AlchemySort", "UMG_AlchemySort", _G.Enum.UILayerType.UI_LAYER_POPUP, "Open", "Close")
  self:RegPanel("AlternateMaterial", "UMG_AlternateMaterial", _G.Enum.UILayerType.UI_LAYER_POPUP, "In", "Out")
  self:RegPanel("AlchemySkip", "UMG_AlchemySkip", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:CalculateMaxValue()
  local req_unlock = _G.ProtoMessage:newZoneGetUnlockedExchangeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoEnum.ZoneSvrCmd.ZONE_GET_UNLOCKED_EXCHANGE_REQ, req_unlock, self, self.OnZoneGetUnlockedExchangeRsp, true, true)
end

function AlchemyModule:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PreLoadMapStart, self.OnDialogueEnded)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDialogueEnded)
  self.waitingForRequestForUpgradeProtocol = nil
end

function AlchemyModule:OnMagicalStudySubPanelClosed()
end

function AlchemyModule:OnDialogueEnded(bIsReconnected)
  if self.ironPan then
    local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.viewObj then
      localPlayer:StopAllMontage(0.1)
      localPlayer.viewObj.RocoSkill:StopCurrentSkill()
    end
    if localPlayer then
      local skillShowComp = localPlayer:GetComponent(SkillShowComponent)
      if skillShowComp then
        skillShowComp:StopAll()
      end
    end
    self:ReleaseCamera()
    self:ClosePanelByLayer(_G.Enum.UILayerType.UI_LAYER_DIALOGUE)
    self:ClosePanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
    if UE4.UObject.IsValid(self.ironPan) then
      if self.ironPan.ExitDuanzao then
        self.ironPan:ExitDuanzao()
      end
      if self.ironPan.ExitAlchemy then
        self.ironPan:ExitAlchemy()
      end
    end
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UnRegisterIronPan)
    DialogueUtils.UnlockPlayerMove()
  end
end

function AlchemyModule:DoRoleHpShow()
end

function AlchemyModule:ResumeRoleHpShow()
end

function AlchemyModule:PauseRoleHpShow()
end

function AlchemyModule:RegisterIronPan(ironPan)
  self.ironPan = ironPan
end

function AlchemyModule:UnRegisterIronPan()
  self.ironPan = nil
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.HoldingItemComponent then
    localPlayer.HoldingItemComponent:UnRegisterItem("ironPan")
  end
end

function AlchemyModule:EndCurrentAction()
  if self.current_action then
    self.current_action:EndAction()
  end
  self.current_action = nil
end

function AlchemyModule:HideMaterial1()
  _G.NRCAudioManager:PlaySound2DAuto(1374, "HideMaterial")
  if self:HasPanel("MaterialItems") then
    local panel = self:GetPanel("MaterialItems")
  end
end

function AlchemyModule:HideMaterial2()
  _G.NRCAudioManager:PlaySound2DAuto(1374, "HideMaterial")
  if self:HasPanel("MaterialItems") then
    local panel = self:GetPanel("MaterialItems")
  end
end

function AlchemyModule:HideMaterial3()
  _G.NRCAudioManager:PlaySound2DAuto(1374, "HideMaterial")
  if self:HasPanel("MaterialItems") then
    local panel = self:GetPanel("MaterialItems")
  end
end

function AlchemyModule:HideMaterial4()
  _G.NRCAudioManager:PlaySound2DAuto(1374, "HideMaterial")
  if self:HasPanel("MaterialItems") then
    local panel = self:GetPanel("MaterialItems")
  end
end

function AlchemyModule:ShowReward()
  if not self.ironPan then
    Log.Trace("AlchemyModule:ShowReward \233\152\178\228\189\143\228\186\134")
    return
  end
  self:CloseSkipPanel()
  self:SetStatus(AlchemyShowStatusEnum.SHOW_REWARD)
  if 0 == self.upgrade_item_type then
    local resListData = _G.NRCPanelResLoadData()
    resListData.PreLoadResList = {}
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(self.exchange_id)
    if #exchangeConf.get_item > 1 then
      Log.Error("\230\137\147\233\128\160\229\135\186\228\186\134\229\164\154\228\184\170\239\188\140\232\191\153\228\184\170UI\231\187\147\230\158\132\228\184\141\230\148\175\230\140\129\239\188\140\232\175\183\230\143\144\228\191\174\230\148\185\233\156\128\230\177\130")
    end
    local get_goods_id = exchangeConf.get_item[1].get_goods_id
    local get_goods_type = exchangeConf.get_item[1].get_goods_type
    local big_icon
    if get_goods_type == _G.Enum.GoodsType.GT_BAGITEM then
      local BagItem = _G.DataConfigManager:GetBagItemConf(get_goods_id)
      big_icon = BagItem and BagItem.big_icon
    elseif get_goods_type == _G.Enum.GoodsType.GT_VITEM then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(get_goods_id)
      big_icon = vItemConf and vItemConf.bigIcon
    else
      Log.Error("\230\137\147\233\128\160\231\154\132\231\177\187\229\158\139\230\154\130\228\184\141\230\148\175\230\140\129")
    end
    table.insert(resListData.PreLoadResList, big_icon)
    self:OpenPanel("AlchemyItem_tips", {
      exchange_id = self.exchange_id,
      exchange_num = self.exchange_num
    }, resListData)
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_ROLE_HP_MAX then
    self:OpenPanel("ArdourUpTips", {
      origin_value = self.origin_value,
      target_value = self.target_value
    })
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_BOTTLE_TIMES then
    self:OpenPanel("RecoverTimeUpTips", {
      origin_value = self.origin_value,
      target_value = self.target_value
    })
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_BOTTLE_VOLUME then
    self:OpenPanel("RecoverUpTips", {
      origin_value = self.origin_value,
      target_value = self.target_value
    })
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_STAMINA then
    self:OpenPanel("VitalityUpTips", {
      origin_upgradeId = self.upgrade_item_id
    })
  end
end

function AlchemyModule:OnCmdCheckWaitingFormRequestUpgradeProtocol()
  return self.waitingForRequestForUpgradeProtocol
end

function AlchemyModule:HideUI()
  _G.NRCEventCenter:DispatchEvent(_G.AlchemyModuleEvent.AlchemyOnHideUI, self.upgrade_item_type)
  self:OpenSkipPanel()
  if self.upgrade_item_type == _G.Enum.VisualItem.VI_ROLE_HP_MAX then
    self:HidePanel("ArdourUpPanel", {
      upgrade_item_id = self.upgrade_item_id
    })
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_BOTTLE_TIMES then
    self:HidePanel("RecoverTimeUpPanel", {
      upgrade_item_id = self.upgrade_item_id
    })
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_BOTTLE_VOLUME then
    self:HidePanel("RecoverUpPanel", {
      upgrade_item_id = self.upgrade_item_id
    })
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_STAMINA then
    self:HidePanel("VitalityPanel", {
      upgrade_item_id = self.upgrade_item_id
    })
  elseif 0 == self.upgrade_item_type then
    self:HidePanel("AlchemyPanel", {
      exchange_id = self.exchange_id,
      exchange_num = self.exchange_num
    })
  end
end

function AlchemyModule:ShowUI()
  _G.NRCEventCenter:DispatchEvent(_G.AlchemyModuleEvent.AlchemyOnShowUI, self.upgrade_item_type)
  if self.upgrade_item_type == _G.Enum.VisualItem.VI_ROLE_HP_MAX then
    self:ShowPanel("ArdourUpPanel")
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_BOTTLE_TIMES then
    self:ShowPanel("RecoverTimeUpPanel")
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_BOTTLE_VOLUME then
    self:ShowPanel("RecoverUpPanel")
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_STAMINA then
    self:ShowPanel("VitalityPanel")
  elseif 0 == self.upgrade_item_type then
    self:ShowPanel("AlchemyPanel")
  end
end

function AlchemyModule:RequestForUpgrade(item_type, upgrade_id, exchangeId, origin_value, target_value)
  self.waitingForRequestForUpgradeProtocol = true
  local req = _G.ProtoMessage:newZoneVisualItemUpgradeReq()
  req.visual_item_type = item_type
  req.visual_item_upgrade_conf_id = upgrade_id
  self.upgrade_item_type = item_type
  self.upgrade_item_id = upgrade_id
  self.exchange_id = exchangeId
  self.exchange_num = 0
  self.origin_value = origin_value
  self.target_value = target_value
  if self.ironPan and self.ironPan.sceneCharacter then
    req.npc_space_obj_id = self.ironPan.sceneCharacter.serverData.base.actor_id
  else
    Log.Error("\231\130\188\233\135\145\239\188\140\228\189\134\230\152\175\230\137\190\228\184\141\229\136\176\231\130\188\233\135\145\231\154\132\233\148\133")
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_VISUAL_ITEM_UPGRADE_REQ, req, self, self.OnUpgradeRsp, true)
end

function AlchemyModule:OnUpgradeRsp(rsp)
  self.waitingForRequestForUpgradeProtocol = nil
  if not self.ironPan then
    Log.Trace("AlchemyModule:OnUpgradeRsp \233\152\178\228\189\143\228\186\134")
    return
  end
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    self:PlayAddMaterials()
  else
    self:ShowUI()
    if rsp.ban_info and rsp.ban_info.ban_reason then
      Log.Error("\229\138\159\232\131\189\229\176\129\231\166\129\228\184\173:", rsp.ban_info.ban_reason)
    else
      Log.Error("\229\176\157\232\175\149\230\137\147\233\128\160\229\164\177\232\180\165\239\188\140\228\184\138\228\184\128\230\172\161\229\135\186\231\142\176\232\191\153\228\184\170\233\151\174\233\162\152\230\152\175\231\173\150\229\136\146\230\148\185\228\186\134\233\133\141\231\189\174", table.tostring(rsp))
    end
  end
end

function AlchemyModule:RequestExchangeInBattle(exchangeId, exchangeNum, costItemList)
  self.upgrade_item_type = 0
  self.upgrade_item_id = 0
  self.exchange_id = exchangeId
  self.exchange_num = exchangeNum
  local iron_id = 0
  local req = _G.ProtoMessage:newZoneExchangeReq()
  req.exchange_item.id = self.exchange_id
  req.exchange_item.num = self.exchange_num
  for _, item in ipairs(costItemList) do
    if item.goods_num > 0 then
      table.insert(req.exchange_item.cost_goods, {
        goods_type = item.goods_type,
        goods_id = item.goods_id,
        goods_num = item.goods_num
      })
    end
  end
  req.npc_space_obj_id = iron_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_EXCHANGE_REQ, req, self, self.OnExchangeInBattleRsp, true, true)
end

function AlchemyModule:OnExchangeInBattleRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 then
      _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, rsp.ret_info.goods_reward.rewards)
    end
    _G.NRCEventCenter:DispatchEvent(_G.AlchemyModuleEvent.RequestExchangeSuccess)
  else
    if rsp.ban_info and rsp.ban_info.ban_reason then
      Log.Error("\229\138\159\232\131\189\229\176\129\231\166\129\228\184\173:", rsp.ban_info.ban_reason)
    end
    if rsp.ret_info and rsp.ret_info.ret_code then
      Log.Error("OnExchangeInBattleRsp \229\144\136\230\136\144\229\164\177\232\180\165,ret_code=", rsp.ret_info.ret_code)
    end
  end
end

function AlchemyModule:RequestForExchange(exchangeId, exchangeNum, costItemList)
  self.upgrade_item_type = 0
  self.upgrade_item_id = 0
  self.exchange_id = exchangeId
  self.exchange_num = exchangeNum
  local iron_id = 0
  if self.ironPan and self.ironPan.sceneCharacter then
    iron_id = self.ironPan.sceneCharacter.serverData.base.actor_id
  else
  end
  local req = _G.ProtoMessage:newZoneExchangeReq()
  req.exchange_item.id = self.exchange_id
  req.exchange_item.num = self.exchange_num
  for _, item in ipairs(costItemList) do
    if item and item.goods_num and item.goods_num > 0 then
      table.insert(req.exchange_item.cost_goods, {
        goods_type = item.goods_type,
        goods_id = item.goods_id,
        goods_num = item.goods_num
      })
    end
  end
  req.npc_space_obj_id = iron_id
  self:SetStatus(AlchemyShowStatusEnum.WAIT_RSP)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_EXCHANGE_REQ, req, self, self.OnExchangeRsp, true, true)
end

function AlchemyModule:OnExchangeRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnUseFormulaSuccess)
  end
  if not self.ironPan then
    self:SetStatus(AlchemyShowStatusEnum.IDLE)
    Log.Trace("AlchemyModule:OnExchangeRsp \233\152\178\228\189\143\228\186\134")
    return
  end
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    self:PlayAddMaterials()
  elseif rsp.ret_info and rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_EXCHANGE_IS_LOCKED then
    self:SetStatus(AlchemyShowStatusEnum.IDLE)
    local Ctx = DialogContext()
    Ctx:SetTitle(_G.LuaText.TIPS)
    Ctx:SetContent(_G.LuaText.exchange_list_refresh)
    Ctx:SetDialogType(DialogContext.DialogType.GeneralTip)
    Ctx:SetMode(DialogContext.Mode.NotBtn)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
    self:ShowUI()
  else
    self:SetStatus(AlchemyShowStatusEnum.IDLE)
    if rsp.ret_info and rsp.ret_info.ret_code then
      local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
    end
    self:ShowUI()
    if rsp.ban_info and rsp.ban_info.ban_reason then
      Log.Error("\229\138\159\232\131\189\229\176\129\231\166\129\228\184\173:", rsp.ban_info.ban_reason)
    else
      Log.Error("\229\144\136\230\136\144\229\164\177\232\180\165\239\188\140\229\137\141\229\144\142\229\143\176\229\143\175\232\131\189\229\173\152\229\156\168\228\184\141\228\184\128\232\135\180\239\188\140\232\175\183\230\155\180\230\150\176", table.tostring(rsp))
      Log.Error("\229\176\157\232\175\149\230\137\147\233\128\160\229\164\177\232\180\165\239\188\140\228\184\138\228\184\128\230\172\161\229\135\186\231\142\176\232\191\153\228\184\170\233\151\174\233\162\152\230\152\175\231\173\150\229\136\146\230\148\185\228\186\134\233\133\141\231\189\174", table.tostring(rsp))
    end
  end
end

function AlchemyModule:PlayAddMaterials()
  if not self.ironPan then
    self:SetStatus(AlchemyShowStatusEnum.IDLE)
    Log.Trace("AlchemyModule:PlayAddMaterials \233\152\178\228\189\143\228\186\134")
    return
  end
  if self.should_skip then
    self:ShowReward()
    return
  end
  self:SetStatus(AlchemyShowStatusEnum.DO_ADD_MATERIAL)
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.ShowMaterialItems)
  local exchange_conf = _G.DataConfigManager:GetExchangeConf(self.exchange_id)
  if exchange_conf then
    if 1 == #exchange_conf.cost_item then
      self:PlayPerformById(104, self, self.PlayAlchemyShow)
    elseif 2 == #exchange_conf.cost_item then
      self:PlayPerformById(105, self, self.PlayAlchemyShow)
    elseif 3 == #exchange_conf.cost_item then
      self:PlayPerformById(106, self, self.PlayAlchemyShow)
    elseif 4 == #exchange_conf.cost_item then
      self:PlayPerformById(107, self, self.PlayAlchemyShow)
    else
      Log.Error("\233\133\141\230\150\185\233\133\141\231\189\174\231\148\177\233\151\174\233\162\152\239\188\140\232\175\183\230\137\190\231\173\150\229\136\146", self.exchange_id)
    end
  else
    Log.Error("\232\191\153\233\135\140\228\184\128\229\174\154\230\152\175\229\135\186\233\151\174\233\162\152\231\154\132\239\188\140\230\138\165\229\164\167\233\148\153")
  end
end

function AlchemyModule:ShowMaterialItems()
  if self:HasPanel("MaterialItems") then
    local panel = self:GetPanel("MaterialItems")
    panel:ShowAll()
    panel:DoAllShow()
    panel:CleanUp()
  end
end

function AlchemyModule:PlayAlchemyShow()
  if not self.ironPan then
    Log.Trace("AlchemyModule:PlayAlchemyShow \233\152\178\228\189\143\228\186\134")
    self:SetStatus(AlchemyShowStatusEnum.IDLE)
    return
  end
  if self.should_skip then
    self:ShowReward()
    return
  end
  self:SetStatus(AlchemyShowStatusEnum.WAIT_SHOW_RES)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.LoadQueue = ResQueue()
  self.LoadQueue:InsertObject("Wand", localPlayer:GetCurWandPath(), _G.PriorityEnum.Active_Player_Action)
  self.LoadQueue:InsertObject("MoZhang", "Blueprint'/Game/NewRoco/Modules/Core/NPC/MagicStar/BP_MoZhang.BP_MoZhang_C'", _G.PriorityEnum.Active_Player_Action)
  self.LoadQueue:StartLoad(self, self.PlayAlchemyShowReal)
end

function AlchemyModule:PlayAlchemyShowReal(Queue, Success)
  self.LoadQueue = nil
  if not self.ironPan then
    Log.Trace("AlchemyModule:PlayAlchemyShowReal \233\152\178\228\189\143\228\186\134")
    Queue:Release()
    self:SetStatus(AlchemyShowStatusEnum.IDLE)
    return
  end
  self:SetStatus(AlchemyShowStatusEnum.DO_SHOW)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Success then
    Log.Error("Load Wand Failed!!!", localPlayer:GetCurWandPath())
  end
  local quat = UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, 0)
  local World = _G.UE4Helper.GetCurrentWorld()
  local fTransform = UE4.FTransform(quat, UE4.FVector(-10000, -10000, -10000))
  local MoZhangActor = World:Abs_SpawnActor(Queue:Get("MoZhang"), fTransform, UE4.ESpawnActorCollisionHandlingMethod.AdjustIfPossibleButAlwaysSpawn, nil, nil, nil, {})
  local wandMesh = Queue:Get("Wand")
  wandMesh = wandMesh or NPCLuaUtils.GetClass("SkeletalMesh'/Game/ArtRes/AnimSequence/Human/PC/PC3/Avatar/Mw/32500101/SKM_PC3_Mw_32500101.SKM_PC3_Mw_32500101'")
  MoZhangActor.SkeletalMesh:SetSkeletalMesh(wandMesh)
  localPlayer.HoldingItemComponent:RegisterItem("mozhang", MoZhangActor)
  Queue:Release()
  if 0 == self.upgrade_item_type then
    self:PlayPerformById(108, self, self.DoNothing)
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_ROLE_HP_MAX then
    self:PlayPerformById(109, self, self.DoNothing)
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_BOTTLE_VOLUME then
    self:PlayPerformById(110, self, self.DoNothing)
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_BOTTLE_TIMES then
    self:PlayPerformById(110, self, self.DoNothing)
  elseif self.upgrade_item_type == _G.Enum.VisualItem.VI_STAMINA then
    self:PlayPerformById(110, self, self.DoNothing)
  end
end

function AlchemyModule:ShowRewardFinish()
  self:PlayPerformById(111, self, self.DoNothing)
  self:SetStatus(AlchemyShowStatusEnum.IDLE)
end

function AlchemyModule:DoNothing()
end

function AlchemyModule:OpenMaterialItems(exchangeId, item_num)
  self:OpenPanel("MaterialItems", exchangeId, self.ironPan, item_num)
end

function AlchemyModule:UpdateMaterialItems(exchangeId, item_num)
  if self:HasPanel("MaterialItems") then
    local panel = self:GetPanel("MaterialItems")
    panel:UpdateItems(exchangeId, item_num)
  end
  if self:HasPanel("AlchemyPanel") then
    local panel = self:GetPanel("AlchemyPanel")
    panel:UpdateCostIcon(exchangeId, item_num)
    panel:UpdateViewItemSelectIndex(exchangeId)
  end
  self.materialExchangeId = exchangeId
  self.materialItemNum = item_num
end

function AlchemyModule:GetMaterialItems()
  return self.materialExchangeId or 0, self.materialItemNum or 0
end

function AlchemyModule:CloseMaterialItems()
  if self:HasPanel("MaterialItems") or self:IsPanelInOpening("MaterialItems") then
    self:ClosePanel("MaterialItems")
  end
  self.materialExchangeId = 0
  self.materialItemNum = 0
end

function AlchemyModule:DisappearAllMaterial()
  if self:HasPanel("MaterialItems") then
    local panel = self:GetPanel("MaterialItems")
    panel:DisappearAll()
  end
end

function AlchemyModule:OpenArdourUpPanel()
  local data = self:GetRoleHpData()
  self:OpenPanel("ArdourUpPanel", {data = data})
  self:OpenMaterialItems(data.exchangeId, 1)
end

function AlchemyModule:OpenRecoverTimeUpPanel(action)
  local data = self:GetBottleTimeData()
  self:OpenPanel("RecoverTimeUpPanel", {action = action, data = data})
  self:OpenMaterialItems(data.exchangeId, 1)
end

function AlchemyModule:OpenRecoverUpPanel(action)
  local data = self:GetBottleVolumeData()
  self:OpenPanel("RecoverUpPanel", {action = action, data = data})
  self:OpenMaterialItems(data.exchangeId, 1)
end

function AlchemyModule:OpenAlchemyPanel(action)
  self:OpenPanel("AlchemyPanel", action)
  self:OpenMaterialItems(0)
end

function AlchemyModule:CmdTestOpenAlchemyPanel()
  self.TestOpen = true
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ClosePanelLobbyMain)
  self:OpenPanel("AlchemyPanel")
end

function AlchemyModule:CmdTestOpenMagicalStudy()
  self.TestOpen = true
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ClosePanelLobbyMain)
  self:OpenPanel("MagicalStudy", {action = nil})
end

function AlchemyModule:OpenVitalityPanel(action)
  local data = self:GetRoleVitalityData()
  self:OpenPanel("VitalityPanel", {action = action, data = data})
  self:OpenMaterialItems(data.exchangeId, 1)
end

function AlchemyModule:OpenMagicStudyPanel(action)
  self:OpenPanel("MagicalStudy", {action = action})
  self:OpenMaterialItems(0)
end

function AlchemyModule:HidePanel(panelName)
  local panel = self:GetPanel(panelName)
  if panel then
    panel:ShowClose()
  end
end

function AlchemyModule:ShowPanel(panelName)
  if self:HasPanel(panelName) then
    local panel = self:GetPanel(panelName)
    if panel then
      panel:ShowOpen()
    end
  else
  end
end

function AlchemyModule:RegPanel(name, path, layer, openAnim, closeAnim, isSingleTouchPanel, disablePcEsc, customDisableRendering)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = "/Game/NewRoco/Modules/System/Alchemy/Res/" .. path
  registerData.panelLayer = layer
  registerData.openAnimName = openAnim
  registerData.closeAnimName = closeAnim
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.enablePcEsc = not disablePcEsc
  registerData.customDisableRendering = customDisableRendering or false
  self:RegisterPanel(registerData)
end

function AlchemyModule:GetBottleVolumeData()
  local effect_value = 0
  local BottleData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, _G.DataConfigManager:GetRoleGlobalConfig("bottle_item").num)
  if BottleData then
    effect_value = BottleData.effect_value
  else
    effect_value = 0
    Log.Error("[CampingModule]: \230\137\190\228\184\141\229\136\176\230\129\162\229\164\141\231\147\182")
  end
  local upgradeId, exchangeId = self:GetBottleVolumeUpExchangeId(effect_value)
  if 0 ~= exchangeId then
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
    local dataTable = {}
    for i, value in pairs(exchangeConf.cost_item) do
      local itemNumber = 0
      local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, value.cost_goods_id)
      if itemData then
        itemNumber = itemData.num
      end
      table.insert(dataTable, {
        itemNum = itemNumber,
        itemId = value.cost_goods_id,
        itemNeedNum = value.cost_goods_num,
        itemType = value.cost_goods_type
      })
    end
    local requiredLevel = 0
    if exchangeConf.unlock_type == _G.Enum.ExchangeFormulaUnlockType.EFUT_ROLE_LEVEL then
      requiredLevel = exchangeConf.unlock_data
    else
      Log.Error("\233\133\141\231\189\174\229\135\186\231\142\176\233\162\132\230\156\159\229\164\150\231\154\132\231\187\147\230\158\156\239\188\140\229\141\135\231\186\167\233\173\148\230\179\149\228\184\141\229\186\148\232\175\165\230\156\137\233\153\164\228\186\134\231\173\137\231\186\167\228\185\139\229\164\150\231\154\132\232\167\163\233\148\129\230\157\161\228\187\182!\230\156\137\231\154\132\232\175\157\232\175\183\230\143\144\228\188\152\229\140\150\233\156\128\230\177\130!")
    end
    return {
      requiredLevel = requiredLevel,
      action = self.Action,
      max_value = self.maxBottleVolume,
      origin_value = effect_value,
      target_value = effect_value + exchangeConf.get_item[1].get_goods_num,
      item_list = dataTable,
      exchangeId = exchangeId,
      upgradeId = upgradeId
    }
  else
    return {
      requiredLevel = 0,
      action = self.Action,
      max_value = self.maxBottleVolume,
      origin_value = effect_value,
      target_value = effect_value,
      item_list = {},
      exchangeId = 0,
      upgradeId = 0
    }
  end
end

function AlchemyModule:GetBottleTimeData()
  local max_use_cnt = 0
  local BottleData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, _G.DataConfigManager:GetRoleGlobalConfig("bottle_item").num)
  if BottleData then
    max_use_cnt = BottleData.max_use_cnt
  else
    max_use_cnt = 0
  end
  local upgradeId, exchangeId = self:GetBottleTimeUpExchangeId(max_use_cnt)
  if 0 ~= exchangeId then
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
    local dataTable = {}
    for i, value in pairs(exchangeConf.cost_item) do
      local itemNumber = 0
      local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, value.cost_goods_id)
      if itemData then
        itemNumber = itemData.num
      end
      table.insert(dataTable, {
        itemNum = itemNumber,
        itemId = value.cost_goods_id,
        itemNeedNum = value.cost_goods_num,
        itemType = value.cost_goods_type
      })
    end
    local requiredLevel = 0
    if exchangeConf.unlock_type == _G.Enum.ExchangeFormulaUnlockType.EFUT_ROLE_LEVEL then
      requiredLevel = exchangeConf.unlock_data
    else
      Log.Error("\233\133\141\231\189\174\229\135\186\231\142\176\233\162\132\230\156\159\229\164\150\231\154\132\231\187\147\230\158\156\239\188\140\229\141\135\231\186\167\233\173\148\230\179\149\228\184\141\229\186\148\232\175\165\230\156\137\233\153\164\228\186\134\231\173\137\231\186\167\228\185\139\229\164\150\231\154\132\232\167\163\233\148\129\230\157\161\228\187\182!\230\156\137\231\154\132\232\175\157\232\175\183\230\143\144\228\188\152\229\140\150\233\156\128\230\177\130!")
    end
    return {
      requiredLevel = requiredLevel,
      action = self.Action,
      max_value = self.maxBottleTimes,
      origin_value = max_use_cnt,
      target_value = max_use_cnt + exchangeConf.get_item[1].get_goods_num,
      item_list = dataTable,
      exchangeId = exchangeId,
      upgradeId = upgradeId
    }
  else
    return {
      requiredLevel = 0,
      action = self.Action,
      max_value = self.maxBottleTimes,
      origin_value = max_use_cnt,
      target_value = max_use_cnt,
      item_list = {},
      exchangeId = 0,
      upgradeId = 0
    }
  end
end

function AlchemyModule:GetRoleHpData()
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local RoleHp = 0
  if localPlayer.serverData.attrs.hp > 0 then
    RoleHp = localPlayer.serverData.attrs.hp
  end
  local RoleHpMax = 0
  if localPlayer.serverData.attrs.hp_max > 0 then
    RoleHpMax = localPlayer.serverData.attrs.hp_max
  end
  Log.Debug("localPlayer serverData attrs hp and hp_max: ", localPlayer.serverData.attrs.hp, RoleHpMax)
  local upgradeId, exchangeId = self:GetRoleHpUpExchangeId(RoleHpMax)
  if 0 ~= exchangeId then
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
    local dataTable = {}
    for _, value in pairs(exchangeConf.cost_item) do
      local itemNumber = 0
      local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, value.cost_goods_id)
      if itemData then
        itemNumber = itemData.num
      end
      table.insert(dataTable, {
        itemNum = itemNumber,
        itemId = value.cost_goods_id,
        itemNeedNum = value.cost_goods_num,
        itemType = value.cost_goods_type
      })
    end
    local requiredLevel = 0
    if exchangeConf.unlock_type == _G.Enum.ExchangeFormulaUnlockType.EFUT_ROLE_LEVEL then
      requiredLevel = exchangeConf.unlock_data
    else
      Log.Error("\233\133\141\231\189\174\229\135\186\231\142\176\233\162\132\230\156\159\229\164\150\231\154\132\231\187\147\230\158\156\239\188\140\229\141\135\231\186\167\233\173\148\230\179\149\228\184\141\229\186\148\232\175\165\230\156\137\233\153\164\228\186\134\231\173\137\231\186\167\228\185\139\229\164\150\231\154\132\232\167\163\233\148\129\230\157\161\228\187\182!\230\156\137\231\154\132\232\175\157\232\175\183\230\143\144\228\188\152\229\140\150\233\156\128\230\177\130!")
    end
    return {
      requiredLevel = requiredLevel,
      action = self.Action,
      max_value = self.maxRoleHp,
      current_value = RoleHpMax,
      origin_value = RoleHpMax,
      target_value = RoleHpMax + exchangeConf.get_item[1].get_goods_num,
      item_list = dataTable,
      exchangeId = exchangeId,
      upgradeId = upgradeId
    }
  else
    return {
      requiredLevel = 0,
      action = self.Action,
      max_value = self.maxRoleHp,
      current_value = RoleHpMax,
      origin_value = RoleHpMax,
      target_value = RoleHpMax,
      item_list = {},
      exchangeId = exchangeId,
      upgradeId = upgradeId
    }
  end
end

function AlchemyModule:IsBottleVolumeUpgradeEnable()
  local Data = self:GetBottleVolumeData()
  if 0 == Data.exchangeId then
    return false
  end
  if not self:CheckExchangeUnlock(Data.exchangeId) then
    return false
  end
  if _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() < Data.requiredLevel then
    return false
  end
  local exchange_conf = _G.DataConfigManager:GetExchangeConf(Data.exchangeId)
  return AlchemyUtils.GetCanExchangeNum(exchange_conf) > 0
end

function AlchemyModule:IsBottleTimeUpgradeEnable()
  local Data = self:GetBottleTimeData()
  if 0 == Data.exchangeId then
    return false
  end
  if not self:CheckExchangeUnlock(Data.exchangeId) then
    return false
  end
  if _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() < Data.requiredLevel then
    return false
  end
  local exchange_conf = _G.DataConfigManager:GetExchangeConf(Data.exchangeId)
  return AlchemyUtils.GetCanExchangeNum(exchange_conf) > 0
end

function AlchemyModule:IsRoleHpUpgradeEnable()
  local Data = self:GetRoleHpData()
  if 0 == Data.exchangeId then
    return false
  end
  if not self:CheckExchangeUnlock(Data.exchangeId) then
    return false
  end
  if _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() < Data.requiredLevel then
    return false
  end
  local exchange_conf = _G.DataConfigManager:GetExchangeConf(Data.exchangeId)
  return AlchemyUtils.GetCanExchangeNum(exchange_conf) > 0
end

function AlchemyModule:IsRolePowerUpgradeEnable()
  local Data = self:GetRoleVitalityData()
  if 0 == Data.exchangeId then
    return false
  end
  if not self:CheckExchangeUnlock(Data.exchangeId) then
    return false
  end
  if _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() < Data.requiredLevel then
    return false
  end
  local exchange_conf = _G.DataConfigManager:GetExchangeConf(Data.exchangeId)
  return AlchemyUtils.GetCanExchangeNum(exchange_conf) > 0
end

function AlchemyModule:GetRoleHpUpExchangeId(RoleHpMax)
  local RoleHpConfTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.HP_MAX_CONF):GetAllDatas()
  for _, Data in pairs(RoleHpConfTable) do
    if Data.upper_limit == nil then
      return 0, 0
    end
    if RoleHpMax >= Data.lower_limit and RoleHpMax < Data.upper_limit then
      return Data.id, Data.exchange_conf
    end
  end
  return 0, 0
end

function AlchemyModule:GetBottleVolumeUpExchangeId(BottleVolume)
  local BottleVolumeTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BOTTLE_VOLUME_CONF):GetAllDatas()
  for _, Data in pairs(BottleVolumeTable) do
    if Data.upper_limit == nil then
      return 0, 0
    end
    if BottleVolume >= Data.lower_limit and BottleVolume < Data.upper_limit then
      return Data.id, Data.exchange_conf
    end
  end
  return 0, 0
end

function AlchemyModule:GetBottleTimeUpExchangeId(BottleTimes)
  local BottleTimesTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BOTTLE_TIMES_CONF):GetAllDatas()
  for _, Data in pairs(BottleTimesTable) do
    if Data.upper_limit == nil then
      return 0, 0
    end
    if BottleTimes >= Data.lower_limit and BottleTimes < Data.upper_limit then
      return Data.id, Data.exchange_conf
    end
  end
  return 0, 0
end

function AlchemyModule:CalculateMaxValue()
  self.maxBottleTimes = 0
  self.maxBottleVolume = 0
  self.maxRoleHp = 0
  self.maxRolePower = 0
  local BottleTimesTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BOTTLE_TIMES_CONF):GetAllDatas()
  for _, Data in pairs(BottleTimesTable) do
    self.maxBottleTimes = math.max(Data.upper_limit, self.maxBottleTimes)
  end
  local BottleVolumeTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BOTTLE_VOLUME_CONF):GetAllDatas()
  for _, Data in pairs(BottleVolumeTable) do
    self.maxBottleVolume = math.max(Data.upper_limit, self.maxBottleVolume)
  end
  local RoleHpTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.HP_MAX_CONF):GetAllDatas()
  for _, Data in pairs(RoleHpTable) do
    self.maxRoleHp = math.max(Data.upper_limit, self.maxRoleHp)
  end
  local RolePowerTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.POWER_MAX_CONF):GetAllDatas()
  for _, Data in pairs(RolePowerTable) do
    self.maxRolePower = math.max(Data.upper_limit, self.maxRolePower)
  end
end

function AlchemyModule:ReduceRoleHp()
  local req = _G.ProtoMessage:newZoneSubRoleHpReq()
  req.sub_val = 1
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SUB_ROLE_HP_REQ, req, false)
end

function AlchemyModule:GetRoleVitalityData()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local roleVitality = 0
  local roleVitalityMax = 0
  if player.serverData.attrs.stamina then
    roleVitality = player.serverData.attrs.stamina
  end
  if player.serverData.attrs.stamina_max then
    roleVitalityMax = player.serverData.attrs.stamina_max
  end
  local upgradeId, exchangeId = self:GetRoleVitalityExchangeId(roleVitalityMax)
  if exchangeId > 0 then
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
    local dataTable = {}
    for k, v in pairs(exchangeConf.cost_item) do
      local itemNumber = 0
      local itemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, v.cost_goods_id)
      if itemData then
        itemNumber = itemData.num
      end
      table.insert(dataTable, {
        itemNum = itemNumber,
        itemId = v.cost_goods_id,
        itemNeedNum = v.cost_goods_num,
        itemType = v.cost_goods_type
      })
    end
    local requiredLevel = 0
    if exchangeConf.unlock_type == _G.Enum.ExchangeFormulaUnlockType.EFUT_ROLE_LEVEL then
      requiredLevel = exchangeConf.unlock_data
    else
      Log.Error("\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174")
    end
    return {
      requiredLevel = requiredLevel,
      max_value = self.maxRolePower,
      current_value = roleVitalityMax,
      origin_value = roleVitalityMax,
      target_value = roleVitalityMax + exchangeConf.get_item[1].get_goods_num,
      item_list = dataTable,
      exchangeId = exchangeId,
      upgradeId = upgradeId
    }
  else
    return {
      requiredLevel = 0,
      max_value = self.maxRolePower,
      current_value = roleVitalityMax,
      origin_value = roleVitalityMax,
      target_value = roleVitalityMax,
      item_list = {},
      exchangeId = exchangeId,
      upgradeId = upgradeId
    }
  end
end

function AlchemyModule:GetRoleVitalityExchangeId(CurVitalityMax)
  local RolePowerConfTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.POWER_MAX_CONF):GetAllDatas()
  for k, v in pairs(RolePowerConfTable) do
    if CurVitalityMax >= v.lower_limit and CurVitalityMax < v.upper_limit then
      return v.id, v.exchange_conf
    end
  end
  return 0, 0
end

function AlchemyModule:PlayPerformById(id, caller, callback, skillProxy, pre_start_caller, pre_start_callback)
  if not self.ironPan then
    Log.Warning("\229\176\157\232\175\149\230\146\173\230\148\190\232\161\168\230\188\148\229\164\177\232\180\165\239\188\140\231\130\188\233\135\145\233\148\133\230\182\136\229\164\177\228\186\134\239\188\140\229\166\130\230\158\156\230\152\175\231\130\188\233\135\145\232\162\171\230\137\147\230\150\173\228\186\134\239\188\140\233\130\163\232\191\153\229\190\136\230\173\163\229\184\184\239\188\140\229\144\166\229\136\153\233\156\128\232\166\129\229\133\179\230\179\168\228\184\128\228\184\139")
    return
  end
  NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  DialogueUtils.LockPlayerMove()
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local performConf = _G.DataConfigManager:GetPerformConf(id)
  localPlayer:EnsurePerform()
  localPlayer.HoldingItemComponent:RegisterItem("ironPan", self.ironPan)
  localPlayer:PlayShowById(performConf, caller, callback, skillProxy, pre_start_caller, pre_start_callback, _G.PriorityEnum.Active_Player_Action)
end

function AlchemyModule:OnReconnect()
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer:EnsurePerform()
  if localPlayer.HoldingItemComponent:GetItemByKey("ironPan") then
    self:PlayPerformById(102)
  end
  self.waitingForRequestForUpgradeProtocol = nil
end

function AlchemyModule:DoFixPerform(IronPan, id, caller, callback)
  if self.ironPan == nil then
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.RegisterIronPan, IronPan)
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.PlayPerformById, id, caller, callback)
  end
end

function AlchemyModule:ReleaseCamera()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer or not localPlayer.HoldingItemComponent then
    return
  end
  local cameraActorMesh = localPlayer.HoldingItemComponent:GetItemByKey("camActor_0001_SA")
  if cameraActorMesh and UE.UObject.IsValid(cameraActorMesh) then
    local ueController = localPlayer:GetUEController()
    local rotation = cameraActorMesh.SkeletalMeshComponent:GetSocketRotation("cam_01")
    ueController:SetControlRotation(rotation)
  end
  local playerController = localPlayer:GetUEController()
  playerController:ReleaseRocoCamera(0, nil, nil, true)
  local holdingItemComponent = localPlayer.HoldingItemComponent
  holdingItemComponent:DestroyItem("camActor_0001_SA")
  holdingItemComponent:DestroyItem("camActor_0001")
end

function AlchemyModule:SetAlchemyItem(exchangeId, index, recipe_index)
  if self.exchange_id ~= exchangeId then
    self.AlternateMaterials = {}
  end
  self.exchange_id = exchangeId
  self.exchange_index = index
  self.recipe_index = recipe_index
end

function AlchemyModule:GetAlchemyItem()
  return self.exchange_id, self.exchange_index, self.recipe_index
end

function AlchemyModule:OnMagicalStudyItemClicked(type)
  self:OpenPanel("MagicalStudy")
  if self:HasPanel("MagicalStudy") then
    local MagicalStudyPanel = self:GetPanel("MagicalStudy")
    MagicalStudyPanel:OnStudyItemSelected(type)
  end
end

function AlchemyModule:EnableClick()
end

function AlchemyModule:DisableClick()
  if self:HasPanel("MaterialItems") then
    local panel = self:GetPanel("MaterialItems")
    panel:DisableClick()
  end
  if self:HasPanel("MagicalStudy") then
    local MagicalStudyPanel = self:GetPanel("MagicalStudy")
    MagicalStudyPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function AlchemyModule:OnCmdOpenAlternativeFormula(exchangeItems, selectIndex)
  self:OpenPanel("AlternativeFormula", exchangeItems, selectIndex)
end

function AlchemyModule:OnCmdOpenAlchemySort(data, confName, condition)
  self:OpenPanel("AlchemySort", data, confName, condition)
end

function AlchemyModule:OnCmdSelectManufactureBasicType(filterList, condition)
  if self:HasPanel("AlchemyPanel") then
    local panel = self:GetPanel("AlchemyPanel")
    panel:OnBasicFilter(filterList, condition)
  end
end

function AlchemyModule:OnCmdOpenAlternateMaterial(materialData)
  self:OpenPanel("AlternateMaterial", materialData)
end

function AlchemyModule:OnCmdCloseAlternateMaterial()
  if self:HasPanel("AlternateMaterial") then
    self:ClosePanel("AlternateMaterial")
  end
end

function AlchemyModule:OnCmdSetExchangeMaterial(alternate_materials)
  self.AlternateMaterials = alternate_materials
  if self:HasPanel("AlchemyPanel") then
    local AlchemyPanel = self:GetPanel("AlchemyPanel")
    AlchemyPanel:OnChangeMaterialUpdate()
  end
  if self:HasPanel("MaterialItems") then
    local MaterialItems = self:GetPanel("MaterialItems")
    MaterialItems:UpdateItems(self.materialExchangeId, self.materialItemNum)
  end
  _G.NRCEventCenter:DispatchEvent(_G.AlchemyModuleEvent.SetExchangeMaterial, self.materialExchangeId, self.materialItemNum)
end

function AlchemyModule:OnCmdGetCostMaterialItems(exchange_id, exchange_num)
  local result = {}
  local exchange_conf = _G.DataConfigManager:GetExchangeConf(exchange_id, true)
  if not exchange_conf then
    return result
  end
  local bubbleNum = _G.DataConfigManager:GetGlobalConfigNumByKey("exchange_bubble_max_num", 4)
  local alternateIndex = -1
  for i, costItem in ipairs(exchange_conf.cost_item) do
    local goodsList = costItem.cost_goods_id
    if 1 == #goodsList then
      table.insert(result, {
        goods_type = costItem.cost_goods_type,
        goods_id = goodsList[1],
        goods_num = costItem.cost_goods_num * exchange_num,
        bAlternate = false
      })
      bubbleNum = bubbleNum - 1
    elseif #goodsList > 1 then
      alternateIndex = i
    end
  end
  if alternateIndex > 0 and bubbleNum > 0 then
    local costItem = exchange_conf.cost_item[alternateIndex]
    local LeftMaterialNum = costItem.cost_goods_num * exchange_num
    local materialMap = {}
    if #self.AlternateMaterials > 0 then
      bubbleNum = bubbleNum - #self.AlternateMaterials
      local totalNum = 0
      for _, material_id in ipairs(self.AlternateMaterials) do
        local itemNum = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, material_id, costItem.cost_goods_type)
        materialMap[material_id] = itemNum
        totalNum = totalNum + itemNum
      end
      if LeftMaterialNum >= totalNum then
        for _, material_id in ipairs(self.AlternateMaterials) do
          table.insert(result, {
            goods_type = costItem.cost_goods_type,
            goods_id = material_id,
            goods_num = materialMap[material_id],
            bAlternate = true
          })
        end
        LeftMaterialNum = LeftMaterialNum - totalNum
      else
        local i = 1
        local resultNum = {}
        while LeftMaterialNum > 0 do
          do
            local material_id = self.AlternateMaterials[i]
            if materialMap[material_id] > 0 then
              if not resultNum[material_id] then
                resultNum[material_id] = 0
              end
              resultNum[material_id] = resultNum[material_id] + 1
              materialMap[material_id] = materialMap[material_id] - 1
              LeftMaterialNum = LeftMaterialNum - 1
            end
            i = i % #self.AlternateMaterials + 1
          end
        end
        for _, material_id in ipairs(self.AlternateMaterials) do
          table.insert(result, {
            goods_type = costItem.cost_goods_type,
            goods_id = material_id,
            goods_num = resultNum[material_id] or 0,
            bAlternate = true
          })
        end
      end
    end
    local dataList = {}
    for _, goodsId in ipairs(costItem.cost_goods_id) do
      local num = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, goodsId, costItem.cost_goods_type)
      local itemData = {itemId = goodsId, itemNum = num}
      table.insert(dataList, itemData)
    end
    dataList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetSortGoodsList, dataList, costItem.cost_goods_type)
    for _, itemData in ipairs(dataList) do
      if bubbleNum <= 0 or LeftMaterialNum <= 0 then
        break
      end
      local goodsId = itemData.itemId
      if not table.contains(self.AlternateMaterials, goodsId) then
        local itemNum = self:OnCmdGetMaterialNum(goodsId, costItem.cost_goods_type)
        table.insert(result, {
          goods_type = costItem.cost_goods_type,
          goods_id = goodsId,
          goods_num = math.min(LeftMaterialNum, itemNum),
          bAlternate = true
        })
        LeftMaterialNum = LeftMaterialNum - itemNum
        bubbleNum = bubbleNum - 1
      end
    end
    local deleteIndex = {}
    local bAllAlternateEmpty = true
    for i, material in ipairs(result) do
      if material.bAlternate then
        if material.goods_num <= 0 then
          table.insert(deleteIndex, i)
        else
          bAllAlternateEmpty = false
        end
      end
    end
    for i = #deleteIndex, 1, -1 do
      if 1 ~= i or not bAllAlternateEmpty then
        table.remove(result, deleteIndex[i])
      end
    end
    if LeftMaterialNum > 0 then
      for _, material in ipairs(result) do
        if material.bAlternate then
          material.goods_num = material.goods_num + LeftMaterialNum
          break
        end
      end
    end
  end
  return result
end

function AlchemyModule:OnCmdGetAlternateMaterials()
  return self.AlternateMaterials
end

function AlchemyModule:OnCmdResetAlternateMaterials()
  self.AlternateMaterials = {}
end

function AlchemyModule:OnCmdGetMaterialNum(itemId, itemType)
  local num = 0
  if itemType == _G.Enum.GoodsType.GT_VITEM then
    num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(itemId) or 0
  elseif itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, itemId)
    if bagItemData then
      num = bagItemData.num
    end
  end
  return num
end

function AlchemyModule:OnCmdGetSortGoodsList(goodsList, costType)
  local function _SortFunc1(a, b)
    local numA = a.itemNum
    
    local numB = b.itemNum
    if numA ~= numB then
      return numA > numB
    else
      local bagItemConfA = _G.DataConfigManager:GetBagItemConf(a.itemId)
      local bagItemConfB = _G.DataConfigManager:GetBagItemConf(b.itemId)
      return bagItemConfA.sort_id < bagItemConfB.sort_id
    end
  end
  
  local function _SortFunc2(a, b)
    local numA = a.itemNum
    local numB = b.itemNum
    if numA ~= numB then
      return numA > numB
    else
      local vItemConfA = _G.DataConfigManager:GetVisualItemConf(a.itemId)
      local vItemConfB = _G.DataConfigManager:GetVisualItemConf(b.itemId)
      return vItemConfA.sort_id < vItemConfB.sort_id
    end
  end
  
  if costType == _G.Enum.GoodsType.GT_BAGITEM then
    table.sort(goodsList, _SortFunc1)
  elseif costType == _G.Enum.GoodsType.GT_VITEM then
    table.sort(goodsList, _SortFunc2)
  end
  return goodsList
end

function AlchemyModule:OnCmdGetFilterBasicList(filter, itemList)
  local bagItemList = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].filterData.bagitem_id)
        if bagItemConf and bagItemConf.lable_type == enum then
          table.insert(bagItemList, itemList[i])
        end
      end
    end
    local showList = {}
    for _, v1 in ipairs(itemList) do
      for _, v2 in ipairs(bagItemList) do
        if v1.filterData.bagitem_id == v2.filterData.bagitem_id then
          table.insert(showList, v1)
          break
        end
      end
    end
    return showList
  end
  return itemList
end

function AlchemyModule:GetUnlockExchange(bIsUseSharedRecipe)
  return self.data:GetAllAvailableRecipeIds(bIsUseSharedRecipe)
end

function AlchemyModule:RegisterSkipEvent()
  local CommonModule = _G.NRCModuleManager:GetModule("CommonModule")
  CommonModule:RegisterEvent(self, _G.CommonModuleEvent.ON_SKIP, self.SkipShow)
end

function AlchemyModule:UnRegisterSkipEvent()
  local CommonModule = _G.NRCModuleManager:GetModule("CommonModule")
  CommonModule:UnRegisterEvent(self, _G.CommonModuleEvent.ON_SKIP)
end

function AlchemyModule:OpenSkipPanel()
  self:RegisterSkipEvent()
  _G.NRCModuleManager:DoCmd(_G.CommonModuleCmd.OpenSkipPanel)
end

function AlchemyModule:CloseSkipPanel()
  self:UnRegisterSkipEvent()
  _G.NRCModuleManager:DoCmd(_G.CommonModuleCmd.CloseSkipPanel)
end

function AlchemyModule:SkipShow()
  self.should_skip = true
  if self.status == AlchemyShowStatusEnum.IDLE or self.status == AlchemyShowStatusEnum.SHOW_REWARD then
    self.should_skip = false
    return
  end
  if self.status == AlchemyShowStatusEnum.WAIT_RSP then
    self:CloseSkipPanel()
    return
  end
  if self.status == AlchemyShowStatusEnum.DO_ADD_MATERIAL then
    self:InterruptAdd()
    self:ShowReward()
    return
  end
  if self.status == AlchemyShowStatusEnum.WAIT_SHOW_RES then
    self.LoadQueue:Release()
    self:ShowReward()
    return
  end
  if self.status == AlchemyShowStatusEnum.DO_SHOW then
    self:InterruptShow()
    self:ShowReward()
    return
  end
end

function AlchemyModule:SetStatus(status)
  Log.Debug("AlchemyModule:SetStatus", table.getKeyName(AlchemyShowStatusEnum, status))
  self.status = status
  if self.status == AlchemyShowStatusEnum.IDLE then
    self.should_skip = false
  end
  _G.NRCEventCenter:DispatchEvent(_G.AlchemyModuleEvent.AlchemyOnStatusChange, self.status)
end

function AlchemyModule:InterruptShow()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local localPlayerView = localPlayer and localPlayer.viewObj
  if not UE4.UObject.IsValid(localPlayerView) then
    localPlayerView = nil
  end
  if localPlayerView then
    localPlayer:StopAllMontage(0.1)
    localPlayerView.RocoSkill:StopCurrentSkill()
  end
  local skillShowComp = localPlayer and localPlayer:GetComponent(SkillShowComponent)
  if skillShowComp then
    skillShowComp:StopAll()
  end
  if self.ironPan and UE4.UObject.IsValid(self.ironPan) then
    self.ironPan:ExitDuanzao()
  end
  if localPlayerView then
    _G.NRCAudioManager:StopAllForActor(localPlayer.viewObj)
  end
  if self.ironPan then
    _G.NRCAudioManager:StopAllForActor(self.ironPan)
  end
  local AnimComponent = self.ironPan.NRCAnimation
  AnimComponent:StopAllMontage(0.1)
end

function AlchemyModule:InterruptAdd()
  self:InterruptShow()
end

function AlchemyModule:OnCmdGetAlchemyStatus()
  return self.status
end

function AlchemyModule:OnCmdGetItemSynthesisInfo(bagItemId)
  local ItemSynthesisInfos = {}
  local allExchangeConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.EXCHANGE_CONF)
  for i, v in pairs(allExchangeConf) do
    for j, item in ipairs(v.get_item) do
      if item.get_goods_id == bagItemId then
        local result = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.CheckExchangeAvailable, v.id)
        if result then
          local ItemSynthesisInfo = {}
          ItemSynthesisInfo.id = bagItemId
          ItemSynthesisInfo.type = item.get_goods_type
          ItemSynthesisInfo.exchangeId = v.id
          ItemSynthesisInfo.cost_item = self:DeepCopyCostItem(v.cost_item)
          table.insert(ItemSynthesisInfos, ItemSynthesisInfo)
        end
        break
      end
    end
  end
  return ItemSynthesisInfos
end

function AlchemyModule:DeepCopyCostItem(source)
  if not source then
    return {}
  end
  local result = {}
  for i, costItem in ipairs(source) do
    local copiedItem = {
      cost_goods_type = costItem.cost_goods_type,
      cost_goods_num = costItem.cost_goods_num
    }
    if costItem.cost_goods_id and #costItem.cost_goods_id > 0 then
      copiedItem.cost_goods_id = {}
      for j, goodsId in ipairs(costItem.cost_goods_id) do
        copiedItem.cost_goods_id[j] = goodsId
      end
    else
      copiedItem.cost_goods_id = nil
    end
    table.insert(result, copiedItem)
  end
  return result
end

function AlchemyModule:OnCmdCheckExchangeAvailable(exchangeId, bIsUseSharedRecipe)
  local haveFormula = self.data:CheckExchangeAvailable(exchangeId, bIsUseSharedRecipe)
  if haveFormula then
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
    if exchangeConf then
      if exchangeConf.cost_item then
        for i, v in ipairs(exchangeConf.cost_item) do
          local bHaveItem = false
          for j, curItemId in ipairs(v.cost_goods_id) do
            local haveNum = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, curItemId, v.cost_goods_type)
            if haveNum >= v.cost_goods_num then
              bHaveItem = true
            end
          end
          if not bHaveItem then
            return false
          end
        end
      end
      if exchangeConf.visual_item_cost_type then
        local haveNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(exchangeConf.visual_item_cost_type) or 0
        if haveNum < exchangeConf.visual_item_cost_num then
          return false
        end
      end
      return true
    end
  end
  return false
end

function AlchemyModule:CheckExchangeUnlock(exchangeId, bIsUseSharedRecipe)
  return self.data:CheckExchangeAvailable(exchangeId, bIsUseSharedRecipe)
end

function AlchemyModule:OnZoneGetUnlockedExchangeRsp(rsp)
  if rsp and 0 == rsp.ret_info.ret_code then
    self.data:RefreshAvailableRecipeMap(rsp.recipes, true)
  end
end

function AlchemyModule:OnZoneUnlockExchangeRecipeNotify(notify)
  self.data:RefreshAvailableRecipeMap(notify.recipes, notify.is_full)
end

return AlchemyModule
