local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUIModule = NRCModuleBase:Extend("PetUIModule")
local DUPLICATE_PAK_SENDING_LIMIT_TIME = 5

function PetUIModule:OnConstruct()
  _G.PetUIModuleCmd = require("NewRoco.Modules.System.PetUI.PetUIModuleCmd")
  self.data = self:SetData("PetUIModuleData", "NewRoco.Modules.System.PetUI.PetUIModuleData")
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SYNC_NOTIFY, self.ListeningPetChange)
end

function PetUIModule:OnActive()
  self:RegisterCmd(PetUIModuleCmd.OpenPanelPetMain, self.OnCmdOpenPetMainPanel)
  self:RegisterCmd(PetUIModuleCmd.EnablePanelPetMain, self.EnablePanelPetMain)
  self:RegisterCmd(PetUIModuleCmd.PreLoadPetMain, self.PreLoadPetMain)
  self:RegisterCmd(PetUIModuleCmd.RefreshPetRightPanel, self.CmdRefreshPetRightPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePanelPetMain, self.OnCmdClosePetMainPanel)
  self:RegisterCmd(PetUIModuleCmd.EquipSkill2, self.OnCmdEquipSkill2)
  self:RegisterCmd(PetUIModuleCmd.UseExpItem, self.OnCmdUseExpItem)
  self:RegisterCmd(PetUIModuleCmd.CloseAllPetShareTeamDiffPanel, self.CmdCloseAllPetShareTeamDiffPanel)
  self:RegisterCmd(PetUIModuleCmd.ChangePetPos2, self.OnCmdChangePetPos2)
  self:RegisterCmd(PetUIModuleCmd.SendPetEvoluteReq, self.OnCmdSendPetEvoluteReq)
  self:RegisterCmd(PetUIModuleCmd.SendFangShengPet, self.OnCmdSendFangShengPet)
  self:RegisterCmd(PetUIModuleCmd.OnCloseCommonTips, self.OnCmdCloseCommonTips)
  self:RegisterCmd(PetUIModuleCmd.OpenRechristenPanel, self.OnCmdOpenRechristenPanel)
  self:RegisterCmd(PetUIModuleCmd.repetname, self.OnCmdrepetname)
  self:RegisterCmd(PetUIModuleCmd.OpenRechristen_1Panel, self.OnCmdOpenRechristen_1Panel)
  self:RegisterCmd(PetUIModuleCmd.PetUpgradePopout, self.OnCmdPetUpgradePopout)
  self:RegisterCmd(PetUIModuleCmd.PetGrowUp, self.OnCmdPetGrowUp)
  self:RegisterCmd(PetUIModuleCmd.PetInspire, self.OnCmdPetInspire)
  self:RegisterCmd(PetUIModuleCmd.PetBreakThrough, self.OnCmdPetBreakThrough)
  self:RegisterCmd(PetUIModuleCmd.CmdTalentRestorePopup, self.ShowChangeTalentRestorePopup)
  self:RegisterCmd(PetUIModuleCmd.SendZonePetTeamFriendMirrorReq, self.CmdSendZonePetTeamFriendMirrorReq)
  self:RegisterCmd(PetUIModuleCmd.OpenFriendMirrorPetTeamCoverPanel, self.CmdOpenFriendMirrorPetTeamCoverPanel)
  self:RegisterCmd(PetUIModuleCmd.PetSort, self.OnPetSort)
  self:RegisterCmd(PetUIModuleCmd.OpenPetFreePanel, self.OnCmdOpenPetFreePanel)
  self:RegisterCmd(PetUIModuleCmd.OpenBackpackPetFreePanel, self.OnCmdOpenBackpackPetFreePanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetBag, self.OnCmdOpenPetBag)
  self:RegisterCmd(PetUIModuleCmd.ChangePetBackInfoInfo, self.OnCmdChangePetBackInfoInfo)
  self:RegisterCmd(PetUIModuleCmd.ChangePetTeamsInfo, self.OnCmdChangePetTeamsInfo)
  self:RegisterCmd(PetUIModuleCmd.ChangePetTeamInfo, self.OnCmdChangePetTeamInfo)
  self:RegisterCmd(PetUIModuleCmd.ChangePetTeamName, self.OnCmdChangePetTeamName)
  self:RegisterCmd(PetUIModuleCmd.ChangePetTeamRoleMagicGid, self.OnCmdChangePetTeamRoleMagicGid)
  self:RegisterCmd(PetUIModuleCmd.ChangePetMainTeams, self.OnCmdChangePetMainTeam)
  self:RegisterCmd(PetUIModuleCmd.EquipPossesion, self.OnCmdEquipPossesion)
  self:RegisterCmd(PetUIModuleCmd.HavingUpgrade, self.OnCmdHavingUpgrade)
  self:RegisterCmd(PetUIModuleCmd.HavingResonance, self.OnCmdHavingResonance)
  self:RegisterCmd(PetUIModuleCmd.RemovePossession, self.OnCmdRemovePossession)
  self:RegisterCmd(PetUIModuleCmd.SavaPetSortIndex, self.OnCmdSavaPetSortIndex)
  self:RegisterCmd(PetUIModuleCmd.GetIsCanExchangePet, self.OnCmdGetIsCanExchangePet)
  self:RegisterCmd(PetUIModuleCmd.SetChooseTypeListTemporary, self.OnCmdSetChooseTypeListTemporary)
  self:RegisterCmd(PetUIModuleCmd.GetChooseTypeListTemporary, self.OnCmdGetChooseTypeListTemporary)
  self:RegisterCmd(PetUIModuleCmd.IsFirstLoadBackground, self.CmdIsFirstLoadBackground)
  self:RegisterCmd(PetUIModuleCmd.SetIsFirstLoadBackground, self.OnCmdSetIsFirstLoadBackground)
  self:RegisterCmd(PetUIModuleCmd.UpdateHavingPanelInfo, self.OnCmdUpdateHavingPanelInfo)
  self:RegisterCmd(PetUIModuleCmd.GetEquipProssession, self.OnCmdGetEquipProssession)
  self:RegisterCmd(PetUIModuleCmd.SetEquipProssession, self.OnCmdSetEquipProssession)
  self:RegisterCmd(PetUIModuleCmd.AutoSupplyCarryon, self.OnCmdAutoSupplyCarryon)
  self:RegisterCmd(PetUIModuleCmd.GetEvoBaseBaseId, self.OnCmdGetEvoBaseBaseId)
  self:RegisterCmd(PetUIModuleCmd.OnChangePetTeamsInfoForTeam, self.OnChangePetTeamsInfoForTeam)
  self:RegisterCmd(PetUIModuleCmd.GetSkillNew, self.GetSkillNew)
  self:RegisterCmd(PetUIModuleCmd.RemoveSkillNew, self.RemoveSkillNew)
  self:RegisterCmd(PetUIModuleCmd.GetSkillsHasNew, self.GetSkillsHasNew)
  self:RegisterCmd(PetUIModuleCmd.OpenPetHatchingReview, self.OnCmdOpenPetHatchingReview)
  self:RegisterCmd(PetUIModuleCmd.OpenPetEvolutionItemPanel, self.OnCmdOpenPetEvolutionItemPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetEvolutionTaskPanel, self.OnCmdOpenPetEvolutionTaskPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetEvolutionRewardPanel, self.OnCmdOpenPetEvolutionRewardPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetEvolutionFinishPanel, self.OnCmdOpenPetEvolutionFinishPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetEvolutionFinishPanel, self.OnCmdClosePetEvolutionFinishPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetDetailedInfoPanel, self.OnCmdOpenPetDetailedInfo)
  self:RegisterCmd(PetUIModuleCmd.OnOpenPetHavingFitTogether, self.OnCmdOpenPetHavingFitTogether)
  self:RegisterCmd(PetUIModuleCmd.OpenPetEvoPanel, self.OnCmdOpenPetEvoPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetEvoNewPanel, self.OnCmdOpenPetEvoNewPanel)
  self:RegisterCmd(PetUIModuleCmd.GetPetHeadSlotScreenPos, self.OnCmdGetPetHeadSlotScreenPos)
  self:RegisterCmd(PetUIModuleCmd.OpenPetTeamPanel, self.OnCmdOpenPetTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetTeamPanel, self.OnCmdClosePetTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.PetTeamSetBtnCloseState, self.OnPetTeamSetBtnCloseState)
  self:RegisterCmd(PetUIModuleCmd.PetMainOpenPvPPetTeamPanel, self.OnCmdPetMainOpenPvPPetTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenWorldPetTeamPanel, self.OnCmdOpenWorldPetTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPvPPetTeamPanel, self.OnCmdOpenPvPPetTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.PlayPetTeamOpenAnimation, self.OnCmdPlayPetTeamOpenAnimation)
  self:RegisterCmd(PetUIModuleCmd.OpenPetTeamResonancePanel, self.OnCmdOpenPetTeamResonancePanel)
  self:RegisterCmd(PetUIModuleCmd.RefreshPetTeamPanel, self.OnCmdRefreshPetTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.CmdSetSavePetTeamInfo, self.CmdSetSavePetTeamInfo)
  self:RegisterCmd(PetUIModuleCmd.CheckIsAnyUmgIsOpening, self.CheckIsAnyUmgIsOpening)
  self:RegisterCmd(PetUIModuleCmd.OpenPetwarehousePanel, self.OnCmdOpenPetWarehousePanel)
  self:RegisterCmd(PetUIModuleCmd.PlayPetEvoSkill, self.PlayPetEvoSkill)
  self:RegisterCmd(PetUIModuleCmd.SetPetSkillLoopState, self.OnCmdSetPetSkillLoopState)
  self:RegisterCmd(PetUIModuleCmd.OnClickSwitchPanelByIndex, self.OnCmdOnClickSwitchPanelByIndex)
  self:RegisterCmd(PetUIModuleCmd.ShowPetWarehouseTips, self.OnCmdShowPetWarehouseTips)
  self:RegisterCmd(PetUIModuleCmd.OnClickReversedSort, self.OnCmdPetWarehouseReverseSort)
  self:RegisterCmd(PetUIModuleCmd.OnTypeChooseBtnClicked, self.OnCmdOnTypeChooseBtnClicked)
  self:RegisterCmd(PetUIModuleCmd.OnTypeChooseChanged, self.OnCmdOnTypeChooseChanged)
  self:RegisterCmd(PetUIModuleCmd.GetTypeChooseNum, self.OnCmdGetTypeChooseNum)
  self:RegisterCmd(PetUIModuleCmd.SetPetWarehouseTipBtnEnable, self.OnCmdSetPetWarehouseTipBtnEnable)
  self:RegisterCmd(PetUIModuleCmd.SetIsBagToOpenPanel, self.OnCmdSetIsBagToOpenPanel)
  self:RegisterCmd(PetUIModuleCmd.GetIsBagToOpenPanel, self.OnCmdGetIsBagToOpenPanel)
  self:RegisterCmd(PetUIModuleCmd.SetOpenPanelPetData, self.OnCmdSetOpenPanelPetData)
  self:RegisterCmd(PetUIModuleCmd.GetOpenPanelPetData, self.OnCmdGetOpenPanelPetData)
  self:RegisterCmd(PetUIModuleCmd.GetOpenPanelPetDataRedPoint, self.OnCmdGetOpenPanelPetDataRedPoint)
  self:RegisterCmd(PetUIModuleCmd.SetPetSelectIndex, self.OnCmdSetPetSelectIndex)
  self:RegisterCmd(PetUIModuleCmd.SetOpenPetSKill, self.OnCmdSetOpenPetSKill)
  self:RegisterCmd(PetUIModuleCmd.GetPetSelectIndex, self.OnCmdGetPetSelectIndex)
  self:RegisterCmd(PetUIModuleCmd.GetOpenPetSKill, self.OnCmdGetOpenPetSKill)
  self:RegisterCmd(PetUIModuleCmd.SetPvpSkillData, self.OnCmdSetPvpSkillData)
  self:RegisterCmd(PetUIModuleCmd.GetPvpSkillData, self.OnCmdGetPvpSkillData)
  self:RegisterCmd(PetUIModuleCmd.GetPvpTeamParam, self.OnCmdGetPvpTeamParam)
  self:RegisterCmd(PetUIModuleCmd.PvpEquipSkillsByTeamType, self.OnCmdPvpEquipSkillsByTeamType)
  self:RegisterCmd(PetUIModuleCmd.OpenPetReportPanel, self.OpenPetReportPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenTestPetReportPanel, self.OpenTestPetReportPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetReportPanel, self.ClosePetReportPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetTeamManagementPanel, self.OnCmdOpenPetTeamManagementPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetTeamManagementPanel, self.ClosePetTeamManagementPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetTeamReplacePanel, self.OpenPetTeamReplacePanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetTeamReplacePanel, self.ClosePetTeamReplacePanel)
  self:RegisterCmd(PetUIModuleCmd.AnimClosePetTeamReplacePanel, self.AnimClosePetTeamReplacePanel)
  self:RegisterCmd(PetUIModuleCmd.PetTeamHasCommonEvolution, self.OnPetTeamHasCommonEvolution)
  self:RegisterCmd(PetUIModuleCmd.PetTeamReplaceGetCurMode, self.OnPetTeamReplaceGetCurMode)
  self:RegisterCmd(PetUIModuleCmd.PetTeamReplaceGetCurExChangeState, self.OnPetTeamReplaceGetCurExChangeState)
  self:RegisterCmd(PetUIModuleCmd.PetTeamReplaceGetCurSelectIsInTeam, self.OnPetTeamReplaceGetCurSelectIsInTeam)
  self:RegisterCmd(PetUIModuleCmd.PetTeamReplaceGetCurSelPetDataGid, self.OnPetTeamReplaceGetCurSelPetDataGid)
  self:RegisterCmd(PetUIModuleCmd.IsPetTeamReplaceTrialPetExpired, self.IsPetTeamReplaceTrialPetExpired)
  self:RegisterCmd(PetUIModuleCmd.UpdatePetWareHouseMainInfo, self.OnCmdUpdatePetWareHouseMainInfo)
  self:RegisterCmd(PetUIModuleCmd.SetPetNewStateInfo, self.OnCmdSetPetNewStateInfo)
  self:RegisterCmd(PetUIModuleCmd.OpenPetSKillTips, self.OnCmdOpenPetSKillTips)
  self:RegisterCmd(PetUIModuleCmd.OpenBagSKillTips, self.OnCmdOpenBagSKillTips)
  self:RegisterCmd(PetUIModuleCmd.OpenBagSKillTipsTop, self.OnCmdOpenBagSKillTipsTop)
  self:RegisterCmd(PetUIModuleCmd.CloseBagSKillTips, self.OnCmdCloseBagSKillTips)
  self:RegisterCmd(PetUIModuleCmd.GetPetSKillTipsCurShowSkillId, self.GetPetSKillTipsCurShowSkillId)
  self:RegisterCmd(PetUIModuleCmd.ClosePetSKillTips, self.OnCmdClosePetSKillTips)
  self:RegisterCmd(PetUIModuleCmd.GetBagSKillTipsCurShowSkillId, self.GetBagSKillTipsCurShowSkillId)
  self:RegisterCmd(PetUIModuleCmd.SetOpenPetAttribute, self.SetOpenPetAttribute)
  self:RegisterCmd(PetUIModuleCmd.GetOpenPetAttribute, self.GetOpenPetAttribute)
  self:RegisterCmd(PetUIModuleCmd.GetOpenPetBag, self.GetOpenPetBag)
  self:RegisterCmd(PetUIModuleCmd.SetOpenPetBag, self.SetOpenPetBag)
  self:RegisterCmd(PetUIModuleCmd.OpenPetBloodPulse, self.OnCmdOpenPetBloodPulse)
  self:RegisterCmd(PetUIModuleCmd.OpenPetBloodPulseStatistics, self.OnCmdOpenPetBloodPulseStatistics)
  self:RegisterCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode, self.OnCmdGetPetPortableBagReleaseLifeMode)
  self:RegisterCmd(PetUIModuleCmd.CheckPetIsInFreeListInPortableBag, self.OnCmdCheckPetIsInFreeListInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.GetBoxFreePetNumInPortableBag, self.OnCmdGetBoxFreePetNumInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.SetCurSelectItemTypeInPortableBag, self.SetCurSelectItemTypeInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.GetCurSelectItemTypeInPortableBag, self.GetCurSelectItemTypeInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.SetCurSelectPetGIDInPortableBag, self.SetCurSelectPetGIDInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.GetCurSelectPetGIDInPortableBag, self.GetCurSelectPetGIDInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.SetCurShowTeamIndexInPortableBag, self.SetCurShowTeamIndexInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.GetCurShowTeamIndexInPortableBag, self.GetCurShowTeamIndexInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.SetCurShowPageIndexInPortableBag, self.SetCurShowPageIndexInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.GetCurShowPageIndexInPortableBag, self.GetCurShowPageIndexInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.SetCurSelectInfoInPortableBag, self.SetCurSelectInfoInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.GetCurSelectInfoInPortableBag, self.GetCurSelectInfoInPortableBag)
  self:RegisterCmd(PetUIModuleCmd.CheckPetIsCanFree, self.OnCmdCheckPetIsCanFree)
  self:RegisterCmd(PetUIModuleCmd.CloseTipsPanel, self.OnCmdClosePetBloodPulse)
  self:RegisterCmd(PetUIModuleCmd.GetCurSelectImpressionIndex, self.OnCmdGetCurSelectImpressionIndex)
  self:RegisterCmd(PetUIModuleCmd.SetCurSelectImpressionIndex, self.OnCmdSetCurSelectImpressionIndex)
  self:RegisterCmd(PetUIModuleCmd.ZoneUnlockPetHabitReq, self.OnCmdZoneUnlockPetHabitReq)
  self:RegisterCmd(PetUIModuleCmd.OpenImpressionUnLockPanel, self.OnCmdOpenImpressionUnLockPanel)
  self:RegisterCmd(PetUIModuleCmd.GetPetUiMenuIndex, self.OnCmdGetPetUiMenuIndex)
  self:RegisterCmd(PetUIModuleCmd.SetPetUiMenuIndex, self.OnCmdSetPetUiMenuIndex)
  self:RegisterCmd(PetUIModuleCmd.ZoneGetHatchStatusReq, self.OnCmdZoneGetHatchStatusReq)
  self:RegisterCmd(PetUIModuleCmd.ZoneStopHatchReq, self.OnCmdZoneStopHatchReq)
  self:RegisterCmd(PetUIModuleCmd.ZoneCrackEggReq, self.OnCmdZoneCrackEggReq)
  self:RegisterCmd(PetUIModuleCmd.OnClickPetImage3d, self.OnCmdClickPetImage3d)
  self:RegisterCmd(PetUIModuleCmd.SetEggPlayAnimaTime, self.SetEggPlayAnimaTime)
  self:RegisterCmd(PetUIModuleCmd.CheckIsEggPlayAnima, self.CheckIsEggPlayAnima)
  self:RegisterCmd(PetUIModuleCmd.OpenEggIncubatePanel, self.OnCmdOpenEggIncubatePanel)
  self:RegisterCmd(PetUIModuleCmd.UpdateEggIncubatePanel, self.OnCmdUpdateEggIncubatePanel)
  self:RegisterCmd(PetUIModuleCmd.CloseEggIncubatePanel, self.OnCmdCloseEggIncubatePanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetHatchOnlyPanel, self.OnCmdOpenPetHatchOnlyPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetHatchOnlyPanel, self.OnCmdClosePetHatchOnlyPanel)
  self:RegisterCmd(PetUIModuleCmd.GetEggFinshOpenAttribute, self.OnCmdGetEggFinshOpenAttribute)
  self:RegisterCmd(PetUIModuleCmd.SetEggFinshOpenAttribute, self.OnCmdSetEggFinshOpenAttribute)
  self:RegisterCmd(PetUIModuleCmd.GetEggSpeedActiveOpenState, self.OnCmdGetEggSpeedActiveOpenState)
  self:RegisterCmd(PetUIModuleCmd.GetEggIsCanGiveAwayByEggType, self.OnCmdGetEggIsCanGiveAwayByEggType)
  self:RegisterCmd(PetUIModuleCmd.CanNotContinueGrow, self.OnCmdCanNotContinueGrow)
  self:RegisterCmd(PetUIModuleCmd.SelectPetFood, self.OnCmdSelectPetFood)
  self:RegisterCmd(PetUIModuleCmd.OpenQualificationInterpretation, self.OnCmdOpenQualificationInterpretation)
  self:RegisterCmd(PetUIModuleCmd.SelectUpGradeItem, self.OnCmdSelectUpGradeItem)
  self:RegisterCmd(PetUIModuleCmd.CanSelectWareHouseItem, self.CmdCanSelectWareHouseItem)
  self:RegisterCmd(PetUIModuleCmd.SetCanSelectWareHouseItem, self.SetCmdCanSelectWareHouseItem)
  self:RegisterCmd(PetUIModuleCmd.CancelSelectWareHouseItem, self.CmdCancelSelectWareHouseItem)
  self:RegisterCmd(PetUIModuleCmd.ShowChangePetConfirm, self.ShowChangePetConfirm)
  self:RegisterCmd(PetUIModuleCmd.AttrTipsOpen, self.OnCmdAttrTipsOpen)
  self:RegisterCmd(PetUIModuleCmd.GetTipsOpenIndex, self.OnCmdGetTipsOpenIndex)
  self:RegisterCmd(PetUIModuleCmd.OpenPetHatchingPanel, self.OnCmdOpenPetHatchingPanel)
  self:RegisterCmd(PetUIModuleCmd.CheckIsPetHatchingPanelShow, self.OnCmdCheckIsPetHatchingPanelShow)
  self:RegisterCmd(PetUIModuleCmd.GetVaildPetBallItemList, self.OnCmdGetVaildPetBallItemList)
  self:RegisterCmd(PetUIModuleCmd.ClosePetHatchingPanel, self.OnCmdClosePetHatchingPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenChoosePetBallPanel, self.OnCmdOpenChoosePetBallPanel)
  self:RegisterCmd(PetUIModuleCmd.CloseChoosePetBallPanel, self.OnCmdCloseChoosePetBallPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenHatchingRightPanel, self.OnCmdOpenHatchingRightPanel)
  self:RegisterCmd(PetUIModuleCmd.CloseHatchingRightPanel, self.OnCmdCloseHatchingRightPanel)
  self:RegisterCmd(PetUIModuleCmd.UpdateHatchingRightPanel, self.OnCmdUpdateHatchingRightPanel)
  self:RegisterCmd(PetUIModuleCmd.GetHatchingRightPanelDisplayMode, self.OnCmdGetHatchingRightPanelDisplayMode)
  self:RegisterCmd(PetUIModuleCmd.OpenColorfulMatchingTips, self.OnCmdOpenColorfulMatchingTips)
  self:RegisterCmd(PetUIModuleCmd.UpdateHatchingRightPanelCommonAddSubtractPanel, self.OnCmdUpdateHatchingRightPanelCommonAddSubtractPanel)
  self:RegisterCmd(PetUIModuleCmd.SetPetVisualParam, self.OnCmdSetPetVisualParam)
  self:RegisterCmd(PetUIModuleCmd.GetPetVisualParam, self.OnCmdGetPetVisualParam)
  self:RegisterCmd(PetUIModuleCmd.SetPetModelScaleAndOffset, self.OnSetPetModelScaleAndOffset)
  self:RegisterCmd(PetUIModuleCmd.AddPetModelBlackAnim, self.OnAddPetModelBlackAnim)
  self:RegisterCmd(PetUIModuleCmd.SetIsPlayPetSkill, self.OnCmdSetIsPlayPetSkill)
  self:RegisterCmd(PetUIModuleCmd.GetIsPlayPetSkill, self.OnCmdGetIsPlayPetSkill)
  self:RegisterCmd(PetUIModuleCmd.IsHavePetSkillTips, self.OnCmdIsHavePetSkillTips)
  self:RegisterCmd(PetUIModuleCmd.OpenFilterPanel, self.CmdOpenFilterPanel)
  self:RegisterCmd(PetUIModuleCmd.FoodClickAddOrDelItem, self.CmdFoodClickAddOrDelItem)
  self:RegisterCmd(PetUIModuleCmd.OpenSortPanel, self.CmdOpenSortPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenExChangeMainPetPanel, self.CmdOpenExChangeMainPetPanel)
  self:RegisterCmd(PetUIModuleCmd.GetRandomPetBonusPanelState, self.OnCmdGetRandomPetBonusPanelState)
  self:RegisterCmd(PetUIModuleCmd.SetRandomPetBonusPanelState, self.OnCmdSetRandomPetBonusPanelState)
  self:RegisterCmd(PetUIModuleCmd.OpenRightPanel, self.OpenRightPanel)
  self:RegisterCmd(PetUIModuleCmd.CloseRightPanel, self.CloseRightPanel)
  self:RegisterCmd(PetUIModuleCmd.HideRightPanel, self.HideRightPanel)
  self:RegisterCmd(PetUIModuleCmd.ShowRightPanel, self.ShowRightPanel)
  self:RegisterCmd(PetUIModuleCmd.HideTipsPanel, self.HideTipsPanel)
  self:RegisterCmd(PetUIModuleCmd.ShowTipsPanel, self.ShowTipsPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenToBagMainPanelByOpenType, self.CmdOpenToBagMainPanelByOpenType)
  self:RegisterCmd(PetUIModuleCmd.SetPetBagOpenState, self.SetPetBagOpenState)
  self:RegisterCmd(PetUIModuleCmd.GetPetBagOpenState, self.GetPetBagOpenState)
  self:RegisterCmd(PetUIModuleCmd.OpenPetBagPanel, self.OpenPetBagPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetBagPanel, self.ClosePetBagPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetSkillTipsPanel, self.ClosePetSkillTipsPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenGrowUpPanel, self.OpenGrowUpPanel)
  self:RegisterCmd(PetUIModuleCmd.CloseGrowUpPanel, self.CloseGrowUpPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenLevelUpPanel, self.OpenLevelUpPanel)
  self:RegisterCmd(PetUIModuleCmd.ClearSkillList, self.OnCmdClearSkillList)
  self:RegisterCmd(PetUIModuleCmd.LeftPanelRefresh, self.LeftPanelRefresh)
  self:RegisterCmd(PetUIModuleCmd.AttributePanelRefresh, self.AttributePanelRefresh)
  self:RegisterCmd(PetUIModuleCmd.ShowPetLevelUp, self.ShowPetLevelUp)
  self:RegisterCmd(PetUIModuleCmd.IsPetHatchingPanel, self.IsPetHatchingPanel)
  self:RegisterCmd(PetUIModuleCmd.PetUIOpenPetTips, self.OpenPetTips)
  self:RegisterCmd(PetUIModuleCmd.PetUIOpendblockerTips, self.OpenDBlockerTips)
  self:RegisterCmd(PetUIModuleCmd.PetUICloseblockerTips, self.CloseDBlockerTips)
  self:RegisterCmd(PetUIModuleCmd.OpenPetRateTip, self.OnCmdOpenPetRateTip)
  self:RegisterCmd(PetUIModuleCmd.PetUIOpenPetBloodPulse, self.OpenPetBloodPulse)
  self:RegisterCmd(PetUIModuleCmd.OpenPetFreeMainPanel, self.CmdOpenPetFreeMainPanel)
  self:RegisterCmd(PetUIModuleCmd.SetPetItemClickAble, self.OnCmdSetPetItemClickAble)
  self:RegisterCmd(PetUIModuleCmd.SetPetWarehouseFreeInfo, self.CmdSetPetWarehouseFreeInfo)
  self:RegisterCmd(PetUIModuleCmd.SetPetCollect, self.CmdSetPetCollect)
  self:RegisterCmd(PetUIModuleCmd.OpenPetCollectPanel, self.CmdOpenPetCollectPanel)
  self:RegisterCmd(PetUIModuleCmd.SetEnterPetPanelType, self.OnCmdSetEnterPetPanelType)
  self:RegisterCmd(PetUIModuleCmd.OpenExChangeGrowUpPanel, self.OnCmdOpenExChangeGrowUpPanel)
  self:RegisterCmd(PetUIModuleCmd.ShowDescPanel, self.OnCmdShowDescPanel)
  self:RegisterCmd(PetUIModuleCmd.ShowDescRightPanel, self.OnCmdShowDescRightPanel)
  self:RegisterCmd(PetUIModuleCmd.ShowDescCampPanel, self.OnCmdShowDescCampPanel)
  self:RegisterCmd(PetUIModuleCmd.SetDescText, self.OnCmdSetDescText)
  self:RegisterCmd(PetUIModuleCmd.GetDescText, self.OnCmdGetDescText)
  self:RegisterCmd(PetUIModuleCmd.SetDescTextTable, self.OnCmdSetDescTextTable)
  self:RegisterCmd(PetUIModuleCmd.ClearModuleDescText, self.OnCmdClearModuleDescText)
  self:RegisterCmd(PetUIModuleCmd.ClearDescText, self.OnCmdClearDescText)
  self:RegisterCmd(PetUIModuleCmd.ResetRightPanelDescText, self.OnCmdResetRightPanelDescText)
  self:RegisterCmd(PetUIModuleCmd.ResetSkillTipDescText, self.OnCmdResetSkillTipDescText)
  self:RegisterCmd(PetUIModuleCmd.ShowBtnClosePanel, self.OnCmdShowBtnClosePanel)
  self:RegisterCmd(PetUIModuleCmd.HideBtnClosePanel, self.OnCmdHideBtnClosePanel)
  self:RegisterCmd(PetUIModuleCmd.OpenBloodLineMagic, self.OnCmdOpenBloodLineMagic)
  self:RegisterCmd(PetUIModuleCmd.SelectBloodItem, self.OnCmdSelectBloodItem)
  self:RegisterCmd(PetUIModuleCmd.EquipProtagonistMagicStateChanged, self.OnEquipProtagonistMagicStateChanged)
  self:RegisterCmd(PetUIModuleCmd.OpenMedalWonPanel, self.OnCmdOpenMedalWonPanel)
  self:RegisterCmd(PetUIModuleCmd.SelectMedalItem, self.OnCmdSelectMedalItem)
  self:RegisterCmd(PetUIModuleCmd.MedalOperation, self.OnCmdMedalOperation)
  self:RegisterCmd(PetUIModuleCmd.OpenTipsIndividualValu, self.OnCmdOpenTipsIndividualValu)
  self:RegisterCmd(PetUIModuleCmd.ResetPetRightPanelShareComboBox, self.OnCmdResetPetRightPanelShareComboBox)
  self:RegisterCmd(PetUIModuleCmd.ResetCanListenShareType, self.OnCmdResetCanListenShareType)
  self:RegisterCmd(PetUIModuleCmd.OpenShareCameraPanel, self.OnCmdOpenShareCameraPanel)
  self:RegisterCmd(PetUIModuleCmd.CloseShareCameraPanel, self.OnCmdCloseShareCameraPanel)
  self:RegisterCmd(PetUIModuleCmd.CloseMoreList, self.OnCmdCloseMoreList)
  self:RegisterCmd(PetUIModuleCmd.PlayShareVideoG6, self.OnCmdPlayShareVideoG6)
  self:RegisterCmd(PetUIModuleCmd.PlayShareCameraPanelCloseAnim, self.OnCmdPlayShareCameraPanelCloseAnim)
  self:RegisterCmd(PetUIModuleCmd.PlayShareVideoEnablePetMain, self.OnCmdPlayShareVideoEnablePetMain)
  self:RegisterCmd(PetUIModuleCmd.ShowRightPanelShareBtn, self.OnCmdShowRightPanelShareBtn)
  self:RegisterCmd(PetUIModuleCmd.SetPetMainPanelVisibility, self.OnCmdSetPetMainPanelVisibility)
  self:RegisterCmd(PetUIModuleCmd.SetPetMainShareBtnVisibility, self.OnCmdSetPetMainShareBtnVisibility)
  self:RegisterCmd(PetUIModuleCmd.VideoShareResetPetMainPet3D, self.OnCmdVideoShareResetPetMainPet3D)
  self:RegisterCmd(PetUIModuleCmd.OpenShareOverlayPanel, self.OnCmdOpenShareOverlayPanel)
  self:RegisterCmd(PetUIModuleCmd.CloseShareOverlayPanel, self.OnCmdCloseShareOverlayPanel)
  self:RegisterCmd(PetUIModuleCmd.GetCanSharePet, self.OnCmdGetCanSharePet)
  self:RegisterCmd(PetUIModuleCmd.CloseShareSelectBox, self.OnCmdCloseShareSelectBox)
  self:RegisterCmd(PetUIModuleCmd.IsShareRecordVideo, self.OnCmdIsShareRecordVideo)
  self:RegisterCmd(PetUIModuleCmd.SetIsShareRecordVideo, self.OnCmdSetIsShareRecordVideo)
  self:RegisterCmd(PetUIModuleCmd.OpenDazzlingTipsPanel, self.OnCmdOpenDazzlingTipsPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenMutationTipsPanel, self.OnCmdOpenMutationTipsPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenTipsStrongPoint, self.OnCmdOpenTipsStrongPoint)
  self:RegisterCmd(PetUIModuleCmd.CloseTipsStrongPoint, self.OnCmdCloseTipsStrongPoint)
  self:RegisterCmd(PetUIModuleCmd.OpenPeculiarityTips, self.OnCmdOpenPeculiarityTips)
  self:RegisterCmd(PetUIModuleCmd.ClosePeculiarityTips, self.OnCmdClosePeculiarityTips)
  self:RegisterCmd(PetUIModuleCmd.OpenPetReleaseTips, self.CmdOpenPetReleaseTips)
  self:RegisterCmd(PetUIModuleCmd.OpenLineupShareAlchemy, self.CmdOpenLineupShareAlchemy)
  self:RegisterCmd(PetUIModuleCmd.GetLineupShareAlchemyByItemId, self.CmdGetLineupShareAlchemyByItemId)
  self:RegisterCmd(PetUIModuleCmd.TestOpenSkillMain, self.OnCmdTestOpenPetSkillMain)
  self:RegisterCmd(PetUIModuleCmd.GetMirrorPetDataByGid, self.CmdGetMirrorPetDataByGid)
  self:RegisterCmd(PetUIModuleCmd.TestOpenPetDetailedInfo, self.OnCmdTestOpenPetDetailedInfo)
  self:RegisterCmd(PetUIModuleCmd.PetRightPanelPcClose, self.OnCmdPetRightPanelPcClose)
  self:RegisterCmd(PetUIModuleCmd.TestOpenPedalPanel, self.OnCmdTestOpenPedalPanel)
  self:RegisterCmd(PetUIModuleCmd.IsCurrentlyInQualifying, self.OnCmdIsCurrentlyInQualifying)
  self:RegisterCmd(PetUIModuleCmd.SetInQualifyingState, self.OnCmdSetInQualifyingState)
  self:RegisterCmd(PetUIModuleCmd.OpenShareTeamPanel, self.OpenShareTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenShareTeamDiffOrLackPanel, self.CmdOpenShareTeamDiffOrLackPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenAdjustTeamPanel, self.OpenAdjustTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenFriendPetTeamPanel, self.OpenFriendPetTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenFriendPetTeamDetailPanel, self.OpenFriendPetTeamDetailPanel)
  self:RegisterCmd(PetUIModuleCmd.OnCmdOpenPetFilteringPanel, self.OnCmdOpenPetFilteringPanel)
  self:RegisterCmd(PetUIModuleCmd.OnPetFilterTypeSelect, self.OnPetFilterTypeSelect)
  self:RegisterCmd(PetUIModuleCmd.OnPetSkillFilterRuleChange, self.OnPetSkillFilterRuleChange)
  self:RegisterCmd(PetUIModuleCmd.OnPetSkillSortRuleChange, self.OnPetSkillSortRuleChange)
  self:RegisterCmd(PetUIModuleCmd.OnCmdOpenPetSortPanel, self.OnCmdOpenPetSortPanel)
  self:RegisterCmd(PetUIModuleCmd.SetIsShowPetNotUnlockSkill, self.SetIsShowPetNotUnlockSkill)
  self:RegisterCmd(PetUIModuleCmd.GetIsShowPetNotUnlockSkill, self.GetIsShowPetNotUnlockSkill)
  self:RegisterCmd(PetUIModuleCmd.OpenPetAlternative, self.OpenPetAlternative)
  self:RegisterCmd(PetUIModuleCmd.OpenSkillAlternative, self.OpenSkillAlternative)
  self:RegisterCmd(PetUIModuleCmd.TryOpenRevisePanelByType, self.CmdTryOpenRevisePanel)
  self:RegisterCmd(PetUIModuleCmd.OpenSkillLearningPanel, self.OpenSkillLearningPanel)
  self:RegisterCmd(PetUIModuleCmd.PetTeamShareQuickAdjust, self.OnPetTeamShareQuickAdjust)
  self:RegisterCmd(PetUIModuleCmd.OnUseBagItemSuccess, self.OnUseBagItemSuccess)
  self:RegisterCmd(PetUIModuleCmd.OnUseFormulaSuccess, self.OnUseFormulaSuccess)
  self:RegisterCmd(PetUIModuleCmd.OnSelectFormula, self.OnSelectFormula)
  self:RegisterCmd(PetUIModuleCmd.SetExchangeMaterial, self.SetExchangeMaterial)
  self:RegisterCmd(PetUIModuleCmd.OpenLoadPetTeamPanel, self.OpenLoadPetTeamPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenTeamChangeBloodPanel, self.OpenTeamChangeBloodPanel)
  self:RegisterCmd(PetUIModuleCmd.GetSkillSource, self.GetSkillSource)
  self:RegisterCmd(PetUIModuleCmd.GetSkillSourceAndUnlockInfo, self.GetSkillSourceAndUnlockInfo)
  self:RegisterCmd(PetUIModuleCmd.OpenSkillLearningPanel2, self.OpenSkillLearningPanel2)
  self:RegisterCmd(PetUIModuleCmd.CloseSkillLearningPanel2, self.CloseSkillLearningPanel2)
  self:RegisterCmd(PetUIModuleCmd.CalcuSkillLearningNeedItems, self.CalcuSkillLearningNeedItems)
  self:RegisterCmd(PetUIModuleCmd.CalcuBloodChangeNeedItems, self.CalcuBloodChangeNeedItems)
  self:RegisterCmd(PetUIModuleCmd.GetPetSkillUnLockInfo, self.OnCmdGetPetSkillUnLockInfo)
  self:RegisterCmd(PetUIModuleCmd.GetPetSkillUnLockInfoByLevelUp, self.OnCmdGetPetSkillUnLockInfoByLevelUp)
  self:RegisterCmd(PetUIModuleCmd.GetPetSkillUnLockInfoBySkillStone, self.OnCmdGetPetSkillUnLockInfoBySkillStone)
  self:RegisterCmd(PetUIModuleCmd.GetPetSkillUnLockInfoByChangeBlood, self.OnCmdGetPetSkillUnLockInfoByChangeBlood)
  self:RegisterCmd(PetUIModuleCmd.GetUseExpItemDosage, self.OnCmdGetUseExpItemDosage)
  self:RegisterCmd(PetUIModuleCmd.GetItemDosageBySynthesis, self.OnCmdGetItemDosageBySynthesis)
  self:RegisterCmd(PetUIModuleCmd.OpenAllDetailedMask, self.OnCmdOpenAllDetailedMask)
  self:RegisterCmd(PetUIModuleCmd.CloseAllDetailedTips, self.OnCmdCloseAllDetailedTips)
  self:RegisterCmd(PetUIModuleCmd.OpenAICoachRecommendTeamPanel, self.CmdOpenAICoachRecommendPanel)
  self:RegisterCmd(PetUIModuleCmd.OnZoneSaveRecommendPetTeamReq, self.OnZoneSaveRecommendPetTeamReq)
  self:RegisterCmd(PetUIModuleCmd.OnSubmitPet, self.OnCmdOnSubmitPet)
  self:RegisterCmd(PetUIModuleCmd.StartShowPetReportTips, self.OnCmdStartShowPetReportTips)
  self:RegisterCmd(PetUIModuleCmd.OnFinishPetReportReq, self.OnCmdOnFinishPetReportReq)
  self:RegisterCmd(PetUIModuleCmd.EndPetSubmitAction, self.OnCmdEndPetSubmitAction)
  self:RegisterCmd(PetUIModuleCmd.OpenPetReportParticulars, self.OnCmdOpenPetReportParticulars)
  self:RegisterCmd(PetUIModuleCmd.ClosePetReportReminder, self.OnCmdClosePetReportReminder)
  self:RegisterCmd(PetUIModuleCmd.OpenPetReportShare, self.OnCmdOpenPetReportShare)
  self:RegisterCmd(PetUIModuleCmd.SetPetReportPanelVisibility, self.OnCmdSetPetReportPanelVisibility)
  self:RegisterCmd(PetUIModuleCmd.IsInteger, self.OnCmdIsInteger)
  self:RegisterCmd(PetUIModuleCmd.GMSetPetUIScaleAndOffsetAndImageRevert, self.OnCmdGMSetPetUIScaleAndOffsetAndImageRevert)
  self:RegisterCmd(PetUIModuleCmd.GMOpenPetReportParticulars, self.OnCmdGMOpenPetReportParticulars)
  self:RegisterCmd(PetUIModuleCmd.GMChangePet, self.OnCmdGMChangePet)
  self:RegisterCmd(PetUIModuleCmd.GMChangePetReportBG, self.OnCmdGMChangePetReportBG)
  self:RegisterCmd(PetUIModuleCmd.GetPetReportParamInfo, self.GetPetReportParamInfo)
  self:RegisterCmd(PetUIModuleCmd.SetPetReportParamInfo, self.SetPetReportParamInfo)
  self:RegisterCmd(PetUIModuleCmd.OpenBloodMagicTips, self.CmdOpenBloodMagicTips)
  self:RegisterCmd(PetUIModuleCmd.CalculationSkillNumByType, self.CalculationSkillNumByType)
  self:RegisterCmd(PetUIModuleCmd.OpenSkillOperationPanel, self.OpenSkillOperationPanel)
  self:RegisterCmd(PetUIModuleCmd.OnSelectSkillOperationItem, self.OnSelectSkillOperationItem)
  self:RegisterCmd(PetUIModuleCmd.OpenUnlockSkillsPanel, self.OpenUnlockSkillsPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenAttributeChangePanel, self.OpenAttributeChangePanel)
  self:RegisterCmd(PetUIModuleCmd.RefreshEditorPetTeamCache, self.RefreshEditorPetTeamCache)
  self:RegisterCmd(PetUIModuleCmd.GetPvpTeamPetEquipSkillMapByPetGid, self.GetPvpTeamPetEquipSkillMapByPetGid)
  self:RegisterCmd(PetUIModuleCmd.GetEnterPetPanelType, self.GetEnterPetPanelType)
  self:RegisterCmd(PetUIModuleCmd.GetPetEquipSkillMap, self.OnCmdGetPetEquipSkillMap)
  self:RegisterCmd(PetUIModuleCmd.GetAssumptionEquipSkill, self.GetAssumptionEquipSkill)
  self:RegisterCmd(PetUIModuleCmd.SetAssumptionEquipSkill, self.SetAssumptionEquipSkill)
  self:RegisterCmd(PetUIModuleCmd.GetPetCurEquipSkillType, self.OnCmdGetPetCurEquipSkillType)
  self:RegisterCmd(PetUIModuleCmd.AutoCheckEnvironmentEquipPetSkill, self.OnCmdAutoCheckEnvironmentEquipPetSkill)
  self:RegisterCmd(PetUIModuleCmd.PetRightPanelIsOpen, self.OnCmdPetRightPanelIsOpen)
  self:RegisterCmd(PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.OnCmdGetLevelSkillConfByPetBaseId)
  self:RegisterCmd(PetUIModuleCmd.GetPetHatchingEnableState, self.GetPetHatchingEnableState)
  self:RegisterCmd(PetUIModuleCmd.GetPetInfoMainEnableState, self.GetPetInfoMainEnableState)
  self:RegisterCmd(PetUIModuleCmd.SetFriendInfoToPetMain, self.SetFriendInfoToPetMain)
  self:RegisterCmd(PetUIModuleCmd.GetFriendInfoToPetMain, self.GetFriendInfoToPetMain)
  self:RegisterCmd(PetUIModuleCmd.PetWarehouseReadyToClose, self.OnCmdPetWarehouseReadyToClose)
  self:RegisterCmd(PetUIModuleCmd.GetPetHatchingIsSelected, self.OnCmdGetPetHatchingIsSelected)
  self:RegisterCmd(PetUIModuleCmd.EncodeShareTeamCode, self.EncodeShareTeamCode)
  self:RegisterCmd(PetUIModuleCmd.GetPetRestrainAndResistType, self.GetPetRestrainAndResistType)
  self:RegisterCmd(PetUIModuleCmd.OpenSendPetToFriendPanel, self.OnCmdOpenSendPetToFriendPanel)
  self:RegisterCmd(PetUIModuleCmd.SendPetToFriend, self.OnCmdSendPetToFriend)
  self:RegisterCmd(PetUIModuleCmd.SetCanShowSendBtn, self.OnCmdSetCanShowSendBtn)
  self:RegisterCmd(PetUIModuleCmd.GetCanShowSendBtn, self.OnCmdGetCanShowSendBtn)
  self:RegisterCmd(PetUIModuleCmd.SetPanelFullScreenMaskShow, self.OnCmdSetPanelFullScreenMaskShow)
  self:RegisterCmd(PetUIModuleCmd.IsPetInCurrentWeek, self.OnCmdIsPetInCurrentWeek)
  self:RegisterCmd(PetUIModuleCmd.IsPetCaughtToday, self.OnCmdIsPetCaughtToday)
  self:RegisterCmd(PetUIModuleCmd.OpenPetEvoOnlyPanel, self.OpenPetEvoOnlyPanel)
  self:RegisterCmd(PetUIModuleCmd.ClosePetEvoOnlyPanel, self.ClosePetEvoOnlyPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPetEvoResultPanel, self.OpenPetEvoResultPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenTrialPVPPet, self.OpenTrialPVPPet)
  self:RegisterCmd(PetUIModuleCmd.CmdGetBalancedPetDataForPvp, self.OnCmdGetBalancedPetDataForPvp)
  self:RegisterCmd(PetUIModuleCmd.CmdInvalidateBalancedPetDataForPvp, self.OnCmdInvalidateBalancedPetDataForPvp)
  self:RegisterCmd(PetUIModuleCmd.CmdQueryBalancedPetDataForPvp, self.OnCmdQueryBalancedPetDataForPvp)
  self:RegisterCmd(PetUIModuleCmd.OpenPetTraceBackPopup, self.OpenPetTraceBackPopup)
  self:RegisterCmd(PetUIModuleCmd.ClosePetTraceBackPopup, self.ClosePetTraceBackPopup)
  self:RegisterCmd(PetUIModuleCmd.SendPetTraceBackReq, self.OnCmdSendPetTraceBackReq)
  self:RegisterCmd(PetUIModuleCmd.OpenNewPetBagPanel, self.OpenNewPetBagPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenLeaderItemPanel, self.OnCmdOpenLeaderItemPanel)
  self:RegisterCmd(PetUIModuleCmd.SelectLeaderItem, self.OnCmdSelectLeaderItem)
  self:RegisterCmd(PetUIModuleCmd.OpenPetLeaderAttribute, self.OnCmdOpenPetLeaderAttribute)
  self:RegisterCmd(PetUIModuleCmd.ClosePetLeaderAttribute, self.OnCmdClosePetLeaderAttribute)
  self:RegisterCmd(PetUIModuleCmd.OpenNewPetBagBoxPanel, self.OpenNewPetBagBoxPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenNetPetBagMarkWarehousePanel, self.OpenNetPetBagMarkWarehousePanel)
  self:RegisterCmd(PetUIModuleCmd.OpenNewPetBagScreenSearchPanel, self.OpenNewPetBagScreenSearchPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenNewPetBagWarehouseScreeningPanel, self.OpenNewPetBagWarehouseScreeningPanel)
  self:RegisterCmd(PetUIModuleCmd.GetAllWarehousConfigs, self.GetAllWarehousConfigs)
  self:RegisterCmd(PetUIModuleCmd.GetAllWarehousCollectMarkConfigs, self.GetAllWarehousCollectMarkConfigs)
  self:RegisterCmd(PetUIModuleCmd.OnCmdGetPetBoxDatas, self.GetPetBoxDatas)
  self:RegisterCmd(PetUIModuleCmd.OnCmdZonePetBoxLastOpenBoxReq, self.OnCmdZonePetBoxLastOpenBoxReq)
  self:RegisterCmd(PetUIModuleCmd.OnCmdZonePetBoxUnlockReq, self.OnCmdZonePetBoxUnlockReq)
  self:RegisterCmd(PetUIModuleCmd.OnCmdZonePetBoxChangePetReq, self.OnCmdZonePetBoxChangePetReq)
  self:RegisterCmd(PetUIModuleCmd.OnCmdZonePetBoxSwapReq, self.OnCmdZonePetBoxSwapReq)
  self:RegisterCmd(PetUIModuleCmd.OnCmdZonePetBoxSetMarkTypeReq, self.OnCmdZonePetBoxSetMarkTypeReq)
  self:RegisterCmd(PetUIModuleCmd.OnCmdZonePetBoxTidyReq, self.OnCmdZonePetBoxTidyReq)
  self:RegisterCmd(PetUIModuleCmd.GetPetBelongBoxID, self.OnCmdGetPetBelongBoxID)
  self:RegisterCmd(PetUIModuleCmd.OnCmdDragPetToBox, self.OnCmdDragPetToBox)
  self:RegisterCmd(PetUIModuleCmd.OnCmdBoxDragStart, self.OnCmdBoxDragStart)
  self:RegisterCmd(PetUIModuleCmd.CheckPetIsInFilterList, self.OnCmdCheckPetIsInFilterList)
  self:RegisterCmd(PetUIModuleCmd.ReturnToPetMainPanel, self.ReturnToPetMainPanel)
  self:RegisterCmd(PetUIModuleCmd.RealOpenNewPetBagBoxPanel, self.OnCmdRealOpenNewPetBagBoxPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenPurchaseBoxPanel, self.OnCmdOpenPurchaseBoxPanel)
  self:RegisterCmd(PetUIModuleCmd.GetUnlockBoxRuleGroupList, self.OnCmdGetUnlockBoxRuleGroupList)
  self:RegisterCmd(PetUIModuleCmd.SelectUnlockBoxItem, self.OnCmdSelectUnlockBoxItem)
  self:RegisterCmd(PetUIModuleCmd.OpenPetBoxPanelFromBag, self.OnCmdOpenPetBoxPanelFromBag)
  self:RegisterCmd(PetUIModuleCmd.SetPetBoxPanelOpenState, self.OnCmdSetPetBoxPanelOpenState)
  self:RegisterCmd(PetUIModuleCmd.GetPetBoxPanelOpenState, self.OnCmdGetPetBoxPanelOpenState)
  self:RegisterCmd(PetUIModuleCmd.ShowSubmitFinishTips, self.OnCmdShowSubmitFinishTips)
  self:RegisterCmd(PetUIModuleCmd.CheckHasPetByPetBaseId, self.OnCmdCheckHasPetByPetBaseId)
  self:RegisterCmd(PetUIModuleCmd.SetPetMainPanelPetImage3DActive, self.OnCmdSetPetMainPanelPetImage3DActive)
  self:RegisterCmd(PetUIModuleCmd.CheckIsOpenEvoPanel, self.OnCmdCheckIsOpenEvoPanel)
  self:RegisterCmd(PetUIModuleCmd.OpenBoxOrganizationFethod, self.OnCmdOpenBoxOrganizationFethod)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_IN_CHANGE_PET_ZONE_NOTIFY, self.OnZonePlayerInChangePetZoneNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_LEAVE_CHANGE_PET_ZONE_NOTIFY, self.OnZonePlayerLeaveChangePetZoneNotify)
  self:RegPanel("PetInfoMain", "UMG_PetInfoMain", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil, nil, true)
  self:RegPanel("PetEvolutionItem", "UMG_PetEvolutionItem", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetEvolutionFinish", "UMG_PetEvolutionFinish", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetEvolutionReward", "UMG_PetEvolutionReward", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetEvolutionTask", "UMG_PetEvolutionTask", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Rename", "Backpack/UMG_Rename", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetUpgradePanel", "Backpack/UMG_PetUpgradePanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetGrowUpPanel", "Backpack/UMG_PetGrowUpPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("TipsStrongPoint", "Backpack/UMG_Tips_StrongPoint", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PeculiarityTips", "UMG_Peculiarity_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetDetailedInfo", "UMG_PetDetailedInfo", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetFreeCaptiveAnimals", "Backpack/UMG_PetFreeCaptiveAnimals", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetFreeCaptive", "Backpack/UMG_OnePetFreeCaptivePanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetHavingFitTogether", "Having/UMG_HavingFitTogether", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("PetEvoPanel", "UMG_PetEvoPanel", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetEvoNewPanel", "UMG_PetEvoNewPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetTeamPanel", "PetTeam/UMG_PetTeam_Main", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetTeamResonancePanel", "PetTeam/UMG_Pet_TeamResonance", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetWarehousePanelMain", "Backpack/UMG_PetWarehouseMain", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, true, nil, nil, true)
  self:RegPanel("PetWarehouseFree", "Backpack/UMG_PetWareHouseFree", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, true, nil, nil, true)
  self:RegPanel("PetReport", "PetReport/UMG_PetReport", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetTeamManagement", "PetTeam/UMG_Pet_TeamManagement", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, true, nil, nil, true)
  self:RegPanel("PetTeamReplace", "PetTeam/UMG_Pet_TeamReplace", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, true, nil, nil, true, true, true)
  self:RegPanel("PetSkillTips", "UMG_PetSkillMain_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("Pet_BloodPulse", "UMG_Pet_BloodPulse", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("Pet_BloodPulse_Statistics", "UMG_Pet_BloodPulse", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, nil, nil, true)
  self:RegPanel("UMG_ImpressionSettlement", "Impression/UMG_ImpressionSettlement", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("EggIncubatePanel", "Hatching/UMG_PetHatching_jiesu", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, "Out", true)
  self:RegPanel("QualificationInterpretation", "UMG_QualificationInterpretation", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetRightPanel", "UMG_PetRightPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, "Qiehuan_Out", nil, true)
  self:RegPanel("PetBagPanel", "PetBag/UMG_PetBag", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetGrowUp", "Backpack/UMG_PetGrowUp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "OpenAnim", "Out")
  self:RegPanel("ExChangeGrowUp", "Backpack/UMG_ExChangeGrowUpItemPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "New_in", "New_out", true)
  self:RegPanel("PetLevelUp", "UMG_PetLevelUp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "New_in", "New_out")
  self:RegPanel("LineupShareAlchemy", "UMG_Lineup_ShareAlchemy", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "open", "close", true)
  self:RegCommonPanel("AICoachRecommendTeam", "/Game/NewRoco/Modules/System/PetUI/Res/PetTeam/UMG_FriendTeam_AICoach1", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegCommonPanel("AICoachRecommendTeam2", "/Game/NewRoco/Modules/System/PetUI/Res/PetTeam/UMG_FriendTeam_AICoach2", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegCommonPanel("PetHatchingReview", "/Game/NewRoco/Modules/System/Activity/Res/UMG_HatchingReview.UMG_HatchingReview", _G.Enum.UILayerType.UI_LAYER_POPUP, true)
  self:RegCommonPanel("Battle_ChangePetConfirm", "/Game/NewRoco/Modules/System/Common/Res/UMG_Battle_ChangePetConfirm_2", _G.Enum.UILayerType.UI_LAYER_POPUP, true)
  self:RegPanel("BagSkillTipsTop", "UMG_BagSkillMain_Tips", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, nil, nil, true)
  self:RegPanel("BagSkillTips", "UMG_BagSkillMain_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetHatchingPanel", "Hatching/UMG_PetHatching", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true, nil, nil, "PetInfoMain")
  self:RegPanel("ChoosePetBallPanel", "Hatching/UMG_ChooseGollball", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("HatchingRightPanel", "Hatching/UMG_NewChoosePetBall", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("ColorfulMatchingTips", "Hatching/UMG_ColorfulMatchingTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetConfirmPanel", "Backpack/UMG_ChangePetConfirmPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, true, nil, nil, true)
  self:RegPanel("PetFilterTips", "Backpack/UMG_PetFilterTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("CandidateTips", "Backpack/UMG_CandidateTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("ExChangeMainPetTips", "Backpack/UMG_PetExchange", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("RandomPetBonus", "PetTeam/UMG_RandomBonus", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("BattleShowImage", "UMG_BattleShowImage", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("QuickSelection", "Backpack/UMG_QuickSelection", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetBloodlineMagic", "UMG_PetBloodlineMagic", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("MedalWonPanel", "UMG_MedalWonPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("TalentRestore_Popup", "UMG_TalentRestore_Popup", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("TipsIndividualValu", "Backpack/UMG_Tips_IndividualValue", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, nil, nil, true)
  self:RegPanel("PetDazzlingTips", "UMG_Pet_DazzlingTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetDifferentColorsTips", "UMG_Pet_DifferentColorsTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("ShareCameraPanel", "UMG_Share_CameraLens", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "Open", nil, true)
  self:RegPanel("PetPartnerMarker", "UMG_Pet_PartnerMarker", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil)
  self:RegPanel("ShareOverlay", "UMG_ShareOverlay", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil)
  self:RegPanel("ShareTeam", "PetTeam/UMG_Lineup_Share", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, "In", "Out", true)
  self:RegPanel("ChooseAlternative", "PetTeam/UMG_ChooseAlternative", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil)
  self:RegPanel("PetReleaseTips", "Backpack/UMG_ReleaseTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("AdjustTeam", "PetTeam/UMG_LineupAdjustment", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, "In", "Out", true)
  self:RegPanel("FriendPetTeamPanel", "PetTeam/UMG_FriendTeamPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, "In", "Out", true)
  self:RegPanel("FriendPetTeamDetailPanel", "PetTeam/UMG_FriendTeam_LineupDetails", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetFiltering", "UMG_PetFiltering", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetSortPanel", "UMG_PetSort", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetAlternative", "PetTeam/UMG_ChooseAlternativePet", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("SkillAlternative", "PetTeam/UMG_ChooseAlternative", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("SkillLearning", "UMG_SkillLearning", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("SkillLearning2", "UMG_SkillLearning_2", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("ShareTeamDetailsDifferences", "PetTeam/UMG_DetailsDifferences", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("ShareTeamDifferenceContent", "PetTeam/UMG_DifferenceContent", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("ShareTeamSolveDifferences", "PetTeam/UMG_SolveDifferences", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("TeamShareReviseTalentPanel", "PetTeam/UMG_Modify", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("FriendPetTeamMirrorImportPanel", "PetTeam/UMG_FriendTeam_ImportIineup", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil)
  self:RegPanel("PetReportParticulars", "PetReport/UMG_PetReport_Particulars", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetReportReminder", "PetReport/UMG_PetReport_Reminder", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil)
  self:RegPanel("PetReportShare", "PetReport/UMG_RetReport_SharePanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("UMG_MagicTips", "PetTeam/UMG_MagicTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("UMG_ReplacementSkills", "UMG_ReplacementSkills", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("UMG_UnlockSkills", "UMG_UnlockSkills", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("UMG_AttributeChange", "UMG_AttributeChange", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("GiftFromColleagues", "UMG_GiftFromColleagues", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetEvoResult", "UMG_PetEvolution_Result", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PetEvoOnly", "UMG_PetImage3D_EvoOnly", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil, nil, true)
  self:RegPanel("PetHatchOnly", "UMG_PetImage3D_HatchOnly", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil, nil, true)
  self:RegPanel("TrialPVPPet", "PetTeam/UMG_Pet_TeamReplace_PVP", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "In", "Out", true)
  self:RegPanel("LeaderItemPanel", "LeaderItem/UMG_LeaderItemPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, "In", "Out", true)
  self:RegPanel("PetLeader_Attribute", "LeaderItem/UMG_PetLeader_Attribute", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "In", "Out", true)
  self:RegPanel("NewPetBag", "PetBag/UMG_PetPortableBag", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("NewPetBagBox", "PetBag/UMG_PetWarehouseOrganization", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("NewPetBagWarehouseScreening", "PetBag/UMG_PetWarehouseScreening", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, "In", "Out", true)
  self:RegPanel("NewPetBagScreenSearch", "PetBag/UMG_Search", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("NetPetBagMarkWarehouse", "PetBag/UMG_MarkingBox", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PetTraceBackPopup", "UMG_TimeRewindPopup", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("PurchaseBox", "PetBag/UMG_PurchaseBox", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:RegPanel("BoxOrganizationFethod", "PetBag/UMG_BoxOrganizationFethod", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, nil, true)
  self:PetSkillInit()
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self.hideEquipProssession = false
  self.PetBeForePropertyInfo = {}
  self.oldPetData = nil
  self.CanSetSelectItem = true
  self.IsBagToOpenPanel = false
  self.NotChangeAnim = false
  self.PetInfoUpdate = nil
  self.descText = {}
  self.IsFirstLoadBg = true
  self.certificationGid = nil
  self.PetWareHouseSort = _G.Enum.PetSequenceDefault.SEQUENCE_LEVEL_DOWN
  self.bInspecting = false
  self.isDisableInEggAnimation = false
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SHARE_FORM_NOTIFY, self.OnGetCard)
  NRCEventCenter:RegisterEvent("PetUIModule", self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:RegisterEvent("PetUIModule", self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
  _G.NRCEventCenter:RegisterEvent("PetUIModule", self, SceneEvent.OnRelogin, self.CloseBeginOpenPanel)
  NRCEventCenter:RegisterEvent("PetUIModule", self, SceneEvent.LoadMapStart, self.ChangeScene)
  _G.NRCEventCenter:RegisterEvent("PetUIModule", self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:RegisterEvent("PetUIModule", self, BattleEvent.EnterBattle, self.OnEnterBattle)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET, self.OnReLoginUpdatePet)
  _G.NRCEventCenter:RegisterEvent("PetUIModule", self, BagModuleEvent.GoodChangeTypeEnum.GT_PETBOX_BOX_INFO, self.OnPetBoxInfoChange)
  _G.NRCEventCenter:RegisterEvent("PetUIModule", self, BagModuleEvent.GoodChangeTypeEnum.GT_PETBOX_PET_PET_CHANGE, self.OnPetBoxChange)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PET_BOX_MARK_TYPE_UNLOCK_NTY, self.OnPetBoxMarkTypeUnlockNotify)
  self:GetFriendGetMirrorPetDataList()
  self:InitEggTypeConfigMap()
end

function PetUIModule:InitEggTypeConfigMap()
  if self.EggTypeConfigMap ~= nil then
    return
  end
  self.EggTypeConfigMap = {}
  local EggTypeCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.EGG_TYPE_CONF)
  if EggTypeCfg then
    local AllEggTypeConfigs = EggTypeCfg:GetAllDatas()
    for _, eggTypeConf in pairs(AllEggTypeConfigs) do
      if eggTypeConf and nil ~= eggTypeConf.precious_egg_type then
        self.EggTypeConfigMap[eggTypeConf.precious_egg_type] = eggTypeConf
      end
    end
  end
end

function PetUIModule:CmdOpenAICoachRecommendPanel(acivityid, data1, data2)
  if data2 then
    self:OpenPanel("AICoachRecommendTeam2", acivityid, data1, data2)
  else
    self:OpenPanel("AICoachRecommendTeam", acivityid, data1)
  end
end

function PetUIModule:OnCmdGetEggIsCanGiveAwayByEggType(PreciousEggType)
  if self.EggTypeConfigMap == nil then
    self:InitEggTypeConfigMap()
  end
  if self.EggTypeConfigMap and PreciousEggType and self.EggTypeConfigMap[PreciousEggType] then
    return not self.EggTypeConfigMap[PreciousEggType].cant_give_away
  end
end

function PetUIModule:GetFriendGetMirrorPetDataList()
  local req = _G.ProtoMessage:newZonePetTeamFriendGetMirrorPetDataReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_FRIEND_GET_MIRROR_PET_DATA_REQ, req, self, self.OnZonePetTeamFriendGetMirrorPetDataRsp, false, true)
end

function PetUIModule:OnZonePetTeamFriendGetMirrorPetDataRsp(rsp)
end

function PetUIModule:CmdGetMirrorPetDataByGid(pet_gid)
  return self.data:GetMirrorPetDataByGid(pet_gid)
end

function PetUIModule:OnBagChange()
  self:DispatchEvent(PetUIModuleEvent.BagItemChange)
end

function PetUIModule:CmdOpenPetReleaseTips(PetData, teamInfo, ParamCall, IsOpenInFreePanel, FreeReasonType, ReleaseTipsOpenType)
  self:OpenPanel("PetReleaseTips", PetData, teamInfo, ParamCall, IsOpenInFreePanel, FreeReasonType, ReleaseTipsOpenType)
end

function PetUIModule:CmdOpenLineupShareAlchemy(data)
  self:OpenPanel("LineupShareAlchemy", data)
end

function PetUIModule:CmdGetLineupShareAlchemyByItemId(ItemId)
  if self.data.LineupShareAlchemy then
    if self.data.LineupShareAlchemy[ItemId] then
      return self.data.LineupShareAlchemy[ItemId]
    else
      local ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetItemSynthesisInfo, ItemId)
      self.data.LineupShareAlchemy[ItemId] = ItemSynthesisInfoList
    end
  else
    self.data.LineupShareAlchemy = {}
    local ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetItemSynthesisInfo, ItemId)
    self.data.LineupShareAlchemy[ItemId] = ItemSynthesisInfoList
  end
  return self.data.LineupShareAlchemy[ItemId]
end

function PetUIModule:OnDeactive()
end

function PetUIModule:OnDestruct()
  if self.delayUpdateBox then
    _G.DelayManager:CancelDelayById(self.delayUpdateBox)
    self.delayUpdateBox = nil
  end
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.CloseBeginOpenPanel)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.ChangeScene)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SYNC_NOTIFY, self.ListeningPetChange)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET, self.OnReLoginUpdatePet)
end

function PetUIModule:ListeningPetChange(rsp)
  if 0 == rsp.ret_info.ret_code then
    local info = rsp.ret_info
    local GoodsChange = info and info.goods_change_info
    local GoodsChangeItems = GoodsChange and GoodsChange.changes
    if GoodsChangeItems then
      for _, GoodsChangeItem in ipairs(GoodsChangeItems) do
        local ItemType = GoodsChangeItem.type
        if ItemType == ProtoEnum.GoodsType.GT_PET then
          self.PetInfoUpdate = GoodsChangeItem
        end
      end
    end
  end
end

function PetUIModule:OnReLoginUpdatePet()
  self:UpdateCachePetBelongBoxMap()
  if self:HasPanel("PetInfoMain") then
    local petInfoMain = self:GetPanel("PetInfoMain")
    if petInfoMain then
      local petLeftPanel = petInfoMain.petLeftPanel
      if petLeftPanel then
        petLeftPanel:UpdatePetBagBtnState()
      end
    end
  end
end

function PetUIModule:ChangeScene()
  local hasPanel = self:HasPanel("PetInfoMain")
  if hasPanel then
    local panel = self:GetPanel("PetInfoMain")
    if panel then
      self:CloseAllPanel()
      local openPetData, index, isRevertPanel = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, nil, index, isRevertPanel)
      local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
      _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList)
      NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    end
  end
end

function PetUIModule:ShowChangePetConfirm(PetInfo, IsShowHp)
  local petinfo = {PetData = PetInfo, IsShowHp = IsShowHp}
  self:OpenPanel("Battle_ChangePetConfirm", petinfo, true)
end

function PetUIModule:ShowChangeTalentRestorePopup(PetInfo)
  local PetData = PetInfo or self:GetCurrPetData()
  self:OpenPanel("TalentRestore_Popup", PetData)
end

function PetUIModule:OpenTeamShareReviseTalentPanel(ChangeType, NeedHideType, gid)
  self:OpenPanel("TeamShareReviseTalentPanel", PetUIModuleEnum.PetTeamShareReviseType.Talent, ChangeType, NeedHideType, gid)
end

function PetUIModule:OpenTeamShareReviseNaturePanel(NatureEffects, gid)
  self:OpenPanel("TeamShareReviseTalentPanel", PetUIModuleEnum.PetTeamShareReviseType.Nature, NatureEffects, nil, gid)
end

function PetUIModule:OpenTeamChangeBloodPanel(BloodNeedItemList, gid)
  self:OpenPanel("TeamShareReviseTalentPanel", PetUIModuleEnum.PetTeamShareReviseType.Blood, BloodNeedItemList, nil, BloodNeedItemList.petGid)
end

function PetUIModule:ShowChangePetConfirmPanel(PetInfo, IsOpen, NeedBtn, PetNum, PetNumLimit, SkillPanel)
  if IsOpen then
    local petinfo = {PetData = PetInfo}
    self:OpenPanel("PetConfirmPanel", petinfo, NeedBtn, PetNum, PetNumLimit, SkillPanel)
  else
    self:ClosePanel("PetConfirmPanel")
  end
end

function PetUIModule:SetChangePetConfirmPanelBtnVisit(NeedBtn)
  if self:HasPanel("PetConfirmPanel") then
    local panel = self:GetPanel("PetConfirmPanel")
    panel:SetBtnVisible(NeedBtn)
  end
end

function PetUIModule:UpDatePetConfirmPanel(PetInfo)
  if self:HasPanel("PetConfirmPanel") then
    local panel = self:GetPanel("PetConfirmPanel")
    panel:PetSkillChangeToBaseInfo(PetInfo)
    panel:SetPetInfo(PetInfo)
  end
end

function PetUIModule:UpDatePetConfirmPanelLimit(PetNum, PetNumLimit)
  if self:HasPanel("PetConfirmPanel") then
    local panel = self:GetPanel("PetConfirmPanel")
    panel:UpDateLimit(PetNum, PetNumLimit)
  end
end

function PetUIModule:OnDialogueEnded(bIsReconnected)
  if bIsReconnected then
    self:CloseAllPanel()
  end
end

function PetUIModule:OnEnterBattle()
  if self:HasPanel("PetInfoMain") then
    self:CloseAllPanel()
  end
end

function PetUIModule:OnCmdOpenPetMainPanel(_param, IsPvPToPetTeam, petData, bShowSendMark, panelDynamicData)
  local resListData = _G.NRCPanelResLoadData()
  resListData.PreLoadResList = {}
  resListData.PreparingResList = {}
  table.insert(resListData.PreparingResList, "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/OpenTwoPanel.OpenTwoPanel'")
  table.insert(resListData.PreparingResList, "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/CloseTwoPanel.CloseTwoPanel'")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_SwitchPetShow_UI.G6_SwitchPetShow_UI_C'")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_OpenPetInfo_UI.G6_OpenPetInfo_UI_C'")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_ClosePetInfo_UI.G6_ClosePetInfo_UI_C'")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_SwitchEegShow_UI.G6_SwitchEegShow_UI_C")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/UI/Hatched/G6_UI_PetHatched.G6_UI_PetHatched_C'")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_OpenPetBag_UI.G6_OpenPetBag_UI_C'")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_ClosePetBag_UI.G6_ClosePetBag_UI_C'")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_OpenDetailsPetBag_UI.G6_OpenDetailsPetBag_UI_C'")
  table.insert(resListData.PreparingResList, "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_CloseDetailsPetBag_UI.G6_CloseDetailsPetBag_UI_C'")
  _G.DataModelMgr.PlayerDataModel:TryGetPetInfo()
  local base_conf_id, baseConf
  if self.data.OpenPanelPetData then
    base_conf_id = self.data.OpenPanelPetData.base_conf_id
  elseif petData then
    base_conf_id = petData.base_conf_id
  else
    local Index = self.data.SelectPetIndex or 1
    local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    if not battlePetList or 0 == #battlePetList then
      Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174\239\188\140\228\184\141\230\137\147\229\188\128\232\131\140\229\140\133")
      return
    end
    for i = 1, #battlePetList do
      if i == Index then
        base_conf_id = battlePetList[i].base_conf_id
        break
      end
    end
  end
  if self.isHatchingPanel and self.curEggGid then
    local backpackEggList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()
    for i = 1, #backpackEggList do
      if backpackEggList[i].gid == self.curEggGid then
        local eggData = backpackEggList[i].eggData
        if eggData and eggData.conf_id then
          local eggConf, modelFxType
          if 0 ~= eggData.conf_id then
            eggConf = _G.DataConfigManager:GetPetEggConf(eggData.conf_id)
            local base_id = _G.DataConfigManager:GetPetConf(eggData.conf_id).base_id
            baseConf = _G.DataConfigManager:GetPetbaseConf(base_id)
            if baseConf then
              modelFxType = baseConf.unit_type[1]
              if modelFxType < Enum.SkillDamType.SDT_COMMON then
                modelFxType = Enum.SkillDamType.SDT_COMMON
              end
            end
          elseif eggData.random_egg_conf then
            eggConf = _G.DataConfigManager:GetPetRandomEggConf(eggData.random_egg_conf)
            modelFxType = Enum.SkillDamType.SDT_UNKNOW
            if eggConf.known_unit_type and eggData.dataconfig and eggData.dataconfig.SkillDamType then
              modelFxType = eggData.dataconfig.SkillDamType
            end
          end
          if eggConf then
            local moduleConf = _G.DataConfigManager:GetModelConf(eggConf.model_id)
            if moduleConf then
              local modulePath = moduleConf.path
              table.insert(resListData.PreparingResList, modulePath)
              resListData.modelPath = modulePath
            end
          end
          if modelFxType then
            local Path = _G.DataConfigManager:GetSkillColorConf(modelFxType).JL_background_colour
            local Path_1 = _G.DataConfigManager:GetSkillColorConf(modelFxType).JL_background_clear
            table.insert(resListData.PreparingResList, Path)
            table.insert(resListData.PreparingResList, Path_1)
            resListData.path = Path
            resListData.path_1 = Path_1
          end
        end
        break
      end
    end
  end
  if base_conf_id then
    baseConf = _G.DataConfigManager:GetPetbaseConf(base_conf_id)
    local modelFxType = baseConf.unit_type[1]
    if modelFxType < Enum.SkillDamType.SDT_COMMON then
      modelFxType = Enum.SkillDamType.SDT_COMMON
    end
    local modelConf = _G.DataConfigManager:GetModelConf(baseConf.model_conf)
    local Path = _G.DataConfigManager:GetSkillColorConf(modelFxType).JL_background_colour
    local Path_1 = _G.DataConfigManager:GetSkillColorConf(modelFxType).JL_background_clear
    table.insert(resListData.PreparingResList, modelConf.path)
    table.insert(resListData.PreparingResList, Path)
    table.insert(resListData.PreparingResList, Path_1)
    resListData.modelPath = modelConf.path
    resListData.path = Path
    resListData.path_1 = Path_1
  end
  self.PanelStateMap = nil
  self.IsFirstLoadBg = true
  if _param and _param.Callback and _param.Caller then
    self:OpenPanel("PetInfoMain", {
      subPanelIndex = 4,
      baseConf = baseConf,
      callback = _param.Callback,
      caller = _param.Caller,
      ModuleName = "PetInfoMain"
    }, IsPvPToPetTeam, resListData, bShowSendMark, panelDynamicData)
  elseif _param and (nil ~= _param.bHideSkill or nil ~= _param.bUseOpenPetData) then
    self:OpenPanel("PetInfoMain", {
      subPanelIndex = 4,
      baseConf = baseConf,
      ModuleName = "PetInfoMain",
      bHideSkill = _param.bHideSkill,
      bUseOpenPetData = _param.bUseOpenPetData
    }, IsPvPToPetTeam, resListData, bShowSendMark, panelDynamicData)
  else
    self:OpenPanel("PetInfoMain", {
      subPanelIndex = 4,
      baseConf = baseConf,
      ModuleName = "PetInfoMain"
    }, IsPvPToPetTeam, resListData, bShowSendMark, panelDynamicData)
  end
end

function PetUIModule:CmdSendZonePetTeamFriendMirrorReq(TeamType, selectTeamIndex, MirrorFromUin, MirrorTeamIndex)
  local PetTeamsList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(TeamType)
  self.IsRefreshMirrorPanel = PetTeamsList.main_team_idx == selectTeamIndex
  local req = _G.ProtoMessage:newZonePetTeamFriendMirrorReq()
  req.team_type = TeamType
  req.team_idx = selectTeamIndex
  req.target_uin = MirrorFromUin
  req.target_team_idx = MirrorTeamIndex
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_FRIEND_MIRROR_REQ, req, self, self.OnMirrorFriendPetTeamsInfoRsp, false, true)
end

function PetUIModule:TryRefreshPetTeamPanel()
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetTeamManagementSelChanged, true)
end

function PetUIModule:OnMirrorFriendPetTeamsInfoRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:GetFriendGetMirrorPetDataList()
    _G.NRCAudioManager:PlaySound2DAuto(13000, "PetUIModule:OnMirrorFriendPetTeamsInfoRsp")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_import_succeed)
  elseif _rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and _rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = _rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", _rsp.ban_info.ban_time)
    local reasonStr = _rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  else
    local key = string.format("Error_Code_%d", _rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
  if self:HasPanel("FriendPetTeamDetailPanel") then
    local panel = self:GetPanel("FriendPetTeamDetailPanel")
    panel:OnCloseClick()
  end
  local panel = self:GetPanel("FriendPetTeamMirrorImportPanel")
  panel:MirrorSuccessClose()
  self:OnChangePetTeamsInfo(_rsp)
end

function PetUIModule:CmdOpenFriendMirrorPetTeamCoverPanel(TeamType, MirrorTeamIndex, MirrorFromUin, PetTeam)
  if TeamType == _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_RAND then
    return
  end
  self:DisablePanel("FriendPetTeamDetailPanel")
  self:OpenPanel("FriendPetTeamMirrorImportPanel", TeamType, MirrorTeamIndex, MirrorFromUin, PetTeam)
end

function PetUIModule:EnablePanelPetMain()
  if self:HasPanel("PetInfoMain") then
    local Panel = self:GetPanel("PetInfoMain")
    Panel:EnableAndShouldBanWorldRendering()
  end
end

function PetUIModule:PreLoadPetMain()
  self:PreLoadPanel("PetInfoMain")
end

function PetUIModule:CmdRefreshPetRightPanel(bIsOpenByBag)
  if self:HasPanel("PetRightPanel") then
    local Panel = self:GetPanel("PetRightPanel")
    Panel.PetSkillMain:RefreshUI(bIsOpenByBag)
    Panel:EnableAndShouldBanWorldRendering()
  end
end

function PetUIModule:OnCmdClosePetMainPanel()
  if self:HasPanel("PetInfoMain") then
    if self.IsBagToOpenPanel then
      local Panel = self:GetPanel("PetInfoMain")
      Panel:OnCloseButtonClicked()
    else
      local Panel = self:GetPanel("PetInfoMain")
      Panel:Disable()
    end
  end
end

function PetUIModule:ReturnToPetMainPanel()
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    if panel then
      panel:OnCloseButtonClicked()
    end
  end
end

function PetUIModule:OnCmdOpenPetWarehousePanel(NPCAction)
  self.data.NPCActionOpenPetWarehouse = NPCAction
  self:OpenPanel("PetWarehousePanelMain")
end

function PetUIModule:CloseBeginOpenPanel()
  self:GetFriendGetMirrorPetDataList()
  self.data:SetFriendInfoToPetMain(nil)
  self.isCrackEggIng = false
  if self:HasPanel("PetHatchingPanel") then
    self:ClosePanel("PetHatchingPanel")
  end
  self.IsWaitSetCollectRsp = false
  if self:HasPanel("PetWarehousePanelMain") then
    self:ClosePanel("PetWarehousePanelMain")
  end
end

function PetUIModule:OnCmdSetPvpSkillData(PvpSkillMap, PvpTeamParam)
  self.data.pvpSkillMap = PvpSkillMap
  self.data.PvpTeamParam = PvpTeamParam
end

function PetUIModule:OnCmdGetPvpSkillData()
  return self.data.pvpSkillMap or nil
end

function PetUIModule:OnCmdGetPvpTeamParam()
  return self.data.PvpTeamParam or nil
end

function PetUIModule:OnCmdSetOpenPetSKill(isSillOpen)
  self.data.OpenPanelSkill = isSillOpen
end

function PetUIModule:OnCmdGetOpenPetSKill()
  return self.data.OpenPanelSkill
end

function PetUIModule:SetOpenPetAttribute(isOpen)
  self.data.OpenPanelAttribute = isOpen
end

function PetUIModule:GetOpenPetAttribute()
  return self.data.OpenPanelAttribute
end

function PetUIModule:SetOpenPetBag(isOpen, gid)
  self.data.OpenPanelPetBag = isOpen
  self.data.OpenPanelSelectBagGid = gid
end

function PetUIModule:OnCmdOpenPetBloodPulseStatistics(_PetData, openType)
  self:OpenPanel("Pet_BloodPulse_Statistics", _PetData, openType)
end

function PetUIModule:OnCmdOpenPetBloodPulse(_PetData, openType)
  self:OpenPanel("Pet_BloodPulse", _PetData, openType)
end

function PetUIModule:OnCmdClosePetBloodPulse()
  self:ClosePanel("Pet_BloodPulse")
  _G.NRCModeManager:DoCmd(TipsModuleCmd.CloseTipsPanel)
end

function PetUIModule:SetPetWareHouseFreeBtnState(IsFree)
  if self:HasPanel("PetConfirmPanel") then
    local panel = self:GetPanel("PetConfirmPanel")
    if IsFree then
      panel.NRCSwitcher_46:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      panel.NRCSwitcher_46:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function PetUIModule:GetOpenPetBag()
  return self.data.OpenPanelPetBag, self.data.OpenPanelSelectBagGid
end

function PetUIModule:OnCmdShowPetWarehouseTips(petData, index)
  local panel = self:GetPanel("PetWarehousePanelMain")
  if panel then
    panel:OnScrollPetItemSelected(petData, index, true)
  end
end

function PetUIModule:CmdCanSelectWareHouseItem()
  return self.CanSetSelectItem
end

function PetUIModule:SetCmdCanSelectWareHouseItem(CanSet)
  self.CanSetSelectItem = CanSet
end

function PetUIModule:CmdCancelSelectWareHouseItem()
  if not self:HasPanel("PetWarehousePanelMain") then
    return
  end
  local panel = self:GetPanel("PetWarehousePanelMain")
  panel:ClearPetListItemSelectState()
end

function PetUIModule:OnCmdUpdatePetWareHouseMainInfo()
  if not self:HasPanel("PetWarehousePanelMain") then
    return
  end
  if self:HasPanel("PetConfirmPanel") then
    local panel = self:GetPanel("PetConfirmPanel")
    if panel then
      panel:RefreshInfo()
    end
  end
  local panel = self:GetPanel("PetWarehousePanelMain")
  if panel then
    panel:OnUpdatePetWareHouseInfo()
  end
  local FreePanel = self:GetPanel("PetWarehouseFree")
  if FreePanel then
    FreePanel:OnUpdatePanel()
  end
end

function PetUIModule:OnCmdOpenPetSKillTips(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
  local isOpened, _ = self:HasPanel("PetSkillTips")
  local isPetBagOpened, _ = self:HasPanel("NewPetBag")
  if isOpened then
    local tipsPanel = self:GetPanel("PetSkillTips")
    if tipsPanel then
      self:DispatchEvent(PetUIModuleEvent.OnDisablePetBagItems, true)
      tipsPanel:RefreshUI(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
    end
  else
    if isPetBagOpened then
      self:DispatchEvent(PetUIModuleEvent.OnDisablePetBagItems, true)
    else
      self:DispatchEvent(PetUIModuleEvent.OpenDetailPanelEvent, true)
    end
    self:OpenPanel("PetSkillTips", skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
  end
end

function PetUIModule:GetPetSKillTipsCurShowSkillId()
  local isOpened, _ = self:HasPanel("PetSkillTips")
  if isOpened then
    local tipsPanel = self:GetPanel("PetSkillTips")
    if tipsPanel then
      return tipsPanel:GetCurShowSkillId()
    end
  end
  return 0
end

function PetUIModule:OnCmdOpenBagSKillTips(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid, IsOpenByChangeSkillPanel)
  local isOpened, _ = self:HasPanel("BagSkillTips")
  if isOpened then
    local tipsPanel = self:GetPanel("BagSkillTips")
    if tipsPanel then
      tipsPanel:RefreshUI(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
    else
      local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").SKILLTIPS
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
    end
  else
    self:OpenPanel("BagSkillTips", skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid, IsOpenByChangeSkillPanel)
  end
end

function PetUIModule:OnCmdCloseBagSKillTips()
  local bOpened, _ = self:HasPanel("BagSkillTips")
  if bOpened then
    local panel = self:GetPanel("BagSkillTips")
    if panel then
      panel:OnClose()
    end
  end
end

function PetUIModule:GetBagSKillTipsCurShowSkillId()
  local isOpened, _ = self:HasPanel("BagSkillTips")
  if isOpened then
    local tipsPanel = self:GetPanel("BagSkillTips")
    if tipsPanel then
      return tipsPanel:GetCurShowSkillId()
    end
  end
  return 0
end

function PetUIModule:OnCmdOpenBagSKillTipsTop(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
  local isOpened, _ = self:HasPanel("BagSkillTipsTop")
  if isOpened then
    local tipsPanel = self:GetPanel("BagSkillTipsTop")
    if tipsPanel then
      tipsPanel:RefreshUI(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
    end
  else
    self:OpenPanel("BagSkillTipsTop", skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
  end
end

function PetUIModule:OnCmdClearSkillList(bPetUI)
  local bOpened, _ = self:HasPanel("PetRightPanel")
  if bOpened then
    local panel = self:GetPanel("PetRightPanel")
    if panel then
      panel.PetSkillMain:ClearSkillListSelection(bPetUI)
    end
  end
end

function PetUIModule:OnCmdClosePetSKillTips()
  if self:HasPanel("PetSkillTips") then
    local panel = self:GetPanel("PetSkillTips")
    panel:OnClose()
  end
end

function PetUIModule:OnCmdSetPetNewStateInfo(_PetData)
  if not self:HasPanel("PetWarehousePanelMain") then
    return
  end
  self:OnCmdOpenPetBag(_PetData.PetData)
  local panel = self:GetPanel("PetWarehousePanelMain")
  panel:OnRemovePetNew(_PetData)
end

function PetUIModule:OnCmdPetWarehouseReverseSort(bool)
  self:DispatchEvent(PetUIModuleEvent.OnClickReversedSort, bool)
end

function PetUIModule:OnCmdSetIsBagToOpenPanel()
  self.IsBagToOpenPanel = true
end

function PetUIModule:OnCmdGetIsBagToOpenPanel()
  if self.IsBagToOpenPanel then
    return true
  else
    return false
  end
end

function PetUIModule:OnCmdSetOpenPanelPetData(petData, index, bool, OpenTips, skill)
  Log.Error("set petdata", nil ~= petData)
  self.data.OpenPanelPetData = petData
  self.data.OpenPanelIndex = index
  self.data.IsRevertMainPanel = bool
  self.data.OpenTips = OpenTips
  self.data.LearnSkill = skill
end

function PetUIModule:OnCmdSetEnterPetPanelType(EnterPetPanelType)
  self.data:SetEnterPetPanelType(EnterPetPanelType)
end

function PetUIModule:OnCmdGetOpenPanelPetDataRedPoint()
  if self.data.OpenPanelPetData then
    local gid = self.data.OpenPanelPetData.gid
    local req = _G.ProtoMessage:newZoneCheckStoragePetReq()
    req.pet_gids = {gid}
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHECK_STORAGE_PET_REQ, req, self, self.OnGetOpenPanelPetDataRedPointRsp, false, true)
  end
end

function PetUIModule:OnGetOpenPanelPetDataRedPointRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if not self.data.OpenPanelPetData then
      return
    end
    local CanEvo = false
    local CanEvoId = 0
    local EvoPets = rsp.evolve_pets
    local num = 0
    if EvoPets and #EvoPets > 0 then
      num = #EvoPets
    end
    if num >= 1 then
      for i = 1, num do
        if EvoPets[i].pet_gid == self.data.OpenPanelPetData.gid then
          CanEvo = true
          CanEvoId = EvoPets[i].evolve_id
          break
        end
      end
    end
    local CanBreakThrough = false
    local BreakThroughPets = rsp.can_breakthrough_pets
    local num1 = 0
    if BreakThroughPets and #BreakThroughPets > 0 then
      num1 = #BreakThroughPets
    end
    if num1 >= 1 then
      for i = 1, num1 do
        if BreakThroughPets[i] == self.data.OpenPanelPetData.gid then
          CanBreakThrough = true
        end
      end
    end
    self.data.CulCanEvo = CanEvo
    self.data.CulEvoId = CanEvoId
    self.data.CulCanBreakThrough = CanBreakThrough
    self:DispatchEvent(PetUIModuleEvent.GetOpenPanelPetDataRedPoint, CanEvo, CanBreakThrough)
  end
end

function PetUIModule:OnCmdGetOpenPanelPetData()
  return self.data.OpenPanelPetData, self.data.OpenPanelIndex, self.data.IsRevertMainPanel, self.data.OpenTips, self.data.LearnSkill
end

function PetUIModule:OnCmdSetPetSelectIndex(_index)
  self.data.SelectPetIndex = _index
end

function PetUIModule:OnCmdGetPetSelectIndex()
  return self.data.SelectPetIndex
end

function PetUIModule:ClosePetTeamReplacePanel()
  if self:HasPanel("PetTeamReplace") then
    self:ClosePanel("PetTeamReplace")
  end
end

function PetUIModule:AnimClosePetTeamReplacePanel()
  if self:HasPanel("PetTeamReplace") then
    local panel = self:GetPanel("PetTeamReplace")
    panel:OnCloseButtonClick()
  end
end

function PetUIModule:OnPetTeamHasCommonEvolution(...)
  if self:HasPanel("PetTeamReplace") then
    local panel = self:GetPanel("PetTeamReplace")
    return panel:HasCommonEvolution(...)
  end
  return false
end

function PetUIModule:OnPetTeamReplaceGetCurSelectIsInTeam()
  if self:HasPanel("PetTeamReplace") then
    local panel = self:GetPanel("PetTeamReplace")
    return panel:GetCurSelectIsInTeam()
  end
  return false
end

function PetUIModule:OnPetTeamReplaceGetCurSelPetDataGid()
  if self:HasPanel("PetTeamReplace") then
    local panel = self:GetPanel("PetTeamReplace")
    return panel:GetCurSelPetDataGid()
  end
  return 0
end

function PetUIModule:OnPetTeamReplaceGetCurMode()
  if self:HasPanel("PetTeamReplace") then
    local panel = self:GetPanel("PetTeamReplace")
    return panel:GetCurMode()
  end
  return 0
end

function PetUIModule:OnPetTeamReplaceGetCurExChangeState()
  local panel = self:GetPanel("PetTeamReplace")
  if panel then
    return panel:GetCurExChangeState()
  end
  return false
end

function PetUIModule:OpenPetTeamReplacePanel(teamType, selectTeamIndex, petGid, slotId, mode, openType)
  self.data.OpenTeamType = teamType
  self:OpenPanel("PetTeamReplace", teamType, selectTeamIndex, petGid, slotId, mode, openType)
end

function PetUIModule:IsPetTeamReplaceTrialPetExpired()
  if self:HasPanel("PetTeamReplace") then
    local panel = self:GetPanel("PetTeamReplace")
    return panel:IsTrialPetExpired()
  end
end

function PetUIModule:ClosePetTeamManagementPanel()
  if self:HasPanel("PetTeamManagement") then
    self:ClosePanel("PetTeamManagement")
  end
end

function PetUIModule:OnPetTeamSetBtnCloseState(State)
  if self:HasPanel("PetTeamPanel") then
    local panel = self:GetPanel("PetTeamPanel")
    panel:OnPetTeamSetBtnCloseStateFromCmd(State)
  end
end

function PetUIModule:OnCmdOpenPetTeamManagementPanel(teamType, index, bPVP)
  self:OpenPanel("PetTeamManagement", teamType, index, bPVP)
end

function PetUIModule:OnZonePlayerInChangePetZoneNotify(notify)
  self.data:SetEnableChange(true)
end

function PetUIModule:OnZonePlayerLeaveChangePetZoneNotify(notify)
  self.data:SetEnableChange(false)
end

function PetUIModule:OnCmdGetIsCanExchangePet()
  return self.data:GetEnableChange()
end

function PetUIModule:OnCmdOnClickSwitchPanelByIndex(_data, _Index, _IsOpen, _IsUpdate, _IsFiIterHaving)
  self:DispatchEvent(PetUIModuleEvent.OnClickSwitchPanelByIndexEvent, _data, _Index, _IsOpen, _IsUpdate, _IsFiIterHaving)
end

function PetUIModule:OnCmdOpenPetEvolutionItemPanel(_param)
  self:OpenPanel("PetEvolutionItem", _param)
end

function PetUIModule:OnCmdOpenPetEvolutionFinishPanel(_param1, _param2)
  _G.NRCAudioManager:PlaySound2DAuto(1068, "PetUIModule:OnCmdOpenPetEvolutionFinishPanel")
  self:OpenPanel("PetEvolutionFinish", {
    owner = _param1 and _param1.owner,
    callback = _param1 and _param1.callback,
    petbaseConfId = _param2
  })
end

function PetUIModule:OnCmdClosePetEvolutionFinishPanel()
  Log.Debug("[PetUIModule:OnCmdClosePetEvolutionFinishPanel]")
  _G.NRCAudioManager:PlaySound2DAuto(1002, "PetUIModule:OnCmdClosePetEvolutionFinishPanel")
  self:ClosePanel("PetEvolutionFinish")
end

function PetUIModule:OnCmdOpenPetEvolutionRewardPanel(_param)
  _G.NRCAudioManager:PlaySound2DAuto(1066, "PetUIModule:OnCmdOpenPetEvolutionRewardPanel")
  self:OpenPanel("PetEvolutionReward", _param)
end

function PetUIModule:OnCmdOpenPetEvolutionTaskPanel(_param)
  _G.NRCAudioManager:PlaySound2DAuto(1067, "PetUIModule:OnCmdOpenPetEvolutionTaskPanel")
  self:OpenPanel("PetEvolutionTask", _param)
end

function PetUIModule:OnCmdOpenRechristenPanel(_Param, isAction, _Mode)
  self:OpenPanel("Rename", _Param, isAction, _Mode)
end

function PetUIModule:OnCmdOpenPetDetailedInfo(_Param)
  self:OpenPanel("PetDetailedInfo", _Param)
end

function PetUIModule:OnCmdOpenPetEvoPanel(_param, _param1)
  self:OpenPanel("PetEvoPanel", _param, _param1)
end

function PetUIModule:OnCmdOpenPetEvoNewPanel(_param, _param1)
  self:OpenPanel("PetEvoNewPanel", _param, _param1)
end

function PetUIModule:OnCmdGetPetHeadSlotScreenPos()
  local hasPanel = self:HasPanel("PetInfoMain")
  if hasPanel then
    local panel = self:GetPanel("PetInfoMain")
    if panel then
      return panel:GetPetHeadSlotScreenPos()
    end
  end
end

function PetUIModule:OnCmdClosePetTeamPanel()
  if self:HasPanel("PetTeamPanel") then
    self:ClosePanel("PetTeamPanel")
    UE4Helper.SetEnableWorldRendering(nil, nil, "UMG_PetTeam_Main")
  end
end

function PetUIModule:OnCmdOpenPetTeamPanel(TeamType, Caller, CallBack, openType)
  self.data.OpenTeamType = TeamType
  self:OpenPanel("PetTeamPanel", TeamType, Caller, CallBack, openType)
end

function PetUIModule:OnCmdPetMainOpenPvPPetTeamPanel()
  self.data.OpenTeamType = _G.ProtoEnum.PlayerTeamType.PTT_PVP_BATTLE_1
  self.IsPetMainOpenPvPTeam = true
  self:OpenPanel("PetTeamPanel", nil, true)
end

function PetUIModule:OnCmdOpenWorldPetTeamPanel(action)
  self.data.OpenTeamType = _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD
  self:OpenPanel("PetTeamPanel", {action = action})
end

function PetUIModule:OnCmdOpenPvPPetTeamPanel()
  self.data.OpenTeamType = _G.ProtoEnum.PlayerTeamType.PTT_PVP_BATTLE_1
  self:OpenPanel("PetTeamPanel", nil, true)
end

function PetUIModule:OnCmdPlayPetTeamOpenAnimation()
  if self:HasPanel("PetTeamPanel") then
    local panel = self:GetPanel("PetTeamPanel")
    if panel then
      panel:PlayOpenAnimation()
    end
  end
end

function PetUIModule:OnCmdOpenPetTeamResonancePanel(team)
  self:OpenPanel("PetTeamResonancePanel", team)
end

function PetUIModule:OnCmdRefreshPetTeamPanel(IsPvPToPetTeam)
  if self:HasPanel("PetTeamPanel") then
    local panel = self:GetPanel("PetTeamPanel")
    if IsPvPToPetTeam then
      if panel then
        panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    elseif panel then
      panel:RefreshUIFromCmd()
    end
  end
end

function PetUIModule:CmdSetSavePetTeamInfo(curTeamIdx, curPetGid, curSlotId, curMode)
  self.curTeamIdx = curTeamIdx
  self.curPetGid = curPetGid
  self.curSlotId = curSlotId
  self.curMode = curMode
end

function PetUIModule:GetPetTeamUITeamInfo(TeamType)
  if TeamType then
    if TeamType == Enum.PlayerTeamType.PTT_BIG_WORLD then
      return _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
    else
      return _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(TeamType)
    end
  else
    return _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
  end
end

function PetUIModule:OnCmdrepetname(gid, name)
  local req = _G.ProtoMessage:newZonePetRenameReq()
  req.gid = gid
  req.name = name
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_RENAME_REQ, req, self, self.ZoneRenameRsp)
end

function PetUIModule:ZoneRenameRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:DispatchEvent(PetUIModuleEvent.PetRename, rsp)
    self:CheckRenameEasterEgg(rsp)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.TssJudgeErr.ERR_JUDGE_MSG_ERROR then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_rename_2)
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
    local reasonStr = rsp.ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
end

function PetUIModule:CheckRenameEasterEgg(rsp)
  if rsp and rsp.ret_info and rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes and rsp.ret_info.goods_change_info.changes[1] and rsp.ret_info.goods_change_info.changes[1].pet_data then
    local PetData = rsp.ret_info.goods_change_info.changes[1].pet_data
    local PetConfId = PetData.conf_id
    local PetConf = _G.DataConfigManager:GetPetConf(PetConfId)
    if PetConf and PetConf.need_name and PetConf.need_name ~= "" and PetData.name == PetConf.need_name then
      local PetUISkillPath = PetConf.pet_interface_anim
      _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnPlayPetSkill, PetUISkillPath)
    end
  end
end

function PetUIModule:OnCmdOpenRechristen_1Panel()
  self:OpenPanel("Tips")
end

function PetUIModule:OnCmdPetUpgradePopout(before_Param, _Param, _petInfoMainCtrl, _beforeLevel)
  self:OpenPanel("PetUpgradePanel", before_Param, _Param, _petInfoMainCtrl, _beforeLevel)
end

function PetUIModule:OnCmdOpenPetFreePanel(_Param)
  local bIncludeCanTraceBackPet = false
  for _, petData in pairs(_Param or {}) do
    if PetUtils.CheckPetIsCanTraceBack(petData, true, false, true) then
      bIncludeCanTraceBackPet = true
      break
    end
  end
  if bIncludeCanTraceBackPet then
    self:OnCmdSendQueryBacktrackPetRewardReq(_Param)
  else
    self:OpenPanel("PetFreeCaptiveAnimals", _Param)
  end
end

function PetUIModule:OnCmdOpenBackpackPetFreePanel(_Param)
  local bIncludeCanTraceBackPet = false
  for _, petData in pairs(_Param or {}) do
    if PetUtils.CheckPetIsCanTraceBack(petData, true, false, true) then
      bIncludeCanTraceBackPet = true
      break
    end
  end
  if bIncludeCanTraceBackPet then
    self:OnCmdSendQueryBacktrackPetRewardReq(_Param)
  else
    self:OpenPanel("PetFreeCaptive", _Param)
  end
end

function PetUIModule:OnCmdOpenPetHavingFitTogether(_Param)
  self:OpenPanel("PetHavingFitTogether", _Param)
end

function PetUIModule:OnCmdOpenPetBag(_PetData)
  local req = _G.ProtoMessage:newZoneOpenPetBagReq()
  local gidList = {}
  if _PetData then
    table.insert(gidList, _PetData.gid)
  else
    gidList = nil
  end
  req.pet_gid = gidList
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_OPEN_PET_BAG_REQ, req, self, self.GetPetTeamInfo)
end

function PetUIModule:PlayPetEvoSkill()
  if not self:HasPanel("PetEvoPanel") then
    return
  end
  local panel = self:GetPanel("PetEvoPanel")
  panel:PlayEvoSkill()
end

function PetUIModule:OnCmdSetPetSkillLoopState(bool)
  if not self:HasPanel("PetInfoMain") then
    return
  end
  local panel = self:GetPanel("PetInfoMain")
  panel:OnClickStartEvo(bool)
  if not self:HasPanel("PetEvoNewPanel") then
    return
  end
end

function PetUIModule:GetEvoTargetCfgId()
  return self.data.EvoTargetCfgId
end

function PetUIModule:OnCmdSavaPetSortIndex(IsSava, _index)
  if IsSava then
    self.data:SetPetSortIndex(_index)
  else
    local PetSortIndex = self.data:GetPetSortIndex()
    self:DispatchEvent(PetUIModuleEvent.SetWarehousePetSortIndex, PetSortIndex)
  end
end

function PetUIModule:GetPetTeamInfo(_rsp)
end

function PetUIModule:OnChangePetTeamsInfoForTeamName(_rsp)
  local function CallEvent(main_team_idx)
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.PetTeamManagementModifyTeamName)
    
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.PetInfoMainModifyTeamName)
  end
  
  self:OnChangePetTeamsInfo(_rsp, CallEvent)
end

function PetUIModule:OnChangePetTeamsInfoForTeam(_rsp)
  local function CallEvent(main_team_idx)
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetTeamManagementSelChanged, main_team_idx)
  end
  
  self:OnChangePetTeamsInfo(_rsp, CallEvent)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.CloseTeamReplacePanel, _rsp.ret_info.ret_code)
end

function PetUIModule:OnChangePetTeamsInfoForSkills(_rsp)
  local function CallEvent(main_team_idx)
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PvpPetTeamEquipPetSkills, main_team_idx)
  end
  
  self:OnChangePetTeamsInfo(_rsp, CallEvent)
end

function PetUIModule:OnChangePetTeamsInfoForMagicGid(_rsp)
  local function CallEvent(main_team_idx)
    self:DispatchEvent(PetUIModuleEvent.EquipmentOrRemoveBloodEvent)
    
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetTeamEquipPetMagicRsp, main_team_idx)
  end
  
  self:OnChangePetTeamsInfo(_rsp, CallEvent)
end

function PetUIModule:OnCmdChangePetTeamRoleMagicGid(team_index, team_type, role_magic_gid)
  local req = self:GetCurrentPetTeamReq(team_index, team_type)
  if not req then
    return
  end
  req.teams[1].role_magic_gid = role_magic_gid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnChangePetTeamsInfoForMagicGid)
end

function PetUIModule:CreateServerPetTeamPetInfoFromClientData(petInfo, options)
  if not petInfo then
    return nil
  end
  options = options or {}
  local checkRandomPet = options.checkRandomPet or true
  local deepCopyEquipInfos = options.deepCopyEquipInfos or false
  local onePet = _G.ProtoMessage:newPetTeam_PetInfo()
  local petGid = petInfo and petInfo.pet_gid
  local teamPetEquipInfos = petInfo and petInfo.equip_infos or options and options.equipInfos
  if checkRandomPet then
    local isRandomPet = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsRandomPet, petGid)
    if isRandomPet then
      local randomPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
      local randomPetType = randomPetData and randomPetData.type
      onePet.type = randomPetType
    elseif petGid then
      onePet.pet_gid = petGid
    end
  elseif petGid then
    onePet.pet_gid = petGid
  end
  if teamPetEquipInfos then
    if deepCopyEquipInfos then
      onePet.equip_infos = {}
      for _, skill in pairs(teamPetEquipInfos) do
        table.insert(onePet.equip_infos, {
          id = skill.id,
          pos = skill.pos
        })
      end
    else
      onePet.equip_infos = teamPetEquipInfos
    end
  else
  end
  return onePet
end

function PetUIModule:InsertTeamPet(OneTeam, Team)
  if Team then
    for i = 1, #Team do
      local TeamItem = Team[i]
      local onePet = self:CreateServerPetTeamPetInfoFromClientData(TeamItem, {deepCopyEquipInfos = true})
      table.insert(OneTeam.pet_infos, onePet)
    end
  else
    OneTeam.pet_infos = {}
  end
end

function PetUIModule:OnCmdChangePetTeamName(team_index, team_type, team_name)
  local req = self:GetCurrentPetTeamReq(team_index, team_type)
  if not req then
    return
  end
  req.teams[1].team_name = team_name
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnChangePetTeamsInfoForTeamName)
end

function PetUIModule:OnCmdPvpEquipSkillsByTeamType(team_index, team_type, PetGid, Skills)
  self.data:SetPetSkillsData(PetGid, Skills)
  local req = self:GetCurrentPetTeamReq(team_index, team_type)
  if not req then
    return
  end
  local oneTeam = req.teams[1]
  local hasModify = false
  for i = 1, #oneTeam.pet_infos do
    local onePet = oneTeam.pet_infos[i]
    if onePet.pet_gid == PetGid then
      hasModify = true
      onePet.equip_infos = {}
      for index, skillId in pairs(Skills) do
        table.insert(onePet.equip_infos, {id = skillId, pos = index})
      end
    end
  end
  if not hasModify then
    self:DispatchEvent(PetUIModuleEvent.PvpPetTeamEquipPetSkills, team_index)
    return
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnChangePetTeamsInfoForSkills)
end

function PetUIModule:OnCmdChangePetTeamInfo(team, team_index, team_type, teamName)
  local checkTeam = {}
  for _, petInfo in pairs(team) do
    if petInfo and type(petInfo) == "table" and petInfo.pet_gid then
      table.insert(checkTeam, petInfo.pet_gid)
    end
  end
  if not PetUtils.CheckPvpTeamValid(checkTeam, team_type) then
    local nameLessCfg = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_same_pet")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, nameLessCfg.str)
    return false
  end
  local req = self:GetCurrentPetTeamReq(team_index, team_type)
  if not req then
    return false
  end
  local oneTeam = req.teams[1]
  oneTeam.pet_infos = {}
  if team.magicID then
    if -1 == team.magicID then
      oneTeam.role_magic_gid = nil
    else
      oneTeam.role_magic_gid = team.magicID
    end
  end
  if teamName then
    oneTeam.team_name = teamName
  end
  for i = 1, #team do
    local teamPetItem = team[i]
    local petGid = teamPetItem and teamPetItem.pet_gid
    local teamPetEquipInfos = self.data:GetPetEquipInfos(petGid)
    local onePet = self:CreateServerPetTeamPetInfoFromClientData(teamPetItem, {checkRandomPet = true, equipInfos = teamPetEquipInfos})
    table.insert(oneTeam.pet_infos, onePet)
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnChangePetTeamsInfoForTeam)
  return true
end

function PetUIModule:GetCurrentPetTeamReq(team_index, team_type)
  local teamInfo = self:GetPetTeamUITeamInfo(team_type)
  if not teamInfo then
    Log.Error("PetUIModule:GetCurrentPetTeamReq team info is nil, the type is ", team_type)
    return nil
  end
  local InitTeam = teamInfo.teams[team_index + 1]
  if not InitTeam then
    Log.Error("PetUIModule:GetCurrentPetTeamReq\233\152\159\228\188\141\230\149\176\230\141\174\229\188\130\229\184\184\239\188\140\232\175\183\230\163\128\230\159\165\233\152\159\228\188\141\231\177\187\229\158\139\230\152\175\229\144\166\230\173\163\231\161\174", team_type)
    return nil
  end
  local req = _G.ProtoMessage:newZonePetTeamChangeReq()
  local oneTeam = _G.ProtoMessage:newPetTeam()
  self:InsertTeamPet(oneTeam, InitTeam.pet_infos)
  oneTeam.team_name = InitTeam.team_name
  oneTeam.role_magic_gid = InitTeam.role_magic_gid
  table.insert(req.teams, oneTeam)
  req.team_type = team_type or _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD
  table.insert(req.team_idxs, team_index)
  local brief = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPetBrief)
  oneTeam.trial_pet = brief
  return req
end

function PetUIModule:GetCurrentPetTeamsReq(team_indexList, team_type)
  local req = _G.ProtoMessage:newZonePetTeamChangeReq()
  for i = 1, #team_indexList do
    local team_index = team_indexList[i]
    local teamInfo = self:GetPetTeamUITeamInfo(team_type)
    if not teamInfo then
      Log.Error("PetUIModule:GetCurrentPetTeamReq team info is nil, the type is ", team_type)
      return nil
    end
    local InitTeam = teamInfo.teams[team_index + 1]
    local oneTeam = _G.ProtoMessage:newPetTeam()
    self:InsertTeamPet(oneTeam, InitTeam.pet_infos)
    oneTeam.team_name = InitTeam.team_name
    oneTeam.role_magic_gid = InitTeam.role_magic_gid
    table.insert(req.teams, oneTeam)
    req.team_type = team_type or _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD
    table.insert(req.team_idxs, team_index)
  end
  return req
end

function PetUIModule:OnCmdChangePetBackInfoInfo(changeGid, AddGid)
  local req = _G.ProtoMessage.newZoneUpdatePetBackpackReq()
  local pet_GidList = {}
  if _G.DataModelMgr.PlayerDataModel.playerInfo.pet_info.backpack_info.pet_gid then
    for i, v in ipairs(_G.DataModelMgr.PlayerDataModel.playerInfo.pet_info.backpack_info.pet_gid) do
      if changeGid ~= v and AddGid ~= v then
        table.insert(pet_GidList, v)
      elseif AddGid == v and changeGid then
        table.insert(pet_GidList, changeGid)
      elseif changeGid == v and changeGid then
        table.insert(pet_GidList, AddGid)
      end
    end
  end
  if not changeGid then
    table.insert(pet_GidList, AddGid)
  end
  req.pet_gid = pet_GidList
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UPDATE_PET_BACKPACK_REQ, req, self, self.OnPetUpdate)
end

function PetUIModule:OnPetUpdate(rsp)
  self:DispatchEvent(PetUIModuleEvent.ChangeWorldTeamSuccess, rsp)
  if 0 == rsp.ret_info.ret_code then
    self:DispatchEvent(PetUIModuleEvent.OnPetWareHouseUpdate)
  end
end

function PetUIModule:OnCmdChangePetTeamsInfo(_teams, team_indexs, team_type, update_backpack, teamNames)
  local req = self:GetCurrentPetTeamsReq(team_indexs, team_type)
  if not req then
    return false
  end
  local Teams = req.teams
  local MainTeamIndex = 0
  local petTeamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(team_type)
  local curMainTeamIndex = petTeamInfo.main_team_idx
  local IsEmptyMainTeam = false
  for j = 1, #Teams do
    local team = _teams[j]
    Teams[j].pet_infos = {}
    if team.magicID then
      Teams[j].role_magic_gid = team.magicID
    end
    if #team > 0 then
      MainTeamIndex = team_indexs[j]
    elseif team_indexs[j] == curMainTeamIndex then
      IsEmptyMainTeam = true
    end
    for i = 1, #team do
      local onePet = self:CreateServerPetTeamPetInfoFromClientData(team[i], {deepCopyEquipInfos = false})
      if onePet then
        table.insert(Teams[j].pet_infos, onePet)
      end
    end
    if teamNames and teamNames[j] then
      Teams[j].team_name = teamNames[j]
    end
  end
  if update_backpack then
    req.update_backpack = update_backpack
  end
  req.strict_check = false
  req.main_team_idx = IsEmptyMainTeam and MainTeamIndex or nil
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnChangePetTeamsInfoForChangeWorldTeamIndex)
end

function PetUIModule:OnChangePetTeamsInfoForChangeWorldTeamIndex(_rsp)
  self:OnChangePetTeamsInfo(_rsp)
  self:DispatchEvent(PetUIModuleEvent.UpdateBloodInfo)
  self:DispatchEvent(PetUIModuleEvent.ChangeWorldTeamSuccess, _rsp)
end

function PetUIModule:OnCmdOnTypeChooseBtnClicked(TypeChooseList)
  self.data.chooseTypeList = self.data.chooseTypeListTemporary
  self:DispatchEvent(PetUIModuleEvent.TypeChooseChanged, self.data.chooseTypeList)
  if not self:HasPanel("PetWarehousePanelMain") then
    return
  end
  local panel = self:GetPanel("PetWarehousePanelMain")
  panel:OnClickTypeBtn(self.data.chooseTypeList)
end

function PetUIModule:OnCmdOnTypeChooseChanged(TypeChooseList, bChoosed)
  local ChooseTypeListTemporary = self:CopyChooseTypeListTemporary()
  local hasTypePos = 0
  if 0 == #ChooseTypeListTemporary then
  else
    for i = 1, #ChooseTypeListTemporary do
      if ChooseTypeListTemporary[i] == TypeChooseList.typeId then
        hasTypePos = i
      end
    end
  end
  if true == bChoosed then
    if #ChooseTypeListTemporary > 0 then
      if 0 == hasTypePos then
        table.clear(ChooseTypeListTemporary)
        table.insert(ChooseTypeListTemporary, TypeChooseList.typeId)
      end
    else
      table.insert(ChooseTypeListTemporary, TypeChooseList.typeId)
    end
  elseif 0 ~= hasTypePos then
    table.remove(ChooseTypeListTemporary, hasTypePos)
  end
  self.data.chooseTypeListTemporary = ChooseTypeListTemporary
end

function PetUIModule:CopyChooseTypeListTemporary()
  local chooseTypeListTemporary = {}
  for i, Type in ipairs(self.data.chooseTypeListTemporary) do
    table.insert(chooseTypeListTemporary, Type)
  end
  return chooseTypeListTemporary
end

function PetUIModule:OnCmdGetTypeChooseNum()
  return self.data.chooseTypeList
end

function PetUIModule:OnCmdSetChooseTypeListTemporary(_data)
  self.data.chooseTypeListTemporary = _data
end

function PetUIModule:OnCmdGetChooseTypeListTemporary()
  return self.data.chooseTypeListTemporary
end

function PetUIModule:CmdIsFirstLoadBackground()
  return self.IsFirstLoadBg
end

function PetUIModule:OnCmdSetIsFirstLoadBackground(_IsFirstLoadBg)
  self.IsFirstLoadBg = _IsFirstLoadBg
end

function PetUIModule:OnCmdSetPetWarehouseTipBtnEnable(bEnable)
  self.data.bPetWarehouseTipBtnEnable = bEnable
end

function PetUIModule:OnChangePetTeamsInfo(_rsp, CallEvent)
  if 0 == _rsp.ret_info.ret_code then
    if _rsp.ret_info.goods_change_info then
      local changeItems = _rsp.ret_info.goods_change_info.changes
      if changeItems and #changeItems > 0 then
        for i, changeItem in ipairs(changeItems) do
          if changeItem.src_type == ProtoEnum.GoodsType.GT_TEAMINFO then
            _G.DataModelMgr.PlayerDataModel:SetPlayerPvPPetTeamInfo(changeItem.team_info)
            _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetTeamManagementSelChanged)
            if CallEvent then
              CallEvent(changeItem.team_info.main_team_idx, _rsp)
            end
          end
        end
      end
    end
    if self:HasPanel("PetWarehousePanelMain") then
      local panel = self:GetPanel("PetWarehousePanelMain")
      panel:OnUpdatePetWareHouseInfo()
    end
    local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList)
    if _G.AppMain:HasDebug() then
      _G.NRCModeManager:DoCmd(DebugModuleCmd.PetTeamFriendGetMirrorPetData)
    end
  elseif _rsp.ret_info.ret_code == 2388 then
    PVPRankedMatchModuleUtils.TrialPetExpiredClosePanel()
  end
end

function PetUIModule:OnCmdChangePetMainTeam(_main_team_idx, team_type)
  local teamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
  if team_type and team_type == _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD and (_main_team_idx < 0 or teamInfo.teams and _main_team_idx > #teamInfo.teams - 1) then
    Log.Error("PetUIModule:OnCmdChangePetMainTeam _main_team_idx error , Please Check teamIndex", _main_team_idx)
    return
  end
  local req = _G.ProtoMessage:newZonePetChangeMainTeamReq()
  req.main_team_idx = _main_team_idx
  req.team_type = _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD
  if team_type then
    req.team_type = team_type
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_CHANGE_MAIN_TEAM_REQ, req, self, self.OnChangePetMainTeam)
end

function PetUIModule:OnChangePetMainTeam(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    local teamInfo = _rsp.ret_info.goods_change_info.changes
    if teamInfo and #teamInfo > 0 then
      for k, changeItem in ipairs(teamInfo) do
        if changeItem.src_type == ProtoEnum.GoodsType.GT_TEAMINFO then
          _G.DataModelMgr.PlayerDataModel:SetPlayerPvPPetTeamInfo(changeItem.team_info)
          _G.DataModelMgr.PlayerDataModel:OnPetMainTeamChanged(changeItem.team_info.main_team_idx)
          self:DispatchEvent(PetUIModuleEvent.PET_TEAM_CHANGE)
          _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetTeamManagementSelChanged, changeItem.team_info.main_team_idx)
          if changeItem.team_info.team_type == _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD then
            local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
            _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList)
          end
        end
      end
    end
  end
end

function PetUIModule:OnCmdPetGrowUp(pet_gid, grow_times, PetPropertyInfo)
  self.PetPropertyInfo = PetPropertyInfo
  local req = _G.ProtoMessage:newZonePetGrowReq()
  req.pet_gid = pet_gid
  req.grow_times = grow_times
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_GROW_REQ, req, self, self.OnPetGrowUpRsp)
end

function PetUIModule:OnPetGrowUpRsp(rsp)
  Log.Dump(rsp, 6, "PetUIModule:OnPetGrowUpRsp")
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.petuimodule_1 .. tostring(rsp.ret_info.ret_code))
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  self:DispatchEvent(PetUIModuleEvent.PET_GROWUP_SUCCESS, retVal)
  self:OpenPanel("PetGrowUpPanel", retVal, PetUIModuleEnum.PetGrowUpType.WaitToGrowUp, self.PetPropertyInfo)
end

function PetUIModule:OnCmdPetInspire(PetGid, OldPetData, PetBeForePropertyInfo, Property)
  if nil == PetGid then
    return
  end
  self.PetBeForePropertyInfo = PetBeForePropertyInfo
  self.oldPetData = OldPetData
  self.Property = Property
  local req = _G.ProtoMessage:newZonePetInspireReq()
  req.gid = PetGid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_INSPIRE_REQ, req, self, self.OnPetInspireRsp)
end

function PetUIModule:OnPetInspireRsp(rsp)
  if rsp and 0 == rsp.ret_info.ret_code then
    local retVal
    if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
      retVal = rsp.ret_info.goods_change_info.changes
      if retVal then
        self:DispatchEvent(PetUIModuleEvent.PET_GROWUP_SUCCESS, retVal)
        self:OpenPanel("PetGrowUpPanel", retVal, PetUIModuleEnum.PetGrowUpType.WaitToInspire, nil, self.PetBeForePropertyInfo, self.oldPetData, self.Property)
      end
    end
  end
end

function PetUIModule:OnCmdPetBreakThrough(oldPetData, _PetBeForePropertyInfo, _Property)
  self.PetBeForePropertyInfo = _PetBeForePropertyInfo
  self.oldPetData = oldPetData
  self.Property = _Property
  local req = _G.ProtoMessage:newZonePetBreakthroughReq()
  req.gid = oldPetData.gid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_BREAKTHROUGH_REQ, req, self, self.OnPetPetBreakThroughRsp)
end

function PetUIModule:OnPetPetBreakThroughRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.petuimodule_1 .. tostring(rsp.ret_info.ret_code))
    self:DispatchEvent(PetUIModuleEvent.ResetIsInEvolution)
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  if self.data.OpenPanelPetData then
    self:OnCmdGetOpenPanelPetDataRedPoint()
  end
  self:DispatchEvent(PetUIModuleEvent.PET_GROWUP_SUCCESS, retVal)
  self:OnCmdPetBreakeThrough(retVal)
end

function PetUIModule:OnCmdPetBreakeThrough(_Param)
  self:OpenPanel("PetGrowUpPanel", _Param, PetUIModuleEnum.PetGrowUpType.WaitToBreakThrough, nil, self.PetBeForePropertyInfo, self.oldPetData, self.Property)
end

function PetUIModule:OnCmdSendPetTraceBackReq(pet_gid, bOnlyCheck)
  Log.Debug("PetUIModule:OnCmdSendPetTraceBackRsq, pet_gid=[", pet_gid, "], bOnlyCheck=[", bOnlyCheck, "]")
  local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(pet_gid)
  if PetData and PetUtils.CheckPetIsCanTraceBack(PetData, false, false, true) then
    local req = _G.ProtoMessage:newZoneBacktrackPetReq()
    req.pet_gid = pet_gid
    req.is_for_check = bOnlyCheck
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BACKTRACK_PET_REQ, req, self, self.OnPetTraceBackRsp)
  end
end

function PetUIModule:OnPetTraceBackRsp(rsp)
  Log.DebugFormat("PetUIModule:OnPetTraceBackRsp")
  Log.Dump(rsp, 6, "ZONE_BACKTRACK_PET_RSQ")
  if 0 ~= rsp.ret_info_ret_code then
    if rsp.is_for_check then
      self:UpdatePetTraceBackPopup(rsp.pet_gid, rsp.show_info, rsp.reward_list)
    else
      self:ClosePetTraceBackPopup()
      if #rsp.ret_info.goods_reward.rewards > 0 then
        local CommonPopupData = {
          Call = self,
          ClosePanelHandler = function()
            local retVal
            if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
              retVal = rsp.ret_info.goods_change_info.changes
            end
            self:DispatchEvent(PetUIModuleEvent.PET_TRACEBACK_SUCCESS_REWARD_POPUP_CLOSE, retVal, rsp.pet_gid)
          end
        }
        _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rsp.ret_info.goods_reward.rewards, LuaText.get_reward_tips_title, nil, nil, nil, nil, nil, CommonPopupData)
      end
    end
  else
    self:ClosePetTraceBackPopup()
    Log.Error("PetUIModule:OnPetTraceBackRsp failed")
  end
end

function PetUIModule:OnCmdSendQueryBacktrackPetRewardReq(petDataList)
  Log.Debug("PetUIModule:OnCmdSendQueryBacktrackPetRewardReq")
  local GIDs = {}
  for k, v in pairs(petDataList or {}) do
    if v then
      table.insert(GIDs, v.gid)
    end
  end
  if 0 ~= #GIDs then
    local req = _G.ProtoMessage:newZoneQueryBacktrackPetRewardReq()
    req.pet_gid = GIDs
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_BACKTRACK_PET_REWARD_REQ, req, self, self.OnQueryBacktrackPetRewardRsp)
  end
end

function PetUIModule:OnQueryBacktrackPetRewardRsp(rsp)
  Log.Debug("PetUIModule:OnQueryBacktrackPetRewardRsp")
  if 0 == rsp.ret_info.ret_code and rsp.pet_gid and #rsp.pet_gid > 0 then
    local PetDataList = {}
    for k, gid in pairs(rsp.pet_gid) do
      if gid then
        local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
        if PetData then
          table.insert(PetDataList, PetData)
        end
      end
    end
    if 1 == #rsp.pet_gid then
      self:OpenPanel("PetFreeCaptive", PetDataList, PetUIModuleEnum.PetFreeCaptivePanelStateType.IncludeCanTraceBackPet, rsp.reward_list)
    else
      self:OpenPanel("PetFreeCaptiveAnimals", PetDataList, PetUIModuleEnum.PetFreeCaptivePanelStateType.IncludeCanTraceBackPet, rsp.reward_list)
    end
  end
end

function PetUIModule:OnPetSort(index, OpenType)
  if OpenType == PetUIModuleEnum.OpenSortType.WareHouse then
    self:DispatchEvent(PetUIModuleEvent.PET_UI_SORT, index)
  elseif OpenType == PetUIModuleEnum.OpenSortType.TeamReplace then
    self:DispatchEvent(PetUIModuleEvent.PET_UI_SORT, index)
  elseif OpenType == PetUIModuleEnum.OpenSortType.WareHouseFree then
    self:DispatchEvent(PetUIModuleEvent.PET_UI_FREE_SORT, index)
  elseif OpenType == PetUIModuleEnum.OpenSortType.WeeklyChallengeBattle then
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PET_UI_SORT, index)
  elseif OpenType == PetUIModuleEnum.OpenSortType.BattleRogue then
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PET_UI_SORT, index)
  end
end

function PetUIModule:OnCmdSendPetEvoluteReq(_petgid, _evolutionIdx)
  local req = _G.ProtoMessage:newZonePetEvoluteReq()
  req.pet_gid = _petgid
  req.chosen_evolve_idx = _evolutionIdx
  if self:HasPanel("PetEvoNewPanel") then
    local panel1 = self:GetPanel("PetEvoNewPanel")
    panel1:ShowReturnBtn(false)
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetEvoNewPanel").EVOLUTIONCONFIRM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetEvoNewPanel", touchReasonType)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_EVOLUTE_REQ, req, self, self.OnPetEvoluteRsp, false, true)
end

function PetUIModule:OnPetEvoluteRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self.data.CulCanEvo = false
    self.data.CulEvoId = 0
    self:OnCmdGetOpenPanelPetDataRedPoint()
    local rewardItems = {}
    if _rsp.ret_info and _rsp.ret_info.goods_reward and _rsp.ret_info.goods_reward.rewards then
      for k, info in ipairs(_rsp.ret_info.goods_reward.rewards) do
        table.insert(rewardItems, {
          itemId = info.id,
          itemCnt = info.num,
          itemType = info.type
        })
      end
    end
    local evolutePetData, petData
    if _rsp.ret_info and _rsp.ret_info.goods_change_info and _rsp.ret_info.goods_change_info.changes then
      local retVal = _rsp.ret_info.goods_change_info.changes
      for i, changItem in ipairs(retVal) do
        if changItem.type == _G.ProtoEnum.GoodsType.GT_PET then
          petData = changItem.pet_data
          if petData and petData.evolution_task and petData.evolution_task > 0 then
            evolutePetData = petData
          end
        end
      end
      self:DispatchEvent(PetUIModuleEvent.OnRefreshEvoPetModel, retVal)
      _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnRefreshEvoPetModel, petData)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSkillLoopState, false)
      if petData and _G.DataModelMgr.PlayerDataModel:GetIsMainTeamPetByGid(petData.gid) then
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, petData.gid)
      end
    end
  else
    if self:HasPanel("PetEvoNewPanel") then
      local panel1 = self:GetPanel("PetEvoNewPanel")
      panel1:ShowReturnBtn(true)
    end
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PetEvolutionFail)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.evolution_fail_tips)
  end
end

function PetUIModule:OnCmdEquipSkill2(petGid, posToIdDic)
  if not petGid then
    Log.Error("PetUIModule:OnCmdEquipSkill2 petGid param is empty!")
    return
  end
  if not posToIdDic or not next(posToIdDic) then
    Log.Error("PetUIModule:OnCmdEquipSkill2 skills param is empty!")
    return
  end
  local req = _G.ProtoMessage:newZonePetEquipSkillReq()
  req.gid = petGid
  req.equip_info = {}
  for pos, skillId in pairs(posToIdDic) do
    if skillId > 0 then
      local equipInfo = {
        id = skillId,
        pos = #req.equip_info + 1
      }
      table.insert(req.equip_info, equipInfo)
    end
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_EQUIP_SKILL_REQ, req, self, self.OnEquipSKillRsp)
end

function PetUIModule:OnEquipSKillRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.petuimodule_2 .. tostring(rsp.ret_info.ret_code))
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  self:DispatchEvent(PetUIModuleEvent.EQUIP_SKILL_SUCCESS, retVal)
end

function PetUIModule:CmdCloseAllPetShareTeamDiffPanel()
  self:ClosePanel("ShareTeamDetailsDifferences")
  self:ClosePanel("ShareTeamDifferenceContent")
  self:ClosePanel("ShareTeamSolveDifferences")
end

function PetUIModule:OnCmdUseExpItem(UseItemList)
  local req = _G.ProtoMessage:newZoneUseMultiBagItemReq()
  req.item_info = UseItemList
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_USE_MULTI_BAG_ITEM_REQ, req, self, self._OnUseExpItemCallback)
end

function PetUIModule:_OnUseExpItemCallback(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:ShowProtocolErrorTips(rsp)
    Log.Debug("\229\174\160\231\137\169\228\189\191\231\148\168\231\187\143\233\170\140\233\129\147\229\133\183\229\164\177\232\180\165 \233\148\153\232\175\175\231\160\129\239\188\154" .. tostring(rsp.ret_info.ret_code))
    return
  end
  self:OnCmdGetOpenPanelPetDataRedPoint()
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  self:DispatchEvent(PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, retVal)
  NRCEventCenter:DispatchEvent(PetUIModuleEvent.RefreshAdjustPetPanel)
end

function PetUIModule:_SetPetPlay(playInfo, bag_pos)
  local req = _G.ProtoMessage:newZonePetSetPlayReq()
  req.play_info = playInfo
  req.bag_pos_gid = bag_pos
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_SET_PLAY_REQ, req, self, self.OnSetPetsIsPlayCallback)
end

function PetUIModule:OnSetPetsIsPlayCallback(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:ShowProtocolErrorTips(rsp)
    Log.Debug("\232\174\190\231\189\174\229\174\160\231\137\169\228\184\138\233\152\181\229\164\177\232\180\165 \233\148\153\232\175\175\231\160\129\239\188\154" .. tostring(rsp.ret_info.ret_code))
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  self:DispatchEvent(PetUIModuleEvent.SET_PET_ISPLAY_SUCCESS, retVal, rsp.bag_pos_gid)
end

function PetUIModule:OnCmdCloseCommonTips()
  self:DispatchEvent(PetUIModuleEvent.PET_UI_COMMON_TIP_CLOSE)
end

function PetUIModule:OnCmdSendFangShengPet(_petgid)
  Log.Debug("PetUIModule:OnCmdSendFangShengPet")
  local req = _G.ProtoMessage:newZonePetFreeReq()
  for i, petinfo in ipairs(_petgid) do
    table.insert(req.pet_gid, petinfo)
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_FREE_REQ, req, self, self.OnFangShengPetCallback, true, true)
end

function PetUIModule:OnFangShengPetCallback(rsp)
  Log.Debug("PetUIModule:OnFangShengPetCallback")
  if 0 ~= rsp.ret_info.ret_code then
    self:ShowProtocolErrorTips(rsp)
    Log.Debug("\232\174\190\231\189\174\229\174\160\231\137\169\228\184\138\233\152\181\229\164\177\232\180\165 \233\148\153\232\175\175\231\160\129\239\188\154" .. tostring(rsp.ret_info.ret_code))
    if self:HasPanel("NewPetBag") then
      local panel = self:GetPanel("NewPetBag")
      panel:OnPetFreeFailed()
    end
    return
  end
  _G.DataModelMgr.PlayerDataModel:OnPetFree(rsp.pet_gid)
  self:UpdateCachePetBoxFilterData(false)
  if self:HasPanel("PetWarehousePanelMain") then
    local panel = self:GetPanel("PetWarehousePanelMain")
    panel:OnPetFreeSuccess()
  end
  if self:HasPanel("PetWarehouseFree") then
    local panel = self:GetPanel("PetWarehouseFree")
    panel:OnPetFreeSuccess()
  end
  if self:HasPanel("NewPetBag") then
    local panel = self:GetPanel("NewPetBag")
    panel:OnPetFreeSuccess()
  end
  if #rsp.ret_info.goods_reward.rewards > 0 then
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rsp.ret_info.goods_reward.rewards, LuaText.get_reward_tips_title)
  end
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnPetFreeCheckHeterochromeSuit, rsp)
end

function PetUIModule:OnCmdOpenSendPetToFriendPanel(gid)
  if gid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
    if petData then
      self:OpenPanel("GiftFromColleagues", petData)
    end
  end
end

function PetUIModule:OnCmdSendPetToFriend(gid, bCheck)
  if gid then
    local req = _G.ProtoMessage:newZoneTogetherCatchPetForGiftingReq()
    req.pet_gid = gid
    req.is_for_check = false
    if bCheck then
      req.is_for_check = true
    end
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TOGETHER_CATCH_PET_FOR_GIFTING_REQ, req, self, self.ZoneTogetherCatchPetForGiftingRsp, true, true)
  end
end

function PetUIModule:OnCmdSetCanShowSendBtn(bShow)
  if self:HasPanel("NewPetBag") then
    local panel = self:GetPanel("NewPetBag")
    if panel then
      panel.bHideSendBtn = not bShow
    end
  end
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    if panel then
      panel:CheckCanSendToFriend()
    end
  end
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    if panel then
      panel:CheckCanSendToFriend()
    end
  end
end

function PetUIModule:OnCmdGetCanShowSendBtn()
  if self:HasPanel("NewPetBag") then
    local panel = self:GetPanel("NewPetBag")
    if panel then
      return not panel.bHideSendBtn
    end
  end
  return true
end

function PetUIModule:OnCmdSetPanelFullScreenMaskShow(panelName, bShow)
  if self:HasPanel(panelName) then
    local panel = self:GetPanel(panelName)
    if panel and panel.SetFullScreenMaskShow then
      panel:SetFullScreenMaskShow(bShow)
    end
  end
end

function PetUIModule:ZoneTogetherCatchPetForGiftingRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    if rsp.is_for_check and rsp.pet_gid then
      self:OnCmdOpenSendPetToFriendPanel(rsp.pet_gid)
    else
      _G.DataModelMgr.PlayerDataModel:OnPetFree()
      self:DispatchEvent(PetUIModuleEvent.OnSendPetSuccess)
    end
  else
    self:ShowProtocolErrorTips(rsp)
    self:DispatchEvent(PetUIModuleEvent.OnSendPetFailed)
  end
end

function PetUIModule:ChangePetPos(petPosList)
  local req = _G.ProtoMessage:newZonePetSetBagPosReq()
  req.bag_pos_gid = petPosList
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_SET_BAG_POS_REQ, req, self, self.OnSetPetBagPosCallback, true, true)
end

function PetUIModule:OnCmdChangePetPos2(_petId1, _petId2)
  local bagPosArray = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo().bag_pos_gid
  if nil ~= _petId1 and nil ~= _petId2 and bagPosArray then
    local bagPos = {}
    for k, gid in ipairs(bagPosArray) do
      if gid == _petId1 then
        table.insert(bagPos, _petId2)
      elseif gid == _petId2 then
        table.insert(bagPos, _petId1)
      else
        table.insert(bagPos, gid)
      end
    end
    local allPetDead = true
    for _, pet_gid in ipairs(bagPos) do
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(pet_gid)
      local maxHp, hp = self:GetPetHP(petData)
      if hp > 0 then
        allPetDead = false
        break
      end
    end
    if allPetDead then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.forbid_change_pet_alldie or LuaText.petuimodule_3)
      return
    end
    self:ChangePetPos(bagPos)
  end
end

function PetUIModule:OnSetPetBagPosCallback(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:ShowProtocolErrorTips(rsp)
    Log.Debug("\228\186\164\230\141\162\229\174\160\231\137\169\228\189\141\231\189\174\229\164\177\232\180\165 \233\148\153\232\175\175\231\160\129\239\188\154" .. tostring(rsp.ret_info.ret_code))
    return
  end
  _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo().bag_pos_gid = rsp.bag_pos_gid
  NRCEventCenter:DispatchEvent(PetUIModuleEvent.CHANGE_PET_POS_SUCCESS, rsp.bag_pos_gid)
end

function PetUIModule:GetPetHP(_petData)
  if _petData and _petData.attribute_new_info then
    local type = _G.ProtoEnum.AttributeType
    local addi_attr = _petData.attribute_new_info.addi_attr_data
    if addi_attr then
      return PetUtils.GetPetAdditionalByType(_petData, type.AT_HPMAX), PetUtils.GetPetAdditionalByType(_petData, type.AT_HPCUR)
    end
  end
  return 0, 0
end

function PetUIModule:OnCmdEquipPossesion(petGid, tarbagConfGid, tarbagConfid, pos, removedpetGid, removePos)
  local req = _G.ProtoMessage:newZonePetEquipPossessionReq()
  req.equip_item_gid = tarbagConfGid
  req.equip_pet_gid = petGid
  req.equip_slot_idx = pos
  req.remove_slot_idx = removePos
  req.remove_pet_gid = removedpetGid
  req.equip_item_conf_id = tarbagConfid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_EQUIP_POSSESSION_REQ, req, self, self.OnEquipPossesionRsp)
end

function PetUIModule:OnEquipPossesionRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.petuimodule_4 .. tostring(rsp.ret_info.ret_code))
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.EQUIP_POSSESION_SUCCESS, retVal)
end

function PetUIModule:OnCmdHavingUpgrade(_pet_gid, _slot_idx, _is_equipped, _upgrade_item_gid)
  local req = _G.ProtoMessage:newZoneUpgradeCarryonReq()
  if true == _is_equipped then
    req.pet_gid = _pet_gid
    req.slot_idx = _slot_idx
    req.is_equipped = _is_equipped
  else
    req.upgrade_item_gid = _upgrade_item_gid
  end
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_UPGRADE_CARRYON_REQ, req, self, self.OnHavingUpgradeRsp)
end

function PetUIModule:OnHavingUpgradeRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.petuimodule_4 .. tostring(rsp.ret_info.ret_code))
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.HavingUpgradeAndResonanceEvent, retVal, rsp.res_carryon)
end

function PetUIModule:OnCmdHavingResonance(_pet_gid, _result_carryon_idx, _is_equipped, _result_item_gid, _cost_item_gid, _result_item_id, _cost_item_id)
  local req = _G.ProtoMessage:newZoneResonanceCarryonReq()
  if true == _is_equipped then
    req.pet_gid = _pet_gid
    req.result_carryon_idx = _result_carryon_idx
    req.is_equipped = _is_equipped
    req.cost_item_gid = _cost_item_gid
    req.cost_item_conf_id = _cost_item_id
  else
    req.result_item_gid = _result_item_gid
    req.cost_item_gid = _cost_item_gid
    req.result_item_conf_id = _result_item_id
    req.cost_item_conf_id = _cost_item_id
    req.is_equipped = _is_equipped
  end
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_RESONANCE_CARRYON_REQ, req, self, self.HavingResonanceSucceed)
end

function PetUIModule:HavingResonanceSucceed(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.petuimodule_4 .. tostring(rsp.ret_info.ret_code))
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.HavingUpgradeAndResonanceEvent, retVal, rsp.res_carryon)
end

function PetUIModule:OnCmdRemovePossession(petGid, pos)
  local req = _G.ProtoMessage:newZonePetRemovePossessionReq()
  req.remove_slot_idx = pos
  req.remove_pet_gid = petGid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_REMOVE_POSSESSION_REQ, req, self, self.OnRemovePossessionRsp)
end

function PetUIModule:OnRemovePossessionRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.petuimodule_4 .. tostring(rsp.ret_info.ret_code))
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.EQUIP_POSSESION_SUCCESS, retVal)
end

function PetUIModule:OnCmdAutoSupplyCarryon(petGid, is_auto)
  local req = _G.ProtoMessage:newZoneAutoSupplyCarryonReq()
  req.is_auto_supply = is_auto
  req.pet_gid = petGid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_AUTO_SUPPLY_CARRYON_REQ, req, self, self.OnAutoSupplyCarryonRsp)
end

function PetUIModule:OnAutoSupplyCarryonRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    return
  end
  local retVal
  if rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    retVal = rsp.ret_info.goods_change_info.changes
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.AUTO_SUPPLY_CARRYON, retVal)
end

function PetUIModule:RegPanel(name, path, layer, IsCapture, bCustomDisableRendering, openAnim, closeAnim, enablePcEsc, fullSpeedDesired, enableExtraGCWhenClose, dependentPanelName)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/PetUI/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = bCustomDisableRendering or false
  registerData.openAnimName = openAnim
  registerData.closeAnimName = closeAnim
  registerData.enablePcEsc = enablePcEsc
  registerData.fullSpeedDesired = fullSpeedDesired or false
  registerData.dependentPanelName = dependentPanelName
  if enableExtraGCWhenClose then
    registerData.closeGCWeight = 20
  end
  self:RegisterPanel(registerData)
end

function PetUIModule:RegCommonPanel(name, path, layer, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
end

function PetUIModule:RegBagPanel(name, path, layer)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer
  registerData.enablePcEsc = false
  self:RegisterPanel(registerData)
end

function PetUIModule:OnLogin(isRelogin)
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.GameLoginEvent, isRelogin)
end

function PetUIModule:OnCmdUpdateHavingPanelInfo(_data, _IsUpdata, _Index)
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.UpdateHavingPanelInfoEvent, _data, _IsUpdata, _Index)
end

function PetUIModule:OnCmdGetEquipProssession()
  return self.hideEquipProssession
end

function PetUIModule:OnCmdSetEquipProssession(flag)
  self.hideEquipProssession = flag
end

function PetUIModule:OnCmdGetEvoBaseBaseId(baseID)
  return self.data:GetEvoBaseId(baseID)
end

function PetUIModule:ShowProtocolErrorTips(rsp)
  local errorKey = "Error_Code_" .. rsp.ret_info.ret_code
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[errorKey] or errorKey)
end

function PetUIModule:PetSkillInit()
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  self.data:Init(uin)
  local pets = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  self.data:CachePetBaseConf()
  self.data:ClearPetBaseConf()
end

function PetUIModule:OnPlayerDataUpdate(UpdateGoodType, PetDataChangeItemList)
  self.data:CachePetBaseConf()
  self.data:ClearPetBaseConf()
  self.data:ClearBalancedPetDataForPvp()
  self:DispatchEvent(PetUIModuleEvent.PlayerDataUpdate, UpdateGoodType, PetDataChangeItemList)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.PlayerDataUpdate, UpdateGoodType, PetDataChangeItemList)
end

function PetUIModule:GetSkillNew(gid, skillid)
  return self.data:GetSkillIsNew(gid, skillid)
end

function PetUIModule:GetSkillsHasNew(gid)
  return self.data:GetSkillsHasNew(gid)
end

function PetUIModule:RemoveSkillNew(gid, skillid)
  if self.data:RemoveSkillIsNew(gid, skillid) then
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.RemoveSkillNewState, gid, skillid)
  end
end

function PetUIModule:OpenPetReportPanel()
  local data = {}
  data.reportData = self.data.PetReportData
  data.submitPetReward = self.data.SubmitPetReward
  data.PetSubmitAction = self.PetSubmitAction
  self:OpenPanel("PetReport", data)
end

function PetUIModule:OnCmdOpenPetHatchingReview(activityInst)
  self:OpenPanel("PetHatchingReview", activityInst)
end

function PetUIModule:OpenTestPetReportPanel()
  local data = {
    action = nil,
    data = {
      pet_submit_params = {
        {bonus_id = 3, bonus_param = 5},
        {bonus_id = 4, bonus_param = 4}
      },
      ret_info = {
        goods_change_info = {
          changes = {
            {
              type = 4,
              pet_data = {
                base_conf_id = 3187,
                level = 1,
                is_first_catch = true,
                add_time = 0,
                mutation_type = 0
              }
            },
            {
              type = 4,
              pet_data = {
                base_conf_id = 3187,
                level = 1,
                is_first_catch = true,
                add_time = 0,
                mutation_type = 0
              }
            },
            {
              type = 4,
              pet_data = {
                base_conf_id = 3187,
                level = 1,
                is_first_catch = true,
                add_time = 0,
                mutation_type = 0
              }
            },
            {
              type = 4,
              pet_data = {
                base_conf_id = 3187,
                level = 1,
                is_first_catch = true,
                add_time = 0,
                mutation_type = 0
              }
            }
          }
        }
      }
    },
    oldCoinNum = 0
  }
  self:OpenPanel("PetReport", data)
end

function PetUIModule:ClosePetReportPanel()
  self:ClosePanel("PetReport")
end

function PetUIModule:OnCmdGetCurSelectImpressionIndex()
  return self.data:GetSelectImpressionIndex()
end

function PetUIModule:OnCmdSetCurSelectImpressionIndex(index, data)
  self.data:SetSelectImpressionIndex(index)
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ImpressionChangeSelect, index, data)
end

function PetUIModule:OnCmdZoneUnlockPetHabitReq(group_id, group_num)
  if self.isReqUnlockHabit then
    return
  end
  if self:HasPanel("UMG_ImpressionSettlement") then
    return
  end
  local req = _G.ProtoMessage:newZoneUnlockPetHabitReq()
  req.group_id = group_id
  req.group_num = group_num
  self.isReqUnlockHabit = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UNLOCK_PET_HABIT_REQ, req, self, self.OnZoneUnlockPetHabitRsp)
end

function PetUIModule:OnZoneUnlockPetHabitRsp(rsp)
  self.isReqUnlockHabit = false
  if 0 == rsp.ret_info.ret_code then
    local petData
    local changes = rsp.ret_info.goods_change_info.changes
    for i, change in pairs(changes) do
      if change.pet_data then
        petData = change.pet_data
        break
      end
    end
    if nil ~= petData then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenImpressionUnLockPanel, petData.habit_group_id, petData.habit_level)
    end
    self:DispatchEvent(PetUIModuleEvent.UpdateImpressionGroup, changes)
  end
end

function PetUIModule:OnCmdOpenImpressionUnLockPanel(group_id, level)
  if self:HasPanel("UMG_ImpressionSettlement") then
  else
    self:OpenPanel("UMG_ImpressionSettlement", group_id, level)
  end
end

function PetUIModule:OnCmdGetPetUiMenuIndex()
  return self.data:GetPetUiMenuIndex()
end

function PetUIModule:OnCmdSetPetUiMenuIndex(index)
  self.data:SetPetUiMenuIndex(index)
end

function PetUIModule:OnCmdZoneGetHatchStatusReq()
  if self.lastClickCrackTime and os.time() - self.lastClickCrackTime < 5 then
    return
  end
  local req = _G.ProtoMessage:newZoneGetAllHatchStatusReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_ALL_HATCH_STATUS_REQ, req, self, self.OnZoneGetAllHatchStatusRsp)
end

function PetUIModule:OnZoneGetAllHatchStatusRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnUpdateHatchSecs, rsp)
  end
end

function PetUIModule:OnCmdZoneStopHatchReq(gid)
  local req = _G.ProtoMessage:newZoneStopHatchReq()
  req.egg_gid = gid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_STOP_HATCH_REQ, req, self, self.OnZoneStopHatchRsp, false, true)
end

function PetUIModule:OnZoneStopHatchRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.petuimodule_5)
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OnStopHatchEgg)
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function PetUIModule:OnCmdZoneCrackEggReq(gid, ballGid, ballItemId, selectGlassColorConfId, selectGlassParticleConfId)
  if self.isCrackEggIng == true then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").HATCHEGG
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
    _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetPetItemClickAble, "PetHatchingPanel", true)
    return
  end
  if nil == gid then
    Log.Error("PetUIModule:OnCmdZoneCrackEggReq gid is nil")
    return
  end
  local EggBagItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, gid)
  if nil == EggBagItem then
    Log.Debug("PetUIModule:OnCmdZoneCrackEggReq EggBagItem is nil")
    return
  end
  local req = _G.ProtoMessage:newZoneCrackEggReq()
  req.egg_gid = gid
  req.select_ball_gid = ballGid
  req.select_glass_color = selectGlassColorConfId
  req.select_glass_particle = selectGlassParticleConfId
  self.crackEggGid = gid
  self.eggBallItemId = ballItemId
  self.lastClickCrackTime = _G.UpdateManager.Timestamp
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetPetItemClickAble, "PetHatchingPanel", false)
  self.isCrackEggIng = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CRACK_EGG_REQ, req, self, self.OnZoneCrackEggRsp)
end

function PetUIModule:OnZoneCrackEggRsp(rsp)
  Log.DebugFormat("PetUIModule:OnZoneCrackEggRsp")
  Log.Dump(rsp, 6, "OnZoneCrackEggRsp:")
  self.isCrackEggIng = false
  if 0 == rsp.ret_info.ret_code then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").HATCHEGG
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
    _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetPetItemClickAble, "PetHatchingPanel", true)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseHatchingRightPanel)
    self:OnCmdClosePetHatchingPanel()
    self:DispatchEvent(PetUIModuleEvent.OnCrackEgg, rsp.hatched_pet_gid, self.crackEggGid, self.eggBallItemId)
    self.CacheHatchePetGid = rsp.hatched_pet_gid
    self.crackEggGid = nil
    self.eggBallItemId = nil
  else
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").HATCHEGG
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
    _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetPetItemClickAble, "PetHatchingPanel", true)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseHatchingRightPanel)
    self:SetPetHatchingPanelIsClicking(false)
    self.lastClickCrackTime = nil
  end
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.CloseChoosePetBallPanel)
end

function PetUIModule:GetIsCrackEggIng()
  return self.isCrackEggIng
end

function PetUIModule:OnCmdClickPetImage3d()
  self:DispatchEvent(PetUIModuleEvent.OnClickPetImage3d)
end

function PetUIModule:SetEggPlayAnimaTime(gid)
  if self.EggTimeDic == nil then
    self.EggTimeDic = {}
  end
  self.EggTimeDic[gid] = os.time()
end

function PetUIModule:CheckIsEggPlayAnima(gid)
  if self.EggTimeDic == nil or self.EggTimeDic[gid] == nil then
    self:SetEggPlayAnimaTime(gid)
    return true
  end
  local time = os.time() - self.EggTimeDic[gid]
  local cd = _G.DataConfigManager:GetPetGlobalConfig("hatch_jump_cd").num
  return time >= cd
end

function PetUIModule:OnCmdOpenEggIncubatePanel(eggPetBaseID, eggPetGid, eggBallItemId)
  self:OpenPanel("EggIncubatePanel", {
    eggPetBaseID = eggPetBaseID,
    eggPetGid = eggPetGid,
    eggBallItemId = eggBallItemId
  })
  self:DispatchEvent(PetUIModuleEvent.OnEggPerformChange, true)
end

function PetUIModule:OnCmdUpdateEggIncubatePanel()
  self:DispatchEvent(PetUIModuleEvent.EggIncubatePanelUpdate)
end

function PetUIModule:OnCmdCloseEggIncubatePanel()
  self.isCrackEggIng = false
  self.isDisableInEggAnimation = true
  self:DispatchEvent(PetUIModuleEvent.OnEggPerformChange, false, self.CacheHatchePetGid)
  self:OnCmdOpenPetHatchingPanel()
end

function PetUIModule:OnCmdOpenPetHatchOnlyPanel(hatchEggData)
  self:OpenPanel("PetHatchOnly", hatchEggData)
end

function PetUIModule:OnCmdClosePetHatchOnlyPanel()
  self:ClosePanel("PetHatchOnly")
end

function PetUIModule:OnCmdCanNotContinueGrow()
  self:DispatchEvent(PetUIModuleEvent.PET_UI_SECONDPANEL_CLOSE)
end

function PetUIModule:OnCmdSelectPetFood(Index)
  self:DispatchEvent(PetUIModuleEvent.SELECT_LEVELUP_ITEM, Index)
end

function PetUIModule:OnCmdOpenQualificationInterpretation(_Param, OpenType)
  self:OpenPanel("QualificationInterpretation", _Param, OpenType)
end

function PetUIModule:OnCmdSelectUpGradeItem(SelectItem, index)
  self:DispatchEvent(PetUIModuleEvent.ClearUpGradeUseItemNum, SelectItem, index)
end

function PetUIModule:OnCmdAttrTipsOpen(bOpen, index, _type)
  self:DispatchEvent(PetUIModuleEvent.AttrTipsOpenEvent, bOpen, index, _type)
end

function PetUIModule:OnCmdGetTipsOpenIndex()
  if not self:HasPanel("PetDetailedInfo") then
    return
  end
  local panel = self:GetPanel("PetDetailedInfo")
  if panel then
    return panel:GetTipsOpenIndex()
  end
  return 0
end

function PetUIModule:OnCmdOpenChoosePetBallPanel(data, egg_id)
  self:OpenPanel("ChoosePetBallPanel", data, egg_id)
end

function PetUIModule:OnCmdCloseChoosePetBallPanel()
  self:ClosePanel("ChoosePetBallPanel")
end

function PetUIModule:OnCmdOpenHatchingRightPanel(rightPanelDisplayMode, data, egg_id)
  self:OpenPanel("HatchingRightPanel", rightPanelDisplayMode, data, egg_id)
end

function PetUIModule:OnCmdCloseHatchingRightPanel(CloseReasonType)
  if self:HasPanel("HatchingRightPanel") then
    local panel = self:GetPanel("HatchingRightPanel")
    if panel then
      panel:ClosePanel(CloseReasonType)
    end
  end
end

function PetUIModule:OnCmdUpdateHatchingRightPanel()
  if self:HasPanel("HatchingRightPanel") then
    local panel = self:GetPanel("HatchingRightPanel")
    if panel then
      panel:UpdateView()
    end
  end
end

function PetUIModule:OnCmdOpenColorfulMatchingTips(ItemID, ParticleIconConf, SelectColorConf)
  self:OpenPanel("ColorfulMatchingTips", ItemID, ParticleIconConf, SelectColorConf)
end

function PetUIModule:OnCmdGetHatchingRightPanelDisplayMode()
  if self:HasPanel("HatchingRightPanel") then
    local panel = self:GetPanel("HatchingRightPanel")
    if panel then
      return panel:GetDisplayMode()
    end
  end
  return PetUIModuleEnum.PetHatchingRightPanelDisplayMode.None
end

function PetUIModule:OnCmdUpdateHatchingRightPanelCommonAddSubtractPanel(UpdateReasonType)
  if self:HasPanel("HatchingRightPanel") then
    local panel = self:GetPanel("HatchingRightPanel")
    if panel then
      panel:UpdateCommonAddSubtractPanel(UpdateReasonType)
    end
  end
end

function PetUIModule:OnCmdOpenPetHatchingPanel(arg, isUpdateData)
  local IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_HATCH_EGG, false)
  if IsBan then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
    return
  end
  if _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, true) then
    return
  end
  if isUpdateData then
    if self:HasPanel("PetHatchingPanel") then
      local panel = self:GetPanel("PetHatchingPanel")
      panel:OnUpdateData(arg)
    end
    return
  end
  local eggGid = arg
  self.isHatchingPanel = true
  self.curEggGid = eggGid
  if not self:HasPanel("PetInfoMain") then
    self:OnCmdOpenPetMainPanel()
    if not self:HasPanel("PetHatchingPanel") then
      self:OpenPanel("PetHatchingPanel", arg)
      self:DispatchEvent(PetUIModuleEvent.OnOpenEggPanel, self.isDisableInEggAnimation)
      self:DispatchEvent(PetUIModuleEvent.ShowHideRecommendedBtn, false)
    else
      local panel = self:GetPanel("PetHatchingPanel")
      panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      panel:OnUpdateData(arg)
    end
  else
    self:DispatchEvent(PetUIModuleEvent.ShowHideRecommendedBtn, false)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetMainShareBtnVisibility, false)
    if not self:HasPanel("PetHatchingPanel") then
      self:OpenPanel("PetHatchingPanel", arg)
      self:DispatchEvent(PetUIModuleEvent.OnOpenEggPanel, self.isDisableInEggAnimation)
    else
      local panel = self:GetPanel("PetHatchingPanel")
      panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      panel:OnUpdateData(arg)
    end
  end
  self.isDisableInEggAnimation = false
end

function PetUIModule:OnCmdCheckIsPetHatchingPanelShow()
  return self:HasPanel("PetHatchingPanel")
end

function PetUIModule:OnCmdGetVaildPetBallItemList(EggGID)
  if nil == EggGID then
    return {}
  end
  local preciousEggType
  local PetEggConfigType, PetEggConfig = PetUtils.GetPetEggConfigTypeByGID(EggGID)
  if PetEggConfigType == PetUIModuleEnum.PetEggConfigType.None then
    return {}
  end
  if PetEggConfigType == PetUIModuleEnum.PetEggConfigType.NormalEgg then
    preciousEggType = PetEggConfig.precious_egg_type
    local BagEggItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, EggGID)
    if BagEggItem and BagEggItem.egg_data and BagEggItem.egg_data.precious_egg_type then
      preciousEggType = BagEggItem.egg_data.precious_egg_type
    end
  elseif PetEggConfigType == PetUIModuleEnum.PetEggConfigType.BlessingEgg then
    local BagEggItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, EggGID)
    if BagEggItem then
      preciousEggType = BagEggItem.egg_data.precious_egg_type
    end
  elseif PetEggConfigType == PetUIModuleEnum.PetEggConfigType.RandomEgg then
    preciousEggType = PetEggConfig.precious_egg_type
  end
  if nil == preciousEggType then
    return {}
  end
  local ballRangeList = {}
  if nil == self.AllEggTypeConfigs then
    local eggTypeCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.EGG_TYPE_CONF)
    if eggTypeCfg then
      self.AllEggTypeConfigs = eggTypeCfg:GetAllDatas()
    end
  end
  for _, eggTypeConf in pairs(self.AllEggTypeConfigs) do
    if eggTypeConf.precious_egg_type == preciousEggType then
      ballRangeList = eggTypeConf.ball_range
      break
    end
  end
  local havePetBallItemMap = {}
  local petBallItemList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemArrayByLableType, _G.Enum.ItemLableType.ILT_USEFUL_ITEM)
  for _, ballItem in pairs(petBallItemList) do
    if ballItem.type == _G.Enum.BagItemType.BI_PET_BALL then
      havePetBallItemMap[ballItem.id] = ballItem
    end
  end
  local invalidPetBallIdMap = {}
  local invalidIdList = _G.DataConfigManager:GetPetGlobalConfig("invalid_ball").numList
  for _, invalidId in pairs(invalidIdList) do
    invalidPetBallIdMap[invalidId] = true
  end
  local validPetBallItemList = {}
  if nil == self.AllPetBallConfigs then
    local cfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BALL_CONF)
    if cfg then
      self.AllPetBallConfigs = cfg:GetAllDatas()
    end
  end
  for _, petBallConfig in pairs(self.AllPetBallConfigs) do
    local ballType = petBallConfig.ball_effect_type
    for _, targetBallType in pairs(ballRangeList) do
      if ballType == targetBallType and not invalidPetBallIdMap[petBallConfig.id] then
        local ballItem = {}
        if havePetBallItemMap[petBallConfig.id] then
          ballItem = havePetBallItemMap[petBallConfig.id]
          ballItem.itemNum = ballItem.num
        else
          ballItem.conf = _G.DataConfigManager:GetBagItemConf(petBallConfig.id)
          ballItem.itemNum = 0
        end
        ballItem.id = petBallConfig.id
        ballItem.itemType = _G.Enum.GoodsType.GT_BAGITEM
        ballItem.bShowNum = true
        ballItem.itemId = ballItem.id
        ballItem.IsPetBall = true
        ballItem.bEnableLongClick = true
        if ballItem.itemNum <= 0 then
          ballItem.bGray = true
          ballItem.IsCanClick = false
        end
        table.insert(validPetBallItemList, ballItem)
        break
      end
    end
  end
  table.sort(validPetBallItemList, function(a, b)
    local ballBagConf_a = _G.DataConfigManager:GetBagItemConf(a.id)
    local ballBagConf_b = _G.DataConfigManager:GetBagItemConf(b.id)
    if 0 == a.itemNum and 0 ~= b.itemNum then
      return false
    end
    if 0 ~= a.itemNum and 0 == b.itemNum then
      return true
    end
    if ballBagConf_a and ballBagConf_b then
      return ballBagConf_a.sort_id < ballBagConf_b.sort_id
    else
      return nil ~= ballBagConf_a and nil ~= ballBagConf_b
    end
  end)
  return validPetBallItemList
end

function PetUIModule:OnCmdClosePetHatchingPanel()
  self:ClosePanel("PetHatchingPanel")
  self.isHatchingPanel = false
end

function PetUIModule:OnClosePetHatchingPanel()
  if _G.NRCModuleManager:GetModule("BagModule"):HasPanel("BagMain") and self:HasPanel("PetInfoMain") then
    local PanelInst = self:GetPanel("PetInfoMain")
    if PanelInst then
      PanelInst:OnCloseButtonClicked()
    end
  end
  self.isHatchingPanel = false
end

function PetUIModule:OnCmdSetPetVisualParam(_PetVisualParam)
  self.data:SetPetVisualParam(_PetVisualParam)
  if _G.AppMain:HasDebug() then
    _G.NRCModeManager:DoCmd(_G.DebugModuleCmd.UpdateVisualToolParam, _PetVisualParam, false)
  end
end

function PetUIModule:OnCmdGetPetVisualParam()
  return self.data:GetPetVisualParam()
end

function PetUIModule:OnSetPetModelScaleAndOffset(_Scale, _Offset)
  if self:HasPanel("PetInfoMain") then
    local PanelInst = self:GetPanel("PetInfoMain")
    if PanelInst and PanelInst.petMiddlePanel and PanelInst.petMiddlePanel.petImage3D then
      PanelInst.petMiddlePanel.petImage3D:UpdateModelScaleAndOffset(_Scale, _Offset)
    end
  end
end

function PetUIModule:OnAddPetModelBlackAnim(_blackAnim)
  if self:HasPanel("PetInfoMain") then
    local PanelInst = self:GetPanel("PetInfoMain")
    if PanelInst and PanelInst.petMiddlePanel and PanelInst.petMiddlePanel.petImage3D then
      PanelInst.petMiddlePanel.petImage3D:UpdateModelBlackAnim(_blackAnim)
    end
  end
end

function PetUIModule:OnCmdSetIsPlayPetSkill(_IsPlayPetSkill, bOnClick)
  self.data:SetIsPlayPetSkill(_IsPlayPetSkill)
  if bOnClick then
    self:DispatchEvent(PetUIModuleEvent.SetAttributeState, _IsPlayPetSkill)
    self:DispatchEvent(PetUIModuleEvent.OnPetSkillChange, _IsPlayPetSkill)
  end
end

function PetUIModule:OnCmdGetIsPlayPetSkill()
  return self.data:GetIsPlayPetSkill()
end

function PetUIModule:OnCmdIsHavePetSkillTips(mode)
  if mode then
    self.data.PetSkillListState = mode
  end
  if self:HasPanel("PetSkillTips") or self:HasPanel("BagSkillTips") then
    self:DispatchEvent(PetUIModuleEvent.OpenOrCloseSkillTipsPanel, true)
  end
end

function PetUIModule:CmdOpenFilterPanel(OpenType, FilterHiddenParam)
  self:OpenPanel("PetFilterTips", OpenType, FilterHiddenParam)
end

function PetUIModule:CmdFoodClickAddOrDelItem(IsAdd, BagItem, AddAutomaticallyType, Count)
  if self:HasPanel("PetLevelUp") then
    local panel = self:GetPanel("PetLevelUp")
    if IsAdd then
      panel:OnClickAddItem(BagItem, AddAutomaticallyType, Count)
    else
      panel:OnClickDelItem(BagItem, AddAutomaticallyType, Count)
    end
  end
end

function PetUIModule:CmdOpenSortPanel(SortType, OpenType)
  self:OpenPanel("CandidateTips", SortType, OpenType)
end

function PetUIModule:CmdOpenExChangeMainPetPanel(ChangePetGid)
  self:OpenPanel("ExChangeMainPetTips", ChangePetGid)
end

function PetUIModule:OnCmdGetRandomPetBonusPanelState()
  local data = self.data
  local state = data and data.RandomPetBonusPanelState
  local stateCopy = {}
  table.copy(state, stateCopy)
  return stateCopy
end

function PetUIModule:OnCmdSetRandomPetBonusPanelState(nextState)
  local data = self.data
  local prevState = data and data.RandomPetBonusPanelState
  nextState.onCloseCallback = self.OnRandomPetBonusClose
  nextState.callbackOwner = self.OnRandomPetBonusClose
  data.RandomPetBonusPanelState = nextState
  local open = nextState and nextState.open
  if open then
    local props = {
      callbackOwner = self,
      onActiveCallback = self.OnRandomPetBonusPanelActive,
      onCloseCallback = self.OnRandomPetBonusClose,
      starCount = nextState.starCount,
      winNum = nextState.winNum,
      hitPetNum = nextState.hitPetNum
    }
    if self:HasPanel("RandomPetBonus") then
      local randomBonusPanel = self:GetPanel("RandomPetBonus")
      randomBonusPanel:ReceiveProps(props)
    elseif not self:IsPanelInOpening("RandomPetBonus") then
      self:OpenPanel("RandomPetBonus", props)
    end
  else
    self:ClosePanel("RandomPetBonus")
  end
end

function PetUIModule:OnRandomPetBonusPanelActive(panel)
  local data = self.data
  local state = data and data.RandomPetBonusPanelState
  panel:ReceiveProps({
    callbackOwner = self,
    onActiveCallback = self.OnRandomPetBonusPanelActive,
    onCloseCallback = self.OnRandomPetBonusClose,
    starCount = state.starCount,
    winNum = state.winNum,
    hitPetNum = state.hitPetNum
  })
end

function PetUIModule:OnRandomPetBonusClose()
  local state = self:OnCmdGetRandomPetBonusPanelState()
  state.open = false
  self:OnCmdSetRandomPetBonusPanelState(state)
end

function PetUIModule:OpenRightPanel(...)
  self:SetPetMainBtnIsEnabled(false)
  if self:HasPanel("PetRightPanel") then
    self:ClosePanel("PetRightPanel")
  end
  self:OpenPanel("PetRightPanel", ...)
end

function PetUIModule:SetPetMainBtnIsEnabled(IsEnabled)
  if self:HasPanel("PetInfoMain") then
    local PetInfoMain = self:GetPanel("PetInfoMain")
    PetInfoMain:SetBtnIsEnabled(IsEnabled)
  end
end

function PetUIModule:CloseRightPanel(...)
  self:ClosePanel("PetRightPanel")
end

function PetUIModule:HideRightPanel(...)
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    panel:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  if self:HasPanel("PetBagPanel") then
    local panel = self:GetPanel("PetBagPanel")
    panel:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function PetUIModule:ShowRightPanel(...)
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self:HasPanel("PetBagPanel") then
    local panel = self:GetPanel("PetBagPanel")
    panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function PetUIModule:HideTipsPanel(...)
  if self:HasPanel("Pet_BloodPulse") then
    self:DisablePanel("Pet_BloodPulse")
  end
  _G.NRCModeManager:DoCmd(TipsModuleCmd.HideTipsPanel)
end

function PetUIModule:ShowTipsPanel(...)
  if self:HasPanel("Pet_BloodPulse") then
    self:EnablePanel("Pet_BloodPulse")
  end
  _G.NRCModeManager:DoCmd(TipsModuleCmd.ShowTipsPanel)
end

function PetUIModule:FoldOrOpenRightPanel()
  local bOpen = false
  if self:HasPanel("PetInfoMain") then
    local petInfoMain = self:GetPanel("PetInfoMain")
    local petleftPanel = petInfoMain.petLeftPanel
    if petleftPanel then
      local attribute = petleftPanel.Attribute
      if attribute and self.PanelStateMap.Attribute then
        if not attribute.showing then
          bOpen = true
        end
        attribute:SwitchVersion(true)
      end
    end
  end
  return bOpen
end

function PetUIModule:SetCurrPetData(petData)
  if petData then
    self.data.PetGid = petData.gid
  else
    self.data.PetGid = nil
  end
end

function PetUIModule:SetRightPanelMarkBtnVisible(Visible)
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    if panel then
      if Visible then
        panel.MarkBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        panel.MarkBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function PetUIModule:GetPetBagPanelIsChangeState()
  if self:HasPanel("PetBagPanel") then
    local panel = self:GetPanel("PetBagPanel")
    return panel and panel.petAddToTeam
  end
end

function PetUIModule:GetCurrPetData()
  if self.data.PetGid then
    return _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.PetGid)
  else
    return nil
  end
end

function PetUIModule:OpenPetBagPanel(...)
  self:OpenPanel("PetBagPanel", ...)
end

function PetUIModule:ClosePetBagPanel(...)
  self:ClosePanel("PetBagPanel")
end

function PetUIModule:ClosePetSkillTipsPanel(...)
  if self:HasPanel("PetSkillTips") then
    local panel = self:GetPanel("PetSkillTips")
    panel:OnClose()
  end
end

function PetUIModule:SetPetBagOpenState(openState)
  self.data.PetBagOpenState = openState
end

function PetUIModule:GetPetBagOpenState()
  return false
end

function PetUIModule:SetCurSelectItemTypeInPortableBag(SelectItemType)
  self.data.CurSelectItemTypeInPortableBag = SelectItemType
end

function PetUIModule:GetCurSelectItemTypeInPortableBag()
  return self.data.CurSelectItemTypeInPortableBag
end

function PetUIModule:SetCurSelectPetGIDInPortableBag(PetGID)
  self.data.CurSelectPetGIDInPortableBag = PetGID
end

function PetUIModule:GetCurSelectPetGIDInPortableBag()
  return self.data.CurSelectPetGIDInPortableBag
end

function PetUIModule:SetCurShowTeamIndexInPortableBag(TeamIndex)
  self.data.CurShowTeamIndexInPortableBag = TeamIndex
end

function PetUIModule:GetCurShowTeamIndexInPortableBag()
  return self.data.CurShowTeamIndexInPortableBag
end

function PetUIModule:SetCurShowPageIndexInPortableBag(PageIndex)
  self.data.CurShowPageIndexInPortableBag = PageIndex
end

function PetUIModule:GetCurShowPageIndexInPortableBag()
  return self.data.CurShowPageIndexInPortableBag
end

function PetUIModule:SetCurSelectInfoInPortableBag(SelectListIndex, SelectItemIndex)
  self.data.CurSelectListIndexInPortableBag = SelectListIndex
  self.data.CurSelectItemIndexInPortableBag = SelectItemIndex
end

function PetUIModule:GetCurSelectInfoInPortableBag()
  return self.data.CurSelectListIndexInPortableBag, self.data.CurSelectItemIndexInPortableBag
end

function PetUIModule:OnCmdGetPetPortableBagReleaseLifeMode()
  if self:HasPanel("NewPetBag") then
    local NewPetBagPanel = self:GetPanel("NewPetBag")
    if NewPetBagPanel then
      return NewPetBagPanel:IsReleaseLifeMode()
    end
  end
  return false
end

function PetUIModule:SwitchReleaseLifeModeInPortableBag()
  if self:HasPanel("NewPetBag") then
    local NewPetBagPanel = self:GetPanel("NewPetBag")
    if NewPetBagPanel then
      NewPetBagPanel:OnSwitchReleaseLifeMode()
    end
  end
end

function PetUIModule:OnCmdCheckPetIsInFreeListInPortableBag(petData)
  if self:HasPanel("NewPetBag") then
    local NewPetBagPanel = self:GetPanel("NewPetBag")
    if NewPetBagPanel then
      return NewPetBagPanel:CheckIsInFreeList(petData)
    end
  end
  return false
end

function PetUIModule:OnCmdGetBoxFreePetNumInPortableBag(box_id)
  if self:HasPanel("NewPetBag") then
    local NewPetBagPanel = self:GetPanel("NewPetBag")
    if NewPetBagPanel then
      return NewPetBagPanel:GetBoxFreePetNum(box_id)
    end
  end
  return 0
end

function PetUIModule:OnCmdCheckPetIsCanFree(petData, onlyCheck, bIgnorePvpOrPveTeam, ApplyFreePvpOrPvePetCaller, ApplyFreePvpOrPvePetCallback, FreeReasonType)
  local Ret = false
  local PetIsCanFree = PetUtils.CheckPetIsCanFree(petData, onlyCheck, bIgnorePvpOrPveTeam, ApplyFreePvpOrPvePetCaller, ApplyFreePvpOrPvePetCallback, FreeReasonType)
  local IsTheLastPet = self:CheckIsTheLastBigWorldTeamPet(petData.gid, onlyCheck)
  if PetIsCanFree and not IsTheLastPet then
    Ret = true
  end
  return Ret
end

function PetUIModule:CheckIsTheLastBigWorldTeamPet(PetGID, OnlyCheck)
  local IsTheLastBigWorldTeamPet = false
  local IsBigWorldTeamPet = false
  local IsOnlyOnePet = false
  local PetNumInBigWorldTeam = 0
  local playerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(playerPetInfo, Enum.PlayerTeamType.PTT_BIG_WORLD)
  if teamInfo and teamInfo.teams then
    for _, team in pairs(teamInfo.teams) do
      local petInfo = PetUtils.PetTeamFindPetInfoByIndex(team, PetGID)
      if petInfo then
        IsBigWorldTeamPet = true
        break
      end
    end
    if IsBigWorldTeamPet then
      for _, team in pairs(teamInfo.teams) do
        if team.pet_infos then
          for _, item in pairs(team.pet_infos or {}) do
            if nil ~= item then
              local PetData = {}
              PetData.gid = item.pet_gid
              if not self:OnCmdCheckPetIsInFreeListInPortableBag(PetData) then
                PetNumInBigWorldTeam = PetNumInBigWorldTeam + 1
              end
            end
          end
        end
      end
    end
    if 1 == PetNumInBigWorldTeam then
      IsOnlyOnePet = true
    end
    if IsBigWorldTeamPet and IsOnlyOnePet then
      IsTheLastBigWorldTeamPet = true
      if not OnlyCheck then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.team_has_one_pet_at_least)
      end
    end
  end
  return IsTheLastBigWorldTeamPet
end

function PetUIModule:OpenGrowUpPanel(...)
  self:OpenPanel("PetGrowUp", ...)
end

function PetUIModule:CloseGrowUpPanel(...)
  self:ClosePanel("PetGrowUp")
end

function PetUIModule:OpenLevelUpPanel(petInfoMainCtrl, uiData)
  self:SetPetMainBtnIsEnabled(false)
  local ResListData = self:OnLoadLevelUpPanelRes()
  self:OpenPanel("PetLevelUp", petInfoMainCtrl, uiData, ResListData)
end

function PetUIModule:OnLoadLevelUpPanelRes()
  local ResListData = _G.NRCPanelResLoadData()
  ResListData.PreLoadResList = {}
  local itemList = NRCModeManager:DoCmd(BagModuleCmd.GetCanFeedItem)
  for i, Item in ipairs(itemList) do
    table.insert(ResListData.PreLoadResList, Item.itemConf.icon)
  end
  return ResListData
end

function PetUIModule:LeftPanelRefresh()
  self:DispatchEvent(PetUIModuleEvent.LeftPanelRefresh)
end

function PetUIModule:AttributePanelRefresh()
  if self:HasPanel("PetBagPanel") then
    local panel = self:GetPanel("PetBagPanel")
    panel:RefreshAttributeInfo()
  end
  self:DispatchEvent(PetUIModuleEvent.AttributePanelRefresh)
end

function PetUIModule:ShowPetLevelUp(_IsClose)
  if self:HasPanel("PetLevelUp") then
    local panel = self:GetPanel("PetLevelUp")
    if _IsClose then
      self:ClosePanel("PetLevelUp")
    else
      panel:SetVisibility(UE4.ESlateVisibility.Visible)
      panel:PlayAnimation(panel.New_in)
    end
  end
end

function PetUIModule:IsPetHatchingPanel()
  if self.isHatchingPanel == nil then
    self.isHatchingPanel = false
  end
  return self.isHatchingPanel
end

function PetUIModule:OpenPetTips(_PetData)
  local petData = self:GetCurrPetData()
  if _PetData then
    petData = _PetData
  end
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, {petData = petData}, _G.Enum.GoodsType.GT_PET)
end

function PetUIModule:OpenDBlockerTips(openType, _PetData)
  local PetData = self:GetCurrPetData()
  if _PetData then
    PetData = _PetData
  end
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.OpendblockerTips, {petData = PetData}, openType)
end

function PetUIModule:CloseDBlockerTips()
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.CloseblockerTips)
end

function PetUIModule:OnCmdOpenPetRateTip(_PetData, opentype, ...)
  local PetData = self:GetCurrPetData()
  if _PetData then
    PetData = _PetData
  end
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.OpendPetRateTips, {petData = PetData}, opentype, ...)
end

function PetUIModule:OpenPetBloodPulse(PetData, OpenType)
  local curPetData = self:GetCurrPetData()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetBloodPulse, PetData or curPetData, OpenType)
end

function PetUIModule:CmdOpenPetFreeMainPanel(Action)
end

function PetUIModule:OnCmdGetEggFinshOpenAttribute()
  return self.data.EggFinshOpenAttribute
end

function PetUIModule:OnCmdOpenExChangeGrowUpPanel(NeedExChangeCount, DiffItem)
  self:OpenPanel("ExChangeGrowUp", NeedExChangeCount, DiffItem)
end

function PetUIModule:OnCmdShowDescPanel(id)
  if self:HasPanel("PetSkillTips") then
    local panelA = self:GetPanel("PetSkillTips")
    if id then
      panelA:OnDescTextClicked(id)
    end
    if self:HasPanel("PetRightPanel") then
      local panelB = self:GetPanel("PetRightPanel")
      if id then
        panelB:OnDescTextClicked(id)
      end
    end
  elseif self:HasPanel("PetConfirmPanel") then
    if self:HasPanel("PetWarehouseFree") then
      local panel = self:GetPanel("PetWarehouseFree")
      if id then
        panel:OnDescTextClicked(id)
      end
    else
      local panel = self:GetPanel("PetConfirmPanel")
      if id then
        panel:OnDescTextClicked(id)
      end
    end
  elseif self:HasPanel("PetWarehouseFree") then
    local panel = self:GetPanel("PetWarehouseFree")
    if id then
      panel:OnDescTextClicked(id)
    end
  elseif self:HasPanel("PetTeamReplace") then
    if self:HasPanel("PetRightPanel") then
      local panel = self:GetPanel("PetRightPanel")
      if id then
        panel:OnDescTextClicked(id)
      end
    else
      local panel = self:GetPanel("PetTeamReplace")
      if id then
        panel:OnDescTextClicked(id)
      end
    end
  elseif self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    if id then
      panel:OnDescTextClicked(id)
    end
  end
end

function PetUIModule:OnCmdShowDescRightPanel(id)
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    if id then
      panel:OnDescTextClicked(id)
    end
  elseif self:HasPanel("PetTeamReplace") then
    if self:HasPanel("PetRightPanel") then
      local panel = self:GetPanel("PetRightPanel")
      if id then
        panel:OnDescTextClicked(id)
      end
    else
      local panel = self:GetPanel("PetTeamReplace")
      if id then
        panel:OnDescTextClicked(id)
      end
    end
  end
end

function PetUIModule:OnCmdShowDescCampPanel(id)
  if self:HasPanel("PetConfirmPanel") then
    if self:HasPanel("PetWarehouseFree") then
      local panel = self:GetPanel("PetWarehouseFree")
      if id then
        panel:OnDescTextClicked(id)
      end
    else
      local panel = self:GetPanel("PetConfirmPanel")
      if id then
        panel:OnDescTextClicked(id)
      end
    end
  elseif self:HasPanel("PetWarehouseFree") then
    local panel = self:GetPanel("PetWarehouseFree")
    if id then
      panel:OnDescTextClicked(id)
    end
  end
end

function PetUIModule:OnCmdSetDescText(descText)
  self:DispatchEvent(PetUIModuleEvent.SetDescText, descText)
end

function PetUIModule:OnCmdGetDescText()
  return self.descText
end

function PetUIModule:OnCmdSetDescTextTable(descText)
  self.descText = descText
end

function PetUIModule:OnCmdClearModuleDescText()
  self.descText = {}
end

function PetUIModule:OnCmdClearDescText()
  self:DispatchEvent(PetUIModuleEvent.ClearDescText)
end

function PetUIModule:OnCmdResetRightPanelDescText()
  if self:HasPanel("PetRightPanel") then
    self:DispatchEvent(PetUIModuleEvent.ResetRightPanelDescText)
  end
end

function PetUIModule:OnCmdResetSkillTipDescText()
  if self:HasPanel("PetSkillTips") then
    self:DispatchEvent(PetUIModuleEvent.ResetSkillTipDescText)
  end
end

function PetUIModule:OnCmdShowBtnClosePanel()
  self:DispatchEvent(PetUIModuleEvent.ShowBtnClosePanel)
end

function PetUIModule:OnCmdHideBtnClosePanel()
  self:DispatchEvent(PetUIModuleEvent.HideBtnClosePanel)
end

function PetUIModule:OnCmdSetEggFinshOpenAttribute(isOpenAttribute)
  self.data.EggFinshOpenAttribute = isOpenAttribute
end

function PetUIModule:OnCmdGetEggSpeedActiveOpenState()
  local Active = _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_UP)
  local isOpenActive = false
  if Active and Active[1] then
    isOpenActive = Active[1]:IsInProgress()
  end
  return isOpenActive
end

function PetUIModule:OnCmdSetPetItemClickAble(panelName, clickable)
  local panel = self:GetPanel(panelName)
  if panel then
    panel:SetPetItemClickAble(clickable)
  end
end

function PetUIModule:SetPetHatchingPanelIsClicking(bClicking)
  if self:HasPanel("PetHatchingPanel") then
    local panel = self:GetPanel("PetHatchingPanel")
    if panel and panel.SetIsClicking then
      panel:SetIsClicking(bClicking)
    end
  end
end

function PetUIModule:CmdSetPetWarehouseFreeInfo(PetData, ListIndex)
  if self:HasPanel("PetWarehouseFree") then
    local panel = self:GetPanel("PetWarehouseFree")
    panel:SetRightInfo(PetData, ListIndex)
  end
end

function PetUIModule:CmdOpenBloodMagicTips(...)
  self:OpenPanel("UMG_MagicTips", ...)
end

function PetUIModule:OnCmdOpenBloodLineMagic(...)
  self:OpenPanel("PetBloodlineMagic", ...)
end

function PetUIModule:OnCmdSelectBloodItem(...)
  self:DispatchEvent(PetUIModuleEvent.SelectBloodItemEvent, ...)
end

function PetUIModule:OnEquipProtagonistMagicStateChanged(Item_Gid, IsEquipment, Item_Id)
  if self.WaitForEquipRsp then
    return
  end
  self.WaitForEquipRsp = true
  self.IsEquipment = IsEquipment
  local req = _G.ProtoMessage:newZoneChangeRoleMagicItemReq()
  req.item_gid = Item_Gid
  req.item_conf_id = Item_Id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHANGE_ROLE_MAGIC_ITEM_REQ, req, self, self.OnCmdEquipProtagonistMagicStateChangedRsp)
end

function PetUIModule:OnCmdEquipProtagonistMagicStateChangedRsp(rsp)
  self.WaitForEquipRsp = false
  if 0 == rsp.ret_info.ret_code then
  end
end

function PetUIModule:CmdOpenPetCollectPanel(pet_gid, CurMark)
  self:OpenPanel("PetPartnerMarker", pet_gid, CurMark)
end

function PetUIModule:CmdSetPetCollect(CollectList, NotTips)
  if self.IsWaitSetCollectRsp then
    return
  end
  self.IsWaitSetCollectRsp = true
  if not NotTips then
    if CollectList[1].partner_mark then
      self.partner_mark = CollectList[1].partner_mark
    else
      self.partner_mark = ProtoEnum.PetPartnerMarkType.PPMT_NONE
    end
  end
  local req = _G.ProtoMessage:newZoneUpdatePetCollectTagReq()
  req.collection_info = CollectList
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UPDATE_PET_COLLECT_TAG_REQ, req, self, self.OnUpdatePetCollectTagRsp)
end

function PetUIModule:OnUpdatePetCollectTagRsp(Rsp)
  self.IsWaitSetCollectRsp = false
  if 0 == Rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.AttributePanelRefresh)
    self:DispatchEvent(PetUIModuleEvent.UpdatePetCollect, self.partner_mark)
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.UpdatePetCollect, self.partner_mark)
    _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.UpdatePetCollect, self.partner_mark)
    _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.OnUpdatePetCollectTagRsp, self.partner_mark)
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OnUpdatePetCollectTagRsp, self.partner_mark)
    _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdUpdatePetCollect, self.partner_mark)
    if self:HasPanel("EggIncubatePanel") then
      local panel = self:GetPanel("EggIncubatePanel")
      if panel then
        panel:UpdateCollect(self.partner_mark)
      end
    end
  end
  self.partner_mark = ProtoEnum.PetPartnerMarkType.PPMT_NONE
end

function PetUIModule:CmdOpenToBagMainPanelByOpenType(OpenEnum, petData, PetOpenUseAction)
  if not self.IsBagToOpenPanel then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.HideRightPanel)
    _G.NRCModuleManager:DoCmd(BagModuleCmd.SetIsPetInfoMainToPanel)
    _G.NRCModuleManager:DoCmd(BagModuleCmd.OpenBagMainPanel, OpenEnum, petData, PetOpenUseAction)
  else
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseRightPanel)
    _G.NRCModuleManager:DoCmd(BagModuleCmd.PetEnableBagMainPanel, petData, OpenEnum, PetOpenUseAction)
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.HideTipsPanel)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ClosePanelPetMain)
end

function PetUIModule:OnCmdOpenTipsIndividualValu(arg)
  self:OpenPanel("TipsIndividualValu", arg)
end

function PetUIModule:OnCmdOpenMedalWonPanel(_PetData)
  self:OpenPanel("MedalWonPanel", _PetData)
end

function PetUIModule:OnCmdSelectMedalItem(Item, Index)
  self:DispatchEvent(PetUIModuleEvent.SelectMedalItemEvent, Item, Index)
end

function PetUIModule:OnCmdMedalOperation(MedalOperationType, PetGid, MedalConfId)
  self.MedalOperationType = MedalOperationType
  local req = _G.ProtoMessage:newZonePetMedalCommonReq()
  req.pet_gid = PetGid
  req.action = MedalOperationType
  req.medal_conf_id = MedalConfId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_MEDAL_COMMON_REQ, req, self, self.OnPetMedalCommonRsp)
end

function PetUIModule:OnPetMedalCommonRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code and _rsp.ret_info.goods_change_info and _rsp.ret_info.goods_change_info.changes then
    for k, v in pairs(_rsp.ret_info.goods_change_info.changes) do
      if v.medal and v.medal.conf_id and v.medal.detail then
        local medal_type = _G.DataModelMgr.PlayerDataModel:GetMedalTypeByPetMedal(v.medal)
        local medalData = _G.DataModelMgr.PlayerDataModel:CreateMedalData(v.medal.detail, v.medal.conf_id, medal_type)
        self:DispatchEvent(PetUIModuleEvent.PetWearMedalEvent, medalData, self.MedalOperationType)
      end
    end
  end
end

function PetUIModule:OnCmdResetPetRightPanelShareComboBox()
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    panel:ResetShareComboBox()
  end
end

function PetUIModule:OnCmdResetCanListenShareType()
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    panel:ResetCanListenShareType()
  end
end

function PetUIModule:OnCmdOpenShareCameraPanel(petData, openCb, closeCb)
  local mainCamera
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    panel:EnablePlayBgm(false)
    panel:DealVideoShareData()
    mainCamera = panel.petMiddlePanel.petImage3D.PetWorldView:getActorByName("MainCamera")
  end
  local petGid = 0
  if petData and petData.gid then
    petGid = petData.gid
  end
  local shareData = {
    camera = mainCamera,
    gid = petGid,
    openCb = openCb,
    closeCb = closeCb
  }
  self:OpenPanel("ShareCameraPanel", shareData)
end

function PetUIModule:OnCmdCloseShareCameraPanel()
  if self:HasPanel("ShareCameraPanel") then
    local panel = self:GetPanel("ShareCameraPanel")
    panel:DoClose()
  end
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    panel:EnablePlayBgm(true)
  end
end

function PetUIModule:OnCmdCloseMoreList(bIsShow)
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    panel.petLeftPanel:TryShowOrCloseList(bIsShow)
  end
end

function PetUIModule:OnCmdPlayShareVideoG6()
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    panel:PlayShareVideoG6()
  end
end

function PetUIModule:OnCmdPlayShareCameraPanelCloseAnim()
  if self:HasPanel("ShareCameraPanel") then
    local panel = self:GetPanel("ShareCameraPanel")
    panel:PlayCloseAnim()
  end
end

function PetUIModule:OnCmdPlayShareVideoEnablePetMain(enable)
  if enable then
    if not self:HasPanel("ShareCameraPanel") then
      if self:HasPanel("PetBagPanel") then
        local petBagPanel = self:GetPanel("PetBagPanel")
        petBagPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      if self:HasPanel("PetInfoMain") then
        local panel = self:GetPanel("PetInfoMain")
        if self.PetInfoMainVisibleTable then
          for _, v in ipairs(self.PetInfoMainVisibleTable) do
            panel[v.panelName]:SetVisibility(v.visible)
          end
        end
        self.PetInfoMainVisibleTable = {}
        self:DispatchEvent(PetUIModuleEvent.ShowHideGiftColleaguesBtn, true)
      end
      if self:HasPanel("PetRightPanel") then
        local panel = self:GetPanel("PetRightPanel")
        panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        panel:CloseSwitchButton(false)
      end
      if self:HasPanel("NewPetBag") then
        local panel = self:GetPanel("NewPetBag")
        panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self:DispatchEvent(PetUIModuleEvent.ShowHideRecommendedBtn, true)
    end
  else
    if self:HasPanel("PetBagPanel") then
      local petBagPanel = self:GetPanel("PetBagPanel")
      petBagPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    if self:HasPanel("PetInfoMain") then
      local panel = self:GetPanel("PetInfoMain")
      self.PetInfoMainVisibleTable = {}
      if self:CheckVideoShareMainPetPanelUIIsVisible(panel.UMG_btnClose) then
        panel:ShowOrHideCloseBtn(false)
        table.insert(self.PetInfoMainVisibleTable, {
          panelName = "UMG_btnClose",
          visible = UE4.ESlateVisibility.Visible
        })
      end
      if self:CheckVideoShareMainPetPanelUIIsVisible(panel.ShareBtn) then
        panel.ShareBtn:SetVisibility(UE4.ESlateVisibility.Hidden)
        table.insert(self.PetInfoMainVisibleTable, {
          panelName = "ShareBtn",
          visible = UE4.ESlateVisibility.Visible
        })
      end
      if self:CheckVideoShareMainPetPanelUIIsVisible(panel.petLeftPanel) then
        panel.petLeftPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
        table.insert(self.PetInfoMainVisibleTable, {
          panelName = "petLeftPanel",
          visible = UE4.ESlateVisibility.SelfHitTestInvisible
        })
      end
      self:DispatchEvent(PetUIModuleEvent.ShowHideGiftColleaguesBtn, false)
    end
    if self:HasPanel("PetRightPanel") then
      local panel = self:GetPanel("PetRightPanel")
      panel:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    if self:HasPanel("NewPetBag") then
      local panel = self:GetPanel("NewPetBag")
      panel:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    self:DispatchEvent(PetUIModuleEvent.ShowHideRecommendedBtn, false)
  end
end

function PetUIModule:OnCmdShowRightPanelShareBtn(enable)
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    if enable then
      panel:ShowShareBtn()
    else
      panel.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function PetUIModule:OnCmdSetPetMainPanelVisibility(enable)
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    if enable then
      panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      panel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function PetUIModule:OnCmdSetPetMainShareBtnVisibility(enable)
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    if enable then
      panel:ShowShareBtn()
    else
      panel.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function PetUIModule:OnCmdVideoShareResetPetMainPet3D()
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    panel.petMiddlePanel.petImage3D:ResetPetModeData()
  end
end

function PetUIModule:OnCmdOpenShareOverlayPanel(data)
  self:ResetPetMainCameraPos()
  self:OpenPanel("ShareOverlay", data)
end

function PetUIModule:OnCmdCloseShareOverlayPanel()
  if self:HasPanel("ShareOverlay") then
    local panel = self:GetPanel("ShareOverlay")
    panel:DoClose()
  end
end

function PetUIModule:OnCmdGetCanSharePet()
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    return panel.petMiddlePanel.petImage3D.IsCanSharePet
  end
  return false
end

function PetUIModule:OnCmdOpenTipsStrongPoint(petData)
  self:OpenPanel("TipsStrongPoint", petData)
end

function PetUIModule:OnCmdCloseTipsStrongPoint()
  if self:HasPanel("TipsStrongPoint") then
    self:ClosePanel("TipsStrongPoint")
  end
end

function PetUIModule:OnCmdOpenPeculiarityTips(petData)
  self:OpenPanel("PeculiarityTips", petData)
end

function PetUIModule:OnCmdClosePeculiarityTips()
  if self:HasPanel("PeculiarityTips") then
    self:ClosePanel("PeculiarityTips")
  end
end

function PetUIModule:OnCmdCloseShareSelectBox()
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    panel:ResetShareComboBox()
  end
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    panel:ResetShareComboBox()
  end
end

function PetUIModule:OnCmdOpenDazzlingTipsPanel(petData)
  self:OpenPanel("PetDazzlingTips", petData)
end

function PetUIModule:OnCmdOpenMutationTipsPanel(petData)
  self:OpenPanel("PetDifferentColorsTips", petData)
end

function PetUIModule:OnCmdTestOpenPetSkillMain()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsBagToOpenPanel)
  local petData = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()[1]
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 2, true, 1)
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    callback = self.OnUMGLoadFinished
  })
end

function PetUIModule:OnCmdTestOpenPetDetailedInfo()
  local petData = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()[1]
  self:OpenPanel("PetDetailedInfo")
end

function PetUIModule:OnCmdPetRightPanelPcClose()
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    panel:OnPcClose()
  elseif self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    panel:OnCloseButtonClicked(false)
  end
end

function PetUIModule:OnCmdTestOpenPedalPanel()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsBagToOpenPanel)
  local petData = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()[1]
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 6, true)
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    callback = self.OnUMGLoadFinished
  })
end

function PetUIModule:OnCmdIsCurrentlyInQualifying()
  return self.data.IsQualifying
end

function PetUIModule:OnCmdSetInQualifyingState(isQualifying)
  self.data.IsQualifying = isQualifying
end

function PetUIModule:OnCmdIsShareRecordVideo()
  return self.data.IsShareRecordVideo
end

function PetUIModule:OnCmdSetIsShareRecordVideo(flag)
  self.data.IsShareRecordVideo = flag
end

function PetUIModule:OpenShareTeamPanel(teamType, teamIndex)
  local req = _G.ProtoMessage:newZonePetSharePetTeamReq()
  req.team_type = teamType
  req.team_idx = teamIndex
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, teamType)
  if not teamInfo then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_copy_no_pet)
    return
  end
  self.teamIndex = teamIndex
  local teamInfoData = teamInfo.teams[teamIndex + 1].pet_infos
  if not teamInfoData or #teamInfoData < 1 then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_copy_no_pet)
    return
  end
  local sharePetTeam = ProtoMessage:newSharedPetTeamInfo()
  sharePetTeam.team_type = teamType
  local DebugData = {
    "\233\152\159\228\188\141",
    "\229\164\167\228\184\150\231\149\140\229\176\143\233\152\159"
  }
  if teamInfo.teams[teamIndex + 1].team_name then
    sharePetTeam.team_name = teamInfo.teams[teamIndex + 1].team_name
  elseif teamType == ProtoEnum.PlayerTeamType.PTT_BIG_WORLD then
    sharePetTeam.team_name = DebugData[2] .. teamIndex + 1
  else
    sharePetTeam.team_name = DebugData[1] .. teamIndex + 1
  end
  local role_magic_gid = teamInfo.teams[teamIndex + 1].role_magic_gid
  local role_magic_id
  if role_magic_gid then
    local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
    if BagItemS then
      for index, BagItem in pairs(BagItemS) do
        if BagItem.gid == role_magic_gid then
          role_magic_id = BagItem.id
        end
      end
    else
      Log.Error("PetUIModule BagItemS is nil")
    end
  end
  sharePetTeam.role_magic_id = role_magic_id or nil
  for i, petInfo in ipairs(teamInfoData) do
    local petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petInfo.pet_gid)
    if not petDataInfo then
      Log.Warning("PetUIModule:OpenShareTeamPanel", "petDataInfo is nil ")
    else
      local typeInfo = petDataInfo and petDataInfo.type
      local typeInfoType = typeInfo and typeInfo.type
      local typeInfoTypeParam = typeInfo and typeInfo.param
      sharePetTeam.pets[i] = {}
      local petBaseConfId
      if typeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM then
        local skillDamType = typeInfoTypeParam
        petBaseConfId = PetUtils.GetRandomPetBaseConfIdFromSkillDamType(skillDamType)
      else
        petBaseConfId = petDataInfo.base_conf_id
      end
      sharePetTeam.pets[i].base_conf_id = petBaseConfId
      sharePetTeam.pets[i].changed_nature_neg_attr_type = petDataInfo.changed_nature_neg_attr_type
      sharePetTeam.pets[i].changed_nature_pos_attr_type = petDataInfo.changed_nature_pos_attr_type
      sharePetTeam.pets[i].blood_id = petDataInfo.blood_id
      sharePetTeam.pets[i].nature = petDataInfo.nature
      sharePetTeam.pets[i].hp_talent = petDataInfo.attribute_info.hp.talent
      sharePetTeam.pets[i].attack_talent = petDataInfo.attribute_info.attack.talent
      sharePetTeam.pets[i].special_attack_talent = petDataInfo.attribute_info.special_attack.talent
      sharePetTeam.pets[i].special_defense_talent = petDataInfo.attribute_info.special_defense.talent
      sharePetTeam.pets[i].speed_talent = petDataInfo.attribute_info.speed.talent
      sharePetTeam.pets[i].defense_talent = petDataInfo.attribute_info.defense.talent
      sharePetTeam.pets[i].skills = {}
      if petInfo.equip_infos then
        for j, skillData in ipairs(petInfo.equip_infos) do
          local pos = skillData.pos
          sharePetTeam.pets[i].skills[j] = {}
          sharePetTeam.pets[i].skills[j].pos = pos
          sharePetTeam.pets[i].skills[j].id = skillData.id
        end
      else
        for j, skillData in ipairs(petDataInfo.skill.skill_data) do
          local pos = skillData.pos
          if skillData.is_equipped and pos > 0 and pos <= 4 then
            sharePetTeam.pets[i].skills[pos] = {}
            sharePetTeam.pets[i].skills[pos].pos = pos
            sharePetTeam.pets[i].skills[pos].id = skillData.id
          end
        end
        local realIndex = 1
        for j = 1, 4 do
          if sharePetTeam.pets[i].skills[j] then
            if j > realIndex then
              sharePetTeam.pets[i].skills[realIndex] = table.deepCopy(sharePetTeam.pets[i].skills[j])
              sharePetTeam.pets[i].skills[realIndex].pos = realIndex
              sharePetTeam.pets[i].skills[j] = nil
            end
            realIndex = realIndex + 1
          end
        end
      end
    end
  end
  self:OpenSharePetTeamPanel(sharePetTeam)
end

function PetUIModule:OnSharePetTeamRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local pets = rsp.team.pets
    if pets then
      self:OpenPanel("ShareTeam", rsp, self.teamIndex)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_copy_no_pet)
    end
  end
end

function PetUIModule:OpenSharePetTeamPanel(team)
  local pets = team.pets
  if pets then
    local shareBaseId = _G.Enum.ShareButtonType.SBT_TEAM_SHARE
    local sharePartId = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartIdByShareBaseId, shareBaseId)
    if sharePartId then
      local data = {
        shareBaseId = shareBaseId,
        sharePartId = sharePartId,
        teamData = team,
        teamIndex = self.teamIndex
      }
      _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenShareUIPanel, data)
    end
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_copy_no_pet)
  end
end

function PetUIModule:EncodeShareTeamCode(SharedPetTeamInfoList, magicID, teamType, teamName)
  local version = _G.DataConfigManager:GetPetGlobalConfig("lineup_code_version") and _G.DataConfigManager:GetPetGlobalConfig("lineup_code_version").num or 1
  local encodePetData = _G.NRCModuleManager:DoCmd(_G.ShareModuleCmd.GetFilledBase64, version, 2)
  local validPetLength = 6
  for i, data in ipairs(SharedPetTeamInfoList) do
    if data.NatureDataList then
      break
    end
    local NatureDataList = {}
    if data.attack_talent and 0 ~= data.attack_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_PHYATK_PERCENT,
        num = data.attack_talent
      })
    end
    if data.defense_talent and 0 ~= data.defense_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_PHYDEF_PERCENT,
        num = data.defense_talent
      })
    end
    if data.hp_talent and 0 ~= data.hp_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_HPMAX_PERCENT,
        num = data.hp_talent
      })
    end
    if data.special_attack_talent and 0 ~= data.special_attack_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEATK_PERCENT,
        num = data.special_attack_talent
      })
    end
    if data.special_defense_talent and 0 ~= data.special_defense_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEDEF_PERCENT,
        num = data.special_defense_talent
      })
    end
    if data.speed_talent and 0 ~= data.speed_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEED_PERCENT,
        num = data.speed_talent
      })
    end
    data.NatureDataList = NatureDataList
  end
  for i, v in ipairs(SharedPetTeamInfoList) do
    local AddNatureNum = 0
    local AddSkillNum = 0
    if v.empty then
      validPetLength = validPetLength - 1
    else
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(v.base_conf_id)
      local encodePetId
      if petBaseConf then
        encodePetId = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, petBaseConf.id, 5)
        encodePetData = encodePetData .. encodePetId
      end
      local encodeBloodId = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, v.blood_id, 2)
      encodePetData = encodePetData .. encodeBloodId
      local nature = v and v.nature or 0
      local natureId = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, nature, 2)
      encodePetData = encodePetData .. natureId
      if not v.NatureDataList then
        AddNatureNum = 3
      elseif v.NatureDataList and #v.NatureDataList < 3 then
        AddNatureNum = 3 - #v.NatureDataList
      end
      Log.PrintScreenMsgRed("AddNatureNum is " .. AddNatureNum)
      if v.NatureDataList then
        for _, nature in ipairs(v.NatureDataList) do
          local encodeNature = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, nature.attribute, 2)
          encodePetData = encodePetData .. encodeNature
        end
      end
      if AddNatureNum > 0 then
        for i = 1, AddNatureNum do
          encodePetData = encodePetData .. "00"
        end
      end
      if not v.skills then
        AddSkillNum = 4
      elseif #v.skills < 4 then
        AddSkillNum = 4 - #v.skills
      end
      Log.PrintScreenMsgRed("AddSkillNum is " .. AddSkillNum)
      if v.skills then
        for _, skill in ipairs(v.skills) do
          local encodeSkillId = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, skill.id, 5)
          encodePetData = encodePetData .. encodeSkillId
        end
      end
      if AddSkillNum > 0 then
        for i = 1, AddSkillNum do
          encodePetData = encodePetData .. "00000"
        end
      end
    end
  end
  Log.Debug("valid pet num is " .. validPetLength)
  local encodeValidPetNum = _G.NRCModuleManager:DoCmd(_G.ShareModuleCmd.GetFilledBase64, validPetLength, 1)
  encodePetData = string.sub(encodePetData, 1, 2) .. encodeValidPetNum .. string.sub(encodePetData, 3)
  local encodeMagicId = ""
  if magicID then
    encodeMagicId = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, magicID, 4)
  else
    encodeMagicId = "0000"
  end
  encodePetData = encodePetData .. encodeMagicId
  local encodeTeamType = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, teamType or 1, 1)
  encodePetData = encodePetData .. encodeTeamType
  for _, v in ipairs(SharedPetTeamInfoList) do
    local encodePosAttr, encodeNegAttr
    if not v.empty then
      if v.changed_nature_pos_attr_type then
        encodePosAttr = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, v.changed_nature_pos_attr_type, 2)
      else
        encodePosAttr = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, 0, 2)
      end
      if v.changed_nature_neg_attr_type then
        encodeNegAttr = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, v.changed_nature_neg_attr_type, 2)
      else
        encodeNegAttr = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetFilledBase64, 0, 2)
      end
      if not string.IsNilOrEmpty(encodePosAttr) then
        encodePetData = encodePetData .. encodePosAttr
      end
      if not string.IsNilOrEmpty(encodeNegAttr) then
        encodePetData = encodePetData .. encodeNegAttr
      end
    end
  end
  local Req = ProtoMessage:newZoneTaskConditionTriggerReq()
  Req.taskid = 0
  Req.condition_type = Enum.TaskKeyType.TKT_TEAM_SHARE
  Log.Debug("[EncodeShareTeamCode : Send ZoneTaskConditionTriggerReq")
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_CONDITION_TRIGGER_REQ, Req, self, self.OnSendFinish)
  return encodePetData
end

function PetUIModule:OnSendFinish(rsp)
end

function PetUIModule:OpenAdjustTeamPanel(...)
  if self:HasPanel("AdjustTeam") then
    local panel = self:GetPanel("AdjustTeam")
    if panel then
      panel:RefreshPanel(...)
    end
  else
    self:OpenPanel("AdjustTeam", ...)
  end
  local req_unlock = _G.ProtoMessage:newZoneGetUnlockedExchangeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoEnum.ZoneSvrCmd.ZONE_GET_UNLOCKED_EXCHANGE_REQ, req_unlock, self, self.OnGetUnlockedExchangeRsp, true, true)
end

function PetUIModule:OnGetUnlockedExchangeRsp(rsp)
  self.exchangeGroupInfoTable = {}
  if 0 == rsp.ret_info.ret_code then
    for i, data in ipairs(rsp.exchange_list or {}) do
      local exchange_group_info = {}
      exchange_group_info.exchange_times = data.exchange_times
      exchange_group_info.next_refresh_time = data.next_refresh_time
      self.exchangeGroupInfoTable[data.exchange_group] = exchange_group_info
    end
  else
    Log.Error("\231\130\188\233\135\145\232\167\163\233\148\129\228\191\161\230\129\175\229\155\158\229\140\133\233\148\153\232\175\175: ", table.tostring(rsp))
  end
end

function PetUIModule:OpenFriendPetTeamPanel(teamType, activity_id)
  Log.Debug("OpenFriendPetTeamPanel teamType:" .. tostring(teamType))
  if activity_id then
    if not self.data:GetRecommendPetTeamList() then
      self:OnZoneRecommendPetTeamGetListReq(activity_id)
    end
    self:OpenPanel("FriendPetTeamPanel", teamType, true, activity_id)
  else
    self:OnZonePetTeamFriendGetListReq(teamType, 0, "")
    self:OpenPanel("FriendPetTeamPanel", teamType)
  end
end

function PetUIModule:OpenFriendPetTeamDetailPanel(friendTeamDetailsParam)
  self:OpenPanel("FriendPetTeamDetailPanel", friendTeamDetailsParam)
end

function PetUIModule:OnCmdOpenPetFilteringPanel(...)
  self:OpenPanel("PetFiltering", ...)
end

function PetUIModule:OnCmdOpenPetSortPanel(sortRuleId, skillSortReverse)
  self:OpenPanel("PetSortPanel", sortRuleId, skillSortReverse)
end

function PetUIModule:OnPetFilterTypeSelect(filterType, values, bIsSelect)
  if self:HasPanel("PetFiltering") then
    local panel = self:GetPanel("PetFiltering")
    if panel then
      panel:OnFilterTypeSelect(filterType, values, bIsSelect)
    end
  end
end

function PetUIModule:OnPetSkillFilterRuleChange(filterRule)
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    if panel then
      panel.PetSkillMain:OnPetSkillFilterRuleChange(filterRule)
    end
  end
  if self:HasPanel("PetConfirmPanel") then
    local panel = self:GetPanel("PetConfirmPanel")
    if panel then
      panel:OnPetSkillFilterRuleChange(filterRule)
    end
  end
  if self:HasPanel("PetTeamReplace") then
    local panel = self:GetPanel("PetTeamReplace")
    if panel then
      panel:OnPetSkillFilterRuleChange(filterRule)
    end
  end
  if self:HasPanel("TrialPVPPet") then
    local panel = self:GetPanel("TrialPVPPet")
    if panel then
      panel:OnPetSkillFilterRuleChange(filterRule)
    end
  end
end

function PetUIModule:OnPetSkillSortRuleChange(id, skillSortReverse)
  if self:HasPanel("PetRightPanel") then
    local panel = self:GetPanel("PetRightPanel")
    if panel then
      panel.PetSkillMain:OnPetSkillSortRuleChange(id, skillSortReverse)
    end
  end
  if self:HasPanel("PetConfirmPanel") then
    local panel = self:GetPanel("PetConfirmPanel")
    if panel then
      panel:OnPetSkillSortRuleChange(id, skillSortReverse)
    end
  end
  if self:HasPanel("PetTeamReplace") then
    local panel = self:GetPanel("PetTeamReplace")
    if panel then
      panel:OnPetSkillSortRuleChange(id, skillSortReverse)
    end
  end
  if self:HasPanel("TrialPVPPet") then
    local panel = self:GetPanel("TrialPVPPet")
    if panel then
      panel:OnPetSkillSortRuleChange(id, skillSortReverse)
    end
  end
end

function PetUIModule:OnZonePetTeamFriendGetListReq(teamType, pageNum, filter)
  local req = _G.ProtoMessage:newZonePetTeamFriendGetListReq()
  req.team_type = teamType
  req.page_num = pageNum or 0
  req.filter = filter or ""
  Log.Info("OnZonePetTeamFriendGetListReq teamType:" .. teamType .. " pageNum:" .. req.page_num .. " filter:" .. req.filter)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_FRIEND_GET_LIST_REQ, req, self, self.OnZonePetTeamFriendGetListRsp, false, true)
end

function PetUIModule:OnZonePetTeamFriendGetListRsp(rsp, reqData)
  if 0 == rsp.ret_info.ret_code then
    self.data:ParseZonePetTeamFriendGetListRsp(rsp)
    self:DispatchEvent(PetUIModuleEvent.UpdateFriendPetTeamList)
  else
    if reqData and reqData.filter == "" and 0 == reqData.page_num then
      Log.Error("PetUIModule:OnZonePetTeamFriendGetListRsp clear data for error")
      self.data:ResetFriendPetTeamData()
      self:DispatchEvent(PetUIModuleEvent.UpdateFriendPetTeamList)
    end
    local filter = reqData and reqData.filter or ""
    local pageNum = reqData and reqData.page_num or 0
    Log.ErrorFormat("PetUIModule:OnZonePetTeamFriendGetListRsp errorCode=%s, filter=%s, pageNum=%s", tostring(rsp.ret_info.ret_code), tostring(filter), tostring(pageNum))
  end
end

function PetUIModule:OnZoneRecommendPetTeamGetListReq(activity_id)
  local req = _G.ProtoMessage:newZoneGetRecommendPetTeamReq()
  req.activity_id = activity_id
  Log.Info("OnZoneRecommendPetTeamGetListReq activity_id:" .. activity_id)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_RECOMMEND_PET_TEAM_REQ, req, self, self.OnZoneRecommendPetTeamGetListRsp, false, true)
end

function PetUIModule:OnZoneRecommendPetTeamGetListRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetRecommendPetTeamList(rsp.recommend_pet_team)
    self:DispatchEvent(PetUIModuleEvent.UpdateFriendPetTeamList)
  else
    Log.Error("OnZoneRecommendPetTeamGetListRsp error: " .. rsp.ret_info.ret_code)
  end
end

function PetUIModule:DebugSaveRecommendPetTeamReq()
  local team = self.data:GetRecommendPetTeamList()
  local saveTeam = ProtoMessage:newRecommendPetTeamInfo()
  if team and #team > 0 then
    saveTeam.pet_team_share_id = nil
    saveTeam.player_name = team[1].player_name
    saveTeam.player_headpic = team[1].player_headpic
    saveTeam.pet_level = team[1].pet_level
    saveTeam.team_name = team[1].team_name
    saveTeam.team_id = team[1].team_id
    local code = self:RemoveCodeAnnotation(team[1].pet_team_share_id)
    local pet_team_info = self:DecodeShareData(code)
    pet_team_info.team_type = _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_4
    saveTeam.pet_team_info = pet_team_info
  end
  self:OnZoneSaveRecommendPetTeamReq(3300001, saveTeam)
end

function PetUIModule:OnZoneSaveRecommendPetTeamReq(activityid, recommend_pet_team)
  Log.Dump(recommend_pet_team, 6, "OnZoneSaveRecommendPetTeamReq")
  local req = _G.ProtoMessage:newZoneActivitySaveRecommendPetTeamReq()
  req.activity_id = activityid
  req.recommend_pet_team = recommend_pet_team
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_SAVE_RECOMMEND_PET_TEAM_REQ, req, self, self.OnZoneSaveRecommendPetTeamRsp, false, true)
end

function PetUIModule:OnZoneSaveRecommendPetTeamRsp(rsp, reqData)
  if 0 == rsp.ret_info.ret_code then
    self:OnZoneRecommendPetTeamGetListReq(reqData.activity_id)
  else
    Log.Error("OnZoneSaveRecommendPetTeamRsp error: " .. rsp.ret_info.ret_code)
  end
end

function PetUIModule:SetIsShowPetNotUnlockSkill(isHideUnlockSkill)
  self.data.isHideUnlockSkill = isHideUnlockSkill
end

function PetUIModule:GetIsShowPetNotUnlockSkill()
  return self.data.isHideUnlockSkill == nil and true or self.data.isHideUnlockSkill
end

function PetUIModule:OpenPetAlternative(...)
  self:OpenPanel("PetAlternative", ...)
end

function PetUIModule:OpenShareTeamDiffPanel(DiffNum, DiffList)
  self:OpenPanel("ShareTeamDifferenceContent", 1, DiffNum, DiffList)
end

function PetUIModule:OpenShareTeamLackPanel(...)
  self:OpenPanel("ShareTeamDifferenceContent", 2, ...)
end

function PetUIModule:OpenShareTeamSolveDifferencesPanel(DiffList, ItemList)
  self:OpenPanel("ShareTeamSolveDifferences", 1, DiffList, ItemList)
end

function PetUIModule:OpenShareTeamSolveLostDataPanel(LostDataList, ItemList)
  self:OpenPanel("ShareTeamSolveDifferences", 2, LostDataList, ItemList)
end

function PetUIModule:OpenPetShareTeamDetailsDifferencesPanel(SolveAllDiffList)
  self:OpenPanel("ShareTeamDetailsDifferences", 1, SolveAllDiffList)
end

function PetUIModule:OpenPetShareTeamLostDataDetailsPanel(SolveAllLostList)
  self:OpenPanel("ShareTeamDetailsDifferences", 2, SolveAllLostList)
end

function PetUIModule:CmdOpenShareTeamDiffOrLackPanel(Type)
  if self:HasPanel("AdjustTeam") then
    local panel = self:GetPanel("AdjustTeam")
    if panel then
      if 1 == Type then
        panel:TryOpenShareTeamDiffPanel()
      elseif 2 == Type then
        panel:TryOpenShareTeamLackPanel()
      end
    end
  end
end

function PetUIModule:OpenSkillAlternative(...)
  self:OpenPanel("SkillAlternative", ...)
end

function PetUIModule:CmdTryOpenRevisePanel(Type, data)
  if self:HasPanel("AdjustTeam") then
    local panel = self:GetPanel("AdjustTeam")
    if panel then
      panel:OpenRevisePanelByType(Type, data)
    end
  end
end

function PetUIModule:OpenSkillLearningPanel(...)
  self:OpenPanel("SkillLearning", ...)
end

function PetUIModule:OnUseBagItemSuccess()
  if self:HasPanel("SkillLearning") then
    local panel = self:GetPanel("SkillLearning")
    if panel then
      panel:OnUseBagItemSuccess()
    end
  end
end

function PetUIModule:OnUseFormulaSuccess()
  if self:HasPanel("SkillLearning") then
    local panel = self:GetPanel("SkillLearning")
    if panel then
      panel:OnUseFormulaSuccess()
    end
  end
end

function PetUIModule:OnSelectFormula(exchangeId)
  if self:HasPanel("SkillLearning") then
    local panel = self:GetPanel("SkillLearning")
    if panel then
      panel:OnSelectFormula(exchangeId)
    end
  end
end

function PetUIModule:SetExchangeMaterial()
  if self:HasPanel("SkillLearning") then
    local panel = self:GetPanel("SkillLearning")
    if panel then
      panel:SetExchangeMaterial()
    end
  end
end

function PetUIModule:OnPetTeamShareQuickAdjustRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    NRCEventCenter:DispatchEvent(PetUIModuleEvent.RefreshAdjustPetPanel)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseAllPetShareTeamDiffPanel)
    if self.RspParam then
      local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.RspParam.gid)
      local BagItem = {
        id = self.RspParam.ItemConfId
      }
      _G.NRCAudioManager:PlaySound2DAuto(40008046, "PetUIModule:OnPetTeamShareQuickAdjustRsp")
      _G.NRCModuleManager:DoCmd(BagModuleCmd.OpenBagUsePopupSuccessPanel, PetData, BagItem)
      self.RspParam = nil
    end
    self:DispatchEvent(PetUIModuleEvent.ShowSolveSuccTips)
  end
end

function PetUIModule:OnPetTeamShareQuickAdjust(ExchangeInfo, BagItemInfo, RspParam)
  self.RspParam = RspParam
  self._pendingBagItemInfo = BagItemInfo
  if ExchangeInfo and #ExchangeInfo > 0 then
    local req = _G.ProtoMessage:newZoneBatchExchangeReq()
    req.exchange_items = ExchangeInfo
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BATCH_EXCHANGE_REQ, req, self, self._OnBatchExchangeRsp)
  elseif BagItemInfo and #BagItemInfo > 0 then
    self:_SendUseMultiBagItemReq(BagItemInfo)
  end
end

function PetUIModule:_OnBatchExchangeRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    if self._pendingBagItemInfo and #self._pendingBagItemInfo > 0 then
      self:_UpdateBagItemGid(self._pendingBagItemInfo)
      if self._pendingBagItemInfo[1].id == 100422 and 1 == #self._pendingBagItemInfo then
        _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItemExistParam, self._pendingBagItemInfo[1])
        self._pendingBagItemInfo = nil
      elseif self._pendingBagItemInfo[1].id == 100421 and 1 == #self._pendingBagItemInfo then
        _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItemExistParam, self._pendingBagItemInfo[1])
        self._pendingBagItemInfo = nil
      else
        self:_SendUseMultiBagItemReq(self._pendingBagItemInfo)
      end
    else
      self:OnPetTeamShareQuickAdjustRsp(Rsp)
    end
    local req_unlock = _G.ProtoMessage:newZoneGetUnlockedExchangeReq()
    _G.ZoneServer:SendWithHandler(_G.ProtoEnum.ZoneSvrCmd.ZONE_GET_UNLOCKED_EXCHANGE_REQ, req_unlock, self, self.OnGetUnlockedExchangeRsp, true, true)
  else
    self._pendingBagItemInfo = nil
    self.RspParam = nil
  end
end

function PetUIModule:_UpdateBagItemGid(BagItemInfoList)
  for _, itemInfo in ipairs(BagItemInfoList) do
    if 0 == itemInfo.gid or itemInfo.gid == nil then
      local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, itemInfo.item_conf_id or itemInfo.id)
      if bagItem then
        itemInfo.gid = bagItem.gid
      end
    end
  end
end

function PetUIModule:_SendUseMultiBagItemReq(BagItemInfo)
  local req = _G.ProtoMessage:newZonePetTeamShareQuickAdjustReq()
  req.item_info = BagItemInfo
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_SHARE_QUICK_ADJUST_REQ, req, self, self._OnUseMultiBagItemRsp)
end

function PetUIModule:_OnUseMultiBagItemRsp(Rsp)
  self._pendingBagItemInfo = nil
  self:OnPetTeamShareQuickAdjustRsp(Rsp)
end

function PetUIModule:OpenLoadPetTeamPanel(team_type, team_index, teamShareCode)
  self.OpenAdjustTeamType = team_type
  self.OpenAdjustTeamIndex = team_index
  if -1 == team_index then
    self:SendLoadPetTeamReq(nil, teamShareCode)
  else
    local PetTeamsList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(team_type)
    local petTeam = PetTeamsList.teams[team_index + 1]
    local Context = DialogContext()
    Context:SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.SendLoadPetTeamReq):SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel)
    Context:SetForceEnableFullScreenBtn()
    Context:SetTitle(LuaText.TIPS)
    if petTeam.pet_infos then
      Context:SetContent(LuaText.lineup_code_replace_tips)
    else
      Context:SetContent(LuaText.lineup_code_generate_tips)
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function PetUIModule:SendLoadPetTeamReq(bOK, teamShareCode)
  local text = teamShareCode or UE4.UNRCStatics.ClipboardPaste()
  if "" == text then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_no_code)
  else
    local code = self:RemoveCodeAnnotation(text)
    local sharePetTeamInfo = self:DecodeShareData(code)
    if false ~= sharePetTeamInfo then
      if self:PreCheckTeamValid(sharePetTeamInfo.pets) then
        local req = ProtoMessage:newZonePetApplySharedPetTeamReq()
        req.shared_team = sharePetTeamInfo
        req.team_type = self.OpenAdjustTeamType or _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD
        _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_APPLY_SHARED_PET_TEAM_REQ, req, self, self.OnLoadPetTeamRsp, nil, true)
      else
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_not_available)
      end
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_not_available)
    end
  end
end

function PetUIModule:OnLoadPetTeamRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenAdjustTeamPanel, rsp, self.OpenAdjustTeamType, self.OpenAdjustTeamIndex)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_not_available)
  end
end

function PetUIModule:RemoveCodeAnnotation(FullCode)
  local newCode
  if FullCode then
    local res = {}
    for line in FullCode:gmatch("[^\r\n]+") do
      if not line:match("^%s*#") then
        table.insert(res, line)
      end
    end
    newCode = table.concat(res, "\n")
  end
  return newCode
end

function PetUIModule:DecodeShareData(encodedStr)
  local newPetData = {}
  local sharePetTeamInfo = ProtoMessage:newSharedPetTeamInfo()
  sharePetTeamInfo.pets = newPetData
  local DebugData = {"\233\152\159\228\188\141"}
  sharePetTeamInfo.team_name = DebugData[1]
  self.decodedMagicID = nil
  self.decodedTeamType = nil
  local versionLength = 2
  local petNumMode = 1
  local encodePetNum = string.sub(encodedStr, 3, 3)
  local petNum = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, encodePetNum)
  if petNum <= 0 then
    Log.Error("invalid pet num: " .. petNum)
    return false
  end
  local petDataLength = 35 * petNum
  local magicIDLength = 4
  local teamTypeLength = 1
  local attrDataLength = 4 * petNum
  local expectedLength = versionLength + petNumMode + petDataLength + magicIDLength + teamTypeLength + attrDataLength
  local expectedLength2 = expectedLength - 117
  if #encodedStr ~= expectedLength and #encodedStr ~= expectedLength2 then
    Log.Error("Invalid encoded string length: " .. #encodedStr .. ", expected: " .. expectedLength)
    return false
  end
  local PetLength = petNum
  if #encodedStr == expectedLength2 then
    petDataLength = 105
    attrDataLength = 12
    PetLength = 3
  end
  local Version = string.sub(encodedStr, 1, versionLength)
  local petDataStr = string.sub(encodedStr, versionLength + 2, versionLength + petDataLength)
  local magicIDStr = string.sub(encodedStr, versionLength + 1 + petDataLength + 1, versionLength + petDataLength + magicIDLength)
  local teamTypeStr = string.sub(encodedStr, versionLength + 1 + petDataLength + magicIDLength + 1, versionLength + petDataLength + magicIDLength + teamTypeLength)
  local attrDataStr = string.sub(encodedStr, versionLength + 1 + petDataLength + magicIDLength + teamTypeLength + 1)
  local MagicID
  if "0000" == magicIDStr then
    MagicID = nil
  else
    MagicID = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, magicIDStr)
  end
  local TeamType = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, teamTypeStr)
  sharePetTeamInfo.role_magic_id = MagicID
  sharePetTeamInfo.team_type = TeamType
  for i = 0, PetLength - 1 do
    local petStr = string.sub(petDataStr, i * 35 + 1, (i + 1) * 35)
    local attrStr = string.sub(attrDataStr, i * 4 + 1, (i + 1) * 4)
    if petStr ~= string.rep("0", 35) then
      local petInfo = self:DecodePetInfo(petStr, attrStr)
      table.insert(newPetData, petInfo)
    end
  end
  return sharePetTeamInfo
end

function PetUIModule:DecodePetInfo(petStr, attrStr)
  local petInfo = ProtoMessage:newSharedPetInfo()
  local baseConfIdStr = string.sub(petStr, 1, 5)
  local bloodIdStr = string.sub(petStr, 6, 7)
  local natureStr = string.sub(petStr, 8, 9)
  local natureDataStr = string.sub(petStr, 10, 15)
  local skillsStr = string.sub(petStr, 16, 35)
  local posAttrStr = string.sub(attrStr, 1, 2)
  local negAttrStr = string.sub(attrStr, 3, 4)
  petInfo.base_conf_id = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, baseConfIdStr)
  petInfo.blood_id = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, bloodIdStr)
  petInfo.nature = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, natureStr)
  petInfo.hp_talent = 0
  petInfo.attack_talent = 0
  petInfo.special_attack_talent = 0
  petInfo.defense_talent = 0
  petInfo.special_defense_talent = 0
  petInfo.speed_talent = 0
  for i = 1, 3 do
    local naturePart = string.sub(natureDataStr, (i - 1) * 2 + 1, i * 2)
    if "00" ~= naturePart then
      local attribute = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, naturePart)
      if attribute == Enum.AttributeType.AT_PHYATK_PERCENT then
        petInfo.attack_talent = 1
      elseif attribute == Enum.AttributeType.AT_PHYDEF_PERCENT then
        petInfo.defense_talent = 1
      elseif attribute == Enum.AttributeType.AT_HPMAX_PERCENT then
        petInfo.hp_talent = 1
      elseif attribute == Enum.AttributeType.AT_SPEATK_PERCENT then
        petInfo.special_attack_talent = 1
      elseif attribute == Enum.AttributeType.AT_SPEDEF_PERCENT then
        petInfo.special_defense_talent = 1
      elseif attribute == Enum.AttributeType.AT_SPEED_PERCENT then
        petInfo.speed_talent = 1
      end
    end
  end
  petInfo.skills = {}
  for i = 1, 4 do
    local skillPart = string.sub(skillsStr, (i - 1) * 5 + 1, i * 5)
    if "00000" ~= skillPart then
      local skillId = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, skillPart)
      table.insert(petInfo.skills, {id = skillId, pos = i})
    else
      table.insert(petInfo.skills, {id = 0, pos = i})
    end
  end
  petInfo.changed_nature_pos_attr_type = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, posAttrStr)
  petInfo.changed_nature_neg_attr_type = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, negAttrStr)
  return petInfo
end

function PetUIModule:PreCheckTeamValid(pets)
  if not pets or 0 == #pets then
    return false
  end
  local PlayerTeamType = _G.Enum.PlayerTeamType
  local state = true
  if self.OpenAdjustTeamType == PlayerTeamType.PTT_PVP_BATTLE_1 or self.OpenAdjustTeamType == PlayerTeamType.PTT_PVP_BATTLE_4 then
    state = self:IsHasCommonEvolutionaryChain(pets)
  elseif self.OpenAdjustTeamType == PlayerTeamType.PTT_PVP_BATTLE_2 then
    state = self:CheckBattle2(pets)
  elseif self.OpenAdjustTeamType == PlayerTeamType.PTT_PVP_BATTLE_3 then
    state = self:CheckBattle3(pets)
  elseif self.OpenAdjustTeamType == PlayerTeamType.PTT_PVP_BATTLE_5 then
    state = self:CheckBattle5(pets)
  end
  do
    local OpenAdjustTeamType = self.OpenAdjustTeamType
    local AllowRandomPetTeamTypeMap = BattleConst.AllowRandomPetTeamTypeMap
    local allowRandomPetTeamType = OpenAdjustTeamType and AllowRandomPetTeamTypeMap and AllowRandomPetTeamTypeMap[OpenAdjustTeamType]
    if not allowRandomPetTeamType then
      local isHasRandomPet = self:IsHasRandomPet(pets)
      if isHasRandomPet then
        state = false
      end
    end
  end
  if not state then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_not_available)
  end
  return state
end

function PetUIModule:CheckDepartmentFilter(DepartmentFilter, petInfo)
  if DepartmentFilter then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_conf_id)
    for k = 1, #petBaseConf.unit_type do
      if petBaseConf.unit_type[k] == DepartmentFilter then
        return true
      end
    end
  end
  return false
end

function PetUIModule:CheckBattle2(pets)
  if not self:IsHasCommonEvolutionaryChain(pets) then
    return false
  end
  for _, petInfo in pairs(pets) do
    if not self:CheckDepartmentFilter(Enum.SkillDamType.SDT_WATER, petInfo) then
      return false
    end
  end
  return true
end

function PetUIModule:CheckBattle3(pets)
  if not self:IsHasCommonEvolutionaryChain(pets) then
    return false
  end
  for _, petInfo in pairs(pets) do
    if not self:CheckDepartmentFilter(Enum.SkillDamType.SDT_INSECT, petInfo) then
      return false
    end
  end
  return true
end

function PetUIModule:CheckBattle5(pets)
  if not self:IsHasCommonEvolutionaryChain(pets) then
    return false
  end
  if #pets > 3 then
    return false
  end
  return true
end

function PetUIModule:IsHasCommonEvolutionaryChain(pets)
  if not self:CheckSharedTeamValid(pets, self.OpenAdjustTeamType) then
    return false
  else
    return true
  end
end

function PetUIModule:IsHasRandomPet(pets)
  pets = pets or {}
  local isHasRandomPet = false
  for i, petInfo in ipairs(pets) do
    local petBaseConfId = petInfo and petInfo.base_conf_id
    local isRandomPet = PetUtils.CheckIsRandomPetBase(petBaseConfId)
    if isRandomPet then
      isHasRandomPet = true
      break
    end
  end
  return isHasRandomPet
end

function PetUIModule:CheckSharedTeamValid(Team, TeamType)
  if TeamType == Enum.PlayerTeamType.PTT_BIG_WORLD then
    return true
  else
    local vis = {}
    local groupMap = {}
    for _, petInfo in pairs(Team) do
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_conf_id)
      if not petBaseConf then
        return
      end
      local petEvoID = petBaseConf.pet_evolution_id[1]
      local petEvoConf
      if petEvoID then
        petEvoConf = _G.DataConfigManager:GetPetEvolutionConf(petEvoID)
      end
      if petEvoConf then
        if groupMap[petEvoConf.pvp_mute_group] then
          return false
        else
          groupMap[petEvoConf.pvp_mute_group] = true
        end
      elseif vis[petInfo.base_conf_id] then
        return false
      else
        vis[petInfo.base_conf_id] = true
      end
    end
    return true
  end
end

function PetUIModule:OnCmdGetLevelSkillConfByPetBaseId(petBaseId)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  if petBaseConf then
    return _G.DataConfigManager:GetLevelSkillConf(petBaseConf.level_skill_conf_id)
  end
  return nil
end

function PetUIModule:GetSkillSource(skillId, petBaseId)
  local sourceTypes = {}
  local levelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, petBaseId)
  if levelSkillConf then
    for i, v in ipairs(levelSkillConf.level) do
      if v.param == skillId then
        table.insert(sourceTypes, _G.Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP)
        break
      end
    end
    for i, v in ipairs(levelSkillConf.machine_skill_group) do
      if v.machine_skill_id == skillId then
        table.insert(sourceTypes, _G.Enum.PetNewSkillSrc.PNSS_SKILL_BOOK)
        break
      end
    end
    if levelSkillConf.blood_skill_COMMON == skillId or levelSkillConf.blood_skill_GRASS == skillId or levelSkillConf.blood_skill_FIRE == skillId or levelSkillConf.blood_skill_WATER == skillId or levelSkillConf.blood_skill_LIGHT == skillId or levelSkillConf.blood_skill_STONE == skillId or levelSkillConf.blood_skill_ICE == skillId or levelSkillConf.blood_skill_DRAGON == skillId or levelSkillConf.blood_skill_ELECTRIC == skillId or levelSkillConf.blood_skill_TOXIC == skillId or levelSkillConf.blood_skill_INSECT == skillId or levelSkillConf.blood_skill_FIGHT == skillId or levelSkillConf.blood_skill_WING == skillId or levelSkillConf.blood_skill_MOE == skillId or levelSkillConf.blood_skill_GHOST == skillId or levelSkillConf.blood_skill_DEMON == skillId or levelSkillConf.blood_skill_MECHANIC == skillId or levelSkillConf.blood_skill_PHANTOM == skillId then
      table.insert(sourceTypes, _G.Enum.PetNewSkillSrc.PNSS_PET_BLOOD)
    end
    if levelSkillConf.legendary_skill == skillId then
      table.insert(sourceTypes, _G.Enum.PetNewSkillSrc.PNSS_LEGENDARY)
    end
    if 0 == #sourceTypes then
      table.insert(sourceTypes, _G.Enum.PetNewSkillSrc.PNSS_PET_BLOOD)
    end
  end
  return sourceTypes
end

function PetUIModule:GetSkillSourceAndUnlockInfo(skillId, petBaseId, petGid)
  local SkillSourceInfoList = {}
  local levelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, petBaseId)
  if levelSkillConf then
    for i, v in ipairs(levelSkillConf.level) do
      if v.param == skillId then
        local skillSourceInfo = {}
        skillSourceInfo.skillId = skillId
        skillSourceInfo.petGid = petGid
        skillSourceInfo.petBaseId = petBaseId
        skillSourceInfo.type = _G.Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP
        skillSourceInfo.text = v.level_point
        table.insert(SkillSourceInfoList, skillSourceInfo)
        break
      end
    end
    local allBagItemList
    for i, v in ipairs(levelSkillConf.machine_skill_group) do
      if v.machine_skill_id == skillId then
        local skillSourceInfo = {}
        skillSourceInfo.bagItemIds = {}
        allBagItemList = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BAG_ITEM_CONF):GetAllDatas()
        for j, bagItemConf in pairs(allBagItemList) do
          if bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_LEARN_SKILL and bagItemConf.item_behavior[1].ratio[1] == skillId then
            skillSourceInfo.icon = bagItemConf.icon
            table.insert(skillSourceInfo.bagItemIds, bagItemConf.id)
            break
          end
        end
        if #skillSourceInfo.bagItemIds > 0 then
          skillSourceInfo.skillId = skillId
          skillSourceInfo.petGid = petGid
          skillSourceInfo.petBaseId = petBaseId
          skillSourceInfo.type = _G.Enum.PetNewSkillSrc.PNSS_SKILL_BOOK
          skillSourceInfo.text = LuaText.skill_source_desc_2
          table.insert(SkillSourceInfoList, skillSourceInfo)
        end
        break
      end
    end
    if levelSkillConf.blood_skill_COMMON == skillId or levelSkillConf.blood_skill_GRASS == skillId or levelSkillConf.blood_skill_FIRE == skillId or levelSkillConf.blood_skill_WATER == skillId or levelSkillConf.blood_skill_LIGHT == skillId or levelSkillConf.blood_skill_STONE == skillId or levelSkillConf.blood_skill_ICE == skillId or levelSkillConf.blood_skill_DRAGON == skillId or levelSkillConf.blood_skill_ELECTRIC == skillId or levelSkillConf.blood_skill_TOXIC == skillId or levelSkillConf.blood_skill_INSECT == skillId or levelSkillConf.blood_skill_FIGHT == skillId or levelSkillConf.blood_skill_WING == skillId or levelSkillConf.blood_skill_MOE == skillId or levelSkillConf.blood_skill_GHOST == skillId or levelSkillConf.blood_skill_DEMON == skillId or levelSkillConf.blood_skill_MECHANIC == skillId or levelSkillConf.blood_skill_PHANTOM == skillId then
      local skillSourceInfo = {}
      local petCurBlood, petTargetBlood = nil, -1
      if petGid then
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
        petCurBlood = petData and petData.blood_id or nil
      else
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
        if petBaseConf then
          local skillDamType = petBaseConf.unit_type and petBaseConf.unit_type[1] or nil
          petCurBlood = skillDamType and PetUtils.GetPetBloodBySkillDamType(skillDamType) or Enum.PetBloodType.PBT_COMMON
        end
      end
      local skillConf = _G.DataConfigManager:GetSkillConf(skillId, true)
      if skillConf then
        petTargetBlood = PetUtils.GetPetBloodBySkillDamType(skillConf.skill_dam_type)
      end
      if petCurBlood == petTargetBlood then
        skillSourceInfo.type = _G.Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP
        skillSourceInfo.text = levelSkillConf.blood_skill_level_point
      else
        skillSourceInfo.type = _G.Enum.PetNewSkillSrc.PNSS_PET_BLOOD
        local petBloodConf = _G.DataConfigManager:GetPetBloodConf(petTargetBlood)
        if petBloodConf then
          skillSourceInfo.icon = petBloodConf.icon
          do
            local departAllList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SKILL_FILTER_CONF):GetAllDatas()
            for i, v in pairs(departAllList) do
              for j, v2 in ipairs(v.filter_enum_value) do
                if v.filter_type == _G.Enum.FilterRule.FIL_SKILLDAM_TYPE and _G.Enum[v.filter_enum_name][v2] == petBloodConf.blood_type then
                  skillSourceInfo.text = v.filter_desc
                  break
                end
              end
            end
          end
        end
        allBagItemList = allBagItemList or _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BAG_ITEM_CONF):GetAllDatas()
        skillSourceInfo.bagItemIds = {}
        for j, bagItemConf in pairs(allBagItemList) do
          if bagItemConf.item_behavior and bagItemConf.item_behavior[1] then
            local itemBehavior = bagItemConf.item_behavior[1]
            if itemBehavior.use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD and itemBehavior.ratio and itemBehavior.ratio[1] == petTargetBlood then
              table.insert(skillSourceInfo.bagItemIds, 1, bagItemConf.id)
              if 2 == #skillSourceInfo.bagItemIds then
                break
              end
            end
            if itemBehavior.use_action == Enum.ItemBehavior.IB_CHANGE_BLOOD_ALL_NATURE then
              table.insert(skillSourceInfo.bagItemIds, bagItemConf.id)
              if 2 == #skillSourceInfo.bagItemIds then
                break
              end
            end
          end
        end
      end
      if skillSourceInfo.type == _G.Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP or skillSourceInfo.bagItemIds and #skillSourceInfo.bagItemIds > 0 then
        skillSourceInfo.skillId = skillId
        skillSourceInfo.petGid = petGid
        skillSourceInfo.petBaseId = petBaseId
        table.insert(SkillSourceInfoList, skillSourceInfo)
      end
    end
    if levelSkillConf.legendary_skill == skillId then
      local skillSourceInfo = {}
      skillSourceInfo.skillId = skillId
      skillSourceInfo.petGid = petGid
      skillSourceInfo.petBaseId = petBaseId
      skillSourceInfo.type = _G.Enum.PetNewSkillSrc.PNSS_LEGENDARY
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(levelSkillConf.legendary_skill_condition, true)
      if petBaseConf then
        skillSourceInfo.text = petBaseConf.name
      end
      table.insert(SkillSourceInfoList, skillSourceInfo)
    end
  end
  return SkillSourceInfoList
end

function PetUIModule:OpenSkillLearningPanel2(...)
  self:OpenPanel("SkillLearning2", ...)
end

function PetUIModule:CloseSkillLearningPanel2()
  local panel = self:GetPanel("SkillLearning2")
  if panel then
    panel:OnClose()
  end
end

function PetUIModule:OnCmdOpenAllDetailedMask(index)
  if self:HasPanel("PetDetailedInfo") then
    local Panel = self:GetPanel("PetDetailedInfo")
    if Panel then
      Panel:OpenAllDetailedMask(index)
    end
  end
end

function PetUIModule:OnCmdCloseAllDetailedTips(Index, IsCloseMaskBtn)
  if self:HasPanel("PetDetailedInfo") then
    local Panel = self:GetPanel("PetDetailedInfo")
    if Panel then
      Panel:CloseAllDetailedTips(Index, IsCloseMaskBtn)
    end
  end
end

function PetUIModule:CalcuSkillLearningNeedItems(skillID, petBaseID, petGid)
  local ItemDosageInfoList, ItemSynthesisInfoList, exchangeID, LearnLevel, skillUnLockInfoList
  local info = self:OnCmdGetPetSkillUnLockInfo(skillID, petBaseID, petGid)
  if info and info[1] then
    ItemDosageInfoList = info[1].ItemDosageInfoList
    ItemSynthesisInfoList = info[1].ItemSynthesisInfoList
    LearnLevel = info[1].LearnLevel
    skillUnLockInfoList = info[1].skillUnLockInfoList
  else
    Log.Debug("PetUIModule SkillUnLockInfo is nil")
    return nil
  end
  if ItemSynthesisInfoList and #ItemSynthesisInfoList > 0 then
    exchangeID = ItemSynthesisInfoList[1].exchangeId
    ItemDosageInfoList = self:OnCmdGetItemDosageBySynthesis(exchangeID)
  end
  return ItemDosageInfoList, exchangeID, LearnLevel, skillUnLockInfoList
end

function PetUIModule:CalcuBloodChangeNeedItems(bloodItemID)
  local ItemDosageInfo, ItemDosageInfoList, ItemSynthesisInfoList, exchangeID
  local bloodItemList = {bloodItemID}
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(bloodItemID)
  if bagItemConf and bagItemConf.item_behavior and bagItemConf.item_behavior[1] then
    if bagItemConf.item_behavior[1].use_action ~= Enum.ItemBehavior.IB_CHANGE_BLOOD_BOSS then
      table.insert(bloodItemList, 102022)
    end
  else
    table.insert(bloodItemList, 102022)
  end
  ItemDosageInfo, ItemSynthesisInfoList = self:OnCmdGetPetSkillUnLockInfoByChangeBlood(bloodItemList)
  ItemDosageInfoList = {ItemDosageInfo}
  if ItemSynthesisInfoList then
    exchangeID = ItemSynthesisInfoList[1].exchangeId
    ItemDosageInfoList = self:OnCmdGetItemDosageBySynthesis(exchangeID)
  end
  return ItemDosageInfoList, exchangeID
end

function PetUIModule:OnCmdGetPetSkillUnLockInfo(skillId, petBaseId, petGid)
  local returnTable = {}
  local skillUnLockInfoList = self:GetSkillSourceAndUnlockInfo(skillId, petBaseId, petGid)
  for i, v in pairs(skillUnLockInfoList) do
    local LearnLevel = tonumber(v.text)
    local ItemDosageInfoList, ItemSynthesisInfoList
    local CanLock = true
    if v.type == Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP then
      ItemDosageInfoList = self:OnCmdGetPetSkillUnLockInfoByLevelUp(LearnLevel, petGid)
      local maxLevel, MaxLevelInfo = PetUtils.GetPetMaxLevel()
      if LearnLevel > maxLevel then
        CanLock = false
      end
    elseif v.type == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK then
      local _ItemDosageInfo, _ItemSynthesisInfoList = self:OnCmdGetPetSkillUnLockInfoBySkillStone(v.bagItemIds[1])
      ItemDosageInfoList = {_ItemDosageInfo}
      ItemSynthesisInfoList = _ItemSynthesisInfoList
    elseif v.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      local _ItemDosageInfo
      _ItemDosageInfo, ItemSynthesisInfoList = self:OnCmdGetPetSkillUnLockInfoByChangeBlood(v.bagItemIds)
      ItemDosageInfoList = {_ItemDosageInfo}
    end
    table.insert(returnTable, {
      type = v.type,
      ItemDosageInfoList = ItemDosageInfoList,
      ItemSynthesisInfoList = ItemSynthesisInfoList,
      LearnLevel = LearnLevel,
      CanLock = CanLock,
      skillUnLockInfoList = skillUnLockInfoList
    })
  end
  return returnTable
end

function PetUIModule:OnCmdCreateItemDosageInfo(bagItemId, itemNum, useNum, type)
  local dosageInfo = {}
  dosageInfo.itemId = bagItemId
  dosageInfo.itemNum = itemNum
  dosageInfo.needNum = useNum or 0
  dosageInfo.itemType = type or _G.Enum.GoodsType.GT_BAGITEM
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
  if bagItem then
    dosageInfo.gid = bagItem.gid
    if not itemNum then
      dosageInfo.itemNum = bagItem.num
    end
  end
  return dosageInfo
end

function PetUIModule:OnCmdGetItemDosageBySynthesis(exchangeId)
  local exChangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
  if exChangeConf then
    local function _GetSortFirstItem(costItem)
      local itemList = {}
      
      local goodsList = costItem.cost_goods_id
      local costType = costItem.cost_goods_type
      local needNum = costItem.cost_goods_num
      for i = 1, #goodsList do
        local num = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, goodsList[i], costType)
        local itemData = self:OnCmdCreateItemDosageInfo(goodsList[i], num, needNum, costType)
        table.insert(itemList, itemData)
      end
      itemList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetSortGoodsList, itemList, costType)
      for i, v in ipairs(itemList) do
        if needNum <= v.itemNum then
          return itemList[i]
        end
      end
      return itemList[1]
    end
    
    local itemDosageInfo = {}
    for i, costItem in ipairs(exChangeConf.cost_item) do
      if #costItem.cost_goods_id > 1 then
        itemDosageInfo[2] = table.deepCopy(_GetSortFirstItem(costItem))
      else
        local num = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, costItem.cost_goods_id[1], costItem.cost_goods_type)
        table.insert(itemDosageInfo, self:OnCmdCreateItemDosageInfo(costItem.cost_goods_id[1], num, costItem.cost_goods_num, costItem.cost_goods_type))
      end
    end
    return itemDosageInfo
  end
  return nil
end

function PetUIModule:OnCmdGetPetSkillUnLockInfoByLevelUp(unLockLevel, petGid)
  local petCurExp = 0
  if petGid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
    if petData then
      petCurExp = petData.exp
    end
  end
  local petLevelConf = _G.DataConfigManager:GetPetLevelConf(unLockLevel - 1)
  local goalNeedExp = petLevelConf and petLevelConf.pet_exp or 0
  local curNeedExp = goalNeedExp - petCurExp
  local bHaveEnoughExp, dosageInfoList, useItemAddExp = self:OnCmdGetUseExpItemDosage(curNeedExp)
  return dosageInfoList
end

function PetUIModule:OnCmdGetPetSkillUnLockInfoBySkillStone(bagItemId)
  local ItemDosageInfo = self:OnCmdCreateItemDosageInfo(bagItemId, nil, 1, nil)
  local ItemSynthesisInfoList
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
  if bagItem and bagItem.num > 0 then
    return ItemDosageInfo, nil
  end
  ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetItemSynthesisInfo, bagItemId)
  return ItemDosageInfo, ItemSynthesisInfoList
end

function PetUIModule:OnCmdGetPetSkillUnLockInfoByChangeBlood(bagItemIDList)
  for i, bagItemId in ipairs(bagItemIDList) do
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
    if bagItem and bagItem.num > 0 then
      return self:OnCmdCreateItemDosageInfo(bagItemId, nil, 1, nil), nil
    end
  end
  for k, bagItemId in ipairs(bagItemIDList) do
    local ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetItemSynthesisInfo, bagItemId)
    if #ItemSynthesisInfoList > 0 then
      return self:OnCmdCreateItemDosageInfo(bagItemId, nil, 1, nil), ItemSynthesisInfoList
    end
  end
  return self:OnCmdCreateItemDosageInfo(bagItemIDList[1], nil, 1, nil), nil
end

function PetUIModule:OnCmdGetUseExpItemDosage(needExp)
  local bHaveEnoughExp = false
  local dosageInfoList = {}
  local useItemAddExp = 0
  local itemList = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetCanFeedItem)
  local haveExp = 0
  for i, v in ipairs(itemList) do
    local itemPetExp = 0
    if v.itemConf.item_behavior then
      for j, item in ipairs(v.itemConf.item_behavior) do
        if item.use_action == Enum.ItemBehavior.IB_ADD_PET_EXP then
          itemPetExp = item.ratio[1] or 0
        end
      end
    end
    local num = v.Item and v.Item.num and v.Item.num or 0
    haveExp = haveExp + num * itemPetExp
    v.itemPetExp = itemPetExp
  end
  table.sort(itemList, function(a, b)
    return a.itemPetExp > b.itemPetExp
  end)
  bHaveEnoughExp = needExp <= haveExp
  if bHaveEnoughExp then
    dosageInfoList, useItemAddExp = self:AddAutomaticallyExpItem(itemList, needExp)
  else
    local poorExp = needExp - haveExp
    local virtualExp = 0
    for i, item in pairs(itemList) do
      local haveNum = item.Item and item.Item.num or 0
      local gid = item.Item and item.Item.gid or nil
      local useNum = 0
      local curNeedExp = poorExp - virtualExp
      if i == #itemList then
        useNum = math.ceil(curNeedExp / item.itemPetExp) + haveNum
      else
        useNum = math.floor(curNeedExp / item.itemPetExp) + haveNum
      end
      if useNum > 0 then
        local dosageInfo = {}
        dosageInfo.itemId = item.itemConf.id
        dosageInfo.needNum = useNum
        dosageInfo.itemNum = haveNum
        dosageInfo.itemType = _G.Enum.GoodsType.GT_BAGITEM
        dosageInfo.gid = gid
        table.insert(dosageInfoList, dosageInfo)
        virtualExp = virtualExp + (useNum - haveNum) * item.itemPetExp
      end
    end
    useItemAddExp = virtualExp
  end
  return bHaveEnoughExp, dosageInfoList, useItemAddExp
end

function PetUIModule:AddAutomaticallyExpItem(itemList, needExp)
  local useInfoList = {}
  local lastDoFloorId = 0
  for i = 1, #itemList do
    local useInfo = self:AutomaticallyExpItemHandle(itemList, needExp, lastDoFloorId)
    table.insert(useInfoList, useInfo)
    lastDoFloorId = useInfo[1]
  end
  table.sort(useInfoList, function(a, b)
    local v1 = needExp > a[3] and 999999999 or a[3] - needExp
    local v2 = needExp > b[3] and 999999999 or b[3] - needExp
    return v1 < v2
  end)
  return useInfoList[1][2], useInfoList[1][3]
end

function PetUIModule:AutomaticallyExpItemHandle(itemList, needExp, lastDoFloorId)
  local curDoFloorId = 0
  local dosageInfoList = {}
  local virtualExp = 0
  for i, item in pairs(itemList) do
    if item.Item then
      local useNum = 0
      local curNeedExp = needExp - virtualExp
      local id = item.Item.id
      if i ~= #itemList and lastDoFloorId < id then
        useNum = math.min(math.floor(curNeedExp / item.itemPetExp), item.Item.num)
        curDoFloorId = id
      else
        useNum = math.min(math.ceil(curNeedExp / item.itemPetExp), item.Item.num)
      end
      if useNum > 0 then
        local dosageInfo = {}
        dosageInfo.itemId = id
        dosageInfo.needNum = useNum
        dosageInfo.itemNum = item.Item.num
        dosageInfo.itemType = _G.Enum.GoodsType.GT_BAGITEM
        dosageInfo.gid = item.Item.gid
        table.insert(dosageInfoList, dosageInfo)
        virtualExp = virtualExp + useNum * item.itemPetExp
      end
    end
  end
  return {
    curDoFloorId,
    dosageInfoList,
    virtualExp
  }
end

function PetUIModule:OnCmdOnSubmitPet(InAction)
  self.PetSubmitAction = InAction
  self.CurIndex = nil
  self.data.PetReportData = nil
  self.data.SpecialPetData = nil
  self.data.SubmitPetReward = 0
  self:OnGetPetReportInfosByPageReq(0)
end

function PetUIModule:OnCmdOpenPetReportParticulars(index, bShowCloseBtn)
  local data = {}
  data.bShowCloseBtn = bShowCloseBtn
  if not bShowCloseBtn and index <= #self.data.SpecialPetData then
    data.petReportData = self.data.SpecialPetData[index]
    data.bFinal = index == #self.data.SpecialPetData
    if index + 1 <= #self.data.SpecialPetData then
      self:PreLoadIcon(self.data.SpecialPetData[index + 1])
    end
  elseif bShowCloseBtn and index <= #self.data.PetReportData then
    data.petReportData = self.data.PetReportData[index]
    self:PreLoadIcon(data.petReportData)
  end
  self:OpenPanel("PetReportParticulars", data)
end

function PetUIModule:OnCmdClosePetReportReminder()
  if self:HasPanel("PetReportReminder") then
    self:ClosePanel("PetReportReminder")
  end
end

function PetUIModule:OnCmdOpenPetReportShare(data)
  local shareBaseId = _G.Enum.ShareButtonType.SBT_PET_REPORT
  local sharePartId = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.GetSharePartIdByShareBaseId, shareBaseId)
  local shareData = {
    shareBaseId = shareBaseId,
    sharePartId = sharePartId,
    reportData = data
  }
  _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenShareUIPanel, shareData)
end

function PetUIModule:OnCmdIsInteger(num)
  if type(num) ~= "number" then
    return false
  end
  local eps = 1.0E-12
  local _, frac = math.modf(num)
  return eps > math.abs(frac)
end

function PetUIModule:ClosePetReportParticulars()
  if self:HasPanel("PetReportParticulars") then
    self:ClosePanel("PetReportParticulars")
  end
end

function PetUIModule:OnCmdStartShowPetReportTips(bSkip)
  if bSkip then
    if self.CurIndex then
      self.CurIndex = nil
      self:ClosePetReportParticulars()
      self:OnCmdOnFinishPetReportReq()
    end
    return
  end
  if self.CurIndex == nil then
    self.CurIndex = 1
  else
    self.CurIndex = self.CurIndex + 1
  end
  if 1 == self.CurIndex then
    self:OnCmdOpenPetReportParticulars(self.CurIndex, false)
  elseif self.CurIndex < #self.data.SpecialPetData then
    self:UpdatePetReportTipsUI(self.data.SpecialPetData[self.CurIndex], false)
    self:PreLoadIcon(self.data.SpecialPetData[self.CurIndex + 1])
  elseif self.CurIndex == #self.data.SpecialPetData then
    self:UpdatePetReportTipsUI(self.data.SpecialPetData[self.CurIndex], true)
  else
    self:OnCmdClosePetReportReminder()
    self:ClosePetReportParticulars()
    self:OnCmdOnFinishPetReportReq()
  end
end

function PetUIModule:OnCmdEndPetSubmitAction()
  if self.PetSubmitAction then
    self.PetSubmitAction:EndAction()
  end
  self.PetSubmitAction = nil
  self.CurIndex = nil
end

function PetUIModule:OnCmdSetPetReportPanelVisibility(bVisible)
  if self:HasPanel("PetReport") then
    local panel = self:GetPanel("PetReport")
    if panel then
      if bVisible then
        panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        panel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function PetUIModule:PreLoadIcon(data)
  local iconPath = self:GetIconPath(data)
  if iconPath then
    NPCLuaUtils.PreLoad(iconPath)
  end
end

function PetUIModule:GetIconPath(data)
  local iconPath
  if data and data.pet_brief and data.pet_brief.gid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(data.pet_brief.gid)
    if petData then
      local base_conf_id = petData.base_conf_id
      local mutation_type = petData.mutation_type
      if base_conf_id then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(base_conf_id)
        if petBaseConf then
          if mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
            iconPath = petBaseConf.JL_shiny_res
          else
            iconPath = petBaseConf.JL_res
          end
        end
      end
    end
  end
  return iconPath
end

function PetUIModule:CheckShowPetReportReminder()
  local bShowReminder = false
  for _, data in pairs(self.data.PetReportData or {}) do
    if data and data.final_ratio then
      local report_title_ratio = _G.DataConfigManager:GetPetGlobalConfig("report_title_ratio").num
      if report_title_ratio and report_title_ratio <= data.final_ratio / 10000 then
        data.bSpecial = true
        bShowReminder = true
        if self.data.SpecialPetData == nil then
          self.data.SpecialPetData = {}
        end
        table.insert(self.data.SpecialPetData, data)
      else
        data.bSpecial = false
      end
    end
  end
  if self.data.SpecialPetData then
    table.sort(self.data.SpecialPetData, function(a, b)
      return a.final_ratio > b.final_ratio
    end)
  end
  if bShowReminder then
    self:PreLoadIcon(self.data.SpecialPetData[1])
    self:OpenPanel("PetReportReminder")
  else
    self:OnCmdOnFinishPetReportReq()
  end
end

function PetUIModule:UpdatePetReportTipsUI(PetReportData, bFinal)
  if self:HasPanel("PetReportParticulars") then
    local panel = self:GetPanel("PetReportParticulars")
    if panel then
      panel:UpdateUI(PetReportData, bFinal)
    end
  end
end

function PetUIModule:OnGetPetReportInfosByPageReq(InPageNum)
  local req = _G.ProtoMessage:newZoneGetPetReportInfosByPageReq()
  req.page_num = InPageNum
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PET_REPORT_INFOS_BY_PAGE_REQ, req, self, self.OnGetPetReportInfosByPageRsp, false, true)
end

function PetUIModule:OnGetPetReportInfosByPageRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local oldPageNum = rsp.req_page
    local totPageNum = rsp.tot_page
    if 0 == oldPageNum then
      self.data.PetReportData = {}
    end
    local len1 = #self.data.PetReportData
    if rsp.pet_report_infos then
      table.move(rsp.pet_report_infos, 1, #rsp.pet_report_infos, len1 + 1, self.data.PetReportData)
    end
    if totPageNum > oldPageNum + 1 then
      local newPageNum = oldPageNum + 1
      self:OnGetPetReportInfosByPageReq(newPageNum)
    else
      self:CheckShowPetReportReminder()
    end
  else
    if rsp.ret_info and 0 ~= rsp.ret_info.ret_code then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code))
    end
    self:OnCmdEndPetSubmitAction()
  end
end

function PetUIModule:OnCmdOnFinishPetReportReq()
  self.oldCoinNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_COIN) or 0
  self.oldBackpackData = _G.DataModelMgr.PlayerDataModel.playerInfo.pet_info.backpack_info
  local req = _G.ProtoMessage:newZoneFinishPetReportReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FINISH_PET_REPORT_REQ, req, self, self.OnFinishPetReportRsp, false, true)
end

function PetUIModule:OnFinishPetReportRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    self.data.SubmitPetReward = rsp.submit_pet_reward
    if rsp.ret_info.goods_change_info then
      for _, item in ipairs(rsp.ret_info.goods_change_info.changes or {}) do
        local tip_succeed = _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_ShowPetChangeToWarehouse, item, _G.ProtoCMD.ZoneSvrCmd.ZONE_FINISH_PET_REPORT_RSP, self.oldBackpackData)
        if tip_succeed and self.PetSubmitAction then
          self.PetSubmitAction.shouldShowTip = true
        end
      end
    end
    self:OpenPetReportPanel()
  else
    self:OnCmdEndPetSubmitAction()
  end
end

function PetUIModule:OnCmdGMSetPetUIScaleAndOffsetAndImageRevert(_IsRevert, _flip, _Scale, _Offset, _CurModifyAxis)
  if self:HasPanel("PetReportParticulars") then
    local panel = self:GetPanel("PetReportParticulars")
    if panel then
      if _IsRevert then
        panel.PetImage:SetPetUIImageRevert(_flip, _Scale)
      else
        panel.PetImage:UpdateUIScaleAndOffset(_flip, _Scale, _Offset, _CurModifyAxis)
      end
    end
  end
end

function PetUIModule:OnCmdGMOpenPetReportParticulars()
  local data = {}
  data.bFinal = true
  data.bShowCloseBtn = true
  data.petReportData = {}
  data.petReportData.bSpecial = false
  self:OpenPanel("PetReportParticulars", data)
end

function PetUIModule:OnCmdGMChangePet(PetID, MutationType, GlassInfo)
  if self:HasPanel("PetReportParticulars") then
    local panel = self:GetPanel("PetReportParticulars")
    if panel then
      panel:SetPetIcon(PetID, MutationType, GlassInfo)
    end
  end
end

function PetUIModule:OnCmdGMChangePetReportBG(bSpecial)
  if self:HasPanel("PetReportParticulars") then
    local panel = self:GetPanel("PetReportParticulars")
    if panel then
      panel:ChangeBG(bSpecial)
    end
  end
end

function PetUIModule:GetPetReportParamInfo()
  return self.data:GetPetReportParamInfo()
end

function PetUIModule:SetPetReportParamInfo(_PetReportParamInfo)
  self.data:SetPetReportParamInfo(_PetReportParamInfo)
end

function PetUIModule:OnCmdShowSubmitFinishTips()
  if self.data.PetReportData and self.data.PetReportData[1] then
    local reportPetNum = #self.data.PetReportData
    local firstPet = self.data.PetReportData[1].pet_brief
    if firstPet and firstPet.name and reportPetNum then
      local Tips = _G.DataConfigManager:GetLocalizationConf("pet_sent_to_warehouse").msg
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(Tips, firstPet.name, reportPetNum), 0, nil, 3)
    end
  end
end

function PetUIModule:GetPetHatchingEnableState()
  if self:HasPanel("PetHatchingPanel") then
    local panel = self:GetPanel("PetHatchingPanel")
    return panel.enableView and panel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and panel:GetVisibility() ~= UE4.ESlateVisibility.Hidden
  end
  return false
end

function PetUIModule:GetPetInfoMainEnableState()
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    if not panel then
      return false
    end
    local petInfoMainEnable = panel and panel.enableView and panel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and panel:GetVisibility() ~= UE4.ESlateVisibility.Hidden
    local topPanel = _G.NRCPanelManager:GetTopVisiblePanel()
    local petLeftPanelVisible = panel:CheckPetLeftPanelVisibleAndShowPetHeadList()
    local bTopPanelIsPetMain = topPanel and "PetInfoMain" == topPanel.panelName
    return petLeftPanelVisible and bTopPanelIsPetMain
  end
  return false
end

function PetUIModule:SetFriendInfoToPetMain(_friendInfo)
  self.data:SetFriendInfoToPetMain(_friendInfo)
end

function PetUIModule:GetFriendInfoToPetMain()
  return self.data:GetFriendInfoToPetMain()
end

function PetUIModule:OnCmdPetWarehouseReadyToClose()
  if self:HasPanel("PetConfirmPanel") then
    local panel = self:GetPanel("PetConfirmPanel")
    if panel then
      panel:PetWarehouseReadyToClose()
    end
  end
end

function PetUIModule:OnCmdGetPetHatchingIsSelected()
  if self:HasPanel("EggIncubatePanel") then
    local panel = self:GetPanel("EggIncubatePanel")
    if panel then
      return panel:GetIsSelectBtn()
    end
  end
  return false
end

function PetUIModule:CalculationSkillNumByType(skillList, petBaseConfId)
  if not skillList or not petBaseConfId then
    return {}
  end
  local skillCountTab = {}
  local departAllList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SKILL_FILTER_CONF):GetAllDatas()
  for i, v in pairs(departAllList) do
    local key1 = v.filter_type
    if not skillCountTab[key1] then
      skillCountTab[key1] = {}
    end
    for j, value in ipairs(v.filter_enum_value) do
      local key2 = _G.Enum[v.filter_enum_name][value]
      if not skillCountTab[key1][key2] then
        skillCountTab[key1][key2] = 0
      end
    end
  end
  for i, skill in pairs(skillList) do
    local skillSourceList = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetSkillSource, skill.id, petBaseConfId)
    for j, v in ipairs(skillSourceList) do
      if skillCountTab[_G.Enum.FilterRule.FIL_SKILL_SOURCE][v] then
        skillCountTab[_G.Enum.FilterRule.FIL_SKILL_SOURCE][v] = skillCountTab[_G.Enum.FilterRule.FIL_SKILL_SOURCE][v] + 1
      end
    end
    local skillConf = _G.DataConfigManager:GetSkillConf(skill.id)
    if skillConf then
      if skillCountTab[_G.Enum.FilterRule.FIL_SKILLDAM_TYPE][skillConf.skill_dam_type] then
        skillCountTab[_G.Enum.FilterRule.FIL_SKILLDAM_TYPE][skillConf.skill_dam_type] = skillCountTab[_G.Enum.FilterRule.FIL_SKILLDAM_TYPE][skillConf.skill_dam_type] + 1
      end
      if skillCountTab[_G.Enum.FilterRule.FIL_SKILL_TYPE][skillConf.Skill_Type] then
        skillCountTab[_G.Enum.FilterRule.FIL_SKILL_TYPE][skillConf.Skill_Type] = skillCountTab[_G.Enum.FilterRule.FIL_SKILL_TYPE][skillConf.Skill_Type] + 1
      end
    end
  end
  return skillCountTab
end

function PetUIModule:OpenSkillOperationPanel(...)
  self:OpenPanel("UMG_ReplacementSkills", ...)
end

function PetUIModule:OnSelectSkillOperationItem(skillId)
  if self:HasPanel("UMG_ReplacementSkills") then
    local panel = self:GetPanel("UMG_ReplacementSkills")
    if panel then
      panel:OnSelectSkillOperationItem(skillId)
    end
  end
end

function PetUIModule:OpenUnlockSkillsPanel(...)
  self:OpenPanel("UMG_UnlockSkills", ...)
end

function PetUIModule:OpenAttributeChangePanel(...)
  self:OpenPanel("UMG_AttributeChange", ...)
end

function PetUIModule:OnGetCard(notify)
  for _, v in ipairs(notify.share_form_item) do
    local conf = _G.DataConfigManager:GetPetShareItemConf(v.id)
    if not conf.is_initial_unlock then
      local info = {
        goods_reward = {
          rewards = {}
        }
      }
      local reward = {}
      info.goods_reward.rewards[1] = reward
      reward.first_get = true
      reward.id = v.id
      reward.num = 1
      reward.reward_reason = _G.ProtoEnum.FlowReason.FLOW_REASON_COLLECT
      reward.tag = ProtoEnum.GoodsDsiplayTag.NARMAL_SHOW
      reward.type = _G.Enum.GoodsType.GT_SHARE_FORM
      if self.certificationGid then
        local pet_data = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.certificationGid)
        if conf.allowed_petbase == pet_data.base_conf_id then
          reward.pet_data = pet_data
          self.certificationGid = nil
        end
      end
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_ProcessRetInfo, ProtoCMD.ZoneSvrCmd.ZONE_SHARE_FORM_NOTIFY, info, false)
    end
  end
end

function PetUIModule:GetPetRestrainAndResistType(petData)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  local _dicTypes = petBaseConf.unit_type
  local petType = {}
  local typeDic
  local ResistTypeList = {}
  local RestainTypeList = {}
  local rests = {}
  for i = 1, 2 do
    if _dicTypes[i] then
      table.insert(petType, _dicTypes[i])
    end
  end
  local AbandonType = {7}
  local extra_sdt = petData.extra_sdt or {}
  for _, v in ipairs(extra_sdt) do
    local typeDicinfo = _G.DataConfigManager:GetTypeDictionary(v.type)
    table.insert(AbandonType, v.type)
    if v.result < 0 then
      table.insert(ResistTypeList, {
        id = 2,
        icon = typeDicinfo.type_icon,
        num = v.type,
        Phase = false,
        isDouble = false,
        typeID = typeDicinfo.id
      })
    elseif v.result > 0 then
      table.insert(RestainTypeList, {
        id = 2,
        icon = typeDicinfo.type_icon,
        num = v.type,
        Phase = true,
        isDouble = false,
        typeID = typeDicinfo.id
      })
    else
      table.insert(rests, {
        id = 0,
        icon = typeDicinfo.type_icon,
        num = v.type,
        isDouble = false,
        typeID = typeDicinfo.id
      })
    end
  end
  local firstTypeRestraints = {}
  typeDic = _G.DataConfigManager:GetTypeDictionary(petType[1])
  for k = 2, 20 do
    if not table.contains(AbandonType, k) then
      local key = "type_restraint" .. typeDic.id
      local typeDicinfo = _G.DataConfigManager:GetTypeDictionary(k)
      local v = typeDicinfo[key]
      firstTypeRestraints[k] = v
      if v then
        if v < 0 then
          table.insert(ResistTypeList, {
            id = 2,
            icon = typeDicinfo.type_icon,
            num = k,
            Phase = false,
            isDouble = false,
            typeID = typeDicinfo.id
          })
        elseif v > 0 then
          table.insert(RestainTypeList, {
            id = 2,
            icon = typeDicinfo.type_icon,
            num = k,
            Phase = true,
            isDouble = false,
            typeID = typeDicinfo.id
          })
        else
          table.insert(rests, {
            id = 0,
            icon = typeDicinfo.type_icon,
            num = k,
            isDouble = false,
            typeID = typeDicinfo.id
          })
        end
      end
    end
  end
  if 2 == #petType then
    typeDic = _G.DataConfigManager:GetTypeDictionary(petType[2])
    local secondTypeRestraints = {}
    for k = 2, 20 do
      if not table.contains(AbandonType, k) then
        local typeDicinfo = _G.DataConfigManager:GetTypeDictionary(k)
        local key = "type_restraint" .. typeDic.id
        local v = typeDicinfo[key]
        secondTypeRestraints[k] = v
      end
    end
    for k = 2, 20 do
      if not table.contains(AbandonType, k) then
        local v1 = firstTypeRestraints[k]
        local v2 = secondTypeRestraints[k]
        local typeDicinfo = _G.DataConfigManager:GetTypeDictionary(k)
        local isDouble = false
        if v1 and v2 then
          if v1 > 0 and v2 > 0 then
            isDouble = true
          elseif v1 < 0 and v2 < 0 then
            isDouble = true
          end
        end
        if v2 then
          if v2 < 0 then
            local propertyplus = false
            for n, m in ipairs(ResistTypeList) do
              if k == m.num then
                propertyplus = true
                ResistTypeList[n].id = 4
                ResistTypeList[n].isDouble = isDouble
              end
            end
            if false == propertyplus then
              table.insert(ResistTypeList, {
                id = 2,
                icon = typeDicinfo.type_icon,
                num = k,
                Phase = false,
                isDouble = isDouble,
                typeID = typeDicinfo.id
              })
            end
          elseif v2 > 0 then
            local propertyplus1 = false
            for n, m in ipairs(RestainTypeList) do
              if k == m.num then
                propertyplus1 = true
                RestainTypeList[n].id = 4
                RestainTypeList[n].isDouble = isDouble
              end
            end
            if false == propertyplus1 then
              table.insert(RestainTypeList, {
                id = 2,
                icon = typeDicinfo.type_icon,
                num = k,
                Phase = true,
                isDouble = isDouble,
                typeID = typeDicinfo.id
              })
            end
          end
        end
      end
    end
    local needRemoveResistType = {}
    local needRemoveRestainType = {}
    for Pinnedi, Pinnedj in ipairs(ResistTypeList) do
      for resisti, resistj in ipairs(RestainTypeList) do
        if Pinnedj.num == resistj.num then
          table.insert(needRemoveResistType, Pinnedj.num)
          table.insert(needRemoveRestainType, resistj.num)
        end
      end
    end
    local number = #ResistTypeList
    for _, v in ipairs(needRemoveResistType) do
      for i = 1, number do
        if ResistTypeList[i] and ResistTypeList[i].num == v then
          table.remove(ResistTypeList, i)
        end
      end
    end
    number = #RestainTypeList
    for _, v in ipairs(needRemoveRestainType) do
      for i = 1, number do
        if RestainTypeList[i] and RestainTypeList[i].num == v then
          table.remove(RestainTypeList, i)
        end
      end
    end
    for Pinnedi, Pinnedj in ipairs(ResistTypeList) do
      for restsi, restsj in ipairs(rests) do
        if Pinnedj.num == restsj.num then
          table.remove(rests, restsi)
        end
      end
    end
    for resisti, resistj in ipairs(RestainTypeList) do
      for restsi, restsj in ipairs(rests) do
        if resistj.num == restsj.num then
          table.remove(rests, restsi)
        end
      end
    end
  end
  table.sort(ResistTypeList, function(a, b)
    if a.isDouble ~= b.isDouble then
      return a.isDouble
    else
      return a.typeID < b.typeID
    end
  end)
  table.sort(RestainTypeList, function(a, b)
    if a.isDouble ~= b.isDouble then
      return a.isDouble
    else
      return a.typeID < b.typeID
    end
  end)
  return RestainTypeList, ResistTypeList
end

function PetUIModule:RefreshEditorPetTeamCache(teamType, selTeamIdx)
  self.data:RefreshEditorPetTeamCache(teamType, selTeamIdx)
end

function PetUIModule:CheckIsAnyUmgIsOpening()
  if self.moduleOpeningPanelLst and #self.moduleOpeningPanelLst > 0 then
    return true
  end
  return false
end

function PetUIModule:GetPvpTeamPetEquipSkillMapByPetGid(petGid)
  local teamInfo = self:GetPetTeamUITeamInfo(self.data.teamType)
  if teamInfo and self.data.selTeamIdx then
    local team = teamInfo.teams[self.data.selTeamIdx + 1]
    if team and team.pet_infos then
      for _, petInfo in pairs(team.pet_infos) do
        if petInfo.pet_gid == petGid then
          if petInfo.equip_infos then
            do
              local skillList = {}
              for _, skillInfo in pairs(petInfo.equip_infos) do
                skillList[skillInfo.pos] = skillInfo.id
              end
              return skillList
            end
            break
          end
          break
        end
      end
    end
  end
  local teamParam = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPvpTeamParam)
  if teamParam and teamParam.PetGid == petGid then
    local PvpSkillMap = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPvpSkillData)
    if PvpSkillMap then
      local skillList = {}
      for id, pos in pairs(PvpSkillMap) do
        skillList[pos] = id
      end
      if #skillList > 0 then
        return skillList
      end
    end
  end
  return nil
end

function PetUIModule:GetEnterPetPanelType()
  return self.data:GetEnterPetPanelType()
end

function PetUIModule:OnCmdGetPetCurEquipSkillType(petGid, ignoreType)
  if self:GetAssumptionEquipSkill(petGid) and (not ignoreType or ignoreType ~= PetUIModuleEnum.PetEquipSkillType.Assumption) then
    return PetUIModuleEnum.PetEquipSkillType.Assumption
  end
  if self:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.WeeklyChallengeBattle and (not ignoreType or ignoreType ~= PetUIModuleEnum.PetEquipSkillType.StarlightDuel) then
    return PetUIModuleEnum.PetEquipSkillType.StarlightDuel
  end
  if self:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.HerbologyBadge and (not ignoreType or ignoreType ~= PetUIModuleEnum.PetEquipSkillType.HerbologyBadge) then
    return PetUIModuleEnum.PetEquipSkillType.HerbologyBadge
  end
  if self:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.PvpPetTeamUmg and (not ignoreType or ignoreType ~= PetUIModuleEnum.PetEquipSkillType.PvpTeam) then
    return PetUIModuleEnum.PetEquipSkillType.PvpTeam
  end
  return PetUIModuleEnum.PetEquipSkillType.PetBag
end

function PetUIModule:OnCmdGetPetEquipSkillMap(petGid, dataType, customizationPetData)
  if customizationPetData then
    return self:GetPetEquipByPetData(petGid, customizationPetData), dataType
  end
  local skillMap = {}
  local _dataType = dataType or self:OnCmdGetPetCurEquipSkillType(petGid)
  if _dataType == PetUIModuleEnum.PetEquipSkillType.PetBag then
    return self:GetPetEquipByPetData(petGid)
  elseif _dataType == PetUIModuleEnum.PetEquipSkillType.PvpTeam then
    skillMap = self:GetPvpTeamPetEquipSkillMapByPetGid(petGid)
  elseif _dataType == PetUIModuleEnum.PetEquipSkillType.Assumption then
    skillMap = self:GetAssumptionEquipSkill(petGid)
  elseif _dataType == PetUIModuleEnum.PetEquipSkillType.StarlightDuel then
    skillMap = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetResetSkillByGid, petGid)
  elseif _dataType == PetUIModuleEnum.PetEquipSkillType.HerbologyBadge then
    skillMap = _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.GetHerbologyPetSkillMapByGid, petGid)
  end
  return skillMap or {}, _dataType
end

function PetUIModule:OnCmdAutoCheckEnvironmentEquipPetSkill(petGid, posToIdDic, customizationEquipType)
  local _customizationEquipType = customizationEquipType and customizationEquipType or self:OnCmdGetPetCurEquipSkillType(petGid)
  if _customizationEquipType == PetUIModuleEnum.PetEquipSkillType.PetBag then
    self:OnCmdEquipSkill2(petGid, posToIdDic)
  elseif _customizationEquipType == PetUIModuleEnum.PetEquipSkillType.PvpTeam then
    self:EquipPetSkillToPvpTeam(posToIdDic)
  elseif _customizationEquipType == PetUIModuleEnum.PetEquipSkillType.Assumption then
    self:SetAssumptionEquipSkill(petGid, posToIdDic)
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnEquipAssumptionSkill)
  elseif _customizationEquipType == PetUIModuleEnum.PetEquipSkillType.StarlightDuel then
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.EquipPetSkills, petGid, posToIdDic)
  elseif _customizationEquipType == PetUIModuleEnum.PetEquipSkillType.HerbologyBadge then
    _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.SetHerbologyPetSkill, petGid, posToIdDic)
  end
  return _customizationEquipType
end

function PetUIModule:EquipPetSkillToPvpTeam(posToIdDic)
  local teamParam = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPvpTeamParam)
  if not teamParam then
    return
  end
  local IdToPosDic = {}
  for pos, skillId in pairs(posToIdDic) do
    IdToPosDic[skillId] = pos
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPvpSkillData, IdToPosDic, teamParam)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PvpEquipSkillsByTeamType, teamParam.TeamIdx, teamParam.TeamType, teamParam.PetGid, posToIdDic)
end

function PetUIModule:GetPetEquipByPetData(petGid, petData)
  local skillMap = {}
  local _petData = petData and petData or _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if _petData and _petData.skill and _petData.skill.skill_data then
    for i, v in ipairs(_petData.skill.skill_data) do
      if v.is_equipped and v.pos > 0 and v.pos < 5 then
        skillMap[v.pos] = v.id
      end
    end
  end
  return skillMap
end

function PetUIModule:GetAssumptionEquipSkill(petGid)
  local _posToIdDic = self.data:GetAssumptionEquipSkill(petGid)
  local posToIdDic, IdToPosDic
  if _posToIdDic then
    posToIdDic = {}
    IdToPosDic = {}
    for i, v in pairs(_posToIdDic) do
      posToIdDic[i] = v
      IdToPosDic[v] = i
    end
  end
  return posToIdDic, IdToPosDic
end

function PetUIModule:SetAssumptionEquipSkill(petGid, posToIdDic, ...)
  local bChange = self.data:SetAssumptionEquipSkill(petGid, posToIdDic)
  if bChange and posToIdDic then
    local IdToPosDic = {}
    for i, v in pairs(posToIdDic) do
      IdToPosDic[v] = i
    end
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnPetAssumptionEquipSkillChange, posToIdDic, IdToPosDic, ...)
  end
end

function PetUIModule:OnCmdPetRightPanelIsOpen()
  return self:HasPanel("PetRightPanel")
end

function PetUIModule:OnCmdIsPetInCurrentWeek(timeStamp)
  local week_start = self:_GetWeekStart()
  local week_end = week_start + 604800
  return timeStamp >= week_start and timeStamp < week_end
end

function PetUIModule:OnCmdIsPetCaughtToday(timeStamp)
  local start_ts = self:_GetDayStart()
  local end_ts = start_ts + 86400
  return timeStamp >= start_ts and timeStamp < end_ts
end

function PetUIModule:_GetWeekStart()
  local curTimeStamp = os.time()
  local now_t = os.date("*t", curTimeStamp)
  local w = tonumber(os.date("%w", curTimeStamp))
  if 0 == w then
    w = 7
  end
  local diff = w - 1
  now_t.day = now_t.day - diff
  now_t.hour = 4
  now_t.min = 0
  now_t.sec = 0
  return os.time(now_t)
end

function PetUIModule:_GetDayStart()
  local curTimeStamp = os.time()
  local day_start_hour = 4
  local t = os.date("*t", curTimeStamp)
  local start_tbl = {
    year = t.year,
    month = t.month,
    day = t.day,
    hour = day_start_hour,
    min = 0,
    sec = 0
  }
  local start_ts = os.time(start_tbl)
  if curTimeStamp < start_ts then
    start_tbl.day = start_tbl.day - 1
    start_ts = os.time(start_tbl)
  end
  return start_ts
end

function PetUIModule:OpenPetEvoResultPanel(arg)
  self:OpenPanel("PetEvoResult", arg)
end

function PetUIModule:ClosePetEvoOnlyPanel()
  self:ClosePanel("PetEvoOnly")
end

function PetUIModule:OpenPetEvoOnlyPanel(arg)
  self:OpenPanel("PetEvoOnly", arg)
end

function PetUIModule:OpenTrialPVPPet()
  self:OpenPanel("TrialPVPPet")
end

function PetUIModule:OnCmdGetBalancedPetDataForPvp(petGuid)
  local data = self.data
  local BalancedPetDataForPvpMap = data and data.BalancedPetDataForPvpMap
  local petData = BalancedPetDataForPvpMap and BalancedPetDataForPvpMap[petGuid]
  return petData
end

function PetUIModule:OnCmdInvalidateBalancedPetDataForPvp(petGuid)
  local data = self.data
  local BalancedPetDataForPvpMap = data and data.BalancedPetDataForPvpMap
  if BalancedPetDataForPvpMap and petGuid then
    BalancedPetDataForPvpMap[petGuid] = nil
  end
end

function PetUIModule:OnCmdQueryBalancedPetDataForPvp(petGuidList)
  local data = self.data
  local PetGidListThatWaitingForQueryBalanceData = data and data.PetGidListThatWaitingForQueryBalanceData or {}
  local BalancedPetDataForPvpMap = data and data.BalancedPetDataForPvpMap or {}
  for i, petGid in ipairs(petGuidList) do
    local isInMap = nil ~= BalancedPetDataForPvpMap[petGid]
    local isInWaitingList = table.contains(PetGidListThatWaitingForQueryBalanceData, petGid)
    if not isInMap and not isInWaitingList then
      table.insert(PetGidListThatWaitingForQueryBalanceData, petGid)
    end
  end
  self:TryQueryBalancePetDataInWaitingQueryList()
end

function PetUIModule:TryQueryBalancePetDataInWaitingQueryList()
  local data = self.data
  local isQueryingBalancePetData = data and data.isQueryingBalancePetData
  if isQueryingBalancePetData then
    Log.Info("PetUIModule:TryQueryBalancePetDataInWaitingQueryList \230\173\163\229\156\168\231\173\137\229\190\133\228\184\138\228\184\128\230\172\161\230\159\165\232\175\162\232\191\148\229\155\158")
    return
  end
  local queryBatchSize = 10
  local PetGidListThatWaitingForQueryBalanceData = data and data.PetGidListThatWaitingForQueryBalanceData or {}
  local NextPetGidListThatWaitingForQueryBalanceData = {}
  for i = queryBatchSize + 1, #PetGidListThatWaitingForQueryBalanceData do
    local gid = PetGidListThatWaitingForQueryBalanceData[i]
    PetGidListThatWaitingForQueryBalanceData[i] = nil
    table.insert(NextPetGidListThatWaitingForQueryBalanceData, gid)
  end
  if data then
    data.PetGidListThatWaitingForQueryBalanceData = NextPetGidListThatWaitingForQueryBalanceData
  end
  if 0 == #PetGidListThatWaitingForQueryBalanceData then
    return
  end
  local req = _G.ProtoMessage:newZoneQueryPetBalancedAttrReq()
  req.gid = PetGidListThatWaitingForQueryBalanceData
  local queryPetBalancedAttrTimeoutId = data and data.queryPetBalancedAttrTimeoutId
  if queryPetBalancedAttrTimeoutId then
    _G.DelayManager:CancelDelayById(queryPetBalancedAttrTimeoutId)
  end
  local queryPetBalancedAttrTimeoutTime = 5
  queryPetBalancedAttrTimeoutId = _G.DelayManager:DelaySeconds(queryPetBalancedAttrTimeoutTime, function()
    Log.Error("PetUIModule:TryQueryBalancePetDataInWaitingQueryList ZoneQueryPetBalancedAttrReq Timeout")
    if data then
      data.isQueryingBalancePetData = false
    end
  end)
  if data then
    data.queryPetBalancedAttrTimeoutId = queryPetBalancedAttrTimeoutId
    data.isQueryingBalancePetData = true
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PET_BALANCED_ATTR_REQ, req, self, self.OnZoneQueryPetBalancedAttrRsp)
end

function PetUIModule:OnZoneQueryPetBalancedAttrRsp(rsp)
  local data = self.data
  local queryPetBalancedAttrTimeoutId = data and data.queryPetBalancedAttrTimeoutId
  if queryPetBalancedAttrTimeoutId then
    _G.DelayManager:CancelDelayById(queryPetBalancedAttrTimeoutId)
  end
  if data then
    data.isQueryingBalancePetData = false
    data.queryPetBalancedAttrTimeoutId = nil
  end
  local retInfo = rsp and rsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if 0 ~= retCode then
    local retMessage = retInfo and retInfo.ret_msg
    Log.Error("PetUIModule:OnZoneQueryPetBalancedAttrRsp", retCode, retMessage)
    return
  end
  local balancePetDataList = rsp and rsp.pet_data or {}
  local balancePetDataListString = ""
  for i, petData in ipairs(balancePetDataList) do
    local petGid = petData and petData.gid
    balancePetDataListString = balancePetDataListString .. " " .. tostring(petGid)
  end
  local PetGidListThatWaitingForQueryBalanceData = data and data.PetGidListThatWaitingForQueryBalanceData or {}
  Log.Info("PetUIModule:OnZoneQueryPetBalancedAttrRsp \229\183\178\230\159\165\232\175\162\229\136\176\229\185\179\232\161\161\230\149\176\230\141\174 ", #balancePetDataList, "\233\161\185 ", balancePetDataListString, "\229\137\169\228\189\153", #PetGidListThatWaitingForQueryBalanceData, "\233\161\185\231\173\137\229\190\133\230\159\165\232\175\162")
  self:AddBalancedPetDataForPvpRsp(balancePetDataList)
  self:TryQueryBalancePetDataInWaitingQueryList()
end

function PetUIModule:AddBalancedPetDataForPvpRsp(petDataList)
  local data = self.data
  local BalancedPetDataForPvpMap = data and data.BalancedPetDataForPvpMap or {}
  for i, petData in ipairs(petDataList) do
    local petGuid = petData and petData.gid
    if petGuid then
      BalancedPetDataForPvpMap[petGuid] = petData
    end
  end
  self:DispatchEvent(PetUIModuleEvent.OnBalancePetDataForPvpUpdate, petDataList)
end

function PetUIModule:OnCmdOpenLeaderItemPanel()
  self:ClosePanel("PetBloodlineMagic")
  local ResListData = PetUtils.GetDefaultPetImage3DResListData()
  self:OpenPanel("LeaderItemPanel", ResListData)
  self:OpenOrCloseLeaderItemPanel(true)
  self:HideRightPanel()
end

function PetUIModule:OpenOrCloseLeaderItemPanel(Open)
  if not Open then
    self:ShowRightPanel()
  end
  if self:HasPanel("PetInfoMain") then
    local Panel = self:GetPanel("PetInfoMain")
    if Panel then
      Panel:OpenLeaderItemPanel(Open)
    end
  end
end

function PetUIModule:ClosePetLeaderAttribute()
  if self:HasPanel("LeaderItemPanel") then
    local Panel = self:GetPanel("LeaderItemPanel")
    if Panel then
      Panel:ClosePanel()
    end
  end
  self:OpenOrCloseLeaderItemPanel(false)
  if self:HasPanel("PetInfoMain") then
    local Panel = self:GetPanel("PetInfoMain")
    if Panel then
      Panel:SelectPetInfoMainPet()
    end
  end
end

function PetUIModule:OnCmdSelectLeaderItem(LeaderItem)
  self.data:SetSelectLeaderItem(LeaderItem)
  self:DispatchEvent(PetUIModuleEvent.SelectLeaderItemEvent, LeaderItem)
end

function PetUIModule:OnCmdOpenPetLeaderAttribute()
  self:OpenPanel("PetLeader_Attribute")
end

function PetUIModule:OnCmdClosePetLeaderAttribute()
  self:ClosePanel("PetLeader_Attribute")
end

function PetUIModule:OpenPetTraceBackPopup(petGid)
  Log.Debug("PetUIModule:OpenPetTraceBackPopup")
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if not petData then
    return
  end
  if PetUtils.CheckPetIsCanTraceBack(petData, false, false, true) then
    if self:HasPanel("PetTraceBackPopup") then
      local Panel = self:GetPanel("PetTraceBackPopup")
      if Panel then
        Panel:OnActive(petGid)
        return
      end
    end
    self:OpenPanel("PetTraceBackPopup", petGid)
  end
end

function PetUIModule:UpdatePetTraceBackPopup(petGid, traceBackShowInfo, reward_list)
  if self:HasPanel("PetTraceBackPopup") then
    local Panel = self:GetPanel("PetTraceBackPopup")
    if Panel then
      Panel:ReceiveRspData(petGid, traceBackShowInfo, reward_list)
      return
    end
  end
end

function PetUIModule:ClosePetTraceBackPopup()
  self:ClosePanel("PetTraceBackPopup")
end

function PetUIModule:OpenNewPetBagPanel()
  self:OpenPanel("NewPetBag")
end

function PetUIModule:CloseNewPetBagPanel()
  if self:HasPanel("NewPetBag") then
    local panel = self:GetPanel("NewPetBag")
    if panel then
    end
    if panel then
      panel:ClosePanel()
    end
    return true
  end
  return false
end

function PetUIModule:OnCmdRealOpenNewPetBagBoxPanel()
  self:OpenPanel("NewPetBagBox")
  self:SetNewPetBagBoxPanelOpenState(false)
end

function PetUIModule:OpenNewPetBagBoxPanel()
  if self:HasPanel("NewPetBagBox") then
    local panel = self:GetPanel("NewPetBagBox")
    if panel then
      self:SetNewPetBagBoxPanelOpenState(true)
      self:OnSavePetBagChildrenPanelState("Box", true)
      panel:Enable()
    end
  end
end

function PetUIModule:CloseNewPetBagBoxPanel(bRealClose)
  if self:HasPanel("NewPetBagBox") then
    local panel = self:GetPanel("NewPetBagBox")
    if panel then
      if not bRealClose then
        panel:HidePanel()
      else
        panel:DoClose()
      end
      self:SetNewPetBagBoxPanelOpenState(false)
      self:OnSavePetBagChildrenPanelState("Box", false)
      self:DispatchEvent(PetUIModuleEvent.OnNewPetBagRightPanelClose, "NewPetBagBox")
      self:DispatchEvent(PetUIModuleEvent.OnUpdatePetBagEmptyView)
    end
  end
end

function PetUIModule:SetNewPetBagBoxPanelOpenState(bOpen)
  self.bNewPetBagBoxPanelOpen = bOpen
end

function PetUIModule:GetNewPetBagBoxPanelOpenState()
  return self.bNewPetBagBoxPanelOpen
end

function PetUIModule:OpenNewPetBagScreenSearchPanel()
  self:OpenPanel("NewPetBagScreenSearch")
end

function PetUIModule:OpenNewPetBagWarehouseScreeningPanel()
  self:OpenPanel("NewPetBagWarehouseScreening")
end

function PetUIModule:SetNewPetBagWarehouseScreeningPanelOpenState(bOpen)
  self.bNewPetBagWarehouseScreeningPanelOpen = bOpen
end

function PetUIModule:GetNewPetBagWarehouseScreeningPanelOpenState()
  return self.bNewPetBagWarehouseScreeningPanelOpen
end

function PetUIModule:OpenNetPetBagMarkWarehousePanel(box_data)
  self:OpenPanel("NetPetBagMarkWarehouse", box_data)
end

function PetUIModule:OnCmdOpenPurchaseBoxPanel(data)
  self:OpenPanel("PurchaseBox", data)
end

function PetUIModule:OnCmdGetUnlockBoxRuleGroupList(box_id)
  local ruleGroupList = {}
  local warehouseConf = _G.DataConfigManager:GetPetWarehouseConf(box_id)
  if warehouseConf then
    local rules = warehouseConf.unlock_rule
    for _, rule in pairs(rules or {}) do
      local checkPass = false
      if rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_EXPEND_MONEY then
        local coinNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(rule.unlock_id) or 0
        if coinNum >= rule.value then
          checkPass = true
        end
      elseif rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_RECORD_PET then
        local collectedPetsNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetHandbookCollectedPetsNum)
        if collectedPetsNum >= rule.value then
          checkPass = true
        end
      elseif rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_USE_BAGITEM then
        do
          local item = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, rule.unlock_id)
          if item then
            local itemNum = item.num or 0
            if itemNum >= rule.value then
              checkPass = true
            end
          end
        end
      end
      for _, groupId in pairs(rule.group_id) do
        if not ruleGroupList[groupId] then
          ruleGroupList[groupId] = {}
        end
        local ruleInfo = {rule = rule, checkPass = checkPass}
        table.insert(ruleGroupList[groupId], ruleInfo)
      end
    end
  end
  return ruleGroupList
end

function PetUIModule:OnCmdSelectUnlockBoxItem(_index, uiData)
  if self:HasPanel("PurchaseBox") then
    local panel = self:GetPanel("PurchaseBox")
    panel:SelectUnlockBoxItem(_index, uiData)
  end
end

function PetUIModule:OnCmdOpenPetBoxPanelFromBag()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, nil, nil, nil, true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetBag, true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetBoxPanelOpenState, true)
end

function PetUIModule:OnCmdSetPetBoxPanelOpenState(bOpenState)
  self.data.bOpenPetBoxPanel = bOpenState
end

function PetUIModule:OnCmdGetPetBoxPanelOpenState()
  return self.data.bOpenPetBoxPanel
end

function PetUIModule:OnCmdZonePetBoxLastOpenBoxReq(box_id)
  local req = _G.ProtoMessage:newZonePetBoxLastOpenBoxReq()
  req.box_id = box_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_BOX_LAST_OPEN_BOX_REQ, req, self, self.OnZonePetBoxLastOpenBoxRsp)
end

function PetUIModule:OnZonePetBoxLastOpenBoxRsp(rsp)
  local retInfo = rsp and rsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if 0 ~= retCode then
    Log.Error("PetUIModule:OnZonePetBoxLastOpenBoxRsp", retCode)
    return
  end
  Log.Debug("\232\174\176\229\189\149\230\136\144\229\138\159")
end

function PetUIModule:OnCmdZonePetBoxUnlockReq(box_id, unlock_group)
  local req = _G.ProtoMessage:newZonePetBoxUnlockReq()
  req.box_id = box_id
  req.unlock_group = unlock_group
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_BOX_UNLOCK_REQ, req, self, self.OnZonePetBoxUnlockRsp)
end

function PetUIModule:OnZonePetBoxUnlockRsp(rsp)
  local retInfo = rsp and rsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if 0 ~= retCode then
    self:DispatchEvent(PetUIModuleEvent.OnPetBoxUpdate)
    Log.Error("PetUIModule:OnZonePetBoxUnlockRsp", retCode)
    return
  elseif rsp.box_info then
    _G.DataModelMgr.PlayerDataModel:OnUpdatePetWarehouseBoxInfo(rsp.box_info)
    if rsp.box_info.box_id then
      self:DispatchEvent(PetUIModuleEvent.OnPetBoxUpdate, rsp.box_info.box_id)
    end
  end
end

function PetUIModule:OnCmdZonePetBoxChangePetReq(ori_info, tar_info)
  local req = _G.ProtoMessage:newZonePetBoxChangePetReq()
  req.ori_info = ori_info
  req.tar_info = tar_info
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_BOX_CHANGE_PET_REQ, req, self, self.OnZonePetBoxChangePetRsp)
end

function PetUIModule:OnZonePetBoxChangePetRsp(rsp)
  local retInfo = rsp and rsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if 0 ~= retCode then
    Log.Error("PetUIModule:OnZonePetBoxChangePetRsp", retCode)
    self:DispatchEvent(PetUIModuleEvent.OnExchangePetFail)
    return
  elseif rsp and rsp.ret_info and rsp.ret_info.goods_change_info and rsp.ret_info.goods_change_info.changes then
    for _, change in pairs(rsp.ret_info.goods_change_info.changes) do
      if change.team_info then
        _G.DataModelMgr.PlayerDataModel:UpdatePlayerPetTeamInfoByTeamType(_G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD, change.team_info)
        self:DispatchEvent(PetUIModuleEvent.OnBigWorldTeamPetChangeEvent)
        break
      end
    end
    self:UpdateCachePetBelongBoxMap()
  end
end

function PetUIModule:OnCmdZonePetBoxSwapReq(box_ids)
  if box_ids then
    local CurSelectItemType = self:GetCurSelectItemTypeInPortableBag()
    local CurSelectBoxID, CurSelectItemIndex = self:GetCurSelectInfoInPortableBag()
    if CurSelectItemType and CurSelectBoxID and CurSelectItemIndex and CurSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.PageItem then
      for i, box_id in pairs(box_ids) do
        if box_id == CurSelectBoxID then
          self.NewSelectBoxIDInPortableBag = i
          break
        end
      end
    end
    local req = _G.ProtoMessage:newZonePetBoxSettingUpReq()
    req.box_ids = box_ids
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_BOX_SETTING_UP_REQ, req, self, self.OnZonePetBoxSettingUpRsp)
  end
end

function PetUIModule:OnZonePetBoxSettingUpRsp(rsp)
  local retInfo = rsp and rsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if 0 ~= retCode then
    Log.Error("PetUIModule:OnZonePetBoxSettingUpRsp", retCode)
    self.NewSelectBoxIDInPortableBag = nil
    return
  elseif rsp.box_info then
    local CurSelectItemType = self:GetCurSelectItemTypeInPortableBag()
    local CurSelectBoxID, CurSelectItemIndex = self:GetCurSelectInfoInPortableBag()
    if CurSelectItemType and CurSelectBoxID and CurSelectItemIndex and CurSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.PageItem and self.NewSelectBoxIDInPortableBag ~= nil and self.NewSelectBoxIDInPortableBag ~= CurSelectBoxID then
      self:SetCurSelectInfoInPortableBag(self.NewSelectBoxIDInPortableBag, CurSelectItemIndex)
    end
    self.NewSelectBoxIDInPortableBag = nil
    for _, box_info in pairs(rsp.box_info) do
      _G.DataModelMgr.PlayerDataModel:OnUpdatePetWarehouseBoxInfo(box_info)
    end
    self:UpdateCachePetBelongBoxMap()
    self:DispatchEvent(PetUIModuleEvent.OnPetBoxUpdate)
  end
end

function PetUIModule:OnCmdZonePetBoxSetMarkTypeReq(box_id, mark_type, box_name, lock)
  local req = _G.ProtoMessage:newZonePetBoxSetMarkTypeReq()
  req.box_id = box_id
  req.mark_type = mark_type
  req.box_name = box_name
  req.lock = lock
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_BOX_SET_MARK_TYPE_REQ, req, self, self.OnZonePetBoxSetMarkTypeRsp)
end

function PetUIModule:OnZonePetBoxSetMarkTypeRsp(rsp)
  local retInfo = rsp and rsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if 0 ~= retCode then
    Log.Error("PetUIModule:OnZonePetBoxSetMarkTypeRsp", retCode)
  elseif 0 == retCode and rsp.box_id and rsp.mark_type and rsp.box_name then
    self:UpdateBoxMark(rsp.box_id, rsp.mark_type, rsp.box_name, rsp.lock)
    self:DispatchEvent(PetUIModuleEvent.OnPetBoxMarkChange, rsp.box_id, rsp.mark_type, rsp.box_name, rsp.lock)
  end
end

function PetUIModule:OnPetBoxChange(GoodsChange, CmdId)
  Log.Debug("PetUIModule:OnPetBoxChange cmdid", CmdId)
  if GoodsChange and GoodsChange.box_pet_change then
    local change = GoodsChange.box_pet_change
    self:SetBoxPets(change)
    self:UpdateCachePetBelongBoxMap()
    self:DispatchEvent(PetUIModuleEvent.OnPetBoxChangeNotifyEvent)
  end
end

function PetUIModule:OnPetBoxInfoChange(GoodsChange, CmdId)
  Log.Debug("PetUIModule:OnPetBoxInfoChang cmdid", CmdId)
  if GoodsChange and GoodsChange.box_info then
    local box_info = GoodsChange.box_info
    _G.DataModelMgr.PlayerDataModel:OnUpdatePetWarehouseBoxInfo(box_info)
    self:UpdateCachePetBelongBoxMap()
    self:DispatchEvent(PetUIModuleEvent.OnPetBoxUpdate)
  end
end

function PetUIModule:OnPetBoxChangeNotify(nty)
  if nty and nty.change_infos then
    local changes = nty.change_infos
    for _, change in pairs(changes) do
      self:SetBoxPets(change)
    end
    self:UpdateCachePetBelongBoxMap()
    self.delayUpdateBox = _G.DelayManager:DelayFrames(1, function()
      self:DispatchEvent(PetUIModuleEvent.OnPetBoxChangeNotifyEvent)
    end)
  end
end

function PetUIModule:OnPetBoxInfoChangeNotify(nty)
  if nty and nty.box_info then
    for _, box_info in pairs(nty.box_info) do
      _G.DataModelMgr.PlayerDataModel:OnUpdatePetWarehouseBoxInfo(box_info)
    end
    self:UpdateCachePetBelongBoxMap()
    self:DispatchEvent(PetUIModuleEvent.OnPetBoxUpdate)
  end
end

function PetUIModule:OnPetBoxMarkTypeUnlockNotify(nty)
  if nty and nty.mark_type then
    local petinfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
    if petinfo and petinfo.backpack_info then
      petinfo.backpack_info.mark_unlock_info = nty.mark_type
    end
  end
end

function PetUIModule:OnCmdZonePetBoxTidyReq(curBoxIndex, tidyType)
  local req = _G.ProtoMessage:newZonePetBoxTidyReq()
  if req then
    req.last_open_box_id = curBoxIndex
    req.tidy_rules = {tidyType}
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_BOX_TIDY_REQ, req, self, self.OnZonePetBoxTidyRsp)
  end
end

function PetUIModule:OnZonePetBoxTidyRsp(rsp)
  local retInfo = rsp and rsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if 0 ~= retCode then
    Log.Error("PetUIModule:OnZonePetBoxTidyRsp", retCode)
  elseif 0 == retCode then
    local petInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
    if petInfo and petInfo.backpack_info then
      petInfo.backpack_info.tidy_rules = rsp.tidy_rules
    end
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.warehouse_have_arranged)
    if rsp then
      if rsp.last_open_box_id then
        _G.DataModelMgr.PlayerDataModel:UpdateLastOpenBoxID(rsp.last_open_box_id)
      end
      if rsp.box_info then
        for _, box_info in pairs(rsp.box_info) do
          _G.DataModelMgr.PlayerDataModel:OnUpdatePetWarehouseBoxInfo(box_info)
        end
      end
    end
    self:UpdateCachePetBelongBoxMap()
    self:DispatchEvent(PetUIModuleEvent.OnPetBoxUpdate)
  end
end

function PetUIModule:UpdateCachePetBelongBoxMap(curBoxIndex)
  if self.CachePetBelongBoxMap == nil then
    self.CachePetBelongBoxMap = {}
  end
  if not (_G.DataModelMgr.PlayerDataModel.playerInfo.pet_info and _G.DataModelMgr.PlayerDataModel.playerInfo.pet_info.backpack_info) or not _G.DataModelMgr.PlayerDataModel.playerInfo.pet_info.backpack_info.boxes then
    return
  end
  for _, boxInfo in ipairs(_G.DataModelMgr.PlayerDataModel.playerInfo.pet_info.backpack_info.boxes) do
    for i = 1, #boxInfo.pet_gid do
      local gid = boxInfo.pet_gid[i]
      if 0 ~= gid then
        self.CachePetBelongBoxMap[gid] = boxInfo.box_id
      end
    end
  end
  for _, team in pairs(_G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo().teams) do
    if team.pet_infos then
      for i = 1, #team.pet_infos do
        if team.pet_infos[i] then
          local gid = team.pet_infos[i].pet_gid
          if gid and self.CachePetBelongBoxMap[gid] then
            self.CachePetBelongBoxMap[gid] = nil
          end
        end
      end
    end
  end
end

function PetUIModule:OnCmdGetPetBelongBoxID(PetGID)
  if nil == PetGID then
    return nil
  end
  if nil == self.CachePetBelongBoxMap then
    return nil
  end
  return self.CachePetBelongBoxMap[PetGID]
end

function PetUIModule:OnCmdDragPetToBox(box_id, pos)
  if self:HasPanel("NewPetBag") then
    local panel = self:GetPanel("NewPetBag")
    if panel then
      panel:DragPetToBox(box_id, pos)
    end
  end
end

function PetUIModule:OnCmdBoxDragStart(box_info)
  if self:HasPanel("NewPetBagBox") then
    local panel = self:GetPanel("NewPetBagBox")
    if panel then
      panel:BoxDragStart(box_info)
    end
  end
end

function PetUIModule:GetAllWarehousConfigs()
  if self.AllWarehousConfigs then
    return self.AllWarehousConfigs
  end
  local cfg = DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_WAREHOUSE_CONF)
  if cfg then
    self.AllWarehousConfigs = cfg:GetAllDatas()
  end
  return self.AllWarehousConfigs
end

function PetUIModule:GetAllWarehousCollectMarkConfigs()
  if self.AllWarehousCollectConfigs then
    return self.AllWarehousCollectConfigs
  end
  local cfg = DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WAREHOUSE_COLLECT_MARK)
  if cfg then
    self.AllWarehousCollectConfigs = cfg:GetAllDatas()
  end
  return self.AllWarehousCollectConfigs
end

function PetUIModule:SetLastOpenBoxId(box_id)
  local petinfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  if petinfo and petinfo.backpack_info then
    petinfo.backpack_info.last_open_box_id = box_id
  end
end

function PetUIModule:GetLastOpenBoxId()
  local petinfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  if petinfo and petinfo.backpack_info and petinfo.backpack_info.last_open_box_id then
    return 0 == petinfo.backpack_info.last_open_box_id and 1 or petinfo.backpack_info.last_open_box_id
  else
    return 1
  end
  return 1
end

function PetUIModule:SetBoxPets(petChange)
  _G.DataModelMgr.PlayerDataModel:OnUpdateBoxPet(petChange)
end

function PetUIModule:UpdateBoxMark(box_id, new_mark_type, new_box_name, new_lock)
  local boxInfos = _G.DataModelMgr.PlayerDataModel:GetPetWarehouseBoxInfos()
  for _, boxInfo in pairs(boxInfos or {}) do
    if boxInfo and boxInfo.box_id == box_id then
      boxInfo.mark_type = new_mark_type
      boxInfo.box_name = new_box_name
      boxInfo.lock = new_lock
      break
    end
  end
end

function PetUIModule:InitCachePetBoxFilterData()
  self.CachePetBoxFilterData = {
    Condition = {
      FilterPetIdCondition = {},
      FilterTalentCondition = {},
      FilterDepartCondition = {},
      FilterNatureCondition = {},
      FilterAttributeCondition = {},
      FilterPetMarkCondition = {},
      FilterStrongCondition = {},
      FilterTimeCondition = {},
      FilterTraceBackCondition = {}
    },
    RawFilterList = {},
    FinalFilterList = {},
    FastLookUpFilterListMap = {}
  }
  return self.CachePetBoxFilterData
end

function PetUIModule:GetCachePetBoxFilterData()
  if self.CachePetBoxFilterData then
    return self.CachePetBoxFilterData
  end
  return self:InitCachePetBoxFilterData()
end

function PetUIModule:SetCachePetBoxFilterData(data)
  self.CachePetBoxFilterData = data
end

function PetUIModule:IsFilteringCondition(AllCondition)
  local function Check(Condition)
    if Condition and #Condition > 0 then
      return true
    end
    return false
  end
  
  if Check(AllCondition.FilterPetIdCondition) then
    return true
  elseif Check(AllCondition.FilterTalentCondition) then
    return true
  elseif Check(AllCondition.FilterDepartCondition) then
    return true
  elseif Check(AllCondition.FilterNatureCondition) then
    return true
  elseif Check(AllCondition.FilterAttributeCondition) then
    return true
  elseif Check(AllCondition.FilterPetMarkCondition) then
    return true
  elseif Check(AllCondition.FilterStrongCondition) then
    return true
  elseif Check(AllCondition.FilterTimeCondition) then
    return true
  elseif Check(AllCondition.FilterTraceBackCondition) then
    return true
  end
  return false
end

function PetUIModule:SetCachePetBoxFilterDataCondition(condition)
  if self.CachePetBoxFilterData == nil then
    return
  end
  self.CachePetBoxFilterData.Condition = condition
end

function PetUIModule:UpdateCachePetBoxFilterData(isSendEvent, isProactiveUpdate)
  if self.CachePetBoxFilterData == nil then
    return
  end
  if nil == self.CachePetBoxFilterData.Condition then
    return
  end
  if not PetUtils.IsFilteringCondition(self.CachePetBoxFilterData.Condition) then
    return
  end
  isSendEvent = isSendEvent or false
  local allPetDataList = self:GetAllPetDatasWithoutBigWorldTeam()
  for i = 1, #allPetDataList do
    local filterData = {}
    filterData.petbase_id = allPetDataList[i].base_conf_id
    filterData.gid = allPetDataList[i].gid
    filterData.gender = allPetDataList[i].gender
    filterData.talent_rank = allPetDataList[i].talent_rank
    local petbaseConf = _G.DataConfigManager:GetPetbaseConf(allPetDataList[i].base_conf_id)
    if petbaseConf and petbaseConf.unit_type then
      filterData.depart = {}
      for k = 1, #petbaseConf.unit_type do
        local unitType = petbaseConf.unit_type[k]
        table.insert(filterData.depart, unitType)
      end
    end
    local naturePositive = allPetDataList[i].changed_nature_pos_attr_type
    if not naturePositive or 0 == naturePositive then
      naturePositive = _G.DataConfigManager:GetNatureConf(allPetDataList[i].nature).positive_effect
    end
    filterData.nature = naturePositive
    filterData.attribute = self:GetAttributeEnums(allPetDataList[i].attribute_info)
    filterData.mark = allPetDataList[i].partner_mark
    if 0 ~= allPetDataList[i].speciality_id then
      filterData.strong = self:GetStrongEnum(allPetDataList[i].speciality_id)
    end
    filterData.isInReleaseList = self:OnCmdCheckPetIsInFreeListInPortableBag(allPetDataList[i])
    filterData.time = {}
    if PetUtils.isTimestampInThisWeek(allPetDataList[i].add_time) then
      table.insert(filterData.time, _G.Enum.PetCatchTime.PCT_THISWEEK)
    end
    if PetUtils.isTimestampInToday(allPetDataList[i].add_time) then
      table.insert(filterData.time, _G.Enum.PetCatchTime.PCT_TODAY)
    end
    filterData.traceBack = {}
    if PetUtils.CheckPetIsCanTraceBack(allPetDataList[i], true, true, true) then
      table.insert(filterData.traceBack, _G.Enum.RollBack.RB_CANROLL)
    end
    allPetDataList[i].filterData = filterData
  end
  self:OnCmdFilterPetBoxData(allPetDataList, self.CachePetBoxFilterData.Condition, isSendEvent, isProactiveUpdate)
end

function PetUIModule:GetAttributeEnums(attribute_info)
  local enums = {}
  local hp = attribute_info.hp
  local attack = attribute_info.attack
  local special_attack = attribute_info.special_attack
  local defense = attribute_info.defense
  local special_defense = attribute_info.special_defense
  local speed = attribute_info.speed
  if hp.talent_add_value and hp.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_HPMAX)
  end
  if attack.talent_add_value and attack.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_PHYATK)
  end
  if special_attack.talent_add_value and special_attack.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_SPEATK)
  end
  if defense.talent_add_value and defense.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_PHYDEF)
  end
  if special_defense.talent_add_value and special_defense.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_SPEDEF)
  end
  if speed.talent_add_value and speed.talent_add_value > 0 then
    table.insert(enums, _G.Enum.AttributeType.AT_SPEED)
  end
  return enums
end

function PetUIModule:GetStrongEnum(speciality_id)
  local conf = _G.DataConfigManager:GetPetTalentConf(speciality_id)
  if not conf or not conf.filter_enum_value then
    return nil
  end
  local enum = _G.Enum.PetTalentFilterName[conf.filter_enum_value]
  return enum
end

function PetUIModule:GetAllPetDatasWithoutBigWorldTeam()
  local teamPetGidDic = {}
  local allData = {}
  for _, team in pairs(_G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo().teams) do
    if team.pet_infos then
      for i = 1, #team.pet_infos do
        if team.pet_infos[i] then
          teamPetGidDic[team.pet_infos[i].pet_gid] = true
        end
      end
    end
  end
  for i = 1, #_G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo().pet_data do
    local petData = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo().pet_data[i]
    if petData and not teamPetGidDic[petData.gid] then
      table.insert(allData, petData)
    end
  end
  return allData
end

function PetUIModule:GetPetBoxDatas()
  local boxInfos = _G.DataModelMgr.PlayerDataModel:GetPetWarehouseBoxInfos()
  if nil == boxInfos then
    return {}
  end
  local confs = self:GetAllWarehousConfigs()
  local itemList = {}
  for i = 1, #confs do
    local conf = confs[i]
    local item = {
      id = conf.id,
      petBoxInfo = nil,
      isLock = true
    }
    for k = 1, #boxInfos do
      local boxInfo = boxInfos[k]
      if boxInfo.box_id == conf.id then
        item.petBoxInfo = boxInfo
        item.isLock = false
        break
      end
    end
    table.insert(itemList, item)
    if i > #boxInfos then
      break
    end
  end
  table.sort(itemList, function(a, b)
    local a_sort = a.isLock and 1 or 0
    local b_sort = b.isLock and 1 or 0
    if a_sort == b_sort then
      return a.id < b.id
    else
      return a_sort < b_sort
    end
  end)
  return itemList
end

function PetUIModule:OnCmdFilterPetBoxData(petDatas, filterCondition, isSendEvent, isProactiveUpdate)
  if nil == isSendEvent then
    isSendEvent = true
  end
  if self:IsFilteringCondition(filterCondition) then
  end
  local dic = {}
  dic.petbase_id = filterCondition.FilterPetIdCondition
  dic.talent_rank = filterCondition.FilterTalentCondition
  dic.nature = filterCondition.FilterNatureCondition
  dic.attribute = filterCondition.FilterAttributeCondition
  dic.mark = filterCondition.FilterPetMarkCondition
  dic.strong = filterCondition.FilterStrongCondition
  dic.depart = filterCondition.FilterDepartCondition
  dic.time = filterCondition.FilterTimeCondition
  dic.traceBack = filterCondition.FilterTraceBackCondition
  local RawFilterList, FreeButNotFilterList, FreeAndFilterList, NotFreeButFilterList = PetUtils.GeneralMultipleConditionFilter(dic, petDatas)
  PetUtils.SortFilterPetList(FreeButNotFilterList)
  PetUtils.SortFilterPetList(FreeAndFilterList)
  PetUtils.SortFilterPetList(NotFreeButFilterList)
  local FinalFilterList = {}
  for _, item in pairs(FreeButNotFilterList or {}) do
    table.insert(FinalFilterList, item)
  end
  for _, item in pairs(FreeAndFilterList or {}) do
    table.insert(FinalFilterList, item)
  end
  for _, item in pairs(NotFreeButFilterList or {}) do
    table.insert(FinalFilterList, item)
  end
  self:SetFastLookUpFilterListMap(RawFilterList)
  self.CachePetBoxFilterData.Condition = filterCondition
  self.CachePetBoxFilterData.RawFilterList = RawFilterList
  self.CachePetBoxFilterData.FinalFilterList = FinalFilterList
  if isSendEvent then
    self:DispatchEvent(PetUIModuleEvent.OnPetBoxFilter, FinalFilterList, isProactiveUpdate)
  end
end

function PetUIModule:SetFastLookUpFilterListMap(PetDatas)
  self.FastLookUpFilterListMap = {}
  for _, PetData in pairs(PetDatas or {}) do
    if PetData then
      self.FastLookUpFilterListMap[PetData.gid] = PetData
    end
  end
end

function PetUIModule:OnCmdCheckPetIsInFilterList(PetGid)
  if self.FastLookUpFilterListMap == nil then
    return false
  end
  return self.FastLookUpFilterListMap[PetGid] ~= nil
end

function PetUIModule:ClearChildrenPanelState()
  if self.PanelStateMap and self.PanelStateMap.Attribute then
    self.PanelStateMap = {}
    self.PanelStateMap.Screening = false
    self.PanelStateMap.Box = false
    self.PanelStateMap.Attribute = true
  else
    self.PanelStateMap = nil
  end
end

function PetUIModule:OnSavePetBagChildrenPanelState(panelName, isVisible)
  if self.PanelStateMap == nil then
    self.PanelStateMap = {}
    self.PanelStateMap.Screening = false
    self.PanelStateMap.Box = false
    self.PanelStateMap.Attribute = false
  end
  self.PanelStateMap[panelName] = isVisible
  local isShowChildren = false
  for i, v in pairs(self.PanelStateMap) do
    if v then
      isShowChildren = true
      break
    end
  end
  if self:HasPanel("NewPetBag") then
    local panel = self:GetPanel("NewPetBag")
    if panel and panel.CacheRightOpenState then
      isShowChildren = true
    end
    self:DispatchEvent(PetUIModuleEvent.OnOpenNewPetBagDetails, isShowChildren)
  end
end

function PetUIModule:OnGetPetBagChilderenPanelState()
  if self.PanelStateMap == nil then
    return false
  end
  local isShowChildren = false
  for i, v in pairs(self.PanelStateMap) do
    if v then
      isShowChildren = true
      break
    end
  end
  return isShowChildren
end

function PetUIModule:CheckVideoShareMainPetPanelUIIsVisible(ui)
  if ui:GetVisibility() ~= UE4.ESlateVisibility.Hidden and ui:GetVisibility() ~= UE4.ESlateVisibility.Collapsed then
    return true
  end
  return false
end

function PetUIModule:OnCmdCheckHasPetByPetBaseId(petBaseId)
  if not petBaseId then
    return false
  end
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if battlePetList then
    for i, data in ipairs(battlePetList) do
      if petBaseId == data.base_conf_id then
        return true
      end
    end
  end
  local backpackPetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackPetInfo()
  if backpackPetList then
    for i, data in ipairs(backpackPetList) do
      if petBaseId == data.base_conf_id then
        return true
      end
    end
  end
  local housePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerHousePetInfo()
  if housePetList then
    for i, data in ipairs(housePetList) do
      if petBaseId == data.base_conf_id then
        return true
      end
    end
  end
  return false
end

function PetUIModule:OnCmdSetPetMainPanelPetImage3DActive(enable)
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    if panel and panel.petMiddlePanel and panel.petMiddlePanel.petImage3D then
      if enable then
        panel.petMiddlePanel.petImage3D:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        panel.petMiddlePanel.petImage3D:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function PetUIModule:OnCmdCheckIsOpenEvoPanel()
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    if panel and panel.petMiddlePanel and panel.petMiddlePanel.petImage3D then
      return panel.petMiddlePanel.petImage3D.IsOpenEvoPanel
    end
  end
  return false
end

function PetUIModule:ResetPetMainCameraPos()
  if self:HasPanel("PetInfoMain") then
    local panel = self:GetPanel("PetInfoMain")
    if panel and panel.petMiddlePanel and panel.petMiddlePanel.petImage3D then
      panel.petMiddlePanel.petImage3D:PlayCloseTwoPanelLevelSequenceForced()
    end
  end
end

function PetUIModule:OnCmdOpenBoxOrganizationFethod(curBoxIndex)
  self:OpenPanel("BoxOrganizationFethod", curBoxIndex)
end

return PetUIModule
