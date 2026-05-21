local PetUtils = require("NewRoco.Utils.PetUtils")
local CampingModule = NRCModuleBase:Extend("CampingModule")
_G.CampingModuleCmd = require("NewRoco.Modules.System.Camping.CampingModuleCmd")
_G.CampingModuleEvent = require("NewRoco.Modules.System.Camping.CampingModuleEvent")
_G.CampingModuleEnum = require("NewRoco.Modules.System.Camping.CampingModuleEnum")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local FakePerformConf = require("NewRoco.Modules.Core.Scene.Component.Show.FakePerformConf")
local HoldingItemComponent = require("NewRoco.Modules.Core.Scene.Component.Show.HoldingItemComponent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local SkillShowComponent = require("NewRoco.Modules.Core.Scene.Component.Show.SkillShowComponent")

function CampingModule:OnConstruct()
  self:RegisterCmd(_G.CampingModuleCmd.GoToTime, self.GotoTime)
  self:RegisterCmd(_G.CampingModuleCmd.SendExchangeReq, self.SendExchangeReq)
  self:RegisterCmd(_G.CampingModuleCmd.ClearCampingData, self.ClearCampingData)
  self:RegisterCmd(_G.CampingModuleCmd.ClearCampingCamera, self.ClearCampingCamera)
  self:RegisterCmd(_G.CampingModuleCmd.ShowBlackScreen, self.ShowBlackScreen)
  self:RegisterCmd(_G.CampingModuleCmd.PlayCampingSkill, self.PlayCampingSkill)
  self:RegisterCmd(_G.CampingModuleCmd.PlayFixCampingSkill, self.PlayFixCampingSkill)
  self:RegisterCmd(_G.CampingModuleCmd.LuluAlreadyAppeared, self.LuluAlreadyAppeared)
  self:RegisterCmd(_G.CampingModuleCmd.ShowPlayer, self.ShowPlayer)
  self:RegisterCmd(_G.CampingModuleCmd.HidePlayerAndPets, self.HidePlayerAndPet)
  self:RegisterCmd(_G.CampingModuleCmd.HideOrShowPets, self.HideOrShowPets)
  self:RegisterCmd(_G.CampingModuleCmd.JustClearCamera, self.JustClearCamera)
  self:RegisterCmd(_G.CampingModuleCmd.SetCampfire, self.SetCampfire)
  self:RegisterCmd(_G.CampingModuleCmd.GetCampfire, self.GetCampfire)
  self:RegisterCmd(_G.CampingModuleCmd.OpenMagicDetails, self.OpenDetails)
  self:RegisterCmd(_G.CampingModuleCmd.OpenPetWarehousePanel, self.SetOpenPetWarehouseSkill)
  self:RegisterCmd(_G.CampingModuleCmd.OnPetWarehouseChangePet, self.OnPetWarehouseChangePet)
  self:RegisterCmd(_G.CampingModuleCmd.OpenPetWarehouseTips, self.SetOpenTipPetWarehouse)
  self:RegisterCmd(_G.CampingModuleCmd.GetCampingPet, self.GetCampingPet)
  self:RegisterCmd(_G.CampingModuleCmd.SetIsCultivatePet, self.SetIsCultivatePet)
  self:RegisterCmd(_G.CampingModuleCmd.GetIsCultivatePet, self.GetIsCultivatePet)
  self:RegisterCmd(_G.CampingModuleCmd.DebugLogCampfirePFF, self.CmdDebugLogCampfirePFF)
  self:RegisterCmd(_G.CampingModuleCmd.ShowNpcInCamp, self.ShowNpcInCamp)
  self:RegisterCmd(_G.CampingModuleCmd.SetNpcModelVisible, self.SetNpcModelVisible)
  self:RegisterCmd(_G.CampingModuleCmd.RecordReportPetInfo, self.RecordReportPetInfo)
  self:RegisterCmd(_G.CampingModuleCmd.ShowReportPetInfo, self.ShowReportPetInfo)
  self:RegPanel("CampingAscension", "UMG_Camping_Ascension", _G.Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("CampingRestore", "UMG_Camping_Restore", _G.Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("CampingBuild", "UMG_CampingBuild", _G.Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("CampingBuildSettlement", "UMG_BuildingSettlement", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MagicNourish", "UMG_Magic_Nourish", _G.Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("MagicTips", "UMG_Magic_DetailsTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MagicDetails", "UMG_Magic_Details", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Nourish", "Nourish/UMG_Nourish", _G.Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("NourishFruit", "Nourish/UMG_Nourish_Fruit", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NourishTips", "Nourish/UMG_Nourish_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("GoodAndBadiTips", "Nourish/UMG_Nourish_GoodAndBadi_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NourishUpgradeConfirmPanel", "Nourish/UMG_Nourish_Upgrade1", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NourishUpgradeSuccessPanel", "Nourish/UMG_Nourish_Upgrade", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NourishHint", "Nourish/UMG_Nourish_Hint", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("NourishHintFinal", "Nourish/UMG_Nourish_Hint1", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self.PetFruitList = nil
  self.SelectPetFruitItemData = nil
  self.SelectedFruitItem = nil
  self.placeName = nil
  self.fruit_id = nil
  self.RefreshReason = nil
  self.fruit_idAddTemp = {}
  self.selectIndex = -1
  self.target_time = 0
  self.NpcId = nil
  self.panel_to_open = nil
  self.panel_opening = nil
  self.NourishTipsOpen = false
  self.GoodAndBadiTipsOpen = false
  self.Action = nil
  self.hpMaxTarget = 0
  self.ExChangeType = nil
  self.skillProxy = nil
  self.CameraActor = nil
  self.CameraActorMesh = nil
  self.petModel = nil
  self.LuluModel = nil
  self.campfire = nil
  self.PetLoadFinished = false
  self.LuluLoadFinished = false
  self.NotConfFruit = {}
  self.IsCultivatePet = false
  self.ContentIdToRuleMap = nil
  self.last_fruit_take_out_timestamp = nil
  self.ItemDeltaTimer = 0
  self.MageNpcIDList = {}
  self.petSubmitNum = nil
  self.firstPetName = nil
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.NRCEventCenter:RegisterEvent("CampingModule", self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:RegisterEvent("CampingModule", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDialogueEnded)
  _G.NRCEventCenter:RegisterEvent("CampingModule", self, SceneEvent.PreLoadMapStart, self.OnDialogueEnded)
end

function CampingModule:SendExchangeReq(exchangeId, exchangeNum, Type, actor_id)
  self.ExChangeType = Type
  local req = _G.ProtoMessage:newZoneExchangeReq()
  req.exchange_id = exchangeId
  req.exchange_num = exchangeNum
  if self.campfire then
    req.npc_space_obj_id = self.campfire.sceneCharacter.serverData.base.actor_id
  elseif actor_id then
    req.npc_space_obj_id = actor_id
  else
    Log.Error("\230\158\175\230\158\157\228\186\164\228\186\146\239\188\140\228\189\134\230\152\175\230\137\190\228\184\141\229\136\176\230\158\175\230\158\157")
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_EXCHANGE_REQ, req, self, self.OnZoneExchangeRsp, true)
end

function CampingModule:OnZoneExchangeRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    local itemInfos = {}
    local rewards = _rsp.ret_info.goods_reward.rewards
    for _, v in ipairs(rewards) do
      local itemId = v.id
      local itemText = tostring(v.num)
      table.insert(itemInfos, {
        itemId = itemId,
        itemText = itemText,
        id = itemId,
        num = v.num,
        type = v.type
      })
    end
    if #itemInfos > 0 and 0 == self.ExChangeType then
    elseif #itemInfos > 0 and 1 == self.ExChangeType then
      _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, itemInfos)
      _G.NRCModuleManager:DoCmd(StarChainModuleCmd.StarChainChangeUpdateTime, itemInfos[1].num)
    end
  end
end

local function SortPetFruitList(a, b)
  if a.type == b.type then
    return a.BagItem.num > b.BagItem.num
  else
    return a.type > b.type
  end
end

function CampingModule:OnDialogueEnded(bIsConnected)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetReportPanel)
  if self.campfire then
    local skillComponent = self.campfire.RocoSkill
    if skillComponent then
      skillComponent:StopCurrentSkill()
      skillComponent:ClearAllPassiveSkillObjs()
    end
    local campSceneCharacter = self.campfire.sceneCharacter
    local skillShowComp = campSceneCharacter and campSceneCharacter:GetComponent(SkillShowComponent)
    if skillShowComp then
      skillShowComp:StopAll()
    end
    self:ClosePanelByLayer(_G.Enum.UILayerType.UI_LAYER_DIALOGUE)
    self:ClosePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    self:ClosePanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
    self:ClearCampingData()
    self:JustClearCamera(nil)
    self:ShowPlayer()
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer then
      localPlayer:StopAllMontage(0.1)
    end
  end
  self.petSubmitNum = nil
  self.firstPetName = nil
end

function CampingModule:CmdDebugLogCampfirePFF()
end

function CampingModule:GetPFF(Pff)
end

function CampingModule:IsCampUpgradeEnable()
  if not self.campfire then
    return false
  end
  local CampingId = self.campfire.sceneCharacter.serverData.npc_base.npc_content_cfg_id
  local CampingLv = self.campfire.sceneCharacter.serverData.base.lv
  local campingLvTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CAMP_LEVELUP_CONF):GetAllDatas()
  local campLvCfg
  for k, v in ipairs(campingLvTable) do
    if v.content_id == CampingId and v.level == CampingLv + 1 then
      campLvCfg = v
    end
  end
  if not campLvCfg then
    return false
  end
  local HasUpItemNum = 0
  if campLvCfg.levelup_cost_item_type == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(campLvCfg.levelup_cost_item_id)
    if bagItemConf then
      local itemData = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, campLvCfg.levelup_cost_item_id)
      if itemData then
        HasUpItemNum = itemData.num or 0
      end
    end
  elseif campLvCfg.levelup_cost_item_type == _G.Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(campLvCfg.levelup_cost_item_id)
    HasUpItemNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(campLvCfg.levelup_cost_item_id)
  end
  if HasUpItemNum < campLvCfg.levelup_cost_item_num then
    return false
  else
    return true
  end
end

function CampingModule:OnActive()
end

function CampingModule:OnRelogin()
end

function CampingModule:SetNourishPanelBtnClick(CanClick)
  if self:HasPanel("Nourish") then
    local panel = self:GetPanel("Nourish")
    panel:SetButtonEnabled(CanClick)
  end
end

function CampingModule:OnDeactive()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDialogueEnded)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PreLoadMapStart, self.OnDialogueEnded)
end

function CampingModule:SetCampfire(campfire)
  if campfire then
    if self.campfire and self.campfire ~= campfire then
      Log.Error("\232\191\153\233\135\140\230\152\175\230\156\137\233\151\174\233\162\152\231\154\132\239\188\140\228\184\138\228\184\128\230\172\161\231\154\132campfire\230\178\161\230\156\137\232\162\171\230\184\133\231\169\186\230\142\137\239\188\140\229\166\130\230\158\156\232\131\189\229\164\141\231\142\176\231\154\132\232\175\157\239\188\140\232\175\183\230\138\165\231\187\153\230\153\186\228\188\159")
      if self.campfire and self.campfire.sceneCharacter then
        self.campfire.sceneCharacter:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnCampfireLeave)
      end
    end
    self.campfire = campfire
    if self.campfire.sceneCharacter then
      if not self.campfire.sceneCharacter:HasListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnCampfireLeave) then
        self.campfire.sceneCharacter:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnCampfireLeave)
      end
    else
      Log.Error("\230\156\137\228\184\128\228\184\170\230\158\175\230\158\157\230\178\161\230\156\137SceneCharacter\239\188\140\232\191\153\229\190\136\230\156\137\233\151\174\233\162\152", self.campfire:GetFullName())
    end
  else
    if self.campfire and self.campfire.sceneCharacter then
      self.campfire.sceneCharacter:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnCampfireLeave)
    end
    self.campfire = campfire
  end
