local ffi = require "ffi"
local route = require "route"
local iface = require "iface"
local unistd = require "unistd"
local signal = require "signal"
local event = require "event"

local function statename(state)
	for k,v in pairs(iface.LINK_STATE) do
		if v == state then
			return k
		end
	end

	return "UNKNOWN"
end

local r = route.new(route.RTM.IFINFO, route.RTM.IFANNOUNCE)
assert(r)
local ev = event.new()
assert(ev)

local stdin

local function cb(fd, what, void)
	local rv, msg = r:getmsg()
	if rv == -1 then
		error("-1")
	end
	if msg ~= nil then
		local ifc = iface.indextoname(msg.index)
		if msg.type == route.RTM.IFINFO then
			print(rv, ifc, "link="..statename(msg.data.link_state))
		--elseif msg.type == route.RTM.IFANNOUNCE then
		--	print(msg.name, ifanstring(msg.what))
		end
		ev:add(stdin)
	end
end

local function sig(num, what, void)
	print("caught signal", num)
	ev:loopbreak()
end

stdin = ev:event(r.fd, event.READ, cb)
ev:add(stdin)

local sigint = ev:signal(signal.INT, sig)
ev:add(sigint)
local sigterm = ev:signal(signal.TERM, sig)
ev:add(sigterm)

ev:dispatch()

print("exiting")

