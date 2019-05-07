local errno = require "sys.errno"
local socket = require "sys.socket"
local ieee80211 = require "sys.ieee80211"

local s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0);
assert(s >= 0)

local wifi = ieee80211.new(s, "iwn0")

--wifi:scan()

local n, t = wifi:nodes()
if n == -1 then
	error(errno())
end

for k,v in ipairs(t) do
	print(k, v.nwid, v.bssid, v.rssi)
end

print("connecting...")

if wifi:connect("Freedom", "therewasnopassword") == -1 then
	error(errno())
end

