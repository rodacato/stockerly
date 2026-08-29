class PushSubscriptionsController < AuthenticatedController
  def create
    case Notifications::UseCases::SubscribeToPush.call(user: current_user, params: subscription_params)
    in Dry::Monads::Success then head :created
    in Dry::Monads::Failure[ :validation, _errors ] then head :unprocessable_content
    end
  end

  def destroy
    Notifications::UseCases::UnsubscribeFromPush.call(user: current_user, endpoint: params.require(:endpoint))
    head :no_content
  end

  private

  def subscription_params
    params.expect(push_subscription: [ :endpoint, :p256dh_key, :auth_key ]).to_h.symbolize_keys
  end
end
