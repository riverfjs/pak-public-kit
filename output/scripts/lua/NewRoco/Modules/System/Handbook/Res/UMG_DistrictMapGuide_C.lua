local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local HandbookModuleEnum = reload("NewRoco.Modules.System.Handbook.HandbookModuleEnum")
local UMG_DistrictMapGuide_C = _G.NRCPanelBase:Extend("UMG_DistrictMapGuide_C")

function UMG_DistrictMapGuide_C:OnActive(petBaseId, districtMapGuideConf)
  self:SetCommonPopUpInfo(self.PopUp)
  self.PopUp:SetTitleTextInfo()
  self.allTypes = {
    HandbookModuleEnum.District.Nature,
    HandbookModuleEnum.District.Talent,
    HandbookModuleEnum.District.Blood,
    HandbookModuleEnum.District.Skill
  }
  local selectTeamType = districtMapGuideConf.selectTeamType
  local selectIconType = districtMapGuideConf.selectIconType
  selectTeamType = selectTeamType or _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetDistrictMapGuideSelectRecord)
  self.curPetAttributes = {}
  local petData = districtMapGuideConf.petData
  if petData then
    self.petData = petData
    self.curPetAttributes[HandbookModuleEnum.District.Nature] = {
      petData.nature
    }
    self.curPetAttributes[HandbookModuleEnum.District.Blood] = {
      petData.blood_id
    }
    if petData.attribute_info then
      local function addToPetOwnedTalent(ownedTalent, attrType, attrData)
        if attrData and 0 ~= attrData.talent then
          table.insert(ownedTalent, attrType)
        end
      end
      
      local petAttributeInfo = petData.attribute_info
      local petOwnedTalent = {}
      self.curPetAttributes[HandbookModuleEnum.District.Talent] = petOwnedTalent
      addToPetOwnedTalent(petOwnedTalent, Enum.AttributeType.AT_HPMAX, petAttributeInfo.hp)
      addToPetOwnedTalent(petOwnedTalent, Enum.AttributeType.AT_PHYATK, petAttributeInfo.attack)
      addToPetOwnedTalent(petOwnedTalent, Enum.AttributeType.AT_SPEATK, petAttributeInfo.special_attack)
      addToPetOwnedTalent(petOwnedTalent, Enum.AttributeType.AT_PHYDEF, petAttributeInfo.defense)
      addToPetOwnedTalent(petOwnedTalent, Enum.AttributeType.AT_SPEDEF, petAttributeInfo.special_defense)
      addToPetOwnedTalent(petOwnedTalent, Enum.AttributeType.AT_SPEED, petAttributeInfo.speed)
    end
    local petOwnedSkill_World = {}
    local petOwnedSkill_PVP = {}
    self.curPetAttributes[HandbookModuleEnum.District.Skill] = {teamTypeEnable = true}
    self.curPetAttributes[HandbookModuleEnum.District.Skill][_G.Enum.PlayerTeamType.PTT_BIG_WORLD] = petOwnedSkill_World
    self.curPetAttributes[HandbookModuleEnum.District.Skill][_G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1] = petOwnedSkill_PVP
    local skillData = petData.skill and petData.skill.skill_data
    if skillData then
      local petSkillData = skillData
      local pvpSkillMap = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPvpSkillData)
      for _, skillDataItem in ipairs(petSkillData) do
        local skillId = skillDataItem.id
        if skillId then
          local isEquipped = skillDataItem.is_equipped and skillDataItem.pos and skillDataItem.pos > 0 and skillDataItem.pos <= 4
          if isEquipped then
            table.insert(petOwnedSkill_World, skillId)
          end
          if pvpSkillMap and pvpSkillMap[skillId] or not pvpSkillMap and isEquipped then
            table.insert(petOwnedSkill_PVP, skillId)
          end
        end
      end
    end
  end
  self.petBaseId = petBaseId
  local statistics = self:GetStatistics()
  self.curSelectTeamType = selectTeamType and selectTeamType >= 1 and selectTeamType <= 2 and selectTeamType or _G.Enum.PlayerTeamType.PTT_BIG_WORLD
  self.curSelectIconType = selectIconType or HandbookModuleEnum.District.Nature
  self.districtMapDic = self:CreateTeamDataDic(statistics)
  self.iconTabDatas = self:CreateIconTabDatas()
  self.tableDatas = self:CreateTabDatas()
  self.SkipIconAudio = true
  self.SkipTeamAudio = true
  self.ListTab:InitGridView(self.tableDatas)
  self.ListTab1:InitGridView(self.iconTabDatas)
  self.ListTab:SelectItemByIndex(self.curSelectTeamType - 1)
  self.ListTab1:SelectItemByIndex(self.curSelectIconType)
  self.Text_describe:SetText(LuaText.Pet_Recommend_count_tips)
  if petData then
    if petData.base_conf_id then
      self.TitleIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.TitleIcon:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
    else
      self.TitleIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if petData.level then
      self.Level:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Level:SetText(petData.level)
    else
      self.Level:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.TitleIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Level:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:LoadAnimation(0)
