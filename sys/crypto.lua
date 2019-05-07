local ffi = require "ffi"

ffi.cdef[[
int pkcs5_pbkdf2(const char *pass, size_t pass_len, const char *salt,
	size_t salt_len, uint8_t *key, size_t key_len, unsigned int rounds);
]]

local lib = ffi.load("util")

local M = {}

function M.pkcs5_pbkdf2(pass, salt, rounds)
	local keylen = 32
	local key = ffi.new("uint8_t[?]", keylen) -- sha1
	local rv = lib.pkcs5_pbkdf2(pass, pass:len(), salt, salt:len(), key, keylen, rounds)
	if rv ~= 0 then
		error("pkcs5_pbkdf2 failed")
	end

	return ffi.string(key, keylen)
end

return M

