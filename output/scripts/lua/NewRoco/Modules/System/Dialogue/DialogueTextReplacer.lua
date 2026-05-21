local Class = _G.MakeSimpleClass
local DialogueTextReplacer = Class("DialogueTextReplacer")
local StageNames = {
  "\228\184\128\233\152\182",
  "\228\186\140\233\152\182",
  "\228\184\137\233\152\182"
}
local DefaultGrass = "78B464"
local UnknownText = string.format("<span color=\"#%s\">\239\188\159\239\188\159\239\188\159</>", DefaultGrass)

function DialogueTextReplacer:Ctor()
  self.Patterns = {}
  self:AddPattern("\231\178\190\231\129\181\231\179\187\229\136\171", self.GetPetClass)
  self:AddPattern("PetClass", self.GetPetClass)
  self:AddPattern("\231\178\190\231\129\181\231\137\169\231\167\141", self.GetPetSpecies)
  self:AddPattern("PetSpecies", self.GetPetSpecies)
  self:AddPattern("\231\178\190\231\129\181\231\173\137\231\186\167", self.GetPetLevel)
  self:AddPattern("PetLevel", self.GetPetLevel)
  self:AddPattern("\231\178\190\231\129\181\233\135\141\233\135\143", self.GetPetWeight)
  self:AddPattern("PetWeight", self.GetPetWeight)
  self:AddPattern("\231\178\190\231\129\181\232\186\171\233\171\152", self.GetPetHeight)
  self:AddPattern("PetHeight", self.GetPetHeight)
  self:AddPattern("\229\183\178\230\141\149\230\141\137\230\149\176\233\135\143", self.GetCatchCount)
  self:AddPattern("CatchCount", self.GetCatchCount)
  self:AddPattern("\231\178\190\231\129\181\233\152\182\228\189\141", self.GetPetStage)
  self:AddPattern("PetStage", self.GetPetStage)
  self:AddPattern("\230\150\176\230\141\149\230\141\137\231\178\190\231\129\181\230\128\187\230\149\176", self.GetSubmitPetNum)
  self:AddPattern("SubmitPetNum", self.GetSubmitPetNum)
  self:AddPattern("\230\141\149\230\141\137\231\178\190\231\129\181\230\138\165\229\145\138", self.GetSubmitPetReport)
  self:AddPattern("SubmitPetReport", self.GetSubmitPetReport)
  self:AddPattern("\230\152\159\233\147\190\231\167\187\232\189\172\229\143\145\232\181\183\230\150\185\231\142\169\229\174\182\229\144\141\229\173\151", self.GetMiraclePlayerName)
  self:AddPattern("MiraclePlayerName", self.GetMiraclePlayerName)
  self:AddPattern("\231\142\169\229\174\182\229\144\141\231\167\176", self.GetPlayerName)
  self:AddPattern("name", self.GetPlayerName)
  self:AddPattern("gender:(.-),(.-)", self.GetPlayerGender)
  self:AddPattern("\229\143\145\232\181\183\230\150\185\231\142\169\229\174\182\229\144\141\229\173\151", self.GetMiracleFinishPlayerName)
  self:AddPattern("MiracleFinishPlayerName", self.GetMiracleFinishPlayerName)
  self:AddPattern("\229\143\145\232\181\183\230\150\185\231\142\169\229\174\182\231\154\132\231\178\190\231\129\181\229\144\141\229\173\151", self.GetMiracleFinishPetName)
  self:AddPattern("MiracleFinishPetName", self.GetMiracleFinishPetName)
  self:AddPattern("\231\137\169\229\147\129\230\149\176\233\135\143:(%d+)", self.GetItemCount)
  self:AddPattern("ItemCount:(%d+)", self.GetItemCount)
  self:AddPattern("\231\137\169\229\147\129\229\144\141\231\167\176:(%d+)", self.GetItemName)
  self:AddPattern("ItemName:(%d+)", self.GetItemName)
  self:AddPattern("\229\186\135\230\138\164\230\137\128\229\141\135\231\186\167\230\182\136\232\128\151", self.GetSanctuaryLevelUpCount)
  self:AddPattern("SanctuaryLevelUpCount", self.GetSanctuaryLevelUpCount)
  self:AddPattern("\231\178\190\231\129\181\228\184\138\230\138\165", self.GetCampPetReportDialogue)
  self:AddPattern("CampPetReport", self.GetCampPetReportDialogue)
  self:AddPattern("\229\136\135\231\163\139\232\131\156\229\136\169\229\156\186\230\172\161", self.GetPvpWin)
  self:AddPattern("PvpWin", self.GetPvpWin)
  self:AddPattern("\229\136\135\231\163\139\229\164\177\232\180\165\229\156\186\230\172\161", self.GetPvpLose)
  self:AddPattern("PvpLose", self.GetPvpLose)
  self:AddPattern("\229\136\135\231\163\139\230\156\128\229\184\184\231\148\168\231\178\190\231\129\181\229\144\141\231\167\176", self.GetPvpPetName)
  self:AddPattern("PvpPetName", self.GetPvpPetName)
  self:AddPattern("\229\136\135\231\163\139\230\156\128\229\184\184\231\148\168\231\178\190\231\129\181\229\189\162\230\128\129", self.GetPvpPetForm)
  self:AddPattern("PvpPetForm", self.GetPvpPetForm)
  self:AddPattern("\233\128\137\230\139\169\231\178\190\231\129\181\229\144\141\231\167\176", self.GetFinalBattlePetName)
  self:AddPattern("FinalBattlePetName", self.GetFinalBattlePetName)
  self:AddPattern("\230\160\145\232\139\151\230\137\128\229\164\132\229\156\176\229\140\186", self.GetFruitTreeArea)
  self:AddPattern("FruitTreeArea", self.GetFruitTreeArea)
  self:AddPattern("\229\155\190\233\137\180\232\128\131\230\160\184\229\183\174\229\128\188", self.GetFruitTreeDiffNum)
  self:AddPattern("FruitTreeDiffNum", self.GetFruitTreeDiffNum)
  self:AddPattern("\229\155\190\233\137\180\232\128\131\230\160\184\230\149\176\233\135\143", self.GetFruitTreeTotalNum)
  self:AddPattern("FruitTreeTotalNum", self.GetFruitTreeTotalNum)
  self:AddPattern("\229\143\175\232\167\163\233\148\129\229\156\159\229\156\176\230\149\176\233\135\143", self.GetMaxUnlockFarmLandNum)
  self:AddPattern("MaxUnlockFarmLandNum", self.GetMaxUnlockFarmLandNum)
