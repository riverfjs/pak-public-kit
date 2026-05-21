local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")
local UMG_RelationTree_ShiningMedal_C = _G.NRCPanelBase:Extend("UMG_RelationTree_ShiningMedal_C")

function UMG_RelationTree_ShiningMedal_C:OnActive(bondConfId, bHideButton, mutationType)
  self.bHideButton = bHideButton
  self.id = bondConfId
  self:LoadAnimation(0)
  self:OnAddEventListener()
  if not bondConfId or 0 == bondConfId then
    Log.Error("UMG_RelationTree_ShiningMedal_C \228\188\160\229\133\165\231\154\132id\230\151\160\230\149\136")
    return
  end
  self.bondConf = _G.DataConfigManager:GetFashionBondConf(bondConfId)
  if not self.bondConf then
    Log.Error("UMG_RelationTree_ShiningMedal_C \228\188\160\229\133\165\231\154\132id\229\156\168\233\133\141\231\189\174\228\184\173\228\184\141\229\173\152\229\156\168 %s", bondConfId)
    return
  end
  self.pageMapper = self:GetPageMapper(self.bondConf, mutationType)
  self.totalPages = #self.pageMapper
  self:_InitPopup()
end

function UMG_RelationTree_ShiningMedal_C:OnDeactive()
end

function UMG_RelationTree_ShiningMedal_C:OnAddEventListener()
  self:BindInputAction()
  self:SetCommonPopUpInfo()
  self:AddButtonListener(self.LeftBtn.btnLevelUp, self.OnLeftBtnClicked)
  self:AddButtonListener(self.RightBtn.btnLevelUp, self.OnRightBtnClicked)
  self.Video:AddOnEndReached(self, self.MovieDone)
  self.Video:AddOnSeekCompleted(self, self.MovieSeekComplete)
  self:AddButtonListener(self.Play.btnLevelUp, self.OnPlayButtonClicked)
  self:AddButtonListener(self.Pause.btnLevelUp, self.OnPauseButtonClicked)
end

function UMG_RelationTree_ShiningMedal_C:OnRemoveEventListener()
  self:UnBindInputAction()
  self.Video:RemoveOnEndReached(self, self.MovieDone)
end

function UMG_RelationTree_ShiningMedal_C:MovieDone()
  self.Video:Seek(UE.UKismetMathLibrary.FromSeconds(0))
end

function UMG_RelationTree_ShiningMedal_C:MovieSeekComplete()
  self.Video:Pause()
  self:SetBtnVisibility(false)
end

function UMG_RelationTree_ShiningMedal_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.TitleText = _G.LuaText.popup_magic_award
  CommonPopUpData.Call = self
  CommonPopUpData.PopUpType = 2
  CommonPopUpData.HideBtn = self.bHideButton
  CommonPopUpData.ClosePanelHandler = self.OnClickCloseBtn
  local slot
  if self.NRCSafeZone_30 then
    slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.NRCSafeZone_30)
  end
  if not self.bHideButton then
    CommonPopUpData.Btn_LeftHandler = self.OnPopUpLeftBtnClicked
    CommonPopUpData.Btn_RightHandler = self.OnPopUpRightBtnClicked
    CommonPopUpData.Btn_RightText = _G.LuaText.btn_fashion_bond_get
    if slot then
      local currentOffsets = slot:GetOffsets()
      local newOffsets = UE4.FMargin()
      newOffsets.Left = currentOffsets.Left
      newOffsets.Top = 0
      newOffsets.Right = currentOffsets.Right
      newOffsets.Bottom = currentOffsets.Bottom
      slot:SetOffsets(newOffsets)
    end
  elseif slot then
    local currentOffsets = slot:GetOffsets()
    local newOffsets = UE4.FMargin()
    newOffsets.Left = currentOffsets.Left
    newOffsets.Top = 89
    newOffsets.Right = currentOffsets.Right
    newOffsets.Bottom = currentOffsets.Bottom
    slot:SetOffsets(newOffsets)
  end
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp:SetPanelInfo(CommonPopUpData)
  if self.PopUp.Btn_Right and self.PopUp.Btn_Right.NRCSwitcher_0 then
    self.PopUp.Btn_Right.NRCSwitcher_0:SetActiveWidgetIndex(1)
  end
end

function UMG_RelationTree_ShiningMedal_C:OnConstruct()
  self:SetChildViews(self.PopUp, self.Video)
  self.Video:OnConstruct(self)
  self.Video.bAutoPlay = true
  self.curPage = 1
end

function UMG_RelationTree_ShiningMedal_C:OnDestruct()
  self:OnRemoveEventListener()
  self.Video:OnDestruct()
