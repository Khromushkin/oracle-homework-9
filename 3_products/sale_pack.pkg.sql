create or replace package sale_pack is
    type t_sale_item_record is record (
        prd_id sale_item.prd_id%type,
        prd_count sale_item.prd_count%type
        );
    type t_sale_items_array is table of t_sale_item_record;

    type t_sale_record is record (
        sale_id sale.sale_id%type,
        sale_dtime sale.sale_dtime%type,
        sale_items_array t_sale_items_array
        );
    -- Создание продажи
    function create_sale(pi_sale_items_array t_sale_items_array)
        return sale.sale_id%type;

    -- Получение информации о продаже по идентификатору продажи
    function get_sale(pi_sale_id sale.sale_id%type)
        return t_sale_record;

    -- частичный возврат продуктов в продаже
    procedure partial_refund(pi_sale_id sale.sale_id%type,
                             pi_refund_items_array t_sale_items_array);

    -- Полный возврат продуктов в продаже
    procedure refund(pi_sale_id sale.sale_id%type);

    -- Триггер аудита
    procedure change_sale_item_tr_body_dml(pi_stm_id sale_item.stm_id%type,
                                           pi_new_rec sale_item%rowtype,
                                           pi_old_rec sale_item%rowtype);

    -- Триггер запрещающий менять без API
    procedure sale_tr_body_restrict;

end sale_pack;
/
create or replace package body sale_pack is

    g_is_api boolean := false; -- Происходит ли изменение через API

    -- Создание продажи
    function create_sale(pi_sale_items_array t_sale_items_array)
        return sale.sale_id%type is
        v_sale_id     sale.sale_id%type;
        v_product_rec product%rowtype;
    begin
        savepoint before_create_sale;

        g_is_api := true;

        -- вставляем запись продажи
        insert into sale
            (sale_id, sale_dtime)
        values (sale_id_seq.nextval, systimestamp)
        returning sale_id into v_sale_id;

        forall i in pi_sale_items_array.first .. pi_sale_items_array.last
            -- забираем со склада позиции
            update product_stock
            set prs_count = prs_count - pi_sale_items_array(i).prd_count
            where prd_id = pi_sale_items_array(i).prd_id;

        forall i in pi_sale_items_array.first .. pi_sale_items_array.last
            -- вставляем записи позиций продажи
            insert into sale_item
                (stm_id, prd_id, prd_count, prd_amount, sale_id)
            select stm_id_seq.nextval,
                   product.prd_id,
                   pi_sale_items_array(i).prd_count,
                   product.prd_cost * pi_sale_items_array(i).prd_count,
                   v_sale_id
            from product
            where prd_id = pi_sale_items_array(i).prd_id;
        g_is_api := false;

        return v_sale_id;
    exception
        when others then
            rollback to before_create_sale;
            g_is_api := false;
            raise_application_error(
                    sqlcode, sqlerrm);
    end;

    function get_sale(pi_sale_id sale.sale_id%type) return t_sale_record
        is
        v_sale_record t_sale_record;
    begin
        select sale_dtime
        into v_sale_record.sale_dtime
        from sale
        where sale_id = pi_sale_id;

        select prd_id, prd_count bulk collect
        into v_sale_record.sale_items_array
        from sale_item
        where sale_id = pi_sale_id;

        return v_sale_record;
    end;

-- частичный возврат продуктов в продаже
    procedure partial_refund(pi_sale_id sale.sale_id%type,
                             pi_refund_items_array t_sale_items_array) is
    begin
        savepoint before_partial_refund;

        g_is_api := true;

        forall i in pi_refund_items_array.first .. pi_refund_items_array.last
            -- Обновляем продажу с пересчетом суммы позиции
            update sale_item
            set prd_count  = prd_count - pi_refund_items_array(i).prd_count,
                prd_amount = prd_amount * (prd_count - pi_refund_items_array(i).prd_count) / prd_count
            where sale_id = pi_sale_id
              and prd_id = pi_refund_items_array(i).prd_id;
        forall i in pi_refund_items_array.first .. pi_refund_items_array.last
            update product_stock
            set prs_count = prs_count + pi_refund_items_array(i).prd_count
            where prd_id = pi_refund_items_array(i).prd_id;

        g_is_api := false;

    exception
        when others then
            rollback to before_partial_refund;
            g_is_api := false;
            raise_application_error(sqlcode, sqlerrm);
    end;

-- Полный возврат продуктов в продаже
    procedure refund(pi_sale_id sale.sale_id%type) is
    begin
        savepoint before_refund;

        g_is_api := true;
        -- Возвращаем на склад
        merge into product_stock
        using
            (
                select *
                from sale_item
                where sale_id = pi_sale_id
            ) sale_item
        on (product_stock.prd_id = sale_item.prd_id)
        when matched then
            update
            set product_stock.prs_count = product_stock.prs_count + sale_item.prd_count;

        -- Обнуляем позиции
        update sale_item
        set prd_count  = 0,
            prd_amount = 0
        where sale_item.sale_id = pi_sale_id;

        g_is_api := false;

    exception
        when others then
            rollback to before_refund;
            g_is_api := false;
            raise_application_error(sqlcode, sqlerrm);
    end;

-- Триггер аудита
    procedure
        change_sale_item_tr_body_dml(pi_stm_id sale_item.stm_id%type,
                                     pi_new_rec sale_item%rowtype,
                                     pi_old_rec sale_item%rowtype) is
    begin
        insert into sale_item_aud
        (sia_id, stm_id, old_prd_count, old_prd_amount, new_prd_count, new_prd_amount)
        values (sia_id_seq.nextval,
                pi_stm_id,
                pi_old_rec.prd_count,
                pi_old_rec.prd_amount,
                pi_new_rec.prd_count,
                pi_new_rec.prd_amount);
    end;

-- Триггер запрещающий менять без API
    procedure
        sale_tr_body_restrict is
    begin
        if g_is_api then
            return;
        else
            raise_application_error(-20101, 'Use API, Luke');
        end if;
    end;

end;
/