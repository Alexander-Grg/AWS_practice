import pytest
from unittest.mock import MagicMock, patch
from datetime import timedelta

# Assuming your class is in a file named services/create_activity.py
# Adjust the import based on your actual folder structure
from services.create_activity import CreateActivity

@patch('services.create_activity.db') # Mock the database module imported inside your service
def test_create_activity_validation_errors(mock_db):
    """
    Test that invalid inputs return the expected error codes 
    without trying to touch the database.
    """
    # 1. Test invalid TTL
    result = CreateActivity.run(
        message="Hello World", 
        cognito_user_id="user123", 
        ttl="invalid-ttl"
    )
    assert 'ttl_blank' in result['errors']

    # 2. Test empty message
    result = CreateActivity.run(
        message="", 
        cognito_user_id="user123", 
        ttl="7-days"
    )
    assert 'message_blank' in result['errors']

    # 3. Test message too long
    long_message = "x" * 300
    result = CreateActivity.run(
        message=long_message, 
        cognito_user_id="user123", 
        ttl="7-days"
    )
    assert 'message_exceed_max_chars' in result['errors']

@patch('services.create_activity.CreateActivity.query_object_activity')
@patch('services.create_activity.CreateActivity.create_activity')
def test_create_activity_success(mock_create, mock_query):
    """
    Test the happy path. We mock the internal static methods 
    so we don't actually run SQL.
    """
    # Setup the mocks to return fake data
    mock_create.return_value = "uuid-1234" # Simulate a successful DB insert returning a UUID
    mock_query.return_value = {"uuid": "uuid-1234", "message": "Success"} # Simulate fetching the object

    result = CreateActivity.run(
        message="Hello World", 
        cognito_user_id="user123", 
        ttl="7-days"
    )

    # Assertions
    assert result['errors'] == []
    assert result['data']['uuid'] == "uuid-1234"
    
    # Verify create_activity was called with correct args
    mock_create.assert_called_once()