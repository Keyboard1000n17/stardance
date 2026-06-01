# frozen_string_literal: true

class GuestSidebarComponent < ViewComponent::Base
  delegate :inline_svg_tag, to: :helpers

  def nav_items
    [
      { slug: "home",      label: "home",      path: helpers.home_path,
        icon: { idle: "rocket", active: "rocket_active" } },
      { slug: "missions",  label: "missions",  path: helpers.missions_path,
        icon: { idle: "calendar", active: "calendar_active" } },
      { slug: "shop",      label: "shop",      path: "/shop",
        icon: { idle: "cart", active: "cart_active" } },
      { slug: "resources", label: "resources",  path: helpers.guides_path,
        icon: { idle: "book", active: "book_active" } }
    ]
  end

  def active?(item)
    candidate_path = item[:path]
    return false if candidate_path == "#"

    helpers.current_page?(candidate_path) ||
      helpers.request.path == candidate_path ||
      helpers.request.path.start_with?("#{candidate_path}/")
  end

  def link_classes_for(item)
    [ "sidebar__nav-link", ("sidebar__nav-link--active" if active?(item)) ].compact.join(" ")
  end
end
