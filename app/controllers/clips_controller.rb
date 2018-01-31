class ClipsController < ApplicationController

	require 'fileutils'

	def image
		@clip = PaperScannedPagesClipping.find(params[:id])
		send_file "#{@clip.clip_filename}", disposition: 'inline', type: 'application/jpg', x_sendfile: true
	end

	def create
		x = params[:x1].to_i
		y = params[:y1].to_i
		x1 = params[:x2].to_i
		y1 = params[:y2].to_i
		w = params[:w].to_i
		h = params[:h].to_i
		page = PaperScannedPage.find(params[:page_id].to_i)
		tcredit = params[:new_credit]
		flow = params[:flow].to_i
		siz = []
		if params[:double]
			imagedouble = params[:double]
			# on cherche la page suivante
			ps = PaperScannedPage.find_by(instance_id: page.instance_id, page_number: (page.page_number+1))
			page_ori = "#{Rails.root}/public/#{imagedouble}"
		else
			page_ori = "#{page.scanned_page_path}#{page.image_filename}"
		end
    s = ImageSize.path(page_ori).size
		siz = s.to_s.split('x')
		wm = siz[0].to_f
		ratio = wm/500
		x = x*ratio
		y = y*ratio
		w = w*ratio
		h = h*ratio
		x1 = x1*ratio
		y1 = y1*ratio
		last_clip = PaperScannedPagesClipping.paper_scanned_page(page.id).where(clip_type: 'manual').order('clip_number desc').first
		clip_number = last_clip.blank? ? 1 : last_clip.clip_number.to_i + 1
		clip_name = page.image_filename.gsub(".jpg","")
		clip_count = page.manual_clip_count + 1
		url_clip = "#{page.scanned_page_path}clipping/#{clip_name}_#{clip_number}_#{clip_count}-manual.jpg"
		img_ori = Magick::Image.read(page_ori).first
		img_ori.crop!(x.to_i,y.to_i,w.to_i,h.to_i)
		img_ori.write(url_clip)
		new_clip = PaperScannedPagesClipping.new(paper_scanned_page_id: page.id, clip_number: clip_number, credit_id: flow,
																						 clip_type: 'manual', clip_selected: 1, clip_filename: url_clip,
																						 position_x0: x, position_y0: y, position_x1: x1, position_y1: y1)
    if new_clip.save
      page.update_attributes(manual_clip_count: clip_count)
      if tcredit == "image"
				if flow == 0 && params[:new_flow] != ""
					flow = PaperCredit.maxi
					PaperCredit.new_flow(flow, params[:new_flow])
				end
				new_clip.update_attributes(credit_id: flow)
			end
    else
      redirect_to action: 'errors'
    end

    if ps
      last_clip = PaperScannedPagesClipping.paper_scanned_page(ps.id).where(clip_type: 'manual').order('clip_number desc').first
      clip_number = last_clip.blank? ? 1 : last_clip.clip_number.to_i + 1
      clip_name = ps.image_filename.gsub(".jpg","")
      clip_count = ps.manual_clip_count + 1
      url_clip = "#{ps.scanned_page_path}clipping/#{clip_name}_#{clip_number}_#{clip_count}-manual.jpg"
      img_ori.write(url_clip)
      new_clip = PaperScannedPagesClipping.new(paper_scanned_page_id: ps.id, clip_number: clip_number, credit_id: flow,
                                               clip_type: 'manual', clip_selected: 1, clip_filename: url_clip,
                                               position_x0: x, position_y0: y, position_x1: x1, position_y1: y1)
      if new_clip.save
			  ps.update_attributes(manual_clip_count: clip_count)
			  if tcredit == "image" and flow > 0
				  new_clip.update_attributes(credit_id: flow)
			  end
		  else
			  redirect_to action: 'errors'
      end
    end
    img_ori.destroy!
    redirect_to controller: 'scanned_pages', action: 'index', from: 'create', parution: params[:parution], filtre: params[:filtre], period: params[:period], page: params[:page], tcredit: tcredit
	end

	def keyw
		keyword = params[:keyw]
		clip_id = params[:mon_id]
		PaperScannedPagesClipping.update(clip_id, keywords: keyword, keywords_exported: 0)
		redirect_to controller: 'scanned_pages', action: 'index', from: 'create', parution: params[:parution], filtre: params[:filtre], period: params[:period], page: params[:page]
	end

	def errors
		flash[:alert] = "Erreur : Clip non enregistré"
	end

	def update_nb_credit(flow, page, nb)
		pspc = PaperScannedPagesCredit.find_by_credit_id_and_scanned_page_id(flow, page)
		if pspc.nil?
			PaperScannedPagesCredit.create(credit_id: flow, scanned_page_id: page, number: nb)
		else
			pspc.update_attributes(number: nb)
		end
	end

end
