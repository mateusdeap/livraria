defmodule LivrariaWeb.CollaboratorSettingsLiveTest do
  use LivrariaWeb.ConnCase

  alias Livraria.Administration
  import Phoenix.LiveViewTest
  import Livraria.AdministrationFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_collaborator(collaborator_fixture())
        |> live(~p"/collaborators/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if collaborator is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/collaborators/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/collaborators/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_collaborator_password()
      collaborator = collaborator_fixture(%{password: password})
      %{conn: log_in_collaborator(conn, collaborator), collaborator: collaborator, password: password}
    end

    test "updates the collaborator email", %{conn: conn, password: password, collaborator: collaborator} do
      new_email = unique_collaborator_email()

      {:ok, lv, _html} = live(conn, ~p"/collaborators/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "collaborator" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Administration.get_collaborator_by_email(collaborator.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/collaborators/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "collaborator" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, collaborator: collaborator} do
      {:ok, lv, _html} = live(conn, ~p"/collaborators/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "collaborator" => %{"email" => collaborator.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_collaborator_password()
      collaborator = collaborator_fixture(%{password: password})
      %{conn: log_in_collaborator(conn, collaborator), collaborator: collaborator, password: password}
    end

    test "updates the collaborator password", %{conn: conn, collaborator: collaborator, password: password} do
      new_password = valid_collaborator_password()

      {:ok, lv, _html} = live(conn, ~p"/collaborators/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "collaborator" => %{
            "email" => collaborator.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/collaborators/settings"

      assert get_session(new_password_conn, :collaborator_token) != get_session(conn, :collaborator_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Administration.get_collaborator_by_email_and_password(collaborator.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/collaborators/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "collaborator" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/collaborators/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "collaborator" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      collaborator = collaborator_fixture()
      email = unique_collaborator_email()

      token =
        extract_collaborator_token(fn url ->
          Administration.deliver_collaborator_update_email_instructions(%{collaborator | email: email}, collaborator.email, url)
        end)

      %{conn: log_in_collaborator(conn, collaborator), token: token, email: email, collaborator: collaborator}
    end

    test "updates the collaborator email once", %{conn: conn, collaborator: collaborator, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/collaborators/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/collaborators/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Administration.get_collaborator_by_email(collaborator.email)
      assert Administration.get_collaborator_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/collaborators/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/collaborators/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, collaborator: collaborator} do
      {:error, redirect} = live(conn, ~p"/collaborators/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/collaborators/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Administration.get_collaborator_by_email(collaborator.email)
    end

    test "redirects if collaborator is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/collaborators/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/collaborators/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
