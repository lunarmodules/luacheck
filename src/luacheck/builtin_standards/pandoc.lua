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
      "pandoc", "lpeg", "re",
   },
}

-- https://pandoc.org/lua-filters.html
local filter = {
   read_globals = {
      "FORMAT", "PANDOC_READER_OPTIONS", "PANDOC_WRITER_OPTIONS", "PANDOC_VERSION", "PANDOC_API_VERSION",
      "PANDOC_SCRIPT_FILE", "PANDOC_STATE",
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

-- https://pandoc.org/custom-readers.html
local reader = {
   globals = {
      "Reader", "Extensions", "ByteStringReader"
   },
}

-- https://pandoc.org/custom-writers.html
local writer = {
   globals = {
      "PANDOC_DOCUMENT", "Writer", "Extensions", "Doc", "Template",
      "Blocksep", "ByteStringWriter", "CaptionedImage", "DisplayMath", "DoubleQuoted", "InlineMath", "SingleQuoted",
   },
}

local variants = {
    pandoc = { globals = combine(common, filter, reader, writer) },
    filter = { globals = combine(common, filter) },
    reader = { globals = combine(common, reader) },
    writer = { globals = combine(common, writer) },
}

return variants
