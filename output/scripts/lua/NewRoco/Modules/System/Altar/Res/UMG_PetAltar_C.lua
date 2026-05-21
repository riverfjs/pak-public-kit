local AltarModuleEvent = require("NewRoco.Modules.System.AltarModule.AltarModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local Enum = require("Data.Config.Enum")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetAltar_C = _G.NRCPanelBase:Extend("UMG_PetAltar_C")

function UMG_PetAltar_C:OnConstruct()
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, false)
  self.Btnknow:SetBtnText(LuaText.umg_petaltar_1)
  self.BtnConfirm:SetBtnText(LuaText.umg_petaltar_2)
  self.SubmitPetConf = {}
  self.petData = nil
  self.petTypeIcons = {
    self.petTypeIcon1,
    self.petTypeIcon2
  }
  self.petTypeText = {
    {
      self.BG1,
      self.Text1
    },
    {
      self.BG2,
      self.Text2
    }
  }
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCancel)
  self:AddButtonListener(self.BtnConfirm.btnLevelUp, self.OnClickConfirm)
  self:AddButtonListener(self.Btnknow.btnLevelUp, self.OnClickCancel)
  self:AddButtonListener(self.Btn_particulars.btnLevelUp, self.OnClickParticulars)
  NRCEventCenter:RegisterEvent("UMG_PetAltar_C", self, AltarModuleEvent.PetAltarItemSelect, self.OnPetAltarItemSelect)
  NRCEventCenter:RegisterEvent("UMG_PetAltar_C", self, AltarModuleEvent.PetAltarItemUnSelect, self.OnPetAltarItemUnSelect)
  self.Percent = 2
  _G.NRCEventCenter:RegisterEvent("UMG_PetAltar_C", self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  self.Btnknow:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

local function cmp(a, b)
  if a.level ~= b.level then
    return a.level < b.level
  end
  return a._totalProperty < b._totalProperty
end

function UMG_PetAltar_C:OnActive(acion)
  self:OnPetAltarItemUnSelect()
  if acion then
    self.optionId = acion.Owner.config.id
    self.npcId = acion.Owner.owner.serverData.base.actor_id
    self.action = acion
    self.SubmitPetConf = _G.DataConfigManager:GetSubmitPetConf(tonumber(acion.Config.action_param1))
    if self.SubmitPetConf.submit_desc then
      self.confirmText:SetText(self.SubmitPetConf.submit_desc)
      self.Text_NonePet:SetText(self.SubmitPetConf.submit_desc)
    else
      self.confirmText:SetText("")
      self.Text_NonePet:SetText("")
    end
  else
    self.SubmitPetConf = {}
    Log.Error("UMG_PetAltar_C:OnActive option\228\184\186nil\239\188\140\229\166\130\230\158\156\228\184\141\230\152\175\233\128\154\232\191\135debug\233\157\162\230\157\191\230\137\147\229\188\128\232\175\183\230\163\128\230\159\165")
  end
  local pets = self:GetShowAllPet(self.SubmitPetConf)
  
  local function calcPetTotalProp(pet)
    local PetBasePropList = {
      Enum.AttributeType.AT_HPMAX,
      Enum.AttributeType.AT_PHYATK,
      Enum.AttributeType.AT_PHYDEF,
      Enum.AttributeType.AT_SPEATK,
      Enum.AttributeType.AT_SPEDEF,
      Enum.AttributeType.AT_SPEED
    }
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(pet.base_conf_id)
    local value = 0
    for _, propType in ipairs(PetBasePropList) do
      value = value + PetUtils.CalcProperty(petBaseConf, pet, propType) or 0
    end
    return value
  end
  
  for _, petData in pairs(pets) do
    petData._totalProperty = calcPetTotalProp(petData)
  end
  pets = self:EliminatePet(pets)
  if #pets > 0 then
    table.sort(pets, cmp)
    self.CanvasPanel_have:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_none:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.CanvasPanel_none1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.petList:InitList(pets)
    self.petList:SelectItemByIndex(0)
  else
    if self.SubmitPetConf.base_id == nil or #self.SubmitPetConf.base_id <= 0 then
      self.CanvasPanel_none:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.CanvasPanel_none:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.anyText:SetText(LuaText.act_submit_2)
    self.CanvasPanel_have:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_none:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_none1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetAltar_C:EliminatePet(PetData)
  local PetList = {}
  for i, Pet in ipairs(PetData) do
    if Pet.partner_mark and 0 == Pet.partner_mark then
      table.insert(PetList, Pet)
    end
  end
  return PetList
end

function UMG_PetAltar_C:OnDialogueEnded()
  self:DoClose()
end

function UMG_PetAltar_C:GetShowAllPet(SubmitPetConf)
  local allpets = _G.DataModelMgr.PlayerDataModel:GetPetData()
  local teamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
  local pets = {}
  if allpets and #allpets > 0 then
    if SubmitPetConf.base_id == nil or #SubmitPetConf.base_id <= 0 then
      for j = 1, #allpets do
        if teamInfo.teams then
          for i, team in ipairs(teamInfo.teams) do
            local petInfo = PetUtils.PetTeamFindPetInfoByIndex(team, allpets[j].gid)
            if petInfo then
              goto lbl_204
            end
          end
        end
        if self.SubmitPetConf.attr_cond and #self.SubmitPetConf.attr_cond > 0 then
          for index = 1, #self.SubmitPetConf.attr_cond do
            if self.SubmitPetConf.attr_cond[index].attr_cond_type == Enum.PetAttrCond.PATC_GENDER and self.SubmitPetConf.attr_cond[index].attr_cond_param[1] ~= allpets[j].gender then
              allpets[j].canCommit = false
              break
            end
            if self.SubmitPetConf.attr_cond[index].attr_cond_type == Enum.PetAttrCond.PATC_WEIGHT_LARGER and self.SubmitPetConf.attr_cond[index].attr_cond_param[1] >= allpets[j].weight then
              allpets[j].canCommit = false
              break
            end
            if self.SubmitPetConf.attr_cond[index].attr_cond_type == Enum.PetAttrCond.PATC_NATURE then
              if #self.SubmitPetConf.attr_cond[index].attr_cond_param <= 0 then
                allpets[j].canCommit = true
                break
              end
              for z = 1, #self.SubmitPetConf.attr_cond[index].attr_cond_param do
                if self.SubmitPetConf.attr_cond[index].attr_cond_param[z] == allpets[j].nature then
                  allpets[j].canCommit = true
                  break
                end
                if z == #self.SubmitPetConf.attr_cond[index].attr_cond_param then
                  allpets[j].canCommit = false
                end
              end
              break
            end
            if self.SubmitPetConf.attr_cond[index].attr_cond_type == Enum.PetAttrCond.PATC_BALL then
              allpets[j].canCommit = false
              if self.SubmitPetConf.attr_cond[index].attr_cond_param[1] == allpets[j].ball_id then
                allpets[j].canCommit = true
              end
              break
            end
            if index == #self.SubmitPetConf.attr_cond then
              allpets[j].canCommit = true
            end
          end
        else
          allpets[j].canCommit = true
        end
        if allpets[j].canCommit then
          local IsTravel = _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.GetPetIsTravel, allpets[j].gid)
          if not IsTravel then
            table.insert(pets, allpets[j])
          end
        end
        ::lbl_204::
      end
      return pets
    end
    for j = 1, #SubmitPetConf.base_id do
      for i = 1, #allpets do
        local isTeam = false
        if teamInfo.teams then
          for v, team in ipairs(teamInfo.teams) do
            local petInfo = PetUtils.PetTeamFindPetInfoByIndex(team, allpets[i].gid)
            if petInfo then
              isTeam = true
            end
          end
        end
        if not isTeam then
          local pet = allpets[i]
          if pet.base_conf_id == SubmitPetConf.base_id[j] then
            table.insert(pets, pet)
          end
        end
      end
    end
    local pets1 = {}
    for j = 1, #pets do
      if self.SubmitPetConf.attr_cond and #self.SubmitPetConf.attr_cond > 0 then
        for index = 1, #self.SubmitPetConf.attr_cond do
          if self.SubmitPetConf.attr_cond[index].attr_cond_type == Enum.PetAttrCond.PATC_GENDER and self.SubmitPetConf.attr_cond[index].attr_cond_param[1] ~= pets[j].gender then
            pets[j].canCommit = false
            break
          end
          if self.SubmitPetConf.attr_cond[index].attr_cond_type == Enum.PetAttrCond.PATC_WEIGHT_LARGER and self.SubmitPetConf.attr_cond[index].attr_cond_param[1] >= pets[j].weight then
            pets[j].canCommit = false
            break
          end
          if self.SubmitPetConf.attr_cond[index].attr_cond_type == Enum.PetAttrCond.PATC_NATURE then
            if #self.SubmitPetConf.attr_cond[index].attr_cond_param <= 0 then
              pets[j].canCommit = false
              break
            end
            for z = 1, #self.SubmitPetConf.attr_cond[index].attr_cond_param do
              if self.SubmitPetConf.attr_cond[index].attr_cond_param[z] == pets[j].nature then
                pets[j].canCommit = true
                break
              end
              if z == #self.SubmitPetConf.attr_cond[index].attr_cond_param then
                pets[j].canCommit = false
              end
            end
            break
          end
          if index == #self.SubmitPetConf.attr_cond then
            pets[j].canCommit = true
          end
        end
      else
        pets[j].canCommit = true
      end
      if pets[j].canCommit then
        local IsTravel = _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.GetPetIsTravel, pets[j].gid)
        if not IsTravel then
          table.insert(pets1, pets[j])
        end
      end
    end
    return pets1
  end
  return pets
