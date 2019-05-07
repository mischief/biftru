local ffi = require "ffi"

ffi.cdef[[
typedef unsigned char u_char;
typedef long ssize_t;
typedef int32_t pid_t;

struct ibuf {
 struct { struct ibuf *tqe_next; struct ibuf **tqe_prev; } entry;
 u_char *buf;
 size_t size;
 size_t max;
 size_t wpos;
 size_t rpos;
 int fd;
};

struct msgbuf {
 struct { struct ibuf *tqh_first; struct ibuf **tqh_last; } bufs;
 uint32_t queued;
 int fd;
};

struct ibuf_read {
 u_char buf[65535];
 u_char *rptr;
 size_t wpos;
};

struct imsg_fd {
 struct { struct imsg_fd *tqe_next; struct imsg_fd **tqe_prev; } entry;
 int fd;
};

struct imsgbuf {
 struct { struct imsg_fd *tqh_first; struct imsg_fd **tqh_last; } fds;
 struct ibuf_read r;
 struct msgbuf w;
 int fd;
 pid_t pid;
};

struct imsg_hdr {
 uint32_t type;
 uint16_t len;
 uint16_t flags;
 uint32_t peerid;
 uint32_t pid;
};

enum {
	IMSG_HEADER_SIZE = 16,
};

struct imsg {
 struct imsg_hdr hdr;
 int fd;
 void *data;
};

struct ibuf *ibuf_open(size_t);
struct ibuf *ibuf_dynamic(size_t, size_t);
int ibuf_add(struct ibuf *, const void *, size_t);
void *ibuf_reserve(struct ibuf *, size_t);
void *ibuf_seek(struct ibuf *, size_t, size_t);
size_t ibuf_size(struct ibuf *);
size_t ibuf_left(struct ibuf *);
void ibuf_close(struct msgbuf *, struct ibuf *);
int ibuf_write(struct msgbuf *);
void ibuf_free(struct ibuf *);
void msgbuf_init(struct msgbuf *);
void msgbuf_clear(struct msgbuf *);
int msgbuf_write(struct msgbuf *);
void msgbuf_drain(struct msgbuf *, size_t);

void imsg_init(struct imsgbuf *, int);
ssize_t imsg_read(struct imsgbuf *);
ssize_t imsg_get(struct imsgbuf *, struct imsg *);
int imsg_compose(struct imsgbuf *, uint32_t, uint32_t, pid_t, int,
     const void *, uint16_t);
int imsg_composev(struct imsgbuf *, uint32_t, uint32_t, pid_t, int,
     const struct iovec *, int);
struct ibuf *imsg_create(struct imsgbuf *, uint32_t, uint32_t, pid_t, uint16_t);
int imsg_add(struct ibuf *, const void *, uint16_t);
void imsg_close(struct imsgbuf *, struct ibuf *);
void imsg_free(struct imsg *);
int imsg_flush(struct imsgbuf *);
void imsg_clear(struct imsgbuf *);
]]

local lib = ffi.load("util")

local imsg = {}

function imsg.compose(m, typ, peerid, data, len)
	return lib.imsg_compose(m.buf, typ, peerid, 0, -1, data, len)
end

function imsg.composefd(m, typ, peerid, fd)
	return lib.imsg_compose(m.buf, typ, peerid, 0, fd, nil, 0)
end

function imsg.flush(m)
	local n, err = lib.imsg_flush(m.buf)
	if n == -1 then
		error("imsg_flush: " .. ffi.string(ffi.C.strerror(ffi.errno())))
	end
	return n
end

function imsg.read(m)
	return tonumber(lib.imsg_read(m.buf))
end

function imsg.get(m)
	local msg = ffi.new("struct imsg")
	--ffi.gc(msg, lib.imsg_free)
	local n = lib.imsg_get(m.buf, msg)
	if n == 0 then
		return 0
	end
	if n == -1 then
		return -1
	end

	return n, msg
end

local imsgmt = {
	__index = imsg,
}

local function imsgbufgc(m)
	lib.imsg_clear(m)
	--ffi.C.free(m)
end

local function imsg(fd)
	local imsgbuf = ffi.new("struct imsgbuf")
	ffi.gc(imsgbuf, imsgbufgc)
	local i = {
		buf = imsgbuf,
	}
	i.buf = ffi.new("struct imsgbuf")
	lib.imsg_init(i.buf, fd)
	return setmetatable(i, imsgmt)
end

local ix = {
	IMSG_HEADER_SIZE = lib.IMSG_HEADER_SIZE,

	imsg = imsg,
}

return ix

