require 'roda'
require './models'
require 'bcrypt'
require 'json'

module MiniTwit

    class SimAPI < Roda

        latest = 0

        route do |r|
            r.get "latest" do
                return {'latest' => latest}.to_json
            end

            try_latest = r.params['latest'].to_s
            latest = try_latest.to_i if try_latest != ''
            
            r.post "register" do
                error = nil
                body = JSON.parse( r.body.read )
                username = body["username"]
                email = body["email"]
                password = body["pwd"]

                if username.nil?
                    error = "You have to enter a username"
                elsif email.nil? || !email.include?("@")
                    error = "You have to enter a valid email address"
                elsif password.nil?
                    error = "You have to enter a password"
                else
                    user = User.where(username: username).first
                    if user != nil
                        error = "The username is already taken"
                    else
                        User.new(
                            email: email,
                            username: username,
                            password: BCrypt::Password.create(password)
                        ).save_changes
                    end
                end

                if error != nil
                    response.status = 400
                    return error
                else   
                    response.status = 200
                    return ""
                end
            end

            #check if request originated from the simulator (does not work for the test)

            authorization_code = r.env["HTTP_AUTHORIZATION"]
            if authorization_code != "Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh"
                response.status = 403
                return "You are not authorized to use this resource!"
            end

            r.on "msgs" do
                r.is do 
                    r.get do
                        no_msgs = r.params["no"].to_s
                        no_msgs = no_msgs.empty? ? 100 : no_msgs.to_i #forgive me
                        msgs = DB.fetch("SELECT * FROM messages m inner join users u ON m.user_id = u.user_id WHERE m.flagged = 0 ORDER BY m.pub_date DESC LIMIT ?;", no_msgs)
                        filtered_msgs = []
                        msgs.each{|msg|
                            filtered_msg = {}
                            filtered_msg["content"] = msg[:text]
                            filtered_msg["pub_date"] = msg[:pub_date]
                            filtered_msg["user"] = msg[:username]
                            filtered_msgs.append(filtered_msg)
                        }
                        return filtered_msgs.to_json
                    end
                end 

                r.is String do |username|
                    user = User.where(username: username).first
                    r.get do
                        if user == nil
                            response.status = 400
                            return ""
                        end
                        no_msgs = r.params["no"].to_s
                        no_msgs = no_msgs.empty? ? 100 : no_msgs.to_i #forgive me
                        msgs = DB.fetch("SELECT * FROM messages m inner join users u ON m.user_id = u.user_id WHERE m.flagged = 0 AND u.user_id = ? ORDER BY m.pub_date DESC LIMIT ?;", user.user_id, no_msgs)
                        filtered_msgs = []
                        msgs.each{|msg|
                            filtered_msg = {}
                            filtered_msg["content"] = msg[:text]
                            filtered_msg["pub_date"] = msg[:pub_date]
                            filtered_msg["user"] = msg[:username]
                            filtered_msgs.append(filtered_msg)
                        }
                        return filtered_msgs.to_json

                    end
                    r.post do
                        text = JSON.parse(r.body.read)["content"]
                        Message.new(
                            text: text,
                            user_id: user.user_id,
                            pub_date: Time.now.to_i,
                            flagged: false
                          ).save_changes
                          response.status = 200
                          return ""
                    end
                end
            end

            r.on "fllws" do
                r.is String do |username|
                    user = User.where(username: username).first
                    if user == nil
                        response.status = 400
                        return ""
                    end

                    no_followers = r.params["no"].to_s
                    no_followers = no_followers.empty? ? 100 : no_followers.to_i #forgive me
                    
                    r.post do 
                        body = JSON.parse(r.body.read)
                        follow_username = body["follow"].to_s
                        if follow_username != ''
                            follow_user = User.where(username: follow_username).first
                            if follow_user == nil
                                response.status = 400
                                return "follow user " + follow_username + " does not exist"
                            end
                            Follower.new(
                                whom_id: follow_user.user_id,
                                who_id: user.user_id
                            ).save_changes
                            response.status = 200
                            return ""
                        end

                        unfollow_username = body["unfollow"].to_s
                        if unfollow_username != ''
                            unfollow_user = User.where(username: unfollow_username).first
                            if unfollow_user == nil
                                response.status = 400
                                return "unfollow user " + unfollow_username + " does not exist"
                            end
                        end
                        Follower.where(
                            whom_id: unfollow_user.user_id,
                            who_id: user.user_id
                          ).delete
                          response.status = 200
                          return ""
                    end

                    r.get do
                        followers = DB.fetch("SELECT users.username FROM users
                            INNER JOIN followers ON followers.whom_id = users.user_id
                            WHERE followers.who_id=?
                            LIMIT ?", user.user_id, no_followers)

                        follower_names = []
                        followers.each{|follower|
                            follower_names.append(follower[:username])
                        }

                        return {"follows" => follower_names}.to_json
                    end
                end
            end
        end
    end
end
