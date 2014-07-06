module CollectionJSON
  class Builder
    def initialize(collection)
      @collection = collection
    end

    def set_error(params = {})
      @collection.error params
    end

    def add_link(href, rel, params = {})
      params.merge!({'rel' => rel, 'href' => href})
      @collection.links << Link.from_hash(params)
    end

    def add_meta(name, value)
      @collection.meta[name] = value
    end

    def add_item(href, params = {}, &block)
      params.merge!({'href' => href})
      @collection.items << Item.from_hash(params).tap do |item|
        if block_given?
          data = []
          links = []
	  related = {}
          item_builder = ItemBuilder.new(data, links, related)
          yield(item_builder)
          item.data data
          item.links links
	  item.related related
        end
      end
    end

    def add_query(href, rel, params = {}, &block)
      params.merge!({'href' => href, 'rel' => rel})
      @collection.queries << Query.from_hash(params).tap do |query|
        data = []
        query_builder = QueryBuilder.new(data)
        yield(query_builder) if block_given?
        query.data data
      end
    end

    def set_template(params = {}, &block)
      if block_given?
        data = params['data'] || []
        template_builder = TemplateBuilder.new(data)
        yield(template_builder) 
        params.merge!({'data' => data})
      end
      @collection.template params
    end
  end

  class ItemBuilder
    attr_reader :data, :links, :related

    def initialize(data, links, related)
      @data = data
      @links = links
      @related = related
    end

    def add_data(name, params = {})
      params.merge!({'name' => name})
      data << params
    end

    def add_related(rel, collection = [])
      related[rel] = collection
    end

    def add_link(href, rel, params = {})
      params.merge!({'rel' => rel, 'href' => href})
      links << params
    end
  end

  class QueryBuilder
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def add_data(name, params = {})
      params.merge!({'name' => name})
      data << params
    end
  end

  class DataBuilder
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def add_template(params = {}, &block)
      if block_given?
        t_data = params['data'] || []
        template_builder = TemplateBuilder.new(t_data)
        yield(template_builder) 
        params = ({'template' => params.merge({'data' => t_data})})
      end

      data << params
    end
  end
 
  class TemplateBuilder
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def add_data(name, params = {})
      params.merge!({'name' => name})
      
      if block_given?
        t_data = params['data'] || []
        data_builder = DataBuilder.new(t_data)
        yield(data_builder) 
        params.merge!(t_data.first) # hm.... 
      end

      data << params
    end

    def add_template(params = {}, &block)
      if block_given?
        t_data = params['data'] || []
        template_builder = TemplateBuilder.new(t_data)
        yield(template_builder) 
        params.merge!({'template' => {'data' => t_data}})
      end
      data << params
    end
  end
end
