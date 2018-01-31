class ScannedPagesController < ApplicationController

	before_action :authenticate_user!

	def index
		@filter = 2
		@sel_period = 0
		next_page = 0
		next_paru = -1
		parution = 0
		@tcredit = params[:tcredit]? params[:tcredit] : "sans"
		if params[:from]
			@filter = params[:filtre].to_i
			@sel_period = params[:period].to_i
			parution = params[:parution].to_i
			next_page = params[:page].to_i
			next_paru = parution
		else
			unless params[:filtre].blank?
				@filter = params[:filtre].to_i
				@sel_period = params[:period].to_i
				next_page = params[:next_page].to_i
				next_paru = params[:next_paru].to_i
				next_page = (params[:page].to_i - 1) if params[:page].to_i != params[:next_page].to_i

				if params[:parution].blank?
					parution = params[:current_paru].to_i
				else
					parution = params[:parution].to_i
					next_page = 0 if parution != params[:current_paru].to_i
				end
				if @filter != params[:current_filter].to_i # on change de filtre
					next_page = 0
					next_paru = -1
					parution = 0
				end
				if @sel_period != params[:current_period].to_i
					next_page = 0
					next_paru = -1
					parution = 0
				end
			end
		end
		if params[:keyw]
			keyword_done = PaperParution.find(parution).keyword_done
			if keyword_done == 3
				Flash[:alert] = "Indexation en cours ..."
			else
				PaperScannedPagesClipping.joins(:paper_scanned_page).where(paper_scanned_pages: { instance_id: parution }, keyword_done: 1).collect{ |c| c.update_attributes(keyword_done: 0) }
				clips = PaperScannedPagesClipping.joins(:paper_scanned_page).select('paper_scanned_pages_clipping.id as clip_id, paper_scanned_pages.page_number as page,
                                          keywords, credit_id as credit, paper_scanned_pages_clipping.paper_scanned_page_id as pid').where('instance_id = ? and keywords_exported = ? and keywords != ?', parution, 0, "")
				clips.each do |clip|
					PaperScannedPagesClipping.update(clip.clip_id, keywords_exported: 1, keyword_done: 1)
					vars = {}
					vars["parution_id"] = parution
					vars["clip_id"] = clip.clip_id
					vars["page_no"] = clip.page
					vars["credit"] = ""
					if clip.credit == 0
						PaperScannedPagesCredit.scanned_page(clip.pid).collect{ |pspc| vars["credit"] += "#{PaperCredit.find_by(flow_id: pspc.credit_id).string_key},"}
						vars["credit"].chop! unless vars["credit"].blank?
					else
						vars["credit"] = PaperCredit.find_by(flow_id: clip.credit).string_key
					end
					vars["keywords"] = clip.keywords
					json_vars = vars.to_json
					json_filename = "clipping_"+Time.now.strftime("%Y%m%d-%H%M%S")+"#{clip.clip_id}.json"
					File.open("/tmp/#{json_filename}",'wb') do |f|
						f.write(json_vars)
					end
					::Net::SCP.upload!("94.23.216.226", "pix", "/tmp/#{json_filename}", "/var/www/pix/current/public/clipping/#{json_filename}", ssh: { password: "pa05la03" })
				end
				PaperParution.update(parution, keyword_done: 1)
			end
		end

    PaperMatchManual.create_match_manual(params[:page_id].to_i, params[:msid]) if params[:ms_img]
		update_ri(parution) if params[:RI]
    if params[:double]
			sp = PaperScannedPage.find(params[:page_id])
			# on cherche la page suivante
			ps = PaperScannedPage.instance(sp.instance_id).page_no(sp.page_number+1).first
			unless ps.nil?
				@image_double = "dble_#{sp.id}.jpg"
				s = ImageSize.path("#{sp.scanned_page_path}#{sp.image_filename}").size
				siz = s.to_s.split('x')
				s2 = ImageSize.path("#{ps.scanned_page_path}#{ps.image_filename}").size
				siz2 = s2.to_s.split('x')
				wm = siz[0].to_i + siz2[0].to_i
				ym = siz[1].to_i + siz2[1].to_i
				image_double = Magick::ImageList.new("#{sp.scanned_page_path}#{sp.image_filename}", "#{ps.scanned_page_path}#{ps.image_filename}").montage do |mont|
					mont.geometry = "#{wm}x#{ym}+0+0"
				end
				image_double.write("#{Rails.root}/public/#{@image_double}")
			end
		end
		next_page = 0 if params[:pageprem]
		@tab_filters = ["automatic_clip_done = 1", "paper_parutions.clip_done=1 and paper_publications.manual_validation=0", "paper_publications.manual_validation = 1 and
paper_parutions.clip_done = 0", "paper_parutions.clip_done = 1 and paper_publications.manual_validation=1 and visualrecognition_done = 0", "visualrecognition_done = 1"]
		sql_period = ""
		sql_period = " and periodicity = #{@sel_period}" if @sel_period > 0
		@ind_parus = []
		ind_parus = []
		@total_pages = 0
		PaperParution.joins(:paper_publication).where( "#{@tab_filters[@filter]}#{sql_period}").order('paper_publications.title').collect{ |sp| ind_parus << sp.id }
		ind_parus.each do |p|
			nb = PaperScannedPage.instance(p).count
			@ind_parus << p
			@total_pages = @total_pages + nb
		end
		if params[:prec]
			next_page = next_page - 2
			next_paru = next_paru -1 if next_page < 1
		end
		@parus = PaperParution.joins(:paper_publication).where("paper_parutions.id in (?) and #{@tab_filters[@filter]}#{sql_period}", @ind_parus).order('paper_publications.title, publication_date')
		if parution > 0
			@parution = PaperParution.find(parution)
		elsif next_paru == -1 && next_page == 0
			parution = PaperParution.joins(:paper_publication).where("#{@tab_filters[@filter]}#{sql_period} and active = 1").count
			@parution = PaperParution.joins(:paper_publication).where("#{@tab_filters[@filter]}#{sql_period} and active = 1").order('paper_publications.title').first unless parution == 0
		else
			@parution = PaperParution.find(@ind_parus[next_paru])
		end
		if parution == 0
			@erreur = "pas parutions disponibles pour ces critères"
			@next_page == 0
		elsif @ind_parus.blank?
			@erreur = "pas de pages disponibles pour ces critères"
			@next_page == 0
		else
			@pages = []
			PaperScannedPage.instance(@parution.id).order(:page_number).collect{ |sp| @pages << sp.id }
			@pagesok = []
			(0..(@pages.count-1)).each{|i| @pagesok[i] = ''}
			(0..(@pages.count-1)).each{|i| @pagesok[i] = ' *' if PaperScannedPage.find(@pages[i]).manual_validation_done == 0 || PaperScannedPage.find(@pages[i]).manual_validation_done === false }
			@nb_pages_fin = 0
			@pagesok.each{ |s| @nb_pages_fin += 1 if s == '' }
			if next_page == 0
				page_id = @pages[0]
				@next_page = 1
				@next_paru = @ind_parus.index(@parution.id)
			else
				page_id = @pages[next_page]
				if params[:pageder]
					page_id = @pages.last
					next_page = @pages.index(page_id)
				end
				@next_page = next_page + 1
				@next_paru = next_paru
				if @next_page == @pages.count
					@next_page = 0
					@next_paru = next_paru + 1
					@next_paru = 0 if @next_paru == @ind_parus.count
				end
			end
			@page = params[:double] ? sp : PaperScannedPage.find(page_id)
			@clips = PaperScannedPagesClipping.where(paper_scanned_page_id: page_id, clip_selected: 0).order(:clip_number)
			@clips_done = PaperScannedPagesClipping.where(paper_scanned_page_id: page_id, clip_selected: 1).order(:clip_number)
			@publi = PaperPublication.find(@parution.instance_id)
		end
		@period = PaperPublicationsPeriodicity.all.order(:id)
		@papercredits = PaperCredit.flow_zero.order(:flow_name)
		@pagecredits = PaperScannedPagesCredit.where(scanned_page_id: @page.id)
		@plus = 0
		@plus = 1 if current_user.admin? and @publi.keyword == 1
	end

	def create
		credit = params[:new_credit]? params[:new_credit] : "sans"
		nb_clips = 0
		psid = params[:page_id].to_i
		if params[:tous]
			PaperScannedPagesClipping.paper_scanned_page(psid).collect{|c| PaperScannedPagesClipping.update(c.id, clip_selected: 1)}
			nb_clips = PaperScannedPagesClipping.paper_scanned_page(psid).count
		else
			PaperScannedPagesClipping.paper_scanned_page(psid).where(clip_selected: 1).collect{|c| PaperScannedPagesClipping.update(c.id, clip_selected: 0)}
			unless params[:button]
				clips = []
				params.each{|k,v| clips << v.to_i if k.include?("img_") && v.to_i != 0}
				clips.each{|id| PaperScannedPagesClipping.update(id, clip_selected: 1)}
				nb_clips = clips.count
			end
		end
		ps = PaperScannedPage.find(psid)
		ps.update_attributes(manual_validation_done: 1, manual_validation_date: Time.now, clip_done:1, clip_date:Time.now, clip_selected_count: nb_clips, user_id: current_user.id)
		if credit == "page"
			PaperCredit.flow_zero.each do |pc|
				fname = "flow_#{pc.flow_name}"
				nb = params[fname].to_i
				if nb > 0
					pspc = PaperScannedPagesCredit.find_by_credit_id_and_scanned_page_id(pc.flow_id, psid)
					if pspc.nil?
						PaperScannedPagesCredit.create(credit_id: pc.flow_id, scanned_page_id: psid, number: nb)
					else
						pspc.update_attributes(number: nb)
					end
				end
			end
			if params[:new_ag] != ""
			  if PaperCredit.find_by_flow_name(params[:new_ag]).nil?
          # nouvelle agence
          flow = PaperCredit.maxi
          PaperCredit.new_flow(flow, params[:new_ag])
          if params[:flow_new].to_i > 0
            PaperScannedPagesCredit.create(credit_id: flow, scanned_page_id: psid, number: params[:flow_new].to_i)
          end
        end
      end
    end
		# validation parution
		count_psp = PaperScannedPage.instance(ps.instance_id).where(manual_validation_done: 1).count
		if PaperParution.find(ps.instance_id).sequence_size == count_psp
			PaperParution.update(ps.instance_id, clip_done: 1, clip_date: Time.now)
		end
		redirect_to action: 'index', from: 'create', parution: params[:parution], filtre: params[:filtre], period: params[:period], page: params[:page], tcredit: credit
	end

	def image
		sp = PaperScannedPage.find(params[:id])
		send_file "#{sp.scanned_page_path}#{sp.image_filename}",:disposition => 'inline', :type=>"application/jpg", :x_sendfile=>true
	end

	def big_image
		sp = PaperScannedPage.find(params[:id])
		send_file "#{sp.scanned_page_path}#{sp.image_filename}",:disposition => 'inline', :type=>"application/jpg", :x_sendfile=>true
  end

  private

  def get_image_double(page)
    sp = PaperScannedPage.find(page)
    # on cherche la page suivante
    ps = PaperScannedPage.instance(sp.instance_id).page_no(sp.page_number+1).first
    unless ps.nil?
      @image_double = "dble_#{sp.id}.jpg"
      s = ImageSize.path("#{sp.scanned_page_path}#{sp.image_filename}").size
      siz = s.to_s.split('x')
      s2 = ImageSize.path("#{ps.scanned_page_path}#{ps.image_filename}").size
      siz2 = s2.to_s.split('x')
      wm = siz[0].to_i + siz2[0].to_i
      ym = siz[1].to_i + siz2[1].to_i
      image_double = Magick::ImageList.new("#{sp.scanned_page_path}#{sp.image_filename}", "#{ps.scanned_page_path}#{ps.image_filename}").montage do |mont|
        mont.geometry = "#{wm}x#{ym}+0+0"
      end
      image_double.write("#{Rails.root}/public/#{@image_double}")
    end

  end

  def update_ri(parution)
    PaperScannedPage.instance(parution).collect{ |sc| sc.update_attributes(result_done: 0, clip_requested: 0, server_id: 0, result_count: 0) }
    PaperScannedPagesClipping.joins(:paper_scanned_page).where(paper_scanned_pages: { instance_id: parution }).collect{ |pc| pc.update_attributes(result_done: 0, clip_requested: 0, result_count: 0) }
    PaperParution.update(parution, visualrecognition_done: 0)
    @filter = 0
  end

end
