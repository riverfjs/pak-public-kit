local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local UMG_Pet_HeadPortrait_C = Base:Extend("UMG_Pet_HeadPortrait_C")

function UMG_Pet_HeadPortrait_C:OnConstruct()
  self:AddButtonListener(self.BtnSkill, self.OnBtnSkill)
end

function UMG_Pet_HeadPortrait_C:OnDestruct()
  Log.Debug("\229\183\178\231\187\143OnDestruct\228\186\134")
end

function UMG_Pet_HeadPortrait_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self._timer = 0
  self.IsPlay = false
  self._longPressThreshold = BattleConst.ItemLongPressThreshold
  self.index = index
  self:SetInfo()
end

function UMG_Pet_HeadPortrait_C:SetInfo()
  local data = self.data
  if not data then
    Log.Error("\230\178\161\230\156\137data\230\149\176\230\141\174")
    return
  end
  data.hide = false
  if data.SkillId and 0 ~= data.SkillId then
    local SkillConf = _G.SkillUtils.GetSkillConf(data.SkillId)
    if SkillConf then
      self.UIIcon_2:SetPath(NRCUtils:FormatConfIconPath(SkillConf.icon, _G.UIIconPath.SkillIconPath))
      local _, iconPath = BattleUtils.GetSkillTypePath(SkillConf.Skill_Type, SkillConf.damage_type)
      self.BUFF:SetPath(iconPath)
    end
    if not data.hide then
      self.UIIcon_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BUFF:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BuffBG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self:PlayAnimation(self.Recover)
      self.UIIcon_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BUFF:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BuffBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.QuestionMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  self:SetPetPos(data)
end

function UMG_Pet_HeadPortrait_C:UpdateRound(curRound)
  self.data.curRound = curRound
end

function UMG_Pet_HeadPortrait_C:SetPetPos(Skill)
  if Skill.Pos then
    self.CanvasPanel_Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if Skill.Own == true then
      self.NRCSwitcher_37:SetActiveWidgetIndex(0)
      self.NRCText_0:SetText(string.format("%dP", Skill.Pos))
    else
      self.NRCSwitcher_37:SetActiveWidgetIndex(1)
      self.ArrangeText:SetText(string.format("%dP", Skill.Pos))
    end
  else
    self.CanvasPanel_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.data.Pos = Skill.Pos
  self.data.OpRecords = Skill.OpRecords
  self.data.is_set_info = true
end

function UMG_Pet_HeadPortrait_C:SetIconShow(Skill)
  if not Skill.hide then
    self.UIIcon_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BUFF:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BuffBG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Click_out)
    self.data.hide = Skill.hide
  end
end

function UMG_Pet_HeadPortrait_C:SetParent(_Parent, _curRound)
  self.Parent = _Parent
  self.curRound = _curRound
end

function UMG_Pet_HeadPortrait_C:PlayRemoveAnim()
  self:PlayAnimation(self.Out)
end

function UMG_Pet_HeadPortrait_C:PlayClickAnim()
  self.Select_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCImage_216:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Click)
end

function UMG_Pet_HeadPortrait_C:PlayOutAnim()
  self:PlayAnimation(self.Click_out2)
end

function UMG_Pet_HeadPortrait_C:AddOrRemove(bAdd, bAnim)
  if bAnim then
    if bAdd then
      self.IsAdd = true
      self.DelayId = DelayManager:DelayFrames(2, function()
        self:PlayAnimation(self.In)
      end)
    else
      self.IsAdd = false
      self:PlayAnimation(self.Out)
    end
  end
end

function UMG_Pet_HeadPortrait_C:OnBtnSkill()
  local data = self.data
  if data and not data.hide then
    local SkillConf = _G.DataConfigManager:GetSkillConf(data.SkillId)
    if data.EnemyPet then
      if SkillConf and not data.EnemyPet:IsDead() then
        if data.detailInfo then
          _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Open_Information_Recording, BattleManager.curRound, data.detailInfo)
        else
          _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenSkillTips, {
            skillData = SkillConf,
            HideClose = false,
            isAddImc = true,
            restraintResult = self:GetRestraintTypeByPetId(),
            is_skill_conf = true
          })
        end
      end
    else
      Log.Error("\229\174\160\231\137\169\230\149\176\230\141\174\228\184\186\231\169\186,\232\175\183\230\159\165\231\156\139\230\149\176\230\141\174")
    end
  end
end

function UMG_Pet_HeadPortrait_C:GetRestraintTypeByPetId(petId)
  if self.data and self.data.SkillId then
    local Boss = _G.BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_ENEMY)
    if Boss then
      local skill = Boss.skillComponent:GetSkillBySkillID(self.data.SkillId)
      if skill and skill.config and 1 ~= skill.config.damage_type then
        if not petId then
          local cards = _G.BattleManager.battlePawnManager.TeamatePlayer.deck.cards
          if cards and #cards > 0 then
            petId = cards[1].guid
          end
        end
        if petId then
          return skill:GetRestraintByPetId(petId)
        end
      end
    end
  end
end

function UMG_Pet_HeadPortrait_C:OnDeactive()
  if self.DelayId then
    DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_Pet_HeadPortrait_C:IsPlayAddOrRemoveAnim()
  if self:IsAnimationPlaying(self.Out) then
    return true
  end
  return false
end

function UMG_Pet_HeadPortrait_C:OnAnimationFinished(Anim)
  if Anim == self.In then
  elseif Anim == self.In_touxiang then
    self:PlayClick()
  elseif Anim == self.Out then
    if not self.IsAdd then
      if self.ParentView then
        self.ParentView:AddOrRemoveItem(false, self.index, nil, false)
      else
        Log.Warning("ParentView\230\178\161\230\156\137\230\137\190\229\136\176,\229\190\151\230\159\165\230\159\165\229\149\165\233\151\174\233\162\152")
      end
    end
  elseif Anim == self.Click_out or Anim == self.Click_out2 then
    self.Select_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_216:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Anim == self.Click then
    self:PlayAnimation(self.Loop, 0, 9999)
  end
end

function UMG_Pet_HeadPortrait_C:PlayClick()
  if 1 == self.index then
    self.Select_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCImage_216:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Click)
  end
end

return UMG_Pet_HeadPortrait_C
