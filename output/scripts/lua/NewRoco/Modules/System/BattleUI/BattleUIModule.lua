local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = reload("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUIModuleCmd = reload("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleFsmData = require("NewRoco.Modules.System.BattleUI.BattleFsmData")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local StarChainEnum = require("NewRoco.Modules.System.StarChain.StarChainEnum")
local BattleUIModule = NRCModuleBase:Extend("BattleUIModule")

function BattleUIModule:OnConstruct()
  _G.BattleUIModuleCmd = reload("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
  local confName = _G.DataConfigManager.ConfigTableId.SKILL_CONF
  local conf = _G.DataConfigManager:GetTable(confName)
  self:CacheConf(confName, conf)
  self.widgetDict = {}
  self.widgetRefDict = {}
  self.BattleFsmInfo = BattleFsmData()
  self.data = self:SetData("BattleUIModuleData", "NewRoco.Modules.System.BattleUI.BattleUIModuleData")
  self:RegisterCmd(BattleUIModuleCmd.OpenLoading, self.OpenLoadingPanel)
  self:RegisterCmd(BattleUIModuleCmd.ForceCloseLoading, self.ForceCloseLoadingPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseLoading, self.CloseLoadingPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseLoadingPanelForce, self.CloseLoadingPanelForce)
  self:RegisterCmd(BattleUIModuleCmd.SetForbidCloseLoading, self.SetForbidCloseLoading)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleFailedUI, self.OpenBattleFailedUI)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleFailedUI, self.CloseBattleFailedUI)
  self:RegisterCmd(BattleUIModuleCmd.OpenTransformLoadingUI, self.OpenTransformLoadingUI)
  self:RegisterCmd(BattleUIModuleCmd.CloseTransformLoadingUI, self.CloseTransformLoadingUI)
  self:RegisterCmd(BattleUIModuleCmd.OpenMain, self.OpenMain)
  self:RegisterCmd(BattleUIModuleCmd.CloseMain, self.CloseMain)
  self:RegisterCmd(BattleUIModuleCmd.WaitingRecycleMain, self.WaitingRecycleMain)
  self:RegisterCmd(BattleUIModuleCmd.HideMain, self.HideMain)
  self:RegisterCmd(BattleUIModuleCmd.HideMainWindow, self.HideMainWindow)
  self:RegisterCmd(BattleUIModuleCmd.HideMainWindowWithOption, self.HideMainWindowWithOption)
  self:RegisterCmd(BattleUIModuleCmd.HideBattlePopupPanel, self.HideBattlePopupPanel)
  self:RegisterCmd(BattleUIModuleCmd.ShowBattleMainWeatherUi, self.OnCmdShowBattleMainWeatherUi)
  self:RegisterCmd(BattleUIModuleCmd.ChangeOperateMode, self.ChangeOperateMode)
  self:RegisterCmd(BattleUIModuleCmd.UpdateRound, self.UpdateRound)
  self:RegisterCmd(BattleUIModuleCmd.MainHideAll, self.MainHideAll)
  self:RegisterCmd(BattleUIModuleCmd.HideHPBars, self.HideHPBars)
  self:RegisterCmd(BattleUIModuleCmd.ShowHPBars, self.ShowHPBars)
  self:RegisterCmd(BattleUIModuleCmd.HideWaiting, self.HideWaiting)
  self:RegisterCmd(BattleUIModuleCmd.ShowWaiting, self.ShowWaiting)
  self:RegisterCmd(BattleUIModuleCmd.HideEmoList, self.HideEmoList)
  self:RegisterCmd(BattleUIModuleCmd.ShowEmoList, self.ShowEmoList)
  self:RegisterCmd(BattleUIModuleCmd.ShowChangePetConfirm, self.ShowChangePetConfirm)
  self:RegisterCmd(BattleUIModuleCmd.UpdateChangePetConfirm, self.ShowChangePetConfirm)
  self:RegisterCmd(BattleUIModuleCmd.HideChangePetConfirm, self.HideChangePetConfirm)
  self:RegisterCmd(BattleUIModuleCmd.ShowChangePetConfirm3, self.ShowChangePetConfirm3)
  self:RegisterCmd(BattleUIModuleCmd.UpdateChangePetConfirm3, self.ShowChangePetConfirm3)
  self:RegisterCmd(BattleUIModuleCmd.HideChangePetConfirm3, self.HideChangePetConfirm3)
  self:RegisterCmd(BattleUIModuleCmd.CloseChangePetConfirm3, self.CloseChangePetConfirm3)
  self:RegisterCmd(BattleUIModuleCmd.SwitchReservesPetsPanel, self.SwitchReservesPetsPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseReservesPetsPanel, self.CloseReservesPetsPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenEnter, self.OpenEnter)
  self:RegisterCmd(BattleUIModuleCmd.CloseEnter, self.CloseEnter)
  self:RegisterCmd(BattleUIModuleCmd.OpenSkillTips, self.OpenSkillTips)
  self:RegisterCmd(BattleUIModuleCmd.UpdateSkillTips, self.UpdateSkillTips)
  self:RegisterCmd(BattleUIModuleCmd.CloseSkillTips, self.CloseSkillTips)
  self:RegisterCmd(BattleUIModuleCmd.OpenSkillPredictionTips, self.OpenSkillPredictionTips)
  self:RegisterCmd(BattleUIModuleCmd.CloseSkillPredictionTips, self.CloseSkillPredictionTips)
  self:RegisterCmd(BattleUIModuleCmd.OpenEscapePanel, self.OpenEscapePanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseEscapePanel, self.CloseEscapePanel)
  self:RegisterCmd(BattleUIModuleCmd.ShowEnterAnimation, self.ShowEnterAnimation)
  self:RegisterCmd(BattleUIModuleCmd.OpenBuffInfo, self.OpenBuffInfo)
  self:RegisterCmd(BattleUIModuleCmd.CloseBuffInfo, self.CloseBuffInfo)
  self:RegisterCmd(BattleUIModuleCmd.OnShowBatleResult, self.OnShowBatleResult)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattlePetEvolutionFinishPanel, self.OnCmdOpenBattlePetEvolutionResultPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattlePetEvolutionFinishPanel, self.OnCmdCloseBattlePetEvolutionResultPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleEvolutionPanel, self.OnCmdOpenBattleEvolutionPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleEvolutionPanel, self.OnCmdCloseBattleEvolutionPanel)
  self:RegisterCmd(BattleUIModuleCmd.TryDestroyBattleEvoActors, self.TryDestroyBattleEvoActors)
  self:RegisterCmd(BattleUIModuleCmd.OpenPveEnterRoleHpPanel, self.OnCmdOpenPveEnterRoleHpPanel)
  self:RegisterCmd(BattleUIModuleCmd.ClosePveEnterRoleHpPanel, self.OnCmdClosePveEnterRoleHpPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenRoleHpCriticalTipPanel, self.OnCmdOpenRoleHpCriticalTipPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseRoleHpCriticalTipPanel, self.OnCmdCloseRoleHpCriticalTipPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenRoleHpDefeatedTipPanel, self.OnCmdOpenRoleHpDefeatedTipPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseRoleHpDefeatedTipPanel, self.OnCmdCloseRoleHpDefeatedTipPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleRedPanel, self.OnCmdOpenBattleRedPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleRedPanel, self.OnCmdCloseBattleRedPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenPVPMatch, self.OnCmdOpenPVPMatch)
  self:RegisterCmd(BattleUIModuleCmd.ClosePVPMatch, self.OnCmdClosePVPMatch)
  self:RegisterCmd(BattleUIModuleCmd.ResumeOpenPVPMatch, self.OnCmdResumeOpenPVPMatch)
  self:RegisterCmd(BattleUIModuleCmd.ChangePVPMatchTeam, self.OnCmdChangePVPMatchTeam)
  self:RegisterCmd(BattleUIModuleCmd.ChangePVPBattleType, self.OnCmdChangePVPBattleType)
  self:RegisterCmd(BattleUIModuleCmd.StartMatchByType, self.OnCmdStartMatchByType)
  self:RegisterCmd(BattleUIModuleCmd.SetPVPPetTip, self.OnCmdSetPVPPetTip)
  self:RegisterCmd(BattleUIModuleCmd.OpenPVPMatchTeam, self.OnCmdOpenPVPMatchTeam)
  self:RegisterCmd(BattleUIModuleCmd.EnterPVP, self.OnCmdEnterPVP)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleUIBackpackTips, self.OnCmdOpenBattleUIBackpackTips)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleUIBackpackTips, self.OnCmdCloseBattleUIBackpackTips)
  self:RegisterCmd(BattleUIModuleCmd.ShowMatchSuccText, self.ShowMatchSuccText)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattlePVPResultPanel, self.OnCmdOpenPVPResult)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattlePVPResultPanel, self.OnCmdClosePVPResult)
  self:RegisterCmd(BattleUIModuleCmd.PVPResultShowQuitState, self.OnCmdPVPResultShowQuitState)
  self:RegisterCmd(BattleUIModuleCmd.SetTerritoryTrialSettlementResultState, self.OnCmdSetBattleTerritoryTrialResultState)
  self:RegisterCmd(BattleUIModuleCmd.OpenNpcBattleFailure, self.OnCmdOpenNpcBattleFailure)
  self:RegisterCmd(BattleUIModuleCmd.CloseNpcBattleFailure, self.OnCmdCloseNpcBattleFailure)
  self:RegisterCmd(BattleUIModuleCmd.OpenAIVisible, self.OnCmdOpenAIVisible)
  self:RegisterCmd(BattleUIModuleCmd.CloseAIVisible, self.OnCmdCloseAIVisible)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleNpcAutoEscapePanel, self.OnCmdOpenBattleNpcAutoEscapePanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleNpcAutoEscapePanel, self.OnCmdCloseBattleNpcAutoEscapePanel)
  self:RegisterCmd(BattleUIModuleCmd.PlayVideo, self.PlayVideo)
  self:RegisterCmd(BattleUIModuleCmd.BattleMainSetOpacity, self.OnCmdBattleMainSetOpacity)
  self:RegisterCmd(BattleUIModuleCmd.UpdatePVPPetInfo, self.OnCmdUpdatePVPPetInfo)
  self:RegisterCmd(BattleUIModuleCmd.ReceiveStartMatch, self.OnCmdReceiveStartMatch)
  self:RegisterCmd(BattleUIModuleCmd.Open_Battle_Evolution_Select, self.OnCmdOpen_Battle_Evolution_Select)
  self:RegisterCmd(BattleUIModuleCmd.Close_Battle_Evolution_Select, self.OnCmdClose_Battle_Evolution_Select)
  self:RegisterCmd(BattleUIModuleCmd.OpenAndSet_Battle_Round_Start, self.OnCmdOpenAndSet_Battle_Round_Start)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattle_Round_StartAndDisplayRestRound, self.OnCmdOpenBattle_Round_StartAndDisplayRestRound)
  self:RegisterCmd(BattleUIModuleCmd.Close_Battle_Round_Start, self.OnCmdClose_Battle_Round_Start)
  self:RegisterCmd(BattleUIModuleCmd.Open_ReplayPanel, self.OnCmdOpen_ReplayPanel)
  self:RegisterCmd(BattleUIModuleCmd.Close_ReplayPanel, self.OnCmdClose_ReplayPanel)
  self:RegisterCmd(BattleUIModuleCmd.Open_Information_Recording, self.OnCmdOpen_Information_Recording)
  self:RegisterCmd(BattleUIModuleCmd.Close_Information_Recording, self.OnCmdClose_Information_Recording)
  self:RegisterCmd(BattleUIModuleCmd.Set_Information_Recording, self.OnCmdSet_Information_Recording)
  self:RegisterCmd(BattleUIModuleCmd.InformationRecordingHyperLinkClick, self.OnCmdInformationRecordingHyperLinkClick)
  self:RegisterCmd(BattleUIModuleCmd.InformationRecordingCloseHyperLink, self.OnCmdInformationRecordingCloseHyperLink)
  self:RegisterCmd(BattleUIModuleCmd.OpenWeatherTips, self.OnCmdOpenWeatherTips)
  self:RegisterCmd(BattleUIModuleCmd.CloseWeatherTips, self.OnCmdCloseWeatherTips)
  self:RegisterCmd(BattleUIModuleCmd.Close_AllTips, self.Close_AllTips)
  self:RegisterCmd(BattleUIModuleCmd.Open_SurrenderPanel, self.OnCmdOpen_SurrenderPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleFsmUI, self.OnCmdOpenBattleFsmUI)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleProcessUI, self.OnCmdOpenBattleProcessUI)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleProcessUI, self.OnCmdCloseBattleProcessUI)
  self:RegisterCmd(BattleUIModuleCmd.SavePreProcessCmd, self.OnCmdSavePreProcessCmd)
  self:RegisterCmd(BattleUIModuleCmd.GetPreProcessCmd, self.OnCmdGetPreProcessCmd)
  self:RegisterCmd(BattleUIModuleCmd.SaveBattleNotify, self.OnCmdSaveBattleNotify)
  self:RegisterCmd(BattleUIModuleCmd.GetBattleNotify, self.OnCmdGetBattleNotify)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleGetGollumBall, self.OnCmdOpenBattleGetGollumBall)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleGetGollumBall, self.OnCmdCloseBattleGetGollumBall)
  self:RegisterCmd(BattleUIModuleCmd.IsHasFsmUIPanel, self.OnCmdIsHasFsmUIPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenPetCatchPanel, self.OnCmdOpenPetCatchPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenGetItemsPanel, self.OnCmdOpenGetItemsPanel)
  self:RegisterCmd(BattleUIModuleCmd.IsHasPetCatchPanel, self.OnCmdIsHasPetCatchPanel)
  self:RegisterCmd(BattleUIModuleCmd.ShowRecoveryItemSelect, self.OnCmdShowRecoveryItemSelect)
  self:RegisterCmd(BattleUIModuleCmd.UpdateStarChain, self.OnCmdUpdateStarChain)
  self:RegisterCmd(BattleUIModuleCmd.ShowStarDebrisText, self.OnCmdShowStarDebrisText)
  self:RegisterCmd(BattleUIModuleCmd.ShowOrHideMoneyBtn, self.OnCmdShowOrHideMoneyBtn)
  self:RegisterCmd(BattleUIModuleCmd.RefreshCatchConsumeInfo, self.OnCmdRefreshCatchConsumeInfo)
  self:RegisterCmd(BattleUIModuleCmd.SelectRecoveryItem, self.OnCmdSelectRecoveryItem)
  self:RegisterCmd(BattleUIModuleCmd.SetSelectRecoveryItem, self.OnCmdSetSelectRecoveryItem)
  self:RegisterCmd(BattleUIModuleCmd.GetSelectRecoveryItem, self.OnCmdGetSelectRecoveryItem)
  self:RegisterCmd(BattleUIModuleCmd.IsSelectRecoveryItemEnough, self.OnCmdIsSelectRecoveryItemEnough)
  self:RegisterCmd(BattleUIModuleCmd.IsAnyRecoveryItemEnough, self.OnCmdIsAnyRecoveryItemEnough)
  self:RegisterCmd(BattleUIModuleCmd.OpenSkillPickPanel, self.OnCmdOpenSkillPickPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenPetGroupWarfare, self.OnCmdOpenPetGroupWarfare)
  self:RegisterCmd(BattleUIModuleCmd.ActivatePetGroupWarfare, self.OnCmdActivatePetGroupWarfare)
  self:RegisterCmd(BattleUIModuleCmd.OpenPetTheFinalBattle, self.OnCmdOpenPetTheFinalBattle)
  self:RegisterCmd(BattleUIModuleCmd.ActivatePetTheFinalBattle, self.OnCmdActivatePetTheFinalBattle)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleCameraControl, self.OpenBattleCameraControl)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleCameraControl, self.CloseBattleCameraControl)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleEntryHud, self.OpenBattleEntryHud)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleEntryHud, self.CloseBattleEntryHud)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleEntryHudVS, self.OpenBattleEntryHudVS)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleEntryHudVS, self.CloseBattleEntryHudVS)
  self:RegisterCmd(BattleUIModuleCmd.SendZonePkExitReq, self.OnCmdZonePkExitReq)
  self:RegisterCmd(BattleUIModuleCmd.SendZonePkSelectPetReq, self.OnCmdZonePkSelectPetReq)
  self:RegisterCmd(BattleUIModuleCmd.SendZonePkCancelPrepareReq, self.OnCmdZonePkCancelPrepareReq)
  self:RegisterCmd(BattleUIModuleCmd.OpenPVP_PreparePanel, self.OpenPVP_PreparePanel)
  self:RegisterCmd(BattleUIModuleCmd.ClosePVP_PreparePanel, self.OnCmdClosePVPPreparePanel)
  self:RegisterCmd(BattleUIModuleCmd.GetPVP_PreparePanelState, self.GetPVP_PreparePanelState)
  self:RegisterCmd(BattleUIModuleCmd.SetPVP_PrepareSelectPet, self.SetPVP_PrepareSelectPet)
  self:RegisterCmd(BattleUIModuleCmd.OpenPreparePanelPetInfo, self.OpenPreparePanelPetInfo)
  self:RegisterCmd(BattleUIModuleCmd.GetPVP_PreparePlayerReadyState, self.GetPlayerPVPReadyState)
  self:RegisterCmd(BattleUIModuleCmd.OpenWarningPrompt, self.OnCmdOpenWarningPrompt)
  self:RegisterCmd(BattleUIModuleCmd.CloseWarningPrompt, self.OnCmdCloseWarningPrompt)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleControllerPanel, self.OnCmdOpenBattleControllerPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleControllerPanel, self.OnCmdCloseBattleControllerPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattlePvpHintPanel, self.OnCmdOpenBattlePvpHintPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattlePvpHintPanel, self.OnCmdCloseBattlePvpHintPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattlePvpState, self.OnCmdOpenBattlePvpState)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattlePvpState, self.OnCmdCloseBattlePvpState)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattlePopUpTips, self.OnCmdOpenBattlePopUpTips)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattlePopUpTips, self.OnCmdCloseBattlePopUpTips)
  self:RegisterCmd(BattleUIModuleCmd.ShowOrHideBattlePopUpTips, self.OnCmdShowOrHideBattlePopUpTips)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattlePopUpDiscoveringDifferentlyColoredPetTips, self.OnCmdOpenBattlePopUpDiscoveringDifferentlyColoredPetTips)
  self:RegisterCmd(BattleUIModuleCmd.OpenHudPerceptionPanel, self.OnCmdOpenHudPerceptionPanel)
  self:RegisterCmd(BattleUIModuleCmd.GetHudPerceptionPanel, self.OnCmdGetHudPerceptionPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleRunAwayTip, self.OnCmdOpenBattleRunAwayTip)
  self:RegisterCmd(BattleUIModuleCmd.ShowBattleRunAwayTip, self.OnCmdShowBattleRunAwayTip)
  self:RegisterCmd(BattleUIModuleCmd.HideBattleRunAwayTip, self.OnCmdHideBattleRunAwayTip)
  self:RegisterCmd(BattleUIModuleCmd.OpenWishPowerPanel, self.OnCmdOpenWishPowerPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseWishPowerPanel, self.OnCmdCloseWishPowerPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenCallNamePanel, self.OnCmdOpenCallNamePanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenPetConfirmPanel, self.OnCmdOpenPetConfirmPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleTutorialPanel, self.OnCmdOpenBattleTutorial)
  self:RegisterCmd(BattleUIModuleCmd.SetGuideWidget, self.OnCmdSetGuideWidget)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleTutorialPanel1, self.OnCmdOpenBattleTutorial1)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleTutorialPanel1, self.OnCmdCloseBattleTutorial1)
  self:RegisterCmd(BattleUIModuleCmd.SetB1P3FirstRoundGuideState, self.OnCmdSetB1P3FirstRoundGuideState)
  self:RegisterCmd(BattleUIModuleCmd.GetB1P3FirstRoundGuideState, self.OnCmdGetB1P3FirstRoundGuideState)
  self:RegisterCmd(BattleUIModuleCmd.OpenFinalBattleLifeBar, self.OnCmdOpenFinalBattleLifeBar)
  self:RegisterCmd(BattleUIModuleCmd.CloseFinalBattleLifeBar, self.OnCmdCloseFinalBattleLifeBar)
  self:RegisterCmd(BattleUIModuleCmd.OPenPetRecoveryTime, self.OnCmdOPenPetRecoveryTime)
  self:RegisterCmd(BattleUIModuleCmd.SelectPetRecoverTime, self.OnCmdSelectPetRecoverTime)
  self:RegisterCmd(BattleUIModuleCmd.OpenAutoBattleTestPanel, self.OnCmdOpenAutoBattleTestPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenPVPDanGradingPanel, self.OnCmdOpenPVPDanGradingPanel)
  self:RegisterCmd(BattleUIModuleCmd.ClosePVPDanGradingPanel, self.OnCmdClosePVPDanGradingPanel)
  self:RegisterCmd(BattleUIModuleCmd.OnCmdShowDanFlag, self.OnCmdShowDanFlag)
  self:RegisterCmd(BattleUIModuleCmd.OnCmdShowDanStars, self.OnCmdShowDanStars)
  self:RegisterCmd(BattleUIModuleCmd.OpenPVPCeleritCarnetyPanel, self.OnCmdOpenPVPCeleritCarnetyPanel)
  self:RegisterCmd(BattleUIModuleCmd.ClosePVPCeleritCarnetyPanel, self.OnCmdClosePVPCeleritCarnetyPanel)
  self:RegisterCmd(BattleUIModuleCmd.OpenMechanismValidation, self.OnCmdOpenMechanismValidation)
  self:RegisterCmd(BattleUIModuleCmd.CloseMechanismValidation, self.OnCmdCloseMechanismValidation)
  self:RegisterCmd(BattleUIModuleCmd.OpenPVPValueNumberPanel, self.OnCmdOpenPVPValueNumberPanel)
  self:RegisterCmd(BattleUIModuleCmd.ClosePVPValueNumberPanel, self.OnCmdClosePVPValueNumberPanel)
  self:RegisterCmd(BattleUIModuleCmd.HandleObserverChangeNotify, self.OnCmdHandleObserverChangeNotify)
  self:RegisterCmd(BattleUIModuleCmd.GetObserverBriefInfoList, self.OnCmdGetObserverBriefInfoList)
  self:RegisterCmd(BattleUIModuleCmd.CheckInFighting, self.OnCmdCheckInFighting)
  self:RegisterCmd(BattleUIModuleCmd.CheckInObserver, self.OnCmdCheckInObserver)
  self:RegisterCmd(BattleUIModuleCmd.CheckInFightingOrObserver, self.OnCmdCheckInFightingOrObserver)
  self:RegisterCmd(BattleUIModuleCmd.ReqJoinObservingBattle, self.OnCmdReqJoinObservingBattle)
  self:RegisterCmd(BattleUIModuleCmd.ReqLeaveObservingBattle, self.OnCmdReqLeaveObservingBattle)
  self:RegisterCmd(BattleUIModuleCmd.ReqBattleKickOutObserver, self.OnCmdReqBattleKickOutObserver)
  self:RegisterCmd(BattleUIModuleCmd.TrySilhouetteCombat, self.OnCmdTrySilhouetteCombat)
  self:RegisterCmd(BattleUIModuleCmd.SetCurMatchPvpId, self.OnCmdSetCurMatchPvpId)
  self:RegisterCmd(BattleUIModuleCmd.GetCurMatchPvpId, self.OnCmdGetCurMatchPvpId)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleAdditionalTarget, self.OnCmdOpenBattleAdditionalTarget)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleAdditionalTarget, self.OnCmdCloseBattleAdditionalTarget)
  self:RegisterCmd(BattleUIModuleCmd.HideBattleAdditionalTarget, self.OnCmdHideBattleAdditionalTarget)
  self:RegisterCmd(BattleUIModuleCmd.CloseMainSubPanel, self.CloseMainSubPanel)
  self:RegisterCmd(BattleUIModuleCmd.SaveFinalBattlePetData, self.OnCmdSaveFinalBattlePetData)
  self:RegisterCmd(BattleUIModuleCmd.GetFinalBattlePetData, self.OnCmdGetFinalBattlePetData)
  self:RegisterCmd(BattleUIModuleCmd.GetSwapSelectPetGuid, self.OnCmdGetSwapSelectPetGuid)
  self:RegisterCmd(BattleUIModuleCmd.GetTriggerInputActionName, self.OnCmdGetTriggerInputActionName)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleBuffTips, self.OnCmdOpenBattleBuffTips)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleBuffTips, self.OnCmdCloseBattleBuffTips)
  self:RegisterCmd(BattleUIModuleCmd.TestChangeWishPower, self.TestChangeWishPower)
  self:RegisterCmd(BattleUIModuleCmd.CheckOpenWishPowerTutorial, self.CheckOpenWishPowerTutorial)
  self:RegisterCmd(BattleUIModuleCmd.OpenWishPowerTutorial, self.OpenWishPowerTutorial)
  self:RegisterCmd(BattleUIModuleCmd.WishPowerVisible, self.WishPowerUIVisible)
  self:RegisterCmd(BattleUIModuleCmd.WishPowerInVisible, self.WishPowerUIInVisible)
  self:RegisterCmd(BattleUIModuleCmd.WishPowerMaxShineOut, self.WishPowerMaxShineOut)
  self:RegisterCmd(BattleUIModuleCmd.OpenPVPWaitingLoad, self.OpenPVPWaitingLoad)
  self:RegisterCmd(BattleUIModuleCmd.ClosePVPWaitingLoad, self.ClosePVPWaitingLoad)
  self:RegisterCmd(BattleUIModuleCmd.SetPvpPlayerPkInfoStartTime, self.SetPvpPlayerPkInfoStartTime)
  self:RegisterCmd(BattleUIModuleCmd.GetPvpPlayerPkInfoStartTime, self.GetPvpPlayerPkInfoStartTime)
  self:RegisterCmd(BattleUIModuleCmd.AddDontDisablePanelToList, self.AddDontDisablePanelToList)
  self:RegisterCmd(BattleUIModuleCmd.OnUpdatePetCollectTagRsp, self.OnUpdatePetCollectTagRsp)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleBloodPulse, self.OpenBattleBloodPulse)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleBloodPulse, self.CloseBattleBloodPulse)
  self:RegisterCmd(BattleUIModuleCmd.ShowFinalBattleTutorial1, self.ShowFinalBattleTutorial1)
  self:RegisterCmd(BattleUIModuleCmd.ShowFinalBattleWishPower, self.ShowFinalBattleWishPower)
  self:RegisterCmd(BattleUIModuleCmd.HideFinalBattleWishPower, self.HideFinalBattleWishPower)
  self:RegisterCmd(BattleUIModuleCmd.WaitBattleEndShowMagicManualTeach, self.OnCmdWaitBattleEndShowMagicManualTeach)
  self:RegisterCmd(BattleUIModuleCmd.ShowMagicManualTeach, self.OnShowMagicManualTeach)
  self:RegisterCmd(BattleUIModuleCmd.SetTeachBattleId, self.OnCmdSetTeachBattleId)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleChangePetConfirmPanel, self.OnCmdOpenBattleChangePetConfirmPanel)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleChangePetConfirmPanel, self.CloseBattleChangePetConfirmPanel)
  self:RegisterCmd(BattleUIModuleCmd.HasSkillTips, self.HasSkillTips)
  self:RegisterCmd(BattleUIModuleCmd.OpenBattleUltimateSkillUI, self.OpenBattleUltimateSkillUI)
  self:RegisterCmd(BattleUIModuleCmd.CloseBattleUltimateSkillUI, self.CloseBattleUltimateSkillUI)
  self:RegisterCmd(BattleUIModuleCmd.TryBattleUltimateSkillClick, self.TryBattleUltimateSkillClick)
  self:RegisterCmd(BattleUIModuleCmd.RefWidget, self.RefWidget)
  self:RegisterCmd(BattleUIModuleCmd.UnRefWidget, self.UnRefWidget)
  self:RegisterCmd(BattleUIModuleCmd.GetWidget, self.GetWidget)
  self:RegisterCmd(BattleUIModuleCmd.ClearWidgetDict, self.ClearWidgetDict)
  self:RegisterCmd(BattleUIModuleCmd.ClosePvpEntryHud, self.ClosePvpEntryHud)
  self:RegisterCmd(BattleUIModuleCmd.ShowPetRecoveryTime, self.OnCmdShowPetRecoveryTime)
  self:RegisterCmd(BattleUIModuleCmd.CloseAllBattleChatRelatedUI, self.OnCmdCloseAllBattleChatRelatedUI)
  self:RegPanel("BattleMain", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleMainWindow", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("BattleLoading", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleLoading/UMG_BattleLoading", _G.Enum.UILayerType.UI_LAYER_TOP_LOADING)
  self:RegPanel("TransformLoading", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleLoading/UMG_TransformLoading", _G.Enum.UILayerType.UI_LAYER_TOP_LOADING)
  self:RegPanel("BattleFailed", "/Game/NewRoco/Modules/System/TipsModule/Res/Tips/UMG_FailTransTip")
  self:RegPanel("BattleEnter", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleEnterWindow")
  self:RegPanel("SkillTips", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Common_Skill_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, false)
  self:RegPanel("SkillPredictionTips", "/Game/NewRoco/Modules/System/BattleUI/Res/Hints/UMG_Battle_Hints_Tips")
  self:RegPanel("BattleEvolutionResult", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleEvolution/UMG_Battle_Evolution_Result", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("EscapePanel", "/Game/NewRoco/Modules/System/BattleUI/Res/HUD/UMG_Battle_EscapePanel")
  self:RegPanel("BuffInfo", "/Game/NewRoco/Modules/System/BattleUI/Res/HUD/UMG_Battle_BuffInfo", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("BattlePveRoleHpPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/RoleHP/UMG_Battle_PVE_RoleHpPanel")
  self:RegPanel("BattleRoleHpCriticalTipPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/RoleHP/UMG_Battle_RoleHp_CriticalTipPanel", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("BattleRoleHpDefeatedTipPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/RoleHP/UMG_Battle_RoleHp_DefeatedTipPanel", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("BattleRedPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_Red", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("BattlePVPMatching", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_PVP_Matching", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("BattleUIBackpackTips", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleUIBackpackTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattlePVPResult", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_Victory", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("BattleVictoryFailure", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_VictoryFailure", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleAIVisible", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleDebugger/UMG_BattleAI_Visible", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("BattleVideo", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleVideo.UMG_BattleVideo", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("BattleNpcAutoEscapeSelectPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/Hints/UMG_Battle_NPC_Escape_Select", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Battle_ChangePetConfirm", "/Game/NewRoco/Modules/System/Common/Res/UMG_Battle_ChangePetConfirm_1", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, false)
  self:RegPanel("Battle_ChangePetConfirm3", "/Game/NewRoco/Modules/System/Common/Res/UMG_Battle_ChangePetConfirm_3", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, false)
  self:RegPanel("BattleReservesPetsPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_ReservesPets.UMG_Battle_ReservesPets", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, false)
  self:RegPanel("Battle_Evolution_Select", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleEvolution/UMG_Battle_Evolution_Select", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UMG_Battle_Bubble", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_Bubble", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Battle_Round_Start", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleUIItem/UMG_Battle_Round_Start", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Battle_Replay", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleDebugger/UMG_Battle_Replay", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Information_Recording", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Information_Recording", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Battle_Plight", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_Plight", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Battle_Fsm", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleDebugger/UMG_Battle_Fsm", _G.Enum.UILayerType.UI_LAYER_TOP_MSG)
  self:RegPanel("Pet_Catch", "/Game/NewRoco/Modules/System/BattleUI/Res/PetGroupWarfare/UMG_Pet_Catch", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true)
  self:RegPanel("Get_Items", "/Game/NewRoco/Modules/System/BattleUI/Res/PetGroupWarfare/UMG_Pet_GetItems", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true)
  self:RegPanel("Battle_Skillpick_List", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_Skillpick_List", _G.Enum.UILayerType.UI_LAYER_BG)
  self:RegPanel("UMG_Pet_GroupWarfare", "/Game/NewRoco/Modules/System/BattleUI/Res/PetGroupWarfare/UMG_Pet_GroupWarfare", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("UMG_Pet_TheFinalBattle", "/Game/NewRoco/Modules/System/BattleUI/Res/PetGroupWarfare/UMG_Pet_TheFinalBattle", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("Battle_EvoPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleEvolution/UMG_BattleEvoPanel", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true)
  self:RegPanel("BattleProcess_Visible", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleDebugger/UMG_BattleProcess_visible.UMG_BattleProcess_Visible", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("BattleCameraControl", "/Game/NewRoco/Modules/Core/Battle/BattleCameraControl", _G.Enum.UILayerType.UI_LAYER_BG)
  self:RegPanel("BattleEntryHud", "/Game/NewRoco/Modules/Core/Battle/UMG_EntryHud", _G.Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("BattleGetGollumBall", "/Game/NewRoco/Modules/System/BattleUI/Res/BallOperation/UMG_GetGollumBall", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleEntryHudVS", "/Game/NewRoco/Modules/Core/Battle/UMG_EntryHudVS_V_2", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("PVP_Prepare", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_PVP_Prepare", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("BattlePVPMatchOnly", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_PVP_Matchmaking", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("BattleWarningPrompt", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_WarningPrompt", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleWeatherTips", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Weather_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleControllerPanel", "/Game/NewRoco/Modules/Core/Battle/LocalBattleRes/UMG_BattleControllerPanel", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattlePvpHintPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_PVP_Hint", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattlePopUpTips", "/Game/NewRoco/Modules/System/BattleUI/Res/PopupItem/UMG_Battle_Popup_CommandMgr", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("BattlePopUpDiscoveringDifferentlyColoredPet", "/Game/NewRoco/Modules/System/BattleUI/Res/PopupItem/UMG_Battle_Popup_DiscoveringDifferentlyColoredPet", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("HudPerceptionPanel", "/Game/NewRoco/Modules/System/MainUI/Res/UMG_Hud_PerceptionPanel", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleRunAwayTip", "/Game/NewRoco/Modules/System/BattleUI/Res/HUD/UMG_Battle_RunAway", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleClickTip", "/Game/NewRoco/Modules/System/BattleUI/Res/HUD/UMG_Battle_ClickTipUI_V", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("WishPower", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_WishPower", _G.Enum.UILayerType.UI_LAYER_BG, nil, "Point_in")
  self:RegPanel("Callname", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Callname", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Callname2", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleRenaming", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out")
  self:RegPanel("PetConfirm", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Pet_ConfirmationWizard", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleTutorial", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_Tutorial", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleTutorial1", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_Tutorial1", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("FinalBattleLifeBar", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_FinalBattleLifeBar", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Pet_RecoveryTime", "/Game/NewRoco/Modules/System/BattleUI/Res/PetGroupWarfare/UMG_Pet_RecoveryTime", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true, nil, nil, true)
  self:RegPanel("AutoBattleTestPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleDebugger/UMG_AutoBattleTestPanel", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("PVPDanGrading", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_PVP_DanGrading", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("PVPCeleritCarnety", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_PVP_CeleritCarnety", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("PVPValueNumber", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_PVP_ValueNumber", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("NameMask", "/Game/NewRoco/Modules/System/BattleUI/Res/HUD/UMG_NameMask", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PVPWaitingLoad", "/Game/NewRoco/Modules/System/BattleUI/Res/HUD/UMG_Battle_WaitLoading", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("MechanismValidation", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_MechanismValidation", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleAdditionalTarget", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_AdditionalTargetSilhouette", _G.Enum.UILayerType.UI_LAYER_BG)
  self:RegPanel("BattleBuffTips", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleBuff_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleBloodPulse", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BloodPulse_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("BattleChangePetConfirmPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_Battle_ChangePetConfirm_3", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, false)
  self:RegPanel("BattleUltimateSkill", "/Game/NewRoco/Modules/System/BattleUI/Res/Skill/UMG_Battle_UltimateSkill", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleTerritoryTrialSettlement", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_TerritoryTrialSettlement", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("WishPowerTutorial", "/Game/NewRoco/Modules/System/BattleUI/Res/UMG_WishPowerMask", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "Point_in", "Point_out", true)
  if not NRCEnv:IsLocalMode() then
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RegisterUIResumeCmd, "BattlePVPMatching", BattleUIModuleCmd.ResumeOpenPVPMatch)
  end
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROLE_LEAVE_NOTIFY, self.OnBattlePlayerLeaveNotify)
  self.DontDisablePanelList = {}
  local moduleData = self.data
  if moduleData then
    local popupDiscoveringDifferentlyColoredPetState = {}
    popupDiscoveringDifferentlyColoredPetState.isShow = false
    moduleData.popupDiscoveringDifferentlyColoredPetState = popupDiscoveringDifferentlyColoredPetState
  end
end

function BattleUIModule:RefWidget(widgetName, widget)
  self.widgetDict[widgetName] = widget
  self.widgetRefDict[widgetName] = UnLua.Ref(widget)
end

function BattleUIModule:UnRefWidget(widgetName)
  self.widgetDict[widgetName] = nil
  self.widgetRefDict[widgetName] = nil
end

function BattleUIModule:GetWidget(widgetName)
  return self.widgetDict[widgetName]
end

function BattleUIModule:ClearWidgetDict()
  self.widgetRefDict = {}
end

function BattleUIModule:ClosePvpEntryHud()
  if self:GetWidget("PvpHud") then
    Log.Error("BattleUIModuleCmd.ClosePvpEntryHud")
    _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.CloseBattleEntryHud)
    if BattleUtils.IsWeeklyChallenge() then
      BattleManager.vBattleField:MarkTodVolumeArrayDirty()
    end
    self:UnRefWidget("PvpHud")
  end
end

function BattleUIModule:RegPanel(name, path, layer, customDisableRendering, openAnim, closeAnim, enablePcEsc)
  local Data = _G.NRCPanelRegisterData()
  Data.panelName = name
  Data.panelPath = path
  Data.openAnimName = openAnim
  Data.closeAnimName = closeAnim
  Data.customDisableRendering = customDisableRendering or false
  Data.panelLayer = layer or _G.Enum.UILayerType.UI_LAYER_POPUP
  Data.enablePcEsc = enablePcEsc
  self:RegisterPanel(Data)
end

function BattleUIModule:OnActive()
end

function BattleUIModule:OpenBattleUltimateSkillUI(...)
  self:OpenPanel("BattleUltimateSkill", ...)
end

function BattleUIModule:CloseBattleUltimateSkillUI()
  if self:HasPanel("BattleUltimateSkill") then
    self:ClosePanel("BattleUltimateSkill")
  end
end

function BattleUIModule:TryBattleUltimateSkillClick(...)
  if self:HasPanel("BattleUltimateSkill") then
    local panel = self:GetPanel("BattleUltimateSkill")
    if panel then
      panel:PlayOutCallBack(...)
    end
  end
end

function BattleUIModule:OpenBattleFailedUI()
  BattleUtils.hasBattleFailedUI = true
  self:OpenPanel("BattleFailed")
end

function BattleUIModule:CloseBattleFailedUI()
  BattleUtils.hasBattleFailedUI = false
  self:ClosePanel("BattleFailed")
end

function BattleUIModule:OpenTransformLoadingUI()
  self:OpenPanel("TransformLoading")
end

function BattleUIModule:CloseTransformLoadingUI()
  self:ClosePanel("TransformLoading")
end

function BattleUIModule:OpenLoadingPanel(_param)
  local openReasonList = _param and _param.openReasonList or {
    BattleEnum.ShowBlackScreenReason.Default
  }
  local data = self.data
  local state = data and data.loadingBlackScreenState
  local openReasonMap = state and state.openReasonMap
  if openReasonMap then
    for i, reason in ipairs(openReasonList) do
      openReasonMap[reason] = true
    end
  end
  local anyReasonIsTrue = false
  if openReasonMap then
    for reason, value in pairs(openReasonMap) do
      if value then
        anyReasonIsTrue = true
        break
      end
    end
  end
  if anyReasonIsTrue then
    self:OpenPanel("BattleLoading", {
      owner = _param and _param.owner,
      callback = _param and _param.callback
    })
  else
    local callback = _param and _param.callback
    local owner = _param and _param.owner
    if callback then
      tcall(owner, callback)
    end
  end
end

function BattleUIModule:ForceCloseLoadingPanel()
  local data = self.data
  local state = data and data.loadingBlackScreenState
  local openReasonMap = state and state.openReasonMap
  if openReasonMap then
    for reason, value in pairs(openReasonMap) do
      openReasonMap[reason] = false
    end
  end
  self:ClosePanel("BattleLoading")
end

function BattleUIModule:CloseLoadingPanel(_param)
  local closeReasonList = _param and _param.closeReasonList or {
    BattleEnum.ShowBlackScreenReason.Default
  }
  local data = self.data
  local state = data and data.loadingBlackScreenState
  local openReasonMap = state and state.openReasonMap
  if openReasonMap then
    for i, reason in ipairs(closeReasonList) do
      openReasonMap[reason] = false
    end
  end
  local anyReasonIsTrue = false
  if openReasonMap then
    for reason, value in pairs(openReasonMap) do
      if value then
        anyReasonIsTrue = true
        break
      end
    end
  end
  if not self.bIsForbidCloseLoadingPanel and not anyReasonIsTrue then
    NRCEventCenter:DispatchEvent(BattleEvent.StartTweenOut, {
      owner = _param and _param.owner,
      callback = _param and _param.callback
    })
  else
    local callback = _param and _param.callback
    local owner = _param and _param.owner
    if callback then
      tcall(owner, callback)
    end
  end
end

function BattleUIModule:SetForbidCloseLoading(state)
  self.bIsForbidCloseLoadingPanel = state
end

function BattleUIModule:OpenMain()
  self.data:InitializeFsmData()
  self:OpenPanelEx("BattleMain", PriorityEnum.Passive_Battle_Panel)
  self:OpenGroupWarfare()
  _G.NRCEventCenter:RegisterEvent("ScreenClickModule", self, _G.NRCGlobalEvent.BattleScreenClick, self.HandleScreenClick)
end

function BattleUIModule:CloseMain()
  self.BattleFsmInfo:InitializeFsmData()
  self:ClosePanel("BattleMain")
  _G.NRCEventCenter:DispatchEvent(BattleEvent.OnCloseBattleMainWindow)
  self:OnCmdOpenBattleFsmUI(false)
  if self:HasPanel("BattleProcess_Visible") then
    self:ClosePanel("BattleProcess_Visible")
  end
  self:Close_AllTips()
  self:CloseSkillPickInfo()
  self:ClosePetGroupWarfare()
  self:ClosePetTheFinalBattle()
  _G.IsSetRenderOpacity = false
  _G.RenderOpacity = 1
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.BattleScreenClick, self.HandleScreenClick)
  self:OnCmdCloseWishPowerPanel()
  self:CloseFlowerTask()
  self:OnCmdCloseWarningPrompt()
end

function BattleUIModule:WaitingRecycleMain()
  local main = self:GetPanel("BattleMain")
  if main then
    main:WaitingRecycle()
  end
end

function BattleUIModule:CloseMainSubPanel()
  local main = self:GetPanel("BattleMain")
  if main then
    main:CloseSubPanel()
  end
end

function BattleUIModule:HideMain()
  if not self:HasPanel("BattleMain") then
    return
  end
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:HideAll()
  end
end

function BattleUIModule:CloseBattleCameraControl()
  self:ClosePanel("BattleCameraControl")
end

function BattleUIModule:OpenBattleCameraControl()
  if not self:HasPanel("BattleCameraControl") then
    self:OpenPanelEx("BattleCameraControl", PriorityEnum.Passive_Battle_Panel)
  end
end

function BattleUIModule:CloseBattleEntryHud()
  local panel = self:GetPanel("BattleEntryHud")
  if panel then
    panel:Quit()
  end
  self:ClosePanel("BattleEntryHud")
end

function BattleUIModule:OpenBattleEntryHud(...)
  self:OpenPanelEx("BattleEntryHud", PriorityEnum.Passive_Battle_Panel, ...)
  return true
end

function BattleUIModule:CloseBattleEntryHudVS()
  local panel = self:GetPanel("BattleEntryHudVS")
  if panel then
    panel:Quit()
  end
  self:ClosePanel("BattleEntryHudVS")
end

function BattleUIModule:OpenBattleEntryHudVS(...)
  self:OpenPanelEx("BattleEntryHudVS", PriorityEnum.Passive_Battle_Panel, ...)
  return true
end

function BattleUIModule:OnCmdOpenBattleAdditionalTarget(...)
  local flag = self:HasPanel("BattleAdditionalTarget")
  if flag then
    local panel = self:GetPanel("BattleAdditionalTarget")
    panel:RefreshUI(...)
  else
    self:OpenPanelEx("BattleAdditionalTarget", PriorityEnum.Passive_Battle_Panel, ...)
  end
end

function BattleUIModule:OnCmdHideBattleAdditionalTarget()
  local flag = self:HasPanel("BattleAdditionalTarget")
  if flag then
    local panel = self:GetPanel("BattleAdditionalTarget")
    panel:Hide()
  end
end

function BattleUIModule:OnCmdCloseBattleAdditionalTarget()
  self:ClosePanel("BattleAdditionalTarget")
end

function BattleUIModule:HideMainWindow(excludeDeck, withAnim, callback)
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:HideAll({
      excludeDeck = excludeDeck,
      withAnim = withAnim,
      callback = callback
    })
  end
end

function BattleUIModule:HideMainWindowWithOption(option)
  local hideAllOption = {}
  local type = option and option.type or BattleEnum.MainWindowHideAllType.Default
  if type == BattleEnum.MainWindowHideAllType.Default then
    hideAllOption = {
      excludeDeck = true,
      excludeTerritoryTrialUi = false,
      withAnim = true,
      callback = option and option.callback
    }
  elseif type == BattleEnum.MainWindowHideAllType.Custom then
    hideAllOption = option and option.customOption or {}
    if option and option.callback then
      hideAllOption.callback = option.callback
    end
  elseif type == BattleEnum.MainWindowHideAllType.RoundPlay then
    hideAllOption = {
      excludeDeck = true,
      excludeChatButton = true,
      excludeRecordButton = true,
      excludeSkillTransmissionItems = true,
      excludeTerritoryTrialUi = true,
      withAnim = true,
      callback = option and option.callback
    }
  elseif type == BattleEnum.MainWindowHideAllType.TeamEnterCatch then
    hideAllOption = {
      excludeDeck = false,
      excludeChatButton = true,
      excludeRecordButton = false,
      excludeSkillTransmissionItems = false,
      withAnim = true,
      callback = option and option.callback
    }
  elseif type == BattleEnum.MainWindowHideAllType.RebuildBattleField then
    hideAllOption = {
      excludeDeck = false,
      excludeSkillTransmissionItems = false,
      withAnim = true,
      callback = option and option.callback
    }
  end
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:HideAll(hideAllOption)
  end
end

function BattleUIModule:HideBattlePopupPanel()
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattleChangePetConfirmPanel)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseReservesPetsPanel)
end

function BattleUIModule:ChangeOperateMode(enum)
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:ChangeOperateMode(enum)
  end
end

function BattleUIModule:OnCmdShowBattleMainWeatherUi()
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:UpdateWeatherUI()
  end
end

function BattleUIModule:UpdateRound(round)
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:SetRound(round)
  end
end

function BattleUIModule:MainHideAll(excludeDeck, withAnim, callback)
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:HideAll({
      excludeDeck = excludeDeck,
      withAnim = withAnim,
      callback = callback
    })
  end
end

function BattleUIModule:HideHPBars()
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:HideHPBars()
  end
end

function BattleUIModule:ShowHPBars()
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    Panel:ShowHPBars()
  end
end

function BattleUIModule:ShowWaiting()
  local Panel = self:GetPanel("UMG_Battle_Bubble")
  if not Panel then
    self:OpenPanel("UMG_Battle_Bubble", PriorityEnum.Passive_Battle_Panel)
  elseif Panel.IsClosing then
    Panel.IsClosing = false
  end
end

function BattleUIModule:HideWaiting()
  local HasPanel = self:HasPanel("UMG_Battle_Bubble")
  if HasPanel then
    local Panel = self:GetPanel("UMG_Battle_Bubble")
    if Panel then
      Panel:Hide()
    end
  else
    self:ClosePanel("UMG_Battle_Bubble")
  end
end

function BattleUIModule:ShowEmoList()
  local HasPanel = self:HasPanel("UMG_Battle_Bubble")
  if HasPanel then
    local Panel = self:GetPanel("UMG_Battle_Bubble")
    if Panel then
      Panel:ShowEmoList(true)
    end
  end
end

function BattleUIModule:HideEmoList()
  local HasPanel = self:HasPanel("UMG_Battle_Bubble")
  if HasPanel then
    local Panel = self:GetPanel("UMG_Battle_Bubble")
    if Panel then
      Panel:HideEmoList(true)
    end
  end
end

function BattleUIModule:ShowChangePetConfirm(card, notHideClose, PetFeatureShowData, callbackOwner, openCallback, closeCallback)
  local HasPanel = self:HasPanel("Battle_ChangePetConfirm")
  if HasPanel then
    local Panel = self:GetPanel("Battle_ChangePetConfirm")
    if Panel then
      if PetFeatureShowData then
        if PetFeatureShowData.isShowPetSkill then
          Panel:ShowPetFeatureSkill(card)
        else
          Panel:Show(card)
          if true == notHideClose then
          else
            Panel:HideClose()
          end
        end
      else
        local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").PETTIPS
        _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
      end
    end
  else
    self:OpenPanel("Battle_ChangePetConfirm", card, nil, notHideClose, false, PetFeatureShowData, callbackOwner, openCallback, closeCallback)
  end
end

function BattleUIModule:HideChangePetConfirm(withAnim, bInBattle)
  local HasPanel = self:HasPanel("Battle_ChangePetConfirm")
  if HasPanel then
    local Panel = self:GetPanel("Battle_ChangePetConfirm")
    if Panel then
      Panel:Hide(withAnim, bInBattle)
    end
  else
    self:ClosePanel("Battle_ChangePetConfirm")
  end
end

function BattleUIModule:ShowChangePetConfirm3(card, isPvpPrepareEnemy, notHideClose, showStrongPoint, PetFeatureShowData, callbackOwner, openCallback, closeCallback)
  local HasPanel = self:HasPanel("Battle_ChangePetConfirm3")
  if HasPanel then
    local Panel = self:GetPanel("Battle_ChangePetConfirm3")
    if Panel then
      if PetFeatureShowData and PetFeatureShowData.isShowPetTips then
        Panel:ShowPetFeatureTips(card)
      elseif isPvpPrepareEnemy then
        Panel:SetPrepareEnemyInfo(card)
      else
        Panel:Show(card)
        if true == notHideClose then
        else
          Panel:HideClose()
        end
      end
    end
  else
    local newCard = setmetatable({}, {__index = card})
    newCard.isPvpPrepareEnemy = isPvpPrepareEnemy
    self:OpenPanel("Battle_ChangePetConfirm3", newCard, nil, notHideClose, showStrongPoint, PetFeatureShowData, callbackOwner, openCallback, closeCallback)
  end
end

function BattleUIModule:HideChangePetConfirm3(withAnim, bInBattle)
  local HasPanel = self:HasPanel("Battle_ChangePetConfirm3")
  if HasPanel then
    local Panel = self:GetPanel("Battle_ChangePetConfirm3")
    if Panel then
      Panel:Hide(withAnim, bInBattle)
    end
  else
    self:ClosePanel("Battle_ChangePetConfirm3")
  end
end

function BattleUIModule:CloseChangePetConfirm3()
  self:ClosePanel("Battle_ChangePetConfirm3")
end

function BattleUIModule:SwitchReservesPetsPanel(battlePlayer)
  if not battlePlayer then
    return
  end
  local PanelName = "BattleReservesPetsPanel"
  local HasPanel = self:HasPanel(PanelName)
  if HasPanel then
    local Panel = self:GetPanel(PanelName)
    if Panel:IsVisible() then
      self:ClosePanel(PanelName)
      return
    end
  end
  self:OpenPanel(PanelName, battlePlayer)
end

function BattleUIModule:CloseReservesPetsPanel()
  self:ClosePanel("BattleReservesPetsPanel")
end

function BattleUIModule:OpenEnter()
  self:OpenPanelEx("BattleEnter", PriorityEnum.Passive_Battle_Panel)
end

function BattleUIModule:CloseEnter()
  local Panel = self:GetPanel("BattleEnter")
  if Panel then
    Panel:PlayCloseAnimation()
  end
end

function BattleUIModule:ShowEnterAnimation(Skill)
  local Panel = self:GetPanel("BattleEnter")
  if Panel then
    Panel:ShowAnimation(Skill)
  end
end

function BattleUIModule:OnCmdOpenBattleGetGollumBall(...)
  self:OpenPanel("BattleGetGollumBall", ...)
end

function BattleUIModule:OnCmdCloseBattleGetGollumBall(...)
  if self:HasPanel("BattleGetGollumBall") then
    self:ClosePanel("BattleGetGollumBall", ...)
  end
end

function BattleUIModule:OpenSkillTips(ContextData, ShowBlur, bNeedDisableDescTip)
  self:OpenPanel("SkillTips", ContextData, ShowBlur, bNeedDisableDescTip)
end

function BattleUIModule:HasSkillTips()
  return self:HasPanel("SkillTips")
end

function BattleUIModule:UpdateSkillTips(ContextData)
  local SkillTips = self:GetPanel("SkillTips")
  if SkillTips then
    SkillTips:UpdateInfo(ContextData.skillData, ContextData.skillEntity)
  end
end

function BattleUIModule:OpenSkillPredictionTips(ContextData)
  self:OpenPanel("SkillPredictionTips", ContextData)
end

function BattleUIModule:CloseSkillPredictionTips()
  self:ClosePanel("SkillPredictionTips")
end

function BattleUIModule:OpenBuffInfo(ContextData)
  self:OpenPanel("BuffInfo", ContextData)
end

function BattleUIModule:CloseBuffInfo()
  self:ClosePanel("BuffInfo")
end

function BattleUIModule:OnShowBatleResult()
  self:ClosePanel("Battle_ChangePetConfirm")
  self:ClosePanel("Battle_ChangePetConfirm3")
  self:ClosePanel("BattleChangePetConfirmPanel")
  self:ClosePanel("BattleReservesPetsPanel")
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.CloseNounInterpretationTipsPanel)
end

function BattleUIModule:OpenEscapePanel(contextData)
  self:OpenPanel("EscapePanel", contextData)
end

function BattleUIModule:CloseEscapePanel()
  self:ClosePanel("EscapePanel")
end

function BattleUIModule:CloseSkillTips()
  self:ClosePanel("SkillTips")
end

function BattleUIModule:OnDeactive()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROLE_LEAVE_NOTIFY, self.OnBattlePlayerLeaveNotify)
  Log.Debug("BattleUIModule:OnDeactive")
  _G.BattleManager:ShutDown()
end

function BattleUIModule:OnCmdOpenBattlePetEvolutionResultPanel(_param1, _param2, _param3, _param4)
  Log.Debug("Battle Evo Progress: BattleUIModule OnCmdOpenBattlePetEvolutionResultPanel")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1068, "PetUIModule:OnCmdOpenPetEvolutionFinishPanel")
  self:OpenPanel("BattleEvolutionResult", {
    owner = _param1 and _param1.owner,
    callback = _param1 and _param1.callback,
    petbaseConfId = _param2,
    name = _param3,
    petGid = _param4
  })
end

function BattleUIModule:OnCmdCloseBattlePetEvolutionResultPanel()
  Log.Debug("Battle Evo Progress: BattleUIModule OnCmdCloseBattlePetEvolutionResultPanel")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "PetUIModule:OnCmdClosePetEvolutionFinishPanel")
end

function BattleUIModule:OnCmdOpenBattleEvolutionPanel(fromPetData, toPetData, bShow)
  Log.Debug("Battle Evo Progress: BattleUIModule OnCmdOpenBattleEvolutionPanel")
  local isOpening, _ = self:HasPanel("Battle_EvoPanel")
  if isOpening then
    local panel = self:GetPanel("Battle_EvoPanel")
    panel:OnShow(bShow)
  else
    self:OpenPanel("Battle_EvoPanel", fromPetData, toPetData, bShow)
  end
end

function BattleUIModule:OnCmdCloseBattleEvolutionPanel()
  Log.Debug("Battle Evo Progress: BattleUIModule OnCmdCloseBattleEvolutionPanel")
  local isOpening, _ = self:HasPanel("Battle_EvoPanel")
  if isOpening then
    local panel = self:GetPanel("Battle_EvoPanel")
    panel:DoClose()
  end
end

function BattleUIModule:TryDestroyBattleEvoActors()
  Log.Debug("Battle Evo Progress: BattleUIModule TryDestroyBattleEvoActors")
  local isOpening, _ = self:HasPanel("Battle_EvoPanel")
  if isOpening then
    local panel = self:GetPanel("Battle_EvoPanel")
    panel:DestroyActors()
  end
end

function BattleUIModule:OnCmdOpenPveEnterRoleHpPanel()
  self:OpenPanel("BattlePveRoleHpPanel")
end

function BattleUIModule:OnCmdClosePveEnterRoleHpPanel()
  self:ClosePanel("BattlePveRoleHpPanel")
end

function BattleUIModule:OnCmdOpenRoleHpCriticalTipPanel()
  self:OpenPanel("BattleRoleHpCriticalTipPanel")
end

function BattleUIModule:OnCmdCloseRoleHpCriticalTipPanel()
  self:ClosePanel("BattleRoleHpCriticalTipPanel")
end

function BattleUIModule:OnCmdOpenRoleHpDefeatedTipPanel(_param1)
  self:OpenPanel("BattleRoleHpDefeatedTipPanel", {
    player = _param1 and _param1.player,
    diePet = _param1 and _param1.diePet,
    isLast = _param1 and _param1.isLast,
    hp_result = _param1 and _param1.hp_result,
    hp_change = _param1 and _param1.hp_change,
    isShowLetter = _param1 and _param1.isShowLetter,
    pvp_result = _param1.pvp_result,
    pvp_change = _param1.pvp_change,
    pvpPlayer = _param1.pvpPlayer,
    black_hp_change = _param1 and _param1.black_hp_change or 0,
    black_hp_result = _param1 and _param1.black_hp_result or 0,
    tips_key = _param1.tips_key
  })
end

function BattleUIModule:OnCmdCloseRoleHpDefeatedTipPanel()
  self:ClosePanel("BattleRoleHpDefeatedTipPanel")
  _G.BattleManager.battleRuntimeData.isWaitingRoleHP = false
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PROCESS_ROLE_HP_END)
end

function BattleUIModule:OnCmdOpenPVPResult(param)
  self:OpenPanel("BattlePVPResult", param)
end

function BattleUIModule:OnCmdSetBattleTerritoryTrialResultState(nextState)
  local data = self.data
  local prevState = data and data.territoryTrailSettlementState
  if data then
    data.territoryTrailSettlementState = nextState
  end
  if self:HasPanel("BattleTerritoryTrialSettlement") then
    local panel = self:GetPanel("BattleTerritoryTrialSettlement")
    if UE.UObject.IsValid(panel) then
      panel:SetProps(nextState)
    end
  else
    local contextData = {}
    contextData.callbackOwner = self
    contextData.onOpenCallback = self.OnBattleTerritoryTrialOpen
    contextData.onCloseCallback = self.OnBattleTerritoryTrialClose
    self:OpenPanel("BattleTerritoryTrialSettlement", contextData)
  end
end

function BattleUIModule:OnBattleTerritoryTrialOpen(panel)
  local data = self.data
  local currentState = data and data.territoryTrailSettlementState
  if currentState then
    panel:SetProps(currentState)
  end
end

function BattleUIModule:OnBattleTerritoryTrialClose(panel)
end

function BattleUIModule:OnCmdPVPResultShowQuitState()
  if self:HasPanel("BattlePVPResult") then
    local panel = self:GetPanel("BattlePVPResult")
    if panel then
      panel:ShowQuitState()
    end
  end
end

function BattleUIModule:OnCmdOpenNpcBattleFailure(...)
  self:OpenPanel("BattleVictoryFailure", ...)
end

function BattleUIModule:OnCmdCloseNpcBattleFailure()
  local Haspanel = self:HasPanel("BattleVictoryFailure")
  if Haspanel then
    self:ClosePanel("BattleVictoryFailure")
  end
end

function BattleUIModule:OnCmdOpenAIVisible()
  self:OpenPanel("BattleAIVisible")
end

function BattleUIModule:OnCmdCloseAIVisible()
  self:ClosePanel("BattleAIVisible")
end

function BattleUIModule:OnCmdClosePVPResult()
  self:ClosePanel("BattlePVPResult")
end

function BattleUIModule:OnCmdBattleMainSetOpacity(Opacity)
  local Panel = self:GetPanel("BattleMain")
  if Panel then
    local renderOpacity = Opacity or 1
    Panel:SetPanelRenderOpacityState(renderOpacity)
  end
end

function BattleUIModule:OnCmdUpdatePVPPetInfo(_openPetData)
  local Haspanel = self:HasPanel("BattlePVPMatching")
  if Haspanel then
    local panel = self:GetPanel("BattlePVPMatching")
    panel:UpdatePetList(_openPetData)
  end
end

function BattleUIModule:OnCmdReceiveStartMatch(notify)
  if notify.state == ProtoEnum.PvpMatchState.PMS_MATCHING then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBattlePvpState, 1, notify.pvp_id)
  elseif notify.state == ProtoEnum.PvpMatchState.PMS_CANCEL or notify.state == ProtoEnum.PvpMatchState.PMS_MATCH_FAILED then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattlePvpState)
  elseif notify.state == ProtoEnum.PvpMatchState.PMS_MATCHED then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattlePvpHintPanel)
  end
  NRCEventCenter:DispatchEvent(NRCGlobalEvent.PlayerPVPMatchStateChange, notify.state)
end

function BattleUIModule:OnCmdOpen_Battle_Evolution_Select()
  self:OpenPanel("Battle_Evolution_Select")
end

function BattleUIModule:OnCmdClose_Battle_Evolution_Select()
  local isPanelOpened, _ = self:HasPanel("Battle_Evolution_Select")
  local isPanelOpening, _ = self:IsPanelInOpening("Battle_Evolution_Select")
  if isPanelOpened then
    local panel = self:GetPanel("Battle_Evolution_Select")
    panel:DoClose()
  elseif isPanelOpening then
    self:ClosePanel("Battle_Evolution_Select")
  end
end

function BattleUIModule:OnCmdOpenAndSet_Battle_Round_Start(curRestTime, _countdown)
  local HasPanel = self:HasPanel("Battle_Round_Start")
  if not HasPanel then
    local contextData = {
      displayType = BattleEnum.UmgBattleRoundStartDisplayType.CountDown,
      arg1 = curRestTime,
      arg2 = _countdown,
      callbackOwner = self,
      onOpenCallback = self.OnBattleRoundStartOpen,
      onCloseCallback = self.OnBattleRoundStartClose
    }
    self:OpenPanel("Battle_Round_Start", contextData)
  else
    local Panel = self:GetPanel("Battle_Round_Start")
    Panel:SetCD(curRestTime)
    Panel:BurnTime(_countdown)
  end
end

function BattleUIModule:OnCmdOpenBattle_Round_StartAndDisplayRestRound(restRound)
  local HasPanel = self:HasPanel("Battle_Round_Start")
  if not HasPanel then
    local contextData = {
      displayType = BattleEnum.UmgBattleRoundStartDisplayType.RestRound,
      arg1 = restRound,
      callbackOwner = self,
      onOpenCallback = self.OnBattleRoundStartOpen,
      onCloseCallback = self.OnBattleRoundStartClose
    }
    self:OpenPanel("Battle_Round_Start", contextData)
  else
    local Panel = self:GetPanel("Battle_Round_Start")
    Panel:DisplayRestRound(restRound)
  end
end

function BattleUIModule:OnBattleRoundStartOpen()
  if self.data.closeBattleRoundStartContextData then
    local displayType = self.data.closeBattleRoundStartContextData.displayType
    local hidePanel = self.data.closeBattleRoundStartContextData.hidePanel
    self:OnCmdClose_Battle_Round_Start(displayType, hidePanel)
    self.data.closeBattleRoundStartContextData = nil
  end
end

function BattleUIModule:OnBattleRoundStartClose()
  if self.data.closeBattleRoundStartContextData then
    self.data.closeBattleRoundStartContextData = nil
  end
end

function BattleUIModule:OnCmdClose_Battle_Round_Start(displayType, hidePanel)
  self.data.closeBattleRoundStartContextData = nil
  if self:HasPanel("Battle_Round_Start") then
    local Panel = self:GetPanel("Battle_Round_Start")
    if Panel.currentDisplayType == displayType or Panel.currentDisplayType == BattleEnum.UmgBattleRoundStartDisplayType.None then
      if hidePanel then
        Panel:Hide(true)
      else
        self:ClosePanel("Battle_Round_Start")
      end
    end
  elseif self:IsPanelInOpening("Battle_Round_Start") then
    self.data.closeBattleRoundStartContextData = {displayType = displayType, hidePanel = hidePanel}
  end
end

function BattleUIModule:OnCmdOpen_ReplayPanel()
  self:OpenPanel("Battle_Replay")
end

function BattleUIModule:OnCmdClose_ReplayPanel()
  self:ClosePanel("Battle_Replay")
end

function BattleUIModule:OnCmdClose_Information_Recording()
  self:ClosePanel("Information_Recording")
end

function BattleUIModule:OnCmdOpen_Information_Recording(curRound, preRoundData)
  self:OpenPanel("Information_Recording", curRound, preRoundData)
end

function BattleUIModule:OnCmdOpenWeatherTips()
  self:OpenPanel("BattleWeatherTips")
end

function BattleUIModule:OnCmdCloseWeatherTips()
  self:ClosePanel("BattleWeatherTips")
end

function BattleUIModule:Close_AllTips()
  self:ClosePanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
end

function BattleUIModule:OnCmdOpen_SurrenderPanel(...)
  self:OpenPanel("Battle_Plight", ...)
end

function BattleUIModule:OnCmdOpenBattleFsmUI(_IsOpen)
  if _IsOpen then
    local ActivateState = self.BattleFsmInfo:GetActivateState()
    local FsmStateListInfo = self.BattleFsmInfo:GetFsmStateListInfo()
    self:OpenPanel("Battle_Fsm", ActivateState, FsmStateListInfo)
  else
    self:ClosePanel("Battle_Fsm")
  end
end

function BattleUIModule:OnCmdOpenBattleProcessUI()
  if not self:HasPanel("BattleProcess_Visible") then
    self:OpenPanel("BattleProcess_Visible")
  end
end

function BattleUIModule:OnCmdCloseBattleProcessUI()
  if self:HasPanel("BattleProcess_Visible") then
    self:ClosePanel("BattleProcess_Visible")
  end
end

function BattleUIModule:OnCmdOpenPetCatchPanel(IsOpen, _Param, PetLevel, PrivilegeCliChannel, MedalReward)
  if IsOpen then
    self:OpenPanel("Pet_Catch", _Param, PetLevel, PrivilegeCliChannel, MedalReward)
  else
    self:ClosePanel("Pet_Catch")
  end
end

function BattleUIModule:OnCmdOpenGetItemsPanel(IsOpen, _Param, PrivilegeCliChannel, MedalReward)
  if IsOpen then
    self:OpenPanel("Get_Items", _Param, PrivilegeCliChannel, MedalReward)
  else
    self:ClosePanel("Get_Items")
  end
end

function BattleUIModule:OnCmdIsHasPetCatchPanel()
  return self:HasPanel("Pet_Catch")
end

function BattleUIModule:OnCmdShowRecoveryItemSelect()
  if self:HasPanel("UMG_Pet_GroupWarfare") then
    local panel = self:GetPanel("UMG_Pet_GroupWarfare")
    panel.CanvasPanel_40:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    panel:SetRecoveryItemInfo()
  end
end

function BattleUIModule:OnCmdUpdateStarChain()
  if self:HasPanel("UMG_Pet_GroupWarfare") then
    local panel = self:GetPanel("UMG_Pet_GroupWarfare")
    panel:UpdateStarChain()
  end
  do
    local ballData = _G.BattleManager.battleRuntimeData.catchInfo and _G.BattleManager.battleRuntimeData.catchInfo.currentBallData
    local isSelectRecoveryItemEnough = _G.NRCModeManager:DoCmd(BattleUIModuleCmd.IsSelectRecoveryItemEnough)
    if ballData and isSelectRecoveryItemEnough then
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, ballData)
    end
  end
end

function BattleUIModule:OnCmdShowStarDebrisText(bIsShow)
  if self:HasPanel("UMG_Pet_GroupWarfare") then
    local panel = self:GetPanel("UMG_Pet_GroupWarfare")
    if bIsShow then
      panel.Text_reminder:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      panel.Text_reminder:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function BattleUIModule:OnCmdShowOrHideMoneyBtn(bIsHide)
  if self:HasPanel("Pet_RecoveryTime") then
    local panel = self:GetPanel("Pet_RecoveryTime")
    panel:ShowOrHideMoneyBtn(bIsHide)
  end
end

function BattleUIModule:OnCmdRefreshCatchConsumeInfo(itemType)
  if self:HasPanel("UMG_Pet_GroupWarfare") then
    local panel = self:GetPanel("UMG_Pet_GroupWarfare")
    panel:RefreshCatchConsumeInfo(itemType)
  end
end

function BattleUIModule:OnCmdSelectRecoveryItem(selectItemIndex)
  if self:HasPanel("UMG_Pet_GroupWarfare") then
    local panel = self:GetPanel("UMG_Pet_GroupWarfare")
    panel:SelectRecoveryItem(selectItemIndex)
  end
end

function BattleUIModule:OnCmdSetSelectRecoveryItem(selectRecoveryItemType)
  self.data.selectRecoveryItem = selectRecoveryItemType
  do
    local ballData = _G.BattleManager.battleRuntimeData.catchInfo and _G.BattleManager.battleRuntimeData.catchInfo.currentBallData
    if ballData then
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, ballData)
    end
  end
end

function BattleUIModule:OnCmdGetSelectRecoveryItem()
  local selectRecoveryItem = self.data.selectRecoveryItem
  return selectRecoveryItem
end

function BattleUIModule:OnCmdIsSelectRecoveryItemEnough(showTipsIfNotEnough)
  local selectRecoveryItemType = _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.GetSelectRecoveryItem) or -1
  local StarNum = selectRecoveryItemType > 0 and _G.DataModelMgr.PlayerDataModel:GetVItemCount(selectRecoveryItemType) or 0
  local CostStar = _G.DataConfigManager:GetPetGlobalConfig("team_battle_starlink").num
  local enough = StarNum >= CostStar
  if not enough and showTipsIfNotEnough then
    local isCall = false
    if BattleUtils.IsBloodTeam() and self:HasPanel("UMG_Pet_GroupWarfare") then
      isCall = true
      _G.BattleEventCenter:Dispatch(BattleEvent.BLOOD_HIDE_MONEY)
      _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFlag, true)
      _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.SetShopSourceReturnFunc, function()
        _G.BattleEventCenter:Dispatch(BattleEvent.BLOOD_SHOW_MONEY)
      end)
    end
    if selectRecoveryItemType == _G.Enum.VisualItem.VI_STAR then
      _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenRecoveryTime, false, StarChainEnum.OpenType.Common, isCall)
    elseif selectRecoveryItemType == _G.Enum.VisualItem.VI_STAR_DEBRIS then
      _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenStarDebrisRecoveryTime, false, StarChainEnum.OpenType.Common, isCall, _G.Enum.VisualItem.VI_STAR_DEBRIS, nil)
    end
  end
  return enough
end

function BattleUIModule:OnCmdIsAnyRecoveryItemEnough()
  local selectRecoveryItemType = _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.GetSelectRecoveryItem) or -1
  local StarNum = selectRecoveryItemType > 0 and _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR) or 0
  local StarDebrisNum = selectRecoveryItemType > 0 and _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS) or 0
  local CostStar = _G.DataConfigManager:GetPetGlobalConfig("team_battle_starlink").num
  local enough = StarNum >= CostStar or StarDebrisNum >= CostStar
  return enough
end

function BattleUIModule:OnCmdOpenSkillPickPanel(_IsShow)
  local isOpening, _ = self:HasPanel("Battle_Skillpick_List")
  if isOpening then
    local Panel = self:GetPanel("Battle_Skillpick_List")
    if (Panel:GetVisibility() == UE4.ESlateVisibility.Collapsed or Panel:GetVisibility() == UE4.ESlateVisibility.Hidden) and _IsShow then
      self:EnablePanel("Battle_Skillpick_List")
    elseif Panel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible and not _IsShow then
      self:DisablePanel("Battle_Skillpick_List")
    end
  elseif _IsShow then
    self:OpenPanel("Battle_Skillpick_List")
  end
end

function BattleUIModule:CloseSkillPickInfo()
  local isOpening, _ = self:HasPanel("Battle_Skillpick_List")
  if isOpening then
    self:ClosePanel("Battle_Skillpick_List")
  end
end

function BattleUIModule:OpenGroupWarfare()
  if BattleUtils.IsTeam() then
    self:OnCmdOpenPetGroupWarfare()
  elseif BattleUtils.IsB1FinalBattleP3() then
    self:OnCmdOpenPetTheFinalBattle()
  end
end

function BattleUIModule:ShowOrHideAdditionalTarget(_IsShow)
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.ShowOrHideAdditionalTarget, _IsShow)
end

function BattleUIModule:OnCmdOpenPetTheFinalBattle()
  self:OpenPanel("UMG_Pet_TheFinalBattle")
end

function BattleUIModule:ClosePetTheFinalBattle()
  local isOpening, _ = self:HasPanel("UMG_Pet_TheFinalBattle")
  if isOpening then
    self:ClosePanel("UMG_Pet_TheFinalBattle")
  end
end

function BattleUIModule:OnCmdActivatePetTheFinalBattle(_IsActivate)
  local isOpening, _ = self:HasPanel("UMG_Pet_TheFinalBattle")
  if isOpening then
    local Panel = self:GetPanel("UMG_Pet_TheFinalBattle")
    if (Panel:GetVisibility() == UE4.ESlateVisibility.Collapsed or Panel:GetVisibility() == UE4.ESlateVisibility.Hidden) and _IsActivate then
      Panel:ShowPanel()
    elseif Panel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible and not _IsActivate then
      Panel:HidePanel()
    end
  end
end

function BattleUIModule:OnCmdOpenPetGroupWarfare()
  self:OpenPanel("UMG_Pet_GroupWarfare")
end

function BattleUIModule:ClosePetGroupWarfare()
  local isOpening, _ = self:HasPanel("UMG_Pet_GroupWarfare")
  if isOpening then
    self:ClosePanel("UMG_Pet_GroupWarfare")
  end
end

function BattleUIModule:OnCmdActivatePetGroupWarfare(_IsActivate)
  local isOpening, _ = self:HasPanel("UMG_Pet_GroupWarfare")
  if isOpening then
    local Panel = self:GetPanel("UMG_Pet_GroupWarfare")
    if (Panel:GetVisibility() == UE4.ESlateVisibility.Collapsed or Panel:GetVisibility() == UE4.ESlateVisibility.Hidden) and _IsActivate then
      Panel:ShowPanel()
    elseif Panel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible and not _IsActivate then
      Panel:HidePanel()
    end
  end
end

function BattleUIModule:OnCmdIsHasFsmUIPanel()
  local HasPanel = self:HasPanel("Battle_Fsm")
  if HasPanel then
    local Panel = self:GetPanel("Battle_Fsm")
    return true, Panel
  end
  return false
end

function BattleUIModule:OnCmdSavePreProcessCmd(cmd)
  self.data:AddPreProcessCmd(cmd)
  local HasPanel = self:HasPanel("Battle_Fsm")
  if HasPanel then
    local Panel = self:GetPanel("Battle_Fsm")
    Panel:UpdatePreProcessList()
  end
end

function BattleUIModule:OnCmdGetPreProcessCmd()
  return self.data:GetPreProcessCmd()
end

function BattleUIModule:OnCmdSaveBattleNotify(notifyCmdId)
  self.data:AddBattleNotify(notifyCmdId)
  local HasPanel = self:HasPanel("Battle_Fsm")
  if HasPanel then
    local Panel = self:GetPanel("Battle_Fsm")
    Panel:UpdatePreProcessList_BattleNotify()
  end
end

function BattleUIModule:OnCmdGetBattleNotify()
  return self.data:GetBattleNotify()
end

function BattleUIModule:OnCmdSet_Information_Recording(round)
  local HasPanel = self:HasPanel("Information_Recording")
  if HasPanel then
    local Panel = self:GetPanel("Information_Recording")
    Panel:RoundStart(round)
  end
end

function BattleUIModule:OnCmdInformationRecordingCloseHyperLink()
  local HasPanel = self:HasPanel("Information_Recording")
  if HasPanel then
    local Panel = self:GetPanel("Information_Recording")
    Panel:CloseHyperLink()
  end
end

function BattleUIModule:OnCmdInformationRecordingHyperLinkClick(descText, index)
  local HasPanel = self:HasPanel("Information_Recording")
  if HasPanel then
    local Panel = self:GetPanel("Information_Recording")
    Panel:HyperLinkClick(descText, index)
  end
end

function BattleUIModule:OnCmdOpenBattleRedPanel()
  local boo, v = self:HasPanel("BattleRedPanel")
  if v > 0 then
    return
  else
    self:OpenPanel("BattleRedPanel")
  end
end

function BattleUIModule:OnCmdCloseBattleRedPanel()
  self:ClosePanel("BattleRedPanel")
end

function BattleUIModule:OnCmdOpenPVPMatch(data, IsPetTeamBack)
  if self:HasPanel("BattlePVPMatchOnly") then
  else
    self:OpenPanel("BattlePVPMatchOnly", data)
  end
end

function BattleUIModule:OpenPVPMatch(rsp)
  local boo, v = self:HasPanel("BattlePVPMatching")
  if v > 0 then
    return
  elseif rsp.is_open == true then
    self:OpenPanel("BattlePVPMatching")
  else
    return
  end
end

function BattleUIModule:OnCmdResumeOpenPVPMatch()
  self:SendZonePvpUiControlReq(true)
end

function BattleUIModule:SendZonePvpUiControlReq(bOpen)
  local req = _G.ProtoMessage:newZoneScenePvpUiControlReq()
  req.is_open = bOpen
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PVP_UI_CONTROL_REQ, req, self, self.OpenPVPMatch)
end

