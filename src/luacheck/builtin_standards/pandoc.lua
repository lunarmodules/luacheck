local add_std_table = require "luacheck.standards".add_std_table

local function combine(...)
   local res = {}
   for _, def in ipairs({...}) do
      add_std_table(res, def)
   end
   return res.fields
end

local common = {
   read_globals = {
      "PANDOC_VERSION", "PANDOC_API_VERSION", "PANDOC_STATE",
      "pandoc", "lpeg", "re",
   },
   globals = {
      -- document types
      "Inlines", "Inline", "Blocks", "Block", "Meta", "Pandoc",
      -- inline types
      "Cite", "Code", "Emph", "Image", "LineBreak", "Link", "Math", "Note", "Quoted", "RawInline", "SmallCaps",
      "SoftBreak", "Space", "Span", "Str", "Strikeout", "Strong", "Subscript", "Superscript", "Underline",
      -- block types
      "BlockQuote", "BulletList", "CodeBlock", "DefinitionList", "Div", "Figure", "Header", "HorizontalRule",
      "LineBlock", "OrderedList", "Para", "Plain", "RawBlock", "Table",
   },
}

-- https://pandoc.org/lua-filters.html
local filter = {
   read_globals = {
      "FORMAT", "PANDOC_READER_OPTIONS", "PANDOC_WRITER_OPTIONS", "PANDOC_SCRIPT_FILE"
   },
}

-- https://pandoc.org/custom-readers.html
-- https://pandoc.org/custom-writers.html
local custom = {
   globals = {
      -- custom scope
      "PANDOC_DOCUMENT",
      "ByteStringReader", "ByteStringWriter", "Doc", "Extensions", "Reader", "Template", "Writer",
      -- extra types applicable to readers/writers
      "Blocksep", "CaptionedImage", "DisplayMath", "DoubleQuoted", "InlineMath", "SingleQuoted",
   },
}

local script = {
   globals = {
   }
}

local variants = {
    pandoc = { globals = combine(common, filter, custom, script) },
    filter = { globals = combine(common, filter) },
    custom = { globals = combine(common, custom) },
    script = { globals = combine(common, script) },
}

return variants
