local Class = _G.MakeSimpleClass
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipUtils = require("NewRoco.Modules.System.TipsModule.Utils.TipUtils")
local TipObject = Class("TipObject")

function TipObject:Ctor()
  self.tipStatus = TipEnum.TipStatus.Init
  self.tipType = TipEnum.TipObjectType.None
  self.tipSeq = TipUtils.GetNextTipSeq()
  self.tipBatch = 0
  self.titleType = TipEnum.TitleType.None
  self.type = ProtoEnum.GoodsType.GT_NONE
  self.id = 0
  self.num = 0
  self.first = false
  self.petData = nil
  self.petSkillData = nil
  self.petNewSkills = nil
  self.source = nil
  self.reason = 0
  self.CmdID = nil
  self.UpdateCmdId = nil
  self.CreateTime = _G.UpdateManager.Timestamp
end

function TipObject:__Dctor()
  self:MarkFinished()
end

function TipObject:__tostring()
  local buffer = {"{"}
  table.insert(buffer, string.format("tipType:%d, ", self.tipType))
  table.insert(buffer, string.format("tipCustomType:%d, ", self.tipCustomType or -1))
  table.insert(buffer, string.format("tipSeq:%d, ", self.tipSeq))
  table.insert(buffer, string.format("tipPass:%d, ", self.tipPass or -1))
  table.insert(buffer, string.format("tipStatus:%d, ", self.tipStatus))
  table.insert(buffer, string.format("tipExistTime:%f, ", self:GetTimeSinceCreation()))
  if self.tipDisplayAreas and #self.tipDisplayAreas > 0 then
    table.insert(buffer, string.format("tipDisplayAreas:%s, ", table.concat(self.tipDisplayAreas)))
  end
  if self.tipType == TipEnum.TipObjectType.TaskComplete or self.tipType == TipEnum.TipObjectType.TaskAccept then
    table.insert(buffer, string.format("task:%d, ", self.source.id))
  end
  table.insert(buffer, "}")
  return table.concat(buffer)
end

function TipObject:Resolve()
  if self.tipType == TipEnum.TipObjectType.None then
    return
  elseif self.tipType == TipEnum.TipObjectType.Reward then
    return UIUtils.GetTipsDetails(self.type, self.id)
  elseif self.tipType == TipEnum.TipObjectType.NewPet then
    return UIUtils.GetTipsDetails(self.type, self.id)
  elseif self.tipType == TipEnum.TipObjectType.RechargeUseCount then
    return UIUtils.GetTipsDetails(self.type, self.id)
  elseif self.tipType == TipEnum.TipObjectType.PetNewSkill then
    local pet, name, icon, bg, quality, desc = UIUtils.GetTipsDetails(ProtoEnum.GoodsType.GT_PET, self.petData.base_conf_id)
    local skillConf = _G.DataConfigManager:GetSkillConf(self.petSkillData.id)
    return skillConf, skillConf.name, NRCUtils:FormatConfIconPath(skillConf.icon, _G.UIIconPath.SkillIconPath), bg, skillConf.show_quality, skillConf.desc, "", icon
  elseif self.tipType == TipEnum.TipObjectType.PetLevelUp then
    return UIUtils.GetTipsDetails(ProtoEnum.GoodsType.GT_PET, self.petData.base_conf_id)
  elseif self.tipType == TipEnum.TipObjectType.PetEvolution then
    local pet, newName, icon, bg, quality, desc = UIUtils.GetTipsDetails(ProtoEnum.GoodsType.GT_PET, self.petData.base_conf_id)
    local _, oldName, _, _, _, _ = UIUtils.GetTipsDetails(ProtoEnum.GoodsType.GT_PET, self.source.base_conf_id)
    return pet, newName, icon, bg, quality, string.format(LuaText.evo_afterbattle_tips, oldName, newName)
  elseif self.tipType == TipEnum.TipObjectType.MiracleExchange then
    local pet, newName, icon, bg, quality, _ = UIUtils.GetTipsDetails(ProtoEnum.GoodsType.GT_PET, self.petData.base_conf_id)
    return pet, newName, icon, bg, quality
  end
  return nil, "", "", "", 0, "", ""
end

