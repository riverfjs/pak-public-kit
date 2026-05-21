local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local EmailModuleEvent = require("NewRoco.Modules.System.Email.EmailModuleEvent")
local EmailModule = NRCModuleBase:Extend("EmailModule")

function EmailModule:OnConstruct()
  _G.EmailModuleCmd = reload("NewRoco.Modules.System.Email.EmailModuleCmd")
  self.InitNoticeRedPoint = false
  self.MailTotalPage = 0
  self.MailReqPage = 0
  self.MailVersion = 0
  self.DelayId = nil
  self.data = self:SetData("EmailModuleData", "NewRoco.Modules.System.Email.EmailModuleData")
  self:RegisterCmd(_G.EmailModuleCmd.OpenMainPanel, self.OnOpenMainPanel)
  self:RegisterCmd(_G.EmailModuleCmd.CloseMainPanel, self.OnCloseMainPanel)
  self:RegisterCmd(_G.EmailModuleCmd.EnableMainPanel, self.EnableMainPanel)
  self:RegisterCmd(_G.EmailModuleCmd.PreLoadMainPanel, self.PreLoadMainPanel)
  self:RegisterCmd(_G.EmailModuleCmd.RemoveNoticeRedPoint, self.RemoveNoticeRedPoint)
  self:RegisterCmd(_G.EmailModuleCmd.GetSelectEmailIndex, self.GetSelectEmailIndex)
  self:RegisterCmd(_G.EmailModuleCmd.SetSelectEmailIndex, self.SetSelectEmailIndex)
  self:RegisterCmd(_G.EmailModuleCmd.GetSelectMailGid, self.GetSelectMailGid)
  self:RegisterCmd(_G.EmailModuleCmd.SetSelectMailGid, self.SetSelectMailGid)
  self:RegisterCmd(_G.EmailModuleCmd.ZoneEmailReadReq, self.ZoneEmailReadReq)
  self:RegisterCmd(_G.EmailModuleCmd.UpdateNoticeList, self.OnCmdUpdateNoticeList)
  self:RegisterCmd(_G.EmailModuleCmd.GetMainInfoByGid, self.GetMainInfo)
  self:RegisterCmd(_G.EmailModuleCmd.GetMailState, self.GetMailState)
  self:RegPanel("EmailMainPanel", "UMG_Email", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, false)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_MAIL_DELETE_NOTIFY, self.OnZoneMailDeleteNotify)
  _G.NRCEventCenter:RegisterEvent("EmailModule", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.InitRedPointData)
  UE4.UNoticeStatics.LoadNoticeData("game", "0", "", false)
end

function EmailModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/Email/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  self:RegisterPanel(registerData)
end

function EmailModule:OnOpenMainPanel(arg)
  UE4.UNoticeStatics.LoadNoticeData("game", "0", "", false)
  self:ZoneMailGetListByPageReq()
  self:MarkPanelWaitingOpen("EmailMainPanel")
  self:OpenPanel("EmailMainPanel", arg)
end

function EmailModule:OnCloseMainPanel()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false, false)
  self:MarkPanelWaitingOpen("EmailMainPanel", true)
  self:ClosePanel("EmailMainPanel")
end

function EmailModule:EnableMainPanel()
  local Panel = self:GetPanel("EmailMainPanel")
  if Panel then
    Panel:EnableAndShouldBanWorldRendering()
  end
end

function EmailModule:PreLoadMainPanel()
  self:PreLoadPanel("EmailMainPanel", 10)
end

function EmailModule:OnActive()
end

function EmailModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.InitRedPointData)
end

function EmailModule:OnDestruct()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function EmailModule:ZoneMailGetListByPageReq()
  local req = _G.ProtoMessage:newZoneMailGetListByPageReq()
  req.page = 1
  req.version = self.MailVersion
  self.isClearDatas = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_GET_LIST_BY_PAGE_REQ, req, self, self.OnGetMailNextPage, true)
end

