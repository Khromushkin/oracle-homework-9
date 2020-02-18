create table sale_item
(
    stm_id     number not null,
    prd_id     number not null,
    prd_count  number not null,
    prd_amount number not null,
    sale_id    number not null
);
alter table sale_item
    add constraint sale_item_pk primary key (stm_id);

create sequence stm_id_seq;

alter table sale_item
    add constraint sale_item_natural check (prd_count >= 0 and prd_amount >= 0);

comment on table sale_item is 'Позиция продажи';
comment on column sale_item.stm_id is 'id позиции продажи';
comment on column sale_item.prd_id is 'id продукта';
comment on column sale_item.prd_count is 'количество товаров в позиции';
comment on column sale_item.prd_amount is 'сумма позиции';
comment on column sale_item.sale_id is 'id продажи';