end

function UMG_RelationTree_ShiningMedal_C:_InitPopup()
  if self.totalPages > 1 then
    local initList = {}
    for i = 1, self.totalPages do
      table.insert(initList, {
        onSelectedCaller = self,
        onSelectedCallback = self.OnDotItemSelectedCallback
      })
    end
    self.Dot_List:InitGridView(initList)
    self.Dot_List:SelectItemByIndex(self.curPage - 1)
    self.bDotInit = true
  else
    self.Dot_List:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.bDotInit = false
  end
  self:SwitchToPage(1)
end

function UMG_RelationTree_ShiningMedal_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_MagnificentMagic")
  if mappingContext then
    mappingContext:BindAction("IA_PlayMagicVideo", self, "OnVideoPlayOrPause", UE.ETriggerEvent.Triggered)
  end
end

function UMG_RelationTree_ShiningMedal_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MagnificentMagic")
  if mappingContext then
    mappingContext:UnBindAction("IA_PlayMagicVideo")
  end
end

function UMG_RelationTree_ShiningMedal_C:OnVideoPlayOrPause()
  if self.Video.MediaPlayer:IsPlaying() then
    self:OnPauseButtonClicked()
  else
    self:OnPlayButtonClicked()
  end
end

function UMG_RelationTree_ShiningMedal_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_ShiningMedal_C:OnClickCloseBtn")
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnShiningMedalDetailClosed)
  self:LoadAnimation(2)
end

function UMG_RelationTree_ShiningMedal_C:OnPauseButtonClicked()
  self:SetBtnVisibility(false)
  self.Video:Pause()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_ShiningMedal_C:OnPauseButtonClicked")
end

function UMG_RelationTree_ShiningMedal_C:OnPlayButtonClicked()
  self:SetBtnVisibility(true)
  self.Video:Play()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_ShiningMedal_C:OnPlayButtonClicked")
end

function UMG_RelationTree_ShiningMedal_C:SetBtnVisibility(bPlay)
  if bPlay then
    self.Pause:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Play:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Pause:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Play:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_RelationTree_ShiningMedal_C:OnPcClose()
  self:OnClickCloseBtn()
end

function UMG_RelationTree_ShiningMedal_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_RelationTree_ShiningMedal_C:SwitchToPage(pageIndex)
  self.curPage = pageIndex
  if self.bDotInit then
    self.Dot_List:SelectItemByIndex(self.curPage - 1)
  end
  self.LeftBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.RightBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if 1 == self.curPage then
    self.LeftBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.curPage == self.totalPages then
    self.RightBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetPageByPageMapperObject(self.pageMapper[pageIndex])
end

function UMG_RelationTree_ShiningMedal_C:OnPopUpLeftBtnClicked()
  self:OnClickCloseBtn()
end

function UMG_RelationTree_ShiningMedal_C:OnPopUpRightBtnClicked()
  local suitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdFromBondId, self.id)
  if not suitId then
    Log.Error("\229\189\147\229\137\141\232\191\153\228\184\170BondId\230\178\161\230\156\137\229\175\185\229\186\148\231\154\132SuitId")
    return
  end
  local bHasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, suitId)
  if bHasSuit then
    local defaultIndex = -1
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
    if suitConf and suitConf.lv_up_closet and #suitConf.lv_up_closet > 0 then
      for k, v in ipairs(suitConf.lv_up_closet) do
        if v.lv_item_type == _G.Enum.GoodsType.GT_FASHION_BOND then
          defaultIndex = k - 1
          break
        end
      end
    end
    if defaultIndex >= 0 then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceClosetPanel, nil, true, true, suitId, defaultIndex, nil, nil, true)
    else
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceClosetPanel, nil, true, true, suitId, nil, nil, nil, true)
    end
    self:DoClose()
  else
    local bCanBuyInMonthlyShop = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSuitAtMonthlyShop, suitId)
    local bCanBuyInExchangeShop = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSuitAtExchangeShop, suitId)
    if bCanBuyInMonthlyShop then
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
      if suitConf then
        local packageId = suitConf and suitConf.package_id
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenTryOnByPackageId, packageId, suitId)
      end
    elseif bCanBuyInExchangeShop then
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OpenMainPanel, 3)
    else
      Log.Error(string.format("UMG_RelationTree_ShiningMedal_C:OnPopUpRightBtnClicked \229\189\147\229\137\141\229\165\151\232\163\133%s\228\184\141\229\143\175\232\180\173\228\185\176\239\188\140\230\156\137\233\151\174\233\162\152\239\188\129", suitId))
    end
  end
end