end

function DialogueTextReplacer:AddPattern(Pattern, Processor)
  if not Pattern then
    return
  end
  if string.IsNilOrEmpty(Pattern) then
    return
  end
  if not Processor then
    return
  end
  table.insert(self.Patterns, {
    Pattern,
    string.format("{%s}", Pattern),
    Processor
  })
end

function DialogueTextReplacer:Replace(Text, Context)
  for _, Patt in ipairs(self.Patterns) do
    Text = Text:gsub(Patt[2], function(...)
      return tostring(Patt[3](self, Context, ...))
    end)
  end
  return Text
end

function DialogueTextReplacer:BatchReplace(TextArray, Context)
  for Index, Text in ipairs(TextArray) do
    TextArray[Index] = self:Replace(Text, Context)
  end
end

function DialogueTextReplacer:GetPlayerGender(Context, Male, Female)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() and player:IsTogetherMove2P() then
    local other_player = player:GetAnotherTogetherMovePlayer()
    if other_player then
      local gender = other_player and other_player.serverData and other_player.serverData.base.gender
      return 1 == gender and Male or Female
    end
  end
  if 1 == player.serverData.base.gender then
    return Male
  else
    return Female
  end
end

function DialogueTextReplacer:GetPetClass(Context)
  local PetConf = Context.PetBaseConf
  if not PetConf then
    return UnknownText
  end
  local UnityType = PetConf.unit_type[1]
  local TypeConf = _G.DataConfigManager:GetTypeDictionary(UnityType)
  return self:Wrap(TypeConf.type_name, DefaultGrass)
end

function DialogueTextReplacer:GetPetSpecies(Context)
  local PetConf = Context.PetBaseConf
  if not PetConf then
    return UnknownText
  end
  local ClassID = PetConf.pet_classis_id
  local ClassConf = _G.DataConfigManager:GetPetClassisConf(ClassID)
  return self:Wrap(ClassConf.name, DefaultGrass)
end

