defmodule LivrariaWeb.CollaboratorAuthTest do
  use LivrariaWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Livraria.Administration
  alias LivrariaWeb.CollaboratorAuth
  import Livraria.AdministrationFixtures

  @remember_me_cookie "_livraria_web_collaborator_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, LivrariaWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{collaborator: collaborator_fixture(), conn: conn}
  end

  describe "log_in_collaborator/3" do
    test "stores the collaborator token in the session", %{conn: conn, collaborator: collaborator} do
      conn = CollaboratorAuth.log_in_collaborator(conn, collaborator)
      assert token = get_session(conn, :collaborator_token)
      assert get_session(conn, :live_socket_id) == "collaborators_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Administration.get_collaborator_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, collaborator: collaborator} do
      conn = conn |> put_session(:to_be_removed, "value") |> CollaboratorAuth.log_in_collaborator(collaborator)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, collaborator: collaborator} do
      conn = conn |> put_session(:collaborator_return_to, "/hello") |> CollaboratorAuth.log_in_collaborator(collaborator)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, collaborator: collaborator} do
      conn = conn |> fetch_cookies() |> CollaboratorAuth.log_in_collaborator(collaborator, %{"remember_me" => "true"})
      assert get_session(conn, :collaborator_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :collaborator_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_collaborator/1" do
    test "erases session and cookies", %{conn: conn, collaborator: collaborator} do
      collaborator_token = Administration.generate_collaborator_session_token(collaborator)

      conn =
        conn
        |> put_session(:collaborator_token, collaborator_token)
        |> put_req_cookie(@remember_me_cookie, collaborator_token)
        |> fetch_cookies()
        |> CollaboratorAuth.log_out_collaborator()

      refute get_session(conn, :collaborator_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Administration.get_collaborator_by_session_token(collaborator_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "collaborators_sessions:abcdef-token"
      LivrariaWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> CollaboratorAuth.log_out_collaborator()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if collaborator is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> CollaboratorAuth.log_out_collaborator()
      refute get_session(conn, :collaborator_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_collaborator/2" do
    test "authenticates collaborator from session", %{conn: conn, collaborator: collaborator} do
      collaborator_token = Administration.generate_collaborator_session_token(collaborator)
      conn = conn |> put_session(:collaborator_token, collaborator_token) |> CollaboratorAuth.fetch_current_collaborator([])
      assert conn.assigns.current_collaborator.id == collaborator.id
    end

    test "authenticates collaborator from cookies", %{conn: conn, collaborator: collaborator} do
      logged_in_conn =
        conn |> fetch_cookies() |> CollaboratorAuth.log_in_collaborator(collaborator, %{"remember_me" => "true"})

      collaborator_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> CollaboratorAuth.fetch_current_collaborator([])

      assert conn.assigns.current_collaborator.id == collaborator.id
      assert get_session(conn, :collaborator_token) == collaborator_token

      assert get_session(conn, :live_socket_id) ==
               "collaborators_sessions:#{Base.url_encode64(collaborator_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, collaborator: collaborator} do
      _ = Administration.generate_collaborator_session_token(collaborator)
      conn = CollaboratorAuth.fetch_current_collaborator(conn, [])
      refute get_session(conn, :collaborator_token)
      refute conn.assigns.current_collaborator
    end
  end

  describe "on_mount: mount_current_collaborator" do
    test "assigns current_collaborator based on a valid collaborator_token ", %{conn: conn, collaborator: collaborator} do
      collaborator_token = Administration.generate_collaborator_session_token(collaborator)
      session = conn |> put_session(:collaborator_token, collaborator_token) |> get_session()

      {:cont, updated_socket} =
        CollaboratorAuth.on_mount(:mount_current_collaborator, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_collaborator.id == collaborator.id
    end

    test "assigns nil to current_collaborator assign if there isn't a valid collaborator_token ", %{conn: conn} do
      collaborator_token = "invalid_token"
      session = conn |> put_session(:collaborator_token, collaborator_token) |> get_session()

      {:cont, updated_socket} =
        CollaboratorAuth.on_mount(:mount_current_collaborator, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_collaborator == nil
    end

    test "assigns nil to current_collaborator assign if there isn't a collaborator_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        CollaboratorAuth.on_mount(:mount_current_collaborator, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_collaborator == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_collaborator based on a valid collaborator_token ", %{conn: conn, collaborator: collaborator} do
      collaborator_token = Administration.generate_collaborator_session_token(collaborator)
      session = conn |> put_session(:collaborator_token, collaborator_token) |> get_session()

      {:cont, updated_socket} =
        CollaboratorAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_collaborator.id == collaborator.id
    end

    test "redirects to login page if there isn't a valid collaborator_token ", %{conn: conn} do
      collaborator_token = "invalid_token"
      session = conn |> put_session(:collaborator_token, collaborator_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: LivrariaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = CollaboratorAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_collaborator == nil
    end

    test "redirects to login page if there isn't a collaborator_token ", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: LivrariaWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = CollaboratorAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_collaborator == nil
    end
  end

  describe "on_mount: :redirect_if_collaborator_is_authenticated" do
    test "redirects if there is an authenticated  collaborator ", %{conn: conn, collaborator: collaborator} do
      collaborator_token = Administration.generate_collaborator_session_token(collaborator)
      session = conn |> put_session(:collaborator_token, collaborator_token) |> get_session()

      assert {:halt, _updated_socket} =
               CollaboratorAuth.on_mount(
                 :redirect_if_collaborator_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "Don't redirect is there is no authenticated collaborator", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               CollaboratorAuth.on_mount(
                 :redirect_if_collaborator_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_collaborator_is_authenticated/2" do
    test "redirects if collaborator is authenticated", %{conn: conn, collaborator: collaborator} do
      conn = conn |> assign(:current_collaborator, collaborator) |> CollaboratorAuth.redirect_if_collaborator_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if collaborator is not authenticated", %{conn: conn} do
      conn = CollaboratorAuth.redirect_if_collaborator_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_collaborator/2" do
    test "redirects if collaborator is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> CollaboratorAuth.require_authenticated_collaborator([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/collaborators/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> CollaboratorAuth.require_authenticated_collaborator([])

      assert halted_conn.halted
      assert get_session(halted_conn, :collaborator_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> CollaboratorAuth.require_authenticated_collaborator([])

      assert halted_conn.halted
      assert get_session(halted_conn, :collaborator_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> CollaboratorAuth.require_authenticated_collaborator([])

      assert halted_conn.halted
      refute get_session(halted_conn, :collaborator_return_to)
    end

    test "does not redirect if collaborator is authenticated", %{conn: conn, collaborator: collaborator} do
      conn = conn |> assign(:current_collaborator, collaborator) |> CollaboratorAuth.require_authenticated_collaborator([])
      refute conn.halted
      refute conn.status
    end
  end
end