end

function CampingModule:OnCampfireLeave()
  self.campfire = nil
  Log.Error("\230\156\137\228\184\128\231\130\185\231\130\185\233\151\174\233\162\152\239\188\140\228\184\186\228\187\128\228\185\136NPC\228\188\154\229\156\168\229\175\185\232\175\157\231\187\147\230\157\159\229\137\141\229\176\177\232\162\171\229\185\178\230\142\137\228\186\134\227\128\130\227\128\130\227\128\130\232\191\153\228\184\141\229\164\170\229\144\136\231\144\134\239\188\140\228\189\134\229\166\130\230\158\156\230\152\175\229\156\168\228\189\141\233\157\162\228\186\146\232\174\191\239\188\140\233\130\163\228\185\159\230\173\163\229\184\184")
end

function CampingModule:GetCampfire()
  return self.campfire
end

function CampingModule:OnDestruct()
end

function CampingModule:GotoTime(TimeInSec, HintText, NpcId)
  local DialogueModule = _G.NRCModuleManager:GetModule("DialogueModule")
  local DialogueConf = {}
  DialogueConf.text = HintText
  DialogueConf.speed = 0
  local ExtraConf = {}
  ExtraConf.fade_in_speed = 8
  ExtraConf.autoCloseOff = true
  self.target_time = TimeInSec
  self.NpcId = NpcId
  DialogueModule:RegisterEvent(self, DialogueModuleEvent.DialogueBlackFadeInDone, self.JumpToTargetTime)
  DialogueModule:RegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished, self.TalkFinished)
  _G.NRCModuleManager:DoCmd(_G.CampingModuleCmd.ShowBlackScreen, DialogueConf, nil, ExtraConf)
