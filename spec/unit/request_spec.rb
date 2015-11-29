require 'spec_helper'

describe CoachClient::Request do
  before do
    @user = 'user123'
    @password = 'test123'
  end

  describe ".get", :vcr  do
    context "when credentials are given" do
      subject { CoachClient::Request.get(url, username: @user, password: @password) }

      context "when url exists" do
        let(:url) { 'http://diufvm31.unifr.ch:8090/CyberCoachServer/resources/users/' }

        it "returns a response" do
          is_expected.to be_instance_of(CoachClient::Response)
        end
      end

      context "when url does not exist" do
        let(:url) { 'http://diufvm31.unifr.ch:8090/CyberCoachServer/resources/not/' }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end
    end

    context "when no credentials are given" do
      subject { CoachClient::Request.get(url) }

      context "when url exists" do
        let(:url) { 'http://diufvm31.unifr.ch:8090/CyberCoachServer/resources/users/' }

        it "returns a response" do
          is_expected.to be_instance_of(CoachClient::Response)
        end
      end

      context "when url does not exist" do
        let(:url) { 'http://diufvm31.unifr.ch:8090/CyberCoachServer/resources/not/' }

        it "raises a NotFound error" do
          expect{ subject }.to raise_error(CoachClient::NotFound)
        end
      end
    end
  end

  describe ".put", :vcr do
    before do
      @url = 'http://diufvm31.unifr.ch:8090/CyberCoachServer/resources/users/user123/cycling'
      @payload = '<subscription><publicvisible>2</publicvisible></subscription>'
    end

    context "when all parameters are given" do
      subject {
        CoachClient::Request.put(@url, username: @user, password: @password,
                                 payload: @payload,
                                 content_type: :xml)
      }

      it "returns a response" do
        is_expected.to be_instance_of(CoachClient::Response)
      end
    end

    context "when payload is missing" do
      subject { CoachClient::Request.put(@url, username: @user,
                                         password: @password, content_type: :xml) }

      it "raises an argument error" do
        expect{ subject }.to raise_error(ArgumentError)
      end
    end

    context "when credentials are missing" do
      subject { CoachClient::Request.put(@url, payload: @payload, content_type: :xml) }

      it "raises unauthorized error" do
        expect{ subject }.to raise_error(CoachClient::Unauthorized)
      end
    end
  end

  describe ".post", :vcr do
    before do
      @url = 'http://diufvm31.unifr.ch:8090/CyberCoachServer/resources/users/user123/cycling'
      @payload = '<entrycycling><publicvisible>1</publicvisible></entrycycling>'
    end

    context "when all parameters are given" do
      subject {
        CoachClient::Request.post(@url, username: @user,
                                  password: @password,
                                  payload: @payload,
                                  content_type: :xml)
      }

      it "returns a response" do
        is_expected.to be_instance_of(CoachClient::Response)
      end
    end

    context "when payload is missing" do
      subject { CoachClient::Request.post(@url, username: @user,
                                          password: @password, content_type: :xml) }

      it "raises an argument error" do
        expect{ subject }.to raise_error(ArgumentError)
      end
    end

    context "when credentials are missing" do
      subject { CoachClient::Request.post(@url, payload: @payload, content_type: :xml) }

      it "raises unauthorized error" do
        expect{ subject }.to raise_error(CoachClient::Unauthorized)
      end
    end
  end

  describe ".delete", :vcr do
    before do
      @url = 'http://diufvm31.unifr.ch:8090/CyberCoachServer/resources/users/user123/cycling'
    end

    context "when credentials are missing" do
      subject { CoachClient::Request.delete(@url) }

      it "raises unauthorized error" do
        expect{ subject }.to raise_error(CoachClient::Unauthorized)
      end
    end

    context "when all parameters are given" do
      subject {
        CoachClient::Request.delete(@url, username: @user, password: @password)
      }

      it "returns a response" do
        is_expected.to be_instance_of(CoachClient::Response)
      end
    end
  end
end
