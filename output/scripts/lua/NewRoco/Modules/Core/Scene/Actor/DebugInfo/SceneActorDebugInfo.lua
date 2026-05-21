local function RegionClass(RegionName, Parent)
  local cls = {}
  
  if Parent then
    setmetatable(cls, {__index = Parent})
  else
    setmetatable(cls, {__index = cls})
  end
  cls.regionName = RegionName
  cls.Super = Parent
  return cls
end

local function newRegion(regionClass, inDebugInfoInst)
  local region = table.new(0, 4)
  setmetatable(region, {__index = regionClass})
  region.debugInfoInst = inDebugInfoInst
  region.Super.Init(region)
  region:Init()
  return region
end

local DebugRegionBase = RegionClass("DebugRegionBase")

function DebugRegionBase:Init()
end

function DebugRegionBase:GetDebugString()
  return "None"
end

function DebugRegionBase:GetTitle()
  return self.title or self.regionName
end

function DebugRegionBase:CheckCanBeShow()
  if GlobalConfig.ActorDebugInfoRegions[self.regionName].show then
    return true
  end
  return false
end

function DebugRegionBase:CanBeShow()
  return true
end

function DebugRegionBase:IsLocalPlayer()
  local sceneActor = self.debugInfoInst.owner
  if not sceneActor then
    return false
  end
  if sceneActor.isLocal then
    return true
  end
  return false
end

local DebugRegionCommon = RegionClass("DebugRegionCommon", DebugRegionBase)
DebugRegionCommon.className = "None"

function DebugRegionCommon:GetDebugString()
  local sceneActor = self.debugInfoInst.owner
  if not sceneActor then
    return "No SceneActor"
  end
  local stringFormat = "Class Name: %s"
  return string.format(stringFormat, sceneActor.className)
end

function DebugRegionCommon:Init()
  self.title = "\229\159\186\230\156\172\228\191\161\230\129\175"
end

local DebugRegionBuff = RegionClass("DebugRegionBuff", DebugRegionBase)

function DebugRegionBuff:GetDebugString()
  local sceneActor = self.debugInfoInst.owner
  if not sceneActor then
    return "No SceneActor"
  end
  local buffComp = sceneActor.buffComponent
  if not buffComp then
    return "No BuffComponent"
  end
  if not buffComp._buffTable then
    return "No Buff Table"
  end
  local stringFormat = "Buff Count: %d\n"
  local buffnum = 0
  for name, buff in pairs(buffComp._buffTable) do
    stringFormat = stringFormat .. name .. "\n"
    buffnum = buffnum + 1
  end
  stringFormat = string.format(stringFormat, buffnum)
  return stringFormat
end

function DebugRegionBuff:CanBeShow()
  return self:IsLocalPlayer()
end

function DebugRegionBuff:Init()
  self.title = "Buff\228\191\161\230\129\175"
end

local DebugRegionSocialComponent = RegionClass("DebugRegionSocialComponent", DebugRegionBase)
DebugRegionSocialComponent.buffList = {}

function DebugRegionSocialComponent:GetDebugString()
  local sceneActor = self.debugInfoInst.owner
  if not sceneActor then
    return "No SceneActor"
  end
  local socialComp = sceneActor:GetComponent(require("NewRoco.Modules.Core.Scene.Component.Social.SocialComponent"))
  if not socialComp then
    return "No SocialComponent"
  end
  local stringFormat = [[
CurVitalityRecoverStage: %s
IsMaster: %s
TriggerFriendID: %s
MateID: %s
]]
  stringFormat = string.format(stringFormat, socialComp:GetCurVitalityRecoverStageName(), socialComp.bIsMaster and "true" or "false", tostring(socialComp.triggerFriendID), tostring(socialComp.mateID))
  local friendCount = 0
  for friendId, player in pairs(socialComp.friendList) do
    if 0 == friendCount then
      stringFormat = stringFormat .. "Friends:\n"
    end
    friendCount = friendCount + 1
    local name = player.serverData and player.serverData.base.name or player.name
    stringFormat = stringFormat .. string.format("  FriendId: %d, Name: %s\n", friendId, name)
  end
  local strangerCount = 0
  for strangerId, player in pairs(socialComp.strangerList) do
    if 0 == strangerCount then
      stringFormat = stringFormat .. "Strangers:\n"
    end
    strangerCount = strangerCount + 1
    local name = player.serverData and player.serverData.base.name or player.name
    stringFormat = stringFormat .. string.format("  StrangerId: %d, Name: %s\n", strangerId, name)
  end
  return stringFormat
end

function DebugRegionSocialComponent:CanBeShow()
  return self:IsLocalPlayer()
end

function DebugRegionSocialComponent:Init()
  self.title = "\232\180\180\232\180\180\228\191\161\230\129\175"
end

