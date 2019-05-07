local ffi = require "ffi"
local iface = require "iface"
local socket = require "socket"

local ioctl = require "ioctl"

local s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0);
assert(s >= 0)

if not pcall(function()
end) then
	print("errno=", ffi.errno())
end

	--local flags = iface.getflags(s, "vether1")
	--print(string.format("%X", tonumber(flags)))

	iface.setflags(s, "vether1", -iface.IFF.UP)

