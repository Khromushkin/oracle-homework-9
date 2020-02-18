set serveroutput on;

CREATE USER admin IDENTIFIED BY admin;
GRANT RESOURCE TO admin;
GRANT UNLIMITED TABLESPACE TO admin;

alter session set current_schema = admin;

spool qiwi.log

prompt >>>>>>> ROLLBACK <<<<<<<<<<

@@rollback.sql

prompt >>>>>>> PRODUCT <<<<<<<<<<
@@product.tbl.sql
prompt >>>>>>> PRODUCT_STOCK<<<<<<<<<<
@@product_stock.tbl.sql
prompt >>>>>>> SALE <<<<<<<<<<
@@sale.tbl.sql
prompt >>>>>>> SALE ITEM <<<<<<<<<<
@@sale_item.tbl.sql
prompt >>>>>>> SALE_ITEM_AUD <<<<<<<<<<
@@sale_item_aud.tbl.sql
prompt >>>>>>> SALE_PACK <<<<<<<<<<
@@sale_pack.pkg.sql
prompt >>>>>>> TRIGGERS <<<<<<<<<<
@@triggers.sql
