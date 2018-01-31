class Image < ActiveRecord::Base
  has_many :matching_images
  has_many :paper_matching_images

end

