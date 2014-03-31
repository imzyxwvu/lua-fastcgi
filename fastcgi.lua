--
--  lua-fastcgi
--  The FastCGI host library for Lua with Copas based on sockets.
--  Author: Zyxwvu <imzyxwvu@gmail.com> Weblog: imzyx.com
--  You can use the code anywhere you want if you have sent me an email.
--

FCGI = {}
local function try1st(s, err) if not s and err then error(err) else return s, err end end
local band = bit32.band

local FCGISocket_MT = {}

function FCGISocket_MT:Header(t, len)
	assert(len < 0x10000)
	copas.send(self.socket, string.char(
		0x1, -- FCGI_VERSION_1
		t, -- unsigned char type
		0, 1, -- FCGI_NULL_REQUEST_ID
		band(len, 0xFF00) / 0x100, band(len, 0xFF),
		0, -- unsigned char paddingLength
		0 -- unsigned char reserved
	))
end

function FCGISocket_MT:Param(p, v)
	local vl
	if #v > 127 then
		vl = #v
		vl = string.char(
			band(vl, 0x7F000000) / 0x1000000 + 0x80,
			band(vl, 0xFF0000) / 0x10000,
			band(vl, 0xFF00) / 0x100,
			band(vl, 0xFF))
	else vl = string.char(#v) end
	local paramdata = string.char(#p) .. vl .. p .. v
	self:Header(4, #paramdata)
	copas.send(self.socket, paramdata)
end

function FCGISocket_MT:BeginRequest(r)
	self:Header(1, 8)
	copas.send(self.socket, string.char(
		0, r, -- unsigned char roleB1, roleB0
		0, -- unsigned char flags
		0, 0, 0, 0, 0
	))
end

function FCGISocket_MT:Receive()
	local raw = try1st(copas.receive(self.socket, 8))
	local data = copas.receive(self.socket, raw:byte(5) * 0x100 + raw:byte(6))
	copas.receive(self.socket, raw:byte(7))
	return raw:byte(2), data
end

FCGISocket_MT.__index = FCGISocket_MT

function FCGI.FilterK(obj, vars, outputfunc, inputfunc)
	obj:BeginRequest(3)
	for k, v in pairs(vars) do
		obj:Param(k, v)
	end
	obj:Header(4, 0) -- FCGI_PARAMS
	if inputfunc then while true do
		local data = inputfunc()
		if data == 0 then break
		elseif data then
			obj:Header(5, #data) -- FCGI_STDIN
			copas.send(obj.socket, data)
		else
			obj:Header(2, 0) -- FCGI_ABORT_REQUEST
			obj.socket:close()
			return
		end
	end end
	obj:Header(5, 0) -- FCGI_STDIN
	while true do
		local rt, rv = obj:Receive(obj.socket)
		if rt == 6 then -- FCGI_STDOUT
			if not outputfunc(rv) then
				obj:Header(2, 0) -- FCGI_ABORT_REQUEST
				obj.socket:close()
			end
		elseif rt == 3 then -- FCGI_END_REQUEST
			obj.socket:close()
			break
		elseif rt == 7 then -- FCGI_STDERR
			if FCGI.ErrorLog then FCGI.ErrorLog:write(rv) end
		end
	end
end

function FCGI.FilterU(port, ...)
	local obj = setmetatable({ socket = socket.unix() }, FCGISocket_MT)
	try1st(obj.socket:connect(port))
	obj.socket:settimeout(0)
	FCGI.FilterK(obj, ...)
end

function FCGI.FilterT(port, ...)
	local obj = setmetatable({ socket = socket.tcp() }, FCGISocket_MT)
	try1st(obj.socket:connect("127.0.0.1", port))
	obj.socket:settimeout(0)
	obj.socket:setoption('tcp-nodelay', true)
	FCGI.FilterK(obj, ...)
end
