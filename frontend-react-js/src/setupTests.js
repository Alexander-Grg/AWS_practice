import '@testing-library/jest-dom';

process.env.AWS_ACCESS_KEY_ID = 'test-access-key';
process.env.AWS_SECRET_ACCESS_KEY = 'test-secret-key';
process.env.AWS_DEFAULT_REGION = 'us-east-1';

process.env.AWS_COGNITO_USER_POOL_ID = 'us-east-1_testPoolId';
process.env.AWS_COGNITO_USER_POOL_CLIENT_ID = 'test-client-id-12345';

process.env.REACT_APP_AWS_PROJECT_REGION = 'us-east-1';
process.env.REACT_APP_AWS_COGNITO_REGION = 'us-east-1';
process.env.REACT_APP_CLIENT_ID = 'test-client-id-12345';
process.env.REACT_APP_AWS_USER_POOLS_ID = 'us-east-1_testPoolId';
process.env.REACT_APP_BACKEND_URL = 'http://localhost:5000';

process.env.CONNECTION_STRING = 'postgresql://postgres:password@localhost:5432/test_db';
process.env.PROD_CONNECTION_STRING = 'postgresql://postgres:password@localhost:5432/prod_db';
process.env.PG_DATABASE = 'test_db';
process.env.PG_PASSWORD = 'test_password';

process.env.FRONTEND_URL = 'http://localhost:3000';
process.env.BACKEND_URL = 'http://localhost:5000';

process.env.AWS_COGNITO_USER_POOL_CLIENT_ID = 'test-client-id-12345';
process.env.AWS_COGNITO_USER_POOL_ID = 'us-east-1_testPoolId'; 
process.env.REACT_APP_BACKEND_URL = 'http://localhost:5000'; 

process.env.PG_DATABASE = 'test_db';
process.env.PG_PASSWORD = 'test_password';

process.env.NODE_ENV = 'test';
process.env.CI = 'true';