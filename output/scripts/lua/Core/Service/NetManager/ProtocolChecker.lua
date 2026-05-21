local OnlineState = require("Core.Service.NetManager.OnlineState")
local ProtocolChecker = Class()

local function IsCmdStartsWithZone(CmdName)
  if string.find(CmdName, "^.Next.Zone") then
    return true
  end
  return false
end

local function IsCmdStartsWithZoneScene(CmdName)
  if string.find(CmdName, "^.Next.ZoneScene") then
    return true
  end
  return false
end

local function IsCmdOnlyStartsWithZone(CmdName)
  return IsCmdStartsWithZone(CmdName) and not IsCmdStartsWithZoneScene(CmdName)
end

function ProtocolChecker:Ctor()
  self.downStreamPktBlacklist = {
    [OnlineState.Logouted] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.Logining] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.Logined] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.EnteringCell] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.EnteredCell] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.SwitchingCell] = {
      CmdList = {},
      MatchFunc = nil
    }
  }
  self.downStreamPktWhitelist = {
    [OnlineState.Logouted] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.Logining] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_KICKOUT_NTY
      },
      MatchFunc = nil
    },
    [OnlineState.Logined] = {
      CmdList = {},
      MatchFunc = IsCmdOnlyStartsWithZone
    },
    [OnlineState.EnteringCell] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_ENTRY_INFO_INCR_NTY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY_ACK,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_ONLINE_VISITOR_INFO_NOTIFY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_ONLINE_VISITOR_CHANGE_NOTIFY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAYER_VISIT_INFO_SYNC_NOTIFY
      },
      MatchFunc = IsCmdOnlyStartsWithZone
    },
    [OnlineState.EnteredCell] = {
      CmdList = {},
      MatchFunc = IsCmdStartsWithZone
    },
    [OnlineState.SwitchingCell] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_KICKOUT_NTY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_ENTRY_INFO_INCR_NTY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CANCEL_PRE_TELEPORT_NOTIFY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TELEPORT_NOTIFY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY_ACK,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_ONLINE_VISITOR_INFO_NOTIFY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_ONLINE_VISITOR_CHANGE_NOTIFY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TEAM_BATTLE_INVITE_NOTIFY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_RSP
      },
      MatchFunc = IsCmdOnlyStartsWithZone
    }
  }
  self.upStreamPktBlacklist = {
    [OnlineState.Logouted] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.Logining] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.Logined] = {
      CmdList = {},
      MatchFunc = nil
    },
    [OnlineState.EnteringCell] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_REQ
      },
      MatchFunc = nil
    },
    [OnlineState.EnteredCell] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_REQ
      },
      MatchFunc = nil
    },
    [OnlineState.SwitchingCell] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_REQ
      },
      MatchFunc = nil
    }
  }
  self.upStreamPktWhitelist = {
    [OnlineState.Logouted] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_REQ,
        ProtoCMD.ZoneSvrCmd.ZONE_REGISTER_REQ
      },
      MatchFunc = nil
    },
    [OnlineState.Logining] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_REQ
      },
      MatchFunc = nil
    },
    [OnlineState.Logined] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_REQ
      },
      MatchFunc = IsCmdOnlyStartsWithZone
    },
    [OnlineState.EnteringCell] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_EVENT_REQ
      },
      MatchFunc = IsCmdOnlyStartsWithZone
    },
    [OnlineState.EnteredCell] = {
      CmdList = {},
      MatchFunc = IsCmdStartsWithZone
    },
    [OnlineState.SwitchingCell] = {
      CmdList = {
        ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_REQ,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY_ACK,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_ENTRY_INFO_INCR_NTY,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_EVENT_REQ,
        ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ
      },
      MatchFunc = nil
    }
  }
end

