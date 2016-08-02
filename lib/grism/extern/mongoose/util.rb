# Credit for these utility methods goes completely to Logan Capaldo.

module Mongoose

module Util
  SINGULAR_TO_PLURAL = Hash.new { |h, k| h[k] = k.to_s + 's' }
  PLURAL_TO_SINGULAR = Hash.new do |h, k| 
                         h[k] =  if md = k.to_s.match(/\A(.*)s\z/)
                                   md[1]
                                 else
                                   raise(ArgumentError, "Please use " +
                                    "plural_form for this special case")
                                 end
                       end

  SPECIAL_PLURALIZATION_CASES = { "child" => "children", "person" => "people",
  "mouse" => "mice" }
  
  SINGULAR_TO_PLURAL.update SPECIAL_PLURALIZATION_CASES
  PLURAL_TO_SINGULAR.update SPECIAL_PLURALIZATION_CASES.invert


                                                        
# converts from things like user_name to things like UserName
def self.us_case_to_class_case(name)
  name.to_s.split(/_/).map do |word|
    word.capitalize
  end.join
end

# converts from things like UserName to things like user_name
def self.class_case_to_us_case(name)
  name.split(/(?=[A-Z])/).map { |s| s.downcase }.join('_')
end

# Adds an s
def self.pluralize(name)
  SINGULAR_TO_PLURAL[name]
end

# chops an s
def self.singularize(name)
  PLURAL_TO_SINGULAR[name]
end

def self.col_name_for_class(name)
  class_case_to_us_case(name) + "_id"
end

def self.class_name_for_col(name)
  us_case_to_class_case(name.sub(/_id\z/, ''))
end

end

end
