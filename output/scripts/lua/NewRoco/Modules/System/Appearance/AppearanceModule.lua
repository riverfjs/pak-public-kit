local AppearanceLocalUtils = require("NewRoco.Modules.System.Appearance.AppearanceLocalUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local CommonUIUtils = require("NewRoco.Utils.UIUtils")
local ResQueue = require("NewRoco.Utils.ResQueue")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local AppearanceAnimationManager = require("NewRoco.Modules.System.Appearance.AppearanceAnimationManager")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local MAX_SEARCH_DEPTH = 64
local AppearanceModule = NRCModuleBase:Extend("AppearanceModule")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
_G.AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")
local AppearanceModuleEnum = _G.AppearanceModuleEnum
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")

function AppearanceModule:OnConstruct()
  _G.AppearanceModuleCmd = reload("NewRoco.Modules.System.Appearance.AppearanceModuleCmd")
  self.data = self:SetData("AppearanceModuleData", "NewRoco.Modules.System.Appearance.AppearanceModuleData")
  self:RegPanel("BeautyMain", "UMG_Beauty_Main", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("AppearanceTip", "UMG_Appearance_Bounced", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AppearanceSuit", "UMG_Appearance_Suit", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AppearanceBlackPopUp", "UMG_AppearanceBlackBg", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AppearanceSuitDetails", "UMG_AppearanceSuit", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AppearanceTryOn", "UMG_TryOn", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("SeasonalCombinationBagShop", "UMG_Shop_CombinationBag", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, true, "In")
  self:RegPanel("TailorShop", "UMG_TailorShop", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true)
  self:RegPanel("MagicWandDetail", "UMG_ShiningMedal", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AppearanceUpgrade", "UMG_UpgradeComponent", _G.Enum.UILayerType.UI_LAYER_POPUP, true, nil, nil, "AppearanceCloset")
  self:RegPanel("ShiningMedalDetail", "UMG_ShiningMedal", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AppearanceUpgradeSucc", "UMG_UpgradeSuccPanel", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("AppearanceCloset", "UMG_ClosetPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true)
  self:RegPanel("FashionMallPopup", "UMG_FashionMallPopup", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("FashionMallConfirm", "UMG_Tryon_Buy", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("FashionBuyResultPopUp", "UMG_UpgradeSuitLevel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, false)
  self:RegPanel("FashionGetHeterochromeSuitPanel", "UMG_UpgradeSuitLevel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, false)
  self:RegPanel("GorgeousMagic", "UMG_GorgeousMagic", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MagicVideoDetails", "UMG_MagnificentMagic", _G.Enum.UILayerType.UI_LAYER_POPUP, nil)
  self:RegPanel("ShopCollectProgress", "UMG_Shop_CollectProgress", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, false)
  self:RegPanel("GorgeousMedal", "UMG_GorgeousMedal", _G.Enum.UILayerType.UI_LAYER_POPUP, true, nil, nil, "AppearanceCloset")
  self:RegPanel("MagicWandPopUp", "UMG_MagnificentMagic1", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PigmentAcquire", "UMG_PigmentAcquire", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self.AvatarPlayer = nil
  self.SkillCameraActor = nil
  self.SkillCameraActorMesh = nil
  self.SceneCaptureComponent = nil
  self.SkillCameraActor1 = nil
  self.SkillCameraActorMesh1 = nil
  self.bChangeSuitWorld = true
  self.NpcAction = nil
  self.ItemListInfo = nil
  self.CanStopEnd = false
  self.AppearOpenFirst = false
  self.bDialogueEnded = false
  self.bBeautyNotSave = false
  self.bAnimStopTick = true
  self.animPriorityTable = {
    HZMoZhangStar = 2,
    HZMoZhangLoop = 2,
    HZMoZhangEnd = 2,
    ShiningMedalOpen = 2,
    ShiningMedalLoop = 2,
    ShiningMedalEnd = 2
  }
  self.animManager = AppearanceAnimationManager.new()
  self.animManager:InitPriorityTable(self.animPriorityTable)
  self.TryOnPreviewWorld = nil
  self.closetNpcAction = nil
  self.closetAvatarPlayer = nil
  self.closetAvatarPlayer_Ref = nil
  self.bStartRot = false
  self.totalRotation = 0
  self.RotAvatarPlayer = nil
  self.bReceivedSetFashionRsp = false
  self.bReceivedSetSalonRsp = false
  self.closetClickable = true
  self.alreadySendReq = false
  self.FashionShowBaseResQue = nil
  self.fashionShowSequenceResQueues = {}
  self.fashionShowPerformBP = {}
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputTouchStart)
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.playerCameraManager = self.player:GetUEController().PlayerCameraManager
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_NEW_FASHION_ITEM_NOTIFY, self.OnNewFashionItemNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_NEW_SALON_ITEM_NOTIFY, self.OnNewSalonItemNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_NEW_FASHION_BOND_NOTIFY, self.OnNewFashionBondNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_COLOR_SUIT_STATE_CHANGE_NTY, self.OnNewColorSuitStateChangedNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GLASS_TINT_CHANGE_NTY, self.OnZoneGlassTintChangeNty)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnEnterFashionMallEnd)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpened)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, SceneEvent.PreLoadMapStart, self.OnPreLoadMapStart)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, SceneEvent.LoadMapFinish, self.OnLoadMapFinish)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, FriendModuleEvent.OnEnterVisit, self.OnEnterVisit)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, AppearanceModuleEvent.OnUpgradeSuitLevelPanelClose, self.OnUpgradeSuitLevelPanelClose)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:RegisterEvent("AppearanceModule", self, BattleEvent.EnterBattle, self.OnEnterBattle)
end

function AppearanceModule:OnActive()
  self.data:SetFreeItemList()
  self.data:SetHasItemList()
  self.data:SetHasSalonList()
  self.data:BuildFashionIdToGoodsIdMap()
  self.data:BuildSalonIdToGoodsIdMap()
  self.data:BuildColorIndexToColorIdMap()
  self.data:BuildUIColorIndexToColorMap()
  self.data:BuildFashionIdToSuitIdMap()
  self.data:BuildClosetTabMap()
  self.data:BuildTimeTokenDic()
  self.data:InitClosetShowItemList()
  self.data:CollectAllPIKAShopActivity()
  self.data:GetInitBodyPath()
  self.data:BuildPackageToAllSuitMap()
  self.data:BuildSuitIdToExchangeGoodsMap(AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION)
  self.data:BuildCurrentBPSuitMap()
  self.pikaActivityList = nil
  self:CollectGlobalConfig()
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnAppearanceModuleActive)
end

function AppearanceModule:OnRelogin()
end

function AppearanceModule:OnDeactive()
end

function AppearanceModule:OnDestruct()
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputTouchStart)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_NEW_FASHION_ITEM_NOTIFY, self.OnNewFashionItemNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnEnterFashionMallEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpened)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PreLoadMapStart, self.OnPreLoadMapStart)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapFinish, self.OnLoadMapFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnEnterVisit, self.OnEnterVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.EnterBattle, self.OnEnterBattle)
  self:ReleaseFashionShowSequenceResource()
  if self.checkPurchasableDelayId then
    _G.DelayManager:CancelDelayById(self.checkPurchasableDelayId)
  end
  if self.createAvatarId then
    _G.DelayManager:CancelDelayById(self.createAvatarId)
  end
  if self.restartFashionShowId then
    _G.DelayManager:CancelDelayById(self.restartFashionShowId)
    self.restartFashionShowId = nil
  end
  if self.loadClosetAvatarDelayId then
    _G.DelayManager:CancelDelayById(self.loadClosetAvatarDelayId)
  end
  if self.fashionMallPopUpDelayId then
    _G.DelayManager:CancelDelayById(self.fashionMallPopUpDelayId)
    self.fashionMallPopUpDelayId = nil
  end
end

function AppearanceModule:OnEnterBattle()
  self:CloseAllPanel()
end

function AppearanceModule:OnDialogueEnded(bIsConnected)
  if bIsConnected then
    if self:HasPanel("AppearanceMain") then
      self.bDialogueEnded = true
      local panel = self:GetPanel("AppearanceMain")
      panel:ConfirmClose(true)
      local panel1 = self:GetPanel("AppearanceTip")
      if panel1 then
        panel1:OnBtnCancelClicked()
      end
    end
    if self:HasPanel("BeautyMain") then
      self.bDialogueEnded = true
      local panel = self:GetPanel("BeautyMain")
      panel:ConfirmClose(true)
      local panel1 = self:GetPanel("AppearanceTip")
      if panel1 then
        panel1:OnBtnCancelClicked()
      end
    end
  end
end

function AppearanceModule:OnReConnect()
  self.data:SetHasItemList()
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  local fashionItems = fashionInfo.wardrobe_data[fashionInfo.current_wardrobe_index + 1].wearing_item
  local salonIds = fashionInfo.wardrobe_data[fashionInfo.current_wardrobe_index + 1].salon_item_wear_id
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local bFashionChange = false
  local bSalonIdChange = false
  local fashionIds = {}
  for _, v in pairs(fashionItems or {}) do
    if v and v.wearing_item_id then
      table.insert(fashionIds, v.wearing_item_id)
    end
  end
  if self.bReceivedSetFashionRsp then
    local fashionItems = player:GetFashionItems()
    local fashionIds = {}
    for _, v in pairs(fashionItems or {}) do
      table.insert(fashionIds, v.wearing_item_id)
    end
    bFashionChange = self:CompareTablesIgnoreZeroAndOrder(fashionIds, fashionIds) == false
    bSalonIdChange = false == self:CompareTablesIgnoreZeroAndOrder(salonIds, player:GetSalonIds())
  else
    bFashionChange = true
    bSalonIdChange = true
  end
  if bFashionChange or bSalonIdChange then
    local curSalonIds = {}
    if salonIds then
      for k, v in ipairs(salonIds) do
        table.insert(curSalonIds, {item_wear_id = v})
      end
    end
    self:SetDefaultSuit(fashionItems, curSalonIds)
    self.bReceivedSetFashionRsp = true
  end
  self.data.savedItemGlassMap = nil
end

function AppearanceModule:CompareTablesIgnoreZeroAndOrder(a, b)
  local extractNumbers = function(t, counts)
    if t then
      for _, v in pairs(t) do
        if type(v) == "number" then
          if 0 ~= v then
            counts[v] = (counts[v] or 0) + 1
          end
        elseif type(v) == "table" then
          extractNumbers(v, counts)
        end
      end
    end
  end
  local countsA = {}
  extractNumbers(a, countsA)
  local countsB = {}
  extractNumbers(b, countsB)
  for num, count in pairs(countsA) do
    if countsB[num] ~= count then
      return false
    end
  end
  for num, count in pairs(countsB) do
    if countsA[num] ~= count then
      return false
    end
  end
  return true
end

function AppearanceModule:OnNewFashionItemNotify(notify)
  _G.DataModelMgr.PlayerDataModel:AddPlayerOwnedFashionInfo(notify.fashion_item_ids, notify.is_deduct)
  self.data:SetHasItemList()
  if self:HasPanel("AppearanceCloset") then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:OnPlayerDataUpdate()
    end
  end
end

function AppearanceModule:OnNewSalonItemNotify(notify)
  _G.DataModelMgr.PlayerDataModel:AddPlayerOwnedSalonInfo(notify.salon_item_ids, notify.is_deduct)
  self.data:SetHasSalonList()
  if self:HasPanel("AppearanceCloset") then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:OnPlayerDataUpdate()
    end
  end
end

function AppearanceModule:OnCmdSetFashionVerticalTabEnum(enum)
  self.data.curAppearChooseType = enum
  self:OnCmdChangeAppearanceChooseType(enum)
end

function AppearanceModule:OnCmdSetFashionCrossTabEnum(enum)
  self.data.curAppearChooseSubType = enum
  self:OnCmdChangeAppearanceChooseType(enum)
end

function AppearanceModule:OnCmdOpenAppearancePanel(itemListInfo, npcAction)
  if RocoEnv.IS_EDITOR and not NRCEnv:IsLocalMode() then
    AppearanceLocalUtils.DumpAppearanceSuitInfo(itemListInfo, self.player)
  end
  self.ItemListInfo = itemListInfo
  local isOpening, _ = self:HasPanel("AppearanceMain")
  self.data.IsWorldReloading = true
  if not isOpening then
    self:SetInitializeData()
  else
    local panel = self:GetPanel("AppearanceMain")
    panel:ConfirmClose(true)
  end
end

function AppearanceModule:SetInitializeData()
  self.AppearOpenFirst = true
  self.data.IsPlayAnim = true
  self.data.PlayAnimStartTime = 0
end

function AppearanceModule:GetPikaActivityInfo()
  local pikaActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PIKA)
  if pikaActivityInst and #pikaActivityInst > 0 then
    local leftTime = pikaActivityInst[1]:GetActivityTimeLeft()
    local subItemIds = pikaActivityInst[1]:GetPartIds()
    local activityPikaConf = _G.DataConfigManager:GetActivityPikaConf(subItemIds[1])
    self.pikaActivityList = {}
    if self:IsPikaActivityHadPopUp(subItemIds[1]) then
      return
    end
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      for k, v in ipairs(activityPikaConf.kv_path) do
        if v.gender == player.gender then
          for key, pkgId in ipairs(v.package_id1) do
            local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(pkgId)
            if fashionPackageConf and fashionPackageConf.kv_pop then
              table.insert(self.pikaActivityList, {
                leftTime = leftTime,
                kvBg = fashionPackageConf.kv_pop,
                pikaActivityBaseId = subItemIds[1],
                pkgId = pkgId
              })
            end
          end
        end
      end
    end
  end
end

function AppearanceModule:OnEnterFashionMallEnd()
  self:GetPikaActivityInfo()
  self:OnCmdOpenFashionMallPopup()
  if SceneUtils.IsInPikaShop() and self.data and not self.data.bFashionShowSequenceWorking then
    self:ReleaseFashionShowSequenceResource()
    if self.restartFashionShowId then
      _G.DelayManager:CancelDelayById(self.restartFashionShowId)
      self.restartFashionShowId = nil
    end
    self.restartFashionShowId = DelayManager:DelayFrames(1, function(appearanceModule)
      appearanceModule:ActiveFashionShowSequence()
    end, self)
  end
end

function AppearanceModule:OnCmdOpenAppearanceBlack(Event, Skill)
  local isOpening, _ = self:HasPanel("AppearanceBlackPopUp")
  if not isOpening then
    self:OpenPanel("AppearanceBlackPopUp")
  end
end

function AppearanceModule:OnCmdOpenBeautyPanel(itemListInfo, npcAction)
  if RocoEnv.IS_EDITOR and not NRCEnv:IsLocalMode() then
    AppearanceLocalUtils.DumpAppearanceSalonInfo(itemListInfo, self.player)
  end
  local isOpening, _ = self:HasPanel("BeautyMain")
  if not isOpening then
    self:OpenPanel("BeautyMain", itemListInfo, npcAction)
  else
    local panel = self:GetPanel("BeautyMain")
    panel:ConfirmClose(true)
  end
end

function AppearanceModule:OnCmdOpenLoginBeautyPanel()
  local isOpening, _ = self:HasPanel("BeautyMain")
  if not isOpening then
    self:OpenPanel("BeautyMain")
  end
end

function AppearanceModule:CollectSuitUpgradeResourcePaths(suitId)
  local paths = {}
  local pathSet = {}
  
  local function addPath(p)
    if p and "" ~= p and not pathSet[p] then
      pathSet[p] = true
      table.insert(paths, p)
    end
  end
  
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if not suitConf or not suitConf.lv_up_closet then
    return paths
  end
  local UE4 = _G.UE4
  local BT = UE4.EAvatarBodyType
  local bHasHat = false
  if suitConf.item_id then
    for _, fashionId in ipairs(suitConf.item_id) do
      local _, _, avatarEnum = self:GetConfigEnumFromFashionId(fashionId)
      if avatarEnum == BT.Hat then
        bHasHat = true
        break
      end
    end
  end
  
  local function applyHatHairVariant(path)
    if not path or "" == path then
      return path
    end
    if string.find(path, "_Hr_Ht", 1, true) then
      return path
    end
    local replaced = string.gsub(path, "_Hr", "_Hr_Ht")
    return replaced
  end
  
  for _, closetItem in ipairs(suitConf.lv_up_closet) do
    local itemType = closetItem.lv_item_type
    local itemId = closetItem.lv_item_id
    if itemId and itemId > 0 then
      if itemType == _G.Enum.GoodsType.GT_FASHION then
        local meshPath, matPath = self:GetFashionResourcePath(itemId)
        local _, _, avatarEnum = self:GetConfigEnumFromFashionId(itemId)
        if bHasHat and avatarEnum == BT.Hair then
          meshPath = applyHatHairVariant(meshPath)
        end
        addPath(meshPath)
        addPath(matPath)
      elseif itemType == _G.Enum.GoodsType.GT_SALON then
        local salonItemConf = _G.DataConfigManager:GetSalonItemConf(itemId)
        if salonItemConf and salonItemConf.avatar_id then
          local bpPath, meshPath, matPath = self:GetSalonResourcePathByItem(salonItemConf.avatar_id, salonItemConf.texture_id or 0)
          local salonBodyEnum = self:GetConfigEnumFromSalonId(salonItemConf.avatar_id)
          if bHasHat and salonBodyEnum == BT.Hair then
            meshPath = applyHatHairVariant(meshPath)
          end
          addPath(bpPath)
          addPath(meshPath)
          addPath(matPath)
        end
      end
    end
  end
  return paths
end

function AppearanceModule:_DoOpenFashionUpgradePanel(suitId, parentPanel, defaultSelectIndex)
  local isOpening, _ = self:HasPanel("AppearanceUpgrade")
  local shopItemsList, suitInfo = self:GetFashionUpgradePanelInfo(suitId)
  if isOpening then
    local panel = self:GetPanel("AppearanceUpgrade")
    if panel then
      panel:Active(shopItemsList, parentPanel, suitInfo)
    end
  else
    self:OpenPanel("AppearanceUpgrade", shopItemsList, parentPanel, suitInfo, defaultSelectIndex)
  end
end

function AppearanceModule:OnCmdOpenFashionUpgradePanel(suitId, parentPanel, defaultSelectIndex)
  parentPanel = parentPanel or self:GetPanel("AppearanceCloset")
  local paths = self:CollectSuitUpgradeResourcePaths(suitId)
  if not paths or 0 == #paths then
    self:_DoOpenFashionUpgradePanel(suitId, parentPanel, defaultSelectIndex)
    return
  end
  
  local function onLoadSuc(caller, _assets, _sessionId)
    caller:_DoOpenFashionUpgradePanel(suitId, parentPanel, defaultSelectIndex)
  end
  
  local function onLoadFail(caller, _assets, _sessionId)
    Log.Warning("AppearanceModule:OnCmdOpenFashionUpgradePanel \229\141\135\231\186\167\233\131\168\228\187\182\232\181\132\230\186\144\229\138\160\232\189\189\229\164\177\232\180\165 suitId=", suitId)
    caller:_DoOpenFashionUpgradePanel(suitId, parentPanel, defaultSelectIndex)
  end
  
  _G.PlayerResourceManager:LoadResources_PlayerLogic_List(self, paths, true, onLoadSuc, onLoadFail)
end

function AppearanceModule:GetFashionUpgradePanelInfo(suitId)
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  local showItems = {}
  if suitConf and suitConf.lv_up_closet then
    for k, v in pairs(suitConf.lv_up_closet) do
      local buyNum = 0
      if self:CheckComponentIsUnlocked(k - 1, suitId) then
        buyNum = 1
      end
      table.insert(showItems, {buy_num = buyNum, componentData = v})
    end
  end
  local bHasGorgeousMagic = false
  local suitsConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  local packageId = suitsConf and suitsConf.package_id
  local packageConf = DataConfigManager:GetFashionPackageConf(packageId, true)
  local suitName, packageName
  if suitsConf then
    suitName = suitsConf.name
  end
  if packageConf then
    packageName = packageConf.name
  end
  local sgSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, suitId)
  if sgSuitId then
    bHasGorgeousMagic = true
  end
  return showItems, {
    suitTitle = suitName,
    packageTitle = packageName,
    bGorgeousMagic = bHasGorgeousMagic,
    packageId = packageId,
    suitId = suitId
  }
end

function AppearanceModule:DebugOpenAppearanceUpgradeTest()
  self:OpenPanel("AppearanceUpgrade")
end

function AppearanceModule:DebugOpenMagicVideoDetailsTest()
  self:OpenPanel("MagicVideoDetails")
end

function AppearanceModule:OnCmdOpenMagicWandDetailPanel(context)
  local isOpening, _ = self:HasPanel("MagicWandDetail")
  if not isOpening then
    self:OpenPanel("MagicWandDetail", context)
  end
end

function AppearanceModule:OnCmdOpenShiningMedalDetailPanel(context)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.OpenRelationTreeMedalDetail, context.bondId)
end

function AppearanceModule:OnCmdOpenCardSkinDetailPanel(context)
  local isOpening, _ = self:HasPanel("ShiningMedalDetail")
  if not isOpening then
    self:OpenPanel("ShiningMedalDetail", context)
  end
end

function AppearanceModule:OnCmdRefreshUpgradeComponentPanel(shopItemsList)
  local isOpening, _ = self:HasPanel("AppearanceUpgrade")
  if not isOpening then
    return
  end
  local panel = self:GetPanel("AppearanceUpgrade")
  if panel then
    panel:RefreshShowItemInfo(shopItemsList)
  end
end

function AppearanceModule:OnCmdCloseFashionUpgradePanel()
  local hasPanel = self:GetPanel("AppearanceUpgrade")
  if hasPanel then
    self:ClosePanel("AppearanceUpgrade")
  end
end

function AppearanceModule:OnCmdOpenAppearanceUpgradeSuccPanel(itemInfo)
  local isOpening, _ = self:HasPanel("AppearanceUpgradeSucc")
  if not isOpening then
    self:OpenPanel("AppearanceUpgradeSucc", itemInfo)
  end
end

function AppearanceModule:OnCmdAppearanceUpgradeSuccPanelClose()
  local isUpgradeComponentOpening, _ = self:HasPanel("AppearanceUpgrade")
  if isUpgradeComponentOpening then
    local panel = self:GetPanel("AppearanceUpgrade")
    if panel then
      panel:OnUpgradeSuccCallBack()
    end
  end
end

function AppearanceModule:OnCmdOpenAppearanceClosetPanel(action, bFastDressUp, bDirectToUpgrade, suitId, defaultUpgradeSelectIndex, defaultTabIndex, defaultSubTabIndex, bSkipSaveOnExit)
  local isOpening, _ = self:HasPanel("AppearanceCloset")
  if not isOpening then
    local resListData = _G.NRCPanelResLoadData()
    resListData.PreLoadResList = {}
    table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color2.T_UI_Closet_Color2'")
    table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color1.T_UI_Closet_Color1'")
    table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_black.T_UI_black'")
    table.insert(resListData.PreLoadResList, "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_YiGui_MeiRong.G6_CosPlay_YiGui_MeiRong_C'")
    table.insert(resListData.PreLoadResList, "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_YiGui_MeiRong_End.G6_CosPlay_YiGui_MeiRong_End_C'")
    self:OpenPanel("AppearanceCloset", action, bFastDressUp, bDirectToUpgrade, suitId, defaultUpgradeSelectIndex, defaultTabIndex, defaultSubTabIndex, bSkipSaveOnExit, resListData)
  end
  _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.RecycleAllThrowPets)
  UE.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.NRCAvatarWaitForStreamInWhenLoadSuit 1")
end

function AppearanceModule:OnCmdCloseAppearanceClosetPanel()
  local isOpening, _ = self:HasPanel("AppearanceCloset")
  if isOpening then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:ConfirmClose(true)
    end
  end
  UE.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.NRCAvatarWaitForStreamInWhenLoadSuit 0")
end

function AppearanceModule:OnCmdGetColorBGResByColorType(colorType)
  local PanelName = "AppearanceCloset"
  local hasPanel = self:HasPanel(PanelName)
  if not hasPanel then
    PanelName = "AppearanceTryOn"
    hasPanel = self:HasPanel(PanelName)
  end
  if hasPanel and self:GetPanel(PanelName) then
    if colorType == Enum.HairColours.HC_PURE then
      return self:GetRes("Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_black.T_UI_black'", PanelName)
    elseif colorType == Enum.HairColours.HC_GRADIENT then
      return self:GetRes("Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color1.T_UI_Closet_Color1'", PanelName)
    elseif colorType == Enum.HairColours.HC_HIGHLIGHT then
      return self:GetRes("Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color2.T_UI_Closet_Color2'", PanelName)
    end
  end
  return nil
end

function AppearanceModule:OnCmdOpenFashionMallPopup()
  if not _G.DataModelMgr.PlayerDataModel:HasStoryFlag(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_PIKA) then
    return
  end
  self.fashionMallPopUpDelayId = DelayManager:DelayFrames(1, function()
    if SceneUtils.IsInPikaShop() and self.pikaActivityList and #self.pikaActivityList > 0 then
      local isOpening = self:IsPanelInOpening("FashionMallPopup")
      if not isOpening then
        self:OpenPanel("FashionMallPopup", self.pikaActivityList[1])
        self:MarkPikaActivityHadPopUp(self.pikaActivityList[1].pikaActivityBaseId)
        table.remove(self.pikaActivityList, 1)
      end
    end
  end)
end

function AppearanceModule:OnCmdClearFashionMallPopup()
  self.pikaActivityList = {}
end

function AppearanceModule:OnCmdOpenFashionMallPopupByPackageId(packageId, closeCallback)
  if not packageId then
    Log.Error("AppearanceModule:OnCmdOpenFashionMallPopupByPackageId", "packageId is nil")
    return
  end
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("AppearanceModule:OnCmdOpenFashionMallPopupByPackageId", "player is nil")
    return
  end
  local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(packageId)
  if not fashionPackageConf then
    Log.Error("AppearanceModule:OnCmdOpenFashionMallPopupByPackageId", "FASHION_PACKAGE_CONF not found for packageId:", packageId)
    return
  end
  local isOpening = self:IsPanelInOpening("FashionMallPopup")
  if not isOpening then
    self:OpenPanel("FashionMallPopup", {
      kvBg = fashionPackageConf.kv_pop,
      pkgId = packageId,
      leftTime = 0,
      hideBtn2 = true,
      closeCallback = closeCallback
    })
  end
end

function AppearanceModule:OnCmdGetPackageIdByGoodsId(goodsId)
  return self.data:GetPackageIdByGoodsId(goodsId)
end

function AppearanceModule:OnCmdRefreshAppearancePanel(itemListInfo, isRefreshNewIcon)
  if self:HasPanel("AppearanceMain") then
    local panel = self:GetPanel("AppearanceMain")
    panel:RefreshPanelInfo(itemListInfo, false, isRefreshNewIcon)
  end
end

function AppearanceModule:OnCmdRefreshBeautyPanel(itemListInfo)
  if self:HasPanel("BeautyMain") then
    local panel = self:GetPanel("BeautyMain")
    panel:RefreshPanelInfo(itemListInfo, false)
  end
end

function AppearanceModule:OnCmdBeautyConfirm()
  if self:HasPanel("BeautyMain") then
    local panel = self:GetPanel("BeautyMain")
    panel:ConfirmConfirm()
  end
end

function AppearanceModule:OnCmdOpenTips(tipsType, param, lastname, curname)
  local isOpening, _ = self:HasPanel("AppearanceTip")
  if not isOpening then
    self:OpenPanel("AppearanceTip", tipsType, param, lastname, curname)
  end
end

function AppearanceModule:OnCmdShowAppearanceBackground(bShow)
  local isOpening, _ = self:HasPanel("AppearanceMain")
  if isOpening then
    local panel = self:GetPanel("AppearanceMain")
    if panel then
    end
  end
end

function AppearanceModule:OnCmdOpenSuitPopupPanel(fashionInfo, bLobbyMain, bOpen, IsWorldReloading, IsFirstOpen)
  local isOpening, _ = self:HasPanel("AppearanceSuit")
  if not isOpening and bOpen then
    self.data.IsWorldReloading = IsWorldReloading
    self.data.IsFirstOpen = IsFirstOpen
    self:OpenPanel("AppearanceSuit", fashionInfo, bLobbyMain)
  elseif isOpening and not bOpen then
    local panel = self:GetPanel("AppearanceSuit")
    if panel then
      panel:ClosePanel()
    end
  end
end

function AppearanceModule:OnCmdOpenSuitDetailsPanel(suitId, shopId, callParam)
  local isOpening, _ = self:HasPanel("AppearanceSuitDetails")
  if not isOpening then
    self:OpenPanel("AppearanceSuitDetails", suitId, shopId, callParam)
  end
end

function AppearanceModule:OnCmdOpenAppearanceTryOn(itemList, vItemType, price, goodsExpireTime, directWearSuitId)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local resListData = _G.NRCPanelResLoadData()
  resListData.PreLoadResList = {}
  table.insert(resListData.PreLoadResList, self:GetAvatarResPath(player.gender))
  table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color2.T_UI_Closet_Color2'")
  table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color1.T_UI_Closet_Color1'")
  table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_black.T_UI_black'")
  if self:HasPanel("AppearanceTryOn") then
    local tryOnPanel = self:GetPanel("AppearanceTryOn")
    if tryOnPanel and tryOnPanel.bPanelHiddenByUpgradeBtn then
      tryOnPanel:Enable()
      tryOnPanel:SetPanelAlreadyVisible()
      tryOnPanel.bPanelHiddenByUpgradeBtn = false
      return
    end
    if tryOnPanel then
      tryOnPanel:DoClose()
    end
    _G.DelayManager:DelayFrames(1, function()
      self:OpenPanel("AppearanceTryOn", itemList, vItemType, price, goodsExpireTime, resListData, directWearSuitId)
    end)
    return
  end
  self:OpenPanel("AppearanceTryOn", itemList, vItemType, price, goodsExpireTime, resListData, directWearSuitId)
end

function AppearanceModule:OnCmdCloseAppearanceTryOn()
  self:ClosePanel("AppearanceTryOn")
end

function AppearanceModule:OnCmdSwitchGorgeousMagicUMG(_bOpenOrClose, _suitId)
  if _bOpenOrClose then
    local _isOpening = self:IsPanelInOpening("GorgeousMagic")
    if not _isOpening then
      self:OpenPanel("GorgeousMagic", _suitId)
    else
      _G.NRCModuleManager:GetModule("AppearanceModule"):DispatchEvent(AppearanceModuleEvent.GorgeousMagicSuitIdChanged, _suitId)
    end
  else
    self:ClosePanel("GorgeousMagic")
  end
end

function AppearanceModule:OnCmdOpenMagicVideoDetailsPanel(goodsType, itemId, extraData)
  local _isOpening = self:IsPanelInOpening("MagicVideoDetails")
  if not _isOpening then
    local resListData = _G.NRCPanelResLoadData()
    resListData.PreparingResList = {}
    resListData.PreLoadResList = {}
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(itemId)
    if suitConf and suitConf.suit_effect_tips then
      for _, suit_tip in pairs(suitConf.suit_effect_tips) do
        if suit_tip and suit_tip.tips_image then
          local cover_texture_ref, cover_texture_path = _G.MediaUtils.ComputeCoverFilePath(suit_tip.tips_image)
          self:Log("pre load cover texture ", cover_texture_ref, cover_texture_path)
          local cover_texture_full_path = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(cover_texture_path)
          if UE4.UBlueprintPathsLibrary.FileExists(cover_texture_full_path) then
            table.insert(resListData.PreLoadResList, cover_texture_ref)
          end
        end
      end
    end
    self:OpenPanel("MagicVideoDetails", goodsType, itemId, extraData, resListData)
  end
end

function AppearanceModule:OnMagicVideoSuitSelected(suitId)
  local hasPanel = self:HasPanel("MagicVideoDetails")
  if hasPanel then
    local panel = self:GetPanel("MagicVideoDetails")
    panel:OnMagicVideoSuitSelected(suitId)
  end
end

function AppearanceModule:GetAvatarResPath(gender)
  local avatarResPath = ""
  if gender == _G.ProtoEnum.ESexValue.SEX_MALE then
    avatarResPath = UEPath.DEFAULT_AVATAR_PLAYER_MALE
  elseif gender == _G.ProtoEnum.ESexValue.SEX_FEMALE then
    avatarResPath = UEPath.DEFAULT_AVATAR_PLAYER_FEMALE
  end
  return avatarResPath
end

function AppearanceModule:OnCmdChangeAppearanceChooseType(chooseType)
  local IsNeedScollToStart
  if self.data.ChoosePreSuitType ~= chooseType then
    self.data.ChoosePreSuitType = chooseType
    IsNeedScollToStart = true
  else
    IsNeedScollToStart = false
  end
  if self:HasPanel("AppearanceMain") then
    local panel = self:GetPanel("AppearanceMain")
    panel:UpdateAppearanceList(IsNeedScollToStart)
    self:SetPlayerAngle(chooseType)
  end
end

function AppearanceModule:OnCmdSetClosetAvatarAngle(chooseType)
  self:SetPlayerAngle(chooseType, self.closetAvatarPlayer, "Closet")
end

