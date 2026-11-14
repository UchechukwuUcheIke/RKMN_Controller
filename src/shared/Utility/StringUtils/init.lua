--!strict
local StringUtils = {}

function StringUtils.TrimWhitespace(text: string): string
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

table.freeze(StringUtils)
return StringUtils
