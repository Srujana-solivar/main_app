class ApplicationController < ActionController::Base
  def show
	@user = User.find(params[:id])
	@title = @user.name
  end
end
