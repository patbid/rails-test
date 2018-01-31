class PaperPublication < ActiveRecord::Base

	belongs_to :paper_publications_periodicity, foreign_key: 'periodicity', primary_key: 'id'
	has_many :paper_parutions, foreign_key: 'instance_id', class_name: 'PaperParution'
end
