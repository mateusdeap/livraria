defmodule Livraria.Administration do
  @moduledoc """
  The Administration context.
  """

  import Ecto.Query, warn: false
  alias Livraria.Repo

  alias Livraria.Administration.{Collaborator, CollaboratorToken, CollaboratorNotifier}

  ## Database getters

  @doc """
  Gets a collaborator by email.

  ## Examples

      iex> get_collaborator_by_email("foo@example.com")
      %Collaborator{}

      iex> get_collaborator_by_email("unknown@example.com")
      nil

  """
  def get_collaborator_by_email(email) when is_binary(email) do
    Repo.get_by(Collaborator, email: email)
  end

  @doc """
  Gets a collaborator by email and password.

  ## Examples

      iex> get_collaborator_by_email_and_password("foo@example.com", "correct_password")
      %Collaborator{}

      iex> get_collaborator_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_collaborator_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    collaborator = Repo.get_by(Collaborator, email: email)
    if Collaborator.valid_password?(collaborator, password), do: collaborator
  end

  @doc """
  Gets a single collaborator.

  Raises `Ecto.NoResultsError` if the Collaborator does not exist.

  ## Examples

      iex> get_collaborator!(123)
      %Collaborator{}

      iex> get_collaborator!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collaborator!(id), do: Repo.get!(Collaborator, id)

  ## Collaborator registration

  @doc """
  Registers a collaborator.

  ## Examples

      iex> register_collaborator(%{field: value})
      {:ok, %Collaborator{}}

      iex> register_collaborator(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_collaborator(attrs) do
    %Collaborator{}
    |> Collaborator.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collaborator changes.

  ## Examples

      iex> change_collaborator_registration(collaborator)
      %Ecto.Changeset{data: %Collaborator{}}

  """
  def change_collaborator_registration(%Collaborator{} = collaborator, attrs \\ %{}) do
    Collaborator.registration_changeset(collaborator, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the collaborator email.

  ## Examples

      iex> change_collaborator_email(collaborator)
      %Ecto.Changeset{data: %Collaborator{}}

  """
  def change_collaborator_email(collaborator, attrs \\ %{}) do
    Collaborator.email_changeset(collaborator, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_collaborator_email(collaborator, "valid password", %{email: ...})
      {:ok, %Collaborator{}}

      iex> apply_collaborator_email(collaborator, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_collaborator_email(collaborator, password, attrs) do
    collaborator
    |> Collaborator.email_changeset(attrs)
    |> Collaborator.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the collaborator email using the given token.

  If the token matches, the collaborator email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_collaborator_email(collaborator, token) do
    context = "change:#{collaborator.email}"

    with {:ok, query} <- CollaboratorToken.verify_change_email_token_query(token, context),
         %CollaboratorToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(collaborator_email_multi(collaborator, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp collaborator_email_multi(collaborator, email, context) do
    changeset =
      collaborator
      |> Collaborator.email_changeset(%{email: email})
      |> Collaborator.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:collaborator, changeset)
    |> Ecto.Multi.delete_all(:tokens, CollaboratorToken.collaborator_and_contexts_query(collaborator, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given collaborator.

  ## Examples

      iex> deliver_collaborator_update_email_instructions(collaborator, current_email, &url(~p"/collaborators/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_collaborator_update_email_instructions(%Collaborator{} = collaborator, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, collaborator_token} = CollaboratorToken.build_email_token(collaborator, "change:#{current_email}")

    Repo.insert!(collaborator_token)
    CollaboratorNotifier.deliver_update_email_instructions(collaborator, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the collaborator password.

  ## Examples

      iex> change_collaborator_password(collaborator)
      %Ecto.Changeset{data: %Collaborator{}}

  """
  def change_collaborator_password(collaborator, attrs \\ %{}) do
    Collaborator.password_changeset(collaborator, attrs, hash_password: false)
  end

  @doc """
  Updates the collaborator password.

  ## Examples

      iex> update_collaborator_password(collaborator, "valid password", %{password: ...})
      {:ok, %Collaborator{}}

      iex> update_collaborator_password(collaborator, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_collaborator_password(collaborator, password, attrs) do
    changeset =
      collaborator
      |> Collaborator.password_changeset(attrs)
      |> Collaborator.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:collaborator, changeset)
    |> Ecto.Multi.delete_all(:tokens, CollaboratorToken.collaborator_and_contexts_query(collaborator, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{collaborator: collaborator}} -> {:ok, collaborator}
      {:error, :collaborator, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_collaborator_session_token(collaborator) do
    {token, collaborator_token} = CollaboratorToken.build_session_token(collaborator)
    Repo.insert!(collaborator_token)
    token
  end

  @doc """
  Gets the collaborator with the given signed token.
  """
  def get_collaborator_by_session_token(token) do
    {:ok, query} = CollaboratorToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_collaborator_session_token(token) do
    Repo.delete_all(CollaboratorToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given collaborator.

  ## Examples

      iex> deliver_collaborator_confirmation_instructions(collaborator, &url(~p"/collaborators/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_collaborator_confirmation_instructions(confirmed_collaborator, &url(~p"/collaborators/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_collaborator_confirmation_instructions(%Collaborator{} = collaborator, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if collaborator.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, collaborator_token} = CollaboratorToken.build_email_token(collaborator, "confirm")
      Repo.insert!(collaborator_token)
      CollaboratorNotifier.deliver_confirmation_instructions(collaborator, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a collaborator by the given token.

  If the token matches, the collaborator account is marked as confirmed
  and the token is deleted.
  """
  def confirm_collaborator(token) do
    with {:ok, query} <- CollaboratorToken.verify_email_token_query(token, "confirm"),
         %Collaborator{} = collaborator <- Repo.one(query),
         {:ok, %{collaborator: collaborator}} <- Repo.transaction(confirm_collaborator_multi(collaborator)) do
      {:ok, collaborator}
    else
      _ -> :error
    end
  end

  defp confirm_collaborator_multi(collaborator) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:collaborator, Collaborator.confirm_changeset(collaborator))
    |> Ecto.Multi.delete_all(:tokens, CollaboratorToken.collaborator_and_contexts_query(collaborator, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given collaborator.

  ## Examples

      iex> deliver_collaborator_reset_password_instructions(collaborator, &url(~p"/collaborators/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_collaborator_reset_password_instructions(%Collaborator{} = collaborator, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, collaborator_token} = CollaboratorToken.build_email_token(collaborator, "reset_password")
    Repo.insert!(collaborator_token)
    CollaboratorNotifier.deliver_reset_password_instructions(collaborator, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the collaborator by reset password token.

  ## Examples

      iex> get_collaborator_by_reset_password_token("validtoken")
      %Collaborator{}

      iex> get_collaborator_by_reset_password_token("invalidtoken")
      nil

  """
  def get_collaborator_by_reset_password_token(token) do
    with {:ok, query} <- CollaboratorToken.verify_email_token_query(token, "reset_password"),
         %Collaborator{} = collaborator <- Repo.one(query) do
      collaborator
    else
      _ -> nil
    end
  end

  @doc """
  Resets the collaborator password.

  ## Examples

      iex> reset_collaborator_password(collaborator, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Collaborator{}}

      iex> reset_collaborator_password(collaborator, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_collaborator_password(collaborator, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:collaborator, Collaborator.password_changeset(collaborator, attrs))
    |> Ecto.Multi.delete_all(:tokens, CollaboratorToken.collaborator_and_contexts_query(collaborator, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{collaborator: collaborator}} -> {:ok, collaborator}
      {:error, :collaborator, changeset, _} -> {:error, changeset}
    end
  end
end
