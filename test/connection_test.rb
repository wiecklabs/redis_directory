require File.dirname(__FILE__) + "/helper"

class ConnectionTest < MiniTest::Unit::TestCase

  def setup
    @user = User.create(:email => SAMPLE_EMAIL, :password => SAMPLE_PASSWORD, :role_name => "User")
    @session = Harbor::Session.new(Harbor::Test::Request.new)
  end

  def teardown
    @r.quit if @r
  end
  
  def test_that_user_can_login
    assert @session.authenticate!(SAMPLE_EMAIL, SAMPLE_PASSWORD)
  end
  
  def test_that_bad_email_cant_login
    assert !@session.authenticate!("bad", SAMPLE_PASSWORD)
  end
  
  def test_that_bad_password_cant_login
    assert !@session.authenticate!(SAMPLE_EMAIL, "bad")
  end
end