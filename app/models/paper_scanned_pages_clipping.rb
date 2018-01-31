class PaperScannedPagesClipping < ActiveRecord::Base
	self.table_name = "paper_scanned_pages_clipping"
	belongs_to :paper_scanned_page

  scope :paper_scanned_page, ->(spid) { where(paper_scanned_page_id: spid) }

end
