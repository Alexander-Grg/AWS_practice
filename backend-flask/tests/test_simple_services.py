import pytest
from unittest.mock import MagicMock, patch
from services.home_activities import HomeActivities
from services.show_activity import ShowActivity
from services.users_short import UsersShort
from services.user_activities import UserActivities
from services.notifications_activities import NotificationsActivities

@patch('services.home_activities.db')
def test_home_activities(mock_db):
    mock_db.query_array_json.return_value = [{"uuid": "123"}]
    results = HomeActivities.run(cognito_user_id="user123")
    assert len(results) == 1
    mock_db.query_array_json.assert_called_once()

@patch('services.show_activity.db')
def test_show_activity(mock_db):
    mock_db.query_object_json.return_value = {"uuid": "123"}
    result = ShowActivity.run(activity_uuid="123")
    assert result['uuid'] == "123"

@patch('services.users_short.db')
def test_users_short(mock_db):
    mock_db.query_object_json.return_value = {"handle": "alex"}
    result = UsersShort.run(handle="alex")
    assert result['handle'] == "alex"

@patch('services.user_activities.db')
def test_user_activities(mock_db):
    # Test validation error
    res_error = UserActivities.run(user_handle="")
    assert 'blank_user_handle' in res_error['errors']

    # Test success
    mock_db.query_object_json.return_value = {"activities": []}
    res_success = UserActivities.run(user_handle="alex")
    assert res_success['data'] is not None

def test_notifications_activities():
    # This service returns static data, no need to mock DB
    results = NotificationsActivities.run()
    assert len(results) > 0
    assert results[0]['handle'] == 'coco'