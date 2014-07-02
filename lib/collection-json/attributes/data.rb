require_relative '../attribute'
require_relative 'option'

module CollectionJSON
  class Data < Attribute
    attribute :name
    attribute :value_type
    attribute :value
    attribute :prompt
    attribute :errors, default: []
    attribute :required, transform: lambda {|value| value.to_s}
    attribute :regexp
    attribute :options,
              transform:      lambda { |data| data.each.map { |d| Option.from_hash(d) }},
              default:        [],
              find_method:    {method_name: :datum, key: 'name'}
    attribute :template, transform: lambda { |template| Template.from_hash( template ) }
  end
end
