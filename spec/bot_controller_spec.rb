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

    it 'おはようと返す' do
      controller = BotController.new
      expect(service).to receive(:say_good_morning).with(event)
      controller.handle_mention(event)
    end
  end

  context "「おやすみ」メンションが来たとき" do
    before do
      allow(event).to receive_message_chain(:message, :to_s).and_return("おやすみ")
    end

    it 'おやすみと返す' do
      controller = BotController.new
      expect(service).to receive(:say_good_night).with(event)
      controller.handle_mention(event)
    end
  end

  context "「楽天」メンションが来たとき" do
    before do
      allow(event).to receive_message_chain(:message, :to_s).and_return("黒衣の楽天使")
    end

    it '楽天の商品をサジェストする' do
      controller = BotController.new
      expect(service).to receive(:suggest_rakuten).with(event)
      controller.handle_mention(event)
    end
  end

  context "「wiki」メンションが来たとき" do
    before do
      allow(event).to receive_message_chain(:message, :to_s).and_return("今日のwikipedia")
    end

    it 'Wikipediaの記事をサジェストする' do
      controller = BotController.new
      expect(service).to receive(:suggest_wikipedia).with(event)
      controller.handle_mention(event)
    end
  end

  context "その他のメンションが来たとき" do
    before do
      allow(event).to receive_message_chain(:message, :to_s).and_return("可愛いね")
    end

    it 'ランダムな返答をする' do
      controller = BotController.new
      expect(service).to receive(:say_random).with(event)
      controller.handle_mention(event)
    end
  end
end