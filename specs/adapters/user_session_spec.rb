require 'rspec'
require './adapters/user_session'

RSpec.describe UserSession do
  let(:build_user) {lambda {UserSession.new("test-id")}}
  before(:each) { build_user[].reset! }
  subject { build_user[] }

  describe '.from_post(post_body_hash)' do
    let(:post_body){Oj.load File.read('specs/fixtures/amazon_init.json')}

    it "builds a UserSession" do
      expect(lambda { UserSession.from_post post_body }).not_to raise_error
    end
  end

  describe '.new(amazon_userId)' do
    it "sets #new_user properly" do
      expect(subject.new_user).to be true
      subject.current_episode
      expect(build_user[].new_user).to be false
    end
  end

  describe '#current_episode' do

  end

  describe '#current_episode=(episode)' do

  end

  describe '#next_episode' do

  end

  describe '#prev_episode' do

  end

  describe '#remaining_episode_count' do

  end

end
