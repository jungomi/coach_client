require 'spec_helper'

describe CoachClient::UserSubscription do
  before do
    @client = CoachClient::Client.new('http://diufvm31.unifr.ch:8090',
                                      '/CyberCoachServer/resources/')
  end

  describe ".path" do
    subject { CoachClient::UserSubscription.path }

    it "returns the users path" do
      is_expected.to eql('users/')
    end
  end

  describe ".new" do
    context "with different input types"
    let(:username) { 'subscriber' }
    let(:user) { CoachClient::User.new(@client, username) }
    let(:sport_name) { 'running' }
    let(:sport) { CoachClient::Sport.new(@client, sport_name) }
    let(:with_objects) { CoachClient::UserSubscription.new(@client, user, sport) }
    let(:with_strings) { CoachClient::UserSubscription.new(@client, username, sport_name) }
    let(:mixed) { CoachClient::UserSubscription.new(@client, user, sport_name) }

    it "returns the same subscription" do
      expect(with_objects.to_s).to eql(with_strings.to_s)
      expect(with_objects.to_s).to eql(mixed.to_s)
      expect(with_strings.to_s).to eql(mixed.to_s)
    end
  end

  subject { CoachClient::UserSubscription.new(@client, user, sport) }
  let(:username) { 'subscriber' }
  let(:user) { CoachClient::User.new(@client, username, password: 'password') }
  let(:sport_name) { 'running' }
  let(:sport) { CoachClient::Sport.new(@client, sport_name) }

  describe "#url" do
    it "ends with the subscription url" do
      expect(subject.url).to end_with("users/#{username}/#{sport_name}")
    end
  end

  describe "#to_s" do
    it "returns the string representation" do
      expect(subject.to_s).to eql("#{username}/#{sport_name}")
    end
  end

  describe "#update", :vcr do
    context "when subscription does not exist" do
      let(:sport_name) { 'cycling' }

      it "raises a NotFound error" do
        expect { subject.update }.to raise_error(CoachClient::NotFound)
      end
    end

    context "when subscription exists" do
      it "has the updated values" do
        subject.update
        expect(subject.id).to_not be nil
        expect(subject.datesubscribed).to_not be nil
        expect(subject.publicvisible).to_not be nil
        expect(subject.entries).to_not be nil
      end
    end
  end

  describe "#save", :vcr do
    let(:sport_name) { 'boxing' }

    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subject.user.password = nil
        expect { subject.save }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      context "with incomplete information" do
        it "raises an IncompleteInformation error" do
          expect { subject.save }.to raise_error(CoachClient::IncompleteInformation)
        end
      end

      context "with complete information" do
        it "returns the saved subscription" do
          subject.publicvisible = 2
          expect(subject.save).to be_instance_of(CoachClient::UserSubscription)
          expect(subject.exist?).to be true
        end
      end
    end
  end

  describe "#delete", :vcr do
    let(:sport_name) { 'boxing' }

    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subject.user.password = nil
        expect { subject.delete }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      context "when subscription exists" do
        it "returns true" do
          expect(subject.delete).to be true
          expect(subject.exist?).to be false
        end
      end

      context "when subscription does not exist" do
        it "raises a NotFound error" do
          expect { subject.delete }.to raise_error(CoachClient::NotFound)
        end
      end
    end
  end
end
