local utils = require "luacheck.utils"

local stage = {}

stage.warnings = {
   ["315"] = {
      message_format = "{set_is_nil}value assigned to table field {name!}.{field!} is unused",
      fields = {"set_is_nil", "name", "field"}
   },
   ["325"] = {message_format = "table field {name!}.{field!} is not defined", fields = {"name", "field"}},
}

local function_call_tags = utils.array_to_set({"Call", "Invoke"})

local ClosureState = utils.class()

function ClosureState:__init(chstate)
   self.chstate = chstate

   -- Map from table name => table info. See new_local_table for the format.
   self.current_tables = {}

   -- externally reference variable means that its fields could potentially all
   -- be referenced externally
   self.external_references_accessed = {}

   self.max_item = 0

   -- Luacheck's linearized item format doesn't explicitly have a node for the "end" tag
   -- This tracks where end tags would be, so that we can stop tracking
   -- This pattern won't be workable if this eventually gets extended to support control flow
   self.jump_destinations = {}
end

-- Start keeping track of a local table
-- Can be from local x = {} OR "local x; x = {}"
function ClosureState:new_local_table(table_name)
   self.current_tables[table_name] = {
      -- set_keys sets store a mapping from key => {table_name, key_node, value_node}
      -- the nodes store the line/column info
      set_keys = {},
      -- accessed keys is a mappings from key => key_node
      accessed_keys = {},
      -- For a variable key, it's impossible to reliably get the value; any given key could be set or accessed
      -- potentially_all_* is set to the node responsible when truthy
      potentially_all_set = nil,
      potentially_all_accessed = nil,
      -- Multiple variable names that point at the same underlying table
      -- e.g. local x = {}; local t = x
      aliases = {[table_name] = true},
   }
end

-- Called when a table's field's value is no longer accessible
-- Either the table is gone, or the field has been overwritten
-- Table info can be different from the value of current_tables[table_name]
-- In the case that the original table was removed but an alias is still relevant
function ClosureState:maybe_warn_unused(table_info, key, set_data)
   local set_table_name, set_node, assigned_val = set_data.table_name, set_data.key_node, set_data.assigned_node
   local access_node = table_info.accessed_keys[key]
   local all_access_node = table_info.potentially_all_accessed
   -- Warn if there were definitely no accesses for this value
   if (not access_node or access_node.line < set_node.line)
      and (not all_access_node or all_access_node.line < set_node.line)
   then
      local original_key = set_node.tag == "Number" and tonumber(set_node[1]) or set_node[1]
      self.chstate:warn_range("315", set_node, {
         name = set_table_name,
         field = original_key,
         set_is_nil = assigned_val.tag == "Nil" and "nil " or ""
      })
   end
end

-- Called on accessing a table's field
function ClosureState:maybe_warn_undefined(table_name, key, range)
   local table_info = self.current_tables[table_name]
   -- Warn if the field is definitely not set
   local set_data = table_info.set_keys[key]
   local set_node, set_val
   if set_data then
      set_node, set_val = set_data.key_node, set_data.assigned_node
   end
   local all_set = table_info.potentially_all_set
   if (not set_data and not all_set)
      or (set_data and set_val.tag == "Nil" and (not all_set or set_node.line > all_set.line))
   then
      self.chstate:warn_range("325", range, {
         name = table_name,
         field = key
      })
   end
end

-- Called on accessing a table's field with an unknown (variable or otherwise indecipherable) key
-- Can only warn if the table is known to be empty
function ClosureState:maybe_warn_undefined_var_key(table_name, var_key_name, range)
   local table_info = self.current_tables[table_name]
   -- Are there any non-nil keys at all?
   if table_info.potentially_all_set then
      return
   end
   for _, set_data in pairs(table_info.set_keys) do
      if set_data.assigned_node.tag ~= "Nil" then
         return
      end
   end

   self.chstate:warn_range("325", range, {
      name = table_name,
      field = var_key_name
   })
end

