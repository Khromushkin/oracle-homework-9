set serveroutput on;

CREATE USER admin IDENTIFIED BY admin;
GRANT RESOURCE TO admin;
GRANT UNLIMITED TABLESPACE TO admin;

alter session set current_schema = admin;

@@product.tbl.sql
@@product_stock.tbl.sql
@@sale.tbl.sql
@@sale_item.tbl.sql
@@sale_pack.pkg.sql
@@triggers.sql