end

function CampingModule:JumpToTargetTime()
  local DialogueModule = _G.NRCModuleManager:GetModule("DialogueModule")
  NRCModuleManager:DoCmd(EnvSystemModuleCmd.ChangeGameTime, self.target_time, false, self.NpcId)
  DialogueModule:UnRegisterEvent(self, DialogueModuleEvent.DialogueBlackFadeInDone)
end

function CampingModule:TalkFinished()
  local DialogueModule = _G.NRCModuleManager:GetModule("DialogueModule")
  DialogueModule:UnRegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished)
end

function CampingModule:SendUpgradeReq(UpgradeType, value)
  local req = _G.ProtoMessage:newZoneVisualItemUpgradeReq()
  req.visual_item_type = UpgradeType
  if UpgradeType == _G.Enum.VisualItem.VI_ROLE_HP_MAX then
    req.visual_item_upgrade_conf_id = value
  else
    req.visual_item_upgrade_conf_id = value
  end
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_VISUAL_ITEM_UPGRADE_REQ, req)
end

function CampingModule:RegPanel(name, path, layer, isSingleTouchPanel)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = "/Game/NewRoco/Modules/System/Camping/Res/" .. path
  registerData.panelLayer = layer
  registerData.isSingleTouchPanel = isSingleTouchPanel
  self:RegisterPanel(registerData)
