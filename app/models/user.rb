class User < ActiveRecord::Base
  acts_as_paranoid

  before_create :set_default_role
  before_create :set_default_profile_pic

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :display_name, :name, :profile_photo_url, :system_role_id
  attr_accessible :provider, :uid

  has_many :user_courses, dependent: :destroy
  has_many :courses, through: :user_courses, dependent: :destroy

  belongs_to :system_role, class_name: "Role"

  def is_admin?
    return self.system_role == Role.find_by_name('superuser')
  end

  def is_lecturer?
    return self.is_admin? || self.system_role == Role.find_by_name('lecturer')
  end

  def self.admins
    return User.joins(:system_role).where('roles.name' => 'superuser')
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    puts auth.to_json
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    puts user.to_json
    unless user
      user = User.find_by_email(auth.info.email)
      if user
        user.provider = auth.provider
        user.uid = auth.uid
        if user.use_default_photo_pic?
          user.profile_photo_url = auth.info.image
        end
      else
        user = User.create(name: auth.extra.raw_info.name,
                           provider: auth.provider,
                           uid: auth.uid,
                           email: auth.info.email,
                           password: Devise.friendly_token[0,20],
                           profile_photo_url: auth.info.image
                          )
      end
      user.save
    end
    user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
        user.display_name = user.name = data["name"] if user.name.blank?
      end
    end
  end

  def use_default_photo_pic?
    return self.profile_photo_url ==
        'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash4/c178.0.604.604/s160x160/252231_1002029915278_1941483569_n.jpg'
  end

  private
  def set_default_role
    if !self.system_role
      self.system_role = Role.find_by_name('normal')
    end
  end

  def set_default_profile_pic
    if !self.profile_photo_url
      self.profile_photo_url =
        'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash4/c178.0.604.604/s160x160/252231_1002029915278_1941483569_n.jpg'
    end
  end

end
