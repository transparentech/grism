module Mongoose

class MongooseError < StandardError
end

class RecordNotFound < MongooseError
end

end
