defmodule LivrariaWeb.CollaboratorConfirmationInstructionsLiveTest do
  use LivrariaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Livraria.AdministrationFixtures

  alias Livraria.Administration
  alias Livraria.Repo

  setup do
    %{collaborator: collaborator_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/collaborators/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, collaborator: collaborator} do
      {:ok, lv, _html} = live(conn, ~p"/collaborators/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", collaborator: %{email: collaborator.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Administration.CollaboratorToken, collaborator_id: collaborator.id).context == "confirm"
    end

    test "does not send confirmation token if collaborator is confirmed", %{conn: conn, collaborator: collaborator} do
      Repo.update!(Administration.Collaborator.confirm_changeset(collaborator))

      {:ok, lv, _html} = live(conn, ~p"/collaborators/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", collaborator: %{email: collaborator.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Administration.CollaboratorToken, collaborator_id: collaborator.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/collaborators/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", collaborator: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Administration.CollaboratorToken) == []
    end
  end
end
