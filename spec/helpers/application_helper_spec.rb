require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#duration_in_words_es" do
    it "renders whole hours" do
      expect(helper.duration_in_words_es(2.hours)).to eq("2 horas")
      expect(helper.duration_in_words_es(1.hour)).to eq("1 hora")
    end

    it "renders whole minutes" do
      expect(helper.duration_in_words_es(30.minutes)).to eq("30 minutos")
      expect(helper.duration_in_words_es(1.minute)).to eq("1 minuto")
    end

    it "falls back to seconds when the duration divides into neither" do
      expect(helper.duration_in_words_es(90.seconds)).to eq("90 segundos")
    end
  end
end
