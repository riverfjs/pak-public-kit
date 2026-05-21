local Base = require("NewRoco.Modules.System.MainUI.Res.UMG_Hud_Base")
local UMG_Hud_Main_C = Base:Extend("UMG_Hud_Main_C")

function UMG_Hud_Main_C:OnEnable(_conf, Hud_Pet)
  self.hudPet = Hud_Pet
  self:SetConfData(_conf)
  if Hud_Pet and UE.UObject.IsValid(Hud_Pet) then
    Hud_Pet:SubmitChange()
  end
end

function UMG_Hud_Main_C:SetConfData(_conf)
  _conf = _conf or {}
  self.AutoLockIcon:SetVisibility(not (not _conf.autoLockIconVisible or _conf.onlyShowTitleIcon) and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.FocusPanel:SetVisibility(not (not _conf.focusVisible or _conf.onlyShowTitleIcon) and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  if _conf.nameVisible and not _conf.onlyShowTitleIcon then
    self.TextName:SetText(_conf.name or "")
  else
    self.TextName:SetText("")
  end
  if _conf.nameColor then
    self.TextName:SetColorAndOpacity(_conf.nameColor)
  end
  if not string.IsNilOrEmpty(_conf.petTypeIconPath) and not _conf.onlyShowTitleIcon then
    self.PetTypeIcon:SetPath(_conf.petTypeIconPath)
  else
    self.PetTypeIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if not string.IsNilOrEmpty(_conf.ownerName) then
    self.OwnerNameText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TipText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.OwnerNameText:SetText(_conf.ownerName)
    self.TipText:SetText(LuaText.Highvaluepet_Owner_Rule_Owner)
  else
    self.OwnerNameText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TipText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local shouldShowTitle = _conf.titleVisible and not _conf.onlyShowTitleIcon and (not string.IsNilOrEmpty(_conf.title) or not string.IsNilOrEmpty(_conf.name))
  if shouldShowTitle then
    self.NameTitle:SetText(_conf.title)
  else
  end
  local titleIconNoDraw = _conf.titleIconNoDraw
  if titleIconNoDraw ~= self.titleIconNoDraw then
    if titleIconNoDraw then
      self.TitleProp.Brush.DrawAs = UE.ESlateBrushDrawType.NoDrawType
    else
      self.TitleProp.Brush.DrawAs = UE.ESlateBrushDrawType.Image
    end
  end
  local shouldShowTitleIcon = _conf.titleVisible and not string.IsNilOrEmpty(_conf.titleIcon)
  if shouldShowTitleIcon and not titleIconNoDraw and _conf.titleIcon ~= self.iconPath then
    self.iconPath = _conf.titleIcon
    self.TitleProp:SetPath(_conf.titleIcon)
  else
  end
  if not self.titleIconVisible then
    if shouldShowTitleIcon then
      if not self.titleVisible then
        if not shouldShowTitle then
          self:TryPlayAnimation(self.Icon_in, true)
        else
          self:TryPlayAnimation(self.Icon_in)
          self:TryPlayAnimation(self.Icon_move)
        end
      end
    elseif not self.titleVisible then
      if shouldShowTitle then
        self:TryPlayAnimation(self.Word_in, true)
      end
    elseif not shouldShowTitle then
      self:TryPlayAnimation(self.Word_out, true)
    end
  elseif not shouldShowTitleIcon then
    if not self.titleVisible and not shouldShowTitle then
      self:TryPlayAnimation(self.Icon_out, true)
    end
  elseif not self.titleVisible then
    if shouldShowTitle then
      self:TryPlayAnimation(self.Icon_move, true)
    end
  elseif not shouldShowTitle then
    self:TryPlayAnimation(self.Icon_move_re, true)
  end
  self.titleVisible = shouldShowTitle
  self.titleIconVisible = shouldShowTitleIcon
  self.titleIconNoDraw = titleIconNoDraw
end

function UMG_Hud_Main_C:TryPlayAnimation(anim, stopAll)
  if stopAll then
    self:StopAllAnimations()
  end
  if not anim or self:IsAnimationPlaying(anim) then
    return
  end
  self:DoPlayAnimation(anim)
end

function UMG_Hud_Main_C:DoPlayAnimation(anim)
  if not anim then
    return
  end
  self:PlayAnimation(anim)
  local playingAnims = self.playingAnims
  if not playingAnims then
    playingAnims = {}
    self.playingAnims = playingAnims
  end
  table.insert(playingAnims, anim)
  local hudPet = self.hudPet
  if hudPet and UE.UObject.IsValid(hudPet) then
    hudPet:SetPlayingAnim(true, "MainHud")
  end
end

function UMG_Hud_Main_C:OnAnimationFinished(anim)
  local playingAnims = self.playingAnims
  table.removeValue(playingAnims, anim)
  if anim == self.Icon_move_re and self.titleIconVisible and not self.titleVisible then
    self:DoPlayAnimation(self.Normal)
  end
  if not playingAnims or next(playingAnims) == nil then
    local hudPet = self.hudPet
    if hudPet and UE.UObject.IsValid(hudPet) then
      hudPet:SetPlayingAnim(false, "MainHud")
    end
  end
end

return UMG_Hud_Main_C
