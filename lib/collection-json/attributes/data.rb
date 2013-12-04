require_relative '../attribute'

module CollectionJSON
  class Data < Attribute
    attribute :name
    attribute :value
    attribute :prompt
    attribute :options,
              transform:      lambda { |data| data.each.map { |d| Data.from_hash(d) }},
              default:        [],
              find_method:    {method_name: :datum, key: 'name'}
  end
end
