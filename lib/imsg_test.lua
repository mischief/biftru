local os = require "os"
local ffi = require "ffi"
local ix = require "imsg"

-- luajit ffi declarations
ffi.cdef[[
typedef int32_t pid_t;

unsigned int sleep(unsigned int s);
pid_t fork(void);
int close(int d);
char *strerror(int n);
int socketpair(int d, int type, int protocol, int sv[2]);
]]

local unistd = {
	close = ffi.C.close,
	fork = ffi.C.fork,
	socketpair = ffi.C.socketpair,
}

local AF_UNIX = 1
local SOCK_STREAM = 1
local AF_UNSPEC = 1

err = function(what)
	error(what .. ": " .. ffi.C.strerror(ffi.errno()))
end

-- example imsg program
child_main = function(b)
	local imsg = ix.imsg(b)
	while true do
		local n = imsg:read()
		print("child", "n=", n)
		if n == 0 then
			err = ffi.errno()
			if err ~= 35 then
				break
			end
		elseif n == -1 then
			print("read==-1")
			return 0
		elseif n > 0 then
			while true do
				local n, msg = imsg:get()
				if n == 0 then
					break
				end
				if msg.hdr.type == 1 then
					local d = ffi.cast("int32_t*", msg.data)
					print(string.format("%d", d[0]))
				end
			end
		end

	end
	return 0
end

parent_main = function(b)
	local imsg = ix.imsg(b)
	local data = ffi.new("int32_t[1]")
	for i = 42, 45 do
		data[0] = i
		--print("compose.. ", i)
		if imsg:compose(1, 0, data, 4) == -1 then
			err("compose")
		end
		print("flush..", imsg:flush())
		ffi.C.sleep(1)
	end
	unistd.close(b)
	return 0
end

local fds = ffi.new("int[2]")
if unistd.socketpair(AF_UNIX, SOCK_STREAM, AF_UNSPEC, fds) == -1 then
	err("socketpair")
end

local pid = unistd.fork()
if fork == -1 then
	err("fork")
end

if pid == 0 then
	-- child
	unistd.close(fds[0])
	os.exit(child_main(fds[1]))
end

-- parent
unistd.close(fds[1])
os.exit(parent_main(fds[0]))

