local RogueModuleEnum = require("NewRoco/Modules/System/BattleRogue/RogueModuleEnum")
local RogueModuleEvent = require("NewRoco/Modules/System/BattleRogue/BattleRogueModuleEvent")
local BattleRogueModuleData = _G.NRCData:Extend("BattleRogueModuleData")

function BattleRogueModuleData:Ctor()
  NRCData.Ctor(self)
  self.TrialID = -1
  self.CurChapterID = -1
  self.CurNodeIndex = 1
  self.RemainingCoin = 0
  self.EventList = {}
  self.TrialPetInfo = ProtoMessage:newGrassTrialPet()
  self.CacheTrialData = nil
  self.bInit = false
  self.CacheNodeData = nil
end

function BattleRogueModuleData:TryInitEventInfo()
  if self.bInit or -1 == self.CurChapterID then
    return
  end
  local ChapterConf = _G.DataConfigManager:GetGrassTrialChapterConf(self.CurChapterID)
  for _, ChapterNode in ipairs(ChapterConf.node_struct) do
    if 0 == ChapterNode.node then
    elseif 0 == #ChapterNode.node_event then
      table.insert(self.EventList, RogueModuleEnum.EventState.Future)
    else
      local AnyEventID = ChapterNode.node_event[1]
      if AnyEventID then
        local EventType = _G.DataConfigManager:GetGrassTrialEventConf(AnyEventID).type
        if EventType == Enum.EventType.ET_BOSS_FIGHT then
          table.insert(self.EventList, RogueModuleEnum.EventState.Boss)
        else
          table.insert(self.EventList, RogueModuleEnum.EventState.Future)
        end
      end
    end
  end
  self.bInit = true
end

function BattleRogueModuleData:UpdateChallengeInfo(NewChallengeInfo)
  if not NewChallengeInfo or not next(NewChallengeInfo) then
    return
  end
  self.CurNodeIndex = NewChallengeInfo.current_node_index or self.CurNodeIndex
  self.CurChapterID = NewChallengeInfo.current_chapter_id or self.CurChapterID
  self:TryInitEventInfo()
  for Index = 1, self.CurNodeIndex do
    self.EventList[Index] = RogueModuleEnum.EventState.Done
  end
  self.EventList[self.CurNodeIndex] = RogueModuleEnum.EventState.InProcess
  self.TrialPetInfo = NewChallengeInfo.trial_pet_data or self.TrialPetInfo
  self.TrialID = NewChallengeInfo.trial_conf_id or self.TrialID
  self.RemainingCoin = NewChallengeInfo.remaining_coin
  self:DispatchEvent(RogueModuleEvent.TrialDataChange, RogueModuleEnum.ChallengeInfoFlag.All)
end

function BattleRogueModuleData:UpdatePetInfo(NewPetInfo)
  self.TrialPetInfo = NewPetInfo or self.TrialPetInfo
  self:DispatchEvent(RogueModuleEvent.TrialDataChange, RogueModuleEnum.ChallengeInfoFlag.PetInfo)
end

function BattleRogueModuleData:UpdateCoinNum(NewNum)
  self.RemainingCoin = NewNum or self.RemainingCoin
  self:DispatchEvent(RogueModuleEvent.TrialDataChange, RogueModuleEnum.ChallengeInfoFlag.Chapter)
end

function BattleRogueModuleData:GetSkills()
  return self.TrialPetInfo.skills
end

function BattleRogueModuleData:GetSkillNum()
  return #self.TrialPetInfo.skills
end

function BattleRogueModuleData:GetCacheTrialData()
  if not self.CacheTrialData then
    self:LogError("CacheTrialData is miss")
  end
  return self.CacheTrialData
end

function BattleRogueModuleData:ClearCacheTrialData()
  self.CacheTrialData = nil
end

return BattleRogueModuleData
