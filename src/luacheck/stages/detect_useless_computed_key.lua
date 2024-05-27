local utils = require "luacheck.utils"

local stage = {}

local function useless_computed_key_message_format()
   return "It's unnecessary to use computed properties with literals such as {name!}"
end

stage.warnings = {
   ["701"] = {message_format = useless_computed_key_message_format,
      fields = {"name"}}
}

local function warn_useless_computed_key(chstate, node, symbol)
   chstate:warn_range("701", node, {
      name = symbol,
   })
end

local keywords = utils.array_to_set({
   "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto", "if", "in",
   "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"})

local function check_computed_key(chstate, key_node)
   if key_node.tag == "String" then
      local symbol = key_node[1]
      if (key_node.end_offset - key_node.offset + 1) > #symbol then
         if string.gmatch(symbol, "[%a_][%a%w_]*$")() == symbol and not keywords[symbol] then
            warn_useless_computed_key(chstate, key_node, symbol)
         end
      end
   end
end

local function check_nodes(chstate, nodes)
   for _, node in ipairs(nodes) do
      if type(node) == "table" then
         if node.tag == "Pair" then
            local key_node = node[1]
            check_computed_key(chstate, key_node)
         elseif node.tag == "Index" then
            local key_node = node[2]
            check_computed_key(chstate, key_node)
         end

         check_nodes(chstate, node)
      end
   end
end

function stage.run(chstate)
   check_nodes(chstate, chstate.ast)
end

return stage
