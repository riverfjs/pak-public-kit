local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local UMG_PetSkillMain_Tips_C = _G.NRCPanelBase:Extend("UMG_PetSkillMain_Tips_C")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BattlePassModuleEvent = reload("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
UMG_PetSkillMain_Tips_C.DamageTypeMap = {
  [1] = nil,
  [2] = 1,
  [3] = 2
}

function UMG_PetSkillMain_Tips_C:OnActive(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
  self.descText = ""
  self.lastSkillId = nil
  self.PetData = self.module:GetData("PetUIModuleData")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002013, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
  self.CanClick = true
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.RefreshQuickUnlockShow)
  self:OnAddEventListener()
  if self.Img_Mask then
    self.Img_Mask:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self:RefreshUI(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
  self:IfHavePetBag()
  self:PlayAnimation(self.Appear)
  if 0 == bagItemId then
    self.Btn_ShutDown_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_ShutDown_5:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Btn_ShutDown_12:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif 1 == bagItemId then
    self.Btn_ShutDown_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Btn_ShutDown_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_ShutDown_12:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetSkillMain_Tips_C:OnDeactive()
end

function UMG_PetSkillMain_Tips_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_ShutDown, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_1, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_2, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_3, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_4, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_5, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_6, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_7, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_8, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_9, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_10, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_11, self.OnClose)
  self:AddButtonListener(self.Btn_ShutDown_12, self.OnClose)
  self:AddButtonListener(self.Btn_CloseDesc, self.ResetDescText)
  self:AddButtonListener(self.Btn_CloseDesc_1, self.ResetDescText)
  self:AddButtonListener(self.Btn_CloseDesc_2, self.ResetDescText)
  self:AddButtonListener(self.LeftBtn.btnLevelUp, self.OnLeftBtnClick)
  self:AddButtonListener(self.LeftBtn_Gray.btnLevelUp, self.OnLeftBtn_GrayClick)
  self:RegisterEvent(self, PetUIModuleEvent.OpenOrCloseSkillTipsPanel, self.IsShouldCloseTips)
  self:RegisterEvent(self, PetUIModuleEvent.ResetSkillTipDescText, self.ResetDescText)
  self:RegisterEvent(self, PetUIModuleEvent.EQUIP_SKILL_SUCCESS, self.OnEquippedSuccess)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.RefreshQuickUnlockShow)
end

function UMG_PetSkillMain_Tips_C:OnEquippedSuccess()
  if 0 == self.bagItemId and self.petGid and self.skillId then
    local pos
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petGid)
    for _, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and skillData.pos > 0 and skillData.pos < 5 and skillData.id == self.skillId then
        pos = skillData.pos
        break
      end
    end
    if pos then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.skill_equip_tips_1, pos))
    end
  end
end

function UMG_PetSkillMain_Tips_C:OnLeftBtn_GrayClick()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.skill_change_tips_7)
end

function UMG_PetSkillMain_Tips_C:OnLeftBtnClick()
  if self.curShowSkill and self.curShowSkill.is_learned then
    if self.curShowSkill.is_equipped then
      if self.curEquipSkillCount > 1 then
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenSkillOperationPanel, self.petGid, PetUIModuleEnum.PetSkillOperationType.Exchange, self.curShowSkill.id)
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.skill_change_tips_7)
      end
    elseif self.curEquipSkillCount < 4 then
      local skillIds = {}
      for i, v in ipairs(self.curEquipSkillMap) do
        skillIds[i] = v
      end
      table.insert(skillIds, self.curShowSkill.id)
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AutoCheckEnvironmentEquipPetSkill, self.petGid, skillIds)
    else
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenSkillOperationPanel, self.petGid, PetUIModuleEnum.PetSkillOperationType.Replacement, self.curShowSkill.id)
    end
    self:ResetDescText()
  end
end

