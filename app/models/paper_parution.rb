class PaperParution < ActiveRecord::Base

  belongs_to :paper_publication, foreign_key: 'instance_id', class_name: 'PaperPublication'
  has_many :paper_scanned_pages, foreign_key: 'instance_id', class_name: 'PaperScannedPage'
end
