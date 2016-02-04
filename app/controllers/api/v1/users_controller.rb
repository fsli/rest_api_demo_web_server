class Api::V1::UsersController < ApplicationController
  skip_before_filter  :verify_authenticity_token
  before_filter :authenticate
  def index
    user_id = params[:id]
    role_id = session[:role_id]
    #list user by manager and return users only
    if role_id == 2
      data = User.all.select(:id,:username, :picture, :role_id, :created_at, :updated_at).where("role_id = 3").order("created_at DESC")
    elsif role_id == 1
      data = User.all.select(:id,:username, :picture, :role_id, :created_at, :updated_at).order("created_at DESC")
    end

    results = Array.new()
    data.each do |row|
      results.push({id: row['id'], username: row['username'], picture: row['picture'], role_id: row['role_id'], created_at: row['created_at'], updated_at: row['updated_at']})
    end
    render json: results
  end

  def show
    user_id = params[:id].to_i()
    current_user_id = session[:user_id]
    role_id = session[:role_id]
    if role_id == 1 #admin can access all admin/managers/users
      data = User.select(:id, :username, :picture, :role_id).find(user_id)
    elsif role_id == 2 #manager can access all users and self
      if user_id == current_user_id
        data = User.select(:id, :username, :picture, :role_id).find(user_id)
      else
        data = User.select(:id, :username, :picture, :role_id).where("id = #{user_id} AND role_id = 3")
        if (data.length > 0)
          data = data[0]
        else
          data = nil
        end
      end
    elsif role_id == 3
      if user_id == current_user_id
        data = User.select(:id, :username, :picture, :role_id).find(user_id)
      end
    end
    if data == nil
      result = {result: false, message: "Cannot find user by id: #{user_id}" }
    else
      result = {result: true, id: data["id"], username: data['username'], picture: data['picture'], role_id: data['role_id']}
    end
    render json: result
  end

  def create
    param_username = params[:username]
    param_password = params[:password]
    param_role_id = params[:role_id] == nil ? 3 : params[:role_id].to_i()
    current_role_id = session[:role_id]
    ret = validate_user_create
    if ret[:result]
      salt = BCrypt::Engine.generate_salt
      encrypted_password = BCrypt::Engine.hash_secret(param_password, salt)
      if current_role_id == 1
        ret = create_user(param_username, encrypted_password, salt, param_role_id)
      else
        ret = create_user(param_username, encrypted_password, salt)
      end
      render json: ret
    else
      render json: ret
    end
  end

  private def create_user(username, encrypted_password, salt, role_id = 3) #default role_id as 3 :user
    if role_id  <= 0 || role_id > 3
      ret = {result: false, message: "Invalid role id. #{role_id}"}
    else
      user = User.create(username: username, password: encrypted_password, salt:salt, role_id: role_id)
      ret =  {result: true, username: user['username'], id: user['id'], role_id: user['role_id'], message: "User has been created successfully." }
    end   
    return ret
  end
  def update
    param_username = params[:username]
    param_password = params[:password]
    param_picture = params[:picture]
    param_role_id = params[:role_id] == nil ? 3 : params[:role_id].to_i()
    current_role_id = session[:role_id]
    param_id = params[:id].to_i
    current_user_id = session[:user_id]
    ret = validate_user_update
    if ret[:result]
      user = User.find_by(id: param_id)
      if user == nil
        render json: {result: false, message: "User id: #{param_id} cannot be found."}   
        return
      end
      salt = user['salt']
      encrypted_password = BCrypt::Engine.hash_secret(param_password, salt)
      #user can only self-update, manager(role_id = 2) can update users andself, admin can update all other users and change roles.
      if current_role_id == 3 && current_user_id == param_id
        ret = update_user(user, param_username, encrypted_password, param_picture)
      elsif current_role_id == 2 && user['role_id'] == 3 || current_user_id == param_id
        ret = update_user(user, param_username, encrypted_password, param_picture)
      elsif current_role_id == 1
        ret = update_user(user, param_username, encrypted_password, param_picture, param_role_id)
      else
        render :nothing => true, :status => :unauthorized
        return
      end
      
      render json: ret
    else
      render json: ret
    end
  end

  private def update_user(user, username, encrypted_password, picture, role_id = nil)
    if role_id != nil && (role_id  <= 0 || role_id > 3)
      ret = {result: false, message: "Invalid role id. #{role_id}"}
    else
      if role_id == nil
        user.update(username: username, picture: picture, password: encrypted_password)
      else
        user.update(username: username, picture: picture, password: encrypted_password, role_id: role_id)
      end     
      ret =  {result: true, username: user['username'], id: user['id'], picture: user['picture'], role_id: user['role_id'], message: "User has been updated successfully." }
    end   
    return ret
  end
  def destroy
    param_id = params[:id].to_i()
    current_role_id = session[:role_id]
    current_user_id = session[:user_id]
    user = User.find_by(id: param_id)
    if user == nil
      render json: {result: false, message: "User id: #{param_id} cannot be found."}    
      return
    end 
    #manager(role_id = 2) can delete users, admin can delete all other users except self.
    if current_role_id == 2 && user['role_id'] == 3
      user.destroy()
    elsif current_role_id == 1 && param_id != current_user_id
      user.destroy()
    else
      render :nothing => true, :status => :unauthorized
      return
    end
    render json: {restul: true, id: user['id'], message: "User has been deleted successfully." }    
  end

  def update_password
    render json: {message: "Password has been updated successfully." }
  end

  private def validate_user_create
    param_username = params[:username]
    if param_username != nil
      data = User.where(username: param_username)
      if data.length > 0
        return {result: false, message: "Username #{param_username} already exists."}
      end
    end
    return {result: true}
  end

  private def validate_user_update
    param_username = params[:username]
    param_id = params[:id].to_i
    if param_username != nil
      data = User.where(username: param_username)
      for u in data
        if u.id != param_id.to_i && u.username == param_username
          return {result: false, message: "Username #{param_username} already exists."}
        end
      end
    end
    return {result: true}
  end
end