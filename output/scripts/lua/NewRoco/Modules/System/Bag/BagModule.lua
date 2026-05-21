local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local BagModuleUtils = require("NewRoco.Modules.System.Bag.BagModuleUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BagModule = NRCModuleBase:Extend("BagModule")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local TipsDisplayController = require("NewRoco.Modules.System.TipsModule.TipsDisplayController")
local TipsDisplayExecutor = require("NewRoco.Modules.System.TipsModule.TipsDisplayExecutor")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local PetUIModuleEnum = reload("NewRoco.Modules.System.PetUI.PetUIModuleEnum")

function BagModule:OnConstruct()
  _G.BagModuleCmd = reload("NewRoco.Modules.System.Bag.BagModuleCmd")
  _G.BagModuleUtils = reload("NewRoco.Modules.System.Bag.BagModuleUtils")
  self.data = self:SetData("BagModuleData", "NewRoco.Modules.System.Bag.BagModuleData")
  self:RegisterCmd(_G.BagModuleCmd.OpenBagMainPanel, self.OnCmdOpenBagMainPanel)
  self:RegisterCmd(_G.BagModuleCmd.OpenBagMainPanelByTableIndex, self.CmdOpenBagMainPanelByTableIndex)
  self:RegisterCmd(_G.BagModuleCmd.EnableBagMainPanel, self.EnableBagMainPanel)
  self:RegisterCmd(_G.BagModuleCmd.PreLoadBagMainPanel, self.PreLoadBagMainPanel)
  self:RegisterCmd(_G.BagModuleCmd.PetEnableBagMainPanel, self.PetEnableBagMainPanel)
  self:RegisterCmd(_G.BagModuleCmd.CloseBagMainPanel, self.OnCmdCloseBagMainPanel)
  self:RegisterCmd(_G.BagModuleCmd.SetBattleSelectItemData, self.OnCmdSetBattleSelectItemData)
  self:RegisterCmd(_G.BagModuleCmd.SendZoneGetBagReq, self.OnCmdZoneGetBagReq)
  self:RegisterCmd(_G.BagModuleCmd.SetSelectedItem, self.OnCmdSetSelectedItem)
  self:RegisterCmd(_G.BagModuleCmd.GetSelectedItem, self.OnCmdGetSelectedItem)
  self:RegisterCmd(_G.BagModuleCmd.OnSequenceSelected, self.OnCmdSequenceSelected)
  self:RegisterCmd(_G.BagModuleCmd.OnEquipStateChanged, self.OnCmdEquipStateChanged)
  self:RegisterCmd(_G.BagModuleCmd.UseBagItem, self.OnCmdZoneUseBagItemReq)
  self:RegisterCmd(_G.BagModuleCmd.UseBagItemExistParam, self.OnCmdZoneUseBagItemReqExistParam)
  self:RegisterCmd(_G.BagModuleCmd.UseMultiBagItem, self.OnCmdUseMultiBagItemReq)
  self:RegisterCmd(_G.BagModuleCmd.GetCurSelectItemType, self.GetItemType)
  self:RegisterCmd(_G.BagModuleCmd.GetCurEquipItemInfo, self.GetEquipItemInfo)
  self:RegisterCmd(_G.BagModuleCmd.GetEquipMagicInfo, self.GetEquipMagicInfo)
  self:RegisterCmd(_G.BagModuleCmd.SetCurEquipItemInfo, self.SetEquipItemInfo)
  self:RegisterCmd(_G.BagModuleCmd.SetEquipMagicInfo, self.SetEquipMagicInfo)
  self:RegisterCmd(_G.BagModuleCmd.SetPetSkillItemSelectedItem, self.OnCmdSetPetSkillItemSelectedItem)
  self:RegisterCmd(_G.BagModuleCmd.GetIsFirstOpenPanel, self.OnCmdGetIsFirstOpenPanel)
  self:RegisterCmd(_G.BagModuleCmd.GetBagItemByID, self.OnGetBagItemByID)
  self:RegisterCmd(_G.BagModuleCmd.UpdateBagItemNumByID, self.OnCmdUpdateBagItemNumByID)
  self:RegisterCmd(_G.BagModuleCmd.GetCanFeedItem, self.OnGetCanFeedItem)
  self:RegisterCmd(_G.BagModuleCmd.GetBagItemArrayByType, self.OnGetBagItemArrayByType)
  self:RegisterCmd(_G.BagModuleCmd.GetBagItemNumByType, self.OnGetBagItemNumByType)
  self:RegisterCmd(_G.BagModuleCmd.GetNPCMapping, self.GetNPCMapping)
  self:RegisterCmd(_G.BagModuleCmd.CheckHasBagItemByType, self.CheckHasBagItemByType)
  self:RegisterCmd(_G.BagModuleCmd.GetBagItemByGid, self.OnGetBagItemByGid)
  self:RegisterCmd(_G.BagModuleCmd.UpdateEquipItemInfoClient, self.UpdateBallItemInfoClient)
  self:RegisterCmd(_G.BagModuleCmd.GetBagItemArrayByLableType, self.OnCmdGetBagItemArrayByLableType)
  self:RegisterCmd(_G.BagModuleCmd.GetBagEggItemWithoutHathcing, self.OnCmdGetBagEggItemWithoutHathcing)
  self:RegisterCmd(_G.BagModuleCmd.SetBagItemArrayFromBagInfo, self.OnCmdSetBagItemArrayFromBagInfo)
  self:RegisterCmd(_G.BagModuleCmd.GetEquipBallList, self.OnCmdGetEquipBallList)
  self:RegisterCmd(_G.BagModuleCmd.ChangeBall, self.OnCmdChangeBall)
  self:RegisterCmd(_G.BagModuleCmd.OpenBagPopUp, self.OnCmdOpenBagPopUp)
  self:RegisterCmd(_G.BagModuleCmd.SetIsCanCloseBagPopUp, self.OnCmdSetIsCanCloseBagPopUp)
  self:RegisterCmd(_G.BagModuleCmd.OpenCommonPopUp, self.OnCmdOpenCommonPopUp)
  self:RegisterCmd(_G.BagModuleCmd.SelectCommonPetHeadPicture, self.OnCmdSelectCommonPetHeadPicture)
  self:RegisterCmd(_G.BagModuleCmd.GetMedalListAndWearMedalByPetGid, self.OnCmdGetMedalListAndWearMedalByPetGid)
  self:RegisterCmd(_G.BagModuleCmd.CloseBagPopUp, self.OnCmdCloseBagPopUp)
  self:RegisterCmd(_G.BagModuleCmd.SetIsFirstAcquisitionMagic, self.OnCmdSetIsFirstAcquisitionMagic)
  self:RegisterCmd(_G.BagModuleCmd.GetIsFirstAcquisitionMagic, self.OnCmdGetIsFirstAcquisitionMagic)
  self:RegisterCmd(_G.BagModuleCmd.SetBagChangeInfo, self.OnCmdSetBagChangeInfo)
  self:RegisterCmd(_G.BagModuleCmd.EquipProtagonistMagicStateChanged, self.OnCmdEquipProtagonistMagicStateChanged)
  self:RegisterCmd(_G.BagModuleCmd.GetEquipedPlayerSkill, self.OnCmdGetEquipedPlayerSkill)
  self:RegisterCmd(_G.BagModuleCmd.OpenBXTips, self.OnCmdOpenBXTips)
  self:RegisterCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.OpenOrCloseCharacterPanelToList)
  self:RegisterCmd(_G.BagModuleCmd.CloseBXTips, self.OnCmdCloseBXTips)
  self:RegisterCmd(_G.BagModuleCmd.OpenChooseItemPanel, self.OnCmdOpenChooseItemPanel)
  self:RegisterCmd(_G.BagModuleCmd.ClearBattleInfo, self.OnCmdClearBattleInfo)
  self:RegisterCmd(_G.BagModuleCmd.OpenHatchTips, self.OnCmdOpenHatchTips)
  self:RegisterCmd(_G.BagModuleCmd.SetCurSelectEggItemData, self.OnCmdSetCurSelectEggItemData)
  self:RegisterCmd(_G.BagModuleCmd.OpenBagScreenPanel, self.OnCmdOpenBagScreenPanel)
  self:RegisterCmd(_G.BagModuleCmd.OpenBagSortPanel, self.OnCmdOpenBagSortPanel)
  self:RegisterCmd(_G.BagModuleCmd.ReversalBagSort, self.OnCmdReversalBagSort)
  self:RegisterCmd(_G.BagModuleCmd.TestEquipBall, self.TestEquipBall)
  self:RegisterCmd(_G.BagModuleCmd.SortEquipBall, self.OnCmdSortEquipBall)
  self:RegisterCmd(_G.BagModuleCmd.SetTableSortSelectIndex, self.OnCmdSetSortSelectIndex)
  self:RegisterCmd(_G.BagModuleCmd.GetTableSortSelectIndex, self.OnCmdGetSortSelectIndex)
  self:RegisterCmd(_G.BagModuleCmd.OpenSwapEggsUI, self.OnCmdOpenSwapEggsUI)
  self:RegisterCmd(_G.BagModuleCmd.CanUseSkillMachine, self.CmdCanUseSkillMachine)
  self:RegisterCmd(_G.BagModuleCmd.GetCanUseBagItemByItemId, self.CmdGetCanUseBagItemByItemId)
  self:RegisterCmd(_G.BagModuleCmd.SetIsPetInfoMainToPanel, self.CmdSetIsPetInfoMainToPanel)
  self:RegisterCmd(_G.BagModuleCmd.OpenFilterPanel, self.CmdOpenFilterPanel)
  self:RegisterCmd(_G.BagModuleCmd.GetBagItemEquipIndexByGid, self.OnCmdGetBagItemEquipIndexByGid)
  self:RegisterCmd(_G.BagModuleCmd.SetBagItemClickAble, self.OnCmdSetBagItemClickAble)
  self:RegisterCmd(_G.BagModuleCmd.OpenNPCRoster, self.OnCmdOpenNPCRoster)
  self:RegisterCmd(_G.BagModuleCmd.OpenMagicBook, self.OnCmdOpenMagicBook)
  self:RegisterCmd(_G.BagModuleCmd.GetRosterData, self.OnCmdGetRosterData)
  self:RegisterCmd(_G.BagModuleCmd.OpenNPCRosterTip, self.OnCmdOpenNPCRosterTips)
  self:RegisterCmd(_G.BagModuleCmd.ShowDescPanel, self.OnCmdShowDescPanel)
  self:RegisterCmd(_G.BagModuleCmd.HideDescPanel, self.OnCmdHideDescPanel)
  self:RegisterCmd(_G.BagModuleCmd.ShowCloseBtnPanel, self.OnCmdShowCloseBtnPanel)
  self:RegisterCmd(_G.BagModuleCmd.FilterPet, self.OnCmdFilterPet)
  self:RegisterCmd(_G.BagModuleCmd.FilterDepart, self.OnCmdFilterDepart)
  self:RegisterCmd(_G.BagModuleCmd.FilterClassify, self.OnCmdFilterClassify)
  self:RegisterCmd(_G.BagModuleCmd.FilterSkillStone, self.OnCmdFilterSkillStone)
  self:RegisterCmd(_G.BagModuleCmd.OpenEvolutionarySelectPanel, self.OnCmdOpenEvolutionarySelectPanel)
  self:RegisterCmd(_G.BagModuleCmd.SetEvolutionarySelectedItem, self.OnCmdSetEvolutionarySelectedItem)
  self:RegisterCmd(_G.BagModuleCmd.OpenEvolutionaryUsePanel, self.OnCmdOpenEvolutionaryUsePanel)
  self:RegisterCmd(_G.BagModuleCmd.UseEvolutionaryItem, self.OnCmdUseEvolutionaryItem)
  self:RegisterCmd(_G.BagModuleCmd.OpenEvolutionarySuccessPanel, self.OnCmdOpenEvolutionarySuccessPanel)
  self:RegisterCmd(_G.BagModuleCmd.OpenBagBright, self.OnCmdOpenBagBright)
  self:RegisterCmd(_G.BagModuleCmd.TestOpenHatchPanel, self.OnCmdTestOpenHatchPanel)
  self:RegisterCmd(_G.BagModuleCmd.OpenBagUsePopupSuccessPanel, self.OnCmdOpenBagUsePopupSuccessPanel)
  self:RegisterCmd(_G.BagModuleCmd.OpenTalentPopupSuccessPanel, self.OnCmdOpenTalentPopupSuccessPanel)
  self:RegisterCmd(_G.BagModuleCmd.OpenCharacterPopupSuccessPanel, self.OnCmdOpenCharacterPopupSuccessPanel)
  self:RegisterCmd(_G.BagModuleCmd.OpenGiftVoucherSharing, self.OnCmdOpenGiftVoucherSharing)
  self:RegisterCmd(_G.BagModuleCmd.CloseGiftVoucherSharing, self.OnCmdCloseGiftVoucherSharing)
  self:RegisterCmd(_G.BagModuleCmd.OnCmdGetTypeBagItem, self.OnCmdGetTypeBagItem)
  self:RegisterCmd(_G.BagModuleCmd.GetBagBloodIsSelected, self.OnCmdGetBagBloodIsSelected)
  self:RegisterCmd(_G.BagModuleCmd.CheckHadUseBall, self.OnCmdCheckHadUseBall)
  self:RegisterCmd(_G.BagModuleCmd.OpenCulturalActivitiesShaer, self.OnCmdOpenCulturalActivitiesShaer)
  self:RegisterCmd(_G.BagModuleCmd.OpenCulturalActivitiesTips, self.OnCmdOpenCulturalActivitiesTips)
  self:RegisterCmd(_G.BagModuleCmd.OnSetEggIconFinished, self.OnCmdOnSetEggIconFinished)
  self:RegisterCmd(_G.BagModuleCmd.OnZoneUpdateBagItemIdFlagReq, self.OnCmdOnZoneUpdateBagItemIdFlagReq)
  self:RegisterCmd(_G.BagModuleCmd.CheckBallIsCollectOptimization, self.OnCheckBallIsCollectOptimization)
  self:RegisterCmd(_G.BagModuleCmd.GetBallNormalSortList, self.OnCmdGetBallNormalSortList)
  self:RegisterCmd(_G.BagModuleCmd.CheckIsSpeciesMedal, self.OnCmdCheckIsSpeciesMedal)
  self:RegisterCmd(_G.BagModuleCmd.GetOriginalPet, self.OnCmdGetOriginalPet)
  self:RegisterCmd(_G.BagModuleCmd.OpenBagExpiredItemsConversion, self.OnCmdOpenBagExpiredItemsConversion)
  self:RegisterCmd(_G.BagModuleCmd.ZoneBagItemExpireCheckReq, self.OnCmdSendZoneCheckBagItemExpireReq)
  self:RegPanel("BagMain", "UMG_Bag", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "open", "close", nil)
  self:RegPanel("BagPopUp", "UMG_Bag_PopUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Bag_CommonPopUp", "UMG_Bag_CommonPopUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Bag_AwardMedal", "UMG_Bag_AwardMedal", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BXTips", "UMG_Bag_BXTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetCharacterTips", "UMG_PetCharacter", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetCharacterPopUp", "UMG_PetCharacter_PopUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("CharacterPopupSuccessPanel", "UMG_PetCharacter_PopUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetAttributePopUp", "UMG_PetAttribute", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BagTips", "UMG_BagTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Hatch", "UMG_Bag_Hatch", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BagSort", "UMG_BagSort", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BagScreen", "UMG_BagScreen", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("SwapEggs", "UMG_SwapEggs", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("BagBright", "UseTalent/UMG_BagBright", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("TalentPopup", "UseTalent/UMG_Talent_Popup", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BagTalentSuccessPopup", "UseTalent/UMG_Talent_Popup", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("TalentChange", "UseTalent/UMG_TalentChange", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BagBlood", "UseBlood/UMG_BagUseItemPanel", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BagBloodPopup", "UseBlood/UMG_BagUse_PopUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BagBloodSuccessPopup", "UseBlood/UMG_BagUse_PopUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BagBloodChange", "UseBlood/UMG_BagChangeSelect", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MagicBook", "MagicBook/UMG_MagicBook", _G.Enum.UILayerType.UI_LAYER_POPUP, nil)
  self:RegPanel("Roster", "MagicBook/UMG_Roster", _G.Enum.UILayerType.UI_LAYER_POPUP, nil)
  self:RegPanel("NPCRosterTip", "MagicBook/UMG_MagicBookTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "Appear", "Disappear", true, true):SetEnableTouchMask(false)
  self:RegPanel("EvolutionaryAgentUse", "Nightmare/UMG_EvolutionaryAgentUse", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UMG_FurnitureScreening", "UMG_FurnitureScreening", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UMG_FurnitureDisassemblyPanel", "UMG_FurnitureDisassemblyPanel", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UMG_GiftVoucherSharing", "UMG_GiftVoucherSharing", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UniversalTips", "UMG_BagGiftTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "Page_Out", true, true)
  self:RegPanel("UMG_CulturalActivitiesShaer", "CulturalActivities/UMG_CulturalActivities_Share", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegPanel("UMG_CulturalActivitiesTips", "CulturalActivities/UMG_CulturalActivities_PopUp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("BagExpiredItemsConversion", "UMG_Bag_ExpiredItemsConversion", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self.NPCMap = {}
  self.totalNum = {}
  self.MagicId = 100701
  self.CharacterPanelList = {}
  self.IsWaitChangeRsp = false
  self.IsPetInfoMainToPanel = false
  self.WaitGetBagInfoRspSuccess = false
  self.TotalBagInfo = nil
  self.changePetGid = nil
  self.getUniversalTipsController = TipsDisplayController(TipEnum.TipObjectType.ReceiveBPGiftTips, self, self.OnPlayUniversalTips)
  self.tipDisplayExecutor = TipsDisplayExecutor():Attach(self, self.OnPlayTips, nil, self.OnAllTipsFinished, self.OnTipDisplayStatusChange)
  self.tipDisplayExecutor:StartTipDispatchStateListener()
  self.tipDisplayExecutor:EnableTipSort(function(a, b)
    return a.customData.npcID < b.customData.npcID
  end)
end

function BagModule:OnActive()
  if not self.initSend then
    self:ZoneGetBagItemInfoByPageReq(1)
  end
  _G.NRCEventCenter:RegisterEvent("BagModule", self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.OnBagChange)
  _G.NRCEventCenter:RegisterEvent("BagModule", self, BagModuleEvent.GoodChangeTypeEnum.GT_BAG_BACKPACK, self.OnBagBackPackChange)
  _G.NRCEventCenter:RegisterEvent("BagModule", self, BagModuleEvent.GoodChangeTypeEnum.GT_PET, self.OnPetChange)
  _G.NRCEventCenter:RegisterEvent("BagModule", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
  NRCEventCenter:RegisterEvent("BagModule", self, SceneEvent.LoadMapStart, self.ChangeScene)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_MAGE_BOOK_NOTIFY, self.OnGetNewNPC)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BAG_ITEM_LIMIT_NOTIFY, self.OnZoneBagItemLimitNotify)
  self:InitNPCMapping()
end

function BagModule:OnZoneBagItemLimitNotify(Notify)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2291, nil, nil, nil, nil, true)
end

function BagModule:ChangeScene()
  local hasPanel = self:HasPanel("BagMain")
  if hasPanel then
    local panel = self:GetPanel("BagMain")
    if panel then
      panel:OnCloseButtonClicked()
    end
  end
end

function BagModule:TestEquipBall()
  for i = 1, #self.data.CurEquipBallIdxList do
    local itemInfo = self:OnGetBagItemByGid(self.data.CurEquipBallIdxList[i].gid)
    local name = _G.DataConfigManager:GetBagItemConf(itemInfo.id).name
    Log.Error("\229\144\142\229\143\176\229\183\178\232\163\133\229\164\135\229\146\149\229\153\156\231\144\131\239\188\154" .. name, self.data.CurEquipBallIdxList[i].idx)
  end
  for i = 1, #self.data.EquipBallList do
    local itemInfo = self.data.EquipBallList[i]
    local name = _G.DataConfigManager:GetBagItemConf(itemInfo.id).name
    Log.Error("\229\137\141\229\143\176\229\183\178\232\163\133\229\164\135\229\146\149\229\153\156\231\144\131\239\188\154" .. name)
  end
end

function BagModule:OnDeactive()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.OnBagChange)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_PET, self.OnPetChange)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_BAG_BACKPACK, self.OnBagBackPackChange)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_MAGE_BOOK_NOTIFY, self.OnGetNewNPC)
  self.NPCMap = {}
end

function BagModule:OnDestruct()
end

function BagModule:OnAddEventListener()
end

function BagModule:OnRemoveEventListener()
end

function BagModule:OnBagBackPackChange(BackpackInfo, CmdId)
  if nil == BackpackInfo then
    return
  end
  if self.data and self.data.BagInfo then
    self.data.BagInfo.bag_backpack = BackpackInfo
  end
  self.data:SetEquipBallList(BackpackInfo.ball_list)
end

function BagModule:OnCmdOpenBagMainPanel(displayMode, itemconf, PetOpenUseAction)
  self:OpenPanel("BagMain", itemconf)
  self.data:SetDisplayMode(displayMode)
  self.PetOpenUseAction = PetOpenUseAction
end

function BagModule:CmdOpenBagMainPanelByTableIndex(Index, BagItemID)
  if BagItemID then
    local BagItem = self:OnGetBagItemByID(BagItemID)
    if BagItem and BagItem.num > 0 then
      local BagItemConf = _G.DataConfigManager:GetBagItemConf(BagItemID)
      if BagItemConf then
        self:OpenPanel("BagMain", BagItemConf)
        return
      end
    end
  end
  Index = Index and tonumber(Index)
  self:OpenPanel("BagMain", nil, nil, Index)
end

function BagModule:EnableBagMainPanel()
  if self:HasPanel("BagMain") then
    local Panel = self:GetPanel("BagMain")
    Panel:EnableAndShouldBanWorldRendering()
  end
end

function BagModule:PreLoadBagMainPanel()
  self:PreLoadPanel("BagMain", 10)
end

function BagModule:PetEnableBagMainPanel(itemconf, DisplayMode, PetOpenUseAction)
  if self:HasPanel("BagMain") then
    self.data:SetCurSelectedItemData(nil)
    local Panel = self:GetPanel("BagMain")
    self.PetOpenUseAction = PetOpenUseAction
    self.data:SetDisplayMode(DisplayMode)
    Panel:OnActive(itemconf, false)
    Panel:EnableAndShouldBanWorldRendering()
  end
end

function BagModule:OnCmdCloseBagMainPanel()
  if self:HasPanel("BagMain") then
    if self.IsPetInfoMainToPanel then
      local panel = self:GetPanel("BagMain")
      if panel then
        panel:OnCloseButtonClicked()
      end
    else
      local panel = self:GetPanel("BagMain")
      if panel then
        panel:OnCloseButtonClicked()
      end
    end
  end
end

function BagModule:OnCmdSetBattleSelectItemData(data)
  self.data:SetCurSelectedItemDataBattle(data)
end

function BagModule:OnCmdSetPetSkillItemSelectedItem(data)
  self.data:SetCurSelectedPetSkillItemData(data)
end

function BagModule:OnCmdGetIsFirstOpenPanel()
  return self.data:GetIsFirstOpenPanel()
end

function BagModule:OnEnterSceneFinishNtyAckCallBack(notify, isReconnecting, isEnteringCell)
  if isEnteringCell or isReconnecting then
    self:ZoneGetBagItemInfoByPageReq(1)
  end
end

function BagModule:TryGetBagInfo()
  if not self.WaitGetBagInfoRspSuccess then
    self.BagItemInfoVersion = nil
    self:ZoneGetBagItemInfoByPageReq(1)
  end
end

function BagModule:SetBagItemInfoVersion(version)
  self.BagItemInfoVersion = version
end

function BagModule:ZoneGetBagItemInfoByPageReq(page)
  page = page or 1
  if 1 == page then
    self.GetTotalBagInfoSuccess = false
  end
  self.WaitGetBagInfoRspSuccess = false
  self.page = page
  local req = _G.ProtoMessage:newZoneGetBagItemInfoByPageReq()
  req.page = page
  if self.BagItemInfoVersion then
    req.version = self.BagItemInfoVersion
  end
  _G.NRCProfilerLog:NRCProtoReqAndRspInterval(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_ITEM_INFO_BY_PAGE_REQ, true, "BagMain")
  self.initSend = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_ITEM_INFO_BY_PAGE_REQ, req, self, self.ZoneGetBagItemInfoByPageRsp)
