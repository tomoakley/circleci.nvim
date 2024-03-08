local utils = {}

function utils.prettyDateTime(dateTimeString)
  -- Extract date and time components from the datetime string
  local year, month, day, hour, min, sec = string.match(dateTimeString, '(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d).%d%d%dZ?')

  -- Convert month from number to name
  local monthNames = {
      ["01"] = "January", ["02"] = "February", ["03"] = "March", ["04"] = "April",
      ["05"] = "May", ["06"] = "June", ["07"] = "July", ["08"] = "August",
      ["09"] = "September", ["10"] = "October", ["11"] = "November", ["12"] = "December"
  }

  if not day or not month or not year or not hour or not min or not sec then
      return dateTimeString
  end

  -- Format the date and time
  return day .. "/" .. month.. "/" .. year .. ", " .. hour .. ":" .. min .. ":" .. sec
end

return utils
