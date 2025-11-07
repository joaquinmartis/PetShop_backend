--
-- PostgreSQL database dump
--

-- Dumped from database version 14.19 (Ubuntu 14.19-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.19 (Ubuntu 14.19-0ubuntu0.22.04.1)
-- Modified for Virtual Pet E-Commerce initialization

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cart; Type: SCHEMA; Schema: -; Owner: virtualpet_user
--

CREATE SCHEMA IF NOT EXISTS cart;

ALTER SCHEMA cart OWNER TO virtualpet_user;

--
-- Name: order_management; Type: SCHEMA; Schema: -; Owner: virtualpet_user
--

CREATE SCHEMA IF NOT EXISTS order_management;

ALTER SCHEMA order_management OWNER TO virtualpet_user;

--
-- Name: product_catalog; Type: SCHEMA; Schema: -; Owner: virtualpet_user
--

CREATE SCHEMA IF NOT EXISTS product_catalog;

ALTER SCHEMA product_catalog OWNER TO virtualpet_user;

--
-- Name: user_management; Type: SCHEMA; Schema: -; Owner: virtualpet_user
--

CREATE SCHEMA IF NOT EXISTS user_management;

ALTER SCHEMA user_management OWNER TO virtualpet_user;

--
-- Name: update_cart_timestamp(); Type: FUNCTION; Schema: cart; Owner: virtualpet_user
--

CREATE OR REPLACE FUNCTION cart.update_cart_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE cart.carts
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.cart_id, OLD.cart_id);
    RETURN COALESCE(NEW, OLD);
END;
$$;

ALTER FUNCTION cart.update_cart_timestamp() OWNER TO virtualpet_user;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: cart; Owner: virtualpet_user
--

CREATE OR REPLACE FUNCTION cart.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

ALTER FUNCTION cart.update_updated_at_column() OWNER TO virtualpet_user;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: order_management; Owner: virtualpet_user
--

CREATE OR REPLACE FUNCTION order_management.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

ALTER FUNCTION order_management.update_updated_at_column() OWNER TO virtualpet_user;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: product_catalog; Owner: virtualpet_user
--

CREATE OR REPLACE FUNCTION product_catalog.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

ALTER FUNCTION product_catalog.update_updated_at_column() OWNER TO virtualpet_user;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: user_management; Owner: virtualpet_user
--

CREATE OR REPLACE FUNCTION user_management.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

ALTER FUNCTION user_management.update_updated_at_column() OWNER TO virtualpet_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cart_items; Type: TABLE; Schema: cart; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS cart.cart_items (
    id bigint NOT NULL,
    cart_id bigint NOT NULL,
    product_id bigint NOT NULL,
    quantity integer NOT NULL,
    unit_price_snapshot numeric(10,2) NOT NULL,
    product_name_snapshot character varying(150) NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cart_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT cart_items_unit_price_snapshot_check CHECK ((unit_price_snapshot >= (0)::numeric))
);

ALTER TABLE cart.cart_items OWNER TO virtualpet_user;

--
-- Name: cart_items_id_seq; Type: SEQUENCE; Schema: cart; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS cart.cart_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE cart.cart_items_id_seq OWNER TO virtualpet_user;

--
-- Name: cart_items_id_seq; Type: SEQUENCE OWNED BY; Schema: cart; Owner: virtualpet_user
--

ALTER SEQUENCE cart.cart_items_id_seq OWNED BY cart.cart_items.id;

