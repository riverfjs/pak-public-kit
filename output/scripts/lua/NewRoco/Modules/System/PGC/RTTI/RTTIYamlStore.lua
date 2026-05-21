local RTTIBase = require("NewRoco.Modules.System.PGC.RTTI.RTTIBase")
local RTTICore = require("NewRoco.Modules.System.PGC.RTTI.RTTICore")
local RTTISettings = require("NewRoco.Modules.System.PGC.RTTI.RTTISettings")
local RTTIYamlStore = {}

local function FormatYamlScalar(Value)
  local T = type(Value)
  if nil == Value then
    return "''"
  end
  if "boolean" == T then
    return Value and "true" or "false"
  end
  if "number" == T then
    return tostring(Value)
  end
  if "string" ~= T then
    return "''"
  end
  if "" == Value then
    return "''"
  end
  if string.find(Value, "\n", 1, true) then
    local Esc = Value:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\r", ""):gsub("\n", "\\n")
    return "\"" .. Esc .. "\""
  end
  local HasLeadingOrTrailingSpace = nil ~= Value:match("^%s") or nil ~= Value:match("%s$")
  local NeedQuote = HasLeadingOrTrailingSpace or Value:find(":", 1, true) or Value:find("#", 1, true) or Value:find("{", 1, true) or Value:find("}", 1, true) or Value:find("[", 1, true) or Value:find("]", 1, true)
  if not NeedQuote then
    local Lower = string.lower(Value)
    if "true" == Lower or "false" == Lower or "null" == Lower or "nil" == Lower then
      NeedQuote = true
    elseif nil ~= tonumber(Value) then
      NeedQuote = true
    end
  end
  if not NeedQuote then
    return Value
  end
  return "'" .. Value:gsub("'", "''") .. "'"
end