-- Called when setting a new key for a known local table
function ClosureState:set_key(table_name, key_node, assigned_val, in_init)
   local table_info = self.current_tables[table_name]
   -- Constant key
   if key_node.tag == "Number" or key_node.tag == "String" then
      -- Don't warn about unused nil initializations
      -- Fairly common to declare that a table should end up with fields set
      -- by setting them to nil in the constructor
      if in_init and assigned_val.tag == "Nil" then
         return
      end
      local key = key_node[1]
      if key_node.tag == "Number" then
         key = tonumber(key)
      end
      -- Don't report duplicate keys in the init; other module handles that
      if table_info.set_keys[key] and not in_init then
         self:maybe_warn_unused(table_info, key, table_info.set_keys[key])
      end
      -- Do note: just because a table's key has a value in set_keys doesn't
      -- mean that it's not nil! variables, function returns, table indexes,
      -- nil itself, and complex boolean conditions can return nil
      -- set_keys tracks *specifically* the set itself, not whether the table's
      -- field is non-nil
      table_info.set_keys[key] = {
         table_name = table_name,
         key_node = key_node,
         assigned_node = assigned_val
      }
   else
      -- variable key
      if assigned_val.tag ~= "Nil" then
         table_info.potentially_all_set = key_node
      end
   end
end

-- Called when indexing into a known local table
function ClosureState:access_key(table_name, key_node)
   if key_node.tag == "Number" or key_node.tag == "String" then
      local key = key_node[1]
      if key_node.tag == "Number" then
         key = tonumber(key)
      end
      self:maybe_warn_undefined(table_name, key, key_node)
      self.current_tables[table_name].accessed_keys[key] = key_node
   else
      -- variable key
      local var_key_name = key_node.var and key_node.var.name or "[Non-atomic key]"
      self:maybe_warn_undefined_var_key(table_name, var_key_name, key_node)
      self.current_tables[table_name].potentially_all_accessed = key_node
   end
end

-- Stop trying to track a table
-- We stop when:
-- * the variable is overwritten entirely
-- * the variable's scope ends
-- * we hit something that leaves us unable to usefully process
function ClosureState:wipe_table_data(table_name)
   local info_table = self.current_tables[table_name]
   for alias in pairs(info_table.aliases) do
      self.current_tables[alias] = nil
   end
end

-- Called when a table variable is no longer accessible
-- i.e. the scope has ended or the variable has been overwritten
function ClosureState:end_table_variable(table_name)
   local table_info = self.current_tables[table_name]
   table_info.aliases[table_name] = nil

   if next(table_info.aliases) == nil then
      for key, set_data in pairs(table_info.set_keys) do
         self:maybe_warn_unused(table_info, key, set_data)
      end
   end

   self.current_tables[table_name] = nil
end

-- Called on a new scope, including from a function call
-- Unlike end_table_variable, this assumes that any and all existing tables values
-- Can potentially be accessed later on, and so doesn't warn about unused values
function ClosureState:stop_tracking_tables()
   for table_name in pairs(self.current_tables) do
      self:wipe_table_data(table_name)
   end
end

function ClosureState:on_scope_end_for_var(table_name)
   local table_info = self.current_tables[table_name]
   local has_external_references = false
   for alias in pairs(table_info.aliases) do
      if self.external_references_accessed[alias] then
         has_external_references = true
      end
   end
   if has_external_references then
      self:wipe_table_data(table_name)
   else
      self:end_table_variable(table_name)
   end
end

function ClosureState:on_scope_end()
   for table_name in pairs(self.current_tables) do
      self:on_scope_end_for_var(table_name)
   end
end

-- A function call leaves the current scope, and does potentially arbitrary modifications
-- To any externally referencable tables: either upvalues to other functions
-- Or parameters
function ClosureState:check_for_function_calls(node)
   if node.tag ~= "Function" then
      if function_call_tags[node.tag] then
         self:stop_tracking_tables(node)
         return true
      end

      for _, sub_node in ipairs(node) do
         if type(sub_node) == "table" then
            if self:check_for_function_calls(sub_node) then
               return true
            end
         end
      end
   end
end

-- Records accesses to a specific key in a table
function ClosureState:record_field_accesses(node)
   if node.tag ~= "Function" then
      if node.tag == "Index" and node[1] then
         local sub_node = node[1]
         if sub_node.var and self.current_tables[sub_node.var.name] then
            self:access_key(sub_node.var.name, node[2])
         end
      end
      for _, sub_node in ipairs(node) do
         if type(sub_node) == "table" then
            self:record_field_accesses(sub_node)
         end
      end
   end
end