end

function BagModule:ZoneGetBagItemInfoByPageRsp(rsp)
  _G.NRCProfilerLog:NRCProtoReqAndRspInterval(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_ITEM_INFO_BY_PAGE_REQ, false, "BagMain")
  if 0 == rsp.ret_info.ret_code then
    if rsp.version and 0 ~= rsp.version then
      self.BagItemInfoVersion = rsp.version
    end
    if rsp.no_new_data and 0 ~= rsp.no_new_data then
      if not self.GetTotalBagInfoSuccess then
        self.page = 1
        self.BagItemInfoVersion = 0
        self.TotalBagInfo = nil
        self:ZoneGetBagItemInfoByPageReq(self.page)
      end
      return
    end
    if not self.TotalBagInfo then
      self.TotalBagInfo = rsp.bag_info
      if not self.TotalBagInfo.item_list then
        self.TotalBagInfo.item_list = {}
      end
      self.NewPage = 1
    else
      if self.NewPage + 1 ~= rsp.req_page then
        return
      end
      for i, BagItem in ipairs(rsp.bag_info.item_list) do
        local IsHasItemList = false
        for j = #self.TotalBagInfo.item_list, 1, -1 do
          if BagItem and BagItem.type == self.TotalBagInfo.item_list[j].type then
            IsHasItemList = true
            if not BagItem.items then
              Log.Debug("BagModule:ZoneGetBagItemInfoByPageRsp Not_Items", BagItem.type)
            end
            if BagItem.items then
              for k, Item in ipairs(BagItem.items) do
                table.insert(self.TotalBagInfo.item_list[j].items, Item)
              end
            end
          end
        end
        if not IsHasItemList then
          table.insert(self.TotalBagInfo.item_list, BagItem)
        end
      end
      self.NewPage = self.NewPage + 1
    end
    if rsp.req_page < rsp.total_page then
      self:ZoneGetBagItemInfoByPageReq(rsp.req_page + 1)
    else
      self.WaitGetBagInfoRspSuccess = true
      self.GetTotalBagInfoSuccess = true
      self.data:SetBagInfo(self.TotalBagInfo)
      self:DispatchEvent(BagModuleEvent.RefreshBagInfo)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipItemInfo, false)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipMagicItemInfo, false)
      self.page = 1
      self.TotalBagInfo = nil
      self.NewPage = 1
    end
  else
    Log.Error("\233\148\153\232\175\175\231\160\129\228\184\186:", rsp.ret_info.ret_code)
  end