function BattleUIModule:OnCmdOpenBattleUIBackpackTips(data)
  local boo, v = self:HasPanel("BattleUIBackpackTips")
  if v > 0 then
    return
  else
    self:OpenPanel("BattleUIBackpackTips", data)
  end
end

function BattleUIModule:OnCmdCloseBattleUIBackpackTips(data)
  self:ClosePanel("BattleUIBackpackTips")
end

function BattleUIModule:OnCmdOpenBattleNpcAutoEscapePanel(data)
  self:OpenPanel("BattleNpcAutoEscapeSelectPanel", data)
end

function BattleUIModule:OnCmdCloseBattleNpcAutoEscapePanel(data)
  self:ClosePanel("BattleNpcAutoEscapeSelectPanel")
end

function BattleUIModule:OnCmdOpenPVPMatchTeam()
  self:OpenPanel("BattlePVPMatching")
end

function BattleUIModule:OnCmdClosePVPMatch()
  if self:HasPanel("BattlePVPMatching") then
    local panel = self:GetPanel("BattlePVPMatching")
    if panel then
      panel:OnCloseButtonClicked()
    end
  end
end

function BattleUIModule:OnCmdChangePVPMatchTeam(curTeamIndex)
  if self:HasPanel("BattlePVPMatching") then
    local panel = self:GetPanel("BattlePVPMatching")
    if panel then
      panel:RefreshPetTeamList(curTeamIndex)
    end
  end
