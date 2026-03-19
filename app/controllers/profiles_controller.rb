class ProfilesController < ApplicationController
  def edit
    @profile = current_user.user_profile || current_user.build_user_profile
  end

  def update
    @profile = current_user.user_profile || current_user.build_user_profile
    @profile.display_name = params[:user_profile][:display_name]

    if @profile.save
      redirect_to root_path, notice: "Display name saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
