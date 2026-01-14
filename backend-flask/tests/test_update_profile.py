import pytest
from unittest.mock import MagicMock, patch
from services.update_profile import UpdateProfile

def test_update_profile_validation():
    # Test blank display_name
    result = UpdateProfile.run(
        cognito_user_id="user123",
        bio="Hello",
        display_name=""
    )
    assert 'display_name_blank' in result['errors']

@patch('services.update_profile.UpdateProfile.query_users_short')
@patch('services.update_profile.UpdateProfile.update_profile')
def test_update_profile_success(mock_update, mock_query):
    # Mock return values
    mock_update.return_value = "new_handle"
    mock_query.return_value = {"handle": "new_handle", "bio": "New Bio"}

    # Run
    result = UpdateProfile.run(
        cognito_user_id="user123",
        bio="New Bio",
        display_name="New Name"
    )

    # Assert
    assert result['errors'] is None
    assert result['data']['handle'] == "new_handle"