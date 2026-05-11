class Mission::AchievementProxy
  # Mirrors the interface of the static `::Achievement` `Data.define` (slug,
  # name, description, icon, has_stardust_reward?, stardust_reward, progress)
  # so renderers and ledger logic can treat dynamic mission achievements
  # identically. Resolved lazily from the underlying `Mission` row.
  #
  # The slug pattern is `mission_<mission_slug>_completed`. Use
  # `Mission::AchievementProxy.find(slug)` to resolve from a stored
  # `User::Achievement.achievement_slug`.

  SLUG_RE = /\Amission_(?<mission_slug>[a-z0-9_-]+)_completed\z/
  ICON_FALLBACK = "icons/star_outline.svg".freeze

  attr_reader :mission

  def self.matches?(slug)
    slug.to_s =~ SLUG_RE
  end

  def self.find(slug)
    match = SLUG_RE.match(slug.to_s)
    return nil unless match
    mission = Mission.with_deleted.find_by(slug: match[:mission_slug])
    new(mission, slug: slug)
  end

  def initialize(mission, slug:)
    @mission = mission
    @slug = slug
  end

  def slug = @slug

  def name
    mission&.achievement_name.presence || "Mission completed"
  end

  def description
    mission&.achievement_description.presence || mission&.name
  end

  def icon
    # Mission rows hold their icon as an Active Storage attachment. Renderers
    # that key off a string slug (the static achievement icon path pattern)
    # need to handle this case explicitly; everything else can fall back.
    mission&.icon&.attached? ? mission.icon : ICON_FALLBACK
  end

  def has_stardust_reward? = false
  def stardust_reward      = 0
  def progress(_user)      = nil
end
