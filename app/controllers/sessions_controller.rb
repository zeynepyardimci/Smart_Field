class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:email]&.strip&.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "Hoş geldiniz, #{user.name}."
      redirect_to root_path
    else
      flash.now[:alert] = "Geçersiz e-posta veya şifre."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Başarıyla çıkış yapıldı."
    redirect_to login_path
  end
end
