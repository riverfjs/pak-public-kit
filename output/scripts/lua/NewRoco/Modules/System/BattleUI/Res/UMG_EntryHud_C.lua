local UMG_EntryHud_C = _G.NRCPanelBase:Extend("UMG_EntryHud_C")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BeastPlayEnterPerform = require("NewRoco.Modules.Core.Battle.Fsm.Actions.TeamBeastEnter.BeastPlayEnterPerform")

function UMG_EntryHud_C:OnActive(battlePlayerData, ballPath, enemyBallPath, successCallBack)
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(UE4Helper.GetCurrentWorld(), "r.shadow.csmcaching 0")
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_BattleShowImage:SetTeamData(battlePlayerData, ballPath, enemyBallPath, self, successCallBack, self.UMG_BattleShowImage.SetTeamDataType.USE_BATTLE_PLAYER_INFO)
  self.All:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetupImage(self.ImagePlayer)
  self:SetupImage(self.ImageFuse)
end

function UMG_EntryHud_C:SetPanelAlreadyVisible()
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(2)
end

function UMG_EntryHud_C:CloseWorldRenderingByTag()
  UE4Helper.SetEnableWorldRendering(false, nil, "UMG_EntryHud")
end

function UMG_EntryHud_C:OnDeactive()
  UE4Helper.SetEnableWorldRendering(true, nil, "UMG_EntryHud")
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(UE4Helper.GetCurrentWorld(), "r.shadow.csmcaching 1")
end

function UMG_EntryHud_C:OnAddEventListener()
end

function UMG_EntryHud_C:OnTick()
end

function UMG_EntryHud_C:OnLogin()
end

function UMG_EntryHud_C:OnConstruct()
end

function UMG_EntryHud_C:Quit()
  self.UMG_BattleShowImage:ClearWorld()
end

function UMG_EntryHud_C:OnHideLine()
  _G.NRCEventCenter:DispatchEvent(BattleEvent.NPC_ENTER_ANIM_DISAPPEAR, 0)
end

function UMG_EntryHud_C:OnDisappear()
  _G.NRCEventCenter:DispatchEvent(BattleEvent.NPC_ENTER_ANIM_DISAPPEAR, 1)
end

function UMG_EntryHud_C:OnDestruct()
end

function UMG_EntryHud_C:OnAnimationFinished(anim)
end

function UMG_EntryHud_C:SetupImage(imageWidget)
  local factor = BeastPlayEnterPerform.GetViewportAdaptFactor()
  Log.Debug("[rtSizeX]", "imageWidget.Brush.ImageSize.Y(before)", imageWidget.Brush.ImageSize.Y, "imageWidget.Brush.ImageSize.X", imageWidget.Brush.ImageSize.X)
  imageWidget.Brush.ImageSize.Y = imageWidget.Brush.ImageSize.Y / factor
  imageWidget:SetRenderScale(UE.FVector2D(1, 1))
end

return UMG_EntryHud_C
