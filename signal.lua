local ffi = require "ffi"

ffi.cdef[[
void (*signal(int, void (*)(int)))(int);
]]

local M = {}

M.INT = 3
M.TERM = 15

-- https://www.freelists.org/post/luajit/CtrlC-handling-and-xpcall-with-jit-off,3
function M.reset()
	ffi.C.signal(M.INT, ffi.cast("void(*)(int)", 0))
end

-- broken. sigh.
--M.reset()

return M

