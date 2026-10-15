class ApplicationController < ActionController::Base
  before_action :ensure_windows_view_paths
  helper_method :current_user, :logged_in?

  private

  def ensure_windows_view_paths
    sample = Dir.glob("#{Rails.root}/app/views/**/*.erb").first
    if sample
      canonical_views = sample.split("/app/views/").first + "/app/views"
      prepend_view_path(canonical_views) unless view_paths.any? { |p| p.to_path == canonical_views }
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_user
    unless logged_in?
      flash[:alert] = "Lütfen önce giriş yapın."
      redirect_to login_path
    end
  end

  def require_manager
    require_user
    unless current_user&.manager?
      flash[:alert] = "Bu işlem için yönetici yetkisi gereklidir."
      redirect_to root_path
    end
  end
end
