class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  protect_from_forgery with: :null_session
  def authenticate

    controller = params[:controller]
    action = params[:action]
    user_id = session[:user_id]
    username = session[:username]
    role_id = session[:role_id]
    logger.debug("Authenticating as {user_id: #{user_id}, username: #{username}, role_id: #{role_id}} for controller: #{controller}, action: #{action}")
    if !is_accessible(controller,action)
      render :nothing => true, :status => :unauthorized
    end
  end

  private def is_accessible(controller, action)
    role_id = session[:role_id] == nil ? 0 : session[:role_id]
    if role_id == 1
      return is_accessible_by_admin(controller, action)
    elsif role_id == 2
      return is_accessible_by_manager(controller, action)
    elsif role_id == 3
      return is_accessible_by_user(controller, action)
    end
    return is_accessible_by_guest(controller, action)
  end

  private def is_accessible_by_admin(controller, action)
    return true
  end

  private def is_accessible_by_manager(controller, action)
    case controller
    when "api/v1/users"
      return true
    when "api/v1/files"
      return true
    when "api/v1/login"
      return true
    end
    return false
  end

  private def is_accessible_by_user(controller, action)
    case controller
    when "api/v1/users"
      if action == "show" || action == "update"
        return true
      end
    when "api/v1/files"
      if action == "create"
        return true
      end
    when "api/v1/login"
      return true
    end
    return false
  end

  private def is_accessible_by_guest(controller, action)
    case controller
    when "api/v1/login"
      if action == "index" || action == "create"
        return true
      end
    when "api/v1/users"
      if action == "create"
        return true
      end
    end
    return false
  end
end
