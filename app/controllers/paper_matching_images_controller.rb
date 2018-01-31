class PaperMatchingImagesController < ApplicationController

	before_action :authenticate_user!

	def index
		@debut = params[:debut]? params[:debut] : 0
		@fin = params[:fin]? params[:fin] : 0
		if @debut == '1'
			UserControl.create_user(current_user.id)
			@debut = '2'
		end
		if @fin == '1'
			UserControl.where('user_id = ? AND end_w = begin_w', current_user.id).collect{ |uc| uc.update_attributes(end_w: Time.now) unless uc.begin_w.blank? }
			@debut = '0'
		end
		@filter = params[:clip] ? params[:clip] : "manual"
		@sel_period = params[:period] ? params[:period].to_i : 0
		@imgs = []
		if @sel_period == 0
			if @filter == "supp"
			  @nb_match = PaperMatchingImage.done.error(2).cliptype("manual").count
			  PaperMatchingImage.done.error(2).cliptype("manual").most_recent(50).collect{ |i| @imgs << i.id }
		  elsif @filter == "tout"
			  @nb_match = PaperMatchingImage.done.processed.error(0).count
			  PaperMatchingImage.done.processed.error(0).most_recent(50).collect{ |i| @imgs << i.id }
		  elsif @filter == "manual"
			  @nb_match = PaperMatchingImage.done.processed.error(0).cliptype(@filter).count
			  PaperMatchingImage.done.processed.error(0).cliptype(@filter).most_recent(50).collect{ |i| @imgs << i.id }
		  else
			  @nb_match = PaperMatchingImage.done.processed.error(0).cliptype(@filter).count
			  PaperMatchingImage.done.processed.error(0).cliptype(@filter).most_recent(50).collect{ |i| @imgs << i.id }
      end
    else
      if @filter == "supp"
        @nb_match = PaperMatchingImage.joins(:paper_scanned_page).
						joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
						INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id').
						where( paper_publications: { periodicity: @sel_period } ).done.error(2).cliptype("manual").count
        PaperMatchingImage.joins(:paper_scanned_page).
            joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
						INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id').
            where( paper_publications: { periodicity: @sel_period } ).done.error(2).cliptype("manual").most_recent(50).
						collect{ |i| @imgs << i.id }
      elsif @filter == "tout"
        @nb_match = PaperMatchingImage.joins(:paper_scanned_page).
            joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
						LEFT JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id').
            where( paper_publications: { periodicity: @sel_period } ).done.processed.error(0).count
        PaperMatchingImage.joins(:paper_scanned_page).
            joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
						INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id').
            where( paper_publications: { periodicity: @sel_period } ).done.processed.error(0).most_recent(50).
						collect{ |i| @imgs << i.id }
      elsif @filter == "manual"
        @nb_match = PaperMatchingImage.joins(:paper_scanned_page).
            joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
						INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id').
            where( paper_publications: { periodicity: @sel_period } ).done.processed.error(0).cliptype(@filter).count
        PaperMatchingImage.joins(:paper_scanned_page).
            joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
						INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id').
            where( paper_publications: { periodicity: @sel_period } ).done.processed.error(0).cliptype(@filter).most_recent(50).
						collect{ |i| @imgs << i.id }
      else
        @nb_match = PaperMatchingImage.joins(:paper_scanned_page).
            joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
						INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id').
            where( paper_publications: { periodicity: @sel_period } ).done.processed.error(0).cliptype(@filter).count
        PaperMatchingImage.joins(:paper_scanned_page).
            joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
						INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id').
            where( paper_publications: { periodicity: @sel_period } ).done.processed.error(0).cliptype(@filter).most_recent(50).
						collect{ |i| @imgs << i.id }
      end
    end
		PaperMatchingImage.where(id: @imgs).update_all( is_being_processed: 1, validation_by_user_id: current_user.id )
    @nb_done = PaperMatchingImage.where(synchronization_done: 1).count
		@mimgs = PaperMatchingImage.select('paper_matching_images.id, paper_matching_images.paper_scanned_page_id, images.medium_location, paper_matching_images.clip_id,
									paper_matching_images.paper_scanned_page_path, images.string_key, paper_matching_images.origin_id, paper_matching_images.created_at').
									joins(:image).
									where( paper_matching_images: { id: @imgs } )
		@period = PaperPublicationsPeriodicity.select(:id, :name).all.order(:id)
	end

	def controles
		@util = params[:util]? params[:util] : ""
		@erreur = params[:erreur]? params[:erreur].to_i : 3
		@dat_begin = params[:date_begin]? params[:date_begin] : ""
		@dat_end = params[:date_end]? params[:date_end] : ""
		@publi = params[:publi]? params[:publi].to_i : 0
		@manauto = params[:manauto]? params[:manauto].to_i : 2
		@no_page = params[:no_page]? params[:no_page].to_i : 0
		@controled = params[:controled]? params[:controled].to_i : 2
		query = "validation_done = 1"
		query = " #{query} AND controle_done = #{@controled} " unless @controled == 2
		unless @util.blank?
			query = "#{query} AND validation_by_user_id = #{@util} "
		end
		unless @erreur > 2
			query = "#{query} AND error = #{@erreur}"
		end
		if @dat_begin.blank?
			unless @dat_end.blank?
				dat_end = "#{@dat_end[6..9]}-#{@dat_end[3..4]}-#{@dat_end[0..1]}"
				query = "#{query} AND validated_at <= '#{dat_end} 23:59'"
			end
		else
			dat_begin = "#{@dat_begin[6..9]}-#{@dat_begin[3..4]}-#{@dat_begin[0..1]}"
			if @dat_end.blank?
				query = "#{query} AND validated_at >= '#{dat_begin} 00:00'"
			else
				dat_end = "#{@dat_end[6..9]}-#{@dat_end[3..4]}-#{@dat_end[0..1]}"
				query = "#{query} AND validated_at >= '#{dat_begin} 00:00' and validated_at <= '#{dat_end} 23:59' "
			end
		end
		if @manauto < 2
			query = "#{query} AND paper_publications.active = 1 AND paper_publications.manual_validation=  #{@manauto}"
		end
		@imgs = []
		if @publi == 0
			if  @manauto == 2
				@nb_match = PaperMatchingImage.where("#{query}").count
				PaperMatchingImage.where("#{query}").order('created_at asc').limit(50).collect{ |i| @imgs << i.id }
			else
				@nb_match = PaperMatchingImage.joins('LEFT JOIN paper_scanned_pages ON paper_scanned_pages.id = paper_matching_images.paper_scanned_page_id LEFT JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id LEFT JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id')
                                                .where("#{query}").count
				PaperMatchingImage.joins('LEFT JOIN paper_scanned_pages ON paper_scanned_pages.id = paper_matching_images.paper_scanned_page_id LEFT JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id LEFT JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id')
																	.where("#{query}").order('created_at asc').limit(50).collect{ |i| @imgs << i.id }
			end
		else
			query = "#{query} AND paper_scanned_pages.page_number = #{@no_page}" unless @no_page == 0
			@nb_match = PaperMatchingImage.joins('LEFT JOIN paper_scanned_pages ON paper_scanned_pages.id = paper_matching_images.paper_scanned_page_id LEFT JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id LEFT JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id')
                                            .where("#{query} AND paper_parutions.id = #{@publi}").count
      PaperMatchingImage.joins('LEFT JOIN paper_scanned_pages ON paper_scanned_pages.id = paper_matching_images.paper_scanned_page_id LEFT JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id LEFT JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id')
																.where("#{query} AND paper_parutions.id = #{@publi}").order('created_at asc').limit(50).collect{ |i| @imgs << i.id }

		end
		@mimgs = PaperMatchingImage.select('paper_matching_images.id, paper_matching_images.error, paper_matching_images.paper_scanned_page_id, images.medium_location, images.ms_image_id, paper_matching_images.clip_id,
 																				paper_matching_images.paper_scanned_page_path, images.string_key, paper_matching_images.origin_id, paper_matching_images.validated_at, paper_matching_images.controled_at,
                                        paper_matching_images.controled_by, users.email')
																			.joins(:image).joins(:user).where( paper_matching_images: { id: @imgs })
		@users = User.where(admin: nil)
		@publis = PaperPublication.select('distinct paper_parutions.id, publication_name, DATE_FORMAT(publication_date,  "%d-%m-%y") AS pdate')
																			.joins('LEFT JOIN paper_parutions ON paper_parutions.instance_id = paper_publications.id LEFT JOIN paper_scanned_pages ON paper_scanned_pages.instance_id = paper_parutions.id LEFT JOIN paper_matching_images ON paper_matching_images.paper_scanned_page_id = paper_scanned_pages.id')
                                      .where('paper_matching_images.validation_done = 1').order('publication_name, publication_date DESC')
	end

	def create
		filter = params[:filter]
		debut = params[:debut]
		fin = params[:fin]
		period = params[:period] ? params[:period] : 0
		error = (filter == "manual")? 2 : 1
		ids = []
		ids = params[:imgs].split(' ')
		err_ids = []
		err_ids = params[:error_id] if params[:error_id]
		ids.delete_if { |i| err_ids.include?(i) }
		ids.each do |i|
			pmi = PaperMatchingImage.find(i)
			PaperMatchingImage.where(paper_scanned_page_id: pmi.paper_scanned_page_id, image_id: pmi.image_id).update_all( validation_done: 1, validated_at: Time.now, is_being_processed: 1, validation_by_user_id: current_user.id, error: 0 )
			#PaperMatchingImage.update(i, validation_done: true, validated_at: Time.now)
		end

		if params[:error_id]
			if filter == "tout"
				err_ids.each do |i|
					pmi = PaperMatchingImage.find(i)
					if pmi.clip_type == "auto"
						PaperMatchingImage.where(paper_scanned_page_id: pmi.paper_scanned_page_id, image_id: pmi.image_id).update_all( validation_done: 1, validated_at: Time.now, is_being_processed: 1, validation_by_user_id: current_user.id, error: 1 )
					else
						PaperMatchingImage.where(paper_scanned_page_id: pmi.paper_scanned_page_id, image_id: pmi.image_id).update_all( validation_done: 0, validated_at: Time.now, is_being_processed: 1, validation_by_user_id: current_user.id, error: 2 )
					end
				end
			else
				err_ids.each do |i|
					pmi = PaperMatchingImage.find(i)
					if error == 2
						PaperMatchingImage.where(paper_scanned_page_id: pmi.paper_scanned_page_id, image_id: pmi.image_id).update_all( validation_done: 0, validated_at: Time.now, is_being_processed: 1, validation_by_user_id: current_user.id, error: error )
					else
						PaperMatchingImage.where(paper_scanned_page_id: pmi.paper_scanned_page_id, image_id: pmi.image_id).update_all( validation_done: 1, validated_at: Time.now, is_being_processed: 1, validation_by_user_id: current_user.id, error: error )
					end
					#PaperMatchingImage.update(i, error: true)
				end
			end
		end
		redirect_to action: 'index', clip: filter, debut: debut, fin: fin, period: period
	end

	def valid_controles
		util = params[:util]? params[:util] : ""
		erreur = params[:erreur]? params[:erreur].to_i : 3
		dat_begin = params[:date_begin]? params[:date_begin] : ""
		dat_end = params[:date_end]? params[:date_end] : ""
		publi = params[:publi]? params[:publi].to_i : 0
		manauto = params[:manauto]? params[:manauto].to_i : 2
		publis = params[:publis]? params[:publis] : {}
    controled = params[:controled]? params[:controled] : 2
    no_page = params[:no_page]? params[:no_page] : 0
		ids = []
		ids = params[:imgs].split(' ')
		err_ids = []
		err_ids = params[:error_id] if params[:error_id]
		ids.delete_if { |i| err_ids.include?(i) }
		# match ok
		ids.each do |i|
			pmi = PaperMatchingImage.find(i)
			if pmi.error == 1 && pmi.synchronization_done == 0
				pmi.update_attributes(controle_done: 1, controled_at: Time.now, controled_by: current_user.id, error: 0)
      elsif pmi.error == 1 && pmi.synchronization_done == 1
        pmi.update_attributes(controle_done: 1, controled_at: Time.now, controled_by: current_user.id, error: 0, synchronization_done: 0)
        parution = PaperScannedPage.find_by_id(pmi.paper_scanned_page_id).instance_id
        PaperParution.update(parution, result_rebuilt: 1)
			else
				pmi.update_attributes(controle_done: 1, controled_at: Time.now, controled_by: current_user.id)
			end
		end
		# match en erreur
		PaperMatchingImage.where(id: err_ids).update_all( controle_done: 1, controled_at: Time.now, controled_by: current_user.id, error: 1 )
		redirect_to action: 'controles', util: util, erreur: erreur, date_begin: dat_begin, date_end: dat_end, publi: publi, manauto: manauto, publis: publis, controled: controled, no_page: no_page
	end

end