end

function BattleUIModule:OnCmdChangePVPBattleType(type)
  if self:HasPanel("BattlePVPMatching") then
    local panel = self:GetPanel("BattlePVPMatching")
    if panel then
      panel:SetPanelInfoByType(type)
    end
  end
end

function BattleUIModule:OnCmdStartMatchByType(bCanMatch)
  if self:HasPanel("BattlePVPMatching") then
    local panel = self:GetPanel("BattlePVPMatching")
    if panel then
      panel:OnBtnMatchingClick(bCanMatch)
    end
  end
end

function BattleUIModule:OnCmdSetPVPPetTip(bShow, PetInfo)
  if self:HasPanel("BattlePVPMatching") then
    local panel = self:GetPanel("BattlePVPMatching")
    if panel then
      panel:ShowRightTips(bShow, PetInfo)
    end
  end
end

function BattleUIModule:OnCmdEnterPVP()
  if self:HasPanel("BattlePVPMatchOnly") then
    local panel = self:GetPanel("BattlePVPMatchOnly")
    if panel then
      panel:MatchSuccess()
    end
  end
end

function BattleUIModule:ShowMatchSuccText(notify)
  if self:HasPanel("BattlePVPMatchOnly") then
    local panel = self:GetPanel("BattlePVPMatchOnly")
    if panel then
      panel:ShowMatchSuccText(notify)
    end
  end
