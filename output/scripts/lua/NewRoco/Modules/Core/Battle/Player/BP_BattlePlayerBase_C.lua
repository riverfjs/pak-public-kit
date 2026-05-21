local ENUM_BATTLE_EVENT = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local Base = require("NewRoco.Modules.Core.NPC.BP_PEO_Scene_C")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local UIUtils = require("NewRoco.Utils.UIUtils")
local BP_BattlePlayerBase_C = Base:Extend("BP_BattlePlayerBase_C")

function BP_BattlePlayerBase_C:Ctor()
  self.battlePlayer = nil
  self.AllowToTurn = true
  self.IsCopyLocalPlayer = false
end

function BP_BattlePlayerBase_C:ReceiveBeginPlay()
  self.Overridden.ReceiveBeginPlay(self)
end

function BP_BattlePlayerBase_C:BindBattlePlayer(player)
  self.battlePlayer = player
  self:InitEmoji()
  self:InitializeBattlePlayerSettings()
end

function BP_BattlePlayerBase_C:BindAnimConf()
  if self.AnimConfig then
    self.RocoAnim:SetAnimConfig(self.AnimConfig)
  else
    Log.Error("Animation Config Not Found!!!!!!!!")
  end
end

function BP_BattlePlayerBase_C:InitializeBattlePlayerSettings()
  local MoveComp = self.CharacterMovement
  if MoveComp then
    MoveComp.MaxWalkSpeed = BattleConst.DynamicBattle.PlayerMaxMovementSpeed
  end
end

function BP_BattlePlayerBase_C:DisableFalling()
  if self.CharacterMovement then
    self.CharacterMovement:SetComponentTickEnabled(false)
  end
end

function BP_BattlePlayerBase_C:AddEventListener()
end

function BP_BattlePlayerBase_C:RemoveEventListener()
end

