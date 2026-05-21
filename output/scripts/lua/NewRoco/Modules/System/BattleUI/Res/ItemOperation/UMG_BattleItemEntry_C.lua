require("UnLuaEx")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_BattleItemEntry_C = NRCUmgClass:Extend("")
UMG_BattleItemEntry_C.Data = NRCUmgClass:Extend("")

function UMG_BattleItemEntry_C.Data:Ctor(id, conf_id, gid, num, canCharge, remainCnt, maxCnt, allowCnt, ItemType, playerMagicRemainCnt, playerMagicMaxCnt, allowUseCntInBattle)
  self.id = id
  self.conf_id = conf_id
  self.gid = gid
  self.num = num or 0
  self.canCharge = canCharge
  self.remainCnt = remainCnt or 0
  self.maxCnt = maxCnt
  self.allowCnt = allowCnt or 0
  self.ItemType = ItemType
  self.playerMagicRemainCnt = playerMagicRemainCnt or 0
  self.playerMagicMaxCnt = playerMagicMaxCnt or 0
  self.allowUseCntInBattle = allowUseCntInBattle or 0
end

function UMG_BattleItemEntry_C:Initialize(Initializer)
  self.battleManager = _G.BattleManager
  self.itemData = nil
  self.itemBagCfg = nil
end

function UMG_BattleItemEntry_C:Construct()
  self.battleManager = _G.BattleManager
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_ITEM, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.BATTLE_CLICKED_CANCELPLAYERSKILL, BattleEvent.BATTLE_CLICKED_PLAYERSKILL, BattleEvent.UI_HIDE, BattleEvent.BATTLE_USE_PLAYERSKILL_SUCCESS, BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL, BattleEvent.BATTLE_CANCEL_USE_PLAYERSKILL, BattleEvent.BATTLE_RECOVER_PLAYERSKILL)
  self._timer = 0
  self._longPressThreshold = BattleConst.ItemLongPressThreshold
  self._pressed = false
  self._isSelect = false
  self.BeginUsePlayerSkill = false
  self.IsCanUse = false
  self.FirstOpen = false
  self.curOperateType = BattleEnum.Operation.ENUM_ITEM
  self.TouchButton.OnPressed:Add(self, self._OnItemPressed)
  self.TouchButton.OnReleased:Add(self, self._OnItemRelease)
end

function UMG_BattleItemEntry_C:Destruct()
  self.TouchButton.OnPressed:Remove(self, self._OnItemPressed)
  self.TouchButton.OnReleased:Remove(self, self._OnItemRelease)
  self:CancelPlayOpenAnimDelay()
  _G.BattleEventCenter:UnBind(self)
  NRCUmgClass.Destruct(self)
end

function UMG_BattleItemEntry_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_CLICKED_ITEM then
    self:OnClickedItem(...)
  elseif eventName == BattleEvent.CHANGE_OPERATE_TYPE then
    self:OnOperatePanelChanged(...)
    self:ChangeOpeRate()
  elseif eventName == BattleEvent.BATTLE_CLICKED_CANCELPLAYERSKILL then
    self:OnClickedItem(...)
  elseif eventName == BattleEvent.BATTLE_CLICKED_PLAYERSKILL then
    self:OnClickedItem(...)
  elseif eventName == BattleEvent.UI_HIDE then
    self:InitializeState()
  elseif eventName == BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL then
    self:SetBeginUsePlayerSkill()
  elseif eventName == BattleEvent.BATTLE_CANCEL_USE_PLAYERSKILL then
    self:CancelUsePlayerSkill()
  elseif eventName == BattleEvent.BATTLE_USE_PLAYERSKILL_SUCCESS and BattleUtils.IsFinalBattleP1() and self._isSelect then
    self:SetClickInfo(false)
    self._isSelect = false
  end
end

function UMG_BattleItemEntry_C:SetBeginUsePlayerSkill()
  if self.itemData and self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL then
    self.BeginUsePlayerSkill = true
  end
