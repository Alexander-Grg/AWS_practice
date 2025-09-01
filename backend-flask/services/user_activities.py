from datetime import datetime, timedelta, timezone
from aws_xray_sdk.core import xray_recorder

class UserActivities:
  def run(user_handle):
    try:
      model = {
        'errors': None,
        'data': None
      }

      now = datetime.now(timezone.utc).astimezone()
      
      if user_handle == None or len(user_handle) < 1:
        model['errors'] = ['blank_user_handle']
      else:
        now = datetime.now()
        results = [{
          'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
          'handle':  'Alex Grg',
          'message': 'Cloud is fun!',
          'created_at': (now - timedelta(days=1)).isoformat(),
          'expires_at': (now + timedelta(days=31)).isoformat()
        }]
        model['data'] = results
        
        # == MOVED X-RAY LOGIC INSIDE THE ELSE BLOCK ==
        subsegment = xray_recorder.begin_subsegment('mock-data')
        
        # == RENAMED 'dict' to 'subsegment_meta' ==
        subsegment_meta = {
          "now": now.isoformat(),
          "results-size": len(model['data'])
        }
        subsegment.put_metadata('results', subsegment_meta, 'namespace')

    finally:  
      if 'subsegment' in locals() and subsegment is not None:
        xray_recorder.end_subsegment()
        
    return model