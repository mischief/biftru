local route = require "route"
local iface = require "iface"
local ev = require "tedu/event"

local r = route.new(route.RTM.IFINFO, route.RTM.IFANNOUNCE)
assert(r)

local function statename(state)
	for k,v in pairs(iface.LINK_STATE) do
		if v == state then
			return k
		end
	end

	return "UNKNOWN"
end

local function ifanstring(what)
	if what == route.IFAN.ARRIVAL then
		return "arrival"
	end

	return "departure"
end

local function printmsg(...)
	while true do
		coroutine.yield()
		local rv, msg = r:getmsg()
		if rv == -1 then
			error("-1")
		end
		if msg ~= nil then
			local ifc = iface.indextoname(msg.index)
			if msg.type == route.RTM.IFINFO then
				print(ifc, "link="..statename(msg.data.link_state))
			elseif msg.type == route.RTM.IFANNOUNCE then
				print(msg.name, ifanstring(msg.what))
			end
		end
	end
end

ev.add(printmsg, "read", r.fd)
ev.go()

