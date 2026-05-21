local UMG_RolePlayPoseLevel_C = _G.NRCViewBase:Extend("UMG_RolePlayPoseLevel_C")
local Delegate = require("Utils.Delegate")

function UMG_RolePlayPoseLevel_C:OnConstruct()
  self.OnPanelTouched = Delegate()
end

function UMG_RolePlayPoseLevel_C:OnActive()
end

function UMG_RolePlayPoseLevel_C:OnDeactive()
end

function UMG_RolePlayPoseLevel_C:OnAddEventListener()
end

function UMG_RolePlayPoseLevel_C:OnTouchEnded(MyGeometry, InTouchEvent)
  self.OnPanelTouched:Invoke()
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_RolePlayPoseLevel_C:Show(Items)
  local function ReqUseRpTypeInGroup(Item)
    _G.NRCModuleManager:DoCmd(RolePlayModuleCmd.ReqUseRpTypeInGroup, Item.rpType)
    
    local executeParam = {}
    executeParam.type = Item.type
    executeParam.id = Item.value
    executeParam.statusParams = {}
    executeParam.statusParams.role_play_param = {}
    executeParam.statusParams.role_play_param.role_play_id = executeParam.id
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.ExecuteRolePlay, executeParam)
    _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_RolePlayPoseLevel_C:ExecuteRolePlay")
  end
  
  local DisplayItems = Items
  for i = 1, #DisplayItems do
    local ItemView = self.ChooseGridView:GetItemByIndex(i - 1)
    if ItemView then
      ItemView.OnClickedEvent:Clear()
    end
  end
  self.ChooseGridView:InitGridView(DisplayItems)
  self.ChooseGridView:SelectItemByIndex(0)
  for i = 1, #DisplayItems do
    local ItemView = self.ChooseGridView:GetItemByIndex(i - 1)
    local Item = DisplayItems[i]
    if not Item.customData or not Item.customData.bLocked then
      ItemView.OnClickedEvent:Add(self, function()
        return ReqUseRpTypeInGroup(Item)
      end)
    end
  end
  self.bPendingAnimation = true
  self:StopAllAnimations()
  self:PlayAnimation(self.In)
end

function UMG_RolePlayPoseLevel_C:Hide()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  for i = 1, self.ChooseGridView:GetItemCount() do
    local ItemView = self.ChooseGridView:GetItemByIndex(i - 1)
    ItemView:PlayOutAnimation()
  end
  self.ChooseGridView:ClearSelection()
  self.bPendingAnimation = true
  self:StopAllAnimations()
  self:PlayAnimation(self.Out)
end

function UMG_RolePlayPoseLevel_C:OnAnimationFinished(Animation)
  if self.bPendingAnimation then
    return
  end
  if Animation == self.Out then
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_RolePlayPoseLevel_C:OnAnimationStarted(Animation)
  self.bPendingAnimation = false
  if Animation == self.In then
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

return UMG_RolePlayPoseLevel_C
