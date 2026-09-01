"""
Amount to words in Indian currency format.
Supports Rupees with Paise.
"""


ONES = [
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
    "Seventeen", "Eighteen", "Nineteen"
]

TENS = [
    "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
]


def _two_digits(n: int) -> str:
    if n < 20:
        return ONES[n]
    return (TENS[n // 10] + (" " + ONES[n % 10] if n % 10 else "")).strip()


def _three_digits(n: int) -> str:
    if n >= 100:
        h = ONES[n // 100] + " Hundred"
        rest = n % 100
        return (h + " " + _two_digits(rest)).strip() if rest else h
    return _two_digits(n)


def number_to_words_inr(amount: float) -> str:
    """Convert a rupee amount to Indian words. e.g. 12500 -> 'Rupees Twelve Thousand Five Hundred Only'"""
    if amount < 0:
        return "Rupees Zero Only"

    rupees = int(amount)
    paise = round((amount - rupees) * 100)

    if rupees == 0 and paise == 0:
        return "Rupees Zero Only"

    parts = []

    crore = rupees // 10_000_000
    rupees %= 10_000_000

    lakh = rupees // 100_000
    rupees %= 100_000

    thousand = rupees // 1_000
    rupees %= 1_000

    remainder = rupees

    if crore:
        parts.append(_three_digits(crore) + " Crore")
    if lakh:
        parts.append(_three_digits(lakh) + " Lakh")
    if thousand:
        parts.append(_three_digits(thousand) + " Thousand")
    if remainder:
        parts.append(_three_digits(remainder))

    rupee_words = "Rupees " + " ".join(parts) if parts else "Rupees Zero"

    if paise:
        paise_words = " and " + _two_digits(paise) + " Paise"
        return rupee_words + paise_words + " Only"

    return rupee_words + " Only"
