module Mongoose

class Property
  attr_reader :property_name, :subquery_no, :subquery_type, :comparison, :arg
  def initialize(name, query, subquery_no, subquery_type)
    @property_name = name
    @query = query
    @subquery_no = subquery_no
    @subquery_type = subquery_type
  end

  [:>, :<=, :==, :<=, :<, :between, :one_of].each do |comparison|
    define_method(comparison) do |*arg|
      @comparison = comparison
      @arg = arg
      @query.add_predicate(self)
    end
  end

end


class Query
  attr_reader :predicates
  def initialize
    @predicates = []
    @subquery_type = :and
    @subquery_no = 0
  end

  def find(&block)
    yield self
  end

  def add_predicate(pred)
    @predicates << pred
  end

  def method_missing(name, *args)
    @subquery_no += 1 if @subquery_type == :and
    Property.new(name, self, @subquery_no, @subquery_type)
  end

  def any(&block)
    @subquery_type = :or
    @subquery_no += 1
    yield
    @subquery_type = :and
  end
end

end
