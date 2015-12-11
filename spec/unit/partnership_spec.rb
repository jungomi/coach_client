require 'spec_helper'

describe CoachClient::Partnership do
  before do
    @client = CoachClient::Client.new('http://diufvm31.unifr.ch:8090',
                                      '/CyberCoachServer/resources/')
  end

  describe ".path" do
    subject { CoachClient::Partnership.path }

    it "returns the partnerships path" do
      is_expected.to eql('partnerships/')
    end
  end

  describe ".extract_users_from_uri" do
    subject { CoachClient::Partnership }
    let(:user1) { 'user1' }
    let(:user2) { 'user2' }
    let(:uri) { "http://example.com/partnerships/#{user1};#{user2}/" }

    it "returns the two usernames" do
      puts uri
      extracted_user1, extracted_user2 = subject.extract_users_from_uri(uri)
      expect(extracted_user1).to eql(user1)
      expect(extracted_user2).to eql(user2)
    end
  end

  describe ".total", :vcr do
    subject { CoachClient::Partnership.total(@client) }

    it "returns the total number of partnerships" do
      expect { Integer(subject) }.to_not raise_error
    end
  end

  describe ".list", :vcr do
    context "with no additional parameters" do
      subject { CoachClient::Partnership.list(@client) }

      it "returns an array of Partnership objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::Partnership) )
      end
    end

    context "with the size parameter" do
      subject { CoachClient::Partnership.list(@client, size: size) }
      let(:size) { 5 }

      it "returns an array of Partnership objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::Partnership) )
      end

      it "returns the specified number of partnerships" do
        expect(subject.size).to eql(size)
      end
    end

    context "with the start parameter" do
      subject { CoachClient::Partnership.list(@client, start: start) }
      let(:before_start) { CoachClient::Partnership.list(@client, size: start) }
      let(:start) { 2 }

      it "returns an array of Partnership objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::Partnership) )
      end

      it "returns the partnerships after the start" do
        is_expected.to_not include(before_start)
      end
    end

    context "with the all parameter" do
      subject { CoachClient::Partnership.list(@client, all: true) }

      it "returns an array of Partnership objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::Partnership) )
      end

      it "has all partnerships" do
        expect(subject.size).to eql(CoachClient::Partnership.total(@client))
      end
    end

    context "with a block given" do
      subject { CoachClient::Partnership.list(@client) { |p| p.user1.username.include?(sub_str) } }
      let(:sub_str) { 'ja' }

      it "returns an array of Partnership objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::Partnership) )
      end

      it "has only the filtered partnerships" do
        subject.each do |s|
          expect(s.user1.username).to include(sub_str)
        end
      end
    end
  end

  describe ".new" do
    context "with different input types" do
      let(:user1) { CoachClient::User.new(@client, username1) }
      let(:user2) { CoachClient::User.new(@client, username2) }
      let(:username1) { 'user1' }
      let(:username2) { 'user2' }
      let(:with_users) { CoachClient::Partnership.new(@client, user1, user2) }
      let(:with_usernames) { CoachClient::Partnership.new(@client, username1, username2) }
      let(:mixed) { CoachClient::Partnership.new(@client, user1, username2) }

      it "returns the same partnership" do
        expect(with_users.to_s).to eql(with_usernames.to_s)
        expect(with_users.to_s).to eql(mixed.to_s)
        expect(with_usernames.to_s).to eql(mixed.to_s)
      end
    end
  end

  subject { CoachClient::Partnership.new(@client, user1, user2) }
  let(:partner1) { CoachClient::User.new(@client, 'partner1', password: 'password') }
  let(:partner2) { CoachClient::User.new(@client, 'partner2', password: 'password') }
  let(:partner3) { CoachClient::User.new(@client, 'partner3', password: 'password') }
  let(:no_partner) { CoachClient::User.new(@client, 'nopartner', password: 'password') }
  let(:user1) { partner1 }
  let(:user2) { partner2 }

  describe "#url" do
    it "ends with the partnership url" do
      expect(subject.url).to end_with("partnerships/#{user1};#{user2}")
    end
  end

  describe "#to_s" do
    it "returns the string representation" do
      expect(subject.to_s).to eql("#{user1};#{user2}")
    end
  end

  describe "#operational?", :vcr do
    context "when the partnership does not exist" do
      let(:user2) { no_partner }

      it "returns nil" do
        expect(subject.operational?).to be nil
      end
    end

    context "when the partnership exists" do
      context "when not both users confirmed" do
        let(:user2) { partner3 }

        it "returns false" do
          subject.update
          expect(subject.operational?).to be false
        end
      end

      context "when both users confirmed" do
        let(:user2) { partner2 }

        it "returns true" do
          subject.update
          expect(subject.operational?).to be true
        end
      end
    end
  end

  describe "#update", :vcr do
    context "when the partnership does not exist" do
      let(:user2) { no_partner }

      it "raises a NotFound error" do
        expect { subject.update }.to raise_error(CoachClient::NotFound)
      end
    end

    context "when the partnership exists" do
      let(:user2) { partner2 }

      it "has the updated values" do
        subject.update
        expect(subject.id).to_not be nil
        expect(subject.datecreated).to_not be nil
        expect(subject.publicvisible).to_not be nil
        expect(subject.user1_confirmed).to_not be nil
        expect(subject.user2_confirmed).to_not be nil
        expect(subject.subscriptions).to_not be nil
      end
    end
  end

  describe "#propose", :vcr do
    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subject.user1.password = nil
        expect { subject.propose }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      let(:user1) { no_partner }

      context "with incomplete information" do
        it "raises an IncompleteInformation error" do
          expect { subject.propose }.to raise_error(CoachClient::IncompleteInformation)
        end
      end

      context "with complete information" do
        it "confirms user1" do
          subject.publicvisible = 2
          subject.propose
          expect(subject.user1_confirmed).to be true
        end
      end
    end
  end

  describe "#confirm", :vcr do
    let(:user1) { partner3 }

    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subject.user2.password = nil
        expect { subject.confirm }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      it "confirms user2" do
        subject.user2.password = 'password'
        subject.confirm
        expect(subject.user2_confirmed).to be true
      end
    end
  end

  describe "#cancel", :vcr do
    let(:user1) { partner3 }

    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subject.user1.password = nil
        expect { subject.cancel }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      it "cancels user1" do
        subject.cancel
        expect(subject.user1_confirmed).to be false
      end
    end
  end

  describe "#invalidate", :vcr do
    let(:user1) { partner3 }

    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subject.user2.password = nil
        expect { subject.invalidate }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      it "invalidates user2" do
        subject.invalidate
        expect(subject.user2_confirmed).to be false
      end
    end
  end

  describe "#save", :vcr do
    let(:user1) { partner3 }

    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subject.user1.password = nil
        subject.user2.password = nil
        expect { subject.save }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      it "returns the operational partnership" do
        expect(subject.save).to be_instance_of(CoachClient::Partnership)
        expect(subject.operational?).to be true
      end
    end
  end

  describe "#delete", :vcr do
    let(:user1) { partner3 }

    context "when not authenticated" do
      it "raises an Unauthorized error" do
        subject.user1.password = nil
        subject.user2.password = nil
        expect { subject.save }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when authenticated" do
      it "returns true" do
        expect(subject.delete).to be true
      end
    end

    context "when the partnership does not exist" do
      let(:user2) { no_partner }

      it "raises a NotFound error" do
        expect { subject.delete }.to raise_error(CoachClient::NotFound)
      end
    end
  end
end
