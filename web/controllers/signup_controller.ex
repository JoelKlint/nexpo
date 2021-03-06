defmodule Nexpo.SignupController do
  use Nexpo.Web, :controller

  alias Nexpo.Repo
  alias Nexpo.User
  alias Nexpo.Email
  alias Nexpo.Mailer
  alias Nexpo.ErrorView
  alias Nexpo.ChangesetView
  alias Nexpo.UserView

  @apidoc """
  @api {POST} /initial_signup Initiate sign up
  @apiGroup Sign up

  @apiParam {String} username Prefix of email on global domain

  @apiSuccessExample {json} Success
    HTTP 201 Created
    {
      "data": {
        "id": 1,
        "email": "username@student.lu.se"
        "first_name": null,
        "last_name": null,
      }
    }

  @apiUse BadRequestError
  """
  def create(conn, %{"username" => username}) do
    case User.initial_signup(%{username: username}) do
      {:ok, user} ->
        Email.pre_signup_email(user) |> Mailer.deliver_later
        conn
        |> put_status(201)
        |> render(UserView, "show.json", %{user: user})
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  @apidoc """
  @api {GET} /initial_signup/:signup_key Get current signup
  @apiGroup Sign up

  @apiParam {String} signup_key Signup key of user

  @apiSuccessExample {json} Success
    HTTP 200 Created
    {
      "data": {
        "id": 1,
        "email": "username@student.lu.se"
        "first_name": "Benjamin",
        "last_name": "Franklin",
      }
    }

  @apiUse NotFoundError
  """
  def get_current_signup(conn, %{"key" => key}) do
    case Repo.get_by(User, signup_key: key) do
      nil ->
        conn
        |> put_status(404)
        |> render(ErrorView, "404.json")
      user ->
        conn
        |> put_status(200)
        |> render(UserView, "show.json", %{user: user})
    end
  end

  @apidoc """
  @api {POST} /final_signup/:signup_key Finish sign up
  @apiGroup Sign up

  @apiParam {String}  signup_key             Signup key of user
  @apiParam {String}  password               Wanted password
  @apiParam {String}  password_confirmation  Confirmation of password
  @apiParam {String}  first_name             First name
  @apiParam {String}  last_name              Last name

  @apiSuccessExample {json} Success
    HTTP 200 Created
    {
      "data": {
        "id": 1,
        "email": "username@student.lu.se"
        "first_name": "Benjamin",
        "last_name": "Franklin",
      }
    }

  @apiUse NotFoundError
  @apiUse BadRequestError
  """
  def final_create(conn, params) do
    params = %{
      signup_key: params["signup_key"],
      password: params["password"],
      password_confirmation: params["password_confirmation"],
      first_name: params["first_name"],
      last_name: params["last_name"]
    }
    case User.final_signup(params) do
      {:ok, user} ->
        Email.completed_sign_up_mail(user) |> Mailer.deliver_later
        conn
        |> put_status(200)
        |> render(UserView, "show.json", %{user: user})
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(ChangesetView, "error.json", changeset: changeset)
      :no_such_user ->
        conn
        |> put_status(404)
        |> render(ErrorView, "404.json")
    end
  end

end