end

function UMG_PetAltar_C:updatePetTypeIcon(_dicTypes)
  local PetTypeList = {}
  for i = 1, 2 do
    local petType = _dicTypes[i]
    if petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
      if typeDic then
        table.insert(PetTypeList, {
          Path = typeDic.tips_base_icon,
          Name = typeDic.short_name
        })
      end
    end
  end
  if self.Attr1 then
    self.Attr1:InitGridView(PetTypeList)
  end
end

function UMG_PetAltar_C:OnPetAltarItemSelect(petData)
  self.petData = petData
  local commonAttrData = {}
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(petData.blood_id)
  table.insert(commonAttrData, {
    Name = PetBloodConf.blood_name,
    Path = PetBloodConf.icon
  })
  if self.Attr then
    self.Attr:InitGridView(commonAttrData)
  end
  if self.Attr:GetItemByIndex(0) then
    local blood = self.Attr:GetItemByIndex(0)
    if blood.Button then
      self:RemoveButtonListener(blood.Button)
      self:AddButtonListener(blood.Button, self.OnBloodPulse)
    end
  end
  if petData.canCommit then
    self.BtnConfirm:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.BtnConfirm:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if 0 ~= petData.changed_nature_neg_attr_type or 0 ~= petData.changed_nature_pos_attr_type then
    self.Character:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_lailang_png.img_lailang_png'")
  else
    self.Character:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_character_png.img_character_png'")
  end
  local baseInfos = {}
  local attritable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ATTRIBUTE_CONF)
  local attriConfs = attritable:GetAllDatas()
  for i, conf in pairs(attriConfs) do
    local _conf = conf
    if _conf and _conf.is_ui_show then
      local _num = PetUtils.GetPetBaseAttrByType(petData, _conf.attribute)
      local infoItem = {
        conf = _conf,
        num = _num,
        nature = petData.nature
      }
      if _conf.attr_ui_type == Enum.AttrUIType.AUT_BASE then
        table.insert(baseInfos, infoItem)
      end
    end
  end
  self:updatePetTypeIcon(petBaseConf.unit_type)
  self.CatchHardLv:Clear()
  local PetStarsList = PetUtils.GetPetStarsListByPetGID(petData.gid)
  self.CatchHardLv:InitGridView(PetStarsList)
  self:SetWeigthAndStature(petData)
  self.AltarRate:SetText(petData)
  self.TextClass:SetText(petData.level)
  local BallId = petData.ball_id
  if 0 == BallId then
    BallId = 100002
  end
  local CurIconPath = _G.DataConfigManager:GetBallConf(BallId).ball_tips_icon
  self.CurIcon:SetPath(CurIconPath)
  self.textPetName:SetText(petBaseConf.name)
  if 1 == petData.gender then
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ImagePetGender2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ImagePetGender1:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  local petNatureConf = _G.DataConfigManager:GetNatureConf(petData.nature)
  self.textPetNature:SetText(petNatureConf.name)
  self.Panel_NameInfo:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetAltar_C:OnBloodPulse()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.PetUIOpenPetBloodPulse, self.petData)
