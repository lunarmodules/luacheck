local helper = require "spec.helper"

local function assert_warnings(warnings, src)
   assert.same(warnings, helper.get_stage_warnings("check_table_fields", src))
end

describe("table field checks", function()
   it("method invocation ends tracking of the base table", function()
      assert_warnings({
         {code = "315", line = 27, column = 3, end_column = 3, name = 'y', field = 'y', set_is_nil = ''},
         {code = "325", line = 27, column = 9, end_column = 9, name = 'y', field = 'x'},
      }, [[
local y = {}

local x = {}
x.y = 1
function x:func() print(self) end
x.y = x:func()
x.y = x.z

local a = {}
a.y = 1
function a:func() print(self) end
a[a:func()] = 1
a.y = a.z

local b = {}
b.y = 1
function b:func() print(self) return 1 end
b[1] = a[b:func()]
b.y = b.z

local c = {}
c.y = 1
function c:func() print(self) return 1 end
c:func()
c.y = c.z

y.y = y.x
      ]])
   end)

   it("functions calls using a table as a whole end tracking of that table", function()
      assert_warnings({
         {code = "315", line = 31, column = 3, end_column = 3, name = 'y', field = 'y', set_is_nil = ''},
         {code = "325", line = 31, column = 9, end_column = 9, name = 'y', field = 'x'},
      }, [[
local y = {}

local x = {}
x.y = 1
x.y = print(x)
x.y = x.z

local a = {}
a.y = 1
function a:func() print(self) end
a[print(a)] = 1
a.y = a.z

local b = {}
b.y = 1
function b:func() print(self) return 1 end
b[1] = a[print(b)]
b.y = b.z

local c = {}
c.y = 1
function c:func() print(self) return 1 end
print(c)
c.y = c.z

local d = {}
d.y = 1
print(print(d))
d.y = d.z

y.y = y.x
      ]])
   end)

   it("functions calls using a table field access only that field", function()
      assert_warnings({
         {code = "315", line = 1, column = 14, end_column = 14, name = 'x', field = 2, set_is_nil = ''},
      }, [[
local x = {1,1}
print(x[1])
x[1], x[2] = 1, 2

local y = {}
function y.func(var) print(var) return 1 end
y[1] = y.func(x[1])
x[1] = 1
y[2] = y:func(x[1])
x[1] = 1

return x, y
      ]])
   end)

   it("functions calls stop checking for tables accessed as upvalues", function()
      assert_warnings({
         {code = "315", line = 27, column = 3, end_column = 3, name = 'y', field = 'y', set_is_nil = ''},
      }, [[
local y = {}

local x = {}
x.y = 1
function x.func() print(x) end
x.y = x.func()
x.y = x.z

local a = {}
a.y = 1
function a.func() print(a) end
a[a.func()] = 1
a.y = a.z

local b = {}
b.y = 1
function glob_func() print(b) return 1 end
b[1] = a[glob_func()]
b.y = b.z

local c = {}
c.y = 1
local function func() print(c) return 1 end
func()
c.y = c.z

y.y = 1

return x, a, b, c
      ]])
   end)

   it("handles multiple layers of nested function calls correctly", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
      }, [[
local x = {...}
x.y = x[2]
      ]])
   end)

   it("assumes that parameters and upvalues have all keys accessed or written to on a function call", function()
      assert_warnings({
      }, [[
local function other_func() end
local x = {}
function func(t)
   t = {1}
   x = {1}
   other_func()
   t[2] = t[2]
   x[2] = x[2]
end
      ]])
   end)

   it("stop tracking for tables passed externally", function()
      assert_warnings({}, [[
local t
local function func1(var)
   t = var
end
local x = {}
func1(x)
x[1] = 1
print(t[1])

local z = {}
local a
function z:func() a = self end
z:func()
z[1] = 1
print(a[1])

local y
local function func2() return y end
function func3()
   y = {}
   local t = func2()
   y[1] = 1
   print(t[1])
end
      ]])
   end)

   it("continues analysis through a function call", function()
      assert_warnings({
         {line = 3, column = 12, name = 'x', end_column = 15, field = 'oops', code = '325', },
      }, [[
   local x = {}
   print("Meh")
   print(x.oops)
      ]])
   end)
end)