function EmailModule:OnGetMailNextPage(rsp)
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code then
    if rsp.not_new_data and 1 == rsp.not_new_data then
      Log.Error("\230\151\160\230\149\176\230\141\174")
    end
    self.MailTotalPage = rsp.total_page or 0
    self.MailReqPage = rsp.req_page or 0
    if rsp.mail_list and rsp.mail_list.mails then
      self:ClearMailDatas()
      self.data:SetMailDatas(rsp.mail_list.mails)
    end
    if self.MailReqPage >= self.MailTotalPage then
      if rsp.version then
        self.MailVersion = rsp.version
      end
      self:DispatchEvent(EmailModuleEvent.RefreshUIEvent, true)
    else
      local req = _G.ProtoMessage:newZoneMailGetListByPageReq()
      req.page = self.MailReqPage + 1
      req.version = self.MailVersion
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_GET_LIST_BY_PAGE_REQ, req, self, self.OnGetMailNextPage, true)
    end
  else
    self:DispatchEvent(EmailModuleEvent.RefreshUIEvent, true)
  end
end

function EmailModule:ClearMailDatas()
  if self.isClearDatas then
    self.data.EmailDic = {}
    self.isClearDatas = false
  end
end

function EmailModule:OnZoneMailDeleteNotify(notify)
  if notify and notify.mail_gid_list then
    self.data:RemoveMail(notify.mail_gid_list)
    self:DispatchEvent(EmailModuleEvent.RemoveMail, notify.mail_gid_list)
  end
end

function EmailModule:ZoneMailGetListReq()
  local req = _G.ProtoMessage:newZoneMailGetListReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_GET_LIST_REQ, req, self, self.ZoneMailGetListRsp)
end

function EmailModule:ZoneMailGetListRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    Log.Dump(rsp, 9, "ZoneMailGetListRsp--")
    if rsp.mail_list and rsp.mail_list.mails then
      self.data:SetMailDatas(rsp.mail_list.mails)
    else
      self.data:SetMailDatas(nil)
    end
    self:DispatchEvent(EmailModuleEvent.RefreshUIEvent, true)
  end
end

function EmailModule:ZoneMailGetReq(mail_id)
  local req = _G.ProtoMessage:newZoneMailGetReq()
  req.mail_gid = 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_GET_REQ, req, self, self.ZoneMailGetRsp)
end

function EmailModule:ZoneMailGetRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetMailDatas(rsp.mail_info)
    self:DispatchEvent(EmailModuleEvent.RefreshUIEvent)
  end
end

function EmailModule:ZoneEmailReadReq(mail_gid)
  if self.data.EmailDic[mail_gid] ~= nil then
    local isRead = self.data.EmailDic[mail_gid].is_read
    if isRead then
      return
    end
    local req = _G.ProtoMessage:newZoneMailReadReq()
    req.mail_gid_list = {}
    table.insert(req.mail_gid_list, mail_gid)
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_READ_REQ, req, self, self.ZoneEmailReadRsp)
  end
end

function EmailModule:ZoneEmailReadRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.mail_gid_list then
    for i = 1, #rsp.mail_gid_list do
      local id = rsp.mail_gid_list[i]
      self.data:SetMailReadState(id, true)
    end
    local gid = self.data.CurSelectMailGid
    local mailInfo = self.data:GetEmailInfo(gid)
    self:DispatchEvent(EmailModuleEvent.UpdateMailDes, mailInfo)
  end
  if self.isGetAll then
    self.isGetAll.readAll = 0 == rsp.ret_info.ret_code
    if self.isGetAll.readAll and self.isGetAll.attachAll then
      self.isGetAll = nil
      self:DispatchEvent(EmailModuleEvent.UpdateGetAllMail)
    end
  end
end

function EmailModule:ZoneMailGetAttachmentReq(mail_id)
  Log.InfoFormat("EmailModule:ZoneMailGetAttachmentReq mail_id = %s", tostring(mail_id))
  local req = _G.ProtoMessage:newZoneMailGetAttachmentReq()
  req.mail_gid = mail_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_GET_ATTACHMENT_REQ, req, self, self.ZoneMailGetAttachmentRsp, true, true)
