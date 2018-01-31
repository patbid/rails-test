class PaperMatchManual < ActiveRecord::Base

  self.table_name = 'paper_match_manual'

  def self.create_match_manual(page_id, image_id)
    self.create(paper_scanned_page_id: page_id, ms_image_id: image_id, type_id: 1)
  end

end

