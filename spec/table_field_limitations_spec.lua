local helper = require "spec.helper"

local function assert_warnings(warnings, src)
   assert.same(warnings, helper.get_stage_warnings("check_table_fields", src))
end

describe("table field todo tests", function()
   it("does nothing for globals", function()
      assert_warnings({}, [[
x = {}
x[1] = 1
x[2] = x.y
x[1] = 1

y[1] = 1
y[2] = x.y
y[1] = 1
      ]])
   end)

   it("can't parse complicated values out", function()
      assert_warnings({}, [[
local val = nil
local t = {}
t[1] = val
print(t[1])
      ]])
   end)

   it("does nothing for nested tables", function()
      assert_warnings({}, [[
local x = {}
x[1] = {}
x[1][1] = 1
x[1][1] = x[1][2]
return x
      ]])
   end)

   -- Because of possible multiple return
   it("assumes tables initialized from functions can have arbitrary keys set", function()
      assert_warnings({
         {code = "315", line = 3, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
      }, [[
local function func() return 1 end
local x = {func()}
x.y = x[2]
      ]])
   end)

   it("does nothing for table parameters that aren't declared in scope", function()
      assert_warnings({}, [[
function func(x)
   x[1] = x.z
   x[1] = 1
end
      ]])
   end)

   it("doesn't handle metatables", function()
      assert_warnings({}, [[
local x = setmetatable({}, {})
x[1] = 1
print(x[2])
      ]])
   end)

   it("detects unused and undefined table fields inside control blocks, but not between them", function()
      assert_warnings({
         {line = 4, column = 13, name = 'x', end_column = 13, field = 'z', code = '325', },
         {line = 10, column = 13, name = 'x', end_column = 13, field = 'z', code = '325', },
         {line = 16, column = 13, name = 'x', end_column = 13, field = 'z', code = '325', },
         {line = 22, column = 13, name = 'x', end_column = 13, field = 'z', code = '325', },
         {line = 28, column = 13, name = 'x', end_column = 13, field = 'z', code = '325', },
         {line = 34, column = 13, name = 'x', end_column = 13, field = 'z', code = '325', },
      }, [[
do
   local x = {}
   x.y = 1
   x[1] = x.z
end

if true then
   local x = {}
   x.y = 1
   x[1] = x.z
end

while true do
   local x = {}
   x.y = 1
   x[1] = x.z
end

repeat
   local x = {}
   x.y = 1
   x[1] = x.z
until false

for i=1,2 do
   local x = {}
   x.y = 1
   x[1] = x.z
end

for _,_ in pairs({}) do
   local x = {}
   x.y = 1
   x[1] = x.z
end
      ]])
   end)

   it("stops checking referenced upvalues if function call is known to not have table as an upvalue", function()
      assert_warnings({}, [[
local x = {}
x[1] = 1
local function printx() x = 1 end
local function ret2() return 2 end
ret2()
x[1] = 1

local y = {}
y[1] = 1
function y.printx() y = 1 end
function y.ret2() return 2 end
y.ret2()
y[1] = 1
      ]])
   end)

   it("halts checking at the end of control flow blocks with jumps", function()
      assert_warnings({}, [[
local x = {1}
if math.rand(0,1) ~= 1 then
   x = {}
end

x[1] = x[1]

local y = {1}
if math.random(0,1) == 1 then
   y[1] = 2
else
   y = {}
end

y[1] = y[1]

local a = {1}
while math.random(0,1) == 1 do
   a = {}
end

a[1] = a[1]
      ]])
   end)

   it("stops checking if a function is called", function()
      assert_warnings({
         {line = 8, column = 3, name = 'y', end_column = 3, field = 'x', code = '315', set_is_nil = '' },
         {line = 8, column = 9, name = 'y', end_column = 9, field = 'a', code = '325', },
         {line = 14, column = 9, name = 't', end_column = 9, field = 'a', code = '325', },
      }, [[
local x = {}
x.y = 1
print("Unrelated text")
x.y = 2
x[1] = x.z

local y = {}
y.x = y.a
y.x = 1
function y:func() return 1 end
y:func()

local t = {}
t.x = t.a
local var = 'func'
t.x = y[var]() + 1
      ]])
   end)
end)