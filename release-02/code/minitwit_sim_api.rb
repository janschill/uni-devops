require 'roda'
require './models'
require 'bcrypt'

module MiniTwit

    class SimAPI < Roda

        latest = 0

        route do |r|
            r.get "latest" do
                return {'latest' => latest}.to_json
            end

            update_latest(r)

            r.post "register" do
                @error = nil
                username = r.params["username"].to_s
                email = r.params["email"].to_s
                password = r.params["pwd"].to_s

                if username.empty?
                    error = "You have to enter a username"
                elsif email.empty? || !email.include?("@")
                    error = "You have to enter a valid email address"
                elsif password.empty?
                    error = "You have to enter a password"
                else
                    user = User.where(username: r.params['username']).first
                    if user != nil
                        error = "The username is already taken"
                    else
                        User.new(
                            email: email_address,
                            username: username,
                            password: BCrypt::Password.create(password)
                        ).save_changes
                    end
                end

                if error != nil
                    return {"status" => 400, "error_msg" => error}.to_json
                else   
                    return "", 204
                end

            end

            #check if req from simulator (how to inspect req headers?)

            r.on "msgs" do
                
                r.is do 
                    r.get do
                        no_msgs = r.params["no"].to_s
                        no_msgs = no_msgs.empty? ? 100 else no_msgs.to_i #forgive me
                        msgs = Message.join_table(:inner, :users, :user_id, :user_id)
                        msgs = msgs.where(:flagged = 0).order(Sequel.desc(:pub_date)).limit(no_msgs)
                        filtered_msgs = []
                        for msg in msgs
                            filtered_msg = {}
                            filtered_msg["content"] = msg.text
                            filtered_msg["pub_date"] = msg.pub_date
                            filtered_msg["user"] = msg.username
                            filtered_msgs.append(filtered_msg)
                        end
                        return filtered_msgs.to_json
                    end
                end 

                r.is ":username" do |username|
                    user = User.where(username: username).first
                    r.get do
                        if user == nil
                            return {"status" => 404}.to_json
                        end
                        no_msgs = r.params["no"].to_s
                        no_msgs = no_msgs.empty? ? 100 else no_msgs.to_i #forgive me
                        msgs = Message.join_table(:inner, :users, :user_id, :user_id)
                        msgs = msgs.where(:flagged = 0).and(:user_id = user.user_id).order(Sequel.desc(:pub_date)).limit(no_msgs)
                        filtered_msgs = []
                        for msg in msgs
                            filtered_msg = {}
                            filtered_msg["content"] = msg.text
                            filtered_msg["pub_date"] = msg.pub_date
                            filtered_msg["user"] = msg.username
                            filtered_msgs.append(filtered_msg)
                        end
                        return filtered_msgs.to_json

                    end
                    r.post do
                        text = r.params["content"]
                        Message.new(
                            text: text,
                            user_id: user.user_id,
                            pub_date: Time.now.to_i,
                            flagged: false
                          ).save_changes
                        return "", 204
                    end
                end

            end 
            
            
        end

    def update_latest(request):
        try_latest = request.params['text']
        latest = try_latest if try_latest.to_s == ''
    end
end