end

function UMG_BattleItemEntry_C:CancelUsePlayerSkill()
  if self.itemData and self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL and self.BeginUsePlayerSkill then
    self.BeginUsePlayerSkill = false
    self:InitializeState()
  end
end

function UMG_BattleItemEntry_C:InitializeState()
  self._isSelect = false
  self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NubBg_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetClickInfo(false)
end

function UMG_BattleItemEntry_C:OnOperatePanelChanged(operateType)
  self.curOperateType = operateType
  if operateType ~= BattleEnum.Operation.ENUM_ITEM and self.SelectedImage and (self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.Visible or self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible) and not _G.BattleManager.battleRuntimeData.PlayerSkillManager:GetIsPlayerSkillSuccess() then
    self:PlayAnimation(self.Btn_Notclick)
  end
end

function UMG_BattleItemEntry_C:OnItemPressed()
  self:_OnItemPressed()
end

function UMG_BattleItemEntry_C:OnItemRelease()
  self:_OnItemRelease()
end

function UMG_BattleItemEntry_C:_OnItemPressed()
  self._pressed = true
  self._timer = self._longPressThreshold
end

function UMG_BattleItemEntry_C:_OnItemRelease()
  if self._pressed then
    if self._isSelect and self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL then
      self:PlayAnimation(self.Btn_Notclick)
      self:InitializeState()
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_CANCELPLAYERSKILL, self.itemData)
    else
      self:DoClick()
    end
  end
  self._pressed = false
  if self.OpenCommonTips and self:IsPCMode() then
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  end
end

function UMG_BattleItemEntry_C:Tick(geometry, deltaTime)
  if not self._pressed then
    return
  end
  self._timer = self._timer - deltaTime
  if self._timer <= 0 then
    self:DoLongClick()
  end
end

function UMG_BattleItemEntry_C:OnClickedItem(itemData)
  if not self.itemData or itemData.id ~= self.itemData.id then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1004, "UMG_BattleItemEntry_C:OnClickedItem")
    self._isSelect = false
    if self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.Visible or self.SelectedImage:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self:PlayAnimation(self.Btn_Notclick)
    end
    self:UnbindAllFromAnimationFinished(self.Btn_Click)
    if self.itemData and self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL then
      self:SetClickInfo(false)
    end
  end
  self:CheckA1FinalCallingNamesRemainEffects()
end

function UMG_BattleItemEntry_C:OnAnimationFinished(Animation)
  if self.Btn_Click == Animation and self._isSelect then
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NubBg_1:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL then
      self:PlayAnimation(self.LiZi, 0, 99999)
    end
  elseif self.Btn_Notclick == Animation and not self._isSelect then
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NubBg_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Animation == self.open or Animation == self.Change_open then
    if self.bNeedSetGuideWidget then
      NRCModuleManager:DoCmd(BattleUIModuleCmd.SetGuideWidget, self)
    end
    if self.hasChangeItem then
      self:PlayAnimation(self.Magic_change)
      self.delayID = DelayManager:DelaySeconds(0.15, function()
        self.hasSetNewIcon = true
        self.Icon:SetPath(self.NewIconPath)
      end)
    end
  end
end

function UMG_BattleItemEntry_C:DoClick()
  if self.curOperateType == BattleEnum.Operation.ENUM_ITEM and self.itemData and BattleUtils.TryUseItem(self.itemData) then
    if self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL then
      if self:TryUsePlayerSkill() then
        self:UseSuccessChangeState()
        self:SetClickInfo(true)
        _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_PLAYERSKILL, self.itemData)
      end
    else
      self:UseSuccessChangeState()
      self.UMG_BattleClickFX:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_ITEM, self.itemData)
    end
  end
end

function UMG_BattleItemEntry_C:UseSuccessChangeState()
  self._isSelect = true
  self.UMG_BattleClickFX:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:PlayAnimation(self.Btn_Click)
