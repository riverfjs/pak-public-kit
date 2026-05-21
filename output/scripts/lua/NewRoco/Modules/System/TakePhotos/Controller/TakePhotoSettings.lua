local Delegate = require("Utils.Delegate")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local TakePhotoOption = Class("TakePhotoOption")

function TakePhotoOption:Ctor(Name, bEnabled)
  self.Name = Name
  if nil == bEnabled then
    bEnabled = false
  end
  self.InitEnabled = bEnabled
  self.bEnabled = bEnabled
  self:Toggle(bEnabled)
  self.OnValueChanged = Delegate()
end

function TakePhotoOption:Reset(bClearEvents)
  if bClearEvents then
    self.OnValueChanged:Clear()
  end
  self:Toggle(self.InitEnabled)
end

function TakePhotoOption:Toggle(bEnable)
  local Old = self.bEnabled
  if nil == bEnable then
    self.bEnabled = not self.bEnabled
  else
    self.bEnabled = bEnable
  end
  if Old ~= self.bEnabled then
    self.OnValueChanged:Invoke(self.bEnabled)
  end
end

function TakePhotoOption:IsEnabled()
  return self.bEnabled
end

local TakePhotoGroupOption = Class("TakePhotoGroupOption")

function TakePhotoGroupOption:Ctor(OptionList, InitIndex)
  InitIndex = InitIndex or 1
  self.OptionList = OptionList
  self.InitIndex = InitIndex
  self.CurrentIdx = 0
  self.OnOptionChanged = Delegate()
  self:Toggle(InitIndex)
end

function TakePhotoGroupOption:Reset(bClearEvents)
  if bClearEvents then
    self.OnOptionChanged:Clear()
  end
  self:Toggle(self.InitIndex)
end

function TakePhotoGroupOption:Toggle(Index)
  if Index and self.CurrentIdx ~= Index and self.OptionList[Index] then
    local Old = self.CurrentIdx
    self.CurrentIdx = Index
    local OldOption = 0 ~= Old and self.OptionList[Old]
    local NewOption = self:GetSelectedOption()
    if OldOption then
      OldOption:Toggle(false)
    end
    NewOption:Toggle(true)
    self.OnOptionChanged:Invoke(NewOption, OldOption)
    return true
  end
end

function TakePhotoGroupOption:SetSelectOption(Option)
  for i, v in ipairs(self.OptionList) do
    if v == Option then
      self:Toggle(i)
    end
  end
end

function TakePhotoGroupOption:GetSelectedIndex()
  return self.CurrentIdx
end

function TakePhotoGroupOption:GetSelectedOption()
  return self.OptionList[self.CurrentIdx]
end

local TakePhotoProgress = Class("TakePhotoProgress")

function TakePhotoProgress:Ctor(MiniValue, MaxiValue, InitValue)
  self.Value = InitValue or 0
  self.MaxiValue = MaxiValue
  self.MiniValue = MiniValue
  assert(self.Value >= self.MiniValue)
  assert(self.Value <= self.MaxiValue)
  self.InitValue = self.Value
  self.ProgressBar = nil
  self.LocatorSlider = nil
  self.OnValueChanged = Delegate()
end

function TakePhotoProgress:Reset(bClearEvents)
  if bClearEvents then
    self:UnBind()
  end
  self:SetValue(self.InitValue)
end

function TakePhotoProgress:UnBind()
  if self.LocatorSlider and UE.UObject.IsValid(self.LocatorSlider) then
    self.LocatorSlider.OnValueChanged:Clear()
  end
  self.ProgressBar = nil
  self.LocatorSlider = nil
end

function TakePhotoProgress:SetValue(Value, bNotSyncSlider)
  if math.abs(Value - self.Value) > 0.001 then
    self.Value = Value
    self:InternalUpdateProgress(bNotSyncSlider)
    self.OnValueChanged:Invoke(self.Value)
  end
end

