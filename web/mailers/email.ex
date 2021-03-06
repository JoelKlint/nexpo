defmodule Nexpo.Email do
  import Bamboo.Email
  use Bamboo.Phoenix, view: Nexpo.EmailView

  def pre_signup_email(user) do
    base_email()
    |> to(user.email)
    |> subject("Nexpo | Verify your email")
    |> render("pre_signup.html", user: user)
  end

  def completed_sign_up_mail(user) do
    base_email()
    |> to(user.email)
    |> subject("Nexpo | Welcome!")
    |> render("completed_signup.html", user: user)
  end

  defp base_email do
    new_email()
    |> from("nexpo@arkad.se")
    |> put_html_layout({Nexpo.LayoutView, "email.html"})
  end
end
