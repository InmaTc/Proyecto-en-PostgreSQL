\c postgres postgres;

DROP DATABASE IF EXISTS confiteria;

CREATE DATABASE confiteria ENCODING 'UTF8';

\c confiteria;

CREATE TABLE incentivo(
    	mes varchar(15) NOT NULL,
    	anio varchar(4) NOT NULL,
    	codTrabajador integer NOT NULL,
	motivo varchar(50) NOT NULL,
	premio integer NOT NULL,
    	PRIMARY KEY (mes, anio)
);

CREATE TABLE empleado(
   	codTrabajador integer NOT NULL,
   	dni varchar(9) NOT NULL,
   	nombre varchar(15) NOT NULL,
   	apellidos varchar(25) NOT NULL,
   	PRIMARY KEY (codTrabajador)
);

CREATE TABLE baja(
  	id_baja serial NOT NULL,
   	fecha_Inicio DATE NOT NULL,
   	fecha_Fin DATE NOT NULL,
   	codTrabajadorFalta integer NOT NULL,
   	codTrabajadorCubre integer NOT NULL,
   	PRIMARY KEY (id_baja),
   	CHECK (codTrabajadorFalta <> codTrabajadorCubre)
);

CREATE TABLE producto(
	cod_producto integer NOT NULL,
	nombre varchar(15) NOT NULL,
        codTrabajador integer NULL,
        stock integer  NOT NULL,
        precio decimal NOT NULL,
	PRIMARY KEY (cod_producto)
);

CREATE TABLE elaborado(
   	relleno varchar(10) NULL,
    	peso numeric(5) NOT NULL,
	celiaco varchar(2) NULL,
   	integral varchar(2) NULL,
   	tipoHarina varchar(10) NOT NULL,
   	cod_producto integer NOT NULL,
    	PRIMARY KEY (cod_producto)
);

CREATE TABLE prodVen(
   	cod_producto integer NOT NULL,
	id_venta varchar(9) NOT NULL,
	unidades integer NOT NULL,
   	PRIMARY KEY (cod_producto, id_venta)
);

CREATE TABLE venta(
	id_venta varchar(9) NOT NULL,
    	PRIMARY KEY (id_venta)
);

CREATE TABLE ventaOnline(
	id_venta varchar(9) NOT NULL,
	fecha DATE NOT NULL,
	descuentos numeric(100) NULL,
	puntos numeric(1000) NOT NULL,
	dirAlter varchar(25) NULL,
	nCliente numeric(9) NOT NULL,
	id_reparto integer NOT NULL,
    	PRIMARY KEY (id_venta)
);

CREATE TABLE cliente(
	nCliente numeric(9) NOT NULL,
	nombre varchar(15) NOT NULL,
    	telefono numeric(9) NOT NULL,
	direccion varchar(25) NOT NULL,
    	PRIMARY KEY (nCliente)
);

CREATE TABLE reparto(
   	id_reparto integer NOT NULL,
	fecha DATE NOT NULL,
	hora varchar(5) NOT NULL, 
	matricula numeric(9) NOT NULL,
	codTrabajador integer NOT NULL,
   	PRIMARY KEY (id_reparto)
);

CREATE TABLE vehiculo(
   	matricula numeric(9) NOT NULL,
	marca varchar(10) NOT NULL,
	modelo varchar(10) NOT NULL,
   	PRIMARY KEY (matricula)
);

CREATE TABLE repartidor(
   	codTrabajador integer NOT NULL,
	zona varchar(2) NOT NULL,
   	PRIMARY KEY (codTrabajador)
);
  


ALTER TABLE baja
    ADD FOREIGN KEY (codTrabajadorCubre) REFERENCES empleado(codTrabajador) ON UPDATE CASCADE;
    
ALTER TABLE baja
    ADD FOREIGN KEY (codTrabajadorFalta) REFERENCES empleado(codTrabajador) ON UPDATE CASCADE;
        
/*ALTER TABLE baja
    ADD CHECK (codTrabajadorFalta <> codTrabajadorCubre);*/
    
ALTER TABLE producto
    ADD FOREIGN KEY (codTrabajador) REFERENCES empleado(codTrabajador) ON UPDATE CASCADE;

ALTER TABLE elaborado
    ADD FOREIGN KEY (cod_producto) REFERENCES producto(cod_producto) ON UPDATE CASCADE;

ALTER TABLE prodVen
    ADD FOREIGN KEY (cod_producto) REFERENCES producto(cod_producto) ON UPDATE CASCADE;

ALTER TABLE prodVen
    ADD FOREIGN KEY (id_venta) REFERENCES venta(id_venta) ON UPDATE CASCADE;

ALTER TABLE ventaOnline
    ADD FOREIGN KEY (id_venta) REFERENCES venta(id_venta) ON UPDATE CASCADE;