function TakePhotoProgress:GetPercent()
  if self.MaxiValue == self.MiniValue then
    return 1
  end
  return math.clamp((self.Value - self.MiniValue) / (self.MaxiValue - self.MiniValue), 0, 1)
end

function TakePhotoProgress:GetValue()
  return self.Value
end

function TakePhotoProgress:BindProgressBar(Panel, ProgressBar, LocatorSlider)
  self.ProgressBar = ProgressBar
  self.LocatorSlider = LocatorSlider
  self.LocatorSlider:SetMinValue(self.MiniValue)
  self.LocatorSlider:SetMaxValue(self.MaxiValue)
  self.LocatorSlider.OnValueChanged:Add(Panel, function(_, Value)
    self:SetValue(Value, true)
  end)
  self:InternalUpdateProgress()
end

function TakePhotoProgress:InternalUpdateProgress(bNotSyncSlider)
  if self.ProgressBar then
    self.ProgressBar:SetPercent(self:GetPercent())
    if not bNotSyncSlider then
      self.LocatorSlider:SetValue(self.Value)
    end
  end
end

local TakePhotoBidirectionalProgress = Class("TakePhotoBidirectionalProgress")

function TakePhotoBidirectionalProgress:Ctor(MiniValue, MaxiValue, ZeroValue, InitValue)
  self.Value = InitValue or 0
  self.InitValue = self.Value
  self.MaxiValue = MaxiValue
  self.MiniValue = MiniValue
  self.ZeroValue = ZeroValue
  assert(ZeroValue >= self.MiniValue)
  assert(ZeroValue <= self.MaxiValue)
  local ValueBounds = self.MaxiValue - self.MiniValue
  self.LeftAmountPercent = (self.ZeroValue - self.MiniValue) / ValueBounds
  self.RightAmountPercent = (self.MaxiValue - self.ZeroValue) / ValueBounds
  self.MaxiAmount = nil
  self.ProgressBar = nil
  self.LocatorSlider = nil
  self.OnValueChanged = Delegate()
end

function TakePhotoBidirectionalProgress:Reset(bClearEvents)
  if bClearEvents then
    self:UnBind()
  end
  self:SetValue(self.InitValue)
end

function TakePhotoBidirectionalProgress:UnBind()
  if self.LocatorSlider and UE.UObject.IsValid(self.LocatorSlider) then
    self.LocatorSlider.OnValueChanged:Clear()
  end
  self.ProgressBar = nil
  self.LocatorSlider = nil
end

function TakePhotoBidirectionalProgress:SetValue(Value, bNotSyncSlider)
  if math.abs(Value - self.Value) > 0.001 then
    self.Value = Value
    self:InternalUpdateProgress(bNotSyncSlider)
    self.OnValueChanged:Invoke(self.Value)
  end
end

function TakePhotoBidirectionalProgress:GetPercent()
  return math.clamp(self.Value / (self.MaxiValue - self.MiniValue + 1.0E-6), 0, 1)
end

function TakePhotoBidirectionalProgress:GetValue()
  return self.Value
end

function TakePhotoBidirectionalProgress:BindProgressBar(Panel, ProgressBar, LocatorSlider, MaxiAmount)
  self.MaxiAmount = MaxiAmount
  self.ProgressBar = ProgressBar
  self.LocatorSlider = LocatorSlider
  self.ProgressBar:SetPercent(0.5)
  self.LocatorSlider:SetMinValue(self.MiniValue)
  self.LocatorSlider:SetMaxValue(self.MaxiValue)
  self.LocatorSlider.OnValueChanged:Add(Panel, function(_, Value)
    self:SetValue(Value, true)
  end)
  self:InternalUpdateProgress()
end

