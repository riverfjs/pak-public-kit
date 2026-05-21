local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local UMG_Login_AccountInfo_C = _G.NRCPanelBase:Extend("UMG_Login_AccountInfo_C")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")

function UMG_Login_AccountInfo_C:OnConstruct()
  self.Marks = {}
  self:OnAddEventListener()
end

function UMG_Login_AccountInfo_C:OnAddEventListener()
  self:RegisterEvent(self, UpdateUIModuleEvent.SetUiAlpha, self.ChangBG)
  self:RegisterEvent(self, UpdateUIModuleEvent.UpdateSvrTime, self.UpdateSvrTime)
  self:RegisterEvent(self, UpdateUIModuleEvent.UpdateLocation, self.UpdateLocation)
  self:RegisterEvent(self, UpdateUIModuleEvent.SetBattleId, self.SetBattleId)
  self:RegisterEvent(self, UpdateUIModuleEvent.UpdateWaterMark, self.UpdateWaterMark)
end

function UMG_Login_AccountInfo_C:OnDisable()
end

function UMG_Login_AccountInfo_C:OnDestruct()
  self:UnRegisterEvent(self, UpdateUIModuleEvent.SetUiAlpha, self.ChangBG)
  self:UnRegisterEvent(self, UpdateUIModuleEvent.UpdateSvrTime, self.UpdateSvrTime)
  self:UnRegisterEvent(self, UpdateUIModuleEvent.UpdateWaterMark, self.UpdateWaterMark)
  if self.DelayWaterMarkId then
    _G.DelayManager:CancelDelayById(self.DelayWaterMarkId)
    self.DelayWaterMarkId = nil
  end
  if self.Marks then
    for k, v in pairs(self.Marks) do
      v:Destruct()
      v:ReleaseForce()
    end
    table.clear(self.Marks)
  end
end

function UMG_Login_AccountInfo_C:OnActive()
  self.UIDtext:SetText(" ")
  if self.Text_SettingID then
    self.Text_SettingID:SetText(" ")
  else
    Log.Debug("UMG_Login_AccountInfo_C: Text_SettingID is empty or uninitialized")
  end
  self.Text_UIN:SetText(" ")
  self.Text_Gopenid:SetText(" ")
  self.Text_Time:SetText(" ")
  self.Text_X:SetText(" ")
  self.Text_Y:SetText(" ")
  self.Text_Z:SetText(" ")
  self.Text_BattleId:SetText(" ")
end

function UMG_Login_AccountInfo_C:RefreshWaterMask()
  if _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel.playerInfo and _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info then
    Log.Error("UMG_Login_AccountInfo_C: RefreshWaterMask close_watermark", _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info.close_watermark)
    Log.Error("UMG_Login_AccountInfo_C: RefreshWaterMask end_time", _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info.end_time)
    Log.Error("UMG_Login_AccountInfo_C: RefreshWaterMask ServerTime", _G.ZoneServer:GetServerTime() / 1000)
    if _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info.close_watermark and _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info.end_time then
      if _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info.end_time > _G.ZoneServer:GetServerTime() / 1000 then
        self.MarkCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.DelayWaterMarkId = _G.DelayManager:DelaySeconds(1, self.RefreshWaterMask, self)
      else
        self.MarkCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        if self.DelayWaterMarkId then
          _G.DelayManager:CancelDelayById(self.DelayWaterMarkId)
          self.DelayWaterMarkId = nil
        end
        local uid = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.uin
        if #self.Marks > 0 then
          for i = 1, #self.Marks do
            self.Marks[i]:UpdateUid(uid)
          end
        end
        local ViewPortSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
        local LineNum = math.ceil(ViewPortSize.Y / 1080)
        local ColNum = math.ceil(ViewPortSize.X / 2340) * 5
        for i = 1, LineNum do
          for j = 1, ColNum do
            local pos = UE4.FVector2D(500 * (j - 1), 1080 * (i - 1))
            local size = UE4.FVector2D(500, 1080)
            local MarkItem = UE4.UWidgetBlueprintLibrary.Create(self, self.Mark)
            self.MarkCanvas:AddChildToCanvas(MarkItem)
            MarkItem:UpdateUid(uid)
            MarkItem.Slot:SetPosition(pos)
            MarkItem.Slot:SetSize(size)
            table.insert(self.Marks, MarkItem)
          end
        end
      end
    else
      self.MarkCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      if self.DelayWaterMarkId then
        _G.DelayManager:CancelDelayById(self.DelayWaterMarkId)
        self.DelayWaterMarkId = nil
      end
      local uid = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.uin
      if #self.Marks > 0 then
        for i = 1, #self.Marks do
          self.Marks[i]:UpdateUid(uid)
        end
      end
      local ViewPortSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
      local LineNum = math.ceil(ViewPortSize.Y / 1080)
      local ColNum = math.ceil(ViewPortSize.X / 2340) * 5
      for i = 1, LineNum do
        for j = 1, ColNum do
          local pos = UE4.FVector2D(500 * (j - 1), 1080 * (i - 1))
          local size = UE4.FVector2D(500, 1080)
          local MarkItem = UE4.UWidgetBlueprintLibrary.Create(self, self.Mark)
          self.MarkCanvas:AddChildToCanvas(MarkItem)
          MarkItem:UpdateUid(uid)
          MarkItem.Slot:SetPosition(pos)
          MarkItem.Slot:SetSize(size)
          table.insert(self.Marks, MarkItem)
        end
      end
    end
  end
end

function UMG_Login_AccountInfo_C:RefreshUID()
  local OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
  local Data
  if OnlineModule then
    Data = OnlineModule.data
  end
  if _G.DataModelMgr.PlayerDataModel.playerInfo then
    self.UIDtext:SetText("" .. tostring(_G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.uin))
    if self:ShowLeftUpTips() then
      local version = _G.DataConfigManager:GetWaterMarkLocalizationConf("permanent_watermark_lowerleft")
      if version and version.msg then
        self.Text:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Text:SetText(version.msg)
      else
        self.Text:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.Text_UIN:SetText(_G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.uin)
      local LoginModule = _G.NRCModuleManager:GetModule("LoginModule")
      self.Text_SettingID:SetText(LoginModule.data:GetServer().id)
    end
    self:RefreshWaterMask()
  else
    self.UIDtext:SetText(" ")
  end
end

function UMG_Login_AccountInfo_C:UpdateWaterMark(water_mark_info)
  if _G.GlobalConfig.bShowTopMark then
    self:RefreshWaterMask()
  else
    self.MarkCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Login_AccountInfo_C:UpdateSvrTime(svr_time)
  if self:ShowLeftUpTips() and svr_time then
    self.Text_Time:SetText(svr_time)
  end
end

function UMG_Login_AccountInfo_C:UpdateLocation(player)
  if self:ShowLeftUpTips() and player then
    local NowHeroPos = player:GetActorLocation()
    self.Text_X:SetText(string.format("X=" .. "%.2f", NowHeroPos.X) .. ",")
    self.Text_Y:SetText(string.format("Y=" .. "%.2f", NowHeroPos.Y) .. ",")
    self.Text_Z:SetText(string.format("Z=" .. "%.2f", NowHeroPos.Z))
  end
end

function UMG_Login_AccountInfo_C:SetBattleId(battleId)
  if self:ShowLeftUpTips() then
    self.Text_BattleId:SetText(battleId)
  end
end

function UMG_Login_AccountInfo_C:ChangBG()
  self.UIDtext:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_Login_AccountInfo_C:ShowLeftUpTips()
  return not _G.AppMain:GetFormalPipeline()
end

return UMG_Login_AccountInfo_C