function AppearanceModule:SetPlayerAngle(chooseType, avatarPlayer, contextKey)
  if nil == avatarPlayer or not UE4.UObject.IsValid(avatarPlayer) then
    return
  end
  local avatarRotation = avatarPlayer:K2_GetActorRotation()
  if not avatarRotation then
    Log.Debug("AppearanceModule:SetPlayerAngle avatarRotation is nil")
    return
  end
  local d = self.data
  local ctx
  if contextKey and d.rotationContexts[contextKey] then
    ctx = d.rotationContexts[contextKey]
  end
  local CCWAngle = 0
  local CWAngle = 0
  local initYaw = ctx and ctx.avatarPlayerRotation_InitializeYaw or d.AvatarPlayerRotation_InitializeYaw
  local rotRef = ctx and ctx.avatarPlayerRotation or d.AvatarPlayerRotation
  if chooseType == _G.Enum.FashionLabelType.FLT_BAGS or chooseType == _G.Enum.FashionLabelType.FLT_PENDANTA then
    rotRef.Yaw = (initYaw or 0) - 180
    if ctx then
      ctx.frontAndBackRotation_Yaw = rotRef.Yaw
      ctx.avatarPlayerRotation_Yaw = rotRef.Yaw
    else
      d.FrontAndBackRotation_Yaw = rotRef.Yaw
      d.AvatarPlayerRotation_Yaw = rotRef.Yaw
    end
    if avatarRotation.Yaw > 0 then
      CCWAngle = avatarRotation.Yaw - rotRef.Yaw
      CWAngle = 360 - CCWAngle
    elseif avatarRotation.Yaw > rotRef.Yaw then
      CCWAngle = avatarRotation.Yaw - rotRef.Yaw
      CWAngle = 360 - CCWAngle
    else
      CWAngle = rotRef.Yaw - avatarRotation.Yaw
      CCWAngle = 360 - CWAngle
    end
  else
    rotRef.Yaw = initYaw
    if ctx then
      ctx.frontAndBackRotation_Yaw = rotRef.Yaw
      ctx.avatarPlayerRotation_Yaw = rotRef.Yaw
    else
      d.FrontAndBackRotation_Yaw = rotRef.Yaw
      d.AvatarPlayerRotation_Yaw = rotRef.Yaw
    end
    if avatarRotation.Yaw > 0 then
      if avatarRotation.Yaw > rotRef.Yaw then
        CCWAngle = avatarRotation.Yaw - rotRef.Yaw
        CWAngle = 360 - CCWAngle
      else
        CWAngle = rotRef.Yaw - avatarRotation.Yaw
        CCWAngle = 360 - CWAngle
      end
    else
      CWAngle = -avatarRotation.Yaw + rotRef.Yaw
      CCWAngle = 360 - CWAngle
    end
  end
  Log.Debug(CWAngle, CCWAngle, chooseType, "AppearanceModule:SetPlayerAngle")
  if CWAngle <= CCWAngle then
    if ctx then
      ctx.avatarPlayerRotationAngle = CWAngle
      ctx.isClockwiseRotation = true
    else
      d.AvatarPlayerRotationAngle = CWAngle
      d.IsClockwiseRotation = true
    end
  elseif ctx then
    ctx.avatarPlayerRotationAngle = CCWAngle
    ctx.isClockwiseRotation = false
  else
    d.AvatarPlayerRotationAngle = CCWAngle
    d.IsClockwiseRotation = false
  end
  local angle = ctx and ctx.avatarPlayerRotationAngle or d.AvatarPlayerRotationAngle
  if 0 == angle then
    if chooseType == _G.Enum.FashionLabelType.FLT_BAGS or chooseType == _G.Enum.FashionLabelType.FLT_PENDANTA then
      return
    end
    if ctx then
      ctx.avatarPlayerRotationAngle = 180
    else
      d.AvatarPlayerRotationAngle = 180
    end
  end
  Log.Debug(avatarRotation, rotRef, ctx and ctx.frontAndBackRotation_Yaw or d.FrontAndBackRotation_Yaw, ctx and ctx.isClockwiseRotation or d.IsClockwiseRotation, "AppearanceModule:SetPlayerAngle")
  if ctx then
    ctx.isRotation = true
    ctx.startTime = 0
  else
    self.IsRotation = true
  end
end

function AppearanceModule:OnCmdChangeBeautyChooseType(chooseType)
  local itemList = self.data:GetBeautyList(chooseType)
  if self:HasPanel("BeautyMain") then
    local panel = self:GetPanel("BeautyMain")
    panel:UpdateBeautyList(itemList)
    panel:SetPlaySoundState(true)
  end
end

function AppearanceModule:OnCmdGetUIColorIndexToColorMap(index)
  return self.data.UIColorIndexToColorIdMap[index]
end

function AppearanceModule:ClearCrossTabAnim()
  if self:HasPanel("AppearanceMain") then
    local panel = self:GetPanel("AppearanceMain")
    panel:UnChooseCrossAnimation()
  end
end

function AppearanceModule:HideLocalPlayer()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerRotation = player:GetActorTransform().Rotation
  local playerLocation = player.viewObj:Abs_K2_GetActorLocation()
  local SKMComponent = player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  SKMComponent:SetComponentTickEnabled(false)
  if self:HasPanel("BeautyMain") then
    local AvatarSubsystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    self.AvatarPlayer = AvatarSubsystem:RequestAvatarActor(self.player.gender)
    self.AvatarPlayer.Hands.BoundsScale = 10
    self:Log("[AppearanceModule] Create AvatarPlayer", self.AvatarPlayer)
    local ActivePanelName = "BeautyMain"
    local path = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/MeiRong_Start_Loop.MeiRong_Start_Loop_C'"
    if ActivePanelName then
      local function OnLoadFailed(...)
        Log.Error(string.format("[AppearanceModule] %s Load Failed:", path))
      end
      
      self:LoadRes(ActivePanelName, path, self.PlayOpenBeautyPanelSkill, OnLoadFailed)
    end
    local avatarAnimConp = self.AvatarPlayer:GetComponentByClass(UE4.URocoAnimComponent)
    self.data.PlayMoZhangIdleTime = avatarAnimConp:GetAnimLengthByName("HZMoZhangLoop")
    self:ChangeSuitConfig(false)
    self:InitTempBeautyData()
    self:GetTempDataFromAvatar()
    self:OnCmdRefreshBeautyPanel()
  elseif self:HasPanel("AppearanceMain") then
    local AvatarSubsystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    self.AvatarPlayer = AvatarSubsystem:RequestAvatarActor(self.player.gender)
    self.AvatarPlayer.Hands.BoundsScale = 10
    self:Log("[AppearanceModule] Create AvatarPlayer", self.AvatarPlayer)
    self.AvatarPlayer:SetActorHiddenInGame(true)
    if self.NpcAction and self.NpcAction.Config.action_type == _G.Enum.ActionType.ACT_CAMP_OPENPIKA then
      self:OnLoadFinishedWithoutChannel()
    else
      self:OnLoadFinished()
    end
    local avatarAnimConp = self.AvatarPlayer:GetComponentByClass(UE4.URocoAnimComponent)
    self.data.PlayMoZhangIdleTime = avatarAnimConp:GetAnimLengthByName("HZMoZhangLoop")
    self:ChangeSuitConfig(true)
    self:GetTempDataFromAvatar()
    self:OnCmdRefreshAppearancePanel()
  end
end

function AppearanceModule:PlayOpenFashion()
  self.AvatarPlayer.OnLoadAvatarActorComplete:Unbind()
  local ActivePanelName = "AppearanceMain"
  local path = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/Cosplay_Start_Loop.Cosplay_Start_Loop_C'"
  if ActivePanelName then
    local function OnLoadFailed(...)
      Log.Error(string.format("[AppearanceModule] %s Load Failed:", path))
    end
    
    self:LoadRes(ActivePanelName, path, self.PlayOpenFashionPanelSkill, OnLoadFailed)
  end
end

function AppearanceModule:OnLoadFinishedWithoutChannel()
  self.AvatarPlayer.OnLoadAvatarActorComplete:Unbind()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayOpenFashion)
end

function AppearanceModule:OnLoadPanelRes()
  local ResListData = _G.NRCPanelResLoadData()
  ResListData.PreLoadResList = {}
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local path
  if 1 == player.gender then
    path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC1.BP_DefaultSuit_PC1_C'"
  elseif 2 == player.gender then
    path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_DefaultSuit_PC2.BP_DefaultSuit_PC2_C'"
  end
  table.insert(ResListData.PreLoadResList, path)
  return ResListData
end

function AppearanceModule:OnLoadFinished()
  self.AvatarPlayer:SetLightingChannels(false, true, false)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayOpenFashion)
end

function AppearanceModule:CreateAvatarPlayer(npcAction)
  self.NpcAction = npcAction
  local path
  if 1 == self.player.gender then
    path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_AvatarPlayer.BP_AvatarPlayer_C'"
  elseif 2 == self.player.gender then
    path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_AvatarPlayer2.BP_AvatarPlayer2_C'"
  end
  self.createAvatarId = _G.DelayManager:DelaySeconds(0.001, function()
    local ActivePanelName
    if self:HasPanel("BeautyMain") then
      ActivePanelName = "BeautyMain"
    elseif self:HasPanel("AppearanceMain") then
      ActivePanelName = "AppearanceMain"
    end
    if ActivePanelName then
      local function OnLoadFailed(...)
        Log.Error("[AppearanceModule] BP_AvatarPlayer Load Failed:", ...)
      end
      
      self:LoadRes(ActivePanelName, path, self.HideLocalPlayer, OnLoadFailed)
    else
      self:LogWarning("[AppearanceModule] Cannot found activated panel, but request create avatar player, maybe panel closed.")
    end
  end)
end

function AppearanceModule:SyncAvatar2Player()
  if not self.AvatarPlayer then
    return
  end
  local Rotation = self.AvatarPlayer:K2_GetActorRotation()
  local Location = self.AvatarPlayer:K2_GetActorLocation()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player.viewObj:K2_SetActorRotation(Rotation + UE4.FVector(0, 0, 90), false)
  player.viewObj:K2_SetActorLocation(Location + UE4.FVector(0, 0, 180), false, nil, false)
end

function AppearanceModule:ShowLocalPlayer()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if type(player) == "boolean" then
    Log.Warning("player is boolean")
    return
  end
  player.viewObj:SetActorHiddenInGame(false)
  if self.AvatarPlayer then
    self.AvatarPlayer.OnLoadAvatarActorComplete:Unbind()
    self.AvatarPlayer.OnSetAvatarBodyComplete:Unbind()
  end
  local SKMComponent = player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  SKMComponent:SetComponentTickEnabled(true)
  if self.AvatarPlayer then
    local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    avatarSystem:ReturnAvatarActor(self.AvatarPlayer)
    self:Log("[AppearanceModule] Remove AvatarPlayer", self.AvatarPlayer)
    self.AvatarPlayer = nil
  end
end

function AppearanceModule:ChangeSuitConfig(bFashion, bIgnoreTips)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local fashionItems = player:GetFashionItems()
  local salonIds = player:GetSalonIds()
  self:SetDefaultSuitAvatar(bFashion, fashionItems, salonIds, self.closetAvatarPlayer, function()
  end, bIgnoreTips)
end

function AppearanceModule:GetCombineBodyType(path)
  local combType = self.AvatarPlayer:GetCombineBodyType(path)
  local MainType, CombinedType = self.AvatarPlayer:ParseCombineBodyTypes(combType)
  local CombinedTypeTable = CombinedType:ToTable()
  return MainType, CombinedTypeTable
end

function AppearanceModule:GetCombineBodyTypeWorld(path)
  local combType = UE4.UAvatarBlueprintFunctionLibrary.GetCombineBodyType(path)
  local MainType, CombinedType = UE4.UAvatarBlueprintFunctionLibrary.ParseCombineBodyTypes(combType)
  local CombinedTypeTable = CombinedType:ToTable()
  return MainType, CombinedTypeTable
end

function AppearanceModule:GetCombineConfigTypeTable(fashionId)
  local combineConfigTable = {}
  local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(fashionId)
  local MainType, CombinedTypeTable = self:GetCombineBodyType(fashionItemConf.model)
  local bFashion, MainConfigType = UIUtils.GetConfigEnumByAvatarEnum(MainType)
  if MainType ~= UE4.EAvatarCombineBodyType.None then
    table.insert(combineConfigTable, MainConfigType)
    for k, v in ipairs(CombinedTypeTable) do
      local bFashion1, CombinedConfigType = UIUtils.GetConfigEnumByAvatarEnum(v)
      table.insert(combineConfigTable, CombinedConfigType)
    end
  end
  return combineConfigTable
end

function AppearanceModule:GetFullSalonId(configId, colorIndex)
  if colorIndex > 0 then
    colorIndex = colorIndex - 1
  end
  local fullSalonId = configId * 100 + colorIndex
  return fullSalonId
end

local function _GetAvatarBodyShortStr(avatarEnum)
  local UE4 = _G.UE4
  local BT = UE4.EAvatarBodyType
  local map = {
    [BT.Hair] = "Hr",
    [BT.Face] = "Fe",
    [BT.Brown] = "Br",
    [BT.EyeSocket] = "Et",
    [BT.Eye] = "Es",
    [BT.Ear] = "Er",
    [BT.Body] = "Cup",
    [BT.Hands] = "Ge",
    [BT.Pants] = "Ps",
    [BT.Socks] = "So",
    [BT.Shoes] = "Se",
    [BT.Bag] = "Bg",
    [BT.Hat] = "Ht",
    [BT.Wh] = "Wh",
    [BT.Wa] = "Wa",
    [BT.Heads] = "Hi",
    [BT.Faces] = "Fi",
    [BT.Earrings] = "Ei",
    [BT.Bags] = "Bi",
    [BT.Wand] = "Mw",
    [BT.Masks] = "Ms",
    [BT.Hg] = "Hg",
    [BT.Hp] = "Hp"
  }
  return map[avatarEnum] or "None"
end

local function _GetModelItemPathPrefix(avatarEnum, modelId)
  local UE4 = _G.UE4
  local BT = UE4.EAvatarBodyType
  if avatarEnum <= BT.DECORATOR then
    return "SKM_"
  end
  if avatarEnum == BT.Bags or avatarEnum == BT.Wand or avatarEnum == BT.Masks or avatarEnum == BT.Hg or avatarEnum == BT.Hp then
    return "SKM_"
  end
  local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(modelId)
  if fashionItemConf and fashionItemConf.is_skm and tonumber(fashionItemConf.is_skm) and 0 ~= tonumber(fashionItemConf.is_skm) then
    return "SKM_"
  end
  return "SM_"
end

local function _ParseAvatarModelID(modelId)
  local SHORT_BASE = 10000000
  local LONG_BASE = 1000000000
  local Base = modelId >= LONG_BASE and LONG_BASE or SHORT_BASE
  local gender = math.floor(modelId / Base)
  local bodyType = math.floor(modelId / (Base / 100)) % 100
  local bodyIndex = math.floor(modelId / (Base / 100000)) % 1000
  local matIndex, combineType
  if Base == SHORT_BASE then
    matIndex = modelId % 100
    combineType = 0
  else
    matIndex = math.floor(modelId / (Base / 100000000)) % 100
    combineType = modelId % 100
  end
  return gender, bodyType, bodyIndex, matIndex, combineType
end

local function _ParseAvatarSalonID(fullSalonId)
  local SHORT_BASE = 10000000
  local LONG_BASE = 1000000000
  if fullSalonId < SHORT_BASE then
    return nil
  end
  local Base = fullSalonId >= LONG_BASE and LONG_BASE or SHORT_BASE
  local gender = math.floor(fullSalonId / Base)
  local salonType = math.floor(fullSalonId / (Base / 10)) % 10
  local partIndex = math.floor(fullSalonId / (Base / 10000)) % 1000
  local bpIndex, selectIndex
  if Base == SHORT_BASE then
    bpIndex = fullSalonId % 1000
    selectIndex = 0
  else
    bpIndex = math.floor(fullSalonId / (Base / SHORT_BASE)) % 1000
    selectIndex = fullSalonId % 100
  end
  return gender, salonType, partIndex, bpIndex, selectIndex
end

function AppearanceModule:GetFashionResourcePath(fashionId)
  if not fashionId or fashionId < 10000000 then
    Log.Warning("AppearanceModule:GetFashionResourcePath invalid fashionId:", fashionId)
    return nil, nil
  end
  local gender, bodyType, bodyIndex, matIndex, combineType = _ParseAvatarModelID(fashionId)
  local UE4 = _G.UE4
  local avatarEnum = bodyType
  local bodyStr = _GetAvatarBodyShortStr(avatarEnum)
  if "None" == bodyStr then
    Log.Warning("AppearanceModule:GetFashionResourcePath invalid bodyType:", bodyType, "fashionId:", fashionId)
    return nil, nil
  end
  local modelMeshId = gender * 10000000 + bodyType * 100000 + bodyIndex * 100 + 1
  local folderPath = string.format("/Game/ArtRes/AnimSequence/Human/PC/PC%d/Avatar/%s/%d/", gender, bodyStr, modelMeshId)
  local prefix = _GetModelItemPathPrefix(avatarEnum, fashionId)
  local meshName = string.format("%sPC%d_%s_%d", prefix, gender, bodyStr, modelMeshId)
  local meshPath = string.format("%s%s.%s", folderPath, meshName, meshName)
  local materialPath
  if matIndex > 0 then
    local matName = string.format("MI_PC%d_%s_%d", gender, bodyStr, fashionId)
    materialPath = string.format("%sMat/%s.%s", folderPath, matName, matName)
  end
  return meshPath, materialPath
end

function AppearanceModule:GetSalonResourcePath(fullSalonId)
  if not fullSalonId then
    return nil, nil, nil
  end
  local gender, salonType, partIndex, bpIndex, selectIndex = _ParseAvatarSalonID(fullSalonId)
  if not gender then
    Log.Warning("AppearanceModule:GetSalonResourcePath invalid fullSalonId:", fullSalonId)
    return nil, nil, nil
  end
  local bpPath
  if bpIndex and bpIndex > 0 then
    local salonTypeStrArr = {
      "None",
      "Skin",
      "Hair",
      "EyeBrows",
      "EyeLash",
      "Eyes",
      "MakeUp"
    }
    local salonTypeStr = salonTypeStrArr[salonType + 2]
    if not salonTypeStr then
      Log.Warning("AppearanceModule:GetSalonResourcePath invalid salonType:", salonType)
      return nil, nil, nil
    end
    local bpIdStr = string.format("%d%d%03d", gender, salonType, bpIndex)
    bpPath = string.format("/Game/NewRoco/Modules/Core/Character/Avatar/%s/%s.%s_C", salonTypeStr, bpIdStr, bpIdStr)
  end
  local UE4 = _G.UE4
  local BT = UE4.EAvatarBodyType
  local salonTypeToBody = {
    [1] = BT.Hair,
    [2] = BT.Brown,
    [3] = BT.EyeSocket
  }
  local meshPath, materialPath
  local bodyTypeForMesh = salonTypeToBody[salonType]
  if bodyTypeForMesh and partIndex and partIndex > 0 then
    local matSuffix = selectIndex and selectIndex > 0 and selectIndex + 1 or 1
    local linkedModelId = gender * 10000000 + bodyTypeForMesh * 100000 + partIndex * 100 + matSuffix
    meshPath, materialPath = self:GetFashionResourcePath(linkedModelId)
  end
  return bpPath, meshPath, materialPath
end

function AppearanceModule:GetSalonResourcePathByItem(salonItemConfId, colorIndex)
  local fullSalonId = self:GetFullSalonId(salonItemConfId, colorIndex or 0)
  return self:GetSalonResourcePath(fullSalonId)
end

function AppearanceModule:OnCmdSetAppearance(fashionId, fashionGoodsId, bChoosed, glassInfo)
  local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(fashionId)
  self:ChangeSkeletalMesh(_G.Enum.GoodsType.GT_FASHION, fashionId, bChoosed, nil, glassInfo)
  local fashionGoodsId = self.data.FashionIdToGoodsIdMap[fashionId].id
  if fashionItemConf then
    local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
    local tag = AppearanceUtils.BuildTagArrayFromConf(fashionItemConf)
    self.data:TempCurAppearChooseInfo(fashionItemConf.type, fashionId, fashionGoodsId, bChoosed, tag, glassInfo)
  else
    Log.Error("FashionItem\228\184\141\229\173\152\229\156\168\239\188\140id\228\184\186\239\188\154", fashionId)
  end
  if self:HasPanel("AppearanceMain") then
    local panel = self:GetPanel("AppearanceMain")
    panel:UpdateCostMoney()
  end
end

function AppearanceModule:OnCmdSetBeauty(SalonId, bChangeSM, colorIndex)
  local salonItemConf = _G.DataConfigManager:GetSalonItemConf(SalonId)
  local salonGoodsData = self.data.SalonIdToGoodsIdMap[SalonId]
  local salonGoodsId = 0
  if salonGoodsData then
    salonGoodsId = salonGoodsData.id
  end
  if self.AvatarPlayer then
    local fullSalonId = self:GetFullSalonId(SalonId, colorIndex)
    self.AvatarPlayer:SetAvatarMaterialID(fullSalonId)
  end
  self.data:TempCurBeautyChooseInfo(salonItemConf.type, SalonId, salonGoodsId, colorIndex)
end

function AppearanceModule:ChangeSkeletalMesh(itemType, itemId, bChoosed, tag, glassInfo)
  if not self.AvatarPlayer then
    Log.Warning("self.AvatarPlayer is nil")
    return
  end
  local itemConf, bBodyType, avatarEnum
  if itemType == _G.Enum.GoodsType.GT_FASHION then
    itemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if itemConf then
      bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(itemConf.type)
    end
  elseif itemType == _G.Enum.GoodsType.GT_SALON then
    itemConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    if itemConf then
      bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumSalon(itemConf.type)
    end
  end
  if avatarEnum and itemConf then
    if bBodyType then
      if bChoosed then
        if itemType == _G.Enum.GoodsType.GT_SALON then
          self.AvatarPlayer:SetAvatarModelID(avatarEnum, true, 0)
        else
          local glassId = 0
          if glassInfo then
            glassId = CommonUIUtils.GetGlassInfoId(glassInfo)
          end
          self.AvatarPlayer:SetAvatarModelID(itemId, true, glassId)
          local fashionGoodsId = 0
          local fashionGoodsMap = self.data.FashionIdToGoodsIdMap[itemId]
          if fashionGoodsMap then
            fashionGoodsId = fashionGoodsMap.id
          end
          self.data:TempCurAppearChooseInfo(itemType, itemId, fashionGoodsId, bChoosed, tag, glassInfo)
        end
      else
        local bFashion, configEnum, Enum = self:GetConfigEnumFromFashionId(itemId)
        self.AvatarPlayer:SetAvatarModelID(Enum, true, 0)
      end
    elseif bChoosed then
      if itemType ~= _G.Enum.GoodsType.GT_FASHION or itemConf.change_bp then
      else
      end
    else
      self.AvatarPlayer:SetAvatarModelID(avatarEnum, true, 0)
    end
  end
  if self.NpcAction and self.NpcAction.Config.action_type ~= _G.Enum.ActionType.ACT_CAMP_OPENPIKA then
    self.AvatarPlayer.OnSetAvatarBodyComplete:Bind(self.AvatarPlayer, self.OnSetAvatarLoadComplete)
  end
end

function AppearanceModule:OnSetAvatarLoadComplete()
  self:SetLightingChannels(false, true, false)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetAppearConfirmBtnClickable, true)
end

function AppearanceModule:OnCmdSetAppearConfirmBtnClickable(bClickable)
  if self:HasPanel("AppearanceMain") then
    local panel = self:GetPanel("AppearanceMain")
    if panel then
      panel:SetConfirmBtnClickable(bClickable)
    end
  end
end

function AppearanceModule:OnCmdPlayAvatarAnim(bSuit, fashionId, avatarPlayer, bChoose)
  local Enum = _G.Enum
  avatarPlayer = avatarPlayer or self.closetAvatarPlayer
  if avatarPlayer and UE4.UObject.IsValid(avatarPlayer) then
    self.data.PlayAnimStartTime = 0
    local avatarAnimComp = avatarPlayer:GetComponentByClass(UE4.URocoAnimComponent)
    if avatarAnimComp then
      if bSuit then
        local IsPlayAnim = self:OnIsPlayAnim(avatarAnimComp)
        if IsPlayAnim then
          return
        end
        self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZLookBody", "HZIdle")
      else
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(fashionId)
        if not fashionItemConf then
          return
        end
        local IsPlayAnim = self:OnIsPlayAnim(avatarAnimComp)
        if fashionItemConf.type ~= Enum.FashionLabelType.FLT_WAND and IsPlayAnim then
          return
        end
        if fashionItemConf.type == Enum.FashionLabelType.FLT_HATS then
          self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZLookHead", "HZIdle", true)
        elseif fashionItemConf.type == Enum.FashionLabelType.FLT_SHOES or fashionItemConf.type == Enum.FashionLabelType.FLT_SOCKS then
          self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZLookFoot", "HZIdle", true)
        elseif fashionItemConf.type == Enum.FashionLabelType.FLT_BAGS then
          self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZLookBack", "HZIdle", true)
        elseif fashionItemConf.type == Enum.FashionLabelType.FLT_TOPS or fashionItemConf.type == Enum.FashionLabelType.FLT_BOTTOMS or fashionItemConf.type == Enum.FashionLabelType.FLT_SUIT or fashionItemConf.type == Enum.FashionLabelType.FLT_DRESSES then
          self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZLookBody", "HZIdle", true)
        elseif fashionItemConf.type == Enum.FashionLabelType.FLT_GLASSES or fashionItemConf.type == Enum.FashionLabelType.FLT_RINGS then
          self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZLookHand", "HZIdle", true)
        elseif fashionItemConf.type == Enum.FashionLabelType.FLT_WAND then
          if false == bChoose then
            self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZMoZhangEnd", "HZIdle", true)
          else
            self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZMoZhangStar", "HZMoZhangLoop", true)
          end
        end
      end
    end
  end
end

function AppearanceModule:OnIsPlayAnim(avatarAnimComp)
  if nil == avatarAnimComp then
    Log.Error("avatarAnimComp is nil")
    return
  end
  local ActionName = self.data.ActionName
  for i, Name in ipairs(ActionName) do
    if avatarAnimComp:IsAnimPlaying(Name) then
      return true
    end
  end
  return false
end

function AppearanceModule:OnPlayEndAnim()
  self.CanStopEnd = true
  local avatarAnimConp = self.player.viewObj:GetComponentByClass(UE4.URocoAnimComponent)
  avatarAnimConp:StopAllMontage()
  avatarAnimConp:PlayAnimByName("HZRelax")
  self.bAnimStopTick = false
end

function AppearanceModule:BackToWorld(bFashion)
  if bFashion then
    self:BackToWorldFashion()
  else
    self:BackToWorldBeauty(true)
  end
end

function AppearanceModule:BackToWorldFashion()
  self:GetTempDataFromAvatar()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.AvatarPlayer:BakeToCharacter(player.viewObj)
  local fashionIds = {}
  if self.data.TempAppearData and #self.data.TempAppearData > 0 then
    for k, v in ipairs(self.data.TempAppearData) do
      table.insert(fashionIds, v.FashionId)
    end
  end
  self:OnCmdSetFashionDataReq(self.data.lastSelectedWardrobeIndex, fashionIds)
end

function AppearanceModule:BakeToCharacter()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.AvatarPlayer then
    self.AvatarPlayer:BakeToCharacter(player.viewObj)
  end
  if self.closetAvatarPlayer and UE4.UObject.IsValid(self.closetAvatarPlayer) then
    if self:CheckAllComponentUnlocked(self.closetAvatarPlayer) then
      self:KeepClosetAvatarPosition()
      self.closetAvatarPlayer:BakeToCharacter(player.viewObj)
    else
      Log.Error("\229\176\157\232\175\149\229\156\168\229\173\152\229\156\168\230\156\170\230\139\165\230\156\137\233\131\168\228\187\182\231\154\132\230\151\182\229\128\153\229\176\134\229\164\150\232\167\130\229\136\183\229\136\176\229\164\167\228\184\150\231\149\140\232\167\146\232\137\178\232\186\171\228\184\138\239\188\140\232\191\153\228\184\141\230\173\163\229\184\184\239\188\129")
    end
  end
end

function AppearanceModule:BackToWorldBeauty(bBake)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if bBake then
    self.AvatarPlayer:BakeToCharacter(player.viewObj)
    self:OnCmdSetSalonDataReq()
  else
    local fashionItems = {}
    for k, v in ipairs(self.data.TempAppearData) do
      local temp = {
        wearing_item_id = v.FashionId,
        wearing_glass = self:GetCurSelectedItemGlassMap(v.FashionId)
      }
      table.insert(fashionItems, temp)
    end
    local salonIds = {}
    if self.data.SavedBeautyData and #self.data.SavedBeautyData > 0 then
      for k, v in ipairs(self.data.SavedBeautyData) do
        table.insert(salonIds, {
          item_wear_id = v.SalonId,
          color_wear_id = self.data.ColorIndexToColorIdMap[v.SalonColorIndex].id
        })
      end
    else
      local tempBeautyData = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetTempAppearOrBeautyData, _G.Enum.GoodsType.GT_SALON)
      if tempBeautyData and #tempBeautyData > 0 then
        for k, v in ipairs(tempBeautyData) do
          table.insert(salonIds, {
            item_wear_id = v.SalonId,
            color_wear_id = self.data.ColorIndexToColorIdMap[v.SalonColorIndex].id
          })
        end
      end
    end
    self:SetDefaultSuit(fashionItems, salonIds)
    self:OnCmdSetSalonDataReq(true)
  end
end

function AppearanceModule:LoadClosetAvatarTransform()
  if self.closetAvatarPlayer and UE4.UObject.IsValid(self.closetAvatarPlayer) then
    self.data.closetAvatarTransform = self.closetAvatarPlayer:Abs_GetTransform()
  end
end

function AppearanceModule:KeepClosetAvatarPosition()
  if self.closetAvatarPlayer and self.data.closetAvatarTransform then
    self.closetAvatarPlayer:Abs_K2_SetActorTransform_WithoutHit(self.data.closetAvatarTransform)
    self.data.closetAvatarTransform = nil
  end
end

function AppearanceModule:StopBlackLoop()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.StopBlackLoop)
end

function AppearanceModule:OnCmdStopBlackLoop()
  if self:HasPanel("AppearanceBlackPopUp") then
    local panel = self:GetPanel("AppearanceBlackPopUp")
    panel:StopLoopAnim()
  end
end

function AppearanceModule:OnCmdGetBeautyColorList(SalonId)
  local salonItemConf = _G.DataConfigManager:GetSalonItemConf(SalonId)
  local pathListTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CHANGE_COLOUR_CONF)
  local pathList = pathListTable:GetAllDatas()
  local selectColor = 0
  for k, v in ipairs(self.data.TempBeautyData) do
    if v.SalonId == SalonId then
      selectColor = v.SalonColorIndex
    end
  end
  local list = {}
  for k, v in pairs(pathList) do
    local UIIndex = v.ui_value
    if 100 == k then
      if salonItemConf.type == _G.Enum.SalonLabelType.SLT_HAIR then
        table.insert(list, {
          path = v.icon,
          salonId = SalonId,
          salonColorIndex = selectColor,
          UIColorIndex = UIIndex
        })
      end
    else
      table.insert(list, {
        path = v.icon,
        salonId = SalonId,
        salonColorIndex = selectColor,
        UIColorIndex = UIIndex
      })
    end
  end
  table.sort(list, function(a, b)
    return a.UIColorIndex < b.UIColorIndex
  end)
  if self:HasPanel("BeautyMain") then
    local panel = self:GetPanel("BeautyMain")
    panel:SetBeautyColorList(list)
  end
  return list
end

function AppearanceModule:OnCmdBuyAndWearSuitReq(index, fashionIds, salonIds, ignoreTips)
  local req = _G.ProtoMessage:newZoneSetFashionDataReq()
  local wearing_item = {}
  for k, v in pairs(fashionIds or {}) do
    local temp = {
      wearing_item_id = v,
      wearing_glass = self:GetCurSelectedItemGlassMap(v)
    }
    table.insert(wearing_item, temp)
  end
  if not self:CheckWearingItemListProperly(wearing_item) then
    Log.Warning("AppearanceModule:OnCmdBuyAndWearSuitReq \229\165\151\232\163\133\229\144\136\230\179\149\230\128\167\230\163\128\230\159\165\228\184\141\233\128\154\232\191\135")
    return
  end
  req.wearing_item = wearing_item
  req.salon_item_wear_id = salonIds
  req.wardrobe_index = index
  req.wardrobe_name = self.data:GetWardrobeDataByIndex(index + 1, true)
  req.use_wardrobe = true
  req.trig_by_interact = true
  self.bIgnoreTips = ignoreTips
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_FASHION_DATA_REQ, req, self, self.OnCmdBuyAndWearSuitRsp, false, false)
end

function AppearanceModule:OnCmdBuyAndWearSuitRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    return
  end
  local suit_id = rsp.fashion_info.suit_id
  local initSuit = rsp.fashion_info.wardrobe_data[rsp.fashion_info.current_wardrobe_index + 1].wearing_item
  local initSalon = rsp.fashion_info.wardrobe_data[rsp.fashion_info.current_wardrobe_index + 1].salon_item_wear_id
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local salonList = {}
  for k, v in ipairs(initSalon) do
    table.insert(salonList, {item_wear_id = v})
  end
  local curWardrobeIndex = rsp.fashion_info.current_wardrobe_index + 1
  _G.DataModelMgr.PlayerDataModel:SetPlayerFashionWardrobeInfo(curWardrobeIndex, rsp.fashion_info.wardrobe_data[curWardrobeIndex])
  if self.bChangeSuitWorld then
    self:SetDefaultSuit(initSuit, salonList, function()
      self:PlayReloadingSkill(localPlayer.viewObj)
    end, not self.bIgnoreTips)
  else
    self:PlayReloadingSkill(self.closetAvatarPlayer)
    local itemsToRemove = {}
    if self.data.TempAppearData then
      for k, v in ipairs(self.data.TempAppearData) do
        table.insert(itemsToRemove, {
          FashionType = v.FashionType,
          FashionId = v.FashionId
        })
      end
      for k, v in ipairs(itemsToRemove) do
        if v.FashionType ~= _G.Enum.FashionLabelType.FLT_WAND then
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurTryOnItemInfo, v.FashionType, v.FashionId, nil, nil, false)
        end
      end
    end
    self:SetDefaultSuitAvatar(true, initSuit, salonList, self.closetAvatarPlayer, nil, self.bIgnoreTips)
    local isPanelOpen = self:HasPanel("AppearanceCloset")
    if isPanelOpen then
      local panel = self:GetPanel("AppearanceCloset")
      if panel then
        panel:UpdateCurClosetTab(initSuit)
        panel:OnSaveFashionDataCallback(initSuit, initSalon)
      end
    end
    self:BakeToCharacter()
  end
  local isPanelOpen = self:HasPanel("AppearanceTryOn")
  if isPanelOpen then
    local panel = self:GetPanel("AppearanceTryOn")
    if panel then
      panel:UpdateTryOnAvatar(initSuit, initSalon)
    end
  end
  if 0 ~= suit_id then
    _G.DataModelMgr.PlayerDataModel:SetPlayerFashionInfo(nil, suit_id)
    self.data.lastSelectedWardrobeIndex = 0
  else
    local curWardrobeIndex = rsp.fashion_info.current_wardrobe_index + 1
    _G.DataModelMgr.PlayerDataModel:SetPlayerFashionWardrobeInfo(curWardrobeIndex, rsp.fashion_info.wardrobe_data[curWardrobeIndex])
  end
end