end

function CampingModule:OnReconnect()
  if self.petModel and self.campfire then
    self:SetPetAndRocoPosition()
  end
end

function CampingModule:OnPetWarehouseChangePet(petBaseId, petGid, HidePet)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetCanSelectWareHouseItem, false)
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  local PetModelId = petbaseConf.model_conf
  local PetModelConf = _G.DataConfigManager:GetModelConf(PetModelId)
  self.campingPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  self.PetRequest = NRCResourceManager:LoadResAsync(self, PetModelConf.path, -1, 10, self.PetWarehouseGenerated, function(caller, resRequest, errMsg)
    Log.Error(errMsg, "\233\156\178\232\144\165Load Failed")
    caller.PetLoadFinished = true
  end, function(caller, resRequest, errMsg)
    Log.Error(errMsg, "\233\156\178\232\144\165Load Failed")
    caller.PetLoadFinished = true
  end)
  self.HideChangePet = HidePet
end

function CampingModule:PetWarehouseGenerated(resRequest, asset)
  local params = {}
  params.inBattle = true
  local petModel = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(asset, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, params)
  if petModel and UE4.UObject.IsValid(petModel) then
    local significanceComp = petModel.SignificanceComponent
    if significanceComp and UE4.UObject.IsValid(significanceComp) then
      significanceComp.bManageSignificance = false
    end
  end
  self.loadingPetModel = petModel
  if self.campingPetData then
    petModel:SetLoadPriority(PriorityEnum.Active_World_NPC_Mutation)
    PetMutationUtils.PrepareMutationAssets(petModel, self.campingPetData)
    petModel:InitOutSceneAsync(self, self.OnPetLoaded)
  else
    self:OnPetGenerateDone()
  end
  self:HideOrShowPets(not self.HideChangePet)
  self.HideChangePet = false
end

function CampingModule:GetPetModel()
  local sceneCharacter = self.campfire and self.campfire.sceneCharacter
  local holdingItemComponent = sceneCharacter and sceneCharacter.HoldingItemComponent
  if holdingItemComponent then
    return holdingItemComponent:GetItemByKey("Pet")
  end
  return nil
end

function CampingModule:OnPetLoaded(character)
  if not self.loadingPetModel then
    return
  end
  if not character then
    return
  end
  if self.loadingPetModel == character then
    self:OnPetGenerateDone()
  end
end

function CampingModule:OnPetGenerateDone()
  if self.campfire and self.campfire.sceneCharacter and self.campfire.sceneCharacter.HoldingItemComponent then
    self.campfire.sceneCharacter.HoldingItemComponent:DestroyItem("Pet")
    self.campfire.sceneCharacter.HoldingItemComponent:RegisterItem("Pet", self.loadingPetModel)
    self.loadingPetModel = nil
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetCanSelectWareHouseItem, true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CancelSelectWareHouseItem)
  local petModel = self:GetPetModel()
  if petModel then
    petModel:SetActorEnableCollision(false)
    self:SetPetAndRocoPosition()
  end
  PetMutationUtils.DoMutation(petModel, self.campingPetData)
end

