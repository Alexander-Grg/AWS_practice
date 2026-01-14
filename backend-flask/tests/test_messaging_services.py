import pytest
from unittest.mock import MagicMock, patch
from services.message_groups import MessageGroups
from services.messages import Messages

@patch('services.message_groups.Ddb')
@patch('services.message_groups.db')
def test_message_groups_run(mock_db, mock_ddb):
    # 1. Mock SQL return (user lookup)
    mock_db.query_value.return_value = "user-uuid-123"
    
    # 2. Mock DDB return
    mock_ddb_client = MagicMock()
    mock_ddb.client.return_value = mock_ddb_client
    mock_ddb.list_message_groups.return_value = [{"uuid": "group1"}]

    # 3. Run
    result = MessageGroups.run(cognito_user_id="cognito123")

    # 4. Assert
    assert result['data'] == [{"uuid": "group1"}]
    mock_db.query_value.assert_called_once()
    mock_ddb.list_message_groups.assert_called_with(mock_ddb_client, "user-uuid-123")

@patch('services.messages.Ddb')
@patch('services.messages.db')
def test_messages_run(mock_db, mock_ddb):
    # 1. Mock SQL return
    mock_db.query_value.return_value = "user-uuid-123"

    # 2. Mock DDB return
    mock_ddb_client = MagicMock()
    mock_ddb.client.return_value = mock_ddb_client
    mock_ddb.list_messages.return_value = [{"message": "hello"}]

    # 3. Run
    result = Messages.run(
        message_group_uuid="group-123", 
        cognito_user_id="cognito123"
    )

    # 4. Assert
    assert result['data'] == [{"message": "hello"}]
    mock_ddb.list_messages.assert_called_with(mock_ddb_client, "group-123")