function TipObject:GetDetails()
  if self.tipType == TipEnum.TipObjectType.Reward then
    return self.first and {self}
  elseif self.tipType == TipEnum.TipObjectType.NewPet then
    return self.first and {self}
  elseif self.tipType == TipEnum.TipObjectType.PetLevelUp then
    if self.petNewSkills then
      local newTips = {}
      for _, v in ipairs(self.petNewSkills) do
        local newTip = TipObject.FromPetNewSkill(v, self.petData)
        newTip.titleType = self.titleType
        table.insert(newTips, newTip)
      end
      return newTips
    else
      return nil
    end
  elseif self.tipType == TipEnum.TipObjectType.PetEvolution then
    return {self}
  else
    return nil
  end
end

function TipObject:GetNewFlagType()
  if self.tipType == TipEnum.TipObjectType.None then
    return TipEnum.NewFlagType.None
  elseif self.tipType == TipEnum.TipObjectType.PetNewSkill then
    return TipEnum.NewFlagType.Blue
  elseif self.tipType == TipEnum.TipObjectType.Reward then
    return TipEnum.NewFlagType.White
  elseif self.tipType == TipEnum.TipObjectType.NewPet then
    return TipEnum.NewFlagType.Yellow
  else
    return TipEnum.NewFlagType.None
  end
end

function TipObject:GetFrameStyle()
  return self.tipType == TipEnum.TipObjectType.PetNewSkill and 1 or 0
end

function TipObject:GetIconSize()
  if self.tipType == TipEnum.TipObjectType.PetNewSkill then
    return 74
  elseif self.tipType == TipEnum.TipObjectType.Reward then
    return 70
  elseif self.tipType == TipEnum.TipObjectType.NewPet then
    return 70
  else
    return 70
  end
end

function TipObject:GetDescription()
  if self.tipType == TipEnum.TipObjectType.AmplifyUseEffect then
    if self.sourceID and 0 == self.sourceID then
      return ""
    end
    local SourceItemConf = _G.DataConfigManager:GetBagItemConf(self.sourceID)
    local CurrentItemConf = _G.DataConfigManager:GetBagItemConf(self.id)
    local BattleItem = _G.DataConfigManager:GetBattleItemConf(self.id)
    local EffectKey = string.format("BattleUseEffect_%d", BattleItem.use_effect_type_in_battle)
    local After = self.source.effect_value or 0
    return string.format(_G.LuaText.Item_Strengthen_Use_Effect, SourceItemConf.name, CurrentItemConf.name, _G.LuaText[EffectKey], self.num, After)
  elseif self.tipType == TipEnum.TipObjectType.IncreaseUseCount then
    if self.sourceID and 0 == self.sourceID then
      return ""
    end
    local SourceItemConf = _G.DataConfigManager:GetBagItemConf(self.sourceID)
    local CurrentItemConf = _G.DataConfigManager:GetBagItemConf(self.id)
    local After = self.source.max_use_cnt or 0
    return string.format(_G.LuaText.Item_Strengthen_Use_Time, SourceItemConf.name, CurrentItemConf.name, self.num, After)
  else
    return ""
  end
end

function TipObject:ShowInList()
  if self.tipType == TipEnum.TipObjectType.PetEvolution then
    return false
  elseif self.tipType == TipEnum.TipObjectType.LeaderFight then
    return false
  elseif self.tipType == TipEnum.TipObjectType.HandbookChange then
    return false
  elseif self.tipType == TipEnum.TipObjectType.LobbyDownTips then
    return false
  end
  return true
end

function TipObject:SetTipStatus(status)
  if self.tipStatus == status or self.tipStatus == TipEnum.TipStatus.Expired then
    return
  end
  self.tipStatus = status
  TipUtils.DebugTipFlow("[SetTipStatus]", self)
  local handles = self.tipStatusChangeCallback and self.tipStatusChangeCallback[status]
  if handles then
    for _, _functor in ipairs(handles) do
      _functor(self)
    end
  end
end

function TipObject:GetTipStatus()
  return self.tipStatus
end

function TipObject:MarkBlocking()
  self:SetTipStatus(TipEnum.TipStatus.Blocking)
end

function TipObject:MarkDisplaying()
  self:SetTipStatus(TipEnum.TipStatus.OnDisplay)
end

function TipObject:MarkFinished()
  self:SetTipStatus(TipEnum.TipStatus.Expired)
end

function TipObject:RegisterStatusChangeHandle(status, owner, callback)
  if not self.tipStatusChangeCallback then
    self.tipStatusChangeCallback = {}
  end
  local handlers = self.tipStatusChangeCallback[status]
  if not handlers then
    handlers = {}
    self.tipStatusChangeCallback[status] = handlers
  end
  table.insert(handlers, _G.MakeWeakFunctor(owner, callback))
