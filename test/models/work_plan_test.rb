# test/models/work_plan_test.rb
require 'test_helper'

class WorkPlanTest < ActiveSupport::TestCase
  test "should not save work plan without required fields" do
    work_plan = WorkPlan.new
    assert_not work_plan.save, "Saved the work plan without required fields"
  end

  test "should save work plan with valid attributes" do
    work_plan = WorkPlan.new(
      coordinator_id: "coordinator_id",
      start_date: Date.today,
      end_date: Date.today + 1.month,
      campus: "Campus",
      active: true
    )
    assert work_plan.save, "Failed to save the work plan with valid attributes"
  end

  test "should not save work plan with end date before start date" do
    work_plan = WorkPlan.new(
      coordinator_id: "coordinator_id",
      start_date: Date.today,
      end_date: Date.today - 1.day,
      campus: "Campus",
      active: true
    )
    assert_not work_plan.save, "Saved the work plan with end date before start date"
    assert_includes work_plan.errors.full_messages, "End date debe ser posterior a la fecha de inicio"
  end
end