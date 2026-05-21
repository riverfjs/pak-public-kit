local Base = _G.NRCPanelBase
local RogueModuleEnum = require("NewRoco/Modules/System/BattleRogue/RogueModuleEnum")
local RogueModuleEvent = require("NewRoco/Modules/System/BattleRogue/BattleRogueModuleEvent")
local UMG_HerbologyBadge_Main_C = Base:Extend("UMG_HerbologyBadge_Main_C")
local ChallengeInfoFlag = RogueModuleEnum.ChallengeInfoFlag
local IsPCMode = _G.UE4Helper.IsPCMode

function UMG_HerbologyBadge_Main_C:OnConstruct()
  Base.OnConstruct(self)
  self.imcPriority = -2
  self:BindInputAction()
  self:AddEventListeners()
  self:SetChildViews(self.SkillTips)
  self.ModuleData = self.module.Data
  self.ListCharacter:SetMsgHandler({
    OnItemClick = _G.MakeWeakFunctor(self, self.OnFeatureItemSelected)
  })
  self.ListCharacter_1:SetMsgHandler({
    OnItemClick = _G.MakeWeakFunctor(self, self.OnSkillItemSelected)
  })
end

function UMG_HerbologyBadge_Main_C:OnDestruct()
  self:RemoveEventListeners()
  self:CancelDelay()
  Base.OnDestruct(self)
end

function UMG_HerbologyBadge_Main_C:OnActive(HerbologyBadgeMainParams)
  Base.OnActive(self)
  self:InitChapterInfo()
  self:InitPetInfo()
end

function UMG_HerbologyBadge_Main_C:OnDeactive(...)
  ReleaseForceAllChild(self)
  Base.OnDeactive(self, ...)
end

function UMG_HerbologyBadge_Main_C:OnEnable()
  _G.NRCModuleManager:GetModule("MainUIModule"):OpenInteractMain()
  UE4Helper.SetDesiredShowCursor(false, "UMG_HerbologyBadge_Main_C")
  self:RemoveInputBlockMappingContext("UMG_HerbologyBadge_Main_C:OnEnable")
  self:RefreshPanel(ChallengeInfoFlag.All)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.MAINUIOPEN)
end

function UMG_HerbologyBadge_Main_C:DisablePlayerJump()
  return true
end

function UMG_HerbologyBadge_Main_C:OnDisable()
  UE4Helper.ReleaseDesiredShowCursor("UMG_HerbologyBadge_Main_C")
  self:AddInputBlockMappingContext("UMG_HerbologyBadge_Main_C:OnDisable")
end

function UMG_HerbologyBadge_Main_C:AddEventListeners()
  self:AddButtonListener(self.Btn_Quit.btnLevelUp, self.OnBtnQuit)
  self:AddButtonListener(self.Btn_Chitchat.btnLevelUp, self.OpenQuickChat)
  self:AddButtonListener(self.Btn_TrialInfo.btnLevelUp, self.OpenHerbologyTrialTips)
  self:AddButtonListener(self.TouchButton, self.OpenHerbologyPetDetailedInformation)
  self:RegisterEvent(self, RogueModuleEvent.TrialDataChange, self.RefreshPanel)
end

function UMG_HerbologyBadge_Main_C:RemoveEventListeners()
  self:UnRegisterEvent(self, RogueModuleEvent.TrialDataChange)
end

function UMG_HerbologyBadge_Main_C:OnBtnQuit()
  self.module:OpenExitPanel()
end

function UMG_HerbologyBadge_Main_C:OnTick(deltaTime)
  self.PlayerCtrl:OnTick(deltaTime)
end

local ChallengeRefreshMap = {
  {
    ChallengeInfoFlag.PetInfo,
    "RefreshPetInfo"
  },
  {
    ChallengeInfoFlag.EventList,
    "RefreshEventList"
  },
  {
    ChallengeInfoFlag.Chapter,
    "RefreshChapterInfo"
  }
}

function UMG_HerbologyBadge_Main_C:RefreshPanel(UpdateFlag)
  if not UpdateFlag then
    return
  end
  for _, entry in ipairs(ChallengeRefreshMap) do
    if UpdateFlag & entry[1] == entry[1] then
      self[entry[2]](self)
    end
  end
end

