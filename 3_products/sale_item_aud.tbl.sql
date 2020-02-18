create table sale_item_aud
(
    sia_id     number not null,
    stm_id     number not null,
    old_prd_count  number not null,
    old_prd_amount number not null,
    new_prd_count number not null,
    new_prd_amount number not null,
    stm_change_dtime timestamp(6) default systimestamp not null
);

alter table sale_item_aud
    add constraint sale_item_aud_pk primary key (sia_id);

create sequence sia_id_seq;

comment on table sale_item_aud is 'Аудит позиций продажи';
comment on column sale_item_aud.stm_id is 'id позиции продажи';
comment on column sale_item_aud.old_prd_count is 'Старое количество товаров в позиции';
comment on column sale_item_aud.old_prd_amount is 'Старая стоимось товаров в позиции';
comment on column sale_item_aud.new_prd_count is 'Новое количество товаров в позиции';
comment on column sale_item_aud.new_prd_amount is 'Новая стоимость товаров в позиции';