local DebugRegionStatus = RegionClass("DebugRegionStatus", DebugRegionBase)

local function GetStatusNameFunc(status)
  for Key, Value in pairs(ProtoEnum.WorldPlayerStatusType) do
    if status == Value then
      local finalStr = Key
      finalStr = string.gsub(finalStr, "WPST_", "")
      return finalStr
    end
  end
end

function DebugRegionStatus:GetDebugString()
  local sceneActor = self.debugInfoInst.owner
  if not sceneActor then
    return "No SceneActor"
  end
  local statusComp = sceneActor.statusComponent
  if not statusComp then
    return "No StatusComponent"
  end
  local stringFormat = "Status Count: %d\n"
  local statusnum = 0
  for status, subStatus in pairs(statusComp._statusDic) do
    stringFormat = stringFormat .. string.format("  Status: %s, SubStatus: %d\n", GetStatusNameFunc(status), subStatus)
    statusnum = statusnum + 1
  end
  stringFormat = string.format(stringFormat, statusnum)
  return stringFormat
end

function DebugRegionStatus:Init()
  self.title = "Status\228\191\161\230\129\175"
end

local SceneActorDebugInfo = {}
setmetatable(SceneActorDebugInfo, {__index = SceneActorDebugInfo})

function SceneActorDebugInfo.new(inSenceActor)
  local self = table.new(0, 4)
  setmetatable(self, {__index = SceneActorDebugInfo})
  self.owner = inSenceActor
  self:Init()
  return self
end

function SceneActorDebugInfo:Init()
  self.regionList = {
    commonRegion = newRegion(DebugRegionCommon, self),
    buffRegion = newRegion(DebugRegionBuff, self),
    socialComponentRegion = newRegion(DebugRegionSocialComponent, self),
    statusRegion = newRegion(DebugRegionStatus, self)
  }
end

function SceneActorDebugInfo:GetRegion(regionName)
  local region = self.regionList[regionName] or self.regionList[regionName .. "Region"] or self.regionList[string.lower(regionName)] or self.regionList[string.lower(regionName) .. "Region"]
  if region then
    return region
  end
  Log.Error(string.format("SceneActorDebugInfo.GetRegion \230\156\170\230\137\190\229\136\176\229\175\185\229\186\148Region: %s", regionName))
  return nil
end

local function AddRegionDebugString(s, region)
  s = s .. [[

------- ]] .. region:GetTitle() .. " -------\n"
  s = s .. region:GetDebugString()
  return s
end

function SceneActorDebugInfo:GetDebugString()
  local result = ""
  local commonRegionName = "commonRegion"
  local commonRegion = self:GetRegion(commonRegionName)
  if commonRegion and commonRegion:CheckCanBeShow() then
    result = AddRegionDebugString(result, commonRegion)
  end
  for name, region in pairs(self.regionList) do
    if name == commonRegionName then
    elseif not region.CheckCanBeShow or not region:CheckCanBeShow() then
    else
      result = AddRegionDebugString(result, region)
    end
  end
  return result
end

function GetActorDebugInfoPannel(SceneActor)
  if not (SceneActor and SceneActor.debugInfo) or not SceneActor.viewObj then
    return nil
  end
  if SceneActor.debugInfoPanel then
    return SceneActor.debugInfoPanel
  end
  local compPath = "/Game/NewRoco/Modules/System/Debug/Res/ActorDebugInfo/BP_ActorDebugInfoPannelComponent.BP_ActorDebugInfoPannelComponent"
  return SceneActor.debugInfo:GetDebugString()
end

function SceneActorDebugInfo:DrawDebugInfo(DeltaTime)
  if GlobalConfig.DebugShowActorDebugInfo then
    if not self.owner then
      return
    end
    local viewObj = self.owner.viewObj
    if not viewObj or not UE4.UObject.IsValid(viewObj) then
      return
    end
    local debugString = self:GetDebugString()
    local World = _G.UE4Helper.GetCurrentWorld()
    local actorLocation = viewObj:K2_GetActorLocation()
    local adjustHeight = 180
    if self.owner.isLocal and self.owner:GetUEController() and self.owner:GetUEController().PlayerCameraManager then
      local cameraLoc = self.owner:GetUEController().PlayerCameraManager:GetCameraLocation()
      local dis = UE.UKismetMathLibrary.Vector_Distance(cameraLoc, actorLocation)
      adjustHeight = dis * 0.4
      adjustHeight = math.clamp(adjustHeight, 120, 200)
    end
    local textLoc = actorLocation + UE4.FVector(0, 0, adjustHeight)
    UE4.UKismetSystemLibrary.DrawDebugString(viewObj, textLoc, debugString, nil, UE4.FLinearColor(1, 1, 1, 1), 0)
  end
end

return SceneActorDebugInfo
