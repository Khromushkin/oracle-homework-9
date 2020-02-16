drop table product cascade constraints;

create table product
(
    prd_id   number             not null,
    prd_name varchar2(2000 char) not null,
    prd_cost number(10, 2)      not null
);
alter table product
    add constraint prd_id_pk primary key (prd_id);

create sequence prd_id_seq;

comment on table product is 'Список продуктов предложенных в магазине';
comment on column product.prd_id is 'id';
comment on column product.prd_name is 'Наименование';
comment on column product.prd_cost is 'Цена';

insert into product(prd_id, prd_name, prd_cost)
select level, level || ' товар', trunc(dbms_random.value() * level, 2)
from dual connect by level < 100;
commit;
