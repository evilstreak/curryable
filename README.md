Curryable
=========

## What is a command object?

An object (noun) that acts as a container for a function (verb).

## Design goals

* Objects should be immutable
* Object should act like a function
* Arguments to the object can be curried
* Objects should be inspectable. Inspection should reveal
  * the class
  * which arguments have been curried, and their values

```ruby
class SignUpUser
  def initialize(user_creator:, attributes:, email_api:, crm_api:)
    @user_creator = user_creator
    @attributes = attributes
    @email_api = email_api
    @crm_api = crm_api
  end

  attr_reader :user_creator, :attributes, :email_api, :crm_api
  private     :user_creator, :attributes, :email_api, :crm_api

  def call
    create_user_record
    send_confirmation_email
    add_user_to_crm
  end
end

signup_service = Curryable.new(SignUpUser).call(
  user_creator: User,
  email_api: EmailAPI.new(EMAIL_AUTH_TOKEN),
  crm_api: CRMAPI.new(CRM_AUTH_TOKEN),
)

signup_service.inspect
# => #<Curryable<SignUpUser>:0x839fa96b9467e0 user_creator:User, email_api:#<EmailAPI>, crm_api:#<CRMAPI>, attributes:>

signup_service.call(
  attributes: user_attrs,
)
```
