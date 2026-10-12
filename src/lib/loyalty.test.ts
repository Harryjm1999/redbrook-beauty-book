import { describe, expect, it } from "vitest";
import { pointsForSpend, progressToNext, vouchersFor } from "./loyalty";

describe("loyalty rules", () => {
  it("earns 1 point per £3, rounded down", () => {
    expect(pointsForSpend(300)).toBe(100);
    expect(pointsForSpend(10)).toBe(3);
  });
  it("100 points = one £10 voucher", () => {
    expect(vouchersFor(250)).toBe(2);
    expect(vouchersFor(99)).toBe(0);
  });
  it("progress to next voucher", () => {
    expect(progressToNext(160)).toBe(60);
  });
});
