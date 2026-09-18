from decimal import Decimal, ROUND_HALF_UP

def calculate_vat(gross_amount: float, vat_rate: float) -> float:
    """Calculate the tax component included in a gross price.
    
    tax = gross_amount * (vat_rate / (100 + vat_rate))
    """
    if gross_amount < 0:
        raise ValueError("Gross amount must be non-negative.")
    if vat_rate < 0:
        raise ValueError("VAT rate must be non-negative.")
        
    g = Decimal(str(gross_amount))
    r = Decimal(str(vat_rate))
    
    tax = (g * r) / (Decimal("100") + r)
    rounded = tax.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    return float(rounded)