end

function TipObject:GetTimeSinceCreation()
  if not self.CreateTime then
    return 36000
  end
  return _G.UpdateManager.Timestamp - self.CreateTime
end

function TipObject.FromGoodsItem(item, CmdID)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.Reward
  tip.tipCustomType = TipEnum.PropTipsType.GoodsItem
  tip.type = item.type
  tip.id = item.id
  tip.num = item.num
  tip.source = item
  tip.first = item.first_get
  tip.sourceID = item.src_id or 0
  tip.sourceType = item.src_type
  tip.reason = item.reward_reason
  tip.CmdID = CmdID
  if tip.type == ProtoEnum.GoodsType.GT_PET then
    if item.pet_data then
      tip.id = item.pet_data.base_conf_id
    else
      return nil
    end
    tip.tipType = TipEnum.TipObjectType.NewPet
    tip.first = true
    tip.num = 1
    local pet_gid_list = _G.DataModelMgr.PlayerDataModel:GetBattlePetGid()
    if item.first_get then
      if table.contains(pet_gid_list, item.pet_data.gid) then
        Log.Debug("\229\156\168\233\152\159\228\188\141\228\184\173")
      elseif _G.DataModelMgr.PlayerDataModel:IsInBackpack(item.pet_data.gid, nil) then
        if _G.DataModelMgr.PlayerDataModel:IsBackpackFull() then
          local error = _G.DataConfigManager:GetLocalizationConf("PetBag_Full").msg
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, error)
        end
        Log.Debug("\228\188\160\232\135\179\232\131\140\229\140\133")
      else
        tip.showIconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetBag/Frames/img_chuanzhicangku_png.img_chuanzhicangku_png'"
        Log.Debug("\228\188\160\232\135\179\228\187\147\229\186\147!")
      end
    else
    end
  elseif tip.type == ProtoEnum.GoodsType.GT_VITEM then
    if tip.id == ProtoEnum.VisualItem.VI_ROLE_LEVEL then
      return nil
    elseif tip.id == ProtoEnum.VisualItem.VI_ROLEEXP then
      return nil
    end
  elseif tip.type == ProtoEnum.GoodsType.GT_SHARE_FORM then
    tip.petData = item.pet_data
  elseif tip.type == ProtoEnum.GoodsType.GT_NONE then
    Log.Error("\229\144\142\229\143\176\229\144\140\229\173\166\228\184\139\229\143\145\228\186\134\228\184\170GT_NONE...")
    return nil
  end
  return tip
end

function TipObject.FromPetChangeToWarehouse(item, BackpackInfo)
  if not item.pet_data then
    return nil
  end
  if not _G.DataModelMgr.PlayerDataModel:IsInBackpack(item.pet_data.gid, BackpackInfo) then
    return nil
  end
  local tip = TipObject()
  tip.showIconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetBag/Frames/img_chuanzhicangku_png.img_chuanzhicangku_png'"
  Log.Dump(item, 2, "\229\176\157\232\175\149\231\148\159\230\136\144TipObject")
  tip.type = item.type
  tip.source = item
  tip.sourceID = item.src_id or 0
  tip.sourceType = item.src_type
  tip.titleType = 4
  tip.reason = item.change_reason
  if tip.type == ProtoEnum.GoodsType.GT_PET then
    if item.pet_data then
      tip.id = item.pet_data.base_conf_id
    else
      return nil
    end
    tip.tipType = TipEnum.TipObjectType.NewPet
    tip.first = true
    tip.num = 1
    return tip
  else
    return nil
  end
end

function TipObject.FromRewardItem(item)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.Reward
  tip.type = item.Type
  tip.id = item.Id
  tip.num = item.Count
  tip.source = item
  tip.first = false
  return tip
end

function TipObject.CreateMainPetTips(petTipsData)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.MainPetTips
  tip.customData = petTipsData
  return tip
end

function TipObject.CreateAddExpPropTip(expData)
  if not expData then
    return
  end
  local addExp = expData.newExp - expData.oldExp
  if expData.newLevel > expData.oldLevel then
    for i = expData.oldLevel, expData.newLevel - 1 do
      local levelExpConf = _G.DataConfigManager:GetRoleExpConf(i)
      if levelExpConf then
        addExp = addExp + levelExpConf.need_exp
      end
    end
  end
  if 0 == addExp then
    return
  end
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.Reward
  tip.tipCustomType = TipEnum.PropTipsType.PlayerAddExp
  tip.type = _G.ProtoEnum.GoodsType.GT_VITEM
  tip.num = addExp
  tip.id = _G.ProtoEnum.VisualItem.VI_ROLEEXP
  tip.customData = expData
  return tip
