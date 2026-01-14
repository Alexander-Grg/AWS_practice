import pytest
from unittest.mock import MagicMock, patch
from services.create_reply import CreateReply

@patch('services.create_reply.db')
def test_create_reply_validation(mock_db):
    # Test blank message
    result = CreateReply.run(
        message="", 
        cognito_user_id="user123", 
        activity_uuid="uuid-abc"
    )
    assert 'message_blank' in result['errors']

    # Test blank activity_uuid
    result = CreateReply.run(
        message="Hello", 
        cognito_user_id="user123", 
        activity_uuid=""
    )
    assert 'activity_uuid_blank' in result['errors']

@patch('services.create_reply.CreateReply.query_object_activity')
@patch('services.create_reply.CreateReply.create_reply')
def test_create_reply_success(mock_create, mock_query):
    # Setup mocks
    mock_create.return_value = "new-reply-uuid"
    mock_query.return_value = {"uuid": "new-reply-uuid", "message": "Hello"}

    # Run
    result = CreateReply.run(
        message="Hello", 
        cognito_user_id="user123", 
        activity_uuid="uuid-abc"
    )

    # Assert
    assert result['errors'] is None
    assert result['data']['uuid'] == "new-reply-uuid"