from decimal import Decimal, ROUND_HALF_UP

def calculate_discount(price: float, discount_percent: float) -> float:
    """
    Calculate the discount amount correctly using Decimal and ROUND_HALF_UP.
    """
    price_dec = Decimal(str(price))
    discount_dec = Decimal(str(discount_percent)) / Decimal('100')
    discount_amount = price_dec * discount_dec
    # Round to 2 decimal places using ROUND_HALF_UP
    rounded_discount = discount_amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    return float(rounded_discount)
