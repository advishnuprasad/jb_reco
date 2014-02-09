class Category < ActiveRecord::Base
  self.primary_key = :id
  has_many :titles
end