end

function UMG_BattleItemEntry_C:ChangeOpeRate()
  local IsPlayerSkillSuccess = _G.BattleManager.battleRuntimeData.PlayerSkillManager:GetIsPlayerSkillSuccess()
  if self.itemData and self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL and not self.BeginUsePlayerSkill and not IsPlayerSkillSuccess then
    self:InitializeState()
  end
end

function UMG_BattleItemEntry_C:SetPlayerSkill()
  local IsPlayerSkillSuccess = _G.BattleManager.battleRuntimeData.PlayerSkillManager:GetIsPlayerSkillSuccess()
  local isPlayerSkill = self:IsPlayerSkill()
  if isPlayerSkill and IsPlayerSkillSuccess and not BattleUtils.IsFinalBattleP1() then
    self:UseSuccessChangeState()
    self:SetClickInfo(true)
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_SET_PLAYERSKILL, self.itemData)
  end
end

function UMG_BattleItemEntry_C:IsPlayerSkill()
  return self.itemData and self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL
end

function UMG_BattleItemEntry_C:TryUsePlayerSkill()
  local itemData = self.itemData
  if not itemData then
    return false
  end
  if itemData.canCharge and itemData.remainCnt <= 0 then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.umg_battleitementry_1)
    return false
  elseif itemData.playerMagicRemainCnt <= 0 then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.player_magic_use_time)
    return false
  elseif not self.IsCanUse then
    local Text = _G.DataConfigManager:GetLocalizationConf("Battle_Skill_CD").msg
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Text)
    return false
  end
  return true
end

function UMG_BattleItemEntry_C:SetClickInfo(_IsShow)
  if _IsShow then
    self.Cancel:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self:StopAnimation(self.LiZi)
    self.Cancel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BattleItemEntry_C:DoLongClick()
  self._pressed = false
  self._timer = 0
  if self.itemData then
    self.OpenCommonTips = true
    if self:IsPCMode() then
      local triggerInputActionName = _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.GetTriggerInputActionName)
      if not triggerInputActionName then
        _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER, "BattleItemEntryLongPressed")
      end
    end
    local itemConfigId = self.itemData.conf_id
    local battleItemConf = _G.DataConfigManager:GetBattleItemConf(itemConfigId, true)
    local use_time_in_battle = battleItemConf and battleItemConf.use_time_in_battle or 0
    local maxCnt = self.itemData.maxCnt or 0
    local showDesc = true
    if use_time_in_battle > 0 and use_time_in_battle < maxCnt then
      showDesc = false
    end
    local remainCnt = self.itemData.remainCnt
    if not showDesc then
      remainCnt = 100
    end
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.itemData.conf_id, _G.Enum.GoodsType.GT_BAGITEM, self.itemData.canCharge, remainCnt, self.itemData.maxCnt, true, nil, self.itemData.num, self, self.OnCommonTipClose, self.OnCommonTipOpen)
  end
end

