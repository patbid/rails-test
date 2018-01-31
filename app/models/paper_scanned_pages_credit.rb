class PaperScannedPagesCredit < ActiveRecord::Base

	belongs_to :paper_scanned_page, foreign_key: 'scanned_page_id', class_name: 'PaperScannedPage'

  scope :scanned_page, ->(pid) { where(scanned_page_id: pid) }
end
