alter session set nls_date_language = 'AMERICAN';

set serveroutput on;

CREATE USER admin IDENTIFIED BY admin;
GRANT RESOURCE TO admin;
GRANT UNLIMITED TABLESPACE TO admin;

alter session set current_schema = admin;

create or replace type t_varchar_array as table of varchar2(2000 char);
/
create or replace type t_number_array as table of number;
/
create or replace function split(p_i_list in varchar2,
                                 p_i_delimiter in varchar2) return t_varchar_array as
    v_split_array t_varchar_array     := t_varchar_array();
    i             pls_integer         := 0;
    v_list        varchar2(4000 char) := p_i_list;
begin
    loop
        i := instr(v_list, p_i_delimiter);
        if i > 0 then
            v_split_array.extend(1);
            v_split_array(v_split_array.last) := substr(v_list, 1, i - 1);
            v_list := substr(v_list, i + length(p_i_delimiter));
        else
            v_split_array.extend(1);
            v_split_array(v_split_array.last) := v_list;
            return v_split_array;
        end if;
    end loop;
end;
/
create or replace function split_numbers(p_i_list in varchar2,
                                         p_i_delimiter in varchar2) return t_number_array as
    v_split_array        t_varchar_array;
    v_split_number_array t_number_array := t_number_array();
    i                    pls_integer    := 0;
begin
    v_split_array := split(p_i_list, p_i_delimiter);
    for i in 1 .. v_split_array.count
        loop
            v_split_number_array.extend(1);
            v_split_number_array(i) := to_number(v_split_array(i));
        end loop;
    return v_split_number_array;
end;
/

create or replace package cron is
    function get_date(p_i_date_from date, p_i_schedule varchar2) return date;