end

function UMG_DistrictMapGuide_C:OnDeactive()
end

function UMG_DistrictMapGuide_C:OnAddEventListener()
  self:RegisterEvent(self, HandbookModuleEvent.OnClickDistrictTabItemData, self.OnSelectTeamTableItem)
  self:RegisterEvent(self, HandbookModuleEvent.OnClickDistrictIconItemData, self.OnSelectIconTableItem)
  self:RegisterEvent(self, HandbookModuleEvent.OnPetStatUpdate, self.OnPetStatUpdate)
end

function UMG_DistrictMapGuide_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:OnAddEventListener()
end

function UMG_DistrictMapGuide_C:OnDestruct()
  self:UnRegisterEvent(self, HandbookModuleEvent.OnClickDistrictTabItemData, self.OnSelectTeamTableItem)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnClickDistrictIconItemData, self.OnSelectIconTableItem)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnPetStatUpdate, self.OnPetStatUpdate)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.RecordDistrictMapGuideSelect, self.curSelectTeamType)
end

function UMG_DistrictMapGuide_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.PopUpType = 2
  CommonPopUpData.ClosePanelHandler = self.OnClickButton
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_DistrictMapGuide_C:GetStatistics()
  local HandbookModule = _G.NRCModuleManager:GetModule("HandbookModule")
  if HandbookModule and HandbookModule.data then
    return HandbookModule.data:GetHandbookStatData(self.petBaseId)
  end
  return nil
end

function UMG_DistrictMapGuide_C:CreateTeamDataDic(statistics)
  local dic = {}
  if nil == statistics then
  elseif 1 == #statistics then
    local statInfo = statistics[1]
    dic[statInfo.team_type] = self:CreateDesListDatas(statInfo.team_type, HandbookModuleEnum.District.Nature, statInfo.top_nature)
    dic[statInfo.team_type] = self:CreateDesListDatas(statInfo.team_type, HandbookModuleEnum.District.Talent, statInfo.top_talent)
    dic[statInfo.team_type] = self:CreateDesListDatas(statInfo.team_type, HandbookModuleEnum.District.Blood, statInfo.top_blood)
    dic[statInfo.team_type] = self:CreateDesListDatas(statInfo.team_type, HandbookModuleEnum.District.Skill, statInfo.top_skill)
    local pvpTeam = _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1
    dic[pvpTeam] = self:CreateDesListDatas(pvpTeam, HandbookModuleEnum.District.Nature, {})
    dic[pvpTeam] = self:CreateDesListDatas(pvpTeam, HandbookModuleEnum.District.Talent, {})
    dic[pvpTeam] = self:CreateDesListDatas(pvpTeam, HandbookModuleEnum.District.Blood, {})
    dic[pvpTeam] = self:CreateDesListDatas(pvpTeam, HandbookModuleEnum.District.Skill, {})
  else
    for i = 1, #statistics do
      local statInfo = statistics[i]
      dic[statInfo.team_type] = {}
      dic[statInfo.team_type][HandbookModuleEnum.District.Nature] = self:CreateDesListDatas(statInfo.team_type, HandbookModuleEnum.District.Nature, statInfo.top_nature)
      dic[statInfo.team_type][HandbookModuleEnum.District.Talent] = self:CreateDesListDatas(statInfo.team_type, HandbookModuleEnum.District.Talent, statInfo.top_talent)
      dic[statInfo.team_type][HandbookModuleEnum.District.Blood] = self:CreateDesListDatas(statInfo.team_type, HandbookModuleEnum.District.Blood, statInfo.top_blood)
      dic[statInfo.team_type][HandbookModuleEnum.District.Skill] = self:CreateDesListDatas(statInfo.team_type, HandbookModuleEnum.District.Skill, statInfo.top_skill)
    end
  end
  return dic
