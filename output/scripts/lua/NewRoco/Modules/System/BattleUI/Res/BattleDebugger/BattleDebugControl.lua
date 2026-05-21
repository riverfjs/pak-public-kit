local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local JsonUtils = require("Common.JsonUtils")
local BattleField = require("NewRoco.Modules.Core.Battle.Common.BattleField")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local BattleDebugControl = NRCClass()
local tInsert = table.insert
local TeamPetCount = 6
local EnterBattleState = {
  WaitStart = 1,
  AddItemsToBattle = 2,
  TeleportToBattleCenter = 3,
  SetPlayerSex = 4,
  AddPetTeams = 5,
  SetPetTeams = 6,
  WaitEnterBattle = 7,
  Finish = 8
}

function BattleDebugControl:Ctor()
  self:Reset()
  self.battleManager = _G.BattleManager
  self.pawnManager = self.battleManager.battlePawnManager
  _G.BattleEventCenter:Bind(self, BattleEvent.ROUND_SELECT_START, BattleEvent.PrepareBattleOver)
  NRCEventCenter:RegisterEvent("BattleDebugControl", self, TaskModuleEvent.BattleOver, self.OnExitBattleEvent)
  NRCEventCenter:RegisterEvent("BattleDebugControl", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnSceneLoaded)
  self:CollectSkillData()
  self:CollectPetData()
  self:CollectMonsterData()
  self:CollectPlayerSkillData()
  self:CollectNPCData()
  self:CollectWeatherData()
  self:CollectBattleTemp()
  self.BattlePosCache = {
    ["\232\191\155\233\153\132\232\191\145\230\136\152\230\150\151"] = {},
    ["\229\165\165\230\150\175\232\180\157\229\157\166\230\185\150"] = {
      x = 420869,
      y = 625410,
      z = 574
    },
    ["\229\149\134\229\186\151\232\161\151"] = {
      x = 440399,
      y = 669799,
      z = 1231
    },
    ["\233\155\170\229\177\177"] = {
      x = 398280,
      y = 548388,
      z = 47701
    },
    ["\230\184\133\233\163\142\229\177\177"] = {
      x = 391032,
      y = 629461,
      z = 6088
    },
    ["\229\189\188\229\190\151\229\164\167\233\129\147"] = {
      x = 563911,
      y = 681997,
      z = 3199
    },
    ["\230\156\136\231\137\153\233\149\135"] = {
      x = 401068,
      y = 651779,
      z = 1698
    },
    ["\233\173\148\230\179\149\229\184\136\228\185\139\229\174\182"] = {
      x = 435471,
      y = 690837,
      z = 2393
    },
    ["\233\173\148\229\138\155\231\140\171"] = {
      x = 438521,
      y = 643555,
      z = 824
    }
  }
  self.BattleTypeName = {
    "1v1",
    "2v2",
    "\233\166\150\233\162\134\230\136\152",
    "\229\155\162\228\189\147\230\136\152",
    "A1\230\156\128\231\187\136\230\136\1521",
    "A1\230\156\128\231\187\136\230\136\1522"
  }
  self.BattleTypeNameMap = {
    ["1v1"] = "1v1",
    ["2v2"] = "2v2",
    BossFight = "\233\166\150\233\162\134\230\136\152",
    TeamFight = "\229\155\162\228\189\147\230\136\152",
    A1FinalBattle1 = "A1\230\156\128\231\187\136\230\136\1521",
    A1FinalBattle2 = "A1\230\156\128\231\187\136\230\136\1522"
  }
  self.BattleType = {}
  for i, v in ipairs(self.BattleTypeName) do
    self.BattleType[v] = i
  end
end

function BattleDebugControl:CollectSkillData()
  local AllSkill = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SKILL_CONF):GetAllDatas()
  for _, v in pairs(AllSkill) do
    if v.res_id then
      local skillType = ""
      if v.skill_result and #v.skill_result > 0 then
        for i, result in ipairs(v.skill_result) do
          local EffectConf = _G.DataConfigManager:GetEffectConf(result.effect_id, true)
          if EffectConf and EffectConf.effect_order == Enum.EffectType.ET_COUNTER then
            skillType = self:SkillTypeTostring(v.Skill_Type)
          end
        end
      end
      local key = string.format("[%d]%s %s %s", v.id, v.name, string.lower(self:SplitFilename(v.res_id)), skillType)
      self.allSkillMap[key] = v.id
      tInsert(self.allSkillList, key)
    end
  end
  table.sort(self.allSkillList, function(a, b)
    return a < b
  end)
end

function BattleDebugControl:SkillTypeTostring(Skill_Type)
  if Skill_Type == Enum.SkillType.ST_DAMAGE then
    return "ST_DAMAGE"
  elseif Skill_Type == Enum.SkillType.ST_STATUS then
    return "ST_STATUS"
  elseif Skill_Type == Enum.SkillType.ST_DEFEND then
    return "ST_DEFEND"
  end
  return "ST_NONE"
end