function CampingModule:SetPosAndLockOnGround(Model, Position, Rotation)
  if self.campfire == nil then
    return
  end
  if not UE.UObject.IsValid(Model) then
    Log.Error("Model Is InValid")
    return
  end
  local MeshComponent = self.campfire:GetComponentByClass(UE4.USkeletalMeshComponent)
  local RootComponent = Model:K2_GetRootComponent()
  if RootComponent then
    RootComponent:K2_AttachToComponent(MeshComponent, "None", UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
    RootComponent:K2_SetRelativeLocation(Position, false, nil, false)
    RootComponent:K2_SetRelativeRotation(Rotation, false, nil, false)
  else
    Log.Error("RootComponent is nil")
  end
  self.campfire:SetActorEnableCollision(false)
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
  local ModelRotation = Model:K2_GetActorRotation()
  local ModelDirection = ModelRotation:ToVector() * 20
  local ModelFrontLocation = ModelLocation + ModelDirection
  local ModelFrontLineBegin = UE4.FVector(ModelFrontLocation.X, ModelFrontLocation.Y, ModelFrontLocation.Z + 500)
  local ModelFrontLineEnd = UE4.FVector(ModelFrontLocation.X, ModelFrontLocation.Y, ModelFrontLocation.Z - 500)
  Hits, Success = UE4.UKismetSystemLibrary.Abs_LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), ModelFrontLineBegin, ModelFrontLineEnd, TraceChannel, false, nil, 0, nil)
  if Success then
    for _, Result in tpairs(Hits) do
      ModelFrontLocation.X = Result.ImpactPoint.X
      ModelFrontLocation.Y = Result.ImpactPoint.Y
      ModelFrontLocation.Z = Result.ImpactPoint.Z + Model:GetHalfHeight()
      break
    end
  end
  local RealRotation = (ModelFrontLocation - ModelUnderLocation):ToRotator()
  Model:K2_SetActorRotation(RealRotation, false)
  local ModelUpVectorNormal = Model:GetActorUpVector()
  local ModelUpVector = Model:GetActorUpVector() * 500
  local ModelUpLineBegin = UE4.FVector(ModelFrontLocation.X + ModelUpVector.X, ModelFrontLocation.Y + ModelUpVector.Y, ModelFrontLocation.Z + ModelUpVector.Z)
  local ModelUpLineEnd = UE4.FVector(ModelFrontLocation.X - ModelUpVector.X, ModelFrontLocation.Y - ModelUpVector.Y, ModelFrontLocation.Z - ModelUpVector.Z)
  local ModelRealLocation = UE4.FVector((ModelFrontLocation.X + ModelUnderLocation.X) / 2, (ModelFrontLocation.Y + ModelUnderLocation.Y) / 2, (ModelFrontLocation.Z + ModelUnderLocation.Z) / 2)
  Hits, Success = UE4.UKismetSystemLibrary.Abs_LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), ModelUpLineBegin, ModelUpLineEnd, TraceChannel, false, nil, 0, nil)
  if Success then
    for _, Result in tpairs(Hits) do
      ModelRealLocation.X = Result.ImpactPoint.X + ModelUpVectorNormal.X * Model:GetHalfHeight()
      ModelRealLocation.Y = Result.ImpactPoint.Y + ModelUpVectorNormal.Y * Model:GetHalfHeight()
      ModelRealLocation.Z = Result.ImpactPoint.Z + ModelUpVectorNormal.Z * Model:GetHalfHeight()
      break
    end
  else
    ModelRealLocation.X = ModelRealLocation.X + ModelUpVectorNormal.X * Model:GetHalfHeight()
    ModelRealLocation.Y = ModelRealLocation.Y + ModelUpVectorNormal.Y * Model:GetHalfHeight()
    ModelRealLocation.Z = ModelRealLocation.Z + ModelUpVectorNormal.Z * Model:GetHalfHeight()
  end
  Model:Abs_K2_SetActorLocation_WithoutHit(ModelRealLocation)
  Model:K2_DetachFromActor(UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
  self.campfire:SetActorEnableCollision(true)
end

function CampingModule:SetPetAndRocoPosition()
  if not self.campfire then
    Log.Error("\230\156\137\229\183\168\229\164\167\231\154\132\233\151\174\233\162\152\239\188\140\228\184\186\228\187\128\228\185\136\230\178\161\230\156\137campfire\239\188\140\231\156\139\229\136\176\232\191\153\228\184\170\230\138\165\233\148\153\232\175\183\229\143\145\231\187\153marvywang")
    return
  end
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local petModel = self.campfire.sceneCharacter.HoldingItemComponent:GetItemByKey("Pet")
  if petModel and UE4.UObject.IsValid(petModel) then
    local PetPosition = UE4.FVector(211, 116, 0 + (petModel:GetHalfHeight() or 0))
    local PetRotation = UE4.FRotator(0, 100, 0)
    local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.campingPetData)
    UE.UNRCCharacterUtils.SetCharacterMeshScale(petModel, heightModelScale)
    self:SetPosAndLockOnGround(petModel, PetPosition, PetRotation)
  end
  local MageNPC1 = self.campfire.sceneCharacter.HoldingItemComponent:GetItemByKey("MageNPC1")
  if MageNPC1 and UE4.UObject.IsValid(MageNPC1) then
    local MageNPC1Position = UE4.FVector(70, -50, 0 + (MageNPC1:GetHalfHeight() or 0))
    local MageNPC1Rotation = UE4.FRotator(0, 60, 0)
    self:SetPosAndLockOnGround(MageNPC1, MageNPC1Position, MageNPC1Rotation)
  end
  local MageNPC2 = self.campfire.sceneCharacter.HoldingItemComponent:GetItemByKey("MageNPC2")
  if MageNPC2 and UE4.UObject.IsValid(MageNPC2) then
    local MageNPC2Position = UE4.FVector(-90, 50, 0 + (MageNPC2:GetHalfHeight() or 0))
    local MageNPC2Rotation = UE4.FRotator(0, 30, 0)
    self:SetPosAndLockOnGround(MageNPC2, MageNPC2Position, MageNPC2Rotation)
  end
  if localPlayer and localPlayer.viewObj then
    localPlayer.viewObj:SetActorEnableCollision(false)
    local movementComponent = localPlayer.viewObj.CharacterMovement
    movementComponent.OnlyUseYawRotation = false
    local RocoPosition = UE4.FVector(-80, 240, 0 + localPlayer.viewObj:GetHalfHeight())
    local RocoRotation = UE4.FRotator(0, 0, 0)
    self:SetPosAndLockOnGround(localPlayer.viewObj, RocoPosition, RocoRotation)
  end
end

function CampingModule:PlayFixCampingSkill(campfire, skillProxy)
  if self.campfire then
    return
  else
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local playerCameraManager = player:GetUEController().playerCameraManager
    Log.Debug("CampingModule:PlayFixCampingSkill")
    self:PlayCampingSkill(campfire, skillProxy)
  end
