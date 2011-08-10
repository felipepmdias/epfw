class Feedback < DaText
  validates_presence_of :email, :text
  belongs_to :user
end