end

function TipObject.FromPetLevelUp(petData, newSkills, levelDiff)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.PetLevelUp
  tip.petData = petData
  tip.petNewSkills = newSkills
  tip.num = levelDiff
  tip.source = petData
  return tip
end

function TipObject.FormPetHandBook(PetData, GlobalConfig)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.HandbookChange
  tip.PetData = PetData
  tip.GlobalConfig = GlobalConfig
  tip.source = PetData
  return tip
end

function TipObject.FormLobbyDownTips(type, tipData)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.LobbyDownTips
  tip.tipCustomType = type
  tip.tipData = tipData
  tip.type = type
  tip.source = tipData
  return tip
end

function TipObject.FormStamps(_Stamps)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.StampsChange
  tip.source = _Stamps
  return tip
end

function TipObject.FormPetBallCatchAward(Item, CmdID, Timestamp)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.PetBallCatchAward
  tip.source = Item
  tip.CmdID = CmdID
  tip.Timestamp = Timestamp
  return tip
end

function TipObject.FromPetNewSkill(petSkillData, petData)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.PetNewSkill
  tip.petData = petData
  tip.petSkillData = petSkillData
  tip.source = petSkillData
  return tip
end

function TipObject.FromPetEvolution(New, Old)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.PetEvolution
  tip.petData = New
  tip.source = Old
  return tip
end

function TipObject.FromTaskAccept(info)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.TaskAccept
  tip.tipCustomType = TipEnum.TopHudTipsType.TaskTips
  tip.source = info
  return tip
end

function TipObject.FromTaskComplete(info)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.TaskComplete
  tip.tipCustomType = TipEnum.TopHudTipsType.TaskTips
  tip.source = info
  return tip
end

function TipObject.FromTaskUpdate()
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.TaskUpdate
  return tip
end

function TipObject.FromDungeonStateCompleted(des)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.DungeonStateCompleted
  tip.tipCustomType = TipEnum.TopHudTipsType.TaskTips
  tip.source = des
  return tip
end

function TipObject.FromDungeonCompleted(des)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.DungeonCompleted
  tip.tipCustomType = TipEnum.TopHudTipsType.TaskTips
  tip.source = des
  return tip
end

function TipObject.FromRecharge(item, old)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.RechargeUseCount
  tip.type = ProtoEnum.GoodsType.GT_BAGITEM
  tip.first = false
  tip.id = item.id
  tip.num = old
  tip.source = item
  return tip
end

function TipObject.FromIncreaseUseCount(item, old, sourceItemID)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.IncreaseUseCount
  tip.type = ProtoEnum.GoodsType.GT_BAGITEM
  tip.first = false
  tip.id = item.id
  tip.num = old
  tip.source = item
  tip.sourceType = ProtoEnum.GoodsType.GT_BAGITEM
  tip.sourceID = sourceItemID
  if not tip.sourceID then
    Log.Error("Can't find src_id, TipObject.FromIncreaseUseCount", item.id)
    Log.Dump(item, 2, "Show Item")
    return nil
  end
  return tip
end

function TipObject.FromAmplifyUseEffect(item, old, sourceItemID)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.AmplifyUseEffect
  tip.type = ProtoEnum.GoodsType.GT_BAGITEM
  tip.first = false
  tip.id = item.id
  tip.num = old
  tip.source = item
  tip.sourceType = ProtoEnum.GoodsType.GT_BAGITEM
  tip.sourceID = sourceItemID
  if not tip.sourceID then
    Log.Error("Can't find src_id, TipObject.FromAmplifyUseEffect", item.id)
    Log.Dump(item, 2, "Show Item")
    return nil
  end
  return tip
end

function TipObject.FromLeaderFight(notify, TipsType)
  local tip = TipObject()
  tip.tipType = TipsType
  tip.source = notify
  return tip
end

function TipObject.FromMiracleExchange(petData, changeReason)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.MiracleExchange
  tip.petData = petData
  tip.source = petData
  tip.reason = changeReason
  return tip
end

function TipObject.FromRaw(tipType, type, id, num, first)
  local tip = TipObject()
  tip.tipType = tipType
  tip.type = type
  tip.id = id
  tip.num = num
  tip.first = first
  return tip
end

