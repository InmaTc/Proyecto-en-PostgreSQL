--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2 (Debian 13.2-1.pgdg100+1)
-- Dumped by pg_dump version 13.2 (Debian 13.2-1.pgdg100+1)

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
-- Name: confiteria; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE confiteria WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE confiteria OWNER TO postgres;

\connect confiteria

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
-- Name: actualiza_elaborados(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.actualiza_elaborados(cod_prod_old integer, relleno_new character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE 
micursor CURSOR FOR SELECT * FROM elaborado;

encontrado boolean := FALSE;
contador integer := 0;

BEGIN
FOR producto IN micursor LOOP

if producto.cod_producto = cod_prod_old then
	update elaborado
		set relleno = relleno_new
	where current of micursor;
	contador := contador +1;
	encontrado := TRUE;
end if;

END LOOP;

if encontrado then
	RAISE NOTICE ' Se ha modificado el relleno de % productos.', contador;
else
	RAISE NOTICE ' No se ha modificado ningún relleno. ';
end if;

RETURN encontrado;
END; 
$$;


ALTER FUNCTION public.actualiza_elaborados(cod_prod_old integer, relleno_new character varying) OWNER TO postgres;

--
-- Name: busqueda_empleado(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.busqueda_empleado(nombreparametro character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
contador integer DEFAULT 0;
miCursor CURSOR FOR SELECT * FROM empleado where nombre = 'nombreParametro';

BEGIN
FOR reg IN miCursor LOOP
	
		RAISE NOTICE'Código de trabajador %: % - % - DNI: %',reg.cod_trabajador, reg.apellidos, reg.nombre, reg.dni;
		contador := contador + 1;
	
END LOOP;

IF contador = 0
THEN
	RAISE NOTICE'Sin coincidencias para este nombre.';
END IF;

END;
$$;


ALTER FUNCTION public.busqueda_empleado(nombreparametro character varying) OWNER TO postgres;

--
-- Name: listar_clientes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.listar_clientes() RETURNS void
    LANGUAGE plpgsql
    AS $$

DECLARE 
micursor CURSOR FOR SELECT * FROM cliente order by nombre;
contador integer := 0;
total integer :=0;

BEGIN
select count(*) into total from cliente;
FOR registro IN micursor LOOP
contador := contador+1;
if (contador > 0 or contador <= total) then
   RAISE NOTICE 'Cliente % -> % - % - %', contador,registro.nombre, registro.telefono, registro.direccion;

end if;
end LOOP;
if not found then
	RAISE NOTICE ' No existen clientes. ';
end if;
RETURN;
END;
$$;


ALTER FUNCTION public.listar_clientes() OWNER TO postgres;

--
-- Name: trig_actualiza_stock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trig_actualiza_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
cantidad int := 0;

begin
	select stock into cantidad from producto where cod_producto = old.cod_producto;	
	
	update producto
	set stock = stock + cantidad
	where cod_producto = old.cod_producto;
		
	return null;
end;
$$;


ALTER FUNCTION public.trig_actualiza_stock() OWNER TO postgres;

--
-- Name: trig_actualiza_stock_ventas(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trig_actualiza_stock_ventas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
cantidad int := 0;

begin
	select unidades into cantidad from prodven where cod_producto = old.cod_producto;	

    		update producto
		set stock = stock - cantidad
		where cod_producto = old.cod_producto;
   		RETURN NULL;

end;
$$;


ALTER FUNCTION public.trig_actualiza_stock_ventas() OWNER TO postgres;

--
-- Name: trig_empleado_despedido(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trig_empleado_despedido() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
contador int := 0;

begin
	select count(*) into contador from empleado_despedido where codtrabajador = old.codtrabajador;	
	
	
	insert into empleado_despedido
	values (old.codtrabajador, old.dni, old.nombre,old.apellidos, contador + 1); 

	
	return null;
end;
$$;


ALTER FUNCTION public.trig_empleado_despedido() OWNER TO postgres;

--
-- Name: trig_modifica_cliente(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trig_modifica_cliente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

begin

if new.ncliente != old.ncliente then
   raise notice 'No se puede modificar el campo ncliente (PRIMARY KEY)';
   new.ncliente := old.ncliente;
end if;

if new.nombre != old.nombre then
	insert into modificaciones_cliente (ncliente, atributo_modificado, valor_antiguo_atributo, valor_nuevo_atributo, fecha_modificacion)
	values (new.idagenda,'nombre',old.nombre,new.nombre,CURRENT_TIMESTAMP);
end if;

if new.telefono != old.telefono then
	insert into modificaciones_cliente (ncliente, atributo_modificado, valor_antiguo_atributo, valor_nuevo_atributo, fecha_modificacion)
	values (new.ncliente,'telefono',old.telefono,new.telefono,CURRENT_TIMESTAMP);
end if;

if new.direccion != old.direccion then
	insert into modificaciones_cliente (ncliente, atributo_modificado, valor_antiguo_atributo, valor_nuevo_atributo, fecha_modificacion)
	values (new.ncliente,'dirección',old.direccion,new.direccion,CURRENT_TIMESTAMP);
end if;


return new;

end;
$$;


ALTER FUNCTION public.trig_modifica_cliente() OWNER TO postgres;

--
-- Name: trig_productos_precio(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trig_productos_precio() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN


IF (new.precio < 0) then
raise notice 'Precio venta antiguo: %', old.precio;
raise notice 'Precio venta modificado: %', new.precio;
raise notice'No puedes introducir un precio de venta negativo.';
return null;

else
RETURN NEW;
end if;


END;
$$;


ALTER FUNCTION public.trig_productos_precio() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: baja; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.baja (
    id_baja integer NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date NOT NULL,
    codtrabajadorfalta integer NOT NULL,
    codtrabajadorcubre integer NOT NULL,
    CONSTRAINT baja_check CHECK ((codtrabajadorfalta <> codtrabajadorcubre))
);


ALTER TABLE public.baja OWNER TO postgres;

--
-- Name: baja_id_baja_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.baja_id_baja_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.baja_id_baja_seq OWNER TO postgres;

--
-- Name: baja_id_baja_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.baja_id_baja_seq OWNED BY public.baja.id_baja;


--
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    ncliente numeric(9,0) NOT NULL,
    nombre character varying(15) NOT NULL,
    telefono numeric(9,0) NOT NULL,
    direccion character varying(25) NOT NULL
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- Name: elaborado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.elaborado (
    relleno character varying(10),
    peso numeric(5,0) NOT NULL,
    celiaco character varying(2),
    integral character varying(2),
    tipoharina character varying(10) NOT NULL,
    cod_producto integer NOT NULL
);


ALTER TABLE public.elaborado OWNER TO postgres;

--
-- Name: empleado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empleado (
    codtrabajador integer NOT NULL,
    dni character varying(9) NOT NULL,
    nombre character varying(15) NOT NULL,
    apellidos character varying(25) NOT NULL
);


ALTER TABLE public.empleado OWNER TO postgres;

--
-- Name: empleado_despedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empleado_despedido (
    codtrabajador integer NOT NULL,
    dni character varying(9) NOT NULL,
    nombre character varying(15) NOT NULL,
    apellidos character varying(25) NOT NULL,
    numborrado integer DEFAULT 0
);


ALTER TABLE public.empleado_despedido OWNER TO postgres;

--
-- Name: incentivo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.incentivo (
    mes character varying(15) NOT NULL,
    anio character varying(4) NOT NULL,
    codtrabajador integer NOT NULL,
    motivo character varying(50) NOT NULL,
    premio integer NOT NULL
);


ALTER TABLE public.incentivo OWNER TO postgres;

--
-- Name: modificaciones_cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modificaciones_cliente (
    idmodifica integer NOT NULL,
    ncliente integer NOT NULL,
    atributo_modificado character varying(10) NOT NULL,
    valor_antiguo_atributo character varying(50),
    valor_nuevo_atributo character varying(50),
    fecha_modificacion timestamp without time zone NOT NULL
);


ALTER TABLE public.modificaciones_cliente OWNER TO postgres;

--
-- Name: modificaciones_cliente_idmodifica_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modificaciones_cliente_idmodifica_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.modificaciones_cliente_idmodifica_seq OWNER TO postgres;

--
-- Name: modificaciones_cliente_idmodifica_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modificaciones_cliente_idmodifica_seq OWNED BY public.modificaciones_cliente.idmodifica;


--
-- Name: producto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producto (
    cod_producto integer NOT NULL,
    nombre character varying(15) NOT NULL,
    codtrabajador integer,
    stock integer NOT NULL,
    precio numeric NOT NULL
);


ALTER TABLE public.producto OWNER TO postgres;

--
-- Name: prodven; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prodven (
    cod_producto integer NOT NULL,
    id_venta character varying(9) NOT NULL,
    unidades integer NOT NULL
);


ALTER TABLE public.prodven OWNER TO postgres;

--
-- Name: repartidor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.repartidor (
    codtrabajador integer NOT NULL,
    zona character varying(2) NOT NULL
);


ALTER TABLE public.repartidor OWNER TO postgres;

--
-- Name: reparto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reparto (
    id_reparto integer NOT NULL,
    fecha date NOT NULL,
    hora character varying(5) NOT NULL,
    matricula numeric(9,0) NOT NULL,
    codtrabajador integer NOT NULL
);


ALTER TABLE public.reparto OWNER TO postgres;

--
-- Name: vehiculo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehiculo (
    matricula numeric(9,0) NOT NULL,
    marca character varying(10) NOT NULL,
    modelo character varying(10) NOT NULL
);


ALTER TABLE public.vehiculo OWNER TO postgres;

--
-- Name: venta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venta (
    id_venta character varying(9) NOT NULL
);


ALTER TABLE public.venta OWNER TO postgres;

--
-- Name: ventaonline; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ventaonline (
    id_venta character varying(9) NOT NULL,
    fecha date NOT NULL,
    descuentos numeric(100,0),
    puntos numeric(1000,0) NOT NULL,
    diralter character varying(25),
    ncliente numeric(9,0) NOT NULL,
    id_reparto integer NOT NULL
);


ALTER TABLE public.ventaonline OWNER TO postgres;

--
-- Name: baja id_baja; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.baja ALTER COLUMN id_baja SET DEFAULT nextval('public.baja_id_baja_seq'::regclass);


--
-- Name: modificaciones_cliente idmodifica; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modificaciones_cliente ALTER COLUMN idmodifica SET DEFAULT nextval('public.modificaciones_cliente_idmodifica_seq'::regclass);


--
-- Data for Name: baja; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.baja (id_baja, fecha_inicio, fecha_fin, codtrabajadorfalta, codtrabajadorcubre) FROM stdin;
1	2021-01-28	2021-02-05	7	6
2	2020-11-15	2020-12-01	2	3
\.


--
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cliente (ncliente, nombre, telefono, direccion) FROM stdin;
1	Marta	654987321	Picasso
2	Pablo	654123589	Zurbaran
\.


--
-- Data for Name: elaborado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.elaborado (relleno, peso, celiaco, integral, tipoharina, cod_producto) FROM stdin;
crema	100	\N	\N	trigo	7
\N	300	SI	\N	maiz	5
\N	1000	\N	SI	trigo	6
\N	50	\N	\N	trigo	1
crema	1000	SI	SI	Arroz	8
\.


--
-- Data for Name: empleado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.empleado (codtrabajador, dni, nombre, apellidos) FROM stdin;
1	12345678A	Juan	Valero
2	12345679B	Lidia	López
3	12345670C	Jose	Redondo
4	12345671D	Jesús	Lara
5	12345672E	Amparo	Talavera
6	12345673F	Teresa	Montero
7	12345674G	Luis	Crespo
20	12340678A	Juana	Vale
\.


--
-- Data for Name: empleado_despedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.empleado_despedido (codtrabajador, dni, nombre, apellidos, numborrado) FROM stdin;
\.


--
-- Data for Name: incentivo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.incentivo (mes, anio, codtrabajador, motivo, premio) FROM stdin;
Enero	2021	1	Primero en ventas	50
Febrero	2021	2	Más repartos	100
Marzo	2021	3	Realiza más productos	75
Abril	2021	1	Primero en ventas	50
Diciembre	2020	7	Puntualidad	50
Noviembre	2020	5	Dedicación extra	150
\.


--
-- Data for Name: modificaciones_cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modificaciones_cliente (idmodifica, ncliente, atributo_modificado, valor_antiguo_atributo, valor_nuevo_atributo, fecha_modificacion) FROM stdin;
\.


--
-- Data for Name: producto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.producto (cod_producto, nombre, codtrabajador, stock, precio) FROM stdin;
1	ochio	3	50	0.60
2	agua	\N	100	1
3	zumo	\N	25	1.15
4	refresco	\N	50	1.75
5	barra	5	40	0.45
6	telera	5	25	0.95
7	torta	3	100	0.65
8	tarta	3	5	15.95
\.


--
-- Data for Name: prodven; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prodven (cod_producto, id_venta, unidades) FROM stdin;
1	1	3
2	2	5
4	3	1
1	4	9
\.


--
-- Data for Name: repartidor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.repartidor (codtrabajador, zona) FROM stdin;
1	A
2	C
\.


--
-- Data for Name: reparto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reparto (id_reparto, fecha, hora, matricula, codtrabajador) FROM stdin;
1	2021-03-05	10:15	1234	2
\.


--
-- Data for Name: vehiculo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehiculo (matricula, marca, modelo) FROM stdin;
1234	seat	leon
4123	Suzuki	vecchi
\.


--
-- Data for Name: venta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venta (id_venta) FROM stdin;
1
2
3
4
\.


--
-- Data for Name: ventaonline; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ventaonline (id_venta, fecha, descuentos, puntos, diralter, ncliente, id_reparto) FROM stdin;
1	2021-03-04	0	1	Pintor Espinosa	1	1
2	2021-03-05	1	2	\N	2	1
\.


--
-- Name: baja_id_baja_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.baja_id_baja_seq', 2, true);


--
-- Name: modificaciones_cliente_idmodifica_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modificaciones_cliente_idmodifica_seq', 1, false);


--
-- Name: baja baja_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_pkey PRIMARY KEY (id_baja);


--
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (ncliente);


--
-- Name: elaborado elaborado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elaborado
    ADD CONSTRAINT elaborado_pkey PRIMARY KEY (cod_producto);


--
-- Name: empleado_despedido empleado_despedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleado_despedido
    ADD CONSTRAINT empleado_despedido_pkey PRIMARY KEY (codtrabajador);


--
-- Name: empleado empleado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT empleado_pkey PRIMARY KEY (codtrabajador);


--
-- Name: incentivo incentivo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incentivo
    ADD CONSTRAINT incentivo_pkey PRIMARY KEY (mes, anio);


--
-- Name: modificaciones_cliente modificaciones_cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modificaciones_cliente
    ADD CONSTRAINT modificaciones_cliente_pkey PRIMARY KEY (idmodifica);


--
-- Name: producto producto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (cod_producto);


--
-- Name: prodven prodven_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prodven
    ADD CONSTRAINT prodven_pkey PRIMARY KEY (cod_producto, id_venta);


--
-- Name: repartidor repartidor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repartidor
    ADD CONSTRAINT repartidor_pkey PRIMARY KEY (codtrabajador);


--
-- Name: reparto reparto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reparto
    ADD CONSTRAINT reparto_pkey PRIMARY KEY (id_reparto);


--
-- Name: vehiculo vehiculo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehiculo
    ADD CONSTRAINT vehiculo_pkey PRIMARY KEY (matricula);


--
-- Name: venta venta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta
    ADD CONSTRAINT venta_pkey PRIMARY KEY (id_venta);


--
-- Name: ventaonline ventaonline_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventaonline
    ADD CONSTRAINT ventaonline_pkey PRIMARY KEY (id_venta);


--
-- Name: baja_codtrabajadorcubre_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX baja_codtrabajadorcubre_idx ON public.baja USING btree (codtrabajadorcubre);


--
-- Name: baja_codtrabajadorfalta_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX baja_codtrabajadorfalta_idx ON public.baja USING btree (codtrabajadorfalta);


--
-- Name: elaborado_cod_producto_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX elaborado_cod_producto_idx ON public.elaborado USING btree (cod_producto);


--
-- Name: incentivo_codtrabajador_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX incentivo_codtrabajador_idx ON public.incentivo USING btree (codtrabajador);


--
-- Name: producto_codtrabajador_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX producto_codtrabajador_idx ON public.producto USING btree (codtrabajador);


--
-- Name: prodven_cod_producto_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX prodven_cod_producto_idx ON public.prodven USING btree (cod_producto);


--
-- Name: prodven_id_venta_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX prodven_id_venta_idx ON public.prodven USING btree (id_venta);


--
-- Name: repartidor_codtrabajador_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX repartidor_codtrabajador_idx ON public.repartidor USING btree (codtrabajador);


--
-- Name: reparto_codtrabajador_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX reparto_codtrabajador_idx ON public.reparto USING btree (codtrabajador);


--
-- Name: reparto_matricula_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX reparto_matricula_idx ON public.reparto USING btree (matricula);


--
-- Name: ventaonline_id_reparto_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ventaonline_id_reparto_idx ON public.ventaonline USING btree (id_reparto);


--
-- Name: ventaonline_id_venta_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ventaonline_id_venta_idx ON public.ventaonline USING btree (id_venta);


--
-- Name: ventaonline_ncliente_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ventaonline_ncliente_idx ON public.ventaonline USING btree (ncliente);


--
-- Name: producto trig_actualiza_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trig_actualiza_stock AFTER UPDATE ON public.producto FOR EACH ROW EXECUTE FUNCTION public.trig_actualiza_stock();


--
-- Name: prodven trig_actualiza_stock_ventas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trig_actualiza_stock_ventas AFTER UPDATE ON public.prodven FOR EACH ROW EXECUTE FUNCTION public.trig_actualiza_stock_ventas();


--
-- Name: empleado trig_empleado_despedido; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trig_empleado_despedido AFTER DELETE ON public.empleado FOR EACH ROW EXECUTE FUNCTION public.trig_empleado_despedido();


--
-- Name: cliente trig_modifica_cliente; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trig_modifica_cliente BEFORE UPDATE ON public.cliente FOR EACH ROW EXECUTE FUNCTION public.trig_modifica_cliente();


--
-- Name: producto trig_modifica_precio; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trig_modifica_precio BEFORE INSERT OR UPDATE ON public.producto FOR EACH ROW EXECUTE FUNCTION public.trig_productos_precio();


--
-- Name: baja baja_codtrabajadorcubre_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_codtrabajadorcubre_fkey FOREIGN KEY (codtrabajadorcubre) REFERENCES public.empleado(codtrabajador) ON UPDATE CASCADE;


--
-- Name: baja baja_codtrabajadorfalta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_codtrabajadorfalta_fkey FOREIGN KEY (codtrabajadorfalta) REFERENCES public.empleado(codtrabajador) ON UPDATE CASCADE;


--
-- Name: elaborado elaborado_cod_producto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.elaborado
    ADD CONSTRAINT elaborado_cod_producto_fkey FOREIGN KEY (cod_producto) REFERENCES public.producto(cod_producto) ON UPDATE CASCADE;


--
-- Name: incentivo incentivo_codtrabajador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incentivo
    ADD CONSTRAINT incentivo_codtrabajador_fkey FOREIGN KEY (codtrabajador) REFERENCES public.empleado(codtrabajador) ON UPDATE CASCADE;


--
-- Name: producto producto_codtrabajador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_codtrabajador_fkey FOREIGN KEY (codtrabajador) REFERENCES public.empleado(codtrabajador) ON UPDATE CASCADE;


--
-- Name: prodven prodven_cod_producto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prodven
    ADD CONSTRAINT prodven_cod_producto_fkey FOREIGN KEY (cod_producto) REFERENCES public.producto(cod_producto) ON UPDATE CASCADE;


--
-- Name: prodven prodven_id_venta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prodven
    ADD CONSTRAINT prodven_id_venta_fkey FOREIGN KEY (id_venta) REFERENCES public.venta(id_venta) ON UPDATE CASCADE;


--
-- Name: repartidor repartidor_codtrabajador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repartidor
    ADD CONSTRAINT repartidor_codtrabajador_fkey FOREIGN KEY (codtrabajador) REFERENCES public.empleado(codtrabajador) ON UPDATE CASCADE;


--
-- Name: reparto reparto_codtrabajador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reparto
    ADD CONSTRAINT reparto_codtrabajador_fkey FOREIGN KEY (codtrabajador) REFERENCES public.repartidor(codtrabajador) ON UPDATE CASCADE;


--
-- Name: reparto reparto_matricula_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reparto
    ADD CONSTRAINT reparto_matricula_fkey FOREIGN KEY (matricula) REFERENCES public.vehiculo(matricula) ON UPDATE CASCADE;


--
-- Name: ventaonline ventaonline_id_reparto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventaonline
    ADD CONSTRAINT ventaonline_id_reparto_fkey FOREIGN KEY (id_reparto) REFERENCES public.reparto(id_reparto) ON UPDATE CASCADE;


--
-- Name: ventaonline ventaonline_id_venta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventaonline
    ADD CONSTRAINT ventaonline_id_venta_fkey FOREIGN KEY (id_venta) REFERENCES public.venta(id_venta) ON UPDATE CASCADE;


--
-- Name: ventaonline ventaonline_ncliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventaonline
    ADD CONSTRAINT ventaonline_ncliente_fkey FOREIGN KEY (ncliente) REFERENCES public.cliente(ncliente) ON UPDATE CASCADE;


--
-- PostgreSQL database dump complete
--
/* 
CONSULTAS 

--Select 1: Productos en stock con al menos uno, de mayor a menor 
select nombre,stock from producto
where stock <> 0
order by stock desc;

--Select 2: Listado de productos que NO son elaborados por la empresa.
select nombre from producto
where cod_producto not in (select cod_producto 
				from elaborado);

--Select 3: Qué nombre completo de empleado ha elaborado cada producto.
select concat(s.nombre,' ',s.apellidos), producto.nombre 
from elaborado,producto, empleado s
where s.codtrabajador = producto.codtrabajador and
elaborado.cod_producto=producto.cod_producto;

--Select 4: Marca del vehículo y nombre del empleado con la que se ha hecho un reparto.
select marca, empleado.nombre from vehiculo, reparto, repartidor,empleado
where vehiculo.matricula=reparto.matricula and 
reparto.codtrabajador = repartidor.codtrabajador and
repartidor.codtrabajador =  empleado.codtrabajador; 

--Select 5: Qué productos son aptos para celiacos.
select nombre from producto
where cod_producto in (select cod_producto from elaborado
			where celiaco is not null);

-- Select 6: Qué productos con aptos para celiacos y, además, sean integrales
select nombre from producto
where cod_producto in (select cod_producto from elaborado
			where celiaco is not null 
			and integral is not null);

/*Select 7: Contar cuantos pedidos se han realizado online en el mes de Marzo
select count(ncliente) from cliente
where ncliente in (select ncliente from ventaonline
		where fecha between '2021/03/01' and '2021/03/30');

-- Select 8: Incentivos que ha habido en 2020
select motivo, premio, codtrabajador from incentivo
where anio = '2020';

--Select 9: Ordenar los empleados por apellidos
select concat(apellidos, ', ', nombre) from empleado
order by apellidos;
*/


