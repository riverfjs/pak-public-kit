local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local TakePhotosModuleEvent = require("NewRoco.Modules.System.TakePhotos.TakePhotosModuleEvent")
local PhotoActivityManager = Class("PhotoActivityManager")

function PhotoActivityManager:Ctor()
  local CdConfig = _G.DataConfigManager:GetActivityGlobalConfig("takephoto_competition_submit_cd")
  self.SubmitCdSeconds = CdConfig and CdConfig.num or 300
end

function PhotoActivityManager:LogError(...)
  return Log.Error("[PhotoActivityManager]", ...)
end

function PhotoActivityManager:LogDebug(...)
  return Log.Debug("[PhotoActivityManager]", ...)
end

function PhotoActivityManager:GetActivityObject()
  local ObjectList = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_TAKEPHOTO_COMPETITION)
  return ObjectList and ObjectList[1]
end

function PhotoActivityManager:InAlbumSubmitStatus()
  return self.bEnableSubmitStatus or false
end

function PhotoActivityManager:ToggleAlbumSubmitStatus(bEnableSubmitStatus)
  self.bEnableSubmitStatus = bEnableSubmitStatus
end

function PhotoActivityManager:InSubmitCoolDown(bShowTips)
  local Object = self:GetActivityObject()
  if not Object then
    return true
  end
  local ActivityData = Object:GetActivityData()
  if not ActivityData then
    return true
  end
  local LastTime = ActivityData.last_submit_time or 0
  if LastTime <= 0 then
    return false
  end
  local CurrTime = _G.ZoneServer:GetServerTime() / 1000
  local bInCd = CurrTime - LastTime < self.SubmitCdSeconds
  if bInCd and bShowTips then
    local Remaining = self.SubmitCdSeconds - (CurrTime - LastTime)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.pic_game_submit_CD_tips, math.tointeger(math.max(1, Remaining // 60))))
  end
  return bInCd
end

function PhotoActivityManager:GetSubmitContest()
  local Object = self:GetActivityObject()
  if not Object then
    return
  end
  local ActivityData = Object:GetActivityData()
  if not ActivityData then
    return
  end
  if not ActivityData.phases then
    return
  end
  for i = #ActivityData.phases, 1, -1 do
    local Phase = ActivityData.phases[i]
    if Phase.phase_id == ActivityData.current_phase_id then
      if (Phase.photo_url or "") ~= "" then
        return Phase
      else
        return nil
      end
    end
  end
end

function PhotoActivityManager:GetRevertNameFlag()
  local Contest = self:GetSubmitContest()
  if Contest and Contest.mini_photo_url ~= "" then
    local Char = string.sub(Contest.mini_photo_url, #Contest.mini_photo_url, #Contest.mini_photo_url)
    assert(Char)
    local Flag = math.tointeger(Char)
    if not Flag then
      return 0
    end
    if 0 == Flag then
      return 1
    end
  end
  return 0
end

function PhotoActivityManager:IsPhotoDataHasBeenSubmit(PhotoData)
  if not PhotoData then
    return false
  end
  if not PhotoData:IsValid() then
    return false
  end
  local SubmitContent = self:GetSubmitContest()
  if SubmitContent then
    local Md5 = PhotoData:GetDesiredMd5()
    return SubmitContent.photo_md5 == Md5
  end
  return false
end

function PhotoActivityManager:IsPhotoDataNeedDisplayHasBeenSubmit(PhotoData)
  return PhotoData and self:InAlbumSubmitStatus() and self:IsPhotoDataHasBeenSubmit(PhotoData)
end

function PhotoActivityManager:UpdateSubmitContest(Contest, LastSubmitTime)
  if not Contest then
    self:LogError(" Cannot found submit contest ", Contest)
    return
  end
  local Activity = self:GetActivityObject()
  if not Activity then
    self:LogError(" Cannot found activity object")
    return
  end
  local ActivityData = Activity:GetActivityData()
  if not ActivityData or not ActivityData.phases then
    self:LogError(" Cannot found activity phase data ", ActivityData, ActivityData.phases)
    return
  end
  if LastSubmitTime then
    ActivityData.last_submit_time = LastSubmitTime
  end
  local bReplaceSubmit = false
  for i = #ActivityData.phases, 1, -1 do
    local Phase = ActivityData.phases[i]
    if Phase.phase_id == ActivityData.current_phase_id then
      bReplaceSubmit = true
      Phase.phase_id = Contest.phase_id
      Phase.photo_url = Contest.photo_url
      Phase.photo_md5 = Contest.photo_md5
      Phase.mini_photo_url = Contest.mini_photo_url
      Phase.mini_photo_md5 = Contest.mini_photo_md5
      Phase.total_like_count = 0
      Phase.is_disposable_reward_taken = false
      Phase.total_hot_count = 0
      self:LogDebug("UpdateSubmitContest", Contest.phase_id, Contest.photo_url, Contest.photo_md5, Contest.mini_photo_url, Contest.mini_photo_md5)
      _G.NRCEventCenter:DispatchEvent(TakePhotosModuleEvent.OnPhotoActivitySubmit)
      break
    end
  end
  if not bReplaceSubmit then
    local Phase = {}
    Phase.phase_id = Contest.phase_id
    Phase.photo_url = Contest.photo_url
    Phase.photo_md5 = Contest.photo_md5
    Phase.mini_photo_url = Contest.mini_photo_url
    Phase.mini_photo_md5 = Contest.mini_photo_md5
    Phase.total_like_count = 0
    Phase.is_disposable_reward_taken = false
    Phase.total_hot_count = 0
    table.insert(ActivityData.phases, Phase)
  end
end

function PhotoActivityManager:CanRequestContestSubmit()
  local Object = self:GetActivityObject()
  if not Object then
    return false
  end
  local Stage = Object:GetCurrentStage()
  if Stage and Stage == ActivityEnum.TakePhotoCompetitionStage.Preparation then
    return true
  end
  return false
end

function PhotoActivityManager:CanRequestPhotoData(PhotoData)
  if not PhotoData then
    return
  end
  local PhotoInfo = PhotoData:GetPhotoInfo()
  if not PhotoInfo then
    return
  end
  return not PhotoInfo.include_myself and PhotoInfo.pet_base_id_list and next(PhotoInfo.pet_base_id_list)
end

function PhotoActivityManager:GetActivityId()
  local Object = self:GetActivityObject()
  if not Object then
    return 0
  end
  return Object:GetActivityId() or 0
end

function PhotoActivityManager:GetActivitySubId()
  local Object = self:GetActivityObject()
  if not Object then
    return 0
  end
  local ActivityData = Object:GetActivityData()
  return ActivityData and ActivityData.current_phase_id or 0
end

return PhotoActivityManager
