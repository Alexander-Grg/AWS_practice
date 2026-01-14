import pytest
from unittest.mock import MagicMock, patch

# Adjust import based on your actual file structure
from services.create_message import CreateMessage

@patch('services.create_message.Ddb') # Mock DynamoDB wrapper
@patch('services.create_message.db')  # Mock SQL wrapper
def test_create_message_mode_create(mock_db, mock_ddb):
    """
    Test the 'create' mode where a new message group is initialized.
    """
    # 1. Setup Mock DB response for user lookup
    # The code expects a list of users (sender and receiver)
    mock_db.query_array_json.return_value = [
        {"kind": "sender", "uuid": "u1", "display_name": "Alex", "handle": "alex_handle"},
        {"kind": "recv", "uuid": "u2", "display_name": "Bob", "handle": "bob_handle"}
    ]
    
    # 2. Setup Mock DDB response
    mock_ddb_client = MagicMock()
    mock_ddb.client.return_value = mock_ddb_client
    mock_ddb.create_message_group.return_value = {"message_group_uuid": "new-group-uuid"}

    # 3. Run the function
    result = CreateMessage().run(
        mode="create",
        message="Hello there",
        cognito_user_id="alex_cognito",
        user_receiver_handle="bob_handle"
    )

    # 4. Assertions
    assert result['errors'] is None
    assert result['data']['message_group_uuid'] == "new-group-uuid"

    # Verify we actually called Ddb.create_message_group, NOT create_message
    mock_ddb.create_message_group.assert_called_once()
    mock_ddb.create_message.assert_not_called()

@patch('services.create_message.Ddb')
@patch('services.create_message.db')
def test_create_message_mode_update(mock_db, mock_ddb):
    """
    Test the 'update' mode where we add to an existing group.
    """
    # 1. Setup Mock DB response
    mock_db.query_array_json.return_value = [
        {"kind": "sender", "uuid": "u1", "display_name": "Alex", "handle": "alex_handle"},
        {"kind": "recv", "uuid": "u2", "display_name": "Bob", "handle": "bob_handle"}
    ]
    
    # 2. Setup Mock DDB response
    mock_ddb.create_message.return_value = {"message_uuid": "msg-123"}

    # 3. Run the function
    result = CreateMessage().run(
        mode="update",
        message="Reply message",
        cognito_user_id="alex_cognito",
        message_group_uuid="existing-group-uuid"
    )

    # 4. Assertions
    assert result['errors'] is None
    
    # Verify we called Ddb.create_message this time
    mock_ddb.create_message.assert_called_once()
    
    # Verify arguments passed to Ddb
    call_args = mock_ddb.create_message.call_args
    assert call_args.kwargs['message_group_uuid'] == "existing-group-uuid"
    assert call_args.kwargs['message'] == "Reply message"