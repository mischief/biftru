local ffi = require "ffi"
local bit = require "bit"
local errno = require "sys.errno"
local socket = require "sys.socket"
local ioctl = require "sys.ioctl"

ffi.cdef[[
enum {
	IFNAMSIZ = 16,
};

struct ifreq {
	char name[IFNAMSIZ];
	union {
		struct  sockaddr	addr;
                struct  sockaddr	dstaddr;
                struct  sockaddr	broadaddr;
                unsigned short		flags;
                int			metric;
                int64_t			vnetid;
                uint64_t		media;
                void*			data;
                unsigned int		index;
        } ifru;
};

struct if_data {
	uint8_t type;
	uint8_t addrlen;
	uint8_t hdrlen;
	uint8_t link_state;
	uint32_t mtu;
	uint32_t metric;
	uint32_t rdomain;
	uint32_t baudrate;
	uint64_t ipackets;
	uint64_t ierrors;
	uint64_t opackets;
	uint64_t oerrors;
	uint64_t collisions;
	uint64_t ibytes;
	uint64_t obytes;
	uint64_t imcasts;
	uint64_t omcasts;
	uint64_t iqdrops;
	uint64_t oqdrops;
	uint64_t noproto;
	uint32_t capabilities;
	struct timeval lastchange;
};

char *if_indextoname(unsigned int ifindex, char *ifname);
]]

local M = {
	ifreq = ffi.typeof("struct ifreq"),
	ifdata = ffi.typeof("struct if_data")
}

M.LINK_STATE = {
	UNKNOWN = 0,
	INVALID = 1,
	DOWN = 2,
	KALIVE_DOWN = 3,
	UP = 4,
	HALF_DUPLEX = 5,
	FULL_DUPLEX = 6,
}

M.IFF = {
	UP = 1,
}

local SIOCSIFFLAGS = ioctl.IOW("i", 16, ffi.sizeof(M.ifreq))
local SIOCGIFFLAGS = ioctl.IOWR("i", 17, ffi.sizeof(M.ifreq))
local SIOCGIFDATA = ioctl.IOWR("i", 27, ffi.sizeof(M.ifreq))

function M.getflags(fd, interface)
	local ifreq = M.ifreq()
	ffi.copy(ifreq.name, interface)
	local rv = ioctl.ioctl(fd, ffi.new("uint32_t", SIOCGIFFLAGS), ifreq)
	if rv == -1 then
		error("SIOCGIFFLAGS="..tostring(ffi.errno()))
	end
	return ifreq.ifru.flags
end

function M.setflags(fd, interface, flag)
	local flags = M.getflags(fd, interface)
	local ifreq = M.ifreq()
	ffi.copy(ifreq.name, interface)

	if flag < 0 then
		flag = -flag
		ifreq.ifru.flags = bit.band(flags, bit.bnot(flag))
	else
		ifreq.ifru.flags = bit.bor(flags, flag)
	end

	local rv = ioctl.ioctl(fd, SIOCSIFFLAGS, ifreq)
	if rv == -1 then
		error("SIOCSIFFLAGS: ".. errno.errno())
	end
	return ifreq.ifru.flags
end

function M.getifdata(fd, interface)
	local ifreq = M.ifreq()
	ffi.copy(ifreq.name, interface)
	local ifdata = M.ifdata()
	ifreq.ifru.data = ifdata

	local rv = ioctl.ioctl(fd, SIOCGIFDATA, ifreq)
	if rv == -1 then
		error("SIOCGIFDATA: ".. errno.errno())
	end

	return ifdata
end

function M.indextoname(index)
	local buf = ffi.new("char[?]", 16)
	if ffi.C.if_indextoname(index, buf) == nil then
		return
	end

	return ffi.string(buf)
end

return M