function UMG_PetSkillMain_Tips_C:RefreshQuickUnlockShow()
  if self.Btn then
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.PromptAcquisitionView then
    self.PromptAcquisitionView:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.petGid then
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petGid)
      if petData then
        self.curEquipSkillCount = 0
        self.curShowSkill = nil
        self.curEquipSkillMap = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, self.petGid) or {}
        self.isPvpTeam = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetEnterPetPanelType) == PetUIModuleEnum.EnterType.PvpPetTeamUmg
        for _, skillData in ipairs(petData.skill.skill_data) do
          if skillData.id == self.skillId then
            self.curShowSkill = table.deepCopy(skillData)
            self.curShowSkill.is_equipped = false
            for pos, id in pairs(self.curEquipSkillMap) do
              if skillData.id == id then
                self.curShowSkill.is_equipped = true
                self.curShowSkill.is_learned = true
                break
              end
            end
          end
        end
        self.curEquipSkillCount = #self.curEquipSkillMap
        if self.Btn and 0 == self.bagItemId and self.curShowSkill and self.curShowSkill.is_learned and petData.blood_id ~= _G.Enum.PetBloodType.PBT_NIGHTMARE then
          local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
          if friendInfo and friendInfo.type and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
            self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
            return
          end
          if self.curShowSkill.is_equipped then
            if self.curEquipSkillCount > 1 then
              self.LeftBtn.Title_1:SetText(LuaText.skill_change_text_2)
              self.Btn:SetActiveWidgetIndex(0)
            else
              self.Btn:SetActiveWidgetIndex(1)
            end
          elseif self.curEquipSkillCount < 4 then
            self.LeftBtn.Title_1:SetText(LuaText.skill_change_text_3)
            self.Btn:SetActiveWidgetIndex(0)
          else
            self.LeftBtn.Title_1:SetText(LuaText.skill_change_text_1)
            self.Btn:SetActiveWidgetIndex(0)
          end
          self.Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          return
        end
      end
    end
    if self.curShowSkill and self.curShowSkill.is_learned then
      return
    end
    if self.petBaseId then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petBaseId, true)
      if petBaseConf then
        local skillSourceList = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetSkillSourceAndUnlockInfo, self.skillId, self.petBaseId, self.petGid)
        for i, v in pairs(skillSourceList) do
          v.bQuickUnlock = self.bQuickUnlock
          v.MaxDesiredWidth = 270
        end
        self.PromptAcquisitionView:InitGridView(skillSourceList)
        if #skillSourceList > 0 then
          local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
          if friendInfo then
            if friendInfo.type == _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
              self.PromptAcquisitionView:SetVisibility(UE4.ESlateVisibility.Visible)
            else
              self.PromptAcquisitionView:SetVisibility(UE4.ESlateVisibility.Collapsed)
            end
          else
            self.PromptAcquisitionView:SetVisibility(UE4.ESlateVisibility.Visible)
          end
        end
      end
    end
  end
end

function UMG_PetSkillMain_Tips_C:OnClose()
  if self.CanClick then
    self.CanClick = false
    if self.module:HasPanel("PetInfoMain") then
      self:IsSwitchToPetBag()
    end
    self:RemoveButtonListener(self.Btn_ShutDown, self.OnClose)
    self:RemoveButtonListener(self.Btn_ShutDown_1, self.OnClose)
    self:RemoveButtonListener(self.Btn_ShutDown_2, self.OnClose)
    self:RemoveButtonListener(self.Btn_ShutDown_3, self.OnClose)
    self:RemoveButtonListener(self.Btn_ShutDown_4, self.OnClose)
    self:RemoveButtonListener(self.Btn_ShutDown_5, self.OnClose)
    self:RemoveButtonListener(self.Btn_ShutDown_6, self.OnClose)
    self:RemoveButtonListener(self.Btn_ShutDown_7, self.OnClose)
    self:PlayAnimation(self.Disappear)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClearSkillList, true)
    NRCEventCenter:DispatchEvent(BattlePassModuleEvent.ClearSelection)
    self.skillId = 0
  end
end

function UMG_PetSkillMain_Tips_C:OnPcClose()
  self:OnClose()
end

function UMG_PetSkillMain_Tips_C:GetSkillTypePath(type, damage_type)
  if type == Enum.SkillType.ST_DAMAGE then
    self.NumericalValue_2:SetText(_G.DataConfigManager:GetLocalizationConf("umg_petevolutionfinish_2").msg)
    if damage_type == Enum.DamageType.DT_SPC then
      return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_04_png.ui_pet_attribute_04_png'"
    else
      return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_02_png.ui_pet_attribute_02_png'"
    end
  elseif type == Enum.SkillType.ST_DEFEND then
    self.NumericalValue_2:SetText(_G.DataConfigManager:GetLocalizationConf("umg_petevolutionfinish_3").msg)
    return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/AT_DEFENSE_png.AT_DEFENSE_png'"
  else
    self.NumericalValue_2:SetText(_G.DataConfigManager:GetLocalizationConf("umg_pet_skill_tips_3").msg)
    return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/AT_CLASSIFICATION_png.AT_CLASSIFICATION_png'"
  end
end