function BattleDebugControl:GetSkillCountTypeTostring(Skill_Type)
  if Skill_Type == Enum.SkillType.ST_DAMAGE then
    return Enum.SkillType.ST_DEFEND
  elseif Skill_Type == Enum.SkillType.ST_STATUS then
    return Enum.SkillType.ST_DAMAGE
  elseif Skill_Type == Enum.SkillType.ST_DEFEND then
    return Enum.SkillType.ST_STATUS
  end
  return Enum.SkillType.ST_NONE
end

function BattleDebugControl:CollectPetData()
  local AllPet = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_CONF):GetAllDatas()
  for _, v in pairs(AllPet) do
    local PetBase = _G.DataConfigManager:GetPetbaseConf(v.base_id, true)
    local Model = PetBase and _G.DataConfigManager:GetModelConf(PetBase.model_conf, true)
    if Model and not string.IsNilOrEmpty(Model.path) then
      local key = string.format("[%d]%s %s", v.id, v.name, string.lower(self:SplitFilename(Model.path)))
      self.allPetMap[key] = v.id
      tInsert(self.allPetList, key)
    end
  end
  table.sort(self.allPetList, function(a, b)
    return a < b
  end)
end

function BattleDebugControl:CollectMonsterData()
  local AllPet = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MONSTER_CONF):GetAllDatas()
  for _, v in pairs(AllPet) do
    local PetBase
    if 0 == v.base_id then
      PetBase = _G.DataConfigManager:GetPetbaseConf(v.base_id, true)
    elseif v.petbase_find_enum == Enum.PetbaseFindType.PFT_SPECIFIC_PETBASE_ID then
      PetBase = _G.DataConfigManager:GetPetbaseConf(v.find_param[1], true)
    end
    local Model = PetBase and _G.DataConfigManager:GetModelConf(PetBase.model_conf, true)
    if Model and not string.IsNilOrEmpty(Model.path) then
      local key = string.format("[%d]%s %s", v.id, v.name, string.lower(self:SplitFilename(Model.path)))
      self.allMonsterMap[key] = v.id
      tInsert(self.allMonsterList, key)
    end
  end
  table.sort(self.allMonsterList, function(a, b)
    return a < b
  end)
end

function BattleDebugControl:SplitFilename(filePath)
  local short_res = filePath
  local str_array = short_res:split("/")
  short_res = str_array[#str_array]
  str_array = short_res:split("%.")
  return str_array[1]
end

function BattleDebugControl:CollectPlayerSkillData()
  tInsert(self.allPlayerSkillList, "None")
  local allSkills = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SKILL_CONF):GetAllDatas()
  local playerSkillResMap = {}
  for _, v in pairs(allSkills) do
    if v.type == Enum.SkillActiveType.SAT_PLAYERSKILL and not string.IsNilOrEmpty(v.res_id) and not playerSkillResMap[v.res_id] then
      local key = string.format("[%d]%s %s", v.id, v.name, string.lower(self:SplitFilename(v.res_id)))
      self.allPlayerSkillMap[key] = v.id
      tInsert(self.allPlayerSkillList, key)
      playerSkillResMap[v.res_id] = 1
    end
  end
  table.sort(self.allPlayerSkillList, function(a, b)
    return a < b
  end)
  local allItems = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BAG_ITEM_CONF):GetAllDatas()
  for _, v in pairs(allItems) do
    if v.type == Enum.BagItemType.BI_PET_BALL then
      local key = string.format("[%d]%s", v.id, v.name)
      self.allPetBallMap[key] = v.id
      tInsert(self.allPetBallList, key)
    end
  end
  table.sort(self.allPetBallList, function(a, b)
    return a < b
  end)
end

function BattleDebugControl:CollectNPCData()
  tInsert(self.allNPCList, "None")
  local allNPCs = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.NPC_CONF):GetAllDatas()
  for _, v in pairs(allNPCs) do
    local model = _G.DataConfigManager:GetModelConf(v.model_conf, true)
    if model and not string.IsNilOrEmpty(model.path) and string.find(model.path, "BP/Battle") then
      local key = string.format("[%d]%s %s", v.id, v.name, self:SplitFilename(model.path))
      self.allNPCMap[key] = v.id
      tInsert(self.allNPCList, key)
    end
  end
  table.sort(self.allNPCList, function(a, b)
    return a < b
  end)
end

function BattleDebugControl:CollectWeatherData()
  local allWeathers = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.WEATHER_CONF):GetAllDatas()
  for _, v in pairs(allWeathers) do
    local key = string.format("[%d] %s", v.id, v.name)
    self.allWeatherMap[key] = v.weather_type
    tInsert(self.allWeatherList, key)
  end
  table.sort(self.allWeatherList, function(a, b)
    return a < b
  end)
end

function BattleDebugControl:Dctor()
  self:Reset()
  _G.BattleEventCenter:UnBind(self)
  NRCEventCenter:UnRegisterEvent(self, BattleEvent.ExitBattle, self.OnExitBattleEvent)
  NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnSceneLoaded)
end

