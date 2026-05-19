module BioHelper
  TOKEN_RE = /<(@|\$)(\d+)>/
  URL_RE   = %r{\bhttps?://[^\s<>]+}

  # Render a user's bio with auto-linked URLs and resolved <@id>/<$id> tokens.
  # Returns html_safe markup; preserves newlines as <br>.
  def render_bio(text)
    return "".html_safe if text.blank?

    text = text.strip

    user_ids, project_ids = collect_token_ids(text)
    users = User.where(id: user_ids).index_by(&:id) if user_ids.any?
    projects = Project.where(id: project_ids).index_by(&:id) if project_ids.any?
    users ||= {}
    projects ||= {}

    out = +""
    cursor = 0
    pattern = Regexp.union(TOKEN_RE, URL_RE)

    text.scan(pattern) do
      match = Regexp.last_match
      out << ERB::Util.html_escape(text[cursor...match.begin(0)]).gsub("\n", "<br>")

      if match[1] && match[2]
        out << render_token(match[1], match[2].to_i, users: users, projects: projects)
      else
        url = match[0]
        out << link_to(url, url, class: "bio-link", target: "_blank", rel: "noopener nofollow")
      end

      cursor = match.end(0)
    end

    out << ERB::Util.html_escape(text[cursor..]).gsub("\n", "<br>") if cursor < text.length
    out.html_safe
  end

  private

  def collect_token_ids(text)
    user_ids = []
    project_ids = []
    text.scan(TOKEN_RE) do |sigil, id|
      (sigil == "@" ? user_ids : project_ids) << id.to_i
    end
    [ user_ids, project_ids ]
  end

  def render_token(sigil, id, users:, projects:)
    # The bio is rendered inside the `profile_card` Turbo Frame, so:
    # - turbo_frame: "_top" breaks out of the frame for full-page navigation
    #   (otherwise turbo:load doesn't fire and `nav-history` won't record it).
    # - turbo_prefetch: "true" opts back into Turbo's hover-prefetching, which
    #   is globally disabled in the layout — without this the click would
    #   feel sluggish since the destination is fetched on click rather than
    #   on hover.
    link_data = { turbo_frame: "_top", turbo_prefetch: "true" }

    if sigil == "@"
      user = users[id]
      return ERB::Util.html_escape("<@#{id}>") unless user
      link_to("@#{user.display_name}", user_path(user), class: "bio-mention bio-mention--user", data: link_data)
    else
      project = projects[id]
      return ERB::Util.html_escape("<$#{id}>") unless project
      link_to(project.title, project_path(project), class: "bio-mention bio-mention--project", data: link_data)
    end
  end
end