end

function UMG_DistrictMapGuide_C:IsDisableAllDatas(statistics)
  if nil == statistics then
    return true
  end
  for index, stat in ipairs(statistics) do
    if nil == stat.top_nature or nil == stat.top_talent or nil == stat.top_blood or nil == stat.top_skill then
      return true
    end
  end
  return false
end

function UMG_DistrictMapGuide_C:CreateListDatas(teamType, handbookType)
  local teamDic = self.districtMapDic and self.districtMapDic[teamType]
  local list = teamDic and teamDic[handbookType]
  if nil == list then
    return {}
  end
  return list
end

function UMG_DistrictMapGuide_C:OnUpdateDataList()
  local handbookType = self.curSelectIconType
  local teamType = self.curSelectTeamType
  local curDataList = {}
  local titleStr = HandbookModuleEnum.DistrictDesc[handbookType] or ""
  self.TitleText:SetText(titleStr)
  curDataList = self:CreateListDatas(teamType, handbookType)
  if 0 == #curDataList then
    self.Switcher:SetActiveWidgetIndex(1)
  else
    self.Switcher:SetActiveWidgetIndex(0)
    self.List:InitList(curDataList)
    self.List:SetScrollOffset(0)
  end
end

function UMG_DistrictMapGuide_C:OnSelectIconTableItem(handbookType)
  if self.SkipIconAudio then
    self.SkipIconAudio = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_DistrictMapGuide_C:OnSelectIconTableItem")
  end
  self.curSelectIconType = handbookType
  self:OnUpdateDataList()
end

function UMG_DistrictMapGuide_C:OnPetStatUpdate()
  local statistics = self:GetStatistics()
  self.districtMapDic = self:CreateTeamDataDic(statistics)
  self:OnUpdateDataList()
end

function UMG_DistrictMapGuide_C:OnSelectTeamTableItem(teamType)
  if self.SkipTeamAudio then
    self.SkipTeamAudio = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401016, "UMG_DistrictMapGuide_C:OnSelectTeamTableItem")
  end
  self.curSelectTeamType = teamType
  self:OnUpdateDataList()
end

function UMG_DistrictMapGuide_C:CreateDesListDatas(teamType, HandbookEnum, datas)
  local list = {}
  if datas and datas.top_ids then
    for i = 1, #datas.top_ids do
      if 0 ~= datas.top_ids[i] then
        local info = {
          type = HandbookEnum,
          petData = self.petData,
          data = datas.top_ids[i],
          ratio = datas.top_ratios[i]
        }
        table.insert(list, info)
      end
    end
    local ownedAttributes = self.curPetAttributes and self.curPetAttributes[HandbookEnum]
    if ownedAttributes then
      if ownedAttributes.teamTypeEnable then
        ownedAttributes = ownedAttributes[teamType]
      end
      for _, info in ipairs(list) do
        if table.contains(ownedAttributes, info.data) then
          info.markOwned = true
        end
      end
    end
  end
  return list
end