-- Records accesses to the table as a whole, i.e. for table x, either t[x] = val or x = t
-- For the former, we stop tracking the table; for the latter, we mark x and t down as aliases if x is a local
-- For existing table t, in "local x = t", x is passed in as the aliased node
function ClosureState:record_table_accesses(node, aliased_node)
   -- t[x or y] = val; x = t1 or t2
   if node[1] == "and" or node[1] == "or" then
      for _, sub_node in ipairs(node) do
         if type(sub_node) == "table" then
            self:record_table_accesses(sub_node)
         end
      end
   end

   -- t[{x}] = val; t = {x}; t = {[x] = val}; all keep x alive
   if node.tag == "Table" then
      for _, sub_node in ipairs(node) do
         if sub_node.tag == "Pair" then
            local key_node, val_node = sub_node[1], sub_node[2]
            self:record_table_accesses(key_node)
            self:record_table_accesses(val_node)
         elseif sub_node.tag ~= "Nil" then
            self:record_table_accesses(sub_node)
         end
      end
   end

   local alias_info = nil
   if node.var and self.current_tables[node.var.name] then
      -- $lhs = $tracked_table
      if aliased_node and aliased_node.var then
         alias_info = {aliased_node.var.name, node.var.name}
      else
         -- assigned to a global; cannot usefully process
         self:wipe_table_data(node.var.name)
      end
   end

   return alias_info
end

-- Detects accesses to tables and table fields in item
-- For the case local $var = $existing table, returns a table
-- of multiple assignment index => {newly_set_var_name, existing_table_name}
function ClosureState:detect_accesses(sub_nodes, potential_aliases)
   local alias_info = {}
   for node_index, node in ipairs(sub_nodes) do
      self:record_field_accesses(node)
      alias_info[node_index] = self:record_table_accesses(node, potential_aliases and potential_aliases[node_index])
   end
   return alias_info
end

function ClosureState:handle_control_flow_item(item)
   -- return gets linearized as a return control flow node followed by
   -- an eval node of what got returned, followed by a jump
   -- We want to defer the scope end processing until the jump so that
   -- any accessed in the eval get processed
   if not item.node or item.node.tag ~= "Return" then
      self:stop_tracking_tables()
   end
end

function ClosureState:handle_local_or_set_item(item)
   self:check_for_function_calls(item.node)

   -- Process RHS first, then LHS
   -- When creating an alias, i.e. $new_var = $existing_var, need to store that info
   -- and record it during LHS processing
   local alias_info = {}
   if item.rhs then
      alias_info = self:detect_accesses(item.rhs, item.lhs)
   end

   -- For imbalanced assignment with possible multiple return function
   local last_rhs_node = false
   for index, lhs_node in ipairs(item.lhs) do
      local rhs_node = item.rhs and item.rhs[index]
      if not rhs_node then
         if last_rhs_node and function_call_tags[last_rhs_node.tag] then
            rhs_node = last_rhs_node
         else
            -- Duck typing seems bad?
            rhs_node = {
               tag = "Nil"
            }
         end
      else
         last_rhs_node = rhs_node
      end

      -- Case: $existing_table[key] = value
      if lhs_node.tag == "Index" then
         local base_node, key_node = lhs_node[1], lhs_node[2]

         -- Case: $var[$existing_table[key]] = value
         -- Need to pass in a new array rather than using lhs_node, because that would
         -- mark the base *set* as also being an access
         self:detect_accesses({key_node})

         -- Deliberately don't continue down indexes- $table[key1][key2] isn't a new set of key1
         if base_node.tag == "Id" then
            -- Might not have a var if it's a global
            local lhs_table_name = base_node.var and base_node.var.name
            if self.current_tables[lhs_table_name] then
               self:set_key(lhs_table_name, key_node, rhs_node, false)
            end
         end
      end

      if alias_info[index] then
         local new_var_name, existing_var_name = alias_info[index][1], alias_info[index][2]
         self.current_tables[new_var_name] = self.current_tables[existing_var_name]
         self.current_tables[new_var_name].aliases[new_var_name] = true
      end

      -- Case: $existing_table = new_value
      -- Complete overwrite of previous value
      if lhs_node.var and self.current_tables[lhs_node.var.name] then
         -- $existing_table = $existing_table should do nothing
         if not (rhs_node.var
            and self.current_tables[rhs_node.var.name] == self.current_tables[lhs_node.var.name])
         then
            self:end_table_variable(lhs_node.var.name)
         end
      end

      -- Case: local $table = {} or local $table; $table = {}
      -- New table assignment
      if lhs_node.var and rhs_node.tag == "Table" then
         local table_var = lhs_node.var
         self:new_local_table(table_var.name)
         for initialization_index, node in ipairs(rhs_node) do
            if node.tag == "Pair" then
               local key_node, val_node = node[1], node[2]
               self:set_key(table_var.name, key_node, val_node, true)
            elseif node.tag == "Dots" or node.tag == "Call" then
               -- Vararg can expand to arbitrary size;
               -- Function calls can return multiple values
               self.current_tables[table_var.name].potentially_all_set = node
               break
            elseif node.tag ~= "Nil" then
               -- Duck typing, meh
               local key_node = {
                  [1] = initialization_index,
                  tag = "Number",
                  line = node.line,
                  offset = node.offset,
                  end_offset = node.end_offset
               }
               self:set_key(table_var.name, key_node, node, true)
            end
         end
      end
   end
