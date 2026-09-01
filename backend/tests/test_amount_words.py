import unittest
from app.utils.amount_words import number_to_words_inr


class TestAmountWords(unittest.TestCase):
    def test_zero(self):
        self.assertEqual(number_to_words_inr(0), "Rupees Zero Only")

    def test_round_hundreds(self):
        self.assertEqual(number_to_words_inr(100), "Rupees One Hundred Only")

    def test_thousands(self):
        self.assertEqual(number_to_words_inr(12500), "Rupees Twelve Thousand Five Hundred Only")

    def test_lakh(self):
        self.assertEqual(number_to_words_inr(100000), "Rupees One Lakh Only")

    def test_crore(self):
        self.assertEqual(number_to_words_inr(10000000), "Rupees One Crore Only")

    def test_complex(self):
        result = number_to_words_inr(1234567)
        self.assertIn("Lakh", result)
        self.assertIn("Thousand", result)

    def test_with_paise(self):
        result = number_to_words_inr(1500.50)
        self.assertIn("Fifty Paise", result)

    def test_negative(self):
        self.assertEqual(number_to_words_inr(-100), "Rupees Zero Only")


if __name__ == "__main__":
    unittest.main()