function UMG_BattleItemEntry_C:SetData(itemData, Index)
  if not itemData or not itemData.conf_id then
    self:SetShowState(false, Index)
    self.itemData = nil
    self.Text_PCKey:SetKeyVisibility(false)
    return
  else
    self:SetShowState(true, Index)
  end
  self.itemData = itemData
  if not self.FirstOpen then
    self.FirstOpen = true
  end
  self:SetPlayerSkill()
  if self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL then
    if not self._isSelect then
      self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NubBg_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NubBg_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetColor(UE4.FLinearColor(1, 1, 1, 1))
  if self.itemData then
    self.itemBagCfg = _G.DataConfigManager:GetBagItemConf(self.itemData.conf_id)
    if not self.itemBagCfg then
      Log.Error("UMG_BattleItemEntry_C Bag Conf not found " .. self.itemData.conf_id)
    end
    if self.itemData.canCharge then
      if self.itemData.ItemType == Enum.BagItemType.BI_PLAYERSKILL then
        local MagicConf = _G.DataConfigManager:GetPlayerMagicConf(self.itemBagCfg.player_skill_id)
        local SkillConf = _G.DataConfigManager:GetSkillConf(MagicConf.skill_id)
        self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Icon:SetPath(NRCUtils:FormatConfIconPath(SkillConf.icon, _G.UIIconPath.SkillIconPath))
        if itemData and (itemData.canCharge and itemData.remainCnt <= 0 or itemData.playerMagicRemainCnt <= 0) then
          self:SetColor(UE4.FLinearColor(0.2, 0.2, 0.2, 1))
          self.TxtCDNew:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.IconMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
        else
          self.Mask:SetPath(NRCUtils:FormatConfIconPath(SkillConf.icon, _G.UIIconPath.SkillIconPath))
          self.IconMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.TxtCDNew:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self:SetSkillCd()
        end
        if self.itemData.remainCnt >= 99 then
          if self.itemData.playerMagicRemainCnt > 0 then
            self.NumTxt:SetText(string.format("%d/%d", self.itemData.playerMagicRemainCnt, self.itemData.playerMagicMaxCnt))
          else
            self.NumTxt:SetText(string.format("<span color=\"#FF0000FF\">0</>/%d", self.itemData.playerMagicMaxCnt))
          end
        else
          self.NumTxt:SetText(tostring(self.itemData.remainCnt))
        end
        self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.NubBg_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.NubBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        local bagItemIconPath = ""
        local itemBagCfg = self.itemBagCfg
        if self.itemData.remainCnt == self.itemData.maxCnt then
          bagItemIconPath = itemBagCfg and itemBagCfg.icon
        elseif 0 == self.itemData.remainCnt then
          bagItemIconPath = itemBagCfg and itemBagCfg.icon_charging1
        else
          bagItemIconPath = itemBagCfg and itemBagCfg.icon_charging2
        end
        local iconMaskVisibility = UE4.ESlateVisibility.Collapsed
        local itemIconVisibility = UE4.ESlateVisibility.Collapsed
        local itemConfigId = itemData and itemData.conf_id
        local battleItemConf = _G.DataConfigManager:GetBattleItemConf(itemConfigId, true)
        local use_time_in_battle = battleItemConf and battleItemConf.use_time_in_battle or 0
        local remainCnt = itemData and itemData.remainCnt or 0
        local allowUseCnt = remainCnt
        if use_time_in_battle > 0 then
          local allowUseCntInBattle = itemData and itemData.allowUseCntInBattle or 0
          allowUseCnt = math.min(allowUseCntInBattle, remainCnt)
        end
        if allowUseCnt and allowUseCnt <= 0 then
          self:SetColor(UE4.FLinearColor(0.2, 0.2, 0.2, 1))
          self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.Icon:SetPath(NRCUtils:FormatConfIconPath(bagItemIconPath, _G.UIIconPath.BagItemPath))
          iconMaskVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
        else
          self.ItemIcon:SetPath(NRCUtils:FormatConfIconPath(bagItemIconPath, _G.UIIconPath.BagItemPath))
          itemIconVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
        end
        self.ItemIcon:SetVisibility(itemIconVisibility)
        self.IconMask:SetVisibility(iconMaskVisibility)
        self.NumTxt:SetText(tostring(self.itemData.remainCnt))
      end
    else
      self.ItemIcon:SetPath(NRCUtils:FormatConfIconPath(self.itemBagCfg.icon, _G.UIIconPath.BagItemPath))
      self.NumTxt:SetText(tostring(self.itemData.num))
    end
  end
  if itemData.conf_id == 104010 then
    self:ChangeItem(104009, 104010)
  end
  self:CheckA1FinalCallingNamesRemainEffects()
end

