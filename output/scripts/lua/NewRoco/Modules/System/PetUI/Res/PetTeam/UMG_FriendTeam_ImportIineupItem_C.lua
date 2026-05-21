local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_FriendTeam_ImportIineupItem_C = Base:Extend("UMG_FriendTeam_ImportIineupItem_C")

function UMG_FriendTeam_ImportIineupItem_C:OnConstruct()
  self.Btn_Cover.btnLevelUp.OnClicked:Add(self, self.OnBtn_Cover)
  self.Btn_Cover_Grey.btnLevelUp.OnClicked:Add(self, self.OnBtn_Cover)
end

function UMG_FriendTeam_ImportIineupItem_C:OnDestruct()
end

function UMG_FriendTeam_ImportIineupItem_C:OnBtn_Cover()
  if self.IsMaxMirror == nil then
    self.ParentPanel:UseRecommendTeam(self.index, self.IsEmptyTeam)
    return
  end
  if self.IsMaxMirror and not self.team.is_mirror then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_pet_upper_limit_text)
  else
    local HasBossItem, PetName = self.ParentPanel:CheckHasBossItem()
    if HasBossItem then
      self:TryCover()
    else
      local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
      local dialogContext = DialogContext()
      dialogContext:SetContent(string.format(LuaText.relationtree_sharepet_check_boss, PetName)):SetTitle(LuaText.TIPS):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetCallbackOkOnly(self, self.TryCover):SetToppingIconType(0)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
    end
  end
end

function UMG_FriendTeam_ImportIineupItem_C:TryCover()
  self.ParentPanel:TryCoverMirrorTeam(self.index, self.IsEmptyTeam)
end

function UMG_FriendTeam_ImportIineupItem_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.petList1 = _data.petList
  self.IsMaxMirror = _data.IsMaxMirror
  self.team = _data.team
  self.ParentPanel = _data.Panel
  self.IsEmptyTeam = self:GetIsEmptyTeam(self.petList1)
  self.ImportlineupView:InitGridView(self.petList1)
  if _data.HideBtn then
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.team.is_mirror then
    self.FriendsLineupText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.FriendsLineupText:SetText(string.format(LuaText.share_pet_owner_inf_1, self.team.mirror_friend_name))
  else
    self.FriendsLineupText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.IsMaxMirror and not self.team.is_mirror then
    self.Mask1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Mask2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Mask1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Mask2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetCurTeamNameAndBloodLineMagic()
end

function UMG_FriendTeam_ImportIineupItem_C:GetIsEmptyTeam(petList)
  local IsEmptyTeam = true
  for i, v in ipairs(petList) do
    if "nil" ~= v then
      IsEmptyTeam = false
      break
    end
  end
  return IsEmptyTeam
end

function UMG_FriendTeam_ImportIineupItem_C:SetCurTeamNameAndBloodLineMagic()
  local default_name = _G.DataConfigManager:GetBattleGlobalConfig("pvp_team_name").str
  local CurPetTeam = self.team
  if CurPetTeam.team_name then
    self.TeamName:SetText(CurPetTeam.team_name)
  else
    self.TeamName:SetText(string.format(default_name, self.index))
  end
  if self.team.is_mirror then
    if CurPetTeam.mirror_magic_id and CurPetTeam.mirror_magic_id > 0 then
      local BagItemConf = _G.DataConfigManager:GetBagItemConf(CurPetTeam.mirror_magic_id)
      if BagItemConf then
        self.NRCSwitcher1:SetActiveWidgetIndex(0)
        self.MagicIcon:SetPath(BagItemConf.icon)
      end
    else
      self.NRCSwitcher1:SetActiveWidgetIndex(1)
    end
  else
    local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
    local IsHasBlood = BagItemS and #BagItemS > 0 and true or false
    if IsHasBlood and CurPetTeam.role_magic_gid and CurPetTeam.role_magic_gid > 0 then
      for i, BagItem in ipairs(BagItemS) do
        if BagItem.gid == CurPetTeam.role_magic_gid then
          local BagItemConf = _G.DataConfigManager:GetBagItemConf(BagItem.id)
          if BagItemConf then
            self.NRCSwitcher1:SetActiveWidgetIndex(0)
            self.MagicIcon:SetPath(BagItemConf.icon)
          end
        end
      end
    else
      self.NRCSwitcher1:SetActiveWidgetIndex(1)
    end
  end
end

function UMG_FriendTeam_ImportIineupItem_C:OnItemSelected(_bSelected)
end

function UMG_FriendTeam_ImportIineupItem_C:OnDeactive()
end

return UMG_FriendTeam_ImportIineupItem_C
