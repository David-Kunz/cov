local M = {}

local coverage_file = "./coverage/coverage-final.json"
local coverage_data = {}
local enabled = true

local function load_coverage()
  local f = io.open(coverage_file, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, json = pcall(vim.fn.json_decode, content)
  if not ok then return {} end
  return json
end

local function define_highlights()
  vim.api.nvim_set_hl(0, "CoverageRed", { fg = "#ff5555" })
  vim.api.nvim_set_hl(0, "CoverageYellow", { fg = "#f1fa8c" })
  vim.api.nvim_set_hl(0, "CoverageGreen", { fg = "#50fa7b" })

  -- full-height block █
  vim.fn.sign_define("CoverageRed",    { text = "█", texthl = "CoverageRed" })
  vim.fn.sign_define("CoverageYellow", { text = "█", texthl = "CoverageYellow" })
  vim.fn.sign_define("CoverageGreen",  { text = "█", texthl = "CoverageGreen" })
end

local function place_signs(bufnr, file_coverage)
  vim.fn.sign_unplace("coverage", { buffer = bufnr })

  if not enabled then return end

  for id, stmt in pairs(file_coverage.statementMap or {}) do
    local count = file_coverage.s[tostring(id)] or 0
    local hl
    if count == 0 then
      hl = "CoverageRed"
    elseif count == 1 then
      hl = "CoverageYellow"
    else
      hl = "CoverageGreen"
    end

    local line = stmt.start.line
    vim.fn.sign_place(
      0,
      "coverage",
      hl,
      bufnr,
      { lnum = line, priority = 10 }
    )
  end
end

function M.refresh()
  if not enabled then
    vim.fn.sign_unplace("coverage")
    return
  end

  coverage_data = load_coverage()
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)

  for path, data in pairs(coverage_data) do
    if filename:sub(-#path) == path then
      place_signs(bufnr, data)
      return
    end
  end
end

function M.toggle()
  enabled = not enabled
  if enabled then
    M.refresh()
    vim.notify("Coverage enabled", vim.log.levels.INFO)
  else
    vim.fn.sign_unplace("coverage")
    vim.notify("Coverage disabled", vim.log.levels.INFO)
  end
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function() M.refresh() end
  })
  vim.api.nvim_create_user_command("CoverageRefresh", function() M.refresh() end, {})
  vim.api.nvim_create_user_command("CoverageToggle", function() M.toggle() end, {})
end

return M
