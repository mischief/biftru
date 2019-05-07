local ffi = require "ffi"

ffi.cdef[[
int daemon(int nochdir, int noclose);
int pledge(const char *promises, const char *paths[]);
]]

local M = {}

M.daemon = ffi.C.daemon
M.pledge = ffi.C.pledge

return M

