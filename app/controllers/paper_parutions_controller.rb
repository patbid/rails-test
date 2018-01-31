class PaperParutionsController < ApplicationController

  before_action :authenticate_user!

  def destroy
    parution = params[:id]
    PaperScannedPage.where(instance_id: parution).destroy_all
    PaperParution.find(parution).destroy
    redirect_to scanned_pages_url
  end
end