function AppearanceModule:OnCmdSetFashionDataReq(_index, fashionIds, nameString, bWorld, bDressUp, quickDressAllCollect, suitID, salonIds)
  self.quickDressAllCollect = quickDressAllCollect or false
  if nil ~= _index and nil == nameString then
    nameString = self.data:GetWardrobeDataByIndex(_index, true)
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local isWorld = bWorld and bWorld or false
  self:SetChangeSuitWorld(isWorld)
  local bDressUp = bDressUp and bDressUp or true
  local index = self.data.lastSelectedWardrobeIndex
  if _index then
    index = _index
  end
  local req = _G.ProtoMessage:newZoneSetFashionDataReq()
  local fashionData = {}
  local fashionList = {}
  local salonData = {}
  local salonList = {}
  if not bWorld then
    if fashionIds then
      local fashionItems = {}
      for _, v in pairs(fashionIds) do
        local temp = {
          wearing_item_id = v,
          wearing_glass = self:GetCurSelectedItemGlassMap(v)
        }
        table.insert(fashionItems, temp)
      end
      fashionData = fashionItems
    else
      fashionList, salonList = self.data:GetWardrobeDataByIndex(index)
      fashionData = fashionList
    end
    if salonIds then
      salonData = salonIds
    else
      fashionList, salonList = self.data:GetWardrobeDataByIndex(index)
      salonData = salonList
    end
  elseif quickDressAllCollect then
    fashionData = nil
    req.set_suit_id = true
    req.wear_suit_id = suitID
  else
    fashionList, salonList = self.data:GetWardrobeDataByIndex(index)
    fashionData = fashionList
    salonData = salonList
  end
  if not self:CheckWearingItemListProperly(fashionData) then
    Log.Warning("AppearanceModule:OnCmdSetFashionDataReq \229\165\151\232\163\133\229\144\136\230\179\149\230\128\167\230\163\128\230\159\165\228\184\141\233\128\154\232\191\135")
    return
  end
  if fashionData and #fashionData > 0 then
    for _, v in ipairs(fashionData) do
      if v and v.wearing_item_id and 0 ~= v.wearing_item_id then
        local bHasOwned = self:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, v.wearing_item_id)
        if not bHasOwned then
          Log.Error(string.format("AppearanceModule:OnCmdSetFashionDataReq \230\151\182\232\163\133\233\131\168\228\187\182 %s \230\156\170\230\139\165\230\156\137\239\188\140\232\183\179\232\191\135\228\191\157\229\173\152\232\175\183\230\177\130", tostring(v.wearing_item_id)))
          return
        end
      end
    end
  end
  req.wearing_item = fashionData
  req.wardrobe_index = index - 1
  req.wardrobe_name = nameString
  req.use_wardrobe = bDressUp
  req.trig_by_interact = self.data.IsWorldReloading
  req.salon_item_wear_id = salonData
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_FASHION_DATA_REQ, req, self, self.SetFashionDataRsp, false, false)
  self.bReceivedSetFashionRsp = false
end

function AppearanceModule:SetFashionDataRsp(_rsp)
  if 0 ~= _rsp.ret_info.ret_code then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local suit_id = _rsp.fashion_info.suit_id
  local initSuit
  initSuit = _rsp.fashion_info.wardrobe_data[_rsp.fashion_info.current_wardrobe_index + 1].wearing_item
  self:UpdateSavedItemGlassMap(initSuit)
  local initSalon = {}
  if _rsp.fashion_info.wardrobe_data[_rsp.fashion_info.current_wardrobe_index + 1].salon_item_wear_id then
    local salonItems = _rsp.fashion_info.wardrobe_data[_rsp.fashion_info.current_wardrobe_index + 1].salon_item_wear_id
    for k, v in ipairs(salonItems) do
      table.insert(initSalon, {item_wear_id = v})
    end
  else
    initSalon = player.serverData.salon_item_wear_data
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.bChangeSuitWorld then
    self:SetDefaultSuit(initSuit, initSalon, function()
      self:PlayReloadingSkill(localPlayer.viewObj)
    end, false)
    if 0 ~= suit_id then
      _G.DataModelMgr.PlayerDataModel:SetPlayerFashionInfo(nil, suit_id)
      self.data.lastSelectedWardrobeIndex = 0
    else
      local curWardrobeIndex = _rsp.fashion_info.current_wardrobe_index + 1
      _G.DataModelMgr.PlayerDataModel:SetPlayerFashionWardrobeInfo(curWardrobeIndex, _rsp.fashion_info.wardrobe_data[curWardrobeIndex])
    end
  else
    local curWardrobeIndex = _rsp.fashion_info.current_wardrobe_index + 1
    _G.DataModelMgr.PlayerDataModel:SetPlayerFashionWardrobeInfo(curWardrobeIndex, _rsp.fashion_info.wardrobe_data[curWardrobeIndex])
    local bSameAsAvatar = self:IsClosetAvatarSameAsSaved(initSuit, initSalon)
    if bSameAsAvatar then
      self:PlayReloadingSkill(self.closetAvatarPlayer)
      self:BakeToCharacter()
    else
      self:PlayReloadingSkill(self.closetAvatarPlayer)
      self:SetDefaultSuitAvatar(true, initSuit, initSalon, self.closetAvatarPlayer, function()
        self.closetAvatarPlayer.OnLoadAvatarActorComplete:Unbind()
        self:BakeToCharacter()
      end)
    end
    local isPanelOpen = self:HasPanel("AppearanceCloset")
    if isPanelOpen then
      local panel = self:GetPanel("AppearanceCloset")
      if panel then
        panel:UpdateTabBtnPromptByCurrentSuit(initSuit)
        panel:OnSaveFashionDataCallback(initSuit, initSalon)
        panel:SetConfirmBtnState()
        panel:UpdateListSelectionAfterSave()
        local curTabType = panel.data.closetChooseTabType
        local curWandId
        if initSuit then
          for _, v in ipairs(initSuit) do
            if v and v.wearing_item_id and v.wearing_item_id > 0 then
              local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
              if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
                curWandId = v.wearing_item_id
                break
              end
            end
          end
        end
        curWandId = curWandId or self:OnCmdGetCurSuitWandId()
        self:HideOrShowAppearanceById(true, curWandId, curTabType == _G.Enum.FashionLabelType.FLT_WAND)
      end
    end
  end
  local isSelectNew = true
  self:UpdateSuitList(false, isSelectNew)
  self.bReceivedSetFashionRsp = true
  if not self.quickDressAllCollect then
    self.data.lastSelectedWardrobeIndex = _rsp.fashion_info.current_wardrobe_index + 1
  end
end

function AppearanceModule:IsClosetAvatarSameAsSaved(savedFashionItems, savedSalonItems)
  if not self.closetAvatarPlayer or not UE4.UObject.IsValid(self.closetAvatarPlayer) then
    return false
  end
  local suitObj = self.closetAvatarPlayer:GetAvatarSuit()
  if not suitObj then
    return false
  end
  local curBodies = suitObj:GetBodies():ToTable()
  local curGlasses = suitObj:GetBodyGlasses():ToTable()
  local curFashionMap = {}
  for i, bodyId in ipairs(curBodies) do
    if bodyId and bodyId > 0 and not self:Is000Model(bodyId) then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(bodyId)
      if not fashionItemConf or fashionItemConf.type ~= _G.Enum.FashionLabelType.FLT_WAND then
        local glassId = curGlasses and curGlasses[i] or 0
        curFashionMap[bodyId] = glassId
      end
    end
  end
  local savedFashionMap = {}
  if savedFashionItems then
    for _, v in ipairs(savedFashionItems) do
      if v and v.wearing_item_id and v.wearing_item_id > 0 then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
        if not fashionItemConf or fashionItemConf.type ~= _G.Enum.FashionLabelType.FLT_WAND then
          local glassId = 0
          if v.wearing_glass and v.wearing_glass.glass_type ~= _G.Enum.GlassType.GT_NULL and 0 ~= v.wearing_glass.glass_value then
            glassId = CommonUIUtils.GetGlassInfoId(v.wearing_glass)
          end
          savedFashionMap[v.wearing_item_id] = glassId
        end
      end
    end
  end
  for id, glass in pairs(curFashionMap) do
    if nil == savedFashionMap[id] or savedFashionMap[id] ~= glass then
      return false
    end
  end
  for id, glass in pairs(savedFashionMap) do
    if nil == curFashionMap[id] or curFashionMap[id] ~= glass then
      return false
    end
  end
  local curSalons = suitObj:GetSalons():ToTable()
  local curSalonSet = {}
  for _, fullId in ipairs(curSalons) do
    if fullId and fullId > 0 then
      curSalonSet[fullId] = true
    end
  end
  local savedSalonSet = {}
  if savedSalonItems then
    for _, v in ipairs(savedSalonItems) do
      if v.item_wear_id and 0 ~= v.item_wear_id then
        local salonItemConf = _G.DataConfigManager:GetSalonItemConf(v.item_wear_id)
        if salonItemConf then
          local fullSalonId = self:GetFullSalonId(salonItemConf.avatar_id, salonItemConf.texture_id)
          savedSalonSet[fullSalonId] = true
        end
      end
    end
  end
  for id, _ in pairs(curSalonSet) do
    if not savedSalonSet[id] then
      return false
    end
  end
  for id, _ in pairs(savedSalonSet) do
    if not curSalonSet[id] then
      return false
    end
  end
  return true
end

function AppearanceModule:OnCmdSuitChangeWoreComponentReq(suitId, wornComponents)
  local req = _G.ProtoMessage:newZoneChangeWornComponentsReq()
  req.suit_id = suitId
  req.components_is_worn = {}
  if wornComponents then
    for k, v in ipairs(wornComponents) do
      table.insert(req.components_is_worn, v)
    end
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHANGE_WORN_COMPONENTS_REQ, req, self, self.SuitChangeWoreComponentRsp, false, false)
end

function AppearanceModule:SuitChangeWoreComponentRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\228\191\157\229\173\152\229\165\151\232\163\133\231\169\191\230\136\180\228\191\161\230\129\175\229\164\177\232\180\165")
    return
  end
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo.suit_info and #fashionInfo.suit_info > 0 then
    local index
    for k, v in pairs(fashionInfo.suit_info) do
      if v.suit_id == rsp.suit_info.suit_id then
        index = k
      end
    end
    if index then
      fashionInfo.suit_info[index] = rsp.suit_info
    end
  end
  local hasPanel = self:HasPanel("AppearanceUpgrade")
  if hasPanel then
    local panel = self:GetPanel("AppearanceUpgrade")
    if panel then
      panel:OnWornComponentChanged(rsp.suit_info.components_is_worn, rsp.suit_info.suit_id)
    end
  end
end

function AppearanceModule:OnCmdSuitUpgradeToLevelReq(components, suitId)
  local req = _G.ProtoMessage:newZoneFashionSuitsLevelUpReq()
  req.components = components
  req.fashion_suit_id = suitId
  self.oldUnlockedComponents = self:GetSuitUnlockComponents(suitId)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FASHION_SUITS_LEVEL_UP_REQ, req, self, self.SuitUpgradeToLevelRsp, false, false)
end

function AppearanceModule:SuitUpgradeToLevelRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\229\165\151\232\163\133\233\131\168\228\187\182\232\167\163\233\148\129\229\164\177\232\180\165")
    return
  end
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo.suit_info and #fashionInfo.suit_info > 0 then
    local index
    for k, v in pairs(fashionInfo.suit_info) do
      if v.suit_id == rsp.suit_info.suit_id then
        index = k
      end
    end
    if index then
      fashionInfo.suit_info[index] = rsp.suit_info
    else
      table.insert(fashionInfo.suit_info, rsp.suit_info)
    end
  else
    fashionInfo.suit_info = {}
    table.insert(fashionInfo.suit_info, rsp.suit_info)
  end
  if rsp.suit_info and rsp.suit_info.components_is_owned then
    local itemList = {}
    for _, v in pairs(rsp.suit_info.components_is_owned) do
      local isUnlockedNew = true
      for _, comp in pairs(self.oldUnlockedComponents or {}) do
        if v == comp then
          isUnlockedNew = false
          break
        end
      end
      if isUnlockedNew then
        table.insert(itemList, v)
      end
    end
    if 0 ~= #itemList then
      local itemInfo = {
        oldItemList = self.oldUnlockedComponents,
        itemList = itemList,
        suitId = rsp.suit_info.suit_id
      }
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceUpgradeSuccPanel, itemInfo)
    end
  end
  local hasCloset = self:HasPanel("AppearanceCloset")
  if hasCloset then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:UpdatePetIconBackground()
      panel:UpdateListByType(true, _G.Enum.FashionLabelType.FLT_SUIT, false, true)
    end
  end
  local hasPanel = self:HasPanel("AppearanceUpgrade")
  if hasPanel then
    local panel = self:GetPanel("AppearanceUpgrade")
    if panel then
      panel:RefreshShowItemInfo(rsp.suit_info.suit_id)
      panel:WearNewComponent()
    end
  end
  local hasTryOn = self:HasPanel("AppearanceTryOn")
  if hasTryOn then
    local panel = self:GetPanel("AppearanceTryOn")
    if panel then
      panel:RefreshSelectedSuitComponent(rsp.suit_info.suit_id)
    end
  end
end

function AppearanceModule:WearCurWardrobeSuit(wardrobeDataFashionIds)
  for i = 1, #wardrobeDataFashionIds do
    if wardrobeDataFashionIds[i] > 0 then
      local fashionGoodsId = self.data.FashionIdToGoodsIdMap[wardrobeDataFashionIds[i]].id
      self:OnCmdSetAppearance(wardrobeDataFashionIds[i], fashionGoodsId, true)
    end
  end
end

function AppearanceModule:OnCmdSetSalonDataReq(bSaved)
  local req = _G.ProtoMessage:newZoneSetSalonDataReq()
  local salonList = self.data.TempBeautyData
  if bSaved then
    salonList = self.data.SavedBeautyData
  end
  req.salon_item_wear_data = {}
  if salonList then
    for k, v in ipairs(salonList) do
      local salonItemConf = _G.DataConfigManager:GetSalonItemConf(v.SalonId)
      local colorId = salonItemConf.texture_id
      table.insert(req.salon_item_wear_data, {
        item_wear_id = v.SalonId,
        color_wear_id = colorId
      })
    end
  else
    Log.Error("AppearanceModule:OnCmdSetSalonDataReq salonData is nil")
  end
  self.bReceivedSetSalonRsp = false
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_SALON_DATA_REQ, req, self, self.SetSalonDataRsp, false, false)
end

function AppearanceModule:SetSalonDataRsp(_rsp)
  Log.Dump(_rsp, 5, "AppearanceModule:SetSalonDataRsp")
  if 0 == _rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:SetPlayerSalonInfo(_rsp.salon_info)
  end
  self.bReceivedSetSalonRsp = true
end

function AppearanceModule:OnCmdSaveCurAppearChooseInfo()
  self.data:SaveCurAppearChooseInfo()
end

function AppearanceModule:OnCmdUpdateWardrobeData(index, fashionIds, nameString)
  local fashionOwned = self.data.fashionHasList
  local curAppear = {}
  for i = 1, #self.data.TempAppearData do
    table.insert(curAppear, self.data.TempAppearData[i].FashionId)
  end
  if #fashionOwned < #curAppear then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopConfirm, self.data.TempAppearData, nil)
  else
    local OwnedNum = 0
    local NotOwnedFashionIds = curAppear
    for i = 1, #curAppear do
      for j = #fashionOwned, 1, -1 do
        if curAppear[i] == fashionOwned[j] then
          OwnedNum = OwnedNum + 1
          table.remove(NotOwnedFashionIds, i)
        end
      end
    end
    if OwnedNum < #curAppear then
      self:OnCmdSendNPCShopBuyReq()
    else
      self:OnCmdSetFashionDataReq(index, curAppear, "nameString")
    end
  end
end

function AppearanceModule:SetChangeSuitWorld(bWorld)
  self.bChangeSuitWorld = bWorld
end

function AppearanceModule:OnWardrobeIndexChanged(index, bWorld, quickDress, fashionIds, suitID)
  local ConfirmCheck = self:HasPanel("AppearanceTip")
  self:SetChangeSuitWorld(bWorld)
  if quickDress then
    self:OnQuickDressAllCollect(fashionIds, suitID)
  elseif bWorld then
    self:OnWardrobeIndexChangedWorld(index)
  else
    local closetPanel
    if self:HasPanel("AppearanceCloset") then
      closetPanel = self:GetPanel("AppearanceCloset")
    end
    local currentWardrobeData, currentSalonData = self.data:GetWardrobeDataByIndex(index)
    local bHasData = nil ~= currentWardrobeData or nil ~= currentSalonData
    if bHasData then
      self.data.canChangeWardrobeIndex = true
      self:OnCmdSetFashionDataReq(index)
      self.data.lastSelectedWardrobeIndex = index
      self.data.lastValidSelectedWardrobeIndex = index
      if closetPanel and closetPanel.bFastDressUp then
        local fashionIds = self:GetFashionIds(currentWardrobeData)
        local suitIds = self:OnCmdCheckSuitEffect(fashionIds)
        if suitIds and #suitIds > 0 then
          local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(suitIds[1])
          if fashionSuitConf then
            closetPanel:RefreshBrandLogoByBrandId(fashionSuitConf.fashion_bond_band)
          end
        end
      end
      return
    end
    self.data.lastSelectedWardrobeIndex = index
    self:DispatchEvent(AppearanceModuleEvent.OnSelectEmptySuitIndex, self.data.lastSelectedWardrobeIndex)
    if closetPanel and closetPanel.bFastDressUp then
      local wandId = self:OnCmdGetCurSuitWandId()
      closetPanel:RefreshBrandLogoByFashionConf(wandId)
    end
  end
end

function AppearanceModule:OnWardrobeIndexChangedWorld(index)
  self:OnCmdSetFashionDataReq(index, nil, nil, true)
  if index ~= self.data.lastSelectedWardrobeIndex then
    local tipText = _G.DataConfigManager:GetLocalizationConf("fashion_closet_bigworld").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipText)
  end
  self.data.lastSelectedAllCollectFashionIds = nil
end

function AppearanceModule:OnQuickDressAllCollect(fashionIds, suitID)
  self:OnCmdSetFashionDataReq(nil, fashionIds, nil, true, nil, true, suitID)
  if fashionIds ~= self.data.lastSelectedAllCollectFashionIds then
    local tipText = _G.DataConfigManager:GetLocalizationConf("fashion_closet_bigworld").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipText)
  end
  self.data.lastSelectedAllCollectFashionIds = fashionIds
end

function AppearanceModule:SetDefaultSuit(fashionItems, salonIds, callback, bShouldShowTips)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local defaultSuitClass
  if 1 == localPlayer.gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
  elseif 2 == localPlayer.gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = localPlayer.gender
  if salonIds and #salonIds > 0 then
    local salonWearIds = {}
    for k, v in ipairs(salonIds) do
      if v.item_wear_id and 0 ~= v.item_wear_id then
        local salonItemConf = _G.DataConfigManager:GetSalonItemConf(v.item_wear_id)
        if salonItemConf then
          local fullSalonId = self:GetFullSalonId(salonItemConf.avatar_id, salonItemConf.texture_id)
          table.insert(salonWearIds, fullSalonId)
        end
      end
    end
    defaultSuitObj:SetSalons(salonWearIds)
  end
  if fashionItems and #fashionItems > 0 then
    for k, v in ipairs(fashionItems) do
      if v and 0 ~= v.wearing_item_id then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
        if fashionItemConf then
          local bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(fashionItemConf.type)
          if bBodyType then
            local glassId = 0
            if v.wearing_glass and v.wearing_glass.glass_type ~= _G.Enum.GlassType.GT_NULL and 0 ~= v.wearing_item_id then
              glassId = CommonUIUtils.GetGlassInfoId(v.wearing_glass)
            end
            defaultSuitObj:SetBody(v.wearing_item_id, glassId)
          end
        end
      end
    end
  end
  if not self:CheckWearingItemListProperly(fashionItems) then
    Log.Warning("AppearanceModule:SetDefaultSuit \229\165\151\232\163\133\229\144\136\230\179\149\230\128\167\230\163\128\230\159\165\228\184\141\233\128\154\232\191\135\239\188\140\232\183\179\232\191\135\229\136\135\230\141\162")
    return
  end
  if fashionItems and #fashionItems > 0 then
    for _, v in ipairs(fashionItems) do
      if v and v.wearing_item_id and 0 ~= v.wearing_item_id then
        local bHasOwned = self:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, v.wearing_item_id)
        if not bHasOwned then
          Log.Error(string.format("AppearanceModule:SetDefaultSuit \230\151\182\232\163\133\233\131\168\228\187\182 %s \230\156\170\230\139\165\230\156\137\239\188\140\232\183\179\232\191\135\229\136\135\230\141\162", tostring(v.wearing_item_id)))
          return
        end
      end
    end
  end
  local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  avatarSystem:StopSwitchAvatarSuit(self.taskId)
  if self.SetDefaultSuitTaskId then
    avatarSystem:StopSwitchAvatarSuit(self.taskId)
    self.SetDefaultSuitTaskId = nil
  end
  if self.SetDefaultSuitCallbackWrapper then
    avatarSystem.OnSwitchAvatarSuitComplete:Remove(avatarSystem, self.SetDefaultSuitCallbackWrapper)
    self.SetDefaultSuitCallbackWrapper = nil
  end
  if callback then
    function self.SetDefaultSuitCallbackWrapper(InAvatarSystem, taskId)
      if taskId ~= self.SetDefaultSuitTaskId then
        return
      else
        callback(InAvatarSystem, taskId)
        self.SetDefaultSuitTaskId = nil
      end
    end
    
    avatarSystem.OnSwitchAvatarSuitComplete:Add(avatarSystem, self.SetDefaultSuitCallbackWrapper)
  end
  self.SetDefaultSuitTaskId = avatarSystem:StartSwitchAvatarSuit(localPlayer.viewObj.Mesh, defaultSuitObj)
  if nil == bShouldShowTips then
    bShouldShowTips = true
  end
  local fashionIds = self:GetFashionIds(fashionItems)
  self.data:CheckSuitEffect(fashionIds, bShouldShowTips)
end

function AppearanceModule:SetDefaultSuitAvatar(bFashion, fashionItems, salonIds, avatarPlayer, callback, bIgnoreTips)
  avatarPlayer = avatarPlayer or self.AvatarPlayer
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local defaultSuitClass, ActivePanelName
  if self:HasPanel("BeautyMain") then
    ActivePanelName = "BeautyMain"
  elseif self:HasPanel("AppearanceMain") then
    ActivePanelName = "AppearanceMain"
  elseif self:HasPanel("AppearanceCloset") then
    ActivePanelName = "AppearanceCloset"
  end
  if self.player.gender == Enum.ESexValue.SEX_MALE then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
  elseif self.player.gender == Enum.ESexValue.SEX_FEMALE then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = player.gender
  if nil == salonIds then
    local salonInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerSalonInfo()
    if salonInfo then
      salonIds = salonInfo.item_wear_data
    end
  end
  if salonIds and #salonIds > 0 then
    self.data.TempBeautyData = nil
    local salonWearIds = {}
    for k, v in ipairs(salonIds) do
      if v.item_wear_id and 0 ~= v.item_wear_id then
        local salonItemConf = _G.DataConfigManager:GetSalonItemConf(v.item_wear_id)
        if salonItemConf then
          local fullSalonId = self:GetFullSalonId(salonItemConf.avatar_id, salonItemConf.texture_id)
          table.insert(salonWearIds, fullSalonId)
        end
      end
    end
    defaultSuitObj:SetSalons(salonWearIds)
  end
  if fashionItems and #fashionItems > 0 then
    self.data.TempAppearData = nil
    self.data._suitWearIdCache = nil
    for k, v in pairs(fashionItems) do
      if v and 0 ~= v.wearing_item_id then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
        if fashionItemConf then
          local glassId = 0
          if v.wearing_glass and v.wearing_glass.glass_type ~= _G.Enum.GlassType.GT_NULL and 0 ~= v.wearing_glass.glass_value then
            glassId = CommonUIUtils.GetGlassInfoId(v.wearing_glass)
          end
          defaultSuitObj:SetBody(v.wearing_item_id, glassId)
        else
          Log.Error("fashion\228\184\141\229\173\152\229\156\168")
        end
      end
    end
  end
  if avatarPlayer and UE4.UObject.IsValid(avatarPlayer) then
    avatarPlayer:SwitchAvatarSuit(defaultSuitObj)
    if callback then
      avatarPlayer.OnLoadAvatarActorComplete:Bind(avatarPlayer, callback)
    end
    self:GetTempDataFromAvatar(avatarPlayer)
  end
  local fashionIds = self:GetFashionIds(fashionItems)
  self.data:CheckSuitEffect(fashionIds, not bIgnoreTips, true)
end

function AppearanceModule:OnSuitBake()
  if self.AvatarPlayer then
    self.AvatarPlayer.OnLoadAvatarActorComplete:Unbind()
  end
  if self.closetAvatarPlayer and UE4.UObject.IsValid(self.closetAvatarPlayer) then
    self.closetAvatarPlayer.OnLoadAvatarActorComplete:Unbind()
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:BakeToCharacter(player.viewObj)
  player.viewObj:SetActorHiddenInGame(true)
end

function AppearanceModule:IsDefaultSuitHair(hairPath)
  return string.match(hairPath, "_001_Hr", 1)
end

function AppearanceModule:IsWearDefaultSuitHair()
  local wear001 = false
  local playerFashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  local curFashionData = playerFashionInfo.fashion_data.wardrobe_data[playerFashionInfo.fashion_data.current_wardrobe_data_index + 1].fashion_id
  for k, v in ipairs(curFashionData) do
    if k == _G.Enum.FashionLabelType.FLT_HATS + 1 and 0 ~= v then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
      if self:IsDefaultSuitHair(fashionItemConf.model) ~= nil then
        wear001 = true
        break
      end
    end
  end
  return wear001
end

function AppearanceModule:ShowChangeHairMesh()
  if self:HasPanel("BeautyMain") and self.data.bShowDecorators == false and self:IsWearDefaultSuitHair() then
    return true
  else
    return false
  end
end

function AppearanceModule:OnCmdSendNPCShopBuyReq(shopId)
  shopId = 101
  local buyShopList = {}
  local buyItemList = {}
  local filterItemList = self.data:FilterHasAndInitFashion()
  local showType = _G.DataConfigManager:GetShopConf(shopId)
  local showTypeList = {}
  local moneyType = {}
  for i = 1, 3 do
    if nil ~= showTypeList[i] then
      table.insert(moneyType, showTypeList[i])
    end
  end
  if #filterItemList > 0 then
    for k, v in ipairs(filterItemList) do
    end
    local diamondCost, coinCost = self.data:SumAppearCostMoney()
    table.insert(buyShopList, {
      shopId = shopId,
      itemList1 = buyItemList,
      sumCost = {diamondCost, coinCost}
    })
    local panel = self:GetPanel("AppearanceMain")
    if panel then
      panel:SetCaptureBackground()
    end
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopConfirm, buyShopList, nil)
  else
    self:GetTempDataFromAvatar()
    local tipText = _G.DataConfigManager:GetLocalizationConf("fashion_save_nothingnew").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipText)
    local fashionIds = {}
    if self.data.TempAppearData and #self.data.TempAppearData > 0 then
      for k, v in ipairs(self.data.TempAppearData) do
        table.insert(fashionIds, v.FashionId)
      end
    end
    self:OnCmdSetFashionDataReq(self.data.lastSelectedWardrobeIndex, fashionIds)
  end
end

function AppearanceModule:OnNewFashionBondNotify(notify)
  if notify.fashion_bond_item and #notify.fashion_bond_item > 0 then
    _G.DataModelMgr.PlayerDataModel:UpdatePlayerBondInfo(notify.fashion_bond_item, notify.is_deduct)
  end
end

function AppearanceModule:OnNewColorSuitStateChangedNotify(notify)
  if notify and notify.fashion_bond_id and 0 ~= notify.fashion_bond_id then
    _G.DataModelMgr.PlayerDataModel:UpdateFashionBondColorSuitState(notify.fashion_bond_id, notify.color_suit_state)
  end
end

function AppearanceModule:OnCmdColseBackground()
  local HasPanel = self:HasPanel("AppearanceMain")
  if HasPanel then
    local panel = self:GetPanel("AppearanceMain")
    panel:SetBackgroundVisible(false)
  end
end

function AppearanceModule:HasNotOwnedFashion()
  if self.data.TempAppearData and #self.data.TempAppearData > 0 then
    local SameNum = 0
    for i = 1, #self.data.TempAppearData do
      for k, v in ipairs(self.data.fashionHasList) do
        if 0 ~= v and self.data.TempAppearData[i].FashionId == v then
          SameNum = SameNum + 1
        end
      end
    end
    if SameNum < #self.data.TempAppearData then
      return true
    else
      return false
    end
  else
    return false
  end
end

function AppearanceModule:OnCmdCheckHasOwned(type, id)
  local hasItem = false
  if type == _G.Enum.GoodsType.GT_FASHION then
    if self.data.fashionHasList and #self.data.fashionHasList > 0 then
      for k, v in ipairs(self.data.fashionHasList) do
        if 0 ~= v and id == v then
          hasItem = true
          return hasItem
        end
      end
    end
  elseif type == _G.Enum.GoodsType.GT_SALON and self.data.salonHasList and #self.data.salonHasList > 0 then
    for k, v in ipairs(self.data.salonHasList) do
      if 0 ~= v and id == v then
        hasItem = true
        return hasItem
      end
    end
  end
  return hasItem
end

function AppearanceModule:CheckHasSuit(suitId)
  local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if fashionSuitConf then
    local sameNum = 0
    for k, fashionId in ipairs(fashionSuitConf.item_id) do
      for j, ownedId in ipairs(self.data.fashionHasList) do
        if fashionId == ownedId then
          sameNum = sameNum + 1
          break
        end
      end
    end
    if sameNum == #fashionSuitConf.item_id then
      return true
    end
  end
  return false
end

function AppearanceModule:CheckSuitAtMonthlyShop(suitId)
  return self.data:CheckSuitAtMonthlyShop(suitId)
end

function AppearanceModule:CheckSuitAtRandomShop(suitId)
  return self.data:CheckSuitAtRandomShop(suitId)
end

function AppearanceModule:CheckSuitAtExchangeShop(suitId)
  return self.data:CheckSuitAtExchangeShop(suitId)
end

function AppearanceModule:CheckSuitAtShopGiftOrMonthlyShop_Old(suitId)
  return self.data:CheckSuitAtShopGiftOrMonthlyShop_Old(suitId)
end

function AppearanceModule:OnCmdCheckSuitTime(suitId, count)
  return self.data:CheckSuitTime(suitId, count)
end

function AppearanceModule:OnCmdGetSuitState(suitId)
  return self.data:GetSuitState(suitId)
end

function AppearanceModule:GetNormalShopConfBySuitId(suitId)
  return self.data:GetNormalShopConfBySuitId(suitId)
end

function AppearanceModule:GetNormalShopConfByFashionId(itemId)
  return self.data:GetNormalShopConfByFashionId(itemId)
end

function AppearanceModule:GetSuitGiftFashion(suitId)
  local conf = self:GetNormalShopConfBySuitId(suitId)
  if conf and conf.gift_list and #conf.gift_list > 0 then
    return conf.gift_list
  end
  return {}
end

function AppearanceModule:PlayOpenFashionPanelSkill(resRequest, Asset)
  self.bDialogueEnded = false
  local targets = {}
  local target
  if self.NpcAction then
    target = self.NpcAction:GetOwnerNPCView()
    target:SetActorEnableCollision(false)
  else
    target = AppearanceLocalUtils.GetShopNPC(self.player)
  end
  table.insert(targets, target)
  local skillClass = Asset
  local skillObj = self.AvatarPlayer.RocoSkill:FindOrAddSkillObj(skillClass)
  skillObj:SetCaster(self.AvatarPlayer)
  skillObj:SetTargets(targets)
  if self.NpcAction and self.NpcAction.Config.action_type == _G.Enum.ActionType.ACT_CAMP_OPENPIKA then
  else
    skillObj:RegisterEventCallback("HidePlayer", self, self.DelayHidePlayer)
  end
  skillObj:RegisterEventCallback("OpenPanel", self, self.SkillOpenFashion)
  skillObj:RegisterEventCallback("CameraBlur", self, self.SetCameraDOFFashion)
  local result = self.AvatarPlayer.RocoSkill:PlaySkill(skillObj)
  if result ~= UE4.ESkillStartResult.Success then
    self:SkillOpenFashion()
    return
  end
end

function AppearanceModule:SetPosAndLockOnGround(Model, Position, Rotation)
  if not self.NpcAction then
    return
  end
  local MeshComponent = self.NpcAction.Owner.owner.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  local RootComponent = Model:K2_GetRootComponent()
  RootComponent:K2_AttachToComponent(MeshComponent, "None", UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
  RootComponent:K2_SetRelativeLocation(Position, false, nil, false)
  RootComponent:K2_SetRelativeRotation(Rotation, false, nil, false)
  local ModelLocation = Model:Abs_GetTransform().Translation
  local ModelUnderLocation = ModelLocation
  local UnderLineBegin = UE4.FVector(ModelLocation.X, ModelLocation.Y, ModelLocation.Z + 500)
  local UnderLineEnd = UE4.FVector(ModelLocation.X, ModelLocation.Y, ModelLocation.Z - 500)
  local TraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
  local Hits, Success = UE4.UKismetSystemLibrary.Abs_LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), UnderLineBegin, UnderLineEnd, TraceChannel, false, nil, 0, nil)
  if Success then
    for _, Result in tpairs(Hits) do
      ModelUnderLocation.X = Result.ImpactPoint.X
      ModelUnderLocation.Y = Result.ImpactPoint.Y
      ModelUnderLocation.Z = Result.ImpactPoint.Z
      break
    end
  end
  Model:Abs_K2_SetActorLocation_WithoutHit(ModelUnderLocation)
end

function AppearanceModule:SkillOpenFashion(Event, Skill)
  local panel = self:GetPanel("AppearanceMain")
  if panel then
    self:InitAvatarRotationData(self.AvatarPlayer)
    panel:OnOpenSkillEnd()
  end
end

function AppearanceModule:InitAvatarRotationData(avatarPlayer, Yaw, InitialYaw, contextKey)
  if avatarPlayer then
    self.RotAvatarPlayer = avatarPlayer
    self.data.AvatarPlayerRotation = avatarPlayer:K2_GetActorRotation()
    self.data.AvatarPlayerRotation_Yaw = Yaw or avatarPlayer:K2_GetActorRotation().Yaw
    self.data.AvatarPlayerRotation_InitializeYaw = InitialYaw or avatarPlayer:K2_GetActorRotation().Yaw
    if contextKey then
      local rot = avatarPlayer:K2_GetActorRotation()
      self.data.rotationContexts[contextKey] = self.data.rotationContexts[contextKey] or {}
      local ctx = self.data.rotationContexts[contextKey]
      ctx.avatarPlayer = avatarPlayer
      ctx.avatarPlayerRotation = rot
      ctx.avatarPlayerRotation_Yaw = Yaw or rot.Yaw
      ctx.avatarPlayerRotation_InitializeYaw = InitialYaw or rot.Yaw
      ctx.frontAndBackRotation_Yaw = ctx.avatarPlayerRotation_Yaw
      ctx.startTime = 0
      ctx.endTime = 1
    end
  end
end

function AppearanceModule:DelayHidePlayer(Event, Skill)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerLocation = player.viewObj:Abs_K2_GetActorLocation()
  player.viewObj:SetActorHiddenInGame(true)
  player.viewObj:Abs_K2_SetActorLocation_WithoutHit(playerLocation - UE4.FVector(500, 0, -500))
  self.AvatarPlayer:SetActorHiddenInGame(false)
end

function AppearanceModule:CloseFashionPanelSkill()
  local path = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/Cosplay_End.Cosplay_End_C'"
  local ActivePanelName = "AppearanceMain"
  if ActivePanelName then
    local function OnLoadFailed(...)
      Log.Error(string.format("[AppearanceModule] %s Load Failed:", path))
    end
    
    self:LoadRes(ActivePanelName, path, self.LoadCloseFashionPanelSkillSuccess, OnLoadFailed)
  end
end

