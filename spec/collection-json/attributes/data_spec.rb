require 'spec_helper'
require 'collection-json/attributes/data'

describe CollectionJSON::Data do
  it 'accepts "conditions" attribute' do
    CollectionJSON::Data.from_hash(conditions: [{field: 'description', value: 'true'}]).to_json.should == "{\"conditions\":[{\"field\":\"description\",\"value\":\"true\"}]}"
  end

  it 'displays value "false"' do
    CollectionJSON::Data.from_hash(value: false).to_json.should == "{\"value\":false}"
  end
end
