drop table product_stock cascade constraints;

create table product_stock
(
    prs_id    number not null,
    prd_id    number not null,
    prs_count number not null
);
comment on table product_stock is 'Остатки продуктов';
comment on column product_stock.prs_id is 'id складской позиции';
comment on column product_stock.prd_id is 'id товара';
comment on column product_stock.prs_count is 'Количество товара на складе';

alter table product_stock
    add constraint prs_id_pk primary key (prs_id);

create sequence prs_id_seq;

alter table product_stock
    add constraint prs_prd_id_fk foreign key (prd_id) references product (prd_id);

alter table product_stock
    add constraint prs_count_natural check (prs_count >= 0);

create unique index i_prs_prd_id_uniq on product_stock(prd_id);

insert into product_stock(prs_id, prd_id, prs_count)
select level, level, trunc(dbms_random.value() * level * level)
from dual
connect by level < 100;
commit;
