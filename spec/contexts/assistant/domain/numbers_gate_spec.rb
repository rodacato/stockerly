require "rails_helper"

RSpec.describe Assistant::Domain::NumbersGate do
  let(:context) do
    <<~CONTEXT
      [1] NVDA · precio USD 187.42 · cambio del día +1.2% · as_of 2026-10-21
      [2] RSI(14) 72.4 · zona de sobrecompra por encima de 70 · as_of 2026-10-20
      [3] Patrimonio MXN 236,800
    CONTEXT
  end

  def gate(answer, ctx = context) = described_class.call(answer: answer, context: ctx)

  it "accepts an answer that states only figures from its context" do
    result = gate("El RSI(14) de NVDA está en 72.4 [2], por encima de 70 [2]; hoy cotiza en USD 187.42 [1].")

    expect(result).to be_ok
  end

  it "rejects an invented figure and names it" do
    result = gate("NVDA cotiza en USD 909 [1] y su RSI está en 72.4 [2].")

    expect(result).not_to be_ok
    expect(result.invented).to eq([ "909" ])
  end

  it "rejects a figure the model derived rather than retrieved" do
    expect(gate("Está 2.4 puntos por encima del umbral de 70.").invented).to eq([ "2.4" ])
  end

  it "does not count citation markers as figures" do
    expect(gate("Sube [1], y el RSI está alto [2] [3].")).to be_ok
  end

  it "reads a thousands separator and its absence as the same figure" do
    expect(gate("Tu patrimonio es de MXN 236800.")).to be_ok
  end

  it "matches a percentage against the bare figure" do
    expect(gate("Subió 1.2% en el día [1].")).to be_ok
  end

  it "rejects every figure when the context holds none" do
    expect(gate("El RSI está en 72.4.", "").invented).to eq([ "72.4" ])
  end
end
