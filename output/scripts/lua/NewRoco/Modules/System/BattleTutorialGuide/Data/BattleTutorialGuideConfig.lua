local BattleTutorialGuideConfig = NRCClass:Extend("GuideGroupConfig")
local BattleTutorialGuideModuleUtils = require("NewRoco.Modules.System.BattleTutorialGuide.BattleTutorialGuideModuleUtils")
local GuideConfigTypes = require("NewRoco.Modules.System.Guidance.Types.GuideConfigTypes")

function BattleTutorialGuideConfig:InitDataTable()
  self.guideGroups = {}
  local guideCtrlConfigs = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.BATTLE_GUIDE_CONF)
  if guideCtrlConfigs then
    self:InsertGuideGroups(guideCtrlConfigs)
  end
  guideCtrlConfigs = self:SimulatedData()
  if guideCtrlConfigs then
    self:InsertGuideGroups(guideCtrlConfigs)
  end
  for _, guideGroup in pairs(self.guideGroups) do
    table.sort(guideGroup, function(a, b)
      return a.battle_lead_order < b.battle_lead_order
    end)
  end
  self.panelNameMap = {
    UMG_BattleMainWindow = "BattleUIModule/BattleMain",
    TeamPetClickTip = "TeamPetClickTip",
    EnemyPetClickTip = "EnemyPetClickTip"
  }
end

function BattleTutorialGuideConfig:InsertGuideGroups(guideCtrlConfigs)
  for _, guideCtrlConfig in pairs(guideCtrlConfigs) do
    local data = {
      id = guideCtrlConfig.id,
      battle_lead_group = guideCtrlConfig.battle_lead_group,
      battle_lead_order = guideCtrlConfig.battle_lead_order,
      battle_guidance_location = guideCtrlConfig.battle_guidance_location,
      battle_lead_Finish_type = guideCtrlConfig.battle_lead_Finish_type,
      battle_lead_ctrl = guideCtrlConfig.battle_lead_ctrl,
      force_termination = guideCtrlConfig.force_termination
    }
    data.CtrlConf = self:GetCtrlConf(guideCtrlConfig.battle_lead_ctrl)
    local group_id = data.battle_lead_group
    if not self.guideGroups[group_id] then
      self.guideGroups[group_id] = {}
    end
    table.insert(self.guideGroups[group_id], data)
  end
end

function BattleTutorialGuideConfig:GetCtrlConf(id)
  if not id then
    Log.Warning("GetCtrlConf.Func battle_lead_ctrl\228\184\186\231\169\186 BATTLE_GUIDE_CONF\232\161\168\231\154\132battle_lead_ctrl\229\173\151\230\174\181=")
    return nil
  end
  if 0 == id then
    return nil
  end
  local conf = _G.DataConfigManager:GetGuideCtrlConf(id)
  if not conf then
    Log.Warning("GetCtrlConf.Func battle_lead_ctrl\230\178\161\230\156\137\230\137\190\229\136\176\229\156\168GUIDE_CTRL_CONF\233\135\140\231\154\132\233\133\141\231\189\174\239\188\140\232\175\183\230\163\128\230\159\165\232\161\168GUIDE_CTRL_CONF\230\152\175\229\144\166\230\156\137id=", id)
    return nil
  end
  local answer = {
    delay_time = conf.delay_time,
    transparence = conf.transparence,
    finish_button_showtime = conf.finish_button_showtime,
    finish_overtime = conf.finish_overtime,
    strong_guide = conf.strong_guide,
    type_id = conf.type_id,
    active_ia_watch = conf.active_ia_watch
  }
  return answer
end

function BattleTutorialGuideConfig:TryGetGuideWidget(location, isStrongGuidance, ui_path)
  if ui_path then
    return BattleTutorialGuideModuleUtils.GetGuideWidget(ui_path)
  else
    Log.Warning("\230\178\161\230\156\137\230\137\190\229\136\176\230\142\167\228\187\182\239\188\140\230\178\161\230\156\137\229\133\179\228\186\142\232\142\183\229\143\150location\231\154\132\229\135\189\230\149\176\239\188\140\232\175\183\230\163\128\230\159\165, battle_guidance_location=", location, "isStrongGuidance=", isStrongGuidance)
  end
  return nil
end

function BattleTutorialGuideConfig:SimulatedData()
  local answer = {}
  local cfg = {
    id = "SimulatedId_1",
    battle_lead_group = "SimulatedGroup_1",
    battle_lead_order = 1,
    battle_guidance_location = Enum.BattleGuidanceLocation.BGL_CAPTURE,
    battle_lead_ctrl = 700001,
    battle_lead_Finish_type = Enum.BattleLeadFinishType.BLFT_UI_BUTTTON_CLICIK
  }
  table.insert(answer, cfg)
  cfg = {
    id = "SimulatedId_2",
    battle_lead_group = "SimulatedGroup_1",
    battle_lead_order = 2,
    battle_guidance_location = Enum.BattleGuidanceLocation.BGL_CAPTURE_1,
    battle_lead_ctrl = 700002,
    battle_lead_Finish_type = Enum.BattleLeadFinishType.BLFT_UI_BUTTTON_CLICIK
  }
  table.insert(answer, cfg)
  return answer
end

function BattleTutorialGuideConfig:GetGroup(id)
  return self.guideGroups[id]
end

function BattleTutorialGuideConfig:TryGetGuideWidgetWithFocusId(typeId)
  if not typeId then
    Log.Warning("TryGetGuideWidgetWithFocusId.Func typeId\228\184\186\231\169\186")
    return nil
  end
  local focusConf = _G.DataConfigManager:GetGuideFocusConf(typeId)
  if not focusConf then
    Log.Warning("TryGetGuideWidgetWithFocusId.Func typeId\230\178\161\230\156\137\230\137\190\229\136\176\229\156\168GUIDE_FOCUS_CONF\233\135\140\231\154\132\233\133\141\231\189\174\239\188\140\232\175\183\230\163\128\230\159\165\232\161\168GUIDE_FOCUS_CONF\230\152\175\229\144\166\230\156\137id=", typeId)
    return nil
  end
  if not focusConf.ui_path then
    Log.Warning("TryGetGuideWidgetWithFocusId.Func focusConf.ui_path\228\184\186\231\169\186\239\188\140typeId=", typeId)
    return nil
  end
  local ui_path = {}
  for _, name in pairs(focusConf.ui_path) do
    table.insert(ui_path, name)
  end
  if not ui_path[1] then
    Log.Warning("TryGetGuideWidgetWithFocusId.Func ui_path[1]\228\184\186\231\169\186\239\188\140typeId=", typeId)
    return nil
  end
  local paneName = ui_path[1]
  paneName = self.panelNameMap[paneName]
  if paneName then
    ui_path[1] = paneName
  else
    Log.Warning("\232\183\175\229\190\132\231\149\140\233\157\162=", ui_path[1], "\228\184\141\229\173\152\229\156\168\230\152\160\229\176\132\232\183\175\229\190\132\239\188\140\232\175\183\232\129\148\231\179\187yukahe\230\183\187\229\138\160\230\152\160\229\176\132\232\183\175\229\190\132")
    return nil
  end
  if focusConf.ui_button_name then
    table.insert(ui_path, focusConf.ui_button_name)
  end
  local targetWidget, targetPanelData, pathWidgets = BattleTutorialGuideModuleUtils.GetGuideWidget(ui_path)
  return targetWidget, targetPanelData, pathWidgets
end

return BattleTutorialGuideConfig
