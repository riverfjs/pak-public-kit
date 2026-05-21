local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local UMG_Friend_Expression_C = _G.NRCPanelBase:Extend("UMG_Friend_Expression_C")

function UMG_Friend_Expression_C:OnConstruct()
  self.data = self.module:GetData("FriendModuleData")
  self:OnAddEventListener()
  self:AddPcInputBlock()
end

function UMG_Friend_Expression_C:OnActive(param, ChatMode)
  self:PlayAnimation(self.In)
  local EmoIdList = self:GetEmoIdListByGroup(param)
  if self.EmoTabList and #self.EmoTabList > 1 then
    self.Switcher:SetActiveWidgetIndex(1)
    self.List_2:InitGridView(self.EmoTabList)
    self.List_2:SelectItemByIndex(0)
    self:SetEmoTabRedPoint()
  else
    self.Switcher:SetActiveWidgetIndex(0)
  end
  self.List:InitGridView(EmoIdList)
  self:SetSlotInfo(ChatMode)
end

function UMG_Friend_Expression_C:SetEmoTabRedPoint()
  local RedPointList = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
  for k, v in ipairs(RedPointList) do
    if v.reason_type == _G.Enum.RedPointReason.RPR_NEW_CHAT_EMOJI and v.point_data and #v.point_data > 0 then
      for key, val in ipairs(v.point_data) do
        local emoId = tonumber(val)
        local emoConf = _G.DataConfigManager:GetChatEmojiConf(emoId)
        if emoConf and emoConf.topic_type then
          local topic_type = 0 ~= emoConf.topic_type and emoConf.topic_type or Enum.EmojiTopic.EMOJI_TOPIC_DEFAULT
          if self.EmoTabList and #self.EmoTabList > 1 then
            for i, tab in ipairs(self.EmoTabList) do
              if tab.type == topic_type then
                local item = self.List_2:GetItemByIndex(i - 1)
                if item and not item.RedDot:IsRed() then
                  item.RedDot:SetupKey(422)
                end
                break
              end
            end
          end
        end
      end
    end
  end
end

function UMG_Friend_Expression_C:EraseEmoRedPoint()
  local EraseRedList = {}
  if self.NeedEraseRedTab and #self.NeedEraseRedTab > 1 then
    local RedPointList = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
    for k, v in ipairs(RedPointList) do
      if v.reason_type == _G.Enum.RedPointReason.RPR_NEW_CHAT_EMOJI and v.point_data and #v.point_data > 0 then
        for key, val in ipairs(v.point_data) do
          local emoId = tonumber(val)
          local emoConf = _G.DataConfigManager:GetChatEmojiConf(emoId)
          if emoConf and emoConf.topic_type then
            local topic_type = 0 ~= emoConf.topic_type and emoConf.topic_type or Enum.EmojiTopic.EMOJI_TOPIC_DEFAULT
            for i, tab in ipairs(self.NeedEraseRedTab) do
              if tab == topic_type then
                table.insert(EraseRedList, {emoId})
                break
              end
            end
          end
        end
      end
    end
  else
    local RedPointList = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
    for k, v in ipairs(RedPointList) do
      if v.reason_type == _G.Enum.RedPointReason.RPR_NEW_CHAT_EMOJI and v.point_data and #v.point_data > 0 then
        for key, val in ipairs(v.point_data) do
          table.insert(EraseRedList, {val})
        end
      end
    end
  end
  if EraseRedList and #EraseRedList > 0 then
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPointWithExtraKeyList, 422, EraseRedList)
  end
end

function UMG_Friend_Expression_C:InitEmoList(EmoType)
  local EmoIdList = self.typeEmoList[EmoType]
  if EmoIdList then
    table.sort(EmoIdList, function(a, b)
      local a_conf = _G.DataConfigManager:GetChatEmojiConf(a)
      local b_conf = _G.DataConfigManager:GetChatEmojiConf(b)
      if a_conf and b_conf then
        if a_conf.sort == b_conf.sort then
          return a < b
        end
        return a_conf.sort < b_conf.sort
      end
      return a < b
    end)
    self.List:InitGridView(EmoIdList)
  end
  if self.NeedEraseRedTab then
    if not table.contains(self.NeedEraseRedTab, EmoType) then
      table.insert(self.NeedEraseRedTab, EmoType)
    end
  else
    self.NeedEraseRedTab = {}
    table.insert(self.NeedEraseRedTab, EmoType)
  end
