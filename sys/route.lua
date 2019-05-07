local ffi = require "ffi"
local bit = require "bit"
local unistd = require "sys.unistd"
local socket = require "sys.socket"
local iface = require "sys.iface"

ffi.cdef[[
struct rt_metrics {
	uint64_t pksent;
	int64_t expore;
	uint32_t locks;
	uint32_t mtu;
	uint32_t refcnt;
	uint32_t hopcount;
	uint32_t recvpipe;
	uint32_t sendpipe;
	uint32_t ssthresh;
	uint32_t rtt;
	uint32_t rttvar;
	uint32_t pad;
};

struct rt_msghdr {
	uint16_t msglen;
	uint8_t version;
	uint8_t type;
	uint16_t hdrlen;
	uint16_t index;
	uint16_t tableid;
	uint8_t priority;
	uint8_t mpls;
	int32_t addrs;
	int32_t flags;
	int32_t fmask;
	int32_t pid;
	int32_t seq;
	int32_t errno;
	uint32_t inits;
	struct rt_metrics rmx;
};

struct if_msghdr {
	uint16_t msglen;
	uint8_t version;
	uint8_t type;
	uint16_t hdrlen;
	uint16_t index;
	uint16_t tableid;
	uint8_t pad1;
	uint8_t pad2;
	int32_t addrs;
	int32_t flags;
	int32_t xflags;
	struct if_data data;
};

struct ifa_announcemsghdr {
	uint16_t msglen;
	uint8_t version;
	uint8_t type;
	uint16_t hdrlen;
	uint16_t index;
	uint16_t what;
	char name[16];
};
]]

local ROUTE_MSGFILTER = 1

local RTM_VERSION = 5

local RTM = {
	ADD =		0x1,
	DELETE =	0x2,
	CHANGE =	0x3,
	GET =		0x4,
	LOSING =	0x5,
	REDIRECT =	0x6,
	MISS =		0x7,
	LOCK =		0x8,
	RESOLVE = 	0xb,
	NEWADDR =	0xc,
	DELADDR =	0xd,
	IFINFO =	0xe,
	IFANNOUNCE =	0xf,
	DESYNC = 	0x10,
}

local IFAN = {
	ARRIVAL = 0,
	DEPARTURE = 1,
}

local rt_msghdr = ffi.typeof("struct rt_msghdr*")
local if_msghdr = ffi.typeof("struct if_msghdr*")
local ifa_announcemsghdr = ffi.typeof("struct ifa_announcemsghdr*")


local ctab = {
--	RTM.NEWADDR =		ifa_msghdr,
--	RTM.DELADDR =		ifa_msghdr,
	[RTM.IFINFO] =		if_msghdr,
	[RTM.IFANNOUNCE] =	ifa_announcemsghdr,
}

local route = {}

function route.getmsg(r)
	local sz = 2048
	local buf = ffi.new("char[?]", sz)
	local rv = socket.read(r.fd, buf, sz)
	if rv == -1 then
		return rv, nil
	end
	local msg = ffi.cast(rt_msghdr, buf)
	if msg.version ~= RTM_VERSION then
		return 0, nil
	end
	ct = ctab[msg.type]
	if ct == nil then
		ct = rt_msghdr
	end
	return rv, ffi.cast(ct, buf)
end

local routemt = {
	__index = route
}

local function route_filter(...)
	local rv = 0
	local t = {...}
	for k, v in ipairs(t) do
		rv = bit.bor(rv, bit.lshift(1, v))
	end
	return rv
end

local function new(...)
	local fd = socket.socket(socket.AF_ROUTE, socket.SOCK_RAW, socket.AF_UNSPEC)
	if fd == -1 then
		return nil
	end

	local ct = ffi.typeof("unsigned int")
	local sz = ffi.sizeof(ct)

	local rtfilter = ct(route_filter(...))

	local opt = ffi.new("unsigned int[1]")
	opt[0] = rtfilter
	if socket.setsockopt(fd, socket.AF_ROUTE, ROUTE_MSGFILTER, opt, sz) == -1 then
		socket.close(fd)
		return nil
	end
	
	local t = {
		fd = fd,
	}

	return setmetatable(t, routemt)
end

return {
	RTM = RTM,
	IFAN = IFAN,

	new = new,
}

