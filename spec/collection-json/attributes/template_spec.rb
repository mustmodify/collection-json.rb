require 'spec_helper'
require 'collection-json/attributes/template'

describe CollectionJSON::Template do
  before(:all) do
    @hash = {
      'data' => [
        {
          'name' => 'full-name',
          'prompt' => 'Full name'
        },
        {
          'name' => 'email',
          'prompt' => 'Email'
        }
      ]
    }
  end

  describe :build do
    it 'should build correctly' do
      template = CollectionJSON::Template.from_hash(@hash)
      result = template.build({
        'email' => 'test@example.com',
        'full-name' => 'Test Example'
      })
      json = result.to_json
      hash = JSON.parse(json)
      hash['template']['data'].length.should eq(2)
      hash['template']['data'].first.keys.length.should eq(2)
    end
  end

  it 'accepts "parameter" attribute' do
    CollectionJSON::Template.from_hash(data: [{parameter: 'animal[description]', name: 'description'}]).to_json.should == "{\"data\":[{\"name\":\"description\",\"parameter\":\"animal[description]\"}]}"
  end

  it 'accepts "conditions" attribute' do
    CollectionJSON::Template.from_hash(conditions: [{field: 'description', value: 'true'}]).to_json.should == "{\"conditions\":[{\"field\":\"description\",\"value\":\"true\"}]}"
  end
end