end

function UMG_Friend_Expression_C:SetSlotInfo(ChatMode)
  if ChatMode == FriendEnum.ChatMode.GeneralChatting then
    local anchors = UE4.FAnchors()
    anchors.Minimum = UE4.FVector2D(0, 1)
    anchors.Maximum = UE4.FVector2D(0, 1)
    self.CanvasPanel_42.Slot:SetAnchors(anchors)
    self.CanvasPanel_42.Slot:SetPosition(UE4.FVector2D(440, -127))
  elseif ChatMode == FriendEnum.ChatMode.QuickAnnouncement then
    local anchors = UE4.FAnchors()
    anchors.Minimum = UE4.FVector2D(0.5, 1)
    anchors.Maximum = UE4.FVector2D(0.5, 1)
    self.CanvasPanel_42.Slot:SetAnchors(anchors)
    self.CanvasPanel_42.Slot:SetPosition(UE4.FVector2D(-163, -148))
  end
end

function UMG_Friend_Expression_C:OnDeactive()
end

function UMG_Friend_Expression_C:OnAddEventListener()
  self:AddButtonListener(self.BtnCloseEmoPanel, self.OnClickBtnCloseEmoPanel)
end

function UMG_Friend_Expression_C:OnDestruct()
  self:EraseEmoRedPoint()
  self:RemovePcInputBlock()
end

function UMG_Friend_Expression_C:AddPcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddBlockIMC, self, self.depth)
end

function UMG_Friend_Expression_C:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveBlockIMC, self)
end

function UMG_Friend_Expression_C:OnClickBtnCloseEmoPanel()
  self:PlayAnimation(self.Out)
end

function UMG_Friend_Expression_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  end
end

function UMG_Friend_Expression_C:AnalyzeEmojiEsc(esc)
  return tonumber(string.sub(esc, 5, 5))
end

function UMG_Friend_Expression_C:GetEmoIdListByGroup(index)
  local EmoIdList = {}
  local EmoConfList = {}
  self.typeEmoList = {}
  self.EmoTabList = {}
  for k, v in pairs(self.data.EmojiEscToIdMap) do
    local topic_type = v.topic_type and 0 ~= v.topic_type or Enum.EmojiTopic.EMOJI_TOPIC_DEFAULT
    if not table.containsKey(self.typeEmoList, topic_type) then
      self.typeEmoList[topic_type] = {}
      table.insert(self.EmoTabList, {
        type = topic_type,
        icon = v.topic_type_ui,
        parent = self
      })
    end
    local groupNum = self:AnalyzeEmojiEsc(k)
    if groupNum == index then
      table.insert(EmoConfList, v)
    end
  end
  for k, v in ipairs(EmoConfList) do
    local topic_type = v.topic_type and 0 ~= v.topic_type or Enum.EmojiTopic.EMOJI_TOPIC_DEFAULT
    if self.typeEmoList[topic_type] then
      table.insert(self.typeEmoList[topic_type], v.id)
    end
  end
  EmoIdList = self.typeEmoList[Enum.EmojiTopic.EMOJI_TOPIC_DEFAULT] or {}
  table.sort(EmoIdList, function(a, b)
    local a_conf = _G.DataConfigManager:GetChatEmojiConf(a)
    local b_conf = _G.DataConfigManager:GetChatEmojiConf(b)
    if a_conf and b_conf then
      if a_conf.sort == b_conf.sort then
        return a < b
      end
      return a_conf.sort < b_conf.sort
    end
    return a < b
  end)
  if self.EmoTabList and #self.EmoTabList > 1 then
    table.sort(self.EmoTabList, function(a, b)
      return a.type < b.type
    end)
  end
  return EmoIdList
end

return UMG_Friend_Expression_C
