local UMG_AbstractPanel = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractPanel")
local UMG_DataView_C = UMG_AbstractPanel:Extend("UMG_DataView_C")

function UMG_DataView_C:OnConstruct()
  UMG_AbstractPanel.OnConstruct(self)
  self.EnableDrag = true
  self.IsConstrainToViewport = false
  if self.TitleBar then
  end
  self.DataList:InitList({})
end

function UMG_DataView_C:OnAddEventListener()
  self:AddButtonListener(self.OpenRecord, self.OnOpenRecord)
  self:AddButtonListener(self.SaveRecord, self.OnSaveRecord)
  self:AddButtonListener(self.CloseRecord, self.OnCloseRecord)
  self:AddButtonListener(self.AddRecord, self.OnAddRecord)
  self:AddButtonListener(self.RemoveRecord, self.OnRemoveRecord)
  self:AddButtonListener(self.CreateNPC, self.OnCreateNPC)
  self:AddButtonListener(self.Close, self.OnCloseDataView)
end

function UMG_DataView_C:OnRefreshData(Data)
  local TypeName = Data and Data.TypeName
  local PrimaryKey = Data and Data.PrimaryKey
  if type(TypeName) == "string" then
    self.TypeName:SetText(TypeName)
  end
  if type(PrimaryKey) == "number" then
    self.PrimaryKey:SetValue(PrimaryKey)
  end
  self:OnOpenRecord()
end

function UMG_DataView_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.OpenRecord, self.OnOpenRecord)
  self:RemoveButtonListener(self.SaveRecord, self.OnSaveRecord)
  self:RemoveButtonListener(self.CloseRecord, self.OnCloseRecord)
  self:RemoveButtonListener(self.AddRecord, self.OnAddRecord)
  self:RemoveButtonListener(self.RemoveRecord, self.OnRemoveRecord)
  self:RemoveButtonListener(self.CreateNPC, self.OnCreateNPC)
  self:RemoveButtonListener(self.Close, self.OnCloseDataView)
end

function UMG_DataView_C:OnOpenRecord()
  local TypeName = self.TypeName:GetText()
  local PrimaryKey = math.floor(self.PrimaryKey:GetValue())
  NRCModuleManager:DoCmd(PGCModuleCmd.LoadRecord, TypeName, PrimaryKey)
end

function UMG_DataView_C:OnSaveRecord()
  local TypeName = self.TypeName:GetText()
  local PrimaryKey = math.floor(self.PrimaryKey:GetValue())
  NRCModuleManager:DoCmd(PGCModuleCmd.SaveRecord, TypeName, PrimaryKey)
end

function UMG_DataView_C:OnCloseRecord()
  local TypeName = self.TypeName:GetText()
  local PrimaryKey = math.floor(self.PrimaryKey:GetValue())
  NRCModuleManager:DoCmd(PGCModuleCmd.CloseRecord, TypeName, PrimaryKey)
end

function UMG_DataView_C:OnAddRecord()
  local TypeName = self.TypeName:GetText()
  NRCModuleManager:DoCmd(PGCModuleCmd.AddRecord, TypeName)
end

function UMG_DataView_C:OnRemoveRecord()
  local TypeName = self.TypeName:GetText()
  local PrimaryKey = math.floor(self.PrimaryKey:GetValue())
  NRCModuleManager:DoCmd(PGCModuleCmd.RemoveRecord, TypeName, PrimaryKey)
end

function UMG_DataView_C:OnCreateNPC()
  local TypeName = self.TypeName:GetText()
  if "NPC_CONF" == TypeName then
    local PrimaryKey = math.floor(self.PrimaryKey:GetValue())
    local LocalPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if LocalPlayer then
      local PlayerPosition = LocalPlayer:GetActorLocation()
      NRCModuleManager:DoCmd(PGCModuleCmd.CreateNPC, PrimaryKey, PlayerPosition)
    end
  end
end

function UMG_DataView_C:OnCloseDataView()
  NRCModuleManager:DoCmd(_G.PGCModuleCmd.CloseDataView)
end

return UMG_DataView_C
