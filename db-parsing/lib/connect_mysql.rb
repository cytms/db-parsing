require 'mysql2'

class Connect_mysql
  @@host = "140.112.107.1"
  @@encoding = "utf8"
  def initialize(username, password)
    @username = username
    @password = password
  end

  def db(database)
    @database = database
    db = Mysql2::Client.new(:host => @@host, :username => @username, :password=> @password, :database => @database, :encoding => @@encoding)
    return db
  end

  def username
    @username
  end

  def password
    @password
  end

  def host
    @@host
  end
end