function TakePhotoBidirectionalProgress:InternalUpdateProgress(bNotSyncSlider)
  local CanvasSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ProgressBar)
  if not CanvasSlot then
    return
  end
  local Offsets = CanvasSlot:GetOffsets()
  local LeftMaxiAmount = self.LeftAmountPercent * self.MaxiAmount
  local RightMaxiAmount = self.RightAmountPercent * self.MaxiAmount
  local ExtentAmount = 0
  if self.ZeroValue < self.Value then
    local Percent = (self.Value - self.ZeroValue) / (self.MaxiValue - self.ZeroValue)
    ExtentAmount = Percent * RightMaxiAmount
    self.ProgressBar:SetBarFillType(UE.EProgressBarExFillType.RightToLeft)
  elseif self.ZeroValue > self.Value then
    local Percent = (self.ZeroValue - self.Value) / (self.ZeroValue - self.MiniValue)
    ExtentAmount = Percent * LeftMaxiAmount
    self.ProgressBar:SetBarFillType(UE.EProgressBarExFillType.LeftToRight)
  end
  Offsets.Left = LeftMaxiAmount - ExtentAmount
  Offsets.Right = RightMaxiAmount - ExtentAmount
  CanvasSlot:SetOffsets(Offsets)
  if not bNotSyncSlider then
    self.LocatorSlider:SetValue(self.Value)
  end
end

local TakePhotoBidirectionalProgress2 = Class("TakePhotoBidirectionalProgress2")

function TakePhotoBidirectionalProgress2:Ctor(MiniValue, MaxiValue, ZeroValue, InitValue)
  self.Value = InitValue or 0
  self.InitValue = self.Value
  self.MaxiValue = MaxiValue
  self.MiniValue = MiniValue
  self.ZeroValue = ZeroValue
  self.LeftProgressBar = nil
  self.RightProgressBar = nil
  self.LocatorSlider = nil
  self.OnValueChanged = Delegate()
end

function TakePhotoBidirectionalProgress2:Reset(bClearEvents)
  if bClearEvents then
    self:UnBind()
  end
  self:SetValue(self.InitValue)
end

function TakePhotoBidirectionalProgress2:UnBind()
  if self.LocatorSlider and UE.UObject.IsValid(self.LocatorSlider) then
    self.LocatorSlider.OnValueChanged:Clear()
  end
  self.LeftProgressBar = nil
  self.RightProgressBar = nil
  self.LocatorSlider = nil
end

function TakePhotoBidirectionalProgress2:SetValue(Value, bNotSyncSlider)
  if math.abs(Value - self.Value) > 0.001 then
    self.Value = Value
    self:InternalUpdateProgress(bNotSyncSlider)
    self.OnValueChanged:Invoke(self.Value)
  end
end

function TakePhotoBidirectionalProgress2:GetPercent()
  return math.clamp(self.Value / (self.MaxiValue - self.MiniValue + 1.0E-6), 0, 1)
end

function TakePhotoBidirectionalProgress2:GetValue()
  return self.Value
end

function TakePhotoBidirectionalProgress2:BindProgressBar(Panel, LeftProgressBar, RightProgressBar, LocatorSlider)
  self.LeftProgressBar = LeftProgressBar
  self.RightProgressBar = RightProgressBar
  self.LocatorSlider = LocatorSlider
  self.LocatorSlider:SetMinValue(self.MiniValue)
  self.LocatorSlider:SetMaxValue(self.MaxiValue)
  self.LocatorSlider:SetValue(self.Value)
  self.LocatorSlider.OnValueChanged:Add(Panel, function(_, Value)
    self:SetValue(Value, true)
  end)
  self:InternalUpdateProgress()
end

function TakePhotoBidirectionalProgress2:InternalUpdateProgress(bNotSyncSlider)
  if not self.LeftProgressBar then
    return
  end
  if self.ZeroValue < self.Value then
    local Percent = (self.Value - self.ZeroValue) / (self.MaxiValue - self.ZeroValue)
    self.LeftProgressBar:SetPercent(0)
    self.RightProgressBar:SetPercent(Percent)
  elseif self.ZeroValue > self.Value then
    local Percent = (self.ZeroValue - self.Value) / (self.ZeroValue - self.MiniValue)
    self.LeftProgressBar:SetPercent(Percent)
    self.RightProgressBar:SetPercent(0)
  else
    self.LeftProgressBar:SetPercent(0)
    self.RightProgressBar:SetPercent(0)
  end
  if not bNotSyncSlider then
    self.LocatorSlider:SetValue(self.Value)
  end
