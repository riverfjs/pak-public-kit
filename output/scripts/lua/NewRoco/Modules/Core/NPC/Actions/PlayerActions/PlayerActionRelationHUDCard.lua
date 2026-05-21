local Base = require("NewRoco.Modules.Core.NPC.Actions.PlayerActions.PlayerActionBase")
local PlayerActionRelationHUDCard = Base:Extend("PlayerActionRelationHUDCard")

function PlayerActionRelationHUDCard:Execute()
  if not self.Owner then
    return
  end
  local SelfOwner = self.Owner.owner
  if not SelfOwner then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local InviteComponent = player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    if InviteComponent and not InviteComponent:IsCanOverrideInteract(ProtoEnum.InteractInviteType.IIT_DOUBLE_ACTION, InviteComponent._interactType) then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.relationtree_performing_request_tip)
      return
    end
  end
  self.PlayerUin = SelfOwner.serverData and SelfOwner.serverData.base and SelfOwner.serverData.base.logic_id or nil
  local playerName = SelfOwner.serverData and SelfOwner.serverData.base and SelfOwner.serverData.base.name or ""
  if self.PlayerUin then
    self.OherRelationRequestEnumType = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOtherRequestsByUin, self.PlayerUin)
    if self.OherRelationRequestEnumType then
      _G.NRCAudioManager:PlaySound2DAuto(40008003, "UMG_RelationTree_Item_C:ConfrimUnlockReq")
      local title = LuaText.relationtree_unlock_request_title
      local des = ""
      if self.OherRelationRequestEnumType == Enum.RelationTreeType.RLTT_ADDFRIEND then
        des = string.format(LuaText.relationtree_add_friend_agree_check, playerName)
      else
        local RelationNode = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeNodeByEnum, self.OherRelationRequestEnumType)
        local RelationName = ""
        if RelationNode then
          RelationName = RelationNode.StateStruct[1].name
        end
        des = string.format(LuaText.relationtree_nomal_agree_check, playerName, RelationName)
      end
      local rightText = LuaText.instancemodule_1
      local leftText = LuaText.instancemodule_2
      local Context = DialogContext()
      Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.TipsSucceed):SetClickAnywhereClose(true):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
    end
  end
end

function PlayerActionRelationHUDCard:TipsSucceed(isOk)
  if isOk then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not (player and player.statusComponent) or not player.statusComponent:PreApplyStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.relationtree_abnormal_status_tip)
      return
    end
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ConfrimUnlockRelationShipNodeReq, self.PlayerUin, self.OherRelationRequestEnumType)
  end
end

return PlayerActionRelationHUDCard