function UMG_DistrictMapGuide_C:CreateIconTabDatas()
  local unselectIcon_1 = _G.DataConfigManager:GetPetGlobalConfig("pet_recommend_option_icon_nature_unselect").str
  local unselectIcon_2 = _G.DataConfigManager:GetPetGlobalConfig("pet_recommend_option_icon_talent_unselect").str
  local unselectIcon_3 = _G.DataConfigManager:GetPetGlobalConfig("pet_recommend_option_icon_blood_unselect").str
  local unselectIcon_4 = _G.DataConfigManager:GetPetGlobalConfig("pet_recommend_option_icon_skill_unselect").str
  local selectIcon_1 = _G.DataConfigManager:GetPetGlobalConfig("pet_recommend_option_icon_nature_selected").str
  local selectIcon_2 = _G.DataConfigManager:GetPetGlobalConfig("pet_recommend_option_icon_talent_selected").str
  local selectIcon_3 = _G.DataConfigManager:GetPetGlobalConfig("pet_recommend_option_icon_blood_selected").str
  local selectIcon_4 = _G.DataConfigManager:GetPetGlobalConfig("pet_recommend_option_icon_skill_selected").str
  local iconTabDatas = {}
  table.insert(iconTabDatas, {
    iconPath_1 = unselectIcon_1,
    iconPath_2 = selectIcon_1,
    type = HandbookModuleEnum.District.Nature
  })
  table.insert(iconTabDatas, {
    iconPath_1 = unselectIcon_2,
    iconPath_2 = selectIcon_2,
    type = HandbookModuleEnum.District.Talent
  })
  table.insert(iconTabDatas, {
    iconPath_1 = unselectIcon_3,
    iconPath_2 = selectIcon_3,
    type = HandbookModuleEnum.District.Blood
  })
  table.insert(iconTabDatas, {
    iconPath_1 = unselectIcon_4,
    iconPath_2 = selectIcon_4,
    type = HandbookModuleEnum.District.Skill
  })
  return iconTabDatas
end

function UMG_DistrictMapGuide_C:CreateTabDatas()
  local tableDatas = {}
  table.insert(tableDatas, {
    name = LuaText.Pet_Recommend_team_main_world,
    type = _G.Enum.PlayerTeamType.PTT_BIG_WORLD
  })
  table.insert(tableDatas, {
    name = LuaText.Pet_Recommend_team_PVP,
    type = _G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1
  })
  return tableDatas
end

function UMG_DistrictMapGuide_C:OnAnimationFinished(anim)
end

function UMG_DistrictMapGuide_C:OnClickButton()
  self:LoadAnimation(2)
end

