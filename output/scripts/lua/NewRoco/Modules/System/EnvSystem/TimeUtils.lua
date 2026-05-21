local TimeUtils = NRCClass()

function TimeUtils.IsTimeBetween(time, start_time, end_time)
  if time and start_time and end_time and type(time) == type(start_time) and type(time) == type(end_time) then
    if start_time < time and time < end_time or end_time < start_time and start_time < time or time < end_time and end_time < start_time then
      Log.Debug("Is Time Between true", start_time < time and time < end_time, end_time < start_time and start_time < time, time < end_time and end_time < start_time, start_time, time, end_time)
      return true
    end
  else
    Log.Error("\229\175\185\230\175\148\231\154\132\230\151\182\233\151\180\230\156\137\233\151\174\233\162\152\239\188\140\232\191\153\229\144\136\231\144\134\229\144\151\239\188\140\230\152\175\228\184\141\230\152\175\231\173\150\229\136\146\233\133\141\231\189\174\233\148\153\228\186\134\229\149\138\239\188\129\239\188\129\239\188\129", time, start_time, end_time)
  end
  Log.Debug("Is Time Between false")
  return false
end

function TimeUtils.ParseTimeSpan(time_span)
  if time_span then
    local TimeArrayList = string.split(time_span, ":")
    local TargetTime = 0
    for i, value in pairs(TimeArrayList) do
      if not string.IsNilOrEmpty(value) then
        local Time = tonumber(value) * 60 ^ (3 - i)
        TargetTime = TargetTime + Time
      end
    end
    return TargetTime
  end
  return tonumber(time_span) or 0
end

function TimeUtils.ToTimeStamp(dateTimeStr)
  if not string.IsNilOrEmpty(dateTimeStr) then
    local dateTime, success = UE4.UKismetMathLibrary.DateTimeFromString(dateTimeStr)
    if success and dateTime then
      return UE4.UNRCStatics.ToTimestamp(dateTime) - 28800
    end
  end
  return 0
end

return TimeUtils
