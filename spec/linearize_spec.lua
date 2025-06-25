local helper = require "spec.helper"

local function get_line_or_throw(src)
   return helper.get_chstate_after_stage("linearize", src).top_line
end

local function get_line(src)
   local ok, res = pcall(get_line_or_throw, src)

   if ok or type(res) == "table" then
      return res
   else
      error(res, 0)
   end
end

local function item_to_string(item)
   if item.tag == "Jump" or item.tag == "Cjump" then
      return item.tag .. " -> " .. tostring(item.to)
   elseif item.tag == "Eval" then
      return "Eval " .. item.node.tag
   elseif item.tag == "Local" then
      local buf = {}

      for _, node in ipairs(item.lhs) do
         table.insert(buf, ("%s (%d..%d)"):format(node.var.name, node.var.scope_start, node.var.scope_end))
      end

      return "Local " .. table.concat(buf, ", ")
   else
      return item.tag
   end
end

local function get_line_as_string(src)
   local line = get_line(src)
   local buf = {}

   for i, item in ipairs(line.items) do
      buf[i] = tostring(i) .. ": " .. item_to_string(item)
   end

   return table.concat(buf, "\n")
end

local function value_info_to_string(item)
   local buf = {}

   for var, value in pairs(item.set_variables) do
      table.insert(buf, ("%s (%s / %s%s%s%s)"):format(
         var.name, var.type, value.type,
         value.empty and ", empty" or "",
         value.secondaries and (", " .. tostring(#value.secondaries) .. " secondaries") or "",
         value.secondaries and value.secondaries.used and ", used" or ""))
   end

   table.sort(buf)
   return item.tag .. ": " .. table.concat(buf, ", ")
end

local function get_value_info_as_string(src)
   local line = get_line(src)
   local buf = {}

   for _, item in ipairs(line.items) do
      if item.tag == "Local" or item.tag == "Set" then
         assert.is_table(item.set_variables)
         table.insert(buf, value_info_to_string(item))
      end
   end

   return table.concat(buf, "\n")
end

describe("linearize", function()
   describe("when handling post-parse syntax errors", function()
      it("detects gotos without labels", function()
         assert.same({line = 1, offset = 1, end_offset = 4, msg = "no visible label 'fail'"},
            get_line("goto fail"))
      end)

      it("detects break outside loops", function()
         assert.same({line = 1, offset = 1, end_offset = 5, msg = "'break' is not inside a loop"},
            get_line("break"))
         assert.same({line = 1, offset = 28, end_offset = 32, msg = "'break' is not inside a loop"},
            get_line("while true do function f() break end end"))
      end)

      it("detects duplicate labels", function()
         assert.same({line = 2, offset = 10, end_offset = 17, prev_line = 1, prev_offset = 1, prev_end_offset = 8,
            msg = "label 'fail' already defined on line 1"},
            get_line("::fail::\n::fail::"))
      end)

      it("detects varargs outside vararg functions", function()
         assert.same({line = 1, offset = 21, end_offset = 23, msg = "cannot use '...' outside a vararg function"},
            get_line("function f() return ... end"))
         assert.same({line = 1, offset = 42, end_offset = 44, msg = "cannot use '...' outside a vararg function"},
            get_line("function f(...) return function() return ... end end"))
      end)
   end)

   describe("when linearizing flow", function()
      it("linearizes empty source correctly", function()
         assert.equal("1: Local ... (2..1)", get_line_as_string(""))
      end)

      it("linearizes do-end blocks correctly", function()
         assert.equal([[
1: Local ... (2..4)
2: Noop
3: Noop
4: Eval Call]], get_line_as_string([[
do end
do print(foo) end]]))
      end)

      it("linearizes loops correctly", function()
         assert.equal([[
1: Local ... (2..8)
2: Noop
3: Eval Id
4: Cjump -> 9
5: Local s (6..6)
6: Eval Call
7: Noop
8: Jump -> 3]], get_line_as_string([[
while cond do
   local s = io.read()
   print(s)
end]]))

         assert.equal([[
1: Local ... (2..6)
2: Noop
3: Local s (4..5)
4: Eval Call
5: Eval Id
6: Cjump -> 3]], get_line_as_string([[
repeat
   local s = io.read()
   print(s)
until cond]]))

         assert.equal([[
1: Local ... (2..9)
2: Noop
3: Eval Number
4: Eval Op
5: Cjump -> 10
6: Local i (7..7)
7: Eval Call
8: Noop
9: Jump -> 5]], get_line_as_string([[
for i = 1, #t do
   print(t[i])
end]]))

         assert.equal([[
1: Local ... (2..8)
2: Noop
3: Eval Call
4: Cjump -> 9
5: Local k (6..6), v (6..6)
6: Eval Call
7: Noop
8: Jump -> 4]], get_line_as_string([[
for k, v in pairs(t) do
   print(k, v)
end]]))
      end)

      it("linearizes loops with literal condition correctly", function()
         assert.equal([[
1: Local ... (2..6)
2: Noop
3: Eval Number
4: Eval Call
5: Noop
6: Jump -> 3]], get_line_as_string([[
while 1 do
   foo()
end]]))

         assert.equal([[
1: Local ... (2..7)
2: Noop
3: Eval False
4: Jump -> 8
5: Eval Call
6: Noop
7: Jump -> 3]], get_line_as_string([[
while false do
   foo()
end]]))

         assert.equal([[
1: Local ... (2..4)
2: Noop
3: Eval Call
4: Eval True]], get_line_as_string([[
repeat
   foo()
until true]]))

            assert.equal([[
1: Local ... (2..5)
2: Noop
3: Eval Call
4: Eval Nil
5: Jump -> 3]], get_line_as_string([[
repeat
   foo()
until nil]]))
      end)

      it("linearizes nested loops and breaks correctly", function()
         assert.equal([[
1: Local ... (2..24)
2: Noop
3: Eval Call
4: Cjump -> 25
5: Eval Call
6: Noop
7: Eval Call
8: Cjump -> 18
9: Eval Call
10: Noop
11: Eval Call
12: Cjump -> 15
13: Jump -> 18
14: Jump -> 15
15: Eval Call
16: Noop
17: Jump -> 7
18: Noop
19: Eval Call
20: Cjump -> 23
21: Jump -> 25
22: Jump -> 23
23: Noop
24: Jump -> 3]], get_line_as_string([[
while cond() do
   stmts()

   while cond() do
      stmts()

      if cond() then
         break
      end

      stmts()
   end

   if cond() then
      break
   end
end]]))
      end)

      it("linearizes if correctly", function()
         assert.equal([[
1: Local ... (2..15)
2: Noop
3: Eval Call
4: Cjump -> 16
5: Noop
6: Eval Call
7: Cjump -> 10
8: Eval Call
9: Jump -> 15
10: Eval Call
11: Cjump -> 14
12: Eval Call
13: Jump -> 15
14: Eval Call
15: Jump -> 16]], get_line_as_string([[
if cond() then
   if cond() then
      stmts()
   elseif cond() then
      stmts()
   else
      stmts()
   end
end]]))
      end)

      it("linearizes if with literal condition correctly", function()
         assert.equal([[
1: Local ... (2..14)
2: Noop
3: Eval True
4: Noop
5: Eval Call
6: Cjump -> 9
7: Eval Call
8: Jump -> 14
9: Eval False
10: Jump -> 13
11: Eval Call
12: Jump -> 14
13: Eval Call
14: Jump -> 15]], get_line_as_string([[
if true then
   if cond() then
      stmts()
   elseif false then
      stmts()
   else
      stmts()
   end
end]]))
      end)

      it("linearizes gotos correctly", function()
         assert.equal([[
1: Local ... (2..13)
2: Eval Call
3: Noop
4: Jump -> 2
5: Eval Call
6: Noop
7: Jump -> 9
8: Eval Call
9: Eval Call
10: Noop
11: Noop
12: Jump -> 14
13: Eval Call]], get_line_as_string([[
::label1::
stmts()
goto label1
stmts()
goto label2
stmts()
::label2::
stmts()

do
   goto label2
   stmts()
   ::label2::
end]]))
      end)
   end)

   describe("when registering values", function()
      it("registers values in empty chunk correctly", function()
         assert.equal([[
Local: ... (arg / arg)]], get_value_info_as_string(""))
      end)

      it("registers values in assignments correctly", function()
         assert.equal([[
Local: ... (arg / arg)
Local: a (var / var)
Set: a (var / var)]], get_value_info_as_string([[
local a = b
a = d]]))
      end)

      it("registers empty values correctly", function()
         assert.equal([[
Local: ... (arg / arg)
Local: a (var / var), b (var / var, empty)
Set: a (var / var), b (var / var)]], get_value_info_as_string([[
local a, b = 4
a, b = 5]]))
      end)

      it("registers function values as of type func", function()
         assert.equal([[
Local: ... (arg / arg)
Local: f (var / func)]], get_value_info_as_string([[
local function f() end]]))
      end)

      it("registers overwritten args and counters as of type var", function()
         assert.equal([[
Local: ... (arg / arg)
Local: i (loopi / loopi)
Set: i (loopi / var)]], get_value_info_as_string([[
for i = 1, 10 do i = 6 end]]))
      end)

      it("registers groups of secondary values", function()
         assert.equal([[
Local: ... (arg / arg)
Local: a (var / var), b (var / var, 2 secondaries), c (var / var, 2 secondaries)
Set: a (var / var), b (var / var, 2 secondaries), c (var / var, 2 secondaries)]], get_value_info_as_string([[
local a, b, c = f(), g()
a, b, c = f(), g()]]))
      end)

      it("marks groups of secondary values used if one of values is put into global or index", function()
         assert.equal([[
Local: ... (arg / arg)
Local: a (var / var, empty)
Set: a (var / var, 1 secondaries, used)]], get_value_info_as_string([[
local a
g, a = f()]]))
      end)
   end)
end)

describe("constant modification detection", function()
   it("detects modified constants", function()
      assert.same({
         {code = "441", line = 4, column = 1, end_column = 17, defined_line = 1, name = 'b'}
      }, helper.get_stage_warnings("linearize", [[
local a, b <const>, c = 1, 1, 1
print(a, b, c)

a, b, c = 2, 2, 2
print(a, b, c)
]]))
   end)

   it("detects a constant overwritten by a function", function()
      assert.same({
         {code = "441", line = 4, column = 1, end_column = 16, defined_line = 1, name = 'a'}
      }, helper.get_stage_warnings("linearize", [[
local a <const> = 1
print(a)

function a() end
a()
]]))
   end)

   it("doesn't trigger on a constant redefinition", function()
      assert.same({
         {code = "411", line = 4, column = 7, end_column = 7, name = 'a',
            prev_column = 7, prev_end_column = 7, prev_line = 1}
      }, helper.get_stage_warnings("linearize", [[
local a <const> = 1
print(a)

local a = 1
print(a)
]]))
   end)

   it("doesn't trigger on a loop overriding a constant", function()
      assert.same({
         {code = "421", line = 4, column = 5, end_column = 5, name = 'a',
            prev_column = 7, prev_end_column = 7, prev_line = 1}
      }, helper.get_stage_warnings("linearize", [[
local a <const> = 1
print(a)

for a = 1,10 do
   print(a)
end
]]))
   end)

   it("handles variable scoping correctly", function()
      assert.same({
         {code = "421", line = 5, column = 10, end_column = 10, name = 'a',
            prev_column = 7, prev_end_column = 7, prev_line = 1},
         {code = "421", line = 5, column = 13, end_column = 13, name = 'b',
            prev_column = 18, prev_end_column = 18, prev_line = 1},
         {code = "441", line = 9, column = 1, end_column = 11, name = 'a',
            defined_line = 1}
      }, helper.get_stage_warnings("linearize", [[
local a <const>, b = 1, 1
print(a, b)

do
   local a, b <const> = 2, 2
   print(a, b)
end

a, b = 3, 3
print(a, b)
]]))
   end)

   it("handles loop control variables correctly", function()
      assert.same({
         {code = "442", line = 2, column = 3, end_column = 11, name = 'i',
            defined_line = 1},
         {code = "442", line = 7, column = 3, end_column = 13, name = 'k',
            defined_line = 6},
      }, helper.get_stage_warnings("linearize", [[
for i = 1, 10 do
  i = i - 1
  print(i)
end

for k,_ in pairs({ foo = "bar" }) do
  k = "k:"..k
  print(k)
end
]]))
   end)
end)