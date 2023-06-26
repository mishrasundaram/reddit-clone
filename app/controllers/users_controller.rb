class UsersController < ApplicationController
  before_action :already_logged_in, only: [:new, :create, :activate]
  before_action :wrong_user, only: [:destroy]
  before_action :deleted_user, only: [:show]

  def new
    @user = User.new
    render :new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      @url = activate_users_url(activation_token: @user.activation_token)
      render :activate
    else
      flash.now[:error] = @user.errors.full_messages
      render :new
    end
  end

  def show
    @user = User.find_by_username(params[:username])
    @subs = @user.subs.alpha_order(:title).select(:title)
    @posts = @user.posts.create_order.includes(:votes, :subs)
    @comments = @user.comments.create_order.includes(:votes, :post)
    render :show
  end

  def destroy
    user = User.find_by_username(params[:username])

    if user.destroy
      flash[:notice] = 'Your account was deleted'
      redirect_to new_user_url
    else
      flash[:error] = 'Oops, something went wrong and you still exist'
      redirect_to user_url(user)
    end
  end

  def activate
    user = User.find_by_activation_token(params[:activation_token])

    if user
      handle_activation(user)
      redirect_to new_session_url
    else
      flash[:error] = 'User not found. Please register first'
      redirect_to new_user_url
    end
  end

  private

  def deleted_user
    return unless params[:username] == DESTROYED
    link = request.referrer || root_url
    redirect_to link
  end

  def wrong_user
    user = User.find_by_username(params[:username])
    return if current_user == user
    redirect_to user_url(user)
  end

  def handle_activation(user)
    if user.activated
      flash[:notice] = 'This account is already active'
    else
      flash[:notice] = 'You have successfully activated your account'
      user.activate_user
    end
  end

  def user_params
    params.require(:user).permit(:email, :username, :password)
  end
end