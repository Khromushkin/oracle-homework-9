drop table sale;

create table sale
(
    sale_id    number        not null,
    sale_dtime timestamp(6) default systimestamp not null
);
alter table sale
    add constraint sale_id_pk primary key (sale_id);
create sequence sale_id_seq;

comment on table sale is 'Продажа';
comment on column sale.sale_id is 'id продажи';
comment on column sale.sale_dtime is 'timestamp продажи';