end

function BagModule:OnCmdZoneGetBagReq()
  local req = _G.ProtoMessage:newZoneGetBagReq()
  _G.NRCProfilerLog:NRCProtoReqAndRspInterval(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_REQ, true, "BagMain")
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_REQ, req, self, self.ZoneGetBagRsp)
  self:DispatchEvent(BagModuleEvent.OpenGetRewardPanel)
end

function BagModule:ZoneGetBagRsp(rsp)
  _G.NRCProfilerLog:NRCProtoReqAndRspInterval(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_REQ, false, "BagMain")
  if 0 == rsp.ret_info.ret_code then
    if not rsp.bag_info.item_list then
      rsp.bag_info.item_list = {}
    end
    self.data:SetBagInfo(rsp.bag_info)
    self:DispatchEvent(BagModuleEvent.RefreshBagInfo, rsp)
  end
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipItemInfo, false)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipMagicItemInfo, false)
end

function BagModule:OnCmdGetTypeBagItem(type)
  local req = ProtoMessage:newZoneGetBagReq()
  req.type = type
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_REQ, req, self, self.OnCmdGetTypeBagItemRsp)
end

function BagModule:OnCmdGetTypeBagItemRsp(rsp)
  if rsp.ret_info and rsp.ret_info.ret_code ~= nil then
    if 0 == rsp.ret_info.ret_code then
      _G.NRCEventCenter:DispatchEvent(BagModuleEvent.RefreshTypeItemInfo, rsp)
      return
    else
      Log.Error("OnCmdGetTypeBagItemRsp failed, ret_code: ", rsp.ret_info.ret_code)
    end
  end
  Log.Error("OnCmdGetTypeBagItemRsp with invalid rsp")
end

function BagModule:IsOnlyOnePetBall()
  local clientBagInfo = self.data.BagInfo
  for i = 1, #clientBagInfo.item_list do
    if clientBagInfo.item_list[i].type == _G.ProtoEnum.BagItemType.BI_PET_BALL and clientBagInfo.item_list[i].items ~= nil then
      local PetBallCount = #clientBagInfo.item_list[i].items
      if 1 == PetBallCount then
        self:SetEquipItemInfo(clientBagInfo.item_list[i].items[1])
        break
      end
    end
  end
end

function BagModule:OnCmdUseMultiBagItemReq(UseItemList)
  local req = _G.ProtoMessage:newZoneUseMultiBagItemReq()
  req.item_info = UseItemList
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_USE_MULTI_BAG_ITEM_REQ, req, self, self.OnZoneUseMultiBagItemRsp)
end

function BagModule:OnZoneUseMultiBagItemRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    NRCEventCenter:DispatchEvent(PetUIModuleEvent.RefreshAdjustPetPanel)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseAllPetShareTeamDiffPanel)
  end
end

function BagModule:OnCmdZoneUseBagItemReqExistParam(Param)
  local gid = Param.gid
  local id = Param.id
  local num = Param.num
  local para = Param.para
  local change_attr_type = Param.change_attr_type
  local target_type = Param.target_type
  local change_talent_type = Param.change_talent_type
  local result_type = Param.result_type
  local para2 = Param.para2
  self.UseBagItemRspParam = Param.RspParam
  local extraParam = {}
  extraParam.change_attr_type = change_attr_type
  extraParam.target_type = target_type
  extraParam.change_talent_type = change_talent_type
  extraParam.result_type = result_type
  extraParam.para2 = para2
  self:OnCmdZoneUseBagItemReq(gid, id, num, para, extraParam)
end

function BagModule:OnCmdZoneUseBagItemReq(gid, id, num, para, extraParam)
  local req = _G.ProtoMessage:newZoneUseBagItemReq()
  req.gid = gid
  req.item_conf_id = id
  req.num = num
  req.para = para
  if extraParam then
    req.para2 = extraParam.para2
    if extraParam.change_attr_type then
      req.change_attr_type = extraParam.change_attr_type
    end
    if extraParam.target_type then
      req.target_type = extraParam.target_type
    end
    if extraParam.change_talent_type then
      req.change_talent_type = extraParam.change_talent_type
    end
    if extraParam.result_type then
      req.result_type = extraParam.result_type
    end
  end
  self.useBagItemReqExtraParam = extraParam
  self.num = num
  self.id = id
  self.para = para
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_USE_BAG_ITEM_REQ, req, self, self.ZoneUseBagItemRsp, true)
end

function BagModule:ZoneUseBagItemRsp(rsp)
  if self.IsWaitChangeRsp then
    self.IsWaitChangeRsp = false
  end
  if 0 == rsp.ret_info.ret_code then
    local useBagItemRspParam = self.useBagItemReqExtraParam
    if useBagItemRspParam and useBagItemRspParam.callback then
      local ok, msg = pcall(useBagItemRspParam.callback, rsp)
      if not ok then
        Log.Error(msg)
      end
    end
    self.data.Canfilter = true
    table.clear(self.CharacterPanelList)
    self:ClosePanel("BagTips")
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetDataRedPoint)
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(rsp.use_bag_id)
    local bValidItemBehavior_1 = bagItemInfo and bagItemInfo.item_behavior and not not bagItemInfo.item_behavior[1]
    if self.UseBagItemRspParam then
      local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.UseBagItemRspParam.gid)
      local BagItem = {
        id = self.UseBagItemRspParam.ItemConfId
      }
      local changeType = self.UseBagItemRspParam.changeType
      if bValidItemBehavior_1 then
        if bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT then
          self:OnCmdOpenTalentPopupSuccessPanel(PetData, BagItem, nil, changeType)
        end
        if bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_NATURE_EFFECT then
          self:OnCmdOpenCharacterPopupSuccessPanel(PetData, BagItem)
        end
      end
      self.UseBagItemRspParam = nil
    end
    if bValidItemBehavior_1 and (bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_TALENT or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_NATURE_EFFECT or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_ALL_NATURE or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC) then
      NRCEventCenter:DispatchEvent(PetUIModuleEvent.RefreshAdjustPetPanel)
    end
    if bValidItemBehavior_1 and (not useBagItemRspParam or not useBagItemRspParam.disableRewardsPanel) then
      if rsp.reward and rsp.reward.rewards and #rsp.reward.rewards > 0 and bagItemInfo.item_behavior[1].use_action ~= _G.Enum.ItemBehavior.IB_CHANGE_BLOOD and bagItemInfo.item_behavior[1].use_action ~= _G.Enum.ItemBehavior.IB_GIVE_MEDAL then
        local itemInfos = {}
        local rewards = rsp.reward.rewards
        for _, v in ipairs(rewards) do
          local itemId = v.id
          table.insert(itemInfos, {
            id = itemId,
            num = v.num,
            type = v.type
          })
        end
        if #itemInfos > 0 then
          _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, itemInfos)
        end
      elseif rsp.ret_info and rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 and bagItemInfo.item_behavior[1].use_action ~= _G.Enum.ItemBehavior.IB_CHANGE_BLOOD and bagItemInfo.item_behavior[1].use_action ~= _G.Enum.ItemBehavior.IB_GIVE_MEDAL then
        local itemInfos = {}
        local rewards = rsp.ret_info.goods_reward.rewards
        for _, v in ipairs(rewards) do
          local itemId = v.id
          table.insert(itemInfos, {
            id = itemId,
            num = v.num,
            type = v.type
          })
        end
        if not self:IsUnlockBP(bagItemInfo) and #itemInfos > 0 then
          local suitInfo = self:CheckRewardsContainFashionSuit(rewards)
          if suitInfo then
            self:ShowFashionSuitRewardPopup(suitInfo, rewards, rsp)
          else
            _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, itemInfos)
          end
        end
      end
    end
    if self:IsUnlockBP(bagItemInfo) then
      self:DoUnlockBP(rsp)
    end
    if self:HasPanel("BagPopUp") then
      local panel = self:GetPanel("BagPopUp")
      panel:OnUseItemRsp(rsp.use_bag_id)
    end
    if self:HasPanel("PetCharacterPopUp") then
      if self.data.PetCharacterItem then
        local panel = self:GetPanel("PetCharacterPopUp")
        panel:SetPanelInfo(true)
      end
    elseif self.data.PetCharacterItem then
      self:OpenPanel("PetCharacterPopUp", true, nil, rsp.use_bag_id)
    end
    if self.changePetGid then
      self:GetChangePetData(rsp.ret_info.goods_change_info.changes)
    end
    if self:HasPanel("TalentPopup") then
      if self.data.PetTalentItem then
        local panel = self:GetPanel("TalentPopup")
        panel:SetUseSuccess()
      end
    elseif self.data.PetTalentItem then
      self:OpenPanel("TalentPopup", true, rsp.use_bag_id)
    end
    if self:HasPanel("BagBloodPopup") then
      if self.data.PetBloodItem then
        local panel = self:GetPanel("BagBloodPopup")
        panel:SetUseSuccess()
      end
    elseif self.data.PetBloodItem then
      self:OpenPanel("BagBloodPopup", true)
    end
    if self.data.displayMode == BagModuleEnum.DisplayMode.SkillMachine then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.RefreshPetRightPanel)
    end
    if bagItemInfo.lable_type == Enum.ItemLableType.ILT_PET_EGG and self.data.CacheHatchEggItem then
      if self:HasPanel("BagMain") and _G.NRCPanelManager:CheckFullScreenPanelIsShowTop("BagMain") then
        local info = self.data.CacheHatchEggItem
        if self:HasPanel("Hatch") then
        else
          self:OpenPanel("Hatch", info)
        end
      else
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.UpdateHatchingRightPanel)
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetHatchingPanel, self.data.CacheHatchEggItem.gid, true)
      end
    elseif bagItemInfo.lable_type == Enum.ItemLableType.ILT_PRECIOUS and bagItemInfo.type == Enum.BagItemType.BI_GLASS_EGG_PIECE then
      if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
        for _, change in ipairs(rsp.ret_info.goods_change_info.changes) do
          if change.bag_item and change.bag_item.egg_data and change.bag_item.gid then
            _G.NRCModuleManager:DoCmd(PetUIModuleCmd.UpdateHatchingRightPanel)
            _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetHatchingPanel, change.bag_item.gid, true)
            break
          end
        end
      end
    elseif bagItemInfo.lable_type == Enum.ItemLableType.ILT_PRECIOUS and bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_PET_HATCH_PROCESS_ADD and rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
      for _, change in ipairs(rsp.ret_info.goods_change_info.changes) do
        if change.bag_item and change.bag_item.egg_data and change.bag_item.gid then
          _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseHatchingRightPanel, PetUIModuleEnum.PetHatchingRightPanelCloseReasonType.UsedIncubationProgressItem)
          _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnUsedIncubationProgressItemSuccess, change.bag_item.gid, change.bag_item.egg_data.hatched_secs)
          if self.id and self.num then
            local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.id)
            if BagItemConf and BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].use_action and BagItemConf.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_PET_HATCH_PROCESS_ADD and BagItemConf.item_behavior[1].ratio and BagItemConf.item_behavior[1].ratio[1] and BagItemConf.item_behavior[1].ratio[1] > 0 then
              local ItemAddProgressPercent = BagItemConf.item_behavior[1].ratio[1]
              if ItemAddProgressPercent and 0 ~= ItemAddProgressPercent then
                local AllPercent = ItemAddProgressPercent * self.num
                _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.HatchProgressAdd_4, AllPercent))
              end
              self.id = nil
              self.num = nil
            end
          end
          break
        end
      end
    end
    if bValidItemBehavior_1 then
      if bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_BASICS or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_BASICS_SPECIFIC or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE_SPECIFIC then
        local BpModuleData = _G.NRCModuleManager:GetModule("BattlePassModule"):GetData()
        local BP_data = BpModuleData.PlayerBattlePassInfo.battle_pass_brief_info
        local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        local gender = player.gender
        local curPassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
        local giftGrade, closeCallback, closeCallbackParam
        if bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_BASICS then
          giftGrade = _G.ProtoEnum.BattlePassGiftGrade.BPGG_NORMAL
          BP_data.gift_grade = giftGrade
        elseif bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE then
          local gift_id
          local isMale = _G.DataModelMgr.PlayerDataModel:IsMale()
          local theme_conf = _G.DataConfigManager:GetBattlePassThemeConf(BpModuleData.PlayerBattlePassInfo.theme_id)
          if BP_data.gift_grade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_NORMAL then
            giftGrade = _G.ProtoEnum.BattlePassGiftGrade.BPGG_SPREAD
            BP_data.gift_grade = giftGrade
            if isMale then
              gift_id = theme_conf.male_spread_gift_id
            else
              gift_id = theme_conf.female_spread_gift_id
            end
          else
            giftGrade = _G.ProtoEnum.BattlePassGiftGrade.BPGG_COLLECTION
            BP_data.gift_grade = giftGrade
            if isMale then
              gift_id = theme_conf.male_collection_gift_id
            else
              gift_id = theme_conf.female_collection_gift_id
            end
          end
          local reward_id = _G.DataConfigManager:GetBattlePassGiftConf(gift_id).gift_rewards_id
          closeCallbackParam = reward_id
          
          function closeCallback(rewardId)
            local RewardItem = _G.DataConfigManager:GetRewardConf(rewardId).RewardItem
            local popupInitData = {}
            for _, v in ipairs(RewardItem) do
              local popupData = _G.ProtoMessage:newGoodsItem()
              popupData.id = v.Id
              popupData.num = v.Count
              popupData.type = v.Type
              table.insert(popupInitData, popupData)
            end
            _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData)
          end
        end
        if bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_BASICS or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE then
          local _, selectGiftConf = BpModuleData:GetBattlePassGiftData(curPassInfo.battle_pass_id, curPassInfo.theme_id, giftGrade, gender)
          local purchaseData = {
            effectText = selectGiftConf.main_effect_text,
            effectIcon = selectGiftConf.main_effect_icon,
            titleText = _G.LuaText.bp_gift_shining_unlock_title,
            closeCallback = closeCallback,
            closeCallbackParam = closeCallbackParam
          }
          _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPurchaseSuccessfulTips, purchaseData)
        end
      end
      if bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_EXCHANGE then
        for _, exchange_id in ipairs(bagItemInfo.item_behavior[1].ratio) do
          local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchange_id)
          local exchangeItem = exchangeConf and exchangeConf.get_item[1]
          local exchangeItemId = exchangeItem and exchangeItem.get_goods_id
          local exchangeItemConf = exchangeItemId and _G.DataConfigManager:GetBagItemConf(exchangeItemId)
          if exchangeItemConf then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.gsub(_G.LuaText.use_recipe_text, "%%s", exchangeItemConf.name))
          end
        end
      end
    end
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.AttributePanelRefresh)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.UpdatePetWareHouseMainInfo)
    self:UseBagItemAction(rsp.use_bag_id)
    self:UpdateMedalInfo(rsp)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnUseBagItemSuccess)
    NRCEventCenter:DispatchEvent(PetUIModuleEvent.RefreshAdjustPetPanel, rsp)
  elseif self:HasPanel("BagPopUp") then
    self:ClosePanel("BagPopUp")
  end
  if self:HasPanel("BagMain") then
    local panel = self:GetPanel("BagMain")
    if panel then
      panel:SetBagCanClick(true)
    end
  end