function UMG_HerbologyBadge_Main_C:InitPetInfo()
  local PetGid = self.ModuleData.TrialPetInfo.pet_gid
  local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(PetGid)
  local PetBaseID = _G.DataConfigManager:GetPetConf(PetData.conf_id).base_id
  self.HeadIcon:SetIconPathAndMaterial(PetBaseID, PetData.mutation_type, PetData.glass_info)
  local FirstDepartment = PetData.skill_dam_type[1]
  local FirstTypeDict = _G.DataConfigManager:GetTypeDictionary(FirstDepartment)
  if FirstDepartment then
    self.DepartmentIcon:SetPath(FirstTypeDict.tips_base_icon)
  end
  local SecDepartment = #PetData.skill_dam_type > 1 and PetData.skill_dam_type[2]
  if SecDepartment then
    local SecTypeDict = _G.DataConfigManager:GetTypeDictionary(SecDepartment)
    self.DepartmentIcon_1:SetPath(SecTypeDict.tips_base_icon)
  else
    self.DepartmentIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

local function ClampList(List, MaxNum)
  if not List or MaxNum >= #List then
    return List
  end
  local result = {}
  table.move(List, 1, MaxNum, 1, result)
  return result
end

function UMG_HerbologyBadge_Main_C:RefreshPetInfo()
  local PetInfo = self.ModuleData.TrialPetInfo
  self.NRCText_Class:SetText(PetInfo.level)
  self.Progress_State:SetPercent(PetInfo.current_hp / PetInfo.max_hp)
  local FeatureList = ClampList(PetInfo.acquired_feature_ids, 3)
  local SkillList = ClampList(PetInfo.skills, 3)
  self.ListCharacter:InitGridView(FeatureList)
  self.Text_NumberCharacteristics:SetText(tostring(#FeatureList))
  self.ListCharacter_1:InitGridView(SkillList)
  self.Text_NumberSkills:SetText(tostring(#SkillList))
end

function UMG_HerbologyBadge_Main_C:RefreshEventList()
  self.ProgressChallengeLst:InitGridView(self.ModuleData.EventList)
end

function UMG_HerbologyBadge_Main_C:RefreshChapterInfo()
  if self.module.CurState == RogueModuleEnum.RogueStateEnum.ChallengeLobby then
    self.TextTitle_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ProgressChallengeLst:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.TextTitle_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ProgressChallengeLst:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.MoneyBtn:SetSumText(tostring(self.ModuleData.RemainingCoin))
end

function UMG_HerbologyBadge_Main_C:InitChapterInfo()
  local TrialConf = _G.DataConfigManager:GetGrassTrialConf(self.ModuleData.TrialID)
  local ChapterConf = _G.DataConfigManager:GetGrassTrialChapterConf(self.ModuleData.CurChapterID)
  self.TextTitle:SetText(TrialConf.name)
  self.TextTitle_1:SetText(ChapterConf.name)
end

function UMG_HerbologyBadge_Main_C:InitChatBtn()
  local Text, Image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_QuickChat")
end

function UMG_HerbologyBadge_Main_C:OnSkillItemSelected()
  self.SkillTips:ActiveSkills()
end

function UMG_HerbologyBadge_Main_C:OnFeatureItemSelected()
  self.SkillTips:ActiveFeatures()
end

function UMG_HerbologyBadge_Main_C:RemoveInputBlockMappingContext(Reason)
  Log.InfoFormat("UMG_HerbologyBadge_Main_C:RemoveInputBlockMappingContext, Reason = %s", Reason)
  local PlayerControlIMC = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_PlayerControll")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, PlayerControlIMC, self.imcPriority)
  local mappingContext = self:GetInputMappingContext("IMC_GrassBadgeMain")
  if mappingContext then
    mappingContext:EnableInputMappingContext(self.imcPriority)
  end
end

function UMG_HerbologyBadge_Main_C:AddInputBlockMappingContext(Reason)
  Log.InfoFormat("UMG_HerbologyBadge_Main_C:AddInputBlockMappingContext, Reason = %s", Reason)
  local PlayerControlIMC = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_PlayerControll")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, PlayerControlIMC)
  local mappingContext = self:GetInputMappingContext("IMC_GrassBadgeMain")
  if mappingContext then
    mappingContext:DisableInputMappingContext()
  end
end

function UMG_HerbologyBadge_Main_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_GrassBadgeMain", self.imcPriority)
  if mappingContext then
    mappingContext:EnableInputMappingContext(self.imcPriority)
    mappingContext:BindAction("IA_ExitDungeon", self, "OnBtnQuit", UE.ETriggerEvent.Triggered)
    mappingContext:BindAction("MoveForward")
    mappingContext:BindAction("MoveRight")
    mappingContext:BindAction("IA_MoveBackward")
    mappingContext:BindAction("IA_MoveLeft")
  end
end

function UMG_HerbologyBadge_Main_C:RefreshFunctionEntryIcons()
  local Items = {}
  local hideFriend = false
  if not hideFriend then
    table.insert(Items, {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_haoyou1_png.img_haoyou1_png'",
      on_clicked = FPartial(self.OpenFriendPanel, self),
      redDotKey = 81,
      type = _G.Enum.FunctionEntrance.FE_FRIEND,
      IsHide = false
    })
  else
    table.insert(Items, {IsHide = true})
  end
  table.insert(Items, {IsHide = true})
  table.insert(Items, {IsHide = true})
  local hideQuickChat = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT) or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT) or FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_MULTI_MAIN_MULTI_CHAT, false, false)
  if not hideQuickChat then
    table.insert(Items, {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_kuaijieliaotian_png.img_kuaijieliaotian_png'",
      on_clicked = FPartial(self.OpenQuickChatByKey, self),
      redDotKey = 83,
      type = _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT,
      IsHide = false
    })
  end
  local hidePhoto = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TAKE_PHOTO) or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_TAKE_PHOTO)
  if not hidePhoto then
    table.insert(Items, {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_xiangji1_png.img_xiangji1_png'",
      on_clicked = FPartial(self.OpenTakePhotos, self),
      redDotKey = 0,
      type = _G.Enum.FunctionEntrance.FE_TAKE_PHOTO
    })
  end
  local hideFastDressUp = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP) or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
  if not hideFastDressUp or self.bMainOpenFriend then
    table.insert(Items, {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_shizhuang_png.img_shizhuang_png'",
      on_clicked = FPartial(self.EnterQuickDressUp, self),
      redDotKey = 405,
      type = _G.Enum.FunctionEntrance.FE_FAST_DRESSUP
    })
    self.bMainOpenFriend = false
  end
  if self.FunctionEntry:GetItemCount() == #Items then
    self.FunctionEntry._listDatas = Items
    for i = 1, #Items do
      self.FunctionEntry:RefreshItemDataByIndex(i - 1)
    end
  else
    self.FunctionEntry:InitGridView(Items)
  end
  self:PCKeySetting()
