require "test_helper"

class Projects::DevlogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(slack_id: "U_DEVLOG_OWNER", display_name: "devlog_owner", email: "devlog_owner@example.test")
    @project = Project.create!(title: "No Hackatime Yet", description: "Still needs setup")
    @project.memberships.create!(user: @owner, role: :owner)
  end

  test "posting a devlog without linked hackatime project returns to project page" do
    sign_in @owner

    post project_devlogs_path(@project), params: {
      post_devlog: {
        body: "Worked on the first pass."
      }
    }

    assert_redirected_to project_path(@project)
    assert_equal "You must link at least one Hackatime project before posting a devlog", flash[:alert]
  end
end
