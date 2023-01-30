class User < ApplicationRecord
    has_many :microposts, dependent: :destroy
    has_many :active_relationships, class_name: "Relationship",
                                    foreign_key: "follower_id",
                                    dependent: :destroy
    has_many :passive_relationships, class_name: "Relationship",
                                    foreign_key: "followed_id",
                                    dependent: :destroy
    has_many :following, through: :active_relationships, source: :followed
    has_many :followers, through: :passive_relationships, source: :follower
    attr_accessor   :remember_token, :activation_token
    before_save     :downcase_email
    before_create   :create_activation_digest

    # Validate :name attribute
    validates :name, presence: true, length: { maximum: 50}

    # VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    
    # Disallowing double dots in email domain names
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    
    # Validate :email atrribute
    validates :email, presence: true, length: { maximum: 255},
                      format: { with: VALID_EMAIL_REGEX },
                      uniqueness: true

    # Validate password is secure with bcrypt
    has_secure_password
    # Validate password and confirmation
    validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

    # When password confirmation field is blank, the error messsage is no displayed and the field outline color is not red.
    # validates_presence_of :password_confirmation, message: "can't be blank"

     # ------------------------------ Writing Style 1 ------------------------------
    
    # Returns the hash digest of the given string.
    def User.digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
    end
    # Returns a random token.
    def User.new_token
        SecureRandom.urlsafe_base64
    end
    
    # ------------------------------ Writing Style 2 ------------------------------
    
    # # Returns the hash digest of the given string.
    # def self.digest(string)
    #     cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    #     BCrypt::Password.create(string, cost: cost)
    # end
    # # Returns a random token.
    # def self.new_token
    #     SecureRandom.urlsafe_base64
    # end
    
    # ------------------------------ Writing Style 3 ------------------------------
    
    # class << self
    #     # Returns the hash digest of the given string.
    #     def digest(string)
    #         cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    #         BCrypt::Password.create(string, cost: cost)
    #     end
    #     # Returns a random token.
    #     def new_token
    #         SecureRandom.urlsafe_base64
    #     end
    # end

    # Remembers a user in the database for use in persistent sessions.
    def remember
        self.remember_token = User.new_token
        update_attribute(:remember_digest, User.digest(remember_token))
        remember_digest
    end

    # Returns a session token to prevent session hijacking.
    # We reuse the remember digest for convenience.
    def session_token
        remember_digest || remember
    end

    # Returns true if the given token matches the digest.
    # def authenticated?(remember_token)
    #     return false if remember_digest.nil?
    #     BCrypt::Password.new(remember_digest).is_password?(remember_token)
    #     # Or mybe also can written like this
    #     # remember_digest.nil? ? false : BCrypt::Password.new(remember_digest).is_password?(remember_token)
    # end

    # Returns true if the given token matches the digest. (With activation)
    def authenticated?(attribute, token)
        digest = send("#{attribute}_digest")
        return false if digest.nil?
        BCrypt::Password.new(digest).is_password?(token)
    end

    # Forgets a user.
    def forget
        update_attribute(:remember_digest, nil)
    end

    # Activates an account.
    def activate
        # update_attribute(:activated,true)
        # update_attribute(:activated_at, Time.zone.now)
        update_columns(activated: true, activated_at: Time.zone.now)
    end

        # Sends activation email.
    def send_activation_email
        UserMailer.account_activation(self).deliver_now
    end
        
    # Defines a proto-feed.
    # See "Following users" for the full implementation.
    def feed
        Micropost.where("user_id = ?", id)
    end

    # Follows a user.
    def follow(other_user)
        following << other_user unless self == other_user
    end

    # Unfollows a user.
    def unfollow(other_user)
        following.delete(other_user)
    end

    # Returns true if the current user is following the other user.
    def following?(other_user)
        following.include?(other_user)
    end

    private

        # Convert email to all lower-case
        def downcase_email
            # self.email = email.downcase #Before
            email.downcase! # After
        end

        # Creates and assigns the activation token and digest.
        def create_activation_digest
            self.activation_token = User.new_token
            self.activation_digest = User.digest(activation_token)
        end
end
