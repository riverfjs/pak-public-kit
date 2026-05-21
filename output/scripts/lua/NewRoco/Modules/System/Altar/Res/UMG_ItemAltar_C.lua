local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local UMG_ItemAltar_C = _G.NRCPanelBase:Extend("UMG_ItemAltar_C")

function UMG_ItemAltar_C:OnConstruct()
  Log.Debug("UMG_ItemAltar_C:OnConstruct")
  self.BtnConfirm:SetBtnText(LuaText.umg_itemaltar_1)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCancel)
  self:AddButtonListener(self.BtnConfirm.btnLevelUp, self.OnClickConfirm)
  _G.NRCEventCenter:RegisterEvent("UMG_ItemAltar_C", self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
end

function UMG_ItemAltar_C:OnActive(action)
  Log.Debug("UMG_ItemAltar_C:OnActive")
  local optionConf
  local items = {}
  self:PlayAnimation(self.In)
  if action then
    self.optionId = action.Owner.config.id
    self.npcId = action.Owner.owner.serverData.base.actor_id
    self.satisfy = true
    self.action = action
    local paramStr = action.Config.action_param1
    local params = paramStr:split(";")
    Log.Debug(self.optionId .. " NPC id " .. self.npcId)
    self.altarName:SetText(LuaText.umg_itemaltar_2)
    for i = 1, #params, 2 do
      local item = {}
      item.id = tonumber(params[i])
      local bagItemData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, item.id)
      if bagItemData then
        item.cur = bagItemData.num
        if bagItemData.type == _G.ProtoEnum.BagItemType.BI_PET_EGG then
          local backpackEggList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()
          for k = 1, #backpackEggList do
            local eggInfo = backpackEggList[k]
            if eggInfo.gid == bagItemData.gid then
              item.cur = 0
              break
            end
          end
        end
      else
        item.cur = 0
      end
      item.need = tonumber(params[i + 1])
      if item.cur < item.need then
        self.satisfy = false
      end
      table.insert(items, item)
    end
  else
    Log.Warning("UMG_PetAltar_C:OnActive option\228\184\186nil\239\188\140\229\166\130\230\158\156\228\184\141\230\152\175\233\128\154\232\191\135debug\233\157\162\230\157\191\230\137\147\229\188\128\232\175\183\230\163\128\230\159\165")
    local test = {}
    test.id = 100002
    test.cur = 0
    test.need = 10
    table.insert(items, test)
  end
  local itemNum = #items
  if itemNum > 0 then
    if itemNum < 3 then
    end
    self.NRCGridViewList:InitGridView(items)
  else
    Log.Debug("no items")
  end
end

function UMG_ItemAltar_C:OnDialogueEnded()
  self:DoClose()
end

function UMG_ItemAltar_C:OnClickCancel()
  Log.Debug("UMG_ItemAltar_C:OnClickCancel")
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ItemAltar_C:OnClickCancel")
  self:PlayAnimation(self.Out)
  if self.action and self.action.Finish then
    self.action:Finish(false, nil)
    self.action = nil
  end
end

function UMG_ItemAltar_C:OnClickConfirm()
  Log.Debug("UMG_ItemAltar_C:OnClickConfirm")
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ItemAltar_C:OnClickConfirm")
  if self.satisfy then
    self:PlayAnimation(self.Out)
    if self.action then
      self.action:GiveFinish()
      self.action = nil
    end
  else
    local tipTxt = _G.DataConfigManager:GetLocalizationConf("Error_Code_2055")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipTxt.msg)
  end
end

function UMG_ItemAltar_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    _G.NRCModuleManager:DoCmd(AltarModuleCmd.CloseItemAltarPanel)
  end
end

function UMG_ItemAltar_C:OnDestruct()
  self.action = nil
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  self:RemoveButtonListener(self.CloseBtn.btnClose)
  self:RemoveButtonListener(self.BtnConfirm.btnLevelUp)
end

function UMG_ItemAltar_C:OnDeactive()
  self.action = nil
end

return UMG_ItemAltar_C
