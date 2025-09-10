-- lua/coverage_signs.lua
local M = {}

-- path to coverage json
local coverage_file = "./coverage/coverage-final.json"
local coverage_data = {}

-- load coverage file
local function load_coverage()
  local f = io.open(coverage_file, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, json = pcall(vim.fn.json_decode, content)
  if not ok then return {} end
  return json
end

-- choose highlight group based on hits
local function highlight_for_count(count)
  if count == 0 then return "CoverageRed"
  elseif count < 5 then return "CoverageOrange"
  elseif count < 20 then return "CoverageYellow"
  else return "CoverageGreen" end
end

-- define signs for a given buffer
local function place_signs(bufnr, file_coverage)
  -- clear old signs
  vim.fn.sign_unplace("coverage", { buffer = bufnr })

  -- iterate over statementMap
  for id, stmt in pairs(file_coverage.statementMap or {}) do
    local count = file_coverage.s[tostring(id)] or 0
    local hl = highlight_for_count(count)
    local line = stmt.start.line

    vim.fn.sign_place(
      0,
      "coverage",
      "CoverageSign" .. hl,
      bufnr,
      { lnum = line, priority = 10 }
    )
  end
end

-- setup signs and highlight groups
local function define_signs()
  local signs = {
    { name = "CoverageSignCoverageRed", text = "●", texthl = "CoverageRed" },
    { name = "CoverageSignCoverageOrange", text = "●", texthl = "CoverageOrange" },
    { name = "CoverageSignCoverageYellow", text = "●", texthl = "CoverageYellow" },
    { name = "CoverageSignCoverageGreen", text = "●", texthl = "CoverageGreen" },
  }
  for _, s in ipairs(signs) do
    vim.fn.sign_define(s.name, { text = s.text, texthl = s.texthl })
  end

  vim.api.nvim_set_hl(0, "CoverageRed", { fg = "#ff5555" })
  vim.api.nvim_set_hl(0, "CoverageOrange", { fg = "#ff9900" })
  vim.api.nvim_set_hl(0, "CoverageYellow", { fg = "#f1fa8c" })
  vim.api.nvim_set_hl(0, "CoverageGreen", { fg = "#50fa7b" })
end

-- public API: refresh signs for current buffer
function M.refresh()
  coverage_data = load_coverage()
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)

  -- try to find file key relative to cwd
  for path, data in pairs(coverage_data) do
    if filename:sub(-#path) == path then
      place_signs(bufnr, data)
      return
    end
  end
end

function M.setup()
  define_signs()
  -- auto refresh on BufEnter
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function() M.refresh() end
  })
end

return M
