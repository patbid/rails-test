module ApplicationHelper


	def border_color(page)
		color = "#fff"
		color = "DarkRed" if page.manual_validation_done === false
		color = "DarkGreen" if page.manual_validation_done === true
		color = "DarkBlue" if page.clip_requested == 1
		color
	end

	def nb_pages(u)
		PaperScannedPage.where(user_id: u).count
	end

	def email_cntrl(u_id)
		User.find(u_id).email
	end

	def pub_id(psp_id)
		PaperParution.joins(:paper_scanned_pages).where( paper_scanned_pages: { id: psp_id } ).pluck('paper_parutions.instance_id').first
	end

	def pub_name(psp_id)
		PaperPublication.joins(:paper_parutions).joins('inner join paper_scanned_pages on paper_parutions.id=paper_scanned_pages.instance_id').where( paper_scanned_pages: { id: psp_id } ).pluck('paper_publications.publication_name').first
	end

	def paru_date(psp_id)
		PaperParution.joins(:paper_scanned_pages).where( paper_scanned_pages: { id: psp_id } ).pluck('paper_parutions.publication_date').first
	end

	def no_page(psp_id)
		PaperScannedPage.where(id: psp_id).pluck(:page_number).first
	end

	def nb_imgs(psp_id, clip_id)
		if psp_id == 0
      PaperMatchingImage.where(clip_id: clip_id).count
    else
      PaperMatchingImage.where(paper_scanned_page_id: psp_id, clip_id: clip_id).count
    end
	end

	def nb_clips(psp_id)
		PaperScannedPage.find(psp_id).clip_selected_count
  end

  def flow_name(credit_id)
    PaperCredit.find_by_flow_id(credit_id).flow_name
  end

  def get_sk(clip_id, s_k)
    credit = PaperScannedPagesClipping.find(clip_id).credit_id
    styl = ""
    unless credit.nil? || PaperCredit.find_by_flow_id(credit).nil?
      styl = "border:2px solid darkred" if PaperCredit.find_by_flow_id(credit).string_key == s_k
    end
    styl
  end
end
