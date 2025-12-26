from datetime import datetime, timedelta, timezone
from opentelemetry import trace
from lib.db import db

class HomeActivities:
    def run(cognito_user_id=None):
        print(f"DEBUG: HomeActivities.run() called with cognito_user_id={cognito_user_id}")
        
        sql = db.template('activities', 'home')
        print(f"DEBUG: RAW SQL Template:")
        print("=" * 50)
        print(sql)
        print("=" * 50)
        
        params = {
            'cognito_user_id': cognito_user_id
        }
        print(f"DEBUG: Params: {params}")
        
        results = db.query_array_json(sql, params)
        
        print(f"DEBUG: Query returned {len(results) if results else 0} results")
        return results