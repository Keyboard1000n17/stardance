class HomeStatsComponent < ApplicationComponent
  def initialize(user:)
    @user = user
  end

  def view_template
      h2(class: "home-stats__title") { "Your Progress" }
      div(class: "home-stats__grid") do
        render_achievements_card
        render_leaderboard_card
      end
  end

  private

  def render_achievements_card
    user_achievement_slugs = @user.achievements.pluck(:achievement_slug).to_set
    countable = Achievement.countable.select { |a| a.shown_to?(@user, earned: user_achievement_slugs.include?(a.slug.to_s)) }
    earned_count = countable.count { |a| user_achievement_slugs.include?(a.slug.to_s) }
    total_count = countable.count

    div(class: "state-card state-card--neutral home-stats-card") do
      div(class: "home-stats-card__content") do
        div(class: "state-card__title") { "Achievements" }
        div(class: "home-stats-card__stat") do
          span(class: "home-stats-card__count") { earned_count.to_s }
          span(class: "home-stats-card__total") { " / #{total_count}" }
        end
        div(class: "state-card__description") do
          if earned_count.zero?
            "Start earning achievements!"
          elsif earned_count == total_count
            "All achievements unlocked!"
          else
            "#{((earned_count.to_f / total_count) * 100).round}% collected"
          end
        end
      end
      div(class: "state-card__cta") do
        a(href: helpers.my_achievements_path, class: "btn btn--borderless btn--bg_yellow") do
          span { "View Achievements" }
        end
      end
    end
  end

  def render_leaderboard_card
    rank = calculate_rank
    balance = @user.balance
    preference = @user.preference

    div(class: "state-card state-card--neutral home-stats-card") do
      div(class: "home-stats-card__content") do
        div(class: "state-card__title") { "Leaderboard" }
        div(class: "home-stats-card__stat") do
          if preference.leaderboard_optin? && rank
            span(class: "home-stats-card__rank") { "You are ##{rank}" }
          else
            span(class: "home-stats-card__rank home-stats-card__rank--unranked") { "Unranked" }
          end
        end
        div(class: "state-card__description") do
          if preference.leaderboard_optin?
            plain "#{balance} "
            img src: helpers.image_path("icons/stardust.png"), alt: "Stardust", class: "currency-icon"
            plain " earned"
          else
            plain "Opt in via settings to rank"
          end
        end
      end
      div(class: "state-card__cta") do
        a(href: helpers.leaderboard_path, class: "btn btn--borderless btn--bg_yellow") do
          span { "View Leaderboard" }
        end
      end
    end
  end

  def calculate_rank
    return nil unless @user.preference.leaderboard_optin?

    scope = User.joins(:preference).where(user_preferences: { leaderboard_optin: true })

    scope.where("(SELECT COALESCE(SUM(amount), 0) FROM ledger_entries WHERE user_id = users.id) > ?", @user.balance)
         .count + 1
  end
end