function AppearanceModule:LoadCloseFashionPanelSkillSuccess(resRequest, Asset)
  local targets = {}
  local target = self.NpcAction and self.NpcAction:GetOwnerNPCView() or self.player.viewObj
  table.insert(targets, target)
  local skillClass = Asset
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local skillObj = self.player.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  skillObj:SetCaster(self.player.viewObj)
  skillObj:SetTargets(targets)
  skillObj:RegisterEventCallback("ActionFinish", self, self.CloseSkillEnd)
  skillObj:RegisterEventCallback("OpenBlack", self, self.OnCmdOpenAppearanceBlack)
  skillObj:RegisterEventCallback("PlayHzRelaxAnim", self, self.PlayRelaxAnim)
  self.player.viewObj.RocoSkill:PlaySkill(skillObj)
end

function AppearanceModule:PlayRelaxAnim(Event, Skill)
  self:OnPlayEndAnim()
end

function AppearanceModule:OnInputTouchStart(Input)
  if self.CanStopEnd then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local avatarAnimConp = player.viewObj:GetComponentByClass(UE4.URocoAnimComponent)
    avatarAnimConp:StopAllMontage()
    self.CanStopEnd = false
  end
end

function AppearanceModule:CloseSkillEnd(Event, Skill)
  if not self.bDialogueEnded and self.NpcAction and self.NpcAction:GetOwnerNPCView() then
    self.NpcAction:GetOwnerNPCView():SetActorEnableCollision(true)
    self.NpcAction:Finish()
  end
  self.bDialogueEnded = false
end

function AppearanceModule:CloseBeautySkillEnd(Event, Skill)
  if not self.bDialogueEnded and self.NpcAction then
    self.NpcAction:GetOwnerNPCView():SetActorEnableCollision(true)
    self.NpcAction:Finish()
    if not self.bBeautyNotSave then
      self:BackToWorldBeauty(true)
    else
      self:BackToWorldBeauty(false)
    end
    self:ShowLocalPlayer()
  end
  self.bDialogueEnded = false
end

function AppearanceModule:GetSkillCamera(Event, Skill)
  self:ClearSkillCamera()
  self.SkillCameraActor1 = Skill.Blackboard:GetValueAsObject("camActor_0001")
  self.SkillCameraActorMesh1 = Skill.Blackboard:GetValueAsObject("camActor_0001_SA")
  Skill.Blackboard:RemoveObjectValue("camActor_0001")
  Skill.Blackboard:RemoveObjectValue("camActor_0001_SA")
end

function AppearanceModule:ClearSkillCamera()
  if self.SkillCameraActor1 and UE4.UObject.IsValid(self.SkillCameraActor1) then
    self.SkillCameraActor1:K2_DestroyActor()
    self.SkillCameraActor1 = nil
  end
  if self.SkillCameraActorMesh1 and UE4.UObject.IsValid(self.SkillCameraActorMesh1) then
    self.SkillCameraActorMesh1:K2_DestroyActor()
    self.SkillCameraActorMesh1 = nil
  end
end

function AppearanceModule:PlayOpenBeautyPanelSkill(resRequest, Asset)
  self.bDialogueEnded = false
  local skillClass = Asset
  local skillObj = self.AvatarPlayer.RocoSkill:FindOrAddSkillObj(skillClass)
  if skillObj then
    skillObj:SetCaster(self.AvatarPlayer)
    local target
    if self.NpcAction and self.NpcAction.Owner then
      target = self.NpcAction.Owner.owner.viewObj
      target:SetActorEnableCollision(false)
    else
      target = AppearanceLocalUtils.GetShopNPC(self.player)
      if not target then
        return
      end
    end
    skillObj:SetTargets({target})
    skillObj:RegisterEventCallback("OpenPanel", self, self.SkillOpenBeauty)
    skillObj:RegisterEventCallback("CameraBlur", self, self.SetCameraDOFBeauty)
    skillObj:RegisterEventCallback("HidePlayer", self, self.DelayHidePlayer)
    local result = self.AvatarPlayer.RocoSkill:PlaySkill(skillObj)
    if result ~= UE4.ESkillStartResult.Success then
      self:SkillOpenBeauty()
      return
    end
  end
end

function AppearanceModule:SkillOpenBeauty(Event, Skill)
  local panel = self:GetPanel("BeautyMain")
  if panel then
    panel:OnOpenSkillEnd()
  end
end

function AppearanceModule:PlayCloseBeautyPanelSkill(resRequest, Asset)
  local skillClass = Asset
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local skillObj = self.player.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  skillObj:SetCaster(self.player.viewObj)
  skillObj:RegisterEventCallback("ActionFinish", self, self.CloseBeautySkillEnd)
  skillObj:RegisterEventCallback("OpenBlack", self, self.OnCmdOpenAppearanceBlack)
  local target
  if self.NpcAction and self.NpcAction.Owner then
    target = self.NpcAction.Owner.owner.viewObj
  else
    target = AppearanceLocalUtils.GetShopNPC(self.player)
  end
  skillObj:SetTargets({target})
  self.player.viewObj.RocoSkill:PlaySkill(skillObj)
end

function AppearanceModule:PlayReloadingSkill(viewObj)
  if not self.data.IsFirstOpen then
    local skill_path = "/Game/ArtRes/Effects/G6Skill/AvaTar/G6_Avatar_FullBody_Fx01.G6_Avatar_FullBody_Fx01"
    if viewObj and UE4.UObject.IsValid(viewObj) then
      local skillComponent = viewObj.RocoSkill
      if skillComponent then
        local skillProxy = RocoSkillProxy.Create(skill_path, skillComponent)
        skillProxy:SetCaster(viewObj)
        skillProxy:SetPassive(true)
        local target = viewObj
        skillProxy:SetTargets({target})
        skillProxy:PlaySkill()
      end
    end
  end
  self.data.IsFirstOpen = false
end

function AppearanceModule:SetCameraDOFFashion(Event, Skill)
  self.SkillCameraActor = Skill.Blackboard:GetValueAsObject("camActor_0001")
  self.SkillCameraActorMesh = Skill.Blackboard:GetValueAsObject("camActor_0001_SA")
  local camComp = self.SkillCameraActor:GetComponentByClass(UE4.UCameraComponent)
  self:SetCameraDOF1(camComp, 660, true)
end

function AppearanceModule:AddSceneCaptureComponent()
  local SceneCaptureComponent = self.SkillCameraActor:GetComponentByClass(UE4.USceneCaptureComponent2D)
  if not SceneCaptureComponent then
    self.SceneCaptureComponent = self.SkillCameraActor:AddComponentByClass(UE4.USceneCaptureComponent2D, false, UE4.FTransform(), false)
  end
  local assetPath = "TextureRenderTarget2D'/Game/NewRoco/TUI/CaptureTest.CaptureTest'"
  self.CaptureTest = LoadObject(assetPath)
  if self.CaptureTest then
    self.SceneCaptureComponent.TextureTarget = self.CaptureTest
    self.SceneCaptureComponent.bCaptureEveryFrame = false
  end
end

function AppearanceModule:SetCameraDOFBeauty(Event, Skill)
  self.SkillCameraActor = Skill.Blackboard:GetValueAsObject("camActor_0001")
  self.SkillCameraActorMesh = Skill.Blackboard:GetValueAsObject("camActor_0001_SA")
  local camComp = self.SkillCameraActor:GetComponentByClass(UE4.UCameraComponent)
  self:SetCameraDOF1(camComp, 245.5, true)
end

function AppearanceModule:SetCameraDOF1(camComp, focalDistance, on)
  local settings = camComp.PostProcessSettings
  settings.bOverride_DepthOfFieldScale = on
  settings.bOverride_DepthOfFieldFocalDistance = on
  settings.bOverride_DepthOfFieldFarTransitionRegion = on
  settings.bOverride_DepthOfFieldNearTransitionRegion = on
  settings.bOverride_DepthOfFieldFarBlurSize = on
  settings.bOverride_DepthOfFieldNearBlurSize = on
  settings.DepthOfFieldScale = 10
  settings.DepthOfFieldFarTransitionRegion = 300
  settings.DepthOfFieldNearTransitionRegion = 500
  settings.DepthOfFieldFarBlurSize = 10
  settings.DepthOfFieldNearBlurSize = 140
  settings.DepthOfFieldFocalDistance = focalDistance
end

function AppearanceModule:InitDefaultSuitConf()
end

function AppearanceModule:OnTick(deltaTime)
  for ctxKey, ctx in pairs(self.data.rotationContexts) do
    if ctx.isRotation and ctx.avatarPlayer and UE4.UObject.IsValid(ctx.avatarPlayer) then
      self:_TickRotationContext(ctx, deltaTime)
    end
  end
  if self.IsRotation and self.RotAvatarPlayer and UE4.UObject.IsValid(self.RotAvatarPlayer) and (self:HasPanel("AppearanceCloset") or self:HasPanel("AppearanceTryOn")) then
    local managedByCtx = false
    for _, ctx in pairs(self.data.rotationContexts) do
      if ctx.avatarPlayer == self.RotAvatarPlayer then
        managedByCtx = true
        break
      end
    end
    if not managedByCtx then
      self.data.StartTime = self.data.StartTime + deltaTime
      local curRot = self.RotAvatarPlayer:K2_GetActorRotation()
      local toRotator = UE4.FRotator()
      if not self.data.IsClockwiseRotation then
        if curRot.Yaw < 0 then
          curRot.Yaw = curRot.Yaw + 360
        end
        if self.data.AvatarPlayerRotation_Yaw < 0 then
          self.data.AvatarPlayerRotation_Yaw = self.data.AvatarPlayerRotation_Yaw + 360
        end
        if curRot.Yaw < self.data.AvatarPlayerRotation_Yaw and math.abs(self.data.AvatarPlayerRotation_Yaw - curRot.Yaw) >= 0.01 then
          curRot.Yaw = curRot.Yaw + 360
        end
      elseif curRot.Yaw > self.data.AvatarPlayerRotation_Yaw and math.abs(curRot.Yaw - self.data.AvatarPlayerRotation_Yaw) >= 0.01 then
        curRot.Yaw = curRot.Yaw - 360
      end
      toRotator.Yaw = self.data.AvatarPlayerRotation_Yaw
      curRot.Yaw = self:Lerp(curRot, toRotator, self.data.StartTime * self.data.EndTime / (self.data.AvatarPlayerRotationAngle / 360))
      self.RotAvatarPlayer:K2_SetActorRotation(curRot, false)
      if math.abs(curRot.Yaw - self.data.AvatarPlayerRotation_Yaw) <= 0.01 then
        curRot.Yaw = self.data.FrontAndBackRotation_Yaw
        self.data.AvatarPlayerRotation_Yaw = self.data.AvatarPlayerRotation_InitializeYaw
        self.data.FrontAndBackRotation_Yaw = self.data.AvatarPlayerRotation_InitializeYaw
        self.RotAvatarPlayer:K2_SetActorRotation(curRot, false)
        self.data.StartTime = 0
        self.IsRotation = false
      end
    end
  end
  if self:HasPanel("AppearanceMain") and self.AvatarPlayer and self.NpcAction and self.NpcAction.Config.action_type ~= _G.Enum.ActionType.ACT_CAMP_OPENPIKA then
    self.data.PlayAnimStartTime = self.data.PlayAnimStartTime + deltaTime
    if self.data.curAppearChooseSubType == _G.Enum.FashionLabelType.FLT_WAND then
      if self.data.PlayAnimStartTime >= 1.2 then
        self.data.PlayAnimStartTime = 0
        local avatarAnimConp = self.AvatarPlayer:GetComponentByClass(UE4.URocoAnimComponent)
        avatarAnimConp:PlayAnimByName("HZMoZhangLoop", 1, 0, 0.25, 0.1)
      end
    elseif self.data.PlayAnimStartTime >= self.data.PlayAnimEndTime then
      self.data.PlayAnimStartTime = 0
      if self.AvatarPlayer then
        local avatarAnimConp = self.AvatarPlayer:GetComponentByClass(UE4.URocoAnimComponent)
        avatarAnimConp:StopAllMontage()
        avatarAnimConp:PlayAnimByName("HZRelax", 1, 0, 0.25, 0.1)
      end
    end
  end
  if false == self.bAnimStopTick and self.player.viewObj then
    local lastInput = self.player.viewObj.characterMovement:GetLastInputVector()
    if lastInput:Size() > 0 then
      local avatarAnimComp = self.player.viewObj:GetComponentByClass(UE4.URocoAnimComponent)
      avatarAnimComp:StopAnimByName("HZRelax")
      self.bAnimStopTick = true
    end
  end
end

function AppearanceModule:Lerp(fromRotator, toRotator, percent)
  percent = math.clamp(percent, 0, 1)
  local Yaw = fromRotator.Yaw * (1 - percent) + toRotator.Yaw * percent
  return Yaw
end

function AppearanceModule:SetAvatarRotation(delta, avatarPlayer)
  avatarPlayer = avatarPlayer or self.AvatarPlayer
  if avatarPlayer and UE4.UObject.IsValid(avatarPlayer) then
    local avatarRotation = avatarPlayer:K2_GetActorRotation()
    avatarPlayer:K2_SetActorRotation(avatarRotation - UE4.FVector(0, delta, 0), false)
  end
end

function AppearanceModule:CanChangeSuitWardrobeIndex()
  return self.data.canChangeWardrobeIndex
end

function AppearanceModule:SetSelectWardrobe(index)
  if self:HasPanel("AppearanceMain") then
    local panel = self:GetPanel("AppearanceMain")
    panel:SelectSuitItemByIndex(index)
  end
  if self:HasPanel("AppearanceCloset") then
    local panel = self:GetPanel("AppearanceCloset")
    panel:SelectSuitItemByIndex(index)
  end
end

function AppearanceModule:UpdateSuitList(bClicked, isSelectNew)
  if self:HasPanel("AppearanceMain") then
    local panel = self:GetPanel("AppearanceMain")
    local suitData = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    panel.Suit:UpdateList(suitData, bClicked, nil, isSelectNew)
    panel:SetPlaySoundState(true)
  end
  if self:HasPanel("AppearanceCloset") then
    local panel = self:GetPanel("AppearanceCloset")
    local suitData = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    panel.Suit:UpdateList(suitData, bClicked, nil, isSelectNew)
  end
end

function AppearanceModule:InitTempAppearData()
  if self.data.TempAppearData == nil then
    self.data.TempAppearData = {}
    local wardrobeIndex = self.data:GetCurSelectWardrobeIndex()
    local wardrobeData = self.data:GetWardrobeDataByIndex(wardrobeIndex)
    for k, v in ipairs(wardrobeData) do
      if v and 0 ~= v.wearing_item_id then
        local fashionGoodsId = self.data.FashionIdToGoodsIdMap[v].id
        table.insert(self.data.TempAppearData, {
          FashionType = k - 1,
          FashionId = v.wearing_item_id,
          FashionGoodsId = fashionGoodsId
        })
      end
    end
  end
  for k, v in ipairs(self.data.TempAppearData) do
    self:OnCmdSetAppearance(v.FashionId, v.FashionGoodsId, true, v.glassInfo)
  end
end

function AppearanceModule:InitTempBeautyData()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.data.TempBeautyData == nil then
    self.data.TempBeautyData = {}
    local salonIds = player:GetSalonIds()
    local colorIndex = 1
    if salonIds and #salonIds > 0 then
      for k, v in ipairs(salonIds) do
        if v.item_wear_id and 0 ~= v.item_wear_id then
          local salonGoodsId = self.data.SalonIdToGoodsIdMap[v.item_wear_id].id
          local salonColorConf = _G.DataConfigManager:GetChangeColourConf(v.color_wear_id)
          if salonColorConf then
            colorIndex = salonColorConf.rank_value
            self.data:TempCurBeautyChooseInfo(k - 1, v.item_wear_id, salonGoodsId, colorIndex)
          else
            Log.Error("\230\137\190\228\184\141\229\136\176\233\133\141\231\189\174\232\161\168\230\149\176\230\141\174")
          end
        end
      end
    end
  end
end

function AppearanceModule:OnCmdGetTempAppearOrBeautyData(type)
  if type == Enum.GoodsType.GT_FASHION then
    return self.data.TempAppearData
  elseif type == Enum.GoodsType.GT_SALON then
    return self.data.TempBeautyData
  end
end

function AppearanceModule:GetTempDataFromAvatar(avatarPlayer)
  avatarPlayer = avatarPlayer or self.AvatarPlayer
  if nil == avatarPlayer then
    return
  end
  local defaultSuitObj = avatarPlayer:GetAvatarSuit()
  if nil == defaultSuitObj then
    return
  end
  local TempBodyGlasses = defaultSuitObj:GetBodyGlasses():ToTable()
  local TempIDs = defaultSuitObj:GetBodies():ToTable()
  local TempSalons = defaultSuitObj:GetSalons():ToTable()
  self.data.TempAppearData = nil
  self.data._suitWearIdCache = nil
  for k, v in pairs(defaultSuitObj.SalonParams:ToTable()) do
  end
  for k, v in ipairs(TempIDs) do
    if self:Is000Model(v) == false then
      local bFashion, configEnum = self:GetConfigEnumFromFashionId(v)
      if configEnum and bFashion and v > 0 then
        local fashionGoodsId = 0
        local fashionGoodsMap = self.data.FashionIdToGoodsIdMap[v]
        if fashionGoodsMap then
          fashionGoodsId = fashionGoodsMap.id
        end
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
        local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
        local tag = fashionItemConf and AppearanceUtils.BuildTagArrayFromConf(fashionItemConf) or nil
        local glassInfo
        if TempBodyGlasses and nil ~= TempBodyGlasses[k] then
          glassInfo = CommonUIUtils.GetGlassInfoFromId(TempBodyGlasses[k])
        end
        self.data:TempCurAppearChooseInfo(configEnum, v, fashionGoodsId, true, tag, glassInfo)
      end
    end
  end
  for k, v in ipairs(TempSalons) do
    local salonAvatarId = math.floor(v / 100)
    local colorIndex = v % 100
    if self.data.AvatarSalonIdToSalonIds[salonAvatarId] and self.data.AvatarSalonIdToSalonIds[salonAvatarId][colorIndex + 1] then
      local salonConfId = self.data.AvatarSalonIdToSalonIds[salonAvatarId][colorIndex + 1]
      local salonGoods = self.data.SalonIdToGoodsIdMap[salonConfId]
      local salonGoodsId = 0
      if salonGoods then
        salonGoodsId = self.data.SalonIdToGoodsIdMap[salonConfId].id
      end
      local configEnum = self:GetConfigEnumFromSalonId(salonAvatarId)
      self.data:TempCurBeautyChooseInfo(configEnum, salonConfId, salonGoodsId, colorIndex)
    end
  end
end

function AppearanceModule:GetConfigEnumFromFashionId(Id)
  if Id < 10000000 then
    return
  end
  local bFashion = true
  local configEnum = _G.Enum.FashionLabelType.FLT_BEGIN
  local Base = 0
  if Id > 99999999 then
    Base = 1000000000
  else
    Base = 10000000
  end
  local AvatarEnum = math.floor(Id / (Base / 100) % 100)
  bFashion, configEnum = UIUtils.GetConfigEnumByAvatarEnum(AvatarEnum, Base)
  return bFashion, configEnum, AvatarEnum
end

function AppearanceModule:GetConfigEnumFromSalonId(Id)
  if Id < 10000000 then
    return
  end
  local configEnum = _G.Enum.SalonLabelType.SLT_BEGIN
  configEnum = math.floor(Id / 1000000 % 10)
  return configEnum
end

function AppearanceModule:Is000Model(Id)
  if Id < 10000000 then
    return
  end
  local b000 = false
  local num = math.floor(Id / 100) % 1000
  if num > 0 then
    b000 = false
  else
    b000 = true
  end
  return b000
end

function AppearanceModule:RegPanel(name, path, layer, customDisableRendering, disabldEsc, openAnimName, dependentPanelName)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/Appearance/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.enablePcEsc = not disabldEsc
  registerData.openAnimName = openAnimName
  registerData.dependentPanelName = dependentPanelName
  self:RegisterPanel(registerData)
end

function AppearanceModule:GetShopId()
  if self.NpcAction then
    return self.NpcAction.Config.action_param1
  end
  return 101
end

function AppearanceModule:ConfirmCloseMain()
  if self.NpcAction then
    local npcActor = self.NpcAction.Owner.owner.viewObj
    if npcActor then
      local animComp = npcActor:GetComponentByClass(UE4.URocoAnimComponent)
      if animComp then
        animComp:PlayAnimByName("HZMovein")
      end
    end
  else
    AppearanceLocalUtils.CloseShop()
  end
end

function AppearanceModule:ConfirmCloseBeauty(bNotSave)
  if self.NpcAction then
    local npcActor = self.NpcAction.Owner.owner.viewObj
    if npcActor then
      local animComp = npcActor:GetComponentByClass(UE4.URocoAnimComponent)
      if animComp then
        animComp:PlayAnimByName("HZMeiRongMoveBack")
      end
      local ActivePanelName = "BeautyMain"
      local path = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/MeiRong_End.MeiRong_End_C'"
      if ActivePanelName then
        local function OnLoadFailed(...)
          Log.Error(string.format("[AppearanceModule] %s Load Failed:", path))
        end
        
        self:LoadRes(ActivePanelName, path, self.PlayCloseBeautyPanelSkill, OnLoadFailed)
      end
      self.bBeautyNotSave = bNotSave
      if not self.NpcAction then
        return
      end
      _G.NRCAudioManager:PlaySound2DAuto(1077, "UMG_Beauty_Main_C:ConfirmClose")
    end
  else
    AppearanceLocalUtils.CloseShop()
  end
end

function AppearanceModule:OnCmdClearFashionItemSelection()
  if self:HasPanel("AppearanceMain") then
    local panel = self:GetPanel("AppearanceMain")
    panel:ClearListSelection()
  end
end

function AppearanceModule:OnCmdGetFashionOwnedBySuitId(suitId)
  return self.data:GetFashionOwnedBySuitId(suitId)
end

function AppearanceModule:OnCmdGetCurSuitWandId(serverData)
  local fashionIds
  if serverData then
    fashionIds = serverData.wearing_item
  else
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    fashionIds = player.serverData.wearing_item
  end
  if fashionIds and #fashionIds > 0 then
    for k, v in ipairs(fashionIds) do
      if v and v.wearing_item_id ~= nil and v.wearing_item_id > 0 then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
        if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND and v.wearing_item_id > 0 then
          return v.wearing_item_id
        end
      end
    end
  end
  return 32500101
end

function AppearanceModule:OnCmdCheckSuitEffect(fashionIds)
  if not self.data then
    Log.Error("AppearanceModule:OnCmdCheckSuitEffect: self.data is nil")
    return
  end
  return self.data:CheckSuitEffect(fashionIds)
end

function AppearanceModule:OnCmdOpenSeasonalCombinationBagShop(specificShopId, param1, combinationBagShopOpenContext, bDirectOpenTryOn, defaultSelectSuitId, bOnlyTryOn)
  local appearanceModuleEnum = _G.AppearanceModuleEnum
  if nil == specificShopId then
    specificShopId = appearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG
  end
  if nil == param1 then
    param1 = 0
  end
  self.data.combinationBagShopOpenContext = combinationBagShopOpenContext
  self.bDirectOpenTryOn = bDirectOpenTryOn
  self.directOpenSuitId = defaultSelectSuitId
  self.bOnlyTryOn = bOnlyTryOn
  _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.FinishNPCActionOpenShop, nil, specificShopId, param1)
end

function AppearanceModule:OnCmdOpenSeasonalCombinationBagShopDirectly(...)
  self:OpenPanel("SeasonalCombinationBagShop", ...)
end

function AppearanceModule:OnCmdEnableSeasonalCombinationBagShopPanel()
  local panel = self:GetPanel("SeasonalCombinationBagShop")
  if panel then
    panel:EnableAndShouldBanWorldRendering()
  end
end

function AppearanceModule:PreLoadSeasonalCombinationBagShop()
  self:PreLoadPanel("SeasonalCombinationBagShop")
end

function AppearanceModule:OnCmdOpenTailorShop(...)
  self:OpenPanel("TailorShop", ...)
end

function AppearanceModule:OnCmdHideOrShowTailorShopMoneyBtn(_IsShow)
  if self:HasPanel("TailorShop") then
    local Panel = self:GetPanel("TailorShop")
    if Panel then
      Panel:ShowOrHideMoneyBtn(_IsShow)
    end
  end
end

function AppearanceModule:OnCmdSetNPCActionOpenShop(npcActionOpenShop)
  if self and self.data then
    self.data.NPCActionOpenShop = npcActionOpenShop
  end
end

function AppearanceModule:OnCmdFindMinSGSuitId(fashionPackageId)
  local allSuits = self:OnCmdGetAllSuitsInPackage(fashionPackageId)
  local minSGSuitId
  if allSuits then
    for idx, suitId in ipairs(allSuits) do
      local sgSuitId = self:OnCmdCheckSGSuitId(suitId)
      if not minSGSuitId or minSGSuitId > sgSuitId then
        minSGSuitId = sgSuitId
      end
    end
  end
  return minSGSuitId
end

function AppearanceModule:OnCmdCheckSGSuitId(anySuitId)
  local suitConf = anySuitId and _G.DataConfigManager:GetFashionSuitsConf(anySuitId, true)
  local checkedSutiId = suitConf and (suitConf.suit_grade == Enum.SuitGrade.SG_BOND or suitConf.suit_grade == Enum.SuitGrade.SG_UNIBOND) and anySuitId
  return checkedSutiId
end

function AppearanceModule:GetStoreListRsp(_rsp)
  local shopId = _rsp.shop_data.id
  local shopConf = _G.DataConfigManager:GetShopConf(shopId)
  local shopType = shopConf.shop_type
  self.data.allClothShopInfoMap[_rsp.shop_data.id] = _rsp.shop_data.goods_data
  if shopType == _G.Enum.ShopType.ST_FASHION_PIKA then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.RefreshTryOnUnlockShop, _rsp.shop_data.goods_data, shopId)
  end
  if shopType == _G.Enum.ShopType.ST_FASHION_CLOSET then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.RefreshTryOnUnlockShop, _rsp.shop_data.goods_data, shopId)
  end
  if shopType == _G.Enum.ShopType.ST_FASHION_PIKA or shopType == _G.Enum.ShopType.ST_FASHION_RANDOM or shopType == _G.Enum.ShopType.ST_FASHION_DISCOUNT or shopType == _G.Enum.ShopType.ST_FASHION_CLOSET then
    self:DispatchEvent(AppearanceModuleEvent.ReceiveFashionShopData, shopId, _rsp)
  end
end

function AppearanceModule:OnCmdCalcFashionPackagePrice(fashionPackageId, packageOriginalPrice, shopId, packageGoodsId)
  if nil == packageOriginalPrice or nil == shopId or nil == packageGoodsId then
    Log.Error("AppearanceModule:OnCmdCalcFashionPackagePrice ", shopId, packageGoodsId)
    return nil, nil
  end
  local PackageTotalPrice = packageOriginalPrice
  local PackageFreePrice = 0
  local bHadOwnEntirePackage = true
  local AvailablePikaPointInPackageContent = 0
  local bInvalidServerData = false
  local packageGoodsData = _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, shopId, packageGoodsId)
  if packageGoodsData and packageGoodsData.sub_goods then
    for idx, subGoodsData in ipairs(packageGoodsData.sub_goods) do
      if subGoodsData.is_gift then
        PackageFreePrice = PackageFreePrice + subGoodsData.real_price.num
      end
      local bHasOwned = false
      local normalShopConf = _G.DataConfigManager:GetNormalShopConf(subGoodsData.goods_id)
      if normalShopConf then
        local goodsType = normalShopConf.Type
        local itemId = normalShopConf.item_id
        if Enum.GoodsType.GT_FASHION_SUITS == goodsType then
          bHasOwned = self:OnCmdHadOwnedEntireSuit(itemId)
        elseif Enum.GoodsType.GT_FASHION == goodsType then
          bHasOwned = self:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, itemId)
        elseif Enum.GoodsType.GT_CARD_SKIN == goodsType then
          bHasOwned = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.HasCardSkin, itemId)
        end
      end
      if not bHasOwned then
        bHadOwnEntirePackage = false
        AvailablePikaPointInPackageContent = AvailablePikaPointInPackageContent + self:OnCmdCalcPikaPoint(shopId, subGoodsData.goods_id, 1)
      end
    end
  else
    bInvalidServerData = true
    Log.Debug("AppearanceModule:OnCmdCalcFashionPackagePrice, \229\149\134\229\147\129\230\156\141\229\138\161\229\153\168\230\149\176\230\141\174\228\184\141\229\173\152\229\156\168", shopId, packageGoodsId)
  end
  return PackageTotalPrice, PackageFreePrice, bHadOwnEntirePackage, AvailablePikaPointInPackageContent, bInvalidServerData
end

function AppearanceModule:OnCmdCalcFashionSuitPrice(suitId)
  local fashionSuitTotalPrice = 0
  local fashionOwned, fashionNotOwned = self.data:GetFashionOwnedBySuitId(suitId)
  if fashionNotOwned then
    for idx, fashionItemId in ipairs(fashionNotOwned) do
      local fashionGoodsConf = self.data.FashionIdToGoodsIdMap[fashionItemId]
      if fashionGoodsConf then
        fashionSuitTotalPrice = fashionSuitTotalPrice + fashionGoodsConf.origin_price
      end
    end
  end
  return fashionSuitTotalPrice
end

function AppearanceModule:OnCmdSetTryOnBg(id)
  local hasPanel = self:HasPanel("AppearanceTryOn")
  if hasPanel then
    local panel = self:GetPanel("AppearanceTryOn")
    if panel then
      panel:SetCardBG(id)
    end
  end
end

function AppearanceModule:OnCmdRefreshTryOnUnlockShop(shopItemList, shopId)
  local hasPanel = self:HasPanel("AppearanceTryOn")
  if hasPanel then
    local panel = self:GetPanel("AppearanceTryOn")
    if panel then
      panel:RefreshTryOnUnlockShop(shopItemList, shopId)
    end
  end
  local hasPanel1 = self:HasPanel("AppearanceCloset")
  if hasPanel1 then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:RefreshTryOnUnlockShop(shopItemList, shopId)
    end
  end
end

function AppearanceModule:OnCmdSetCurTryOnItemInfo(type, id, goodsId, colorIndex, bChoosed, bInTryOn, bRefreshBrand, glassInfo, bFashionType)
  self.data.curTryOnItemInfo.type = type
  self.data.curTryOnItemInfo.id = id
  if bInTryOn then
    local hasPanel = self:HasPanel("AppearanceTryOn")
    if hasPanel then
      local panel = self:GetPanel("AppearanceTryOn")
      if panel then
        panel:SetCurSelectItem(type, id, goodsId)
      end
    end
  end
  if not bInTryOn then
    local hasPanel1 = self:HasPanel("AppearanceCloset")
    if hasPanel1 then
      local panel = self:GetPanel("AppearanceCloset")
      if panel then
        panel:SetCurSelectItem(type, id, colorIndex, bChoosed, nil, bRefreshBrand, glassInfo, bFashionType)
      end
    end
  end
end

function AppearanceModule:OnCmdSelectUpgradeItem(index)
  local hasPanel = self:HasPanel("AppearanceUpgrade")
  if hasPanel then
    local panel = self:GetPanel("AppearanceUpgrade")
    if panel then
      panel:SelectUpgradeItem(index)
    end
  end
end

function AppearanceModule:OnCmdEraseFashionPackageShopRedPoint()
  _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 309)
  _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 310)
  if self.data and type(self.data.PIKAShopActivityId) == "table" and #self.data.PIKAShopActivityId > 0 then
    local extraKeyArray = table.new(#self.data.PIKAShopActivityId, 0)
    for idx, activityId in ipairs(self.data.PIKAShopActivityId) do
      table.insert(extraKeyArray, {activityId})
    end
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPointWithExtraKeyList, ActivityEnum.RedPointKey.NewActivity, extraKeyArray)
  end
end

function AppearanceModule:OnCmdBuyFashions(shopId, goodsTable)
  local buyItemTable = {}
  if goodsTable and #goodsTable > 0 then
    for k, v in ipairs(goodsTable) do
      if v.goodsType == Enum.GoodsType.GT_FASHION_PACKAGE then
        table.insert(buyItemTable, {
          shopLibId = v.goodsId,
          selectedNum = v.num
        })
      else
        table.insert(buyItemTable, {
          shopLibId = v.goodsId,
          selectedNum = v.num
        })
      end
    end
  end
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.MallBuyItemReq, shopId, buyItemTable)
end

function AppearanceModule:ClearRotAvatarPlayer(contextKey)
  if contextKey then
    self.data.rotationContexts[contextKey] = nil
  else
    self.RotAvatarPlayer = nil
  end
end

function AppearanceModule:_TickRotationContext(ctx, deltaTime)
  ctx.startTime = ctx.startTime + deltaTime
  local curRot = ctx.avatarPlayer:K2_GetActorRotation()
  local toRotator = UE4.FRotator()
  if not ctx.isClockwiseRotation then
    if curRot.Yaw < 0 then
      curRot.Yaw = curRot.Yaw + 360
    end
    if ctx.avatarPlayerRotation_Yaw < 0 then
      ctx.avatarPlayerRotation_Yaw = ctx.avatarPlayerRotation_Yaw + 360
    end
    if curRot.Yaw < ctx.avatarPlayerRotation_Yaw and math.abs(ctx.avatarPlayerRotation_Yaw - curRot.Yaw) >= 0.01 then
      curRot.Yaw = curRot.Yaw + 360
    end
  elseif curRot.Yaw > ctx.avatarPlayerRotation_Yaw and math.abs(curRot.Yaw - ctx.avatarPlayerRotation_Yaw) >= 0.01 then
    curRot.Yaw = curRot.Yaw - 360
  end
  toRotator.Yaw = ctx.avatarPlayerRotation_Yaw
  curRot.Yaw = self:Lerp(curRot, toRotator, ctx.startTime * ctx.endTime / (ctx.avatarPlayerRotationAngle / 360))
  ctx.avatarPlayer:K2_SetActorRotation(curRot, false)
  if math.abs(curRot.Yaw - ctx.avatarPlayerRotation_Yaw) <= 0.01 then
    curRot.Yaw = ctx.frontAndBackRotation_Yaw
    ctx.avatarPlayerRotation_Yaw = ctx.avatarPlayerRotation_InitializeYaw
    ctx.frontAndBackRotation_Yaw = ctx.avatarPlayerRotation_InitializeYaw
    ctx.avatarPlayer:K2_SetActorRotation(curRot, false)
    ctx.startTime = 0
    ctx.isRotation = false
  end
end

function AppearanceModule:CreateClosetAvatarPlayer(npcAction)
  self.closetNpcAction = npcAction
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local path
  if player.gender == Enum.ESexValue.SEX_MALE then
    path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_AvatarPlayer.BP_AvatarPlayer_C'"
  elseif player.gender == Enum.ESexValue.SEX_FEMALE then
    path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_AvatarPlayer2.BP_AvatarPlayer2_C'"
  end
  self.loadClosetAvatarDelayId = _G.DelayManager:DelayFrames(1, function()
    local ActivePanelName
    if self:HasPanel("AppearanceCloset") then
      ActivePanelName = "AppearanceCloset"
    end
    if ActivePanelName then
      local function OnLoadFailed(...)
        Log.Error("[AppearanceModule] BP_AvatarPlayer Load Failed:", ...)
      end
      
      self:LoadRes(ActivePanelName, path, self.HideClosetLocalPlayer, OnLoadFailed)
    end
  end)
