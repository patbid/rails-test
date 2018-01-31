class PaperScannedPage < ActiveRecord::Base

	belongs_to :paper_parution, foreign_key: 'instance_id', class_name: 'PaperParution'
	has_many :paper_matching_images
	has_many  :paper_scanned_pages_clipping, dependent: :destroy
	has_many  :paper_scanned_pages_credits, foreign_key: 'scanned_page_id', class_name: 'PaperScannedPagesCredit', dependent: :destroy

  scope :instance, ->(iid) { where(instance_id: iid) }
  scope :page_no, ->(pno) { where(page_number: pno) }

end
