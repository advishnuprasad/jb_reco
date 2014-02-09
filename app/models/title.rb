class Title < ActiveRecord::Base
  self.primary_key = :id
  has_many :books
  has_many :rentals, :foreign_key => :legacy_title_id, :primary_key => :id
  belongs_to :category, :primary_key => :id
end