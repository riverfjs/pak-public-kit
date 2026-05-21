local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_Pet_Catch_C = _G.NRCPanelBase:Extend("UMG_Pet_Catch_C")

function UMG_Pet_Catch_C:OnConstruct()
  local icon1 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_01grew_png.ui_pet_attribute_01grew_png'"
  local icon2 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_02grew_png.ui_pet_attribute_02grew_png'"
  local icon3 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_03grew_png.ui_pet_attribute_03grew_png'"
  local icon4 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_06grew_png.ui_pet_attribute_06grew_png'"
  local icon5 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_04grew_png.ui_pet_attribute_04grew_png'"
  local icon6 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_05grew_png.ui_pet_attribute_05grew_png'"
  self.Icon = {
    hp = icon1,
    phyAtk = icon2,
    phyDef = icon3,
    speed = icon4,
    speAtk = icon5,
    speDef = icon6
  }
  self.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  self.rewards = {}
  self.camera = nil
  self.camera1 = nil
  self.captureComponent = nil
  self.captureComponent1 = nil
  self.petActor = nil
  self.PetLevel = nil
  self.time = 0
  self.maxAnimListIdleTime = 5
  self.petbaseConf = nil
  self.actor = nil
  self.PetData = nil
  self.animList = {"Alert", "Relax"}
  self.curAnimInfo = {isPlayAnim = false, curAniLength = 0}
  self.curAnimListTime = 0
  self.curAnimListIndex = 1
  self.CommonHeight = 180
  self:OnAddEventListener()
  self:PlayAnimation(self.In)
  self:SetChildViews(self.UMG_PetRate)
end

function UMG_Pet_Catch_C:OnActive(_Param, PetLevel)
  _G.NRCAudioManager:BatchSetState("UI_Music;UI_Music;UI_Type;Settlement")
  if self:IsPCMode() then
    self:PCModeScreenSetting()
  end
  self:SetTestData(_Param, PetLevel)
  self:SetPanelInfo()
end

function UMG_Pet_Catch_C:SetTestData(_Param, PetLevel)
  if not _Param then
    _Param = {
      rewards = {
        {
          type = ProtoEnum.GoodsType.GT_VITEM,
          id = 7,
          num = 200,
          tag = 0,
          src_type = ProtoEnum.GoodsType.GT_NONE,
          reward_reason = 10
        },
        {
          type = ProtoEnum.GoodsType.GT_BAGITEM,
          id = 100115,
          num = 5,
          tag = 0,
          src_type = ProtoEnum.GoodsType.GT_NONE,
          first_get = false,
          reward_reason = 10
        },
        {
          type = ProtoEnum.GoodsType.GT_PET,
          id = 217,
          num = 1,
          tag = 0,
          src_type = ProtoEnum.GoodsType.GT_NONE,
          first_get = true,
          pet_data = _G.DataModelMgr.PlayerDataModel:GetPetData()[1],
          reward_reason = 10
        }
      }
    }
    Log.Error("\229\144\142\229\143\176\230\151\160\230\149\176\230\141\174\230\181\139\232\175\149\230\149\176\230\141\174")
  end
  self.rewards = _Param.rewards
  self.PetLevel = PetLevel
end

function UMG_Pet_Catch_C:OnDeactive()
  _G.NRCAudioManager:BatchSetState("UI_Music;None")
end

function UMG_Pet_Catch_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseRenamePanel, self.OnClickbtnCloseRenamePanel)
  self:AddButtonListener(self.BtnRechristen_1, self.OnBtnRechristen_1Click)
  self:AddButtonListener(self.BloodBtn, self.OnBloodBtn)
  self:AddButtonListener(self.UMG_CollectBtn.Button, self.OnBtnCollectClick)
end

function UMG_Pet_Catch_C:OnClickbtnCloseRenamePanel()
  _G.BattleEventCenter:Dispatch(BattleEvent.CLICKED_Result_Close)
end

function UMG_Pet_Catch_C:SetTalentRank(petData)
  self.UMG_PetRate:SetText(petData)
