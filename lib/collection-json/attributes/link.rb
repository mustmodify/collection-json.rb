require_relative '../attribute'

module CollectionJSON
  class Link < Attribute
    attribute :href, transform: URI
    attribute :rel
    attribute :name
    attribute :render
    attribute :prompt

    def embed(collection=nil)
      self.embedded.push( collection ) 
    end

    def embedded
      @embedded ||= []
    end
  end
end
