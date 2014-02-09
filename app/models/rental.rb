class Rental < ActiveRecord::Base
  belongs_to :member_plan
  has_one :title, :primary_key => :legacy_title_id, :foreign_key => :id
end