ALTER TABLE ventaOnline
    ADD FOREIGN KEY (nCliente) REFERENCES cliente(nCliente) ON UPDATE CASCADE;

ALTER TABLE ventaOnline
    ADD FOREIGN KEY (id_reparto) REFERENCES reparto(id_reparto) ON UPDATE cascade;

ALTER TABLE reparto
    ADD FOREIGN KEY (matricula) REFERENCES vehiculo(matricula) ON UPDATE CASCADE;

ALTER TABLE reparto
    ADD FOREIGN KEY (codTrabajador) REFERENCES repartidor(codTrabajador) ON UPDATE CASCADE;

ALTER TABLE repartidor
    ADD FOREIGN KEY (codTrabajador) REFERENCES empleado(codTrabajador) ON UPDATE CASCADE;

ALTER TABLE incentivo
    ADD FOREIGN KEY (codTrabajador) REFERENCES empleado(codTrabajador) ON UPDATE CASCADE;


CREATE INDEX ON incentivo(codTrabajador);

CREATE INDEX ON baja(codTrabajadorCubre);

CREATE INDEX ON baja(codTrabajadorFalta);

CREATE INDEX ON producto(codTrabajador);

CREATE INDEX ON elaborado(cod_producto);

CREATE INDEX ON prodVen(id_venta);

CREATE INDEX ON prodVen(cod_producto);

CREATE INDEX ON ventaOnline(id_venta);

CREATE INDEX ON ventaOnline(nCliente);

CREATE INDEX ON ventaOnline(id_reparto);

CREATE INDEX ON reparto(matricula);

CREATE INDEX ON reparto(codTrabajador);

CREATE INDEX ON repartidor(codTrabajador);


--Triggers

/* Trigger 1: No permitir que se introduzcan precios negativos en los productos. */


CREATE TABLE IF NOT EXISTS modificaciones_cliente ( 
idmodifica serial PRIMARY KEY, 
ncliente integer not null, 
atributo_modificado varchar(10) not null, 
valor_antiguo_atributo varchar(50), 
valor_nuevo_atributo varchar(50), 
fecha_modificacion timestamp not null 
);

CREATE OR REPLACE FUNCTION trig_productos_precio() RETURNS trigger AS $$

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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trig_modifica_precio BEFORE INSERT OR UPDATE ON producto
FOR EACH ROW EXECUTE PROCEDURE trig_productos_precio();


/* COMPROBACIÓN: 
insert into producto
values (5,'barra','5',40,-2);
*/

/* Trigger 2:*/ 
create or replace function trig_modifica_cliente() returns trigger AS $$

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
$$ language plpgsql;
create trigger trig_modifica_cliente before update on cliente 
for each row execute procedure trig_modifica_cliente();

/*
update cliente
set ncliente = 2
where ncliente=1;
*/

/* Trigger 3: Dar de baja en el sistema a un empleado */


CREATE TABLE IF NOT EXISTS empleado_despedido (
  	codTrabajador integer NOT NULL,
   	dni varchar(9) NOT NULL,
   	nombre varchar(15) NOT NULL,
   	apellidos varchar(25) NOT NULL,
   	numborrado integer default 0,
   	PRIMARY KEY (codTrabajador)
) ;

create or replace function trig_empleado_despedido() returns trigger AS $$
declare
contador int := 0;

begin
	select count(*) into contador from empleado_despedido where codtrabajador = old.codtrabajador;	
	
	
	insert into empleado_despedido
	values (old.codtrabajador, old.dni, old.nombre,old.apellidos, contador + 1); 

	
	return null;
end;
$$ language plpgsql;

create trigger trig_empleado_despedido after delete on empleado 
for each row execute procedure trig_empleado_despedido();

/*
COMPROBACIÓN:
delete from empleado
where codtrabajador=20;
*/

/* Trigger 4: Actualizar el stock de un producto modificado. */

create or replace function trig_actualiza_stock() returns trigger AS $$
declare
cantidad int := 0;

begin
	select stock into cantidad from producto where cod_producto = old.cod_producto;	
	
	update producto
	set stock = stock + cantidad
	where cod_producto = old.cod_producto;
		
	return null;
end;
$$ language plpgsql;

create trigger trig_actualiza_stock after update on producto 
for each row execute procedure trig_actualiza_stock();

/* COMPROBACIÓN:
update producto
set stock = 20
where cod_producto = 1;
*/

/* Trigger 5: Actualizar el stock de un producto al venderse. */

create or replace function trig_actualiza_stock_ventas() returns trigger AS $$
declare
cantidad int := 0;

begin
	select unidades into cantidad from prodven where cod_producto = old.cod_producto;	

    		update producto
		set stock = stock - cantidad
		where cod_producto = old.cod_producto;
   		RETURN NULL;

end;
$$ language plpgsql;

