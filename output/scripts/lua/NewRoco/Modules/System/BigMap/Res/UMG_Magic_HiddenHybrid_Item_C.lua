local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local UMG_Magic_HiddenHybrid_Item_C = Base:Extend("UMG_Magic_HiddenHybrid_Item_C")

function UMG_Magic_HiddenHybrid_Item_C:OnConstruct()
end

function UMG_Magic_HiddenHybrid_Item_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  if self.uiData.bOwlSanctuary then
    self:SetSelectable(false)
    self.Select1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Select1:Setvisibility(UE4.ESlateVisibility.Visible)
    self:SetSelectable(true)
  end
  self.evoDatas = _data.evoDatas
  self.firstStageBaseId = nil
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    local VisIndex = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, self.uiData.fruit_uin) or nil
    if self.uiData.bOwlSanctuary then
      self.Text_Sort:SetText(string.format("%sP", VisIndex))
    elseif 0 ~= self.uiData.isFruit then
      self.Text_Sort:SetText(string.format("%sP", VisIndex))
    end
    if 1 == self.uiData.isFruit then
      self.Team:SetVisibility(UE4.ESlateVisibility.Visible)
      if self.uiData.fruit_uin == playerUin then
        self.NRCSwitcher_65:SetActiveWidgetIndex(1)
      else
        self.NRCSwitcher_65:SetActiveWidgetIndex(0)
      end
    end
  end
  self:SetIcon()
end

function UMG_Magic_HiddenHybrid_Item_C:OnItemSelected(_bSelected)
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_Magic_HiddenHybrid_Item_C:OnItemSelected")
  self:StopAllAnimations()
  if false == _bSelected and self.IsPlayClickOut then
    self.IsPlayClickOut = false
    return
  end
  if _bSelected then
    local petBaseConfId
    if self.uiData.FirstStageBaseConf then
      petBaseConfId = self.uiData.FirstStageBaseConf
    else
      petBaseConfId = self.uiData.petBaseConfId
    end
    local param = {
      petBaseConfId = petBaseConfId,
      petDataList = self.evoDatas,
      NotFound = self.IsNotFound,
      caller = self,
      callBack = self.ClearSelect,
      isFruit = self.uiData.isFruit
    }
    _G.NRCModeManager:DoCmd(_G.BigMapModuleCmd.OpenNourishBigMapTips, param)
    self:PlayAnimation(self.Click)
  else
    self:PlayAnimation(self.Click_out)
  end
end

function UMG_Magic_HiddenHybrid_Item_C:ClearSelect()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.IsPlayClickOut = true
  self:PlayAnimation(self.Click_out)
end

