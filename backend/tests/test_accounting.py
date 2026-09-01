import unittest
from app.services.accounting import (
    bank_balance_from_txns,
    cash_balance_for_staff_from_txns,
    totals_for_staff,
)


class MockTxn:
    def __init__(self, type_, amount, mode=None, direction=None, staff_id="s1"):
        self.type = type_
        self.amount = amount
        self.mode = mode
        self.direction = direction
        self.staff_id = staff_id


class TestAccounting(unittest.TestCase):
    def test_bank_balance_tax_bank(self):
        txns = [MockTxn("tax", 1000, mode="bank")]
        self.assertEqual(bank_balance_from_txns(5000, txns), 6000)

    def test_bank_balance_donation_bank(self):
        txns = [MockTxn("donation", 500, mode="bank")]
        self.assertEqual(bank_balance_from_txns(5000, txns), 5500)

    def test_bank_balance_expense_bank(self):
        txns = [MockTxn("expense", 200, mode="bank")]
        self.assertEqual(bank_balance_from_txns(5000, txns), 4800)

    def test_bank_balance_transfer_deposit(self):
        txns = [MockTxn("transfer", 1000, direction="deposit")]
        self.assertEqual(bank_balance_from_txns(5000, txns), 6000)

    def test_bank_balance_transfer_withdraw(self):
        txns = [MockTxn("transfer", 1000, direction="withdraw")]
        self.assertEqual(bank_balance_from_txns(5000, txns), 4000)

    def test_cash_balance_holder_gets_opening(self):
        txns = [MockTxn("tax", 500, mode="cash")]
        self.assertEqual(cash_balance_for_staff_from_txns(2000, True, txns), 2500)

    def test_cash_balance_non_holder_starts_zero(self):
        txns = [MockTxn("tax", 500, mode="cash")]
        self.assertEqual(cash_balance_for_staff_from_txns(2000, False, txns), 500)

    def test_cash_balance_expense_reduces(self):
        txns = [MockTxn("expense", 300, mode="cash")]
        self.assertEqual(cash_balance_for_staff_from_txns(1000, True, txns), 700)

    def test_cash_balance_deposit_reduces(self):
        txns = [MockTxn("transfer", 500, direction="deposit")]
        self.assertEqual(cash_balance_for_staff_from_txns(1000, True, txns), 500)

    def test_cash_balance_withdraw_increases(self):
        txns = [MockTxn("transfer", 500, direction="withdraw")]
        self.assertEqual(cash_balance_for_staff_from_txns(1000, True, txns), 1500)

    def test_totals_for_staff(self):
        txns = [
            MockTxn("tax", 1000),
            MockTxn("tax", 500),
            MockTxn("donation", 2000),
            MockTxn("expense", 300),
        ]
        result = totals_for_staff(txns)
        self.assertEqual(result["tax"], 1500)
        self.assertEqual(result["donation"], 2000)
        self.assertEqual(result["expense"], 300)
        self.assertEqual(result["income"], 3500)
        self.assertEqual(result["net"], 3200)

    def test_bank_mode_tax_does_not_affect_cash(self):
        txns = [MockTxn("tax", 1000, mode="bank")]
        self.assertEqual(cash_balance_for_staff_from_txns(500, True, txns), 500)


if __name__ == "__main__":
    unittest.main()