function UMG_PetSkillMain_Tips_C:RefreshUI(skillId, _isBagItem, bagItemId, petBaseId, bQuickUnlock, petGid)
  self.skillId = skillId
  self.petBaseId = petBaseId
  self.bQuickUnlock = bQuickUnlock
  self.petGid = petGid
  self.curEquipSkillCount = 0
  self.curShowSkill = nil
  self.curEquipSkillMap = {}
  self.bagItemId = bagItemId
  local skillConf = _G.DataConfigManager:GetSkillConf(skillId)
  local state = self.PetData and self.PetData.PetSkillListState
  if not self.lastSkillId then
    self.lastSkillId = skillId
  elseif self.lastSkillId ~= skillId then
    self:ResetDescText()
    self.lastSkillId = skillId
  end
  if 1 == state then
    self.Btn_ShutDown_8:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 0 == state then
    self.Btn_ShutDown_8:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if skillConf then
    self.SkillIcon:SetPath(skillConf.icon)
    self.SkillNameTxt:SetText(skillConf.name)
    local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
    if typeDic then
      self.SkillShuIcon:SetPath(typeDic.tips_base_icon)
    end
    self.Department:SetPath(self:GetSkillTypePath(skillConf.Skill_Type, skillConf.damage_type))
    if 1 ~= skillConf.damage_type then
      self.NumericalValue:SetText(tostring(skillConf.dam_para[1]))
    else
      self.NumericalValue:SetText("-")
    end
    local skillDesc = skillConf.desc
    self.descText = skillDesc
    self.NRCTextDes:SetText(skillDesc)
    self.NRCTextDes_1:SetText(skillConf.flavor_text)
    self.NumericalValue_1:SetText(skillConf.energy_cost[1])
    if skillConf.type == Enum.SkillActiveType.SAT_LEGENDARY then
      self.BeastSkill:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.BeastSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    Log.Debug("\230\137\190\228\184\141\229\136\176\232\191\153\228\184\170\230\138\128\232\131\189", skillId)
  end
  if true == _isBagItem then
    self.Type:SetRenderOpacity(0)
    self.HorizontalBox_0:SetRenderOpacity(0)
    self.Btn_ShutDown_4:SetVisibility(UE4.ESlateVisibility.Visible)
    local bagItemData = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(bagItemId)
    self.Type:SetText(bagItemInfo.type_desc)
    if nil ~= bagItemData then
      self.OwnedText:SetText(tostring(bagItemData.num))
    else
      self.OwnedText:SetText("0")
    end
    self.PromptAcquisition:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Type:SetRenderOpacity(0)
    self.HorizontalBox_0:SetRenderOpacity(0)
    self.Btn_ShutDown_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:RefreshQuickUnlockShow()
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PromptAcquisitionView:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetSkillMain_Tips_C:ShowDescRightPanel(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_PetSkillMain_Tips_C:OnDescTextClicked(id)
  _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.ResetDescText)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetRightPanelDescText)
  local descNote = _G.DataConfigManager:GetDescNoteConf(tonumber(id))
  local descText = string.format("\227\128\144%s\227\128\145\n%s", descNote.note, descNote.desc)
end

function UMG_PetSkillMain_Tips_C:ResetDescText()
end

function UMG_PetSkillMain_Tips_C:OnAnimationFinished(Animation)
  if Animation == self.Disappear then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002014, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
    self:DoClose()
  elseif Animation == self.Appear then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").TIPS)
    if self.Img_Mask then
      self.Img_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PetSkillMain_Tips_C:IsSwitchToPetBag()
  local GetPetBagState = self:IfHavePetBag()
  self:DispatchEvent(PetUIModuleEvent.PetSkillTipsOpen, false)
  if not GetPetBagState then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetBagOpenState, false)
    self:DispatchEvent(PetUIModuleEvent.OpenDetailPanelEvent, false)
  else
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetBagOpenState, true)
    self:DispatchEvent(PetUIModuleEvent.OnDisablePetBagItems, false)
  end
end

function UMG_PetSkillMain_Tips_C:IfHavePetBag()
  if not self.Gongming then
    return false
  end
  local HavePetBag = _G.NRCModuleManager:GetModule("PetUIModule"):HasPanel("NewPetBag")
  self.Gongming:SetVisibility(UE4.ESlateVisibility.Collapsed)
  goto lbl_27
  self.Gongming:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  ::lbl_27::
  return HavePetBag
end

function UMG_PetSkillMain_Tips_C:IsShouldCloseTips(_IsShould)
  if _IsShould then
    self:OnClose()
  end
end

function UMG_PetSkillMain_Tips_C:GetCurShowSkillId()
  return self.skillId or 0
end

return UMG_PetSkillMain_Tips_C
