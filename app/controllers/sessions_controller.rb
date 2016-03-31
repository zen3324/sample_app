class SessionsController < ApplicationController

  def new
    #code
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      sign_in user
      redirect_back_or user
    else
      flash.now[:error] = t('flash.invalid_email_password_combination')
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end
end
