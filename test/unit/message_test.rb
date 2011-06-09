require 'test_helper'

class MessagesTest < ActiveSupport::TestCase
  test "valid message should be valid" do
    assert Factory.build(:message).valid?
  end

  test "should be invalid without a message stream id" do
    assert Factory.build(:message, :message_stream_id => nil).invalid?
  end

  test "should be invalid without a name" do
    assert Factory.build(:message, :name => nil).invalid?
  end

  test "should be invalid without a title" do
    assert Factory.build(:message, :title => nil).invalid?
  end

  #----------------------------------------------------------------------------#
  # offset_days:
  #-------------
  test "should be invalid without an offset" do
    assert Factory.build(:message, :offset_days => nil).invalid?
  end

  test "days offset must be a whole number" do
    assert Factory.build(:message, :offset_days => 2.25).invalid?
  end

  test "negative day offsets are invalid" do
    assert Factory.build(:message, :offset_days => -5).invalid?
  end

  test "zero day offsets are valid" do
    assert Factory.build(:message, :offset_days => 0).valid?
  end

  #----------------------------------------------------------------------------#
  # path:
  #------
  test "can get a unique path to represent message across message streams" do
    message = Factory.build(:message)
    assert_equal "#{message.message_stream.name}/#{message.name}",
      message.path
  end

  test "path should return nil if not enough info to build path" do
    assert_nil Factory.build(:message, :message_stream => nil).path
    assert_nil Factory.build(:message, :name => nil).path
  end

  test "can search for a message by its path" do
    message = Factory.create(:message)
    assert_equal message, Message.find_by_path(message.path)
  end

  test "searching for a message by a nonexistent path should return nil" do
    assert_nil Message.find_by_path('nonexistent/path')
  end

  #----------------------------------------------------------------------------#
  # relationship w/ MessageStream:
  #-------------------------------
  test "can access message stream from message" do
    assert Factory.build(:message).message_stream
  end

end