end

function UMG_PetAltar_C:OnClickParticulars()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, self.petData, 1, false)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetEnterPetPanelType, PetUIModuleEnum.EnterType.PetAltar)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1014, "UMG_LobbyMain_C:OnBtnPetHeadClick")
  NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    callback = self.OnUMGLoadFinished
  })
end

function UMG_PetAltar_C:SetWeigthAndStature(PetBaseInfo)
end

function UMG_PetAltar_C:OnPetAltarItemUnSelect()
  Log.Debug("UMG_PetAltar_C:OnPetAltarItemUnSelect")
  self.Panel_NameInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetAltar_C:OnClickConfirm()
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, true)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetAltar_C:OnClickConfirm")
  _G.NRCModuleManager:DoCmd(AltarModuleCmd.OpenGivePetAwayTips, self.petData, self.action)
end

function UMG_PetAltar_C:OnClickCancel()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_PetAltar_C:OnClickCancel")
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, true)
  if self.action and self.action.Finish then
    self.action:Finish(false, nil)
  end
  _G.NRCModuleManager:DoCmd(AltarModuleCmd.ClosePetAltarPanel)
end

function UMG_PetAltar_C:OnDestruct()
  self.action = nil
  self:RemoveButtonListener(self.CloseBtn.btnClose)
  self:RemoveButtonListener(self.BtnConfirm.btnLevelUp)
  self:RemoveButtonListener(self.Btnknow.btnLevelUp)
  NRCEventCenter:UnRegisterEvent(self, AltarModuleEvent.PetAltarItemSelect, self.OnPetAltarItemSelect)
  NRCEventCenter:UnRegisterEvent(self, AltarModuleEvent.PetAltarItemUnSelect, self.OnPetAltarItemUnSelect)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
end

function UMG_PetAltar_C:OnDeactive()
end

return UMG_PetAltar_C