end

function AppearanceModule:SetFastDressUpAvatarPlayer(fastDressUpAvatarPlayer, fastDressUpAvatarWardrobe, bIgnoreTips, overrideFashionIds, overrideSalonIds)
  if not fastDressUpAvatarPlayer or not UE4.UObject.IsValid(fastDressUpAvatarPlayer) then
    return
  end
  self.closetAvatarPlayer = fastDressUpAvatarPlayer
  self.closetAvatarPlayer_Ref = UnLua.Ref(self.closetAvatarPlayer)
  self.closetAvatarPlayer.AnimComponent:InitAnimInstance()
  self.fastDressUpAvatarWardrobe = fastDressUpAvatarWardrobe
  self:InitAvatarRotationData(self.closetAvatarPlayer, nil, nil, "Closet")
  self.animManager:TryPlayBeginLoopAnimByName(fastDressUpAvatarPlayer, "HZIdle", "HZIdle")
  if self:HasPanel("AppearanceCloset") then
    if overrideFashionIds and overrideSalonIds then
      self:SetDefaultSuitAvatar(true, overrideFashionIds, overrideSalonIds, self.closetAvatarPlayer, function()
      end, bIgnoreTips)
    else
      self:ChangeSuitConfig(true, bIgnoreTips)
    end
    self:UpdateClosetPanelInfo()
    _G.NRCModuleManager:GetModule("AppearanceModule"):DispatchEvent(AppearanceModuleEvent.OnClosetPlayerInitOver)
    self:OnOpenClosetPanelSkillEnded()
  end
end

function AppearanceModule:UpdateClosetPanelInfo()
  local hasPanel = self:HasPanel("AppearanceCloset")
  if hasPanel then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:UpdatePanelInfo()
    end
  end
end

function AppearanceModule:CloseFastDressUpPanelHandle(subPanelUWorld)
  if self.closetAvatarPlayer and UE4.UObject.IsValid(self.closetAvatarPlayer) then
    self.closetAvatarPlayer.OnLoadAvatarActorComplete:Unbind()
    self.closetAvatarPlayer.OnSetAvatarBodyComplete:Unbind()
    if subPanelUWorld then
      local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(subPanelUWorld, UE.UAvatarSubsystem)
      avatarSystem:ReturnAvatarActor(self.closetAvatarPlayer)
      self:Log("[AppearanceModule] Remove AvatarPlayer", self.closetAvatarPlayer)
    end
    self.closetAvatarPlayer = nil
    self.closetAvatarPlayer_Ref = nil
  end
  self.data.rotationContexts.Closet = nil
end

function AppearanceModule:HideClosetLocalPlayer()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local SKMComponent = player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  SKMComponent:SetComponentTickEnabled(false)
  if self:HasPanel("AppearanceCloset") then
    local AvatarSubsystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    self.closetAvatarPlayer = AvatarSubsystem:RequestAvatarActor(player.gender)
    self.closetAvatarPlayer.Hands.BoundsScale = 10
    self.closetAvatarPlayer_Ref = UnLua.Ref(self.closetAvatarPlayer)
    self:Log("[AppearanceModule] Create ClosetAvatarPlayer", self.closetAvatarPlayer)
    if self.closetAvatarPlayer and UE4.UObject.IsValid(self.closetAvatarPlayer) then
      self.closetAvatarPlayer:SetActorHiddenInGame(true)
      self.closetAvatarPlayer:SetLightingChannels(false, true, false)
      self.closetAvatarPlayer:SetActorEnableCollision(false)
      self.closetAvatarPlayer.AnimComponent:InitAnimInstance()
      self:OpenClosetPanelSkill(self.closetNpcAction)
      player.viewObj:SetActorHiddenInGame(true)
      self.closetAvatarPlayer:SetActorHiddenInGame(false)
      self:ChangeSuitConfig(true)
    end
    _G.NRCModuleManager:GetModule("AppearanceModule"):DispatchEvent(AppearanceModuleEvent.OnClosetPlayerInitOver)
  end
end

function AppearanceModule:SyncClosetAvatar2Player()
  if not self.closetAvatarPlayer or not UE4.UObject.IsValid(self.closetAvatarPlayer) then
    return
  end
  local Rotation = self.closetAvatarPlayer:K2_GetActorRotation()
  local Location = self.closetAvatarPlayer:K2_GetActorLocation()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player.viewObj:K2_SetActorRotation(Rotation + UE4.FRotator(0, 90, 0), false)
  player.viewObj:K2_SetActorLocation(Location + UE4.FVector(0, 0, 90), false, nil, false)
  player.movementComponent:OnPause(false)
end

function AppearanceModule:ShowClosetLocalPlayer()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if type(player) == "boolean" then
    Log.Warning("player is boolean")
    return
  end
  player.viewObj:SetActorHiddenInGame(false)
  if self.closetAvatarPlayer and UE4.UObject.IsValid(self.closetAvatarPlayer) then
    self.closetAvatarPlayer.OnLoadAvatarActorComplete:Unbind()
    self.closetAvatarPlayer.OnSetAvatarBodyComplete:Unbind()
  end
  self:CloseClosetPanelSkill(self.closetNpcAction)
  local SKMComponent = player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  SKMComponent:SetComponentTickEnabled(true)
  if self.closetAvatarPlayer and UE4.UObject.IsValid(self.closetAvatarPlayer) then
    local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    avatarSystem:ReturnAvatarActor(self.closetAvatarPlayer)
    self:Log("[AppearanceModule] Remove AvatarPlayer", self.closetAvatarPlayer)
    self.closetAvatarPlayer = nil
    self.closetAvatarPlayer_Ref = nil
  end
  self.data.rotationContexts.Closet = nil
end

function AppearanceModule:OpenClosetPanelSkill(npcAction)
  if npcAction then
    local View = npcAction:GetOwnerNPCView()
    if View then
      local SkillComp = View.RocoSkill
      if SkillComp then
        local skillPath = "/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_YiGui_Start_Loop.G6_CosPlay_YiGui_Start_Loop"
        local Skill = RocoSkillProxy.Create(skillPath, SkillComp)
        if not Skill then
          npcAction:Finish(false)
          return
        end
        Skill:SetCaster(self.closetAvatarPlayer)
        Skill:SetTargets({View})
        Skill:RegisterEventCallback("OpenPanel", self, self.ShowClosetPanel)
        Skill:RegisterEventCallback("End", self, self.OnOpenClosetPanelSkillEnded)
        Skill:RegisterEventCallback("End", self, self.GetSkillCamera)
        Skill:PlaySkill()
      end
    end
  else
    self:ShowClosetPanel()
  end
end

function AppearanceModule:LoadOpenClosetPanelSkill()
  local skillPath = "/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_YiGui_Start_Loop.G6_CosPlay_YiGui_Start_Loop"
  self:PlayOpenSkill(nil, UE4.UClass.Load(skillPath))
end

function AppearanceModule:PlayOpenSkill(req, skillClass)
  local caster = self.closetAvatarPlayer
  if caster then
    local skillObj = caster.RocoSkill:FindOrAddSkillObj(skillClass)
    if skillObj then
      skillObj:SetCaster(caster)
      skillObj:SetTargets({
        self.closetNpcAction:GetOwnerNPCView()
      })
      skillObj:RegisterEventCallback("OpenPanel", self, self.ShowClosetPanel)
      caster.RocoSkill:LoadAndPlaySkill(skillObj)
    end
  end
end

function AppearanceModule:ShowClosetPanel()
  local hasPanel = self:HasPanel("AppearanceCloset")
  if hasPanel then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      self:InitAvatarRotationData(self.closetAvatarPlayer, nil, nil, "Closet")
      panel:SkillEndShowPanel()
      local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      local playerLocation = player.viewObj:Abs_K2_GetActorLocation()
      player.movementComponent:OnPause(true)
      player.viewObj:SetForceHidden(true)
    end
  end
end

function AppearanceModule:OnOpenClosetPanelSkillEnded(Event, Skill)
  self:DispatchEvent(AppearanceModuleEvent.OnOpenClosetPanelSkillEnded)
end

function AppearanceModule:CloseClosetPanelSkill(npcAction)
  if npcAction then
    local View = npcAction:GetOwnerNPCView()
    if View then
      local SkillComp = View.RocoSkill
      if SkillComp then
        local skillPath = "/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_YiGui_End.G6_CosPlay_YiGui_End"
        local Skill = RocoSkillProxy.Create(skillPath, SkillComp)
        if not Skill then
          self:Finish(false)
          return
        end
        SkillComp:StopCurrentSkill()
        Skill:SetCaster(self.closetAvatarPlayer)
        Skill:SetTargets({View})
        Skill:PlaySkill()
        Skill:RegisterEventCallback("End", self, self.OnCloseSkillEnded)
      end
    end
  end
end

function AppearanceModule:LoadCloseClosetPanelSkill()
  local skillPath = "/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_YiGui_End.G6_CosPlay_YiGui_End"
  self:PlayCloseSkill(nil, UE4.UClass.Load(skillPath))
end

function AppearanceModule:PlayCloseSkill(req, skillClass)
  local caster = self.closetAvatarPlayer
  if caster then
    caster.RocoSkill:StopCurrentSkill()
    local skillObj = caster.RocoSkill:FindOrAddSkillObj(skillClass)
    if skillObj then
      skillObj:SetCaster(caster)
      skillObj:SetTargets({
        self.closetNpcAction:GetOwnerNPCView()
      })
      skillObj:RegisterEventCallback("End", self, self.OnCloseSkillEnded)
      caster.RocoSkill:LoadAndPlaySkill(skillObj)
    end
  end
end

function AppearanceModule:OnCloseSkillEnded()
  self:ClearSkillCamera()
  if self.closetNpcAction then
    self.closetNpcAction = nil
  end
  self:ResetCamera()
end

function AppearanceModule:ResetCamera()
  local Player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Controller = Player:GetUEController()
  if Controller then
    Controller:ReleaseRocoCamera()
  end
end

function AppearanceModule:ChooseSalonTabInSkill()
  if self.closetAvatarPlayer then
    local caster = self.closetAvatarPlayer
    local skillPath = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_YiGui_MeiRong.G6_CosPlay_YiGui_MeiRong_C'"
    local skillClass = self:GetRes(skillPath, "AppearanceCloset")
    local skillComponent = caster.RocoSkill
    if not skillComponent then
      return
    end
    local skillObj = skillComponent:FindOrAddSkillObj(skillClass)
    if skillObj then
      if self.closetNpcAction then
        caster.RocoSkill:StopCurrentSkill()
        skillObj:SetCaster(caster)
        skillObj:SetTargets({
          self.closetNpcAction:GetOwnerNPCView()
        })
        skillObj:RegisterEventCallback("End", self, self.GetSkillCamera)
        skillObj:RegisterEventCallback("StartHZIdleAnim", self, self.StartHZIdleAnim)
        skillObj:RegisterEventCallback("StartHZMeiRongStartAnim", self, self.StartMeiRongStartAnim)
        skillObj:RegisterEventCallback("StartIdleAnim", self, self.StartIdleAnim)
        caster.RocoSkill:LoadAndPlaySkill(skillObj)
      else
        caster.RocoSkill:StopCurrentSkill()
        skillObj:SetCaster(caster)
        skillObj:SetTargets({
          self.fastDressUpAvatarWardrobe
        })
        skillObj:RegisterEventCallback("SetCamera", self, self.OnFastDressUpSetSkillCamera)
        skillObj:RegisterEventCallback("End", self, self.OnFastDressUpChangeViewSkillEnd)
        skillObj:RegisterEventCallback("StartHZIdleAnim", self, self.StartHZIdleAnim)
        skillObj:RegisterEventCallback("StartHZMeiRongStartAnim", self, self.StartMeiRongStartAnim)
        skillObj:RegisterEventCallback("StartIdleAnim", self, self.StartIdleAnim)
        caster.RocoSkill:LoadAndPlaySkill(skillObj)
      end
    end
  end
end

function AppearanceModule:OnFastDressUpSetSkillCamera(Event, Skill)
  self:DispatchEvent(AppearanceModuleEvent.OnFastDressUpSetSkillCamera, Skill)
end

function AppearanceModule:OnFastDressUpChangeViewSkillEnd(Event, Skill)
  self:DispatchEvent(AppearanceModuleEvent.OnFastDressUpChangeViewSkillEnd, Skill)
end

function AppearanceModule:ChooseFashionTabInSkill(bIgnoreAnim)
  if self.closetAvatarPlayer then
    local caster = self.closetAvatarPlayer
    local skillPath = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Cosplay/G6_CosPlay_YiGui_MeiRong_End.G6_CosPlay_YiGui_MeiRong_End_C'"
    local skillClass = self:GetRes(skillPath, "AppearanceCloset")
    local skillComponent = caster.RocoSkill
    if not skillComponent then
      return
    end
    local skillObj = skillComponent:FindOrAddSkillObj(skillClass)
    if skillObj then
      if self.closetNpcAction then
        caster.RocoSkill:StopCurrentSkill()
        skillObj:SetCaster(caster)
        skillObj:SetTargets({
          self.closetNpcAction:GetOwnerNPCView()
        })
        skillObj:RegisterEventCallback("End", self, self.GetSkillCamera)
        if not bIgnoreAnim then
          skillObj:RegisterEventCallback("StartIdleAnim", self, self.StartIdleAnim)
          skillObj:RegisterEventCallback("StartHZIdle", self, self.StartHZIdleAnim)
        end
        caster.RocoSkill:LoadAndPlaySkill(skillObj)
      else
        caster.RocoSkill:StopCurrentSkill()
        skillObj:SetCaster(caster)
        skillObj:SetTargets({
          self.fastDressUpAvatarWardrobe
        })
        skillObj:RegisterEventCallback("SetCamera", self, self.OnFastDressUpSetSkillCamera)
        skillObj:RegisterEventCallback("End", self, self.OnFastDressUpChangeViewSkillEnd)
        if not bIgnoreAnim then
          skillObj:RegisterEventCallback("StartIdleAnim", self, self.StartEndSkillIdleAnim)
          skillObj:RegisterEventCallback("StartHZIdle", self, self.StartEndSkillHZIdle)
        end
        caster.RocoSkill:LoadAndPlaySkill(skillObj)
      end
    end
  end
end

function AppearanceModule:StartHZIdleAnim()
  local avatarPlayer = self.closetAvatarPlayer
  if avatarPlayer then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.1
    param.blendOutTime = 0.2
    self.animManager:TryPlayAnimByNameWithParam(avatarPlayer, "HZIdle", false, param)
  end
end

function AppearanceModule:StartMeiRongStartAnim()
  local avatarPlayer = self.closetAvatarPlayer
  if avatarPlayer then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.2
    param.blendOutTime = 0.3
    self.animManager:TryPlayAnimByNameWithParam(avatarPlayer, "HZMeiRongStart", false, param)
  end
end

function AppearanceModule:StartIdleAnim()
  local avatarPlayer = self.closetAvatarPlayer
  if avatarPlayer then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.4
    param.blendOutTime = 0.1
    param.loopCount = -1
  end
end

function AppearanceModule:StartEndSkillIdleAnim()
  local avatarPlayer = self.closetAvatarPlayer
  if avatarPlayer then
    local param = self.animManager:CreateAnimPlayParamInstance()
    param.blendInTime = 0.1
    param.blendOutTime = 0.3
  end
end

function AppearanceModule:StartEndSkillHZIdle()
  local avatarPlayer = self.closetAvatarPlayer
  if avatarPlayer then
    self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "HZIdle", "HZIdle", false)
  end
end

function AppearanceModule:OnCmdChooseClosetTab(tabConfId, tabInfo)
  local hasPanel = self:HasPanel("AppearanceCloset")
  if hasPanel then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      local bEnterFilterGlassItemState = panel.bEnterFilterGlassItemState
      local bShowFilterGlassItem = panel.bShowFilterGlassItem
      if tabInfo.LabelType == self.data.closetChooseOutterTab and tabInfo.LabelType ~= _G.Enum.FashionLabelType.FLT_SUIT and not bEnterFilterGlassItemState and not bShowFilterGlassItem then
        return
      end
      if -1 ~= self.data.closetChooseOutterTab then
        if tabInfo.bFashion == true and tabInfo.LabelType ~= _G.Enum.FashionLabelType.FLT_SALON then
          if self.data.closetChooseOutterTab == _G.Enum.FashionLabelType.FLT_SALON or self.data.bChooseClosetFashionTab == false then
            local shouldIgnoreAnim = tabInfo.LabelType == _G.Enum.FashionLabelType.FLT_WAND
            self:OnCmdPlayMeiRongSkillByType(true, shouldIgnoreAnim)
          end
        elseif self.data.closetChooseOutterTab ~= _G.Enum.FashionLabelType.FLT_SALON and true == self.data.bChooseClosetFashionTab then
          self:OnCmdPlayMeiRongSkillByType(false)
        end
      end
      panel:ChooseClosetTab(tabConfId, tabInfo)
    end
  end
end

function AppearanceModule:OnCmdPlayMeiRongSkillByType(bFashion, bIgnoreAnim)
  if bFashion then
    self:ChooseFashionTabInSkill(bIgnoreAnim)
  else
    self:ChooseSalonTabInSkill()
  end
  local hasPanel = self:HasPanel("AppearanceCloset")
  if hasPanel then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:SetBlandLogoHide(not bFashion)
    end
  end
end

function AppearanceModule:OnCmdChooseClosetSubTab(tabConfId, tabInfo)
  local hasPanel = self:HasPanel("AppearanceCloset")
  if hasPanel then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:ChooseClosetSubTab(tabConfId, tabInfo)
    end
  end
end

function AppearanceModule:OnCmdGetChooseClosetTabType()
  return self.data.bChooseClosetFashionTab, self.data.closetChooseTabType
end

function AppearanceModule:OnCmdGetSuitIdFromFashionId(fashionId)
  return self.data.fashionIdToSuitIdMap[fashionId]
end

function AppearanceModule:OnCmdGetSuitIdFromLevelUpItemId(bFashion, itemId)
  if bFashion then
    return self.data.levelUpFashionIdToSuitIdMap[itemId]
  end
  return self.data.levelUpSalonIdToSuitIdMap[itemId]
end

function AppearanceModule:OnCmdGetHairColorOwnedList(id)
end

function AppearanceModule:OnCmdSetClosetAvatar(bFashion, type, id, colorIndex, bChoosed, glassInfo)
  if bFashion then
    if type == Enum.FashionLabelType.FLT_BAGS or type == Enum.FashionLabelType.FLT_PENDANTA then
      self.bStartRot = true
    else
      self.bStartRot = false
    end
    self:OnCmdSetClosetAppearance(id, bChoosed, nil, glassInfo)
  else
    self:OnCmdSetClosetBeauty(id, colorIndex, glassInfo)
  end
end

function AppearanceModule:OnCmdSetClosetAppearance(fashionId, bChoosed, bShow, glassInfo)
  local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(fashionId)
  if nil ~= bChoosed then
    self:ChangeClosetSkeletalMesh(_G.Enum.GoodsType.GT_FASHION, fashionId, bChoosed, glassInfo)
    if fashionId > 0 then
      local fashionGoods = self.data.FashionIdToGoodsIdMap[fashionId]
      local fashionGoodsId = 0
      if fashionGoods then
        fashionGoodsId = fashionGoods.id
      end
      local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
      local tag = fashionItemConf and AppearanceUtils.BuildTagArrayFromConf(fashionItemConf) or nil
      self.data:TempCurAppearChooseInfo(fashionItemConf.type, fashionId, fashionGoodsId, bChoosed, tag, glassInfo)
      if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_BOTTOMS and bChoosed then
        local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        local initSuitId = self.data:GetInitialSuitIdByFashionId(fashionId, player.gender)
        if initSuitId then
          self.data:SetInitialSuitBottomCache(player.gender, initSuitId)
        end
      end
    end
  end
  if nil ~= bShow then
    self:ChangeClosetSkeletalMesh(_G.Enum.GoodsType.GT_FASHION, fashionId, bShow)
  end
end

function AppearanceModule:ChangeClosetSkeletalMesh(itemType, itemId, bChoosed, glassInfo)
  if not self.closetAvatarPlayer or not UE4.UObject.IsValid(self.closetAvatarPlayer) then
    Log.Warning("self.closetAvatarPlayer is nil")
    return
  end
  local itemConf, bBodyType, avatarEnum
  if itemType == _G.Enum.GoodsType.GT_FASHION then
    itemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if itemConf then
      bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(itemConf.type)
    end
  elseif itemType == _G.Enum.GoodsType.GT_SALON then
    itemConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    if itemConf then
      bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumSalon(itemConf.type)
    end
  end
  if avatarEnum and itemConf then
    if bBodyType then
      if bChoosed then
        if itemType == _G.Enum.GoodsType.GT_SALON then
          self.closetAvatarPlayer:SetAvatarModelID(avatarEnum, true, 0)
        else
          local glassId = 0
          if glassInfo then
            glassId = CommonUIUtils.GetGlassInfoId(glassInfo)
          end
          self.closetAvatarPlayer:SetAvatarModelID(itemId, true, glassId)
          local conf = _G.DataConfigManager:GetFashionItemConf(itemId)
          if conf and conf.type == _G.Enum.FashionLabelType.FLT_WAND then
            local bHasWand = false
            if self.data.TempAppearData then
              for k, v in ipairs(self.data.TempAppearData) do
                if v.FashionType == _G.Enum.FashionLabelType.FLT_WAND then
                  bHasWand = true
                  break
                end
              end
            end
            if not bHasWand then
              local fashionGoodsId = 0
              if self.data.FashionIdToGoodsIdMap[fashionId] then
                fashionGoodsId = self.data.FashionIdToGoodsIdMap[fashionId].id
              end
              self.data:TempCurAppearChooseInfo(conf.type, itemId, fashionGoodsId, bChoosed, nil, glassInfo)
            end
          end
        end
      else
        local bFashion, configEnum, Enum = self:GetConfigEnumFromFashionId(itemId)
        self.closetAvatarPlayer:SetAvatarModelID(Enum, true, 0)
        local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
        local cacheBodyTypes = AppearanceUtils.GetCacheBodyTypes(Enum)
        if cacheBodyTypes and #cacheBodyTypes > 0 then
          self:RestoreHairSalonAfterHelmetRemoval()
        end
        local avatarPlayer = self.closetAvatarPlayer
        local avatarAnimConp = avatarPlayer:GetComponentByClass(UE4.URocoAnimComponent)
        local animName = avatarAnimConp:GetCurAnimName()
        if "HZMoZhangLoop" == animName then
          avatarAnimConp:PlayAnimByName("HZMoZhangEnd")
        end
      end
    elseif bChoosed then
      if itemType ~= _G.Enum.GoodsType.GT_FASHION or itemConf.change_bp then
      else
      end
    else
      self.closetAvatarPlayer:SetAvatarModelID(avatarEnum, true, 0)
    end
  end
  if self.closetNpcAction then
    self.closetAvatarPlayer.OnSetAvatarBodyComplete:Bind(self.closetAvatarPlayer, self.OnSetClosetAvatarLoadComplete)
  end
end

function AppearanceModule:OnSetClosetAvatarLoadComplete()
  self:SetLightingChannels(false, true, false)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetClosetClickable, true)
end

function AppearanceModule:OnCmdSetClosetClickable(bClickable)
  self.closetClickable = bClickable
end

function AppearanceModule:OnCmdGetClosetClickable()
  return self.closetClickable
end

function AppearanceModule:OnCmdSetClosetBeauty(SalonId, colorIndex, glassInfo)
  if not self.closetAvatarPlayer or not UE4.UObject.IsValid(self.closetAvatarPlayer) then
    Log.Warning("self.closetAvatarPlayer is nil")
    return
  end
  local salonItemConf = _G.DataConfigManager:GetSalonItemConf(SalonId)
  local salonGoodsData = self.data.SalonIdToGoodsIdMap[SalonId]
  local salonGoodsId = 0
  if salonGoodsData then
    salonGoodsId = salonGoodsData.id
  end
  local fullSalonId = self:GetFullSalonId(salonItemConf.avatar_id, colorIndex)
  self.data:TempCurBeautyChooseInfo(salonItemConf.type, salonItemConf.id, salonGoodsId, colorIndex)
  local bHasUpgradePanel = self:HasPanel("AppearanceUpgrade")
  if self:IsClosetAvatarWearingHelmet() and salonItemConf.type == _G.Enum.SalonLabelType.SLT_HAIR and not bHasUpgradePanel then
    self:AutoRemoveHelmetForHair()
  end
  self.closetAvatarPlayer:SetAvatarMaterialID(fullSalonId)
end

function AppearanceModule:HideOrShowAppearanceById(bFashion, itemId, bShow)
  if bFashion then
    self:OnCmdSetClosetAppearance(itemId, nil, bShow)
  else
    self:OnCmdSetClosetBeauty(itemId, nil, bShow)
  end
end

function AppearanceModule:OnCmdSetTryOnAppearance(bFashion, ids, bFromCloset, bIgnoreRotate)
  local closetPanel
  local hasCloset = self:HasPanel("AppearanceCloset")
  if hasCloset then
    closetPanel = self:GetPanel("AppearanceCloset")
  end
  local hasPanel = self:HasPanel("AppearanceTryOn")
  if hasPanel and not bFromCloset then
    local panel = self:GetPanel("AppearanceTryOn")
    if panel and (not closetPanel or closetPanel and not closetPanel.bDirectToUpgrade) then
      if bFashion then
        panel:SetImageAvatarAppearance(ids)
      else
        panel:SetImageAvatarAppearance(nil, ids)
      end
    end
  end
  if hasCloset and bFromCloset and closetPanel then
    if bFashion then
      for k, v in ipairs(ids) do
        self:OnCmdSetClosetAppearance(v, true)
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
        if not bIgnoreRotate then
          self:SetPlayerAngle(fashionItemConf.type, self.closetAvatarPlayer, "Closet")
        end
      end
    else
      for k, v in ipairs(ids) do
        local salonItemConf = _G.DataConfigManager:GetSalonItemConf(v)
        self:OnCmdSetClosetBeauty(v, salonItemConf.texture_id)
        if not bIgnoreRotate then
          self:SetPlayerAngle(0, self.closetAvatarPlayer, "Closet")
        end
      end
    end
    closetPanel:SetConfirmBtnState()
  end
end

function AppearanceModule:OnCmdSyncCardRevealedState(shopId, latestRevealedState)
  self.data.CardRevealedState[shopId] = latestRevealedState
end

function AppearanceModule:OnCmdAddCardHadRevealed(shopId, cardIndex)
  if self.data.CardRevealedState[shopId] == nil then
    self.data.CardRevealedState[shopId] = {}
  end
  table.insertUnique(self.data.CardRevealedState[shopId], cardIndex)
  local req = _G.ProtoMessage:newZoneSetRandomShopShownIndexesReq()
  req.shop_id = shopId
  req.indexes = self.data.CardRevealedState[shopId]
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_RANDOM_SHOP_SHOWN_INDEXES_REQ, req, self, self.OnReceiveCardRevealStateRsp, false, false)
end

function AppearanceModule:OnReceiveCardRevealStateRsp(_rsp)
  if 0 ~= _rsp.ret_info.ret_code then
    local key = string.format("Error_Code_%d", _rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function AppearanceModule:OnCmdFindOpeningFashionShopId(shopType, bFindNextOpening)
  if shopType == Enum.ShopType.ST_FASHION_PIKA then
    return AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG
  elseif shopType == Enum.ShopType.ST_FASHION_RANDOM then
    return AppearanceModuleEnum.FashionMallShopId.RANDOM_FASHION
  elseif shopType == Enum.ShopType.ST_FASHION_DISCOUNT then
    local nextOpeningDiscountShopId
    if self.CurrentDiscountShopId ~= nil then
      local shopConf = DataConfigManager:GetShopConf(self.CurrentDiscountShopId)
      local closeTimeStamp = ActivityUtils.ToTimestamp(shopConf.disable_time)
      if closeTimeStamp < ActivityUtils.GetSvrTimestamp() then
        self.CurrentDiscountShopId = nil
      end
    end
    if self.CurrentDiscountShopId == nil or bFindNextOpening then
      local shopConfTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SHOP_CONF)
      if shopConfTable then
        local allShopConf = shopConfTable:GetAllDatas()
        local nearestFutureStartTimeStamp = math.maxinteger
        for shopId, shopConf in pairs(allShopConf) do
          if shopConf.shop_type == Enum.ShopType.ST_FASHION_DISCOUNT then
            local startTimeStamp = ActivityUtils.ToTimestamp(shopConf.enable_time)
            local closeTimeStamp = ActivityUtils.ToTimestamp(shopConf.disable_time)
            local srvTimeStamp = ActivityUtils.GetSvrTimestamp()
            if bFindNextOpening and startTimeStamp > srvTimeStamp and nearestFutureStartTimeStamp > startTimeStamp then
              nearestFutureStartTimeStamp = startTimeStamp
              nextOpeningDiscountShopId = shopId
            end
            if startTimeStamp <= srvTimeStamp and closeTimeStamp > srvTimeStamp then
              self.CurrentDiscountShopId = shopId
            end
          end
        end
      end
    end
    return self.CurrentDiscountShopId, nextOpeningDiscountShopId
  end
end

function AppearanceModule:OnCmdOpenFashionShopConfirm(...)
  self:OpenPanel("FashionMallConfirm", ...)
end

function AppearanceModule:OnCmdSetGoodsCostInfoFromConfirmTicket(costNum, vitemType)
  if self:HasPanel("FashionMallConfirm") then
    local panel = self:GetPanel("FashionMallConfirm")
    panel:SetGoodsCostInfo(costNum, vitemType)
  end
end

function AppearanceModule:OnCmdHadOwnedEntireSuit(suitId)
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if nil == suitConf then
    return false
  end
  local suitFashionIds = suitConf.item_id
  if suitFashionIds and #suitFashionIds > 0 then
    for k, v in ipairs(suitFashionIds) do
      local hasOwned = self:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, v)
      if not hasOwned then
        return false
      end
    end
  end
  return true
end

function AppearanceModule:OnCmdOpenFashionBuyResultPopUp(rsp)
  local openRsp = rsp or self.data.FashionBuySuccessRsp
  if openRsp then
    if openRsp.shop_id then
      local shopConf = DataConfigManager:GetShopConf(openRsp.shop_id)
      if shopConf and shopConf.shop_type == _G.Enum.ShopType.ST_FASHION_PIKA then
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetPanelMoneyBtnVisibleFlag, "AppearanceTryOn", "UMG_UpgradeSuitLevel_C", false, 2)
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetPanelMoneyBtnVisibleFlag, "SeasonalCombinationBagShop", "UMG_UpgradeSuitLevel_C", false, 2)
      end
    end
    self:OpenPanel("FashionBuyResultPopUp", openRsp)
    self.data.FashionBuySuccessRsp = nil
  end
end

function AppearanceModule:IsPikaActivityHadPopUp(pikaActivityBaseId)
  if nil == pikaActivityBaseId then
    return false
  end
  local pikaActivityBaseIdStr = tostring(pikaActivityBaseId)
  local myUinStr = tostring(_G.DataModelMgr.PlayerDataModel:GetPlayerUin())
  self.data:LoadFashionMallPopUpRecord()
  local Record = self.data.FashionMallPopUpRecord[myUinStr]
  if type(Record) == "table" and Record[pikaActivityBaseIdStr] then
    return true
  end
  return false
end

function AppearanceModule:MarkPikaActivityHadPopUp(pikaActivityBaseId)
  if nil == pikaActivityBaseId then
    return false
  end
  local pikaActivityBaseIdStr = tostring(pikaActivityBaseId)
  local myUinStr = tostring(_G.DataModelMgr.PlayerDataModel:GetPlayerUin())
  local Record = self.data.FashionMallPopUpRecord[myUinStr]
  if nil == Record then
    Record = {}
  end
  Record[pikaActivityBaseIdStr] = true
  self.data.FashionMallPopUpRecord[myUinStr] = Record
  return self.data:SaveFashionMallPopUpRecord()
end

function AppearanceModule:OnCmdGetFashionFreeWand()
  return self.data:GetFashionFreeWand()
end

function AppearanceModule:OnLoadingUIOpened()
  self:ClosePanel("FashionMallPopup")
end

function AppearanceModule:OnCmdFashionBuySuccess(_rsp)
  self.data.FashionBuySuccessRsp = _rsp
  local bConfirmIsAvailable = false
  if self:HasPanel("FashionMallConfirm") then
    local panel = self:GetPanel("FashionMallConfirm")
    if panel and panel.OnBuySuccess then
      bConfirmIsAvailable = true
      panel:OnBuySuccess()
    end
  end
  if not bConfirmIsAvailable and self:ShouldPopUpEvenConfirmUIDisabled(_rsp) then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionBuyResultPopUp, _rsp)
  end
end

function AppearanceModule:OnCmdFashionBuyFail(_rsp)
  local bConfirmIsAvailable = false
  if self:HasPanel("FashionMallConfirm") then
    local panel = self:GetPanel("FashionMallConfirm")
    if panel and panel.OnBuySuccess then
      bConfirmIsAvailable = true
      panel:OnBuyFail()
    end
  end
end

function AppearanceModule:OnCmdGetWearIdByType(bFashion, type)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if bFashion then
    local fashionItems = player:GetFashionItems()
    if fashionItems then
      for k, v in pairs(fashionItems) do
        if v and v.wearing_item_id > 0 then
          local fashionConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
          if fashionConf and fashionConf.type == type then
            return v.wearing_item_id
          end
        end
      end
    end
  else
    local salonIds = player:GetSalonIds()
    if salonIds then
      for k, v in ipairs(salonIds) do
        if v > 0 then
          local salonConf = _G.DataConfigManager:GetSalonItemConf(v)
          if salonConf and salonConf.type == type then
            return v
          end
        end
      end
    end
  end
  return 0
end

function AppearanceModule:OnCmdOnNameCardPopupAvatarSuitComplete()
  if self:HasPanel("ShiningMedalDetail") then
    local panel = self:GetPanel("ShiningMedalDetail")
    if panel then
      panel:OnSwitchAvatarSuitComplete()
    end
  end
end

function AppearanceModule:OnCmdOpenGorgeousMedalPanel(medalId, bUpgradeSkip)
  local _isOpening, _ = self:HasPanel("GorgeousMedal")
  if _isOpening then
    local panel = self:GetPanel("GorgeousMedal")
    if panel then
      panel:Active(medalId, bUpgradeSkip)
    end
  else
    self:OpenPanel("GorgeousMedal", medalId, bUpgradeSkip)
  end
end

function AppearanceModule:GorgeousMedalPanelIsOpen()
  local _isOpening, _ = self:HasPanel("GorgeousMedal")
  return _isOpening
end

function AppearanceModule:FashionUpgradePanelIsOpen()
  local _isOpening, _ = self:HasPanel("AppearanceUpgrade")
  return _isOpening
end

function AppearanceModule:AppearanceTryOnPanelIsOpen()
  local _isOpening, _ = self:HasPanel("AppearanceTryOn")
  return _isOpening
end