end;
/
create or replace package body cron is
    type t_weekday_array is table of varchar2(100 char) index by pls_integer;
    g_weekdays t_weekday_array;

    procedure init is
    begin
        dbms_output.put_line('init');
        g_weekdays := t_weekday_array();
        g_weekdays(1) := 'SUNDAY';
        g_weekdays(2) := 'MONDAY';
        g_weekdays(3) := 'TUESDAY';
        g_weekdays(4) := 'WEDNESDAY';
        g_weekdays(5) := 'THURSDAY';
        g_weekdays(6) := 'FRIDAY';
        g_weekdays(7) := 'SATURDAY';
    end;

    function find_closest_min(p_i_date date, p_i_minutes_array t_number_array) return date is
        v_current_min number;
        v_iter_min    number;
    begin
        dbms_output.put_line('find_closest_min');
        v_current_min := extract(minute from to_timestamp(p_i_date));
        for i in 1 .. p_i_minutes_array.count
            loop
                v_iter_min := p_i_minutes_array(i);
                dbms_output.put_line('check minute: ' || v_iter_min);
                if (v_iter_min = 0 and v_current_min > 0) then
                    v_iter_min := 60;
                end if;
                if (v_current_min <= v_iter_min AND (v_iter_min - v_current_min) < 15) then
                    return p_i_date + (v_iter_min - v_current_min) * 1 / 24 * 1 / 60;
                end if;
            end loop;
    end;

    function find_closest_hour(p_i_date date, p_i_hours_array t_number_array) return date is
        v_current_hour        number;
        v_iter_hour           number;
        v_closest_target_hour number := 100;
    begin
        dbms_output.put_line('find_closest_hour');
        v_current_hour := extract(hour from to_timestamp(p_i_date));
        for i in 1 .. p_i_hours_array.count
            loop
                v_iter_hour := p_i_hours_array(i);
                dbms_output.put_line('check hour: ' || v_iter_hour);
                if (v_iter_hour = 0 and v_current_hour > 0) then
                    v_iter_hour := 24;
                end if;
                if (v_current_hour <= v_iter_hour AND
                    (v_iter_hour - v_current_hour) < (v_closest_target_hour - v_current_hour)) then
                    v_closest_target_hour := v_iter_hour;
                end if;
            end loop;
        return p_i_date + (v_closest_target_hour - v_current_hour) * 1 / 24;
    end;

    function find_closest_weekday(p_i_date date, p_i_weekdays_array t_number_array) return date is
        v_closest_date        date := p_i_date + 100;
        v_iter_date           date;
        v_current_day_of_week varchar2(100 char);
    begin
        dbms_output.put_line('find_closest_weekday');
        v_current_day_of_week := trim(to_char(p_i_date, 'DAY'));
        dbms_output.put_line('current day of week is ' || v_current_day_of_week);
        for i in 1 .. p_i_weekdays_array.count
            loop
                dbms_output.put_line('check weekday: ' || g_weekdays(p_i_weekdays_array(i)));
                if (v_current_day_of_week = g_weekdays(p_i_weekdays_array(i))) then
                    dbms_output.put_line('current day of week fits');
                    v_closest_date := p_i_date;
                    exit;
                end if;
                v_iter_date := next_day(p_i_date, g_weekdays(p_i_weekdays_array(i)));
                if (v_iter_date - p_i_date < v_closest_date - p_i_date) then
                    v_closest_date := v_iter_date;
                end if;
            end loop;
        return v_closest_date;
    end;

    function find_closest_monthday(p_i_date date, p_i_monthdays_array t_number_array) return date is
        v_current_monthday        number;
        v_iter_monthday           number;
        v_closest_target_monthday number := 100;
    begin
        dbms_output.put_line('find_closest_monthday');
        v_current_monthday := extract(day from to_timestamp(p_i_date));
        for i in 1 .. p_i_monthdays_array.count
            loop
                v_iter_monthday := p_i_monthdays_array(i);
                dbms_output.put_line('check monthday: ' || v_iter_monthday);
                if (v_current_monthday <= v_iter_monthday AND
                    (v_iter_monthday - v_current_monthday) < (v_closest_target_monthday - v_current_monthday)) then
                    v_closest_target_monthday := v_iter_monthday;
                end if;
            end loop;
        return p_i_date + (v_closest_target_monthday - v_current_monthday);
    end;

    function find_closest_month(p_i_date date, p_i_months_array t_number_array) return date is
        v_current_month        number;
        v_iter_month           number;
        v_closest_target_month number := 100;
    begin
        dbms_output.put_line('find_closest_month');
        v_current_month := extract(month from to_timestamp(p_i_date));
        for i in 1 .. p_i_months_array.count
            loop
                v_iter_month := p_i_months_array(i);
                dbms_output.put_line('check month: ' || v_iter_month);
                if (v_current_month <= v_iter_month AND
                    (v_iter_month - v_current_month) < (v_closest_target_month - v_current_month)) then
                    v_closest_target_month := v_iter_month;
                end if;
            end loop;
        return add_months(p_i_date, v_closest_target_month - v_current_month);
    end;

    procedure log_date_transition(p_i_date_from date, p_i_date_to date) is
    begin
        dbms_output.put_line(
                    to_char(p_i_date_from,
                            'DD.MM.YYYY HH24:mi') || ' -> ' ||
                    to_char(p_i_date_to,
                            'DD.MM.YYYY HH24:mi'));
    end;

    function get_date(p_i_date_from date, p_i_schedule varchar2) return date
        is
        type t_intervals_array is table of t_number_array;
        v_intervals_array t_intervals_array := t_intervals_array();
        v_split_array     t_varchar_array   := t_varchar_array();
        v_iter_date       date;
        v_iter_next_date  date;
        v_result_date     date;
    begin
        dbms_output.put_line('get_date');
        v_split_array := split(p_i_schedule, ';');
        for i in 1 .. v_split_array.count
            loop
                v_intervals_array.extend(1);
                v_intervals_array(i) := split_numbers(v_split_array(i), ',');
            end loop;

        v_iter_date := p_i_date_from;
        v_result_date := p_i_date_from;
        loop

            v_iter_next_date := find_closest_month(v_iter_date, v_intervals_array(5));
            log_date_transition(v_iter_date, v_iter_next_date);
            if (v_iter_next_date != v_iter_date) then
                dbms_output.put_line('trunc month');
                v_iter_next_date := trunc(v_iter_next_date, 'month');
            end if;
            v_iter_date := v_iter_next_date;

            v_iter_next_date := find_closest_monthday(v_iter_date, v_intervals_array(4));
            log_date_transition(v_iter_date, v_iter_next_date);
            if (v_iter_next_date != v_iter_date) then
                dbms_output.put_line('trunc month day');
                v_iter_next_date := trunc(v_iter_next_date);
            end if;
            v_iter_date := v_iter_next_date;

            v_iter_next_date := find_closest_weekday(v_iter_date, v_intervals_array(3));
            log_date_transition(v_iter_date, v_iter_next_date);
            if (v_iter_next_date != v_iter_date) then
                dbms_output.put_line('trunc week day');
                v_iter_next_date := trunc(v_iter_next_date);
            end if;
            v_iter_date := v_iter_next_date;

            v_iter_next_date := find_closest_hour(v_iter_date, v_intervals_array(2));
            log_date_transition(v_iter_date, v_iter_next_date);
            if (v_iter_next_date != v_iter_date) then
                dbms_output.put_line('trunc hour');
                v_iter_next_date := trunc(v_iter_next_date, 'hh24');
            end if;
            v_iter_date := v_iter_next_date;

            v_iter_next_date := find_closest_min(v_iter_date, v_intervals_array(1));
            log_date_transition(v_iter_date, v_iter_next_date);

            if (v_result_date = v_iter_next_date) then
                exit;
            end if;

            v_result_date := v_iter_next_date;
        end loop;
        return v_result_date;
    end ;
    begin
    init();
end;
/
begin
    dbms_output.put_line(
            to_char(
                    cron.get_date(
                            to_date('09.07.2010 23:36', 'DD.MM.YYYY HH24:mi'),
                            '0,45;12;1,2,6;3,6,14,18,21,24,28;1,2,3,4,5,6,7,8,9,10,11,12;'),
                    'DD.MM.YYYY HH24:mi')
        );
end;
/