end

function BattleUIModule:PlayVideo(param)
  self:OpenPanel("BattleVideo", param)
end

function BattleUIModule:ClosePVPMatchPanel()
  if self:HasPanel("BattlePVPMatchOnly") then
    local panel = self:GetPanel("BattlePVPMatchOnly")
    panel:OnCloseMatch()
  end
end

function BattleUIModule:HandleScreenClick(location)
  local debugLine = UE4.EDrawDebugTrace.None
  local drawTime = 0
  if _G.EnableDebugSelectPet then
    debugLine = UE4.EDrawDebugTrace.ForDuration
    drawTime = 10
  end
  local origin, dir = UE4.UNRCStatics.Abs_ScreenPosToLineTraceVector(UE4.FVector2D(location.X, location.Y))
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(UE4Helper.GetCurrentWorld(), origin, origin + dir * 3000, {
    UE4.ECollisionChannel.ECC_Pawn
  }, true, nil, debugLine, nil, true, UE4.FLinearColor(0, 1, 0, 1), UE4.FLinearColor(1, 1, 0, 1), drawTime)
  if isHit then
    for i = 1, hitResults:Length() do
      local hitResult = hitResults:Get(i)
      local hitactor = hitResult.Actor
      Log.Debug("BattleUIModule HandleScreenClick:", hitactor:GetName(), hitResults:Length())
      if hitactor:GetName() ~= nil and hitactor:IsA(UE4.ARocoCharacter) then
        local battlePet = BattleManager.battlePawnManager:GetBattlePetByActor(hitactor)
        if battlePet then
          battlePet:OnPetClick()
          Log.Debug("BattleUIModule HandleScreenClick onclick pet:", battlePet.guid)
        end
      end
    end
  end
