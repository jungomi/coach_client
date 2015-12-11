require 'spec_helper'

describe CoachClient::Sport do
  before do
    @client = CoachClient::Client.new('http://diufvm31.unifr.ch:8090',
                                      '/CyberCoachServer/resources/')
  end

  describe ".path" do
    subject { CoachClient::Sport.path }

    it "returns the sports path" do
      is_expected.to eql('sports/')
    end
  end

  describe ".total", :vcr do
    subject { CoachClient::Sport.total(@client) }

    it "returns the total number of sports" do
      expect { Integer(subject) }.to_not raise_error
    end
  end

  describe ".list", :vcr do
    context "with no block given" do
      subject { CoachClient::Sport.list(@client) }

      it "returns an array of Sport objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::Sport) )
      end

      it "has all sports" do
        expect(subject.size).to eql(CoachClient::Sport.total(@client))
      end
    end

    context "with a block given" do
      subject { CoachClient::Sport.list(@client) { |s| s.sport == sport } }
      let(:sport) { :running }

      it "returns an array of Sport objects" do
        is_expected.to be_instance_of(Array)
        is_expected.to all( be_instance_of(CoachClient::Sport) )
      end

      it "has only the filtered sports" do
        subject.each do |s|
          expect(s.sport).to eql(sport)
        end
      end
    end
  end

  describe ".new" do
    context "when using different types of input" do
      let(:with_string) { CoachClient::Sport.new(@client, sport) }
      let(:with_symbol) { CoachClient::Sport.new(@client, sport.to_sym) }
      let(:sport) { "running" }

      it "returns the same sport" do
        expect(with_string.sport).to eql(with_symbol.sport)
      end
    end
  end

  subject { CoachClient::Sport.new(@client, sport) }
  let(:sport) { :running }

  describe "#url" do
    it "ends with the sport url" do
      expect(subject.url).to end_with('sports/' + sport.to_s)
    end
  end

  describe "#to_s" do
    it "returns the sport" do
      expect(subject.to_s).to eql(sport.to_s)
    end
  end

  describe "#update", :vcr do
    context "when the sport exists" do
      it "has the updated values" do
        subject.update
        expect(subject.id).to_not be nil
        expect(subject.name).to_not be nil
        expect(subject.description).to_not be nil
      end
    end

    context "when the sport does not exist" do
      let(:sport) { :tennis }
      it "raises an error" do
        expect { subject.update }.to raise_error(CoachClient::NotFound)
      end
    end
  end
end
