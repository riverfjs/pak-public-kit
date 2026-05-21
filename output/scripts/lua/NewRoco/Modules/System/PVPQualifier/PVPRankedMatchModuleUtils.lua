local PVPRankedMatchModuleUtils = {}
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function PVPRankedMatchModuleUtils.GetCurRankName()
  local RankStar = PVPRankedMatchModuleUtils.GetSelfRankStar()
  if not RankStar then
    return ""
  end
  local curRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(RankStar)
  if not curRankConf then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150\230\174\181\228\189\141\233\133\141\231\189\174,\230\174\181\228\189\141\230\149\176\230\141\174\229\188\130\229\184\184 \229\189\147\229\137\141\230\136\145\231\154\132\230\174\181\228\189\141RankStar\230\152\175", RankStar)
    return ""
  end
  return curRankConf.name
end

function PVPRankedMatchModuleUtils.GetRankName(rank_star)
  local rank_conf = PVPRankedMatchModuleUtils.GetPvpRankConf(rank_star)
  if not rank_conf then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150\230\174\181\228\189\141\233\133\141\231\189\174,\230\174\181\228\189\141rank_star\230\152\175", rank_star)
  end
  return rank_conf.name
end

function PVPRankedMatchModuleUtils.IsMaxRankStar(RankStar)
  local maxRankStar = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetMaxRankStar)
  return RankStar >= maxRankStar
end

function PVPRankedMatchModuleUtils.IsSelfMaxRankStar()
  local maxRankStar = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetMaxRankStar)
  local RankStar = PVPRankedMatchModuleUtils.GetSelfRankStar()
  return maxRankStar <= RankStar
end

function PVPRankedMatchModuleUtils.CorrectionRankStar(RankStar)
  local maxRankStar = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetMaxRankStar)
  if not RankStar then
    Log.Error("RankStar is nil")
  end
  if not maxRankStar then
    Log.Error("maxRankStar is nil")
  end
  if RankStar >= maxRankStar then
    return maxRankStar
  else
    return RankStar
  end
end

function PVPRankedMatchModuleUtils.GetCurOrderOrRankName()
  local RankOrder = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_ORDER)
  return PVPRankedMatchModuleUtils.GetOrderOrRankName(RankOrder)
end

function PVPRankedMatchModuleUtils.GetOrderOrRankName(RankOrder)
  if not RankOrder or 0 == RankOrder or RankOrder > 10000 then
    return "10000+"
  end
  return RankOrder
end

function PVPRankedMatchModuleUtils.GetSelfRankStar()
  local RankStar = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_STAR)
  local module = NRCModuleManager:GetModule("PVPRankedMatchModule")
  if module and module.__debugSeasonOpenStarNum > 0 then
    RankStar = module.__debugSeasonOpenStarNum
  end
  return RankStar
end

function PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
  local RankStar = PVPRankedMatchModuleUtils.GetSelfRankStar()
  return PVPRankedMatchModuleUtils.GetPvpRankConf(RankStar)
end

function PVPRankedMatchModuleUtils.GetPvpRankConf(RankStar)
  RankStar = PVPRankedMatchModuleUtils.CorrectionRankStar(RankStar)
  local rankConf = _G.DataConfigManager:GetPvpRankConf(RankStar)
  if not rankConf then
    Log.Error("\230\174\181\228\189\141\233\133\141\231\189\174\232\142\183\229\143\150\229\188\130\229\184\184,\232\175\183\230\163\128\230\159\165\229\189\147\229\137\141\230\174\181\228\189\141\230\152\175\229\144\166\229\173\152\229\156\168\233\133\141\231\189\174\239\188\140RankStar=", RankStar)
  end
  return rankConf
end

function PVPRankedMatchModuleUtils.GetCurSeasonStepRemainTimeStr()
  local curStepFinishTime = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurStepFinishTime)
  local curTime = ActivityUtils.GetSvrTimestamp()
  local remainTime = curStepFinishTime - curTime
  return ActivityUtils.GetTimeFormatStr(remainTime)
end

function PVPRankedMatchModuleUtils.GetWeekRefreshRemainTimeStr()
  local curStepFinishTime = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurWeekRefreshTime)
  local curTime = ActivityUtils.GetSvrTimestamp()
  local remainTime = curStepFinishTime - curTime
  return ActivityUtils.GetTimeFormatStr(remainTime)
end