end

function BattleUIModule:OnPlayerPKInfoNotify(notify)
  if self:HasPanel("PVP_Prepare") then
  else
    self:OpenPanel("PVP_Prepare", notify)
  end
end

function BattleUIModule:OnCmdZonePkExitReq()
  local req = _G.ProtoMessage:newZonePkExitReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PK_EXIT_REQ, req, self, self.OnCmdZonePkExitRsp)
end

function BattleUIModule:OnCmdZonePkExitRsp(rsp)
end

function BattleUIModule:OnCmdZonePkSelectPetReq(gid)
  local req = _G.ProtoMessage:newZonePkSelectPetReq()
  req.pet_gid = gid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PK_SELECT_PET_REQ, req, self, self.OnCmdZonePkSelectPetRsp)
end

function BattleUIModule:OnCmdZonePkSelectPetRsp(rsp)
end

function BattleUIModule:OnCmdZonePkCancelPrepareReq()
  local req = _G.ProtoMessage:newZonePkCancelPrepareReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PK_CANCEL_PREPARE_REQ, req, self, self.OnCmdZonePkCancelPrepareRsp)
end

function BattleUIModule:OnCmdZonePkCancelPrepareRsp(rsp)
end

function BattleUIModule:OpenPVP_PreparePanel(arg)
  if self:GetPVP_PreparePanelState() == false then
    NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
    self:OpenPanel("PVP_Prepare", arg)
  end
