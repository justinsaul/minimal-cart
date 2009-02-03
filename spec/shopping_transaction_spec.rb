require File.dirname(__FILE__) + '/../../../../spec/spec_helper'

describe ShoppingTransaction do
  it 'should save the transaction code after creation without a prefix is prefix is undefined' do
    t = ShoppingTransaction.new
    t.save
    id = t.id
    t = ShoppingTransaction.find t
    t.transaction_code.should_not be_nil
    t.transaction_code.empty?.should be_false
    t.transaction_code.should == (15170000 + id).to_s
  end

  it 'should save the transaction code with a prefix if prefix is defined' do
    TRANSACTION_CODE_PREFIX = "PREFIX-"
    t = ShoppingTransaction.new
    t.save
    t = ShoppingTransaction.find t
    t.transaction_code.should =~ /^PREFIX-/
  end
end
