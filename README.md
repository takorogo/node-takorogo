node-takorogo
============

Takorogo to JSON parser for Node.js

[![build status](https://travis-ci.org/takorogo/node-takorogo.svg)](http://travis-ci.org/takorogo/node-takorogo)
[![Coverage Status](https://img.shields.io/coveralls/takorogo/node-takorogo.svg)](https://coveralls.io/r/takorogo/node-takorogo)
[![NPM version](https://badge.fury.io/js/takorogo.svg)](http://badge.fury.io/js/takorogo)
[![Dependency Status](https://david-dm.org/takorogo/node-takorogo.svg)](https://david-dm.org/takorogo/node-takorogo)
[![devDependency Status](https://david-dm.org/takorogo/node-takorogo/dev-status.svg)](https://david-dm.org/takorogo/node-takorogo#info=devDependencies)

Installation
------------

This module is installed via npm:

``` bash
$ npm install takorogo
```

Example Usage
-------------

``` js
var takorogo = require('takorogo');
var rules = takorogo.parse('user <--[POSTED]-- :User');
```

Takorogo Syntax
--------------

Takorogo uses relations to maps properties to nodes determined by classes and their indices. That's all.

### Relations
  
For example we have a tweet with embedded user object:
 
```javascript
var tweet = {
    id: 481101713646960641
    user: {
        default_profile_image : false,
        id : 119102990,
        profile_background_image_url_https : "https://pbs.twimg.com/profile_background_images/444244318/16840333315.png",
        verified : false,
        /* ... */
    }
}
```

In this case we can say that tweet posted by user:
  
```takorogo
--[POSTED_BY]--> user:User 
```

Or that user posted a tweet:

```takorogo
<--[POSTED]-- user:User 
```

Or user and tweet has a bidirectional relationship:

```takorogo
<--[POSTED|POSTED_BY]--> user:User 
```

Where `user` is a property name that contains embedded object and `:User` is a name of a class.

You can specify what attribute will be stored in relation passing them to relation in parentheses:

```takorogo
--[PARTICIPATE_IN(score, wins)]--> game:Game
```

You can specify types for relation attributes:

```takorogo
--[PARTICIPATE_IN(score: Score, wins: Integer)]--> game:Game
```
 
Or even destructuring an array property:
 
```takorogo
entities.urls[] --[REFERS_TO(indices[first, last])]--> :Url
```

Attention. Currently only plain values are supported. 

### Relations resolved from keys

Sometimes your document just points to something via key. In this case you can specify how relation should be resolved.

```takorogo
in_reply_to_status_id_str => id_str <--[ REPLIED_WITH|REPLIED_TO ]--> in_reply_to:Tweet
```

In the last case `=>` means that `in_reply_to_status_id_str` should be treated as an `id_str` key.

For compound keys you can use following syntax:

```takorogo
(longitude, latitude) => (x, y) --[ LOCATED ]--> location:Point
```

### Attributes

Sometimes your document's structure doesn't fit plane key-value nature of node.
In this case you can specify properties by paths:

```takorogo
--[CITIZEN_OF]--> place.country:Country 
```

If document's field doesn't match what you want to have in the target node you can rename it:
 
```takorogo
--[CITIZEN_OF]--> place.country => country:Country 
```
 
You also can assign types to attributes (user-defined classes are also supported):

```takorogo
def :Person {
    + firstName :String
    + dateOfBirth :Date
}        
```

Attention: attribute aliasing in types constraints are not supported yet.
 
### Embedded objects 

Embedded objects are stored inside the node. Mechanism depends on graph database engine.  

### Links (anonymous relations)

You can store unstructured embedded object as a link to node: 

```takorogo
--> metadata
```

As for normal relations you can specify classes and arrays for links:
 
```gypher
--> tweet:Tweet
--> comments:Comment[]
```

### Indices

You can specify unique constraint: 

```takorogo
UNIQUE(id)
```

Takorogo also handles compound constraints:
  
```takorogo
UNIQUE(firstName, lastName)
```

### Classes & Types

You can refer to already defined class or type by colon notation:

```takorogo
UNIQUE(id:Int)
--> tweet:Tweet
```

In case when you have a collection of instances you can use an array syntax:

```takorogo
--> comments:Comment[]
```

Unstructured arrays are also supported:

```takorogo
--> things[]
```

#### Class Definition

To define class use `def` keyword:

```takorogo
def Tweet
```

You can specify primary key in parentheses:

```takorogo
def HashTag(text)
```

Compound indexes are also supported:

```takorogo
def Person(firstname, lastname)
```

And you can use paths to specify properties:

```takorogo
def Citizen(credentials.passport.number)
```

Sometimes your class's primary key is stored in array.
For example we have a location document with unique combinations of longitude and latitude stored in array.
For this cases you can write: 

```takorogo
def Location(coordinates[longitude, latitude])
```

#### Complex Classes

You can define rules for complex classes in curly braces:

```takorogo
def User(passport.id) {
    --[CHILD_OF]--> father:Person
    --[REFERS_TO(indices[first, last])]--> entities.url.urls[]:Url
}
```

#### Enumerations

You can define enumeration mappers for arrays of fixed length:

```takorogo
def Coordinates [ longitude, latitude ]
```

After array items specified we can treat it as a regular document:

```takorogo
def VendorCoordinates [ longitude, latitude, vendor ] {
  UNIQUE(longitude, latitude, vendor.id)
  --[PRODUCED_BY]--> vendor:Vendor  
}
```

### Inline Class Definition

Simple classes can be defined inside relation rules by appending class name with parentheses:

```takorogo
--[POPULATED_WITH]--> comment:Comment(id)
```

You can specify indices as in normal declaration: 

```takorogo
--[REFERS_TO]--> urls:Url(url)[]
```

That will create a class `Url` with `url` as primary key and use it as a map for related nodes.


### Comments

Takorogo supports only one line comments (both `#` and `//`):

```takorogo
# JIRA task 
def Task {
  UNIQUE(id)  // Primary key
  --[BLOCKED_BY]-->blocker:Task
}
```

Examples
--------

The following Takorogo script describes tweet structure from Twitter Stream API:  

```takorogo
# The whole tweet document returned by Twitter Stream API
def Tweet {
    UNIQUE(id_str:String)
    UNIQUE(id:Int)
    
    + location: String

    <--[POSTED]-- user:User
    --> metadata
    <--[ REPLIED_WITH|REPLIED_TO ]--> in_reply_to_status_id_str => in_reply_to:Tweet
     --[ REFERS_TO(indices[first, last]) ]--> entities.urls[]:Url
     --[ HAS_TAG(indices[first, last]) ]--> entities.hashtags[]:HashTag(text)
     --[ AT ]--> coordinates:Location
     --[ ON ]--> geo:Location
     --[ PLACED ]--> place:Place
}

# Just a point
def Coordinates [ longitude, latitude ] {
  UNIQUE(longitude: Double, latitude: Double)
}

def Location(coordinates:Coordinates)  // Simply a wrapper for coordinates 

def Place {
    --[ BOUNDED_BY ]--> bounding_box.coordinates => bounding_box:Coordinates[]
}

def User(id_str) {
    --[REFERS_TO(indices[first, last])]--> entities.url.urls[]:Url
}
```

Browser
-------

Client versions of `node-takorogo` can be built from sources or can be found in `./client/` directory of NPM module.


Contribution
------------

You can start from [API docs](http://sitin.github.io/node-takorogo/).

I will accept only changes covered by unit tests.


Road map
--------

### Support indentation for class rules

```takorogo
def :Person
    UNIQUE(passport.id)
    --[CHILD_OF]--> father:Person
```

### Add attribute rewrite in type constraint statements

```takorogo
def :Person {
    + name.first => firstName :String
}
```
