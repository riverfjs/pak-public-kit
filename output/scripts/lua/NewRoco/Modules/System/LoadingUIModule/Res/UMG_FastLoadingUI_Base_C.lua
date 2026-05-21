local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local UMG_FastLoadingUI_Base_C = _G.NRCViewBase:Extend("UMG_FastLoadingUI_Base_C")

function UMG_FastLoadingUI_Base_C:Ctor()
  self:Log("[Ctor]")
  self.LoadingTipsList = {}
  self.tipsChangeTime = 0
  self.tipsTime = 0
  self.tipsIndex = 1
  self.tipsChangeTime = _G.DataConfigManager:GetGlobalConfig("loading_tips_change").num / 1000
  self.FxPlayed = false
  self.FxFinished = false
end

function UMG_FastLoadingUI_Base_C:OnDeconstruct()
  self:Log("[OnDestruct]")
end

function UMG_FastLoadingUI_Base_C:OnActive(content, tips, switch_reason, teleport_id)
  self:Log("[OnActive] content:", content, "tips:", tips, "switch_reason:", switch_reason, "teleport_id:", teleport_id)
  self.FxPlayed = false
  self.FxFinished = false
  self.tipsChangeTime = 0
  self.LoadingTipsList = {}
  self.tipsTime = 0
  self.tipsIndex = 1
  self.tipsChangeTime = _G.DataConfigManager:GetGlobalConfig("loading_tips_change").num / 1000
  self.switch_reason = switch_reason
  self.teleport_id = teleport_id
  self.IsSetTipsData = false
  self.OutDuration = self.Out and self.Out:GetEndTime() - self.Out:GetStartTime() or 0.5
  self:SetData(content, tips, switch_reason, teleport_id)
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_FastLoadingUI_Base_C:OnDeactive()
  self:Log("[OnDeactive]")
end

function UMG_FastLoadingUI_Base_C:OnEnable()
  self:Log("[OnEnable]", self.className)
  self.FxPlayed = false
  self.FxFinished = false
  UE4Helper.SetDesiredShowCursor(true, self.className)
  ScenePlayerInputManager.Pause()
  local bIsBlockPCInput = true
  _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_OPENED, bIsBlockPCInput)
  self.IsSetTipsData = false
  self:ShowBackGround(false == _G.GlobalConfig.SetFastLoadingWorldRendering)
end

function UMG_FastLoadingUI_Base_C:OnDisable()
  self:Log("[OnDisable]")
  self.OnlineText = nil
  UE4Helper.ReleaseDesiredShowCursor("UMG_FastLoadingUI_Common_C")
  ScenePlayerInputManager.Resume()
  local bIsBlockPCInput = false
  _G.NRCEventCenter:DispatchEvent(LoadingUIModuleEvent.LOADING_UI_CLOSED, bIsBlockPCInput)
  _G.GlobalConfig.SetFastLoadingWorldRendering = false
end

function UMG_FastLoadingUI_Base_C:OnViewTick(deltaTime)
  if self.enableView then
    self.tipsTime = self.tipsTime + deltaTime
    if self.tipsTime > self.tipsChangeTime then
      self:UpdateTips()
    end
  end
end

function UMG_FastLoadingUI_Base_C:SetData(content, tips, switch_reason, teleport_id, teleport_rule_id)
  self:Log("[SetData] content:", content, "tips:", tips, "switch_reason:", switch_reason, "teleport_id:", teleport_id, "teleport_rule_id:", teleport_rule_id)
  self.switch_reason = switch_reason
  self.teleport_id = teleport_id
  self.teleport_rule_id = teleport_rule_id
  if not self.IsSetTipsData then
    self:InitLoadingTipsList()
    self:UpdateTips()
    self.IsSetTipsData = true
  end
  local SceneModule = NRCModuleManager:GetModule("SceneModule")
  local TeleportData = SceneModule and SceneModule:GetTeleportLoadingCustomData()
  local HomeName = TeleportData and TeleportData.TeleportHomeName
  local FarmName = TeleportData and TeleportData.TeleportFarmName
  if HomeName and DataConfigManager:GetLocalizationConf("home_visitor_loading_tips", true) then
    self.OnlineText = string.format(LuaText.home_visitor_loading_tips, HomeName)
    self.content:SetText(self.OnlineText)
  elseif FarmName and DataConfigManager:GetLocalizationConf("farm_visitor_loading_tips", true) then
    self.OnlineText = string.format(LuaText.farm_visitor_loading_tips, FarmName)
    self.content:SetText(self.OnlineText)
  else
    self.OnlineText = nil
  end
  if self.switch_reason then
    if self.switch_reason == ProtoEnum.TeleportReason.ENUM.LEAVE_ONLINE_VISIT then
      self.OnlineText = _G.DataConfigManager:GetLocalizationConf("online_leave_loading_text").msg
      self.content:SetText(self.OnlineText)
    elseif self.switch_reason == ProtoEnum.TeleportReason.ENUM.ENTER_ONLINE_VISIT then
      self.OnlineText = _G.DataConfigManager:GetLocalizationConf("online_enter_loading_text").msg
      self.content:SetText(self.OnlineText)
    elseif self.switch_reason == ProtoEnum.TeleportReason.ENUM.WORLDCOMBAT_PET_ALL_DIE then
      self.OnlineText = _G.DataConfigManager:GetLocalizationConf("leaderfight_all_pet_death").msg
      self.content:SetText(self.OnlineText)
    elseif self.switch_reason == ProtoEnum.TeleportReason.ENUM.PET_GUARD_STEAL_HIT then
      self.OnlineText = _G.DataConfigManager:GetLocalizationConf("plant_home_steal_guard_back_home").msg
      self.content:SetText(self.OnlineText)
    elseif self.switch_reason == ProtoEnum.TeleportReason.ENUM.ENTER_HOME then
    end
  end
  self:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_FastLoadingUI_Base_C:ShowBackGround(bShow)
  self:Log("ShowBackGround ", bShow)
