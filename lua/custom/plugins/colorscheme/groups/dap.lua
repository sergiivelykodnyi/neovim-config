-- nvim-dap and nvim-dap-ui. The debug plugin is off by default in this config,
-- so these groups are applied only when it is turned on.
local M = {}

M.detect = { 'dap', 'dapui' }

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    DapBreakpoint = { fg = p.red },
    DapBreakpointCondition = { fg = p.orange },
    DapBreakpointRejected = { fg = p.comment },
    DapLogPoint = { fg = p.orange },
    DapStopped = { fg = p.green },
    DapStoppedLine = { bg = p.bg_line },

    DapUIScope = { fg = p.blue },
    DapUIType = { fg = p.yellow },
    DapUIValue = { fg = p.fg },
    DapUIModifiedValue = { fg = p.orange },
    DapUIDecoration = { fg = p.blue },
    DapUIThread = { fg = p.green },
    DapUIStoppedThread = { fg = p.blue },
    DapUIFrameName = { fg = p.fg },
    DapUISource = { fg = p.purple },
    DapUILineNumber = { fg = p.line_nr },
    DapUIFloatBorder = { fg = p.border, bg = p.bg_float },
    DapUIWatchesEmpty = { fg = p.comment },
    DapUIWatchesValue = { fg = p.green },
    DapUIWatchesError = { fg = p.diag_error },
    DapUIBreakpointsPath = { fg = p.blue },
    DapUIBreakpointsInfo = { fg = p.green },
    DapUIBreakpointsCurrentLine = { fg = p.green },
    DapUIBreakpointsLine = { fg = p.line_nr },
    DapUIBreakpointsDisabledLine = { fg = p.comment },
    DapUICurrentFrameName = { fg = p.green },
    DapUIStepOver = { fg = p.blue },
    DapUIStepInto = { fg = p.blue },
    DapUIStepBack = { fg = p.blue },
    DapUIStepOut = { fg = p.blue },
    DapUIStop = { fg = p.red },
    DapUIPlayPause = { fg = p.green },
    DapUIRestart = { fg = p.green },
    DapUIUnavailable = { fg = p.comment },
    DapUIWinSelect = { fg = p.blue },
    DapUIEndofBuffer = { fg = p.bg },
  }
end

return M
