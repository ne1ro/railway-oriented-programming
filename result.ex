with {:ok, _} <- validate_email(email),
     {:ok, _} <- validate_name(name),
     user <- %User{name: name, email: email},
     {:ok, _} <- UsersRepo.save(user)
     {:ok, notification} <- Notifier.send_notification(user) do
  {user, notification}
end