end

function BattleUIModule:GetPVP_PreparePanelState()
  if self:HasPanel("PVP_Prepare") then
    return true
  else
    return false
  end
end

function BattleUIModule:OnCmdClosePVPPreparePanel()
  self:ClosePanel("PVP_Prepare")
end

function BattleUIModule:SetPVP_PrepareSelectPet(index, selected)
  if self:HasPanel("PVP_Prepare") then
    local panel = self:GetPanel("PVP_Prepare")
    panel:SetSelectPet(index, selected)
  end
end

function BattleUIModule:OpenPreparePanelPetInfo(index, isLeft)
  if self:HasPanel("PVP_Prepare") then
    local panel = self:GetPanel("PVP_Prepare")
    panel:OpenPetInfoTips(index, isLeft)
  end
end

function BattleUIModule:GetPlayerPVPReadyState()
  if self:HasPanel("PVP_Prepare") then
    local panel = self:GetPanel("PVP_Prepare")
    return panel.ready
  else
    return nil
  end
end

function BattleUIModule:OnCmdOpenWarningPrompt(...)
  if not self:HasPanel("BattleWarningPrompt") then
    self:OpenPanel("BattleWarningPrompt", ...)
  end
end

function BattleUIModule:OnCmdHideWarningPrompt()
  if self:HasPanel("BattleWarningPrompt") then
    local panel = self:GetPanel("BattleWarningPrompt")
    panel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function BattleUIModule:OnCmdCloseWarningPrompt()
  if self:HasPanel("BattleWarningPrompt") then
    local panel = self:GetPanel("BattleWarningPrompt")
    panel:PlayEndAnim()
  end
end

function BattleUIModule:OnCmdOpenBattleControllerPanel(...)
  if not self:HasPanel("BattleControllerPanel") then
    self:OpenPanel("BattleControllerPanel", ...)
  end
end

function BattleUIModule:OnCmdCloseBattleControllerPanel()
  if self:HasPanel("BattleControllerPanel") then
    self:ClosePanel("BattleControllerPanel")
  end
end

function BattleUIModule:OnCmdOpenBattlePvpHintPanel(...)
  if not self:HasPanel("BattlePvpHintPanel") then
    self:OpenPanel("BattlePvpHintPanel", ...)
  end
end

function BattleUIModule:OnCmdCloseBattlePvpHintPanel()
  if self:HasPanel("BattlePvpHintPanel") then
    local Panel = self:GetPanel("BattlePvpHintPanel")
    if Panel and UE.UObject.IsValid(Panel) then
      Panel:TryCloseHintPanel()
    end
  end