end

function CampingModule:PlayCampingSkill(campfire, skillProxy, caller, callback)
  self:OnPlayCampingSkill(campfire)
  local PetGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  if self.campingPetData then
    PetGid = self.campingPetData.gid
  else
    self.campingPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(PetGid)
  end
  if PetGid <= 0 then
    local petTeam = DataModelMgr.PlayerDataModel:GetPlayerBattlePetGid()
    PetGid = petTeam and petTeam.pet_infos and petTeam.pet_infos[1] and petTeam.pet_infos[1].pet_gid
  end
  local PetData, PetNpcId
  if PetGid then
    PetData = DataModelMgr.PlayerDataModel:GetPetDataByGid(PetGid)
    PetNpcId = 0
    if PetData then
      local PetBaseConfId = PetData.base_conf_id
      PetNpcId = _G.DataConfigManager:GetPetbaseConf(PetBaseConfId).npc_id
    else
      Log.Error("Pet Gid\230\139\191\228\184\141\229\136\176PetData???", PetGid)
      PetNpcId = 10012
    end
  else
    Log.Error("\228\184\186\228\187\128\228\185\136\232\131\140\229\140\133\233\135\140\228\184\128\229\143\170\231\178\190\231\129\181\233\131\189\230\178\161\230\156\137\229\176\177\229\143\175\228\187\165\229\146\140\230\158\175\230\158\157\228\186\164\228\186\146\229\149\138\239\188\140\232\191\153\229\144\136\231\144\134\229\144\151\239\188\159\232\191\153\228\184\141\229\144\136\231\144\134\239\188\129\239\188\129\239\188\129\239\188\129\233\184\173\229\144\137\229\144\137\239\188\140\229\135\186\229\135\187\239\188\129")
    PetData = nil
    PetNpcId = 10012
  end
  self.campingPetData = PetData
  local PerformConf = FakePerformConf(skillProxy:GetSkillPath())
  PerformConf:AddPerformer("Campfire", 0, false, UE4.EBattleStaticActorType.Player_1)
  PerformConf:AddPerformer("Player", 0, false, UE4.EBattleStaticActorType.Player_1_2)
  if self:LuluAlreadyAppeared() then
    PerformConf:AddPerformer("Lulu", 25400, false, UE4.EBattleStaticActorType.Pet_2_1)
  end
  PerformConf:AddPerformer("Pet", PetNpcId, false, UE4.EBattleStaticActorType.Pet_1_1)
  if #self.MageNpcIDList > 0 then
    local NpcID = self.MageNpcIDList[1]
    if NpcID and 0 ~= NpcID then
      PerformConf:AddPerformer("MageNPC1", NpcID, false, UE4.EBattleStaticActorType.Player_2_2)
    end
  end
  if #self.MageNpcIDList > 1 then
    local NpcID = self.MageNpcIDList[2]
    if NpcID and 0 ~= NpcID then
      PerformConf:AddPerformer("MageNPC2", NpcID, false, UE4.EBattleStaticActorType.Player_2_3)
    end
  end
  PerformConf:AddSkillBlackboardValue("camActor_0001", false)
  PerformConf:AddSkillBlackboardValue("camActor_0001_SA", false)
  local holdingItemComponent = self.campfire.sceneCharacter:EnsureComponent(HoldingItemComponent)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.viewObj:Event_StopTurn()
  holdingItemComponent:RegisterItem("Player", localPlayer.viewObj, 0, true)
  holdingItemComponent:RegisterItem("Campfire", campfire, 0, true)
  skillProxy:RegisterEventCallback("SetPosition", self, self.SetPetAndRocoPosition)
  _G.NRCModuleManager:DoCmd(_G.MiracleExchangeModuleCmd.HideMiraclesInRange, campfire)
  self.campfire.sceneCharacter:PlayShowById(PerformConf, caller, callback, skillProxy, self, self.OnSkillPreStart)
end

function CampingModule:OnSkillPreStart(skillObj)
  if self.campingPetData then
    if not self.campfire then
      Log.Error("\232\191\153\228\184\141\229\186\148\232\175\165\229\143\145\231\148\159\239\188\140\232\191\153\230\152\175\230\128\142\228\185\136\229\135\186\231\142\176\231\154\132\239\188\140\232\175\183\230\138\138\229\137\141\233\157\162\229\143\145\231\148\159\228\186\134\228\187\128\228\185\136\229\145\138\232\175\137marvynwang")
      return
    end
    local holdingItemComponent = self.campfire.sceneCharacter:EnsureComponent(HoldingItemComponent)
    local petModel = holdingItemComponent:GetItemByKey("Pet")
    if petModel and UE4.UObject.IsValid(petModel) then
      Log.Debug("CampingModule:OnSkillPreStart petModel", petModel)
      PetMutationUtils.PrepareMutationAssets(petModel, self.campingPetData)
      if petModel.resourceLoaded then
        self:TrySetPetModelMutation(petModel)
      end
      local petSceneCharacter = petModel.sceneCharacter
      if petSceneCharacter then
        petSceneCharacter:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnPetLoadedForSkillPreStart)
        local petAIComponent = petSceneCharacter.AIComponent
        if petAIComponent then
          petAIComponent:ForceLockForReason(true, false, AIDefines.LockReason.DIALOGUE)
        end
      else
        Log.Debug("CampingModule:OnSkillPreStart petModel.sceneCharacter is nil")
      end
    else
      Log.Warning("petModel from holdingItemComponent is nil")
    end
  end
  skillObj.Blackboard:SetValueAsInt("lulu", self:LuluAlreadyAppeared() and 1 or 0)