function DialogueTextReplacer:GetPetLevel(Context)
  local PetData = Context.PetData
  if not PetData then
    return UnknownText
  end
  return self:Wrap(PetData.level, DefaultGrass)
end

function DialogueTextReplacer:GetPetWeight(Context)
  local PetData = Context.PetData
  if not PetData then
    return UnknownText
  end
  return self:Wrap(string.format("%.2fkg", PetData.weight * 0.001), DefaultGrass)
end

function DialogueTextReplacer:GetPetHeight(Context)
  local PetData = Context.PetData
  if not PetData then
    return UnknownText
  end
  return self:Wrap(string.format("%.2fm", PetData.height * 0.01), DefaultGrass)
end

function DialogueTextReplacer:GetCatchCount(Context)
  local PetData = Context.PetData
  if not PetData then
    return UnknownText
  end
  local HandbookInfo = _G.DataModelMgr.PlayerDataModel:GetHandbookInfoByPetBaseId(PetData.base_conf_id)
  if not HandbookInfo then
    return UnknownText
  end
  return self:Wrap(HandbookInfo.exp, DefaultGrass)
end

function DialogueTextReplacer:GetPetStage(Context)
  local PetConf = Context.PetBaseConf
  if not PetConf then
    return UnknownText
  end
  return self:Wrap(StageNames[PetConf.stage], DefaultGrass)
end

function DialogueTextReplacer:GetSubmitPetNum(Context)
  return string.format("%d", _G.DataModelMgr.PlayerDataModel:GetPetSubmitNum())
end

function DialogueTextReplacer:GetSubmitPetReport(Context)
  local module = _G.NRCModuleManager:GetModule("DialogueModule")
  if module then
    local info = module:GetLastPetSubmitReportInfo()
    if info and #info >= 2 then
      local SubmitNum = info[1]
      local MaxLevel = info[2] / 10000
      local Text
      if MaxLevel >= _G.DataConfigManager:GetPetGlobalConfig("report_text_hard", true).num then
        Text = LuaText.report_text_super
      elseif MaxLevel >= _G.DataConfigManager:GetPetGlobalConfig("report_text_middle", true).num then
        Text = LuaText.report_text_hard
      elseif MaxLevel >= _G.DataConfigManager:GetPetGlobalConfig("report_text_easy", true).num then
        Text = LuaText.report_text_middle
      else
        Text = LuaText.report_text_easy
      end
      Text = Text:gsub("{\230\150\176\230\141\149\230\141\137\231\178\190\231\129\181\230\128\187\230\149\176}", tostring(SubmitNum))
      Text = Text:gsub("{SubmitPetNum}", tostring(SubmitNum))
      return Text
    else
      return "No valid pet submit report info!"
    end
  end
  return "ParseError"
end

function DialogueTextReplacer:Wrap(Text, Color)
  return string.format("<span color=\"#%s\">%s</>", Color, tostring(Text))
end

function DialogueTextReplacer:GetMiraclePlayerName(Context)
  local serverData = Context.NpcServerData
  return serverData and serverData.miracle_change_info and serverData.miracle_change_info.src_avatar_name or ""
end

function DialogueTextReplacer:GetPlayerName(Context)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() and player:IsTogetherMove2P() then
    local other_player = player:GetAnotherTogetherMovePlayer()
    if other_player then
      return other_player and other_player.serverData and other_player.serverData.base.name
    end
  end
  return _G.DataModelMgr.PlayerDataModel:GetPlayerName()
end

function DialogueTextReplacer:GetMiracleFinishPlayerName(Context)
  local miracleModule = _G.NRCModuleManager:GetModule("MiracleExchangeModule")
  return miracleModule and miracleModule.CacheMiracleInfo and miracleModule.CacheMiracleInfo.playerName or ""
end

function DialogueTextReplacer:GetMiracleFinishPetName(Context)
  local miracleModule = _G.NRCModuleManager:GetModule("MiracleExchangeModule")
  return miracleModule and miracleModule.CacheMiracleInfo and miracleModule.CacheMiracleInfo.petName or ""
end

function DialogueTextReplacer:GetItemCount(Context, ItemIDStr)
  local ID = tonumber(ItemIDStr) or 0
  local BagItem, _ = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, ID)
  if not BagItem then
    return "0"
  end
  return tostring(BagItem.num)
