# Goal: Add VAT calculation function with configurable rates

- **Target Path Scope**: `src/billing`
- **Created At**: Fri Sep 18 21:42:00 CEST 2026

## Background & Specifications
In addition to discounts, `src/billing` needs a precise VAT (Value-Added Tax) calculation module:
- Create `src/billing/tax.py` containing `calculate_vat(gross_amount: float, vat_rate: float) -> float`.
- It must calculate the tax component included in a gross price: `tax = gross_amount * (vat_rate / (100 + vat_rate))`.
- Must handle standard decimal precision and round using `ROUND_HALF_UP` to 2 decimal places.
- Example: Gross amount `125.0` with `25%` VAT rate contains `25.0` VAT.
- Must reject negative amounts or rates by raising `ValueError`.

## Pipeline Steps
1. **RED**: Create `src/billing/test_tax.py` reproducing all test cases and verifying they fail.
2. **GREEN**: Implement `src/billing/tax.py` using `Decimal` and `ROUND_HALF_UP` to pass tests.
3. **REFACTOR**: Parametrize standard VAT rates (e.g. 25%, 12%, 6%, 0%) using `@pytest.mark.parametrize`.

## End Condition
- Tests in `src/billing/test_tax.py` pass with 100% GREEN.