function UMG_BattleItemEntry_C:CheckA1FinalCallingNamesRemainEffects()
  if not BattleUtils.IsFinalBattleP1() or not self.itemData then
    return
  end
  if self.itemData.conf_id ~= 104009 then
    self:StopA1FinalCallingNamesRemainEffects()
    return
  end
  local playerPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true, false)
  local nameBuffId = _G.DataConfigManager:GetBattleGlobalConfig("a1_finalbattle_name_buff_ID").num
  local hasNamedBuff = false
  for _, pet in pairs(playerPets) do
    local flag = false
    if pet.card and pet.card.petInfo and pet.card.petInfo.battle_inside_pet_info and pet.card.petInfo.battle_inside_pet_info.buffs then
      for i, v in ipairs(pet.card.petInfo.battle_inside_pet_info.buffs) do
        if nameBuffId == v.buff_id then
          flag = true
          break
        end
      end
    end
    if flag then
      hasNamedBuff = true
      break
    end
  end
  if hasNamedBuff and BattleUtils.CheckMyPlayerItemRemainCount(104009) then
    if self._isSelect then
      self:StopA1FinalCallingNamesRemainEffects()
      self.Icon:PlayAnimation(self.Normal)
    else
      self:PlayAnimation(self.Highlight_Loop, 0, 0)
      if self.Icon.IconHighlight_Loop then
        self.Icon:PlayAnimation(self.Icon.IconHighlight_Loop, 0, 0)
      end
    end
  else
    self:StopA1FinalCallingNamesRemainEffects()
  end
end

function UMG_BattleItemEntry_C:StopA1FinalCallingNamesRemainEffects()
  if self:IsAnimationPlaying(self.Highlight_Loop) then
    self:StopAnimation(self.Highlight_Loop)
  end
  if self.Icon.IconHighlight_Loop and self.Icon:IsAnimationPlaying(self.Icon.IconHighlight_Loop) then
    self.Icon:StopAnimation(self.Icon.IconHighlight_Loop)
  end
end

function UMG_BattleItemEntry_C:ChangeItem(OriginItemID, newItemID)
  local itemBagCfg = _G.DataConfigManager:GetBagItemConf(OriginItemID)
  local MagicConf = _G.DataConfigManager:GetPlayerMagicConf(itemBagCfg.player_skill_id)
  local SkillConf = _G.DataConfigManager:GetSkillConf(MagicConf.skill_id)
  if not self.hasSetNewIcon then
    self.Icon:SetPath(NRCUtils:FormatConfIconPath(SkillConf.icon, _G.UIIconPath.SkillIconPath))
  end
  self.hasChangeItem = true
  itemBagCfg = _G.DataConfigManager:GetBagItemConf(newItemID)
  MagicConf = _G.DataConfigManager:GetPlayerMagicConf(itemBagCfg.player_skill_id)
  SkillConf = _G.DataConfigManager:GetSkillConf(MagicConf.skill_id)
  self.NewIconPath = NRCUtils:FormatConfIconPath(SkillConf.icon, _G.UIIconPath.SkillIconPath)
end

function UMG_BattleItemEntry_C:SetColor(color)
  self.ItemIcon:SetColorAndOpacity(color)
  self.Icon:SetColorAndOpacity(color)
end

