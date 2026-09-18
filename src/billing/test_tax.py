import pytest
from src.billing.tax import calculate_vat

@pytest.mark.parametrize(
    "gross_amount,vat_rate,expected_vat",
    [
        (125.0, 25.0, 25.0),
        (100.0, 12.0, 10.71),
        (100.0, 6.0, 5.66),
        (100.0, 0.0, 0.0),
        (0.575, 15.0, 0.08),
        (0.0, 25.0, 0.0),
    ]
)
def test_calculate_vat_valid(gross_amount, vat_rate, expected_vat):
    assert calculate_vat(gross_amount, vat_rate) == expected_vat

@pytest.mark.parametrize(
    "gross_amount,vat_rate",
    [
        (-100.0, 25.0),
        (100.0, -5.0),
        (-50.0, -10.0),
    ]
)
def test_calculate_vat_invalid_raises_error(gross_amount, vat_rate):
    with pytest.raises(ValueError):
        calculate_vat(gross_amount, vat_rate)
