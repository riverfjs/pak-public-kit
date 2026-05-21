local IOSRatingModule = NRCModuleBase:Extend("IOSRatingModule")
local IOSRatingModuleEvent = require("NewRoco.Modules.System.IOSRating.IOSRatingModuleEvent")

function IOSRatingModule:OnConstruct()
  _G.IOSRatingModuleCmd = reload("NewRoco.Modules.System.IOSRating.IOSRatingModuleCmd")
  self.data = self:SetData("IOSRatingModuleData", "NewRoco.Modules.System.IOSRating.IOSRatingModuleData")
end

function IOSRatingModule:OnActive()
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_RATING_POPUP_NOTIFY, self.OnZoneRatingPopUpNotify)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
end

function IOSRatingModule:OnDeactive()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_RATING_POPUP_NOTIFY, self.OnZoneRatingPopUpNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
end

function IOSRatingModule:OnZoneRatingPopUpNotify(rsp)
  if not RocoEnv.Is_SHIPPING and self.data.forbidRatingPopupUsingGM then
    self:Log("IOSRatingModule:OnZoneRatingTopUpNotify forbidRatingPopupUsingGM")
    return
  end
  self:Log("IOSRatingModule:OnZoneRatingTopUpNotify", rsp.rating_popup_id)
  self.data.cacheRatingPopupId = rsp.rating_popup_id
end

function IOSRatingModule:OnOpenPanel(panelData)
  if not panelData or panelData.panelName ~= "LobbyMain" or self.data.cacheRatingPopupId then
  end
end

function IOSRatingModule:OnTick(deltaTime)
  self:TriggerRatingPopUp()
end

function IOSRatingModule:TriggerRatingPopUp()
  if not self.data or not self.data.cacheRatingPopupId then
    return
  end
  local conf = _G.DataConfigManager:GetIosRatingPopupConf(self.data.cacheRatingPopupId)
  if not conf then
    return
  end
  if conf.ios_rating == Enum.DialogRatingType.DRT_HOMEPAGE then
    local isLobbyMainEnable = NRCModuleManager:DoCmd(MainUIModuleCmd.GetLobbyMainEnableState)
    if isLobbyMainEnable then
      Log.Info("IOSRatingModule:TriggerRatingPopUp DRT_HOMEPAGE")
      self:ShowRatingAlert()
    end
  elseif conf.ios_rating == Enum.DialogRatingType.DRT_HATCH_EGG then
    local isPetHatchingEnable = NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetHatchingEnableState)
    if isPetHatchingEnable then
      Log.Info("IOSRatingModule:TriggerRatingPopUp DRT_HATCH_EGG")
      self:ShowRatingAlert()
    end
  elseif conf.ios_rating == Enum.DialogRatingType.DRT_PVP_MATCH then
    local isPVPMatchEnable = NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.GetPvPQualifierEnableState)
    if isPVPMatchEnable then
      Log.Info("IOSRatingModule:TriggerRatingPopUp DRT_PVP_MATCH")
      self:ShowRatingAlert()
    end
  elseif conf.ios_rating == Enum.DialogRatingType.DRT_PET then
    local isPetInfoMainEnable = NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetInfoMainEnableState)
    if isPetInfoMainEnable then
      Log.Info("IOSRatingModule:TriggerRatingPopUp DRT_PET")
      self:ShowRatingAlert()
    end
  end
end

function IOSRatingModule:GMIOSRating(id)
  if not RocoEnv.Is_SHIPPING and self.data.forbidRatingPopupUsingGM then
    self:Log("IOSRatingModule:GMIOSRating forbidRatingPopupUsingGM")
    return
  end
  self:Log("IOSRatingModule:GMIOSRating", id)
  self.data.cacheRatingPopupId = id
end

function IOSRatingModule:GMCloseIOSRating()
  self.data.forbidRatingPopupUsingGM = true
end

function IOSRatingModule:GMOpenIOSRating()
  self.data.forbidRatingPopupUsingGM = false
end

function IOSRatingModule:ShowRatingAlert()
  self.data.cacheRatingPopupId = nil
  if RocoEnv.PLATFORM_IOS then
    UE4.UNRCStatics.ShowRatingAlert()
  elseif RocoEnv.PLATFORM_ANDROID then
    local IsHide = true
    local IsBan = true
    if _G.Enum.FunctionEntrance.FE_TAPTAP_RATING then
      IsHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_TAPTAP_RATING)
      IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TAPTAP_RATING, false)
    end
    Log.Debug("[IOSRatingModule:ShowRatingAlert] IsHide :", IsHide, ", IsBan:", IsBan)
    if IsHide or IsBan then
      return
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenTapTapTips)
  end
end

return IOSRatingModule
