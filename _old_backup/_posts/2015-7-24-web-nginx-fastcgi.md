---
layout: page
tile: Web: Nginx FastCGI
time: 2015-07-24 10:09 
---

Recently, I met a problem on deploying [HotCRP][c2] on Nginx+HHVM.
It seems that Nginx cannot redirect the URI correctly to HotCRP.
During the trouble shooting process, I was really annoying by the 
Nginx's configuration and simple-but-not-complete blogs online.
So I've decided to structurally learn and write down the Nginx
config staff.

This is the second blog about Nginx Configuration.
I will focus on the fastcgi configuration for php/hhvm
<!---and a lit bit about reverse proxy--->.
The config file on Ubuntu14.04 will be in "/etc/nginx/nginx.conf". 
If you don't know where your config file is, 
you can use ``nginx -t`` to check it out.

There probably will be one more blog talking about reverse proxy:

- [Web: Nginx Basic Configuration][t1]
- **Web: Nginx FastCGI**
- Web: Nginx Reverse Proxy

### What if FastCGI ###

As you can see "FastCGI" should be fast version of [CGI][c4], which is
almost true. CGI is a very simple protocol which allows the webserver
to run some program in the old days when only the static pages are available.
	
>CGI allows the owner of the Web server to designate a directory within 
>the document collection as containing executable scripts (or binary files)
>instead of pre-written pages; this is known as a CGI directory.

FastCGI is the successor of CGI. It has solved two very important problem that
CGI involved: perforamnce and security.

> FastCGI's main aim is to reduce the overhead associated with
> interfacing the web server and CGI programs, allowing a server
> to handle more web page requests at once.

FastCGI is also fairly simple protocol. In short, it connects two sides: webserver
and one program (php, ruby on rails and so on).
First, the webserver (nginx) sends
a series of key-value pairs which represents the request variables from user,
as well as some environment variables.
The program on the other side, which is usually a daemon, receives these pairs as
inputs and sends the result (usually is a html page) back to webserver. Finally,
the webserver reply user's browser with such page.


### FastCGI Configuration ###

As we mentioned in [previous blog][t1], "location context" is where we usually
redirect one request to another folder. Same thing happens here. If we want to
run FastCGI protocol for a request, the first step is to set up which url will
redirect to the program running on another side of FastCGI.

Let's see an example:
    location ~ ^.*\.php$ {      fastcgi_pass 127.0.0.1:9000;      include fastcgi_params;	}

This example redirects all the requests ending with ".php" to the localhost
port 9000. And include the directives in file "fastcgi_params".

The following lines are the full contents from file "fastcgi_params". I don't know
where it comes from (is it a standard file for everyone?). It just happens appear
in my Nginx configuration folder. Yet, after I read it, I found it is a best practice
to place all the FastCGI configuration in a file and includes it each time you want
to use FastCGI protocol.

	fastcgi_param   QUERY_STRING            $query_string;
	fastcgi_param   REQUEST_METHOD          $request_method;
	fastcgi_param   CONTENT_TYPE            $content_type;
	fastcgi_param   CONTENT_LENGTH          $content_length;
	 
	fastcgi_param   SCRIPT_FILENAME         $document_root$fastcgi_script_name;
	fastcgi_param   SCRIPT_NAME             $fastcgi_script_name;
	fastcgi_param   PATH_INFO               $fastcgi_path_info;
	fastcgi_param   PATH_TRANSLATED		$document_root$fastcgi_path_info;
	fastcgi_param   REQUEST_URI             $request_uri;
	fastcgi_param   DOCUMENT_URI            $document_uri;
	fastcgi_param   DOCUMENT_ROOT           $document_root;
	fastcgi_param   SERVER_PROTOCOL         $server_protocol;
 
	fastcgi_param   GATEWAY_INTERFACE       CGI/1.1;
	fastcgi_param   SERVER_SOFTWARE         nginx/$nginx_version;
 
	fastcgi_param   REMOTE_ADDR             $remote_addr;
	fastcgi_param   REMOTE_PORT             $remote_port;
	fastcgi_param   SERVER_ADDR             $server_addr;
	fastcgi_param   SERVER_PORT             $server_port;
	fastcgi_param   SERVER_NAME             $server_name;
 
	fastcgi_param   HTTPS                   $https;
 
	# PHP only, required if PHP was built with --enable-force-cgi-redirect
	fastcgi_param   REDIRECT_STATUS         200;

