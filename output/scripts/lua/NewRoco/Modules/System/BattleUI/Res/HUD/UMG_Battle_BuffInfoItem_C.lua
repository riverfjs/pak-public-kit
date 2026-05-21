require("UnLuaEx")
local Enum = reload("Data.Config.Enum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local Base = require("NewRoco.TUI.BP_ScrollViewItemBase_C")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local ProtoEnum = require("Data.PB.ProtoEnum")
local UMG_Battle_BuffInfoItem_C = NRCUmgClass:Extend("")

function UMG_Battle_BuffInfoItem_C:UpdateBuffInoItem(buffInfoBox, buff)
  local buffConfig
  if buff then
    buffConfig = _G.DataConfigManager:GetBuffConf(buff.id)
  else
    buffConfig = nil
  end
  self.imageEmpty:SetVisibility(UE4.ESlateVisibility.Hidden)
  if buff and buffConfig then
    self.buffIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.buffIcon:SetPath(buffConfig.icon)
    self.textBuffName:SetText(buffConfig.name)
    local desc = self:UpdateBuffDesc(buffConfig.desc, buff)
    self.textBuffDesc:SetText(desc)
    if 0 == buff.stack or 1 == buff.stack then
      self.textBuffStack:SetText("")
    else
      self.textBuffStack:SetText(buff.stack)
    end
    local type_id = buffConfig.type_id
    local BuffTypeConf
    if type_id then
      local typeId = tonumber(type_id)
      if not typeId then
        Log.Error("BUFF\231\155\184\229\133\179\233\133\141\231\189\174\233\148\153\232\175\175\239\188\140buffId=", buff.id, "type_id=", type_id)
      end
      BuffTypeConf = _G.DataConfigManager:GetBuffType(typeId)
    end
    if BuffTypeConf then
      self.CanvasPanel_12:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCText_67:SetText(BuffTypeConf.buff_type_desc)
      self.ICON:SetPath(BuffTypeConf.buff_type_icon)
    else
      self.CanvasPanel_12:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local corner_markers = buffConfig.corner_markers
    if corner_markers then
      self.Buff_CornerMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Buff_CornerMark:SetPath(corner_markers)
    else
      self.Buff_CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local buffInfo = buff and buff.buffInfo
    local CurRound = _G.BattleManager:GetCurRound()
    local battleConfig = BattleUtils.GetBattleConfig()
    local battleMaxRound = battleConfig and battleConfig.max_round or 9999
    local timer = buffInfo and buffInfo.buff_left_round or -1
    local roundNumberWhenBuffRemoved = CurRound + timer
    local shouldTimerHide = timer < 0 or battleMaxRound < roundNumberWhenBuffRemoved
    if not shouldTimerHide then
      local isRoundReduce = false
      for _, group_reduce in ipairs(buffConfig.buff_group_reduce) do
        if group_reduce.reduce_type == Enum.BuffReduceType.BRT_ROUND or group_reduce.reduce_type == Enum.BuffReduceType.BRT_ROUND_SEVENTY_FIVE then
          isRoundReduce = true
          break
        end
      end
      shouldTimerHide = not isRoundReduce
    end
    if shouldTimerHide then
      self.SandClock:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.textBuffTimer:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.textBuffTimer:SetText("")
    else
      self.SandClock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.textBuffTimer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.textBuffTimer:SetText(timer)
    end
    self.textBuffName:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.textBuffDesc:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.textBuffName:SetText("")
    self.textBuffDesc:SetText("")
    self.textBuffTimer:SetText("")
    self.textBuffStack:SetText("")
    self.textBuffName:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.textBuffDesc:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SandClock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.textBuffTimer:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.textBuffStack:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  buffInfoBox.setupCount = buffInfoBox.setupCount + 1
  self.textBuffDesc:ForceLayoutPrepass()
  self.BuffInfoItemVerticalBox:ForceLayoutPrepass()
  self:ForceLayoutPrepass()
end

function UMG_Battle_BuffInfoItem_C:UpdateBuffDesc(source, buff)
  local output = source
  output = self:UpdateBuffDescForEnv(output, buff)
  output = self:UpdateBuffDescForAcs(output, buff)
  return output
end

function UMG_Battle_BuffInfoItem_C:UpdateBuffDescForEnv(source, buff)
  local weatherDesc, areaDesc
  if buff.desc_param_1 then
    weatherDesc = BattleUtils.FindWeatherDesc(buff.desc_param_1[1], buff.desc_param_1[2])
  end
  if buff.desc_param_2 then
    areaDesc = BattleUtils.FindAreaDesc(buff.desc_param_2[1])
  end
  local replacement = {}
  if weatherDesc then
    table.insert(replacement, weatherDesc)
  end
  if areaDesc then
    table.insert(replacement, areaDesc)
  end
  local pattern = BattleConst.UIInfoSettings.DescSpecialPatternEnv
  local output = BattleUtils.ReplaceSubString(source, pattern, replacement)
  return output
end

function UMG_Battle_BuffInfoItem_C:UpdateBuffDescForAcs(source, buff)
  if not buff:GetBuffBaseOrder() == ProtoEnum.BuffType.BFT_O_THIRTYTWO then
    return source
  end
  local pattern = BattleConst.UIInfoSettings.DescSpecialPatternAcs
  local attrList = BuffUtils.GetAllBuff132AttrListFromPet(buff.owner)
  local skillNameList = {}
  for i, attr in ipairs(attrList) do
    local typeConf = _G.DataConfigManager:GetTypeDictionary(attr, true)
    local name = typeConf and typeConf.type_name
    if name then
      table.insert(skillNameList, name)
    end
  end
  if 0 == #skillNameList then
    local typeConf = _G.DataConfigManager:GetTypeDictionary(Enum.SkillDamType.SDT_RELAX, true)
    local name = typeConf and typeConf.type_name
    if name then
      table.insert(skillNameList, name)
    end
  end
  local skillNameStr = table.concat(skillNameList, "\227\128\129")
  local replacement = {skillNameStr}
  local output = BattleUtils.ReplaceSubString(source, pattern, replacement)
  return output
end

return UMG_Battle_BuffInfoItem_C
