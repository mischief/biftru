local ffi = require "ffi"
local ioctl = require "sys.ioctl"
local iface = require "sys.iface"
local crypto = require "sys.crypto"

-- ieee80211.h, ieee80211_ioctl.h
ffi.cdef[[
enum {
	IEEE80211_ADDR_LEN = 6,
	IEEE80211_NWID_LEN = 32,
	IEEE80211_RATE_MAXSIZE = 15,
};

struct ieee80211_nwid {
	uint8_t	len;
	uint8_t	nwid[IEEE80211_NWID_LEN];
};

struct ieee80211_wpapsk {
	char	name[16];
	int	enabled;
	uint8_t	psk[32];
};

struct ieee80211_wpaparams {
	char		name[16];
	int		enabled;
	unsigned int	protos;
	unsigned int	akms;
	unsigned int	ciphers;
	unsigned int	groupcipher;
};

struct ieee80211_nodereq {
	char		ifname[16];
	uint8_t		macaddr[IEEE80211_ADDR_LEN];
	uint8_t		bssid[IEEE80211_ADDR_LEN];
	uint8_t		nwid_len;
	uint8_t		nwid[IEEE80211_NWID_LEN];
	uint16_t	channel;
	uint16_t	chan_flags;
	uint8_t		nrates;
	uint8_t		rates[IEEE80211_RATE_MAXSIZE];
	int8_t		rssi;
	int8_t		max_rssi;
	uint8_t		tstamp[8];
	uint16_t	intval;
	uint16_t	capinfo;
	uint8_t		erp;
	uint8_t		pwrsave;
	uint16_t	associd;
	uint16_t	txseq;
	uint16_t	rxseq;
	uint32_t	fails;
	uint32_t	inact;
	uint8_t		txrate;
	uint16_t	state;
	unsigned int	rsnprotos;
	unsigned int	rsnciphers;
	unsigned int	rsnakms;
	uint8_t		flags;
	uint16_t	htcaps;
	uint8_t		rxmcs[10];
	uint16_t	max_rxrate;
	uint8_t		tx_mcs_set;
	uint8_t		txmcs;
};

struct ieee80211_nodereq_all {
	char				ifname[16];
	int				nodes;
	size_t				size;
	struct ieee80211_nodereq*	node;
	uint8_t 			flags;
};
]]

local NR = ffi.typeof("struct ieee80211_nodereq")
local NRA = ffi.typeof("struct ieee80211_nodereq_all")
local WPAPSK = ffi.typeof("struct ieee80211_wpapsk")
local WPAPARAMS = ffi.typeof("struct ieee80211_wpaparams")

local SCAN = ioctl.IOW("i", 210, ffi.sizeof(iface.ifreq))
local ALLNODES = ioctl.IOWR("i", 214, ffi.sizeof(NRA))
local SETNWID = ioctl.IOWR("i", 230, ffi.sizeof(iface.ifreq))
local SETWPAPSK = ioctl.IOW("i", 245, ffi.sizeof(WPAPSK))
local SETWPAPARAMS = ioctl.IOW("i", 247, ffi.sizeof(WPAPARAMS))
local GETWPAPARAMS = ioctl.IOWR("i", 248, ffi.sizeof(WPAPARAMS))

local wifi = {}

function wifi:scan()
	-- ensure UP
	local status, err = pcall(iface.setflags, self.fd, self.interface, iface.IFF.UP)
	if not status then
		return -1
	end

	-- initiate scan
	local ifreq = iface.ifreq()
	ffi.copy(ifreq.name, self.interface)
	return ioctl.ioctl(self.fd, SCAN, ifreq)
end

function wifi:nodes(nreq)
	nreq = nreq or 128
	local nra = NRA()
	local nr = ffi.new("struct ieee80211_nodereq[?]", nreq)

	nra.node = nr
	nra.size = nreq * ffi.sizeof(NR)
	ffi.copy(nra.ifname, self.interface)

	local rv = ioctl.ioctl(self.fd, ALLNODES, nra)
	if rv == -1 then
		return -1, nil
	end

	local nodes = {}

	for i=0, nra.nodes-1 do
		local cb = nr[i].bssid
		local bssid = string.format("%02X:%02X:%02X:%02X:%02X:%02X",
			cb[0], cb[1], cb[2], cb[3], cb[4], cb[5])
		local n = {
			bssid = bssid,
			nwid = ffi.string(nr[i].nwid, nr[i].nwid_len),
			rssi = nr[i].rssi,
		}
		table.insert(nodes, n)
	end

	-- lower RSSI is better
	local rssicmp = function(a, b)
		return a.rssi > b.rssi
	end

	table.sort(nodes, rssicmp)

	return nra.nodes, nodes
end

function wifi:connect(nwid, key)
	local ifreq = iface.ifreq()
	ffi.copy(ifreq.name, self.interface)
	local nw = ffi.new("struct ieee80211_nwid")
	ffi.fill(nw.nwid, ffi.C.IEEE80211_NWID_LEN)
	nw.len = math.min(nwid:len(), ffi.C.IEEE80211_NWID_LEN)
	ffi.copy(nw.nwid, nwid, nw.len)
	ifreq.ifru.data = ffi.cast("void*", nw)

	local rv = ioctl.ioctl(self.fd, SETNWID, ifreq)
	if rv == -1 then
		return -1
	end

	if not key then
		return 0
	end

	local wpakey = crypto.pkcs5_pbkdf2(key, nwid, 4096)
	local wpapsk = WPAPSK()
	ffi.copy(wpapsk.name, self.interface)
	wpapsk.enabled = 1
	ffi.copy(wpapsk.psk, wpakey, wpakey:len())
	
	rv = ioctl.ioctl(self.fd, SETWPAPSK, wpapsk)
	if rv == -1 then
		return -1
	end

	local wpaparams = WPAPARAMS()
	ffi.copy(wpaparams.name, self.interface)
	rv = ioctl.ioctl(self.fd, GETWPAPARAMS, wpaparams)
	if rv == -1 then
		return -1
	end

	wpaparams.enabled = 1
	rv = ioctl.ioctl(self.fd, SETWPAPARAMS, wpaparams)
	if rv == -1 then
		return -1
	end

	return 0
end

local wifimt = {
	__index = wifi
}

local M = {}

function M.new(socket, interface)
	return setmetatable({fd=socket, interface=interface}, wifimt)
end

return M

