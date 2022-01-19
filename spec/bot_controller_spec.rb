require './bot_controller'
require './bot_service'

describe 'moc練習' do

  let(:service) { double(:service) }
  let(:event) { double(:event) }

  before do
    allow(BotService).to receive(:new).and_return(service)
  end

  context "「おはよう」メンションが来たとき" do
    before do
      allow(event).to receive_message_chain(:message, :to_s).and_return("おはよう")
    end

    it 'respond_good_morningが呼ばれる' do
      controller = BotController.new
      expect(service).to receive(:respond_good_morning).with(event)
      controller.handle_mention(event)
    end
  end

  context "「おやすみ」メンションが来たとき" do
    before do
      allow(event).to receive_message_chain(:message, :to_s).and_return("おやすみ")
    end

    it 'respond_good_nightが呼ばれる' do
      controller = BotController.new
      expect(service).to receive(:respond_good_night).with(event)
      controller.handle_mention(event)
    end
  end

  context "「楽天」メンションが来たとき" do
    before do
      allow(event).to receive_message_chain(:message, :to_s).and_return("黒衣の楽天使")
    end

    it 'suggest_rakutenが呼ばれる' do
      controller = BotController.new
      expect(service).to receive(:suggest_rakuten).with(event)
      controller.handle_mention(event)
    end
  end

  context "「wiki」メンションが来たとき" do
    before do
      allow(event).to receive_message_chain(:message, :to_s).and_return("今日のwikipedia")
    end

    it 'suggest_wikipediaが呼ばれる' do
      controller = BotController.new
      expect(service).to receive(:suggest_wikipedia).with(event)
      controller.handle_mention(event)
    end
  end
end