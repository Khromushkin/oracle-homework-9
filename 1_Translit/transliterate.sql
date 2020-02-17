set serveroutput on;
/
create or replace package pack_translit is
    function transliterate(p_in_string varchar2) return varchar2;
--         deterministic;
end;
/
create or replace package body pack_translit is
    type t_alphabet is table of varchar2(3 char) index by varchar2 (2 char);
    g_alphabet t_alphabet := t_alphabet();
    procedure init is
        v_alphabet_map_iterator varchar2(2 char);
        v_alphabet_upper t_alphabet := t_alphabet();
    begin
        g_alphabet := t_alphabet();
        g_alphabet('а') := 'a';
        g_alphabet('б') := 'b';
        g_alphabet('в') := 'v';
        g_alphabet('г') := 'g';
        g_alphabet('д') := 'd';
        g_alphabet('е') := 'e';
        g_alphabet('ё') := 'yo';
        g_alphabet('ж') := 'zh';
        g_alphabet('з') := 'z';
        g_alphabet('и') := 'i';
        g_alphabet('й') := 'j';
        g_alphabet('к') := 'k';
        g_alphabet('л') := 'l';
        g_alphabet('м') := 'm';
        g_alphabet('н') := 'n';
        g_alphabet('о') := 'o';
        g_alphabet('п') := 'p';
        g_alphabet('р') := 'r';
        g_alphabet('с') := 's';
        g_alphabet('т') := 't';
        g_alphabet('у') := 'u';
        g_alphabet('ф') := 'f';
        g_alphabet('х') := 'x';
        g_alphabet('ц') := 'c';
        g_alphabet('ч') := 'ch';
        g_alphabet('ш') := 'sh';
        g_alphabet('щ') := 'shh';
        g_alphabet('ъ') := '`';
        g_alphabet('ы') := 'y`';
        g_alphabet('ь') := '`';
        g_alphabet('э') := 'e`';
        g_alphabet('ю') := 'yu';
        g_alphabet('я') := 'ya';

        v_alphabet_map_iterator := g_alphabet.first;
        while v_alphabet_map_iterator is not null
        loop
            v_alphabet_upper(upper(v_alphabet_map_iterator)) := upper(g_alphabet(v_alphabet_map_iterator));
            v_alphabet_map_iterator := g_alphabet.next(v_alphabet_map_iterator);
        end loop;

        v_alphabet_map_iterator := v_alphabet_upper.first;
        while v_alphabet_map_iterator is not null
        loop
            g_alphabet(v_alphabet_map_iterator) := v_alphabet_upper(v_alphabet_map_iterator);
            v_alphabet_map_iterator := v_alphabet_upper.next(v_alphabet_map_iterator);
        end loop;
        dbms_output.put_line('initialized');
    end;

    function transliterate_char(p_in_char varchar2) return varchar2
        result_cache
        deterministic
        is
    begin
        if g_alphabet.exists(p_in_char) then
            return g_alphabet(p_in_char);
        else
            return p_in_char;
        end if;
    end;

    function transliterate(p_in_string varchar2) return varchar2
--         deterministic
        is
        v_result_str varchar2(500 char) := '';
    begin
        for i in 1 .. length(p_in_string)
            loop
                v_result_str := v_result_str || transliterate_char(substr(p_in_string, i, 1));
            end loop;
        return v_result_str;
    end;
    begin
    init();
end;
/
declare
    v_input_string varchar2(200 char) := 'Privet, Андрей!Privet, Андрей!Privet, Андрей!Privet, Андрей!Privet, Андрей!Privet, Андрей!';
    v_date_start pls_integer;
    v_result varchar2(1000 char);
    v_counter pls_integer := 0;
begin
    v_date_start := dbms_utility.get_time();

    for idx in 1 .. 1000000 loop
        v_counter := v_counter + 1;
    v_result := pack_translit.transliterate(v_input_string);
--         dbms_output.put_line(v_result);
    end loop;
    dbms_output.put_line((dbms_utility.get_time() - v_date_start)* 10 || ' milliseconds for ' || v_counter || ' iterations');
end;
/