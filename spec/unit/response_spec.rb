require 'spec_helper'

describe CoachClient::Response do
  subject { CoachClient::Response.new(header, body, code) }
  let(:header) { { content_type: 'application/json' } }
  let(:body) { '{"description": "some description"}' }
  let(:code) { 200 }

  describe "#to_h" do
    context "when body is JSON" do
      it "returns ruby hash" do
        expect(subject.to_h).to be_instance_of(Hash)
      end
    end

    context "when body is not JSON" do
      let(:body) { 'text' }

      it "raises an error" do
        expect { subject.to_h }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe "#to_s" do
    it "returns string" do
      expect(subject.to_s).to be_instance_of(String)
    end
  end
end