end

function EmailModule:ZoneMailGetAttachmentRsp(rsp)
  Log.InfoFormat("EmailModule:ZoneMailGetAttachmentRsp ret_code = %s", tostring(rsp.ret_info.ret_code))
  if 0 ~= rsp.ret_info.ret_code then
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    local text = LuaText[key]
    if rsp.get_fail_goods and #rsp.get_fail_goods > 0 then
      local names = self:GetItemNames(rsp.get_fail_goods)
      text = string.format(text, names)
    end
    self.DelayId = _G.DelayManager:DelayFrames(1, function()
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, text)
    end)
  end
  if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1066, "UMG_LevelUpRewards_C:OnBtnGetRewardsClick")
    local rewards = {}
    for i, v in pairs(rsp.ret_info.goods_reward.rewards) do
      local reward = {}
      reward.type = v.type
      reward.num = v.num
      if reward.type == _G.Enum.GoodsType.GT_PET then
        if v.pet_data.base_conf_id then
          reward.id = v.pet_data.base_conf_id
          reward.IsShowPetbase = true
        else
          reward.id = v.pet_data.conf_id
        end
      else
        reward.id = v.id
      end
      if v.gids and #v.gids > 0 then
        reward.gid = v.gids[1]
      end
      if rsp.mail_brief and rsp.mail_brief[1] and rsp.mail_brief[1].reward and rsp.mail_brief[1].reward.rewards and rsp.mail_brief[1].reward.rewards[i] and rsp.mail_brief[1].reward.rewards[i].egg_info then
        reward.eggInfo = rsp.mail_brief[1].reward.rewards[i].egg_info
      end
      reward.reward_reason = v.reward_reason
      table.insert(rewards, reward)
    end
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewards, LuaText.emailmodule_1)
  end
  if rsp.mail_brief and #rsp.mail_brief > 0 then
    for i = 1, #rsp.mail_brief do
      local id = rsp.mail_brief[i].mail_gid
      self.data:SetMailRecvState(id, true)
      self.data:SetMailReadState(id, true)
    end
  end
  local gid = self.data.CurSelectMailGid
  local mailInfo = self.data:GetEmailInfo(gid)
  self:DispatchEvent(EmailModuleEvent.UpdateMailDes, mailInfo)
  self:DispatchEvent(EmailModuleEvent.UpdateGetAllMail)
end

