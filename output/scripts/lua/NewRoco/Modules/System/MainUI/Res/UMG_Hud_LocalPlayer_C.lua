local BitMask = require("Utils.BitMask")
local UMG_Hud_LocalPlayer_C = _G.NRCClass:Extend("UMG_Hud_LocalPlayer_C")
local TypeEnum = {RoleRelationTree = 1, AFK = 2}

function UMG_Hud_LocalPlayer_C:Construct()
  self:DoCheckContentVisibleForChatBubble()
end

function UMG_Hud_LocalPlayer_C:Destruct()
end

function UMG_Hud_LocalPlayer_C:RefreshVisible()
  if not self.showType then
    self.showType = BitMask()
  end
  if self.showType:any() then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:DoCheckContentVisibleForChatBubble()
end

function UMG_Hud_LocalPlayer_C:ShowPanelByType(Type, Param)
  if not self.OldData then
    self.OldData = {}
  end
  if not self.showType then
    self.showType = BitMask()
  end
  self.showType:set(TypeEnum[Type], true)
  if TypeEnum[Type] == TypeEnum.RoleRelationTree and Param and (Param.RelationTreeType or Param.ActionID) then
    if not self.RelationTree_Interaction:IsVisible() then
      self.OldData = {
        RelationTreeType = Param.RelationTreeType,
        ActionID = Param.ActionID
      }
      self.RelationTree_Interaction:UpdateHeadHUD(true, self.OldData.RelationTreeType, self.OldData.ActionID, false, true)
    elseif self.OldData and (self.OldData.RelationTreeType ~= Param.RelationTreeType or self.OldData.ActionID ~= Param.ActionID) then
      self.OldData = {
        RelationTreeType = Param.RelationTreeType,
        ActionID = Param.ActionID
      }
      self.RelationTree_Interaction:PlayerAnimChangeOut(true, self.OldData.RelationTreeType, self.OldData.ActionID, false)
    end
  end
  if TypeEnum[Type] == TypeEnum.AFK then
    self.IdleState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if not self.IdleState:IsAnimationPlaying(self.IdleState.Loop) then
      self.IdleState:PlayAnimation(self.IdleState.Loop, 0, 0)
    end
  end
  self:RefreshVisible()
end

function UMG_Hud_LocalPlayer_C:CloseType(Type)
  if not self.showType then
    self.showType = BitMask()
  end
  self.showType:set(TypeEnum[Type], false)
  if TypeEnum[Type] == TypeEnum.RoleRelationTree then
    self.RelationTree_Interaction:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if TypeEnum[Type] == TypeEnum.AFK then
    self.IdleState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IdleState:StopAnimation(self.IdleState.Loop)
  end
  self:RefreshVisible()
end

function UMG_Hud_LocalPlayer_C:UnVisibileRelationTree()
  if self.RelationTree_Interaction:IsVisible() then
    self.OldData = {}
    self.RelationTree_Interaction:PlayerAnimOut()
  end
end

function UMG_Hud_LocalPlayer_C:ClearOldData()
  self.OldData = {}
  self:CloseType("RoleRelationTree")
end

function UMG_Hud_LocalPlayer_C:OnAddEventListener()
end

function UMG_Hud_LocalPlayer_C:DoCheckContentVisibleForChatBubble()
  local isShow = self.RelationTree_Interaction:IsVisible() or self.IdleState:IsVisible()
  Log.Debug("UMG_Hud_LocalPlayer_C: DoCheckContentVisibleForChatBubble", isShow)
  self:SetDetailedInfo(isShow and "" or "InVisible")
end

return UMG_Hud_LocalPlayer_C
