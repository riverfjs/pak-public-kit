local EmailModuleData = _G.NRCData:Extend("EmailModuleData")
local JsonUtils = require("Common.JsonUtils")

function EmailModuleData:Ctor()
  NRCData.Ctor(self)
  self.TableIndex = 0
  self.MailIndex = 0
  self.NoticeIndex = 0
  self.CurSelectMailGid = 0
  self.EmailDic = nil
  self.NoticeRedPointIds = {}
  self.TableNameDatas = self:GetTableDatas()
  self.NoticeListDatas = {}
end

function EmailModuleData:GetEmailInfo(gid)
  return self.EmailDic[gid]
end

function EmailModuleData:SetSelectMailGid(id)
  self.CurSelectMailGid = id
end

function EmailModuleData:GetSelectMailGid()
  return self.CurSelectMailGid
end

function EmailModuleData:SetTableIndex(index)
  self.TableIndex = index
end

function EmailModuleData:GetTableIndex()
  return self.TableIndex
end

function EmailModuleData:SetMailIndex(index)
  self.MailIndex = index
end

function EmailModuleData:GetMailIndex()
  return self.MailIndex
end

function EmailModuleData:SetNoticeIndex(index)
  self.NoticeIndex = index
end

function EmailModuleData:GetNoticeIndex()
  return self.NoticeIndex
end

function EmailModuleData:GetTableDatas()
  local name1 = LuaText.emailmoduledata_1
  local name2 = LuaText.emailmoduledata_2
  local tables = {}
  table.insert(tables, name1)
  table.insert(tables, name2)
  return tables
end

function EmailModuleData:GetTimeDateString(time)
  return os.date("%Y-%m-%d %H:%M", time)
end

function EmailModuleData:GetExpireTimeDateString(time)
  if time <= 0 then
    return
  end
  local day = math.floor(time / 86400)
  local hour = math.floor(time % 86400 / 3600)
  local str = ""
  if day > 0 then
    str = day .. LuaText.emailmoduledata_3
  end
  if hour > 0 then
    str = str .. hour .. LuaText.emailmoduledata_4
  end
  if day <= 0 and hour <= 0 then
    local minute = math.floor(time % 3600 / 60)
    if minute > 0 then
      str = str .. minute .. LuaText.umg_npcshop_4
    else
      str = 0 .. LuaText.umg_npcshop_4
    end
  end
  return str
end

