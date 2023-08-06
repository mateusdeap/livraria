defmodule LivrariaWeb.Router do
  use LivrariaWeb, :router

  import LivrariaWeb.CollaboratorAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LivrariaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_collaborator
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LivrariaWeb do
    pipe_through :browser

    live "/", ProductLive.Index, :index
  end

  scope "/", LivrariaWeb do
    pipe_through :browser

    live "/suppliers", SupplierLive.Index, :index
    live "/suppliers/new", SupplierLive.Index, :new
    live "/suppliers/:id/edit", SupplierLive.Index, :edit

    live "/suppliers/:id", SupplierLive.Show, :show
    live "/suppliers/:id/show/edit", SupplierLive.Show, :edit
  end

  scope "/", LivrariaWeb do
    pipe_through :browser

    live "/products", ProductLive.Index, :index
    live "/products/new", ProductLive.Index, :new
    live "/products/:id/edit", ProductLive.Index, :edit

    live "/products/:id", ProductLive.Show, :show
    live "/products/:id/show/edit", ProductLive.Show, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", LivrariaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:livraria, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LivrariaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LivrariaWeb do
    pipe_through [:browser, :redirect_if_collaborator_is_authenticated]

    live_session :redirect_if_collaborator_is_authenticated,
      on_mount: [{LivrariaWeb.CollaboratorAuth, :redirect_if_collaborator_is_authenticated}] do
      live "/collaborators/register", CollaboratorRegistrationLive, :new
      live "/collaborators/log_in", CollaboratorLoginLive, :new
      live "/collaborators/reset_password", CollaboratorForgotPasswordLive, :new
      live "/collaborators/reset_password/:token", CollaboratorResetPasswordLive, :edit
    end

    post "/collaborators/log_in", CollaboratorSessionController, :create
  end

  scope "/", LivrariaWeb do
    pipe_through [:browser, :require_authenticated_collaborator]

    live_session :require_authenticated_collaborator,
      on_mount: [{LivrariaWeb.CollaboratorAuth, :ensure_authenticated}] do
      live "/collaborators/settings", CollaboratorSettingsLive, :edit
      live "/collaborators/settings/confirm_email/:token", CollaboratorSettingsLive, :confirm_email
    end
  end

  scope "/", LivrariaWeb do
    pipe_through [:browser]

    delete "/collaborators/log_out", CollaboratorSessionController, :delete

    live_session :current_collaborator,
      on_mount: [{LivrariaWeb.CollaboratorAuth, :mount_current_collaborator}] do
      live "/collaborators/confirm/:token", CollaboratorConfirmationLive, :edit
      live "/collaborators/confirm", CollaboratorConfirmationInstructionsLive, :new
    end
  end
end