function UMG_RelationTree_ShiningMedal_C:OnLeftBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_RelationTree_ShiningMedal_C:OnLeftBtnClicked")
  local newPage = math.clamp(self.curPage - 1, 1, self.totalPages)
  self:SwitchToPage(newPage)
end

function UMG_RelationTree_ShiningMedal_C:OnRightBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_RelationTree_ShiningMedal_C:OnRightBtnClicked")
  local newPage = math.clamp(self.curPage + 1, 1, self.totalPages)
  self:SwitchToPage(newPage)
end

function UMG_RelationTree_ShiningMedal_C:OnDotItemSelectedCallback(data, index)
  if self.curPage == index then
    return
  end
  local newPage = math.clamp(index, 1, self.totalPages)
  self:SwitchToPage(newPage)
end

function UMG_RelationTree_ShiningMedal_C:SetPageByPageMapperObject(mapper)
  if not mapper then
    Log.Error("UMG_RelationTree_ShiningMedal_C:SetPageByPageMapperObject \228\188\160\229\133\165\231\169\186Mapper!")
    return
  end
  self.Switcher_0:SetActiveWidgetIndex(mapper.switcherIndex)
  if 0 == mapper.switcherIndex then
    self.Picture:SetPath(mapper.imagePath)
    if string.IsNilOrEmpty(mapper.iconPath) then
      self.Image_Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Image_Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Image_Icon:SetPath(mapper.iconPath)
    end
  elseif 1 == mapper.switcherIndex then
    self.Video:CloseMedia()
    local paramTable = {
      source = mapper.videoPath,
      needAutoPlay = true,
      isLoop = false
    }
    self.Video:OpenMediaPanelByParamTable(paramTable)
    self:SetBtnVisibility(true)
  elseif 2 == mapper.switcherIndex then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(mapper.suitId)
    if suitConf then
      self.ItemName:SetText(suitConf.name)
      self.Protagonist:SetPath(suitConf.suits_icon_big)
      local iconBase = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BigHeadIcon256/"
      local IconPath = string.format("%s%d.%d", iconBase, suitConf.petbase_id[1], suitConf.petbase_id[1])
      if suitConf.suits_original_id and 0 ~= suitConf.suits_original_id then
        local id = string.format("%s_1", suitConf.petbase_id[1])
        IconPath = string.format("%s%s.%s", iconBase, id, id)
      end
      self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PetHeadIcon:SetPath(IconPath)
      local componentInitList = {}
      local fashionIds = suitConf.item_id
      if fashionIds and #fashionIds > 0 then
        for k, v in ipairs(fashionIds) do
          table.insert(componentInitList, {
            ItemId = v,
            bPendingPurchase = false,
            bHasOwned = true,
            Color = "#FFFFFFFF"
          })
        end
      end
      self.GridView_ClothingItem:InitGridView(componentInitList)
    else
      Log.Error("UMG_RelationTree_ShiningMedal_C:SetPageByPageMapperObject Mapper\229\189\147\228\184\173\229\175\185\229\186\148\231\154\132\229\188\130\232\137\178\229\165\151\232\163\133\233\133\141\231\189\174\230\178\161\230\156\137\230\137\190\229\136\176\239\188\140id\228\184\186%s", mapper.suitId)
    end
  elseif 3 == mapper.switcherIndex then
    local itemList = self:GetGlassyItemList()
    if itemList and #itemList > 0 then
      self.GridView_ClothingItem_1:InitGridView(itemList)
    end
    self:SetPetIcon()
  end
  self.Text1:SetText(mapper.desc)
  if mapper.bShowLabel then
    self.HandHoldingPrivilege:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.HandHoldingPrivilege:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_RelationTree_ShiningMedal_C:GetPageMapper(bondConf, mutationType)
  if not bondConf then
    return {}
  end
  if bondConf.fashion_bond_source == Enum.FashionBondSource.FBS_REWARD then
    return self:GetRewardPageMapper(bondConf)
  end
  return self:GetPetPageMapper(bondConf, mutationType)
end

function UMG_RelationTree_ShiningMedal_C:GetRewardPageMapper(bondConf)
  local result = {}
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.gender == Enum.ESexValue.SEX_MALE then
    table.insert(result, {
      switcherIndex = 1,
      desc = bondConf.popup_text_callout or "",
      videoPath = bondConf.popup_callout_male
    })
  else
    table.insert(result, {
      switcherIndex = 1,
      desc = bondConf.popup_text_callout or "",
      videoPath = bondConf.popup_callout_female
    })
  end
  return result
end