end

function UMG_Pet_Catch_C:OnBtnRechristen_1Click()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpenPetTips, self.PetData)
end

function UMG_Pet_Catch_C:OnBloodBtn()
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_PetBaseInfo_C:OnBloodPulse")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpenPetBloodPulse, self.PetData)
end

function UMG_Pet_Catch_C:OnBtnCollectClick()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetCollectPanel, self.PetData.gid, self.partner_mark or 0)
end

function UMG_Pet_Catch_C:UpdateCollect(partner_mark)
  self.partner_mark = partner_mark
  self.UMG_CollectBtn:UpdateInfo(partner_mark)
end

function UMG_Pet_Catch_C:SetPanelInfo()
  for _, reward in ipairs(self.rewards) do
    if reward.type == ProtoEnum.GoodsType.GT_PET then
      self:SetPetInfo(reward)
      break
    end
  end
end

function UMG_Pet_Catch_C:SetPetInfo(reward)
  if not reward or not reward.pet_data then
    Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\144\142\229\143\176\229\143\145\230\157\165\230\149\176\230\141\174")
    return
  end
  local petBaseCfg = _G.DataConfigManager:GetPetbaseConf(reward.pet_data.base_conf_id)
  if petBaseCfg then
    self.PetData = reward.pet_data
    local text = string.format("%s%s", LuaText.umg_pet_catch_1, petBaseCfg.name)
    self.Text_Name:SetText(text)
    self.TextName:SetText(self.PetData.name)
    if reward.pet_data.blood_id then
      local typeList = {}
      local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.PetData.blood_id)
      if PetBloodConf then
        table.insert(typeList, {
          Name = PetBloodConf.blood_name,
          Path = PetBloodConf.icon
        })
      end
      self.Attr:InitGridView(typeList)
    end
    if petBaseCfg then
      self:updatePetTypeIcon(petBaseCfg.unit_type)
    end
    if self.PetData then
      self:UpdateCollect(self.PetData.partner_mark)
    else
      self:UpdateCollect(0)
    end
  end
  local Levels = {}
  if self.PetLevel then
    for i = 0, self.PetLevel - 1 do
      table.insert(Levels, {IsHas = true})
    end
  end
  self.List:InitGridView(Levels)
  self:SetPetAttri()
  self:updatePetGender(self.PetData.gender)
  self:SetTalentRank(self.PetData)
  self:UpdateMDT_SHINING()
end

