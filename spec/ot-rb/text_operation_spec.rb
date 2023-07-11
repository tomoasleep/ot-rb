# frozen_string_literal: true

RSpec.describe OT::TextOperation do
  describe "#compose" do
    it "composes sequential operations" do
      op1 = OT::TextOperation::Builder.replace("hoge", from: 2, insert: "ho")
      op2 = OT::TextOperation::Builder.replace("hohoge", from: 3, delete: "o", insert: "i")

      expect(op1.compose(op2)).to be_operation.from("hoge").to("hohige")
    end
  end

  describe ".transform" do
    subject { OT::TextOperation.transform(op1, op2) }

    context "op2 insert text before op1" do
      let(:base_text) { "hoge" }
      let(:op1) { OT::TextOperation::Builder.replace(base_text, from: 3, insert: "g") }
      let(:op2) { OT::TextOperation::Builder.replace(base_text, from: 2, insert: "o") }

      it "transforms operations to be consistent" do
        op1t, op2t = subject

        expect(op2.compose(op1t)).to be_operation.from("hoge").to("hoogge")
        expect(op1.compose(op2t)).to be_operation.from("hoge").to("hoogge")
      end
    end

    context "op2 insert text the same position with op1" do
      let(:base_text) { "hoge" }
      let(:op1) { OT::TextOperation::Builder.replace(base_text, from: 2, insert: "bo") }
      let(:op2) { OT::TextOperation::Builder.replace(base_text, from: 2, insert: "yo") }

      it "transforms operations to be consistent (later one is former)" do
        op1t, op2t = subject

        expect(op2.compose(op1t)).to be_operation.from("hoge").to("hoboyoge")
        expect(op1.compose(op2t)).to be_operation.from("hoge").to("hoboyoge")
      end
    end

    context "op2 delete text op1 is inserting into" do
      let(:base_text) { "hoge" }
      let(:op1) { OT::TextOperation::Builder.replace(base_text, from: 2, delete: "ge", insert: "bo") }
      let(:op2) { OT::TextOperation::Builder.replace(base_text, from: 1, insert: "yo") }

      it "transforms operations to be consistent (later one is former)" do
        op1t, op2t = subject

        expect(op2.compose(op1t)).to be_operation.from("hoge").to("hyoobo")
        expect(op1.compose(op2t)).to be_operation.from("hoge").to("hyoobo")
      end
    end

    context "op2 delete text op1 is inserting after" do
      let(:base_text) { "hoge" }
      let(:op1) { OT::TextOperation::Builder.replace(base_text, from: 2, delete: "ge", insert: "bo") }
      let(:op2) { OT::TextOperation::Builder.replace(base_text, from: 2, insert: "yo") }

      it "transforms operations to be consistent (later one is former)" do
        op1t, op2t = subject

        expect(op2.compose(op1t)).to be_operation.from("hoge").to("hoboyo")
        expect(op1.compose(op2t)).to be_operation.from("hoge").to("hoboyo")
      end
    end

    context "op2 delete text op1 is inserting into" do
      let(:base_text) { "hoge" }
      let(:op1) { OT::TextOperation::Builder.replace(base_text, from: 2, delete: "ge", insert: "bo") }
      let(:op2) { OT::TextOperation::Builder.replace(base_text, from: 3, insert: "yo") }

      it "transforms operations to be consistent (later one is former)" do
        op1t, op2t = subject

        expect(op2.compose(op1t)).to be_operation.from("hoge").to("hoboyo")
        expect(op1.compose(op2t)).to be_operation.from("hoge").to("hoboyo")
      end
    end
  end
end
