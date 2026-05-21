local Array = require("Utils.Array")
local AICoachModuleData = _G.NRCData:Extend("AICoachModuleData")

function AICoachModuleData:Ctor()
  NRCData.Ctor(self)
  self.CurrentPlayVoiceList = Array()
  self.CurrentShowText = ""
  self.CurrentShowNarrationText = ""
  self.CurrentRecommendDiffJson = ""
  self.CurrentRecommendName = ""
  self.CurrentAICoachVoiceStream = UE4.TArray(UE4.uint8)
end

function AICoachModuleData:Clear()
  for i = 1, self.CurrentPlayVoiceList:Size() do
    UE.UNRCStatics.DeleteToFile(self.CurrentPlayVoiceList:Get(i))
  end
  self.CurrentAICoachVoiceStream:Clear()
  self.CurrentPlayVoiceList:Clear()
  self.CurrentShowText = ""
  self.CurrentShowNarrationText = ""
  self.CurrentRecommendDiffJson = ""
  self.CurrentRecommendName = ""
end

function AICoachModuleData:OnUpdateShowText(text)
  self.CurrentShowText = self.CurrentShowText .. text
end

function AICoachModuleData:OnUpdateNarrationShowText(text)
  self.CurrentShowNarrationText = self.CurrentShowNarrationText .. text
end

function AICoachModuleData:GetShowText()
  return self.CurrentShowText
end

function AICoachModuleData:GetShowNarrationText()
  return self.CurrentShowNarrationText
end

function AICoachModuleData:OnAddPlayVoiceItem(audio)
  self.CurrentPlayVoiceList:Push(audio)
end

function AICoachModuleData:OnGetPlayVoiceItems()
  return self.CurrentPlayVoiceList
end

function AICoachModuleData:OnClearShowText()
  self.CurrentShowText = ""
end

function AICoachModuleData:OnClearShowNarrationText()
  self.CurrentShowNarrationText = ""
end

function AICoachModuleData:OnSetRecommendDiffJson(json)
  self.CurrentRecommendDiffJson = json
end

function AICoachModuleData:OnGetRecommendDiffJson()
  return self.CurrentRecommendDiffJson
end

function AICoachModuleData:OnSetRecommendName(name)
  self.CurrentRecommendName = name
end

function AICoachModuleData:OnGetRecommendName()
  return self.CurrentRecommendName
end

function AICoachModuleData:OnAddAICoachVoiceStream(audio)
  self.CurrentAICoachVoiceStream:Append(audio)
end

function AICoachModuleData:OnGetAICoachVoiceStreamByLength(arrayData, length)
  if length > self.CurrentAICoachVoiceStream:Length() then
    arrayData:Append(self.CurrentAICoachVoiceStream)
  else
    arrayData = UE4.TArray(self.CurrentAICoachVoiceStream:GetData(), length)
    self.CurrentAICoachVoiceStream:RemoveAt(0, length)
  end
end

return AICoachModuleData
