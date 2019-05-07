local log = require "log"
local bsd = require "bsd"
local unistd = require "unistd"

local debug = false

local logger = log.new("log_test", nil, debug)

logger:print("startup")

if not debug then
	bsd.daemon(true, false)
end

logger:print("hello, world!")
for i=0, 5 do logger:printf("i=%d", i); unistd.sleep(1) end

--logger:printf("answer is %d", 42)

logger:panicf("bad shit yo: %d", 42)

