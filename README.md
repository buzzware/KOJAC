<h3 style="color; red">Current Status</h3>
<p style="color; red; font-weight: bold">
Kojac has been implemented in ActionScript 3 and Javascript for separate projects, but has not yet been extracted for separate release. There is not yet any code here to see.
</p>

------------------------

> "Sometimes the strategic breakthrough will be a new algorithm ... Much more often, strategic breakthrough will come from redoing the representation of the data or tables. This is where the heart of a program lies."   
> - "The Mythical Man Month" by Fred Brooks

## What is KOJAC ?

KOJAC is an acronym for Key Oriented JSON Application Cache. Yes you may know of [Kojak, the 1970s TV cop show](http://en.wikipedia.org/wiki/Kojak).

KOJAC is an opinionated design and implementation for data management within ["single page"](http://en.wikipedia.org/wiki/Single-page_application) or ["Rich Internet"](http://en.wikipedia.org/wiki/Rich_Internet_application) applications. It relates most heavily to the client and data protocol. The server may continue the key/value style down to a key/value-style database if desired, but that is not necessary. KOJAC also makes sense for the client design when a standard REST-style server is to be used, but naturally multiple operations will require multiple server requests.

Single page applications require a different way of thinking, and present different challenges to traditional server-based applications. In particular, application state and user data must be managed and synchronised with the server. 

Behind the design of KOJAC is the belief that how we structure and identify data has an enormous impact on the size and complexity of the application code.

#### 1) Think REST ...

Like [REST](http://en.wikipedia.org/wiki/Representational_state_transfer), the server has "resources" eg. customers or products that the client may do CRUD (Create, Read, Update, Destroy) operations on. Unlike REST, URLs are replaced by keys. Keys follow a standard format eg. `<resource>__<id>`. 

Values may be of any valid JSON type ie. Null, Int, Number, String, Boolean, Array, Object. Potentially the Client, server and protocol can use the same key/value schema.

#### 2) ...with multiple operations per request...

Multiple operations per http request. Freely specify a mixture of CRUD operations on any resources in a given order, and get back the results (including errors) of any operation. That means your data can be broken down to single values, and you can request just the values you need from the server.

#### 3) ...and an object factory.

An optional custom factory method easily converts raw JSON into your application classes and property types. When KOJAC is used with Ember.js, the included EmberModel class enables application models to be declared with typed properties, and data is intelligently converted (if required) when these properties are set. Model classes serve as a live data dictionary for your app, and provide a meaningful place for related methods. Typed properties simplify application code by reducing the need to check and convert types. 

#### 4) A central cache keeps things responsive

Responses from the server update the cache (by default), keeping it fresh. With frameworks like Ember, the view can bind directly to the cache key eg. {rowIdsBinding: "App.cache.products"} for display as soon as it arrives. 

#### 5) No boiler-plate code

As date in the cache is often up to date and in your application classes, very little code is required to support or use the KOJAC framework once setup.


<br/>
<br/>
<br/>
KOJAC is server agnostic, open for hacking and debugging, uses and supports jQuery (especially Deferred Objects/Promises), prefers Ember.js but doesn't require it.

