local ffi = require "ffi"
local bit = require "bit"

ffi.cdef[[
void openlog(const char *ident, int logopt, int facility);
void syslog(int priority, const char *message, ...);
]]

local facility = {
	USER = 0x8,
	DAEMON = 0x18,
	LOCAL0 = 0x80,
}

local priority = {
	EMERG = 0,
	ALERT = 1,
	CRIT = 2,
	ERR = 3,
	WARNING = 4,
	NOTICE = 5,
	INFO = 6,
	DEBUG = 7,
}

local log = {}

function log:log(pri, msg)
	if self.isdebug == true then
		print(string.format("%s: %s", self.ident, msg))
	else
		ffi.C.syslog(self.facility, msg)
	end
end

function log:print(msg)
	self:log(priority.INFO, msg)
end

function log:printf(msg, ...)
	self:print(msg:format(...))
end

function log:debug(msg)
	if self.isdebug == true then
		self:log(priority.DEBUG, msg)
	end
end

function log:debugf(msg, ...)
	if self.isdebug == true then
		self:debug(msg:format(...))
	end
end

function log:fatal(msg)
	self:log(priority.CRIT, msg)
	os.exit(1)
end

function log:fatalf(msg, ...)
	self:fatal(msg:format(...))
end

function log:panic(msg, lv)
	local trace = debug.traceback(msg, lv or 2)

	for line in trace:gmatch("[^\r\n]+") do
		self:print(line)
	end

	os.exit(1)
end

function log:panicf(msg, ...)
	self:panic(msg:format(...), 3)
end

local logmt = {
	__index = log,
}

local LOG_PID = 0x1
local LOG_NDELAY = 0x8

local function new(ident, fac, verbose)
	local t = {
		ident = ident,
		facility = fac or facility.USER,
		isverbose = verbose or false,
		isdebug = verbose or false,
	}

	if not t.isdebug then
		ffi.C.openlog(ident, bit.bor(LOG_PID, LOG_NDELAY), t.facility)
	end

	return setmetatable(t, logmt)
end

return {
	facility = facility,

	new = new,
}