function EmailModuleData:SetMailDatas(mailInfoList)
  if self.EmailDic == nil then
    self.EmailDic = {}
  end
  if nil == mailInfoList or 0 == #mailInfoList then
    return
  end
  for i = 1, #mailInfoList do
    local mailInfo = mailInfoList[i]
    local id = mailInfo.mail_gid
    mailInfo.time_str = self:GetTimeDateString(mailInfo.add_time)
    
    function mailInfo.expire_str()
      local str = ""
      local curServerTime = _G.ZoneServer:GetServerTime()
      if mailInfo.expire_time and mailInfo.expire_time > 0 then
        if type(curServerTime) == "number" then
          local svr_time = math.floor(curServerTime / 1000)
          local elapsedTime = svr_time - mailInfo.add_time
          local expirationDate = mailInfo.expire_time - mailInfo.add_time - elapsedTime
          str = self:GetExpireTimeDateString(expirationDate)
        end
      else
        str = LuaText.emailmoduledata_5
      end
      return str
    end
    
    mailInfo.name = ""
    local isServerMsg = mailInfo.use_svr_data
    if not isServerMsg and mailInfo.mail_conf_id and 0 ~= mailInfo.mail_conf_id then
      local cfg = _G.DataConfigManager:GetMailConf(mailInfo.mail_conf_id)
      if cfg then
        mailInfo.name = cfg.mail_sender
        mailInfo.contents = cfg.mail_content
        mailInfo.title = cfg.mail_title
      end
    end
    if mailInfo.src and mailInfo.src.name then
      mailInfo.name = mailInfo.src.name
    end
    if mailInfo.params and mailInfo.params.content_param_list and #mailInfo.params.content_param_list > 0 then
      mailInfo.contents = self:ProcessContentParameters(mailInfo.contents, mailInfo.params.content_param_list)
    end
    if mailInfo.params and mailInfo.params.title_param_list and #mailInfo.params.title_param_list > 0 then
      mailInfo.title = self:ProcessContentParameters(mailInfo.title, mailInfo.params.title_param_list)
    end
    mailInfo.is_read = mailInfo.mail_status == _G.ProtoEnum.MailStatusType.MAIL_STATUS_READ
    mailInfo.is_recv = mailInfo.recv_status == _G.ProtoEnum.MailRecvStatusType.MAIL_RECV_STATUS_YES
    mailInfo.is_redpoint = not mailInfo.isRead or not mailInfo.isRecv
    mailInfo.icon_head = {}
    mailInfo.icon_head.is_read = mailInfo.is_read
    mailInfo.icon_head.is_head_icon = true
    mailInfo.rewards = {}
    local rewards = {}
    if mailInfo.reward and mailInfo.reward.rewards then
      rewards = mailInfo.reward.rewards
    end
    if rewards and #rewards > 0 then
      if rewards[1].type == _G.Enum.GoodsType.GT_REWARD then
        local rewardConf = _G.DataConfigManager:GetRewardConf(rewards[1].id)
        if rewardConf and rewardConf.show_bagitem_id > 0 then
          mailInfo.icon_head.Id = rewardConf.show_bagitem_id
          mailInfo.icon_head.Count = 1
          mailInfo.icon_head.Type = _G.Enum.GoodsType.GT_BAGITEM
        elseif rewardConf and rewardConf.Type == _G.Enum.RewardType.RT_GIFT then
          local rwdItem = rewardConf.RewardItem[1]
          mailInfo.icon_head.Id = rwdItem.Id
          mailInfo.icon_head.Count = rwdItem.Count
          mailInfo.icon_head.Type = rwdItem.Type
        end
      else
        mailInfo.icon_head.Id = rewards[1].id
        mailInfo.icon_head.Count = rewards[1].num
        mailInfo.icon_head.Type = rewards[1].type
        mailInfo.icon_head.IsShowPetbase = false
        if rewards[1].type == _G.Enum.GoodsType.GT_PET and rewards[1].pet_data and rewards[1].pet_data.base_conf_id then
          mailInfo.icon_head.IsShowPetbase = true
          mailInfo.icon_head.Id = rewards[1].pet_data.base_conf_id
        end
      end
      for j = 1, #rewards do
        if rewards[j].type == _G.Enum.GoodsType.GT_REWARD then
          local rewardConf = _G.DataConfigManager:GetRewardConf(rewards[j].id)
          if rewardConf then
            if rewardConf.show_bagitem_id > 0 then
              local item = {}
              item.is_recv = mailInfo.is_recv
              item.Id = rewardConf.show_bagitem_id
              item.Type = _G.Enum.GoodsType.GT_BAGITEM
              item.Count = 1
              table.insert(mailInfo.rewards, item)
            elseif rewardConf.Type == _G.Enum.RewardType.RT_GIFT then
              local rewardItems = rewardConf.RewardItem
              if rewardItems and #rewardItems > 0 then
                for k = 1, #rewardItems do
                  local rewardItem = rewardItems[k]
                  local item = {}
                  item.is_recv = mailInfo.is_recv
                  item.Id = rewardItem.Id
                  item.Count = rewardItem.Count
                  item.Type = rewardItem.Type
                  table.insert(mailInfo.rewards, item)
                end
              end
            else
              local rewardItems = rewardConf.RewardItem
              if rewardItems and #rewardItems > 0 then
                local rewardItem = rewardItems[1]
                local item = {}
                item.is_recv = mailInfo.is_recv
                item.Id = rewardItem.Id
                item.Count = rewardItem.Count
                item.Type = rewardItem.Type
                table.insert(mailInfo.rewards, item)
              end
            end
          end
        else
          local item = {}
          item.is_recv = mailInfo.is_recv
          item.IsShowPetbase = false
          if rewards[j].type == _G.Enum.GoodsType.GT_PET and rewards[j].pet_data and rewards[j].pet_data.base_conf_id then
            item.IsShowPetbase = true
            item.Id = rewards[j].pet_data.base_conf_id
          else
            item.Id = rewards[j].id
          end
          item.Count = rewards[j].num
          item.Type = rewards[j].type
          table.insert(mailInfo.rewards, item)
        end
      end
    end
    self.EmailDic[id] = mailInfo
  end
end

function EmailModuleData:GetRewardItem(itemData, itemList, is_recv)
  if itemData.Type == _G.Enum.GoodsType.GT_REWARD then
    local rewardConf = _G.DataConfigManager:GetRewardConf(itemData.Id)
    local rewardItems = rewardConf.RewardItem
    if rewardItems and #rewardItems > 0 then
      for k = 1, #rewardItems do
        local rewardItem = rewardItems[k]
        if rewardItem.Type == _G.Enum.GoodsType.GT_REWARD then
          self:GetRewardItem(rewardItem, itemList, is_recv)
        else
          local item = {}
          item.is_recv = is_recv
          item.Id = rewardItem.Id
          item.Count = rewardItem.Count
          item.Type = rewardItem.Type
          table.insert(itemList, item)
        end
      end
    end
  end
