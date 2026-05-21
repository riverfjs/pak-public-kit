local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Appearance_Bounced_C = _G.NRCPanelBase:Extend("UMG_Appearance_Bounced_C")

local function GetUTF8CharLength(str)
  if not str then
    return 0
  end
  local len = 0
  for _ in string.gmatch(str, "([%z\001-\127\239\191\189-\239\191\189][\239\191\189-\239\191\189]*)") do
    len = len + 1
  end
  return len
end

local function SubUTF8String(str, maxChars)
  if not str then
    return ""
  end
  local chars = {}
  local count = 0
  for char in string.gmatch(str, "([%z\001-\127\239\191\189-\239\191\189][\239\191\189-\239\191\189]*)") do
    count = count + 1
    if maxChars >= count then
      table.insert(chars, char)
    else
      break
    end
  end
  return table.concat(chars)
end

function UMG_Appearance_Bounced_C:OnConstruct()
  self.data = self.module:GetData("AppearanceModuleData")
  self:SetChildViews(self.PopUp3)
  self.textMaxLen = 6
end

function UMG_Appearance_Bounced_C:OnActive(type, param, _lastClothName, _CurClothName)
  self:LoadAnimation(0)
  self:OnAddEventListener()
  self.type = type
  self.uiData = param
  self.LastClothName = _lastClothName
  self.CurClothName = _CurClothName
  self:SetCommonPopUpInfo(self.PopUp3)
  self:UpdateBtnInfo(type)
  self:UpdatePanelInfo(type)
  self:AddPcInputBlock()
end

function UMG_Appearance_Bounced_C:OnDeactive()
  self:RemovePcInputBlock()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnVirtualKeyboardShowOrHide, self.OnVirtualKeyboardShowOrHide)
end

function UMG_Appearance_Bounced_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtnCancelClicked
  CommonPopUpData.Btn_RightHandler = self.OnBtnConfirmClicked
  CommonPopUpData.ClosePanelHandler = self.OnBtnCancelClicked
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Appearance_Bounced_C:OnPcCloseByKeyDirectly()
  self:OnBtnCancelClicked()
end

function UMG_Appearance_Bounced_C:AddPcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddBlockIMC, self, self.depth)
end

function UMG_Appearance_Bounced_C:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveBlockIMC, self)
end

function UMG_Appearance_Bounced_C:OnAddEventListener()
  self:AddDelegateListener(self.UsernameDisplay.OnTextEndTransaction, self.OnTextEndTransaction)
  self:AddDelegateListener(self.UsernameDisplay.OnTextChanged, self.InputInfoChange)
  _G.NRCEventCenter:RegisterEvent("UMG_Appearance_Bounced_C", self, _G.NRCGlobalEvent.OnVirtualKeyboardShowOrHide, self.OnVirtualKeyboardShowOrHide)
end

function UMG_Appearance_Bounced_C:OnVirtualKeyboardShowOrHide(bShow)
  if bShow then
    if self.PopUp3 and self.PopUp3.FullScreen_Close then
      self.PopUp3.FullScreen_Close:SetIsEnabled(false)
    end
  else
    if self.PopUp3 and self.PopUp3.FullScreen_Close then
      self.PopUp3.FullScreen_Close:SetIsEnabled(true)
    end
    self:OnTextEndTransaction()
  end
end

function UMG_Appearance_Bounced_C:OnTextEndTransaction()
  self._isPinYin = false
  self:InputInfoChange(self.UsernameDisplay:GetText())
end