function UMG_DistrictMapGuide_C:CreateTeamDataDicTest()
  local dic = {}
  if UE4.UNRCStatics.IsEditor() then
    local childDic = {}
    local childDicTest = {}
    dic[_G.Enum.PlayerTeamType.PTT_BIG_WORLD] = childDic
    dic[_G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1] = childDicTest
    for i = 1, #self.allTypes do
      local type = self.allTypes[i]
      if type == HandbookModuleEnum.District.Nature then
        childDic[type] = self:CreateDesListDatas(_G.Enum.PlayerTeamType.PTT_BIG_WORLD, type, {
          {
            data = 1,
            ratio = 2000,
            type = type
          },
          {
            data = 2,
            ratio = 1000,
            type = type
          },
          {
            data = 4,
            ratio = 500,
            type = type
          },
          {
            data = 8,
            ratio = 800,
            type = type
          },
          {
            data = 5,
            ratio = 1000,
            type = type
          },
          {
            data = 12,
            ratio = 100,
            type = type
          },
          {
            data = 16,
            ratio = 1000,
            type = type
          }
        })
        childDicTest[type] = self:CreateDesListDatas(_G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1, type, {
          {
            data = 1 + i,
            ratio = 2000,
            type = type
          },
          {
            data = 2 + i,
            ratio = 1000,
            type = type
          },
          {
            data = 4 + i,
            ratio = 500,
            type = type
          },
          {
            data = 8 + i,
            ratio = 800,
            type = type
          },
          {
            data = 5 + i,
            ratio = 1000,
            type = type
          },
          {
            data = 12 + i,
            ratio = 100,
            type = type
          },
          {
            data = 16 + i,
            ratio = 1000,
            type = type
          }
        })
      elseif type == HandbookModuleEnum.District.Talent then
        childDic[type] = self:CreateDesListDatas(_G.Enum.PlayerTeamType.PTT_BIG_WORLD, type, {
          {
            data = 1,
            ratio = 10,
            type = type
          },
          {
            data = 2,
            ratio = 1,
            type = type
          },
          {
            data = 14,
            ratio = 600,
            type = type
          },
          {
            data = 10,
            ratio = 2000,
            type = type
          },
          {
            data = 15,
            ratio = 3000,
            type = type
          },
          {
            data = 11,
            ratio = 1050,
            type = type
          },
          {
            data = 16,
            ratio = 1010,
            type = type
          }
        })
        childDicTest[type] = self:CreateDesListDatas(_G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1, type, {
          {
            data = 1 + i,
            ratio = 2000,
            type = type
          },
          {
            data = 2 + i,
            ratio = 1000,
            type = type
          },
          {
            data = 4 + i,
            ratio = 500,
            type = type
          },
          {
            data = 8 + i,
            ratio = 800,
            type = type
          },
          {
            data = 5 + i,
            ratio = 1000,
            type = type
          },
          {
            data = 12 + i,
            ratio = 100,
            type = type
          },
          {
            data = 16 + i,
            ratio = 1000,
            type = type
          }
        })
      elseif type == HandbookModuleEnum.District.Blood then
        childDic[type] = self:CreateDesListDatas(_G.Enum.PlayerTeamType.PTT_BIG_WORLD, type, {
          {
            data = 11,
            ratio = 6000,
            type = type
          },
          {
            data = 12,
            ratio = 10,
            type = type
          },
          {
            data = 14,
            ratio = 100,
            type = type
          },
          {
            data = 11,
            ratio = 500,
            type = type
          },
          {
            data = 5,
            ratio = 200,
            type = type
          },
          {
            data = 1,
            ratio = 300,
            type = type
          },
          {
            data = 6,
            ratio = 1000,
            type = type
          }
        })
        childDicTest[type] = self:CreateDesListDatas(_G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1, type, {
          {
            data = 1 + i,
            ratio = 2000,
            type = type
          },
          {
            data = 2 + i,
            ratio = 1000,
            type = type
          },
          {
            data = 4 + i,
            ratio = 500,
            type = type
          },
          {
            data = 8 + i,
            ratio = 800,
            type = type
          },
          {
            data = 5 + i,
            ratio = 1000,
            type = type
          },
          {
            data = 12 + i,
            ratio = 100,
            type = type
          },
          {
            data = 16 + i,
            ratio = 1000,
            type = type
          }
        })
      elseif type == HandbookModuleEnum.District.Skill then
        childDic[type] = self:CreateDesListDatas(_G.Enum.PlayerTeamType.PTT_BIG_WORLD, type, {
          {
            data = 200001,
            ratio = 3000,
            type = type
          },
          {
            data = 200002,
            ratio = 1000,
            type = type
          },
          {
            data = 200003,
            ratio = 20,
            type = type
          }
        })
        childDicTest[type] = self:CreateDesListDatas(_G.Enum.PlayerTeamType.PTT_PVP_BATTLE_1, type, {
          {
            data = 7120070,
            ratio = 300,
            type = type
          },
          {
            data = 7020870,
            ratio = 100,
            type = type
          },
          {
            data = 200090,
            ratio = 20,
            type = type
          },
          {
            data = 7000030,
            ratio = 20,
            type = type
          }
        })
      end
    end
  end
  return dic
end

function UMG_DistrictMapGuide_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_DistrictMapGuide_C