create trigger trig_actualiza_stock_ventas after update on prodven 
for each row execute procedure trig_actualiza_stock_ventas();

/*COMPROBACIÓN:
 
update prodven
set unidades = 2
where cod_producto = 1 and id_venta = '1';
*/

--Insercciones

/*tabla empleado*/
insert into empleado
values (1,'12345678A','Juan','Valero');

insert into empleado
values (2,'12345679B','Lidia','López');

insert into empleado
values (3,'12345670C','Jose','Redondo');

insert into empleado
values (4,'12345671D','Jesús','Lara');

insert into empleado
values (5,'12345672E','Amparo','Talavera');

insert into empleado
values (6,'12345673F','Teresa','Montero');

insert into empleado
values (7,'12345674G','Luis','Crespo');

insert into empleado
values (20,'12340678A','Juana','Vale');

/*tabla incentivo*/
insert into incentivo
values ('Enero','2021','1','Primero en ventas',50);

insert into incentivo
values ('Febrero','2021','2','Más repartos',100);

insert into incentivo
values ('Marzo','2021','3','Realiza más productos',75);

insert into incentivo
values ('Abril','2021','1','Primero en ventas',50);

insert into incentivo
values ('Diciembre','2020','7','Puntualidad',50);

insert into incentivo
values ('Noviembre','2020','5','Dedicación extra',150);

/*tabla baja*/
insert into baja
values (DEFAULT,'2021/01/28','2021/02/05',7,6);

insert into baja
values (DEFAULT,'2020/11/15','2020/12/01',2,3);

/*tabla producto*/
insert into producto
values (1,'ochio','3',50,0.60);

insert into producto (cod_producto,nombre,stock, precio)
values (2,'agua',100,1);

insert into producto (cod_producto,nombre,stock,precio)
values (3,'zumo',25,1.15);

insert into producto (cod_producto,nombre,stock,precio)
values (4,'refresco',50,1.75);

insert into producto
values (5,'barra','5',40,0.45);

insert into producto
values (6,'telera','5',25,0.95);

insert into producto
values (7,'torta','3',100,0.65);

insert into producto
values (8,'tarta','3',5,15.95);

/*tabla elaborado*/
insert into elaborado (relleno, peso, tipoHarina, cod_producto)
values ('crema',100,'trigo',7);

insert into elaborado (peso, celiaco, tipoHarina, cod_producto)
values (300,'SI','maiz',5);

insert into elaborado (peso, integral, tipoHarina, cod_producto)
values (1000,'SI','trigo',6);

insert into elaborado (peso, tipoHarina, cod_producto)
values (50,'trigo',1);

insert into elaborado 
values ('crema',1000,'SI','SI','Arroz',8);

/*tabla venta*/
insert into venta
values (1);

insert into venta
values (2);

insert into venta
values (3);

insert into venta
values (4);

/*tabla prodVen*/
insert into prodVen
values (1,1,3);

insert into prodVen
values (2,2,5);

insert into prodVen
values (4,3,1);

insert into prodVen
values (1,4,9);

/*tabla cliente*/
insert into cliente (nCliente,nombre,telefono,direccion)
values (1,'Marta',654987321,'Picasso');

insert into cliente
values (2,'Pablo',654123589,'Zurbaran');

/*tabla vehiculo*/
insert into vehiculo
values (1234,'seat','leon');

insert into vehiculo
values (4123,'Suzuki','vecchi');

/*tabla repartidor*/
insert into repartidor
values (1,'A');

insert into repartidor
values (2,'C');

/*tabla reparto*/
insert into reparto
values (1,'2021/03/05','10:15',1234,2);

/*tabla ventaOnline*/
insert into ventaOnline
values (1,'2021/03/04',0,1,'Pintor Espinosa',1, 1);

insert into ventaOnline (id_venta,fecha,descuentos,puntos,nCliente,id_reparto)
values (2,'2021/03/05',1,2,2,1);

--Cursores

/* Cursor 1: Actualizar o agregar rellenos a un producto elaborado*/

CREATE OR REPLACE FUNCTION actualiza_elaborados(cod_prod_old elaborado.cod_producto%type, relleno_new elaborado.relleno%type) RETURNS boolean AS $$
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
$$ LANGUAGE plpgsql;


/* Cursor 2: Listar los datos de un cliente a partir del código de venta (id_venta) ordenados por apellidos alfabéticamente*/


CREATE OR REPLACE FUNCTION listar_clientes() RETURNS void AS $$

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
$$ LANGUAGE plpgsql;

/* Cursor 3: Buscar a un empleado por su nombre y listar sus datos. */


CREATE OR REPLACE FUNCTION busqueda_empleado(nombreParametro empleado.nombre%TYPE) RETURNS void AS $$
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
$$ LANGUAGE plpgsql

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



