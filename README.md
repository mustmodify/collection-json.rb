# CollectionJSON

## Forked Changes

In the process of using collection+JSON for an API, our team found we had certain needs that weren't being met. We have added non-canon elements to collection+JSON in this repo. We have tried to do so responsibly, but it's important to note that this is NOT per Collection+JSON spec. But it is good stuff, and we think it's useful.

* meta
* template validations
* template options
* template option conditions
* template errors
* template recursion
* template value types
* related ( alpha )

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
### Options have conditions.

This isn't in HTML... but we don't have javascript. We needed a way to change the options based on what was selected elsewhere. 

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

```ruby
      CollectionJSON.generate_for('/results.json') do |api|
        api.set_template do |api|
          api.add_data "history_of_smoking" do |api|
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


### Value Types

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
