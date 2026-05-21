local HandbookModuleEnum = reload("NewRoco.Modules.System.Handbook.HandbookModuleEnum")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_RegionalSelection_List_C = Base:Extend("UMG_RegionalSelection_List_C")

function UMG_RegionalSelection_List_C:OnConstruct()
end

function UMG_RegionalSelection_List_C:OnDestruct()
end

function UMG_RegionalSelection_List_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.areaInfo = nil
  self.HorizontalBox_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local curSelectData = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurSelectedSeasonHandbookData)
  self:StopAllAnimations()
  self:PlayAnimation(self.Normal)
  self.index = index
  if self.data.type == HandbookModuleEnum.SeasonHandbookTable.Photo then
    self.HorizontalBox_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.data.conf then
      local seasonId = self.data.conf.id
      self.SeasonId = seasonId
      local totalNormalPetNum, collectNormalPetNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, seasonId, ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW)
      local totalSeasonShinyPetNum, collectSeasonShinyPetNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, seasonId, ProtoEnum.PetHandbookSeasonPetType.PHSPT_SHINING)
      local totalNormalShinyPetNum, collectNormalShinyPetNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, seasonId, ProtoEnum.PetHandbookSeasonPetType.PHSPT_NORMAL_SHINING)
      local isBanId = self.data.conf.enter_ban_id
      local totalNum = totalNormalPetNum
      local collectNum = collectNormalPetNum
      local shinyTotalNum = totalSeasonShinyPetNum + totalNormalShinyPetNum
      local collectShinyNum = collectSeasonShinyPetNum + collectNormalShinyPetNum
      local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonId)
      local seasonName = string.format("S%d%s", seasonId, seasonConf.s_title_subtitle)
      self.Text:SetText(seasonName)
      self.ProgressText1:SetText(string.format("%s/", collectNum))
      self.ProgressText2:SetText(totalNum)
      self.ProgressText3:SetText((string.format("%s/%s", collectShinyNum, shinyTotalNum)))
      self.Bg:SetPath(self.data.conf.handbook_icon)
      self.Bg_Mask:SetPath(self.data.conf.handbook_icon)
      self.Dot:SetupKey(126, {
        HandbookModuleEnum.SeasonHandbookTable.Photo,
        seasonId
      })
      if curSelectData.type == self.data.type and curSelectData.id == seasonId then
        self:PlayDefaultSelectAnimation()
      end
      self:IsShowLock(isBanId)
    end
    return
  end
  if _data then
    local conf = _data.conf
    self.Text:SetText(conf.name)
    self.Bg:SetPath(conf.book_res)
    self.Bg_Mask:SetPath(conf.book_res)
    self.Dot:SetupKey(126, {
      HandbookModuleEnum.SeasonHandbookTable.Handbook,
      conf.id
    })
    self.areaInfo = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetAreaHandbookInfo, conf.area_handbook_type)
    local collStr = ""
    if self.areaInfo then
      collStr = string.format("%s/", self.areaInfo.collect_coll_num)
    end
    local maxCount = self:GetMaxCount(conf.area_handbook_type)
    self.ProgressText1:SetText(collStr)
    self.ProgressText2:SetText(maxCount)
    local curSelectAreaId = curSelectData.type == self.data.type and curSelectData.id or nil
    if curSelectAreaId == conf.id then
      self:PlayDefaultSelectAnimation()
    end
    self:IsShowLock(conf.enter_ban_id)
  end
end

function UMG_RegionalSelection_List_C:IsShowLock(banId)
  local isBan = true
  if nil == banId or 0 == banId then
    isBan = false
  else
    local banConf = _G.DataConfigManager:GetUiEnterBanConf(banId)
    local banType = banConf.function_entrance
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, banType, false)
  end
  if isBan then
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Text:SetText(LuaText.lock_area_handbook_2)
  else
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.banId = banId
end

function UMG_RegionalSelection_List_C:PlayDefaultSelectAnimation()
  if self.data.type == HandbookModuleEnum.SeasonHandbookTable.Photo then
    local seasonConf = _G.DataConfigManager:GetSeasonConf(self.SeasonId)
    local seasonName = string.format("S%d%s", self.SeasonId, seasonConf.s_title_subtitle)
    self.Text:SetText(seasonName)
  else
    self.Text:SetText(self.data.conf.name)
  end
  self:PlayAnimation(self.Click_loop, 0, 0)
end

function UMG_RegionalSelection_List_C:GetMaxCount(type)
  local HandBookConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_HANDBOOK)
  local count = 0
  if HandBookConf then
    local confs = HandBookConf:GetAllDatas()
    for key, conf in pairs(confs) do
      for i = 1, #conf.belong_area_handbook do
        if type == conf.belong_area_handbook[i] then
          count = count + 1
        end
      end
    end
  end
  return count
end

function UMG_RegionalSelection_List_C:OnItemSelected(_bSelected)
  if _bSelected then
    if _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetDisableRewardAnimationState) then
      return
    end
    _G.NRCModuleManager:DoCmd(HandbookModuleCmd.SetDisableRewardAnimationState, true, 1)
    self:OnClickItem()
  end
end

function UMG_RegionalSelection_List_C:OnClickItem()
  local isBan = true
  local banId = self.banId
  if nil == banId or 0 == banId then
    isBan = false
  else
    local banConf = _G.DataConfigManager:GetUiEnterBanConf(banId)
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, banConf.function_entrance, true)
  end
  if not isBan then
    _G.NRCAudioManager:PlaySound2DAuto(1237, "UMG_RegionalSelection_List_C:OnItemSelected")
    if self.data.type ~= HandbookModuleEnum.SeasonHandbookTable.Photo then
      _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SelectAreaItem, self.data)
      _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.CloseSeasonHandBook)
      self.Text:SetText(self.data.conf.name)
    end
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_RegionalSelection_List_C:OnItemSelected")
    return
  end
  self:PlayAnimation(self.Click)
  if self.data.type == HandbookModuleEnum.SeasonHandbookTable.Photo then
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SelectAreaItem, self.data)
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenSeasonHandBook, self.SeasonId)
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.CloseHandbookCoverByPlayer)
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCloseAreaHandbookChangPanel)
    _G.NRCAudioManager:PlaySound2DAuto(1237, "UMG_RegionalSelection_List_C:OnItemSelected")
    local seasonConf = _G.DataConfigManager:GetSeasonConf(self.SeasonId)
    local seasonName = string.format("S%d%s", self.SeasonId, seasonConf.s_title_subtitle)
    self.Text:SetText(seasonName)
  end
end

function UMG_RegionalSelection_List_C:UnSelectItem(data)
  local name = ""
  if data.type == HandbookModuleEnum.SeasonHandbookTable.Photo and self.SeasonId ~= data.conf.id then
    self:StopAllAnimations()
    self:PlayAnimation(self.Normal)
    local seasonConf = _G.DataConfigManager:GetSeasonConf(self.SeasonId)
    name = string.format("S%d%s", self.SeasonId, seasonConf.s_title_subtitle)
  elseif data.type == HandbookModuleEnum.SeasonHandbookTable.Handbook and data.conf.area_handbook_type ~= self.data.conf.area_handbook_type then
    self:StopAllAnimations()
    self:PlayAnimation(self.Normal)
    name = self.data.conf.name
  end
  self.Text:SetText(name)
end

function UMG_RegionalSelection_List_C:OnAnimationFinished(anim)
  if anim == self.Click then
    self:PlayAnimation(self.Click_loop, 0)
  end
end

function UMG_RegionalSelection_List_C:OnDeactive()
end

return UMG_RegionalSelection_List_C