function BattleDebugControl:Reset()
  self.allSkillMap = {}
  self.allSkillList = {}
  self.allPetMap = {}
  self.allPetList = {}
  self.allMonsterMap = {}
  self.allMonsterList = {}
  self.allPlayerSkillMap = {}
  self.allPlayerSkillList = {}
  self.allPetBallMap = {}
  self.allPetBallList = {}
  self.allNPCMap = {}
  self.allNPCList = {}
  self.allWeatherMap = {}
  self.allWeatherList = {}
  self.tempMap = {}
  self.tempList = {}
  self.battleManager = nil
  self.pawnManager = nil
  self.enterBattleState = EnterBattleState.WaitStart
end

function BattleDebugControl:OnBattleEvent(eventName, ...)
  if not self.isInBattleTest then
    return
  end
  if self.isInAutoTest then
    return
  end
  if self.isInAutoPlaySkill then
    return
  end
  if eventName == BattleEvent.ROUND_SELECT_START then
    if _G.AppMain:HasDebug() then
      NRCModuleManager:DoCmd(_G.DebugModuleCmd.OpenRuntimeDebugSkill)
    end
    self:HideBattleUI()
  elseif eventName == BattleEvent.PrepareBattleOver then
    self:OnPrepareBattleOver()
  end
end

function BattleDebugControl:OnPrepareBattleOver()
  self:ShowOrHideAllScreenInfo()
  self:HideBattleUI()
  if _G.AppMain:HasDebug() then
    NRCModuleManager:DoCmd(_G.DebugModuleCmd.OpenRuntimeDebugSkill)
  end
end

function BattleDebugControl:HideBattleUI()
  if self.cacheBattleParams.isShowHP then
    NRCModeManager:DoCmd(BattleUIModuleCmd.MainHideAll, true)
    local mainWindow = BattleUtils.GetMainWindow()
    if mainWindow then
      mainWindow:ChangeBattleOperateEnable(false)
    end
  else
    NRCModeManager:DoCmd(BattleUIModuleCmd.BattleMainSetOpacity, 0)
  end
end

function BattleDebugControl:OnExitBattleEvent()
  self:ShowOrHideAllScreenInfo()
  self.cacheBattleParams = nil
  self.cacheRoundParams = nil
  self.isInBattleTest = false
  if self.cacheBattleParamsToSave then
    JsonUtils.DumpSaved("BattleDebugParam" .. os.date("%Y-%m-%d_%H_%M_%S", os.time()), self.cacheBattleParamsToSave)
  end
  _G.BattleManager.battleRuntimeData.battleDebugControl = nil
end

function BattleDebugControl:GetAllPetList()
  return self.allPetList
end

function BattleDebugControl:GetPetIdByKey(key)
  return self.allPetMap[key]
end

function BattleDebugControl:GetAllMonsterList()
  return self.allMonsterList
end

function BattleDebugControl:GetMonsterIdByKey(key)
  return self.allMonsterMap[key]
end

function BattleDebugControl:GetInBattlePetList(teamEnum, isCaster)
  if not self.battleManager.isInBattle then
    return {}
  end
  local player = self.pawnManager:GetPlayerMyTeam()
  if teamEnum == BattleEnum.Team.ENUM_ENEMY then
    player = self.pawnManager:GetPlayerEnemyTeam()
  end
  local petMap = {}
  if player then
    for i, v in ipairs(player.deck.cards) do
      if isCaster then
        if v:IsInBattle() or not v:IsBeCatch() and v:IsAlive() then
          local key = string.format("[%d]%s", v.config.id, v.name)
          petMap[key] = v
        end
      elseif v:IsInBattle() then
        local key = string.format("[%d]%s", v.config.id, v.name)
        petMap[key] = v
      end
    end
  end
  return petMap
end

function BattleDebugControl:GetAllSkillList()
  return self.allSkillList
end

function BattleDebugControl:GetSkillIdByKey(key)
  return self.allSkillMap[key]
end

function BattleDebugControl:GetAllPlayerSkillList()
  return self.allPlayerSkillList
end

function BattleDebugControl:GetPlayerSkillIdByKey(key)
  return self.allPlayerSkillMap[key]
end

function BattleDebugControl:GetAllPetBallList()
  return self.allPetBallList
end

function BattleDebugControl:GetPetBallIdByKey(key)
  return self.allPetBallMap[key]
end

function BattleDebugControl:GetAllNpcList()
  return self.allNPCList
end

function BattleDebugControl:GetNpcIdByKey(key)
  return self.allNPCMap[key]
end

function BattleDebugControl:GetAllWeatherList()
  return self.allWeatherList
end

function BattleDebugControl:GetWeatherByKey(key)
  return self.allWeatherMap[key]
end

function BattleDebugControl:GetBattlePetCount()
  local battleType = self.cacheBattleParams.battleType or 1
  if battleType == self:GetBattleType("1v1") or battleType == self:GetBattleType("BossFight") or battleType == self:GetBattleType("A1FinalBattle2") then
    return 1
  elseif battleType == self:GetBattleType("2v2") then
    return 2
  elseif battleType == self:GetBattleType("TeamFight") then
    return 4
  elseif battleType == self:GetBattleType("A1FinalBattle1") then
    return 3
  end
end

function BattleDebugControl:GetEnemyBattlePetCount()
  local battleType = self.cacheBattleParams.battleType or 1
  if battleType == self:GetBattleType("2v2") then
    return 2
  else
    return 1
  end
end

