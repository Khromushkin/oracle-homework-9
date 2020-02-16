set serveroutput on;

CREATE USER admin IDENTIFIED BY admin;
GRANT RESOURCE TO admin;
GRANT UNLIMITED TABLESPACE TO admin;

alter session set current_schema = admin;

create or replace package odba.current_session_params is
    type t_user_params is record (
        sid NUMBER,
        pid NUMBER,
        osuser varchar2(128 char),
        oracle_user varchar2(128 char)
        );
    g_session_params t_user_params := t_user_params();

end;
/
create or replace package body odba.current_session_params is
    procedure init is
    begin
        select s.sid, p.pid, s.username, s.osuser
        into g_session_params.sid, g_session_params.pid, g_session_params.oracle_user, g_session_params.osuser
        from v$session s
                 inner join v$process p on p.addr = s.paddr
        where s.sid = sys_context('userenv', 'sid');
    end;
    begin
    init();
end;
/
grant execute on odba.current_session_params to admin;

drop table event_log;
create table event_log
(
    dtime       TIMESTAMP(6) default systimestamp not null,
    log_level   CHAR(1 char),
    message     VARCHAR2(4000 char),
    call_place  VARCHAR2(1000 char),
    call_stack  VARCHAR2(4000 char),
    sid         NUMBER,
    pid         NUMBER,
    osuser      varchar2(128 char),
    oracle_user varchar2(128 char)
)
    partition by range (dtime) interval (numtodsinterval(1, 'DAY'))
(
    partition p0 values less than (to_date('2020-01-01', 'YYYY-MM-DD'))
);

alter table event_log
    add constraint check_event_log_level check (log_level in ('I', 'E', 'W'));

begin
    dbms_scheduler.drop_job('drop_old_event_log');
end;
/
begin
    dbms_scheduler.create_job('drop_old_event_log',
                              job_type=>'PLSQL_BLOCK', job_action=>
                                  'begin
                                    execute immediate ''ALTER TABLE event_log DROP PARTITION FOR(sysdate - 31);'';
                                    exception
                                    when others then
                                        null;
                                  end;'
        , number_of_arguments=>0,
                              start_date=>NULL, repeat_interval=>
                                  'FREQ=SECONDLY;INTERVAL=1'
        , end_date=>NULL,
                              job_class=>'"DEFAULT_JOB_CLASS"', enabled=> FALSE, auto_drop=> FALSE, comments=>
                                  NULL
        );
    dbms_scheduler.set_attribute('drop_old_event_log', 'logging_level', dbms_scheduler.logging_runs);
    dbms_scheduler.enable('drop_old_event_log');
end;

/

comment on table event_log is 'Логи событий в БД'
/

comment on column event_log.dtime is 'Время события'
/

comment on column event_log.log_level is 'Уровень логирования сообщения. I - информация, E - ошибка, W - предупреждение'
/

comment on column event_log.message is 'Сообщение'
/
comment on column event_log.call_place is 'Место логирования'
/
comment on column event_log.call_stack is 'Стэк вызовов'
/

comment on column event_log.pid is 'Идентификатор процесса'
/

comment on column event_log.sid is 'Идентификатор сессии'
/

comment on column event_log.osuser is 'Имя пользователя операционной системы клиента'
/

comment on column event_log.oracle_user is 'Имя пользователя oracle'
/

create index event_log_dtime_i_l
    on event_log (dtime desc) local;


create or replace package event_log_pack is

    procedure warn(p_place event_log.call_place%type
                  , p_message event_log.message%type);
    procedure info(p_place event_log.call_place%type
                  , p_message event_log.message%type);
    procedure error(p_place event_log.call_place%type
                   , p_message event_log.message%type);
end;
/

create or replace package body event_log_pack is
    procedure insert_log(pi_event_log_rec event_log%rowtype) is
        pragma autonomous_transaction;
    begin
        insert into event_log
        values pi_event_log_rec;
        commit;
    end;

    procedure log(p_place event_log.call_place%type
                 , p_message event_log.message%type
                 , p_log_level event_log.log_level%type) is
        v_event_log_rec event_log%rowtype;
    begin
        v_event_log_rec.log_level := substr(p_log_level, 1, 1);
        v_event_log_rec.call_place := substr(p_place, 1, 1000);
        v_event_log_rec.message := substr(p_message, 1, 4000);
        v_event_log_rec.dtime := systimestamp;
        v_event_log_rec.call_stack := substr(dbms_utility.format_call_stack ||
                                             chr(10) ||
                                             dbms_utility.format_error_stack ||
                                             chr(10) ||
                                             dbms_utility.format_error_backtrace,
                                             1,
                                             4000);
        v_event_log_rec.sid := odba.current_session_params.g_session_params.sid;
        v_event_log_rec.pid := odba.current_session_params.g_session_params.pid;
        v_event_log_rec.oracle_user := odba.current_session_params.g_session_params.oracle_user;
        v_event_log_rec.osuser := odba.current_session_params.g_session_params.osuser;


        insert_log(v_event_log_rec);

    exception
        when others then
            null;
    end;

    procedure warn(p_place event_log.call_place%type
                  , p_message event_log.message%type) is
    begin
        log(p_place, p_message, 'W');
    end;
    procedure info(p_place event_log.call_place%type
                  , p_message event_log.message%type) is
    begin
        log(p_place, p_message, 'I');
    end;
    procedure error(p_place event_log.call_place%type
                   , p_message event_log.message%type) is
    begin
        log(p_place, p_message, 'E');
    end;
end;
/
begin
    event_log_pack.warn('here', 'this situation is unusual!');
    event_log_pack.error('here', 'error occured!');
    event_log_pack.info('here', 'im ok');
end;
/
select *
from event_log;