function UMG_Pet_Catch_C:SetPetAttri()
  local _petData = self.PetData
  local baseInfoList = {}
  if _petData then
    local attri_info = _petData.attribute_info
    local natureConf = {}
    local natureConfNormal = _G.DataConfigManager:GetNatureConf(_petData.nature)
    local natureConfChange = {positive_effect = nil, negative_effect = nil}
    if 0 ~= _petData.changed_nature_pos_attr_type then
      natureConfChange.positive_effect = self:GetChangeAttrReqEnum(_petData.changed_nature_pos_attr_type)
    end
    if 0 ~= _petData.changed_nature_neg_attr_type then
      natureConfChange.negative_effect = self:GetChangeAttrReqEnum(_petData.changed_nature_neg_attr_type)
    end
    if natureConfChange.positive_effect or natureConfChange.negative_effect then
      if not natureConfChange.positive_effect then
        natureConfChange.positive_effect = natureConfNormal.positive_effect
      end
      if not natureConfChange.negative_effect then
        natureConfChange.negative_effect = natureConfNormal.negative_effect
      end
      natureConf = natureConfChange
    else
      natureConf = natureConfNormal
    end
    local ItemDataList = {}
    if attri_info.attack.talent and 0 ~= attri_info.attack.talent then
      local ItemData = {
        data = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_PHYATK),
        data1 = attri_info.attack,
        natureConf = natureConf,
        attributeType = Enum.AttributeType.AT_PHYATK_PERCENT,
        icon = self.Icon.phyAtk
      }
      table.insert(ItemDataList, ItemData)
    end
    if attri_info.defense.talent and 0 ~= attri_info.defense.talent then
      local ItemData = {
        data = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_PHYDEF),
        data1 = attri_info.defense,
        natureConf = natureConf,
        attributeType = Enum.AttributeType.AT_PHYDEF_PERCENT,
        icon = self.Icon.phyDef
      }
      table.insert(ItemDataList, ItemData)
    end
    if attri_info.speed.talent and 0 ~= attri_info.speed.talent then
      local ItemData = {
        data = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEED),
        data1 = attri_info.speed,
        natureConf = natureConf,
        attributeType = Enum.AttributeType.AT_SPEED_PERCENT,
        icon = self.Icon.speed
      }
      table.insert(ItemDataList, ItemData)
    end
    if attri_info.hp.talent and 0 ~= attri_info.hp.talent then
      local ItemData = {
        data = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_HPMAX),
        data1 = attri_info.hp,
        natureConf = natureConf,
        attributeType = Enum.AttributeType.AT_HPMAX_PERCENT,
        icon = self.Icon.hp
      }
      table.insert(ItemDataList, ItemData)
    end
    if attri_info.special_attack.talent and 0 ~= attri_info.special_attack.talent then
      local ItemData = {
        data = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEATK),
        data1 = attri_info.special_attack,
        natureConf = natureConf,
        attributeType = Enum.AttributeType.AT_SPEATK_PERCENT,
        icon = self.Icon.speAtk
      }
      table.insert(ItemDataList, ItemData)
    end
    if attri_info.special_defense.talent and 0 ~= attri_info.special_defense.talent then
      local ItemData = {
        data = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEDEF),
        data1 = attri_info.special_defense,
        natureConf = natureConf,
        attributeType = Enum.AttributeType.AT_SPEDEF_PERCENT,
        icon = self.Icon.speDef
      }
      table.insert(ItemDataList, ItemData)
    end
    self.List_1:InitGridView(ItemDataList)
  end
end

function UMG_Pet_Catch_C:UpdateMDT_SHINING()
  self.DazzlingColors:InitUI(self.PetData)
end

function UMG_Pet_Catch_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Pet_Catch_C:PCModeScreenSetting()
  local Padding = UE4.FMargin()
  Padding.Left = -164
  Padding.Top = -74
  Padding.Right = -164
  Padding.Bottom = -74
  self:SetRenderScale(UE4.FVector2D(0.88, 0.88))
  if self.Slot then
    self.Slot:SetOffsets(Padding)
  end
end

function UMG_Pet_Catch_C:GetChangeAttrReqEnum(attribute)
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

function UMG_Pet_Catch_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Pet_Catch_C:updatePetTypeIcon(_dicTypes)
  local typeList = {}
  for i, Type in ipairs(_dicTypes) do
    table.insert(typeList, Type)
  end
  self.Attr1:InitGridView(typeList)
end

function UMG_Pet_Catch_C:OnAnimFinish()
  self:PlayAnimByName("Idle", -1)
end

function UMG_Pet_Catch_C:PlayAnimByName(_name, _loopCount)
  local AddTime = 0
  if "Show" == _name then
    AddTime = 2
  end
  if self.petActor then
    _loopCount = _loopCount or 1
    local curAnimInfo = self.curAnimInfo
    local len = self.petActor:PlayAnimByName(_name, 1, 0, 0, 0, _loopCount)
    if _loopCount and _loopCount > 0 then
      curAnimInfo.isPlayAnim = true
      curAnimInfo.curAniName = _name
      curAnimInfo.curAniLength = len * _loopCount + AddTime
      Log.Debug(curAnimInfo.curAniLength, "UMG_Pet_Catch_C:PlayAnimByName")
    else
      curAnimInfo.curAniLength = 0
      curAnimInfo.isPlayAnim = false
    end
  end
end

function UMG_Pet_Catch_C:HideInfo()
  self:PlayAnimation(self.Out)
end

function UMG_Pet_Catch_C:ClosePanel()
  self:DoClose()
end

return UMG_Pet_Catch_C
