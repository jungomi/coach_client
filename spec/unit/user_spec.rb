require 'spec_helper'

describe CoachClient::User do
  before do
    @client = CoachClient::Client.new('http://diufvm31.unifr.ch:8090',
                                      '/CyberCoachServer/resources/')
  end

  describe ".path" do
    subject { CoachClient::User.path }

    it "returns the users path" do
      is_expected.to eql('users/')
    end
  end

  describe ".total", :vcr do
    subject { CoachClient::User.total(@client) }

    it "returns the total number of users" do
      expect { Integer(subject) }.to_not raise_error
    end
  end

  describe ".list", :vcr do
    context "with no additional parameters" do
      subject { CoachClient::User.list(@client) }

      it "returns an array of User objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::User) )
      end
    end

    context "with the size parameter" do
      subject { CoachClient::User.list(@client, size: size) }
      let(:size) { 5 }

      it "returns an array of User objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::User) )
      end

      it "returns the specified number of users" do
        expect(subject.size).to eql(size)
      end
    end

    context "with the start parameter" do
      subject { CoachClient::User.list(@client, start: start) }
      let(:before_start) { CoachClient::User.list(@client, size: start) }
      let(:start) { 2 }

      it "returns an array of User objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::User) )
      end

      it "returns the users after the start" do
        is_expected.to_not include(before_start)
      end
    end

    context "with the all parameter" do
      subject { CoachClient::User.list(@client, all: true) }

      it "returns an array of User objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::User) )
      end

      it "has all users" do
        expect(subject.size).to eql(CoachClient::User.total(@client))
      end
    end

    context "with a block given" do
      subject { CoachClient::User.list(@client) { |u| u.username.include?(sub_str) } }
      let(:sub_str) { 'ja' }

      it "returns an array of User objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::User) )
      end

      it "has only the filtered users" do
        subject.each do |s|
          expect(s.username).to include(sub_str)
        end
      end
    end
  end

  subject { CoachClient::User.new(@client, user) }
  let(:user) { 'user321' }

  describe "#url" do
    it "ends with the user url" do
      expect(subject.url).to end_with('users/' + user)
    end
  end

  describe "#to_s" do
    it "returns the string representation" do
      expect(subject.to_s).to eql(user)
    end
  end

  describe "#update", :vcr do
    context "when the user exists" do
      it "has the updated values" do
        subject.update
        expect(subject.realname).to_not eql nil
        expect(subject.email).to_not eql nil
        expect(subject.datecreated).to_not eql nil
        expect(subject.publicvisible).to_not eql nil
        expect(subject.partnerships).to_not eql nil
        expect(subject.subscriptions).to_not eql nil
      end
    end

    context "when the user does not exist" do
      let(:user) { 'nonexistinguser' }

      it "raises a NotFound error" do
        expect { subject.update }.to raise_error(CoachClient::NotFound)
      end
    end
  end

  describe "#save", :vcr do
    context "when user does not exist" do
      let(:user) { 'brandnewuser' }

      context "with incomplete information" do
        it "raises an IncompleteInformation error" do
          expect { subject.save }.to raise_error(CoachClient::IncompleteInformation)
        end
      end

      context "with complete information" do
        it "returns the saved user" do
          subject.password = 'password'
          subject.email = 'email@address.com'
          subject.realname = 'A real name'
          subject.publicvisible = 2
          expect(subject.save).to be_instance_of(CoachClient::User)
          expect(subject.exist?).to be true
        end
      end
    end

    context "when user already exists" do
      context "with incorrect password" do
        it "raises an Unauthorized error" do
          subject.password = 'incorrectpassword'
          expect { subject.save }.to raise_error(CoachClient::Unauthorized)
        end
      end

      context "with correct password" do
        it "returns the saved user" do
          realname = 'Real User'
          subject.password = 'test321'
          subject.realname = realname
          returned_user = subject.save
          expect(returned_user).to be_instance_of(CoachClient::User)
          expect(returned_user.realname).to eql(realname)
        end
      end
    end
  end

  describe "#delete", :vcr do
    context "when user does not exist" do
      let(:user) { 'nonexistinguser' }

      it "raises a NotFound error" do
        expect { subject.delete }.to raise_error(CoachClient::NotFound)
      end
    end

    context "when user does exist" do
      let(:user) { 'brandnewuser' }

      context "with incorrect password" do
        it "raises an Unauthorized error" do
          subject.password =  'incorrectpassword'
          expect { subject.delete }.to raise_error(CoachClient::Unauthorized)
        end
      end

      context "with correct password" do
        it "returns true" do
          subject.password =  'password'
          expect(subject.delete).to be true
        end
      end
    end
  end

  describe "#authenticated?", :vcr do
    context "with incorrect credentials" do
      it "returns false" do
        subject.password = 'incorrectpassword'
        expect(subject.authenticated?).to be false
      end
    end

    context "with correct credentials" do
      it "returns true" do
        subject.password = 'test321'
        expect(subject.authenticated?).to be true
      end
    end
  end
end

