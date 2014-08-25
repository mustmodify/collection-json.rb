# CollectionJSON

## Forked Changes

In the process of using collection+JSON for an API, our team found we had certain needs that weren't being met. We have added non-canon elements to collection+JSON in this repo. We have tried to do so responsibly, but it's important to note that this is NOT per Collection+JSON spec. But it is good stuff, and we think it's useful.

* embedded links
* meta
* template validations
* template options
* template option conditions
* template errors
* template conditions
* template recursion
* other template fields
* related ( alpha )

### Embedded Links

We used cJ's links and the "embedded" concept from HAL to eager-load nested resources. The 'embedded' root node contains a collection of independantly-complete collection+JSON objects. Clients can check the root 'href' of each embedded object before trying to get the data from linked uri. 

Although we could easily have skipped the 'collection' node, our sense was that clients would find it easier to implement, pretend to cache, etc., if it were a complete cJ document. 

As with most of our extensions, it's 100% backwards compatible. Clients that choose to follow the link should still get a valid response.

**Don't Bait and Switch**

In order to preserve backward-compatibility, the embedded document MUST be the same the content that would be retrieved by getting the link's target.

Exceptions:
* the server may choose to embed or not embed links.
* if the underlying data changes, then obviously that should be reflected on that endpoint.

Alternative Solutions:
* [Inline Collections](https://github.com/collection-json/extensions/blob/master/inline.md)

On the Ruby side, all links accept an 'embed' attribute. The value should respond to #to_json. For instance, you could use another CollectionJSON instance, which wraps everything up in a nice bow:

```
actors = CollectionJSON.generate_for('/characters/the_doctor/actors.json') do |api|
  api.add_item("/doctors/1.json") do |api|
    api.add_data "full-name", value: "William Hartnell"
  end
  api.add_item("/doctors/2.json") do |api|
    api.add_data "full-name", value: "Patrick Troughton"
  end
  api.add_item("/doctors/3.json") do |api|
    api.add_data "full-name", value: "Jon Pertwee"
  end
  api.add_item("/doctors/4.json") do |api|
    api.add_data "full-name", value: "Tom Baker"
  end
end

CollectionJSON.generate_for('/characters.json') do |api|
  api.add_item "/characters/the_doctor.json" do |api|
    api.add_link "/characters/the_doctor/actors.json", 'actors', embed: actors, render: 'link', prompt: "Actors"
  end
end
```

results in:

```
{
    "collection": {
        "href": "/characters.json",
        "embedded": [
            {
                "collection": {
                    "href": "/characters/the_doctor/actors.json",
                    "items": [
                        {
                            "href": "/doctors/1.json",
                            "data": [
                                {
                                    "name": "full-name",
                                    "value": "William Hartnell"
                                }
                            ]
                        },
                        {
                            "href": "/doctors/2.json",
                            "data": [
                                {
                                    "name": "full-name",
                                    "value": "Patrick Troughton"
                                }
                            ]
                        },
                        {
                            "href": "/doctors/3.json",
                            "data": [
                                {
                                    "name": "full-name",
                                    "value": "Jon Pertwee"
                                }
                            ]
                        },
                        {
                            "href": "/doctors/4.json",
                            "data": [
                                {
                                    "name": "full-name",
                                    "value": "Tom Baker"
                                }
                            ]
                        }
                    ]
                }
            }
        ],
        "items": [
            {
                "href": "/characters/the_doctor.json",
                "links": [
                    {
                        "href": "/characters/the_doctor/actors.json",
                        "rel": "actors",
                        "render": "link",
                        "prompt": "Actors"
                    }
                ]
            }
        ]
    }
}
```

Here's an example of a link on the root level being embedded:

```
pertwee = CollectionJSON.generate_for('/doctors/3.json') do |api|
  api.add_item("/doctors/3.json") do |api|
    api.add_data "full-name", value: "Jon Pertwee"
    api.add_data "first-appearance", value: '1970-01-03'
    api.add_data "last-appearance", value: '1974-06-08'
  end
end

CollectionJSON.generate_for('/doctors.json') do |api|
  api.add_link "/doctors/3.json", "incarnation", prompt: "Jon Pertwee", render: 'link', embed: pertwee
end
```

results in:

```
{
    "collection": {
        "href": "/doctors.json",
        "embedded": [
            {
                "collection": {
                    "href": "/doctors/3.json",
                    "items": [
                        {
                            "href": "/doctors/3.json",
                            "data": [
                                {
                                    "name": "full-name",
                                    "value": "Jon Pertwee"
                                },
                                {
                                    "name": "first-appearance",
                                    "value": "1970-01-03"
                                },
                                {
                                    "name": "last-appearance",
                                    "value": "1974-06-08"
                                }
                            ]
                        }
                    ]
                }
            }
        ],
        "links": [
            {
                "href": "/doctors/3.json",
                "rel": "incarnation",
                "render": "link",
                "prompt": "Jon Pertwee"
            }
        ]
    }
}
```

### Meta

Sometimes you have meta-data that doesn't belong in an item, is not a link, etc. Examples include:

* total search results
* results per page
* server response time

For those situations, we have added a base-level element 'meta'.


```json
{
  "collection":
  {
    "href": "/search?term=breach",
    "meta": 
    {
      "current_page": "12",
      "total_pages": "192",
      "result_count": "1917",
    }
  }
}
```

to add this to your CollectionJSON result:

```ruby
      CollectionJSON.generate_for('/search') do |api|
        api.add_meta('current_page', '12')
      end
```

Adding the same key twice will overwrite the previous values ... it's a hash, people.

### Template Validation
following [the existing Collection+JSON extension]:(https://github.com/mamund/collection-json/blob/master/extensions/template-validation.md) you can add 'required' and 'regexp' fields to the data elements of forms:

```ruby
CollectionJSON.generate_for('/starships') do |api|
  api.set_template do |api|
    api.add_data 'registry', required: true, regexp: "NCC-[0-9]{3,}"
  end
end
```
results in:

```json
{
    "collection": {
        "href": "/starships",
        "template": {
            "data": [
                {
                    "name": "registry",
                    "required": "true",
                    "regexp": "NCC-[0-9]{3,}"
                }
            ]
        }
    }
}
```

### Options

So there's no way to say 'here are the choices' as you would with <select><option>...</option></select>.

```ruby
      CollectionJSON.generate_for('/friends/') do |api|
        api.set_template do |api|
          api.add_data "force-side", options: [
                  {
                    value: 'dark',
                    prompt: 'Dark Side'
                  },
                  {
                    value: 'light',
                    prompt: 'Light Side'
                  }
          ]
        end
      end.to_json
```

will result in:

```json
      { "collection" : { "href" : "/friends/",
            "template" : { "data" : [ { "name" : "force-side",
                      "options" : [ { "prompt" : "Dark Side",
                            "value" : "dark"
                          },
                          { "prompt" : "Light Side",
                            "value" : "light"
                          }
                        ]
                    } ] }
          } 
      }
```
### Template Conditions

In HTML, sometimes you find yourself using javascript to hide and reveal fields based on answers provided elsewhere. If describing a sectional, how many sections? If it's a table, what are the dimensions? We've added conditions to nested templates, datum, and options.

#### Recursive Template Example

```ruby
CollectionJSON.generate_for('/planet.json') do |api|
  api.set_template do |api|
    api.add_data "history_of_tobacco", options: [{value: 'true'}, {value: 'false'}] do |api|
      api.add_template('Tobacco Usage', conditions: [{field: 'history_of_tobacco', value: 'true'}]) do |api|
        api.add_data "years_of_tobacco_usage", value_type: 'numeric'
        api.add_data "max_packs_per_day", value_type: 'numeric'
      end
    end
  end
end.to_json
```

results in:

```
{
    "collection": {
        "href": "/planet.json",
        "template": {
            "data": [
                {
                    "name": "history_of_tobacco",
                    "options": [
                        {
                            "value": "true"
                        },
                        {
                            "value": "false"
                        }
                    ],
                    "template": {
                        "conditions": [
                            {
                                "field": "history_of_tobacco",
                                "value": "true"
                            }
                        ],
                        "data": [
                            {
                                "name": "years_of_tobacco_usage",
                                "value_type": "numeric"
                            },
                            {
                                "name": "max_packs_per_day",
                                "value_type": "numeric"
                            }
                        ]
                    }
                }
            ]
        }
    }
}
```


#### Datum Example

We need a way to indicate whether a question is valid based on what was selected elsewhere.

```ruby
CollectionJSON.generate_for('/planet.json') do |api|
  api.set_template do |api|
    api.add_data "planet_class", options: [{value: 'M'}, {value: 'Y'}]
    api.add_data "subclass", conditions: [{field: "planet_class", value: 'm'}]
  end
end.to_json
```



#### Option Example

We needed a way to change the options based on what was selected elsewhere. 

```ruby
CollectionJSON.generate_for('/song_search') do |api|
  api.set_template do |api|
    api.add_data "artist", options: [
            {
              value: '12',
              prompt: 'Bob Marley',
              conditions: [
                {:field => 'genre', :value => 'Reggae'}
                {:field => 'instrument', :value => 'guitar'}
              ]
            },
            {
              value: '14',
              prompt: 'The Wailers',
              conditions: [
                {:field => 'genre', :value => 'Reggae'}
              ]
            },
            {
              value: '16',
              prompt: 'Miles Davis',
              conditions: [
                {:field => 'genre', :value => 'Jazz'},
                {:field => 'instrument', :value => 'trumpet'}
              ]
            }
    ]
  end
end.to_json
```


### Field-Specific Errors

So collection+JSON has this lame "Error" field. We feel like that's useful for "You aren't authorized to do that" and other flash-messagy kind of stuff. But When you want to provide feedback about a form submission, one bit of text isn't sufficient.

```ruby
      CollectionJSON.generate_for('/starships') do |api|
        api.set_template do |api|
          api.add_data "mode of", {
                    value: 'riverboat',
                    errors: [
                      'were meant to fly',
                      'hands up and touch the sky'
                    ]
          }
        end
      end
```

produces:

```json
{
    "collection": {
        "href": "/song_search",
        "template": {
            "data": [
                {
                    "name": "starships",
                    "errors": [
                      "were meant to fly",
                      "hands up and touch the sky"
                    ]
                }
            ]
        }
    }
}
```

### Template Recursion

This is the equivalent of HTML fieldsets. It allows you to group fields. Templates can be nested within data OR in sequence.

Although we used this to support follow-up questions, it could also be used to support sections.

#### Template Recursion In Sequence:

```ruby
      CollectionJSON.generate_for('/results.json') do |api|
        api.set_template do |api|
          api.add_data "gender"
          api.add_template(name: "smoking") do |api|
            api.add_data "history_of_smoking"
            api.add_data "packs_per_day_max"
          end
        end
      end
```

note that we use set_template on the collection, and add_template inside... per convention, add_* is used when there may be N of them... set_* is used when there can be only one.

produces:

```json
      {
          "collection": {
              "href": "/results.json",
              "template": {
                  "data": [
                      {
                          "name": "gender"
                      },
                      {
                          "name": "smoking",
                          "template": {
                              "data": [
                                  {
                                      "name": "history_of_smoking"
                                  },
                                  {
                                      "name": "packs_per_day_max"
                                  }
                              ]
                          }
                      }
                  ]
              }
          }
      }
```

#### Nested Template Recursion

This is basically the same thing as nested liste items.

```ruby
      CollectionJSON.generate_for('/results.json') do |api|
        api.set_template do |api|
          api.add_data("history_of_smoking", :value_type => "boolean", :value => 'yes') do |api|
            api.add_template do |api|
              api.add_data "packs_per_day_max"
              api.add_data "do_you_wanna_quit"
            end
          end
        end
      end
```

produces:

```js
{
    "collection": {
        "href": "/results.json",
        "template": {
            "data": [
                {
                    "name": "history_of_smoking",
                    "value_type": "boolean",
                    "value": "yes",


                    "template": {
                        "data": [
                            {
                                "name": "packs_per_day_max"
                            },
                            {
                                "name": "do_you_wanna_quit"
                            }
                        ]
                    }
                }
            ]
        }
    }
}
```

### Other Template Fields

#### Value Type 

Part validation, part how-do-I-collect-this, here are some values I would expect to be valid:

* string
* boolean
* date
* numeric
* email
* password
* text
* time
* file

#### Parameter

When you submit this back to the server, what parameter should be used? Although the Collection+JSON spec isn't clear on what parameter to use, the 'name' field seems like the most obvious option. Here we are being explicit.

      {
          "collection": {
              "href": "animals.json",
              "items": [
                  {
                      "href": "/surveys/1.json",
                      "data": [
                          {
                              "name": "description",
                              "value": "green with shell"
                          }
                      ]
                  }
              ],
              "template": {
                  "data": [
                      {
                          "name": "description",
                          "parameter": "animal[description]",
                          "value_type": "string",
                          "prompt": "Description"
                      },
                 ]
              }
          }
      }

### Related

Here, we've gone off-road a bit. If we were going to truly respect the collection+JSON style, this would be considerably more ... verbose. And we may still go that way. We're curious whether this more compact schema will work.

```json
{
    "collection": {
        "href": "/starships",
        "items": [
            {
                "href": "/starships/enterprise",
                "related":
                {
                    "officers": [
                        {
                            "name": "Picard",
                            "position": "Captain"
                        }
                    ]
                }
                
            }
        ]
    }
}
```


## We now return you to your regularly scheduled readme 

A lightweight gem to easily build and parse response objects with a MIME type of
'application/vnd.collection+json'.

Read http://amundsen.com/media-types/collection/ for more information about this
media type.

## Usage

### Building

Use ```CollectionJSON.generate_for``` to build a response object which you can
call ```to_json``` on.

```ruby
collection = CollectionJSON.generate_for('/friends/') do |builder|
  builder.add_link '/friends/rss', 'feed'
  user.friends.each do |friend|
    builder.add_item("/friends/#{friend.id}") do |item|
      item.add_data "full-name", value: friend.full_name
      item.add_data "email", value: friend.email
      item.add_link "/blogs/#{friend.id}", "blog", prompt: "Blog"
      item.add_link "/blogs/#{friend.id}", "avatar", prompt: "Avatar", render: "image"
    end
  end
  builder.add_query("/friends/search", "search", prompt: "Search") do |query|
    query.add_data "search"
  end
  builder.set_template do |template|
    template.add_data "full-name", prompt: "Full Name"
    template.add_data "email", prompt: "Email"
    template.add_data "blog", prompt: "Blog"
    template.add_data "avatar", prompt: "Avatar"
  end
end

collection.to_json
```

Output:

```javascript
{ "collection" :
  {
    "version" : "1.0",
    "href" : "http://example.org/friends/",
    
    "links" : [
      {"rel" : "feed", "href" : "http://example.org/friends/rss"}
    ],
    
    "items" : [
      {
        "href" : "http://example.org/friends/jdoe",
        "data" : [
          {"name" : "full-name", "value" : "J. Doe", "prompt" : "Full Name"},
          {"name" : "email", "value" : "jdoe@example.org", "prompt" : "Email"}
        ],
        "links" : [
          {"rel" : "blog", "href" : "http://example.org/blogs/jdoe", "prompt" : "Blog"},
          {
            "rel" : "avatar", "href" : "http://example.org/images/jdoe",
            "prompt" : "Avatar", "render" : "image"
          }
        ]
      },
      
      {
        "href" : "http://example.org/friends/msmith",
        "data" : [
          {"name" : "full-name", "value" : "M. Smith", "prompt" : "Full Name"},
          {"name" : "email", "value" : "msmith@example.org", "prompt" : "Email"}
        ],
        "links" : [
          {"rel" : "blog", "href" : "http://example.org/blogs/msmith", "prompt" : "Blog"},
          {
            "rel" : "avatar", "href" : "http://example.org/images/msmith",
            "prompt" : "Avatar", "render" : "image"
          }
        ]
      },
      
      {
        "href" : "http://example.org/friends/rwilliams",
        "data" : [
          {"name" : "full-name", "value" : "R. Williams", "prompt" : "Full Name"},
          {"name" : "email", "value" : "rwilliams@example.org", "prompt" : "Email"}
        ],
        "links" : [
          {"rel" : "blog", "href" : "http://example.org/blogs/rwilliams", "prompt" : "Blog"},
          {
            "rel" : "avatar", "href" : "http://example.org/images/rwilliams",
            "prompt" : "Avatar", "render" : "image"
          }
        ]
      }      
    ],
    
    "queries" : [
      {"rel" : "search", "href" : "http://example.org/friends/search", "prompt" : "Search",
        "data" : [
          {"name" : "q", "prompt" : "Search Query"}
        ]
      }
    ],
    
    "template" : {
      "data" : [
        {"name" : "full-name", "prompt" : "Full Name"},
        {"name" : "email", "prompt" : "Email"},
        {"name" : "blog", "prompt" : "Blog"},
        {"name" : "avatar", "prompt" : "Avatar"}
        
      ]
    }
  } 
}
```

### Parsing

CollectionJSON also helps you to consume APIs by parsing JSON strings:

```ruby
collection = CollectionJSON.parse(json)
collection.href # => "http://example.org/friends/"
collection.items.count # => 3
```

You can then build queries:

```ruby
collection.queries.first.build({'search' => 'puppies'}) # => "http://example.org/friends/search?q=puppies"
```

It also builds templates:

```ruby
built_template = collection.template.build({"full-name" => "Lol Cat", "email" => "lol@cats.com"})
built_template.to_json
```

Output:

```javascript
{
  "template" : {
    "data" : [
      {
        "name" : "full-name",
        "value" : "Lol Cat"
      },
      {
        "name" : "email",
        "value" : "lol@cats.com"
      }
    ]
  }
}
```

## Notes

Set the ```COLLECTION_JSON_HOST``` environment variable to automatically add
this to the href's. Eg. ```COLLECTION_JSON_HOST=http://example.org```

## Installation

Add this line to your application's Gemfile:

    gem 'collection-json'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install collection-json
