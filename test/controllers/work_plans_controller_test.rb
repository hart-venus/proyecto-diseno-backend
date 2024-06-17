require 'test_helper'

class WorkPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @work_plan = WorkPlan.create(
      coordinator_id: "coordinator_id",
      start_date: Date.today,
      end_date: Date.today + 1.month,
      campus: "Campus",
      active: true
    )
  end

  test "should get index" do
    get '/work_plans'
    assert_response :success
  end

  test "should create work plan" do
    professor = { id: "professor_id", coordinator: true }
    mock_firestore = Minitest::Mock.new
    mock_firestore.expect :col, mock_firestore, ['professors']
    mock_firestore.expect :where, mock_firestore, ['user_id', '==', 'user_id']
    mock_firestore.expect :get, [OpenStruct.new(data: professor, document_id: "professor_id")], []

    FirestoreDB.stub :col, mock_firestore do
      assert_difference('WorkPlan.count') do
        post '/work_plans', params: {
          work_plan: {
            start_date: Date.today,
            end_date: Date.today + 1.month,
            campus: "Campus",
            active: true
          },
          user_id: "user_id"
        }
      end
    end

    assert_mock mock_firestore
    assert_response :created
  end

  test "should show work plan" do
    get "/work_plans/#{@work_plan.id}"
    assert_response :success
  end

  test "should update work plan" do
    professor = { id: "professor_id", coordinator: true }
    mock_firestore = Minitest::Mock.new
    mock_firestore.expect :col, mock_firestore, ['professors']
    mock_firestore.expect :where, mock_firestore, ['user_id', '==', 'user_id']
    mock_firestore.expect :get, [OpenStruct.new(data: professor, document_id: "professor_id")], []

    FirestoreDB.stub :col, mock_firestore do
      patch "/work_plans/#{@work_plan.id}", params: {
        work_plan: {
          start_date: Date.today,
          end_date: Date.today + 2.months
        },
        user_id: "user_id"
      }
    end

    assert_mock mock_firestore
    assert_response :success
  end

  test "should get active work plans" do
    get '/work_plans/active'
    assert_response :success
  end

  test "should get inactive work plans" do
    get '/work_plans/inactive'
    assert_response :success
  end
end