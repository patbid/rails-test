class MatchingImage < ActiveRecord::Base
	belongs_to :user, foreign_key: "validation_by_user_id", class_name: 'User'
	belongs_to :image


	def rapport
		tab_count = {}
		dd = []
		df = []
		duree = []
		tab_count = MatchingImage.joins(:user).where(validation_done: 1, validated_at: (Time.now-1.day).beginning_of_day..(Time.now-1.day).end_of_day).group(:email).count
		tab_count.keys.each do |mail|
			uid = User.find_by_email(mail).id
			dd[mail] = MatchingImage.where(validation_done: 1, validated_at: (Time.now-1.day).beginning_of_day..(Time.now-1.day).end_of_day, validation_by_user_id: uid).order('validated_at ASC').first
			df[mail] = MatchingImage.where(validation_done: 1, validated_at: (Time.now-1.day).beginning_of_day..(Time.now-1.day).end_of_day, validation_by_user_id: uid).order('validated_at DESC').last
			dif = (Time.parse(df[uid].to_s) - Time.parse(dd[uid].to_s))
			heure = (dif/3600).floor
			minutes = ((dif-heure*3600)/60).floor
			duree[mail] = "#{heure}h #{minutes}mn"
		end
		UserMailer.rapport_count(tab_count, dd, df, duree).deliver
	end

end

