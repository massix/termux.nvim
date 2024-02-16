local M = {}
local Job = require("plenary.job")

M.setup_commands = function()
	vim.api.nvim_create_user_command("TermuxHoldWakeLock", function()
		require("termux.modules.wakelock").wakelock(true)
	end, {})

	vim.api.nvim_create_user_command("TermuxReleaseWakeLock", function()
		require("termux.modules.wakelock").wakelock(false)
	end, {})
end

---Modify the current status of the lock
---@param hold boolean # true to hold the wl
M.wakelock = function(hold)
	Job:new({
		command = hold and "termux-wake-lock" or "termux-wake-unlock",
		args = {},
		on_exit = function()
			vim.notify((hold and "Holding" or "Released") .. " wake lock")
		end,
	}):start()
end

return M
