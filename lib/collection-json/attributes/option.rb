require_relative '../attribute'

module CollectionJSON
  class Option < Attribute
    attribute :value
    attribute :prompt
    attribute :results
    attribute :conditions
  end
end