end

local TakePhotoSettings = Class("TakePhotoSettings")

function TakePhotoSettings:Ctor()
  self.CountDownGroup = self:InitCreateCountDownOptions()
  self.BurstGroup = self:InitCreateBurstOptions()
  self.PlayerLookCamera = TakePhotoOption("", true)
  self.PetLookCamera = TakePhotoOption("", true)
  self.CameraRollProgress = self:InitCreateCameraRollProgress()
  self.FilterGroup = self:InitCreateFilterOptions()
  self.ActionGroup = self:InitCreateActionOptions()
  self.ActionMirror = TakePhotoOption()
  self.EmojiGroup = self:InitCreateEmojiOptions()
  self.FashionGroup = self:InitFashionGroup()
  self.CameraSkinGroup = self:InitCameraSkinGroup()
  self:InitFocalRegionSetting()
end

function TakePhotoSettings:Reset(bClearEvents)
  self.CountDownGroup:Reset(bClearEvents)
  self.BurstGroup:Reset(bClearEvents)
  self.PlayerLookCamera:Reset(bClearEvents)
  self.PetLookCamera:Reset(bClearEvents)
  self.CameraRollProgress:Reset(bClearEvents)
  self.FilterGroup:Reset(bClearEvents)
  self.ActionGroup:Reset(bClearEvents)
  self.ActionMirror:Reset(bClearEvents)
  self.EmojiGroup:Reset(bClearEvents)
  self.FashionGroup:Reset(bClearEvents)
  self.FashionGroup = self:InitFashionGroup()
  for i, Option in ipairs(self.FilterGroup.OptionList) do
    local CustomData = Option.CustomData
    if CustomData then
      local Progress = CustomData.BlendProgress
      if Progress then
        Progress:Reset(bClearEvents)
      end
    end
  end
end

function TakePhotoSettings:ResetCamera()
  self.CameraRollProgress:Reset(false)
end

function TakePhotoSettings:InitCameraSkinGroup()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local CameraInfo = player.serverData.camera_info
  local SkinList = CameraInfo and CameraInfo.unlock_skin_ids or {}
  local CurrentSkinId = CameraInfo and CameraInfo.skin_id or 0
  local TempSkinList = {}
  local TempSkinMap = {}
  for i, v in ipairs(SkinList) do
    TempSkinList[i] = v
    TempSkinMap[v] = true
  end
  table.sort(TempSkinList, function(a, b)
    return a < b
  end)
  local OptionsList = {}
  local AllData = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.CAMERA_SKIN_CONF) or {}
  for i, Data in pairs(AllData) do
    if Data.is_initial and not TempSkinMap[Data.id] then
      local Option = TakePhotoOption("")
      table.insert(OptionsList, Option)
      Option.CustomData = {
        SkinId = Data.id,
        SkinConf = Data
      }
    end
  end
  local InitIndex = 1
  for i, SkinId in ipairs(TempSkinList) do
    local Option = TakePhotoOption("")
    table.insert(OptionsList, Option)
    Option.CustomData = {
      SkinId = SkinId,
      SkinConf = _G.DataConfigManager:GetCameraSkinConf(SkinId, true)
    }
    if CurrentSkinId == SkinId then
      InitIndex = #OptionsList
    end
  end
  return TakePhotoGroupOption(OptionsList, InitIndex)
end

