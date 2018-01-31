class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :rememberable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
       :recoverable, :timeoutable, :trackable
	has_many :matching_images, foreign_key: "validation_by_user_id", class_name: 'MatchingImage'
  has_many :paper_matching_images, foreign_key: "validation_by_user_id", class_name: 'PaperMatchingImage'
  has_many :user_controls

end