end

function BagModule:GetChangePetData(changes)
  if self.data.PetBloodItem then
    for _, v in ipairs(changes) do
      if v.pet_data and v.pet_data.gid == self.changePetGid then
        self.data.PetBloodItem = v.pet_data
        break
      end
    end
    self.changePetGid = nil
  end
end

function BagModule:SetChangePetGid(gid)
  self.changePetGid = gid
end

function BagModule:IsUnlockBP(bagItemInfo)
  if bagItemInfo and bagItemInfo.item_behavior and bagItemInfo.item_behavior[1] and (bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_BASICS or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_BASICS_SPECIFIC or bagItemInfo.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE_SPECIFIC) then
    return true
  end
  return false
end

function BagModule:CheckRewardsContainFashionSuit(rewards)
  if not rewards or 0 == #rewards then
    return nil
  end
  local suitIdMap = {}
  for _, reward in ipairs(rewards) do
    if reward.type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      return {
        suitId = reward.id,
        isSuit = true
      }
    end
    if reward.type == _G.Enum.GoodsType.GT_FASHION then
      local fashionConf = _G.DataConfigManager:GetFashionItemConf(reward.id)
      if fashionConf and fashionConf.suit_id and 0 ~= fashionConf.suit_id then
        local suitId = fashionConf.suit_id
        if not suitIdMap[suitId] then
          suitIdMap[suitId] = {}
        end
        table.insert(suitIdMap[suitId], reward.id)
      end
    end
  end
  for suitId, fashionIds in pairs(suitIdMap) do
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
    if suitConf and suitConf.item_id then
      local requiredCount = #suitConf.item_id
      if #fashionIds > 0 then
        return {
          suitId = suitId,
          fashionIds = fashionIds,
          isSuit = false
        }
      end
    end
  end
  return nil
end

function BagModule:MakeDiamondReturnInfo(rsp)
  local diamondReturnInfo
  local changes = rsp.ret_info and rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards
  if changes then
    for _, change in ipairs(changes) do
      if change.type == _G.Enum.GoodsType.GT_VITEM and change.id == _G.Enum.VisualItem.VI_DIAMOND then
        diamondReturnInfo = {
          type = change.type,
          id = change.id,
          num = change.num
        }
        break
      end
    end
  end
  return diamondReturnInfo
end

function BagModule:CalculateFashionSuitTotalReturnAmount(suitInfo, rewards)
  if not suitInfo then
    return 0
  end
  local totalReturn = 0
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerGender = player and player.gender
  if suitInfo.isSuit then
    totalReturn = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetGoodsReturnAmount, _G.Enum.GoodsType.GT_FASHION_SUITS, suitInfo.suitId, playerGender)
    if 0 == totalReturn then
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitInfo.suitId)
      if suitConf and suitConf.item_id then
        for _, fashionId in ipairs(suitConf.item_id) do
          local fashionReturn = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetGoodsReturnAmount, _G.Enum.GoodsType.GT_FASHION, fashionId, playerGender)
          totalReturn = totalReturn + fashionReturn
        end
      end
    end
  elseif suitInfo.fashionIds then
    for _, fashionId in ipairs(suitInfo.fashionIds) do
      local fashionReturn = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdGetGoodsReturnAmount, _G.Enum.GoodsType.GT_FASHION, fashionId, playerGender)
      totalReturn = totalReturn + fashionReturn
    end
  end
  return totalReturn
end

function BagModule:ShowFashionSuitRewardPopup(suitInfo, rewards, rsp)
  local diamondReturnInfo = self:MakeDiamondReturnInfo(rsp)
  local totalReturnAmount = self:CalculateFashionSuitTotalReturnAmount(suitInfo, rewards)
  local alreadyOwned = diamondReturnInfo and totalReturnAmount > 0 and totalReturnAmount <= diamondReturnInfo.num
  if alreadyOwned then
    local rewardList = {diamondReturnInfo}
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardList, "")
  else
    local fakeRsp = _G.ProtoMessage:newZoneShopBuyItemRsp()
    fakeRsp.ret_info.ret_code = 0
    fakeRsp.ret_info.goods_reward = rsp.ret_info.goods_reward
    if diamondReturnInfo then
      fakeRsp.onCloseCallback = _G.MakeWeakFunctor(nil, function()
        local rewardList = {diamondReturnInfo}
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewardList, "")
      end)
    end
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionBuyResultPopUp, fakeRsp)
  end
end

function BagModule:DoUnlockBP(rsp)
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OnCmdGetNewBattlePassInfo)
  _G.NRCEventCenter:DispatchEvent(BagModuleEvent.RefreshBagInfo, rsp)
end

function BagModule:UseBagItemAction(use_bag_id)
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(use_bag_id)
  if self:HasPanel("BagMain") then
    local panel = self:GetPanel("BagMain")
    panel:OnUseBagItemRsp(BagItemConf)
  end
  if BagItemConf.is_close_bagui and 1 == BagItemConf.is_close_bagui then
    self:OnCmdCloseBagMainPanel()
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  end
end

function BagModule:UpdateMedalInfo(rsp)
  local bagItemInfo = _G.DataConfigManager:GetBagItemConf(rsp.use_bag_id)
  local use_action = bagItemInfo.item_behavior and bagItemInfo.item_behavior[1] and bagItemInfo.item_behavior[1].use_action
  if use_action == _G.Enum.ItemBehavior.IB_GIVE_MEDAL then
    local GoodsChangeItem
    if rsp.ret_info and rsp.ret_info.goods_change_info and #rsp.ret_info.goods_change_info.changes > 0 then
      for i, Changes in ipairs(rsp.ret_info.goods_change_info.changes) do
        if Changes.medal then
          GoodsChangeItem = Changes
        end
      end
    end
    if GoodsChangeItem then
      self:OpenPanel("Bag_AwardMedal", GoodsChangeItem, self.para)
    end
  end
end

function BagModule:OnCmdOpenBagPopUp(petSkillLernlist, Type, SelectItemData)
  local isOpened, _ = self:HasPanel("BagPopUp")
  if isOpened then
  else
    self:OpenPanel("BagPopUp", petSkillLernlist, Type, SelectItemData)
  end
end

function BagModule:OnCmdSetIsCanCloseBagPopUp(_IsCanClose)
  local isOpened, _ = self:HasPanel("BagPopUp")
  if isOpened then
    local Panel = self:GetPanel("BagPopUp")
    Panel:SetIsCanClose(_IsCanClose)
  end
end

function BagModule:OnCmdCloseBagPopUp()
  self:ClosePanel("BagPopUp")
end

function BagModule:OnCmdOpenCommonPopUp(SelectItemData)
  self:OpenPanel("Bag_CommonPopUp", SelectItemData)
end

function BagModule:OnCmdSelectCommonPetHeadPicture(_PetData)
  self:DispatchEvent(BagModuleEvent.SelectCommonPetHeadPictureEvent, _PetData)
end

function BagModule:OnCmdGetMedalListAndWearMedalByPetGid(Gid)
  Log.Warning("BagModule:OnCmdGetMedalListAndWearMedalByPetGid \229\183\178\229\186\159\229\188\131\239\188\140\232\175\183\228\189\191\231\148\168 PlayerDataModel:GetMedalListAndWearMedalByPetGid")
  local MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(Gid)
  if not WearMedal then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(Gid)
    Log.Debug(Gid, PetData and PetData.name, "BagModule:OnCmdGetMedalListAndWearMedalByPetGid")
    Log.Dump(MedalList, 2, "BagModule:OnCmdGetMedalListAndWearMedalByPetGid_1")
  end
  return MedalList, WearMedal
end

function BagModule:OnCmdOpenBXTips(CurSelectItem)
  self:OpenPanel("BXTips", CurSelectItem)
end

function BagModule:OnCmdOpenChooseItemPanel(curSelectItem, treasureItemIds)
  if not (curSelectItem and treasureItemIds) or #treasureItemIds <= 0 then
    return
  end
  local treasureCfg = _G.DataConfigManager:GetTreasureItemConf(treasureItemIds[1])
  local umg = treasureCfg and treasureCfg.umg_path
  if not string.IsNilOrEmpty(umg) then
    local OtherModuleUmgCmd = {
      FashionRewardSelect = ActivityModuleCmd.OpenCommonFashionRewardSelectPanel
    }
    local cmd = OtherModuleUmgCmd[umg]
    if cmd then
      _G.NRCModuleManager:DoCmd(cmd, curSelectItem, treasureCfg)
    else
      self:OpenPanel(umg, curSelectItem, treasureCfg)
    end
  else
    self:OnCmdOpenBXTips(curSelectItem)
  end
end

