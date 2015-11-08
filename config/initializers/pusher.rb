if Rails.env.production?
  Pusher.encrypted = true
else
  Pusher.app_id = '152890'
  Pusher.key = 'f3e17c9d8c2041ad74e5'
  Pusher.secret = 'd87f960f5d6119888342'
end
