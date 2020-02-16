

declare
    v_sale_items sale_pack.t_sale_items_array := sale_pack.t_sale_items_array();
begin
    v_sale_items.extend();
    v_sale_items(v_sale_items.last) := sale_pack.t_sale_item_record(11, 2);
    sale_pack.PARTIAL_REFUND(142, v_sale_items);
--     dbms_output.put_line(sale_pack.create_sale(v_sale_items));
    commit;
end;

/
select * from product_stock;
select * from sale_item;

 update sale_item
        set prd_count  = 0,
            prd_amount = 0
        where sale_item.sale_id = 141;


select * from all_errors;
update sale_item set prd_amount = 48 where stm_id = 1;

