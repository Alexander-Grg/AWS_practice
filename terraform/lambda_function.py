import json
import psycopg2
import os

def lambda_handler(event, context):
    """
    Cognito Post-Confirmation Lambda
    Syncs the new user from Cognito into the RDS 'users' table.
    """
    print('== Connection starting...')
    print('FULL EVENT:', event)

    user_attrs = event['request']['userAttributes']
    
    user_display_name = user_attrs.get('name', 'No Name')
    user_email        = user_attrs.get('email')
    user_cognito_id   = user_attrs.get('sub')
    user_handle       = user_attrs.get('preferred_username')

    # Guard clause
    if not user_email or not user_handle:
        print("ERROR: Missing email or handle in Cognito attributes.")
        return event

    conn = None # Initialize here to be safe
    try:
        print('== Connecting to DB...')
        # UPDATED: Matches your Terraform variable
        conn = psycopg2.connect(os.getenv('PROD_CONNECTION_STRING'))
        cur = conn.cursor()
        
        sql = """
            INSERT INTO public.users (
                display_name, 
                email, 
                handle, 
                cognito_user_id
            ) 
            VALUES(%s, %s, %s, %s)
            ON CONFLICT (handle) 
            DO UPDATE SET 
                cognito_user_id = EXCLUDED.cognito_user_id,
                email = EXCLUDED.email;
        """
        
        params = [
            user_display_name,
            user_email,
            user_handle,
            user_cognito_id
        ]
        
        print(f"== Executing SQL for handle: {user_handle}")
        cur.execute(sql, params)
        conn.commit()
        print("== User successfully synced.")

    except (Exception, psycopg2.DatabaseError) as error:
        print("== Database Error:", error)
        # We purposely do NOT raise the error here so the user can still sign up
        # even if the DB sync fails (CloudWatch will alert us).
        
    finally:
        if conn is not None:
            cur.close()
            conn.close()
            print('== Database connection closed.')

    return event
