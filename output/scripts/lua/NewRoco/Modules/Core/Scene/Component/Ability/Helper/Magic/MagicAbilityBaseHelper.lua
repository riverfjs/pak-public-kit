local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelper")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MagicAbilityBaseHelper = Base:Extend("MagicAbilityBaseHelper")

function MagicAbilityBaseHelper:Ctor(abilityConfig)
  Base.Ctor(self, abilityConfig)
  self._buffName = "MagicBuff"
  self.magic_type = self.config.add_sub_status
  self.checkBagItem = (_G.DataConfigManager:GetGlobalConfigByKeyType("bag_item_not_enough_ability_button", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num or 1) > 0
end

function MagicAbilityBaseHelper:InitFromConf(inItemId, inMagicId, inAbilityId)
  self.BagItemId = inItemId
  self.MagicId = inMagicId
  self.AbilityId = inAbilityId
end

function MagicAbilityBaseHelper:CanCastAbility(caster)
  if _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.IsMagicBanned, self.magic_type) then
    return AbilityErrorCode.DUNGEON_BAN
  end
  if self.bBannedByArea then
    return AbilityErrorCode.AREA_BAN
  end
  if caster.viewObj == nil then
    return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
  end
  if UE.UObject.IsValid(caster.viewObj.RidePet) then
    local CharMoveComp = caster.viewObj.RidePet.CharacterMovement
    if nil == CharMoveComp or CharMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Walking then
      return AbilityErrorCode.HIGHER_PRIORITY_ABILITY_IS_CASTING
    end
  end
  local buffComp = caster.buffComponent
  if buffComp:HasBuff("ThrowBuff") or buffComp:HasBuff("MagicBuff") then
    return AbilityErrorCode.ABILITY_IS_CASTING
  end
  return Base.CanCastAbility(self, caster)
end

function MagicAbilityBaseHelper:HandleStatus(caster, ...)
  local customParams = ProtoMessage:newPlayerStatusCustomParams()
  local SelectedItemId = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedItemId)
  local BagItem = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, SelectedItemId)
  if nil == BagItem then
    Log.Error("\230\137\190\228\184\141\229\136\176\233\173\148\230\179\149\231\137\169\229\147\129", SelectedItemId)
    return
  end
  customParams.throw_aim_param.throw_ball_id = BagItem.gid
  customParams.throw_aim_param.magic_conf_id = self.MagicId
  Base.HandleStatus(self, caster, customParams, ...)
end

function MagicAbilityBaseHelper:GetBuff(caster)
  local buffComp = caster.buffComponent
  return buffComp:GetBuff(self._buffName)
end

function MagicAbilityBaseHelper:GetBuffName()
  return self._buffName
end

function MagicAbilityBaseHelper:IsBlock(caster)
  local abilityErrorCode = self:CanCastAbility(caster)
  if abilityErrorCode ~= AbilityErrorCode.NO_ERROR then
    return true, abilityErrorCode
  end
  local flag, errorCode = Base.IsBlock(self, caster)
  if not flag and not errorCode then
    if self:CheckMagicCostItemEnough(caster) == AbilityErrorCode.BAG_ITEM_NOT_ENOUGH then
      return true, AbilityErrorCode.BAG_ITEM_NOT_ENOUGH
    end
  else
    return flag, errorCode
  end
  return false
end

function MagicAbilityBaseHelper:GetIcon(caster, isBlock)
  local magicBaseConfig = self:GetMagicBaseConf()
  if self.checkBagItem and magicBaseConfig and magicBaseConfig.cost_bag_item and magicBaseConfig.cost_bag_item[1] and magicBaseConfig.cost_bag_item[2] then
    local costItem = magicBaseConfig.cost_bag_item[1]
    local costNum = magicBaseConfig.cost_bag_item[2]
    local costData = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, costItem)
    local bBagItemEnough = true
    if costData and costData.num then
      if costNum > costData.num then
        bBagItemEnough = false
      end
    else
      bBagItemEnough = false
    end
    if false == bBagItemEnough then
      if self.config.ability_insufficient_icon ~= nil and 0 ~= string.len(self.config.ability_insufficient_icon) then
        return self.config.ability_insufficient_icon
      else
        return self.config.ability_block_icon
      end
    end
  end
  return Base.GetIcon(self, caster, isBlock)
end

function MagicAbilityBaseHelper:GetMagicBaseConf(caster)
  if self.MagicId == nil and nil ~= caster then
    local Id = _G.ProtoEnum.WorldPlayerStatusType.WPST_MAGIC
    local customParams = caster.statusComponent:GetCustomParams(Id)
    self.MagicId = customParams.throw_aim_param.magic_conf_id
  end
  local conf = _G.DataConfigManager:GetMagicBaseConf(self.MagicId)
  if nil == self.AbilityId and conf then
    self.AbilityId = conf.sceneability
  end
  return conf
end

function MagicAbilityBaseHelper:CheckMagicCostItemEnough(caster)
  local magicBaseConfig = self:GetMagicBaseConf()
  if nil ~= magicBaseConfig then
    local vitalityCost = magicBaseConfig.vitality_cost_minimum
    if not caster.vitalityComponent:IsVitalityEnough(vitalityCost) then
      return AbilityErrorCode.VITALITY_NOT_ENOUGH
    end
    if self.checkBagItem and magicBaseConfig.cost_bag_item and magicBaseConfig.cost_bag_item[1] and magicBaseConfig.cost_bag_item[2] then
      local costItem = magicBaseConfig.cost_bag_item[1]
      local costNum = magicBaseConfig.cost_bag_item[2]
      local costData = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, costItem)
      if costData and costData.num then
        if costNum <= costData.num then
          return AbilityErrorCode.NO_ERROR
        else
          return AbilityErrorCode.BAG_ITEM_NOT_ENOUGH
        end
      else
        return AbilityErrorCode.BAG_ITEM_NOT_ENOUGH
      end
    end
  end
  return AbilityErrorCode.NO_ERROR
end

return MagicAbilityBaseHelper