function AppearanceModule:OnCmdOpenShopCollectProgressPanel(ShopID, itemArray, isSuit)
  local _isOpening, _ = self:HasPanel("ShopCollectProgress")
  if not _isOpening then
    self:OpenPanel("ShopCollectProgress", ShopID, itemArray, isSuit)
  end
end

local FashionShowPerformState = {}
FashionShowPerformState.None = 0
FashionShowPerformState.TimeCheck = 1
FashionShowPerformState.SuitCheck = 2
FashionShowPerformState.ResCheck = 4
local FashionShowPerformStateIsReady = 0
for k, v in pairs(FashionShowPerformState) do
  FashionShowPerformStateIsReady = FashionShowPerformStateIsReady + v
end
local DebugDelayCallPath = {}
DebugDelayCallPath.Default = 0
DebugDelayCallPath.Transition = 1
DebugDelayCallPath.Idle = 2

function AppearanceModule:CollectGlobalConfig()
  local function _GetRoleGlobalConfigNumDefault(key, defaultValue)
    local config = _G.DataConfigManager:GetRoleGlobalConfig(key)
    
    if config then
      defaultValue = config.num
    end
    return defaultValue or 0
  end
  
  self.PikaShopXRayValue = _GetRoleGlobalConfigNumDefault("pika_shop_xray_value", 200) / 1000
  self.PikaShopFadeDuration = _GetRoleGlobalConfigNumDefault("pika_shop_fade_time", 500)
  self.PikaShopLoopCD = _GetRoleGlobalConfigNumDefault("pika_shop_loop_cd", 10000)
  self.PikaTransitionDuration = _GetRoleGlobalConfigNumDefault("pika_shop_trans_time", 3000)
end

function AppearanceModule:ResetFashionShowPerformStateFlag(indexInSequence)
  if indexInSequence and self.data.fashionShowPerformStateFlag then
    self.data.fashionShowPerformStateFlag[indexInSequence] = FashionShowPerformState.None
  else
    self.data.fashionShowPerformStateFlag = {}
  end
end

function AppearanceModule:SetFashionShowPerformStateFlag(indexInSequence, flag)
  if not self.data.fashionShowPerformStateFlag then
    return
  end
  if not self.data.fashionShowPerformStateFlag[indexInSequence] then
    self.data.fashionShowPerformStateFlag[indexInSequence] = flag
  elseif self:CheckFashionShowPerformStateFlag(indexInSequence, flag) then
    return
  else
    self.data.fashionShowPerformStateFlag[indexInSequence] = self.data.fashionShowPerformStateFlag[indexInSequence] | flag
  end
  if self:CheckFashionShowPerformStateFlag(indexInSequence, FashionShowPerformStateIsReady) then
    self:DoStartFashionShow(indexInSequence)
  end
end

function AppearanceModule:ClearFashionShowPerformStateFlag(indexInSequence, flag)
  if not self.data.fashionShowPerformStateFlag then
    return
  end
  if self.data.fashionShowPerformStateFlag[indexInSequence] then
    self.data.fashionShowPerformStateFlag[indexInSequence] = self.data.fashionShowPerformStateFlag[indexInSequence] & ~flag
  end
end

function AppearanceModule:CheckFashionShowPerformStateFlag(indexInSequence, flag)
  if not self.data.fashionShowSequence or indexInSequence ~= self.data.currentIndexInSequence then
    return
  end
  local currentFlag = self.data.fashionShowPerformStateFlag[indexInSequence]
  return currentFlag and currentFlag & flag == flag
end

function AppearanceModule:ReleaseFashionShowSequenceResource()
  Log.Debug("AppearanceModule_FashionShow_ReleaseFashionShowSequenceResource")
  self.data.bFashionShowSequenceWorking = false
  if self.DelayIdStartFirstFashionShow then
    DelayManager:CancelDelay(self.DelayIdStartFirstFashionShow)
    self.DelayIdStartFirstFashionShow = nil
  end
  local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  if avatarSystem then
    if self.MannequinTaskId then
      avatarSystem:StopSwitchAvatarSuit(self.MannequinTaskId)
      self.MannequinTaskId = nil
    end
    if self.OnMannequinSuitSwitchCompleteWrapper then
      avatarSystem.OnSwitchAvatarSuitComplete:Remove(avatarSystem, self.OnMannequinSuitSwitchCompleteWrapper)
      self.OnMannequinSuitSwitchCompleteWrapper = nil
    end
  end
  if self.MannequinActorRelaxSkillProxy then
    self.MannequinActorRelaxSkillProxy:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.MannequinActorRelaxSkillProxy:Destroy()
    self.MannequinActorRelaxSkillProxy = nil
  end
  for key, resQueue in pairs(self.fashionShowSequenceResQueues) do
    if resQueue then
      local npc = resQueue:Get("NPC")
      resQueue:Release()
      if npc then
        npc:SetVisible(false)
        _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, npc:GetServerId())
      end
    end
  end
  if self.FashionShowBaseResQue then
    self.FashionShowBaseResQue:Release()
    self.FashionShowBaseResQue = nil
  end
  if self.fashionShowIdleDelayId then
    DelayManager:CancelDelayById(self.fashionShowIdleDelayId)
    self.fashionShowIdleDelayId = nil
  end
  if self.fashionShowPendingDelayId then
    DelayManager:CancelDelayById(self.fashionShowPendingDelayId)
    self.fashionShowPendingDelayId = nil
  end
  if self.fashionShowTransDelayId then
    DelayManager:CancelDelayById(self.fashionShowTransDelayId)
    self.fashionShowTransDelayId = nil
  end
  self:StopMannequinActorFadeAppear()
  self.data.fashionShowSequence = nil
  if self.MannequinActor_Ref and UE.UObject.IsValid(self.MannequinActor_Ref) then
    UnLua.Unref(self.MannequinActor_Ref)
  end
  self.MannequinActor_Ref = nil
  if self.MannequinActor then
    if UE.UObject.IsValid(self.MannequinActor) then
      self:SetMannequinActorHiddenInternal(self.MannequinActor, true)
      self.MannequinActor:K2_DestroyActor()
    end
    self.MannequinActor = nil
    self.MannequinActorGender = nil
  end
  self.FashionShowRelaxPetNpc = nil
  self.fashionShowSequenceResQueues = {}
end

function AppearanceModule:ActiveFashionShowSequence()
  if not SceneUtils.IsInPikaShop() then
    return
  end
  local gender, fashionShowSequence = self:InitFashionShowSequence()
  Log.Debug("AppearanceModule_FashionShow_Init", #fashionShowSequence)
  if nil == gender then
    return
  end
  self:ResetFashionShowPerformStateFlag()
  self.data.fashionShowSequence = fashionShowSequence
  self.data.fashionShowBaseGender = gender
  self.data.currentIndexInSequence = 1
  self.data.bFashionShowSequenceWorking = true
  self:LoadFashionShowBaseRes(self.data.fashionShowSequence)
end

function AppearanceModule:InitFashionShowSequence()
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerGender = Enum.ESexValue.SEX_MALE
  local bVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  if not bVisit and player.gender then
    playerGender = player.gender
  end
  local _showingPkgIds = {}
  local _otherGenderPkgIds = {}
  local pikaActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PIKA)
  if pikaActivityInst and #pikaActivityInst > 0 then
    local subItemIds = pikaActivityInst[1]:GetPartIds()
    local activityPikaConf = _G.DataConfigManager:GetActivityPikaConf(subItemIds[1])
    for k, v in ipairs(activityPikaConf.kv_path) do
      if v.gender == playerGender then
        for key, pkgId in ipairs(v.package_id1) do
          table.insert(_showingPkgIds, pkgId)
        end
      else
        for key, pkgId in ipairs(v.package_id1) do
          table.insert(_otherGenderPkgIds, pkgId)
        end
      end
    end
  end
  for idx, otherGenderPkgId in ipairs(_otherGenderPkgIds) do
    table.insert(_showingPkgIds, otherGenderPkgId)
  end
  local _showingSuitIds = {}
  for idx, pkgId in ipairs(_showingPkgIds) do
    local suitIds = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetAllSuitsInPackage, pkgId)
    for idx1, suitId in ipairs(suitIds) do
      table.insert(_showingSuitIds, suitId)
    end
  end
  local pikaShopIdleAnimOfA = ""
  local pikaShopIdleAnimOfS = ""
  local config = _G.DataConfigManager:GetRoleGlobalConfig("pika_shop_anim_idle_a")
  if config then
    pikaShopIdleAnimOfA = config.str
  end
  config = _G.DataConfigManager:GetRoleGlobalConfig("pika_shop_anim_idle_s")
  if config then
    pikaShopIdleAnimOfS = config.str
  end
  local IdleAnimForA = string.Split(pikaShopIdleAnimOfA, ";")
  local IdleAnimForS = string.Split(pikaShopIdleAnimOfS, ";")
  local IdxOfIdleAnimOfA = 1
  local IdxOfIdleAnimOfS = 1
  local fashionShowSequence = {}
  for idx, suitId in ipairs(_showingSuitIds) do
    local fashionSuitConf = DataConfigManager:GetFashionSuitsConf(suitId)
    if not fashionSuitConf then
    else
      table.insert(fashionShowSequence, {
        index = #fashionShowSequence + 1,
        length = self.PikaTransitionDuration
      })
      local animName
      if fashionSuitConf.suit_grade ~= Enum.SuitGrade.SG_BOND then
        if IdxOfIdleAnimOfA > #IdleAnimForA then
          IdxOfIdleAnimOfA = 1
        end
        animName = IdleAnimForA[IdxOfIdleAnimOfA]
        table.insert(fashionShowSequence, {
          index = #fashionShowSequence + 1,
          suitId = suitId,
          animName = animName
        })
        IdxOfIdleAnimOfA = IdxOfIdleAnimOfA + 1
      else
        if IdxOfIdleAnimOfS > #IdleAnimForS then
          IdxOfIdleAnimOfS = 1
        end
        animName = IdleAnimForS[IdxOfIdleAnimOfS]
        table.insert(fashionShowSequence, {
          index = #fashionShowSequence + 1,
          suitId = suitId,
          animName = animName
        })
        IdxOfIdleAnimOfS = IdxOfIdleAnimOfS + 1
        local skill_path, npcId, petBaseId
        local fashionPerformConf = _G.DataConfigManager:GetFashionPerformConf(fashionSuitConf.perform_id)
        if fashionPerformConf then
          local skillResConf = _G.DataConfigManager:GetSkillResConf(fashionPerformConf.suiteffect3_rest_skill, true)
          if skillResConf then
            skill_path = skillResConf.res_id
          end
          if fashionPerformConf.petbase3_id and #fashionPerformConf.petbase3_id > 0 then
            petBaseId = fashionPerformConf.petbase3_id[1]
          end
        end
        if petBaseId then
          local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
          if PetBaseConf then
            npcId = PetBaseConf.npc_id
          end
        end
        if skill_path and npcId then
          table.insert(fashionShowSequence, {
            index = #fashionShowSequence + 1,
            suitId = suitId,
            skillPath = skill_path,
            npcId = npcId
          })
        end
      end
    end
  end
  table.insert(fashionShowSequence, {
    index = #fashionShowSequence + 1,
    bLast = true,
    length = self.PikaShopLoopCD
  })
  return playerGender, fashionShowSequence
end

function AppearanceModule:LoadFashionShowBaseRes(fashionShowSequence)
  local reqQueue = ResQueue(30)
  self.FashionShowBaseResQue = reqQueue
  reqQueue:InsertClass("MannequinBPClass", "/Game/NewRoco/Modules/System/Appearance/BP/BP_FashionMannequin.BP_FashionMannequin")
  reqQueue:InsertClass("ABP1", "/Game/ArtRes/AnimSequence/Human/PC/PC1/ABP_Avatar1.ABP_Avatar1")
  reqQueue:InsertClass("ABP2", "/Game/ArtRes/AnimSequence/Human/PC/PC2/ABP_Avatar_PC2_1.ABP_Avatar_PC2_1")
  local bVisit = true
  if bVisit and fashionShowSequence then
    reqQueue:InsertClass("ballBackSkillClass", "/Game/ArtRes/Effects/G6Skill/Yuancheng/CallBack_False")
    for idx, showInfo in ipairs(fashionShowSequence) do
      if showInfo and showInfo.suitId and showInfo.npcId and showInfo.skillPath then
        reqQueue:InsertClass(tostring(showInfo.suitId), showInfo.skillPath)
      end
    end
  end
  reqQueue:StartLoad(self, self.OnFashionShowBaseResLoadComplete)
end

function AppearanceModule:OnFashionShowBaseResLoadComplete(InQueue, bSuccess)
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:OnFashionShowBaseResLoadComplete, \230\156\170\229\183\165\228\189\156")
    return
  end
  if bSuccess then
    local mannequinActor = self:CreateFashionMannequinActor()
    if not mannequinActor then
      Log.Error("AppearanceModule:OnFashionShowBaseResLoadComplete Actor\231\148\159\230\136\144\229\164\177\232\180\165")
      return
    end
    self:UpdateFashionShowSequenceLength(mannequinActor)
    if not self.data.fashionShowSequenceTotalTime then
      Log.Error("AppearanceModule:OnFashionShowBaseResLoadComplete \232\161\168\230\188\148\229\186\143\229\136\151\230\128\187\230\151\182\233\149\191\232\174\161\231\174\151\229\164\177\232\180\165")
      return
    end
    if self.DelayIdStartFirstFashionShow then
      DelayManager:CancelDelay(self.DelayIdStartFirstFashionShow)
      self.DelayIdStartFirstFashionShow = nil
    end
    self.DelayIdStartFirstFashionShow = DelayManager:DelayFrames(1, function(appearanceModule)
      appearanceModule:StartFashionShow(appearanceModule.data.currentIndexInSequence, true)
    end, self)
  else
    Log.Error("AppearanceModule:OnFashionShowBaseResLoadComplete \229\138\160\232\189\189\229\164\177\232\180\165")
  end
end

function AppearanceModule:UpdateFashionShowSequenceLength(mannequinActor)
  if not (self.data.fashionShowSequence and self.FashionShowBaseResQue) or not mannequinActor then
    return
  end
  if not mannequinActor.RocoSkill or not mannequinActor.RocoAnim then
    return
  end
  local bVisit = true
  local ballFlyToOwnerLength = 0
  if bVisit then
    local ballBackSkillClass = self.FashionShowBaseResQue:Get("ballBackSkillClass")
    if ballBackSkillClass then
      local skillObj = mannequinActor.RocoSkill:FindOrAddSkillObj(ballBackSkillClass)
      if skillObj then
        ballFlyToOwnerLength = skillObj:GetLength() * 1000
      end
    end
  end
  local TotalCost = 0
  for idx, showInfo in ipairs(self.data.fashionShowSequence) do
    if showInfo then
      if showInfo.skillPath and showInfo.npcId then
        if bVisit then
          local length = 0
          local skillClass = self.FashionShowBaseResQue:Get(tostring(showInfo.suitId))
          if skillClass then
            local skillObj = mannequinActor.RocoSkill:FindOrAddSkillObj(skillClass)
            if skillObj then
              local extraTimeSpaceForTinyAdjust = 500
              length = skillObj:GetLength() * 1000 + extraTimeSpaceForTinyAdjust
            end
          end
          showInfo.length = length
        end
      elseif showInfo.animName then
        local animLength = mannequinActor.RocoAnim:GetAnimLengthByName(showInfo.animName) * 1000
        if animLength < 1 then
          animLength = 3000
        end
        showInfo.length = animLength
      end
      showInfo.startTime = TotalCost
      if bVisit and showInfo.length then
        TotalCost = TotalCost + showInfo.length
      end
    end
  end
  self.data.fashionShowSequenceTotalTime = TotalCost
end

function AppearanceModule:CreateFashionMannequinActor(gender)
  if not self.FashionShowBaseResQue then
    return
  end
  gender = gender or Enum.ESexValue.SEX_MALE
  local mannequinActor
  if not self.MannequinActor or not self.MannequinActor_Ref then
    local mannequinBPClass = self.FashionShowBaseResQue:Get("MannequinBPClass")
    local x, y, z, yaw = self:GetTailorStageCenter()
    if not (x and y and z) or not yaw then
      Log.Warning("AppearanceModule:CreateFashionMannequinActor \229\189\147\229\137\141\229\156\186\230\153\175\230\151\160\232\136\158\229\143\176\228\184\173\229\191\131\233\133\141\231\189\174")
      return
    end
    local fTransfom = UE4.FTransform(UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, math.rad(yaw)), UE4.FVector(x, y, z))
    local params = {}
    mannequinActor = UE4Helper.GetCurrentWorld():Abs_SpawnActor(mannequinBPClass, fTransfom, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, params)
    if not mannequinActor then
      return nil
    end
    self.MannequinActor = mannequinActor
    self.MannequinActor_Ref = UnLua.Ref(self.MannequinActor)
  end
  self:ChangeMannequinActorGender(gender)
  return mannequinActor
end

function AppearanceModule:StartFashionShow(indexInSequence, bFirstStart)
  if not SceneUtils.IsInPikaShop() then
    return
  end
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:StartFashionShow, \230\156\170\229\183\165\228\189\156")
    return
  end
  local currentUtcTimeStampMs = UE.UNRCStatics.GetUTCTimestampMS()
  local idx, delay = self:CalcFashionShouldShow(currentUtcTimeStampMs, indexInSequence, bFirstStart)
  Log.Debug("AppearanceModule_FashionShow_StartFashionShow", idx, delay, bFirstStart)
  self:ClearFashionShowPerformStateFlag(idx, FashionShowPerformState.TimeCheck)
  if not self.data.fashionShowSequence or not self.data.fashionShowSequence[idx] then
    return
  end
  if 2 == idx or bFirstStart and idx ~= #self.data.fashionShowSequence then
    local fashionShowStage = self:GetFashionShowPerformBP("fashionShowStage")
    if fashionShowStage and fashionShowStage.TurnOffTheLight then
      fashionShowStage:TurnOffTheLight()
    end
    local projector = self:GetFashionShowPerformBP("fashionShowProjector")
    if projector and projector.StartPerform then
      projector:StartPerform()
    end
    local boxes = self:GetFashionShowPerformBP("fashionShowBox")
    if boxes and boxes.StartJumpPerform then
      boxes:StartJumpPerform()
    end
  end
  local showInfo = self.data.fashionShowSequence[idx]
  if showInfo.suitId == nil then
    self:SetFashionShowPerformStateFlag(idx, FashionShowPerformState.SuitCheck)
    self:SetFashionShowPerformStateFlag(idx, FashionShowPerformState.ResCheck)
  else
    if not self:CheckFashionShowPerformStateFlag(indexInSequence, FashionShowPerformState.SuitCheck) and not self.MannequinTaskId then
      self:ChangeMannequinActorSuit(showInfo, indexInSequence)
    end
    if not self:CheckFashionShowPerformStateFlag(indexInSequence, FashionShowPerformState.ResCheck) then
      self:PrepareFashionShowRelaxSkill(showInfo)
    end
    if showInfo.skillPath and showInfo.npcId then
    elseif showInfo.animName then
      self:SetFashionShowPerformStateFlag(idx, FashionShowPerformState.ResCheck)
    end
  end
  self:SetCurrentIndexInSequence(idx)
  if self.fashionShowPendingDelayId then
    DelayManager:CancelDelayById(self.fashionShowPendingDelayId)
    self.fashionShowPendingDelayId = nil
    Log.Warning("AppearanceModule:StartFashionShow \230\151\182\233\151\180\232\174\161\231\174\151\233\148\153?")
  end
  if idx then
    if nil == delay or delay <= 0 then
      self:SetFashionShowPerformStateFlag(idx, FashionShowPerformState.TimeCheck)
    else
      self.fashionShowPendingDelayId = DelayManager:DelaySeconds(delay / 1000, function()
        if self.fashionShowPendingDelayId then
          DelayManager:CancelDelayById(self.fashionShowPendingDelayId)
          self.fashionShowPendingDelayId = nil
        end
        self:StartFashionShow(idx)
      end)
    end
  end
end

function AppearanceModule:OnFashionShowFinish(bOk, debugDelayCallPath)
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:OnFashionShowFinish, \230\156\170\229\183\165\228\189\156", bOk, debugDelayCallPath)
    return
  end
  if nil == bOk or false == bOk then
    return
  end
  self:SetCurrentIndexInSequence(self.data.currentIndexInSequence + 1, debugDelayCallPath)
  self:StartFashionShow(self.data.currentIndexInSequence)
end

function AppearanceModule:DoStartFashionShow(indexInSequence)
  if not self.data.fashionShowSequence or not self.data.fashionShowSequenceTotalTime then
    return
  end
  local showInfo = self.data.fashionShowSequence[indexInSequence]
  if not showInfo then
    return
  end
  local nextSuitIndex, nextRelaxSkillIndex = self:CalcAllShowOfSuit(indexInSequence)
  self:PrepareFashionShowRelaxSkill(self.data.fashionShowSequence[nextRelaxSkillIndex])
  if showInfo.suitId == nil then
    self:DoStartFashionShow_Transition(showInfo, nextSuitIndex)
  else
    self:ChangeMannequinActorSuit()
    if self.MannequinActor and self.MannequinActor.bHidden then
      self:StartMannequinActorFadeAppear(true, true)
    end
    if self.MannequinActor and self.MannequinActor.RocoAnim then
      self.MannequinActor.RocoAnim:GetAnimInstance()
    end
    if showInfo.skillPath and showInfo.npcId then
      self:DoStartFashionShow_Relax(showInfo)
    elseif showInfo.animName then
      self:DoStartFashionShow_Idle(showInfo)
    end
  end
end

function AppearanceModule:DoStartFashionShow_Transition(showInfo, nextSuitIndex)
  if not showInfo then
    return
  end
  local bLast = showInfo.bLast
  if bLast then
    local fashionShowStage = self:GetFashionShowPerformBP("fashionShowStage")
    if fashionShowStage and fashionShowStage.TurnOnTheLight then
      fashionShowStage:TurnOnTheLight()
    end
    local projector = self:GetFashionShowPerformBP("fashionShowProjector")
    if projector and projector.StopPerform then
      projector:StopPerform()
    end
    local boxes = self:GetFashionShowPerformBP("fashionShowBox")
    if boxes and boxes.StopJumpPerform then
      boxes:StopJumpPerform()
    end
  end
  local PikaShopFadeDurationSecond = self.PikaShopFadeDuration / 1000
  local length = showInfo.length
  local fallBehindAmount = self:GetShowFallBehindStandTime(showInfo)
  fallBehindAmount = math.clamp(fallBehindAmount, -1000, 1000)
  length = math.max(length - fallBehindAmount, 2 * self.PikaShopFadeDuration)
  if length and length > 2 * self.PikaShopFadeDuration then
    local bFirst = 1 == showInfo.index
    if not bFirst then
      self:StartMannequinActorFadeAppear(false)
    end
    if self.fashionShowTransDelayId then
      DelayManager:CancelDelayById(self.fashionShowTransDelayId)
      self.fashionShowTransDelayId = nil
    end
    self.fashionShowTransDelayId = DelayManager:DelaySeconds(PikaShopFadeDurationSecond, function()
      if self.fashionShowTransDelayId then
        DelayManager:CancelDelayById(self.fashionShowTransDelayId)
        self.fashionShowTransDelayId = nil
      end
      self.fashionShowTransDelayId = DelayManager:DelaySeconds(length / 1000 - 2 * PikaShopFadeDurationSecond, function()
        if self.fashionShowTransDelayId then
          DelayManager:CancelDelayById(self.fashionShowTransDelayId)
          self.fashionShowTransDelayId = nil
        end
        if self:CheckFashionShowPerformStateFlag(nextSuitIndex, FashionShowPerformState.SuitCheck) and not bLast then
          self:StartMannequinActorFadeAppear(true)
        end
        self.fashionShowTransDelayId = DelayManager:DelaySeconds(PikaShopFadeDurationSecond, function()
          if self.fashionShowTransDelayId then
            DelayManager:CancelDelayById(self.fashionShowTransDelayId)
            self.fashionShowTransDelayId = nil
          end
          self:OnFashionShowFinish(true, DebugDelayCallPath.Transition)
        end)
      end)
      self:ChangeMannequinActorSuit(self.data.fashionShowSequence[nextSuitIndex])
    end)
  end
end

function AppearanceModule:DoStartFashionShow_Idle(showInfo)
  if not showInfo.animName or not self.MannequinActor then
    return
  end
  self.MannequinActor.RocoAnim:PlayAnimByName(showInfo.animName)
  if self.fashionShowIdleDelayId then
    DelayManager:CancelDelayById(self.fashionShowIdleDelayId)
    self.fashionShowIdleDelayId = nil
  end
  if showInfo.length and showInfo.length > 0 then
    self.fashionShowIdleDelayId = DelayManager:DelaySeconds(showInfo.length / 1000, function()
      self:OnFashionShowFinish(true, DebugDelayCallPath.Idle)
    end)
  end
end

function AppearanceModule:DoStartFashionShow_Relax(showInfo)
  if not showInfo then
    return
  end
  if not self.data.fashionShowSequence then
    return
  end
  if not (self.fashionShowSequenceResQueues and showInfo.index) or not self.fashionShowSequenceResQueues[showInfo.index] then
    return
  end
  local resQueue = self.fashionShowSequenceResQueues[showInfo.index]
  local petNpc = resQueue:Get("NPC")
  local skillComponent = self.MannequinActor.RocoSkill
  if skillComponent and skillComponent:IsPlayingSkill() then
    local skillPath = "None"
    local skillObj = skillComponent:GetActiveSkill()
    if skillObj then
      skillPath = skillObj:GetName()
    end
    Log.Error("AppearanceModule:DoStartFashionShow_Relax \229\183\178\231\187\143\229\156\168\230\146\173G6\228\186\134", skillObj, skillPath, showInfo.index, showInfo.skillPath)
    return
  end
  if not (petNpc and petNpc.viewObj and UE.UObject.IsValid(petNpc.viewObj) and self.MannequinActor and showInfo) or not showInfo.skillPath then
    self:OnFashionShowFinish(true, DebugDelayCallPath.Default)
    return
  end
  self.FashionShowRelaxPetNpc = petNpc
  petNpc.isFake = true
  self:ModifyXRay(petNpc.viewObj, self.PikaShopXRayValue)
  petNpc.viewObj:SetActorEnableCollision(false)
  local petBp = petNpc.viewObj
  if petBp and petBp.Mesh then
    UE.UNRCCharacterUtils.SetCharacterMeshScale(petBp, 1)
    petBp.IkOverride = false
  end
  petNpc.AIComponent:ForceLockForReason(true, false, _G.AIDefines.LockReason.SUIT_PERFORM)
  petNpc.PetHUDComponent:SetRenderStatus(false, MainUIModuleEnum.DisableHudOpSource.SuitPerform)
  local targets = {petBp}
  if skillComponent and not skillComponent:IsPlayingSkill() then
    local skillProxy = RocoSkillProxy.Create(showInfo.skillPath, skillComponent)
    self.MannequinActorRelaxSkillProxy = skillProxy
    skillProxy:RegisterEventCallback("PreStart", self, self.OnFashionShowRelaxG6PreStart)
    skillProxy:RegisterEventCallback("ActivateSuccess", self, self.OnFashionShowRelaxG6CastSuccess)
    skillProxy:RegisterEventCallback("ActivateFailed", self, self.OnFashionShowRelaxG6CastFailed)
    skillProxy:RegisterEventCallback("End", self, self.OnFashionShowRelaxBallBackG6End)
    skillProxy:RegisterEventCallback("PetBack", self, self.OnFashionShowRelaxG6PetBack)
    skillProxy:RegisterEventCallback("Interrupt", self, self.OnFashionShowRelaxG6Interrupt)
    skillProxy:SetCaster(self.MannequinActor)
    skillProxy:SetTargets(targets)
    skillProxy:PlaySkill()
  end
end

function AppearanceModule:ChangeMannequinActorSuit(showInfo)
  if not showInfo or not showInfo.suitId then
    return
  end
  if not self.MannequinActor then
    return
  end
  local fashionSuitId = showInfo.suitId
  local fashionSuitConf = DataConfigManager:GetFashionSuitsConf(fashionSuitId)
  if not fashionSuitConf then
    return
  end
  local defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
  local gender = fashionSuitConf.gender
  if gender == Enum.ESexValue.SEX_MALE then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
  elseif gender == Enum.ESexValue.SEX_FEMALE then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
  end
  local lvUpClosetFashion = {}
  local lvUpClosetSalon = {}
  local fashionIds, salonIds = CommonUIUtils.GetDefaultWearIds(gender)
  if fashionSuitId and 0 ~= fashionSuitId then
    if fashionSuitConf and fashionSuitConf.item_id then
      fashionIds = UE4.FBinDataUtils.CloneConfigTable(fashionSuitConf.item_id)
    end
    if fashionIds and fashionSuitConf.lv_up_closet then
      for idx1, lvUpCloset in ipairs(fashionSuitConf.lv_up_closet) do
        if lvUpCloset.lv_item_type == _G.Enum.GoodsType.GT_FASHION then
          local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(lvUpCloset.lv_item_id, true)
          if fashionItemConf and fashionItemConf.type then
            lvUpClosetFashion[fashionItemConf.type] = lvUpCloset.lv_item_id
          end
        elseif lvUpCloset.lv_item_type == _G.Enum.GoodsType.GT_SALON then
          local salonItemConf = _G.DataConfigManager:GetSalonItemConf(lvUpCloset.lv_item_id, true)
          if salonItemConf and salonItemConf.type then
            lvUpClosetSalon[salonItemConf.type] = CommonUIUtils.GetFullSalonId(salonItemConf.avatar_id, salonItemConf.texture_id)
          end
        end
      end
      for idx, fashionId in ipairs(fashionIds) do
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(fashionId)
        if fashionItemConf and fashionItemConf.type and lvUpClosetFashion[fashionItemConf.type] ~= nil then
          fashionIds[idx] = lvUpClosetFashion[fashionItemConf.type]
          lvUpClosetFashion[fashionItemConf.type] = nil
        end
      end
    end
  end
  for fashionType, fashionId in pairs(lvUpClosetFashion) do
    table.insert(fashionIds, fashionId)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = gender
  local fullSalonIds = {}
  for k, v in ipairs(salonIds) do
    local SalonItemConf = _G.DataConfigManager:GetSalonItemConf(v, true)
    if SalonItemConf and SalonItemConf.type then
      if lvUpClosetSalon[SalonItemConf.type] ~= nil then
        table.insert(fullSalonIds, lvUpClosetSalon[SalonItemConf.type])
        lvUpClosetSalon[SalonItemConf.type] = nil
      else
        table.insert(fullSalonIds, CommonUIUtils.GetFullSalonId(SalonItemConf.avatar_id, SalonItemConf.texture_id))
      end
    end
  end
  for key, fullSalonId in pairs(lvUpClosetSalon) do
    table.insert(fullSalonIds, fullSalonId)
  end
  defaultSuitObj:SetSalons(fullSalonIds)
  for k, v in ipairs(fashionIds) do
    if 0 ~= v then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
      if fashionItemConf then
        defaultSuitObj:SetBody(v, 0)
      else
        Log.Error("fashion\228\184\141\229\173\152\229\156\168", v)
      end
    end
  end
  self:ChangeMannequinActorGender(fashionSuitConf.gender)
  local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  if self.MannequinTaskId then
    avatarSystem:StopSwitchAvatarSuit(self.MannequinTaskId)
    self.MannequinTaskId = nil
  end
  if self.OnMannequinSuitSwitchCompleteWrapper then
    avatarSystem.OnSwitchAvatarSuitComplete:Remove(avatarSystem, self.OnMannequinSuitSwitchCompleteWrapper)
    self.OnMannequinSuitSwitchCompleteWrapper = nil
  end
  local indexInSequence = showInfo.index
  
  function self.OnMannequinSuitSwitchCompleteWrapper(InAvatarSystem, Id)
    self:OnMannequinSuitSwitchComplete(InAvatarSystem, Id, indexInSequence)
  end
  
  avatarSystem.OnSwitchAvatarSuitComplete:Add(avatarSystem, self.OnMannequinSuitSwitchCompleteWrapper)
  self.MannequinTaskId = avatarSystem:StartSwitchAvatarSuit(self.MannequinActor.Mesh, defaultSuitObj)
end

function AppearanceModule:OnMannequinSuitSwitchComplete(avatarSystem, Id, indexInSequence)
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:OnMannequinSuitSwitchComplete, \230\156\170\229\183\165\228\189\156")
    return
  end
  if Id ~= self.MannequinTaskId then
    return
  end
  self.MannequinTaskId = nil
  if self.OnMannequinSuitSwitchCompleteWrapper then
    avatarSystem.OnSwitchAvatarSuitComplete:Remove(avatarSystem, self.OnMannequinSuitSwitchCompleteWrapper)
    self.OnMannequinSuitSwitchCompleteWrapper = nil
  end
  local showInfo
  if self.data.fashionShowSequence and indexInSequence then
    showInfo = self.data.fashionShowSequence[indexInSequence]
  end
  if self.MannequinActor then
    self:SetMannequinActorHiddenInternal(self.MannequinActor, true)
    if nil == self.fashionShowTransDelayId and self.data.fashionShowSequence[self.data.currentIndexInSequence] and self.data.fashionShowSequence[self.data.currentIndexInSequence].suitId then
      self:StartMannequinActorFadeAppear(true)
    end
  end
  local nextSuitIndex, nextRelaxSkillIndex = self:CalcAllShowOfSuit(indexInSequence - 1)
  self:SetFashionShowPerformStateFlag(indexInSequence, FashionShowPerformState.SuitCheck)
  self:SetFashionShowPerformStateFlag(nextSuitIndex, FashionShowPerformState.SuitCheck)
  self:SetFashionShowPerformStateFlag(nextRelaxSkillIndex, FashionShowPerformState.SuitCheck)
end

function AppearanceModule:PrepareFashionShowRelaxSkill(showInfo)
  if not showInfo or not self.MannequinActor then
    return
  end
  if showInfo.skillPath and showInfo.npcId then
    local resQueue = self.fashionShowSequenceResQueues[showInfo.index]
    if resQueue then
      if resQueue.bSuccess then
        self:OnMannequinFashionShowLoadComplete(resQueue, true, showInfo.index)
        return
      else
        Log.Error("AppearanceModule:PrepareFashionShowRelaxSkill \232\181\132\230\186\144\232\175\183\230\177\130\229\144\142\229\176\154\230\156\170\230\136\144\229\138\159\231\154\132\230\131\133\229\134\181\239\188\140\229\143\136\232\175\149\229\155\190\232\191\155\232\161\140\228\184\128\230\172\161\232\175\183\230\177\130", showInfo.index, resQueue.State, resQueue.TimeoutHandler)
        if resQueue.TimeoutHandler > 0 then
          return
        end
      end
    end
    if resQueue then
      local npc = resQueue:Get("NPC")
      if npc then
        _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, npc:GetServerId())
      end
      resQueue:Release()
    end
    local newResQueue = ResQueue(30)
    self.fashionShowSequenceResQueues[showInfo.index] = newResQueue
    local pos = self.MannequinActor:Abs_K2_GetActorLocation()
    local position = ProtoMessage:newPosition()
    position.x = pos.X
    position.y = pos.Y
    position.z = pos.Z
    local npcResObj = newResQueue:InsertNPC("NPC", showInfo.npcId, position, 0)
    local resObj = newResQueue:InsertClass("SkillClass", showInfo.skillPath)
    local indexInSequence = showInfo.index
    
    local function OnMannequinFashionShowLoadCompleteWrapper(appearanceModule, InQueue, bSuccess)
      appearanceModule:OnMannequinFashionShowLoadComplete(InQueue, bSuccess, indexInSequence)
    end
    
    newResQueue:StartLoad(self, OnMannequinFashionShowLoadCompleteWrapper)
    if npcResObj and npcResObj.NPC then
      npcResObj.NPC:SetVisible(false)
      if npcResObj.NPC.AIComponent then
        npcResObj.NPC.AIComponent:ForceLockForReason(true, false, _G.AIDefines.LockReason.SUIT_PERFORM)
      end
      if npcResObj.NPC.PetHUDComponent then
        npcResObj.NPC.PetHUDComponent:SetRenderStatus(false, MainUIModuleEnum.DisableHudOpSource.SuitPerform)
      end
    end
  end
