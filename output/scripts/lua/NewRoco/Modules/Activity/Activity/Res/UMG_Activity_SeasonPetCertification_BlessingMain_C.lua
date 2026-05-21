local UMG_Activity_SeasonPetCertification_BlessingMain_C = _G.NRCPanelBase:Extend("UMG_Activity_SeasonPetCertification_BlessingMain_C")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ResQueue = require("NewRoco.Utils.ResQueue")
local PetUtils = require("NewRoco.Utils.PetUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local FakePerformConf = require("NewRoco.Modules.Core.Scene.Component.Show.FakePerformConf")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local HoldingItemComponent = require("NewRoco.Modules.Core.Scene.Component.Show.HoldingItemComponent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnConstruct()
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnCameraStartEnd()
  self.GridView1:SelectItemByIndex(0)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.open)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnEnterCameraSkillPreStart(skillObj)
  if skillObj then
    local characters = {}
    characters[UE4.EBattleStaticActorType.Player_1] = self.g6_npc.viewObj
    skillObj:SetCharacters(characters)
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnActive(OpenAction)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCSwitcher_0:SetActiveWidgetIndex(1)
  self:OnAddEventListener()
  self.isReversalSort = false
  self.resQueue = nil
  self.loadingPetActor = nil
  self.petActor = nil
  self.curPetData = nil
  self.curPetDatas = nil
  self.OpenAction = OpenAction
  self.activity_id = OpenAction:GetActivityId()
  local base_id = _G.DataConfigManager:GetActivityConf(self.activity_id).base_id[1]
  local playerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local petList = {}
  table.deepCopy(playerPetInfo.pet_data, petList)
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(playerPetInfo, Enum.PlayerTeamType.PTT_BIG_WORLD)
  for i = 1, #teamInfo.teams do
    local team = teamInfo.teams[i]
    if team.pet_infos then
      for _, pet_data in ipairs(team.pet_infos) do
        for _, v in ipairs(petList) do
          if v.gid == pet_data.pet_gid then
            v.team_index = i
            break
          end
        end
      end
    end
  end
  local conf = _G.DataConfigManager:GetActivityPetCertification(base_id)
  if 1 == conf.Intimacy then
    local tempPetList = {}
    local close_level = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_BOND):GetDataByIndex(1).close_level
    local maxLevel = close_level[#close_level]
    for _, v in ipairs(petList) do
      if v.closeness_info and v.closeness_info.closeness_lv == maxLevel then
        table.insert(tempPetList, v)
      end
    end
    petList = tempPetList
  end
  local activityPetList = {}
  if 1 == conf.select_type then
    local dateTime, success = UE4.UKismetMathLibrary.DateTimeFromString(conf.start_time)
    if success and dateTime then
      local start_time = UE4.UNRCStatics.ToTimestamp(dateTime) - 28800
      for _, v in ipairs(petList) do
        if start_time < v.add_time then
          table.insert(activityPetList, v)
        end
      end
    end
  elseif 2 == conf.select_type then
    local id_map = {}
    for _, v in ipairs(conf.white_baseid) do
      id_map[v] = v
    end
    for _, v in ipairs(petList) do
      if id_map[v.base_conf_id] then
        table.insert(activityPetList, v)
      end
    end
  end
  self.activityPetList = activityPetList
  for _, v in ipairs(self.activityPetList) do
    v.parent = self
    v.selectedCallback = self.OnItemSelected
  end
  self.curPetDatas = self.activityPetList
  if 0 == #activityPetList then
    self:CleanPanel()
  end
  self.curSortId = -1
  local sortList = {}
  local sortText = {}
  local sortInfo = {}
  sortInfo.name = _G.LuaText.furniture_handbook_sort_id
  sortInfo.ComType = CommonBtnEnum.ComboBoxType.CertificationActivity
  table.insert(sortList, sortInfo)
  table.insert(sortText, sortInfo.name)
  for i = 0, 1 do
    sortInfo = {}
    local sortId = i + 1
    local name = _G.DataConfigManager:GetTravelSequenceConf(sortId).sequence_desc
    sortInfo.name = name
    sortInfo.ComType = CommonBtnEnum.ComboBoxType.CertificationActivity
    table.insert(sortList, sortInfo)
    table.insert(sortText, name)
  end
  local commonDropDownListData = _G.NRCCommonDropDownListData()
  commonDropDownListData.DropDownListInfo = sortList
  commonDropDownListData.DropDownListText = sortText[1]
  commonDropDownListData.Call = self
  commonDropDownListData.Btn_LeftHandler = self.OpenFilterPanelBtnClick
  commonDropDownListData.Btn_RightHandler = self.OnReversePetList
  commonDropDownListData.DropDownListIndex = 1
  commonDropDownListData.ComType = CommonBtnEnum.ComboBoxType.CertificationActivity
  self.ComboBox:SetPanelInfo(commonDropDownListData)
  self.ComboBox.OnPopupVisibilityChanged = FPartial(self.OnPopupVisibilityChanged, self)
  self:OnPopupVisibilityChanged(false)
  self.GridView1:SetItemCanClickChecker(self.ItemClickChecker, self)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_LOCAL_PLAYER, true)
  self.g6_npc = OpenAction:GetOwnerNPC()
  local npcViewObj = self.g6_npc.viewObj
  local skillPath = "/Game/ArtRes/Effects/G6Skill/Luying/Camping_Pet_Storeroon_Start.Camping_Pet_Storeroon_Start"
  local skillProxy = RocoSkillProxy.Create(skillPath, npcViewObj.RocoSkill)
  local PerformConf = FakePerformConf(skillProxy:GetSkillPath())
  PerformConf:AddSkillBlackboardValue("camActor_0001", false)
  PerformConf:AddSkillBlackboardValue("camActor_0001_SA", false)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.viewObj:Event_StopTurn()
  self.g6_npc:PlayShowById(PerformConf, self, self.OnCameraStartEnd, skillProxy, self, self.OnEnterCameraSkillPreStart)
  self.PromptText:SetText(_G.LuaText.PET_CERTIFICATION_7)
  self.NoUnlockFormulaText:SetText(_G.LuaText.PET_CERTIFICATION_17)
  self.Title1:SetSubtitle(_G.DataConfigManager:GetTitleConf("PetBless").subtitle[1].subtitle)
  self.Title1:Set_MainTitle(_G.DataConfigManager:GetTitleConf("PetBless").title)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:GetCurPetGid()
  return self.curPetData and self.curPetData.gid
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:ItemClickChecker(item, index, userClick)
  if not userClick then
    return
  end
  return not self.bItemLock
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnPopupVisibilityChanged(bShow)
  if bShow then
    self.FullScreenBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.FullScreenBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OpenFilterPanelBtnClick()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenFilterPanel, PetUIModuleEnum.OpenSortType.CertificationActivity)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:HasGid(gid, table)
  if not table then
    return false
  end
  for i = 1, #table do
    if table[i].gid == gid then
      return true
    end
  end
  return false
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnFilterPet(typeChooseList)
  self.curPetDatas = self.activityPetList
  local departmentFilter = {}
  local departList = {}
  if typeChooseList.DepartmentFilter then
    for i, v in pairs(typeChooseList.DepartmentFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(departmentFilter, enum)
      end
    end
  end
  if #departmentFilter > 0 then
    for i = 1, #self.curPetDatas do
      if self.curPetDatas[i] then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.curPetDatas[i].base_conf_id)
        for k = 1, #petBaseConf.unit_type do
          for j = 1, #departmentFilter do
            if petBaseConf.unit_type[k] == departmentFilter[j] and not self:HasGid(self.curPetDatas[i].gid, departList) then
              table.insert(departList, self.curPetDatas[i])
            end
          end
        end
      end
    end
  else
    departList = self.curPetDatas
  end
  local talentFilter = {}
  local talentList = {}
  if typeChooseList.TalentFilter then
    for i, v in pairs(typeChooseList.TalentFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(talentFilter, enum)
      end
    end
  end
  if #talentFilter > 0 then
    for i = 1, #departList do
      for j = 1, #talentFilter do
        if departList[i].talent_rank == talentFilter[j] then
          table.insert(talentList, departList[i])
          break
        end
      end
    end
  else
    talentList = departList
  end
  local naturePositiveEffectFilter = {}
  local naturePositiveEffectList = {}
  if typeChooseList.NaturePositiveEffectFilter then
    for i, v in pairs(typeChooseList.NaturePositiveEffectFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(naturePositiveEffectFilter, enum)
      end
    end
  end
  if #naturePositiveEffectFilter > 0 then
    for i = 1, #talentList do
      local naturePositive = talentList[i].changed_nature_pos_attr_type
      if not naturePositive or 0 == naturePositive then
        naturePositive = _G.DataConfigManager:GetNatureConf(talentList[i].nature).positive_effect
      else
        naturePositive = self:GetChangeAttrReqEnum(naturePositive)
      end
      for j = 1, #naturePositiveEffectFilter do
        if naturePositive == naturePositiveEffectFilter[j] then
          table.insert(naturePositiveEffectList, talentList[i])
          break
        end
      end
    end
  else
    naturePositiveEffectList = talentList
  end
  local attributeFilter = {}
  local attributeList = {}
  if typeChooseList.AttributeFilter then
    for i, v in pairs(typeChooseList.AttributeFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(attributeFilter, enum)
      end
    end
  end
  if #attributeFilter > 0 then
    for i = 1, #naturePositiveEffectList do
      for j = 1, #attributeFilter do
        if attributeFilter[j] == _G.Enum.AttributeType.AT_HPMAX and naturePositiveEffectList[i].attribute_info.hp.talent and naturePositiveEffectList[i].attribute_info.hp.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_PHYATK and naturePositiveEffectList[i].attribute_info.attack.talent and naturePositiveEffectList[i].attribute_info.attack.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEATK and naturePositiveEffectList[i].attribute_info.special_attack.talent and naturePositiveEffectList[i].attribute_info.special_attack.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_PHYDEF and naturePositiveEffectList[i].attribute_info.defense.talent and naturePositiveEffectList[i].attribute_info.defense.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEDEF and naturePositiveEffectList[i].attribute_info.special_defense.talent and naturePositiveEffectList[i].attribute_info.special_defense.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
        if attributeFilter[j] == _G.Enum.AttributeType.AT_SPEED and naturePositiveEffectList[i].attribute_info.speed.talent and naturePositiveEffectList[i].attribute_info.speed.talent > 0 then
          table.insert(attributeList, naturePositiveEffectList[i])
          break
        end
      end
    end
  else
    attributeList = naturePositiveEffectList
  end
  local PartnerMarkerFilter = {}
  local PartnerMarkerList = {}
  if typeChooseList.PartnerMarkerFilter then
    for i, v in pairs(typeChooseList.PartnerMarkerFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value]
        table.insert(PartnerMarkerFilter, enum)
      end
    end
  end
  if #PartnerMarkerFilter > 0 then
    for i = 1, #attributeList do
      for j = 1, #PartnerMarkerFilter do
        if attributeList[i].partner_mark == PartnerMarkerFilter[j] then
          table.insert(PartnerMarkerList, attributeList[i])
          break
        end
      end
    end
  else
    PartnerMarkerList = attributeList
  end
  local SpecialityFilter = {}
  local SpecialityList = {}
  if typeChooseList.SpecialityFilter then
    for i, v in pairs(typeChooseList.SpecialityFilter) do
      if v.data.filter_enum_name and v.data.filter_enum_value and _G.Enum[v.data.filter_enum_name] and _G.Enum[v.data.filter_enum_name][v.data.filter_enum_value] then
        local enum = v.data.filter_enum_value
        table.insert(SpecialityFilter, enum)
      end
    end
  end
  if #SpecialityFilter > 0 then
    for i = 1, #PartnerMarkerList do
      for j = 1, #SpecialityFilter do
        if PartnerMarkerList[i].speciality_id then
          local petTalentConf = _G.DataConfigManager:GetPetTalentConf(PartnerMarkerList[i].speciality_id)
          if petTalentConf and petTalentConf.filter_enum_value == SpecialityFilter[j] then
            table.insert(SpecialityList, PartnerMarkerList[i])
            break
          end
        end
      end
    end
  else
    SpecialityList = PartnerMarkerList
  end
  if #departmentFilter <= 0 and #talentFilter <= 0 and #naturePositiveEffectFilter <= 0 and #attributeFilter <= 0 and #PartnerMarkerFilter <= 0 and #SpecialityFilter <= 0 then
    self.curPetDatas = self.activityPetList
    SpecialityList = self.activityPetList
  elseif SpecialityList then
    self.curPetDatas = SpecialityList
  end
  if 0 == #self.curPetDatas then
    self:CleanPanel()
  else
    self.CanvasPanel_63:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_98:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_142:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:DelayFrames(1, function()
    self:OnShowPetWithOrder(self.curSortId, nil)
  end)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:GetChangeAttrReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX then
    return Enum.AttributeType.AT_HPMAX_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYATK then
    return Enum.AttributeType.AT_PHYATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEATK then
    return Enum.AttributeType.AT_SPEATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYDEF then
    return Enum.AttributeType.AT_PHYDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEDEF then
    return Enum.AttributeType.AT_SPEDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEED then
    return Enum.AttributeType.AT_SPEED_PERCENT
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnShowPetWithOrder(uiIndex)
  self.curSortId = uiIndex
  if self.curSortId == Enum.PetSequenceSwitch.SEQUENCE_LEVEL_UP then
    table.sort(self.curPetDatas, function(a, b)
      if a.level == b.level then
        return a.gid < b.gid
      else
        return a.level > b.level
      end
    end)
  elseif self.curSortId == Enum.PetSequenceSwitch.SEQUENCE_CATCH_UP then
    table.sort(self.curPetDatas, function(a, b)
      if a.addTime == b.addTime then
        return a.gid < b.gid
      else
        return a.addTime > b.addTime
      end
    end)
  else
    table.sort(self.curPetDatas, function(a, b)
      if a.team_index and b.team_index or not a.team_index and not b.team_index then
        if a.level == b.level then
          if a.addTime == b.addTime then
            return a.gid < b.gid
          else
            return a.addTime < b.addTime
          end
        else
          return a.level > b.level
        end
      elseif not a.team_index and b.team_index then
        return false
      else
        return true
      end
    end)
  end
  if self.isReversalSort then
    self:ReversePetList()
  end
  self.GridView1:InitList(self.curPetDatas)
  self:UpdateSelectAndShowModel()
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:UpdateSelectAndShowModel()
  if 0 == #self.curPetDatas then
    return
  end
  if self.curPetData then
    for i, v in ipairs(self.curPetDatas) do
      if v.gid == self.curPetData.gid then
        self.GridView1:SelectItemByIndex(i - 1)
        return
      end
    end
  end
  self.GridView1:SelectItemByIndex(0)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:ReversePetList()
  local newPetList = {}
  for i = #self.curPetDatas, 1, -1 do
    table.insert(newPetList, self.curPetDatas[i])
  end
  self.curPetDatas = newPetList
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:CollapsedCombBoxPopUp()
  self.ComboBox:SetPopupVisible(false)
  self.FullScreenBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnReversePetList()
  self.IsReversalSort = not self.IsReversalSort
  self:ReversePetList()
  self.GridView1:InitList(self.curPetDatas)
  self:UpdateSelectAndShowModel()
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:CleanPanel()
  self:DispatchEvent(ActivityModuleEvent.UpdateCertificationDetailPanel, nil)
  if self.petActor then
    self.petActor:K2_DestroyActor()
    self.petActor = nil
  end
  self.curPetData = nil
  self.CanvasPanel_63:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_98:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_142:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Empty:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnItemSelected(index)
  self.selectedIndex = index
  local petInfo = self.curPetDatas[index]
  self.curPetData = petInfo
  self.textPetName:SetText(petInfo.name)
  local BreakThroughStarsList = PetUtils.GetBreakThroughStarsList(petInfo)
  self.CatchHardLv:InitGridView(BreakThroughStarsList)
  local commonAttrData = {}
  local commonAttrData1 = {}
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_conf_id)
  local petType = petBaseConf.unit_type
  for i = 1, 2 do
    if i <= #petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType[i])
      if typeDic then
        table.insert(commonAttrData1, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon
        })
      end
    end
  end
  self.Attr1:InitGridView(commonAttrData1)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(petInfo.blood_id)
  table.insert(commonAttrData, {
    Name = PetBloodConf.blood_name,
    Path = PetBloodConf.icon
  })
  self.Attr:InitGridView(commonAttrData)
  self:DispatchEvent(ActivityModuleEvent.UpdateCertificationDetailPanel, petInfo)
  self.bItemLock = true
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_conf_id)
  local PetModelId = petbaseConf.model_conf
  local PetModelConf = _G.DataConfigManager:GetModelConf(PetModelId)
  if self.resQueue then
    self.resQueue:Release()
  end
  self.resQueue = ResQueue(30)
  self.resQueue:InsertObject("PetModel", PetModelConf.path)
  self.resQueue:StartLoad(self, self.OnPetModelLoaded)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnPetModelLoaded(InQueue, bSuccess)
  if bSuccess then
    local asset = InQueue:Get("PetModel")
    local params = {}
    params.inBattle = true
    local petModel = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(asset, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, params)
    if not petModel then
      return
    end
    self.loadingPetActor = petModel
    petModel:SetLoadPriority(PriorityEnum.UI_Pet_Mutation)
    if self.curPetData then
      PetMutationUtils.PrepareMutationAssets(petModel, self.curPetData)
    end
    petModel:InitOutSceneAsync(self, self.OnInitOutSceneComplete)
  else
    Log.Error("UMG_PlantProtectionMain_C:OnPetModelLoaded \229\138\160\232\189\189\229\164\177\232\180\165\228\186\134")
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnInitOutSceneComplete(petModel)
  if self.curPetData then
    local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.curPetData)
    UE.UNRCCharacterUtils.SetCharacterMeshScale(petModel, heightModelScale)
    PetMutationUtils.DoMutation(petModel, self.curPetData)
  else
    self:OnPetGenerateDone(petModel, false)
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnPetMutationDone(character)
  if not self.loadingPetActor or not character then
    return
  end
  if self.loadingPetActor == character then
    self:OnPetGenerateDone(self.loadingPetActor, true)
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnPetGenerateDone(petModel, bLegal)
  self.bItemLock = false
  if self.petActor then
    self.petActor:K2_DestroyActor()
    self.petActor = nil
  end
  self.loadingPetActor = nil
  if petModel then
    if bLegal then
      self.petActor = petModel
      petModel:SetActorEnableCollision(false)
      self:SetPetPosition(petModel)
    else
      petModel:K2_DestroyActor()
    end
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:SetPetPosition(petModel)
  if petModel then
    local PetPosition = UE4.FVector(0, -200, 0 + (petModel:GetHalfHeight() or 0))
    local PetRotation = UE4.FRotator(0, 0, 0)
    self:SetPosAndLockOnGround(petModel, PetPosition, PetRotation)
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:SetPosAndLockOnGround(Model, Position, Rotation)
  if not self.OpenAction then
    return
  end
  local npcViewObj = self.OpenAction:GetOwnerNPCView()
  if not npcViewObj then
    return
  end
  local MeshComponent = npcViewObj:K2_GetRootComponent()
  local RootComponent = Model:K2_GetRootComponent()
  RootComponent:K2_AttachToComponent(MeshComponent, "None", UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
  RootComponent:K2_SetRelativeLocation(Position, false, nil, false)
  RootComponent:K2_SetRelativeRotation(Rotation, false, nil, false)
  local ModelLocation = Model:Abs_GetTransform().Translation
  local ModelUnderLocation = ModelLocation
  local UnderLineBegin = UE4.FVector(ModelLocation.X, ModelLocation.Y, ModelLocation.Z + 500)
  local UnderLineEnd = UE4.FVector(ModelLocation.X, ModelLocation.Y, ModelLocation.Z - 500)
  local TraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
  local Hits, Success = UE4.UKismetSystemLibrary.Abs_LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), UnderLineBegin, UnderLineEnd, TraceChannel, false, nil, 0, nil)
  if Success then
    for _, Result in tpairs(Hits) do
      ModelUnderLocation.X = Result.ImpactPoint.X
      ModelUnderLocation.Y = Result.ImpactPoint.Y
      ModelUnderLocation.Z = Result.ImpactPoint.Z + Model:GetHalfHeight()
      break
    end
  end
  Model:Abs_K2_SetActorLocation_WithoutHit(ModelUnderLocation)
  Model:K2_DetachFromActor(UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:MoveDetailPanelCamera(bOpenDetailPanel)
  local skillPath
  if bOpenDetailPanel then
    skillPath = "/Game/ArtRes/Effects/G6Skill/Luying/Camping_Pet_StoreroonUp_Start.Camping_Pet_StoreroonUp_Start"
  else
    skillPath = "/Game/ArtRes/Effects/G6Skill/Luying/Camping_Pet_StoreroonUp_End.Camping_Pet_StoreroonUp_End"
  end
  local npcViewObj = self.g6_npc.viewObj
  if npcViewObj then
    local SkillProxy = RocoSkillProxy.Create(skillPath, npcViewObj.RocoSkill)
    if SkillProxy then
      local FakePerform = FakePerformConf(skillPath)
      FakePerform:AddSkillBlackboardValue("camActor_0001", false)
      FakePerform:AddSkillBlackboardValue("camActor_0001_SA", false)
      self.g6_npc:PlayShowById(FakePerform, nil, nil, SkillProxy)
    end
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnCloseBtnClicked()
  if self.OpenAction then
    self.OpenAction:Finish(false, nil, "0")
    self.OpenAction = nil
  end
  self:OnClose()
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnClickBtnGuard()
  local popUpData = _G.NRCCommonPopUpData()
  popUpData.TitleText = _G.LuaText.PET_CERTIFICATION_10
  popUpData.ContentText = _G.LuaText.PET_CERTIFICATION_9
  popUpData.RemindSwitch = 0
  popUpData.Btn_LeftText = _G.LuaText.tips_dialog_butten_cancel
  popUpData.Btn_RightText = _G.LuaText.tips_dialog_butten_accept
  popUpData.Btn_RightHandler = self.ReqCertification
  popUpData.Call = self
  _G.NRCModeManager:DoCmd(_G.CommonPopUpModuleCmd.OpenRemindPanel, popUpData)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:ReqCertification()
  local petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  if petUIModule then
    petUIModule.certificationGid = self.curPetData.gid
  end
  local req = _G.ProtoMessage:newZoneActivityPetCertificationReq()
  req.activity_id = self.OpenAction:GetActivityId()
  req.pet_gid = self.curPetData.gid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_CERTIFICATION_REQ, req, self, self.OnPetCertification)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnPetCertification(rsp)
  if 0 == rsp.ret_info.ret_code then
    local base_id = _G.DataConfigManager:GetActivityConf(self.OpenAction:GetActivityId()).base_id[1]
    self:DispatchEvent(ActivityModuleEvent.UpdateCertificationDetailPanel, nil)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.CreatePetCertificationTips(base_id))
    if self.OpenAction then
      self.OpenAction:Finish(true, nil, "1")
      self.OpenAction = nil
    end
    self:OnClose()
  else
    local petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
    if petUIModule then
      petUIModule.certificationGid = nil
    end
    local Key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    local ErrorText = _G.DataConfigManager:GetLocalizationConf(Key, true)
    if ErrorText then
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, ErrorText.msg)
    end
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnShowPetDetail()
  self:MoveDetailPanelCamera(true)
  _G.NRCModeManager:DoCmd(_G.ActivityModuleCmd.OnCmdOpenBlessingPetDetailPanel, self.curPetData, self, self.OnDetailPanelClose)
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnDetailPanelClose(bCertification)
  if bCertification then
    self:OnClickBtnGuard()
  else
    self:MoveDetailPanelCamera(false)
    self:PlayAnimation(self.Plant_open)
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:UpdatePetCollect(partner_mark)
  if not self.curPetData then
    return
  end
  if partner_mark == self.curPetData.partner_mark then
    return
  end
  self.curPetData.partner_mark = partner_mark
  local widget = self.GridView1:GetItemByIndex(self.selectedIndex - 1)
  if widget and widget.UpdatePartnerMark then
    widget:UpdatePartnerMark()
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnAddEventListener()
  self:AddButtonListener(self.FullScreenBtn, self.CollapsedCombBoxPopUp)
  self:AddButtonListener(self.CloseBtn_1.btnClose, self.OnCloseBtnClicked)
  self:AddButtonListener(self.GuardBtn.btnLevelUp, self.OnClickBtnGuard)
  self:AddButtonListener(self.Btn_Details, self.OnShowPetDetail)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_SeasonPetCertification_BlessingMain_C", self, PetUIModuleEvent.FilterPet, self.OnFilterPet)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_SeasonPetCertification_BlessingMain_C", self, ActivityModuleEvent.OnSelectCertificationPetSort, self.OnShowPetWithOrder)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_SeasonPetCertification_BlessingMain_C", self, NPCModuleEvent.OnNpcMutationComplete, self.OnPetMutationDone)
  local petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  if petUIModule then
    petUIModule:RegisterEvent(self, PetUIModuleEvent.UpdatePetCollect, self.UpdatePetCollect)
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.FullScreenBtn)
  self:RemoveButtonListener(self.CloseBtn_1.btnClose)
  self:RemoveButtonListener(self.GuardBtn.btnLevelUp)
  self:RemoveButtonListener(self.Btn_Details)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.FilterPet, self.OnFilterPet)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnSelectCertificationPetSort, self.OnShowPetWithOrder)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.OnNpcMutationComplete, self.OnPetMutationDone)
  local petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  if petUIModule then
    petUIModule:UnRegisterEvent(self, PetUIModuleEvent.UpdatePetCollect)
  end
end

function UMG_Activity_SeasonPetCertification_BlessingMain_C:OnDeactive()
  self:OnRemoveEventListener()
  if self.petActor then
    self.petActor:K2_DestroyActor()
    self.petActor = nil
  end
  if self.loadingPetActor then
    self.loadingPetActor:K2_DestroyActor()
    self.loadingPetActor = nil
  end
  if self.resQueue then
    self.resQueue:Release()
    self.resQueue = nil
  end
  if self.g6_npc then
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_LOCAL_PLAYER, false)
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local playerController = localPlayer:GetUEController()
    playerController:ReleaseRocoCamera()
    local holdingItemComponent = self.g6_npc:EnsureComponent(HoldingItemComponent)
    holdingItemComponent:DestroyItem("camActor_0001")
    holdingItemComponent:DestroyItem("camActor_0001_SA")
    self.g6_npc = nil
  end
end

return UMG_Activity_SeasonPetCertification_BlessingMain_C
