local VitalityRecoverStageEnum = {
  SEARCH = 1,
  CLIENT_TRIGGER = 2,
  SERVER_ACK_SUCCEED = 3,
  CLIENT_CANCEL = 4
}
local STAGE_NAMES = {}
for name, id in pairs(VitalityRecoverStageEnum) do
  STAGE_NAMES[id] = name
end

function VitalityRecoverStageEnum.GetStageName(stageId)
  return STAGE_NAMES[stageId] or "Unknown_" .. tostring(stageId)
end

return VitalityRecoverStageEnum
