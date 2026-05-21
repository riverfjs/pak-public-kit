local TaskEnum = require("NewRoco.Modules.Core.Battle.Common.TaskEnum")
local UMG_NpcInfo_SeasonNpc_C = _G.NRCPanelBase:Extend("UMG_NpcInfo_SeasonNpc_C")

function UMG_NpcInfo_SeasonNpc_C:OnActive()
end

function UMG_NpcInfo_SeasonNpc_C:OnDeactive()
end

function UMG_NpcInfo_SeasonNpc_C:OnAddEventListener()
end

function UMG_NpcInfo_SeasonNpc_C:OnRemoveEventListener()
end

function UMG_NpcInfo_SeasonNpc_C:OnConstruct()
end

function UMG_NpcInfo_SeasonNpc_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_NpcInfo_SeasonNpc_C:OnEnable(entryId, worldMapConf)
  self:OnAddEventListener()
  self.entryId = entryId
  self.worldMapConf = worldMapConf
  self.TaskIcon:SetPath(self:GetMapIconPath(self.worldMapConf.npcicon_unlock))
  self.npcName_5:SetText(self.worldMapConf.element_text_name)
  self.TaskDesc:SetText(self.worldMapConf.worldmap_npc_des)
  self.PetIcon:SetPath(self:GetMapIconPath(self.worldMapConf.world_map_NPCicon_des))
  self.NRCText_Hint:SetText(self.worldMapConf.dungeon_type_des)
  self.CabinIcon:SetPath(self.worldMapConf.dungeon_title_bg)
  local seasonId = 0
  local seasonInfo = NRCModuleManager:DoCmd(SeasonIntegrationModuleCmd.GetSeasonInfo)
  if seasonInfo then
    seasonId = seasonInfo.season_id
  end
  local showSeasonId = worldMapConf.belong_to_season
  if showSeasonId and seasonId and showSeasonId == seasonId then
    self.AwardCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local ReqBatchParam = {}
    ReqBatchParam.Caller = self
    ReqBatchParam.rspHandler = self.RefreshAwardList
    ReqBatchParam.reqTag = "UMG_NpcInfo_SeasonNpc_C"
    ReqBatchParam.shopIDList = worldMapConf.map_tips_param
    if worldMapConf.map_tips_param and type(worldMapConf.map_tips_param) == "table" and #worldMapConf.map_tips_param > 0 then
      NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdBatchGetShopData, ReqBatchParam)
    end
  else
    self.AwardCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if showSeasonId and showSeasonId > 0 then
    local seasonConf = DataConfigManager:GetSeasonConf(showSeasonId)
    if seasonConf then
      local bFinished = self:HasFinishSeasonTask(seasonConf.season_task_paragraph)
      if bFinished then
        self.UnfinishedPrompt:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.UnfinishedPrompt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
end

function UMG_NpcInfo_SeasonNpc_C:RefreshAwardList(rsp)
  if 0 == rsp.ret_info.ret_code then
    local awardList = {}
    local shopList = rsp.shop_datas
    if shopList and #shopList > 0 then
      for i, shopDatas in ipairs(shopList) do
        local goodsData = shopDatas.goods_data
        if goodsData and #goodsData > 0 then
          for j, goodData in ipairs(goodsData) do
            local showData = {}
            local goodsId = goodData.goods_id
            local goodsConf = DataConfigManager:GetNormalShopConf(goodsId)
            if goodsConf then
              showData.itemType = goodsConf.Type or 0
              showData.itemId = goodsConf.item_id or 0
              showData.bShowNum = false
              showData.bShowTip = true
              showData.IsCanClick = true
              table.insert(awardList, showData)
            end
          end
        end
      end
      if #awardList > 0 then
        self.TaskAwardList:InitGridView(awardList)
      else
        self.AwardCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  else
    self.AwardCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_NpcInfo_SeasonNpc_C:OnSpecialTransBtnClicked()
  self.module:DoCommonTransfer(self.entryId, self.worldMapConf, nil, true)
end

function UMG_NpcInfo_SeasonNpc_C:OnTransBtnClicked()
  self.module:DoCommonTransfer(self.entryId, self.worldMapConf, nil, false)
end

function UMG_NpcInfo_SeasonNpc_C:OnForbiddenBtnClicked()
  local tip = DataConfigManager:GetLocalizationConf("season_scene_teleport_locked").msg
  local tip1 = string.format(tip, self.worldMapConf.element_text_name)
  NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tip1)
end

function UMG_NpcInfo_SeasonNpc_C:SetSpecialTransBtnState()
end

function UMG_NpcInfo_SeasonNpc_C:GetMapIconPath(Icon)
  local param = string.split(Icon, "/")
  if #param > 1 then
    return Icon, true
  else
    return self.module:GetBigMapIconRes(Icon)
  end
end

function UMG_NpcInfo_SeasonNpc_C:HasFinishSeasonTask(paragraphList)
  local bOpen = false
  local bFinished = false
  if paragraphList and #paragraphList > 0 then
    for k, paragraphId in ipairs(paragraphList) do
      local paragraphType = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetParagraphType, paragraphId)
      if paragraphType == TaskEnum.TaskParagraphFinishState.open then
        bOpen = true
      end
    end
  end
  if bOpen then
    return false
  else
    return true
  end
end

return UMG_NpcInfo_SeasonNpc_C