end

function AppearanceModule:OnMannequinFashionShowLoadComplete(resQueue, bSuccess, indexInSequence)
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:OnMannequinFashionShowLoadComplete, \230\156\170\229\183\165\228\189\156", resQueue, bSuccess, indexInSequence)
    return
  end
  if bSuccess then
    local petNpc = resQueue:Get("NPC")
    if petNpc and petNpc.viewObj and UE.UObject.IsValid(petNpc.viewObj) then
      petNpc.viewObj:SetInSignificance(false)
    end
    self:SetFashionShowPerformStateFlag(indexInSequence, FashionShowPerformState.ResCheck)
  else
    Log.Error("AppearanceModule:OnMannequinFashionShowLoadComplete, \229\138\160\232\189\189\229\164\177\232\180\165\228\186\134")
    self:OnFashionShowFinish(true, DebugDelayCallPath.Default)
  end
end

function AppearanceModule:OnFashionShowRelaxG6PreStart()
  if not (self.MannequinActorRelaxSkillProxy and self.MannequinActorRelaxSkillProxy.SkillObject) or not self.MannequinActor then
    return
  end
  local Blackboard = self.MannequinActorRelaxSkillProxy.SkillObject:GetBlackboard()
  local casterXfm = self.MannequinActor:Abs_GetTransform()
  Blackboard:SetValueAsTransform("Target", casterXfm)
  Blackboard:SetValueAsString("HavePet", "HavePet")
end

function AppearanceModule:OnFashionShowRelaxG6CastSuccess()
  if self.fashionShowRelaxPerformDelayId then
    DelayManager:CancelDelayById(self.fashionShowRelaxPerformDelayId)
    self.fashionShowRelaxPerformDelayId = nil
  end
  self.fashionShowRelaxPerformDelayId = DelayManager:DelaySeconds(0.5, function()
    if self.fashionShowRelaxPerformDelayId then
      DelayManager:CancelDelayById(self.fashionShowRelaxPerformDelayId)
      self.fashionShowRelaxPerformDelayId = nil
    end
    if self.FashionShowRelaxPetNpc then
      self.FashionShowRelaxPetNpc:SetVisible(true)
      if self.FashionShowRelaxPetNpc.viewObj and self.FashionShowRelaxPetNpc.viewObj.SetHiddenMask and UE.UObject.IsValid(self.FashionShowRelaxPetNpc.viewObj) then
        self.FashionShowRelaxPetNpc.viewObj:SetHiddenMask(false, UE.EPlayerForceHiddenType.Default)
      end
    end
  end)
end

function AppearanceModule:OnFashionShowRelaxG6CastFailed()
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:OnFashionShowRelaxG6CastFailed, \230\156\170\229\183\165\228\189\156")
    return
  end
  if self.FashionShowRelaxPetNpc then
    self.FashionShowRelaxPetNpc:SetVisible(false)
  end
  self:OnFashionShowFinish(true, DebugDelayCallPath.Default)
end

function AppearanceModule:OnFashionShowRelaxG6PetBack()
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:OnFashionShowRelaxG6PetBack, \230\156\170\229\183\165\228\189\156")
    return
  end
  if self.FashionShowRelaxPetNpc and self.FashionShowRelaxPetNpc.viewObj and UE.UObject.IsValid(self.FashionShowRelaxPetNpc.viewObj) and self.FashionShowRelaxPetNpc.isFake then
    local ballFlyBackToOwner = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/Yuancheng/CallBack_False", self.FashionShowRelaxPetNpc.viewObj.RocoSkill)
    ballFlyBackToOwner:SetCaster(self.MannequinActor)
    ballFlyBackToOwner:SetPassive(true)
    ballFlyBackToOwner:SetTargets({
      self.FashionShowRelaxPetNpc.viewObj
    })
    ballFlyBackToOwner:PlaySkill()
  end
end

function AppearanceModule:OnFashionShowRelaxBallBackG6End()
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:OnFashionShowRelaxBallBackG6End, \230\156\170\229\183\165\228\189\156")
    return
  end
  if self.FashionShowRelaxPetNpc then
    self.FashionShowRelaxPetNpc:SetVisible(false)
  end
  self:OnFashionShowFinish(true, DebugDelayCallPath.Default)
end

function AppearanceModule:OnFashionShowRelaxG6Interrupt()
  if not self.data.bFashionShowSequenceWorking then
    Log.Debug("AppearanceModule:OnFashionShowRelaxG6Interrupt, \230\156\170\229\183\165\228\189\156")
    return
  end
  if self.FashionShowRelaxPetNpc then
    self.FashionShowRelaxPetNpc:SetVisible(false)
  end
  self:OnFashionShowFinish(true, DebugDelayCallPath.Default)
end

function AppearanceModule:ModifyXRay(actor, value)
  if nil == actor then
    return
  end
  local rocoMaterial = actor.RocoMaterial
  local mesh = actor.mesh
  if not (rocoMaterial and mesh and UE4.UObject.IsValid(rocoMaterial)) or not UE4.UObject.IsValid(mesh) then
    return
  end
  local materials = rocoMaterial:GetCurrentMaterialsAsMID(mesh)
  for _, mat in tpairs(materials) do
    if UE4.UObject.IsValid(mat) then
      mat:SetSwitchParameterValue("Xray", true, mesh, false)
      mat:SetScalarParameterValue("Xray", value)
      for _, additionalMat in tpairs(mat.AdditionalMaterials) do
        if UE4.UObject.IsValid(additionalMat) then
          additionalMat:SetSwitchParameterValue("Xray", true, mesh, false)
          additionalMat:SetScalarParameterValue("Xray", value)
        end
      end
    end
  end
  if actor.Avatar then
    local actorTArray = actor.Avatar:GetDecorators()
    for _, decoratorActor in tpairs(actorTArray) do
      local meshComponent = decoratorActor:GetComponentByClass(UE.UStaticMeshComponent)
      meshComponent = meshComponent or decoratorActor:GetComponentByClass(UE.USkeletalMeshComponent)
      if meshComponent then
        materials = rocoMaterial:GetCurrentMaterialsAsMID(meshComponent)
        for _, mat in tpairs(materials) do
          if UE4.UObject.IsValid(mat) then
            mat:SetSwitchParameterValue("Xray", true, meshComponent, false)
            mat:SetScalarParameterValue("Xray", value)
            for _, additionalMat in tpairs(mat.AdditionalMaterials) do
              if UE4.UObject.IsValid(additionalMat) then
                additionalMat:SetSwitchParameterValue("Xray", true, meshComponent, false)
                additionalMat:SetScalarParameterValue("Xray", value)
              end
            end
          end
        end
      end
    end
  end
end

function AppearanceModule:SetCurrentIndexInSequence(newIndex, debugDelayCallPath)
  if not self.data.fashionShowSequence then
    Log.Warning("AppearanceModule:SetCurrentIndexInSequence \232\181\132\230\186\144\233\135\138\230\148\190\228\184\141\230\173\163\231\161\174 \232\176\131\231\148\168\232\183\175\229\190\132", debugDelayCallPath)
    return
  end
  newIndex = newIndex % #self.data.fashionShowSequence
  if 0 == newIndex then
    newIndex = #self.data.fashionShowSequence
  end
  self.data.currentIndexInSequence = newIndex
end

function AppearanceModule:StartMannequinActorFadeAppear(bFadeAppear, bRespect)
  if not self.MannequinActor then
    return
  end
  local InSameTypeFading = self.MannequinActorFadeAppearTimer and self.bFadeAppearMannequin == bFadeAppear
  if InSameTypeFading and bRespect then
    return
  end
  self:StopMannequinActorFadeAppear()
  self.bFadeAppearMannequin = bFadeAppear
  self.MannequinActorFadeAppearTimer = _G.TimerManager:CreateTimer(self, "AppearanceModuleFadeAppear", self.PikaShopFadeDuration / 1000, self.DoMannequinActorFadeAppear, self.OnMannequinActorFadeAppearComplete, 0)
end

function AppearanceModule:StopMannequinActorFadeAppear(bResetToHideAndDefault)
  if self.MannequinActorFadeAppearTimer then
    _G.TimerManager:RemoveTimer(self.MannequinActorFadeAppearTimer)
    self.MannequinActorFadeAppearTimer = nil
  end
  if bResetToHideAndDefault and self.MannequinActor and bResetToHideAndDefault then
    self:ModifyXRay(self.MannequinActor, self.PikaShopXRayValue)
    self:SetMannequinActorHiddenInternal(self.MannequinActor, true)
  end
end

function AppearanceModule:DoMannequinActorFadeAppear()
  if not self.MannequinActor then
    return
  end
  if not self.MannequinActorFadeAppearTimer then
    return
  end
  local deltaTime = self.MannequinActorFadeAppearTimer.elapsedTime
  local timer = self.MannequinActorFadeAppearTimer
  local PikaShopFadeDurationSecond = self.PikaShopFadeDuration / 1000
  if 0 == PikaShopFadeDurationSecond then
    return
  end
  if math.abs(timer.leftTime - PikaShopFadeDurationSecond) < 1.0E-5 then
    self:SetMannequinActorHiddenInternal(self.MannequinActor, false)
  end
  local leftTimeAfterUpdate = math.max(timer.leftTime - deltaTime, 0)
  local newValue = self.PikaShopXRayValue
  if self.bFadeAppearMannequin then
    newValue = self.PikaShopXRayValue + (1 - self.PikaShopXRayValue) * (leftTimeAfterUpdate / PikaShopFadeDurationSecond)
  else
    newValue = self.PikaShopXRayValue + (1 - self.PikaShopXRayValue) * (1 - leftTimeAfterUpdate / PikaShopFadeDurationSecond)
  end
  self:ModifyXRay(self.MannequinActor, newValue)
end

function AppearanceModule:OnMannequinActorFadeAppearComplete()
  if self.MannequinActor and self.MannequinActor_Ref then
    self:SetMannequinActorHiddenInternal(self.MannequinActor, not self.bFadeAppearMannequin)
  end
  self:StopMannequinActorFadeAppear(false)
end

function AppearanceModule:CalcFashionShouldShow(timeStampMs, indexInSequence, bFirstStart)
  if nil == timeStampMs then
    return
  end
  local bVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  local bSyncPendingPlayIndex = bVisit and bFirstStart
  if not bSyncPendingPlayIndex then
    if indexInSequence then
      return indexInSequence, 0
    else
      return 1, 0
    end
  end
  if self.data.fashionShowSequence and self.data.fashionShowSequenceTotalTime then
    local fashionShowSequence = self.data.fashionShowSequence
    local validTimeSpan = timeStampMs % self.data.fashionShowSequenceTotalTime
    local accumulateTime = 0
    for idx, showInfo in ipairs(fashionShowSequence) do
      if validTimeSpan <= accumulateTime then
        return idx, accumulateTime - validTimeSpan
      end
      if showInfo and showInfo.length then
        accumulateTime = accumulateTime + showInfo.length
      end
    end
    return 1, math.max(0, accumulateTime - validTimeSpan)
  end
  return nil, nil
end

function AppearanceModule:GetShowFallBehindStandTime(showInfo)
  local currentTimeStampMS = UE.UNRCStatics.GetUTCTimestampMS()
  local validTimeSpan = currentTimeStampMS % self.data.fashionShowSequenceTotalTime
  return validTimeSpan - (showInfo.startTime or 0)
end

function AppearanceModule:ChangeMannequinActorGender(gender)
  gender = gender or Enum.ESexValue.SEX_MALE
  if self.MannequinActorGender == gender then
    return
  end
  if not self.MannequinActor or not self.FashionShowBaseResQue then
    return
  end
  local animConfig, ABPClass
  if gender == Enum.ESexValue.SEX_MALE then
    ABPClass = self.FashionShowBaseResQue:Get("ABP1")
    animConfig = _G.NRCBigWorldPreloader:Get(UEPath.ANIM_CONFIG_MALE)
  elseif gender == Enum.ESexValue.SEX_FEMALE then
    ABPClass = self.FashionShowBaseResQue:Get("ABP2")
    animConfig = _G.NRCBigWorldPreloader:Get(UEPath.ANIM_CONFIG_FEMALE)
  end
  if ABPClass and animConfig then
    self.MannequinActor.Mesh:SetAnimClass(ABPClass)
    self.MannequinActor.RocoAnim:InitAnimInstance()
    self.MannequinActor.RocoAnim:SetAnimConfig(animConfig)
    self:SetMannequinActorHiddenInternal(self.MannequinActor, true)
    self.MannequinActorGender = gender
  else
    Log.Error("AppearanceModule:ChangeMannequinActorGender invalid Resource", ABPClass, animConfig)
  end
end

function AppearanceModule:CalcAllShowOfSuit(indexInSequence)
  local checkIndex = indexInSequence
  local nextSuitIndex = 0
  local nextRelaxSkillIndex = 0
  local sequenceLength = #self.data.fashionShowSequence
  for i = 1, sequenceLength do
    checkIndex = checkIndex + 1
    if sequenceLength < checkIndex then
      checkIndex = 1
    end
    local checkShowInfo = self.data.fashionShowSequence[checkIndex]
    if not checkShowInfo.suitId then
      break
    end
    if 0 == nextSuitIndex and checkShowInfo and checkShowInfo.suitId then
      nextSuitIndex = checkIndex
    end
    if 0 == nextRelaxSkillIndex and checkShowInfo.skillPath and checkShowInfo.npcId then
      nextRelaxSkillIndex = checkIndex
      break
    end
  end
  return nextSuitIndex, nextRelaxSkillIndex
end

function AppearanceModule:OnCmdRegisterFashionShowPerformBP(BPName, BPInstance)
  if string.IsNilOrEmpty(BPName) then
    return
  end
  self.fashionShowPerformBP[BPName] = BPInstance
end

function AppearanceModule:GetFashionShowPerformBP(BPName)
  local BPInstance = self.fashionShowPerformBP[BPName]
  if BPInstance and UE.UObject.IsValid(BPInstance) then
    return BPInstance
  end
end

function AppearanceModule:OnPreLoadMapStart(SameScene, bReconnecting)
  self:ReleaseFashionShowSequenceResource()
  if self:HasPanel("AppearanceCloset") then
    self:OnCmdCloseAppearanceClosetPanel()
  end
end

function AppearanceModule:OnLoadMapFinish(bReconnecting)
  self:ReleaseFashionShowSequenceResource()
end

function AppearanceModule:OnCmdGetTailorFittingRoomDoorFace()
  local curSceneResId = SceneUtils.GetSceneResId()
  local config = _G.DataConfigManager:GetMapGlobalConfig("tailor_fitting_room_door")
  if config then
    local max = 9
    for i = 0, max do
      local sceneResIdIndex = i * 4 + 1
      if sceneResIdIndex > #config.numList then
        return
      elseif config.numList[sceneResIdIndex] == curSceneResId then
        return config.numList[sceneResIdIndex + 1], config.numList[sceneResIdIndex + 2], config.numList[sceneResIdIndex + 3], config.numList[sceneResIdIndex + 4]
      end
    end
  end
end

function AppearanceModule:GetTailorStageCenter()
  local curSceneResId = SceneUtils.GetSceneResId()
  local config = _G.DataConfigManager:GetMapGlobalConfig("tailor_stage_center")
  if config then
    local max = 100
    for i = 0, max do
      local sceneResIdIndex = i * 5 + 1
      if sceneResIdIndex > #config.numList then
        return
      elseif config.numList[sceneResIdIndex] == curSceneResId then
        return config.numList[sceneResIdIndex + 1], config.numList[sceneResIdIndex + 2], config.numList[sceneResIdIndex + 3], config.numList[sceneResIdIndex + 4]
      end
    end
  end
end

function AppearanceModule:SetMannequinActorHiddenInternal(mannequinActor, bHidden)
  if mannequinActor then
    mannequinActor:SetActorHiddenInGame(bHidden)
    mannequinActor.mesh:SetVisibility(not bHidden)
    mannequinActor.Avatar:SetDecoratorVisible(not bHidden)
  end
end

function AppearanceModule:OnBondSelected(bondInfo)
  local hasPanel = self:HasPanel("GorgeousMedal")
  if hasPanel then
    local panel = self:GetPanel("GorgeousMedal")
    if panel then
      panel:OnBondSelected(bondInfo)
    end
  end
end

function AppearanceModule:OnBondTabSelected(type)
  local hasPanel = self:HasPanel("GorgeousMedal")
  if hasPanel then
    local panel = self:GetPanel("GorgeousMedal")
    if panel then
      panel:OnTabSelected(type)
    end
  end
end

function AppearanceModule:OnGorgeousMedalSortChange(index)
  local hasPanel = self:HasPanel("GorgeousMedal")
  if hasPanel then
    local panel = self:GetPanel("GorgeousMedal")
    if panel then
      panel:OnGorgeousMedalSortChange(index)
    end
  end
end

function AppearanceModule:OnCmdZoneGetFashionBondLastTabReq()
  if self.data.fashionBondLastTab ~= nil and self.data.fashionBondLastTab > 0 then
    return
  end
  local req = _G.ProtoMessage:newZoneGetFashionBondLastTabReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_FASHION_BOND_LAST_TAB_REQ, req, self, self.OnZoneGetFashionBondLastTabRsp, false, false)
end

function AppearanceModule:OnZoneGetFashionBondLastTabRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self.data.fashionBondLastTab = math.max(1, _rsp.last_fashionbond_tab)
  end
end

function AppearanceModule:OnCmdZoneSetFashionBondLastTabReq(tabType)
  local req = _G.ProtoMessage:newZoneSetFashionBondLastTabReq()
  req.last_fashionbond_tab = tabType
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_FASHION_BOND_LAST_TAB_REQ, req, self, self.OnZoneSetFashionBondLastTabRsp, false, false)
end

function AppearanceModule:OnZoneSetFashionBondLastTabRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self.data.fashionBondLastTab = math.max(1, _rsp.last_fashionbond_tab)
  end
end

function AppearanceModule:OnCmdGetFashionBondLastTab()
  if self.data.fashionBondLastTab then
    return self.data.fashionBondLastTab
  end
  return _G.Enum.FashionBondBand.FBB_OPERA
end

function AppearanceModule:CheckIfSuitPurchasableReq(storeIds)
  if self.alreadySendReq then
    return
  end
  self.alreadySendReq = true
  self.checkPurchasablePendingCount = 0
  self.checkPurchasableDelayId = _G.DelayManager:DelaySeconds(5, function()
    self.alreadySendReq = false
    self.checkPurchasablePendingCount = 0
  end)
  for _, shopId in ipairs(storeIds) do
    self.checkPurchasablePendingCount = self.checkPurchasablePendingCount + 1
    local reqShopData = {
      shopId = shopId,
      Caller = self,
      rspHandler = self.CheckIfSuitPurchasableRsp,
      needModal = false,
      ignoreErrorTip = false,
      reqTag = "AppearanceModule:CheckIfSuitPurchasableReq"
    }
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
  end
end

function AppearanceModule:CheckIfSuitPurchasableRsp(rsp)
  self.checkPurchasablePendingCount = (self.checkPurchasablePendingCount or 1) - 1
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("AppearanceModule:CheckIfSuitPurchasableRsp \232\175\183\230\177\130\229\164\177\232\180\165")
  else
    local rspShopId = rsp.shop_data and rsp.shop_data.id or 0
    self.data.allClothShopInfoMap[rspShopId] = rsp.shop_data.goods_data
  end
  if self.checkPurchasablePendingCount <= 0 then
    self.alreadySendReq = false
    if self.checkPurchasableDelayId then
      _G.DelayManager:CancelDelayById(self.checkPurchasableDelayId)
      self.checkPurchasableDelayId = nil
    end
    local gorgeousMedalPanel
    if self:HasPanel("GorgeousMedal") then
      gorgeousMedalPanel = self:GetPanel("GorgeousMedal")
    end
    if not gorgeousMedalPanel then
      local bIsOpening = self:HasPanel("AppearanceCloset")
      if bIsOpening then
        local panel = self:GetPanel("AppearanceCloset")
        if panel then
          panel:OnPurchaseBtnClickCallback()
        end
      end
    end
  end
end

function AppearanceModule:OnEnterVisit()
  if SceneUtils.IsInPikaShop() then
    self:ReleaseFashionShowSequenceResource()
    self.bRestartFashionShowSequenceAtEnterSceneAck = true
    if _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      if self.restartFashionShowId then
        _G.DelayManager:CancelDelayById(self.restartFashionShowId)
        self.restartFashionShowId = nil
      end
      self.restartFashionShowId = DelayManager:DelayFrames(3, function(appearanceModule)
        appearanceModule:ActiveFashionShowSequence()
      end, self)
    end
  end
  self:ClosePanel("FashionMallPopup")
end

function AppearanceModule:OnLeaveVisit()
  if SceneUtils.IsInPikaShop() then
    self.bRestartFashionShowSequenceAtEnterSceneAck = true
    self:ReleaseFashionShowSequenceResource()
    if self.restartFashionShowId then
      _G.DelayManager:CancelDelayById(self.restartFashionShowId)
      self.restartFashionShowId = nil
    end
    self.restartFashionShowId = DelayManager:DelayFrames(3, function(appearanceModule)
      appearanceModule:ActiveFashionShowSequence()
    end, self)
  end
end

function AppearanceModule:OnUpgradeSuitLevelPanelClose()
  local suitId = 0
  if 0 == suitId and self.claimColorBondId and 0 ~= self.claimColorBondId then
    local bondConf = _G.DataConfigManager:GetFashionBondConf(self.claimColorBondId)
    if bondConf and bondConf.color_suits_id then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      for k, v in ipairs(bondConf.color_suits_id) do
        local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v)
        if suitConf and suitConf.gender == player.gender then
          suitId = v
          break
        end
      end
    end
  end
  self:DispatchEvent(AppearanceModuleEvent.OnUnlockNewHeterochromeSuit, suitId)
end

function AppearanceModule:PlayClosetShiningMedalSkillStart()
  local avatarPlayer = self.closetAvatarPlayer
  if avatarPlayer then
    self.animManager:TryPlayBeginLoopAnimByName(avatarPlayer, "ShiningMedalOpen", "ShiningMedalLoop", true)
  end
  self._bIsPlayingShiningMedalSkill = true
end

function AppearanceModule:PlayClosetShiningMedalSkillEnd()
  local avatarPlayer = self.closetAvatarPlayer
  if avatarPlayer then
    self.animManager:TryPlayBeginLoopAnimByNameWithParam(avatarPlayer, "ShiningMedalEnd", "HZIdle", true)
  end
  self._bIsPlayingShiningMedalSkill = false
end

function AppearanceModule:OpenMagicWandPopUp(context)
  local isOpening, _ = self:HasPanel("MagicWandPopUp")
  if not isOpening then
    self:OpenPanel("MagicWandPopUp", context)
  end
end

function AppearanceModule:OnCmdSetPanelMoneyBtnVisibleFlag(panelName, flag, bRelease, presetTime)
  if not (panelName and flag) or not self.data.PanelMoneyBtn then
    return
  end
  local widget = self.data.PanelMoneyBtn[panelName]
  if not widget or not UE.UObject.IsValid(widget) then
    return
  end
  if not self.data.PanelMoneyBtnHideFlag then
    self.data.PanelMoneyBtnHideFlag = {}
  end
  if not self.data.PanelMoneyBtnHideFlag[panelName] then
    self.data.PanelMoneyBtnHideFlag[panelName] = {}
  end
  local moneyBtnHideFlag = self.data.PanelMoneyBtnHideFlag[panelName]
  if bRelease then
    moneyBtnHideFlag[flag] = nil
    local pendingRemoveIndex
    for idx, checkFlag in ipairs(moneyBtnHideFlag) do
      if checkFlag == flag then
        pendingRemoveIndex = idx
      end
    end
    if pendingRemoveIndex then
      table.remove(moneyBtnHideFlag, pendingRemoveIndex)
    end
  else
    if presetTime then
      if not self.data.PanelMoneyBtnPresetAutoReleaseDelay then
        self.data.PanelMoneyBtnPresetAutoReleaseDelay = {}
      end
      if not self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName] then
        self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName] = {}
      end
      if self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName][flag] then
        _G.DelayManager:CancelDelayById(self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName][flag])
        self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName][flag] = nil
      end
      self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName][flag] = _G.DelayManager:DelaySeconds(presetTime, function()
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetPanelMoneyBtnVisibleFlag, panelName, flag, true)
      end)
    elseif not bRelease and self.data.PanelMoneyBtnPresetAutoReleaseDelay and self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName] and self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName][flag] then
      _G.DelayManager:CancelDelayById(self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName][flag])
      self.data.PanelMoneyBtnPresetAutoReleaseDelay[panelName][flag] = nil
    end
    local bHadSamFlag = false
    for idx, checkFlag in ipairs(moneyBtnHideFlag) do
      if checkFlag == flag then
        bHadSamFlag = true
        break
      end
    end
    if not bHadSamFlag then
      table.insert(moneyBtnHideFlag, flag)
    end
  end
  local bVisible = 0 == #moneyBtnHideFlag
  if bVisible then
    widget:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    widget:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function AppearanceModule:OnCmdRegisterMoneyBtn(panelName, widget, bUnRegister)
  if not panelName or not widget then
    return
  end
  if not self.data.PanelMoneyBtn then
    self.data.PanelMoneyBtn = {}
  end
  if bUnRegister then
    self.data.PanelMoneyBtn[panelName] = nil
    if self.data.PanelMoneyBtnHideFlag and self.data.PanelMoneyBtnHideFlag[panelName] then
      self.data.PanelMoneyBtnHideFlag[panelName] = nil
    end
  else
    self.data.PanelMoneyBtn[panelName] = widget
  end
end

function AppearanceModule:GetAvatarDefaultSalonIdsByGender(gender)
  local defaultSalonIds = {}
  if 1 == gender then
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_HAIR] = 1
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYEBORWS] = 33
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYELASH] = 58
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYES] = 157
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_MAKEUP] = 64
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_SKIN] = 153
  elseif 2 == gender then
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_HAIR] = 77
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYEBORWS] = 109
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYELASH] = 134
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYES] = 157
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_MAKEUP] = 140
    defaultSalonIds[_G.Enum.SalonLabelType.SLT_SKIN] = 153
  end
  return defaultSalonIds
end

function AppearanceModule:GetAvatarDefaultFashionIdsByGender(gender)
  local defaultFashionIds = {}
  if 1 == gender then
    defaultFashionIds[_G.Enum.FashionLabelType.FLT_TOPS] = 10700101
    defaultFashionIds[_G.Enum.FashionLabelType.FLT_BOTTOMS] = 10900101
    defaultFashionIds[_G.Enum.FashionLabelType.FLT_BAGS] = 11200101
    defaultFashionIds[_G.Enum.FashionLabelType.FLT_SHOES] = 11100101
  elseif 2 == gender then
    defaultFashionIds[_G.Enum.FashionLabelType.FLT_TOPS] = 20700101
    defaultFashionIds[_G.Enum.FashionLabelType.FLT_BOTTOMS] = 20900101
    defaultFashionIds[_G.Enum.FashionLabelType.FLT_BAGS] = 21200101
    defaultFashionIds[_G.Enum.FashionLabelType.FLT_SHOES] = 21100101
  end
  return defaultFashionIds
end

function AppearanceModule:OnCmdGetAllSuitsInPackage(packageId)
  if not packageId then
    return {}
  end
  return self.data.AllSuitInPackage[packageId] or {}
end

function AppearanceModule:IsLocalPlayerInCloset()
  return self.closetNpcAction ~= nil
end

function AppearanceModule:OnCmdCalcPikaPoint(shopId, goodsId, currentDepth)
  if not currentDepth or currentDepth < 0 then
    currentDepth = 0
  end
  if currentDepth >= MAX_SEARCH_DEPTH then
    Log.Error("AppearanceModule:OnCmdCalcPikaPoint search depth max", shopId, goodsId, currentDepth)
    return 0
  end
  local searchResultPikaPoint = 0
  local goodsData = _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, shopId, goodsId, true)
  if goodsData and goodsData.sub_goods then
    for idx, subGoodsData in ipairs(goodsData.sub_goods) do
      if subGoodsData.is_gift then
        local subGoodsNormalShopConf = _G.DataConfigManager:GetNormalShopConf(subGoodsData.goods_id, true)
        local bHasOwned = false
        if subGoodsNormalShopConf then
          local goodsType = subGoodsNormalShopConf.Type
          local itemId = subGoodsNormalShopConf.item_id
          if Enum.GoodsType.GT_FASHION_SUITS == goodsType then
            bHasOwned = self:OnCmdHadOwnedEntireSuit(itemId)
          elseif Enum.GoodsType.GT_FASHION == goodsType then
            bHasOwned = self:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, itemId)
          elseif Enum.GoodsType.GT_CARD_SKIN == goodsType then
            bHasOwned = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.HasCardSkin, itemId)
          elseif Enum.GoodsType.GT_VITEM == goodsType and itemId == _G.Enum.VisualItem.VI_PIKA_POINT and subGoodsData.is_gift then
            searchResultPikaPoint = searchResultPikaPoint + subGoodsNormalShopConf.item_num
            bHasOwned = true
          end
          if not bHasOwned then
            searchResultPikaPoint = searchResultPikaPoint + self:OnCmdCalcPikaPoint(shopId, subGoodsData.goods_id, currentDepth + 1)
          end
        end
      end
    end
  end
  return searchResultPikaPoint
end

function AppearanceModule:CheckAllComponentUnlocked(avatar)
  if not avatar then
    return false
  end
  local suit = avatar:GetAvatarSuit()
  if not suit then
    return true
  end
  local bodies = suit:GetBodies()
  local salonsFull = suit:GetSalons()
  local fashions = bodies and bodies.ToTable and bodies:ToTable() or {}
  local salons = salonsFull and salonsFull.ToTable and salonsFull:ToTable() or {}
  for _, fashionId in ipairs(fashions) do
    local has = self:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, fashionId)
    if not has then
      Log.Error(string.format("fashion\233\131\168\228\187\182 %s \230\156\170\230\139\165\230\156\137", fashionId))
      return false
    end
  end
  for _, fullSalon in ipairs(salons) do
    local avatarId = CommonUIUtils.GetSalonIdFromFull(fullSalon)
    local list = self.data and self.data.AvatarSalonIdToSalonIds and self.data.AvatarSalonIdToSalonIds[avatarId]
    if not list or 0 == #list then
      Log.Error(string.format("salon\233\131\168\228\187\182 %s \230\137\190\228\184\141\229\136\176\229\175\185\229\186\148\231\154\132 salon_item_conf id", avatarId))
      return false
    end
    local owned = false
    for _, itemId in ipairs(list) do
      if self:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_SALON, itemId) then
        owned = true
        break
      end
    end
    if not owned then
      Log.Error(string.format("salon\233\131\168\228\187\182 %s \230\156\170\230\139\165\230\156\137", avatarId))
      return false
    end
  end
  return true
end

function AppearanceModule:OnCmdGetItemPartType(goodsType, itemId)
  return self.data:GetItemPartType(goodsType, itemId)
end

function AppearanceModule:GetLocalPlayerPendanta()
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if not fashionInfo then
    return nil
  end
  local index = (fashionInfo.current_wardrobe_index or 0) + 1
  local wardrobeInfo = fashionInfo.wardrobe_data[index]
  if not wardrobeInfo then
    return nil
  end
  if wardrobeInfo.wearing_item and #wardrobeInfo.wearing_item > 0 then
    for k, v in pairs(wardrobeInfo.wearing_item) do
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
      if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
        return v.wearing_item_id
      end
    end
  end
  return nil
end

function AppearanceModule:GetPackageIdFromGiftId(giftItemId)
  local goodsId = self.data.FashionIdToGoodsIdMap[giftItemId]
  if not goodsId then
    return
  end
  return self.data.giftIdToPackageIdMap[goodsId.id]
end

function AppearanceModule:HasFashionBond(fashionBondId)
  local bondItem = _G.DataModelMgr.PlayerDataModel:GetFashionBondItem(fashionBondId)
  if bondItem and bondItem.id == fashionBondId then
    return true
  end
  return false
end

function AppearanceModule:CanFashionBondPurchasable(fashionBondId)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local gender = player.gender or 1
  local suitId = self.data.bondIdToSuitId[gender][fashionBondId]
  if suitId then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
    if not suitConf or not suitConf.package_id then
      return false
    end
    if self:CheckHasSuit(suitId) then
      return true
    end
    if self:CheckSuitAtMonthlyShop(suitId) then
      return true
    end
  end
  return false
end

function AppearanceModule:GetSuitIdFromBondId(bondConfId)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return nil
  end
  local gender = player.gender or 1
  return self.data.bondIdToSuitId[gender][bondConfId]
end

function AppearanceModule:GetShiningSuitIdFromBondId(bondConfId)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return nil
  end
  local gender = player.gender or 1
  local bondConf = _G.DataConfigManager:GetFashionBondConf(bondConfId)
  if bondConf and bondConf.color_suits_id and #bondConf.color_suits_id > 0 then
    for k, v in ipairs(bondConf.color_suits_id) do
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v)
      if suitConf and suitConf.suits_original_id and suitConf.suits_original_id > 0 and suitConf.gender == gender then
        return v
      end
    end
  end
  return nil
end

function AppearanceModule:OnMagnificentMagicDotItemSelected(index)
  local bHasPanel = self:HasPanel("MagicVideoDetails")
  if bHasPanel then
    local panel = self:GetPanel("MagicVideoDetails")
    if panel then
      panel:OnDotItemSelected(index)
    end
  end
end

function AppearanceModule:OpenGetHeterochromeSuitPanel(rsp)
  if not rsp or 0 ~= rsp.ret_info.ret_code then
    Log.Error("AppearanceModule:OpenGetHeterochromeSuitPanel \232\175\183\230\177\130\232\142\183\229\143\150\229\188\130\232\137\178\229\165\151\232\163\133\229\164\177\232\180\165\239\188\140\233\148\153\232\175\175\231\160\129%s", rsp.ret_info.ret_code)
    if self.claimColorBondPopUp and self.claimColorBondId then
      local bondConf = _G.DataConfigManager:GetFashionBondConf(self.claimColorBondId)
      if bondConf and bondConf.color_suits_id then
        local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        if player then
          for k, v in ipairs(bondConf.color_suits_id) do
            local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v)
            if suitConf and suitConf.gender == player.gender then
              _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.RemoveHiddenSuitTipsId, v)
              break
            end
          end
        end
      end
    end
    return
  end
  _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 466, string.format("%s", self.claimColorBondId), true)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.OpenGiftReminder, self.claimColorPetGid, self.claimColorBondId, self.claimColorBondPopUp)
