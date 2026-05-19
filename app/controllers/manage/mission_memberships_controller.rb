class Manage::MissionMembershipsController < Manage::BaseController
  before_action :set_membership, only: [ :update, :destroy ]

  def create
    user = User.find_by(id: membership_params[:user_id])
    user ||= User.find_by(slack_id: membership_params[:user_id])

    if user.nil?
      redirect_to edit_manage_mission_path(@mission.slug), alert: "User not found." and return
    end

    membership = @mission.memberships.new(user: user, role: membership_params[:role])
    if membership.save
      redirect_to edit_manage_mission_path(@mission.slug), notice: "Membership added."
    else
      redirect_to edit_manage_mission_path(@mission.slug), alert: membership.errors.full_messages.to_sentence
    end
  end

  def update
    if @membership.update(role: membership_params[:role])
      redirect_to edit_manage_mission_path(@mission.slug), notice: "Membership updated."
    else
      redirect_to edit_manage_mission_path(@mission.slug), alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @membership.owner_role? && @mission.memberships.where(role: Mission::Membership.roles[:owner]).count <= 1
      redirect_to edit_manage_mission_path(@mission.slug), alert: "Can't remove the last owner." and return
    end
    @membership.destroy!
    redirect_to edit_manage_mission_path(@mission.slug), notice: "Membership removed."
  end

  private

  def set_membership
    @membership = @mission.memberships.find(params[:id])
  end

  def membership_params
    params.require(:mission_membership).permit(:user_id, :role)
  end
end