end

function CampingModule:OnPetLoadedForSkillPreStart(viewObj)
  Log.Debug("CampingModule:OnPetLoadedForSkillPreStart", viewObj)
  if viewObj then
    if viewObj.sceneCharacter then
      viewObj.sceneCharacter:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnPetLoadedForSkillPreStart)
    end
    self:TrySetPetModelMutation(viewObj)
  end
end

function CampingModule:TrySetPetModelMutation(petModel)
  if not self.campingPetData then
    return
  end
  Log.Debug("CampingModule:TrySetPetModelMutation", petModel, self.campingPetData.gid, self.campingPetData.name, self.campingPetData.mutation_type, self.campingPetData.glass_info)
  local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.campingPetData)
  UE.UNRCCharacterUtils.SetCharacterMeshScale(petModel, heightModelScale)
  PetMutationUtils.DoMutation(petModel, self.campingPetData)
end

function CampingModule:OnPlayCampingSkill(campfire)
  if campfire then
    self:SetCampfire(campfire)
  end
  if self.campfire == nil then
    Log.Error("CampingModule:PlayCampingSkillPure Failed, we do not have campfire")
    return
  end
  local CampFirePos = campfire:Abs_K2_GetActorLocation()
  local CampFireVec = UE4.FVector(CampFirePos.X, CampFirePos.Y, CampFirePos.Z)
  local normalleaf_hidden_distance = DataConfigManager:GetMapGlobalConfig("normalleaf_hidden_distance").num
  UE4.UNRCStatics.Abs_SetBattleGrassVisibleAndDist(CampFireVec, 1, 200, normalleaf_hidden_distance)
  _G.NRCEventCenter:DispatchEvent(_G.CampingModuleEvent.ON_ENTER_CAMPING, self.campfire)
end

function CampingModule:GetCampingPet()
  return self.petModel
end

function CampingModule:CloseUpdate()
  self.FruitCountDownTime = 0
end

function CampingModule:GetCamera(Event, Skill)
  if not Skill then
    return
  end
  if not self.campfire then
    return
  end
  self.campfire.sceneCharacter.HoldingItemComponent:RegisterItem("camActor_0001", Skill.Blackboard:GetValueAsObject("camActor_0001"))
  self.campfire.sceneCharacter.HoldingItemComponent:RegisterItem("camActor_0001_SA", Skill.Blackboard:GetValueAsObject("camActor_0001_SA"))
  Skill.Blackboard:RemoveObjectValue("camActor_0001")
  Skill.Blackboard:RemoveObjectValue("camActor_0001_SA")
end

function CampingModule:SetOpenTipPetWarehouse(bOpen)
  local skillPath
  if not self.campfire then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetWarehouseTipBtnEnable, true)
    return
  end
  if bOpen then
    skillPath = "/Game/ArtRes/Effects/G6Skill/Luying/Camping_Pet_StoreroonUp_Start.Camping_Pet_StoreroonUp_Start"
  else
    skillPath = "/Game/ArtRes/Effects/G6Skill/Luying/Camping_Pet_StoreroonUp_End.Camping_Pet_StoreroonUp_End"
  end
  local SkillProxy = RocoSkillProxy.Create(skillPath, self.campfire.RocoSkill)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetWarehouseTipBtnEnable, false)
  local FakePerform = FakePerformConf(skillPath)
  FakePerform:AddSkillBlackboardValue("camActor_0001", false)
  FakePerform:AddSkillBlackboardValue("camActor_0001_SA", false)
  self.campfire.sceneCharacter:PlayShowById(FakePerform, self, self.OnStoreroonUpSkillEnd, SkillProxy)
end

function CampingModule:OnStoreroonUpSkillEnd(bStart)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetWarehouseTipBtnEnable, true)
end

function CampingModule:SetIsCultivatePet(_IsCultivatePet)
  self.IsCultivatePet = _IsCultivatePet
end

function CampingModule:GetIsCultivatePet()
  return self.IsCultivatePet
end

function CampingModule:ClearPetAndLulu()
  if not self.campfire then
    return
  end
  if self.campfire.sceneCharacter.HoldingItemComponent then
    self.campfire.sceneCharacter.HoldingItemComponent:DestroyItem("Lulu")
    self.campfire.sceneCharacter.HoldingItemComponent:DestroyItem("Pet")
    self:ClearMageNpc()
  end