One important line to explain:

	fastcgi_param   SCRIPT_FILENAME         $document_root$fastcgi_script_name;

The SCRIPT\_FILENAME decides which script you're going to run.
And $document\_root is a builtin variable which is your root folder for this location;
$fastcgi\_script\_name is another builtin varialbe which can be set by directive 
``fastcgi_index name;``.

### FastCGI Variables ###

**$fastcgi\_script\_name**:

>request URI or, if a URI ends with a slash, request URI with an index file 
>name configured by the fastcgi\_index directive appended to it. 
>This variable can be used to set the SCRIPT\_FILENAME and PATH\_TRANSLATED 
>parameters that determine the script name in PHP. 
>For example, for the “/info/” request with the following directives
>``fastcgi_index index.php;``
>``fastcgi_param SCRIPT_FILENAME /home/www/scripts/php$fastcgi_script_name;``
>the SCRIPT\_FILENAME parameter will be equal to “/home/www/scripts/php/info/index.php”.
>When using the fastcgi_split\_path\_info directive, 
>the $fastcgi\_script\_name variable equals the value of the 
>first capture set by the directive.

**$fastcgi\_path\_info**:

>the value of the second capture set by the fastcgi\_split\_path\_info directive.
>This variable can be used to set the PATH\_INFO parameter.

### FastCGI Directives ###

In my opinion, there are four directives which are pretty important and very
common during your configuration. They are:

- [fastcgi_pass][c6]
- [fastcgi_param][c7]
- [fastcgi\_split\_path\_info][c9]
<!--- - [fastcgi_index][c8]--->

**fastcgi_pass** _address_:

This directive sets the address of a FastCGI server. 
It is like the entrance symbol to show where the other side of FastCGI
is listening on. The address can be a network port like "localhost:9000".
It can also be a local socket, like Unix-domain socket.

**fastcgi\_param** _parameter value_:

This is probably the most popular directive
for FastCGI context. 

>Sets a parameter that should be passed to the FastCGI server. 
>The value can contain text, variables, and their combination. 
>These directives are inherited from the previous level if and 
>only if there are no fastcgi_param directives defined on the current level.

**fastcgi\_split\_path\_info** _regex_:

This is a pretty useful directive when
you want to redirect all the request to a same script, usually it's index.php.
Using it, you can have one main entrance (index.php) with the argument 
"PATH\_INFO" to further decide what to do.

>Defines a regular expression that captures a value for the 
>$fastcgi\_path\_info variable. 
>The regular expression should have two captures: the first 
>becomes a value of the $fastcgi\_script\_name variable,
>the second becomes a value of the $fastcgi\_path\_info variable.

This line in "fastcgi\_params" will assgin $fastcgi\_path\_info to PATH\_INFO
environment variable in the program.
``fastcgi_param   PATH_INFO               $fastcgi_path_info;``

### Location Regular Expression ###

What the hell is Nginx's regular expression's standard?
That's a very important but concealed question.
The answer is Nginx uses PCRE. Here is the link:
[What regular expression engine does Nginx use?][c3]

<!---
### Reverse Proxy ###

try_file

upstream

proxy_pass

$uri
--->

### Summary ###

I have explained what is FastCGI and how to configure it in Nginx in this blog.


[t1]: {% post_url 2015-7-22-web-nginx-config-I %} "nginx I"
[c1]: https://www.nginx.com/oreilly-guide "nginx book"
[c2]: http://www.read.seas.harvard.edu/~kohler/hotcrp/ "hotcrp"
[c3]: http://stackoverflow.com/questions/14126872/what-regular-expression-engine-does-nginx-use "what re"
[c4]: https://en.wikipedia.org/wiki/Common_Gateway_Interface "CGI"
[c5]: http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html "fastcgi doc"
[c6]: http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_pass "fastcgi_pass"
[c7]: http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_param "fastcgi_param"
[c8]: http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_index "fastcgi_index"
[c9]: http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_split_path_info "fastcgi_split_path_info"