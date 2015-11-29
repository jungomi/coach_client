require 'spec_helper'

describe CoachClient::Client do
  before do
    @host = 'http://diufvm31.unifr.ch:8090'
    @path = '/CyberCoachServer/resources/'
    @client = CoachClient::Client.new(@host, @path)
  end

  describe "#url" do
    it "returns the correct url" do
      expect(@client.url).to eql(@host + @path)
    end
  end

  describe "#authenticated?", :vcr do
    subject { @client.authenticated?(user, password) }

    context "with valid credentials" do
      let(:user) { 'user123' }
      let(:password) { 'test123' }

      it "returns true" do
        is_expected.to be true
      end
    end

    context "with invalid password" do
      let(:user) { 'user123' }
      let(:password) { 'invalidpassword' }

      it "returns false" do
        is_expected.to be false
      end
    end

    context "with non-existent user" do
      let(:user) { 'nonexistent' }
      let(:password) { 'password' }

      it "returns false" do
        is_expected.to be false
      end
    end
  end

  describe "#get_sport", :vcr do
    subject { @client.get_sport(sport) }

    context "when sport exists" do
      context "when using String" do
        let(:sport) { 'running' }

        it "returns the correct sport object" do
          is_expected.to be_instance_of(CoachClient::Sport)
          expect(subject.to_s).to eql(sport)
        end
      end

      context "when using Symbol" do
        let(:sport) { :running }

        it "returns the correct sport object" do
          is_expected.to be_instance_of(CoachClient::Sport)
          expect(subject.sport).to eql(sport)
        end
      end
    end

    context "when sport does not exist" do
      context "when using String" do
        let(:sport) { 'tennis' }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end
      context "when using Symbol" do
        let(:sport) { :tennis }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end
    end
  end

  describe "#get_user", :vcr do
    subject { @client.get_user(username) }

    context "when user exists" do
      let(:username) { 'user123' }

      it "returns the correct user object" do
        is_expected.to be_instance_of(CoachClient::User)
        expect(subject.to_s).to eql(username)
      end
    end

    context "when user does not exist" do
      let(:username) { 'nonexistinguser' }

      it "raises a NotFound error" do
        expect{ subject }.to raise_error(CoachClient::NotFound)
      end
    end
  end

  describe "#get_partnership", :vcr do
    subject { @client.get_partnership(user1, user2) }

    context "when partnership exists" do
      context "when using username" do
        let(:user1) { 'user123' }
        let(:user2) { 'user321' }

        it "returns the correct partnership object" do
          is_expected.to be_instance_of(CoachClient::Partnership)
          expect(subject.user1.to_s).to eql(user1)
          expect(subject.user2.to_s).to eql(user2)
        end
      end

      context "when using user object" do
        let(:user1) { CoachClient::User.new(@client, 'user123') }
        let(:user2) { CoachClient::User.new(@client, 'user321') }

        it "returns the correct partnership object" do
          is_expected.to be_instance_of(CoachClient::Partnership)
          expect(subject.user1).to eql(user1)
          expect(subject.user2).to eql(user2)
        end
      end
    end

    context "when partnership does not exist" do
      context "when using username" do
        let(:user1) { 'user123' }
        let(:user2) { 'anotheruser' }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end

      context "when using user object" do
        let(:user1) { CoachClient::User.new(@client, 'user123') }
        let(:user2) { CoachClient::User.new(@client, 'anotheruser') }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end
    end
  end

  describe "#get_user_subscription", :vcr do
    subject { @client.get_user_subscription(user, sport) }

    context "when subscription exists" do
      context "using strings" do
        let(:user) { 'user123' }
        let(:sport) { 'running' }

        it "returns the correct subscription object" do
          is_expected.to be_instance_of(CoachClient::UserSubscription)
          expect(subject.user.to_s).to eql(user)
          expect(subject.sport.to_s).to eql(sport)
        end
      end

      context "using objects" do
        let(:user) { CoachClient::User.new(@client, 'user123') }
        let(:sport) {  CoachClient::Sport.new(@client, 'running') }

        it "returns the correct subscription object" do
          is_expected.to be_instance_of(CoachClient::UserSubscription)
          expect(subject.user).to eql(user)
          expect(subject.sport).to eql(sport)
        end
      end
    end

    context "when subscription does not exist" do
      context "using Strings" do
        let(:user) { 'user321' }
        let(:sport) { 'running' }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end

      context "using objects" do
        let(:user) { CoachClient::User.new(@client, 'user321') }
        let(:sport) {  CoachClient::Sport.new(@client, 'running') }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end
    end
  end

  describe "#get_partnership_subscription", :vcr do
    subject { @client.get_partnership_subscription(user1, user2, sport) }

    context "when subscription exists" do
      context "when using strings" do
        let(:user1) { 'user123' }
        let(:user2) { 'user321' }
        let(:sport) { 'running' }

        it "returns the correct subscription object" do
          is_expected.to be_instance_of(CoachClient::PartnershipSubscription)
          expect(subject.partnership.user1.to_s).to eql(user1)
          expect(subject.partnership.user2.to_s).to eql(user2)
          expect(subject.sport.to_s).to eql(sport)
        end
      end

      context "when using objects" do
        let(:user1) { CoachClient::User.new(@client, 'user123') }
        let(:user2) { CoachClient::User.new(@client, 'user321') }
        let(:sport) { CoachClient::Sport.new(@client, 'running') }

        it "returns the correct subscription object" do
          is_expected.to be_instance_of(CoachClient::PartnershipSubscription)
          expect(subject.partnership.user1).to eql(user1)
          expect(subject.partnership.user2).to eql(user2)
          expect(subject.sport).to eql(sport)
        end
      end
    end

    context "when subscription does not exist" do
      context "when using strings" do
        let(:user1) { 'user123' }
        let(:user2) { 'user321' }
        let(:sport) { 'boxing' }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end

      context "when using objects" do
        let(:user1) { CoachClient::User.new(@client, 'user123') }
        let(:user2) { CoachClient::User.new(@client, 'user321') }
        let(:sport) { CoachClient::Sport.new(@client, 'boxing') }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end
    end
  end
end