function UMG_RelationTree_ShiningMedal_C:GetPetPageMapper(bondConf, mutationType)
  local result = {}
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local videoPath = bondConf.popup_image_male
  local imagePath = bondConf.fashion_bond_album_male
  local iconPath = bondConf.fashion_bond_icon
  local gender = 1
  if player and 2 == player.gender then
    videoPath = bondConf.popup_image_female
    imagePath = bondConf.fashion_bond_album_female
    gender = 2
  end
  mutationType = mutationType or _G.Enum.MutationDiffType.MDT_NONE
  local bIsHeterochrome = 0 ~= mutationType & _G.Enum.MutationDiffType.MDT_SHINING
  local bIsGlassy = 0 ~= mutationType & _G.Enum.MutationDiffType.MDT_GLASS
  if bIsHeterochrome then
    local heteroChromeSuitId
    if bondConf.color_suits_id and #bondConf.color_suits_id > 0 then
      for k, v in ipairs(bondConf.color_suits_id) do
        local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v)
        if suitConf and suitConf.suits_original_id and suitConf.suits_original_id > 0 and suitConf.gender == gender then
          heteroChromeSuitId = v
          break
        end
      end
    end
    if heteroChromeSuitId then
      local bShowHeterochrome = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSuitTime, heteroChromeSuitId)
      if bShowHeterochrome then
        table.insert(result, {
          switcherIndex = 2,
          desc = self.bondConf.popup_text_color,
          bShowLabel = false,
          suitId = heteroChromeSuitId
        })
      end
    end
  end
  if bIsGlassy then
    table.insert(result, {
      switcherIndex = 3,
      desc = self:GetGlassyDesc(),
      bShowLabel = false
    })
  end
  if bondConf.fashion_bond_quality == _G.Enum.FashionBondQuality.FBQ_S then
    table.insert(result, {
      switcherIndex = 1,
      desc = self.bondConf.popup_text_interact or "",
      bShowLabel = true,
      videoPath = videoPath
    })
    table.insert(result, {
      switcherIndex = 0,
      desc = self.bondConf.popup_text_normal or "",
      bShowLabel = false,
      imagePath = imagePath,
      iconPath = iconPath
    })
  else
    table.insert(result, {
      switcherIndex = 0,
      desc = self.bondConf.popup_text_normal or "",
      bShowLabel = false,
      imagePath = imagePath,
      iconPath = iconPath
    })
  end
  return result
end

function UMG_RelationTree_ShiningMedal_C:GetGlassyItemList()
  local itemList = {}
  local suitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdFromBondId, self.id)
  if suitId then
    local tintType = {}
    if self.bondConf then
      local bondQuality = self.bondConf.fashion_bond_quality
      if bondQuality then
        local bondTintConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BOND_TINT_CONF):GetAllDatas()
        for _, v in pairs(bondTintConf or {}) do
          if v.fashion_bond_quality == bondQuality then
            tintType = v.tint_type
          end
        end
      end
    end
    if #tintType > 0 then
      local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
      if suitConf and suitConf.item_id then
        local fashionIds = suitConf.item_id
        if fashionIds then
          for _, item in pairs(fashionIds) do
            for _, type in pairs(tintType) do
              local itemConf = _G.DataConfigManager:GetFashionItemConf(item)
              if itemConf.type == type then
                table.insert(itemList, itemConf)
                break
              end
            end
          end
        end
      end
    end
  end
  return itemList
end

function UMG_RelationTree_ShiningMedal_C:GetGlassyDesc()
  local str = ""
  local itemList = self:GetGlassyItemList()
  local itemName1, itemName2
  for _, item in pairs(itemList or {}) do
    if item then
      if not itemName1 then
        itemName1 = item.type_name
      else
        itemName2 = itemName2 or item.type_name
      end
    end
  end
  local suitName
  local suitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdFromBondId, self.id)
  if suitId then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
    if suitConf then
      suitName = suitConf.name
    end
  end
  local desc
  if self.bondConf then
    desc = self.bondConf.popup_text_tint
    str = string.format(desc, suitName or "", itemName1 or "", itemName2 or "")
  end
  return str
end

function UMG_RelationTree_ShiningMedal_C:SetPetIcon()
  local suitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdFromBondId, self.id)
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if suitConf then
    local baseConfID = suitConf.petbase_id[1]
    if baseConfID then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(baseConfID)
      if petBaseConf then
        local _scale = petBaseConf.report_res_ui_percentage and petBaseConf.report_res_ui_percentage > 0 and petBaseConf.report_res_ui_percentage or 1
        self.CanvasPanel_127:SetRenderScale(UE4.FVector2D(_scale, _scale))
        self.PetImage:SetPath(petBaseConf.JL_res)
      end
    end
  end
end

return UMG_RelationTree_ShiningMedal_C
