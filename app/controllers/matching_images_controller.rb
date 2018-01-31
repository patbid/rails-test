class MatchingImagesController < ApplicationController

	before_action :authenticate_user!

	def index
		@crawler = params[:crawler]? params[:crawler].to_i : 0
		@stringkey = params[:stringkey]? params[:stringkey] : ""
		@debut = params[:debut]? params[:debut] : '0'
		@fin = params[:fin]? params[:fin] : '0'
		if @debut == '1'
			UserControl.create_user(current_user.id)
			@debut = '2'
		end
		if @fin == '1'
			UserControl.where('user_id = ? AND web_end_w = web_begin_w', current_user.id).collect{ |uc| uc.update_attributes(web_end_w: Time.now) unless uc.web_begin_w.blank? }
			@debut = '0'
		end
		@imgs = []
		crawl = @crawler > 0 ? " AND crawltype_id = #{@crawler}" : " AND (crawltype_id != 2 OR (crawltype_id=2 AND error=2))"
		crawl += " AND error = 2" if @crawler == 2
		@stringkeys = Image.joins(:matching_images).where(images: { provider_type: 'agency' })
											.where(matching_images: { crawltype_id: @crawler, is_being_processed: 0, validated_at: nil })
											.order(:string_key).pluck('DISTINCT string_key')
		@stringkey = "" unless @stringkeys.include? @stringkey
		if !@stringkey.blank?
			MatchingImage.joins(:image).where(images: { string_key: @stringkey },
																				matching_images: { is_being_processed: 0, validated_at: nil, crawltype_id: @crawler })
					                        .order('created_at asc').limit(50).collect{ |i| @imgs << i.id }
			@nb_match = MatchingImage.joins(:image).where(images: { string_key: @stringkey },
																										matching_images: { is_being_processed: 0, validated_at: nil, crawltype_id: @crawler })
                                              .count
		else
			MatchingImage.where("is_being_processed is false AND validated_at is Null#{crawl}")
					          .order('created_at asc').limit(50).collect{ |i| @imgs << i.id }
			@nb_match = MatchingImage.where("is_being_processed is false AND validated_at is Null#{crawl}").count
		end
		MatchingImage.where(id: @imgs).update_all( is_being_processed: 1, validation_by_user_id: current_user.id )
		@mimgs = MatchingImage.select('matching_images.id, matching_images.url_image, images.medium_location,
																	images.string_key, matching_images.domain, matching_images.country_name,
																	matching_images.url_parent, matching_images.origin_id, matching_images.created_at')
				                  .joins(:image).where( matching_images: { id: @imgs })
	end

	def create
		MatchingImage.where(id: params[:error_id]).update_all( error: 1 ) if params[:error_id]
		ids = []
		ids = params[:imgs].split(' ')
		MatchingImage.where(id: ids).update_all( validation_done: 1, validated_at: Time.now )
		redirect_to  action: 'index', debut: params[:debut], fin: params[:fin], crawler: params[:crawler], stringkey: params[:stringkey]
	end

end