end

function ClosureState:handle_op_set(item)
   self:check_for_function_calls(item.node)

   -- By assumption, OpSet only supports a single item on the lhs/rhs
   local lhs_node = item.lhs[1]
   local rhs_node = item.rhs[1]

   -- Only way OpSet can be relevant to tables is $table[key] += val or the like
   if lhs_node.tag == "Index" then
      local base_node, key_node = lhs_node[1], lhs_node[2]

      -- Always accesses the lhs before writing to it
      self:detect_accesses({lhs_node})

      -- Case: $var[$existing_table[key]] = value
      -- Need to pass in a new array rather than using lhs_node, because that would
      -- mark the base *set* as also being an access
      self:detect_accesses({key_node})

      -- Deliberately don't continue down indexes- $table[key1][key2] isn't a new set of key1
      if base_node.tag == "Id" then
         -- Might not have a var if it's a global
         local lhs_table_name = base_node.var and base_node.var.name
         if self.current_tables[lhs_table_name] then
            self:set_key(lhs_table_name, key_node, rhs_node, false)
         end
      end
   end
end

function ClosureState:handle_eval(item)
   self:check_for_function_calls(item.node)
   self:detect_accesses({item.node})
end

function ClosureState:handle_jump(item)
   self.jump_destinations[item.to] = true
   if item.to > self.max_item then
      -- return; see comment under handle_control_flow_item
      self:on_scope_end()
   else
      self:stop_tracking_tables()
   end
end

local item_callbacks = {
   Noop = ClosureState.handle_control_flow_item,
   Jump = ClosureState.handle_jump,
   Cjump = ClosureState.handle_jump,
   Eval = ClosureState.handle_eval,
   Local = ClosureState.handle_local_or_set_item,
   Set = ClosureState.handle_local_or_set_item,
   OpSet = ClosureState.handle_op_set,
}

-- Steps through the closure one item at a time
-- At each point, tracking for each local table which fields have been set
local function detect_unused_table_fields(closure, check_state)
   local closure_state = ClosureState(check_state)

   local args = closure.node[1]
   for _, parameter in ipairs(args) do
      closure_state.external_references_accessed[parameter.var.name] = true
   end

   -- Only need to check set_upvalues because we only track newly set tables
   -- Inside the current scope
   for var in pairs(closure.set_upvalues) do
      closure_state.external_references_accessed[var.name] = true
   end

   closure_state.max_item = #closure.items

   for item_index = 1, #closure.items do
      if closure_state.jump_destinations[item_index] then
         closure_state:stop_tracking_tables()
      end
      -- Function declaration: function could potentially survive this scope
      -- Preserving a reference to its upvalues
      local item = closure.items[item_index]
      if item.lines then
         for _,func_scope in pairs(item.lines) do
            for var in pairs(func_scope.accessed_upvalues) do
               closure_state.external_references_accessed[var.name] = true
            end
         end
      end
      item_callbacks[item.tag](closure_state, item)
   end

   -- Handle implicit return
   closure_state:on_scope_end()
end

-- Warns about table fields that are never accessed
-- VERY high false-negative rate, deliberately in order to minimize the false-positive rate
function stage.run(check_state)
   for _, closure in ipairs(check_state.lines) do
      detect_unused_table_fields(closure, check_state)
   end
end

return stage