function EmailModule:GetItemNames(goods)
  local itemNameTable = {}
  local str = ""
  for i = 1, #goods do
    if i > 10 then
      table.insert(itemNameTable, "...")
      break
    end
    local id = goods[i].goods_id
    local type = goods[i].type
    if type == _G.Enum.GoodsType.GT_VITEM then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(id)
      if nil ~= vItemConf then
        table.insert(itemNameTable, vItemConf.displayName)
      end
    elseif type == _G.Enum.GoodsType.GT_BAGITEM then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(id)
      if nil ~= bagItemConf then
        table.insert(itemNameTable, bagItemConf.name)
      end
    elseif type == _G.Enum.GoodsType.GT_PET then
      if goods[i].pet_base_id and goods[i].pet_base_id > 0 then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(goods[i].pet_base_id)
        if nil ~= petBaseConf then
          table.insert(itemNameTable, petBaseConf.name)
        end
      else
        local petInfo = _G.DataConfigManager:GetPetConf(id, true)
        if petInfo then
          local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_id)
          if nil ~= petBaseConf then
            table.insert(itemNameTable, petBaseConf.name)
          end
        else
          local monsterConf = _G.DataConfigManager:GetMonsterConf(id)
          if nil ~= monsterConf then
            local petBaseConf = _G.DataConfigManager:GetPetbaseConf(monsterConf.base_id)
            if nil ~= petBaseConf then
              table.insert(itemNameTable, petBaseConf.name)
            end
          end
        end
      end
    elseif type == _G.Enum.GoodsType.GT_CARD_SKIN then
      local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(id)
      if cardSkinConf and cardSkinConf.bagitem_id then
        local bagitem_id = cardSkinConf.bagitem_id
        local bagItemConf = _G.DataConfigManager:GetBagItemConf(bagitem_id)
        if nil ~= bagItemConf then
          table.insert(itemNameTable, bagItemConf.name)
        end
      end
    elseif type == _G.Enum.GoodsType.GT_CARD_ICON then
      local GetCardIconConf = _G.DataConfigManager:GetCardIconConf(id)
      if GetCardIconConf then
        table.insert(itemNameTable, GetCardIconConf.icon_resource_name)
      end
    elseif type == _G.Enum.GoodsType.GT_CARD_LABEL then
      local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(id)
      if CardLabelConf then
        table.insert(itemNameTable, CardLabelConf.label_text)
      end
    elseif type == _G.Enum.GoodsType.GT_FASHION_SUITS then
      local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(id)
      if fashionConf then
        table.insert(itemNameTable, fashionConf.name)
      end
    elseif type == _G.Enum.GoodsType.GT_FASHION then
      local fashionConf = _G.DataConfigManager:GetFashionItemConf(id)
      if fashionConf then
        table.insert(itemNameTable, fashionConf.name)
      end
    elseif type == _G.Enum.GoodsType.GT_SALON then
      local salonConf = _G.DataConfigManager:GetSalonItemConf(id)
      if salonConf then
        table.insert(itemNameTable, salonConf.name)
      end
    end
  end
  for i = 1, #itemNameTable do
    if 1 == i then
      str = itemNameTable[i]
    else
      str = string.format("%s,%s", str, itemNameTable[i])
    end
  end
  return str
end

function EmailModule:ZoneMailDelReq(mail_gid)
  local req = _G.ProtoMessage:newZoneMailDelReq()
  req.mail_gid_list = {}
  table.insert(req.mail_gid_list, mail_gid)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_DEL_REQ, req, self, self.ZoneMailDelRsp)
end

function EmailModule:ZoneMailDelRsp(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.mail_gid_list then
    self.data:RemoveMail(rsp.mail_gid_list)
    self:DispatchEvent(EmailModuleEvent.RemoveMail, rsp.mail_gid_list)
  end
end

function EmailModule:GetEmailItemAllReq()
  local req = _G.ProtoMessage:newZoneMailGetAttachmentReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_GET_ATTACHMENT_REQ, req, self, self.ZoneMailGetAttachmentRsp, true)
end

function EmailModule:DeleteEmailAllReq()
  local req = _G.ProtoMessage:newZoneMailDelReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_MAIL_DEL_REQ, req, self, self.ZoneMailDelRsp)
end

function EmailModule:MailNotify(notify)
  for i = 1, #notify.mail_list do
    self.data:SetMailDatas(notify.mail_list)
    self:DispatchEvent(EmailModuleEvent.RefreshUIEvent)
  end
end

function EmailModule:NoticeNotify(notify)
end

function EmailModule:GetMailState(id)
  return self.data:GetMailState(id)
end

function EmailModule:RemoveNoticeRedPoint(id)
  self.data:RemoveNoticeRedPoint(id)
end

function EmailModule:GetSelectEmailIndex()
  return self.data:GetMailIndex()
end

function EmailModule:SetSelectEmailIndex(index)
  self.data:SetMailIndex(index)
end

function EmailModule:GetSelectMailGid()
  return self.data:GetSelectMailGid()
end

function EmailModule:SetSelectMailGid(id)
  self.data:SetSelectMailGid(id)
end

function EmailModule:OnCmdUpdateNoticeList(NoticeList)
  self.data:SetNoticeListDatas(NoticeList)
end

function EmailModule:InitRedPointData()
  if self.InitNoticeRedPoint == false then
    self.InitNoticeRedPoint = true
  else
    return
  end
  self.data:InitRedPointData()
end

function EmailModule:GetMainInfo(gid)
  return self.data:GetEmailInfo(gid)
end

return EmailModule
