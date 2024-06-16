require 'test_helper'

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get activities_url, params: { work_plan_id: 'abc123' }
    assert_response :success
  end

  test "should get show" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'PLANEADA')
    get activity_url(activity)
    assert_response :success
  end

  test "should create activity" do
    assert_difference('Activity.count') do
      post activities_url, params: {
        work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'New Activity',
        realization_date: '2023-06-25', realization_time: '14:30', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
        publication_days_before: 3, reminder_frequency_days: 1, is_remote: false,
        poster_file: fixture_file_upload('IC Primer Proyecto de Diseño de Software IS 2024 (2).pdf', 'application/pdf')
      }
    end
    assert_response :created
  end

  test "should update activity" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'PLANEADA')
    put activity_url(activity), params: { name: 'Updated Activity' }
    assert_response :success
    activity.reload
    assert_equal 'Updated Activity', activity.name
  end

  test "should add evidence" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'PLANEADA')
    post activity_evidence_url(activity), params: { evidence_file: fixture_file_upload('evidence.pdf', 'application/pdf') }
    assert_response :success
    activity.reload
    assert_not_empty activity.evidences
  end

  test "should activate activity" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'PLANEADA')
    put activate_activity_url(activity)
    assert_response :success
    activity.reload
    assert_equal 'NOTIFICADA', activity.status
  end

  test "should notify activity" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'PLANEADA')
    put notify_activity_url(activity)
    assert_response :success
    activity.reload
    assert_equal 'NOTIFICADA', activity.status
    assert_equal SystemDate.current_date.date, activity.notification_date
  end

  test "should mark activity as done" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'NOTIFICADA')
    put mark_as_done_activity_url(activity), params: { evidence_files: [fixture_file_upload('evidence1.pdf', 'application/pdf'), fixture_file_upload('evidence2.pdf', 'application/pdf')] }
    assert_response :success
    activity.reload
    assert_equal 'REALIZADA', activity.status
  end

  test "should cancel activity" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'NOTIFICADA')
    put cancel_activity_path(activity), params: { cancel_reason: 'Reason for cancellation' }
    assert_response :success
    activity.reload
    assert_equal 'CANCELADA', activity.status
    assert_equal 'Reason for cancellation', activity.cancel_reason
  end

  test "should get notified activities" do
    get notified_activities_url, params: { work_plan_id: 'abc123' }
    assert_response :success
  end

  test "should get poster" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'PLANEADA',
                               poster_url: 'https://example.com/poster.pdf')
    get poster_activity_url(activity)
    assert_response :success
  end

  test "should check if activity should notify" do
    activity = Activity.create(work_plan_id: 'abc123', week: 1, activity_type: 'Meeting', name: 'Test Activity',
                               realization_date: '2023-06-20', realization_time: '10:00', responsible_ids: ['7XSX3TTBfrfryOyYROqc'],
                               publication_days_before: 5, reminder_frequency_days: 2, is_remote: true, status: 'PLANEADA')
    get should_notify_activity_url(activity)
    assert_response :success
  end
end