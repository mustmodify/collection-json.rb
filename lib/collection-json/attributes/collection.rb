require_relative '../attribute'
require_relative 'link'
require_relative 'item'
require_relative 'query'
require_relative 'error'
require_relative 'template'

module CollectionJSON
  class Collection < Attribute
    root_node :collection
    attribute :href, transform: URI
    attribute :embedded
    attribute :version
    attribute :links,
              transform:  lambda { |links| links.each.map { |l| Link.from_hash(l) }},
              default:    [],
              find_method:    :link
    attribute :items,
              transform:  lambda { |items| items.each.map { |i| Item.from_hash(i) }},
              default:    []
    attribute :queries,
              transform:  lambda { |queries| queries.each.map { |q| Query.from_hash(q) }},
              default:    [],
              find_method:    :query
    attribute :template, transform: lambda { |template| Template.from_hash(template) }
    attribute :meta, default: {}
    attribute :error, transform: lambda { |error| Error.from_hash(error) }

    def embedded(atts = {})
      x = [].tap do |out|
        links.each do |link|
          link.embedded.each do |item|
            out.push(item)
          end
	end

	items.each do |item|
          item.links.each do |link|
            link.embedded.each do |item|
              out.push(item)
            end
          end
	end
      end
    end
  end
end
