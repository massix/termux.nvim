local M = {}
local Job = require("plenary.job")

M.setup_commands = function()
	vim.api.nvim_create_user_command("TermuxHoldWakeLock", function()
		require("termux.modules.wakelock").wakelock(true)
	end, { nargs = 0, desc = "Hold the WakeLock", force = true })

	vim.api.nvim_create_user_command("TermuxReleaseWakeLock", function()
		require("termux.modules.wakelock").wakelock(false)
	end, { nargs = 0, desc = "Release the WakeLock", force = true })

	vim.api.nvim_create_user_command("TermuxWakeLock", function(opts)
		local wl = require("termux.modules.wakelock")
		if opts.fargs[1] == "hold" then
			wl.wakelock(true)
		elseif opts.fargs[1] == "release" then
			wl.wakelock(false)
		end
	end, {
		nargs = 1,
		complete = function()
			return { "hold", "release" }
		end,
		desc = "Interact with WakeLock functionality in Termux",
		force = true,
	})
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
