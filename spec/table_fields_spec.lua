local helper = require "spec.helper"

local function assert_warnings(warnings, src)
   assert.same(warnings, helper.get_stage_warnings("check_table_fields", src))
end

describe("table field checks", function()
   it("detects unused and undefined table fields", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
         {code = "315", line = 3, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
         {code = "315", line = 4, column = 3, end_column = 3, name = 'x', field = 1, set_is_nil = ''},
         {code = "325", line = 4, column = 10, end_column = 10, name = 'x', field = 'z'},
         {code = "325", line = 5, column = 9, end_column = 9, name = 'x', field = 'a'},
         {code = "315", line = 6, column = 12, end_column = 15, name = 'x', field = 'func', set_is_nil = ''},
      }, [[
local x = {}
x.y = 1
x.y = 2
x[1] = x.z
x.a = x.a
function x.func() end
      ]])
   end)

   it("detects complicated unused and undefined table fields", function()
      assert_warnings({
         {line = 4, column = 11, name = 't', end_column = 11, field = 'b', code = '325', },
         {line = 10, column = 3, name = 'a', end_column = 3, field = 1, code = '315', set_is_nil = '' },
      }, [[
local x = {1}
local t = {}
t.a = 1
t.x = x[t.b]
x[t.a + 1] = x[t.x]

local b = {}
b[1] = 1
local a = {}
a[1] = {}
a[1][1] = 1
a[2] = {}
a[1][b[1] + 1] = a[2][1]
      ]])
   end)

   it("handles upvalue references after definition", function()
      assert_warnings({}, [[
local x = {}
x.y = 1
function x.func() print(x) end
      ]])
   end)

   it("handles upvalue references before definition", function()
      assert_warnings({}, [[
local x
function func() print(x[1]) end
x = {1}
      ]])
   end)

   it("handles upvalues references in returned functions", function()
      assert_warnings({}, [[
function inner()
   local x = {1}
   return function() print(x[1]) end
end
      ]])
   end)

   it("handles upvalue mutations", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
         {code = "315", line = 3, column = 12, end_column = 15, name = 'x', field = 'func', set_is_nil = ''},
      }, [[
local x = {}
x.y = 1
function x.func() x.z = 1 end
      ]])
   end)

   it("handles upvalue sets", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
         {code = "315", line = 3, column = 12, end_column = 15, name = 'x', field = 'func', set_is_nil = ''},
      }, [[
local x = {}
x.y = 1
function x.func() x = 1 end
      ]])
   end)

   it("handles complicated upvalue mutations", function()
      assert_warnings({}, [[
local x = {}
x[1] = {}
x[1][1] = function() x[1][1] = 2 end
x[1][1]()
print(x[1][1])
      ]])
   end)

   -- Handled separately, in detect_unused_fields
   it("doesn't warn on duplicate keys in initialization", function()
      assert_warnings({}, [[
local x = {key = 1, key = 1}
local y = {1, [1] = 1}
return x,y
      ]])
   end)

   it("doesn't warn on overwritten nil-sets in constructor", function()
      assert_warnings({}, [[
local t = {key = nil}
t.key = 1
return t
      ]])
   end)

   it("doesn't warn on unused fields of parameters", function()
      assert_warnings({}, [[
local function func(x)
   x = {1}
end
      ]])
   end)

   it("handles table assignments", function()
      assert_warnings({}, [[
function new_scope()
   local c = {1}
   return {key = c}
end

function new_scope2()
   local t = {}
   t[1] = 1
   return { [t[1] ] = 1}
end

local x = {1}
local y = {x}
local b = {key = y}
local a = {1}
a[b or x] = 1
local d = {[a] = 1}
return {d} or {d}
      ]])
   end)

   it("accounts for returned tables", function()
      assert_warnings({
         {code = "315", line = 6, column = 3, end_column = 3, name = 't', field = 'x', set_is_nil = ''},
      }, [[
local x = {}
x[1] = 1
x.y = 1
local t = {}
t.y = 1
t.x = 1
return x, t.y
      ]])
   end)

   it("handles nested indexes correctly", function()
      assert_warnings({
         {code = "315", line = 3, column = 3, end_column = 3, name = 'x', field = 'z', set_is_nil = ''},
      }, [[
local x = {}
x.y = {}
x.z = {}
return x.y.z
      ]])
   end)

   it("handles initialized tables", function()
      assert_warnings({
         {code = "315", line = 1, column = 12, end_column = 12, name = 'x', field = 1, set_is_nil = ''},
         {code = "315", line = 1, column = 15, end_column = 15, name = 'x', field = 2, set_is_nil = ''},
         {code = "315", line = 1, column = 18, end_column = 18, name = 'x', field = 'a', set_is_nil = ''},
         {code = "315", line = 2, column = 3, end_column = 3, name = 'x', field = 1, set_is_nil = ''},
         {code = "325", line = 2, column = 10, end_column = 10, name = 'x', field = 'z'},
         {code = "315", line = 3, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''}
      }, [[
local x = {1, 2, a = 3}
x[1] = x.z
x.y = 1
      ]])
   end)

   it("handles tables that are upvalues", function()
      assert_warnings({
         {code = "325", line = 5, column = 13, end_column = 13, name = 'x', field = 'a'},
      }, [[
local x

function func()
   x = {}
   x[1] = x.a
end

local t

print(function()
   t = {t.a}
end)
      ]])
   end)

   it("handles table assignments to existing local variables", function()
      assert_warnings({
         {code = "315", line = 3, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
         {code = "315", line = 6, column = 3, end_column = 3, name = 'y', field = 'y', set_is_nil = ''},
         {code = "315", line = 8, column = 3, end_column = 3, name = 'y', field = 'y', set_is_nil = ''},
      }, [[
local x
x = {}
x.y = 1

local y = {}
y.y = 1
y = {}
y.y = 1
      ]])
   end)

   it("handles nil sets correctly", function()
      assert_warnings({
         {line = 2, column = 3, name = 'x', end_column = 3, field = 'y', code = '315', set_is_nil = ''},
         {line = 3, column = 3, name = 'x', end_column = 3, field = 'y', code = '315', set_is_nil = 'nil '},
         {line = 5, column = 3, name = 'x', end_column = 3, field = 'z', code = '315', set_is_nil = ''},
         {line = 5, column = 9, name = 'x', end_column = 9, field = 'y', code = '325', },
         {line = 6, column = 3, name = 'x', end_column = 3, field = 'y', code = '315', set_is_nil = ''},
      }, [[
local x = {}
x.y = 1
x.y = nil
x.y = nil
x.z = x.y
x.y = 1
      ]])
   end)

   it("handles balanced multiple assignment correctly", function()
      assert_warnings({
         {code = "325", line = 2, column = 22, end_column = 22, name = 't', field = 'b'},
         {code = "325", line = 3, column = 20, end_column = 20, name = 't', field = 'z'}
      }, [[
local t = {}
t.x, t.y, t.z = 1, t.b
return t.x, t.y, t.z
      ]])
   end)

   it("handles multiple assignment of tables", function()
      assert_warnings({
         {code = "315", line = 3, column = 3, end_column = 3, name = 'x', field = 'a', set_is_nil = ''},
         {code = "325", line = 4, column = 10, end_column = 10, name = 'b', field = 'c'},
      }, [[
local x,y = {}, {}
local a,b = {}, {}
x.a = 1
return b.c
      ]])
   end)

   it("handles imbalanced multiple assignment correctly", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 't', field = 'x', set_is_nil = ''},
         {code = "325", line = 3, column = 10, end_column = 10, name = 't', field = 'y'},
      }, [[
local t = {}
t.x, t.y = 1
return t.y
      ]])
   end)

   it("tables used as keys create a reference to them", function()
      assert_warnings({}, [[
local t = {}
local y = {1}
t[y or 3] = 1
return t
      ]])
   end)

   it("understands the difference between string and number keys", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 't', field = 1, set_is_nil = ''},
         {code = "315", line = 3, column = 3, end_column = 5, name = 't', field = '2', set_is_nil = ''},
         {code = "325", line = 3, column = 12, end_column = 14, name = 't', field = '1'},
      }, [[
local t = {}
t[1] = 1
t["2"] = t["1"]
      ]])
   end)

   it("continues checking if the table variable itself is accessed without creating a reference", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
         {code = "315", line = 5, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''}
      }, [[
local x = {}
x.y = 1
local t = {1}
t[1] = t[x]
x.y = 1
      ]])
   end)

   it("warns on non-atomic key access to an entirely empty table", function()
      assert_warnings({
         {code = "325", line = 3, column = 11, end_column = 13, name = 't2', field = '[Non-atomic key]'},
         {code = "325", line = 4, column = 11, end_column = 11, name = 't2', field = 't'},
      }, [[
local t = {}
local t2 = {}
t[1] = t2[1+1]
t[2] = t2[t]
return t
      ]])
   end)

   it("handles aliases correctly", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 'x', field = 1, set_is_nil = ''},
         {code = "325", line = 2, column = 10, end_column = 10, name = 'x', field = 'z'},
         {code = "315", line = 3, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
         {code = "315", line = 6, column = 3, end_column = 3, name = 't', field = 'y', set_is_nil = ''},
         {code = "315", line = 7, column = 3, end_column = 3, name = 't', field = 1, set_is_nil = ''},
         {code = "325", line = 7, column = 10, end_column = 10, name = 't', field = 'z'},
      }, [[
local x = {}
x[1] = x.z
x.y = 1
x.x = 1
local t = x
t.y = 1
t[1] = t.z
t = t
x = t
return t.x
      ]])
   end)

   it("an alias being overwritten doesn't end processing for the other aliases", function()
      assert_warnings({
         {code = "315", line = 5, column = 3, end_column = 3, name = 'x', field = 1, set_is_nil = ''},
      }, [[
local x = {}
local t = x
t[2] = 2
t = 1
x[1] = 1
x[1] = 1
return x, t
      ]])
   end)

   it("any alias being externally referenced blocks unused warnings", function()
      assert_warnings({}, [[
local t
function inner()
   local x = {1}
   t = x
end
      ]])
   end)

   it("handles rhs/lhs order correctly", function()
      assert_warnings({
         {code = "325", line = 5, column = 10, end_column = 10, name = 'x', field = 3},
      }, [[
local x = {}
x[1] = 1
x[2] = 2
x[1], x[2] = x[2], x[1]
x[3] = x[3]

local t = {}
t[1] = 1
t[t[1] ] = 2
return x, t
      ]])
   end)

   it("assumes that tables initialized from varargs can have arbitary keys set", function()
      assert_warnings({
         {code = "315", line = 2, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
      }, [[
local x = {...}
x.y = x[2]
      ]])
   end)

   it("catches unused writes after a non-atomic access", function()
      assert_warnings({
         {code = "315", line = 6, column = 3, end_column = 3, name = 'x', field = 'y', set_is_nil = ''},
         {code = "315", line = 10, column = 3, end_column = 3, name = 'a', field = 'y', set_is_nil = ''},
      }, [[
local var = 1

local x = {1}
local t = {}
t[1] = x[var]
x.y = 1

local a = {1}
t[2] = a[1 + 1]
a.y = 1
return t
      ]])
   end)

   it("accesses are not forever", function()
      assert_warnings({
         {code = "315", line = 3, column = 3, end_column = 3, name = 'x', field = 2, set_is_nil = ''},
         {code = "315", line = 4, column = 3, end_column = 3, name = 'x', field = 1, set_is_nil = ''},
      }, [[
local x = {}
x[1] = 1
x[2] = x[1]
x[1] = 1
      ]])
   end)

   it("more complicated function calls", function()
      assert_warnings({}, [[
local t = {}
function t.func(var) print(var) end
local x = {}
x.y = 1
t.func(x)
      ]])
   end)
end)
