-- nvim-dap and nvim-dap-ui: breakpoints, stopped line, debug panels.
local M = {}

M.detect = { 'dap', 'dapui' }

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    -- nvim-dap signs
    DapBreakpoint = { fg = p.red },
    DapBreakpointCondition = { fg = p.orange },
    DapBreakpointRejected = { fg = p.comment },
    DapLogPoint = { fg = p.blue },
    DapStopped = { fg = p.green },
    DapStoppedLine = { bg = p.diff_add_bg },

    -- nvim-dap-ui panels
    DapUIScope = { fg = p.blue },
    DapUIType = { fg = p.teal },
    DapUIValue = { fg = p.fg },
    DapUIModifiedValue = { fg = p.blue, bold = true },
    DapUIDecoration = { fg = p.blue },
    DapUIThread = { fg = p.green },
    DapUIStoppedThread = { fg = p.blue },
    DapUIFrameName = { fg = p.fg },
    DapUISource = { fg = p.purple },
    DapUILineNumber = { fg = p.blue },
    DapUIFloatBorder = { fg = p.border },
    DapUIWatchesEmpty = { fg = p.red },
    DapUIWatchesValue = { fg = p.green },
    DapUIWatchesError = { fg = p.red },
    DapUIBreakpointsPath = { fg = p.blue },
    DapUIBreakpointsInfo = { fg = p.green },
    DapUIBreakpointsCurrentLine = { fg = p.green, bold = true },
    DapUIBreakpointsLine = { fg = p.blue },
    DapUIBreakpointsDisabledLine = { fg = p.comment },
    DapUICurrentFrameName = { fg = p.green, bold = true },
    DapUIStepOver = { fg = p.blue },
    DapUIStepInto = { fg = p.blue },
    DapUIStepBack = { fg = p.blue },
    DapUIStepOut = { fg = p.blue },
    DapUIStop = { fg = p.red },
    DapUIPlayPause = { fg = p.green },
    DapUIRestart = { fg = p.green },
    DapUIUnavailable = { fg = p.comment },
    DapUIWinSelect = { fg = p.blue, bold = true },
    DapUIEndofBuffer = { fg = p.bg },
  }
end

return M
