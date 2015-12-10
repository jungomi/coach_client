require 'spec_helper'

describe CoachClient::Entry do
  before do
    @client = CoachClient::Client.new('http://diufvm31.unifr.ch:8090',
                                      '/CyberCoachServer/resources/')
  end

  describe ".extract_id_from_uri" do
    subject { CoachClient::Entry.extract_id_from_uri(uri) }
    let(:uri) { "http://example.com/subscription/#{id}/" }
    let(:id) { '123' }

    it "returns the id" do
      is_expected.to eql(id)
    end
  end

  subject { entry }
  let(:entry) { entry_without_id }
  let(:entry_without_id) { CoachClient::Entry.new(@client, subscription) }
  let(:entry_with_id) { CoachClient::Entry.new(@client, subscription, id: id) }
  let(:id) { 123 }
  let(:subscription) { user_subscription }
  let(:user_subscription) { CoachClient::UserSubscription.new(@client, user, sport) }
  let(:partnership_subscription) { CoachClient::PartnershipSubscription.new(@client, partnership, sport) }
  let(:user) { CoachClient::User.new(@client, 'subscriber', password: 'password') }
  let(:partner1) { CoachClient::User.new(@client, 'partner1', password: 'password') }
  let(:partner2) { CoachClient::User.new(@client, 'partner2', password: 'password') }
  let(:partnership) { CoachClient::Partnership.new(@client, partner1, partner2) }
  let(:sport) { 'running' }

  describe "#url" do
    context "without an id" do
      it "ends with the subscription path" do
        expect(subject.url).to end_with "#{sport}/"
      end
    end

    context "with an id" do
      let(:entry) { entry_with_id }

      it "ends with the id" do
        expect(subject.url).to end_with "#{sport}/#{id}"
      end
    end
  end

  describe "#to_s" do
    context "without an id" do
      it "returns an empty string" do
        expect(subject.to_s).to eql("")
      end
    end

    context "with an id" do
      let(:entry) { entry_with_id }

      it "returns the id" do
        expect(subject.to_s).to eql(id.to_s)
      end
    end
  end

  describe "#user", :vcr do
    context "with a partnership subscription" do
      let(:subscription) { partnership_subscription }

      context "when partner1 is not authenticated" do
        it "returns partner2" do
          subscription.partnership.user1.password = nil
          expect(subject.user).to eql(partner2)
        end
      end

      context "when partner1 is authenticated" do
        it "returns partner1" do
          expect(subject.user).to eql(partner1)
        end
      end
    end

    context "with a user subscription" do
      it "returns the user" do
        expect(subject.user).to eql(user)
      end
    end
  end

  describe "#update", :vcr do
    context "without an id" do
      it "raises a NotFound error" do
        expect { subject.update }.to raise_error(CoachClient::NotFound)
      end
    end

    context "with an id" do
      let(:entry) { entry_with_id }
      let(:id) { 9999 }

      context "when the entry does not exist" do
        it "raises a NotFound error" do
          expect { subject.update }.to raise_error(CoachClient::NotFound)
        end
      end

      context "when the entry exists" do
        let(:id) { 779 }

        it "has the updated values" do
          subject.update
          expect(subject.datecreated).to_not be nil
          expect(subject.datemodified).to_not be nil
          expect(subject.publicvisible).to_not be nil
        end
      end
    end
  end

  describe "#create", :vcr do
    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subscription.user.password = nil
        expect { subject.create }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      context "with incomplete information" do
        it "raises an IncompleteInformation error" do
          expect { subject.create }.to raise_error(CoachClient::IncompleteInformation)
        end
      end

      context "with complete information" do
        it "returns the created entry" do
          subject.publicvisible = 2
          expect(subject.create).to be_instance_of(CoachClient::Entry)
          expect(subject.exist?).to be true
        end
      end
    end
  end

  describe "#save", :vcr do
    context "without an id" do
      it "creates a new entry" do
        subject.publicvisible = 2
        subject.save
        expect(subject.exist?)
      end
    end

    context "with an id" do
      let(:entry) { entry_with_id }

      context "when entry does not exist" do
        let(:id) { 9999 }

        it "raises a NotFound error" do
          expect { subject.save }.to raise_error(CoachClient::NotFound)
        end
      end

      context "when entry exists" do
        let(:id) { 780 }
        let(:comment) { 'updated' }

        it "has the updated values" do
          subject.comment = comment
          expect(subject.save.comment).to eql(comment)
        end
      end
    end
  end

  describe "#delete", :vcr do
    context "without an id" do
      it "raises a NotFound error" do
        expect { subject.delete }.to raise_error(CoachClient::NotFound)
      end
    end

    context "with an id" do
      let(:entry) { entry_with_id }
      let(:id) { 801 }

      context "when not authenticated" do
        it "raises an Unauthorized error" do
          subscription.user.password = nil
          expect { subject.delete }.to raise_error(CoachClient::Unauthorized)
        end
      end

      context "when authenticated" do
        it "returns true" do
          expect(subject.delete).to be true
          expect(subject.exist?).to be false
        end
      end
    end
  end
end

