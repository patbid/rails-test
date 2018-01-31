class UserControl < ActiveRecord::Base

  belongs_to :user

  def self.create_user(uid)
    self.create(user_id: uid, web_begin_w: Time.now, web_end_w: Time.now)
  end

end

