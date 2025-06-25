local helper = require "spec.helper"

local function assert_warnings(warnings, src)
   assert.same(warnings, helper.get_stage_warnings("detect_useless_computed_key", src))
end

describe("useless computed property key detection", function()
   it("does not detect anything wrong key is a keyword", function()
      assert_warnings({}, [[
aTable["and"] = 0
]])
   end)

   it("does not detect anything wrong key is not a string", function()
      assert_warnings({}, [[
aTable[{}] = 0
]])
   end)

   it("does not detect anything wrong key start with a number", function()
      assert_warnings({}, [[
aTable["1key"] = 0
]])
   end)


   it("detects useless computed key in table creation", function()
      assert_warnings({
         {code = "701", line = 2, column = 5, end_column = 11, name = "aKey1"},
      }, [[
local aTable = {
   ["aKey1"] = 0
}
]])
   end)

   it("detects useless computed key when affecting a value", function()
      assert_warnings({
         {code = "701", line = 1, column = 8, end_column = 14, name = "aKey2"},
      }, [[
aTable["aKey2"] = 0
]])
   end)

   it("detects useless computed key when accessing a value", function()
      assert_warnings({
         {code = "701", line = 1, column = 14, end_column = 20, name = "aKey3"},
      }, [[
print(aTable["aKey3"])
]])
   end)

end)