function TipObject.CreateHandbookTopicDataTip(changeTopicData)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.HandbookTopic
  tip.timeLeft = _G.DataConfigManager:GetPetGlobalConfig("handbook_topic_renew_show_time").num / 1000
  tip.customData = changeTopicData
  return tip
end

function TipObject.CreateHandbookTopicTip(handbookTopicTipData)
  if not handbookTopicTipData then
    return nil
  end
  handbookTopicTipData.displayTopicIndex = {}
  for _topicIndex, _topicType in pairs(handbookTopicTipData.changeTopicType) do
    if not table.contains(handbookTopicTipData.preFinishTopicIndex, _topicIndex) then
      local _topic = handbookTopicTipData.topicData.topics[_topicIndex]
      if _topic and _topic.finishCnt and _topic.finishCnt > 0 then
        table.insert(handbookTopicTipData.displayTopicIndex, _topicIndex)
      end
    end
  end
  if #handbookTopicTipData.displayTopicIndex <= 0 then
    return nil
  end
  local topicDataCopy = table.deepCopy(handbookTopicTipData.topicData)
  handbookTopicTipData.topicData = topicDataCopy
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.HandbookTopic
  tip.timeLeft = _G.DataConfigManager:GetPetGlobalConfig("handbook_topic_renew_show_time").num / 1000
  tip.customData = handbookTopicTipData
  return tip
end

function TipObject.CreateTopHudTip(customType, customData)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.TopHudTips
  tip.tipCustomType = customType
  tip.customData = customData
  return tip
end

function TipObject.CreateDungeonTip(customType, customData)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.DungeonCompleted
  tip.tipCustomType = customType
  tip.customData = customData
  return tip
end

function TipObject.CreateZoneTip(zoneId, action)
  local customData = {}
  customData.zoneId = zoneId
  customData.action = action
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.ZoneTips, customData)
  return tip
end

function TipObject.CreateActivityZoneTip(Desc)
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.ActivityTips, Desc)
  tip.isActivityZoneTip = true
  return tip
end

function TipObject.CreateEnterHomeZoneTip(customData)
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.EnterHomeZoneTips, customData)
  return tip
end

function TipObject.CreateAddHomeExpTip(customData)
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.HomeAddExpTips, customData)
  return tip
end

function TipObject.CreateHomeExpandTip(customData)
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.HomeRoomExpandTips, customData)
  return tip
end

function TipObject.CreateCatchPetTip(customData)
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.CatchPetTips, customData)
  return tip
end

function TipObject.CreateExpChangeTip(tipData)
  if not tipData then
    return nil
  end
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.ExpTips, tipData)
  return tip
end

function TipObject.CreateBreakThroughTip(conf, expTip)
  local customData = {}
  customData.conf = conf
  customData.expTip = expTip
  customData.isBegin = true
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.BreakThroughTips, customData)
  return tip
end

function TipObject.CreateUnlockUIEnumTip(UnlockUIEnum)
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.FunUnlockTips, UnlockUIEnum)
  return tip
end

function TipObject.CreateMagicUnlockTip(item)
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.MagicTips, item)
  return tip
end

function TipObject.CreateCommonTips(content, delay, color, showTime)
  local customData = {}
  customData.content = content
  customData.delay = delay
  customData.color = color
  customData.showTime = showTime
  local tip = TipObject.CreateTopHudTip(TipEnum.TopHudTipsType.CommonTips, customData)
  return tip
end

function TipObject.CreateLobbyRegionPreUpdateTip(cmdId)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.LobbyRegionPreUpdate
  tip.customData = cmdId
  return tip
end

function TipObject:IsPlayerCard()
  if self.type == ProtoEnum.GoodsType.GT_CARD_ICON or self.type == ProtoEnum.GoodsType.GT_CARD_SKIN or self.type == ProtoEnum.GoodsType.GT_CARD_LABEL then
    return true
  end
  return false
end

function TipObject:IsNotFashionOrMyGenderFashion()
  if self.type ~= ProtoEnum.GoodsType.GT_FASHION then
    return true
  end
  local fashionItemConf = self:Resolve()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not fashionItemConf then
    return false
  end
  if fashionItemConf.gender == Enum.ESexValue.SEX_NOT_SEL or player.gender == tonumber(fashionItemConf.gender) then
    return true
  else
    return false
  end
end

function TipObject:IsBattlePassIgnored()
  return false
end

function TipObject:IsCardSkinAndCardLabel()
  if self.type == ProtoEnum.GoodsType.GT_CARD_SKIN or self.type == ProtoEnum.GoodsType.GT_CARD_LABEL then
    return true
  end
  return false
