from datetime import datetime, timedelta, timezone
from lib.db import db
import traceback

class CreateActivity:
    @staticmethod
    def run(message, cognito_user_id, ttl):
        print(f"DEBUG CreateActivity.run(): Starting with cognito_user_id={cognito_user_id}")
        model = {
            'errors': [],
            'data': None
        }
        
        now = datetime.now(timezone.utc).astimezone()
        ttl_offset = None
        
        if (ttl == '30-days'):
            ttl_offset = timedelta(days=30) 
        elif (ttl == '7-days'):
            ttl_offset = timedelta(days=7) 
        elif (ttl == '3-days'):
            ttl_offset = timedelta(days=3) 
        elif (ttl == '1-day'):
            ttl_offset = timedelta(days=1) 
        elif (ttl == '12-hours'):
            ttl_offset = timedelta(hours=12) 
        elif (ttl == '3-hours'):
            ttl_offset = timedelta(hours=3) 
        elif (ttl == '1-hour'):
            ttl_offset = timedelta(hours=1) 
        else:
            model['errors'].append('ttl_blank')
        
        if not cognito_user_id or len(cognito_user_id) < 1:
            model['errors'].append('cognito_user_id_blank')
        
        if not message or len(message) < 1:
            model['errors'].append('message_blank') 
        elif len(message) > 280:
            model['errors'].append('message_exceed_max_chars') 
        
        if model['errors']:
            model['data'] = {
                'cognito_user_id': cognito_user_id,
                'message': message
            }
            print(f"DEBUG CreateActivity.run(): Validation errors: {model['errors']}")
            return model
        
        try:
            expires_at = (now + ttl_offset)
            print(f"DEBUG CreateActivity.run(): Calling create_activity with cognito_user_id={cognito_user_id}, message={message}, expires_at={expires_at}")
            uuid = CreateActivity.create_activity(cognito_user_id, message, expires_at)
            print(f"DEBUG CreateActivity.run(): create_activity returned UUID: {uuid}")
            
            if uuid:
                print(f"DEBUG CreateActivity.run(): Querying object for UUID: {uuid}")
                object_json = CreateActivity.query_object_activity(uuid)
                model['data'] = object_json
                print(f"DEBUG CreateActivity.run(): Successfully created activity")
            else:
                model['errors'].append('failed_to_create_activity')
                print(f"DEBUG CreateActivity.run(): Failed - UUID was None")
        except Exception as e:
            print(f"DEBUG CreateActivity.run(): Exception: {e}")
            traceback.print_exc()
            model['errors'].append('internal_error')
        
        return model
    
    @staticmethod
    def create_activity(cognito_user_id, message, expires_at):
        try:
            print(f"DEBUG create_activity(): Starting with cognito_user_id={cognito_user_id}")
            
            check_sql = """
            SELECT uuid FROM public.users 
            WHERE cognito_user_id = %(cognito_user_id)s
            LIMIT 1
            """
            print(f"DEBUG create_activity(): Checking if user exists...")
            user = db.query_object_json(check_sql, {'cognito_user_id': cognito_user_id})
            print(f"DEBUG create_activity(): User query result: {user}")
            
            if not user or 'uuid' not in user:
                print(f"ERROR: User not found for cognito_user_id: {cognito_user_id}")
                return None
            
            print(f"DEBUG: Found user with UUID: {user['uuid']}")
            
            sql = db.template('activities','create')
            print(f"DEBUG create_activity(): SQL template loaded")
            
            params = {
                'cognito_user_id': cognito_user_id,
                'message': message,
                'expires_at': expires_at
            }
            
            print(f"DEBUG create_activity(): Executing INSERT with params: {params}")
            uuid = db.query_commit(sql, params)
            print(f"DEBUG create_activity(): INSERT returned UUID: {uuid}")
            
            return uuid
        except Exception as e:
            print(f"ERROR in create_activity: {e}")
            traceback.print_exc()
            return None
    
    @staticmethod           
    def query_object_activity(uuid):
        print(f"DEBUG query_object_activity(): Querying UUID: {uuid}")
        sql = db.template('activities','object')
        return db.query_object_json(sql, {
            'uuid': uuid
        })