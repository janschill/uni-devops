# frozen_string_literal: true

# Message posted by users
class Message < Sequel::Model
  many_to_one :user

  dataset_module do
    def latest_messages
      Message
        .order(Sequel.desc(:pub_date))
        .limit(10)
        .all
    end

    def messages_by_user_id(user_id)
      Message
        .where(user_id: user_id)
        .order(Sequel.desc(:pub_date))
        .limit(10)
        .all
    end

    # TODO: Show tweets by follower
    def messages_by_user_id_and_followers(user_id)
      Message
        .where(user_id: user_id)
        .order(Sequel.desc(:pub_date))
        .limit(10)
        .all
    end
  end
end
