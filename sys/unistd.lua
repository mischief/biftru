local ffi = require("ffi")

ffi.cdef[[
typedef intptr_t ssize_t;
typedef int32_t pid_t;

struct timeval {
	int64_t tv_sec;
	long tv_usec;
};

pid_t fork(void);
int close(int d);
unsigned sleep(unsigned s);
ssize_t read(int d, void *buf, size_t nbytes);
]]

local function timeval(ms)
	local sec = ms/1000
	local usec = (ms % 1000) * 1000
	return ffi.new("struct timeval", sec, usec)
end

return {
	timeval = timeval,

	fork = ffi.C.fork,
	close = ffi.C.close,
	sleep = ffi.C.sleep,
	read = ffi.C.read,
}