function BattleDebugControl:GetBattleType(typeName)
  local cnName = self.BattleTypeNameMap[typeName]
  return self.BattleType[cnName]
end

function BattleDebugControl:EnterDebugBattle(RuntimeBattleDebugParam)
  self.cacheBattleParams = RuntimeBattleDebugParam
  self:TeleportToBattlePos()
end

function BattleDebugControl:TeleportToBattlePos()
  self.enterBattleState = EnterBattleState.TeleportToBattleCenter
  if self.cacheBattleParams.DungeonId and self.cacheBattleParams.DungeonId > 0 then
    local dungeonConf = _G.DataConfigManager:GetDungeonConf(self.cacheBattleParams.DungeonId)
    if dungeonConf then
      if dungeonConf.scene_id == SceneUtils.GetSceneID() then
        self:OnSceneLoaded()
        return
      end
      local open_dungeon_req = ProtoMessage.newZoneGmOpenDungeonReq()
      open_dungeon_req.dungeon_cfg_id = dungeonConf.id
      Log.Warning("GM Open Dungeon:", open_dungeon_req.dungeon_cfg_id, dungeonConf.name)
      ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_GM_OPEN_DUNGEON_REQ, open_dungeon_req, self, self.OnTeleportRsp, true)
      return
    end
  end
  local battlePos = self.cacheBattleParams.battlePos
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerLocation = player.viewObj:Abs_K2_GetActorLocation()
  if self:GetPositionSize(battlePos.x - playerLocation.X, battlePos.y - playerLocation.Y, battlePos.z - playerLocation.Z) < 9999 then
    self:OnSceneLoaded()
    return
  end
  Log.Debug("BattleDebugControl:TeleportToBattlePos curPos ", playerLocation, battlePos.x, battlePos.y, battlePos.z)
  local _DCM = DataConfigManager
  local teleReq = ProtoMessage.newZoneSceneGmTeleportReq()
  local bornSceneCfgId = _DCM:GetGlobalConfigByKeyType("novice_pt", _DCM.ConfigTableId.ROLE_GLOBAL_CONFIG).num
  if SceneUtils.GetSceneID() ~= bornSceneCfgId then
    teleReq.to_scene_cfg_id = bornSceneCfgId
  else
    teleReq.to_scene_cfg_id = SceneUtils.GetSceneID()
  end
  teleReq.to_point.pos = battlePos
  teleReq.to_point.dir.x = 0
  teleReq.to_point.dir.y = 0
  teleReq.to_point.dir.z = 174
  ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_SCENE_GM_TELEPORT_REQ, teleReq, self, self.OnTeleportRsp, true, true)
end

function BattleDebugControl:GetPositionSize(x, y, z)
  return x * x + y * y + z * z
end

function BattleDebugControl:OnTeleportRsp(retInfo)
end

function BattleDebugControl:OnSceneLoaded()
  if self.enterBattleState ~= EnterBattleState.TeleportToBattleCenter then
    return
  end
  self.delayId = DelayManager:DelaySeconds(1, function()
    self:SetPlayerSex()
  end)
end

function BattleDebugControl:SetPlayerSex()
  self.enterBattleState = EnterBattleState.SetPlayerSex
  local targetGender = self.cacheBattleParams.player_team.playerSex and 1 or 2
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if targetGender == player.gender then
    self:SetRoleMagicLevel()
    return
  end
  local gender = 1
  if 1 == player.gender then
    gender = 2
  end
  GlobalConfig.ForceLocalMode = true
  player:SetCharacterGender(gender)
  GlobalConfig.ForceLocalMode = false
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
  self.delayId = DelayManager:DelaySeconds(1, function()
    self:SetRoleMagicLevel()
  end)
end

function BattleDebugControl:SetRoleMagicLevel()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
  local Req = ProtoMessage:newZoneGmSetPlayerLevelReq()
  Req.uin = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.uin
  Req.level = 40
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_GM_SET_PLAYER_LEVEL_REQ, Req, self, self.SetPlayWorldLevel)
end

function BattleDebugControl:SetPlayWorldLevel()
  local Req = ProtoMessage:newZoneGmSetPlayerWorldLevelReq()
  Req.uin = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.uin
  Req.world_level = 10
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_GM_SET_PLAYER_WORLD_LEVEL_REQ, Req, self, self.SetPetTeams)
end

function BattleDebugControl:SetPetTeams()
  self.enterBattleState = EnterBattleState.AddPetTeams
  self.curAddCount = 0
  for i = 1, TeamPetCount do
    local petKey = self.cacheBattleParams.player_team["pet" .. i] or ""
    local petConfId = self.allPetMap[petKey]
    if petConfId and not self:GetPetGuidByConfId(petConfId) then
      self:OperatePetReq(petConfId)
    else
      self:OnOperatePetRsp({})
    end
  end
end

function BattleDebugControl:GetPetGuidByConfId(petConfId)
  local battlePetDatas = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if battlePetDatas then
    for i, data in ipairs(battlePetDatas) do
      if data.conf_id == petConfId then
        return data.gid
      end
    end
  end
  local backpackPetDatas = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackPetInfo()
  if backpackPetDatas then
    for i, data in ipairs(backpackPetDatas) do
      if data.conf_id == petConfId then
        return data.gid
      end
    end
  end
  return nil