function BP_BattlePlayerBase_C:PlayAnimByType(type, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
  rate = rate or 1
  position = position or 0
  BlendInTime = BlendInTime or 0.25
  BlendOutTime = BlendOutTime or 0.25
  LoopCount = LoopCount or 1
  endPosition = endPosition or 0
  local animName = UE4.RocoEnumUtils.EnumToStringLua("EBattlePlayerAnimType", type)
  if not self.RocoAnim then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150RocoAnim", self:GetName())
    return -1
  end
  return self.RocoAnim:PlayAnimByName(animName, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
end

function BP_BattlePlayerBase_C:PlayAnimByName(animName, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
  rate = rate or 1
  position = position or 0
  BlendInTime = BlendInTime or 0.25
  BlendOutTime = BlendOutTime or 0.25
  LoopCount = LoopCount or 1
  endPosition = endPosition or 0
  if not self.RocoAnim then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150RocoAnim", self:GetName())
    return -1
  end
  return self.RocoAnim:PlayAnimByName(animName, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
end

function BP_BattlePlayerBase_C:OnEndTurn()
end

function BP_BattlePlayerBase_C:OnBattlePlayerDestroyed(player)
  if self.battlePlayer ~= player then
    return
  end
  self:ClearAvatar()
  self.battlePlayer = nil
  if UE4.UObject.IsValid(self) then
    self:K2_DestroyActor()
  end
end

function BP_BattlePlayerBase_C:HurtPlayer(caster)
  local dir = self:Abs_K2_GetActorLocation() - caster:Abs_K2_GetActorLocation()
  dir.Z = 0
  self.Start_Overlap = true
  self.Turn_Alpha = 0
  self:OnOverlap(caster)
end

function BP_BattlePlayerBase_C:InitEmoji()
  self.EmojiWidget:SetHiddenInGame(false)
  self.EmojiUI = self.EmojiWidget:GetUserWidgetObject()
  self.EmojiUI:SetRenderOpacity(0)
end

function BP_BattlePlayerBase_C:ShowThinking(closeTime)
  if self:IsEmojiUIValid() then
    self.EmojiUI:ShowThinking(closeTime)
  end
end

function BP_BattlePlayerBase_C:HideThinking()
  if self:IsEmojiUIValid() and self.EmojiUI:IsShowThinking() then
    self:HideEmoji()
  end
end

function BP_BattlePlayerBase_C:ShowDoubt(closeTime)
  if self:IsEmojiUIValid() then
    self.EmojiUI:ShowDoubt(closeTime)
  end
end

function BP_BattlePlayerBase_C:ShowEmoji(path, teamEnum, closeTime)
  if self:IsEmojiUIValid() then
    self.EmojiUI:ShowEmoji(path, teamEnum, closeTime)
  end
end

function BP_BattlePlayerBase_C:HideEmoji()
  if self:IsEmojiUIValid() then
    self.EmojiUI:Hide()
  end
end

function BP_BattlePlayerBase_C:IsEmojiUIValid()
  return self.EmojiUI and self.EmojiUI:IsValid()
end

function BP_BattlePlayerBase_C:SetDefaultSuit(playerMesh, gender, wearing_items, salonIds, callBack, callBackOwner)
  local defaultSuitClass
  if 2 == gender then
    if NRCEnv:IsLocalMode() then
      defaultSuitClass = UEPath.DEFAULT_AVATAR_SUIT_FEMALE_EDITOR
    else
      defaultSuitClass = UEPath.DEFAULT_AVATAR_SUIT_FEMALE
    end
  elseif NRCEnv:IsLocalMode() then
    defaultSuitClass = UEPath.DEFAULT_AVATAR_SUIT_MALE_EDITOR
  else
    defaultSuitClass = UEPath.DEFAULT_AVATAR_SUIT_MALE
  end
  local salonWearIds = {}
  for i, v in pairs(salonIds or {}) do
    salonWearIds[i] = v.item_wear_id
  end
  if not wearing_items or type(wearing_items) ~= "table" or 0 == #wearing_items then
    Log.Error("BattlePlayerFashion \230\149\176\230\141\174\230\152\175\231\169\186\231\154\132")
  elseif type(wearing_items[1]) ~= "table" then
    Log.Error(string.format("BattlePlayerFashion \230\149\176\230\141\174\229\183\178\230\148\185\230\136\144\231\187\147\230\158\132\228\186\134, \228\184\141\230\152\175" .. type(wearing_items[1])))
  end
  BattleResourceManager:LoadResWithParam(self, defaultSuitClass, self.OnClassLoad, nil, playerMesh, gender, wearing_items, salonWearIds, callBack, callBackOwner)
end

function BP_BattlePlayerBase_C:OnClassLoad(defaultSuitClass, playerMesh, gender, wearing_items, salonIds, callBack, callBackOwner)
  if not UE4.UObject.IsValid(playerMesh) then
    if callBack then
      tcall(callBackOwner, callBack)
    end
    return
  end
  local defaultFashionIds, defaultSalonIds
  local fashionIds = {}
  local wearing_item_values = {}
  if nil == wearing_items or 0 == #wearing_items then
    fashionIds, defaultSalonIds = UIUtils.GetDefaultWearIds(gender)
  else
    for k, v in ipairs(wearing_items) do
      local val = 0
      if type(v) == "table" then
        table.insert(fashionIds, v.wearing_item_id)
        if v.wearing_glass then
          val = (v.wearing_glass.glass_type or 0) << 32 | (v.wearing_glass.glass_value or 0)
        end
      else
        table.insert(fashionIds, v)
      end
      table.insert(wearing_item_values, val)
    end
  end
  if nil == salonIds or 0 == #salonIds then
    defaultFashionIds, salonIds = UIUtils.GetDefaultWearIds(gender)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = gender
  local fullSalonIds = {}
  for k, v in ipairs(salonIds) do
    local SalonItemConf = _G.DataConfigManager:GetSalonItemConf(v, true)
    if SalonItemConf then
      local salonAvatarId = _G.DataConfigManager:GetSalonItemConf(v).avatar_id
      table.insert(fullSalonIds, UIUtils.GetFullSalonId(salonAvatarId, SalonItemConf.texture_id))
    else
      Log.Error("zgx get none", v)
    end
  end
  defaultSuitObj:SetSalons(fullSalonIds)
  for i, v in ipairs(fashionIds) do
    defaultSuitObj:SetBody(v, wearing_item_values[i] or 0)
  end
  self.AvatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  if not self.AvatarSystemOver then
    function self.AvatarSystemOver(system, ID)
      self:SwitchAvatarSuitOver(ID)
    end
  end
  if callBack and self.AvatarSystem.OnSwitchAvatarSuitComplete then
    self.AvatarCallBack = callBack
    self.AvatarCallBackOwner = callBackOwner
    self.AvatarSystem.OnSwitchAvatarSuitComplete:Add(self.AvatarSystem, self.AvatarSystemOver)
  end
  self.AvatarID = self.AvatarSystem:StartSwitchAvatarSuit(playerMesh, defaultSuitObj)
end

function BP_BattlePlayerBase_C:SwitchAvatarSuitOver(ID)
  if ID == self.AvatarID and self.AvatarSystem then
    if self.AvatarCallBack then
      tcall(self.AvatarCallBackOwner, self.AvatarCallBack)
    end
    self:ClearAvatar()
  end
end

function BP_BattlePlayerBase_C:ClearAvatar()
  if self.AvatarSystem and self.AvatarSystemOver then
    self.AvatarSystem.OnSwitchAvatarSuitComplete:Remove(self.AvatarSystem, self.AvatarSystemOver)
  end
  self.AvatarCallBacK = nil
  self.AvatarCallBackOwner = nil
  self.AvatarSystem = nil
  self.AvatarID = nil
  self.AvatarSystemOver = nil
end

function BP_BattlePlayerBase_C:GetCombineBodyType(path)
  local combType = UE4.UAvatarBlueprintFunctionLibrary.GetCombineBodyType(path)
  local MainType, CombinedType = UE4.UAvatarBlueprintFunctionLibrary.ParseCombineBodyTypes(combType)
  local CombinedTypeTable = CombinedType:ToTable()
  return MainType, CombinedTypeTable
end

function BP_BattlePlayerBase_C:OnVisible()
  if self.battlePlayer and self.battlePlayer.battlePlayerComponents then
    self.battlePlayer.battlePlayerComponents:SetClickTip()
  end
end

function BP_BattlePlayerBase_C:OnLoadResource()
  Base.OnLoadResource(self)
  if self.Mesh then
    self.Mesh:SetForcedLOD(BattleEnum.BattleLodModel.Lod0)
  end
end

return BP_BattlePlayerBase_C