end

function TipObject:GetCardIconPath()
  if self.type == ProtoEnum.GoodsType.GT_CARD_ICON then
    return "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/Images/Frames/img_touxiang1_png.img_touxiang1_png'"
  elseif self.type == ProtoEnum.GoodsType.GT_CARD_SKIN then
    return "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/Images/Frames/img_pifu_png.img_pifu_png'"
  elseif self.type == ProtoEnum.GoodsType.GT_CARD_LABEL then
    return "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/Images/Frames/img_tag_png.img_tag_png'"
  elseif self.type == ProtoEnum.GoodsType.GT_SHARE_FORM then
    return "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_share_png.img_share_png'"
  else
    Log.Error("\229\189\147\229\137\141\231\177\187\229\158\139\228\184\141\230\152\175\228\184\170\228\186\186\229\144\141\231\137\135,\232\175\183\230\159\165\231\156\139\230\149\176\230\141\174")
    return "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/Images/Frames/img_touxiang1_png.img_touxiang1_png'"
  end
end

function TipObject.CreateRolePlayTips(uiData, pcKeyIAName)
  if not uiData then
    return
  end
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.RolePlayGetTips
  tip.customData = uiData
  tip.timeLeft = uiData.countdown
  tip.tickInterval = 1
  tip.pcKeyIAName = pcKeyIAName
  return tip
end

function TipObject.CreateNPCRosterTips(uiData)
  if not uiData then
    return
  end
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.NPCRosterTips
  tip.customData = uiData
  tip.timeLeft = uiData.countdown or 5
  tip.tickInterval = 1
  return tip
end

function TipObject.CreateLegendaryTaskUnlockTips(uiData)
  if not uiData then
    return
  end
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.LegendaryTaskUnlockTips
  tip.customData = uiData
  tip.timeLeft = uiData.countdown or 5
  tip.tickInterval = 1
  return tip
end

function TipObject.CreateTeachingUnlockTips(uiData)
  if not uiData then
    return
  end
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.TeachingUnlockTips
  tip.customData = uiData
  tip.timeLeft = uiData.countdown or 3
  tip.tickInterval = 1
  return tip
end

function TipObject.CreateBPGiftTips(tipsData)
  if not tipsData then
    return
  end
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.ReceiveBPGiftTips
  tip.customData = tipsData
  tip.timeLeft = tipsData.countdown or 5
  tip.tickInterval = 1
  return tip
end

function TipObject.CreateMusicCollectUnlockTips(uiData)
  if not uiData then
    return
  end
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.MusicCollectUnlockTips
  tip.customData = uiData
  tip.timeLeft = uiData.countdown or 5
  tip.tickInterval = 1
  return tip
end

function TipObject.CreateMonthlyCardDailyRewardTips(_type, _id, _num, order)
  local customData = {
    [_type] = {
      [_id] = {_num, order}
    }
  }
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.MonthlyCardDailyRewardTips
  tip.customData = customData
  return tip
end

function TipObject.CreateTaskSummaryTips(uiData)
  if not uiData then
    Log.Error("\229\144\142\229\143\176\231\154\132TaskSummaryInfo\230\149\176\230\141\174\228\184\186\231\169\186,\228\184\141\230\146\173tips")
    return
  end
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.TaskSummary
  tip.customData = uiData
  return tip
end

function TipObject.CreateTaskReturnRewardTips(uiData)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.TaskReturnReward
  tip.customData = uiData
  return tip
end

function TipObject.CreatePetCertificationTips(base_id)
  local tip = TipObject()
  local certificationConf = _G.DataConfigManager:GetActivityPetCertification(base_id)
  local tipsData = {
    effectText = certificationConf.finish_text,
    effectIcon = certificationConf.finish_picture,
    titleText = certificationConf.finish_title
  }
  tip.tipType = TipEnum.TipObjectType.PetCertification
  tip.customData = tipsData
  tip.tipCustomType = TipEnum.TopHudTipsType.PetCertification
  return tip
end

function TipObject.CreateSeasonBeginsTips()
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.SeasonBeginsTips
  return tip
end

function TipObject.CreateActivityCommonOpenTips(activityId, bDebug)
  local tip = TipObject()
  tip.tipType = TipEnum.TipObjectType.ActivityCommonOpenTips
  tip.tipCustomType = activityId
  local tipsData = {activityId = activityId, bDebug = bDebug}
  tip.customData = tipsData
  return tip
end

return TipObject
