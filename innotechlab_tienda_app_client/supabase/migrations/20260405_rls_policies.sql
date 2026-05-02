-- RLS Security Policies
-- Enable Row Level Security on tables used by the app

-- Enable RLS on sales table
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- Enable RLS on payment_transactions table
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Enable RLS on sale_items table
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;

-- Enable RLS on drivers table
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Enable RLS on products table
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own sales
CREATE POLICY "Users can view own sales" ON sales
  FOR SELECT
  USING (customer_id = auth.uid());

-- Policy: Users can only view their own payment transactions
CREATE POLICY "Users can view own transactions" ON payment_transactions
  FOR SELECT
  USING (
    sale_id IN (
      SELECT id FROM sales WHERE customer_id = auth.uid()
    )
  );

-- Policy: Users can only view sale items from their own sales
CREATE POLICY "Users can view own sale items" ON sale_items
  FOR SELECT
  USING (
    sale_id IN (
      SELECT id FROM sales WHERE customer_id = auth.uid()
    )
  );

-- Policy: Users can view driver info only for their own orders
CREATE POLICY "Users can view drivers for own orders" ON drivers
  FOR SELECT
  USING (
    id IN (
      SELECT driver_id FROM sales WHERE customer_id = auth.uid()
    )
  );

-- Policy: Products are readable by everyone (public catalog)
CREATE POLICY "Products are public" ON products
  FOR SELECT
  USING (true);

-- Policy: Sale items are readable if the sale is accessible
CREATE POLICY "Sale items accessible via sales" ON sale_items
  FOR SELECT
  USING (
    sale_id IN (
      SELECT id FROM sales WHERE customer_id = auth.uid()
    )
  );