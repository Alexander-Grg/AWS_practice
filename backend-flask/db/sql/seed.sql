-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Alex Grg', 'a.a.grigoryev@icloud.com' , 'alexgrg','MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'alexgrg' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  );