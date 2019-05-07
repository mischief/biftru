local ffi = require "ffi"

ffi.cdef[[
typedef uint32_t socklen_t;
typedef intptr_t ssize_t;

struct sockaddr {
	uint8_t len;
	uint8_t family;
	char data[14];
};

int close(int d);
ssize_t read(int d, void *buf, size_t nbytes);
int socket(int domain, int type, int protocol);
int socketpair(int domain, int type, int protocol, int sv[2]);
int setsockopt(int s, int level, int optname, const void *optval, socklen_t optlen);
]]

return {
	AF_UNSPEC = 0,
	AF_UNIX = 1,
	AF_INET = 2,
	AF_ROUTE = 17,

	SOCK_STREAM = 1,
	SOCK_DGRAM = 2,
	SOCK_RAW = 3,
	SOCK_RDM = 4,
	SOCK_SEQPACKET = 5,

	sockaddr = ffi.typeof("struct sockaddr"),

	close = ffi.C.close,
	read = ffi.C.read,
	socket = ffi.C.socket,
	socketpair = ffi.C.socketpair,
	setsockopt = ffi.C.setsockopt,
}