end

function BattleDebugControl:GetPetGuidListByConfId(petConfId)
  local petGuidList = {}
  local battlePetDatas = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if battlePetDatas then
    for i, data in ipairs(battlePetDatas) do
      if data.conf_id == petConfId then
        table.insert(petGuidList, data.gid)
      end
    end
  end
  local backpackPetDatas = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackPetInfo()
  if backpackPetDatas then
    for i, data in ipairs(backpackPetDatas) do
      if data.conf_id == petConfId then
        table.insert(petGuidList, data.gid)
      end
    end
  end
  return petGuidList
end

function BattleDebugControl:OperatePetReq(petId)
  local opItemReq = ProtoMessage.newZoneGmOperateItemReq()
  opItemReq.op_type = ProtoEnum.OpType.OT_ADD
  opItemReq.item_type = ProtoEnum.GoodsType.GT_PET
  opItemReq.item_id = petId
  opItemReq.item_num = 1
  ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_GM_OPERATE_ITEM_REQ, opItemReq, self, self.OnOperatePetRsp)
end

function BattleDebugControl:OnOperatePetRsp(retInfo)
  Log.Dump(retInfo, 6, "BattleDebugControl:OnOperatePetRsp")
  self.curAddCount = self.curAddCount + 1
  if self.curAddCount >= TeamPetCount then
    self.curAddCount = 0
    self.enterBattleState = EnterBattleState.SetPetTeams
    self:ReqSetTeamPet()
  end
end

function BattleDebugControl:ReqSetTeamPet()
  local req = _G.ProtoMessage:newZonePetTeamChangeReq()
  req.team_type = _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD
  table.insert(req.team_idxs, 0)
  local selectTeam = _G.ProtoMessage:newPetTeam()
  local inBattleTeam = self.cacheBattleParams.player_team
  for i = 1, 6 do
    local petConfId = self.allPetMap[inBattleTeam["pet" .. i]]
    local petGid = self:GetPetGuidByConfId(petConfId)
    if petGid then
      local teamPetInfo = _G.ProtoMessage:newPetTeam_PetInfo()
      teamPetInfo.pet_gid = petGid
      teamPetInfo.equip_infos = {}
      table.insert(selectTeam.pet_infos, teamPetInfo)
    end
  end
  selectTeam.team_name = "\232\135\170\229\138\168\229\140\150\230\181\139\232\175\149"
  table.insert(req.teams, selectTeam)
  Log.Dump(req, 6, "BattleDebugControl:newZonePetTeamChangeReq")
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TEAM_CHANGE_REQ, req, self, self.OnOperatePetTeamRsp)
end

function BattleDebugControl:OnOperatePetTeamRsp(retInfo)
  Log.Dump(retInfo, 10, "BattleDebugControl:OnOperatePetTeamRsp")
  self:InternalEnterBattle()
end

function BattleDebugControl:InternalEnterBattle()
  local battleType = self.cacheBattleParams.battleType
  self.enterBattleState = EnterBattleState.WaitEnterBattle
  local battleID = 5
  if 1 == battleType then
  elseif battleType == self:GetBattleType("2v2") then
    battleID = 6
  elseif battleType == self:GetBattleType("BossFight") then
    battleID = 304023
  elseif battleType == self:GetBattleType("TeamFight") then
    battleID = 1010
  elseif battleType == self:GetBattleType("A1FinalBattle1") then
    battleID = 399501
  elseif battleType == self:GetBattleType("A1FinalBattle2") then
    battleID = 399502
  end
  local req = ProtoMessage:newZoneGmCreateBattleReq()
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local PlayerLocation = player.viewObj:Abs_K2_GetActorLocation()
  PlayerLocation.Z = PlayerLocation.Z - player:GetHalfHeight()
  req.avatar_pt.pos.x = math.floor(PlayerLocation.X)
  req.avatar_pt.pos.y = math.floor(PlayerLocation.Y)
  req.avatar_pt.pos.z = math.floor(PlayerLocation.Z)
  req.npc_pt.pos.x = math.floor(PlayerLocation.X)
  req.npc_pt.pos.y = math.floor(PlayerLocation.Y)
  req.npc_pt.pos.z = math.floor(PlayerLocation.Z)
  req.battle_conf_id = battleID
  req.npc_level = 99
  req.disable_anti_cheat = true
  req.skill_tool_mode = true
  if 1 == battleType then
    local battleNpc = ProtoMessage:newGmBattleNpc()
    battleNpc.npc_cfg_id = self:GetNpcIdByKey(self.cacheBattleParams.enemy_team.npcName) or 17015
    for i = 1, TeamPetCount do
      local petKey = self.cacheBattleParams.enemy_team["pet" .. i]
      if not string.IsNilOrEmpty(petKey) and self.allMonsterMap[petKey] then
        tInsert(battleNpc.monster_ids, self.allMonsterMap[petKey])
      end
    end
    tInsert(req.dynamic_npcs, battleNpc)
  end
  self.isInBattleTest = true
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_GM_CREATE_BATTLE_REQ, req, self, self.OnEnterBattleRsp)
end

