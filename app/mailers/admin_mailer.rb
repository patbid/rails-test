class AdminMailer < ActionMailer::Base
	default from: ENV['EMAIL_SUPPORT']
	default bcc: ENV['EMAIL_VERIF']

	def rapport_purge(date_purge, nb_web, nb_print, nb_page)
		@date_purge = I18n.l (date_purge), format: '%d %B %Y'
		@nb_web = nb_web
		@nb_print = nb_print
		@nb_page = nb_page
		mail(to: '',
		     subject: "purge bdd #{@date_purge}")
	end

end