function TakePhotoSettings:InitFashionGroup()
  local DataList = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetRolePlayData, RolePlayModuleDef.RolePlayType.Suit) or {}
  local indexToRemove = {}
  for k, v in ipairs(DataList) do
    if v.suitType == "allCollect" then
      table.insert(indexToRemove, k)
    end
  end
  table.sort(indexToRemove)
  for i = #indexToRemove, 1, -1 do
    local idx = indexToRemove[i]
    table.remove(DataList, idx)
  end
  local OptionsList = {}
  local FashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo() or {}
  local current_wardrobe_index = FashionInfo.current_wardrobe_index or 0
  local WardrobeIndex = current_wardrobe_index + 1
  local CurrentIndex = 0
  Log.Debug("[TakePhoto] Fashion Num", #DataList, WardrobeIndex)
  for i, Data in ipairs(DataList) do
    local Option = TakePhotoOption("")
    table.insert(OptionsList, Option)
    Option.CustomData = {FashionRolePlayItem = Data}
    if Data.wardrobeIndex == WardrobeIndex then
      CurrentIndex = i
    end
  end
  return TakePhotoGroupOption(OptionsList, CurrentIndex)
end

function TakePhotoSettings:InitCreateActionOptions()
  local TAKE_PHOTO_POSE_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TAKE_PHOTO_POSE_CONF):GetAllDatas()
  local ConfList = {}
  for i, v in pairs(TAKE_PHOTO_POSE_CONF) do
    table.insert(ConfList, v)
  end
  table.sort(ConfList, function(a, b)
    return a.id < b.id
  end)
  Log.Debug("[TakePhoto] Pose Num", #ConfList)
  local OptionsList = {}
  for i, Conf in ipairs(ConfList) do
    local Option = TakePhotoOption("")
    table.insert(OptionsList, Option)
    Option.CustomData = {PoseConf = Conf}
  end
  return TakePhotoGroupOption(OptionsList)
end

function TakePhotoSettings:InitCreateEmojiOptions()
  local TAKE_PHOTO_EMOJI_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TAKE_PHOTO_EMOJI_CONF):GetAllDatas()
  local ConfList = {}
  for i, v in pairs(TAKE_PHOTO_EMOJI_CONF) do
    table.insert(ConfList, v)
  end
  table.sort(ConfList, function(a, b)
    return a.id < b.id
  end)
  Log.Debug("[TakePhoto] Emoji Num", #ConfList)
  local OptionsList = {}
  for i, Conf in ipairs(ConfList) do
    local Option = TakePhotoOption("")
    table.insert(OptionsList, Option)
    Option.CustomData = {EmojiConf = Conf}
  end
  return TakePhotoGroupOption(OptionsList)
end

function TakePhotoSettings:InitCreateFilterOptions()
  local TAKE_PHOTO_FILTER_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.TAKE_PHOTO_FILTER_CONF):GetAllDatas()
  local ConfList = {}
  for i, v in pairs(TAKE_PHOTO_FILTER_CONF) do
    table.insert(ConfList, v)
  end
  table.sort(ConfList, function(a, b)
    return a.id < b.id
  end)
  Log.Debug("[TakePhoto] Filter Num", #ConfList)
  local OptionsList = {}
  for i, FilterConf in ipairs(ConfList) do
    local Option = TakePhotoOption("")
    table.insert(OptionsList, Option)
    Option.CustomData = {FilterConf = FilterConf}
    if "" ~= (FilterConf.filter_path or "") then
      Option.CustomData.BlendProgress = TakePhotoProgress(0, 1, 0.5)
    end
  end
  return TakePhotoGroupOption(OptionsList)
end

function TakePhotoSettings:InitCreateCameraRollProgress()
  local Angle = TakePhotosEnum.TPGlobalNumList("takephoto_slant_angle", {-60, 60})
  return TakePhotoBidirectionalProgress2(Angle[1], Angle[2], 0, 0)
end

function TakePhotoSettings:InitCreateCountDownOptions()
  local Unit = LuaText.take_photo_second
  local SecondsList = TakePhotosEnum.TPGlobalNumList("takephoto_countdown", {})
  local OptionsList = {}
  table.insert(OptionsList, TakePhotoOption(LuaText.take_photo_close))
  for i, Seconds in ipairs(SecondsList) do
    if 0 ~= Seconds then
      local Option = TakePhotoOption(string.format(Unit, Seconds))
      table.insert(OptionsList, Option)
      Option.CustomData = {DelaySeconds = Seconds}
    end
  end
  return TakePhotoGroupOption(OptionsList)
end

function TakePhotoSettings:InitCreateBurstOptions()
  local Unit = LuaText.take_photo_unit
  local NumbersList = TakePhotosEnum.TPGlobalNumList("takephoto_burst_num", {})
  local OptionsList = {}
  table.insert(OptionsList, TakePhotoOption(LuaText.take_photo_close))
  for i, Number in ipairs(NumbersList) do
    if 0 ~= Number then
      local Option = TakePhotoOption(string.format(Unit, Number))
      table.insert(OptionsList, Option)
      Option.CustomData = {BurstNumber = Number}
    end
  end
  return TakePhotoGroupOption(OptionsList)
end

function TakePhotoSettings:CreateCountDownGroupUIDataList()
  local UIDataList = {}
  for i, o in ipairs(self.CountDownGroup.OptionList) do
    local Data = {
      Name = o.Name,
      OnClicked = function()
        self.CountDownGroup:Toggle(i)
      end,
      IsSelected = function()
        return self.CountDownGroup:GetSelectedIndex() == i
      end
    }
    table.insert(UIDataList, Data)
  end
  return UIDataList
end

function TakePhotoSettings:CreateBurstGroupUIDataList()
  local UIDataList = {}
  for i, o in ipairs(self.BurstGroup.OptionList) do
    local Data = {
      Name = o.Name,
      OnClicked = function()
        self.BurstGroup:Toggle(i)
      end,
      IsSelected = function()
        return self.BurstGroup:GetSelectedIndex() == i
      end
    }
    table.insert(UIDataList, Data)
  end
  return UIDataList
end

function TakePhotoSettings:CreateFilterGroupUIDataList()
  local UIDataList = {}
  for i, o in ipairs(self.FilterGroup.OptionList) do
    local Data = {
      FilterConf = o.CustomData and o.CustomData.FilterConf,
      OnClicked = function()
        self.FilterGroup:Toggle(i)
      end,
      IsSelected = function()
        return self.FilterGroup:GetSelectedIndex() == i
      end
    }
    table.insert(UIDataList, Data)
  end
  return UIDataList
end

function TakePhotoSettings:CreatePoseActionGroupUIDataList()
  local UIDataList = {}
  for i, o in ipairs(self.ActionGroup.OptionList) do
    local Data = {
      PoseConf = o.CustomData and o.CustomData.PoseConf,
      OnClicked = function()
        self.ActionGroup:Toggle(i)
      end,
      IsSelected = function()
        return self.ActionGroup:GetSelectedIndex() == i
      end
    }
    table.insert(UIDataList, Data)
  end
  return UIDataList
end

function TakePhotoSettings:GetSelectedPoseId()
  local Option = self.ActionGroup:GetSelectedOption()
  if Option then
    local Conf = Option.CustomData and Option.CustomData.PoseConf
    return Conf and Conf.id
  end
end

function TakePhotoSettings:GetSelectedEmojiId()
  local Option = self.ActionGroup:GetSelectedOption()
  if Option then
    local Conf = Option.CustomData and Option.CustomData.EmojiConf
    return Conf and Conf.id
  end
end

function TakePhotoSettings:GetSelectedFilterId()
  local Option = self.FilterGroup:GetSelectedOption()
  if Option then
    local Conf = Option.CustomData and Option.CustomData.FilterConf
    return Conf and Conf.id
  end
end

function TakePhotoSettings:CreateEmojiGroupUIDataList()
  local UIDataList = {}
  for i, o in ipairs(self.EmojiGroup.OptionList) do
    local Data = {
      EmojiConf = o.CustomData and o.CustomData.EmojiConf,
      OnClicked = function()
        self.EmojiGroup:Toggle(i)
      end,
      IsSelected = function()
        return self.EmojiGroup:GetSelectedIndex() == i
      end
    }
    table.insert(UIDataList, Data)
  end
  return UIDataList
end

function TakePhotoSettings:CreateFashionGroupUIDataList()
  local UIDataList = {}
  for i, o in ipairs(self.FashionGroup.OptionList) do
    local Data = {
      FashionRolePlayItem = o.CustomData and o.CustomData.FashionRolePlayItem,
      OnClicked = function()
        self.FashionGroup:Toggle(i)
      end,
      IsSelected = function()
        return self.FashionGroup:GetSelectedIndex() == i
      end
    }
    table.insert(UIDataList, Data)
  end
  return UIDataList
end

function TakePhotoSettings:CreateCameraSkinGroupUIDataList()
  local UIDataList = {}
  for i, o in ipairs(self.CameraSkinGroup.OptionList) do
    local SkinId = o.CustomData and o.CustomData.SkinId
    local SkinConf = o.CustomData and o.CustomData.SkinConf
    local Data = {
      SkinId = SkinId,
      SkinConf = SkinConf,
      OnClicked = function()
        if self.CameraSkinGroup:Toggle(i) then
          _G.NRCAudioManager:PlaySound2DAuto(40007001, "CameraSkinChanged")
          _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.ReqChangeCameraTexture, SkinId)
        end
      end,
      IsSelected = function()
        return self.CameraSkinGroup:GetSelectedIndex() == i
      end,
      RedDotKey = 494,
      RedDotExtraKey = {SkinId}
    }
    table.insert(UIDataList, Data)
  end
  return UIDataList