function UMG_Appearance_Bounced_C:InputInfoChange(Text)
  _G.NRCAudioManager:PlaySound2DAuto(1086, "UMG_Appearance_Bounced_C:OnBtnConfirmClicked")
  if self._isPinYin then
    return
  end
  local text = self.UsernameDisplay:GetSelectedText()
  if text and "" ~= text then
    self._isPinYin = true
    return
  end
  local len = GetUTF8CharLength(Text)
  if len > self.textMaxLen then
    local truncatedText = SubUTF8String(Text, self.textMaxLen)
    self.UsernameDisplay:SetText(truncatedText)
  end
  UIUtils.RemoveInvalidCharsHandle(self.UsernameDisplay)
  local bIsLegal = UIUtils.CheckNameIsLegal(self.UsernameDisplay:GetText())
  self.NameHint:SetVisibility(bIsLegal and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  UIUtils.SetBtnGary(self.PopUp3.Btn_Right, not bIsLegal, bIsLegal)
end

function UMG_Appearance_Bounced_C:OnDestruct()
end

function UMG_Appearance_Bounced_C:UpdateBtnInfo(type)
  if type == AppearanceModuleEnum.OpenTipType.FASHION_CHANGENAME then
    self.PopUp3:SetBtnRightText(LuaText.umg_appearance_bounced_1)
    self.PopUp3:SetBtnLeftText(LuaText.umg_appearance_bounced_2)
  elseif type == AppearanceModuleEnum.OpenTipType.FASHION_CHANGESUIT then
    self.PopUp3:SetBtnRightText(LuaText.umg_appearance_bounced_3)
    self.PopUp3:SetBtnLeftText(LuaText.umg_appearance_bounced_4)
  elseif type == AppearanceModuleEnum.OpenTipType.FASHION_CLOSE then
    self.PopUp3:SetBtnRightText(LuaText.umg_appearance_bounced_5)
    self.PopUp3:SetBtnLeftText(LuaText.umg_appearance_bounced_4)
  elseif type == AppearanceModuleEnum.OpenTipType.SALON_CONFIRM then
    self.PopUp3:SetBtnRightText(LuaText.umg_appearance_bounced_3)
    self.PopUp3:SetBtnLeftText(LuaText.umg_appearance_bounced_4)
  elseif type == AppearanceModuleEnum.OpenTipType.SALON_CLOSE then
    self.PopUp3:SetBtnRightText(LuaText.umg_appearance_bounced_5)
    self.PopUp3:SetBtnLeftText(LuaText.umg_appearance_bounced_4)
  end
end

function UMG_Appearance_Bounced_C:UpdatePanelInfo(type)
  if type == AppearanceModuleEnum.OpenTipType.FASHION_CHANGENAME then
    self.UsernameDisplay:SetText(self.uiData[1].Name)
  elseif type == AppearanceModuleEnum.OpenTipType.FASHION_CHANGESUIT then
    local LastClothName = self.LastClothName
    local CurClothName = self.CurClothName
    local text1 = _G.DataConfigManager:GetLocalizationConf("fashion_closet_text").msg
    local text2 = _G.DataConfigManager:GetLocalizationConf("fashion_closet_text_small").msg
    local text = text1 .. "\n" .. "<orange>" .. text2 .. "</>"
  elseif type == AppearanceModuleEnum.OpenTipType.FASHION_CLOSE then
    local text1 = _G.DataConfigManager:GetLocalizationConf("fashion_close_text").msg
    local text2 = _G.DataConfigManager:GetLocalizationConf("fashion_close_text_small").msg
    local text = text1 .. "\n" .. "<orange>" .. text2 .. "</>"
  elseif type == AppearanceModuleEnum.OpenTipType.SALON_CONFIRM then
    local text = _G.DataConfigManager:GetLocalizationConf("salon_btn_text").msg
    self.NRCImage_77:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif type == AppearanceModuleEnum.OpenTipType.SALON_CLOSE then
    local text1 = _G.DataConfigManager:GetLocalizationConf("salon_close_text").msg
    local text2 = _G.DataConfigManager:GetLocalizationConf("salon_close_text_small").msg
    local text = text1 .. "\n" .. "<orange>" .. text2 .. "</>"
  end
  self.NameHint:SetText(LuaText.illegal_name_tips)
end

function UMG_Appearance_Bounced_C:OnBtnCancelClicked()
  self:LoadAnimation(2)
  if self.type == AppearanceModuleEnum.OpenTipType.FASHION_CHANGESUIT then
    self.module:SetSelectWardrobe(self.data.lastSelectedWardrobeIndex - 1)
    self.data.canChangeWardrobeIndex = false
  end
  _G.NRCAudioManager:PlaySound2DAuto(1071, "UMG_Appearance_Bounced_C:OnBtnCancelClicked")
end

function UMG_Appearance_Bounced_C:OnBtnConfirmClicked()
  self:LoadAnimation(2)
  if self.type == AppearanceModuleEnum.OpenTipType.FASHION_CHANGENAME then
    local newName = self.UsernameDisplay:GetText()
    local nameLen = GetUTF8CharLength(newName)
    if 0 == nameLen then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_appearance_bounced_7)
    elseif nameLen > self.textMaxLen then
      local tips = _G.DataConfigManager:GetLocalizationConf("fashion_closet_text_oversize").msg
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
    elseif not UIUtils.CheckNameIsLegal(newName) then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.input_sensitive_words_tips)
      Log.Debug("FASHION_CHANGENAME HasSpecialChars newName", newName)
    else
      local bIsProperly = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckOutfitProperly)
      if not bIsProperly then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.dressup_wear_pajamas_tips)
        return
      end
      local fashionIds = {}
      local bHasWand = false
      if self.data.TempAppearData and #self.data.TempAppearData > 0 then
        for k, v in ipairs(self.data.TempAppearData) do
          local itemConf
          if not bHasWand then
            itemConf = _G.DataConfigManager:GetFashionItemConf(v.FashionId)
          end
          if itemConf and itemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
            bHasWand = true
          end
          table.insert(fashionIds, v.FashionId)
        end
      end
      if not bHasWand then
        local wandId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSuitWandId)
        table.insert(fashionIds, wandId)
      end
      local salonIds = {}
      if self.data.TempBeautyData and #self.data.TempBeautyData > 0 then
        for k, v in ipairs(self.data.TempBeautyData) do
          table.insert(salonIds, v.SalonId)
        end
      end
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetFashionDataReq, self.uiData[1].Index, fashionIds, newName, false, false, nil, nil, salonIds)
    end
  elseif self.type == AppearanceModuleEnum.OpenTipType.FASHION_CHANGESUIT then
    self.data.canChangeWardrobeIndex = true
    self.module:SetSelectWardrobe(self.uiData - 1)
  elseif self.type == AppearanceModuleEnum.OpenTipType.FASHION_CLOSE then
    self.module:OnCmdCloseAppearanceClosetPanel()
  elseif self.type == AppearanceModuleEnum.OpenTipType.SALON_CONFIRM then
    self:DispatchEvent(AppearanceModuleEvent.BeautyConfirm)
  elseif self.type == AppearanceModuleEnum.OpenTipType.SALON_CLOSE then
    self.module:OnCmdOpenBeautyPanel()
  end
  _G.NRCAudioManager:PlaySound2DAuto(1071, "UMG_Appearance_Bounced_C:OnBtnConfirmClicked")
end

function UMG_Appearance_Bounced_C:GetNameLen(Name)
  local str = string.StringGetTotalNum(Name)
  return str
end

function UMG_Appearance_Bounced_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

return UMG_Appearance_Bounced_C
