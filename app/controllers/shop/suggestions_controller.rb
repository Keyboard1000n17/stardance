class Shop::SuggestionsController < Shop::BaseController
  before_action -> { head :not_found unless Flipper.enabled?(:shop_suggestions, current_user) }

  def index
    authorize ShopSuggestion
    @new_suggestions = ShopSuggestion.kept.pending.includes(:user, :shop_suggestion_votes).order(created_at: :desc).limit(6)
    @suggestions = ShopSuggestion
      .kept
      .pending
      .includes(:user, :shop_suggestion_votes)
      .sort_by { |s| [ -s.vote_count, -s.id ] }
  end

  def history
    authorize ShopSuggestion
    @decided = ShopSuggestion.kept.where(aasm_state: [ :accepted, :rejected ]).includes(:user, :shop_suggestion_votes).order(updated_at: :desc)
  end

  def create
    authorize ShopSuggestion

    @suggestion = current_user.shop_suggestions.build(suggestion_params)

    if @suggestion.save
      redirect_to shop_suggestions_path, notice: "Your suggestion was submitted! #{ShopSuggestion::SUBMISSION_COST} Stardust has been deducted."
    else
      @new_suggestions = ShopSuggestion.kept.pending.includes(:user, :shop_suggestion_votes).order(created_at: :desc).limit(6)
      @suggestions = ShopSuggestion
        .kept
        .pending
        .includes(:user, :shop_suggestion_votes)
        .sort_by { |s| [ -s.vote_count, -s.id ] }
      render :index, status: :unprocessable_entity
    end
  end

  private

  def suggestion_params
    params.require(:shop_suggestion).permit(:name, :description, :url, :usd_cost, :image)
  end
end