function BagModule:OpenOrCloseCharacterPanelToList(Panel, IsOpen, petList, bIsFrameItem, ...)
  local panel = self:GetPanel("BagMain")
  if not panel then
    local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").OK
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType1)
    local touchReasonType2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").CANCEL
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType2)
    return
  end
  if IsOpen then
    panel:SetBagCanClick(false)
    if #self.CharacterPanelList >= 1 then
      local panel1 = self.CharacterPanelList[#self.CharacterPanelList]
      self:ClosePanel(panel1)
    end
    table.insert(self.CharacterPanelList, #self.CharacterPanelList + 1, Panel)
    self:OpenCharacterPanel(Panel, petList, bIsFrameItem)
  else
    if #self.CharacterPanelList >= 1 then
      local panel1 = table.remove(self.CharacterPanelList, #self.CharacterPanelList)
      self:ClosePanel(panel1)
    end
    if #self.CharacterPanelList >= 1 then
      local panel1 = self.CharacterPanelList[#self.CharacterPanelList]
      self:OpenCharacterPanel(panel1, petList)
    else
      panel:SetBagCanClick(true)
    end
    local touchReasonType2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").CANCEL
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType2)
  end
end

function BagModule:OpenCharacterPanel(Panel, PetList, bIsFrameItem)
  if Panel == self.data.CharacterPanelEnum.PetCharacterTips then
    local CurSelectItem = self.data:GetCurSelectedItemData()
    self:OpenPanel(Panel, CurSelectItem)
  elseif Panel == self.data.CharacterPanelEnum.BagBright then
    if PetList then
      self.BagBrightPetList = PetList
    end
    local CurSelectItem = self.data:GetCurSelectedItemData()
    self:OpenPanel(Panel, CurSelectItem, self.BagBrightPetList)
  elseif Panel == self.data.CharacterPanelEnum.BagBlood then
    local CurSelectItem = self.data:GetCurSelectedItemData()
    if PetList then
      self.BagBloodPetList = PetList
    end
    self:OpenPanel(Panel, CurSelectItem, self.BagBloodPetList)
  else
    self:OpenPanel(Panel, bIsFrameItem)
  end
end

function BagModule:ChangePetCharacterSuccess()
  if self.IsWaitChangeRsp then
    return
  end
  local change_attr_type = {}
  local target_type = {}
  local GoodPetNature = self:GetChangeAttrReqEnum(self.data.GoodPetNature)
  local BagPetNature = self:GetChangeAttrReqEnum(self.data.BadPetNature)
  if GoodPetNature and BagPetNature then
    change_attr_type = {1, 2}
    target_type = {GoodPetNature, BagPetNature}
  end
  if GoodPetNature and not BagPetNature then
    change_attr_type = {1}
    target_type = {GoodPetNature}
  end
  if BagPetNature and not GoodPetNature then
    change_attr_type = {2}
    target_type = {BagPetNature}
  end
  self.IsWaitChangeRsp = true
  self:OnCmdZoneUseBagItemReq(self.data.curSelectedItemData.gid, self.data.curSelectedItemData.id, 1, self.data.PetCharacterItem.gid, {change_attr_type = change_attr_type, target_type = target_type})
end

function BagModule:ChangePetBloodSuccess()
  if self.IsWaitChangeRsp then
    return
  end
  if not self.data.PetBloodItem then
    Log.Error("PetBloodItem is nil")
    return
  end
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.data.curSelectedItemData.id)
  local para2 = self.data.ChangeBlood
  if BagItemConf and BagItemConf.item_behavior and BagItemConf.item_behavior[1] and BagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD then
    para2 = nil
  end
  self.IsWaitChangeRsp = true
  self:OnCmdZoneUseBagItemReq(self.data.curSelectedItemData.gid, self.data.curSelectedItemData.id, 1, self.data.PetBloodItem.gid, {para2 = para2})
end

function BagModule:ChangePetTalentSuccess()
  if self.IsWaitChangeRsp then
    return
  end
  local ChangeTalentType = Enum.AttributeType.AT_NONE
  if self.data.ChangeTalentType then
    ChangeTalentType = self.data.ChangeTalentType
  end
  self.IsWaitChangeRsp = true
  self:OnCmdZoneUseBagItemReq(self.data.curSelectedItemData.gid, self.data.curSelectedItemData.id, 1, self.data.PetTalentItem.gid, {
    change_talent_type = ChangeTalentType,
    result_type = self.data.ResultTalentType
  })
end

function BagModule:ADDPetTalentSuccess()
  if self.IsWaitChangeRsp then
    return
  end
  local ChangeTalentType = Enum.AttributeType.AT_NONE
  if self.data.ChangeTalentType then
    ChangeTalentType = self.data.ChangeTalentType
  end
  self.IsWaitChangeRsp = true
  self:OnCmdZoneUseBagItemReq(self.data.curSelectedItemData.gid, self.data.curSelectedItemData.id, 1, self.data.PetTalentItem.gid, {para2 = ChangeTalentType})
end

function BagModule:GetChangeAttrReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX_PERCENT then
    return Enum.AttributeType.AT_HPMAX
  elseif attribute == Enum.AttributeType.AT_PHYATK_PERCENT then
    return Enum.AttributeType.AT_PHYATK
  elseif attribute == Enum.AttributeType.AT_SPEATK_PERCENT then
    return Enum.AttributeType.AT_SPEATK
  elseif attribute == Enum.AttributeType.AT_PHYDEF_PERCENT then
    return Enum.AttributeType.AT_PHYDEF
  elseif attribute == Enum.AttributeType.AT_SPEDEF_PERCENT then
    return Enum.AttributeType.AT_SPEDEF
  elseif attribute == Enum.AttributeType.AT_SPEED_PERCENT then
    return Enum.AttributeType.AT_SPEED
  end
end

function BagModule:OnCmdCloseBXTips()
  self:ClosePanel("BXTips")
end

function BagModule:OnCmdOpenHatchTips()
  local CurSelectItem = self.data:GetCurSelectedItemData()
  self.data.CacheHatchEggItem = {}
  self.data.CacheHatchEggItem.gid = CurSelectItem.gid
  self.data.CacheHatchEggItem.id = CurSelectItem.id
  self.data.CacheHatchEggItem.egg_data = CurSelectItem.egg_data
end

function BagModule:OnCmdSetCurSelectEggItemData(EggItemData)
  self.data.CacheHatchEggItem = {}
  self.data.CacheHatchEggItem.gid = EggItemData.gid
  self.data.CacheHatchEggItem.id = EggItemData.id
  self.data.CacheHatchEggItem.egg_data = EggItemData.egg_data
end

function BagModule:OnCmdOpenBagScreenPanel(list, confName)
  self:OpenPanel("BagScreen", list, confName)
end

function BagModule:CmdOpenFilterPanel(list, confName, condition, limitFilter)
  self:OpenPanel("BagScreen", list, confName, condition, limitFilter)
end

function BagModule:OnCmdOpenBagSortPanel(list, selectId, bskipSound)
  self:OpenPanel("BagSort", list, selectId, bskipSound)
end

function BagModule:CmdCanUseSkillMachine(PetData)
  local condition = {}
  condition.FilterPetCondition = {PetData}
  condition.FilterDepartCondition = {}
  condition.FilterClassifyCondition = {}
  self.data:SetSkillStoneFilter(nil, condition)
  local bagInfoList = self.data:SortItemListByLableType(_G.Enum.ItemLableType.ILT_SKILL_MACHINE, _G.Enum.Sequence.SEQUENCE_DEFAULT)
  if bagInfoList and #bagInfoList > 0 then
  else
    self.data:ClearSkillStoneFilter()
  end
  return bagInfoList and #bagInfoList > 0
end

function BagModule:CmdGetCanUseBagItemByItemId(petData, PetOpenUseAction)
  local ItemIdList = {}
  if PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Blood then
    ItemIdList = _G.DataConfigManager:GetPetGlobalConfig("normal_blood_effect_item").numList
  elseif PetOpenUseAction == BagModuleEnum.PetOpenUseAction.NightMareBlood then
    ItemIdList = _G.DataConfigManager:GetPetGlobalConfig("nightmare_blood_effect_item").numList
  elseif PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Talent then
    ItemIdList = _G.DataConfigManager:GetPetGlobalConfig("talent_effect_item").numList
  elseif PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Nature then
    ItemIdList = _G.DataConfigManager:GetPetGlobalConfig("nature_effect_item").numList
  end
  local itemList = {}
  itemList = self:GetCanUseBagItemByItemId(ItemIdList, PetOpenUseAction)
  return itemList and #itemList > 0
end

function BagModule:GetCanUseBagItemByItemId(ItemIdList, PetOpenUseAction)
  local itemList = {}
  local bagInfoList = self.data:SortItemListByLableType(_G.Enum.ItemLableType.ILT_PRECIOUS, _G.Enum.Sequence.SEQUENCE_DEFAULT)
  if bagInfoList and #bagInfoList > 0 then
    for _, v in pairs(ItemIdList) do
      for _, item in pairs(bagInfoList) do
        if item.id == v then
          if PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Blood then
            if item.conf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_ALL_NATURE then
              table.insert(itemList, item)
            elseif item.conf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD then
              table.insert(itemList, item)
            elseif item.conf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS then
              table.insert(itemList, item)
            elseif item.conf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_FANTASTIC then
              table.insert(itemList, item)
            end
          elseif PetOpenUseAction == BagModuleEnum.PetOpenUseAction.NightMareBlood then
            if item.conf.item_behavior[1].use_action == Enum.ItemBehavior.IB_NIGHTMARE_ELITE_RECOVERY then
              table.insert(itemList, item)
            end
          elseif PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Talent then
            if item.conf.item_behavior[1].use_action == Enum.ItemBehavior.IB_IMPROVE_TALENT then
              table.insert(itemList, item)
            end
            if item.conf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_TALENT then
              table.insert(itemList, item)
            end
          elseif PetOpenUseAction == BagModuleEnum.PetOpenUseAction.Nature and item.conf.item_behavior[1].use_action == Enum.ItemBehavior.IB_CHANGE_NATURE_EFFECT then
            table.insert(itemList, item)
          end
        end
      end
    end
  end
  return itemList
end

function BagModule:CmdSetIsPetInfoMainToPanel()
  UE4Helper.SetEnableWorldRendering(true)
  self.IsPetInfoMainToPanel = true
end

function BagModule:OnCmdReversalBagSort(_itemType)
  local itemType = _itemType or self.data:GetCurItemType()
  local curIsReversal = self.data:GetTabSortIsReversalSort(itemType)
  self.data:SetTabSortListIsReversalSort(itemType, not curIsReversal)
  self:DispatchEvent(BagModuleEvent.UpdateFilter)
end

function BagModule:OnCmdSetIsFirstAcquisitionMagic(IsFirstAcquisitionMagic)
  self.data.IsFirstAcquisitionMagic = IsFirstAcquisitionMagic
end

function BagModule:OnCmdGetIsFirstAcquisitionMagic()
  return self.data.IsFirstAcquisitionMagic
end

function BagModule:OnCmdSetSortSelectIndex(bagItemType, sortIndex)
  self.data:SetTableSortSelectIndex(bagItemType, sortIndex)
end

function BagModule:OnCmdGetSortSelectIndex(bagItemType)
  return self.data:GetTableSortSelectIndex(bagItemType)
end

function BagModule:OnCmdSortEquipBall(list)
  return self.data:SortEquipBall(list)
end

function BagModule:OnCmdChangeBall()
  local afterItemInfo = self.data.curSelectedItemData
  local beforeItemInfo = self.data.ChangeBallSelectedItem
  local equippedItemGid
  if _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.catchInfo then
    equippedItemGid = _G.BattleManager.battleRuntimeData.catchInfo.curUseBallGID
  end
  local RemovePetBallIndex = 0
  local ballIndex = 0
  if beforeItemInfo then
    if equippedItemGid and 0 ~= equippedItemGid then
      for i = 1, #self.data.EquipBallList do
        if self.data.EquipBallList[i].gid == equippedItemGid then
          ballIndex = i
        end
      end
    end
    for i = 1, #self.data.EquipBallList do
      if self.data.EquipBallList[i].gid == beforeItemInfo.gid then
        if 0 == ballIndex then
          ballIndex = i
        end
        if 9 == self.data.EquipBallList[i].bag_item_flags then
          RemovePetBallIndex = i
        end
        self.data.EquipBallList[i] = afterItemInfo
        break
      end
    end
    self:OnCmdZoneModifyBagItemFlagsReq(RemovePetBallIndex, ballIndex)
    self.data.ChangeBallSelectedItem = nil
    return true
  else
    local desStr = _G.DataConfigManager:GetLocalizationConf("Equipped_Ball_Exchange_tip").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, desStr)
    return false
  end
end

function BagModule:OnCmdEquipStateChanged(gid, flag)
  local itemInfo = self:OnGetBagItemByGid(gid)
  local RemovePetBallIndex = 0
  if not itemInfo then
    Log.Warning("itemInfo is nil!!!")
    return
  end
  if 0 ~= flag then
    if 1 == flag then
      if itemInfo.type == ProtoEnum.BagItemType.BI_PET_BALL then
        local IsHasHandheld = false
        itemInfo.bag_item_flags = 1
        if self.data.BagInfo.bag_backpack == nil then
          self.data.BagInfo.bag_backpack = {}
        end
        if nil == self.data.BagInfo.bag_backpack.ball_list then
          self.data.BagInfo.bag_backpack.ball_list = {}
        end
        for k, v in ipairs(self.data.EquipBallList) do
          if v.id == itemInfo.id then
            table.remove(self.data.EquipBallList, k)
            break
          end
        end
        table.insert(self.data.EquipBallList, itemInfo)
        for i, EquipBall in ipairs(self.data.EquipBallList) do
          if 9 == EquipBall.bag_item_flags then
            IsHasHandheld = true
          end
        end
        if IsHasHandheld then
          RemovePetBallIndex = 0
        else
          RemovePetBallIndex = #self.data.EquipBallList
        end
        self:OnCmdZoneModifyBagItemFlagsReq(RemovePetBallIndex)
      elseif itemInfo.type == ProtoEnum.BagItemType.BI_MAGIC then
        self:SetEquipMagicInfo(itemInfo, true)
        self:DispatchEvent(BagModuleEvent.UpdateEquipState, itemInfo)
      elseif itemInfo.type == ProtoEnum.BagItemType.BI_PLAYERSKILL then
        self:SetProtagonistMagicInfo(itemInfo)
      end
    elseif 9 == flag and itemInfo.type == ProtoEnum.BagItemType.BI_PET_BALL then
      itemInfo.bag_item_flags = 9
      for k, v in ipairs(self.data.EquipBallList) do
        if v.gid == itemInfo.gid then
          v.bag_item_flags = 9
        else
          v.bag_item_flags = 1
        end
      end
      self:OnCmdZoneModifyBagItemFlagsReq()
    end
  elseif itemInfo.type == ProtoEnum.BagItemType.BI_PET_BALL then
    for k, v in ipairs(self.data.EquipBallList) do
      if v.gid == gid then
        if 9 == v.bag_item_flags then
          RemovePetBallIndex = k
        end
        table.remove(self.data.EquipBallList, k)
        break
      end
    end
    self:OnCmdZoneModifyBagItemFlagsReq(RemovePetBallIndex)
  elseif itemInfo.type == ProtoEnum.BagItemType.BI_MAGIC then
    self:SetEquipMagicInfo(nil, false)
    self:DispatchEvent(BagModuleEvent.UpdateEquipState, itemInfo)
  elseif itemInfo.type == ProtoEnum.BagItemType.BI_PLAYERSKILL then
    self:SetProtagonistMagicInfo(nil)
  end
end

function BagModule:OnCmdZoneModifyBagItemFlagsReq(RemovePetBallIndex, ballIndex)
  self.lastBallIndex = ballIndex
  local equipItemList = self.data.EquipBallList
  local HandheldPetBall
  local req = _G.ProtoMessage:newZoneModifyBagItemFlagsReq()
  for i = 1, #equipItemList do
    if RemovePetBallIndex and i == RemovePetBallIndex then
      equipItemList[i].bag_item_flags = 9
      HandheldPetBall = equipItemList[i]
    elseif RemovePetBallIndex and i == #equipItemList and i < RemovePetBallIndex then
      equipItemList[i].bag_item_flags = 9
      HandheldPetBall = equipItemList[i]
    elseif 9 == equipItemList[i].bag_item_flags then
      HandheldPetBall = equipItemList[i]
    else
      equipItemList[i].bag_item_flags = 1
    end
    local slotIdx = 999
    if equipItemList[i] and equipItemList[i].gid then
      slotIdx = self.data:GetBagEquipSortIndex(equipItemList[i].gid)
    end
    table.insert(req.modify_info, {
      gid = equipItemList[i].gid,
      bag_item_flags = equipItemList[i].bag_item_flags,
      slot_idx = slotIdx,
      item_conf_id = equipItemList[i].id or 0
    })
  end
  if HandheldPetBall then
    self.data:SetCurEquipItem(HandheldPetBall)
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MODIFY_BAG_ITEM_FLAGS_REQ, req, self, self.ZoneModifyBagItemFlagsRsp, false)
end

function BagModule:ZoneModifyBagItemFlagsRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local clientBagInfo = self.data.BagInfo
    for i = 1, #clientBagInfo.item_list do
      if clientBagInfo.item_list[i].items ~= nil then
        for j = 1, #clientBagInfo.item_list[i].items do
          local itemInfo = clientBagInfo.item_list[i].items[j]
          local hasSame = false
          local EquipBall
          for k = 1, #self.data.EquipBallList do
            if itemInfo.gid == self.data.EquipBallList[k].gid then
              hasSame = true
              EquipBall = self.data.EquipBallList[k]
            end
          end
          if hasSame then
            if nil ~= self:GetEquipItemInfo() and EquipBall and 9 == EquipBall.bag_item_flags then
              itemInfo.bag_item_flags = 9
            elseif nil ~= self:GetEquipItemInfo() and self:GetEquipItemInfo().gid == itemInfo.gid then
              itemInfo.bag_item_flags = 9
            end
          else
            itemInfo.bag_item_flags = 0
          end
        end
      end
    end
    self.data:SetBagInfo(clientBagInfo)
    self:DispatchEvent(BagModuleEvent.UpdateEquipState, self.data:GetCurEquipItem())
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipItemInfo, true)
    if _G.NRCModuleManager:DoCmd(BattleModuleCmd.IsInBattle) and rsp.items then
      _G.BattleManager.battlePawnManager.TeamatePlayer.itemInfo = rsp.items
    end
    _G.NRCModuleManager:DoCmd(BattleModuleCmd.OnSelectExtraCatchBall, nil, self.lastBallIndex)
    self.lastBallIndex = 0
  end
end

function BagModule:OnCmdEquipProtagonistMagicStateChanged(Item_Gid, Item_Id)
  local req = _G.ProtoMessage:newZoneChangeRoleMagicItemReq()
  req.item_gid = Item_Gid
  req.item_conf_id = Item_Id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHANGE_ROLE_MAGIC_ITEM_REQ, req, self, self.OnCmdEquipProtagonistMagicStateChangedRsp)
end

function BagModule:OnCmdEquipProtagonistMagicStateChangedRsp(_Rsp)
end

function BagModule:OnCmdGetEquipedPlayerSkill()
  return self.data:GetEquipedPlayerSkill()
end

function BagModule:OnCmdSetSelectedItem(itemData, way, bTouchClickByUser)
  if 0 == way then
    local CurSelectedItemData = self.data:GetCurSelectedItemData()
    if CurSelectedItemData and CurSelectedItemData.gid and itemData.gid == CurSelectedItemData.gid and CurSelectedItemData.type ~= _G.Enum.BagItemType.BI_PET_BALL and CurSelectedItemData.type ~= _G.Enum.BagItemType.BI_PET_EGG and CurSelectedItemData.type ~= _G.Enum.BagItemType.BI_FURNITURE then
      self.data:SetCurSelectedItemData(itemData)
      return
    end
    if not CurSelectedItemData and not bTouchClickByUser and itemData.type == _G.Enum.BagItemType.BI_FURNITURE and self.data:InFurnitureDecomposeMode() then
      return
    end
    self.data:SetCurSelectedItemData(itemData)
    self:DispatchEvent(BagModuleEvent.SetChooseItemInfo, itemData.id, itemData.gid, bTouchClickByUser)
  else
    self.data.ChangeBallSelectedItem = itemData
  end
end

function BagModule:OnCmdGetSelectedItem()
  return self.data:GetCurSelectedItemData()
end

function BagModule:OnCmdSequenceSelected(index)
  local sortList = self.data:GetCurSortList()
  self:OnCmdSetSortSelectIndex(self.data:GetCurItemType(), index)
  self.data.SortSelectIndex = index
  if self:HasPanel("BagMain") then
    local panel = self:GetPanel("BagMain")
    panel.NeeItemSelectedAudio = false
  end
  local itemType = self.data:GetCurItemType()
  local curSortType = sortList[self.data.SortSelectIndex]
  self.data:SetTabSortListSortType(itemType, curSortType)
  self:DispatchEvent(BagModuleEvent.SetSortType, itemType, curSortType)
end

function BagModule:OnCmdGetEquipBallList()
  return self.data.EquipBallList
end

function BagModule:OnBagChange(item, cmdID, GoodsChangeItems)
  self:Log("BagModule:OnBagChange CMD=", cmdID, "ItemId=", item.id, "ItemGid=", item.gid, "ItemType", item.bag_item.type)
  if cmdID == ProtoCMD.ZoneSvrCmd.ZONE_MODIFY_BAG_ITEM_FLAGS_RSP then
    return
  end
  self:OnCmdSetBagChangeInfo(item, cmdID, GoodsChangeItems)
end

function BagModule:DisableExcessiveTips()
  local delayedTime = 0.4
  if not self.tipsLastTime then
    self.tipsLastTime = os.time()
    return true
  end
  if delayedTime < os.time() - self.tipsLastTime then
    self.tipsLastTime = os.time()
    return true
  end
  return false
end

function BagModule:OnCmdSetBagChangeInfo(item, cmdID, GoodsChangeItems)
  self.data.Canfilter = true
  local BagItem = self.data:GetBagItemByGID(item.bag_item.gid)
  local IsSetEquipItem = false
  if not BagItem then
    IsSetEquipItem = true
  end
  if GoodsChangeItems then
    for _, GoodsChangeItem in ipairs(GoodsChangeItems) do
      if GoodsChangeItem.bag_item and GoodsChangeItem.bag_item.type == ProtoEnum.BagItemType.BI_PLAYERSKILL and BagItem and item.bag_item and item.bag_item.remain_use_cnt and BagItem.remain_use_cnt and item.bag_item.remain_use_cnt > BagItem.remain_use_cnt and self:DisableExcessiveTips() then
        local RecoverMagicConf = _G.DataConfigManager:GetLocalizationConf("PLAYER_SKILL_RECOVER_TIP")
        _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, RecoverMagicConf.msg)
        break
      end
    end
  end
  self.data:UpdateBagItemData(item, cmdID)
  if item.bag_item.type == ProtoEnum.BagItemType.BI_MAGIC then
    self.data.IsFirstAcquisitionMagic = true
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_OpenMagicTips, item)
    self:OnCmdEquipStateChanged(item.bag_item.gid, 1)
  end
  if item.bag_item.type == ProtoEnum.BagItemType.BI_PET_BALL then
    local ballConf = _G.DataConfigManager:GetBallConf(item.id)
    if ballConf and ballConf.bigworld_catch ~= false then
      local isEquip = false
      local itemList = self.data:GetPlayerThrowBallList()
      for i = 1, #itemList do
        if itemList[i].gid == item.bag_item.gid then
          isEquip = true
          break
        end
      end
      if not isEquip then
        self:OnCmdEquipStateChanged(item.bag_item.gid, 1)
      end
    end
  end
  if item.bag_item.type == ProtoEnum.BagItemType.BI_MUSIC then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(item.bag_item.id)
    if bagItemConf and bagItemConf.item_behavior and bagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_UNLOCK_MUSIC and bagItemConf.item_behavior[1].ratio[1] then
      local info = {
        goods_reward = {
          rewards = {}
        }
      }
      local reward = {}
      info.goods_reward.rewards[1] = reward
      reward.first_get = true
      reward.id = item.id
      reward.num = 1
      reward.reward_reason = _G.ProtoEnum.FlowReason.FLOW_REASON_COLLECT
      reward.tag = ProtoEnum.GoodsDsiplayTag.NARMAL_SHOW
      reward.type = item.type
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_ProcessRetInfo, cmdID, info, false)
      _G.DataModelMgr.PlayerDataModel:ADDPlayerMusicInfo(bagItemConf.item_behavior[1].ratio[1])
    end
  end
  self:DispatchEvent(BagModuleEvent.RefreshBagInfo, nil)
  _G.NRCEventCenter:DispatchEvent(BagModuleEvent.GlobalRefreshBagInfo)
  _G.NRCEventCenter:DispatchEvent(BagModuleEvent.UpdateBag, item)
  if not self:GetEquipItemInfo() then
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(item.bag_item.id)
    if bagItemInfo and bagItemInfo.throw_function_id > 0 then
      local ballConf = _G.DataConfigManager:GetBallConf(item.bag_item.id)
      if ballConf and ballConf.bigworld_catch ~= false then
        if cmdID == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY then
          if IsSetEquipItem then
            self:EquipHandheldItem(item)
            return
          end
        else
          self:EquipHandheldItem(item)
          return
        end
      end
    end
  end
  if item.bag_item.type == ProtoEnum.BagItemType.BI_PET_BALL then
    self:UpdateBallItemInfoClient(false, cmdID)
  end
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.SetBagChangeInfoEvent, GoodsChangeItems)
end

function BagModule:EquipHandheldItem(item)
  local changeBallSceneNum = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetThrowBagItemCount, item.bag_item.gid)
  if item.bag_item.num - changeBallSceneNum > 0 then
    local bagItem = self:OnGetBagItemArrayByType(1)
    if bagItem and #bagItem <= 0 then
      return
    end
    self:SetEquipItemInfo(item.bag_item)
    _G.NRCModuleManager:DoCmd(BagModuleCmd.OnEquipStateChanged, item.bag_item.gid, 1)
  else
    self:SetEquipItemInfo(nil)
  end
end

function BagModule:OnGetBagItemByID(id)
  return self.data:GetBagItemByID(id)
end

function BagModule:OnCmdUpdateBagItemNumByID(ID, Num)
  self.data:UpdateBagItemNumByID(ID, Num)
end

function BagModule:OnGetCanFeedItem()
  return self.data:GetCanFeedItem()
end

function BagModule:OnGetBagItemArrayByType(ItemType)
  local Data = self.data:GetBagItemArrByType(ItemType)
  return Data
end

function BagModule:OnGetBagItemNumByType(ItemType)
  local Data = self.data:GetBagItemNumByType(ItemType)
  return Data
end

function BagModule:CheckHasBagItemByType(ItemType)
  local Data = self.data:GetBagItemNumByType(ItemType)
  if 0 == Data then
    return false
  else
    return true
  end
end

function BagModule:OnCmdGetBagItemArrayByLableType(ItemType)
  local Data = self.data:GetBagItemByLableType(ItemType)
  return Data
end

function BagModule:OnCmdGetBagEggItemWithoutHathcing()
  local List = self.data:GetBagEggItemWithoutHathcing()
  return List
end

function BagModule:OnCmdSetBagItemArrayFromBagInfo(equipBallList)
  local BagItemList = self.data:SortItemListByLableType(self.data.curItemType, self.data.SortIndex)
  if equipBallList and BagItemList and #equipBallList > 0 and #BagItemList > 0 then
    for j, equipBall in ipairs(equipBallList) do
      for i, BagItem in ipairs(BagItemList) do
        if BagItem.gid == equipBall.gid then
          BagItem.FromBag = true
          break
        end
      end
    end
  end
end

