defmodule LivrariaWeb.CollaboratorConfirmationLiveTest do
  use LivrariaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Livraria.AdministrationFixtures

  alias Livraria.Administration
  alias Livraria.Repo

  setup do
    %{collaborator: collaborator_fixture()}
  end

  describe "Confirm collaborator" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/collaborators/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, collaborator: collaborator} do
      token =
        extract_collaborator_token(fn url ->
          Administration.deliver_collaborator_confirmation_instructions(collaborator, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/collaborators/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Collaborator confirmed successfully"

      assert Administration.get_collaborator!(collaborator.id).confirmed_at
      refute get_session(conn, :collaborator_token)
      assert Repo.all(Administration.CollaboratorToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/collaborators/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Collaborator confirmation link is invalid or it has expired"

      # when logged in
      {:ok, lv, _html} =
        build_conn()
        |> log_in_collaborator(collaborator)
        |> live(~p"/collaborators/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, collaborator: collaborator} do
      {:ok, lv, _html} = live(conn, ~p"/collaborators/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Collaborator confirmation link is invalid or it has expired"

      refute Administration.get_collaborator!(collaborator.id).confirmed_at
    end
  end
end
