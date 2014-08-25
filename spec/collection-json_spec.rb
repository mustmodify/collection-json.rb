require 'spec_helper'
require 'collection-json'

describe CollectionJSON do
  describe :generate_for do
    before :each do
      @friends = [
        {
          "id"        =>  "jdoe",
          "full-name" =>  "J. Doe",
          "email"     =>  "jdoe@example.org"
        },
        {
          "id"        =>  "msmith",
          "full-name" =>  "M. Smith",
          "email"     =>  "msmith@example.org"
        },
        {
          "id"        =>  "rwilliams",
          "full-name" =>  "R. Williams",
          "email"     =>  "rwilliams@example.org"
        }
      ]
    end

    it 'should embed objects from root-level links' do
      pertwee = CollectionJSON.generate_for('/doctors/3.json') do |api|
        api.add_item("/doctors/3.json") do |api|
          api.add_data "full-name", value: "Jon Pertwee"
          api.add_data "first-appearance", value: '1970-01-03'
          api.add_data "last-appearance", value: '1974-06-08'
	end
      end

      CollectionJSON.generate_for('/doctors.json') do |api|
        api.add_link "/doctors/3.json", "incarnation", prompt: "Jon Pertwee", render: 'link', embed: pertwee
      end.to_json.should == %|{\"collection\":{\"href\":\"/doctors.json\",\"embedded\":[{\"collection\":{\"href\":\"/doctors/3.json\",\"items\":[{\"href\":\"/doctors/3.json\",\"data\":[{\"name\":\"full-name\",\"value\":\"Jon Pertwee\"},{\"name\":\"first-appearance\",\"value\":\"1970-01-03\"},{\"name\":\"last-appearance\",\"value\":\"1974-06-08\"}]}]}}],\"links\":[{\"href\":\"/doctors/3.json\",\"rel\":\"incarnation\",\"render\":\"link\",\"prompt\":\"Jon Pertwee\"}]}}|
    end

    it 'should embed objects from item-level links' do
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
      end.to_json.should == %|{\"collection\":{\"href\":\"/characters.json\",\"embedded\":[{\"collection\":{\"href\":\"/characters/the_doctor/actors.json\",\"items\":[{\"href\":\"/doctors/1.json\",\"data\":[{\"name\":\"full-name\",\"value\":\"William Hartnell\"}]},{\"href\":\"/doctors/2.json\",\"data\":[{\"name\":\"full-name\",\"value\":\"Patrick Troughton\"}]},{\"href\":\"/doctors/3.json\",\"data\":[{\"name\":\"full-name\",\"value\":\"Jon Pertwee\"}]},{\"href\":\"/doctors/4.json\",\"data\":[{\"name\":\"full-name\",\"value\":\"Tom Baker\"}]}]}}],\"items\":[{\"href\":\"/characters/the_doctor.json\",\"links\":[{\"href\":\"/characters/the_doctor/actors.json\",\"rel\":\"actors\",\"render\":\"link\",\"prompt\":\"Actors\"}]}]}}|
    end

    it 'should generate an object with the attributes we expect' do
      response = CollectionJSON.generate_for('/friends/') do |builder|
        builder.add_link '/friends/rss', 'feed'
        @friends.each do |friend|
          builder.add_item("/friends/#{friend['id']}") do |item|
            item.add_data "full-name", value: friend["full-name"]
            item.add_data "email", value: friend["email"]
            item.add_link "/blogs/#{friend['id']}", "blog", prompt: "Blog"
            item.add_link "/blogs/#{friend['id']}", "avatar", prompt: "Avatar", render: 'image'
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

      response.href.should eq('/friends/')
      response.links.first.href.should eq("/friends/rss")
      response.link('feed').href.should eq("/friends/rss")
      response.items.length.should eq(3)
      response.items.first.data.length.should eq(2)
      response.items.first.datum('full-name').value.should eq("J. Doe")
      response.items.first.links.length.should eq(2)
      response.items.first.href.class.should eq(String)
      response.template.data.length.should eq(4)
      response.queries.length.should eq(1)
      response.queries.first.href.should eq("/friends/search")
      response.queries.first.data.length.should eq(1)
      response.queries.first.data.first.name.should eq('search')
      response.query('search').prompt.should eq('Search')
    end

    it 'includes a "meta" top-level element' do
      response = CollectionJSON.generate_for('/search') do |builder|
	      builder.add_meta('total_results', 33)
      end

      response.meta['total_results'].should == 33
      response.to_json.should == %|{"collection":{"href":"/search","meta":{"total_results":33}}}|
    end

    it 'includes the unapproved but totally necessary "options" attribute on data.' do
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
      end.to_json.should == %|{"collection":{"href":"/friends/","template":{"data":[{"name":"force-side","options":[{"value":"dark","prompt":"Dark Side"},{"value":"light","prompt":"Light Side"}]}]}}}|
    end

    it 'includes "group" as an option attribute.' do
      CollectionJSON.generate_for('/friends/') do |api|
        api.set_template do |api|
          api.add_data "artist", options: [
                  {
                    value: '12',
                    prompt: 'Bob Marley',
                    conditions: [
                      {:field => 'genre', :value => 'Reggae'},
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
      end.to_json.should == %|{\"collection\":{\"href\":\"/friends/\",\"template\":{\"data\":[{\"name\":\"artist\",\"options\":[{\"value\":\"12\",\"prompt\":\"Bob Marley\",\"conditions\":[{\"field\":\"genre\",\"value\":\"Reggae\"},{\"field\":\"instrument\",\"value\":\"guitar\"}]},{\"value\":\"14\",\"prompt\":\"The Wailers\",\"conditions\":[{\"field\":\"genre\",\"value\":\"Reggae\"}]},{\"value\":\"16\",\"prompt\":\"Miles Davis\",\"conditions\":[{\"field\":\"genre\",\"value\":\"Jazz\"},{\"field\":\"instrument\",\"value\":\"trumpet\"}]}]}]}}}|
    end

    it 'knows about template validation' do
      CollectionJSON.generate_for('/starships') do |api|
        api.set_template do |api|
          api.add_data 'registry', required: true, regexp: "NCC-[0-9]{3,}"
	end
      end.to_json.should == %|{"collection":{"href":"/starships","template":{"data":[{"name":"registry","required":"true","regexp":"NCC-[0-9]{3,}"}]}}}| 
    end

    it 'includes field-specific errors in the template' do
      CollectionJSON.generate_for('/starships') do |api|
        api.set_template do |api|
          api.add_data 'registry', errors: ['must follow the pattern NCC-xxxx']
	end
      end.to_json.should == %|{"collection":{"href":"/starships","template":{"data":[{"name":"registry","errors":["must follow the pattern NCC-xxxx"]}]}}}|
    end

    it 'includes "related" on an item' do
      CollectionJSON.generate_for('/starships') do |api|
        api.add_item('/starships/enterprise') do |api|
          api.add_related( "officers", [
	     {
               name: 'Picard',
               position: 'Captain'
	     }])
	end
      end.to_json.should == "{\"collection\":{\"href\":\"/starships\",\"items\":[{\"href\":\"/starships/enterprise\",\"related\":{\"officers\":[{\"name\":\"Picard\",\"position\":\"Captain\"}]}}]}}"
    end
    
    it 'allows the "value type" attribute a la HL7' do
      CollectionJSON.generate_for('/facebook') do |api|
        api.set_template do |api|
          api.add_data "bff_email", value_type: 'email'
	end
      end.to_json.should == %|{"collection":{"href":"/facebook","template":{"data":[{"name":"bff_email","value_type":"email"}]}}}|
    end

    it 'allows recursive templates in sequence' do
      endpoint = CollectionJSON.generate_for('/results.json') do |api|
        api.set_template do |api|
          api.add_data "gender"
          api.add_template(:name => "smoking") do |api|
            api.add_data "history_of_smoking"
            api.add_data "packs_per_day_max"
          end
        end
      end

      endpoint.to_json.should == "{\"collection\":{\"href\":\"/results.json\",\"template\":{\"data\":[{\"name\":\"gender\"},{\"name\":\"smoking\",\"template\":{\"data\":[{\"name\":\"history_of_smoking\"},{\"name\":\"packs_per_day_max\"}]}}]}}}"
    end

    it 'allows nested recursive templates' do
      endpoint = CollectionJSON.generate_for('/results.json') do |api|
        api.set_template do |api|
          api.add_data("history_of_smoking", :value_type => 'boolean', :value => 'yes') do |api|
            api.add_template do |api|
              api.add_data "packs_per_day_max"
              api.add_data "do_you_wanna_quit"
            end
	  end
        end
      end

      endpoint.to_json.should == "{\"collection\":{\"href\":\"/results.json\",\"template\":{\"data\":[{\"name\":\"history_of_smoking\",\"value_type\":\"boolean\",\"value\":\"yes\",\"template\":{\"data\":[{\"name\":\"packs_per_day_max\"},{\"name\":\"do_you_wanna_quit\"}]}}]}}}" 

    end

    describe 'conditions' do
      it 'works for templates' do
        endpoint = CollectionJSON.generate_for('/planet.json') do |api|
          api.set_template do |api|
            api.add_data "history_of_tobacco", options: [{value: 'true'}, {value: 'false'}] do |api|
              api.add_template(conditions: [{field: 'history_of_tobacco', value: 'true'}]) do |api|
                api.add_data "years_of_tobacco_usage", value_type: 'numeric'
                api.add_data "max_packs_per_day", value_type: 'numeric'
              end
            end
          end
        end 

        endpoint.to_json.should == "{\"collection\":{\"href\":\"/planet.json\",\"template\":{\"data\":[{\"name\":\"history_of_tobacco\",\"options\":[{\"value\":\"true\"},{\"value\":\"false\"}],\"template\":{\"conditions\":[{\"field\":\"history_of_tobacco\",\"value\":\"true\"}],\"data\":[{\"name\":\"years_of_tobacco_usage\",\"value_type\":\"numeric\"},{\"name\":\"max_packs_per_day\",\"value_type\":\"numeric\"}]}}]}}}" 
      end
    end
  end


  describe :parse do
    before(:all) do
      json = '{"collection": {
        "href": "http://www.example.org/friends",
        "links": [
          {"rel": "feed", "href": "http://www.example.org/friends.rss"}
        ],
        "items": [
          {
            "href": "http://www.example.org/m.rowe",
            "data": [
              {"name": "full-name", "value": "Matt Rowe"}
            ]
          }
        ]
      }}'
      @collection = CollectionJSON.parse(json)
    end

    it 'should parse JSON into a Collection' do
      @collection.class.should eq(CollectionJSON::Collection)
    end

    it 'should have correct href' do
      @collection.href.should eq("http://www.example.org/friends")
    end

    it 'should handle the nested attributes' do
      @collection.items.first.href.should eq("http://www.example.org/m.rowe")
      @collection.items.first.data.count.should eq(1)
    end

    it 'should be able to be reserialized' do
      @collection.to_json.class.should eq(String)
    end

    it 'should have the correct link' do
      @collection.links.first.href.should eq("http://www.example.org/friends.rss")
    end
  end
end