function BagModule:OnLogin(isRelogin)
  if isRelogin then
    self.page = 1
    self.TotalBagInfo = nil
    self.data.FilterPetCondition = {}
    self.data.FilterDepartCondition = {}
    self.data.FilterClassifyCondition = {}
  end
end

function BagModule:GetNPCMapping()
  return self.NPCMap
end

function BagModule:GetItemType()
  return self.data:GetCurItemType()
end

function BagModule:GetEquipItemInfo()
  return self.data:GetCurEquipItem()
end

function BagModule:SetEquipItemInfo(itemData)
  if nil == itemData then
    self.data:SetCurEquipItem(nil)
  else
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemData.id)
    if bagItemConf.type == _G.Enum.BagItemType.BI_PET_BALL then
      if self.data:GetCurEquipItem() == itemData then
        Log.DebugFormat("BagModule:SetEquipItemInfo itemData.id=%s already equiped, no need req", tostring(itemData.id))
      else
        self.data:SetCurEquipItem(itemData)
        self:OnCmdEquipStateChanged(itemData.gid, 9)
      end
    elseif bagItemConf.type == _G.Enum.BagItemType.BI_MAGIC then
      self.data:SetCurEquipMagicData(itemData)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OnCmdSendChangeSelectedThrowItemReq, -1, itemData)
    end
  end
end

function BagModule:GetEquipMagicInfo()
  return self.data:GetCurEquipMagicData()
end

function BagModule:SetEquipMagicInfo(itemData, bSetThrow)
  if not itemData then
    local Num = self:OnGetBagItemNumByType(ProtoEnum.BagItemType.BI_MAGIC)
    if 1 == Num then
      Log.Error("[MAGIC] \228\184\141\229\186\148\232\175\165\229\135\186\231\142\176\232\191\153\231\167\141\230\131\133\229\134\181 \229\143\170\230\156\137\228\184\128\228\184\170\233\173\148\230\179\149\233\129\147\229\133\183 \228\189\134\230\152\175\229\135\186\231\142\176\228\186\134\229\141\184\232\189\189\229\174\131\231\154\132\230\147\141\228\189\156")
    end
  end
  self.data:SetCurEquipMagicData(itemData, bSetThrow)
  if nil == itemData then
    self:UpdateWorldSelectState()
  end
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OnCmdSendChangeSelectedThrowItemReq, -1, itemData)
end

function BagModule:SetProtagonistMagicInfo(itemData)
  self.data:SetCurEquipProtagonistMagicData(itemData)
end

function BagModule:UpdateWorldSelectState()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetThrowNull)
end

function BagModule:UpdateBallItemInfoClient(bool, cmdID)
  local bagBallItemInfo1 = self.data:GetPlayerThrowBallList()
  local oldEquipBallList = self.data.EquipBallList
  self.data.EquipBallList = {}
  local bagBallItemInfo = {}
  if bagBallItemInfo1 then
    for k, v in ipairs(bagBallItemInfo1) do
      v.bag_item_flags = 1
      table.insert(bagBallItemInfo, v)
    end
  end
  self.data.EquipBallList = bagBallItemInfo
  if not bagBallItemInfo or 0 == #bagBallItemInfo then
    self:SetEquipItemInfo(nil)
    if not self.data.IsFirstAcquisitionMagic then
      NRCEventCenter:DispatchEvent(BagModuleEvent.UpdateBag)
    end
    return
  end
  local curEquipItem = self:GetEquipItemInfo()
  local hasEquipBall = false
  if bagBallItemInfo then
    for i = 1, #bagBallItemInfo do
      if curEquipItem and bagBallItemInfo[i].id == curEquipItem.id then
        self.data:SetCurEquipItem(bagBallItemInfo[i])
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipItemInfo, true)
        hasEquipBall = true
        if self:CheckIsNeedEquipChanged(oldEquipBallList, self.data.EquipBallList) then
          self:OnCmdEquipStateChanged(bagBallItemInfo[i].gid, 1)
          break
        end
        bagBallItemInfo[i].bag_item_flags = 9
        Log.DebugFormat("BagModule:UpdateBallItemInfoClient no need req equip changed, curEquipItem.id=%s, oldEquipBallList count = %s, curEquipItem count = %s", tostring(curEquipItem.id), tostring(#oldEquipBallList), tostring(#self.data.EquipBallList))
        break
      end
    end
  end
  if not hasEquipBall then
    self.data:UpdateEquipItemNum(0)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UpdateEquipItemInfo, true)
    local equipItem = _G.NRCModeManager:DoCmd(BagModuleCmd.GetCurEquipItemInfo)
    if equipItem and equipItem.id then
      local req = _G.ProtoMessage:newLastEquipBall()
      req.EquipBallId = equipItem.id
      _G.DataModelMgr.RemoteStorage:Set("EquipBallId", ".Next.LastEquipBall", req)
    end
  end
end

function BagModule:CheckIsNeedEquipChanged(oldEquipBallList, newEquipBallList)
  if not oldEquipBallList or not newEquipBallList then
    return true
  end
  if #oldEquipBallList ~= #newEquipBallList then
    return true
  end
  for i = 1, #oldEquipBallList do
    local found = false
    for j = 1, #newEquipBallList do
      if oldEquipBallList[i] and oldEquipBallList[i].gid == newEquipBallList[j].gid then
        found = true
        break
      end
    end
    if not found then
      return true
    end
  end
  return false
end

function BagModule:InitNPCMapping()
  Log.Debug("BagModule:InitNPCMapping")
  local cfgTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BAG_ITEM_CONF)
  local cfgDatas = cfgTable:GetAllDatas()
  if cfgDatas then
    for _, conf in pairs(cfgDatas) do
      if 0 ~= conf.npcid then
        self.NPCMap[conf.npcid] = conf.id
      end
    end
  end
end

function BagModule:OnGetBagItemByGid(gid)
  return self.data:GetBagItemByGID(gid)
end

function BagModule:OnPetChange(item, cmdID)
  if cmdID == ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_IN_CHANGE_PET_ZONE_NOTIFY or cmdID == ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_LEAVE_CHANGE_PET_ZONE_NOTIFY then
    return
  end
  self.delayId = _G.DelayManager:DelaySeconds(0.1, function()
    local function checkFunc(CatchPetInfo, Type)
      if CatchPetInfo then
        for i, v in ipairs(CatchPetInfo) do
          if item.pet_data and item.pet_data.gid == v.gid then
            _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, Type, item)
          end
        end
      end
    end
    
    if _G.BattleBossChallengeUtils.IsInLeaderChallengeDungeon() then
      local CatchPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfoByTeamType(Enum.PlayerTeamType.PTT_PVE_BOSS_CHALLENGE_FIGHT)
      checkFunc(CatchPetInfo, 4)
    else
      local CatchPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
      checkFunc(CatchPetInfo, 0)
    end
  end)
end

function BagModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName, disablePcEsc, disableLoadBlock)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/Bag/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  registerData.enablePcEsc = not disablePcEsc
  registerData.disableLoadBlock = disableLoadBlock
  self:RegisterPanel(registerData)
  return registerData
end

function BagModule:OnCmdClearBattleInfo()
  self.data:SetCurSelectedItemDataBattle(nil)
end

function BagModule:OnCmdOpenSwapEggsUI(Params)
  if self:HasPanel("BagMain") then
    local panel = self:GetPanel("BagMain")
    if panel then
      panel:OnCloseButtonClicked()
    end
  end
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  self:OpenPanel("SwapEggs", Params)
end

function BagModule:OnCmdGetBagItemEquipIndexByGid(gid)
  return self.data:GetEquipBallIndex(gid)
end

function BagModule:OnCmdSetBagItemClickAble(panelName, clickable)
  if self:HasPanel(panelName) then
    local panel = self:GetPanel(panelName)
    panel:SetBagItemClickAble(clickable)
  end
end

local function compare(a, b)
  return a.id < b.id
end

function BagModule:OnCmdOpenNPCRoster(NPCDataList, npcID)
  local ValidNPCDataList = {}
  if NPCDataList then
    for i, NPCData in ipairs(NPCDataList) do
      if NPCData.unlocked == true then
        table.insert(ValidNPCDataList, NPCData)
      end
    end
  end
  table.sort(ValidNPCDataList, compare)
  self.ValidNPCDataList = ValidNPCDataList
  self:OpenPanel("Roster", ValidNPCDataList, npcID)
end

function BagModule:OnCmdOpenMagicBook(curNPCID)
  self:OpenPanel("MagicBook", curNPCID)
end

function BagModule:OnCmdGetRosterData()
  return self.ValidNPCDataList
end

function BagModule:OnGetNewNPC(notify)
  local uiData = {}
  uiData.npcID = notify.npc_id or 1
  uiData.countdown = 5
  if 1 == notify.action and 0 ~= notify.item_id then
    local MageInfoConf = _G.DataConfigManager:GetMageInfoConf(notify.item_id)
    if MageInfoConf and MageInfoConf.show_tips == true then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.AddTip, TipObject.CreateNPCRosterTips(uiData))
    end
  end
end

function BagModule:OnAllTipsFinished()
  if self:HasPanel("NPCRosterTip") then
    local panel = self:GetPanel("NPCRosterTip")
    panel:ClosePanel()
  end
end

function BagModule:OnTipDisplayStatusChange()
  if self:IsPanelInOpening("NPCRosterTip") then
    self.tipDisplayExecutor:ConsumeNextTip()
  end
  self:ClosePanel("NPCRosterTip")
end

function BagModule:OnCmdOpenNPCRosterTips(tip)
  self.tipDisplayExecutor:AddDisplayTip(tip)
end

function BagModule:OnCmdShowDescPanel(id)
  if self:HasPanel("BagMain") then
    local panel = self:GetPanel("BagMain")
    if id then
      panel:OnDescTextClicked(id)
    end
  end
end

function BagModule:OnCmdHideDescPanel()
  if self:HasPanel("BagMain") then
    local panel = self:GetPanel("BagMain")
    panel:ResetDescText()
  end
end

function BagModule:OnCmdShowCloseBtnPanel()
  if self:HasPanel("BagMain") then
    local panel = self:GetPanel("BagMain")
    panel:ResetDescText(true)
  end
end

function BagModule:OnPlayTips(tip)
  if self:HasPanel("NPCRosterTip") then
    local panel = self:GetPanel("NPCRosterTip")
    panel:ClosePanel()
  end
  self:OpenPanel("NPCRosterTip", tip)
end

function BagModule:OnCmdFilterPet(filter, itemList)
  local bagItemList = {}
  local ItemGidDic = {}
  if nil ~= filter and #filter > 0 then
    local petFilter = filter
    local learnskillid = 0
    for j = 1, #petFilter do
      if petFilter[j] then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petFilter[j].base_conf_id)
        learnskillid = petBaseConf and petBaseConf.level_skill_conf_id or 0
      end
      local LevelSkillConf = _G.DataConfigManager:GetLevelSkillConf(learnskillid)
      local PetLevelSkillList = {}
      local Allmachineskilllist = {}
      if LevelSkillConf then
        local machineskilllist = LevelSkillConf.machine_skill_group
        local PetLevelInfo = LevelSkillConf.level
        for l, v in pairs(PetLevelInfo) do
          table.insert(PetLevelSkillList, {
            machine_skill_id = v.param
          })
        end
        
        local function isIdExists(id, table)
          for _, v in ipairs(table) do
            if v.machine_skill_id == id then
              return true
            end
          end
          return false
        end
        
        for _, v in ipairs(machineskilllist) do
          if not isIdExists(v.machine_skill_id, Allmachineskilllist) then
            table.insert(Allmachineskilllist, v)
          end
        end
      end
      local machineskilllistNum = #Allmachineskilllist
      local TempList = {}
      for i = 1, #itemList do
        if #TempList < 1 then
          local List = {}
          table.insert(List, itemList[i])
          local itemId = itemList[i].filterData.bagitem_id
          local itemConf = _G.DataConfigManager:GetBagItemConf(itemId)
          local list = {
            ItemId = itemId,
            List = List,
            conf = itemConf
          }
          table.insert(TempList, list)
        else
          local num = #TempList
          for k = 1, num do
            if TempList[k].ItemId == itemList[i].filterData.bagitem_id then
              break
            end
            if k == num then
              local List = {}
              table.insert(List, itemList[i])
              local itemId = itemList[i].filterData.bagitem_id
              local itemConf = _G.DataConfigManager:GetBagItemConf(itemId)
              local list = {
                ItemId = itemId,
                List = List,
                conf = itemConf
              }
              table.insert(TempList, list)
            end
          end
        end
      end
      if #TempList < 1 then
        return bagItemList
      end
      local TempItemList = {}
      local TempListNum = #TempList
      for k = 1, machineskilllistNum do
        for i = 1, TempListNum do
          local bagItemConf = TempList[i].conf
          if bagItemConf then
            local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
            if Allmachineskilllist[k].machine_skill_id == skillMachineid then
              table.insert(TempItemList, TempList[i].List)
            end
          end
        end
      end
      if #TempItemList < 1 then
        return bagItemList
      end
      local TempItemListNum = #TempItemList
      for i = 1, TempItemListNum do
        local List = TempItemList[i]
        local num = #List
        for k = 1, num do
          local data = List[k]
          if data and data.filterData then
            local isError = type(data) == "number"
            if isError then
              Log.Error("\230\173\164\229\164\132\231\150\145\228\188\188\233\128\187\232\190\145\233\148\153\232\175\175\239\188\140\232\175\183\230\138\138\230\156\172\230\156\186\230\151\165\229\191\151\229\143\138\230\138\165\233\148\153\230\136\170\229\155\190\228\184\128\229\185\182\229\143\145\231\187\153v_mllmli", data)
            end
            if not isError and not ItemGidDic[data.filterData.bagitem_id] then
              ItemGidDic[data.filterData.bagitem_id] = true
              table.insert(bagItemList, data)
            end
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function BagModule:OnCmdFilterDepart(filter, itemList)
  local bagItemList = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        if itemList[i].filterData and itemList[i].filterData.bagitem_id then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].filterData.bagitem_id)
          if bagItemConf then
            local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
            local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
            if skillConf.skill_dam_type == enum then
              table.insert(bagItemList, itemList[i])
            end
          end
        elseif itemList[i].filterData and itemList[i].filterData.petbase_id then
          local petbaseConf = _G.DataConfigManager:GetPetbaseConf(itemList[i].filterData.petbase_id)
          if petbaseConf then
            for k = 1, #petbaseConf.unit_type do
              local unitType = petbaseConf.unit_type[k]
              if unitType == enum then
                local isRepeat = false
                for key, value in pairs(bagItemList) do
                  if value.filterData.gid and value.filterData.gid == itemList[i].filterData.gid then
                    isRepeat = true
                  end
                end
                if not isRepeat then
                  table.insert(bagItemList, itemList[i])
                end
              end
            end
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function BagModule:OnCmdFilterClassify(filter, itemList)
  local bagItemList = {}
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].filterData.bagitem_id)
        if bagItemConf then
          local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
          local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
          if skillConf.Skill_Type == enum then
            table.insert(bagItemList, itemList[i])
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function BagModule:OnCmdFilterSkillStone(filter, itemList)
  local filterList = {}
  filterList = self:OnCmdFilterPet(filter.FilterPetCondition, itemList)
  filterList = self:OnCmdFilterDepart(filter.FilterDepartCondition, filterList)
  filterList = self:OnCmdFilterClassify(filter.FilterClassifyCondition, filterList)
  return filterList