function ProtocolChecker:CanSendCMD(CmdId, CurOnlineState)
  if CurOnlineState < OnlineState.Begin and CurOnlineState >= OnlineState.End or self.upStreamPktWhitelist[CurOnlineState] == nil or nil == self.upStreamPktBlacklist[CurOnlineState] then
    Log.Error("[ZoneServer][NetMsg][ProtocolChecker] CanSendCMD Invalid OnlineState: ", CurOnlineState, CmdId)
    return false
  end
  local CmdName = ProtoCMD:GetMessageName(CmdId)
  if CmdName and (string.find(CmdName, "ZoneGm") or string.find(CmdName, "ZoneSceneGm")) then
    return true
  end
  local BlackListMatchItem = self.upStreamPktBlacklist[CurOnlineState]
  if table.contains(BlackListMatchItem.CmdList, CmdId) then
    Log.Error("[ZoneServer][NetMsg][ProtocolChecker] Cannot send cmd", CmdName, "it's in BlackList, CurOnlineState", OnlineState.ToString(CurOnlineState))
    return false
  end
  local BlackListMatchFunc = BlackListMatchItem.MatchFunc
  if nil ~= BlackListMatchFunc and BlackListMatchFunc(CmdName) then
    Log.Error("[ZoneServer][NetMsg][ProtocolChecker] Cannot send cmd", CmdName, "it's BlackList MatchFunc return false, CurOnlineState", OnlineState.ToString(CurOnlineState))
    return false
  end
  local WhiteListMatchItem = self.upStreamPktWhitelist[CurOnlineState]
  if table.contains(WhiteListMatchItem.CmdList, CmdId) then
    return true
  end
  local WhiteListMatchFunc = WhiteListMatchItem.MatchFunc
  if nil ~= WhiteListMatchFunc and WhiteListMatchFunc(CmdName) then
    return true
  end
  Log.Error("[ZoneServer][NetMsg][ProtocolChecker] Cannot send cmd", CmdName, "current OnlineState is", OnlineState.ToString(CurOnlineState))
  return false
end

function ProtocolChecker:CanRecvCMD(CmdId, CurOnlineState)
  if CurOnlineState < OnlineState.Begin and CurOnlineState >= OnlineState.End or self.downStreamPktWhitelist[CurOnlineState] == nil or nil == self.downStreamPktBlacklist[CurOnlineState] then
    Log.Error("[ZoneServer][NetMsg][ProtocolChecker] CanRecvCMD Invalid OnlineState: ", CurOnlineState, CmdId)
    return false
  end
  local CmdName = ProtoCMD:GetMessageName(CmdId)
  if CmdName and string.find(CmdName, "_GM_") then
    return true
  end
  local BlackListMatchItem = self.downStreamPktBlacklist[CurOnlineState]
  if table.contains(BlackListMatchItem.CmdList, CmdId) then
    Log.Error("[ZoneServer][NetMsg][ProtocolChecker] Cannot recv cmd", CmdName, "it's in BlackList, CurOnlineState", OnlineState.ToString(CurOnlineState))
    return false
  end
  local BlackListMatchFunc = BlackListMatchItem.MatchFunc
  if nil ~= BlackListMatchFunc and BlackListMatchFunc(CmdName) then
    Log.Error("[ZoneServer][NetMsg][ProtocolChecker] Cannot recv cmd", CmdName, "it's BlackList MatchFunc return false, CurOnlineState", OnlineState.ToString(CurOnlineState))
    return false
  end
  local WhiteListMatchItem = self.downStreamPktWhitelist[CurOnlineState]
  if table.contains(WhiteListMatchItem.CmdList, CmdId) then
    return true
  end
  local WhiteListMatchFunc = WhiteListMatchItem.MatchFunc
  if nil ~= WhiteListMatchFunc and WhiteListMatchFunc(CmdName) then
    return true
  end
  Log.Error("[ZoneServer][NetMsg][ProtocolChecker] Cannot recv cmd", CmdName, "current OnlineState is", OnlineState.ToString(CurOnlineState))
  return false
end

return ProtocolChecker
