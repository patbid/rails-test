class UsersController < ApplicationController

	before_action :authenticate_user!
	before_action :set_user, only: [:show, :edit, :update]
	before_filter :authorize_admin, except: :logout

	def index
		@users = User.all
	end

	def create
		if params[:admin]
			user = User.new(email: params[:email],
											password: params[:password],
											password_confirmation: params[:password_confirmation], admin: 1)
		else
			user = User.new(email: params[:email],
											password: params[:password],
											password_confirmation: params[:password_confirmation])
		end
		user.save
		@users = User.all
		render 'index'
	end

	def edit
	end

	def update
		if params[:admin]
			@user.update_attributes(email: params[:email], admin: 1)
		else
			@user.update_attributes(email: params[:email], admin: nil)
		end
		redirect_to users_path, notice: "OK"
	end

	def show
		@pages = []
		PaperScannedPage.where(user_id: params[:id]).order(:manual_validation_date).collect{ |psp| @pages << psp.id }
	end

	def logout
		MatchingImage.where(is_being_processed: 1, validation_by_user_id: current_user.id, validation_done: 0).update_all( is_being_processed: 0, validation_by_user_id: 0 )
		PaperMatchingImage.where(is_being_processed: 1, validation_by_user_id: current_user.id, validation_done: 0).update_all( is_being_processed: 0, validation_by_user_id: 0 )
		UserControl.where('user_id = ? AND begin_w = end_w', current_user.id).collect{ |uc| uc.update_attributes(end_w: Time.now) unless uc.begin_w.blank? }
		UserControl.where('user_id = ? AND web_end_w = web_begin_w', current_user.id).collect{ |uc| uc.update_attributes(web_end_w: Time.now) unless uc.web_begin_w.blank? }
		redirect_to signout_path and return
	end

	private

	def authorize_admin
		redirect_to root_path, Flash[:alert] => 'Accès restreint' unless current_user.admin?
	end

	def set_user
		@user = User.find(params[:id])
	end

	def permitted_params
		params.require(:user).permit(:email, :admin)
	end
end
