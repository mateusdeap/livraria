defmodule Livraria.AdministrationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Livraria.Administration` context.
  """

  def unique_collaborator_email, do: "collaborator#{System.unique_integer()}@example.com"
  def valid_collaborator_password, do: "hello world!"

  def valid_collaborator_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_collaborator_email(),
      password: valid_collaborator_password()
    })
  end

  def collaborator_fixture(attrs \\ %{}) do
    {:ok, collaborator} =
      attrs
      |> valid_collaborator_attributes()
      |> Livraria.Administration.register_collaborator()

    collaborator
  end

  def extract_collaborator_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
