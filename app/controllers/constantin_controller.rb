require "json"
require 'rest_client'

class ConstantinController < ApplicationController

	def index
		@page = PaperScannedPage.find(params[:page].to_i)
		@clips = PaperScannedPagesClipping.where(paper_scanned_page_id: params[:page].to_i).order(:clip_number)
	end

	def show
		@erreur = ""
		@nb_img = 0
		img = params[:id].to_i
		filen = PaperScannedPagesClipping.find(img).clip_filename
		filen.gsub!("/mnt/storage/pixtrakkprint/input/Kantarmedia","public/datas")
		c = Curl::Easy.new(ENV['VISUAL_SEARCH'])
		c.multipart_form_post = true
		c.http_post(Curl::PostField.file('image', filen),Curl::PostField.content('searchtype', 'print'))
		if c.body_str.blank?
			@erreur = "Image inconnue"
		else
			if valid_json(c.body_str)
				retour = JSON.parse(c.body_str)
				@nb_img = retour['searchresults']['nbtotalresults'].to_i
			else
				@erreur = "Erreur Json"
			end
		end
		if @nb_img == 0
			@erreur = " aucune image trouvée"
			@img = img
		else
			msids = {}
			@ori_name = {}
			retour['searchresults']['imagesinfo']['imageinfo'].each do |i|
				j = i['externalid'].to_i
				if j == 0
					@ori_name[i['externalid'].to_s] = i['score'].to_f
				else
					msids[j] = i['score'].to_f
				end
			end
			@imgs = {}
			url_key = 'return_thumb'
			#secret_key = 'secret'
			endpoint_url = ENV['PTREF_URL']
			msids.each do |i, s|
logger.info" i = #{i} s = #{s}"
				begin
					res = RestClient.post( "#{endpoint_url}/#{url_key}",
				                       { "image_id" => i
				                       }.to_json, content_type: :json, accept: :json)
				rescue => e
					@erreur << e.inspect
				end
				if res.nil?
					@erreur << " – ms_image_id #{i} inconnu"
				else
					if valid_json(res.body)
						retour = JSON.parse(res.body)
						if retour.blank?
							@erreur << " – ms_image_id #{i} inconnu"
						else
							@imgs[i] = {'name' => retour['file_name'], 'thumb' => retour['thumb_path'], 'prov' => retour['provider'], 'score' => s}
						end
					else
						@erreur = " – ms_image_id #{i} : erreur JSON"
					end
				end
			end
			@url = ENV['SITE_TEST']
		end

	end

	private

	def valid_json(vari)
		JSON.parse(vari)
		return true
	rescue JSON::ParserError
		return false
	end
end