function BattleDebugControl:OnEnterBattleRsp(rsp)
  self.enterBattleState = EnterBattleState.Finish
end

function BattleDebugControl:ShowOrHideAllScreenInfo()
  local updateUIModule = _G.NRCModuleManager:GetModule("UpdateUIModule")
  local debugModule = _G.NRCModuleManager:GetModule("DebugModule")
  local Account = updateUIModule and updateUIModule:GetPanel("AccountInfo")
  local TimeText = debugModule:GetPanel("DebugEntry")
  if Account then
    if 1 ~= Account:GetRenderOpacity() then
      Account:SetRenderOpacity(1)
      TimeText.TimeText:SetRenderOpacity(1)
    else
      Account:SetRenderOpacity(0)
      TimeText.TimeText:SetRenderOpacity(0)
    end
  end
end

function BattleDebugControl:ZoneSceneGmReq(gm_type, gm_op_type, value)
  local req = _G.ProtoMessage:newZoneSceneGmReq()
  req.gm_type = gm_type
  req.gm_op_type = gm_op_type
  req.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  req.param1 = value
  _G.ZoneServer:Send(_G.ProtoEnum.ZoneSvrGmCmd.ZONE_SCENE_GM_REQ, req)
end

function BattleDebugControl:RoundStart(runtimeBattleDebugRoundParam)
  if not runtimeBattleDebugRoundParam then
    return
  end
  if not self.cacheBattleParamsToSave then
    self.cacheBattleParamsToSave = {}
  end
  Log.Dump(runtimeBattleDebugRoundParam, 5, "BattleDebugControl:RoundStart ")
  table.insert(self.cacheBattleParamsToSave, runtimeBattleDebugRoundParam)
  self.cacheRoundParams = runtimeBattleDebugRoundParam
  self:HandleRoundMagic()
end

function BattleDebugControl:HandleRoundMagic()
  self.curCompleteMagicCount = 0
  if 0 == #self.cacheRoundParams.playerMagicCMDs then
    self:OnUseMagicEnd()
    return
  end
  self:SendMagicReq()
end

function BattleDebugControl:SendMagicReq()
  self.curCompleteMagicCount = self.curCompleteMagicCount + 1
  if self.curCompleteMagicCount > #self.cacheRoundParams.playerMagicCMDs then
    self.magicDelay = DelayManager:DelayFrames(3, function()
      self:OnUseMagicEnd()
    end)
    self.curCompleteMagicCount = 0
    return
  end
  local playerMagicInfo = self.cacheRoundParams.playerMagicCMDs[self.curCompleteMagicCount]
  local req = ProtoMessage:newZoneBattleGmReq()
  req.gm_type = ProtoEnum.ZoneBattleGmReq.BATTLE_GM_TYPE.B_GM_TYPE_SKILL
  req.gm_op_type = 3
  req.side = playerMagicInfo.team == BattleEnum.Team.ENUM_ENEMY and 1 or 0
  req.pos = 1
  req.uin = self.pawnManager:GetPlayerMyTeam().guid
  if playerMagicInfo.team == BattleEnum.Team.ENUM_ENEMY then
    req.uin = self.pawnManager:GetPlayerEnemyTeam().guid
  end
  req.param1 = req.uin
  req.param2 = playerMagicInfo.magicId
  req.param3 = playerMagicInfo.target_pet_id
  Log.Dump(req, 3, "BattleDebugControl:SendMagicReq")
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_BATTLE_GM_REQ, req, self, self.OnUseMagicRsp, false, false)
end

function BattleDebugControl:OnUseMagicRsp(retInfo)
  Log.Dump(retInfo, 3, "BattleDebugControl:OnUseMagicRsp")
  self:SendMagicReq()
end

function BattleDebugControl:OnUseMagicEnd()
  if self.magicDelay then
    _G.DelayManager:CancelDelayById(self.magicDelay)
    self.magicDelay = nil
  end
  self.curSkillIdx = 0
  self:HandleEnemySkill()
end

function BattleDebugControl:HandleEnemySkill()
  self.curSkillIdx = self.curSkillIdx + 1
  local cmd = self.cacheRoundParams.enemyCMDs[self.curSkillIdx]
  if cmd then
    cmd = cmd[1]
    local battlePet = self.pawnManager:GetPetByPos(cmd.team, cmd.pos)
    local playerId = self.pawnManager:GetPlayerEnemyTeam().guid
    if battlePet and battlePet.guid ~= cmd.petGuid then
      self:HandleChangePet(cmd.petGuid, playerId, cmd.team, battlePet.card.posInField, self.OnEnemySkillRsp)
    else
      self:SendPlaySkillReq(cmd, playerId, self.OnEnemySkillRsp)
    end
  elseif self.cacheBattleParams.battleType == self:GetBattleType("BossFight") then
    self:HandleComboSkill()
  elseif self.cacheRoundParams.playerCatchCMD then
    self:HandleRoundCatch()
  else
    self.curSkillIdx = 0
    self:HandleTeamSkill()
  end
end

function BattleDebugControl:OnEnemySkillRsp(rsp)
  Log.Dump(rsp, 3, "BattleDebugControl:OnEnemySkillRsp")
  self:HandleEnemySkill()
