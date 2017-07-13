require 'rspec'
require './adapters/user_session'

RSpec.describe UserSession do
  let(:post_body){ File.read('spec/fixtures/amazon_init.json')}
  let(:build_user) {lambda {|pb=post_body| UserSession.new(pb)}}
  let(:episodes_cache) {build_user[].episodes_cache}
  before(:each) { build_user[].reset! }
  subject { build_user[] }


  describe '.new(post_body)' do
    it "sets #new_user properly" do
      expect(subject.new_user).to be true
      subject.current_episode
      expect(build_user[].new_user).to be false
    end

    it "builds from hash or string" do
      expect(lambda{build_user[post_body]}).not_to raise_error
      expect(lambda{build_user[Oj.load(post_body)]}).not_to raise_error
    end
  end

  describe '#current_episode' do
    context 'when the user is new' do
      it "returns the first episode" do
        expect(subject.current_episode).to eq episodes_cache.first
      end
    end

    context 'when the episode is too old' do
      it "returns the first episode" do
        subject.current_episode = 55555
        expect(subject.current_episode).to eq episodes_cache.first
      end
    end

    context 'when there is a saved episode' do
      it "returns the episode object" do
        random = subject.current_episode = episodes_cache.sample
        expect(subject.current_episode).to eql random
      end
    end
  end

  describe '#current_episode=(episode)' do
    it "uses the first episode when passed `false`" do
      # this works with prev / next to loop foward episodes
      # expect(subject.)
    end
  end

  describe '#next_episode' do
    it "returns the next episode in the cache" do
      expect(subject.current_episode).to eq episodes_cache.first
      expect(subject.next_episode).to eq episodes_cache[1]
    end

    it "returns false once 'out' of episodes" do
      subject.current_episode = episodes_cache[-1]
      expect(subject.next_episode).to be false
    end
  end

  describe '#prev_episode' do
    it "returns the previous episode in the cache" do
      subject.current_episode = episodes_cache[1]
      expect(subject.prev_episode).to eq episodes_cache.first
    end

    it "returns false once 'out' of episodes" do
      expect(subject.prev_episode).to be false
    end
  end

  describe '#remaining_episode_count' do
    it "returns the number of episodes forward of the current_episode" do
      expect(subject.remaining_episode_count).to be episodes_cache.length-1
      subject.next_episode!
      expect(subject.remaining_episode_count).to be episodes_cache.length-2
    end
  end

  describe '#updated_at' do
    it "returns a Date" do
      subject.next_episode!
      expect(subject.updated_at).to be_a Date
    end
  end

  describe '#loop!(is=true)' do
    it "toggles .looping?" do
      subject.loop!
      expect(subject.looping?).to be true
      subject.loop! false
      expect(subject.looping?).to be false
    end
  end


end
