require "openssl"

class User < ApplicationRecord
  ITERATIONS = 20000
  DIGEST = OpenSSL::Digest::SHA256.new
  USERNAME_FORMAT = /\A\w+\z/
  EMAIL_FORMAT = /\A[a-z0-9]+\.[a-z0-9]+@[a-z]+\.[a-z]+/i

  attr_accessor :password

  has_many :questions
  has_many :asked_questions, class_name: "Question", foreign_key: :author_id, dependent: :nullify

  before_save :encrypt_password
  before_validation :downcase_username, :downcase_email

  validates :email, :username, presence: true
  validates :email, :username, uniqueness: true
  validates :password, presence: true, on: :create
  validates :password, confirmation: true
  validates :username, length: { maximum: 40 }
  validates :username, format: { with: USERNAME_FORMAT}
  validates :email, format: { with: EMAIL_FORMAT }

  #служебный метод, преобразующий бинарную строку в 16-ричный формат, для удобства хранения
  def self.hash_to_string(password_hash)
    password_hash.unpack("H*")[0]
  end

  def self.authenticate(email, password)
    user = find_by(email: email&.downcase) #сперва находим кандидата по email

    #сравнивается password_hash, а оригинальный пароль так никогда и  не сохраняется нигде
    if user.present? && user.password_hash == User.hash_to_string(OpenSSL::PKCS5.pbkdf2_hmac(password, user.password_salt, ITERATIONS, DIGEST.length, DIGEST))
      user
    end
  end

  private

  def downcase_username
    username&.downcase!
  end

  def downcase_email
    email&.downcase!
  end

  def encrypt_password
    if self.password.present?
      #создаем т.н. соль - рандоманая строка, усложняющая задачу хакерам
      self.password_salt = User.hash_to_string(OpenSSL::Random.random_bytes(16))

      #создаем хэш пароля - длинная уникальная строка, из которой невозможно восстановить
      #исходный пароль
      self.password_hash = User.hash_to_string(
        OpenSSL::PKCS5.pbkdf2_hmac(self.password, self.password_salt, ITERATIONS, DIGEST.length,
        DIGEST)
      )
    end
  end
end