end

function DialogueTextReplacer:GetItemName(Context, ItemIDStr)
  local ID = tonumber(ItemIDStr) or 0
  local Conf = _G.DataConfigManager:GetBagItemConf(ID, true)
  if not Conf then
    return UnknownText
  end
  return Conf.name
end

function DialogueTextReplacer:GetSanctuaryLevelUpCount(Context)
  local ServerData = Context and Context.NpcServerData
  if not ServerData then
    return UnknownText
  end
  local ContentID = ServerData.npc_base.npc_content_cfg_id
  local Conf = _G.DataConfigManager:GetOwlSanctuaryConf(ContentID)
  if not Conf then
    return UnknownText
  end
  return tostring(Conf.levelup_cost_num)
end

function DialogueTextReplacer:GetCampPetReportDialogue(Context)
  local ReportID = 0
  if Context.Params then
    ReportID = Context.Params[1] or 0
  end
  local CampPetReportConf = _G.DataConfigManager:GetCampPetReportConf(ReportID)
  if not CampPetReportConf then
    return UnknownText
  end
  return CampPetReportConf.dialogue
end

function DialogueTextReplacer:GetPvpWin(Context)
  local PvpStats = _G.DataModelMgr.PlayerDataModel:GetPVPStats()
  if not PvpStats then
    return "0"
  end
  return tostring(PvpStats.win_count or 0)
end

function DialogueTextReplacer:GetPvpLose(Context)
  local PvpStats = _G.DataModelMgr.PlayerDataModel:GetPVPStats()
  if not PvpStats then
    return "0"
  end
  return tostring(PvpStats.lose_count or 0)
end

function DialogueTextReplacer:GetPvpPetName(Context)
  local PvpStats = _G.DataModelMgr.PlayerDataModel:GetPVPStats()
  if not PvpStats then
    return LuaText.pvp_no_fight_inquire_des
  end
  local PetID = PvpStats.freq_base_id or 0
  if 0 == PetID then
    return LuaText.pvp_no_fight_inquire_des
  end
  local Conf = _G.DataConfigManager:GetPetbaseConf(PetID)
  if not Conf then
    return UnknownText
  end
  return Conf.name
end

function DialogueTextReplacer:GetPvpPetForm(Context)
  local PvpStats = _G.DataModelMgr.PlayerDataModel:GetPVPStats()
  if not PvpStats then
    return ""
  end
  local PetID = PvpStats.freq_base_id or 0
  if 0 == PetID then
    return ""
  end
  local Conf = _G.DataConfigManager:GetPetbaseConf(PetID)
  if not Conf then
    return ""
  end
  if string.IsNilOrEmpty(Conf.form) then
    return ""
  end
  return string.format("\239\188\136%s\239\188\137", Conf.form)
end

function DialogueTextReplacer:GetFinalBattlePetName(Context)
  local petData = NRCModuleManager:DoCmd(BattleUIModuleCmd.GetFinalBattlePetData)
  return petData.name
end

function DialogueTextReplacer:GetFruitTreeArea(Context)
  local ServerData = Context and Context.NpcServerData
  if not ServerData then
    return UnknownText
  end
  local ContentID = ServerData.npc_base.npc_content_cfg_id
  local Conf = _G.DataConfigManager:GetFruitTreeConf(ContentID)
  if not Conf then
    return UnknownText
  end
  return Conf.area
end

function DialogueTextReplacer:GetFruitTreeDiffNum(Context)
  local ServerData = Context and Context.NpcServerData
  if not ServerData then
    return UnknownText
  end
  local DiffNum = 0
  if Context.Params then
    DiffNum = Context.Params[1] or 0
  end
  return DiffNum
end

function DialogueTextReplacer:GetFruitTreeTotalNum(Context)
  local ServerData = Context and Context.NpcServerData
  if not ServerData then
    return UnknownText
  end
  local ContentID = ServerData.npc_base.npc_content_cfg_id
  local Conf = _G.DataConfigManager:GetFruitTreeConf(ContentID)
  if not Conf then
    return UnknownText
  end
  return Conf.pet_num
end

function DialogueTextReplacer:GetMaxUnlockFarmLandNum(Context)
  local num = _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.GetAvailableUnlockFarmLandNum)
  num = num or 0
  return num
end

return DialogueTextReplacer