function PVPRankedMatchModuleUtils.OnFlagSpineAnimationStart(entry)
  local animName
  local soundId = 0
  if entry and UE.UObject.IsValid(entry) then
    animName = entry:getAnimationName()
    if animName:find("In") then
      soundId = 40100015
    elseif animName:find("Out") then
      soundId = 40100016
    elseif animName:find("loop") then
      soundId = 0
    elseif animName:find("up") then
      if "F_5_up_F-G" == animName then
        soundId = 40100012
      elseif "G_1_up" == animName then
        soundId = 40100017
      elseif animName:find("-") then
        soundId = 40100010
      else
        soundId = 40100018
      end
    elseif animName:find("-") then
      if "G_2-1" == animName then
        soundId = 40100021
      else
        soundId = 40100009
      end
    end
  end
  if soundId > 0 then
    _G.NRCAudioManager:PlaySound2DAuto(soundId, animName)
  end
end

function PVPRankedMatchModuleUtils.IsTrialPetExpired(gid)
  local isTrialPet, _ = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, gid)
  if not isTrialPet then
    return false
  end
  local time = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetTrialPetBriefRefreshTime)
  local servetTime = ActivityUtils.GetSvrTimestamp()
  if time < servetTime then
    return true
  else
    return false
  end
end

function PVPRankedMatchModuleUtils.TrialPetExpiredClosePanel()
  local tips = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_trial_pet_character4").str
  _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AnimClosePetTeamReplacePanel)
end

function PVPRankedMatchModuleUtils.GetDeltaMasterScoreText(oldScore, newScore)
  oldScore = oldScore or 0
  newScore = newScore or 0
  local deltaMasterScore = newScore - oldScore
  local absDeltaMasterScore = math.abs(deltaMasterScore)
  local isPositive = deltaMasterScore >= 0
  local deltaMasterScoreText = tostring(absDeltaMasterScore)
  if isPositive then
    deltaMasterScoreText = "+" .. deltaMasterScoreText
  else
    deltaMasterScoreText = "-" .. deltaMasterScoreText
  end
  return deltaMasterScoreText
end

function PVPRankedMatchModuleUtils.GetTimestampFromTimeStr(time_str)
  local year, month, day, hour, min, sec = string.match(time_str, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
  if year then
    local timestamp = os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = tonumber(sec)
    })
    return timestamp
  else
    return 0
  end
end

function PVPRankedMatchModuleUtils.GetRankListBySeasonIdInRankConf(pvpRankConf, seasonId)
  local rankList = pvpRankConf and pvpRankConf.rank_list or {}
  for i, rankListItem in ipairs(rankList) do
    local itemSeasonId = rankListItem and rankListItem.season
    if itemSeasonId == seasonId then
      return rankListItem
    end
  end
end

function PVPRankedMatchModuleUtils.GetSpineAssetPathsSeasonIdInRankConf(pvpRankConf, seasonId)
  local rankListItem = PVPRankedMatchModuleUtils.GetRankListBySeasonIdInRankConf(pvpRankConf, seasonId)
  local spine = rankListItem and rankListItem.spine
  local atlasPath
  if spine then
    atlasPath = string.format("SpineAtlasAsset'%s.qizi-atlas'", tostring(spine))
  end
  local skeletonDataPath
  if spine then
    skeletonDataPath = string.format("SpineSkeletonDataAsset'%s.qizi-data'", tostring(spine))
  end
  return atlasPath, skeletonDataPath
end

function PVPRankedMatchModuleUtils.GetPreloadList()
  local list = {}
  local fantasticUi1Conf = _G.DataConfigManager:GetBattleGlobalConfig("fantastic_ui1", true)
  local fantasticUi1ConfStr = fantasticUi1Conf and fantasticUi1Conf.str
  if fantasticUi1ConfStr then
    list[fantasticUi1ConfStr] = fantasticUi1ConfStr
  end
  local seasonTable = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.SEASON_CONF)
  local seasonConfList = seasonTable and seasonTable:GetAllDatas() or {}
  for key, seasonSkillConf in pairs(seasonConfList) do
    local season_skill_ui = seasonSkillConf and seasonSkillConf.season_skill_ui
    if not string.IsNilOrEmpty(season_skill_ui) then
      list[season_skill_ui] = season_skill_ui
    end
  end
  return list
end

return PVPRankedMatchModuleUtils
