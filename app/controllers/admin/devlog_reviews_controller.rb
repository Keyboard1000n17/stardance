class Admin::DevlogReviewsController < Admin::ApplicationController
  before_action :set_devlog_review

  def update
    authorize :admin, :access_admin_endpoints?

    # Log the incoming params for debugging
    Rails.logger.debug "DevlogReview ##{@devlog_review.id} update params: #{devlog_review_params.inspect}"

    if @devlog_review.update(devlog_review_params)
      Rails.logger.debug "DevlogReview ##{@devlog_review.id} successfully updated: status=#{@devlog_review.status}, approved_minutes=#{@devlog_review.approved_minutes}, justification=#{@devlog_review.justification}"

      render json: {
        success: true,
        devlog_review: {
          id: @devlog_review.id,
          status: @devlog_review.status,
          approved_minutes: @devlog_review.approved_minutes,
          justification: @devlog_review.justification
        }
      }
    else
      Rails.logger.debug "DevlogReview ##{@devlog_review.id} update failed: #{@devlog_review.errors.full_messages.join(', ')}"

      render json: {
        success: false,
        errors: @devlog_review.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_devlog_review
    @devlog_review = DevlogReview.find(params[:id])
  end

  def devlog_review_params
    params.require(:devlog_review).permit(:approved_minutes, :status, :justification)
  end
end
