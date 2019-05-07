local crypto = require "sys.crypto"

local key = crypto.pkcs5_pbkdf2("wpa key", "nwid", 4096)
print(key)

