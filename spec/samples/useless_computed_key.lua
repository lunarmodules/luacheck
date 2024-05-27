-- warn, could be written simply with "aKey = 0"
local aTable = {
   ["aKey"] = 0
}

-- warn, could be written simply with "aTable.aKey = 1"
aTable["aKey"] = 1

-- no warn, "and" is a keyword
aTable["and"] = 0

-- no warn, "1key" is not a valid name for key
aTable["1key"] = 0

print(aTable)
