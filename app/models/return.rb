class Return < ActiveRecord::Base
  set_date_columns :issue_date, :expiry_date, :return_date
  has_one :rental, :foreign_key => :id
  attr_accessor :username, :user_id, :book_number
  belongs_to :book
  belongs_to :member_plan, :touch => :last_book_returned_date
  belongs_to :title, :foreign_key => 'legacy_title_id'
end