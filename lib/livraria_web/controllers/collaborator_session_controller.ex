defmodule LivrariaWeb.CollaboratorSessionController do
  use LivrariaWeb, :controller

  alias Livraria.Administration
  alias LivrariaWeb.CollaboratorAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:collaborator_return_to, ~p"/collaborators/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"collaborator" => collaborator_params}, info) do
    %{"email" => email, "password" => password} = collaborator_params

    if collaborator = Administration.get_collaborator_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> CollaboratorAuth.log_in_collaborator(collaborator, collaborator_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/collaborators/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> CollaboratorAuth.log_out_collaborator()
  end
end
