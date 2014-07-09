node-grypher
============

Grypher to JSON parser for Node.js

[![build status](https://secure.travis-ci.org/Sitin/node-grypher.png)](http://travis-ci.org/Sitin/node-grypher)
[![coverage status](https://coveralls.io/repos/Sitin/node-grypher/badge.png)](https://coveralls.io/r/Sitin/node-grypher)

Installation
------------

This module is installed via npm:

``` bash
$ npm install grypher
```

Example Usage
-------------

``` js
var grypher = require('grypher');
var rules = grypher.parse('user <--[POSTED]-- :User');
```

Grypher syntax
----------------

Grypher uses relations to maps properties to nodes determined by classes and their indices. That's all.

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
  
```grypher
--[POSTED_BY]--> user:User 
```

Or that user posted a tweet:

```grypher
<--[POSTED]-- user:User 
```

Or user and tweet has a bidirectional relationship:

```grypher
<--[POSTED|POSTED_BY]--> user:User 
```

Where `user` is a property name that contains embedded object and `:User` is a name of a class.

You can specify what attribute will be stored in relation passing them to relation in parentheses:

```grypher
--[PARTICIPATE_IN(score, wins)]--> game:Game
```
 
Or even destructuring an array property:
 
```grypher
entities.urls[] --[REFERS_TO(indices[first, last])]--> :Url
```

Attention. Currently only plain values are supported. 

### Attributes

Sometimes your document's structure doesn't fit plane key-value nature of node.
In this case you can specify properties by paths:

```grypher
--[CITIZEN_OF]--> place.country:Country 
```

If document's field doesn't match what you want to have in the target node you can rename it:
 
```grypher
--[CITIZEN_OF]--> place.country => country:Country 
```
 
You also can assign types to attributes (user-defined classes are also supported):

```grypher
def :Person {
    + firstName :String
    + dateOfBirth :Date
}        
```

Attention: attribute aliasing in types constraints are not supported yet. 

### Classes & Types

You can refer to already defined class or type by colon notation:

```grypher
id:Int UNIQUE
--> tweet:Tweet
```

In case when you have a collection of instances you can use an array syntax:

```grypher
--> comments:Comment[]
```

To define class use `def` keyword:

```grypher
def Tweet
```

You can specify primary key in parentheses:

```grypher
def HashTag(text)
```

Compound indexes are also supported:

```grypher
def Person(firstname, lastname)
```

And you can use paths to specify properties:

```grypher
def Citizen(credentials.passport.number)
```

Sometimes your class's primary key is stored in array.
For example we have a location document with unique combinations of longitude and latitude stored in array.
For this cases you can write: 

```grypher
def Location(coordinates[longitude, latitude])
```

You can define rules for complex classes in curly braces:

```grypher
def User(passport.id) {
    --[CHILD_OF]--> father:Person
    --[REFERS_TO(indices[first, last])]--> entities.url.urls[]:Url
}
```

### Inline class definition

Simple classes can be defined inside relation rules by appending class name with parentheses:

```grypher
--[POPULATED_WITH]--> comment:Comment(id)
```

You can specify indices as in normal declaration: 

```grypher
--[REFERS_TO]--> urls[]:Url(url)
```

That will create a class `Url` with `url` as primary key and use it as a map for related nodes.


Road map
--------

### Support indentation for class rules

```grypher
def :Person
    passport.id UNIQUE
    --[CHILD_OF]--> father:Person
```

### Add attribute rewrite in type constraint statements

```grypher
def :Person {
    + name.first => firstName :String
}
```