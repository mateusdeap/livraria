defmodule LivrariaWeb.CollaboratorSessionControllerTest do
  use LivrariaWeb.ConnCase, async: true

  import Livraria.AdministrationFixtures

  setup do
    %{collaborator: collaborator_fixture()}
  end

  describe "POST /collaborators/log_in" do
    test "logs the collaborator in", %{conn: conn, collaborator: collaborator} do
      conn =
        post(conn, ~p"/collaborators/log_in", %{
          "collaborator" => %{"email" => collaborator.email, "password" => valid_collaborator_password()}
        })

      assert get_session(conn, :collaborator_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ collaborator.email
      assert response =~ ~p"/collaborators/settings"
      assert response =~ ~p"/collaborators/log_out"
    end

    test "logs the collaborator in with remember me", %{conn: conn, collaborator: collaborator} do
      conn =
        post(conn, ~p"/collaborators/log_in", %{
          "collaborator" => %{
            "email" => collaborator.email,
            "password" => valid_collaborator_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_livraria_web_collaborator_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the collaborator in with return to", %{conn: conn, collaborator: collaborator} do
      conn =
        conn
        |> init_test_session(collaborator_return_to: "/foo/bar")
        |> post(~p"/collaborators/log_in", %{
          "collaborator" => %{
            "email" => collaborator.email,
            "password" => valid_collaborator_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, collaborator: collaborator} do
      conn =
        conn
        |> post(~p"/collaborators/log_in", %{
          "_action" => "registered",
          "collaborator" => %{
            "email" => collaborator.email,
            "password" => valid_collaborator_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, collaborator: collaborator} do
      conn =
        conn
        |> post(~p"/collaborators/log_in", %{
          "_action" => "password_updated",
          "collaborator" => %{
            "email" => collaborator.email,
            "password" => valid_collaborator_password()
          }
        })

      assert redirected_to(conn) == ~p"/collaborators/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/collaborators/log_in", %{
          "collaborator" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/collaborators/log_in"
    end
  end

  describe "DELETE /collaborators/log_out" do
    test "logs the collaborator out", %{conn: conn, collaborator: collaborator} do
      conn = conn |> log_in_collaborator(collaborator) |> delete(~p"/collaborators/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :collaborator_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the collaborator is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/collaborators/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :collaborator_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
