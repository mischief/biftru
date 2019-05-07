local ffi = require "ffi"
local bit = require "bit"

ffi.cdef[[
/* junk goes in the junk drawer */
int ioctl(int fd, unsigned long request, ...);
]]

local M = {}

M.ioctl = ffi.C.ioctl

local VOID =	0x20000000
local OUT =	0x40000000
local IN =	0x80000000

local function IOC(inout, group, num, len)
	if type(group) == "string" then
		group = group:byte()
	end
	local ioc = bit.bor(inout, bit.lshift(len, 16), bit.lshift(group, 8), num)
	return ffi.cast("uint32_t", ioc)
end

function M.IO(g, n) return IOC(VOID, g, n, 0) end
function M.IOR(g, n, sz) return IOC(OUT, g, n, sz) end
function M.IOW(g, n, sz) return IOC(IN, g, n, sz) end
function M.IOWR(g, n, sz) return IOC(bit.bor(IN, OUT), g, n, sz) end

return M