end

function AppearanceModule:OpenFashionGetHeterochromeSuitPanel(bondId)
  local fakeRsp = _G.ProtoMessage:newZoneShopBuyItemRsp()
  local suitId = 0
  if 0 == suitId and bondId and 0 ~= bondId then
    local bondConf = _G.DataConfigManager:GetFashionBondConf(bondId)
    if bondConf and bondConf.color_suits_id then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      for k, v in ipairs(bondConf.color_suits_id) do
        local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v)
        if suitConf and suitConf.gender == player.gender then
          suitId = v
          break
        end
      end
    end
  end
  if 0 == suitId then
    Log.Error("AppearanceModule:OpenGetHeterochromeSuitPanel \230\137\147\229\188\128\229\188\130\232\137\178\229\165\151\232\163\133\230\129\173\229\150\156\231\149\140\233\157\162\229\164\177\232\180\165\239\188\140bond id\230\178\161\230\156\137\229\175\185\229\186\148\231\154\132\229\188\130\232\137\178suit id")
    return
  end
  _G.DataModelMgr.PlayerDataModel:UpdateFashionBondColorSuitState(bondId, _G.Enum.FashionBondColorSuitState.FBCSS_OWNED)
  fakeRsp.ret_info.ret_code = 0
  fakeRsp.shop_id = 103
  fakeRsp.ret_info.goods_reward.rewards = {
    {
      type = _G.Enum.GoodsType.GT_FASHION_SUITS,
      id = suitId
    }
  }
  local bClosetPanel = self:HasPanel("AppearanceCloset")
  if bClosetPanel then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:OnPlayerDataUpdate()
    end
  end
  local bHasPanel = self:HasPanel("FashionBuyResultPopUp")
  if not bHasPanel then
    self:OpenPanel("FashionBuyResultPopUp", fakeRsp)
  end
end

function AppearanceModule:IsSuitHeterochrome(suitId)
  if not suitId or 0 == suitId then
    return false
  end
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if not (suitConf and suitConf.suits_original_id) or 0 == suitConf.suits_original_id then
    return false
  end
  return true, suitConf.suits_original_id
end

function AppearanceModule:IsFashionHeterochrome(itemId)
  if not itemId or 0 == itemId then
    return false
  end
  local itemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
  if not (itemConf and itemConf.suits_id) or 0 == itemConf.suits_id then
    return false
  end
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(itemConf.suits_id)
  if not (suitConf and suitConf.suits_original_id) or 0 == suitConf.suits_original_id then
    return false
  end
  return true
end

function AppearanceModule:CheckWearingItemListProperly(wearingItemList)
  if not wearingItemList or 0 == #wearingItemList then
    return false
  end
  local bHasDress = false
  local bHasTop = false
  local bHasBottom = false
  local bHasShoes = false
  for _, v in ipairs(wearingItemList) do
    if v.wearing_item_id and v.wearing_item_id > 0 then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
      if fashionItemConf then
        local fashionType = fashionItemConf.type
        if fashionType == _G.Enum.FashionLabelType.FLT_DRESSES then
          bHasDress = true
        elseif fashionType == _G.Enum.FashionLabelType.FLT_TOPS then
          bHasTop = true
        elseif fashionType == _G.Enum.FashionLabelType.FLT_BOTTOMS then
          bHasBottom = true
        elseif fashionType == _G.Enum.FashionLabelType.FLT_SHOES then
          bHasShoes = true
        end
      end
    end
  end
  return (bHasDress or bHasTop and bHasBottom) and bHasShoes
end

function AppearanceModule:CheckOutfitProperly()
  if not self.data.TempAppearData or 0 == #self.data.TempAppearData then
    return false
  end
  local bHasDress = false
  local bHasTop = false
  local bHasBottom = false
  local bHasShoes = false
  for k, v in ipairs(self.data.TempAppearData) do
    if v.FashionType == _G.Enum.FashionLabelType.FLT_DRESSES then
      bHasDress = true
    elseif v.FashionType == _G.Enum.FashionLabelType.FLT_TOPS then
      bHasTop = true
    elseif v.FashionType == _G.Enum.FashionLabelType.FLT_BOTTOMS then
      bHasBottom = true
    elseif v.FashionType == _G.Enum.FashionLabelType.FLT_SHOES then
      bHasShoes = true
    end
  end
  if bHasDress or bHasTop and bHasBottom then
    return bHasShoes
  end
  return false
end

function AppearanceModule:ClaimHeterochromeSuitReq(fashionBondId, petGid, bIsPopUp)
  local req = _G.ProtoMessage:newZoneClaimColorSuitReq()
  req.fashion_bond_id = fashionBondId
  req.pet_gid = petGid
  self.claimColorBondPopUp = bIsPopUp
  self.claimColorBondId = fashionBondId
  self.claimColorPetGid = petGid
  if bIsPopUp then
    local bondConf = _G.DataConfigManager:GetFashionBondConf(fashionBondId)
    if bondConf and bondConf.color_suits_id then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if player then
        for k, v in ipairs(bondConf.color_suits_id) do
          local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v)
          if suitConf and suitConf.gender == player.gender then
            _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.AddHiddenSuitTipsId, v)
            break
          end
        end
      end
    end
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLAIM_COLOR_SUIT_REQ, req, self, self.OpenGetHeterochromeSuitPanel)
end

function AppearanceModule:OpenPackagePreview(packageId, suitsId, suitId)
  if nil ~= packageId and type(packageId) ~= "number" and type(packageId) == "string" then
    packageId = tonumber(packageId)
  end
  if nil ~= suitsId and type(suitsId) ~= "table" then
    return
  end
  if nil ~= suitId and type(suitId) ~= "number" and type(suitId) == "string" then
    suitId = tonumber(suitId)
  end
  if not packageId and (not suitsId or 0 == #suitsId) then
    Log.Error("AppearanceModule:OpenPackagePreview \228\188\160\229\133\165\231\169\186Id")
    return
  end
  if suitsId and #suitsId > 0 and suitId and 0 ~= suitId then
    local bFound = false
    for k, v in ipairs(suitsId) do
      if suitId == v then
        bFound = true
        break
      end
    end
    if not bFound then
      Log.Error("AppearanceModule:OpenPackagePreview \228\188\160\229\133\165\231\154\132suitId\229\156\168suitsId\228\184\173\228\184\141\229\173\152\229\156\168")
      return
    end
  end
  local bHasPanel = self:HasPanel("AppearanceTryOn")
  if bHasPanel then
    Log.Error("\229\176\157\232\175\149\229\156\168TryOn\231\149\140\233\157\162\230\137\147\229\188\128\228\184\128\228\184\170\230\150\176\231\154\132TryOn\231\149\140\233\157\162\239\188\140\230\156\137\233\151\174\233\162\152")
    return
  end
  local goodsId = self.data.packageIdToGoodsIdMap[packageId]
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("\232\142\183\229\143\150\230\156\172\229\156\176\231\142\169\229\174\182\229\164\177\232\180\165")
    return
  end
  local resListData = _G.NRCPanelResLoadData()
  resListData.PreLoadResList = {}
  table.insert(resListData.PreLoadResList, self:GetAvatarResPath(player.gender))
  table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color2.T_UI_Closet_Color2'")
  table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_Closet_Color1.T_UI_Closet_Color1'")
  table.insert(resListData.PreLoadResList, "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Textures/T_UI_black.T_UI_black'")
  local param = {
    FashionPackageId = packageId,
    boughtNum = 0,
    goodsExpireTime = 0,
    shopId = 103,
    shopItemId = goodsId,
    shopLibId = goodsId
  }
  self:OpenPanel("AppearanceTryOn", param, nil, nil, nil, resListData, suitId, true, suitsId)
end

function AppearanceModule:GetSuitUnlockComponentsNum(suit_id)
  local unlockNum = 0
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo and fashionInfo.suit_info then
    for _, v in pairs(fashionInfo.suit_info or {}) do
      if v.suit_id == suit_id and v.components_is_owned then
        return #v.components_is_owned
      end
    end
  end
  return unlockNum
end

function AppearanceModule:GetSuitUnlockComponents(suit_id)
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo.suit_info then
    for _, v in pairs(fashionInfo.suit_info or {}) do
      if v.suit_id == suit_id and v.components_is_owned then
        return v.components_is_owned
      end
    end
  end
  return nil
end

function AppearanceModule:GetSuitComponentsTotalNum(suit_id)
  local totalNum = 0
  if suit_id then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suit_id, true)
    if suitConf and suitConf.lv_up_closet then
      totalNum = #suitConf.lv_up_closet
    end
  end
  return totalNum
end

function AppearanceModule:CheckComponentIsUnlocked(index, suit_id)
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo.suit_info then
    for _, v in pairs(fashionInfo.suit_info or {}) do
      if v.suit_id == suit_id then
        for _, comp in pairs(v.components_is_owned or {}) do
          if comp == index then
            return true
          end
        end
      end
    end
  end
  return false
end

function AppearanceModule:IsUnlockedAllComponents(suit_id)
  return self:GetSuitUnlockComponentsNum(suit_id) == self:GetSuitComponentsTotalNum(suit_id) and 0 ~= self:GetSuitComponentsTotalNum(suit_id)
end

function AppearanceModule:GetNextLockedItemIconPath(suit_id)
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suit_id)
  if not suitConf then
    return ""
  end
  if not suitConf.lv_up_closet or 0 == #suitConf.lv_up_closet then
    return ""
  end
  local components_is_owned = {}
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo.suit_info then
    for _, v in ipairs(fashionInfo.suit_info) do
      if v.suit_id == suit_id then
        components_is_owned = v.components_is_owned
        break
      end
    end
  end
  local index = #suitConf.lv_up_closet
  for i, _ in pairs(suitConf.lv_up_closet or {}) do
    local isOwned = false
    for _, v in pairs(components_is_owned or {}) do
      if i - 1 == v then
        isOwned = true
        break
      end
    end
    if not isOwned then
      index = i
      break
    end
  end
  if suitConf.lv_up_closet[index].lv_item_type == _G.Enum.GoodsType.GT_FASHION then
    local itemConf = _G.DataConfigManager:GetFashionItemConf(suitConf.lv_up_closet[index].lv_item_id, true)
    if itemConf then
      return itemConf.icon, false, true, itemConf.type
    end
  elseif suitConf.lv_up_closet[index].lv_item_type == _G.Enum.GoodsType.GT_SALON then
    local itemConf = _G.DataConfigManager:GetSalonItemConf(suitConf.lv_up_closet[index].lv_item_id, true)
    if itemConf then
      return itemConf.icon, false, false, itemConf.type
    end
  elseif suitConf.lv_up_closet[index].lv_item_type == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local itemConf = _G.DataConfigManager:GetFashionSuitsConf(suitConf.lv_up_closet[index].lv_item_id, true)
    if itemConf then
      return itemConf.suits_icon, true, false, _G.Enum.GoodsType.GT_FASHION_SUITS
    end
  elseif suitConf.lv_up_closet[index].lv_item_type == _G.Enum.GoodsType.GT_FASHION_BOND then
    local itemConf = _G.DataConfigManager:GetFashionBondConf(suitConf.lv_up_closet[index].lv_item_id, true)
    if itemConf then
      return itemConf.fashion_bond_icon, true, false, _G.Enum.GoodsType.GT_FASHION_BOND
    end
  end
  return ""
end

function AppearanceModule:SendClaimGlassTintReq(fashion_bond_id, is_shining, glass, fashion_item_id, pet_data)
  local req = _G.ProtoMessage:newZoneClaimGlassTintReq()
  req.fashion_bond_id = fashion_bond_id
  req.is_shining = is_shining
  req.glass = glass
  req.fashion_item_id = fashion_item_id
  self.bFromRelationTree = false
  self.claimGlassPetData = nil
  if not fashion_item_id and pet_data then
    self.bFromRelationTree = true
    self.claimGlassPetData = pet_data
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLAIM_GLASS_TINT_REQ, req, self, self.ZoneClaimGlassTintRsp, false, false)
end

function AppearanceModule:ZoneClaimGlassTintRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local changes = rsp.change_to_owned
    local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    if fashionInfo.owned_item_info then
      for _, item in pairs(changes or {}) do
        local targetItem
        for _, _item in pairs(fashionInfo.owned_item_info or {}) do
          if item and _item and item.fashion_item_id == _item.item_id then
            targetItem = _item
            break
          end
        end
        if targetItem then
          local removeIndex
          for i, glass in pairs(targetItem.claimable_glass or {}) do
            if item.glass.glass_type == glass.glass_type and item.glass.glass_value == glass.glass_value then
              removeIndex = i
              break
            end
          end
          if removeIndex then
            table.remove(targetItem.claimable_glass, removeIndex)
          end
          if not targetItem.unlocked_glass then
            targetItem.unlocked_glass = {}
          end
          table.insert(targetItem.unlocked_glass, item.glass)
        end
      end
    end
    self:UpdateOwnedGlassItemTabList()
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ClosePetRelationCover)
    self:OpenPigmentAcquirePanel(rsp.change_to_owned, not self.bFromRelationTree)
    self:UpdateCurClosetTabAfterGetGlassTint()
  end
end

function AppearanceModule:OnZoneGlassTintChangeNty(rsp)
  if rsp then
    local change_to_claimable = rsp.change_to_claimable
    local change_to_lock = rsp.change_to_lock
    local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    if fashionInfo.owned_item_info then
      for _, claimableItem in pairs(change_to_claimable or {}) do
        local addItem
        for _, item in pairs(fashionInfo.owned_item_info or {}) do
          if item.item_id == claimableItem.fashion_item_id then
            addItem = item
            break
          end
        end
        if addItem then
          local addIndex
          for i, glass in pairs(addItem.claimable_glass or {}) do
            if glass.glass_type == claimableItem.glass.glass_type and glass.glass_value == claimableItem.glass.glass_value then
              addIndex = i
              break
            end
          end
          if not addIndex then
            if not addItem.claimable_glass then
              addItem.claimable_glass = {}
            end
            table.insert(addItem.claimable_glass, claimableItem.glass)
          end
        end
      end
      for _, claimableItem in pairs(change_to_lock or {}) do
        local removeItem
        for _, item in pairs(fashionInfo.owned_item_info or {}) do
          if item.item_id == claimableItem.fashion_item_id then
            removeItem = item
            break
          end
        end
        if removeItem then
          local removeIndex
          for i, glass in pairs(removeItem.claimable_glass or {}) do
            if glass.glass_type == claimableItem.glass.glass_type then
              removeIndex = i
              break
            end
          end
          if removeIndex then
            table.remove(removeItem.claimable_glass, removeIndex)
          end
        end
      end
    end
    self:UpdateClosetPanelInfo()
  end
end

function AppearanceModule:CheckPetGlassTintIsClaimableByBondID(fashion_bond_id, glass_info, is_shining)
  if fashion_bond_id then
    local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    if fashionInfo.owned_item_info then
      local suitId = self:GetSuitIdFromBondId(fashion_bond_id)
      if is_shining then
        do
          local snap_suitId = self:GetShiningSuitIdFromBondId(fashion_bond_id)
          if not snap_suitId then
            Log.Debug("\232\191\153\230\152\175\228\184\128\228\184\170\229\188\130\232\137\178\229\185\182\228\184\148\231\130\171\229\189\169\231\154\132\231\178\190\231\129\181\239\188\140 \228\189\134\230\152\175\230\178\161\230\156\137\229\188\130\232\137\178\231\154\132\229\165\151\232\163\133ID")
          end
          suitId = snap_suitId and snap_suitId or suitId
        end
      end
      for _, item in pairs(fashionInfo.owned_item_info or {}) do
        if item and item.claimable_glass and #item.claimable_glass > 0 then
          local isEqual = false
          if glass_info then
            for k, v in pairs(item.claimable_glass) do
              if v.glass_type == glass_info.glass_type and v.glass_value == glass_info.glass_value then
                local itemConf = _G.DataConfigManager:GetFashionItemConf(item.item_id)
                if itemConf and itemConf.suits_id == tostring(suitId) then
                  return true
                end
              end
            end
          end
        end
      end
    end
  end
  return false
end

function AppearanceModule:CheckPetGlassTintIsClaimableByItemID(item_id)
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo.owned_item_info then
    for _, item in pairs(fashionInfo.owned_item_info or {}) do
      if item and item.item_id == item_id and item.claimable_glass and #item.claimable_glass > 0 then
        return true
      end
    end
  end
  return false
end

function AppearanceModule:CheckPetGlassTintIsClaimableByType(type)
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if not fashionInfo then
    return false
  end
  if fashionInfo.owned_item_info then
    for _, item in pairs(fashionInfo.owned_item_info or {}) do
      if item and item.claimable_glass and #item.claimable_glass > 0 then
        if not type then
          return true
        end
        local itemConf = _G.DataConfigManager:GetFashionItemConf(item.item_id)
        if itemConf and itemConf.type == type then
          return true
        end
      end
    end
  end
  return false
end

function AppearanceModule:GetGlassItemListByType(type)
  local glassItemList = {}
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo and fashionInfo.owned_item_info then
    for _, item in pairs(fashionInfo.owned_item_info or {}) do
      if item and (item.claimable_glass and #item.claimable_glass > 0 or item.unlocked_glass and #item.unlocked_glass > 0) then
        local itemConf = _G.DataConfigManager:GetFashionItemConf(item.item_id)
        if itemConf and itemConf.type == type then
          table.insert(glassItemList, {
            item.item_id
          })
        end
      end
    end
  end
  return glassItemList
end

function AppearanceModule:OpenPigmentAcquirePanel(change_to_owned, bHiddenBtn)
  local glassTintList = {}
  for _, item in pairs(change_to_owned) do
    local bUnique = true
    for _, _item in pairs(glassTintList) do
      if item and _item and item.glass and _item.glass and item.glass.glass_value == _item.glass.glass_value and item.glass.glass_type == _item.glass.glass_type then
        bUnique = false
        break
      end
    end
    if bUnique then
      table.insert(glassTintList, item)
    end
  end
  local tabIndex, subTabIndex = self:GetDefaultTabIndexAndDefaultSubTabIndex(change_to_owned)
  self:OpenPanel("PigmentAcquire", glassTintList, bHiddenBtn, tabIndex, subTabIndex, self.claimGlassPetData)
end

function AppearanceModule:GetDefaultTabIndexAndDefaultSubTabIndex(change_to_owned)
  local tabType = _G.Enum.FashionLabelType.FLT_CLOTHES
  local subTabType
  for _, item in pairs(change_to_owned) do
    if item and item.fashion_item_id then
      local itemConf = _G.DataConfigManager:GetFashionItemConf(item.fashion_item_id)
      if itemConf then
        local type = itemConf.type
        if type == _G.Enum.FashionLabelType.FLT_DRESSES or type == _G.Enum.FashionLabelType.FLT_TOPS then
          subTabType = type
          break
        end
      end
    end
  end
  subTabType = subTabType or _G.Enum.FashionLabelType.FLT_HATS
  local tabIndex, subTabIndex
  local closetTabConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CLOSET_TAB_CONF)
  local closetTabTable = closetTabConf:GetAllDatas()
  for _, conf in pairs(closetTabTable) do
    if conf and conf.use_FashionLabelType then
      if conf.use_FashionLabelType == tabType then
        tabIndex = conf.rank_value
      elseif conf.use_FashionLabelType == subTabType then
        subTabIndex = conf.subrank_value
      end
      if tabIndex and subTabIndex then
        break
      end
    end
  end
  if tabIndex and subTabIndex then
    tabIndex = tabIndex - 1
    subTabIndex = subTabIndex - 1
  end
  return tabIndex, subTabIndex
end

function AppearanceModule:GetFashionItemGlassInfo(item_id)
  local isGlassItem = false
  local wearingGlassInfo, unlockedGlassInfo, claimableGlassInfo
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo then
    local wardrobeData = fashionInfo.wardrobe_data
    if wardrobeData then
      for _, singleWardrobeData in pairs(wardrobeData or {}) do
        if singleWardrobeData and singleWardrobeData.wearing_item then
          for _, wearingItem in pairs(singleWardrobeData.wearing_item or {}) do
            if wearingItem and wearingItem.wearing_item_id == item_id then
              wearingGlassInfo = wearingItem.wearing_glass
              if wearingGlassInfo then
                isGlassItem = true
              end
              break
            end
          end
        end
        if wearingGlassInfo then
          break
        end
      end
    end
    if not self.data.savedItemGlassMap then
      self:InitSavedItemGlassMap()
    end
    if self.data.savedItemGlassMap[item_id] then
      wearingGlassInfo = self.data.savedItemGlassMap[item_id]
      isGlassItem = true
    end
    local ownedItemInfo = fashionInfo.owned_item_info
    for _, item in pairs(ownedItemInfo or {}) do
      if item and item.item_id == item_id then
        if item.unlocked_glass and #item.unlocked_glass > 0 then
          isGlassItem = true
          unlockedGlassInfo = item.unlocked_glass
        end
        if item.claimable_glass and #item.claimable_glass > 0 then
          isGlassItem = true
          claimableGlassInfo = item.claimable_glass
        end
        break
      end
    end
  end
  return isGlassItem, wearingGlassInfo, unlockedGlassInfo, claimableGlassInfo
end

function AppearanceModule:CheckIsGlassSuit(suitId)
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if suitConf and fashionInfo then
    local suitFashionIds = suitConf.item_id
    local ownedItemInfo = fashionInfo.owned_item_info
    if suitFashionIds and #suitFashionIds > 0 then
      for _, item_id in pairs(suitFashionIds or {}) do
        for _, item in pairs(ownedItemInfo or {}) do
          if item and item.item_id == item_id then
            if item.unlocked_glass and #item.unlocked_glass > 0 then
              return true
            end
            if item.claimable_glass and #item.claimable_glass > 0 then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function AppearanceModule:UpdateOwnedGlassItemTabList()
  self.data.OwnedGlassItemTabList = {}
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo then
    local ownedItemInfo = fashionInfo.owned_item_info
    for _, item in pairs(ownedItemInfo or {}) do
      if item and item.unlocked_glass and #item.unlocked_glass > 0 then
        local itemConf = _G.DataConfigManager:GetFashionItemConf(item.item_id)
        if itemConf then
          table.insertUnique(self.data.OwnedGlassItemTabList, itemConf.type)
        end
      end
    end
  end
end

function AppearanceModule:GetOwnedGlassItemTabList()
  if not self.data.OwnedGlassItemTabList then
    self:UpdateOwnedGlassItemTabList()
  end
  return self.data.OwnedGlassItemTabList
end

function AppearanceModule:CheckItemGlass()
  if self:HasPanel("AppearanceCloset") then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:CheckNeedToShowGlassDetails()
    end
  end
end

function AppearanceModule:SetCurrentSelectItemInfo(itemInfo)
  self.data.curSelectItemInfo = itemInfo
  self:CheckItemGlass()
end

function AppearanceModule:GetCurrentSelectItemInfo()
  return self.data.curSelectItemInfo
end

function AppearanceModule:GetFashionIds(fashionItems)
  local fashionIds = {}
  for _, v in pairs(fashionItems or {}) do
    table.insert(fashionIds, v.wearing_item_id)
  end
  return fashionIds
end

function AppearanceModule:UpdateSavedItemGlassMap(wearing_item)
  for _, wearingItem in pairs(wearing_item or {}) do
    local wearingGlassInfo = wearingItem.wearing_glass
    if not self.data.savedItemGlassMap then
      self:InitSavedItemGlassMap()
    end
    self.data.savedItemGlassMap[wearingItem.wearing_item_id] = wearingGlassInfo
  end
end

function AppearanceModule:InitSavedItemGlassMap()
  self.data.savedItemGlassMap = {}
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo then
    local ownedItemInfo = fashionInfo.owned_item_info
    for _, item in pairs(ownedItemInfo or {}) do
      if item and item.default_glass and next(item.default_glass) then
        self.data.savedItemGlassMap[item.item_id] = item.default_glass
      end
    end
  end
end

function AppearanceModule:SetCurSelectedItemGlassMap(item_id, glass_info)
  if item_id and glass_info and glass_info.glass_type and glass_info.glass_value then
    self.data.curSelectedItemGlassMap[item_id] = glass_info
  elseif item_id and not glass_info then
    self.data.curSelectedItemGlassMap[item_id] = nil
  end
  if self:HasPanel("AppearanceCloset") then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:UpdateDazzling(item_id, glass_info)
    end
  end
end

function AppearanceModule:GetCurSelectedItemGlassMap(item_id)
  if item_id then
    return self.data.curSelectedItemGlassMap[item_id]
  end
  return nil
end

function AppearanceModule:InitCurSelectedItemGlassMap()
  self.data.curSelectedItemGlassMap = {}
  if not self.data.savedItemGlassMap then
    self:InitSavedItemGlassMap()
  end
  for item_id, glass_info in pairs(self.data.savedItemGlassMap or {}) do
    self.data.curSelectedItemGlassMap[item_id] = glass_info
  end
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if fashionInfo then
    local wardrobeData = fashionInfo.wardrobe_data
    if wardrobeData then
      for _, singleWardrobeData in pairs(wardrobeData or {}) do
        if singleWardrobeData.wearing_item then
          for _, wearingItem in pairs(singleWardrobeData.wearing_item or {}) do
            if wearingItem and wearingItem.wearing_item_id then
              self.data.curSelectedItemGlassMap[wearingItem.wearing_item_id] = wearingItem.wearing_glass
            end
          end
        end
      end
    end
  end
end

function AppearanceModule:UpdateCurClosetTabAfterGetGlassTint()
  if self:HasPanel("AppearanceCloset") then
    local panel = self:GetPanel("AppearanceCloset")
    if panel then
      panel:UpdateCurClosetTabAfterGetGlassTint()
    end
  end
end

function AppearanceModule:IsHeterochromeSuitClaimable(suitId)
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if not (suitConf and suitConf.suits_original_id and 0 ~= suitConf.suits_original_id and suitConf.bond_id) or 0 == suitConf.bond_id then
    return false
  end
  local bondItem = _G.DataModelMgr.PlayerDataModel:GetFashionBondItem(suitConf.bond_id)
  if not bondItem or not bondItem.color_suit_state then
    return false
  end
  return bondItem.color_suit_state == _G.Enum.FashionBondColorSuitState.FBCSS_CLAIMABLE
end

function AppearanceModule:OnPetFreeCheckHeterochromeSuit(rsp)
  if not rsp.pet_gid or 0 == #rsp.pet_gid then
    return
  end
  local removedPetData = {}
  if rsp.ret_info and rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    for k, v in ipairs(rsp.ret_info.goods_change_info.changes) do
      if v.type == _G.Enum.GoodsType.GT_PET then
        removedPetData[v.pet_data.gid] = v.pet_data
      end
    end
  end
  local extraRedDotKey = {}
  for i, gid in ipairs(rsp.pet_gid) do
    local petData = removedPetData[gid]
    if petData and 0 ~= petData.gid then
      local bFoundOtherShiningPet = false
      local petDatas = _G.DataModelMgr.PlayerDataModel:GetPetDatasByPetBaseId(petData.base_conf_id)
      for k, v in ipairs(petDatas) do
        if 0 ~= v.mutation_type & _G.Enum.MutationDiffType.MDT_SHINING and v.gid ~= gid then
          bFoundOtherShiningPet = true
          break
        end
      end
      if not bFoundOtherShiningPet then
        local bondId = 0
        local bond_id_list = _G.DataConfigManager:GetPetbaseUsedByFashionBond(petData.base_conf_id)
        if bond_id_list then
          local fashionbondlist = bond_id_list.fashion_bond_id
          if table.getTableCount(fashionbondlist) > 0 then
            bondId = fashionbondlist[1]
          end
        end
        if 0 ~= bondId then
          table.insert(extraRedDotKey, string.format("%s", bondId))
        end
      end
    end
  end
  if #extraRedDotKey > 0 then
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPointWithExtraKeyList, 467, extraRedDotKey)
  end
end

function AppearanceModule:OnCmdOpenTryOnByPackageId(packageId, suitId)
  if not packageId then
    Log.Error("AppearanceModule:OnCmdOpenTryOnByPackageId", "packageId is nil")
    return
  end
  local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(packageId)
  if not fashionPackageConf then
    Log.Error("AppearanceModule:OnCmdOpenTryOnByPackageId", "FASHION_PACKAGE_CONF not found for packageId:", packageId)
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    Log.Error("AppearanceModule:OnCmdOpenTryOnByPackageId", "player is nil")
    return
  end
  if fashionPackageConf.gender and fashionPackageConf.gender ~= player.gender then
    Log.Error("AppearanceModule:OnCmdOpenTryOnByPackageId", "package gender mismatch, package gender:", fashionPackageConf.gender, "player gender:", player.gender)
    return
  end
  local goodsId = self.data.packageIdToGoodsIdMap[packageId]
  if not goodsId then
    Log.Error("AppearanceModule:OnCmdOpenTryOnByPackageId", "goodsId not found for packageId:", packageId)
    return
  end
  local normalShopConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
  if not normalShopConf then
    Log.Error("AppearanceModule:OnCmdOpenTryOnByPackageId", "NORMAL_SHOP_CONF not found for goodsId:", goodsId)
    return
  end
  local shopId = AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG
  local reqShopData = {
    shopId = shopId,
    Caller = self,
    rspHandler = function(caller, rsp)
      caller:OnOpenTryOnByPackageIdRsp(packageId, goodsId, shopId, rsp, suitId)
    end,
    needModal = true,
    ignoreErrorTip = false,
    reqTag = "AppearanceModule:OnCmdOpenTryOnByPackageId"
  }
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
end

function AppearanceModule:OnOpenTryOnByPackageIdRsp(packageId, goodsId, shopId, rsp, suitId)
  if not rsp or not rsp.shop_data then
    Log.Error("AppearanceModule:OnOpenTryOnByPackageIdRsp", "rsp or shop_data is nil")
    return
  end
  local foundGoods
  if rsp.shop_data.goods_data then
    for idx, goodsData in ipairs(rsp.shop_data.goods_data) do
      if goodsData.goods_id == goodsId then
        foundGoods = goodsData
        break
      end
    end
  end
  if not foundGoods then
    Log.Warning("AppearanceModule:OnOpenTryOnByPackageIdRsp", "package is not available in shop, packageId:", packageId)
    local tipText = _G.DataConfigManager:GetLocalizationConf("fashion_package_not_available")
    if tipText and tipText.msg then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipText.msg)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\229\149\134\229\147\129\230\154\130\230\156\170\228\184\138\230\158\182")
    end
    return
  end
  local goodsExpireTime
  local normalShopConf = _G.DataConfigManager:GetNormalShopConf(goodsId)
  if normalShopConf and normalShopConf.disable_time then
    goodsExpireTime = ActivityUtils.ToTimestamp(normalShopConf.disable_time)
  end
  local itemData = {
    FashionPackageId = packageId,
    shopId = shopId,
    shopItemId = goodsId,
    shopLibId = goodsId,
    boughtNum = foundGoods.buy_num or 0,
    next_refresh_time = foundGoods.next_refresh_time,
    goodsExpireTime = goodsExpireTime
  }
  self:OnCmdOpenAppearanceTryOn(itemData, nil, nil, goodsExpireTime, suitId)
end

function AppearanceModule:OnCmdGetExchangeGoodsIdBySuitId(suitId)
  return self.data:GetExchangeGoodsIdBySuitId(suitId)
end

function AppearanceModule:OnEnterSceneFinishNtyAck(notify, isReconnecting, isEnteringCell, preMapId, mapID)
  if SceneUtils.IsInPikaShop() and (preMapId == mapID or self.bRestartFashionShowSequenceAtEnterSceneAck) then
    self:ReleaseFashionShowSequenceResource()
    if self.restartFashionShowId then
      _G.DelayManager:CancelDelayById(self.restartFashionShowId)
      self.restartFashionShowId = nil
    end
    self.restartFashionShowId = DelayManager:DelayFrames(3, function(appearanceModule)
      appearanceModule.bRestartFashionShowSequenceAtEnterSceneAck = false
      appearanceModule:ActiveFashionShowSequence()
    end, self)
  end
end

function AppearanceModule:AutoRemoveHelmetForHair()
  local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
  local hairConflicts = AppearanceUtils.GetConflictBodyTypes(UE4.EAvatarBodyType.Hair)
  if not hairConflicts or 0 == #hairConflicts then
    return
  end
  if self.data.TempAppearData then
    for k, v in ipairs(self.data.TempAppearData) do
      local existAvatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(v.FashionId)
      if existAvatarEnum then
        for _, conflictType in ipairs(hairConflicts) do
          if existAvatarEnum == conflictType then
            self:OnCmdSetClosetAppearance(v.FashionId, false)
            local hasCloset = self:HasPanel("AppearanceCloset")
            if hasCloset then
              local closetPanel = self:GetPanel("AppearanceCloset")
              if closetPanel then
                closetPanel:OnHelmetAutoRemoved()
              end
            end
            return
          end
        end
      end
    end
  end
end

function AppearanceModule:IsClosetAvatarWearingHelmet()
  local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
  local hairConflicts = AppearanceUtils.GetConflictBodyTypes(UE4.EAvatarBodyType.Hair)
  if not hairConflicts or 0 == #hairConflicts then
    return false
  end
  if self.data.TempAppearData then
    for k, v in ipairs(self.data.TempAppearData) do
      local existAvatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(v.FashionId)
      if existAvatarEnum then
        for _, conflictType in ipairs(hairConflicts) do
          if existAvatarEnum == conflictType then
            return true
          end
        end
      end
    end
  end
  return false
end

function AppearanceModule:RestoreHairSalonAfterHelmetRemoval()
  if not self.closetAvatarPlayer or not UE4.UObject.IsValid(self.closetAvatarPlayer) then
    return
  end
  if self.data.TempBeautyData then
  end
end

function AppearanceModule:GetExchangeVoucherIdBySuitId(suitId)
  return self.data:GetExchangeVoucherIdBySuitId(suitId)
end

function AppearanceModule:GetSuitIdByExchangeVoucherId(voucherId)
  return self.data:GetSuitIdByExchangeVoucherId(voucherId)
end

function AppearanceModule:OnCmdSetCurTopExclusionPanel(panelType)
  self.data:SetCurTopExclusionPanel(panelType)
end

function AppearanceModule:OnCmdGetCurTopExclusionPanel()
  return self.data:GetCurTopExclusionPanel()
end

function AppearanceModule:ShouldPopUpEvenConfirmUIDisabled(rsp)
  if not rsp or not rsp.shop_id then
    return false
  end
  local shopId = rsp.shop_id
  local shopConf = _G.DataConfigManager:GetShopConf(shopId)
  local shopType = shopConf and shopConf.shop_type
  if not shopType then
    return false
  end
  if shopType == Enum.ShopType.ST_FASHION_TAILOR then
    return false
  end
  return true
end

return AppearanceModule