end

function UMG_FastLoadingUI_Base_C:InitLoadingTipsList()
  self:Log("[InitLoadingTipsList]")
  local tableId = _G.DataConfigManager.ConfigTableId.LOADING_TIPS_CONF
  local allData = _G.DataConfigManager:GetAllByTableID(tableId)
  local allTipsList = {}
  local defaultUnlockList = {}
  local levelTipsList = {}
  local teleportAddList = {}
  local teleportLimitList = {}
  local specialLimitList = {}
  local specialAddList = {}
  for _, tipsData in ipairs(allData) do
    table.insert(allTipsList, tipsData)
    if tipsData.tips_show_type == Enum.TipsShowType.TST_ROLE_LV_ADD then
      local minLevel
      if tipsData.para1 then
        minLevel = tipsData.para1[1]
      end
      local maxLevel = tipsData.para2
      if minLevel and maxLevel then
        local level = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
        if minLevel <= level and maxLevel >= level then
          table.insert(levelTipsList, tipsData)
        end
      end
    elseif tipsData.tips_show_type == Enum.TipsShowType.TST_TELEPORT_ADD then
      local teleportList = tipsData.para1
      if teleportList then
        for _, target in ipairs(teleportList) do
          if target == self.teleport_id then
            table.insert(teleportAddList, tipsData)
            break
          end
        end
      end
    elseif tipsData.tips_show_type == Enum.TipsShowType.TST_TELEPORT_LIMIT then
      local teleportList = tipsData.para1
      if teleportList then
        for _, target in ipairs(teleportList) do
          if target == self.teleport_id then
            table.insert(teleportLimitList, tipsData)
            break
          end
        end
      end
    elseif tipsData.tips_show_type == Enum.TipsShowType.TST_TELEPORT_RULES_LIMIT then
      local teleportList = tipsData.para1
      if teleportList then
        for _, target in ipairs(teleportList) do
          if target == self.teleport_rule_id then
            table.insert(specialLimitList, tipsData)
            break
          end
        end
      end
    elseif tipsData.tips_show_type == Enum.TipsShowType.TST_TELEPORT_RULES_ADD then
      local teleportList = tipsData.para1
      if teleportList then
        for _, target in ipairs(teleportList) do
          if target == self.teleport_rule_id then
            table.insert(specialAddList, tipsData)
            break
          end
        end
      end
    else
      table.insert(defaultUnlockList, tipsData)
    end
  end
  self.LoadingTipsList = {}
  if #teleportLimitList > 0 then
    self.LoadingTipsList = teleportLimitList
  elseif #specialLimitList > 0 then
    self.LoadingTipsList = specialLimitList
  elseif #specialAddList > 0 then
    for i = 1, #defaultUnlockList do
      table.insert(self.LoadingTipsList, defaultUnlockList[i])
    end
    for i = 1, #specialAddList do
      table.insert(self.LoadingTipsList, specialAddList[i])
    end
  else
    for i = 1, #defaultUnlockList do
      table.insert(self.LoadingTipsList, defaultUnlockList[i])
    end
    for i = 1, #levelTipsList do
      table.insert(self.LoadingTipsList, levelTipsList[i])
    end
    for i = 1, #teleportAddList do
      table.insert(self.LoadingTipsList, teleportAddList[i])
    end
  end
  if 0 == #self.LoadingTipsList then
    self.LoadingTipsList = allTipsList
  end
end

function UMG_FastLoadingUI_Base_C:UpdateTips()
  if self.OnlineText then
    if self.content then
      self.content:SetText(self.OnlineText)
    end
    return
  end
  if not self.LoadingTipsList or 0 == #self.LoadingTipsList then
    self:InitLoadingTipsList()
  end
  local lastIndex = self.tipsIndex
  self.tipsIndex = self.tipsIndex + 1
  if self.tipsIndex > #self.LoadingTipsList then
    self.tipsIndex = math.random(1, #self.LoadingTipsList)
    if self.tipsIndex == lastIndex then
      self.tipsIndex = 1
    end
  end
  local tipsData = self.LoadingTipsList[self.tipsIndex]
  if self.Title then
    self.Title:SetText(tipsData.loading_tips_title)
  end
  if self.content then
    self.content:SetText(tipsData.loading_tips_text)
  end
  self.tipsTime = 0
end

return UMG_FastLoadingUI_Base_C
