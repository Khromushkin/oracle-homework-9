create or replace trigger change_product_b_iud_strict
    before insert or update or delete
    on product
begin
    sale_pack.sale_tr_body_restrict();
end change_product_b_iud_strict;
/
create or replace trigger change_prs_b_iud_strict
    before insert or update or delete
    on product_stock
begin
    sale_pack.sale_tr_body_restrict();
end change_prs_b_iud_strict;
/
create or replace trigger change_sale_b_iud_strict
    before insert or update or delete
    on sale
begin
    sale_pack.sale_tr_body_restrict();
end change_sale_b_iud_strict;
/
create or replace trigger change_sale_item_b_iud_strict
    before insert or update or delete
    on sale_item
begin
    sale_pack.sale_tr_body_restrict();
end change_sale_item_b_iud_strict;
/
create or replace trigger change_sale_item_b_u
    before update
    on sale_item
    for each row
declare
    v_new sale_item%rowtype;
    v_old sale_item%rowtype;
begin
    v_new.prd_count := :new.prd_count;
    v_new.prd_amount := :new.prd_amount;
    v_old.prd_count := :old.prd_count;
    v_old.prd_amount := :old.prd_amount;
    sale_pack.change_sale_item_tr_body_dml(:new.stm_id, v_new, v_old);
end change_sale_item_b_u;
/
create or replace trigger change_sale_item_aud_b_iud_strict
    before insert or update or delete
    on sale_item_aud
begin
    sale_pack.sale_tr_body_restrict();
end change_sale_item_aud_b_iud_strict;
/