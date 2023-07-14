# frozen_string_literal: true

RSpec.describe OT::WrappedOperation do
  describe "#apply" do
    it "composes sequential operations" do
      op1 = OT::TextOperation::Builder.replace("hoge", from: 2, insert: "ho")

      wop1 = OT::WrappedOperation.new(op1, nil)

      expect(wop1).to be_operation.from("hoge").to("hohoge")
    end
  end

  describe "#compose" do
    context "meta is nil" do
      it "composes operation and meta (be the meta of the second operation)" do
        op1 = OT::TextOperation::Builder.replace("hoge", from: 2, insert: "ho")
        op2 = OT::TextOperation::Builder.replace("hohoge", from: 3, delete: "o", insert: "i")

        wop1 = OT::WrappedOperation.new(op1, nil)
        wop2 = OT::WrappedOperation.new(op2, :another)

        expect(wop1.compose(wop2)).to be_operation.from("hoge").to("hohige")
        expect(wop1.compose(wop2).meta).to be(:another)
      end
    end

    context "meta has compose method" do
      it "composes operation and meta (compose by using the method)" do
        op1 = OT::TextOperation::Builder.replace("hoge", from: 2, insert: "ho")
        op2 = OT::TextOperation::Builder.replace("hohoge", from: 3, delete: "o", insert: "i")

        meta = Object.new.tap do |o|
          o.define_singleton_method :compose do |another|
            "composed_#{another}".to_sym
          end
        end

        wop1 = OT::WrappedOperation.new(op1, meta)
        wop2 = OT::WrappedOperation.new(op2, :another)

        expect(wop1.compose(wop2)).to be_operation.from("hoge").to("hohige")
        expect(wop1.compose(wop2).meta).to be(:composed_another)
      end
    end
  end

  describe ".transform" do
    context "meta is nil" do
      it "transforms operations to be consistent" do
        base_text = "hoge"
        op1 = OT::TextOperation::Builder.replace(base_text, from: 3, insert: "g")
        op2 = OT::TextOperation::Builder.replace(base_text, from: 2, insert: "o")

        wop1 = OT::WrappedOperation.new(op1, nil)
        wop2 = OT::WrappedOperation.new(op2, :another)
        wop1t, wop2t = OT::WrappedOperation.transform(wop1, wop2)

        expect(wop2.compose(wop1t)).to be_operation.from("hoge").to("hoogge")
        expect(wop1.compose(wop2t)).to be_operation.from("hoge").to("hoogge")

        expect(wop1t.meta).to be_nil
        expect(wop2t.meta).to be(:another)
      end
    end

    context "meta has transform method" do
      it "transforms operations to be consistent" do
        base_text = "hoge"
        op1 = OT::TextOperation::Builder.replace(base_text, from: 3, insert: "g")
        op2 = OT::TextOperation::Builder.replace(base_text, from: 2, insert: "o")

        meta1 = Object.new.tap do |o|
          o.define_singleton_method :transform do |another_wop|
            "composed_meta1_#{another_wop.wrapped.ops}"
          end
        end

        wop1 = OT::WrappedOperation.new(op1, meta1)
        wop2 = OT::WrappedOperation.new(op2, :another)
        wop1t, wop2t = OT::WrappedOperation.transform(wop1, wop2)

        expect(wop2.compose(wop1t)).to be_operation.from("hoge").to("hoogge")
        expect(wop1.compose(wop2t)).to be_operation.from("hoge").to("hoogge")

        expect(wop1t.meta).to eq('composed_meta1_[2, "o", 2]')
        expect(wop2t.meta).to be(:another)
      end
    end

    context "operations are wrapped multiple times" do
      it "transforms operations to be consistent" do
        base_text = "hoge"
        op1 = OT::TextOperation::Builder.replace(base_text, from: 3, insert: "g")
        op2 = OT::TextOperation::Builder.replace(base_text, from: 2, insert: "o")

        meta1 = Object.new.tap do |o|
          o.define_singleton_method :transform do |another_wop|
            "composed_meta1_#{another_wop.wrapped.ops}"
          end
        end

        meta1_1 = Object.new.tap do |o|
          o.define_singleton_method :transform do |another_wop|
            "composed_meta1_1_#{another_wop.wrapped.wrapped.ops}"
          end
        end

        wop1 = OT::WrappedOperation.new(op1, meta1)
        wop2 = OT::WrappedOperation.new(op2, :another)

        wwop1 = OT::WrappedOperation.new(wop1, meta1_1)
        wwop2 = OT::WrappedOperation.new(wop2, :another_w)

        wwop1t, wwop2t = OT::WrappedOperation.transform(wwop1, wwop2)

        expect(wwop2.compose(wwop1t)).to be_operation.from("hoge").to("hoogge")
        expect(wwop1.compose(wwop2t)).to be_operation.from("hoge").to("hoogge")

        expect(wwop1t.meta).to eq('composed_meta1_1_[2, "o", 2]')
        expect(wwop2t.meta).to be(:another_w)

        expect(wwop1t.wrapped.meta).to eq('composed_meta1_[2, "o", 2]')
        expect(wwop2t.wrapped.meta).to be(:another)
      end
    end
  end
end
