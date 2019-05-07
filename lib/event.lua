local ffi = require "ffi"
local bit = require "bit"
local unistd = require "sys.unistd"

ffi.cdef[[
struct event_base;

struct event {
 struct { struct event *tqe_next; struct event **tqe_prev; } ev_next;
 struct { struct event *tqe_next; struct event **tqe_prev; } ev_active_next;
 struct { struct event *tqe_next; struct event **tqe_prev; } ev_signal_next;
 unsigned int min_heap_idx;

 struct event_base *ev_base;

 int ev_fd;
 short ev_events;
 short ev_ncalls;
 short *ev_pncalls;

 struct timeval ev_timeout;

 int ev_pri;

 void (*ev_callback)(int, short, void *arg);
 void *ev_arg;

 int ev_res;
 int ev_flags;
};

struct event_base *event_init();
int event_dispatch(void);
void event_set(struct event *ev, int fd, short event, void (*fn)(int, short, void *), void *arg);
int event_add(struct event *ev, const struct timeval *tv);
int event_del(struct event *ev);
int event_pending(struct event *ev, short event, struct timeval *tv);
int event_initialized(struct event *ev);
void evtimer_set(struct event *ev, void (*fn)(int, short, void *), void *arg);
void evtimer_add(struct event *ev, const struct timeval *tv);
void evtimer_del(struct event *ev);
int evtimer_pending(struct event *ev, struct timeval *tv);
int evtimer_initialized(struct event *ev);
void signal_set(struct event *ev, int signal, void (*fn)(int, short, void *), void *arg);
void signal_add(struct event *ev, const struct timeval *tv);
void signal_del(struct event *ev);
int signal_pending(struct event *ev, struct timeval *tv);
int signal_initialized(struct event *ev);
int event_once(int fd, short event, void (*fn)(int, short, void *), void *arg, const struct timeval *tv);
int event_loop(int flags);
int event_loopexit(const struct timeval *tv);
int event_loopbreak(void);

int event_base_dispatch(struct event_base *base);
int event_base_loop(struct event_base *base, int flags);
int event_base_loopexit(struct event_base *base, const struct timeval *tv);
int event_base_loopbreak(struct event_base *base);
int event_base_set(struct event_base *base, struct event *ev);
int event_base_once(struct event_base *base, int fd, short event, void (*fn)(int, short, void *), void *arg, const struct timeval *tv);
void event_base_free(struct event_base *base);
]]

local lib = assert(ffi.load("event"))

local READ = 0x2
local WRITE = 0x4
local RDWR = 0x6
local SIGNAL = 0x8
local PERSIST = 0x10

local ev = {}

function ev:del()
	return lib.event_del(self.ev)
end

local evb = {}

function evb:event(fd, what, fn)
	local event = ffi.new("struct event")
	lib.event_set(event, fd, what, fn, nil)
	local mt = {
		__index = ev,
	}

	local t = {
		ev = event,
		evb = self,
	}

	return setmetatable(t, mt)
end

function evb:timer(fn)
	return self:event(-1, 0, fn)
end

function evb:signal(sig, fn)
	return self:event(sig, bit.bor(SIGNAL, PERSIST), fn)
end

function evb:add(event, ms)
	lib.event_base_set(self.evb, event.ev)
	if ms ~= nil then
		ms = unistd.timeval(ms)
	end
	lib.event_add(event.ev, ms)
end

function evb:dispatch()
	return lib.event_base_dispatch(self.evb)
end

function evb:loopbreak()
	return lib.event_base_loopbreak(self.evb)
end

local evbmt = {
	__index = evb,
}

local M = {
	-- 'what' argument to ev:event
	READ = READ,
	WRITE = WRITE,
	RDWR = RDWR,
	PERSIST = PERSIST,
}

function M.new()
	local event_base = lib.event_init();
	ffi.gc(event_base, lib.event_base_free)
	local t = {
		evb = event_base,
	}

	return setmetatable(t, evbmt)
end

return M

