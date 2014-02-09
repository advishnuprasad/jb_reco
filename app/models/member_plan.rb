class MemberPlan < ActiveRecord::Base
  has_many :rentals
  has_many :returns
end