end

function BattleDebugControl:HandleComboSkill()
  local req = ProtoMessage:newZoneBattleGmReq()
  req.gm_type = ProtoEnum.ZoneBattleGmReq.BATTLE_GM_TYPE.B_GM_TYPE_COMBO
  req.gm_op_type = 1
  req.side = 0
  req.pos = 1
  req.uin = self.pawnManager:GetPlayerMyTeam().guid
  local cmds = self.cacheRoundParams.teamCMDs[1]
  for i = 1, #cmds do
    req["param" .. i] = cmds[i].skillId or 0
  end
  req.param6 = 1
  Log.Dump(req, 3, "BattleDebugControl:HandleComboSkill")
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_BATTLE_GM_REQ, req, self, self.OnComboSkillRsp, false, false)
end

function BattleDebugControl:OnComboSkillRsp(retInfo)
  self.curSkillIdx = 0
  self:HandleTeamSkill()
end

function BattleDebugControl:HandleRoundCatch()
  local catchCmd = self.cacheRoundParams.playerCatchCMD
  local req = ProtoMessage:newZoneBattleGmReq()
  req.gm_type = ProtoEnum.ZoneBattleGmReq.BATTLE_GM_TYPE.B_GM_TYPE_SKILL
  req.gm_op_type = 4
  req.side = 0
  req.pos = 1
  req.uin = self.pawnManager:GetPlayerMyTeam().guid
  local battlePet = self.pawnManager:GetFirstPet(BattleEnum.Team.ENUM_ENEMY)
  req.param1 = catchCmd.ballItemId
  req.param2 = battlePet.guid
  req.param3 = catchCmd.isSucceed and 9999 or 0
  req.param4 = catchCmd.isCrit and 1 or 0
  Log.Dump(req, 4, "BattleDebugControl:HandleRoundCatch")
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_BATTLE_GM_REQ, req, self, self.OnCatchRsp, false, false)
end

function BattleDebugControl:OnCatchRsp(retInfo)
  self.curSkillIdx = 0
  self:HandleTeamSkill()
end

function BattleDebugControl:HandleTeamSkill()
  self.curSkillIdx = self.curSkillIdx + 1
  local cmd = self.cacheRoundParams.teamCMDs[self.curSkillIdx]
  if cmd then
    cmd = cmd[1]
    local battlePet = self.pawnManager:GetPetByPos(cmd.team, cmd.pos)
    local playerId = self.pawnManager:GetPlayerMyTeam().guid
    if battlePet and battlePet.guid ~= cmd.petGuid then
      self:HandleChangePet(cmd.petGuid, playerId, cmd.team, battlePet.card.posInField, self.OnTeamSkillRsp)
    else
      local isFinal = self.curSkillIdx == #self.cacheRoundParams.teamCMDs and 1 or 0
      self:SendPlaySkillReq(cmd, playerId, self.OnTeamSkillRsp, isFinal)
    end
  end
end

function BattleDebugControl:OnTeamSkillRsp(rsp)
  Log.Dump(rsp, 3, "BattleDebugControl:OnTeamSkillRsp")
  self:HandleTeamSkill()
end

function BattleDebugControl:HandleChangePet(battlePetGUId, playerGuid, team, pos, callBack)
  local req = ProtoMessage:newZoneBattleGmReq()
  req.gm_type = ProtoEnum.ZoneBattleGmReq.BATTLE_GM_TYPE.B_GM_TYPE_SKILL
  req.gm_op_type = 5
  req.side = team == BattleEnum.Team.ENUM_ENEMY and 1 or 0
  req.pos = pos
  req.uin = playerGuid
  req.param1 = battlePetGUId
  Log.Dump(req, 4, "BattleDebugControl:HandleChangePet")
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_BATTLE_GM_REQ, req, self, callBack, false, false)
end

function BattleDebugControl:SendPlaySkillReq(skillInfo, playerGuid, callBack, isFinalSkill)
  local damageAmount = skillInfo.damageAmount ~= nil and skillInfo.damageAmount or 1
  local req = ProtoMessage:newZoneBattleGmReq()
  req.gm_type = ProtoEnum.ZoneBattleGmReq.BATTLE_GM_TYPE.B_GM_TYPE_SKILL
  req.gm_op_type = 2
  req.side = skillInfo.team == BattleEnum.Team.ENUM_ENEMY and 1 or 0
  req.pos = skillInfo.pos
  req.uin = playerGuid
  req.param1 = skillInfo.skillId
  req.param2 = skillInfo.skillTargetId
  req.param3 = 999 - skillInfo.playOrder * 100
  req.param4 = skillInfo.isKill and 9999999 or damageAmount
  req.param5 = skillInfo.attackCount or 0
  req.param6 = isFinalSkill or 0
  Log.Dump(req, 3, "BattleDebugControl:SendPlaySkillReq")
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_BATTLE_GM_REQ, req, self, callBack, false, false)
end