function UMG_Magic_HiddenHybrid_Item_C:SetIcon()
  if self.uiData.bOwlSanctuary and self.uiData.petBaseConfId == nil then
    self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.wenHao:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Fruit:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local cruTime = _G.ZoneServer:GetServerTime() / 1000
    local slotstamp = self.uiData.slot_active_timestamp
    if slotstamp and cruTime - slotstamp < 0 then
      self.NRCSwitcher_40:SetActiveWidgetIndex(3)
      return
    end
    self.NRCSwitcher_40:SetActiveWidgetIndex(2)
    return
  end
  self.NRCSwitcher_40:SetActiveWidgetIndex(0)
  local petBaseConfId
  if self.uiData.FirstStageBaseConf then
    petBaseConfId = self.uiData.FirstStageBaseConf
  else
    petBaseConfId = self.uiData.petBaseConfId
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseConfId)
  local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  local isBattleEnemy = self.uiData.isBattleEnemy
  local accessHandbookPetDic = {}
  local isVisitState = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  local isVisitOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
  if isVisitState and false == isVisitOwner then
    accessHandbookPetDic = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetAccessHandbookData)
  end
  self.IsNotFound = true
  self.IsBelongCamp = false
  if 1 == self.uiData.isFruit then
    for i = 1, #self.evoDatas do
      if self.evoDatas[i].state ~= _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
        self.IsNotFound = false
        self.IsBelongCamp = true
        break
      end
    end
  elseif #self.evoDatas > 0 then
    for i = 1, #self.evoDatas do
      if isVisitState and false == isVisitOwner and nil ~= accessHandbookPetDic then
        local evoPetId = self.evoDatas[i].petBaseConfId
        local handPetData = accessHandbookPetDic[evoPetId]
        if handPetData then
          if handPetData.state ~= _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
            self.IsNotFound = false
          end
          if handPetData.caught_camp and #handPetData.caught_camp > 0 then
            for j = 1, #handPetData.caught_camp do
              if handPetData.caught_camp[j] == self.uiData.CampId then
                self.IsBelongCamp = true
                break
              end
            end
          end
        end
        if not self.IsNotFound and self.IsBelongCamp then
          break
        end
      else
        local HandBookData = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandBookData, self.evoDatas[i].handbookId)
        if HandBookData and HandBookData.Collection and HandBookData.Collection.record then
          local record = HandBookData.Collection.record
          for k = 1, #record do
            if record[k].state ~= _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
              self.IsNotFound = false
            end
            local CaughtCamp = record[k].caught_camp
            if CaughtCamp and #CaughtCamp > 0 then
              for j = 1, #CaughtCamp do
                if CaughtCamp[j] == self.uiData.CampId and record[k].pet_base_id == self.evoDatas[i].petBaseConfId then
                  self.IsBelongCamp = true
                  break
                end
              end
            end
            if not self.IsNotFound and self.IsBelongCamp then
              break
            end
          end
        end
        if not self.IsNotFound and self.IsBelongCamp then
          break
        end
      end
    end
  end
  self.NpcIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.IsNotFound and 0 == self.uiData.isFruit then
    self.iconPath = NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath)
    self.wenHao:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Default:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#DCD5C0FF"))
    self:SetUnFoundIcon()
  else
    self.Default:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#272727FF"))
    if 1 == self.uiData.isFruit or not self.IsNotFound and self.IsBelongCamp or isBattleEnemy then
      self.ItemIcon:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
      self.ItemIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.wenHao:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if 1 == self.uiData.isFruit then
        local cruTime = _G.ZoneServer:GetServerTime() / 1000
        local fruitstamp = self.uiData.fruit_active_timestamp
        local slotstamp = self.uiData.slot_active_timestamp
        if fruitstamp and slotstamp and (cruTime - fruitstamp < 0 or cruTime - slotstamp < 0) then
          self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.Icon_Mask:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
          self.Countdown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    else
      self.ItemIcon:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
      self.ItemIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Icon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Icon_Mask:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
      self.wenHao:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self.Fruit:SetVisibility(1 == self.uiData.isFruit and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Hidden)
end

function UMG_Magic_HiddenHybrid_Item_C:OnDeactive()
  self:ReleaseRequest()
end

function UMG_Magic_HiddenHybrid_Item_C:SetUnFoundIcon()
  self.NpcIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NpcIcon:SetRenderOpacity(0)
  local materialPath = "MaterialInstanceConstant'/Game/NewRoco/Modules/System/TeamBattle/Res/MI_UI_Silhouettew.MI_UI_Silhouettew'"
  self.NpcIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
  self.MatRequest = NRCResourceManager:LoadResAsync(self, materialPath, 255, 0, self.OnLoadIconMaterialSucceed, self.OnLoadIconMaterialFail, nil)
end

function UMG_Magic_HiddenHybrid_Item_C:OnLoadIconMaterialSucceed(_, asset)
  if self.iconPath and asset and self.NpcIcon and UE4.UObject.IsValid(self.NpcIcon) then
    self.NpcIcon.MaterialInstance = asset
    self.NpcIcon:SetBrushFromMaterial(asset)
    self.IconRequest = NRCResourceManager:LoadResAsync(self, self.iconPath, 255, 0, self.OnLoadImageResSucc, nil, nil)
  end
end

function UMG_Magic_HiddenHybrid_Item_C:OnLoadIconMaterialFail()
  if self.iconPath ~= "" then
    self.NpcIcon:SetPath(self.iconPath)
    self.NpcIcon:SetRenderOpacity(1)
  end
end

function UMG_Magic_HiddenHybrid_Item_C:OnLoadImageResSucc(req, asset)
  if self.NpcIcon and UE4.UObject.IsValid(self.NpcIcon) then
    local material = self.NpcIcon:GetDynamicMaterial()
    material:SetTextureParameterValue("SpriteTexture", asset)
    self.NpcIcon:SetRenderOpacity(1)
  end
end

function UMG_Magic_HiddenHybrid_Item_C:ReleaseRequest()
  if self.MatRequest then
    _G.NRCResourceManager:UnLoadRes(self.MatRequest)
    self.MatRequest = nil
  end
  if self.IconRequest then
    _G.NRCResourceManager:UnLoadRes(self.IconRequest)
    self.IconRequest = nil
  end
end

return UMG_Magic_HiddenHybrid_Item_C
