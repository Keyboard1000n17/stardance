require "test_helper"
require "base64"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(verification_status: :verified, ysws_eligible: true)
    @project = projects(:one)
    @other_project = projects(:two)
    @project.update!(title: "Current user project")
    @other_project.update!(title: "Recommended project")
    @devlog = create_devlog(body: "Home feed update")
    @post = Post.create!(project: @other_project, user: users(:two), postable: @devlog)
  end

  test "home page loads for signed in user" do
    sign_in @user

    get home_path

    assert_response :success
    assert_select ".feed-composer"
    assert_select ".feed-post-card"
    assert_select ".feed-shelf"
  end

  test "home feed excludes deleted devlogs for normal users" do
    @devlog.update!(deleted_at: Time.current)
    sign_in @user

    get home_path

    assert_response :success
    assert_select ".feed-post-card", count: 0
    assert_no_match "Home feed update", response.body
  end

  test "recommended projects exclude current user's projects" do
    sign_in @user

    get home_path

    assert_response :success
    assert_no_match @project.title, response.body.scan(/project-shelf-card.*?<\/a>/m).join
  end

  private

  def create_devlog(body:)
    devlog = Post::Devlog.new(body: body, duration_seconds: 1.hour)
    devlog.attachments.attach(
      io: StringIO.new(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=")),
      filename: "progress.png",
      content_type: "image/png"
    )
    devlog.save!
    devlog
  end
end