end

function CampingModule:ClearMageNpc()
  if self.campfire.sceneCharacter.HoldingItemComponent then
    self.campfire.sceneCharacter.HoldingItemComponent:DestroyItem("MageNPC1")
    self.campfire.sceneCharacter.HoldingItemComponent:DestroyItem("MageNPC2")
  end
end

function CampingModule:ClearCampingData()
  self:ClearPetAndLulu()
  self:SetCampfire(nil)
  self.skillObj = nil
  self.MageNpcIDList = {}
  self.campingPetData = nil
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function CampingModule:ClearCampingCamera(Skill)
  self:GetCamera("", Skill)
  local normalleaf_hidden_distance = DataConfigManager:GetMapGlobalConfig("normalleaf_hidden_distance").num
  UE4.UNRCStatics.Abs_SetBattleGrassVisibleAndDist(_G.FVectorZero, 0, 200, normalleaf_hidden_distance)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.campfire.sceneCharacter.HoldingItemComponent:DestroyItem("camActor_0001")
  self.campfire.sceneCharacter.HoldingItemComponent:DestroyItem("camActor_0001_SA")
  localPlayer.viewObj:SetActorEnableCollision(true)
  local movementComponent = localPlayer.viewObj.CharacterMovement
  movementComponent.OnlyUseYawRotation = true
  _G.NRCModuleManager:DoCmd(_G.MiracleExchangeModuleCmd.ReShowMiraclesInRange)
end

function CampingModule:JustClearCamera(skill)
  self:GetCamera("", skill)
  local normalleaf_hidden_distance = DataConfigManager:GetMapGlobalConfig("normalleaf_hidden_distance").num
  UE4.UNRCStatics.Abs_SetBattleGrassVisibleAndDist(_G.FVectorZero, 0, 200, normalleaf_hidden_distance)
  if self.CameraActor then
    self.CameraActor:K2_DestroyActor()
  end
  if self.CameraActorMesh then
    self.CameraActorMesh:K2_DestroyActor()
  end
  self.CameraActor = nil
  self.CameraActorMesh = nil
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.viewObj:SetActorEnableCollision(true)
  local movementComponent = localPlayer.viewObj.CharacterMovement
  movementComponent.OnlyUseYawRotation = true
end

function CampingModule:ShowBlackScreen(DialogueConf, prev, ExtraConf)
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.ShowDialogueBlack, DialogueConf, prev, ExtraConf)
end

function CampingModule:LuluAlreadyAppeared()
  if _G.DataModelMgr.PlayerDataModel.playerInfo.story_flag_info and _G.DataModelMgr.PlayerDataModel.playerInfo.story_flag_info.story_flags then
    for _, item in ipairs(_G.DataModelMgr.PlayerDataModel.playerInfo.story_flag_info.story_flags) do
      if 1014 == item then
        return true
      end
    end
  end
  return false
end

function CampingModule:HidePlayerAndPet()
  _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.RecycleAllThrowPets)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.viewObj:K2_GetRootComponent():SetVisibility(false, true)
  if self.petModel then
    self.petModel:K2_GetRootComponent():SetVisibility(false, true)
  end
end

function CampingModule:HideOrShowPets(_bShow)
  local petModel = self:GetPetModel()
  if petModel and UE4.UObject.IsValid(petModel) then
    petModel:K2_GetRootComponent():SetVisibility(_bShow, true)
  end
end

function CampingModule:ShowPlayer()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.viewObj:K2_GetRootComponent():SetVisibility(true, true)
  if self.petModel then
    self.petModel:K2_GetRootComponent():SetVisibility(true, true)
  end
end

function CampingModule:SetNpcModelVisible(bIsVisible)
  if not self.campfire then
    return
  end
  if not self.campfire.sceneCharacter then
    return
  end
  if not self.campfire.sceneCharacter.HoldingItemComponent then
    return
  end
  local MageNPC1 = self.campfire.sceneCharacter.HoldingItemComponent:GetItemByKey("MageNPC1")
  if MageNPC1 and UE4.UObject.IsValid(MageNPC1) then
    local Root = MageNPC1:K2_GetRootComponent()
    if Root then
      Root:SetVisibility(bIsVisible, true)
    end
  end
  local MageNPC2 = self.campfire.sceneCharacter.HoldingItemComponent:GetItemByKey("MageNPC2")
  if MageNPC2 and UE4.UObject.IsValid(MageNPC2) then
    local Root = MageNPC2:K2_GetRootComponent()
    if Root then
      Root:SetVisibility(bIsVisible, true)
    end
  end
end

function CampingModule:OnPlayerDataUpdate()
  self:DispatchEvent(CampingModuleEvent.UpdatePanelInfo)
end

function CampingModule:ShowNpcInCamp(NpcList)
  self.MageNpcIDList = NpcList
end

function CampingModule:RecordReportPetInfo(firstPetName)
  self.firstPetName = firstPetName
end

function CampingModule:ShowReportPetInfo()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ShowSubmitFinishTips)
  self.firstPetName = nil
end

return CampingModule