end

function BattleUIModule:OnCmdOpenBattlePvpState(MatchNum, PvpId)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBattlePvpHintPanel, MatchNum)
  if self.PvpBattleAirWallId and self.PvpBattleAirWallId > 0 then
    self.PvpBattleAirWallId = nil
    _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.DestroyWall, self.PvpBattleAirWallId)
  end
  if PvpId > 0 then
    local pvpConf = _G.DataConfigManager:GetPvpConf(PvpId)
    if pvpConf.air_wall then
      self.PvpBattleAirWallId = pvpConf.air_wall
      self.curMatchPvpId = PvpId
      _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.CreateWall, self.PvpBattleAirWallId, false)
    end
  end
end

function BattleUIModule:OnCmdCloseBattlePvpState(...)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattlePvpHintPanel)
  if self.PvpBattleAirWallId and self.PvpBattleAirWallId > 0 then
    _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.DestroyWall, self.PvpBattleAirWallId)
    self.PvpBattleAirWallId = nil
    self.curMatchPvpId = nil
  end
end

function BattleUIModule:OnDestruct()
  local confName = _G.DataConfigManager.ConfigTableId.SKILL_CONF
  self:ClearConf(confName)
  self.BattleFsmInfo:CleanFsmManager()
  self.BattleFsmInfo = nil
end

function BattleUIModule:OnLogin(isRelogin)
  if isRelogin then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.ClosePVP_PreparePanel)
  end
end

function BattleUIModule:OnCmdOpenBattlePopUpTips()
  self:OpenPanel("BattlePopUpTips")
end

function BattleUIModule:OnCmdCloseBattlePopUpTips()
  self:ClosePanel("BattlePopUpTips")
end

function BattleUIModule:OnCmdShowOrHideBattlePopUpTips(_IsShow)
  if self:HasPanel("BattlePopUpTips") then
    local Panel = self:GetPanel("BattlePopUpTips")
    if _IsShow then
      Panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      Panel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function BattleUIModule:OnCmdOpenBattlePopUpDiscoveringDifferentlyColoredPetTips(openTimeSeconds)
  openTimeSeconds = openTimeSeconds or 2
  local currState, nextState = self:GetCurrAndNextBattlePopUpDiscoveringDifferentlyColoredPetState()
  local currDelayId = currState and currState.delayCloseId
  if currDelayId then
    _G.DelayManager:CancelDelayById(currDelayId)
  end
  nextState.isShow = true
  openTimeSeconds = math.max(openTimeSeconds, 0.1)
  local delayId = _G.DelayManager:DelaySeconds(openTimeSeconds, function()
    self:OnDelayBattlePopUpDiscoveringDifferentlyColoredPetCloseTimeout()
  end)
  nextState.delayCloseId = delayId
  self:SetBattlePopUpDiscoveringDifferentlyColoredPetState(nextState)
end

function BattleUIModule:OnCmdCloseBattlePopUpDiscoveringDifferentlyColoredPetTips()
  local _, nextState = self:GetCurrAndNextBattlePopUpDiscoveringDifferentlyColoredPetState()
  nextState.isShow = false
  self:SetBattlePopUpDiscoveringDifferentlyColoredPetState(nextState)
end

function BattleUIModule:OnDelayBattlePopUpDiscoveringDifferentlyColoredPetCloseTimeout()
  local _, nextState = self:GetCurrAndNextBattlePopUpDiscoveringDifferentlyColoredPetState()
  nextState.delayCloseId = nil
  self:SetBattlePopUpDiscoveringDifferentlyColoredPetState(nextState)
  self:OnCmdCloseBattlePopUpDiscoveringDifferentlyColoredPetTips()
end

function BattleUIModule:GetBattlePopUpDiscoveringDifferentlyColoredPetState()
  local moduleData = self.data
  local state = moduleData and moduleData.popupDiscoveringDifferentlyColoredPetState or {}
  return state
end

function BattleUIModule:SetBattlePopUpDiscoveringDifferentlyColoredPetState(nextState)
  local moduleData = self.data
  local prevState = moduleData and moduleData.popupDiscoveringDifferentlyColoredPetState or {}
  if moduleData then
    moduleData.popupDiscoveringDifferentlyColoredPetState = nextState
  end
  self:OnBattlePopUpDiscoveringDifferentlyColoredPetStateUpdate(prevState, nextState)
end

function BattleUIModule:GetCurrAndNextBattlePopUpDiscoveringDifferentlyColoredPetState()
  local moduleData = self.data
  local currState = moduleData and moduleData.popupDiscoveringDifferentlyColoredPetState or {}
  local nextState = {}
  table.copy(currState, nextState)
  return currState, nextState
end

function BattleUIModule:OnBattlePopUpDiscoveringDifferentlyColoredPetStateUpdate(prevState, currState)
  local prevIsShow = prevState and prevState.isShow or false
  local currIsShow = currState and currState.isShow or false
  local panelName = "BattlePopUpDiscoveringDifferentlyColoredPet"
  if self:HasPanel(panelName) then
    local panel = self:GetPanel(panelName)
    self:RenderBattlePopUpDiscoveringDifferentlyColoredPet(panel, currState)
  end
  if prevIsShow ~= currIsShow and currIsShow and not self:HasPanel(panelName) then
    local OnActiveCallback = _G.MakeWeakFunctor(self, self.OnBattlePopUpDiscoveringDifferentlyColoredPetTipsActive)
    self:OpenPanel(panelName, OnActiveCallback)
  end
end

function BattleUIModule:RenderBattlePopUpDiscoveringDifferentlyColoredPet(panel, state)
  if UE.UObject.IsValid(panel) then
    local isShow = state and state.isShow or false
    local props = {}
    props.isShow = isShow
    props.OnIsShowDisplayChanged = _G.MakeWeakFunctor(self, self.OnBattlePopUpDiscoveringDifferentlyColoredPetTipsIsShowDisplayChanged)
    panel:SetProps(props)
  end
end

function BattleUIModule:OnBattlePopUpDiscoveringDifferentlyColoredPetTipsActive(panelInstance)
  local state = self:GetBattlePopUpDiscoveringDifferentlyColoredPetState()
  self:RenderBattlePopUpDiscoveringDifferentlyColoredPet(panelInstance, state)
end

function BattleUIModule:OnBattlePopUpDiscoveringDifferentlyColoredPetTipsIsShowDisplayChanged(currIsDisplay)
  currIsDisplay = currIsDisplay or false
  local moduleData = self.data
  local currData = moduleData and moduleData.popupDiscoveringDifferentlyColoredPetState or {}
  local currIsShow = currData and currData.isShow or false
  local panelName = "BattlePopUpDiscoveringDifferentlyColoredPet"
  if not currIsDisplay and not currIsShow and self:HasPanel(panelName) then
    self:ClosePanel(panelName)
  end
end

function BattleUIModule:OnCmdOpenHudPerceptionPanel()
  self:OpenPanel("HudPerceptionPanel")
end

function BattleUIModule:OnCmdGetHudPerceptionPanel()
  if self:HasPanel("HudPerceptionPanel") then
    local panel = self:GetPanel("HudPerceptionPanel")
    return panel
  end
end

function BattleUIModule:OnCmdOpenBattleRunAwayTip(...)
  self:OpenPanel("BattleRunAwayTip", ...)
end

function BattleUIModule:OnCmdShowBattleRunAwayTip(...)
  if self:HasPanel("BattleRunAwayTip") then
    local panel = self:GetPanel("BattleRunAwayTip")
    panel.ForceHide = false
    panel:Show()
  end
end

function BattleUIModule:OnCmdHideBattleRunAwayTip(...)
  if self:HasPanel("BattleRunAwayTip") then
    local panel = self:GetPanel("BattleRunAwayTip")
    panel.ForceHide = true
    panel:Hide()
  end
end

function BattleUIModule:OnCmdOpenWishPowerPanel(...)
  if not self:HasPanel("WishPower") then
    self:OpenPanel("WishPower", ...)
  else
    local panel = self:GetPanel("WishPower")
    panel:OnDialogueEnded()
  end
end

function BattleUIModule:OnCmdCloseWishPowerPanel()
  local bHasPanel = self:HasPanel("WishPower")
  if bHasPanel then
    local panel = self:GetPanel("WishPower")
    if panel then
      panel:OnClose()
    end
  end
end

function BattleUIModule:OnCmdOpenCallNamePanel(req)
  self:OpenPanel("Callname2", req)
end

function BattleUIModule:OnCmdOpenPetConfirmPanel(name, pet)
  self:OpenPanel("PetConfirm", name, pet)
end

function BattleUIModule:OnCmdOpenBattleTutorial(num, guideWidget)
  if not self:HasPanel("BattleTutorial") then
    self:OpenPanel("BattleTutorial", num, guideWidget)
  else
    local panel = self:GetPanel("BattleTutorial")
    if 1 == num then
      panel:OnGetContent()
    elseif 2 == num then
      panel:CallOutNameTutorial2(true)
    end
  end
end

function BattleUIModule:OnCmdSetGuideWidget(guideWidget)
  local panel = self:GetPanel("BattleTutorial")
  if panel then
    panel:ShowTutorial2(guideWidget)
  end
end

function BattleUIModule:OnCmdGetB1P3FirstRoundGuideState()
  return self.b1P3GuideState
end

function BattleUIModule:OnCmdSetB1P3FirstRoundGuideState(State)
  self.b1P3GuideState = State
end

function BattleUIModule:OnCmdOpenBattleTutorial1()
  if not self:HasPanel("BattleTutorial1") then
    self:OpenPanel("BattleTutorial1")
  end
end

function BattleUIModule:OnCmdCloseBattleTutorial1()
  if self:HasPanel("BattleTutorial1") then
    self:ClosePanel("BattleTutorial1")
  end
end

function BattleUIModule:OnCmdOpenFinalBattleLifeBar(pet)
  self:OpenPanel("FinalBattleLifeBar", pet)
end

function BattleUIModule:OnCmdCloseFinalBattleLifeBar(pet)
  self:ClosePanel("FinalBattleLifeBar")
end

function BattleUIModule:OnCmdOpenAutoBattleTestPanel()
  self:OpenPanel("AutoBattleTestPanel")
end

function BattleUIModule:OnCmdOpenPVPDanGradingPanel(...)
  self:OpenPanel("PVPDanGrading", ...)
end

function BattleUIModule:OnCmdClosePVPDanGradingPanel()
  self:ClosePanel("PVPDanGrading")
end

function BattleUIModule:OnCmdShowDanFlag(rankStarNum, bUpgrade, onFinishedCallback)
  local panel = self:GetPanel("PVPDanGrading")
  if panel then
    panel:ShowDanFlag(rankStarNum, bUpgrade, onFinishedCallback)
  end
end

function BattleUIModule:OnCmdShowDanStars(oldStarNum, newStarNum, bFastShow, onFinishedCallback)
  local panel = self:GetPanel("PVPDanGrading")
  if panel then
    panel:ShowDanStars(oldStarNum, newStarNum, bFastShow, onFinishedCallback)
  end
end

function BattleUIModule:DoDebug(season_id, old_pvp_rank_star, new_pvp_rank_star, random_pet_addtional_rank_star, win_streak_addtional_rank_star, old_pvp_rank_order, new_pvp_rank_order, old_pvp_rank_master_score, new_pvp_rank_master_score)
  _G.NRCModuleManager:GetModule("PVPRankedMatchModule").data:DebugSeasonId(season_id)
  local pvp_rank_settle_info = {}
  pvp_rank_settle_info.old_pvp_rank_star = old_pvp_rank_star or 89
  pvp_rank_settle_info.new_pvp_rank_star = new_pvp_rank_star or 90
  pvp_rank_settle_info.old_pvp_rank_order = old_pvp_rank_order or 55
  pvp_rank_settle_info.new_pvp_rank_order = new_pvp_rank_order or 50
  pvp_rank_settle_info.old_pvp_rank_master_score = old_pvp_rank_master_score or 100
  pvp_rank_settle_info.new_pvp_rank_master_score = new_pvp_rank_master_score or 150
  pvp_rank_settle_info.random_pet_addtional_rank_star = random_pet_addtional_rank_star or 0
  pvp_rank_settle_info.win_streak_addtional_rank_star = win_streak_addtional_rank_star or 0
  self:OnCmdOpenPVPDanGradingPanel(pvp_rank_settle_info, season_id or 9)
end

function BattleUIModule:DisablePvpResultUiMaskCamera(isDisable)
  local moduleData = self.data
  if moduleData then
    moduleData.__disablePvpResultUiMaskCamera = isDisable
  end
end

function BattleUIModule:EnableBattleVictoryTitleFillImage(isEnable)
  local moduleData = self.data
  if moduleData then
    moduleData.__enableBattleVictoryTitleFillImage = isEnable
  end
end

function BattleUIModule:SetFantasticBackgroundPathOverride(value)
  local moduleData = self.data
  if moduleData then
    if value and value > 0 then
      moduleData.__fantasticBackgroundPathOverride = value
    else
      moduleData.__fantasticBackgroundPathOverride = nil
    end
  end
end

function BattleUIModule:OnCmdOpenPVPCeleritCarnetyPanel(...)
  self:OpenPanel("PVPCeleritCarnety", ...)
end

function BattleUIModule:OnCmdClosePVPCeleritCarnetyPanel()
  self:ClosePanel("PVPCeleritCarnety")
end

function BattleUIModule:OnCmdOpenPVPValueNumberPanel()
  if not self:HasPanel("PVPValueNumber") then
    self:OpenPanel("PVPValueNumber")
  end
end

function BattleUIModule:OnCmdClosePVPValueNumberPanel()
  self:ClosePanel("PVPValueNumber")
end

function BattleUIModule:OnCmdHandleObserverChangeNotify(notify)
  local observingInfo = _G.BattleManager.battleRuntimeData.observingInfo
  if not observingInfo or not observingInfo.ObserverBriefInfoList then
    return
  end
  for i, info in ipairs(notify.leave_observer) do
    local player = self.data:FindObserverBriefInfoByUin(info.uin)
    if player and player.name then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.AddLocalChatMessage, _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM, string.format(LuaText.chat_multi_system_mseeage_leave_look_battle, player.name))
    end
    self.data:RemoveObserverBriefInfo(info)
  end
  for i, info in ipairs(notify.enter_observer) do
    self.data:AddObserverBriefInfo(info)
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.AddLocalChatMessage, _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM, string.format(LuaText.chat_multi_system_mseeage_enter_look_battle, info.name))
  end
  if observingInfo.ObserverBriefInfoList ~= notify.observer_num then
    Log.Warning("BattleUIModule:HandleObserverChangeNotify \232\167\130\230\136\152\231\142\169\229\174\182\229\136\151\232\161\168\229\137\141\229\144\142\229\143\176\228\184\141\228\184\128\232\135\180")
  end
