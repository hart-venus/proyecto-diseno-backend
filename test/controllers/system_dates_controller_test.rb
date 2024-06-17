require 'test_helper'

class SystemDatesControllerTest < ActionDispatch::IntegrationTest
  test "should get current system date" do
    get 'http://localhost:3000/system_date'
    assert_response :success
    assert_equal SystemDate.current_date.date.to_s, JSON.parse(response.body)['date']
  end

  test "should update system date" do
    new_date = '2023-06-20'
    put 'http://localhost:3000/system_date', params: { system_date: { date: new_date } }
    assert_response :success
    assert_equal new_date, JSON.parse(response.body)['date']
  end

  test "should handle invalid date format" do
    invalid_date = 'invalid_date'
    put 'http://localhost:3000/system_date', params: { system_date: { date: invalid_date } }
    assert_response :bad_request
    assert_equal 'Formato de fecha inválido', JSON.parse(response.body)['error']
  end

  test "should increment system date" do
    current_date = SystemDate.current_date.date
    days = 5
    post 'http://localhost:3000/system_date/increment', params: { days: days }
    assert_response :success
    assert_equal (current_date + days.days).to_s, JSON.parse(response.body)['date']
  end

  test "should decrement system date" do
    current_date = SystemDate.current_date.date
    days = 3
    post 'http://localhost:3000/system_date/decrement', params: { days: days }
    assert_response :success
    assert_equal (current_date - days.days).to_s, JSON.parse(response.body)['date']
  end
end