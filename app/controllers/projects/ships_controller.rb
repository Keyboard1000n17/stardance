class Projects::ShipsController < ApplicationController
  before_action :set_project
  before_action :setup_chrome,    only: [ :new, :compose, :create ]
  before_action :require_shippable, only: [ :compose, :create ]

  # Step 0 — "what is a ship" refresher (video only). Entry point.
  def new
    authorize @project, :ship?
    @step = 0
  end

  # Step 1 — ship composer (the only real step). Writing the ship post,
  # acknowledging mission requirements, and shipping all happen here.
  # Requires the project to be shippable (handled by the before_action).
  def compose
    authorize @project, :ship?
    @step = 1
    @last_ship = @project.last_ship_event
  end

  def create
    authorize @project, :ship?
    # Everything posts from the single ship page, so read straight from params.
    mission_payout_path = params[:mission_payout_path]
    submission_guide_ack = params[:mission_submission_guide_acknowledged].to_s == "1"

    if mission_submission_guide_ack_required? && !submission_guide_ack
      redirect_to compose_project_ships_path(@project),
                  alert: "Read and acknowledge the mission submission guide before shipping." and return
    end

    unless @project.readme_is_raw_github_url?
      flash.now[:warning] = "Your README link doesn't appear to be a raw GitHub URL. We require raw README files (from raw.githubusercontent.com) for proper display and consistency. Please update your README URL."
    end

    reship = had_prior_ship_event?
    probe_result = reship ? ProjectUrlProbeService.new(@project).call : nil

    @project.with_lock do
      @project.submit_for_review!
      ship_event = Post::ShipEvent.create!(
        body: params[:ship_update].to_s.strip
      )
      @post = @project.posts.create!(user: current_user, postable: ship_event)
      maybe_create_mission_submission(ship_event, mission_payout_path, submission_guide_ack)
      maybe_create_ysws_review(ship_event)
    end

    if !reship
      redirect_to project_path(@project, just_shipped: 1), notice: "Congratulations! Your project has been submitted for review! While you wait, rate other projects at the voting booth."
    elsif probe_result.ok?
      @post.postable.update!(certification_status: "approved")
      redirect_to project_path(@project, just_shipped: 1), notice: "Ship submitted! Your project is now out for voting. Rate other projects to help yours get noticed too."
    else
      @project.ship_reviews.pending.first&.update!(
        status: :returned,
        feedback: "Automated URL check failed: #{probe_result.failures.join('; ')}. Fix and re-ship."
      )
      redirect_to project_path(@project), notice: "Your project needs changes. We couldn't reach your demo or repo. Fix those and re-ship."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: new_project_ships_path(@project), alert: e.record.errors.full_messages.to_sentence
  end

  private
    def set_project
      @project = Project.find(params[:project_id])
    end

    # Shared chrome state for every wizard step: hide the global sidebar and
    # apply the ship-page body class so the layout knows we're in the wizard.
    def setup_chrome
      @hide_sidebar = true
      @body_class = "ship-page"
    end

    # The review/ship steps can only be reached once the project meets every
    # shipping requirement. If a user lands on those URLs early (typed-in URL,
    # stale bookmark, mid-flow regression), bounce them back to the project
    # page, where project info is completed and remaining requirements surface.
    def require_shippable
      return if @project.shippable?
      redirect_to project_path(@project), alert: "Finish the remaining requirements before shipping."
    end

    def initial_ship?
      @project.posts.where(postable_type: "Post::ShipEvent").one?
    end

    def had_prior_ship_event?
      @project.posts.where(postable_type: "Post::ShipEvent").exists?
    end

    def mission_submission_guide_ack_required?
      mission = @project.current_mission
      return false if mission.nil? || @project.shipped_to_mission?(mission)
      mission.submission_guide.present?
    end

    def maybe_create_mission_submission(ship_event, payout_path_param, submission_guide_acknowledged = false)
      attachment = @project.current_mission_attachment
      return unless attachment

      mission = attachment.mission
      # Only the first ship to a mission counts; later ships are regular ships.
      return if @project.shipped_to_mission?(mission)
      payout_path = resolve_payout_path(mission, payout_path_param)
      ack_time = (submission_guide_acknowledged && mission.submission_guide.present?) ? Time.current : nil

      # Don't pass status — AASM defaults it and rejects direct assignment.
      Mission::Submission.create!(
        ship_event: ship_event,
        mission: mission,
        payout_path: payout_path,
        submission_guide_acknowledged_at: ack_time
      )
    end

    def resolve_payout_path(mission, payout_path_param)
      return "voting" unless mission.has_prizes?
      return "voting" if user_redeemed_prize_for?(mission)
      payout_path_param.to_s == "voting" ? "voting" : "static_prize"
    end

    def user_redeemed_prize_for?(mission)
      Mission::Submission
        .where(mission_id: mission.id)
        .joins(ship_event: { post: :user })
        .where(users: { id: current_user.id })
        .where.not(shop_order_id: nil)
        .exists?
    end

    def maybe_create_ysws_review(ship_event)
      # Only create review if this is NOT the first ship (i.e., there are previous approved ships)
      return unless has_previous_approved_ships?

      # Calculate hours worked between ships and convert to minutes
      hours_worked = ship_event.hours || 0
      original_minutes = (hours_worked * 60).to_i

      Certification::Ysws.create!(
        user: current_user,
        project: @project,
        post_ship_event: ship_event,
        ship_cert_id: nil, # Will be set later when this ship is certified
        original_minutes: original_minutes,
        approved_minutes: nil, # Will be set by reviewer
        reviewed_at: nil, # Will be set when reviewed
        reviewer_id: nil # Will be assigned by admin
      )
    end

    def has_previous_approved_ships?
      @project.posts
        .joins("INNER JOIN post_ship_events ON posts.postable_id = post_ship_events.id AND posts.postable_type = 'Post::ShipEvent'")
        .where(post_ship_events: { certification_status: "approved" })
        .exists?
    end
end
