---
layout: page
tile: Web: Nginx Configuration I
time: 2015-07-22 16:01
---

Recently, I met a problem on deploying [HotCRP][c2] on Nginx+HHVM.
It seems that Nginx cannot redirect the URI correctly to HotCRP.
During the trouble shooting process, I was really annoying by the 
Nginx's configuration and simple-but-not-complete blogs online.
So I've decided to structurally learn and write down the Nginx
config staff.

This is the first blog about basic Nginx Configuration.
The config file on Ubuntu14.04 will be in "/etc/nginx/nginx.conf". 
If you don't know where your config file is, 
you can use ``nginx -t`` to check it out.

### Command to control Nginx ###

I'm intended to skip the install or compiling/install procedure
since there are whole bunch of blogs talking about them.
You can either install them by package manager (apt-get/yum) or
download the source code and compile from scratch.

When one uses Nginx by her first time, the reasonable questions she 
would ask might be:

- How to control (start/stop/reload) the nginx server?

	**Start** Nginx server:
	
	(1) If you use whatever package manager to install the
	nginx, like apt-get or yum, you probably can use
	``service nginx start`` to start the nginx server.
	
	(2) If you compile it from source code, you can run ``nginx`` to
	start the server. Yet, please make sure you are using the correct
	and suitable configuration which use ``nginx -h`` to know more.
	
	**reload/stop** server:
	
	Use cmd ``nginx -s [quit|stop|reload]`` to [graceful stop|quick stop|reload]
	the server.

- How do I know the Nginx server works?

	Run ``ps aux|grep hhvm`` to see if there is any process named nginx.
	If it works fine, you shoud see something similar like:
		
		root     17171  0.0  0.0  85996  2424 ?        Ss   09:40   0:00 nginx: master process /usr/sbin/nginx
		www-data 29013  0.0  0.0  86280  1924 ?        S    22:24   0:00 nginx: worker process
		www-data 29014  0.0  0.0  86280  1924 ?        S    22:24   0:00 nginx: worker process
		www-data 29015  0.0  0.0  86280  2180 ?        S    22:24   0:00 nginx: worker process
		www-data 29016  0.0  0.0  86280  1924 ?        S    22:24   0:00 nginx: worker process

### Basic Layout of Nginx ###

The config file of Nginx is quite clear.
It will have similar layout as:

	(1)
	events {
	  (2)
	}
	http {
      (3)
	  server {
        (4)
	  } 
	}
	
I have divided the config file into 4 sections, namely (1)-(4)
on the above code.
In each section, there will be a bunch of directives 
which can fit in. I will follow this four sections
to introduce the directives. [Here][c3] is
a list of core directives.

**Note**: There are not only these four sections which you
can write directives, and the layout is not fixed like above.
For example, you can have multiple ``server{}`` in
one ``http{}`` context. Also, there are more blocks,
such as ``mail{}`` which I didn't mention here. What
I have demonstrated is just a simple but general case.

### Section(1): Directives for the Main Context ###

Each of the ``<name> {...}`` like structure is called context. 
In each context, there will be different directives which can take effect.
However, in setction(1), out of all other context, we call it main context.
Here are some directives can place here:

