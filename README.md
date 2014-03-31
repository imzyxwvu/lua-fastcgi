lua-fastcgi
===========

The FastCGI host library for Lua with [Copas](//github.com/keplerproject/copas). With you can execute a PHP script in Lua or write a web server that supports PHP scripts. "socket" and "copas" table should be in the global table before calling:

  require "fastcgi"

The following code should be executed in a Copas thread:

  FCGI.FilterT(port_to_php_cgi, {
	SCRIPT_FILENAME = "C:/htdocs/test.php",
	REQUEST_URI = "/test.php",
	DOCUMENT_ROOT = "C:/htdocs",
	REQUEST_METHOD = "GET",
  }, io.write, inputfunc)
  
If the inputfunc is given as a Lua function, it can be used to read the POST data. It should return a string, the number 0 which means the data is completed or nil that aborts the FastCGI request.

Suggestion to Optimize the Performance
===========

FCGI.FilterU is like FCGI.FilterT, but its first param should be a string of the path to a unix socket of the FastCGI filter. This needs "socket.unix" loaded and an Unix OS, but works much faster.

