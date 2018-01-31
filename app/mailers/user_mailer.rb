class UserMailer < ActionMailer::Base
	default from: ENV['EMAIL_SUPPORT']
	default bcc: ENV['EMAIL_VERIF']

	def rapport_count(tab, dd, df, duree, dureetot, dureeall, ptab, pdd, pdf, pduree, pdureetot, pdureeall)
		@tab = tab
		@dd = dd
		@df = df
		@duree = duree
		@dureetot = dureetot
		@dureeall = dureeall
		@ptab = ptab
		@pdd = pdd
		@pdf = pdf
		@pduree = pduree
		@pdureetot = pdureetot
		@pdureeall = pdureeall
		@dat = I18n.l (Time.now-1.day), format: '%d %B %Y'
		mail(to: '',
		     subject: "validation matches #{@dat}")
	end

end


