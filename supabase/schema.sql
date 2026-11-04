-- ========================================================
-- WAREHOUSE MANAGEMENT SYSTEM (WMS) - SUPABASE SCHEMA
-- Platform: Flutter Mobile & Supabase PostgreSQL
-- ========================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- --------------------------------------------------------
-- 1. PROFILES TABLE (Linked with auth.users)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('admin', 'staff')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
DROP POLICY IF EXISTS "Public profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Public profiles are viewable by authenticated users"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Trigger to auto-create profile upon auth.users signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', 'Staf Gudang'),
        COALESCE(new.raw_user_meta_data->>'role', 'staff')
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        role = EXCLUDED.role;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- --------------------------------------------------------
-- 2. CATEGORIES TABLE
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Categories are viewable by authenticated users" ON public.categories;
CREATE POLICY "Categories are viewable by authenticated users"
ON public.categories FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Categories can be inserted by authenticated users" ON public.categories;
CREATE POLICY "Categories can be inserted by authenticated users"
ON public.categories FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Categories can be updated by authenticated users" ON public.categories;
CREATE POLICY "Categories can be updated by authenticated users"
ON public.categories FOR UPDATE
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Categories can be deleted by authenticated users" ON public.categories;
CREATE POLICY "Categories can be deleted by authenticated users"
ON public.categories FOR DELETE
TO authenticated
USING (true);


-- --------------------------------------------------------
-- 3. PRODUCTS TABLE
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    category_id BIGINT REFERENCES public.categories(id) ON DELETE SET NULL,
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    min_stock INTEGER NOT NULL DEFAULT 5 CHECK (min_stock >= 0),
    location TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_products_sku ON public.products(sku);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Products are viewable by authenticated users" ON public.products;
CREATE POLICY "Products are viewable by authenticated users"
ON public.products FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Products can be inserted by authenticated users" ON public.products;
CREATE POLICY "Products can be inserted by authenticated users"
ON public.products FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Products can be updated by authenticated users" ON public.products;
CREATE POLICY "Products can be updated by authenticated users"
ON public.products FOR UPDATE
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Products can be deleted by authenticated users" ON public.products;
CREATE POLICY "Products can be deleted by authenticated users"
ON public.products FOR DELETE
TO authenticated
USING (true);


-- --------------------------------------------------------
-- 4. STOCK TRANSACTIONS TABLE
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.stock_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('IN', 'OUT')),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_stock_transactions_product ON public.stock_transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_transactions_created_at ON public.stock_transactions(created_at DESC);

ALTER TABLE public.stock_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Transactions viewable by authenticated users" ON public.stock_transactions;
CREATE POLICY "Transactions viewable by authenticated users"
ON public.stock_transactions FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Transactions insertable by authenticated users" ON public.stock_transactions;
CREATE POLICY "Transactions insertable by authenticated users"
ON public.stock_transactions FOR INSERT
TO authenticated
WITH CHECK (true);


-- --------------------------------------------------------
-- 5. ATOMIC STORED PROCEDURE: RECORD STOCK TRANSACTION (IN/OUT)
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_stock_transaction(
    p_product_id UUID,
    p_type TEXT,
    p_quantity INTEGER,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_stock INTEGER;
    v_product_name TEXT;
    v_new_stock INTEGER;
    v_user_id UUID;
    v_transaction_id UUID;
BEGIN
    -- Validate type
    IF p_type NOT IN ('IN', 'OUT') THEN
        RAISE EXCEPTION 'Tipe transaksi tidak valid. Harus IN atau OUT.';
    END IF;

    -- Validate quantity
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Jumlah kuantitas harus lebih besar dari 0.';
    END IF;

    v_user_id := auth.uid();

    -- Lock product row for atomic stock update
    SELECT stock, name INTO v_current_stock, v_product_name
    FROM public.products
    WHERE id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Barang dengan ID % tidak ditemukan.', p_product_id;
    END IF;

    -- Calculate new stock
    IF p_type = 'IN' THEN
        v_new_stock := v_current_stock + p_quantity;
    ELSE
        IF v_current_stock < p_quantity THEN
            RAISE EXCEPTION 'Stok tidak mencukupi. Stok saat ini: %, permintaan keluar: %.', v_current_stock, p_quantity;
        END IF;
        v_new_stock := v_current_stock - p_quantity;
    END IF;

    -- Update stock in products table
    UPDATE public.products
    SET stock = v_new_stock
    WHERE id = p_product_id;

    -- Insert into stock_transactions
    INSERT INTO public.stock_transactions (
        product_id,
        user_id,
        type,
        quantity,
        notes
    ) VALUES (
        p_product_id,
        v_user_id,
        p_type,
        p_quantity,
        p_notes
    ) RETURNING id INTO v_transaction_id;

    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'product_id', p_product_id,
        'product_name', v_product_name,
        'previous_stock', v_current_stock,
        'new_stock', v_new_stock,
        'type', p_type,
        'quantity', p_quantity
    );
END;
$$;


-- --------------------------------------------------------
-- 6. SEED DATA (Kategori & Contoh Barang Awal)
-- --------------------------------------------------------
INSERT INTO public.categories (name)
VALUES 
    ('Elektronik'),
    ('Bahan Baku'),
    ('Kemasan & Packing'),
    ('Peralatan Gudang'),
    ('Suku Cadang')
ON CONFLICT (name) DO NOTHING;

-- Sisipkan beberapa produk contoh jika belum ada
INSERT INTO public.products (sku, name, category_id, stock, min_stock, location)
VALUES 
    ('ELK-001', 'Scanner Barcode Wireless 2.4G', (SELECT id FROM public.categories WHERE name = 'Elektronik' LIMIT 1), 15, 5, 'Rak A-01'),
    ('ELK-002', 'Printer Label Thermal Bluetooth 58mm', (SELECT id FROM public.categories WHERE name = 'Elektronik' LIMIT 1), 8, 3, 'Rak A-02'),
    ('KMS-001', 'Kardus Box Single Wall 20x20x10', (SELECT id FROM public.categories WHERE name = 'Kemasan & Packing' LIMIT 1), 250, 50, 'Rak B-01'),
    ('KMS-002', 'Bubble Wrap Tebal 50m x 1.25m', (SELECT id FROM public.categories WHERE name = 'Kemasan & Packing' LIMIT 1), 4, 10, 'Rak B-02'),
    ('PRL-001', 'Hand Pallet Truck Hydraulic 3 Ton', (SELECT id FROM public.categories WHERE name = 'Peralatan Gudang' LIMIT 1), 2, 1, 'Zona C-Utama'),
    ('PRL-002', 'Lakban Bening Daimaru 2 Inch', (SELECT id FROM public.categories WHERE name = 'Kemasan & Packing' LIMIT 1), 3, 20, 'Rak B-03')
ON CONFLICT (sku) DO NOTHING;


-- --------------------------------------------------------
-- 7. CHECK IF USER EMAIL EXISTS (For client login validation)
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_user_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth.users WHERE LOWER(email) = LOWER(TRIM(p_email))
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_user_exists(TEXT) TO anon, authenticated;

