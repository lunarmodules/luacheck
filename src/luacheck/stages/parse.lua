local decoder = require "luacheck.decoder"
local parser = require "luacheck.parser"

local stage = {}

stage.warnings = {
   ["641"] = {
      message_format = "line contains multiple statements", fields = {}
   },
}

function stage.run(chstate)
   chstate.source = decoder.decode(chstate.source_bytes)
   chstate.line_offsets = {}
   chstate.line_lengths = {}
   local ast, comments, code_lines, line_endings, useless_semicolons = parser.parse(
      chstate.source, chstate.line_offsets, chstate.line_lengths)
   local lines_with_statements = {}
   for _, node in ipairs(ast) do
      if not lines_with_statements[node.line] then
         lines_with_statements[node.line] = true
      else
         chstate:warn_range("641", node)
      end
   end
   chstate.ast = ast
   chstate.comments = comments
   chstate.code_lines = code_lines
   chstate.line_endings = line_endings
   chstate.useless_semicolons = useless_semicolons
end

return stage
