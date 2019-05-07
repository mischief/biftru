local ffi = require "ffi"

ffi.cdef[[
int strerror_r(int errnum, char *strerrbuf, size_t buflen);
]]

local function strerror(e)
	local sz = 128
	local buf = ffi.new("char [?]", 128)
	ffi.C.strerror_r(e.errno, buf, sz)
	return ffi.string(buf)
end

local function errno(e)
	local t = {
		errno = e or ffi.errno(),
	}

	local mt = {
		__tostring = strerror,
	}

	return setmetatable(t, mt)
end

local M = {
	EPERM = 1,
	ENOENT = 2,
	ESRCH = 3,
	EINTR = 4,
	EIO = 5,
	ENXIO = 6,
	E2BIG = 7,
	ENOEXEC = 8,
	EBADF = 9,
	ECHILD = 10,
	EDEADLK = 11,
	ENOMEM = 12,
	EACCES = 13,
	EFAULT = 14,
	ENOTBLK = 15,
	EBUSY = 16,
	EEXIST = 17,
	EXDEV = 18,
	ENODEV = 19,
	ENOTDIR = 20,
	EISDIR = 21,
	EINVAL = 22,
	ENFILE = 23,
	EMFILE = 24,
	ENOTTY = 25,
}

local emt = {
	__call = function(_, e) return errno(e) end
}

return setmetatable(M, emt)

