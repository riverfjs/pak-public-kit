local Base = require("NewRoco.Modules.System.MainUI.Res.compass.CompItemNpcBase")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local UMG_CompItem_Pet_C = Base:Extend("UMG_CompItem_Pet_C")

function UMG_CompItem_Pet_C:SetNpcIconPath(IconPath)
  if self.uiData.NpcConfig and self.uiData.NpcConfig.genre == Enum.ClientNpcType.CNT_PETBOSS then
    self.Crown:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Switcher_Boss:SetActiveWidgetIndex(0)
    if self.NRCIcon.SetIconPath then
      self.NRCIcon:SetIconPath(IconPath)
    end
  elseif self.uiData.NpcConfig and self.uiData.NpcConfig.genre == Enum.ClientNpcType.CNT_HOME_NPC then
    if self.uiData.petInfo and self.uiData.petInfo.pet_gid then
      local petData = HomeUtils.GetHomePetAdditionalInfo(self.uiData.petInfo.pet_gid)
      if petData then
        self.NRCIcon:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
      end
    end
    self.Switcher_Boss:SetActiveWidgetIndex(2)
    self.Crown:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.uiData.petInfo and self.uiData.petInfo.productionInfo then
      if HomeIndoorSandbox then
        local output = self.uiData.petInfo.productionInfo
        if not output then
          self:UpdateCrownIcon(UE4.ESlateVisibility.Collapsed, nil)
        end
        if HomeIndoorSandbox:InLocalMasterIndoor() then
          for _, v in ipairs(output) do
            if v.goods_num > 0 then
              local worldMapCfg = self.uiData.WorldMapConfig
              if not worldMapCfg then
                return
              end
              if self.uiData.WorldMapConfig.npcicon_corner_unlock then
                self:UpdateCrownIcon(UE4.ESlateVisibility.HitTestInvisible, self.uiData.WorldMapConfig.npcicon_corner_unlock)
              end
            end
          end
        elseif HomeIndoorSandbox:InOtherHomeIndoor() then
          for _, v in ipairs(output) do
            if v.goods_id == _G.Enum.VisualItem.VI_FURNITURE_COIN then
              local remainRatio = _G.DataConfigManager:GetHomeGlobalConfig("home_pet_left_steal_max").num / 10000
              remainRatio = remainRatio or 0
              if v.goods_num <= v.goods_total_num * remainRatio then
                return
              end
              local worldMapCfg = self.uiData.WorldMapConfig
              if not worldMapCfg then
                return
              end
              if self.uiData.WorldMapConfig.npcicon_corner_unlock then
                self:UpdateCrownIcon(UE4.ESlateVisibility.HitTestInvisible, self.uiData.WorldMapConfig.npcicon_corner_unlock)
              end
              break
            end
          end
        end
      end
    else
      self.Crown_Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.Switcher_Boss:SetActiveWidgetIndex(1)
    self.Crown:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    if self.NRCIcon.SetIconPath then
      self.NRCIcon:SetIconPath(IconPath)
    end
  end
end

function UMG_CompItem_Pet_C:UpdateCrownIcon(visibility, iconPath)
  if self.Crown_Icon and self.Crown_Icon:GetVisibility() ~= visibility then
    self.Crown_Icon:SetVisibility(visibility)
    if visibility ~= UE4.ESlateVisibility.Collapsed and visibility ~= UE4.ESlateVisibility.Hidden then
      if not iconPath then
        return
      end
      self.Crown_Icon:SetPath(self:GetCornerPath(iconPath))
    end
  end
end

return UMG_CompItem_Pet_C
