local errno = require "errno"

for k,v in pairs(errno) do
	print(k, v, errno(v))
end