function BattleDebugControl:CheckCanAutoSupplyPet()
  local canSummer = {}
  local deadPet = {}
  local ridOfPet = {}
  local player = self.battleManager.battlePawnManager.TeamatePlayer
  for k, pet in pairs(player.deck.cards) do
    if pet:IsInBattle() then
      if pet:IsBeRidOf() then
        tInsert(ridOfPet, pet.posInField)
      elseif not pet:IsAlive() or pet:IsBeCatch() then
        tInsert(deadPet, pet.posInField)
      end
    elseif pet:CanSummon() then
      tInsert(canSummer, pet.guid)
    end
  end
  if 0 == #canSummer or 0 == #ridOfPet and 0 == #deadPet then
    return false
  end
  return true
end

function BattleDebugControl:NeedAutoSupplyPet()
  if not self.isInBattleTest then
    return false
  end
  local canSummer = {}
  local deadPet = {}
  local ridOfPet = {}
  local player = self.battleManager.battlePawnManager.TeamatePlayer
  for k, pet in pairs(player.deck.cards) do
    if pet:IsInBattle() then
      if pet:IsBeRidOf() then
        tInsert(ridOfPet, pet.posInField)
      elseif not pet:IsAlive() or pet:IsBeCatch() then
        tInsert(deadPet, pet.posInField)
      end
    elseif pet:CanSummon() then
      tInsert(canSummer, pet.guid)
    end
  end
  if 0 == #canSummer or 0 == #ridOfPet and 0 == #deadPet then
    return false
  end
  local supplyGid = canSummer[1]
  local supplyPos = 1
  if #ridOfPet > 0 then
    supplyPos = ridOfPet[1]
  elseif #deadPet then
    supplyPos = deadPet[1]
  end
  local req = ProtoMessage:newZoneBattleGmReq()
  req.gm_type = ProtoEnum.ZoneBattleGmReq.BATTLE_GM_TYPE.B_GM_TYPE_SKILL
  req.gm_op_type = 5
  req.side = 0
  req.pos = supplyPos
  req.uin = player.guid
  req.param1 = supplyGid
  Log.Dump(req, 4, "BattleDebugControl:AutoSupplyPet")
  _G.ZoneServer:Send(ProtoCMD.ZoneSvrGmCmd.ZONE_BATTLE_GM_REQ, req)
  return true
end

local BattleDebugParam = {
  name = "DefaultTemp",
  battleType = 1,
  battlePosTempName = "\232\191\155\233\153\132\232\191\145\230\136\152\230\150\151",
  battlePos = {
    x = 440399,
    y = 669799,
    z = 1331
  },
  isShowHP = false,
  player_team = {
    playerSex = 1,
    pet1 = "[14000152]\230\152\165\229\155\162 BP_Gra_YuTu1_001",
    pet2 = "[3075002]\231\129\181\231\139\144 BP_Fir_LingHu1_001",
    pet3 = "[14000087]\231\129\171\229\176\190\230\136\152\229\163\171 BP_Fir_WaTe2_001",
    pet4 = "[14000403]\229\134\176\233\146\187\229\184\131\233\178\129\230\150\175 BP_Ice_BuLuSi3_001",
    pet5 = "[14000015]\231\189\151\233\154\144 BP_Roc_Amiyate3_001",
    pet6 = "[3097001]\231\129\181\232\148\147\232\141\137\231\142\139 BP_Gra_CaoWang3_001"
  },
  enemy_team = {
    npcName = "[17015]\232\183\175\230\152\147\230\150\175 BP_Battle_NPC_01101",
    pet1 = "[410157]\230\152\165\229\155\162 BP_Gra_YuTu1_001",
    pet2 = "[410071]\231\129\181\231\139\144 BP_Fir_LingHu1_001",
    pet3 = "[1606]\231\129\171\229\176\190\230\136\152\229\163\171 BP_Fir_WaTe2_001",
    pet4 = "[410255]\229\134\176\233\146\187\229\184\131\233\178\129\230\150\175 BP_Ice_BuLuSi3_001",
    pet5 = "[410016]\231\189\151\233\154\144 BP_Roc_Amiyate3_001",
    pet6 = "[410064]\231\129\181\232\148\147\232\141\137\231\142\139 BP_Gra_CaoWang3_001"
  }
}

function BattleDebugControl:SetTestData()
  self.cacheBattleParams = self.cacheBattleParams or BattleDebugParam
end

function BattleDebugControl:GetTestData()
  return BattleDebugParam
end

function BattleDebugControl:CollectBattleTemp()
  local temps = JsonUtils.LoadAllDebugBattleTemp("BattleDebug/")
  for i, v in pairs(temps) do
    local key = v.name or v.battlePosTempName
    self.tempMap[key] = v
    tInsert(self.tempList, key)
  end
end

function BattleDebugControl:GetTempList()
  return self.tempList
end

function BattleDebugControl:GetTempByTempName(tempName)
  local temp = self.tempMap[tempName]
  self.cacheBattleParams = temp
  return temp
end

function BattleDebugControl:SaveTemplate(templateName, debugCfg)
  if not self.tempMap[templateName] then
    self.tempMap[templateName] = debugCfg
    tInsert(self.tempList, templateName)
  end
  JsonUtils.DumpSaved("BattleDebug/" .. templateName, debugCfg)
end

return BattleDebugControl
