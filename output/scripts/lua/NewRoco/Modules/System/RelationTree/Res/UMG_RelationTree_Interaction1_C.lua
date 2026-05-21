local UMG_RelationTree_Interaction1_C = _G.NRCPanelBase:Extend("UMG_RelationTree_Interaction1_C")

function UMG_RelationTree_Interaction1_C:OnActive()
end

function UMG_RelationTree_Interaction1_C:OnAddEventListener()
end

function UMG_RelationTree_Interaction1_C:PlayerAnimIn()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:StopAnimation(self.Loop_2)
  self:PlayAnimation(self.In_2)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004007, "UMG_RelationTree_Interaction1_C:PlayerAnim.In_2")
end

function UMG_RelationTree_Interaction1_C:PlayerAnimChangeOut(IsRequests, RelationTreeType, ActionID, IsNotLoopAnim)
  self.ChangeData = {
    IsRequests = IsRequests,
    RelationTreeType = RelationTreeType,
    ActionID = ActionID,
    IsNotLoopAnim = IsNotLoopAnim
  }
  self:StopAnimation(self.Loop_2)
  self:PlayAnimation(self.Change_out)
end

function UMG_RelationTree_Interaction1_C:PlayerAnimOut()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_RelationTree_Interaction1_C:PlayerAnimChangeIn()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004007, "UMG_RelationTree_Interaction1_C:PlayerAnimChangeIn.Change_in")
  self:PlayAnimation(self.Change_in)
end

function UMG_RelationTree_Interaction1_C:PlayerPerceptionAnimIn()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:StopAnimation(self.Loop_3)
  self:PlayAnimation(self.In_4)
end

function UMG_RelationTree_Interaction1_C:UpdateHeadHUD(IsRequests, RelationTreeType, ActionID, IsNotLoopAnim, IsPlayAnimIn, IsChangeAnimIn)
  if RelationTreeType then
    local RelationNode = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeNodeByEnum, RelationTreeType)
    if RelationNode then
      self.IconPath = RelationNode.StateStruct[1].icon
    end
  elseif ActionID then
    local Config = _G.DataConfigManager:GetRelationtreeAnimConf(ActionID)
    if Config and Config.name_icon_struct and Config.name_icon_struct[2] then
      self.IconPath = Config.name_icon_struct[2].icon
    end
  end
  self.IsNotLoopAnim = IsNotLoopAnim
  if IsRequests then
    self.NRCSwitcher:SetActiveWidgetIndex(0)
    self:UpdateUI(IsPlayAnimIn, IsChangeAnimIn)
  else
    self.NRCSwitcher:SetActiveWidgetIndex(1)
  end
  self.ChangeData = nil
end

function UMG_RelationTree_Interaction1_C:UpdateUI(IsPlayAnimIn, IsChangeAnimIn)
  if self.IconPath and self.IconPath ~= "" then
    if IsPlayAnimIn then
      self.Icon:SetPathWithCallBack(self.IconPath, {
        self,
        self.PlayerAnimIn
      })
    elseif IsChangeAnimIn then
      self.Icon:SetPathWithCallBack(self.IconPath, {
        self,
        self.PlayerAnimChangeIn
      })
    else
      self.Icon:SetPath(self.IconPath)
    end
  end
end

function UMG_RelationTree_Interaction1_C:SetHeadHUD_BGYellow(IsYellow)
  if IsYellow then
    self.Bg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFC75FFF"))
  else
    self.Bg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFFFFFFF"))
  end
end

function UMG_RelationTree_Interaction1_C:OnAnimationFinished(anim)
  if anim == self.In_2 then
    if not self.IsNotLoopAnim then
      self:PlayAnimation(self.Loop_2, 0, 0)
    end
  elseif anim == self.Change_out then
    if self.ChangeData then
      self.IsNotLoopAnim = self.ChangeData.IsNotLoopAnim
      self:UpdateHeadHUD(self.ChangeData.IsRequests, self.ChangeData.RelationTreeType, self.ChangeData.ActionID, self.ChangeData.IsNotLoopAnim, false, true)
    end
    self:PlayAnimation(self.Change_in)
  elseif anim == self.Change_in then
    if not self.IsNotLoopAnim then
      self:PlayAnimation(self.Loop_2, 0, 0)
    end
  elseif anim == self.OUt then
  elseif anim == self.In_4 then
    self:PlayAnimation(self.Loop_3, 0, 0)
  end
end

function UMG_RelationTree_Interaction1_C:OnDeactive()
end

return UMG_RelationTree_Interaction1_C