--
-- Name: carts; Type: TABLE; Schema: cart; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS cart.carts (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE cart.carts OWNER TO virtualpet_user;

--
-- Name: carts_id_seq; Type: SEQUENCE; Schema: cart; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS cart.carts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE cart.carts_id_seq OWNER TO virtualpet_user;

--
-- Name: carts_id_seq; Type: SEQUENCE OWNED BY; Schema: cart; Owner: virtualpet_user
--

ALTER SEQUENCE cart.carts_id_seq OWNED BY cart.carts.id;

--
-- Name: order_items; Type: TABLE; Schema: order_management; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS order_management.order_items (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_name_snapshot character varying(150) NOT NULL,
    product_image_snapshot character varying(255),
    quantity integer NOT NULL,
    unit_price_snapshot numeric(10,2) NOT NULL,
    subtotal numeric(10,2) GENERATED ALWAYS AS (((quantity)::numeric * unit_price_snapshot)) STORED,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT order_items_unit_price_snapshot_check CHECK ((unit_price_snapshot >= (0)::numeric))
);

ALTER TABLE order_management.order_items OWNER TO virtualpet_user;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: order_management; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS order_management.order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE order_management.order_items_id_seq OWNER TO virtualpet_user;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: order_management; Owner: virtualpet_user
--

ALTER SEQUENCE order_management.order_items_id_seq OWNED BY order_management.order_items.id;

--
-- Name: order_status_history; Type: TABLE; Schema: order_management; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS order_management.order_status_history (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    from_status character varying(50),
    to_status character varying(50) NOT NULL,
    changed_by_user_id bigint,
    changed_by_role character varying(20),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT order_status_history_changed_by_role_check CHECK (((changed_by_role)::text = ANY ((ARRAY['CLIENT'::character varying, 'WAREHOUSE'::character varying, 'SYSTEM'::character varying])::text[])))
);

ALTER TABLE order_management.order_status_history OWNER TO virtualpet_user;

--
-- Name: TABLE order_status_history; Type: COMMENT; Schema: order_management; Owner: virtualpet_user
--

COMMENT ON TABLE order_management.order_status_history IS 'Historial de cambios de estado de pedidos (auditoría)';

--
-- Name: order_status_history_id_seq; Type: SEQUENCE; Schema: order_management; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS order_management.order_status_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE order_management.order_status_history_id_seq OWNER TO virtualpet_user;

--
-- Name: order_status_history_id_seq; Type: SEQUENCE OWNED BY; Schema: order_management; Owner: virtualpet_user
--

ALTER SEQUENCE order_management.order_status_history_id_seq OWNED BY order_management.order_status_history.id;

--
-- Name: orders; Type: TABLE; Schema: order_management; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS order_management.orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    status character varying(50) NOT NULL,
    total numeric(10,2) NOT NULL,
    shipping_method character varying(20),
    shipping_id bigint,
    shipping_address text NOT NULL,
    customer_name character varying(200) NOT NULL,
    customer_email character varying(100),
    customer_phone character varying(20),
    notes text,
    cancellation_reason character varying(200),
    cancelled_at timestamp without time zone,
    cancelled_by character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT check_cancellation_consistency CHECK (((((status)::text = 'CANCELLED'::text) AND (cancellation_reason IS NOT NULL) AND (cancelled_at IS NOT NULL)) OR (((status)::text <> 'CANCELLED'::text) AND (cancellation_reason IS NULL) AND (cancelled_at IS NULL)))),
    CONSTRAINT check_shipping_method CHECK (((shipping_method IS NULL) OR ((shipping_method)::text = ANY ((ARRAY['OWN_TEAM'::character varying, 'COURIER'::character varying])::text[])))),
    CONSTRAINT check_status_values CHECK (((status)::text = ANY ((ARRAY['PENDING_VALIDATION'::character varying, 'CONFIRMED'::character varying, 'READY_TO_SHIP'::character varying, 'SHIPPED'::character varying, 'DELIVERED'::character varying, 'CANCELLED'::character varying])::text[]))),
    CONSTRAINT orders_cancelled_by_check CHECK (((cancelled_by)::text = ANY ((ARRAY['CLIENT'::character varying, 'WAREHOUSE'::character varying, 'SYSTEM'::character varying])::text[]))),
    CONSTRAINT orders_total_check CHECK ((total >= (0)::numeric))
);

ALTER TABLE order_management.orders OWNER TO virtualpet_user;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: order_management; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS order_management.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE order_management.orders_id_seq OWNER TO virtualpet_user;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: order_management; Owner: virtualpet_user
--

ALTER SEQUENCE order_management.orders_id_seq OWNED BY order_management.orders.id;