function UMG_BattleItemEntry_C:SetShowState(_IsShow, Index)
  self.NotEquipped:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.IconMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if _IsShow then
    self.emptyImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Bg:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NubBg_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NumTxt:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NubBg:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.emptyImage:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SelectedImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NubBg_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NumTxt:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NubBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TxtCDNew:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if _G.IsOpenPlayerSkill and 1 == Index then
      self.NotEquipped:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_BattleItemEntry_C:SetSkillCd()
  local team = _G.BattleManager.battlePawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM)
  local CurRound = _G.BattleManager:GetCurRound()
  local player = team.player
  local ShowCdRound = player.roleInfo.magic_skill_info.show_cd_round
  local battleConfig = BattleUtils.GetBattleConfig()
  local battleMaxRound = battleConfig and battleConfig.max_round or 9999
  if CurRound <= ShowCdRound then
    self.IsCanUse = false
    self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TxtCDNew:SetVisibility(UE4.ESlateVisibility.Visible)
    local cdText = ""
    if ShowCdRound < battleMaxRound then
      cdText = tostring(ShowCdRound - CurRound + 1)
    end
    self.TxtCDNew:SetText(cdText)
    self:SetColor(UE4.FLinearColor(0.2, 0.2, 0.2, 1))
  else
    self.IsCanUse = true
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TxtCDNew:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetColor(UE4.FLinearColor(1, 1, 1, 1))
  end
end

function UMG_BattleItemEntry_C:SetMaterialAssetInfo(MaterialAsset)
  self.Bg:SetBrushFromMaterial(MaterialAsset)
  self.SelectedImage:SetBrushFromMaterial(MaterialAsset)
  self.emptyImage:SetBrushFromMaterial(MaterialAsset)
end

function UMG_BattleItemEntry_C:DelayPlayAnim(_IsOpen, i)
  self:CancelPlayOpenAnimDelay()
  local interval = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenInterval or 0.04
  self.playOpenAnimDelayId = _G.DelayManager:DelaySeconds(i * interval, self.PlayOpenAnimation, self, _IsOpen)
end

function UMG_BattleItemEntry_C:HidePoint()
  self.point0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.point1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.point2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.point3:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BattleItemEntry_C:CancelPlayOpenAnimDelay()
  if self.playOpenAnimDelayId then
    _G.DelayManager:CancelDelayById(self.playOpenAnimDelayId)
    self.playOpenAnimDelayId = nil
  end
end

function UMG_BattleItemEntry_C:OnDestruct()
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
    self.delayID = nil
  end
end

function UMG_BattleItemEntry_C:PlayOpenAnimation(_IsOpen)
  self:HidePoint()
  if _IsOpen then
    self:RandVisiblePoint()
    local openAnimSpeedRate = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenAnimSpeedRate or 1
    if BattleUtils.IsMainWindowChangingBetweenSubPanels() then
      self:PlayAnimation(self.Change_open, 0, 1, 0, openAnimSpeedRate)
    else
      self:PlayAnimation(self.open, 0, 1, 0, openAnimSpeedRate)
    end
  elseif BattleUtils.IsMainWindowChangingBetweenSubPanels() then
    self:PlayAnimation(self.Change_close)
  else
    self:PlayAnimation(self.close)
  end
end

function UMG_BattleItemEntry_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_BattleItemEntry_C:RandVisiblePoint()
  if self.itemData then
    local Rand = math.random(0, 3)
    if self["point" .. Rand] then
      self["point" .. Rand]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_BattleItemEntry_C:UpdatePlayerSkillTutorial(showPlayerSkillTutorialHighLight)
  showPlayerSkillTutorialHighLight = self:IsPlayerSkill() and showPlayerSkillTutorialHighLight
  if self.itemData and self.itemData.showPlayerSkillTutorialHighLight == showPlayerSkillTutorialHighLight then
    return
  end
  if self.itemData then
    self.itemData.showPlayerSkillTutorialHighLight = showPlayerSkillTutorialHighLight
  end
  if showPlayerSkillTutorialHighLight then
    self.TutorialHighLightLoader:LoadPanel()
  else
    local itemTutorialHighLight = self.TutorialHighLightLoader:GetPanel()
    if itemTutorialHighLight then
      itemTutorialHighLight:Hide()
    end
    self.TutorialHighLightLoader:UnLoadPanel()
  end
end

function UMG_BattleItemEntry_C:OnCommonTipOpen()
end

function UMG_BattleItemEntry_C:OnCommonTipClose()
  self.OpenCommonTips = false
end

return UMG_BattleItemEntry_C