end

function UMG_HerbologyBadge_Main_C:OpenFriendPanel()
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_COMPASS, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenFriendUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  Log.Debug("UMG_LobbyMain_C:OpenFriendPanel")
  self.bMainOpenFriend = true
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_LobbyMain_C:OpenFriendPanel")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenMainPanel)
end

function UMG_HerbologyBadge_Main_C:OpenQuickChatByKey()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT, true)
  local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT)
  if isBan or isHide then
    return
  end
  local Item = self.FunctionEntry:GetItemByIndex(3)
  if Item and Item:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OpenQuickChat()
  return true
end

function UMG_HerbologyBadge_Main_C:OpenQuickChat()
  Log.Debug("UMG_HerbologyBadge_Main_C:OpenQuickChat")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenQuickChatBubble)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_HerbologyBadge_Main_C:OpenQuickChat")
end

function UMG_HerbologyBadge_Main_C:CloseQuickChat()
end

function UMG_HerbologyBadge_Main_C:OpenHerbologyTrialTips()
  self.module:OpenHerbologyTrialTips(true)
end

function UMG_HerbologyBadge_Main_C:OpenHerbologyPetDetailedInformation()
  self.module:OpenHerbologyBadgeDetailedInformation()
end

function UMG_HerbologyBadge_Main_C:OpenTakePhotos()
  if self.WaitForEnterPhotoGraph then
    self:CancelDelayByID(self.WaitForEnterPhotoGraph)
    self.WaitForEnterPhotoGraph = nil
    return NRCModuleManager:DoCmd(MainUIModuleCmd.TryOpenTakePhotosPanel, true)
  end
end

function UMG_HerbologyBadge_Main_C:EnterQuickDressUp()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
  local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
  if isBan or isHide then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceClosetPanel, nil, true)
  return true
end

function UMG_HerbologyBadge_Main_C:PCKeySetting()
  if SystemSettingModuleCmd then
    for i = 1, 6 do
      local item = self.FunctionEntry:GetItemByIndex(i - 1)
      if item and item._data then
        local text, image = ""
        if item._data.type == _G.Enum.FunctionEntrance.FE_TAKE_PHOTO then
          text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_PgEnter")
        elseif item._data.type == _G.Enum.FunctionEntrance.FE_FAST_DRESSUP then
          text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_QuickDressUP")
        elseif item._data.type == _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT then
          text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_QuickChat")
        elseif item._data.type == _G.Enum.FunctionEntrance.FE_FRIEND then
          text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_OpenFriendUI")
        end
        if "" ~= image then
          item.PCKey_2:SetImageMode(image)
        else
          item.PCKey_2:SetText(text)
        end
        item.PCKey_2:SetKeyVisibility(true)
      end
    end
  end
end

function UMG_HerbologyBadge_Main_C:GetPropTipsSizeY()
  return 360
end

return UMG_HerbologyBadge_Main_C
