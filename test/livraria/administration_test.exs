defmodule Livraria.AdministrationTest do
  use Livraria.DataCase

  alias Livraria.Administration

  import Livraria.AdministrationFixtures
  alias Livraria.Administration.{Collaborator, CollaboratorToken}

  describe "get_collaborator_by_email/1" do
    test "does not return the collaborator if the email does not exist" do
      refute Administration.get_collaborator_by_email("unknown@example.com")
    end

    test "returns the collaborator if the email exists" do
      %{id: id} = collaborator = collaborator_fixture()
      assert %Collaborator{id: ^id} = Administration.get_collaborator_by_email(collaborator.email)
    end
  end

  describe "get_collaborator_by_email_and_password/2" do
    test "does not return the collaborator if the email does not exist" do
      refute Administration.get_collaborator_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the collaborator if the password is not valid" do
      collaborator = collaborator_fixture()
      refute Administration.get_collaborator_by_email_and_password(collaborator.email, "invalid")
    end

    test "returns the collaborator if the email and password are valid" do
      %{id: id} = collaborator = collaborator_fixture()

      assert %Collaborator{id: ^id} =
               Administration.get_collaborator_by_email_and_password(collaborator.email, valid_collaborator_password())
    end
  end

  describe "get_collaborator!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Administration.get_collaborator!(-1)
      end
    end

    test "returns the collaborator with the given id" do
      %{id: id} = collaborator = collaborator_fixture()
      assert %Collaborator{id: ^id} = Administration.get_collaborator!(collaborator.id)
    end
  end

  describe "register_collaborator/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Administration.register_collaborator(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Administration.register_collaborator(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Administration.register_collaborator(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = collaborator_fixture()
      {:error, changeset} = Administration.register_collaborator(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Administration.register_collaborator(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers collaborators with a hashed password" do
      email = unique_collaborator_email()
      {:ok, collaborator} = Administration.register_collaborator(valid_collaborator_attributes(email: email))
      assert collaborator.email == email
      assert is_binary(collaborator.hashed_password)
      assert is_nil(collaborator.confirmed_at)
      assert is_nil(collaborator.password)
    end
  end

  describe "change_collaborator_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Administration.change_collaborator_registration(%Collaborator{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_collaborator_email()
      password = valid_collaborator_password()

      changeset =
        Administration.change_collaborator_registration(
          %Collaborator{},
          valid_collaborator_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_collaborator_email/2" do
    test "returns a collaborator changeset" do
      assert %Ecto.Changeset{} = changeset = Administration.change_collaborator_email(%Collaborator{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_collaborator_email/3" do
    setup do
      %{collaborator: collaborator_fixture()}
    end

    test "requires email to change", %{collaborator: collaborator} do
      {:error, changeset} = Administration.apply_collaborator_email(collaborator, valid_collaborator_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{collaborator: collaborator} do
      {:error, changeset} =
        Administration.apply_collaborator_email(collaborator, valid_collaborator_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{collaborator: collaborator} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Administration.apply_collaborator_email(collaborator, valid_collaborator_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{collaborator: collaborator} do
      %{email: email} = collaborator_fixture()
      password = valid_collaborator_password()

      {:error, changeset} = Administration.apply_collaborator_email(collaborator, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{collaborator: collaborator} do
      {:error, changeset} =
        Administration.apply_collaborator_email(collaborator, "invalid", %{email: unique_collaborator_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{collaborator: collaborator} do
      email = unique_collaborator_email()
      {:ok, collaborator} = Administration.apply_collaborator_email(collaborator, valid_collaborator_password(), %{email: email})
      assert collaborator.email == email
      assert Administration.get_collaborator!(collaborator.id).email != email
    end
  end

  describe "deliver_collaborator_update_email_instructions/3" do
    setup do
      %{collaborator: collaborator_fixture()}
    end

    test "sends token through notification", %{collaborator: collaborator} do
      token =
        extract_collaborator_token(fn url ->
          Administration.deliver_collaborator_update_email_instructions(collaborator, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert collaborator_token = Repo.get_by(CollaboratorToken, token: :crypto.hash(:sha256, token))
      assert collaborator_token.collaborator_id == collaborator.id
      assert collaborator_token.sent_to == collaborator.email
      assert collaborator_token.context == "change:current@example.com"
    end
  end

  describe "update_collaborator_email/2" do
    setup do
      collaborator = collaborator_fixture()
      email = unique_collaborator_email()

      token =
        extract_collaborator_token(fn url ->
          Administration.deliver_collaborator_update_email_instructions(%{collaborator | email: email}, collaborator.email, url)
        end)

      %{collaborator: collaborator, token: token, email: email}
    end

    test "updates the email with a valid token", %{collaborator: collaborator, token: token, email: email} do
      assert Administration.update_collaborator_email(collaborator, token) == :ok
      changed_collaborator = Repo.get!(Collaborator, collaborator.id)
      assert changed_collaborator.email != collaborator.email
      assert changed_collaborator.email == email
      assert changed_collaborator.confirmed_at
      assert changed_collaborator.confirmed_at != collaborator.confirmed_at
      refute Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end

    test "does not update email with invalid token", %{collaborator: collaborator} do
      assert Administration.update_collaborator_email(collaborator, "oops") == :error
      assert Repo.get!(Collaborator, collaborator.id).email == collaborator.email
      assert Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end

    test "does not update email if collaborator email changed", %{collaborator: collaborator, token: token} do
      assert Administration.update_collaborator_email(%{collaborator | email: "current@example.com"}, token) == :error
      assert Repo.get!(Collaborator, collaborator.id).email == collaborator.email
      assert Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end

    test "does not update email if token expired", %{collaborator: collaborator, token: token} do
      {1, nil} = Repo.update_all(CollaboratorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Administration.update_collaborator_email(collaborator, token) == :error
      assert Repo.get!(Collaborator, collaborator.id).email == collaborator.email
      assert Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end
  end

  describe "change_collaborator_password/2" do
    test "returns a collaborator changeset" do
      assert %Ecto.Changeset{} = changeset = Administration.change_collaborator_password(%Collaborator{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Administration.change_collaborator_password(%Collaborator{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_collaborator_password/3" do
    setup do
      %{collaborator: collaborator_fixture()}
    end

    test "validates password", %{collaborator: collaborator} do
      {:error, changeset} =
        Administration.update_collaborator_password(collaborator, valid_collaborator_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{collaborator: collaborator} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Administration.update_collaborator_password(collaborator, valid_collaborator_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{collaborator: collaborator} do
      {:error, changeset} =
        Administration.update_collaborator_password(collaborator, "invalid", %{password: valid_collaborator_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{collaborator: collaborator} do
      {:ok, collaborator} =
        Administration.update_collaborator_password(collaborator, valid_collaborator_password(), %{
          password: "new valid password"
        })

      assert is_nil(collaborator.password)
      assert Administration.get_collaborator_by_email_and_password(collaborator.email, "new valid password")
    end

    test "deletes all tokens for the given collaborator", %{collaborator: collaborator} do
      _ = Administration.generate_collaborator_session_token(collaborator)

      {:ok, _} =
        Administration.update_collaborator_password(collaborator, valid_collaborator_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end
  end

  describe "generate_collaborator_session_token/1" do
    setup do
      %{collaborator: collaborator_fixture()}
    end

    test "generates a token", %{collaborator: collaborator} do
      token = Administration.generate_collaborator_session_token(collaborator)
      assert collaborator_token = Repo.get_by(CollaboratorToken, token: token)
      assert collaborator_token.context == "session"

      # Creating the same token for another collaborator should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%CollaboratorToken{
          token: collaborator_token.token,
          collaborator_id: collaborator_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_collaborator_by_session_token/1" do
    setup do
      collaborator = collaborator_fixture()
      token = Administration.generate_collaborator_session_token(collaborator)
      %{collaborator: collaborator, token: token}
    end

    test "returns collaborator by token", %{collaborator: collaborator, token: token} do
      assert session_collaborator = Administration.get_collaborator_by_session_token(token)
      assert session_collaborator.id == collaborator.id
    end

    test "does not return collaborator for invalid token" do
      refute Administration.get_collaborator_by_session_token("oops")
    end

    test "does not return collaborator for expired token", %{token: token} do
      {1, nil} = Repo.update_all(CollaboratorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Administration.get_collaborator_by_session_token(token)
    end
  end

  describe "delete_collaborator_session_token/1" do
    test "deletes the token" do
      collaborator = collaborator_fixture()
      token = Administration.generate_collaborator_session_token(collaborator)
      assert Administration.delete_collaborator_session_token(token) == :ok
      refute Administration.get_collaborator_by_session_token(token)
    end
  end

  describe "deliver_collaborator_confirmation_instructions/2" do
    setup do
      %{collaborator: collaborator_fixture()}
    end

    test "sends token through notification", %{collaborator: collaborator} do
      token =
        extract_collaborator_token(fn url ->
          Administration.deliver_collaborator_confirmation_instructions(collaborator, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert collaborator_token = Repo.get_by(CollaboratorToken, token: :crypto.hash(:sha256, token))
      assert collaborator_token.collaborator_id == collaborator.id
      assert collaborator_token.sent_to == collaborator.email
      assert collaborator_token.context == "confirm"
    end
  end

  describe "confirm_collaborator/1" do
    setup do
      collaborator = collaborator_fixture()

      token =
        extract_collaborator_token(fn url ->
          Administration.deliver_collaborator_confirmation_instructions(collaborator, url)
        end)

      %{collaborator: collaborator, token: token}
    end

    test "confirms the email with a valid token", %{collaborator: collaborator, token: token} do
      assert {:ok, confirmed_collaborator} = Administration.confirm_collaborator(token)
      assert confirmed_collaborator.confirmed_at
      assert confirmed_collaborator.confirmed_at != collaborator.confirmed_at
      assert Repo.get!(Collaborator, collaborator.id).confirmed_at
      refute Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end

    test "does not confirm with invalid token", %{collaborator: collaborator} do
      assert Administration.confirm_collaborator("oops") == :error
      refute Repo.get!(Collaborator, collaborator.id).confirmed_at
      assert Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end

    test "does not confirm email if token expired", %{collaborator: collaborator, token: token} do
      {1, nil} = Repo.update_all(CollaboratorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Administration.confirm_collaborator(token) == :error
      refute Repo.get!(Collaborator, collaborator.id).confirmed_at
      assert Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end
  end

  describe "deliver_collaborator_reset_password_instructions/2" do
    setup do
      %{collaborator: collaborator_fixture()}
    end

    test "sends token through notification", %{collaborator: collaborator} do
      token =
        extract_collaborator_token(fn url ->
          Administration.deliver_collaborator_reset_password_instructions(collaborator, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert collaborator_token = Repo.get_by(CollaboratorToken, token: :crypto.hash(:sha256, token))
      assert collaborator_token.collaborator_id == collaborator.id
      assert collaborator_token.sent_to == collaborator.email
      assert collaborator_token.context == "reset_password"
    end
  end

  describe "get_collaborator_by_reset_password_token/1" do
    setup do
      collaborator = collaborator_fixture()

      token =
        extract_collaborator_token(fn url ->
          Administration.deliver_collaborator_reset_password_instructions(collaborator, url)
        end)

      %{collaborator: collaborator, token: token}
    end

    test "returns the collaborator with valid token", %{collaborator: %{id: id}, token: token} do
      assert %Collaborator{id: ^id} = Administration.get_collaborator_by_reset_password_token(token)
      assert Repo.get_by(CollaboratorToken, collaborator_id: id)
    end

    test "does not return the collaborator with invalid token", %{collaborator: collaborator} do
      refute Administration.get_collaborator_by_reset_password_token("oops")
      assert Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end

    test "does not return the collaborator if token expired", %{collaborator: collaborator, token: token} do
      {1, nil} = Repo.update_all(CollaboratorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Administration.get_collaborator_by_reset_password_token(token)
      assert Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end
  end

  describe "reset_collaborator_password/2" do
    setup do
      %{collaborator: collaborator_fixture()}
    end

    test "validates password", %{collaborator: collaborator} do
      {:error, changeset} =
        Administration.reset_collaborator_password(collaborator, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{collaborator: collaborator} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Administration.reset_collaborator_password(collaborator, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{collaborator: collaborator} do
      {:ok, updated_collaborator} = Administration.reset_collaborator_password(collaborator, %{password: "new valid password"})
      assert is_nil(updated_collaborator.password)
      assert Administration.get_collaborator_by_email_and_password(collaborator.email, "new valid password")
    end

    test "deletes all tokens for the given collaborator", %{collaborator: collaborator} do
      _ = Administration.generate_collaborator_session_token(collaborator)
      {:ok, _} = Administration.reset_collaborator_password(collaborator, %{password: "new valid password"})
      refute Repo.get_by(CollaboratorToken, collaborator_id: collaborator.id)
    end
  end

  describe "inspect/2 for the Collaborator module" do
    test "does not include password" do
      refute inspect(%Collaborator{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
