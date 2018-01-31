class SuperpositionController < ApplicationController

  before_action :authenticate_user!

  def index
    @typsup = params[:typsup]? params[:typsup].to_i : 1 # 0 = web; 1 = print
    @erreur = params[:erreur]? params[:erreur].to_i : 3
    @dat_begin = params[:date_begin]? params[:date_begin] : ""
    @dat_end = params[:date_end]? params[:date_end] : ""
    @manauto = params[:manauto]? params[:manauto].to_i : 2
    if @erreur == 0
      if @typsup == 0
        query = "superposition_done = 1 and superposition_error = 1 and error = 1"
      else
        query = "superposition_done = 1 and superposition_error = 0 and error != 0"
      end
    elsif @erreur == 1
      query = "superposition_done = 1 and superposition_error = 0 and error = 0"
    elsif @erreur == 2
      if @typsup == 0
        query = "superposition_done = 1 and superposition_error > 1 and error = 1"
      else
        query = "superposition_done = 1 and superposition_error = 1 and error = 0"
      end
    else
      query = "superposition_done = 1 "
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
    if @manauto < 2 && @typsup == 1
      query = "#{query} AND paper_pubications.active = 1 AND paper_pubications.manual_validation=  #{@manauto}"
    end
    @imgs = []
    if @typsup == 0
      @nb_match = MatchingImage.where("#{query}").count
      MatchingImage.where("#{query}").order('created_at asc').limit(1000).collect{ |i| @imgs << i.id }
      @mimgs = MatchingImage.select('matching_images.id, matching_images.url_image, images.medium_location,
																	images.string_key, matching_images.domain, matching_images.error,
																	matching_images.url_parent, matching_images.origin_id, matching_images.created_at').
                            joins(:image).where( matching_images: { id: @imgs } )
    else
      if  @manauto == 2
        @nb_match = PaperMatchingImage.where("#{query}").count
        PaperMatchingImage.where("#{query}").order('created_at asc').limit(1000).collect{ |i| @imgs << i.id }
      else
        @nb_match = PaperMatchingImage.joins(:paper_scanned_page)
                                      .joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
                                              INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id')
                                      .where("#{query}")
                                      .count
        PaperMatchingImage.joins(:paper_scanned_page)
                          .joins('INNER JOIN paper_parutions ON paper_parutions.id = paper_scanned_pages.instance_id
                                  INNER JOIN paper_publications ON paper_publications.id = paper_parutions.instance_id')
                          .where("#{query}")
                          .order('created_at asc')
                          .limit(1000)
                          .collect{ |i| @imgs << i.id }
      end
      @mimgs = PaperMatchingImage.select('paper_matching_images.id, paper_matching_images.error, paper_matching_images.paper_scanned_page_id,
                                        images.medium_location, paper_matching_images.clip_id, paper_matching_images.paper_scanned_page_path,
                                        images.string_key, paper_matching_images.origin_id, paper_matching_images.created_at, users.email').
                                  joins(:image).joins(:user).where( paper_matching_images: { id: @imgs } )
    end
  end

end