end

function EmailModuleData:GetStringFormat(content, params)
  local strParamDatas = {}
  local strs = {}
  for i = 1, #params do
    local param = params[i]
    table.insert(strParamDatas, param)
  end
  table.sort(strParamDatas, function(a, b)
    return a.key < b.key
  end)
  for i, str in pairs(strParamDatas) do
    table.insert(strs, str.value)
  end
  self:LogError(content, table.unpack(strs))
  return string.format(content, table.unpack(strs))
end

function EmailModuleData:ProcessContentParameters(content, params)
  local strContent = content
  for i, v in pairs(params) do
    local param = v
    local seat = string.format("{%s}", param.key)
    if string.find(content, seat) then
      strContent = string.gsub(strContent, seat, function()
        return param.value
      end)
    end
  end
  return strContent
end

function EmailModuleData:ProcessMailParameters(mailInfo)
  if mailInfo.params and #mailInfo.params > 0 then
    for i = 1, #mailInfo.params do
      local param = mailInfo.params[i]
      if param.content_param_list and #param.content_param_list > 0 then
        self:ProcessContentParameters(mailInfo.content, param.content_param_list)
      end
      if param.title_param_list and #param.title_param_list then
        self:ProcessTitleParameters(mailInfo.title, param.title_param_list)
      end
    end
  end
end

function EmailModuleData:ProcessTitleParameters(title, params)
end

function EmailModuleData:SetMailReadState(id, isRead)
  if self.EmailDic[id] then
    self.EmailDic[id].is_read = isRead
    self.EmailDic[id].icon_head.is_read = isRead
  end
end

function EmailModuleData:SetMailRecvState(id, isRecv)
  if self.EmailDic[id] then
    self.EmailDic[id].is_recv = isRecv
    for i, v in pairs(self.EmailDic[id].rewards) do
      v.is_recv = isRecv
    end
  end
end

function EmailModuleData:GetMailState(id)
  if self.EmailDic[id] then
    return self.EmailDic[id].is_read, self.EmailDic[id].is_recv
  end
end

function EmailModuleData:RemoveMail(ids)
  if nil ~= ids then
    for i = 1, #ids do
      local id = ids[i]
      self.EmailDic[id] = nil
    end
  end
end

function EmailModuleData:GetMailListDatas()
  local dataList = {}
  if self.EmailDic == nil then
    self.EmailDic = {}
  end
  for i, v in pairs(self.EmailDic) do
    table.insert(dataList, v)
  end
  return dataList
end

function EmailModuleData:SetNoticeListDatas(NoticeList)
  self.NoticeListDatas = NoticeList
  self:InitRedPointData()
end

function EmailModuleData:AddNoticeRedPoint()
  _G.NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointData, _G.Enum.RedPointReason.RPR_NEW_NOTICE, table.copy(self.NoticeRedPointIds))
end

function EmailModuleData:RemoveNoticeRedPoint(id)
  for i = 1, #self.NoticeRedPointIds do
    if id == tonumber(self.NoticeRedPointIds[i]) then
      table.remove(self.NoticeRedPointIds, i)
      JsonUtils.DumpSaved(string.format("Notices/Notice_Red_%s", id), {id = id, state = false})
    end
  end
  _G.NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointData, _G.Enum.RedPointReason.RPR_NEW_NOTICE, table.copy(self.NoticeRedPointIds))
end

function EmailModuleData:InitRedPointData()
  self.NoticeRedPointIds = {}
  if self.NoticeListDatas then
    for i = 1, #self.NoticeListDatas do
      local notice = self.NoticeListDatas[i]
      local redJson = JsonUtils.LoadSaved(string.format("Notices/Notice_Red_%s", notice.ID), {})
      local isShowRed = false
      if not redJson or redJson.state == nil then
        JsonUtils.DumpSaved(string.format("Notices/Notice_Red_%s", notice.ID), {
          id = notice.ID,
          state = true
        })
        isShowRed = true
      else
        JsonUtils.DumpSaved(string.format("Notices/Notice_Red_%s", notice.ID), {
          id = notice.ID,
          state = redJson.state
        })
        isShowRed = redJson.state
      end
      if isShowRed then
        table.insert(self.NoticeRedPointIds, tostring(notice.ID))
      end
    end
  end
  self:AddNoticeRedPoint()
end

return EmailModuleData
