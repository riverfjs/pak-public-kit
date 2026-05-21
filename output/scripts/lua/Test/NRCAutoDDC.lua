local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
NRCAutoDDC = {}
local StartPos = UE4.FVector(332800, 486400, 50000)
local EndPos = UE4.FVector(691200, 742400, 50000)
local StartRunPos = UE4.FVector(StartPos.X, StartPos.Y, StartPos.Z)
local TempPos = UE4.FVector(StartPos.X, StartPos.Y, StartPos.Z)
local MoveSpeed = 5000
local ScanNPCNum = 15000
NRCAutoDDC.TaskList = {}

function NRCAutoDDC.AutoRun()
  UE.UNRCStatics.ExecConsoleCommand("s.AsyncLoadingTimeLimit 30", nil)
  UE.UNRCStatics.ExecConsoleCommand("s.MaxCallbackTimeCost 10", nil)
  local curLevelFullName = LevelHelper:GetLevelName(true)
  local nameTable = string.Split(curLevelFullName, "/")
  local levelName = nameTable[#nameTable]
  Log.Debug("NRCAutoDDC.AutoRun() Start", curLevelFullName, levelName)
  if "L_Bigworld_01_Release" == levelName then
    NRCAutoDDC.TaskList = {}
    table.insert(NRCAutoDDC.TaskList, NRCAutoDDC.AutoMoveAnywhere)
    table.insert(NRCAutoDDC.TaskList, NRCAutoDDC.ScanNPC)
    table.insert(NRCAutoDDC.TaskList, NRCAutoDDC.ScanNPCSkill)
    table.insert(NRCAutoDDC.TaskList, NRCAutoDDC.ScanLevel)
    NRCAutoDDC.DoNext()
  else
    NRCAutoDDC.End()
  end
end

function NRCAutoDDC.DoNext()
  if #NRCAutoDDC.TaskList > 0 then
    local task = NRCAutoDDC.TaskList[1]
    tcall(NRCAutoDDC, task)
    table.remove(NRCAutoDDC.TaskList, 1)
  else
    NRCAutoDDC.End()
  end
end

function NRCAutoDDC.LoadMap()
  NRCModeManager:ActiveMode("LocalMode")
  if _G.GlobalConfig.MemoryAutoTest then
    _G.LevelHelper:OpenLevel("/Game/ArtRes/Level/Game/BigWorld/L_Bigworld_01_Release/L_Bigworld_01_Release")
  else
    _G.NRCModeManager:DoCmd(SceneModuleCmd.EnterMap, 103)
  end
  _G.NRCModeManager:DoCmd(EnvSystemModuleCmd.ChangeTimeScale, 1)
end

function NRCAutoDDC.AutoMoveAnywhere(Caller, Callback)
  Log.Debug("NRCAutoDDC.AutoMoveAnywhere", StartPos.X, StartPos.Y, EndPos.X, EndPos.Y, MoveSpeed)
  NRCAutoDDC.AutoMoveAnywhereEnd()
  NRCAutoDDC.ScanNPCEnd()
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  StartRunPos = player:GetActorLocation()
  TempPos = UE4.FVector(StartPos.X, StartPos.Y, StartPos.Z)
  NRCAutoDDC.AutoMoveTimer = _G.TimerManager:CreateTimer(NRCAutoDDC, "AutoMoveTimer", 9999999, NRCAutoDDC.OnMoveNext, nil, 0.5)
end

function NRCAutoDDC.OnMoveNext()
  Log.Debug("NRCAutoDDC.OnMoveNext", TempPos.X, TempPos.Y, 50000)
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:SetActorLocation(TempPos)
  local Pos = SceneUtils.GetPosInLand(TempPos, 83, 90, 500000)
  if Pos then
    player:SetActorLocation(Pos)
    Log.Debug("NRCAutoDDC.OnMoveNext New Pos", Pos.X, Pos.Y, Pos.Z)
  end
  TempPos.Y = TempPos.Y + MoveSpeed
  if TempPos.Y > EndPos.Y or TempPos.Y < StartPos.Y then
    TempPos.X = TempPos.X + 10000
    MoveSpeed = MoveSpeed * -1
    if TempPos.X > EndPos.X then
      NRCAutoDDC.AutoMoveAnywhereEnd()
      NRCAutoDDC.DoNext()
    end
  end
end

function NRCAutoDDC.AutoMoveAnywhereEnd()
  if NRCAutoDDC.AutoMoveTimer then
    local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    player:SetActorLocation(StartRunPos)
    Log.Debug("NRCAutoDDC.OnMoveNext End", StartRunPos.X, StartRunPos.Y, StartRunPos.Z)
    NRCAutoDDC.AutoMoveTimer:Stop()
    NRCAutoDDC.AutoMoveTimer = nil
  end
end

function NRCAutoDDC.ScanNPC()
  Log.Debug("NRCAutoDDC.ScanNPC Start")
  NRCAutoDDC.AutoMoveAnywhereEnd()
  NRCAutoDDC.ScanNPCEnd()
  NRCAutoDDC.NpcIDs = {}
  NRCAutoDDC.Npcs = {}
  NRCAutoDDC.PosID = 1
  local Model_Path = {}
  local npcs = _G.DataConfigManager:GetAllByName("NPC_CONF")
  for k, v in pairs(npcs) do
    if #NRCAutoDDC.NpcIDs < ScanNPCNum then
      local NPC_CONF = v
      local model_Cfg_id = NPC_CONF.model_conf
      if model_Cfg_id and 0 ~= model_Cfg_id then
        local modelConf = _G.DataConfigManager:GetModelConf(model_Cfg_id)
        if modelConf then
          if Model_Path[modelConf.path] == nil then
            Model_Path[modelConf.path] = v
            table.insert(NRCAutoDDC.NpcIDs, k)
          end
        else
          Log.ErrorFormat("NPC\233\133\141\231\189\174\231\154\132ModelCfg\228\184\186\231\169\186 %d", model_Cfg_id)
        end
      end
    end
  end
  NRCAutoDDC.NPCCreateTimer = _G.TimerManager:CreateTimer(NRCAutoDDC, "NPCCreateTimer", 9999999, NRCAutoDDC.OnCreateNPC, nil, 0.2)
  Log.Debug("NRCAutoDDC.ScanNPC total ", #NRCAutoDDC.NpcIDs)
end

function NRCAutoDDC.OnCreateNPC()
  Log.Debug("NRCAutoDDC.OnCreateNPC", #NRCAutoDDC.NpcIDs)
  NRCAutoDDC.PosID = NRCAutoDDC.PosID + 1
  if NRCAutoDDC.PosID > 8 then
    NRCAutoDDC.PosID = 1
  end
  if NRCAutoDDC.Npcs[NRCAutoDDC.PosID] ~= nil then
    local NPC = NRCAutoDDC.Npcs[NRCAutoDDC.PosID]
    NPC:SetNotDestroyFlag(false)
    local npcModule = NRCModuleManager:GetModule("NPCModule")
    npcModule:RemoveNpc(NRCAutoDDC.Npcs[NRCAutoDDC.PosID]:GetServerId(), true)
    NRCAutoDDC.Npcs[NRCAutoDDC.PosID] = nil
  end
  if #NRCAutoDDC.NpcIDs > 0 then
    local npcID = NRCAutoDDC.NpcIDs[1]
    table.remove(NRCAutoDDC.NpcIDs, 1)
    NRCAutoDDC.CreateLocalNPC(npcID, NRCAutoDDC.PosID)
  else
    NRCAutoDDC.ScanNPCEnd()
    NRCAutoDDC.DoNext()
  end
end

function NRCAutoDDC.CreateLocalNPC(npcId, posid)
  Log.Debug("NRCAutoDDC.CreateLocalNPC", npcId, posid)
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local pos = player:GetActorLocation()
  pos.X = pos.X + 200
  pos.Y = pos.Y + posid * 100 - 400
  local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.CreateLocalNPC, npcId, pos, nil, nil, PriorityEnum.Passive_World_NPC_Close_BP)
  NRCAutoDDC.Npcs[posid] = npc
end

function NRCAutoDDC.ScanNPCEnd()
  if NRCAutoDDC.NPCCreateTimer then
    for i = 1, 8 do
      if NRCAutoDDC.Npcs[i] ~= nil then
        local NPC = NRCAutoDDC.Npcs[i]
        NPC:SetNotDestroyFlag(false)
        local npcModule = NRCModuleManager:GetModule("NPCModule")
        npcModule:RemoveNpc(NRCAutoDDC.Npcs[i]:GetServerId(), true)
        NRCAutoDDC.Npcs[i] = nil
        collectgarbage("collect")
        UE4.UNRCStatics.ForceGarbageCollection(true)
      end
    end
    NRCAutoDDC.NPCCreateTimer:Stop()
    NRCAutoDDC.NPCCreateTimer = nil
  end
end

function NRCAutoDDC.ScanNPCSkill()
  Log.Debug("[ScanNpcSkill] NRCAutoDDC.ScanNPCSkill ")
  NRCAutoDDC.OnScanNpcSkillInit()
end

function NRCAutoDDC.OnScanNpcSkillInit()
  Log.Debug("[ScanNpcSkill] NRCAutoDDC.OnScanNpcSkillInit ")
  NRCAutoDDC.CurProcessNpcData = {}
  NRCAutoDDC.SkillNpcIDList = {}
  NRCAutoDDC.ParallelProcessNum = 5
  NRCAutoDDC.SkillNpcPosIndex = {}
  for i = 1, NRCAutoDDC.ParallelProcessNum do
    table.insert(NRCAutoDDC.SkillNpcPosIndex, true)
  end
  local Model_Path = {}
  local NpcConfs = _G.DataConfigManager:GetAllByName("NPC_CONF")
  for k, v in pairs(NpcConfs) do
    local NPC_CONF = v
    local model_Cfg_id = NPC_CONF.model_conf
    if model_Cfg_id and 0 ~= model_Cfg_id then
      local modelConf = _G.DataConfigManager:GetModelConf(model_Cfg_id)
      if modelConf and Model_Path[modelConf.path] == nil and NPC_CONF.traverse_data_type == Enum.Traverse_Data_Type.TDT_PETBASE then
        Model_Path[modelConf.path] = v
        table.insert(NRCAutoDDC.SkillNpcIDList, {
          NpcId = k,
          NpcPath = modelConf.path
        })
      end
    end
  end
  NRCAutoDDC.OnScanNpcSkillBegin()
end

function NRCAutoDDC.OnScanNpcSkillBegin()
  Log.Debug("[ScanNpcSkill] NRCAutoDDC.OnScanNpcSkillBegin")
  
  local function GetValidPosIndexList()
    local IndexTable = {}
    for i = 1, NRCAutoDDC.ParallelProcessNum do
      if NRCAutoDDC.SkillNpcPosIndex[i] then
        table.insert(IndexTable, i)
      end
    end
    return IndexTable
  end
  
  local ValidIndexList = GetValidPosIndexList()
  local CurProcessNpcNum = table.getTableCount(NRCAutoDDC.CurProcessNpcData)
  local NeedProcessNum = NRCAutoDDC.ParallelProcessNum - CurProcessNpcNum
  if NeedProcessNum < 0 then
    Log.Error("[ScanNpcSkill] NRCAutoDDC.OnScanNpcSkillBegin CurProcessNpcNum exceed limit\239\188\129\239\188\129 CurProcessNpcNum: ", CurProcessNpcNum)
    return
  end
  if 0 == NeedProcessNum then
    Log.Error("[ScanNpcSkill] NRCAutoDDC.OnScanNpcSkillBegin NeedProcessNum == 0")
    return
  end
  for NpcId, NpcData in pairs(NRCAutoDDC.CurProcessNpcData) do
    if 0 == table.getTableCount(NpcData.SkillNpcList) then
      Log.Debug("[ScanNpcSkill] NRCAutoDDC.OnScanNpcSkillBegin invalid NPCData: ", NpcId, " has no skill")
      NRCAutoDDC.SkillNpcPosIndex[NpcData.PosIndex] = true
      NRCAutoDDC.CurProcessNpcData[NpcId] = nil
    end
  end
  if 0 == #ValidIndexList or NeedProcessNum > #ValidIndexList then
    Log.Warning("[ScanNpcSkill] NRCAutoDDC.OnScanNpcSkillBegin ValidIndexList count error ,NeedProcessNum: ", NeedProcessNum, " ValidIndexList: ", table.concat(ValidIndexList, ","))
    for _ = 1, NeedProcessNum - #ValidIndexList do
      table.insert(NRCAutoDDC.SkillNpcPosIndex, true)
      table.insert(ValidIndexList, #NRCAutoDDC.SkillNpcPosIndex)
    end
  end
  local AllEnd = false
  while NeedProcessNum > 0 do
    if #NRCAutoDDC.SkillNpcIDList > 0 then
      local NpcId = NRCAutoDDC.SkillNpcIDList[1].NpcId
      local NpcPath = NRCAutoDDC.SkillNpcIDList[1].NpcPath
      table.remove(NRCAutoDDC.SkillNpcIDList, 1)
      local PosIndex = ValidIndexList[1]
      table.remove(ValidIndexList, 1)
      NRCAutoDDC.CurProcessNpcData[NpcId] = {}
      NRCAutoDDC.InitNpcSkillList(NRCAutoDDC.CurProcessNpcData[NpcId], NpcId, NpcPath, PosIndex)
    else
      AllEnd = true
      break
    end
    NeedProcessNum = NeedProcessNum - 1
  end
  if AllEnd and CurProcessNpcNum <= 0 then
    NRCAutoDDC.OnScanNpcSkillEnd()
    NRCAutoDDC.DoNext()
  end
end

function NRCAutoDDC.InitNpcSkillList(InNpcDataTable, NpcId, NpcPath, PosIndex)
  local function OnFailedProcess(InNpcId, InPosIndex)
    NRCAutoDDC.SkillNpcPosIndex[InPosIndex] = true
    
    NRCAutoDDC.CurProcessNpcData[InNpcId] = nil
    collectgarbage("collect")
    UE4.UNRCStatics.ForceGarbageCollection(true)
    NRCAutoDDC.OnScanNpcSkillBegin()
  end
  
  Log.Debug("[ScanNpcSkill] NRCAutoDDC.InitNpcSkillList - NpcId: ", NpcId)
  local NpcConf = _G.DataConfigManager:GetNpcConf(NpcId)
  if nil == NpcConf then
    Log.Debug("[ScanNpcSkill] InitNpcSkillList NpcConf == nil NpcId: ", NpcId)
    OnFailedProcess(NpcId, PosIndex)
    return
  end
  if #NpcConf.traverse_data_param < 1 then
    Log.Debug("[ScanNpcSkill] InitNpcSkillList #NpcConf.traverse_data_param < 1 NpcId: ", NpcId)
    OnFailedProcess(NpcId, PosIndex)
    return
  end
  local PetBaseId = NpcConf.traverse_data_param[1]
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetBaseId)
  if nil == PetBaseConf then
    Log.Debug("[ScanNpcSkill] InitNpcSkillList PetBaseConf == nil NpcId: ", NpcId)
    OnFailedProcess(NpcId, PosIndex)
    return
  end
  local LevelSkillConfId = PetBaseConf.level_skill_conf_id
  local LevelSkillConf = _G.DataConfigManager:GetLevelSkillConf(LevelSkillConfId)
  if nil == LevelSkillConf then
    Log.Debug("[ScanNpcSkill] InitNpcSkillList LevelSkillConf == nil NpcId: ", NpcId)
    OnFailedProcess(NpcId, PosIndex)
    return
  end
  local NPCClass = UE4.UClass.Load(NpcPath)
  if nil == NPCClass then
    Log.Warning("[ScanNpcSkill] NRCAutoDDC.OnScanNpcSkillBegin NPCClass == nil, skip this pet, NpcPath: ", NpcPath, "")
    OnFailedProcess(NpcId, PosIndex)
    return
  end
  
  local function IsPathExists(id, table)
    for _, v in ipairs(table) do
      if v.SkillConfId == id then
        return true
      end
    end
    return false
  end
  
  NRCAutoDDC.SkillNpcPosIndex[PosIndex] = false
  InNpcDataTable.NpcId = NpcId
  InNpcDataTable.NpcPath = NpcPath
  InNpcDataTable.PosIndex = PosIndex
  InNpcDataTable.SkillNpcList = {}
  for _, v in pairs(LevelSkillConf.level) do
    local SkillConfId = v.param
    if not IsPathExists(SkillConfId, InNpcDataTable) then
      table.insert(InNpcDataTable.SkillNpcList, {SkillConfId = SkillConfId})
    end
  end
  for _, v in ipairs(LevelSkillConf.machine_skill_group) do
    local SkillConfId = v.machine_skill_id
    if not IsPathExists(SkillConfId, InNpcDataTable) then
      table.insert(InNpcDataTable.SkillNpcList, {SkillConfId = SkillConfId})
    end
  end
  if 0 == #InNpcDataTable.SkillNpcList then
    Log.Debug("[ScanNpcSkill] NRCAutoDDC.OnNpc has no skill - NpcId: ", NpcId)
    OnFailedProcess(NpcId, PosIndex)
    return
  end
  local BPClass = UE4.UClass.Load(NpcPath)
  local Player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local Pos = Player:GetActorLocation()
  Pos.X = Pos.X + 100
  Pos.Y = Pos.Y + 100
  Pos.Z = Pos.Z + PosIndex * 400
  for i, SkillData in ipairs(InNpcDataTable.SkillNpcList) do
    local SkillConfId = SkillData.SkillConfId
    local SkillPos = UE4.FVector(Pos.X, Pos.Y, Pos.Z)
    SkillPos.X = Pos.X + math.floor(i / 5) * 400
    SkillPos.Y = Pos.Y + i % 5 * 400
    SkillData.Owner = InNpcDataTable
    SkillData.ValidStatus = true
    SkillData.LocalNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.CreateLocalNPC, NpcId, SkillPos, nil, nil, PriorityEnum.Passive_World_NPC_Close_BP)
    local Transform = UE4.FTransform(UE4.FRotator(0, 0, 0):ToQuat(), UE4.FVector(SkillPos.X, SkillPos.Y, SkillPos.Z), UE4.FVector(1, 1, 1))
    local Actor = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(BPClass, Transform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    SkillData.LocalNpc:SetViewObj(Actor)
    SkillData.ViewObj = SkillData.LocalNpc.viewObj
    local ViewObj = SkillData.ViewObj
    if nil == ViewObj.RocoSkill then
      local SkillComp = ViewObj:GetComponentByClass(UE4.URocoSkillComponent)
      if not SkillComp then
        local Identity = UE4.FTransform()
        SkillComp = ViewObj:AddComponentByClass(UE4.URocoSkillComponent, false, Identity, false)
        ViewObj.RocoSkill = SkillComp
        if not ViewObj:GetComponentByClass(UE4.URocoFXComponent) then
          ViewObj:AddComponentByClass(UE4.URocoFXComponent, false, Identity, false)
        end
      end
      if not SkillComp then
        Log.Debug("[ScanNpcSkill] ViewObj.RocoSkill == nil -NpcId: ", NpcId, " -SkillConfId: ", SkillConfId)
      end
    end
    
    function SkillData.OnSkillEnd(SkillDataTable, EventName, SkillObj)
      Log.Debug("[ScanNpcSkill] NRCAutoDDC.OnSkillEnd -NpcId: ", SkillDataTable.Owner.NpcId, " -SkillConfId: ", SkillDataTable.SkillConfId)
      SkillDataTable.ValidStatus = false
      SkillObj:UnregisterEventCallback("PreEnd", SkillDataTable, SkillDataTable.OnSkillEnd)
      SkillObj:UnregisterEventCallback("End", SkillDataTable, SkillDataTable.OnSkillEnd)
      SkillObj:UnregisterEventCallback("Interrupt", SkillDataTable, SkillDataTable.OnSkillEnd)
      SkillObj:UnregisterEventCallback("LoadFailed", SkillDataTable, SkillDataTable.OnSkillEnd)
      SkillObj:UnregisterEventCallback("ActivateFailed", SkillDataTable, SkillDataTable.OnSkillEnd)
      if SkillDataTable.LocalNpc ~= nil then
        local NPC = SkillDataTable.LocalNpc
        NPC:SetNotDestroyFlag(false)
        local npcModule = NRCModuleManager:GetModule("NPCModule")
        npcModule:RemoveNpc(SkillDataTable.LocalNpc:GetServerId(), true)
        SkillDataTable.LocalNpc = nil
      end
      for _, v in ipairs(SkillDataTable.Owner.SkillNpcList) do
        if v.ValidStatus then
          return
        end
      end
      Log.Debug("[ScanNpcSkill] NRCAutoDDC.OnNpcAllSkillEnd - NpcId: ", SkillDataTable.Owner.NpcId)
      NRCAutoDDC.SkillNpcPosIndex[SkillDataTable.Owner.PosIndex] = true
      NRCAutoDDC.CurProcessNpcData[SkillDataTable.Owner.NpcId] = nil
      NRCAutoDDC.OnScanNpcSkillBegin()
    end
    
    local SkillConf = _G.DataConfigManager:GetSkillConf(SkillConfId)
    if nil ~= SkillConf then
      local SkillPath = SkillConf.res_id
      local Skill = RocoSkillProxy.Create(SkillPath, ViewObj.RocoSkill)
      if Skill then
        Log.Debug("[ScanNpcSkill] NRCAutoDDC.PlayNpcSkill -NpcId: ", SkillData.Owner.NpcId, " -SkillConfId: ", SkillConfId, " -SkillPath: ", SkillPath)
        Skill:SetPassive(true)
        Skill:SetCaster(ViewObj)
        Skill:SetTargets({ViewObj})
        Skill:RegisterEventCallback("PreEnd", SkillData, SkillData.OnSkillEnd)
        Skill:RegisterEventCallback("End", SkillData, SkillData.OnSkillEnd)
        Skill:RegisterEventCallback("Interrupt", SkillData, SkillData.OnSkillEnd)
        Skill:RegisterEventCallback("LoadFailed", SkillData, SkillData.OnSkillEnd)
        Skill:RegisterEventCallback("ActivateFailed", SkillData, SkillData.OnSkillEnd)
        Skill:PlaySkill()
      else
        SkillData.ValidStatus = false
        Log.Debug("[ScanNpcSkill] NRCAutoDDC.PlayNpcSkill SkillCreateFailed -NpcId: ", SkillData.Owner.NpcId, " -SkillConfId: ", SkillConfId, " -SkillPath: ", SkillPath)
      end
    else
      SkillData.ValidStatus = false
    end
  end
end

function NRCAutoDDC.OnScanNpcSkillEnd()
  Log.Debug("[ScanNpcSkill] NRCAutoDDC.OnScanNpcSkillEnd ")
  NRCAutoDDC.CurProcessNpcData = {}
  NRCAutoDDC.SkillNpcIDList = {}
  NRCAutoDDC.SkillNpcPosIndex = {}
end

function NRCAutoDDC.ScanLevel()
  Log.Debug("NRCAutoDDC.AutoRun() ScanLevel")
  NRCAutoDDC.Levels = {}
  NRCAutoDDC.LevelIndex = 0
  local SCENE_RES_CONF = _G.DataConfigManager:GetAllByName("SCENE_RES_CONF")
  for k, Conf in pairs(SCENE_RES_CONF) do
    if Conf.is_unused == false then
      table.insert(NRCAutoDDC.Levels, Conf.source)
    end
  end
  NRCEventCenter:UnRegisterEvent(NRCAutoDDC, NRCGlobalEvent.PostLoadMapWithWorld, NRCAutoDDC.OnPostLoadMapWithWorld)
  NRCEventCenter:RegisterEvent("OnMapLoaded", NRCAutoDDC, NRCGlobalEvent.PostLoadMapWithWorld, NRCAutoDDC.OnPostLoadMapWithWorld)
  NRCModeManager:DeactiveMode("LoginMode")
  NRCModeManager:ActiveMode("LocalMode")
  NRCAutoDDC.DoChangeLevel()
end

function NRCAutoDDC.DoChangeLevel()
  NRCAutoDDC.LevelIndex = NRCAutoDDC.LevelIndex + 1
  if NRCAutoDDC.LevelIndex <= #NRCAutoDDC.Levels then
    local level = NRCAutoDDC.Levels[NRCAutoDDC.LevelIndex]
    Log.Debug("NRCAutoDDC.DoChangeLevel", level)
    _G.LevelHelper:OpenLevel(level)
  else
    NRCAutoDDC.DoNext()
  end
end

function NRCAutoDDC:OnPostLoadMapWithWorld()
  NRCAutoDDC.delayID = _G.DelayManager:DelayFrames(60, function()
    NRCAutoDDC.DoChangeLevel()
  end)
end

function NRCAutoDDC.End()
  if NRCAutoDDC.delayID then
    _G.DelayManager:CancelDelayById(NRCAutoDDC.delayID)
    NRCAutoDDC.delayID = nil
  end
  Log.Debug("NRCAutoDDC End")
end

return NRCAutoDDC
