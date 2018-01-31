class PaperPublicationsPeriodicity < ActiveRecord::Base

	self.table_name = "paper_publications_periodicity"
	has_many :paper_publications, primary_key: 'id', foreign_key: 'periodicity'
end