end

function BagModule:OnCmdOpenEvolutionarySelectPanel(evolutionaryPetList)
  if self:HasPanel("EvolutionaryAgentUse") then
    local panel = self:GetPanel("EvolutionaryAgentUse")
    panel:ClosePanel()
  end
  self:OpenPanel("EvolutionaryAgentUse", self.data.PurificationEnum.SELECT, evolutionaryPetList)
end

function BagModule:OnCmdSetEvolutionarySelectedItem(petData)
  self.data:SetEvolutionarySelectedItem(petData)
end

function BagModule:OnCmdOpenEvolutionaryUsePanel()
  if self:HasPanel("EvolutionaryAgentUse") then
    local panel = self:GetPanel("EvolutionaryAgentUse")
    panel:ClosePanel()
  end
  local selectPetData = self.data:GetEvolutionarySelectedItem()
  self:OpenPanel("EvolutionaryAgentUse", self.data.PurificationEnum.USE, selectPetData)
end

function BagModule:OnCmdUseEvolutionaryItem()
  local evolutionaryPet = self.data.curEvolutionarySelectedItem
  if evolutionaryPet and evolutionaryPet[1].gid then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.RecycleBattlePetByGid, evolutionaryPet[1].gid)
    self:OnCmdZoneUseBagItemReq(self.data.curSelectedItemData.gid, self.data.curSelectedItemData.id, 1, evolutionaryPet[1].gid)
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.viewObj then
      local rideComponent = localPlayer.viewObj.BP_RideComponent
      if rideComponent and rideComponent.ScenePet then
        local rideGid = rideComponent.ScenePet.gid
        if rideGid == evolutionaryPet[1].gid then
          localPlayer:StopRide(true)
          localPlayer.abilityComponent:StopAbility(true)
        end
      end
    end
  else
    Log.Error("\231\188\147\229\173\152\231\154\132\229\135\128\229\140\150\231\178\190\231\129\181\230\149\176\230\141\174\230\156\137\233\151\174\233\162\152\239\188\129\239\188\129\239\188\129")
  end
end

function BagModule:OnCmdOpenEvolutionarySuccessPanel(petData)
  if self:HasPanel("EvolutionaryAgentUse") then
    local panel = self:GetPanel("EvolutionaryAgentUse")
    panel:ClosePanel()
  end
  self:OpenPanel("EvolutionaryAgentUse", self.data.PurificationEnum.SUCCESS, petData)
end

function BagModule:OnCmdOpenBagUsePopupSuccessPanel(PetData, BagItem, ChangeBlood)
  self:OpenPanel("BagBloodSuccessPopup", true, {
    PetData = PetData,
    BagItem = BagItem,
    ChangeBlood = ChangeBlood
  })
end

function BagModule:OnCmdOpenTalentPopupSuccessPanel(PetData, BagItem, ChangeTalentType, ResultTalentType)
  self:OpenPanel("BagTalentSuccessPopup", true, nil, {
    PetData = PetData,
    BagItem = BagItem,
    ChangeTalentType = ChangeTalentType,
    ResultTalentType = ResultTalentType
  })
end

function BagModule:OnCmdOpenCharacterPopupSuccessPanel(PetData, BagItem)
  self:OpenPanel("CharacterPopupSuccessPanel", true, {PetData = PetData, BagItem = BagItem})
end

function BagModule:OnCmdOpenBagBright()
  self:OpenPanel("BagBright")
end

function BagModule:OnCmdTestOpenHatchPanel()
  local info = self.data.CacheHatchEggItem
  if info then
    self:OpenPanel("Hatch", info)
  else
    Log.Error("\231\178\190\231\129\181\232\155\139\228\191\161\230\129\175\228\184\186\231\169\186\239\188\140\233\156\128\232\166\129\230\156\137\231\178\190\231\129\181\232\155\139\230\137\141\232\131\189\230\137\147\229\188\128")
  end
end

function BagModule:OnCmdOpenGiftVoucherSharing(giftVoucherData)
  self:OpenPanel("UMG_GiftVoucherSharing", giftVoucherData)
end

function BagModule:OnCmdCloseGiftVoucherSharing()
  if self:HasPanel("UMG_GiftVoucherSharing") then
    self:ClosePanel("UMG_GiftVoucherSharing")
  end
end

function BagModule:OnPlayUniversalTips()
  if self:HasPanel("UniversalTips") then
    self:ClosePanel("UniversalTips")
  end
  self:OpenPanel("UniversalTips", self)
end

function BagModule:OnCmdGetBagBloodIsSelected()
  if self:HasPanel("BagBlood") then
    local panel = self:GetPanel("BagBlood")
    if panel then
      return panel:GetIsSelectBtn()
    end
  end
  return true
end

function BagModule:OnCmdCheckHadUseBall()
  local itemList = self.data:GetPlayerThrowBallList()
  if not itemList or 0 == #itemList then
    return nil
  end
  return itemList
end

function BagModule:OnCmdOpenCulturalActivitiesShaer()
  local shareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, _G.Enum.ShareButtonType.SBT_ACTIVITY_SIM)
  if shareIsOpen then
    self:OpenPanel("UMG_CulturalActivitiesShaer")
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.SIM_bagitem_conceal_state_tips, nil, nil, 1)
  end
end

function BagModule:OnCmdOpenCulturalActivitiesTips()
  self:OpenPanel("UMG_CulturalActivitiesTips")
end

function BagModule:OnCmdOnSetEggIconFinished(panelName)
  if panelName and "BagMain" == panelName and self:HasPanel("BagMain") then
    local panel = self:GetPanel("BagMain")
    if panel then
      panel:OnHasItemSwitcherShow()
    end
  end
end

function BagModule:OnCmdOnZoneUpdateBagItemIdFlagReq(ballId, flag)
  local req = _G.ProtoMessage:newZoneUpdateBagItemIdFlagReq()
  req.bag_item_id_flags = {
    {id = ballId, flag = flag}
  }
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UPDATE_BAG_ITEM_ID_FLAG_REQ, req, self, self.OnZoneUpdateBagItemIdFlagRsp, false)
end

function BagModule:OnZoneUpdateBagItemIdFlagRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SaveBallCollectList(rsp.bag_item_id_flags.bag_flag_items)
    local sortList = self.data:GetCurSortList()
    local itemType = self.data:GetCurItemType()
    local curSortType = sortList[self.data.SortSelectIndex]
    self.data:SetTabSortListSortType(itemType, curSortType)
    self:DispatchEvent(BagModuleEvent.SetSortType, itemType, curSortType)
  else
    local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
  end
end

function BagModule:OnCmdGetBallNormalSortList(itemList)
  return self.data:OnGetBallNormalSortList(itemList)
end

function BagModule:OnCheckBallIsCollectOptimization(ballId)
  return self.data:OnCheckBallIsCollectOptimization(ballId)
end

function BagModule:OnCmdCheckIsSpeciesMedal(MedalConf)
  if MedalConf.medal_type == _G.Enum.MedalType.MT_SPECIES then
    return true
  elseif MedalConf.medal_type == _G.Enum.MedalType.MT_BOND then
    local MedalBondConfList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.MEDAL_BOND_CONF):GetAllDatas()
    for _, MedalBondConf in pairs(MedalBondConfList) do
      if MedalBondConf.medal_id == MedalConf.id then
        if 1 == MedalBondConf.is_species_range then
          return true
        else
          return false
        end
      end
    end
  end
  return false
end

function BagModule:OnCmdGetOriginalPet(baseConfId)
  local petConf = _G.DataConfigManager:GetPetbaseConf(baseConfId)
  if petConf then
    local petEvoId = petConf.pet_evolution_id[1]
    local evoConf = _G.DataConfigManager:GetPetEvolutionConf(petEvoId)
    if evoConf and evoConf.evolution_chain and evoConf.evolution_chain[1] and evoConf.evolution_chain[1].petbase_id then
      return evoConf.evolution_chain[1].petbase_id, evoConf.evolution_chain[1].pet_name
    end
  end
  return 0, ""
end

function BagModule:OnCmdOpenBagExpiredItemsConversion()
  local req = _G.ProtoMessage:newZoneBagItemExpireConvertReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BAG_ITEM_EXPIRE_CONVERT_REQ, req, self, self.ZoneBagItemExpireConvertRsp)
end

function BagModule:ZoneBagItemExpireConvertRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local filteredItems = {}
    local currentTime = _G.ZoneServer:GetServerTime() / 1000
    if rsp.bag_item_expire_list and rsp.bag_item_expire_list.items then
      Log.Debug("BagModule:ZoneBagItemExpireConvertRsp", #rsp.bag_item_expire_list.items)
      for _, itemInfo in ipairs(rsp.bag_item_expire_list.items) do
        table.insert(filteredItems, itemInfo)
      end
    end
    if #filteredItems > 0 then
      Log.Debug("BagModule:filteredItems", #filteredItems)
      local beforeConvertList = {}
      local afterConvertList = {}
      local expireGidList = {}
      if filteredItems then
        for _, expireInfo in ipairs(filteredItems) do
          if expireInfo.gid then
            table.insert(expireGidList, expireInfo.gid)
          end
          local bFound = false
          for _, existingItem in ipairs(beforeConvertList) do
            if existingItem.itemId == expireInfo.id then
              local bagItemConf = _G.DataConfigManager:GetBagItemConf(expireInfo.id)
              if bagItemConf and bagItemConf.can_stack and 1 == bagItemConf.can_stack then
                existingItem.itemNum = existingItem.itemNum + (expireInfo.num or 1)
                bFound = true
              end
              break
            end
          end
          if not bFound then
            local beforeItem = _G.NRCCommonItemIconData()
            beforeItem.itemType = _G.Enum.GoodsType.GT_BAGITEM
            beforeItem.itemId = expireInfo.id
            beforeItem.itemNum = expireInfo.num or 1
            beforeItem.IsShowExpire = true
            beforeItem.bShowNum = true
            beforeItem.bShowTip = true
            table.insert(beforeConvertList, beforeItem)
          end
        end
        afterConvertList = BagModuleUtils.GetConvertAfterItemsList(filteredItems)
      end
      if #afterConvertList > 0 then
        self:OpenPanel("BagExpiredItemsConversion", beforeConvertList, afterConvertList, expireGidList, rsp.ret_info.goods_reward)
      elseif expireGidList and #expireGidList > 0 then
        Log.Debug("BagModule:expireGidList")
        _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.ZoneBagItemExpireCheckReq, expireGidList)
      end
    end
  else
    local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
  end
end

function BagModule:OnCmdSendZoneCheckBagItemExpireReq(gidList)
  if not gidList or 0 == #gidList then
    return
  end
  local req = _G.ProtoMessage:newZoneBagItemExpireCheckReq()
  req.gids = gidList
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BAG_ITEM_EXPIRE_CHECK_REQ, req, self, self.ZoneCheckBagItemExpireRsp)
end

function BagModule:ZoneCheckBagItemExpireRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
  else
    local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
  end
end

return BagModule
