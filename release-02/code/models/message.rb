# frozen_string_literal: true

# rubocop:disable BlockLength
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

    def messages_by_user_id_and_followers(user_id)
      follower_ids = MiniTwit::DB[
        'SELECT * FROM followers WHERE who_id = ?', user_id
      ].all
      messages = Message
                 .where(user_id: user_id)
                 .order(Sequel.desc(:pub_date))
                 .limit(10)
                 .all
      follower_ids.each do |id|
        messages.push(Message
             .where(user_id: id[:whom_id])
             .order(Sequel.desc(:pub_date))
             .limit(10)
             .all)
      end
      messages.flatten!
    end
  end
end
# rubocop:enable BlockLength