--
-- Name: categories; Type: TABLE; Schema: product_catalog; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS product_catalog.categories (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE product_catalog.categories OWNER TO virtualpet_user;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: product_catalog; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS product_catalog.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE product_catalog.categories_id_seq OWNER TO virtualpet_user;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: product_catalog; Owner: virtualpet_user
--

ALTER SEQUENCE product_catalog.categories_id_seq OWNED BY product_catalog.categories.id;

--
-- Name: products; Type: TABLE; Schema: product_catalog; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS product_catalog.products (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    stock integer DEFAULT 0 NOT NULL,
    category_id integer NOT NULL,
    image_url character varying(255),
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT products_price_check CHECK ((price >= (0)::numeric)),
    CONSTRAINT products_stock_check CHECK ((stock >= 0))
);

ALTER TABLE product_catalog.products OWNER TO virtualpet_user;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: product_catalog; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS product_catalog.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE product_catalog.products_id_seq OWNER TO virtualpet_user;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: product_catalog; Owner: virtualpet_user
--

ALTER SEQUENCE product_catalog.products_id_seq OWNED BY product_catalog.products.id;

--
-- Name: roles; Type: TABLE; Schema: user_management; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS user_management.roles (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE user_management.roles OWNER TO virtualpet_user;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: user_management; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS user_management.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE user_management.roles_id_seq OWNER TO virtualpet_user;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: user_management; Owner: virtualpet_user
--

ALTER SEQUENCE user_management.roles_id_seq OWNED BY user_management.roles.id;

--
-- Name: users; Type: TABLE; Schema: user_management; Owner: virtualpet_user
--

CREATE TABLE IF NOT EXISTS user_management.users (
    id integer NOT NULL,
    email character varying(100) NOT NULL,
    password_hash text NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    phone character varying(20) NOT NULL,
    address text NOT NULL,
    role_id integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

ALTER TABLE user_management.users OWNER TO virtualpet_user;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: user_management; Owner: virtualpet_user
--

CREATE SEQUENCE IF NOT EXISTS user_management.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE user_management.users_id_seq OWNER TO virtualpet_user;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: user_management; Owner: virtualpet_user
--

ALTER SEQUENCE user_management.users_id_seq OWNED BY user_management.users.id;

--
-- Name: cart_items id; Type: DEFAULT; Schema: cart; Owner: virtualpet_user
--

ALTER TABLE ONLY cart.cart_items ALTER COLUMN id SET DEFAULT nextval('cart.cart_items_id_seq'::regclass);

--
-- Name: carts id; Type: DEFAULT; Schema: cart; Owner: virtualpet_user
--

ALTER TABLE ONLY cart.carts ALTER COLUMN id SET DEFAULT nextval('cart.carts_id_seq'::regclass);

--
-- Name: order_items id; Type: DEFAULT; Schema: order_management; Owner: virtualpet_user
--

ALTER TABLE ONLY order_management.order_items ALTER COLUMN id SET DEFAULT nextval('order_management.order_items_id_seq'::regclass);

--
-- Name: order_status_history id; Type: DEFAULT; Schema: order_management; Owner: virtualpet_user
--

ALTER TABLE ONLY order_management.order_status_history ALTER COLUMN id SET DEFAULT nextval('order_management.order_status_history_id_seq'::regclass);

--
-- Name: orders id; Type: DEFAULT; Schema: order_management; Owner: virtualpet_user
--

ALTER TABLE ONLY order_management.orders ALTER COLUMN id SET DEFAULT nextval('order_management.orders_id_seq'::regclass);

--
-- Name: categories id; Type: DEFAULT; Schema: product_catalog; Owner: virtualpet_user
--

ALTER TABLE ONLY product_catalog.categories ALTER COLUMN id SET DEFAULT nextval('product_catalog.categories_id_seq'::regclass);

--
-- Name: products id; Type: DEFAULT; Schema: product_catalog; Owner: virtualpet_user
--

ALTER TABLE ONLY product_catalog.products ALTER COLUMN id SET DEFAULT nextval('product_catalog.products_id_seq'::regclass);

--
-- Name: roles id; Type: DEFAULT; Schema: user_management; Owner: virtualpet_user
--

ALTER TABLE ONLY user_management.roles ALTER COLUMN id SET DEFAULT nextval('user_management.roles_id_seq'::regclass);

--
-- Name: users id; Type: DEFAULT; Schema: user_management; Owner: virtualpet_user
--

ALTER TABLE ONLY user_management.users ALTER COLUMN id SET DEFAULT nextval('user_management.users_id_seq'::regclass);

--
-- Data for Name: roles; Type: TABLE DATA; Schema: user_management; Owner: virtualpet_user
--

INSERT INTO user_management.roles (id, name, description, created_at) VALUES
(1, 'CLIENT', 'Cliente que puede realizar compras en la tienda', CURRENT_TIMESTAMP),
(2, 'WAREHOUSE', 'Empleado de depósito que gestiona pedidos y envíos', CURRENT_TIMESTAMP)
ON CONFLICT (name) DO NOTHING;

--
-- Data for Name: users; Type: TABLE DATA; Schema: user_management; Owner: virtualpet_user
--

INSERT INTO user_management.users (id, email, password_hash, first_name, last_name, phone, address, role_id, is_active, created_at, updated_at) VALUES
(1, 'cliente@test.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye6J946P9xqmCqCp8e1OVQaLZKbK5e2f2', 'Cliente', 'Test', '1234567890', 'Calle Test 123, Mar del Plata', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'warehouse@test.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye6J946P9xqmCqCp8e1OVQaLZKbK5e2f2', 'Warehouse', 'Manager', '1234567890', 'Depósito Central', 2, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'juan.perez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye6J946P9xqmCqCp8e1OVQaLZKbK5e2f2', 'Juan', 'Pérez', '2234567890', 'Av. Libertador 456, Buenos Aires', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 'maria.garcia@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye6J946P9xqmCqCp8e1OVQaLZKbK5e2f2', 'María', 'García', '3334567890', 'Calle Belgrano 789, Rosario', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (email) DO NOTHING;

--
-- Data for Name: categories; Type: TABLE DATA; Schema: product_catalog; Owner: virtualpet_user
--

INSERT INTO product_catalog.categories (id, name, description, active, created_at, updated_at) VALUES
(1, 'Alimentos para perros', 'Comida balanceada, snacks y premios para perros de todas las razas y edades', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'Alimentos para gatos', 'Comida balanceada, snacks y premios para gatos de todas las razas y edades', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'Alimentos para peces', 'Alimento en escamas, pellets y tabletas para peces tropicales y de agua fría', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 'Accesorios para perros', 'Correas, collares, juguetes, cuchas y accesorios para perros', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 'Accesorios para gatos', 'Rascadores, juguetes, camas, transportadoras para gatos', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(6, 'Acuarios y accesorios', 'Peceras, filtros, plantas, decoración y accesorios para acuarios', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(7, 'Higiene y cuidado', 'Shampoos, cepillos, cortauñas y productos de higiene para mascotas', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(8, 'Juguetes', 'Juguetes interactivos, pelotas, mordedores y juguetes educativos', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (name) DO NOTHING;

--
-- Data for Name: products; Type: TABLE DATA; Schema: product_catalog; Owner: virtualpet_user
--

INSERT INTO product_catalog.products (id, name, description, price, stock, category_id, image_url, active, created_at, updated_at) VALUES
(1, 'Alimento Premium para Perros Adultos 15kg', 'Alimento balanceado premium para perros adultos de todas las razas. Contiene proteínas de alta calidad, vitaminas y minerales esenciales. Con pollo, arroz y vegetales.', 25000.00, 50, 1, '/images/products/dog-food-premium.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 'Alimento Cachorro Razas Grandes 20kg', 'Alimento especial para cachorros de razas grandes. Fórmula con DHA para desarrollo cerebral y glucosamina para articulaciones.', 32000.00, 30, 1, '/images/products/puppy-food-large.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(3, 'Snacks Dentales para Perros x10', 'Snacks que ayudan a limpiar los dientes y refrescar el aliento. Con sabor a menta. Pack x10 unidades.', 4200.00, 100, 1, '/images/products/dog-dental-snacks.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(4, 'Alimento Light para Perros 12kg', 'Alimento bajo en calorías para perros con sobrepeso. Con L-carnitina para quemar grasas. Sabor pollo y vegetales.', 22000.00, 40, 1, '/images/products/dog-food-light.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5, 'Alimento para Gatos Adultos 7.5kg', 'Alimento completo y balanceado para gatos adultos. Fórmula especial para el cuidado del tracto urinario. Con pescado y pollo.', 18000.00, 45, 2, '/images/products/cat-food.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(6, 'Alimento Gatito hasta 12 meses 3kg', 'Alimento para gatitos en crecimiento. Alto en proteínas y DHA. Con leche materna deshidratada.', 12500.00, 60, 2, '/images/products/kitten-food.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(7, 'Snacks Anti-Bolas de Pelo x50g', 'Snacks que ayudan a eliminar bolas de pelo. Con malta y fibra natural. Sabor salmón.', 3500.00, 80, 2, '/images/products/cat-hairball-snacks.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(8, 'Alimento Senior Gatos +7 años 5kg', 'Alimento especial para gatos mayores. Bajo en fósforo para cuidado renal. Rico en antioxidantes.', 16000.00, 35, 2, '/images/products/cat-senior-food.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(9, 'Alimento en Escamas Tropicales 100g', 'Alimento completo en escamas para peces tropicales. Rico en nutrientes esenciales y colores naturales.', 2500.00, 120, 3, '/images/products/fish-food-flakes.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(10, 'Pellets para Goldfish 250g', 'Pellets flotantes para goldfish y carpas. Realzan colores naturales. Fácil digestión.', 3200.00, 90, 3, '/images/products/goldfish-pellets.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(11, 'Tabletas de Fondo 100 unidades', 'Tabletas que se hunden para peces de fondo. Con espirulina y vegetales. Para corydoras y plecos.', 4500.00, 70, 3, '/images/products/bottom-tablets.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(12, 'Collar Ajustable Nylon', 'Collar de nylon resistente con hebilla de seguridad. Disponible en tallas S, M, L, XL. Varios colores.', 3500.00, 150, 4, '/images/products/dog-collar.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(13, 'Correa Extensible 5 metros', 'Correa extensible con sistema de freno. Hasta 30kg. Mango ergonómico antideslizante.', 8500.00, 80, 4, '/images/products/dog-leash-retractable.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(14, 'Pelota de Goma Maciza 7cm', 'Pelota de goma natural ultra resistente. Perfecta para mordedores fuertes. Flota en agua.', 1500.00, 200, 4, '/images/products/dog-ball.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(15, 'Cucha Acolchada Tamaño M', 'Cucha acolchada con base antideslizante. Lavable en lavarropas. 60x80cm. Para perros medianos.', 12000.00, 45, 4, '/images/products/dog-bed.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(16, 'Arnés Chaleco Acolchado', 'Arnés tipo chaleco con acolchado interno. Distribución uniforme de presión. Tallas S a XL.', 6500.00, 90, 4, '/images/products/dog-harness.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(17, 'Arena Sanitaria Aglutinante 10kg', 'Arena aglutinante con control de olores. Fácil limpieza. Baja generación de polvo.', 8500.00, 100, 5, '/images/products/cat-litter.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(18, 'Rascador Torre con Plataforma', 'Rascador de 80cm con plataforma superior y cueva inferior. Cubierto con sisal natural.', 15000.00, 30, 5, '/images/products/cat-scratching-post.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(19, 'Juguete Ratón con Hierba Gatera', 'Ratón de felpa con hierba gatera natural. Estimula el instinto de caza. Pack x3 unidades.', 1800.00, 150, 5, '/images/products/cat-mouse-toy.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(20, 'Transportadora Plástica', 'Transportadora resistente con puerta metálica. Ventilación lateral. Hasta 8kg. 48x32x28cm.', 9500.00, 50, 5, '/images/products/cat-carrier.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(21, 'Fuente de Agua Automática', 'Fuente con filtro de carbón activado. Capacidad 2 litros. Ultra silenciosa. Estimula consumo de agua.', 13500.00, 40, 5, '/images/products/cat-water-fountain.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(22, 'Acuario Completo 60 litros', 'Acuario de vidrio con tapa, filtro y LED. Medidas: 60x30x40cm. Kit completo para comenzar.', 35000.00, 20, 6, '/images/products/aquarium-60l.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(23, 'Filtro Interno 500 L/h', 'Filtro interno con esponja y carbón activado. Para acuarios de hasta 100 litros. Bajo consumo.', 8500.00, 60, 6, '/images/products/aquarium-filter.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(24, 'Planta Artificial Decorativa', 'Planta artificial realista de 25cm. Base con lastre. No requiere luz ni CO2. Segura para peces.', 2200.00, 100, 6, '/images/products/aquarium-plant.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(25, 'Termocalentador 100W', 'Termocalentador sumergible con termostato. Para acuarios de 80-120 litros. Rango 18-32°C.', 7500.00, 50, 6, '/images/products/aquarium-heater.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(26, 'Shampoo para Perros 500ml', 'Shampoo neutro para todo tipo de pelaje. Con aloe vera y avena. Hipoalergénico. PH balanceado.', 4500.00, 80, 7, '/images/products/dog-shampoo.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(27, 'Shampoo para Gatos 250ml', 'Shampoo especial para gatos. Fórmula sin lágrimas. Desenreda y da brillo. Con extracto de manzanilla.', 3800.00, 70, 7, '/images/products/cat-shampoo.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(28, 'Cepillo Deslanador', 'Cepillo con púas de acero inoxidable. Elimina pelo muerto y subpelo. Para perros y gatos de pelo largo.', 5500.00, 90, 7, '/images/products/deshedding-brush.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(29, 'Cortauñas Profesional', 'Cortauñas de acero inoxidable con protector de seguridad. Mango ergonómico. Para perros y gatos.', 3200.00, 110, 7, '/images/products/nail-clipper.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(30, 'Toallitas Húmedas x80', 'Toallitas húmedas con aloe vera. Limpian sin agua. Para patas, hocico y pelaje. Hipoalergénicas.', 2800.00, 120, 7, '/images/products/pet-wipes.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(31, 'Kong Clásico Rojo', 'Juguete rellenable ultra resistente. Perfecto para masticadores extremos. Talla M. Goma natural.', 5500.00, 100, 8, '/images/products/kong-classic.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(32, 'Pelota con Cuerda', 'Pelota de goma con cuerda de algodón. Ideal para juegos de tira y afloja. Limpia dientes.', 2200.00, 150, 8, '/images/products/ball-with-rope.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(33, 'Juguete Interactivo con Premios', 'Dispensador de premios interactivo. Estimula la inteligencia. Nivel de dificultad ajustable.', 7800.00, 60, 8, '/images/products/interactive-toy.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(34, 'Frisbee Flotante', 'Frisbee de goma suave para perros. Flota en agua. No daña dientes. Colores brillantes. 22cm.', 3500.00, 80, 8, '/images/products/dog-frisbee.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(35, 'Caña de Pescar para Gatos', 'Caña telescópica con plumas naturales. Estimula instinto de caza. Ejercicio y diversión.', 2500.00, 100, 8, '/images/products/cat-fishing-rod.jpg', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

--
-- Name: cart_items_id_seq; Type: SEQUENCE SET; Schema: cart; Owner: virtualpet_user
--

SELECT pg_catalog.setval('cart.cart_items_id_seq', 1, false);

--
-- Name: carts_id_seq; Type: SEQUENCE SET; Schema: cart; Owner: virtualpet_user
--

SELECT pg_catalog.setval('cart.carts_id_seq', 1, false);

--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: order_management; Owner: virtualpet_user
--

SELECT pg_catalog.setval('order_management.order_items_id_seq', 1, false);

--
-- Name: order_status_history_id_seq; Type: SEQUENCE SET; Schema: order_management; Owner: virtualpet_user
--

SELECT pg_catalog.setval('order_management.order_status_history_id_seq', 1, false);

--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: order_management; Owner: virtualpet_user
--

SELECT pg_catalog.setval('order_management.orders_id_seq', 1, false);

--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: product_catalog; Owner: virtualpet_user
--

SELECT pg_catalog.setval('product_catalog.categories_id_seq', 8, true);

--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: product_catalog; Owner: virtualpet_user
--

SELECT pg_catalog.setval('product_catalog.products_id_seq', 35, true);

--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: user_management; Owner: virtualpet_user
--

SELECT pg_catalog.setval('user_management.roles_id_seq', 2, true);

--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: user_management; Owner: virtualpet_user
--

SELECT pg_catalog.setval('user_management.users_id_seq', 4, true);

--
-- Name: cart_items cart_items_pkey; Type: CONSTRAINT; Schema: cart; Owner: virtualpet_user
--

ALTER TABLE ONLY cart.cart_items
    ADD CONSTRAINT cart_items_pkey PRIMARY KEY (id);

--
-- Name: carts carts_pkey; Type: CONSTRAINT; Schema: cart; Owner: virtualpet_user
--

ALTER TABLE ONLY cart.carts
    ADD CONSTRAINT carts_pkey PRIMARY KEY (id);

--
-- Name: cart_items unique_cart_product; Type: CONSTRAINT; Schema: cart; Owner: virtualpet_user
--

ALTER TABLE ONLY cart.cart_items
    ADD CONSTRAINT unique_cart_product UNIQUE (cart_id, product_id);

--
-- Name: carts unique_user_cart; Type: CONSTRAINT; Schema: cart; Owner: virtualpet_user
--

ALTER TABLE ONLY cart.carts
    ADD CONSTRAINT unique_user_cart UNIQUE (user_id);

--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: order_management; Owner: virtualpet_user
--

ALTER TABLE ONLY order_management.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);

--
-- Name: order_status_history order_status_history_pkey; Type: CONSTRAINT; Schema: order_management; Owner: virtualpet_user
--

ALTER TABLE ONLY order_management.order_status_history
    ADD CONSTRAINT order_status_history_pkey PRIMARY KEY (id);

--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: order_management; Owner: virtualpet_user
--

ALTER TABLE ONLY order_management.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);

--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: product_catalog; Owner: virtualpet_user
--

ALTER TABLE ONLY product_catalog.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);

--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: product_catalog; Owner: virtualpet_user
--

ALTER TABLE ONLY product_catalog.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);

--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: product_catalog; Owner: virtualpet_user
--

ALTER TABLE ONLY product_catalog.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);

--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: user_management; Owner: virtualpet_user
--

ALTER TABLE ONLY user_management.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);

--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: user_management; Owner: virtualpet_user
--

ALTER TABLE ONLY user_management.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);

--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: user_management; Owner: virtualpet_user
--

ALTER TABLE ONLY user_management.users
    ADD CONSTRAINT users_email_key UNIQUE (email);

--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: user_management; Owner: virtualpet_user
--

ALTER TABLE ONLY user_management.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

--
-- Name: idx_cart_items_cart_id; Type: INDEX; Schema: cart; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON cart.cart_items USING btree (cart_id);

--
-- Name: idx_cart_items_product_id; Type: INDEX; Schema: cart; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_cart_items_product_id ON cart.cart_items USING btree (product_id);

--
-- Name: idx_carts_user_id; Type: INDEX; Schema: cart; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_carts_user_id ON cart.carts USING btree (user_id);

--
-- Name: idx_order_items_order_id; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_management.order_items USING btree (order_id);

--
-- Name: idx_order_items_product_id; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_management.order_items USING btree (product_id);

--
-- Name: idx_order_status_history_created_at; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_order_status_history_created_at ON order_management.order_status_history USING btree (created_at);

--
-- Name: idx_order_status_history_order_id; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_management.order_status_history USING btree (order_id);

--
-- Name: idx_orders_cancelled_at; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_orders_cancelled_at ON order_management.orders USING btree (cancelled_at);

--
-- Name: idx_orders_created_at; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON order_management.orders USING btree (created_at);

--
-- Name: idx_orders_shipping_id; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_orders_shipping_id ON order_management.orders USING btree (shipping_id);

--
-- Name: idx_orders_status; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_orders_status ON order_management.orders USING btree (status);

--
-- Name: idx_orders_user_id; Type: INDEX; Schema: order_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON order_management.orders USING btree (user_id);

--
-- Name: idx_categories_active; Type: INDEX; Schema: product_catalog; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_categories_active ON product_catalog.categories USING btree (active);

--
-- Name: idx_categories_name; Type: INDEX; Schema: product_catalog; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_categories_name ON product_catalog.categories USING btree (name);

--
-- Name: idx_products_active; Type: INDEX; Schema: product_catalog; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_products_active ON product_catalog.products USING btree (active);

--
-- Name: idx_products_category_id; Type: INDEX; Schema: product_catalog; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_products_category_id ON product_catalog.products USING btree (category_id);

--
-- Name: idx_products_name; Type: INDEX; Schema: product_catalog; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_products_name ON product_catalog.products USING btree (name);

--
-- Name: idx_products_price; Type: INDEX; Schema: product_catalog; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_products_price ON product_catalog.products USING btree (price);

--
-- Name: idx_users_email; Type: INDEX; Schema: user_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_users_email ON user_management.users USING btree (email);

--
-- Name: idx_users_is_active; Type: INDEX; Schema: user_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_users_is_active ON user_management.users USING btree (is_active);

--
-- Name: idx_users_role_id; Type: INDEX; Schema: user_management; Owner: virtualpet_user
--

CREATE INDEX IF NOT EXISTS idx_users_role_id ON user_management.users USING btree (role_id);

--
-- Name: cart_items update_cart_items_updated_at; Type: TRIGGER; Schema: cart; Owner: virtualpet_user
--

DROP TRIGGER IF EXISTS update_cart_items_updated_at ON cart.cart_items;
CREATE TRIGGER update_cart_items_updated_at BEFORE UPDATE ON cart.cart_items FOR EACH ROW EXECUTE FUNCTION cart.update_updated_at_column();

--
-- Name: cart_items update_cart_on_item_change; Type: TRIGGER; Schema: cart; Owner: virtualpet_user
--

DROP TRIGGER IF EXISTS update_cart_on_item_change ON cart.cart_items;
CREATE TRIGGER update_cart_on_item_change AFTER INSERT OR DELETE OR UPDATE ON cart.cart_items FOR EACH ROW EXECUTE FUNCTION cart.update_cart_timestamp();

--
-- Name: carts update_carts_updated_at; Type: TRIGGER; Schema: cart; Owner: virtualpet_user
--

DROP TRIGGER IF EXISTS update_carts_updated_at ON cart.carts;
CREATE TRIGGER update_carts_updated_at BEFORE UPDATE ON cart.carts FOR EACH ROW EXECUTE FUNCTION cart.update_updated_at_column();

--
-- Name: orders update_orders_updated_at; Type: TRIGGER; Schema: order_management; Owner: virtualpet_user
--

DROP TRIGGER IF EXISTS update_orders_updated_at ON order_management.orders;
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON order_management.orders FOR EACH ROW EXECUTE FUNCTION order_management.update_updated_at_column();

--
-- Name: categories update_categories_updated_at; Type: TRIGGER; Schema: product_catalog; Owner: virtualpet_user
--

DROP TRIGGER IF EXISTS update_categories_updated_at ON product_catalog.categories;
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON product_catalog.categories FOR EACH ROW EXECUTE FUNCTION product_catalog.update_updated_at_column();

--
-- Name: products update_products_updated_at; Type: TRIGGER; Schema: product_catalog; Owner: virtualpet_user
--

DROP TRIGGER IF EXISTS update_products_updated_at ON product_catalog.products;
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON product_catalog.products FOR EACH ROW EXECUTE FUNCTION product_catalog.update_updated_at_column();

--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: user_management; Owner: virtualpet_user
--

DROP TRIGGER IF EXISTS update_users_updated_at ON user_management.users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON user_management.users FOR EACH ROW EXECUTE FUNCTION user_management.update_updated_at_column();

--
-- Name: cart_items cart_items_cart_id_fkey; Type: FK CONSTRAINT; Schema: cart; Owner: virtualpet_user
--

ALTER TABLE ONLY cart.cart_items
    ADD CONSTRAINT cart_items_cart_id_fkey FOREIGN KEY (cart_id) REFERENCES cart.carts(id) ON DELETE CASCADE;

--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: order_management; Owner: virtualpet_user
--

ALTER TABLE ONLY order_management.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES order_management.orders(id) ON DELETE CASCADE;

--
-- Name: order_status_history order_status_history_order_id_fkey; Type: FK CONSTRAINT; Schema: order_management; Owner: virtualpet_user
--

ALTER TABLE ONLY order_management.order_status_history
    ADD CONSTRAINT order_status_history_order_id_fkey FOREIGN KEY (order_id) REFERENCES order_management.orders(id) ON DELETE CASCADE;

--
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: product_catalog; Owner: virtualpet_user
--

ALTER TABLE ONLY product_catalog.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES product_catalog.categories(id);

--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: user_management; Owner: virtualpet_user
--

ALTER TABLE ONLY user_management.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES user_management.roles(id);

--
-- PostgreSQL database dump complete
--

