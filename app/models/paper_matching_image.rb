class PaperMatchingImage < ActiveRecord::Base

	belongs_to :user, foreign_key: "validation_by_user_id", class_name: 'User'
	belongs_to :paper_scanned_page
	has_many :paper_scanned_pages_clippings, foreign_key: "clip_id", class_name: 'PaperScannedPagesClipping'
	belongs_to :image

	scope :done, -> { where(superposition_done: 1, validation_done: 0) }
  scope :processed, -> { where(is_being_processed: 0) }
  scope :error, ->(err) { where(error: err) }
  scope :cliptype, ->(ctype) { where(clip_type: ctype) }
  scope :most_recent, -> (limit) { order("created_at desc").limit(limit) }
end

