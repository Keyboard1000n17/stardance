require "test_helper"

class Admin::Missions::SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reviewer = User.create!(email: "reviewer-#{SecureRandom.hex(4)}@example.test",
                             display_name: "reviewer-#{SecureRandom.hex(4)}",
                             slack_id: "U#{SecureRandom.hex(8)}",
                             granted_roles: [ "mission_reviewer" ])
    @builder = User.create!(email: "builder-#{SecureRandom.hex(4)}@example.test",
                            display_name: "builder-#{SecureRandom.hex(4)}",
                            slack_id: "U#{SecureRandom.hex(8)}")
    @project = Project.create!(title: "Queue Test Project")
    @project.memberships.create!(user: @builder, role: :owner)
    @mission = create_mission
    @project.mission_attachments.create!(mission: @mission)
    @submission = ship_to_mission!(@project, @builder, @mission, status: "pending")
  end

  test "reviewer walks the queue: index, next claims oldest, approve advances" do
    sign_in @reviewer

    get admin_mission_submissions_path(@mission.slug)
    assert_response :success

    get next_admin_mission_submissions_path(@mission.slug)
    assert_redirected_to admin_mission_submission_path(@mission.slug, @submission)
    assert_equal @reviewer.id, @submission.reload.reviewed_by_id

    patch admin_mission_submission_path(@mission.slug, @submission),
          params: { mission_submission: { status: "approved" } }
    assert_redirected_to next_admin_mission_submissions_path(@mission.slug)
    assert @submission.reload.approved?
    assert_equal 1, Mission::Submission.reviewed_today(@reviewer, mission: @mission)
  end

  test "rejecting without feedback bounces back" do
    sign_in @reviewer
    Mission::Submission.atomic_claim!(@submission.id, @reviewer)

    patch admin_mission_submission_path(@mission.slug, @submission),
          params: { mission_submission: { status: "rejected", feedback: "" } }

    assert_redirected_to admin_mission_submission_path(@mission.slug, @submission)
    assert @submission.reload.pending?
  end

  test "claims are exclusive while fresh and stealable when expired" do
    other = User.create!(email: "other-#{SecureRandom.hex(4)}@example.test",
                         display_name: "other-#{SecureRandom.hex(4)}",
                         slack_id: "U#{SecureRandom.hex(8)}",
                         granted_roles: [ "mission_reviewer" ])
    assert Mission::Submission.atomic_claim!(@submission.id, other)

    assert_nil Mission::Submission.atomic_claim!(@submission.id, @reviewer)

    @submission.reload.update_columns(claim_expires_at: 1.minute.ago)
    assert Mission::Submission.atomic_claim!(@submission.id, @reviewer)
  end

  test "the all-missions queue works without a specific mission" do
    sign_in @reviewer

    get admin_mission_submissions_path("all")
    assert_response :success

    get next_admin_mission_submissions_path("all")
    assert_redirected_to admin_mission_submission_path("all", @submission)
    assert_equal @reviewer.id, @submission.reload.reviewed_by_id
  end

  test "overview lists per-mission queue depth" do
    sign_in @reviewer
    get admin_mission_reviews_path
    assert_response :success
  end

  test "builders cannot reach the queue" do
    sign_in @builder
    get admin_mission_submissions_path(@mission.slug)
    assert_not_equal 200, response.status
  end
end