**[user][c8]**: Directive "user" can take two parameters which are user name
and group name the nginx is running on behalf of.

	user www-data www-data
	
	events {
	...

This will run Nginx on behalf of user www-data.

**[worker_processes][c9]**: Given by a number, this directive will
set the number of worker processes the nginx will issue. The
following means there will be four worker processes.

	...
	worker_processes 4;
	
	events {
	...

### Section(2): Event Context ###

Nginx is an event-driven server.
The event context includes some configurations about the
event handling. For example, how many connections for a
worker process ([worker_connections][c10]).

	...
	events {
	  worker_connections 512;
	  ...


### Section(3): HTTP Context ###

Http context contains the server context which will be discussed
in the next section. The server context represents a "server" which
will responds user's requests. There can multiple server context 
inside http context, and there is only one http context.

Somehow, the drectives placed in Section(3) can be regarded as
the common directives shared by all the server contexts.
You can put everything into different server contexts.
But the best practice would be put the shared directives here.

### Section(4): Server Context ##

This is the most important context you should take care of.
Server context will represent a http server which should respond to
the user's requests.

**[listen][c4]**: The full explanation of this directive is [here][c4].
It can be really complicated.
Directive listen tell Nginx which port is this "server" listen on.

	server {
	  listen *:80
	  ...

The default value for this directive is ``listen *:80``.
In other words, if you config a server context without listen directive,
then it will listen on port 80.

**[root][c5]**: Sets the root directory for requests.

	server {
	  root /usr/share/nginx/html/
	  ...

In this example, the root of this server would be "/usr/share/nginx/html/".
The file "/usr/share/nginx/html/index.html" will be sent in response to the
"/index.html" request.
A path to the file is constructed by merely adding a URI to the value of the root directive.
If a URI has to be modified, the alias directive should be used.

**[location][c7]{...}**:
This is a context which belongs to serve context.
And this is also very important context.
Please see next section for more details.

### Location Context ###

After previous configuration, the uri must match the
directory/filesystem layout of the root. However, sometime,
we want to put different resources into different place.
For instance, I may want uri "www.you.com/pic/good.jpg" goes to 
folder "~/picture/good.jpg", while "www.you.com/index.html" is
still in "/usr/share/nginx/html/index.html".

The location context is used to mapping different uri to
different locations. The syntax of location context is like:

	location [=|~|~*|^~] uri {
	  configuration_directives
	}

There are four kinds of location context:

- Prefix location 
- Exact location 
- Regular expression location
- Non-Regular expression location

**Prefix location**:

	location /pic/ {
	  ...
	}

**Exact location**:

	location = /whatever/path/lol.jpg {
	  ...
	}
	
**Regular expression location**:

	location ~ \.(gif|jpg)$ {
		...
	}
	
Note that "~" means case-sensitive matching, which "xxx.gif" will match
but "xxx.GIF" won't. On the contrary, "~*" is the indicator you want to
match case-insensitive matching.

**Non-Regular expression location**:

	location ^~ /whatever/path/ {
		...
	}

<!---
Named location:

	location @what {
		...
	}
	
	location /why/ {
		try_file why.html @what;
	}
--->

**[alias][c6]**: Directive "alias" is a little bit different from "root".
The "root" will still contain the matching path as suffix; while
"alias" totally replace it. For example:

	location /whatever/ {
		root /new/path/to/;
	}
	
	location /whatever2/ {
		alias /new/path/to/;
	}
	
The result of these two location would be:  
``www.you.com/whaterever/ => /new/path/to/whatever/``  
and  
``www.you.com/whatever2/ => /new/path/to/``

### The Location Block Selection Algorithm ###

This section is borrowed from book [Nginx: A Practical Guide][c1].
And it is talking about which location to use if Nginx has several
matching locations.

|Modifier|Name|Description|
---------|----|-----------
|(none)|Prefix|Matches on the prefix of a URI|
|   =  |Exact Match| Matches an exact URI|
| ~/~*| Regular Expression| Matches a URI against a case-sensitive/insensitive regular expression|
|^~|Non-regular expression prefix| Matches a URI against a prefix and skips regular expression matching|

The algorithm of the Nginx location matching:

1. The exact match location blocks are checked.
If an exact match is found, the search is terminated and the location block is used.

2. All of the prefix location blocks are checked for the
most specific (longest) matching prefix. If the best match has
the ^~ modifier, the search is terminated and the block is used.

3. Each regular expression block is checked in sequential order.
If a regular expression match occurs, the search is terminated and block is used.

4. If no regular expression block is matched, the best prefix
location block determined in step #2 is used.

### Summary ###

To summary, we talked about the basic control commands of Nginx,
and the layout of Nginx's config file.
By splitting the file into 4 sections, we have introduced
4 different context as well as several directives on each 
context. At last, we talked about location context which belongs
to server context and Nginx's location matching algorithm.

[c1]: https://www.nginx.com/oreilly-guide "nginx book"
[c2]: http://www.read.seas.harvard.edu/~kohler/hotcrp/ "hotcrp"
[c3]: http://nginx.org/en/docs/ngx_core_module.html "list of directives"
[c4]: http://nginx.org/en/docs/http/ngx_http_core_module.html#listen "listen directive"
[c5]: http://nginx.org/en/docs/http/ngx_http_core_module.html#root "root"
[c6]: http://nginx.org/en/docs/http/ngx_http_core_module.html#alias "alias"
[c7]: http://nginx.org/en/docs/http/ngx_http_core_module.html#location "location"
[c8]: http://nginx.org/en/docs/ngx_core_module.html#user "user"
[c9]: http://nginx.org/en/docs/ngx_core_module.html#worker_processes "worker processes"
[c10]: http://nginx.org/en/docs/ngx_core_module.html#worker_connections "worker connections"
