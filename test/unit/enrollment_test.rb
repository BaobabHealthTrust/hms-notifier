require 'test_helper'

class EnrollmentTest < ActiveSupport::TestCase
  setup do
    @enrollment = Factory.build(:enrollment)
  end

  test "valid enrollment is valid" do
    assert Factory.build(:enrollment).valid?
  end

  test "should be invalid without a first_name" do
    assert Factory.build(:enrollment, :first_name => nil).invalid?
  end

  test "should be invalid without a last_name" do
    assert Factory.build(:enrollment, :last_name => nil).invalid?
  end

  test "should be invalid without a phone_number" do
    assert Factory.build(:enrollment, :phone_number => nil).invalid?
  end

  test "should be invalid without a delivery_method" do
    assert Factory.build(:enrollment, :delivery_method => nil).invalid?
  end

  test "should be invalid without a stream_start date" do
    assert Factory.build(:enrollment, :stream_start => nil).invalid?
  end

  test "should be able to retrieve the created_at date" do
    @enrollment.save!
    assert_not_nil @enrollment.created_at
  end

  test "should be able to retrieve the updated_at date" do
    @enrollment.save!
    assert_not_nil @enrollment.updated_at
  end

end
