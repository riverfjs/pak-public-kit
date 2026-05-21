local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local PetUtils = require("NewRoco.Utils.PetUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local Base = NPCActionBase
local lastTime
local NPCActionRecoverAll = Base:Extend("NPCActionRecoverAll")

function NPCActionRecoverAll:OnNpcAction()
  local currentTime = os.clock()
  if lastTime and currentTime - lastTime < 3 then
    Log.Debug("\233\151\180\233\154\148\229\164\170\229\176\145\239\188\140\229\134\141\231\173\137\231\173\137")
    return false
  end
  return Base.OnNpcAction(self)
end

function NPCActionRecoverAll:Execute(playerId, needSendReq)
  lastTime = os.clock()
  Base.Execute(self, playerId, needSendReq)
end

function NPCActionRecoverAll:OnSubmit(rsp)
  Base.OnSubmit(self, rsp)
  local ErrorCode = rsp.ret_info.ret_code
  if 0 == ErrorCode then
    local targetGids = {}
    local PetTeams = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
    if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
      for _, team in ipairs(PetTeams.teams) do
        local gids = PetUtils.PetTeamGetPetGidList(team)
        if gids then
          for _, gid in ipairs(gids) do
            local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
            local curHp = PetUtils.GetPetAdditionalByType(petData, _G.ProtoEnum.AttributeType.AT_HPCUR)
            if curHp <= 0 then
              table.insert(targetGids, gid)
            end
          end
        end
      end
    end
    if #targetGids <= 0 then
      return
    end
    local req = ProtoMessage:newZoneGetPetInfoByGidReq()
    req.gids = targetGids
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_PET_INFO_BY_GID_REQ, req, self, self.OnCheckDeadPetDataSuccess, false, true, nil, nil)
  end
end

function NPCActionRecoverAll:OnCheckDeadPetDataSuccess(rsp)
  local ErrorCode = rsp.ret_info and rsp.ret_info.ret_code or -1
  if 0 == ErrorCode then
    local inValidGids = rsp.not_exist_gids
    if inValidGids and #inValidGids > 0 then
      for _, gid in ipairs(inValidGids) do
        Log.Debug("NPCActionRecoverAll:OnCheckDeadPetDataSuccess, request inValidGids:", gid)
      end
    end
    local petDataInfos = rsp.pet_list
    if petDataInfos and petDataInfos.pet_data and #petDataInfos.pet_data > 0 then
      for _, petData in ipairs(petDataInfos.pet_data) do
        if petData then
          if petData.attribute_new_info then
            _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 2, petData)
          end
          self:SendEvent(ENUM_PLAYER_DATA_EVENT.UPDATE_PET_HP, petData)
        end
      end
    end
  else
    Log.Error("NPCActionRecoverAll:OnCheckDeadPetDataSuccess, Request ErrorCode:", ErrorCode)
  end
end

return NPCActionRecoverAll
