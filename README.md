# A url shortener service with z/OS COBOL and DB2

## Wait, what?

This [fizzbuzz LOC-competition](https://grasswire-engineering.tumblr.com/post/94043813041/a-url-shortener-service-in-45-lines-of-scala) had just entries like 
[Hashkell+Redis](https://bitemyapp.com/blog/url-shortener-in-haskell/) or 
[Clojure+Redis](https://adambard.com/blog/a-clojure-url-shortener-service/) and 
was obviously in a dire need for more esoteric solutions.

<img src='https://github.com/alaisi/urlshortener-z/blob/master/edit.png?raw=true'/>

## Building

The build is driven by make on Linux/macOS. Source code is first transformed 
to EBDCDIC and sent to z/OS with FTP. A JCL build job is then submitted to the Job Entry Subsystem 
to run DB2 precompilation, COBOL compilation, linking a load
module, creating database tables and binding DB2 query plans. The make 
build also copies a cgi script to IBM HTTP Server cgi-bin in UNIX system services
filesystem to enable invoking the load module HTTP.

```shell
$ make
...
IEF142I IBMUSERB DB2PREC - STEP WAS EXECUTED - COND CODE 0000 
IEF142I IBMUSERB DB2PREC2 - STEP WAS EXECUTED - COND CODE 0000 
IEF142I IBMUSERB COMPILE - STEP WAS EXECUTED - COND CODE 0000 
IEF142I IBMUSERB LINK - STEP WAS EXECUTED - COND CODE 0000 
IEF142I IBMUSERB MIGRATE - STEP WAS EXECUTED - COND CODE 0000 
IEF142I IBMUSERB DB2BIND - STEP WAS EXECUTED - COND CODE 0000
```

## Testing

Adding a new link:

```shell
$ curl -iX POST http://mainframe.local:8080/cgi-bin/urlshort.cgi?u=https://google.com/
HTTP/1.1 201 Created 
Server: IBM HTTP Server/V5R3M0
Accept-Ranges: bytes
Transfer-Encoding: chunked
Content-Type: text/json

{"url": "http://mainframe.local:8080/cgi-bin/urlshort.cgi?l=000000000000000039"}
```

Getting the URL for a link:

```shell
$ curl -i http://mainframe.local:8080/cgi-bin/urlshort.cgi?l=000000000000000039
HTTP/1.1 200 Document follows 
Server: IBM HTTP Server/V5R3M0
Accept-Ranges: bytes
Transfer-Encoding: chunked
Content-Type: text/json
Refresh: 0;url=https://google.com/
```

## But... why?

Because the mountain was there and unclimbled.