end

function BattleUIModule:OnBattlePlayerLeaveNotify(notify)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, notify.player_uin)
  if player and player.serverData and player.serverData.base and player.serverData.base.name then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.AddLocalChatMessage, _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM, string.format(LuaText.chat_multi_system_mseeage_leave_battle, player.serverData.base.name))
  end
end

function BattleUIModule:OnCmdCheckInFighting(uin)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, uin)
  if player then
    return player:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
  end
  return false
end

function BattleUIModule:OnCmdCheckInObserver(uin)
  return self.data:FindObserverBriefInfoIndexByUin(uin) > 0
end

function BattleUIModule:OnCmdCheckInFightingOrObserver(_uin)
  local uin = _uin or _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  return self:OnCmdCheckInFighting(uin) or self:OnCmdCheckInObserver(uin)
end

function BattleUIModule:OnCmdGetObserverBriefInfoList()
  return self.data:GetObserverBriefInfoList()
end

function BattleUIModule:OnCmdOPenPetRecoveryTime()
  local req = _G.ProtoMessage:newZoneSceneQueryBeastChallengeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_QUERY_BEAST_CHALLENGE_REQ, req, self, self.OnZoneQueryBeastChallengeRsp)
end

function BattleUIModule:OnZoneQueryBeastChallengeRsp(req)
  if 0 == req.ret_info.ret_code then
    self:OpenPanel("Pet_RecoveryTime", req)
  end
end

function BattleUIModule:OnCmdSelectPetRecoverTime(_index, uiData)
  if self:HasPanel("Pet_RecoveryTime") then
  end
  local panel = self:GetPanel("Pet_RecoveryTime")
  panel:SelectPetRecoverTime(_index, uiData)
end

function BattleUIModule:OnCmdShowPetRecoveryTime()
  if self:HasPanel("Pet_RecoveryTime") then
    local panel = self:GetPanel("Pet_RecoveryTime")
    panel:ShowOrHideMoneyBtn(false)
    panel:OpenSelfFunc()
  end
end

function BattleUIModule:OnCmdCloseAllBattleChatRelatedUI(forceClose)
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if not forceClose and not self:OnCmdCheckInFighting(myUin) then
    return
  end
  Log.DebugFormat("BattleUIModule:OnCmdCloseAllBattleChatRelatedUI forceClose=%s", tostring(forceClose))
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseChatMainPanel)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdCloseAddPrivateChatPanel)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseFriendReport)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseStudentCardPanel)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseFriendRemark)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseHomeEntrance)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseFriendWold)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenEmoMainPanel, 1, false)
end

function BattleUIModule:OnCmdOpenMechanismValidation(...)
  self:OpenPanel("MechanismValidation", ...)
end

function BattleUIModule:OnCmdCloseMechanismValidation()
  self:ClosePanel("MechanismValidation")
end

function BattleUIModule:OnCmdReqJoinObservingBattle(battlerUni)
  local req = _G.ProtoMessage:newZoneBattleObserverJoinReq()
  req.battler_uin = battlerUni
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_OBSERVER_JOIN_REQ, req, self, self.OnZoneBattleObserverJoinRsp)
end

function BattleUIModule:OnZoneBattleObserverJoinRsp(rsp)
  Log.Debug("BattleUIModule:OnZoneBattleObserverJoinRsp")
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\229\188\128\229\144\175\229\165\189\229\143\139\232\167\130\230\136\152\229\164\177\232\180\165", table.tostring(rsp))
  else
    Log.Debug("\229\188\128\229\144\175\229\165\189\229\143\139\232\167\130\230\136\152\230\136\144\229\138\159", table.tostring(rsp))
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "Friend").WATCH
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "FriendModule", "Friend", touchReasonType)
end

function BattleUIModule:OnCmdReqLeaveObservingBattle()
  local req = _G.ProtoMessage:newZoneBattleObserverLeaveReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_OBSERVER_LEAVE_REQ, req, self, self.OnZoneBattleObserverLeaveRsp)
end

function BattleUIModule:OnZoneBattleObserverLeaveRsp(rsp)
  Log.Debug("BattleUIModule:OnZoneBattleObserverJoinRsp")
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\231\166\187\229\188\128\232\167\130\230\136\152\229\164\177\232\180\165", table.tostring(rsp))
  else
    Log.Debug("\231\166\187\229\188\128\229\165\189\229\143\139\232\167\130\230\136\152\230\136\144\229\138\159", table.tostring(rsp))
    _G.BattleManager:SetPlayerDataModelBattleState(0)
    _G.BattleManager.stateFsm:SendEvent(BattleEvent.EnterNormalOver)
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.AddLocalChatMessage, _G.ProtoEnum.SpecialChatSessionUin.SCSU_MULTI_TEAM, string.format(LuaText.chat_multi_system_mseeage_leave_look_battle, _G.DataModelMgr.PlayerDataModel:GetPlayerName()))
  end
end

function BattleUIModule:OnCmdReqBattleKickOutObserver(uin)
  local req = _G.ProtoMessage:newZoneBattleKickOutObserverReq()
  req.uin = uin
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_KICK_OUT_OBSERVER_REQ, req, self, self.OnZoneBattleKickOutObserverRsp)
end

function BattleUIModule:OnZoneBattleKickOutObserverRsp(rsp)
  Log.Debug("BattleUIModule:OnZoneBattleKickOutObserverRsp")
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\232\184\162\229\135\186\231\142\169\229\174\182\229\164\177\232\180\165", table.tostring(rsp))
  else
    Log.Debug("\232\184\162\229\135\186\231\142\169\229\174\182\230\136\144\229\138\159", table.tostring(rsp))
  end
end

function BattleUIModule:OnCmdTrySilhouetteCombat(activityId, moduleId, levelId)
  local req = ProtoMessage:newZoneChallengeCreateBattleReq()
  req.source_data = ProtoMessage:newSourceData()
  req.source_data.activity_id = activityId
  req.source_data.challenge_module_id = moduleId
  req.source_data.challenge_level_id = levelId
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    req.avatar_pt = localPlayer:GetServerPoint()
  end
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_CHALLENGE_CREATE_BATTLE_REQ, req, self, self.OnSilhouetteCombatRsp, false, false)
end

function BattleUIModule:OnSilhouetteCombatRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
  end
end

function BattleUIModule:OnCmdSetCurMatchPvpId(PvpId)
  self.curMatchPvpId = PvpId
end

function BattleUIModule:OnCmdGetCurMatchPvpId()
  return self.curMatchPvpId
end

function BattleUIModule:OnCmdSaveFinalBattlePetData(pet)
  self.FinalBattlePetData = pet
end

function BattleUIModule:OnCmdGetFinalBattlePetData()
  return self.FinalBattlePetData
end

function BattleUIModule:OnCmdGetSwapSelectPetGuid()
  local battleMainWindow = self:GetPanel("BattleMain")
  local changePetPanel
  if battleMainWindow then
    changePetPanel = battleMainWindow:GetSubPanel(BattleEnum.Operation.ENUM_CHANGE)
  end
  local petCardItems = {}
  if changePetPanel then
    petCardItems = changePetPanel.items or {}
  end
  local guid
  for i, item in ipairs(petCardItems) do
    if item:IsSelect() and item.card then
      guid = item.card.guid
    end
  end
  return guid
end

function BattleUIModule:OnCmdGetTriggerInputActionName()
  if self:HasPanel("BattleMain") then
    local panel = self:GetPanel("BattleMain")
    local triggerInputActionName = panel:GetSubPanelTriggerInputActionName()
    return triggerInputActionName
  end
end

function BattleUIModule:OnCmdOpenBattleBuffTips(buffId, battlePet)
  if self:HasPanel("BattleBuffTips") then
    return
  end
  self:OpenPanel("BattleBuffTips", buffId, battlePet)
end

function BattleUIModule:OnCmdCloseBattleBuffTips()
  if self:HasPanel("BattleBuffTips") then
    self:ClosePanel("BattleBuffTips")
  end
end

function BattleUIModule:TestChangeWishPower(wishPower)
  if not self:HasPanel("WishPower") then
    self:OpenPanel("WishPower")
  end
  local panel = self:GetPanel("WishPower")
  if panel then
    panel:PlayWishPowerItemAnim(wishPower)
  end
end

function BattleUIModule:OpenPVPWaitingLoad()
  if self:HasPanel("PVPWaitingLoad") then
    return
  end
  self:OpenPanel("PVPWaitingLoad")
end

function BattleUIModule:CheckOpenWishPowerTutorial()
  if self:HasPanel("WishPower") then
    local panel = self:GetPanel("WishPower")
    panel:OpenTutorialDownloadData()
  end
end

function BattleUIModule:OpenWishPowerTutorial()
  self:OpenPanel("WishPowerTutorial")
end

function BattleUIModule:ClosePVPWaitingLoad()
  if self:HasPanel("PVPWaitingLoad") then
    local panel = self:GetPanel("PVPWaitingLoad")
    panel:Hide()
  else
    self:ClosePanel("PVPWaitingLoad")
  end
end

function BattleUIModule:WishPowerUIVisible()
  if self:HasPanel("WishPower") then
    local panel = self:GetPanel("WishPower")
    panel:UIVisible()
  end
end

function BattleUIModule:WishPowerUIInVisible()
  if self:HasPanel("WishPower") then
    local panel = self:GetPanel("WishPower")
    panel:UIInVisible()
  end
end

function BattleUIModule:WishPowerMaxShineOut()
  if self:HasPanel("WishPower") then
    local panel = self:GetPanel("WishPower")
    panel:WishPowerMaxShineOut()
  end
end

function BattleUIModule:AddDontDisablePanelToList(panelName)
  self.DontDisablePanelList[panelName] = panelName
end

function BattleUIModule:OnUpdatePetCollectTagRsp(partner_mark)
  if self:HasPanel("Pet_Catch") then
    local panel = self:GetPanel("Pet_Catch")
    if panel then
      panel:UpdateCollect(partner_mark)
    end
  end
end

function BattleUIModule:DisablePanelByLayer(layer)
  for i = 1, #self.moduleLivingPanelLst do
    local panelName = self.moduleLivingPanelLst[i]
    local panelData = self:GetPanelData(panelName)
    if panelData.panelLayer == layer and self:IsPanelEnabled(panelName) then
      if self.modulePanelPrevStatueDict[panelName] ~= nil then
        self:Log("\232\175\183\229\139\191\229\164\154\230\172\161\232\176\131\231\148\168DisablePanelByLayer\239\188\140\232\176\131\231\148\168DisablePanelByLayer\229\144\142\233\156\128\232\166\129\232\176\131\231\148\168RevertPanelEnableStateByLayer\229\164\141\229\142\159UI\231\138\182\230\128\129", layer)
        return
      end
      if not self.DontDisablePanelList[panelName] then
        self.modulePanelPrevStatueDict[panelName] = false
        self:DisablePanel(panelName)
      else
        Log.Debug("\232\175\165\233\157\162\230\157\191\232\162\171\230\148\190\229\133\165\232\191\155\230\136\152\230\150\151\233\152\178\231\187\159\228\184\128\229\133\179\233\151\173\231\154\132\233\157\162\230\157\191\229\136\151\232\161\168\239\188\140\230\173\164\229\164\132\228\184\141Disable\232\175\165\233\157\162\230\157\191\239\188\154" .. panelName)
      end
    end
  end
end

function BattleUIModule:SetPvpPlayerPkInfoStartTime(startTime)
  self.PvpPlayerPkInfoStartTime = startTime
end

function BattleUIModule:GetPvpPlayerPkInfoStartTime()
  return self.PvpPlayerPkInfoStartTime
end

function BattleUIModule:OpenBattleBloodPulse(petData)
  if self:HasPanel("BattleBloodPulse") then
    return
  end
  self:OpenPanel("BattleBloodPulse", petData)
end

function BattleUIModule:CloseBattleBloodPulse()
  self:ClosePanel("BattleBloodPulse")
end

function BattleUIModule:OnCmdOpenBattleChangePetConfirmPanel(data)
  if self:HasPanel("BattleChangePetConfirmPanel") then
    self:ClosePanel("BattleChangePetConfirmPanel")
  end
  self:OpenPanel("BattleChangePetConfirmPanel", data)
end

function BattleUIModule:CloseBattleChangePetConfirmPanel()
  self:ClosePanel("BattleChangePetConfirmPanel")
end

function BattleUIModule:ShowFinalBattleTutorial1()
  if self:HasPanel("BattleTutorial") then
    local panel = self:GetPanel("BattleTutorial")
    panel:CallOutNameTutorial1()
  else
    self:OpenPanel("BattleTutorial", 1)
  end
end

function BattleUIModule:ShowFinalBattleWishPower()
  if self:HasPanel("WishPower") then
    local panel = self:GetPanel("WishPower")
    panel:OnDialogueEnded()
  end
end

function BattleUIModule:HideFinalBattleWishPower()
  if self:HasPanel("WishPower") then
    local panel = self:GetPanel("WishPower")
    panel:OnDialogueStart()
  end
end

function BattleUIModule:OnCmdSetTeachBattleId(BattleId)
  self.WaitBattleEndShowMagicManualTeachBattleId = BattleId
end

function BattleUIModule:OnCmdWaitBattleEndShowMagicManualTeach()
  self.hasFunctionBanRemoveBattleType = true
  _G.NRCEventCenter:RegisterEvent("BattleUIModule", self, BattleEvent.FunctionBanRemoveBattleType, self.OnShowMagicManualTeach)
end

function BattleUIModule:OnShowMagicManualTeach()
  if self.hasFunctionBanRemoveBattleType then
    _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.FunctionBanRemoveBattleType, self.OnShowMagicManualTeach)
    self.hasFunctionBanRemoveBattleType = nil
  end
  if self.WaitBattleEndShowMagicManualTeachBattleId then
    _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManualByTeachBattleId, self.WaitBattleEndShowMagicManualTeachBattleId)
    self.WaitBattleEndShowMagicManualTeachBattleId = nil
  end
end

function BattleUIModule:ShowFlowerTask()
  local battle_tasks = _G.BattleManager.battleRuntimeData:GetBattleTasks()
  self:OnCmdOpenBattleAdditionalTarget(battle_tasks, nil, true, true)
end

function BattleUIModule:CloseFlowerTask()
  self:OnCmdCloseBattleAdditionalTarget()
end

return BattleUIModule
