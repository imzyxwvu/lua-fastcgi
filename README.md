lua-fastcgi
===========

The FastCGI host library for [Lua](http://www.lua.org) with [Copas](//github.com/keplerproject/copas) based on sockets. With it you can execute a [PHP](http://php.net/) script in Lua or write a web server that supports PHP scripts. "socket" and "copas" table should be in the global table before calling:

    require "fastcgi"

The following code should be executed in a Copas thread:

    FCGI.FilterT(port_to_php_cgi, {
        SCRIPT_FILENAME = "C:/htdocs/test.php",
        REQUEST_URI = "/test.php",
        DOCUMENT_ROOT = "C:/htdocs",
        REQUEST_METHOD = "GET",
    }, io.write, inputfunc)
  
If the inputfunc is given as a Lua function, it can be used to read the POST data. It should return a string, the number 0 which means the data is completed or nil that aborts the FastCGI request.

## Suggestion for Performance

FCGI.FilterU is just like FCGI.FilterT, but its first param is the path to a unix socket of the FastCGI filter. This call needs "socket.unix" loaded and an Unix OS, but it works much faster than with TCP.

## License

You can use the code anywhere you want if you have sent me an email to me or left a message on my blog to let me know. And I hope you could help me improve this project if you are interested in it.

## Come and See My Blog

[imzyx.com](http://imzyx.com) This blog is running on a web server written in Lua that uses this library.

I love Joshua_RK and Zhyupe.
