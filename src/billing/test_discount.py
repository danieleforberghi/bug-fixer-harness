import pytest
from src.billing.discount import calculate_discount

@pytest.mark.parametrize(
    "price, discount_percent, expected_discount",
    [
        (10.70, 25.0, 2.68),
        (0.15, 10.0, 0.02),
        (1.15, 10.0, 0.12),
        (100.0, 15.0, 15.00),
        (10.25, 15.0, 1.54),
    ]
)
def test_discount_rounding_parametrized(price, discount_percent, expected_discount):
    assert calculate_discount(price, discount_percent) == expected_discount