end

function TakePhotoSettings:RemoveCameraSkinRedDots()
  Log.Debug("TakePhotoSettings:RemoveCameraSkinRedDots()")
  local RedDotKey = 494
  for i, o in ipairs(self.CameraSkinGroup.OptionList) do
    local SkinId = o.CustomData and o.CustomData.SkinId
    local ExtraKey = {SkinId}
    local bRed = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.IsRedPointLightUp, RedDotKey, ExtraKey)
    if bRed then
      _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, RedDotKey, ExtraKey)
      Log.Debug("TakePhotoSettings:RemoveCameraSkinRedDots()", SkinId)
    end
  end
end

function TakePhotoSettings:GetTakePhotoBurstNum()
  local CustomData = self.BurstGroup:GetSelectedOption().CustomData
  if CustomData then
    return CustomData.BurstNumber or 0
  end
  return 0
end

function TakePhotoSettings:GetTakePhotoCountDownSeconds()
  local CustomData = self.CountDownGroup:GetSelectedOption().CustomData
  if CustomData then
    return CustomData.DelaySeconds or 0
  end
  return 0
end

function TakePhotoSettings:InitFocalRegionSetting()
  local Blur = TakePhotosEnum.TPGlobalNum("takephoto_blur", 10000) / 10000
  local MiniBlur = TakePhotosEnum.TPGlobalNum("takephoto_blur_min", 1000) / 10000
  local FocalDistance = TakePhotosEnum.TPGlobalNum("takephoto_focal_distance", 20000)
  local BlurDefault = TakePhotosEnum.TPGlobalNum("takephoto_blur_default", 0) / 10000
  local FocalDistanceDefault = TakePhotosEnum.TPGlobalNum("takephoto_focal_distance_default", 0)
  self.FocalScaleProgress = TakePhotoProgress(MiniBlur, Blur, BlurDefault)
  self.FocalRegionProgress = TakePhotoProgress(0, FocalDistance, FocalDistanceDefault)
end

return TakePhotoSettings
