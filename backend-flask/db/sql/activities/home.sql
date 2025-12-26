SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  users.cognito_user_id,
  activities.message,
  activities.replies_count,
  activities.reposts_count,
  activities.likes_count,
  activities.reply_to_activity_uuid,
  activities.expires_at,
  activities.created_at
FROM public.activities
LEFT JOIN public.users ON users.uuid = activities.user_uuid
WHERE 
  (activities.expires_at > NOW() OR activities.expires_at IS NULL)
AND (%(cognito_user_id)s IS NULL OR users.cognito_user_id = %(cognito_user_id)s)
ORDER BY activities.created_at DESC