local EmitYamlDataByTypeInfo = function(TypeName, Data, Indent)
  local TypeInfo = RTTICore:GetTypeInfo(TypeName)
  if not TypeInfo then
    return {}
  end
  local Lines = {}
  Data = Data or {}
  for _, FieldName in ipairs(TypeInfo.FieldOrder) do
    local FieldInfo = TypeInfo.FieldInfos[FieldName]
    if FieldInfo then
      local FieldType = FieldInfo.Type
      local FieldValue = Data[FieldName]
      if FieldType == RTTIBase.FieldType.ENUM then
        local EnumName = FieldInfo.Constraint.Enum.EnumName
        table.insert(Lines, Indent .. FieldName .. ": " .. RTTICore:GetEnumFieldName(EnumName, FieldValue))
      elseif RTTIBase.IsPrimitiveType(FieldType) then
        table.insert(Lines, Indent .. FieldName .. ": " .. FormatYamlScalar(FieldValue))
      elseif FieldType == RTTIBase.FieldType.STRUCT then
        local StructTypeName = FieldInfo.Constraint.Type and FieldInfo.Constraint.Type.TypeName
        if StructTypeName then
          local SubLines = EmitYamlDataByTypeInfo(StructTypeName, FieldValue, Indent .. "  ")
          if 0 == #SubLines then
            table.insert(Lines, Indent .. FieldName .. ": {}")
          else
            table.insert(Lines, Indent .. FieldName .. ":")
            for _, SubLine in ipairs(SubLines) do
              Lines[#Lines + 1] = SubLine
            end
          end
        else
        end
      else
        if FieldType == RTTIBase.FieldType.ARRAY then
          if 0 == #FieldValue then
            table.insert(Lines, Indent .. FieldName .. ": []")
          else
            table.insert(Lines, Indent .. FieldName .. ":")
            local ElementType = FieldInfo.Constraint.Array and FieldInfo.Constraint.Array.ElementType
            local IsTypeName = false
            if ElementType == RTTIBase.FieldType.STRUCT then
              ElementType = FieldInfo.Constraint.Type and FieldInfo.Constraint.Type.TypeName
              IsTypeName = true
            end
            if ElementType then
              for _, ElementValue in ipairs(FieldValue) do
                if IsTypeName then
                  local SubLines = EmitYamlDataByTypeInfo(ElementType, ElementValue, Indent .. "  ")
                  if 0 == #SubLines then
                    table.insert(Lines, Indent .. "- {}")
                  else
                    local Prefix = Indent .. "  "
                    local First = SubLines[1]
                    local Rest = First
                    if type(First) == "string" and First:sub(1, #Prefix) == Prefix then
                      Rest = First:sub(#Prefix + 1)
                    end
                    table.insert(Lines, Indent .. "- " .. Rest)
                    for i = 2, #SubLines do
                      Lines[#Lines + 1] = SubLines[i]
                    end
                  end
                elseif ElementType == RTTIBase.FieldType.ENUM then
                  local EnumName = FieldInfo.Constraint.Enum.EnumName
                  table.insert(Lines, Indent .. "- " .. RTTICore:GetEnumFieldName(EnumName, ElementValue))
                else
                  if RTTIBase.IsPrimitiveType(ElementType) then
                    table.insert(Lines, Indent .. "- " .. FormatYamlScalar(ElementValue))
                  else
                  end
                end
              end
            else
            end
          end
        else
        end
      end
    else
    end
  end
  return Lines
end

local function ReadTextFile(Path)
  local File = io.open(Path, "r")
  if not File then
    return nil
  end
  local Content = File:read("*a")
  File:close()
  return Content
end

local function WriteTextFile(Path, Content)
  local File = io.open(Path, "w")
  if not File then
    return false
  end
  File:write(Content)
  File:close()
  return true
end

local function ParseYamlScalar(Text)
  local S = (Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if "''" == S then
    return ""
  end
  if "true" == S then
    return true
  end
  if "false" == S then
    return false
  end
  if S:sub(1, 1) == "'" and S:sub(-1) == "'" then
    local Inner = S:sub(2, -2)
    return (Inner:gsub("''", "'"))
  end
  if S:sub(1, 1) == "\"" and S:sub(-1) == "\"" then
    local Inner = S:sub(2, -2)
    Inner = Inner:gsub("\\\"", "\""):gsub("\\\\", "\\"):gsub("\\n", "\n")
    return Inner
  end
  local N = tonumber(S)
  if nil ~= N then
    return N
  end
  return S
end

local function SplitLines(Content)
  local Lines = {}
  Content = Content or ""
  Content = Content:gsub("\r\n", "\n"):gsub("\r", "\n")
  for Line in (Content .. "\n"):gmatch("(.-)\n") do
    table.insert(Lines, Line)
  end
  return Lines
end

local function GetRelativeYamlPath(TypeName)
  local TypeInfo = RTTICore:GetTypeInfo(TypeName)
  return TypeInfo and TypeInfo.Metadata.RelativeYamlPath
end

local function FindBodyIndex(Lines)
  for i, Line in ipairs(Lines) do
    if "body:" == Line then
      return i
    end
  end
  return nil
end

local function FindRowEnd(Lines, StartIndex)
  local RowEnd = #Lines
  local j = StartIndex + 1
  while j <= #Lines do
    if "- !Row" == Lines[j] then
      RowEnd = j - 1
      break
    end
    j = j + 1
  end
  return RowEnd
end

local function ReadPrimaryKeyFromRow(Lines, StartIndex, EndIndex, PrimaryKeyName)
  local Prefix = "    " .. PrimaryKeyName .. ":"
  for i = StartIndex, EndIndex do
    local Line = Lines[i]
    if Line and Line:sub(1, #Prefix) == Prefix then
      local Raw = Line:sub(#Prefix + 1)
      return ParseYamlScalar(Raw)
    end
  end
  return nil
end

local function FindDataRangeInRow(Lines, StartIndex, EndIndex)
  local DataStart
  for i = StartIndex, EndIndex do
    if "  data:" == Lines[i] then
      DataStart = i
      break
    end
  end
  if not DataStart then
    return nil, nil
  end
  local DataEnd = EndIndex + 1
  for i = DataStart + 1, EndIndex do
    local Line = Lines[i]
    if "" ~= Line and Line:sub(1, 2) == "  " and Line:sub(1, 4) ~= "    " then
      DataEnd = i
      break
    end
  end
  return DataStart, DataEnd
end

local function UpsertYamlRow(Content, PrimaryKeyName, PrimaryKeyValue, DataLines)
  local Lines = SplitLines(Content)
  local BodyIndex = FindBodyIndex(Lines)
  if not BodyIndex then
    return nil, false
  end
  local UserName = RTTISettings:Get("User.Name", "")
  if not RTTIBase.IsValidStringValue(UserName) then
    UserName = ""
  end
  local CreatorPrefix = "  creator:"
  local LastAuthorPrefix = "  last_author:"
  local CommentsPrefix = "  comments:"
  
  local function EnsureAuthorLines(RowLines, RowStart, RowEnd, IsModify)
    local function FindIndices()
      local CreatorIndex, LastAuthorIndex, CommentsIndex
      
      for idx = RowStart, RowEnd do
        local Line = RowLines[idx]
        if Line then
          if Line:sub(1, #CreatorPrefix) == CreatorPrefix then
            CreatorIndex = idx
          elseif Line:sub(1, #LastAuthorPrefix) == LastAuthorPrefix then
            LastAuthorIndex = idx
          elseif Line:sub(1, #CommentsPrefix) == CommentsPrefix then
            CommentsIndex = idx
          end
        end
      end
      return CreatorIndex, LastAuthorIndex, CommentsIndex
    end
    
    do
      local CreatorIndex, _, CommentsIndex = FindIndices()
      local NeedSetCreator = true
      if CreatorIndex then
        if IsModify then
          local Raw = RowLines[CreatorIndex]:sub(#CreatorPrefix + 1)
          local Existing = tostring(ParseYamlScalar(Raw) or "")
          if RTTIBase.IsValidStringValue(Existing) then
            NeedSetCreator = false
          end
        end
        if NeedSetCreator then
          RowLines[CreatorIndex] = "  creator: " .. FormatYamlScalar(UserName)
        end
      else
        local InsertAt = CommentsIndex or RowEnd + 1
        table.insert(RowLines, InsertAt, "  creator: " .. FormatYamlScalar(UserName))
        RowEnd = RowEnd + 1
      end
    end
    do
      local _, LastAuthorIndex, CommentsIndex = FindIndices()
      if LastAuthorIndex then
        RowLines[LastAuthorIndex] = "  last_author: " .. FormatYamlScalar(UserName)
      else
        local InsertAt = CommentsIndex or RowEnd + 1
        table.insert(RowLines, InsertAt, "  last_author: " .. FormatYamlScalar(UserName))
        RowEnd = RowEnd + 1
      end
    end
    return RowEnd
  end
  
  local i = BodyIndex + 1
  while i <= #Lines do
    if "- !Row" == Lines[i] then
      local RowStart = i
      local RowEnd = FindRowEnd(Lines, RowStart)
      local ExistingPk = ReadPrimaryKeyFromRow(Lines, RowStart, RowEnd, PrimaryKeyName)
      if tostring(ExistingPk) == tostring(PrimaryKeyValue) then
        local DataStart, DataEnd = FindDataRangeInRow(Lines, RowStart, RowEnd)
        if not DataStart then
          return nil, true
        end
        local OldDataCount = DataEnd - DataStart - 1
        local NewLines = {}
        for idx = 1, DataStart do
          NewLines[#NewLines + 1] = Lines[idx]
        end
        for _, DL in ipairs(DataLines) do
          NewLines[#NewLines + 1] = DL
        end
        for idx = DataEnd, #Lines do
          NewLines[#NewLines + 1] = Lines[idx]
        end
        local Delta = #DataLines - OldDataCount
        local NewRowEnd = RowEnd + Delta
        NewRowEnd = EnsureAuthorLines(NewLines, RowStart, NewRowEnd, true)
        return table.concat(NewLines, "\n"), true
      end
      i = RowEnd + 1
    else
      i = i + 1
    end
  end
  local Tail = {}
  for _, Line in ipairs(Lines) do
    Tail[#Tail + 1] = Line
  end
  Tail[#Tail + 1] = "- !Row"
  Tail[#Tail + 1] = "  data:"
  for _, DL in ipairs(DataLines) do
    Tail[#Tail + 1] = DL
  end
  Tail[#Tail + 1] = "  creator: " .. FormatYamlScalar(UserName)
  Tail[#Tail + 1] = "  last_author: " .. FormatYamlScalar(UserName)
  Tail[#Tail + 1] = "  comments: {}"
  return table.concat(Tail, "\n"), false
end

local function DeleteYamlRow(Content, PrimaryKeyName, PrimaryKeyValue)
  local Lines = SplitLines(Content)
  local BodyIndex = FindBodyIndex(Lines)
  if not BodyIndex then
    return nil, false
  end
  local i = BodyIndex + 1
  while i <= #Lines do
    if "- !Row" == Lines[i] then
      local RowStart = i
      local RowEnd = FindRowEnd(Lines, RowStart)
      local ExistingPk = ReadPrimaryKeyFromRow(Lines, RowStart, RowEnd, PrimaryKeyName)
      if tostring(ExistingPk) == tostring(PrimaryKeyValue) then
        local NewLines = {}
        for idx = 1, RowStart - 1 do
          NewLines[#NewLines + 1] = Lines[idx]
        end
        for idx = RowEnd + 1, #Lines do
          NewLines[#NewLines + 1] = Lines[idx]
        end
        return table.concat(NewLines, "\n"), true
      end
      i = RowEnd + 1
    else
      i = i + 1
    end
  end
  return table.concat(Lines, "\n"), false
end

function RTTIYamlStore.ResolveYamlFilePath(TypeName, ForceCreate)
  local ProjectDir = UE and UE.UBlueprintPathsLibrary and UE.UBlueprintPathsLibrary.ProjectDir and UE.UBlueprintPathsLibrary.ProjectDir() or ""
  if not RTTIBase.IsValidStringValue(ProjectDir) then
    return nil
  end
  local YamlRootDir = ProjectDir .. RTTISettings:Get("Reflection.YamlRootDir", "DataConfig")
  if "" ~= YamlRootDir and not YamlRootDir:match("[/\\]$") then
    YamlRootDir = YamlRootDir .. "/"
  end
  local YamlPath
  local RelativeYamlPath = GetRelativeYamlPath(TypeName)
  if RelativeYamlPath and "" ~= RelativeYamlPath then
    YamlPath = string.format("%s%s", YamlRootDir, RelativeYamlPath)
  else
    YamlPath = string.format("%s%s.yaml", YamlRootDir, TypeName)
  end
  local YamlFile = io.open(YamlPath, "r")
  if YamlFile then
    YamlFile:close()
    return YamlPath
  elseif ForceCreate then
    local InitContent = table.concat({
      "!Sheet",
      string.format("name: %s", tostring(TypeName or "")),
      "index: 0",
      "excel_name: ''",
      "version_id: 1",
      "headers: []",
      "comments_index: []",
      "body:"
    }, "\n")
    if WriteTextFile(YamlPath, InitContent) then
      return YamlPath
    end
  end
  return nil
end

function RTTIYamlStore:UpsertRecord(TypeName, Data, ForceCreate)
  local PrimaryKeyName, PrimaryKeyValue = RTTICore:GetPrimaryKeyValue(TypeName, Data)
  if not PrimaryKeyName then
    return false
  end
  if nil == PrimaryKeyValue then
    return false
  end
  local YamlPath = self.ResolveYamlFilePath(TypeName, ForceCreate)
  if not YamlPath then
    return false
  end
  local Content = ReadTextFile(YamlPath)
  if not Content then
    return false
  end
  local DataLines = EmitYamlDataByTypeInfo(TypeName, Data, "    ")
  local NewContent = UpsertYamlRow(Content, PrimaryKeyName, PrimaryKeyValue, DataLines)
  if not NewContent then
    return false
  end
  return WriteTextFile(YamlPath, NewContent)
end

function RTTIYamlStore:InsertRecord(TypeName, Data, ForceCreate)
  local PrimaryKeyName, PrimaryKeyValue = RTTICore:GetPrimaryKeyValue(TypeName, Data)
  if not PrimaryKeyName then
    return false
  end
  if nil == PrimaryKeyValue then
    return false
  end
  local YamlPath = self.ResolveYamlFilePath(TypeName, ForceCreate)
  if not YamlPath then
    return false
  end
  local Content = ReadTextFile(YamlPath)
  if not Content then
    return false
  end
  local DataLines = EmitYamlDataByTypeInfo(TypeName, Data, "    ")
  local NewContent, Existed = UpsertYamlRow(Content, PrimaryKeyName, PrimaryKeyValue, DataLines)
  if not NewContent or Existed then
    return false
  end
  return WriteTextFile(YamlPath, NewContent)
end

function RTTIYamlStore:ModifyRecord(TypeName, Data, ForceCreate)
  local PrimaryKeyName, PrimaryKeyValue = RTTICore:GetPrimaryKeyValue(TypeName, Data)
  if not PrimaryKeyName then
    return false
  end
  if nil == PrimaryKeyValue then
    return false
  end
  local YamlPath = self.ResolveYamlFilePath(TypeName, ForceCreate)
  if not YamlPath then
    return false
  end
  local Content = ReadTextFile(YamlPath)
  if not Content then
    return false
  end
  local DataLines = EmitYamlDataByTypeInfo(TypeName, Data, "    ")
  local NewContent, Existed = UpsertYamlRow(Content, PrimaryKeyName, PrimaryKeyValue, DataLines)
  if not NewContent or not Existed then
    return false
  end
  return WriteTextFile(YamlPath, NewContent)
end

function RTTIYamlStore:DeleteRecord(TypeName, PrimaryKeyValue)
  local PrimaryKeyName = RTTICore:GetPrimaryKeyName(TypeName)
  if not PrimaryKeyName or "" == PrimaryKeyName then
    return false
  end
  if nil == PrimaryKeyValue then
    return false
  end
  local YamlPath = self.ResolveYamlFilePath(TypeName, false)
  if not YamlPath then
    return false
  end
  local Content = ReadTextFile(YamlPath)
  if not Content then
    return false
  end
  local NewContent, Existed = DeleteYamlRow(Content, PrimaryKeyName, PrimaryKeyValue)
  if not NewContent or not Existed then
    return false
  end
  return WriteTextFile(YamlPath, NewContent)
end

return RTTIYamlStore
