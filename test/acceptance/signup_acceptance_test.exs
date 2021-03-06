defmodule Nexpo.SignupAcceptanceTest do
  use Nexpo.ConnCase
  use Bamboo.Test

  alias Nexpo.Repo
  alias Nexpo.User

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "GET /initial_signup/:key returns a user given a valid key", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    user = User.initial_signup!(params)

    conn = get(conn, "/api/initial_signup/#{user.signup_key}")

    assert json_response(conn, 200)
    response = Poison.decode!(conn.resp_body)["data"]

    assert response["id"] == user.id
  end

  test "GET /initial_signup/:key returns 404 given an invalid key", %{conn: conn} do

    conn = get(conn, "/api/initial_signup/invalid key")

    assert json_response(conn, 404)
  end

  test "POST /initial_signup accepts usernames that are not already signed up", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    conn = post(conn, "/api/initial_signup", params)

    assert json_response(conn, 201)
  end

  test "POST /initial_signup lower cases email", %{conn: conn} do
    params = Factory.params_for(:initial_signup)

    incorrect_username = String.upcase(params.username)

    correct_username = params.username |> String.trim |> String.downcase
    email = correct_username <> User.global_email_domain()

    params = Map.put(params, :username, incorrect_username)

    conn = post(conn, "/api/initial_signup", params)

    assert json_response(conn, 201)

    user = Repo.get_by!(User, email: email)

    assert user != nil
    assert user.email == email
  end

  test "POST /initial_signup does not allow usernames with blankspace", %{conn: conn} do
    params = Factory.params_for(:initial_signup)

    incorrect_username = "  " <> params.username <> "  "

    correct_username = params.username |> String.trim |> String.downcase
    email = correct_username <> User.global_email_domain()

    params = Map.put(params, :username, incorrect_username)

    conn = post(conn, "/api/initial_signup", params)

    assert json_response(conn, 400)

    user = Repo.get_by(User, email: email)

    assert user == nil
  end

  test "POST /initial_signup rejects empty usernames", %{conn: conn} do
    params = Factory.params_for(:initial_signup, username: "")

    conn = post(conn, "/api/initial_signup", params)

    assert json_response(conn, 400)
  end

  test "POST /initial_signup rejects usernames that are already signed up", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    User.initial_signup!(params)

    conn = post(conn, "/api/initial_signup", params)

    assert json_response(conn, 400)
  end

  test "POST /initial_signup sends an email on success", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    conn = post(conn, "/api/initial_signup", params)

    assert json_response(conn, 201)

    email = User.convert_username_to_email(params.username)
    user = Repo.get_by!(User, email: email)

    assert_delivered_email Nexpo.Email.pre_signup_email(user)
  end

  test "POST /final_signup/:key fails given no passwords", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    user = User.initial_signup!(params)

    params = Factory.params_for(:final_signup) |> Map.drop([:password, :password_confirmation])

    conn = post(conn, "/api/final_signup/#{user.signup_key}", params)

    assert json_response(conn, 400)
  end

  test "POST /final_signup/:key fails given no to short password", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    user = User.initial_signup!(params)

    params = Factory.params_for(:final_signup)
    |> Map.put(:password, "short")
    |> Map.put(:password_confirmation, "short")

    conn = post(conn, "/api/final_signup/#{user.signup_key}", params)

    assert json_response(conn, 400)
  end

  test "POST /final_signup/:key fails given non-matching passwords", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    user = User.initial_signup!(params)

    params = Factory.params_for(:final_signup)
    params = Map.put(params, :password_confirmation, params.password <> "invalid")

    conn = post(conn, "/api/final_signup/#{user.signup_key}", params)

    assert json_response(conn, 400)
  end

  test "POST /final_signup/:key fails given invalid signup_key", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    user = User.initial_signup!(params)

    params = Factory.params_for(:final_signup)

    conn = post(conn, "/api/final_signup/#{user.signup_key}invalid", params)

    assert json_response(conn, 404)
  end

  test "POST /final_signup/:key returns user on success and sends an email", %{conn: conn} do
    params = Factory.params_for(:initial_signup)
    user = User.initial_signup!(params)

    params = Factory.params_for(:final_signup)

    conn = post(conn, "/api/final_signup/#{user.signup_key}", params)

    assert json_response(conn, 200)
    response = Poison.decode!(conn.resp_body)["data"]

    user = Repo.get!(User, user.id)

    # Assert id and email in response
    assert response["id"] != nil
    assert response["email"] != nil

    # Assert correct data in response
    assert response["id"] == user.id
    assert response["email"] == user.email
    assert response["first_name"] == params.first_name
    assert response["last_name"] == params.last_name

    # Assert sign_up key has been destroyed
    assert user.signup_key == nil

    assert_delivered_email Nexpo.Email.completed_sign_up_mail(user)
  end

end
