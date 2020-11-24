Kong Header-Based-Router Plugin
===============================


This plugin will route requests to different upstreams depending on their headers.


Prerequisites
=============

In its current form the Plugin requires one or many Upstreams.

For example `italy_cluster` and `europe_cluster`


````
http POST :8001/upstreams name=italy_cluster
http POST :8001/upstreams name=europe_cluster
http POST :8001/upstreams/italy_cluster/targets target=mockbin.org:80
http POST :8001/upstreams/europe_cluster/targets target=httpbin.org:80
````

In addition you need to add a Service that points to one of the upstreams.

````
http POST :8001/services name=local host=europe_cluster # the default
````

Add a route to the recently added Service `local`.

````
http POST :8001/services/local/routes paths:='["/local"]' name=local methods:='["GET", "POST"]'
````

Finally enable the plugin for this Service.

````
http POST :8001/services/local/plugins name=myplugin
````

Alternatively this can also be conveniently done with a declarative configuration.


``` yaml

services:
 - host: europe_cluster
   name: local
   port: 80
   protocol: http
   routes:
   - name: local_route
     paths:
     - /local
     strip_path: true
     plugins:
     - name: myplugin
       enabled: true

 upstreams:
 - name: europe_cluster
   targets:
     - target: httpbin.org:80
       weight: 100
 - name: italy_cluster
   targets:
     - target: httpbin.org:80
       weight: 100
 plugins:
 - name: myplugin
   config:
     filter_rules:
       - upstream: italy_cluster
         header_match:
         - "X-Region:Abruzzo"
         - "X-City:Pescara"
       - upstream: europe_cluster
         default_target: true
         header_match:
         - ""
```


Configuration
=============


The plugin allows to define filter rules that match configured Upstreams.


For example you want to route requests that have `X-Region:Abruzzo` and `X-City:Pescara` in their headers to Upstream `italy_cluster`. All other requests, even if they also have `X-Region:Abruzzo` in their headers, go to the Upstream that you defined as `default_target`.

Note: Defined filters in the configuration act as a AND gate.